#!/usr/bin/env python3
"""Run exhaustive Microverse expansion checks without submitting proofs.

The default run performs catalog validation, validator regression tests, and a
stock-PEXE compile/check.  When an isolated test package and scenario contract
are supplied, it also executes every positive and negative sequence through
the existing reachable-state harness.  Mock execution is the default; ``--real``
locally proves only scenarios marked ``real_sample``.  This program has no
submission mode and rejects any command containing the word ``submit``.

Scenario contract shape::

    {
      "schema_version": 1,
      "production_module_hash": "...",
      "required_action_coverage": ["ActionA", "ActionB"],
      "positive": [
        {"name": "component-a-reusable", "actions": ["Mint...", "ActionA"],
         "covers": ["ActionA"], "real_sample": true}
      ],
      "negative": [
        {"name": "component-a-wrong-skill", "actions": ["Mint...", "ActionA"],
         "covers": ["ActionA"], "expected_error_contains": ["constraint"]}
      ]
    }

The isolated package must be generated from production action source and may
only remove audited VDF blocks/add output-only fixtures.  Source-parity and
fixture audits are required alongside the contract.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
from typing import Any, Mapping, Sequence

import validate_expansion_catalogs as validator


ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / "tools" / "validate_expansion_catalogs.py"
DEFAULT_PEXE = Path(r"C:\Users\Rich\.dobj\bin\pexe.exe")
DEFAULT_HARNESS = (
    ROOT.parent.parent
    / "microverse-celestial-prototype"
    / "tools"
    / "target"
    / "release"
    / "microverse-reachable-harness.exe"
)
VDF_BLOCK = re.compile(
    r"\n(?P<indent>[ \t]*)var\s+"
    r"(?P<work>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
    r"action\.intro_vdf\(\s*(?P<iterations>[0-9]+)\s*,\s*"
    r"(?P<object>[A-Za-z_][A-Za-z0-9_]*)\s*\);\s*\r?\n"
    r"(?P=indent)(?P=object)\.update\(\"work\",\s*(?P=work)\);"
)
APPROVED_TEST_VDF_HELPERS = frozenset({
    *(name for name, _kind, _iterations, _representative in validator.PHASE4_ECONOMY_HELPERS),
    *validator.PHASE5_KNOWN_HELPER_NAMES,
    *validator.PHASE6_VDF_HELPERS.values(),
    "reveal_chart_p",
    "reveal_chart_t",
})
APPROVED_TEST_VDF_HELPER_COUNT = 45
APPROVED_TEST_VDF_HELPERS_SHA256 = (
    "b9d48dbac953fce8af5f0353cc456f499792740c6920dd6e124dbae2a62aad78"
)
assert len(APPROVED_TEST_VDF_HELPERS) == APPROVED_TEST_VDF_HELPER_COUNT
assert hashlib.sha256(
    ("\n".join(sorted(APPROVED_TEST_VDF_HELPERS)) + "\n").encode("utf-8")
).hexdigest() == APPROVED_TEST_VDF_HELPERS_SHA256


def exact_vdf_transform(source: str) -> tuple[str, int]:
    expected = source.count("action.intro_vdf(")
    transformed, removed = VDF_BLOCK.subn("", source)
    if removed != expected or "action.intro_vdf(" in transformed:
        raise RuntimeError(
            f"noncanonical VDF source: expected {expected}, removed {removed}"
        )
    return transformed, removed


def source_role_rows(source: str) -> list[dict[str, Any]]:
    occurrences: dict[tuple[str, str], int] = {}
    output_ordinal = 0
    rows: list[dict[str, Any]] = []
    for ordinal, (variable, mode, class_name) in enumerate(
        re.findall(
            r"\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
            r"action\.(output|input|mutate)\s*\(\s*\"([^\"]+)\"\s*\)",
            source,
        ),
        start=1,
    ):
        key = (mode, class_name)
        occurrences[key] = occurrences.get(key, 0) + 1
        produced: int | None = None
        if mode in {"output", "mutate"}:
            output_ordinal += 1
            produced = output_ordinal
        normalized = f'{variable}=action.{mode}("{class_name}")'
        rows.append(
            {
                "ordinal": ordinal,
                "variable": variable,
                "mode": mode,
                "class": class_name,
                "class_occurrence": occurrences[key],
                "output_ordinal": produced,
                "normalized_ref": normalized,
                "normalized_ref_sha256": sha256_text(normalized),
            }
        )
    return rows


def fixture_source_schema_contract(
    action: str,
    class_name: str,
    source: str,
    class_row: Mapping[str, Any],
) -> dict[str, Any]:
    """Independently reconstruct fixture schema coverage from its Rhai source."""

    fields = class_row.get("fields")
    if not isinstance(fields, list):
        raise RuntimeError(f"fixture class {class_name} lacks schema fields")
    expected_types = {
        str(field["name"]): str(field["type"])
        for field in fields
        if isinstance(field, Mapping)
    }
    sdk_live = class_row.get("sdk_managed_live_fields")
    if not isinstance(sdk_live, list) or set(map(str, sdk_live)) != {
        "type",
        "work",
    }:
        raise RuntimeError(
            f"fixture class {class_name} must declare exact SDK live fields "
            "type/work"
        )
    for field_name in ("key", "stable_identifier"):
        if expected_types.get(field_name) != "Raw":
            raise RuntimeError(
                f"fixture class {class_name}.{field_name} must be Raw"
            )

    roles = source_role_rows(source)
    if len(roles) != 1 or roles[0]["mode"] != "output" or roles[0]["class"] != class_name:
        raise RuntimeError(
            f"fixture {action} must have exactly one {class_name} output role"
        )
    output_variable = str(roles[0]["variable"])
    raw_variables = set(
        re.findall(
            r"\b(?:var|let)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
            r"action\.(?:random|top_limb_u256)\s*\(",
            source,
        )
    )
    integer_variables = {
        name
        for name, _value in re.findall(
            r"\b(?:var|let)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
            r"(-?[0-9]+)\s*;",
            source,
        )
    }

    def inferred_type(expression: str) -> str:
        if re.fullmatch(r"-?[0-9]+", expression) or expression in integer_variables:
            return "Int"
        if expression in raw_variables:
            return "Raw"
        raise RuntimeError(
            f"fixture {action} has untyped expression {expression!r}"
        )

    assignments: dict[str, dict[str, Any]] = {}
    set_matches = list(
        re.finditer(
            rf"\b{re.escape(output_variable)}\.set\s*\(\s*"
            rf"\[(?P<body>.*?)\]\s*\)\s*;",
            source,
            re.DOTALL,
        )
    )
    if len(set_matches) != 1:
        raise RuntimeError(f"fixture {action} must have exactly one output set call")
    set_body = set_matches[0].group("body")
    set_pairs = re.findall(
        r'\[\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*,\s*'
        r"([A-Za-z_][A-Za-z0-9_]*|-?[0-9]+)\s*\]",
        set_body,
    )
    if len(set_pairs) != len(re.findall(r'\[\s*"', set_body)):
        raise RuntimeError(f"fixture {action} has an unparsed output set entry")
    for field_name, expression in set_pairs:
        if field_name in assignments:
            raise RuntimeError(f"fixture {action} assigns {field_name} more than once")
        assignments[field_name] = {
            "source": "set",
            "expression": expression,
            "inferred_type": inferred_type(expression),
        }

    update_pairs = re.findall(
        rf"\b{re.escape(output_variable)}\.update\s*\(\s*"
        r'"([A-Za-z_][A-Za-z0-9_]*)"\s*,\s*'
        r"([A-Za-z_][A-Za-z0-9_]*|-?[0-9]+)\s*\)\s*;",
        source,
    )
    if len(update_pairs) != len(
        re.findall(rf"\b{re.escape(output_variable)}\.update\s*\(", source)
    ):
        raise RuntimeError(f"fixture {action} has an unparsed output update")
    for field_name, expression in update_pairs:
        assignments[field_name] = {
            "source": "update",
            "expression": expression,
            "inferred_type": inferred_type(expression),
        }

    sdk_runtime_managed = {str(field) for field in sdk_live} | {
        "key",
        "stable_identifier",
    }
    sdk_defaulted: list[str] = []
    for field_name in ("key", "stable_identifier"):
        if field_name not in assignments:
            assignments[field_name] = {
                "source": "sdk_managed",
                "expression": None,
                "inferred_type": "SDKManaged",
            }
            sdk_defaulted.append(field_name)
    for field_name in sdk_live:
        name = str(field_name)
        if name not in assignments:
            assignments[name] = {
                "source": "sdk_managed",
                "expression": None,
                "inferred_type": "SDKManaged",
            }
            sdk_defaulted.append(name)

    explicit_fields = {
        name for name, row in assignments.items() if row["source"] != "sdk_managed"
    }
    unknown_explicit = sorted(explicit_fields - set(expected_types))
    if unknown_explicit:
        raise RuntimeError(
            f"fixture {action} assigns fields outside {class_name}: {unknown_explicit}"
        )
    missing = sorted(set(expected_types) - set(assignments))
    if missing:
        raise RuntimeError(
            f"fixture {action} is schema-incomplete for {class_name}; missing {missing}"
        )
    wrong_types = {
        name: {
            "expected": expected_types[name],
            "actual": assignments[name]["inferred_type"],
        }
        for name in expected_types
        if assignments[name]["source"] != "sdk_managed"
        and assignments[name]["inferred_type"] != expected_types[name]
    }
    if wrong_types:
        raise RuntimeError(
            f"fixture {action} has wrong field types for {class_name}: {wrong_types}"
        )
    return {
        "status": "complete",
        "class": class_name,
        "output_variable": output_variable,
        "schema_field_count": len(expected_types),
        "explicit_schema_field_count": len(explicit_fields),
        "sdk_managed_runtime_fields": sorted(sdk_runtime_managed),
        "sdk_defaulted_fields": sorted(set(sdk_defaulted)),
        "field_sources": {name: assignments[name] for name in sorted(assignments)},
        "missing_fields": [],
        "wrong_type_fields": {},
    }


def source_direct_helpers(
    name: str,
    functions: Mapping[str, str],
    action_names: set[str],
) -> list[str]:
    source = functions[name]
    body = validator.strip_rhai_comments(source[source.find("{") + 1 :])
    result: list[str] = []
    for call in re.findall(
        r"(?<![.A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(", body
    ):
        if call in functions and call not in action_names and call not in result:
            result.append(call)
    return result


def source_helper_paths(
    name: str,
    production_functions: Mapping[str, str],
    test_functions: Mapping[str, str],
    action_names: set[str],
) -> tuple[list[str], list[dict[str, Any]]]:
    paths: list[tuple[str, ...]] = []

    def visit(current: str, path: tuple[str, ...]) -> None:
        for helper in source_direct_helpers(current, production_functions, action_names):
            next_path = (*path, helper)
            if helper in path:
                raise RuntimeError(f"helper cycle {' -> '.join(next_path)}")
            paths.append(next_path)
            visit(helper, next_path)

    visit(name, (name,))
    return (
        sorted({path[-1] for path in paths}),
        [
            {
                "path": list(path),
                "helper": path[-1],
                "production_sha256": sha256_text(production_functions[path[-1]]),
                "test_sha256": sha256_text(test_functions[path[-1]]),
            }
            for path in paths
        ],
    )


def stable_json(value: Any) -> str:
    return json.dumps(value, indent=2, sort_keys=True) + "\n"


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def safe_command(command: Sequence[str]) -> None:
    for argument in command:
        if "submit" in argument.lower():
            raise RuntimeError(
                f"submission commands are prohibited by this runner: {command}"
            )


def run_command(command: list[str], *, cwd: Path) -> dict[str, Any]:
    safe_command(command)
    started = time.perf_counter()
    completed = subprocess.run(
        command,
        cwd=cwd,
        text=True,
        encoding="utf-8",
        errors="replace",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    return {
        "command": command,
        "cwd": str(cwd),
        "exit_code": completed.returncode,
        "seconds": time.perf_counter() - started,
        "stdout_tail": completed.stdout[-8_000:],
        "stderr_tail": completed.stderr[-8_000:],
    }


def process_status(process: Mapping[str, Any]) -> str:
    return "pass" if process.get("exit_code") == 0 else "fail"


def build_check_isolated_copy(pexe: Path, source_root: Path) -> dict[str, Any]:
    """Build then check a disposable copy, preserving the zero-hash test source."""
    started = time.perf_counter()
    with tempfile.TemporaryDirectory(
        prefix=f"microverse-build-check-{source_root.name}-"
    ) as directory:
        copied_root = Path(directory) / source_root.name
        shutil.copytree(source_root, copied_root)
        build = run_command(
            [str(pexe), "build", str(copied_root)],
            cwd=ROOT,
        )
        check: dict[str, Any] | None = None
        if build["exit_code"] == 0:
            check = run_command(
                [str(pexe), "build", str(copied_root), "--check"],
                cwd=ROOT,
            )
    phases = [build] + ([check] if check is not None else [])
    exit_code = 0 if all(row["exit_code"] == 0 for row in phases) else 1
    return {
        "command": [
            str(pexe),
            "build+check-isolated-copy",
            str(source_root),
        ],
        "cwd": str(ROOT),
        "exit_code": exit_code,
        "seconds": time.perf_counter() - started,
        "source_preserved": True,
        "phases": phases,
        "stdout_tail": "",
        "stderr_tail": "" if exit_code == 0 else "isolated build/check failed",
    }


def summarize_harness_report(report: Any) -> Any:
    if not isinstance(report, Mapping):
        return report
    fields = (
        "status",
        "mode",
        "steps",
        "seconds",
        "worst_payload_bytes",
        "worst_payload_headroom_bytes",
        "worst_payload_utilization_percent",
        "payload_hard_limit_bytes",
        "all_payloads_fit_hard_limit",
        "all_automatic_lifecycle_assertions_pass",
        "all_latest_ship_chain_assertions_pass",
        "failed_payload_actions",
        "failed_lifecycle_actions",
        "failed_latest_ship_chain_actions",
    )
    return {field: report.get(field) for field in fields if field in report}


def validate_contract(contract: Mapping[str, Any]) -> list[str]:
    errors: list[str] = []
    if contract.get("schema_version") != 1:
        errors.append("scenario contract schema_version must be 1")
    required = contract.get("required_action_coverage")
    if not isinstance(required, list) or not all(
        isinstance(item, str) and item for item in required
    ):
        errors.append("required_action_coverage must be a list of action names")
        required = []
    seen_names: set[str] = set()
    positive_coverage: set[str] = set()
    all_coverage: set[str] = set()
    selection_gates: dict[str, list[Mapping[str, Any]]] = {
        "positive": [],
        "negative": [],
    }
    capacity_gates: dict[str, list[Mapping[str, Any]]] = {
        "positive": [],
        "negative": [],
    }
    for kind in ("positive", "negative"):
        scenarios = contract.get(kind)
        if not isinstance(scenarios, list):
            errors.append(f"{kind} must be a list")
            continue
        for index, scenario in enumerate(scenarios):
            if not isinstance(scenario, Mapping):
                errors.append(f"{kind}[{index}] must be an object")
                continue
            name = scenario.get("name")
            actions = scenario.get("actions")
            covers = scenario.get("covers")
            if not isinstance(name, str) or not name:
                errors.append(f"{kind}[{index}] requires a name")
            elif name in seen_names:
                errors.append(f"duplicate scenario name {name}")
            else:
                seen_names.add(name)
            if not isinstance(actions, list) or not actions or not all(
                isinstance(item, str) and item for item in actions
            ):
                errors.append(f"{kind}[{index}] requires nonempty action names")
            if not isinstance(covers, list) or not all(
                isinstance(item, str) and item for item in covers
            ):
                errors.append(f"{kind}[{index}] requires covers action names")
            else:
                all_coverage.update(covers)
                if kind == "positive":
                    positive_coverage.update(covers)
            if kind == "negative":
                expected = scenario.get("expected_error_contains")
                if not isinstance(expected, list) or not expected or not all(
                    isinstance(item, str) and item for item in expected
                ):
                    errors.append(
                        f"negative[{index}] requires expected_error_contains tokens"
                    )
            selection_gate = scenario.get("selection_gate")
            if selection_gate is not None:
                if not isinstance(selection_gate, Mapping):
                    errors.append(f"{kind}[{index}] selection_gate must be an object")
                else:
                    selection_gates[kind].append(selection_gate)
                    expected_gate_keys = {
                        "selection_mode",
                        "selection_kind",
                        "selected_code",
                        "counter_field",
                        "minimum_inclusive",
                        "fixture_counter",
                        "expected",
                    }
                    if set(selection_gate) != expected_gate_keys:
                        errors.append(f"{kind}[{index}] selection_gate fields changed")
                    selected_code = selection_gate.get("selected_code")
                    minimum = selection_gate.get("minimum_inclusive")
                    fixture_counter = selection_gate.get("fixture_counter")
                    expected = "accept" if kind == "positive" else "reject"
                    if (
                        selection_gate.get("selection_mode")
                        != "explicit_action_identity"
                        or selection_gate.get("expected") != expected
                        or not isinstance(selected_code, int)
                        or isinstance(selected_code, bool)
                        or not isinstance(minimum, int)
                        or isinstance(minimum, bool)
                        or minimum <= 0
                        or fixture_counter
                        != (minimum if kind == "positive" else minimum - 1)
                    ):
                        errors.append(f"{kind}[{index}] selection_gate values changed")
                    kind_name = selection_gate.get("selection_kind")
                    expected_counter = {
                        "survey_profile": "claim_serial",
                        "civilization_type": "civilization_scan_serial",
                    }.get(kind_name)
                    if selection_gate.get("counter_field") != expected_counter:
                        errors.append(f"{kind}[{index}] selection_gate counter changed")
                    expected_selected_action = None
                    if kind_name == "survey_profile" and isinstance(
                        selected_code, int
                    ):
                        slug = {
                            1: "Sparse",
                            2: "Standard",
                            3: "Rich",
                            4: "Ancient",
                            5: "Anomalous",
                        }.get(selected_code)
                        if slug is not None:
                            expected_selected_action = (
                                f"SurveySector_{selected_code:02d}_{slug}"
                            )
                    elif kind_name == "civilization_type" and isinstance(
                        selected_code, int
                    ):
                        suffix = {1: "I", 2: "II", 3: "III"}.get(
                            selected_code
                        )
                        if suffix is not None:
                            expected_selected_action = (
                                f"MaterializeCivilizationType{suffix}"
                            )
                    if (
                        expected_selected_action is None
                        or not isinstance(actions, list)
                        or actions[-1] != expected_selected_action
                        or not isinstance(covers, list)
                        or expected_selected_action not in covers
                    ):
                        errors.append(f"{kind}[{index}] selection_gate action changed")
            capacity_gate = scenario.get("capacity_gate")
            if capacity_gate is not None:
                if not isinstance(capacity_gate, Mapping):
                    errors.append(f"{kind}[{index}] capacity_gate must be an object")
                else:
                    capacity_gates[kind].append(capacity_gate)
                    expected_capacity_keys = {
                        "selection_mode",
                        "catalog",
                        "action",
                        "destination_code",
                        "uses",
                        "minimum_source_pool_inclusive",
                        "fixture_source_pool_before",
                        "expected",
                    }
                    if set(capacity_gate) != expected_capacity_keys:
                        errors.append(f"{kind}[{index}] capacity_gate fields changed")
                    catalog_name = capacity_gate.get("catalog")
                    code = capacity_gate.get("destination_code")
                    uses = capacity_gate.get("uses")
                    minimum = capacity_gate.get("minimum_source_pool_inclusive")
                    fixture_pool = capacity_gate.get("fixture_source_pool_before")
                    expected = "accept" if kind == "positive" else "reject"
                    expected_uses = 10 if code == 1 else 3 if code == 2 else 1 if code == 5 else None
                    minima = (
                        {10: 18_000, 3: 9_001, 1: 9_000}
                        if isinstance(catalog_name, str)
                        and catalog_name.startswith("v1.")
                        else {10: 40_000, 3: 31_000, 1: 9_000}
                    )
                    action_prefix, slug_width = {
                        "v1.position": ("RevealWarpCoordinate", 3),
                        "v1.time": ("RevealTimeCoordinate", 2),
                        "v2.position": ("RevealWarpChart", 3),
                        "v2.time": ("RevealEpochChart", 3),
                    }.get(catalog_name, ("", 0))
                    expected_action = (
                        f"{action_prefix}{code:0{slug_width}d}"
                        if isinstance(code, int)
                        and not isinstance(code, bool)
                        and action_prefix
                        else None
                    )
                    if (
                        capacity_gate.get("selection_mode")
                        != "explicit_action_identity"
                        or catalog_name
                        not in {"v1.position", "v1.time", "v2.position", "v2.time"}
                        or capacity_gate.get("expected") != expected
                        or capacity_gate.get("action") != expected_action
                        or expected_uses is None
                        or uses != expected_uses
                        or minimum != minima.get(uses)
                        or not isinstance(fixture_pool, int)
                        or isinstance(fixture_pool, bool)
                        or (
                            kind == "positive" and fixture_pool < minimum
                        )
                        or (
                            kind == "negative" and fixture_pool != minimum - 1
                        )
                    ):
                        errors.append(f"{kind}[{index}] capacity_gate values changed")
    if "dynamic_reveals" in contract:
        errors.append(
            "dynamic_reveals is retired; use explicit_reveal_representatives"
        )
    representatives = contract.get("explicit_reveal_representatives", [])
    if not isinstance(representatives, list):
        errors.append("explicit_reveal_representatives must be a list")
    else:
        expected_keys = {
            "name",
            "fixture",
            "ship_fixture",
            "ship_fixture_required_by_target",
            "state_pressure_decoy_fixture",
            "class",
            "catalog_version",
            "catalog_section",
            "action_prefix",
            "representative_action",
            "real_sample",
            "covered_actions",
            "destination_count",
            "vdf_mode",
            "selection_mode",
        }
        for index, row in enumerate(representatives):
            if not isinstance(row, Mapping):
                errors.append(
                    f"explicit_reveal_representatives[{index}] must be an object"
                )
                continue
            if set(row) != expected_keys:
                errors.append(
                    f"explicit_reveal_representatives[{index}] fields changed"
                )
            for field in (
                "name",
                "fixture",
                "ship_fixture",
                "state_pressure_decoy_fixture",
                "class",
                "catalog_version",
                "catalog_section",
                "action_prefix",
                "representative_action",
                "vdf_mode",
            ):
                if not isinstance(row.get(field), str) or not row[field]:
                    errors.append(
                        f"explicit_reveal_representatives[{index}] requires {field}"
                    )
            if row.get("selection_mode") != "explicit_action_identity":
                errors.append(
                    f"explicit_reveal_representatives[{index}] selection mode changed"
                )
            if not isinstance(
                row.get("ship_fixture_required_by_target"), bool
            ) or not isinstance(row.get("real_sample"), bool):
                errors.append(
                    f"explicit_reveal_representatives[{index}] requires boolean flags"
                )
            if row.get("catalog_version") not in {"v1", "v2"}:
                errors.append(
                    f"explicit_reveal_representatives[{index}] has invalid catalog_version"
                )
            if row.get("catalog_section") not in {"position", "time"}:
                errors.append(
                    f"explicit_reveal_representatives[{index}] has invalid catalog_section"
                )
            expected_mode = (
                "source_absent_default_zero"
                if row.get("catalog_version") == "v1"
                else "vdf_stripped_default_zero"
            )
            if row.get("vdf_mode") != expected_mode:
                errors.append(
                    f"explicit_reveal_representatives[{index}] has invalid vdf_mode"
                )
            covered = row.get("covered_actions")
            if not isinstance(covered, list) or not covered or not all(
                isinstance(item, str) and item for item in covered
            ):
                errors.append(
                    f"explicit_reveal_representatives[{index}] requires covered_actions"
                )
            else:
                positive_coverage.update(covered)
                all_coverage.update(covered)
                if row.get("destination_count") != len(covered):
                    errors.append(
                        f"explicit_reveal_representatives[{index}] destination_count mismatch"
                    )
                if row.get("representative_action") not in covered:
                    errors.append(
                        f"explicit_reveal_representatives[{index}] representative is not covered"
                    )
                prefix = row.get("action_prefix")
                if not isinstance(prefix, str) or not str(
                    row.get("representative_action", "")
                ).startswith(prefix):
                    errors.append(
                        f"explicit_reveal_representatives[{index}] action prefix mismatch"
                    )
            if row.get("state_pressure_decoy_fixture") in {
                row.get("fixture"),
                row.get("ship_fixture"),
            }:
                errors.append(
                    f"explicit_reveal_representatives[{index}] decoy must be unrelated"
                )
    missing_all = sorted(set(required) - all_coverage)
    missing_positive = sorted(set(required) - positive_coverage)
    if missing_all:
        errors.append(f"required actions absent from all scenarios: {missing_all}")
    if missing_positive:
        errors.append(
            f"required actions lack a positive lifecycle scenario: {missing_positive}"
        )
    if any(selection_gates.values()):
        expected_selection = {
            ("survey_profile", code, minimum)
            for code, minimum in enumerate(
                (4, 8, 32, 128, 256), start=1
            )
        } | {
            ("civilization_type", code, minimum)
            for code, minimum in enumerate(
                (64, 1_024, 16_384), start=1
            )
        }
        for kind in ("positive", "negative"):
            observed = {
                (
                    row.get("selection_kind"),
                    row.get("selected_code"),
                    row.get("minimum_inclusive"),
                )
                for row in selection_gates[kind]
            }
            if observed != expected_selection or len(selection_gates[kind]) != 8:
                errors.append(f"{kind} selection_gate census changed")
    if any(capacity_gates.values()):
        catalog_minima = {
            "v1.position": {10: 18_000, 3: 9_001, 1: 9_000},
            "v1.time": {10: 18_000, 3: 9_001, 1: 9_000},
            "v2.position": {10: 40_000, 3: 31_000, 1: 9_000},
            "v2.time": {10: 40_000, 3: 31_000, 1: 9_000},
        }
        expected_at_min = {
            (catalog_name, code, minima[uses])
            for catalog_name, minima in catalog_minima.items()
            for code, uses in ((1, 10), (2, 3), (5, 1))
        }
        expected_high_lower = {
            (catalog_name, code, minima[10])
            for catalog_name, minima in catalog_minima.items()
            for code in (2, 5)
        }
        observed_positive = {
            (
                row.get("catalog"),
                row.get("destination_code"),
                row.get("fixture_source_pool_before"),
            )
            for row in capacity_gates["positive"]
        }
        observed_negative = {
            (
                row.get("catalog"),
                row.get("destination_code"),
                row.get("fixture_source_pool_before"),
            )
            for row in capacity_gates["negative"]
        }
        expected_negative = {
            (catalog_name, code, minima[uses] - 1)
            for catalog_name, minima in catalog_minima.items()
            for code, uses in ((1, 10), (2, 3), (5, 1))
        }
        if (
            len(capacity_gates["positive"]) != 20
            or observed_positive != expected_at_min | expected_high_lower
        ):
            errors.append("positive capacity_gate census changed")
        if (
            len(capacity_gates["negative"]) != 12
            or observed_negative != expected_negative
        ):
            errors.append("negative capacity_gate census changed")
    return errors


def audit_test_package(
    test_root: Path,
    contract: Mapping[str, Any],
    production_root: Path = ROOT,
) -> list[str]:
    errors: list[str] = []
    for relative in (
        "plugin.rhai",
        "manifest.toml",
        "generated/source-parity.json",
        "generated/fixture-catalog.json",
    ):
        if not (test_root / relative).exists():
            errors.append(f"test package missing {relative}")
    if contract.get("explicit_reveal_representatives") and not (
        test_root / "generated" / "warp-coordinate-contract.json"
    ).exists():
        errors.append(
            "explicit reveal representatives require warp-coordinate-contract.json"
        )
    plugin_path = test_root / "plugin.rhai"
    manifest_path = test_root / "manifest.toml"
    plugin_source = (
        plugin_path.read_text(encoding="utf-8") if plugin_path.exists() else ""
    )
    manifest_source = (
        manifest_path.read_text(encoding="utf-8") if manifest_path.exists() else ""
    )
    production_plugin_path = production_root / "plugin.rhai"
    production_manifest_path = production_root / "manifest.toml"
    production_plugin = (
        production_plugin_path.read_text(encoding="utf-8")
        if production_plugin_path.exists()
        else ""
    )
    production_manifest = (
        production_manifest_path.read_text(encoding="utf-8")
        if production_manifest_path.exists()
        else ""
    )
    if not production_plugin:
        errors.append(f"missing production plugin source: {production_plugin_path}")
    if not production_manifest:
        errors.append(f"missing production manifest source: {production_manifest_path}")
    functions = validator.extract_rhai_functions(plugin_source)
    production_functions = validator.extract_rhai_functions(production_plugin)
    manifest_actions = set(validator.manifest_action_names(manifest_source))
    production_action_names = set(validator.manifest_action_names(production_manifest))
    if len(plugin_source.encode("utf-8")) > 990_000:
        errors.append("test plugin exceeds the 990,000-byte safety limit")
    if not re.search(
        r'(?m)^name\s*=\s*"microverse-expansion-test-only-[^"]+"\s*$',
        manifest_source,
    ):
        errors.append("test manifest must use an isolated test-only package name")
    if not re.search(
        r'(?m)^module_hash\s*=\s*"0{64}"\s*$',
        manifest_source,
    ):
        errors.append("test manifest module_hash must be cleared")

    parity_path = test_root / "generated" / "source-parity.json"
    production_action_symbols: set[str] = set()
    parity_symbols: set[str] = set()
    parity_helper_symbols: set[str] = set()
    parity_removed_total = 0
    expected_binding_symbols: set[str] = set()
    if parity_path.exists():
        parity = load_json(parity_path)
        strict_parity = (
            isinstance(parity, Mapping) and parity.get("schema_version") == 2
        )
        rows = parity.get("actions") if isinstance(parity, Mapping) else None
        if not isinstance(rows, list) or not rows:
            errors.append("source-parity.json must enumerate retained actions")
        else:
            for row in rows:
                if not isinstance(row, Mapping):
                    errors.append("source parity row must be an object")
                    continue
                symbol = row.get("symbol", row.get("action"))
                kind = row.get("kind", "production_action")
                if not isinstance(symbol, str) or not symbol:
                    errors.append(f"source parity row lacks a symbol: {row!r}")
                    continue
                if symbol in parity_symbols:
                    errors.append(f"duplicate source parity symbol {symbol}")
                parity_symbols.add(symbol)
                if kind not in {"production_action", "production_helper"}:
                    errors.append(f"invalid source parity kind for {symbol}: {kind!r}")
                if kind == "production_action":
                    production_action_symbols.add(symbol)
                elif kind == "production_helper":
                    parity_helper_symbols.add(symbol)
                function = functions.get(symbol)
                if function is None:
                    errors.append(f"source parity symbol is absent from plugin: {symbol}")
                else:
                    actual_hash = hashlib.sha256(function.encode("utf-8")).hexdigest()
                    if row.get("test_sha256") != actual_hash:
                        errors.append(f"test source hash mismatch for {symbol}")
                production_hash = row.get("production_sha256")
                if not isinstance(production_hash, str) or not re.fullmatch(
                    r"[0-9a-f]{64}", production_hash
                ):
                    errors.append(f"invalid production source hash for {symbol}")
                else:
                    production_function = production_functions.get(symbol)
                    if production_function is None:
                        errors.append(
                            f"source parity symbol is absent from production: {symbol}"
                        )
                    elif sha256_text(production_function) != production_hash:
                        errors.append(
                            f"production source hash mismatch for {symbol}"
                        )
                    else:
                        try:
                            expected_test, expected_removed = exact_vdf_transform(
                                production_function
                            )
                        except RuntimeError as error:
                            errors.append(f"{symbol}: {error}")
                        else:
                            if function != expected_test:
                                errors.append(
                                    f"{symbol} differs by more than the exact VDF pair"
                                )
                            if row.get("vdf_blocks_removed") != expected_removed:
                                errors.append(
                                    f"VDF removal count mismatch for {symbol}"
                                )
                if row.get("only_approved_transform") is not True:
                    errors.append(
                        f"unapproved source transform for {symbol!r}"
                    )
                removed = row.get("vdf_blocks_removed")
                if not isinstance(removed, int) or removed < 0:
                    errors.append(
                        f"invalid VDF removal count for {symbol!r}"
                    )
                if strict_parity and kind in {"production_action", "production_helper"}:
                    production_function = production_functions.get(symbol)
                    if production_function is not None:
                        expected_roles = source_role_rows(production_function)
                        if kind == "production_helper" and expected_roles:
                            errors.append(f"production helper has direct roles: {symbol}")
                        if row.get("direct_roles") != expected_roles:
                            errors.append(f"direct role contract mismatch for {symbol}")
                        expected_outputs = [
                            role
                            for role in expected_roles
                            if role["output_ordinal"] is not None
                        ]
                        if row.get("outputs") != expected_outputs:
                            errors.append(f"output role contract mismatch for {symbol}")
                        expected_direct = source_direct_helpers(
                            symbol, production_functions, production_action_names
                        )
                        if row.get("direct_helpers") != expected_direct:
                            errors.append(f"direct helper contract mismatch for {symbol}")
                        try:
                            expected_closure, expected_paths = source_helper_paths(
                                symbol,
                                production_functions,
                                functions,
                                production_action_names,
                            )
                        except RuntimeError as error:
                            errors.append(f"{symbol}: {error}")
                        else:
                            expected_binding_symbols.update(expected_closure)
                            if kind == "production_helper":
                                expected_binding_symbols.add(symbol)
                            if row.get("transitive_helper_closure") != expected_closure:
                                errors.append(
                                    f"transitive helper closure mismatch for {symbol}"
                                )
                            if row.get("helper_call_paths") != expected_paths:
                                errors.append(f"helper call paths mismatch for {symbol}")
                if isinstance(removed, int) and removed >= 0:
                    parity_removed_total += removed
        expected_action_count = contract.get("retained_production_action_count")
        if expected_action_count != len(production_action_symbols):
            errors.append(
                "source parity production-action count mismatch: "
                f"expected {expected_action_count!r}, got {len(production_action_symbols)}"
            )
        if strict_parity:
            if parity.get("production_action_row_count") != len(
                production_action_symbols
            ):
                errors.append("source parity production_action_row_count mismatch")
            helper_count = len(parity_helper_symbols)
            if parity.get("vdf_helper_row_count") != helper_count:
                errors.append("source parity vdf_helper_row_count mismatch")
            if parity.get("vdf_helper_symbols") != sorted(parity_helper_symbols):
                errors.append("source parity vdf_helper_symbols mismatch")
            helper_symbols_sha256 = hashlib.sha256(
                ("\n".join(sorted(parity_helper_symbols)) + "\n").encode("utf-8")
            ).hexdigest()
            if parity.get("vdf_helper_symbols_sha256") != helper_symbols_sha256:
                errors.append("source parity vdf_helper_symbols_sha256 mismatch")
            if parity.get("vdf_blocks_removed") != parity_removed_total:
                errors.append("source parity vdf_blocks_removed mismatch")
            if parity.get("parity_row_count") != len(parity_symbols):
                errors.append("source parity parity_row_count mismatch")
            if parity.get("tree_action_count") != contract.get("tree_action_count"):
                errors.append("source parity tree_action_count mismatch")
            if parity.get("setup_action_count") != contract.get("setup_action_count"):
                errors.append("source parity setup_action_count mismatch")
            retained_helpers = {
                name
                for name in production_functions
                if name not in production_action_names
            }
            missing_helpers = retained_helpers - set(functions)
            if missing_helpers:
                errors.append(
                    "test source omits production helpers: "
                    f"{sorted(missing_helpers)}"
                )
            transformed_unlisted_helpers: set[str] = set()
            for helper in retained_helpers & set(functions):
                try:
                    expected_test, _expected_removed = exact_vdf_transform(
                        production_functions[helper]
                    )
                except RuntimeError as error:
                    errors.append(f"{helper}: {error}")
                    continue
                if functions[helper] != expected_test:
                    errors.append(
                        f"production helper differs by more than the exact VDF pair: {helper}"
                    )
                if (
                    production_functions[helper].count("action.intro_vdf(")
                    and helper not in parity_helper_symbols
                ):
                    transformed_unlisted_helpers.add(helper)
            if transformed_unlisted_helpers:
                errors.append(
                    "transformed production helpers are absent from source parity: "
                    f"{sorted(transformed_unlisted_helpers)}"
                )
            helper_bindings = parity.get("helper_bindings")
            if not isinstance(helper_bindings, list):
                errors.append("source parity helper_bindings must be a list")
            else:
                binding_symbols: set[str] = set()
                binding_removed_total = 0
                for binding in helper_bindings:
                    if not isinstance(binding, Mapping):
                        errors.append("invalid helper binding row")
                        continue
                    helper = binding.get("symbol")
                    if not isinstance(helper, str) or helper not in production_functions:
                        errors.append(f"invalid helper binding symbol {helper!r}")
                        continue
                    if helper not in functions:
                        errors.append(f"helper binding absent from test plugin: {helper}")
                        continue
                    if helper in binding_symbols:
                        errors.append(f"duplicate helper binding symbol {helper}")
                    binding_symbols.add(helper)
                    if binding.get("production_sha256") != sha256_text(
                        production_functions[helper]
                    ):
                        errors.append(f"helper production hash mismatch for {helper}")
                    if binding.get("test_sha256") != sha256_text(functions[helper]):
                        errors.append(f"helper test hash mismatch for {helper}")
                    expected_direct = source_direct_helpers(
                        helper, production_functions, production_action_names
                    )
                    if binding.get("direct_helpers") != expected_direct:
                        errors.append(f"helper direct call mismatch for {helper}")
                    try:
                        _expected_test, expected_removed = exact_vdf_transform(
                            production_functions[helper]
                        )
                    except RuntimeError as error:
                        errors.append(f"{helper}: {error}")
                    else:
                        if functions[helper] != _expected_test:
                            errors.append(
                                f"helper differs by more than the exact VDF pair: {helper}"
                            )
                        if binding.get("vdf_blocks_removed") != expected_removed:
                            errors.append(f"helper VDF removal count mismatch for {helper}")
                        binding_removed_total += expected_removed
                if binding_symbols != expected_binding_symbols:
                    errors.append(
                        "source parity helper_bindings completeness mismatch: "
                        f"missing={sorted(expected_binding_symbols-binding_symbols)}, "
                        f"extra={sorted(binding_symbols-expected_binding_symbols)}"
                    )
                if binding_removed_total != sum(
                    binding.get("vdf_blocks_removed", 0)
                    for binding in helper_bindings
                    if isinstance(binding, Mapping)
                    and isinstance(binding.get("vdf_blocks_removed"), int)
                ):
                    errors.append("source parity helper_bindings VDF count mismatch")
            if parity_helper_symbols != APPROVED_TEST_VDF_HELPERS:
                errors.append("source parity VDF-helper inventory mismatch")
            if helper_count != APPROVED_TEST_VDF_HELPER_COUNT:
                errors.append("source parity VDF-helper count mismatch")
            if helper_symbols_sha256 != APPROVED_TEST_VDF_HELPERS_SHA256:
                errors.append("source parity VDF-helper inventory hash mismatch")
            static_audit_path = test_root / "generated" / "static-audit.json"
            if not static_audit_path.exists():
                errors.append("strict source parity requires static-audit.json")
            else:
                static_audit = load_json(static_audit_path)
                if not isinstance(static_audit, Mapping):
                    errors.append("static-audit.json must be an object")
                elif (
                    static_audit.get("source_parity_helper_count") != helper_count
                    or static_audit.get("source_parity_vdf_helper_symbols")
                    != sorted(parity_helper_symbols)
                    or static_audit.get("source_parity_vdf_helper_symbols_sha256")
                    != helper_symbols_sha256
                    or static_audit.get("source_parity_vdf_blocks_removed")
                    != parity_removed_total
                ):
                    errors.append("static audit source-parity helper metadata mismatch")
    fixtures_path = test_root / "generated" / "fixture-catalog.json"
    fixture_symbols: set[str] = set()
    if fixtures_path.exists():
        fixtures = load_json(fixtures_path)
        strict_fixtures = (
            isinstance(fixtures, Mapping) and fixtures.get("schema_version") == 2
        )
        schema_sidecar_path = production_root / "generated" / "schema-counts.json"
        schema_sidecar = (
            load_json(schema_sidecar_path) if schema_sidecar_path.exists() else {}
        )
        schema_classes = (
            schema_sidecar.get("classes")
            if isinstance(schema_sidecar, Mapping)
            else None
        )
        if strict_fixtures and isinstance(schema_classes, Mapping):
            for schema_class_name, schema_class_row in schema_classes.items():
                if not isinstance(schema_class_row, Mapping):
                    errors.append(
                        f"invalid schema sidecar row for {schema_class_name}"
                    )
                    continue
                sdk_live = schema_class_row.get("sdk_managed_live_fields")
                field_types = {
                    str(field.get("name")): str(field.get("type"))
                    for field in schema_class_row.get("fields", [])
                    if isinstance(field, Mapping)
                }
                if not isinstance(sdk_live, list) or set(map(str, sdk_live)) != {
                    "type",
                    "work",
                }:
                    errors.append(
                        f"schema {schema_class_name} lacks exact SDK live fields"
                    )
                for runtime_raw in ("key", "stable_identifier"):
                    if field_types.get(runtime_raw) != "Raw":
                        errors.append(
                            f"schema {schema_class_name}.{runtime_raw} is not Raw"
                        )
        rows = fixtures.get("fixtures") if isinstance(fixtures, Mapping) else None
        if not isinstance(rows, list) or not rows:
            errors.append("fixture-catalog.json must enumerate test-only fixtures")
        else:
            for row in rows:
                if not isinstance(row, Mapping) or row.get("output_only") is not True:
                    errors.append(
                        f"fixture must be explicitly output_only: {row!r}"
                    )
                    continue
                action = row.get("action")
                if not isinstance(action, str) or not action:
                    errors.append(f"fixture lacks an action name: {row!r}")
                    continue
                if action in fixture_symbols:
                    errors.append(f"duplicate fixture action {action}")
                fixture_symbols.add(action)
                if action not in functions:
                    errors.append(f"fixture action is absent from plugin: {action}")
                    continue
                fixture_source = functions[action]
                roles = source_role_rows(fixture_source)
                if strict_fixtures and row.get("direct_roles") != roles:
                    errors.append(f"fixture direct roles mismatch for {action}")
                if strict_fixtures and (
                    len(roles) != 1 or roles[0]["mode"] != "output"
                ):
                    errors.append(f"fixture {action} must have exactly one output role")
                class_name = row.get("class")
                class_row = (
                    schema_classes.get(class_name)
                    if isinstance(schema_classes, Mapping)
                    else None
                )
                expected_types = {
                    str(field["name"]): str(field["type"])
                    for field in (
                        class_row.get("fields", [])
                        if isinstance(class_row, Mapping)
                        else []
                    )
                    if isinstance(field, Mapping)
                }
                if strict_fixtures and row.get("field_types") != expected_types:
                    errors.append(f"fixture field_types mismatch for {action}")
                if strict_fixtures and isinstance(class_row, Mapping):
                    try:
                        reconstructed_schema = fixture_source_schema_contract(
                            action,
                            str(class_name),
                            fixture_source,
                            class_row,
                        )
                    except RuntimeError as error:
                        errors.append(str(error))
                    else:
                        if row.get("schema_completeness") != reconstructed_schema:
                            errors.append(
                                f"fixture schema_completeness mismatch for {action}"
                            )
                expected_literals = {
                    field: int(value)
                    for field, value in re.findall(
                        r'\[\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*,\s*'
                        r"(-?[0-9]+)\s*\]",
                        fixture_source,
                    )
                }
                if strict_fixtures and row.get("literal_fields") != expected_literals:
                    errors.append(f"fixture literal_fields mismatch for {action}")
                if strict_fixtures and class_name in {
                    "MicroversePositionAnchor",
                    "MicroverseTimeAnchor",
                }:
                    if expected_types.get("source_ship_id") != "Raw":
                        errors.append(f"fixture {action} source_ship_id is not Raw")
                    raw_relations = row.get("raw_relations")
                    source_relation = next(
                        (
                            relation
                            for relation in raw_relations
                            if isinstance(relation, Mapping)
                            and relation.get("field") == "source_ship_id"
                        ),
                        None,
                    ) if isinstance(raw_relations, list) else None
                    if (
                        not isinstance(source_relation, Mapping)
                        or source_relation.get("field_type") != "Raw"
                        or source_relation.get("variable") != "raw_a"
                        or "var raw_a = action.random();" not in fixture_source
                    ):
                        errors.append(
                            f"fixture {action} lacks its Raw source_ship_id relation"
                        )
        runtime_relations = (
            fixtures.get("runtime_output_relations")
            if isinstance(fixtures, Mapping)
            else None
        )
        if strict_fixtures and contract.get("tree_action_count"):
            relation_targets = {
                row.get("target_action")
                for row in runtime_relations
                if isinstance(row, Mapping)
            } if isinstance(runtime_relations, list) else set()
            if not {"CapturePositionAnchor", "CaptureTimeAnchor"}.issubset(
                relation_targets
            ):
                errors.append(
                    "warp fixture catalog must bind both capture Raw output relations"
                )
    if manifest_actions != production_action_symbols | fixture_symbols:
        errors.append(
            "test manifest action set differs from audited production/fixture symbols"
        )
    production_hash = contract.get("production_module_hash")
    if not isinstance(production_hash, str) or not re.fullmatch(
        r"[0-9a-f]{64}", production_hash
    ):
        errors.append("contract must bind a 64-hex production_module_hash")
    expected_plugin_hash = contract.get("production_plugin_sha256")
    if expected_plugin_hash != sha256_text(production_plugin):
        errors.append("contract production_plugin_sha256 does not match production")
    expected_manifest_hash = contract.get("production_manifest_sha256")
    if expected_manifest_hash != sha256_text(production_manifest):
        errors.append("contract production_manifest_sha256 does not match production")
    binding_paths = {
        "production_plugin_sha256": production_plugin_path,
        "production_manifest_sha256": production_manifest_path,
        "production_warp_catalog_sha256": (
            production_root / "catalog" / "microverse-warp-tree-v2.json"
        ),
        "production_catalog_index_sha256": (
            production_root / "catalog" / "microverse-catalog-index-v2.json"
        ),
        "production_schema_counts_sha256": (
            production_root / "generated" / "schema-counts.json"
        ),
    }
    if isinstance(contract.get("hash_bindings"), Mapping):
        for key, path in binding_paths.items():
            if not path.exists():
                errors.append(f"missing hash-bound production input {path}")
                continue
            actual = hashlib.sha256(path.read_bytes()).hexdigest()
            if contract.get(key) != actual:
                errors.append(f"contract {key} does not match production")
            for sidecar_name in (
                "source-parity.json",
                "fixture-catalog.json",
            ):
                sidecar_path = test_root / "generated" / sidecar_name
                if sidecar_path.exists():
                    sidecar = load_json(sidecar_path)
                    if not isinstance(sidecar, Mapping) or sidecar.get(key) != actual:
                        errors.append(f"{sidecar_name} {key} does not match production")
    if contract.get("tree_action_count"):
        tree_actions = contract.get("tree_actions")
        setup_actions = contract.get("setup_actions")
        selection_actions = contract.get("selection_milestone_actions")
        if not isinstance(tree_actions, list) or len(tree_actions) != 622:
            errors.append("warp tree_actions must enumerate exactly 622 actions")
        if setup_actions != ["UseTechnologySkill"]:
            errors.append("warp setup_actions must be exactly UseTechnologySkill")
        if not isinstance(selection_actions, list) or len(selection_actions) != 8:
            errors.append(
                "warp selection_milestone_actions must enumerate exactly 8 actions"
            )
        if contract.get("tree_action_count") != 622:
            errors.append("warp tree_action_count must be 622")
        if contract.get("setup_action_count") != 1:
            errors.append("warp setup_action_count must be 1")
        if contract.get("selection_milestone_action_count") != 8:
            errors.append("warp selection_milestone_action_count must be 8")
        if (
            set(tree_actions or [])
            | set(setup_actions or [])
            | set(selection_actions or [])
            != production_action_symbols
        ):
            errors.append(
                "warp tree/setup/selection sets differ from production parity actions"
            )
    if (
        isinstance(contract.get("hash_bindings"), Mapping)
        and (b"\r" in plugin_path.read_bytes() or b"\r" in manifest_path.read_bytes())
    ):
        errors.append("test plugin/manifest must be exact LF bytes")
    return errors


def run_sequence(
    harness: Path,
    test_root: Path,
    scenario: Mapping[str, Any],
    report_dir: Path,
    *,
    real: bool,
    negative: bool,
    retain_raw_report: bool = False,
) -> dict[str, Any]:
    name = str(scenario["name"])
    report_path = report_dir / f"{name}.json"
    command = [
        str(harness),
        "sequence",
        str(test_root),
        *[str(item) for item in scenario["actions"]],
    ]
    if real:
        command.append("--target-real")
    command.extend(["--output", str(report_path)])
    process = run_command(command, cwd=ROOT)
    combined = (
        str(process.get("stdout_tail", ""))
        + "\n"
        + str(process.get("stderr_tail", ""))
    ).lower()
    report: Any = None
    if report_path.exists():
        try:
            report = load_json(report_path)
        except (OSError, json.JSONDecodeError) as error:
            report = {"status": "unreadable", "error": str(error)}
    if negative:
        # Some harness failures are reported only in the structured report,
        # rather than echoed to stdout/stderr.  Include that evidence when
        # checking that the intended predicate/constraint rejected the case.
        if report is not None:
            combined += "\n" + json.dumps(report, sort_keys=True).lower()
        tokens = [
            str(item).lower()
            for item in scenario.get("expected_error_contains", [])
        ]
        rejected = process.get("exit_code") != 0 or (
            isinstance(report, Mapping) and report.get("status") == "fail"
        )
        token_observed = any(token in combined for token in tokens)
        status = "pass" if rejected and token_observed else "fail"
    else:
        report_pass = report is None or (
            isinstance(report, Mapping) and report.get("status") == "pass"
        )
        status = (
            "pass"
            if process.get("exit_code") == 0 and report_pass
            else "fail"
        )
    result = {
        "name": name,
        "kind": "negative" if negative else "positive",
        "proof_mode": "local-real" if real else "mock",
        "actions": scenario["actions"],
        "covers": scenario.get("covers", []),
        "status": status,
        "process": process,
        "report": summarize_harness_report(report),
    }
    if retain_raw_report:
        result["_raw_report"] = report
    return result


def run_explicit_reveal_representative(
    harness: Path,
    test_root: Path,
    scenario: Mapping[str, Any],
    report_dir: Path,
    *,
    real: bool,
) -> dict[str, Any]:
    reveal_actions = [str(scenario["state_pressure_decoy_fixture"])]
    if scenario.get("ship_fixture_required_by_target") is not False:
        reveal_actions.append(str(scenario["ship_fixture"]))
    reveal_actions.extend(
        [
            str(scenario["fixture"]),
            str(scenario["representative_action"]),
        ]
    )
    reveal = {
        "name": str(scenario["name"]),
        "actions": reveal_actions,
        "covers": [str(scenario["representative_action"])],
    }
    result = run_sequence(
        harness,
        test_root,
        reveal,
        report_dir,
        real=real,
        negative=False,
    )
    result["kind"] = "explicit_reveal_representative"
    result["selection"] = {
        "selection_mode": "explicit_action_identity",
        "stable_identifier_used": False,
        "action": str(scenario["representative_action"]),
        "catalog_version": scenario["catalog_version"],
        "catalog_section": scenario["catalog_section"],
        "vdf_mode": scenario["vdf_mode"],
    }
    return result


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pexe", type=Path, default=DEFAULT_PEXE)
    parser.add_argument("--harness", type=Path, default=DEFAULT_HARNESS)
    parser.add_argument("--test-root", type=Path)
    parser.add_argument("--contract", type=Path)
    parser.add_argument("--skip-build-check", action="store_true")
    parser.add_argument(
        "--skip-production-build-check",
        action="store_true",
        help=(
            "skip only the production-root build/check; generated test shards "
            "are still built and checked"
        ),
    )
    parser.add_argument("--skip-unit-tests", action="store_true")
    parser.add_argument(
        "--real",
        action="store_true",
        help="locally prove scenarios marked real_sample; never submits them",
    )
    parser.add_argument(
        "--real-all",
        action="store_true",
        help=(
            "locally prove every positive/explicit-reveal scenario; rejection cases stay "
            "mock and nothing is submitted"
        ),
    )
    parser.add_argument(
        "--real-samples-only",
        action="store_true",
        help=(
            "execute only scenarios marked real_sample, using local real proofs; "
            "negative and other mock scenarios are skipped, never submitted"
        ),
    )
    parser.add_argument(
        "--output",
        type=Path,
        help="optional persistent result JSON; default is stdout only",
    )
    args = parser.parse_args(argv)
    if args.real_samples_only and (args.real or args.real_all):
        parser.error(
            "--real-samples-only cannot be combined with --real or --real-all"
        )

    setup: list[dict[str, Any]] = []
    pexe = args.pexe.resolve()
    setup.append(
        run_command(
            [
                sys.executable,
                "-B",
                str(VALIDATOR),
                "--catalog-dir",
                str(ROOT / "catalog"),
                "--rhai",
                str(ROOT / "plugin.rhai"),
                "--manifest",
                str(ROOT / "manifest.toml"),
                "--json",
            ],
            cwd=ROOT,
        )
    )
    if not args.skip_unit_tests:
        setup.append(
            run_command(
                [
                    sys.executable,
                    "-B",
                    "-m",
                    "unittest",
                    "discover",
                    "-s",
                    str(ROOT / "tests"),
                    "-p",
                    "test_*.py",
                    "-v",
                ],
                cwd=ROOT,
            )
        )
    if not args.skip_build_check and not args.skip_production_build_check:
        if not pexe.exists():
            setup.append(
                {
                    "command": [str(pexe), "build", str(ROOT), "--check"],
                    "cwd": str(ROOT),
                    "exit_code": 127,
                    "seconds": 0,
                    "stdout_tail": "",
                    "stderr_tail": f"missing stock PEXE CLI: {pexe}",
                }
            )
        else:
            setup.append(
                run_command(
                    [str(pexe), "build", str(ROOT), "--check"],
                    cwd=ROOT,
                )
            )

    contract_errors: list[str] = []
    scenarios: list[dict[str, Any]] = []
    contract_case_counts: Counter[str] = Counter()
    if args.test_root is not None:
        requested_root = args.test_root.resolve()
        shard_manifest = requested_root / "generated" / "shards.json"
        test_roots: list[Path] = []
        if shard_manifest.exists():
            if args.contract is not None:
                contract_errors.append(
                    "--contract cannot be combined with a generated multi-shard root"
                )
            loaded_shards = load_json(shard_manifest)
            rows = (
                loaded_shards.get("shards")
                if isinstance(loaded_shards, Mapping)
                else None
            )
            if not isinstance(rows, list) or not rows:
                contract_errors.append("shards.json must contain a nonempty shards list")
            else:
                for row in rows:
                    root_name = row.get("root") if isinstance(row, Mapping) else None
                    if not isinstance(root_name, str) or not root_name:
                        contract_errors.append(f"invalid shard row: {row!r}")
                    else:
                        test_roots.append(requested_root / root_name)
        else:
            test_roots = [requested_root]
        harness = args.harness.resolve()
        if not harness.exists():
            contract_errors.append(f"missing reachable-state harness: {harness}")
        contracts: list[tuple[Path, Mapping[str, Any]]] = []
        for test_root in test_roots:
            contract_path = (
                args.contract.resolve()
                if args.contract is not None
                else test_root / "generated" / "expansion-test-contract.json"
            )
            local_errors: list[str] = []
            contract: Mapping[str, Any] = {}
            if not contract_path.exists():
                local_errors.append(f"missing scenario contract: {contract_path}")
            else:
                loaded = load_json(contract_path)
                if not isinstance(loaded, Mapping):
                    local_errors.append("scenario contract root must be an object")
                else:
                    contract = loaded
                    local_errors.extend(validate_contract(contract))
                    local_errors.extend(audit_test_package(test_root, contract))
            contract_errors.extend(
                f"{test_root.name}: {error}" for error in local_errors
            )
            if not local_errors:
                contracts.append((test_root, contract))
                contract_case_counts["positive"] += len(
                    contract.get("positive", [])
                )
                contract_case_counts["negative"] += len(
                    contract.get("negative", [])
                )
                contract_case_counts[
                    "explicit_reveal_representative"
                ] += len(
                    contract.get("explicit_reveal_representatives", [])
                )
                if not args.skip_build_check and pexe.exists():
                    setup.append(build_check_isolated_copy(pexe, test_root))
        if not contract_errors and harness.exists():
            # Harness reports live in a temporary directory unless a persistent
            # summary was explicitly requested.
            with tempfile.TemporaryDirectory(prefix="microverse-expansion-tests-") as directory:
                report_dir = Path(directory)
                for test_root, contract in contracts:
                    for scenario in contract.get("positive", []):
                        if (
                            args.real_samples_only
                            and scenario.get("real_sample") is not True
                        ):
                            continue
                        real = args.real_all or args.real_samples_only or (
                            args.real and scenario.get("real_sample") is True
                        )
                        scenarios.append(
                            run_sequence(
                                harness,
                                test_root,
                                scenario,
                                report_dir,
                                real=real,
                                negative=False,
                            )
                        )
                        if len(scenarios) % 50 == 0:
                            print(
                                f"executed {len(scenarios)} scenarios",
                                file=sys.stderr,
                            )
                    if not args.real_samples_only:
                        for scenario in contract.get("negative", []):
                            # Negative tests stay mock: their purpose is rejection,
                            # not generation of a valid real proof.
                            scenarios.append(
                                run_sequence(
                                    harness,
                                    test_root,
                                    scenario,
                                    report_dir,
                                    real=False,
                                    negative=True,
                                )
                            )
                            if len(scenarios) % 50 == 0:
                                print(
                                    f"executed {len(scenarios)} scenarios",
                                    file=sys.stderr,
                                )
                    for scenario in contract.get(
                        "explicit_reveal_representatives", []
                    ):
                        if (
                            args.real_samples_only
                            and scenario.get("real_sample") is not True
                        ):
                            continue
                        real = args.real_all or args.real_samples_only or (
                            args.real and scenario.get("real_sample") is True
                        )
                        scenarios.append(
                            run_explicit_reveal_representative(
                                harness,
                                test_root,
                                scenario,
                                report_dir,
                                real=real,
                            )
                        )

    failed_setup = [item for item in setup if item.get("exit_code") != 0]
    failed_scenarios = [
        item["name"] for item in scenarios if item["status"] != "pass"
    ]
    payload_rows = [
        (
            int(item["report"]["worst_payload_bytes"]),
            item["name"],
            item["proof_mode"],
        )
        for item in scenarios
        if isinstance(item.get("report"), Mapping)
        and isinstance(item["report"].get("worst_payload_bytes"), int)
    ]
    worst_payload = max(payload_rows, default=None)
    proof_mode_counts: dict[str, int] = {}
    for item in scenarios:
        mode = str(item.get("proof_mode", "unknown"))
        proof_mode_counts[mode] = proof_mode_counts.get(mode, 0) + 1
    executed_kind_counts = Counter(str(item.get("kind", "unknown")) for item in scenarios)
    executed_status_counts = Counter(
        str(item.get("status", "unknown")) for item in scenarios
    )
    result = {
        "status": (
            "pass"
            if not failed_setup and not contract_errors and not failed_scenarios
            else "fail"
        ),
        "proof_policy": {
            "default": "mock",
            "local_real_requested": bool(
                args.real or args.real_all or args.real_samples_only
            ),
            "real_samples_only": bool(args.real_samples_only),
            "submissions_supported": False,
            "submission_attempts": 0,
        },
        "setup": setup,
        "contract_errors": contract_errors,
        "scenario_count": len(scenarios),
        "contract_case_counts": dict(contract_case_counts),
        "executed_kind_counts": dict(executed_kind_counts),
        "executed_status_counts": dict(executed_status_counts),
        "proof_mode_counts": proof_mode_counts,
        "worst_payload": (
            {
                "bytes": worst_payload[0],
                "scenario": worst_payload[1],
                "proof_mode": worst_payload[2],
            }
            if worst_payload is not None
            else None
        ),
        "failed_scenarios": failed_scenarios,
        "scenarios": scenarios,
    }
    rendered = stable_json(result)
    if args.output is not None:
        output = args.output.resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(rendered, encoding="utf-8")
        concise = {
            key: value
            for key, value in result.items()
            if key not in {"setup", "scenarios"}
        }
        print(stable_json(concise), end="")
    else:
        print(rendered, end="")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
