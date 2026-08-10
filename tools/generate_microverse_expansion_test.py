#!/usr/bin/env python3
"""Generate a VDF-free, production-source-driven expansion test package.

This generator never edits production source or the SDK.  It copies the real
``plugin.rhai`` and manifest into an isolated package, removes only audited
two-statement VDF work blocks, and appends output-only ``TestMintExpansion...``
fixture actions.  Generated objects are intentionally incompatible with the
production PEXE because the test manifest uses a distinct package identity.

The executable matrix is derived from the canonical resource, component,
skill, warp, and generated-index catalogs.  It covers every expanded source
extraction, refinement, component, and skill-development action with positive
and negative cases, plus extraction-to-refinement and consumable-warp chains.
The generated direct-plan inventory covers every real production action.
"""

from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import shutil
from typing import Any, Mapping, Sequence

import validate_expansion_catalogs as validator


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "target" / "microverse-expansion-test"
TEST_PACKAGE_NAME = "microverse-expansion-test-only"
ZERO_HASH = "0" * 64
COORD_ZERO = 1_000_000_000_000
# Test-only locations deliberately avoid equal-value coincidences.  Every
# location has pairwise-distinct axes and a nonzero epoch; A/B are also the
# exact directional endpoints used by the link fixtures below.
FIXTURE_LOCATIONS: dict[int, tuple[int, int, int, int]] = {
    0: (COORD_ZERO + 101, COORD_ZERO + 211, COORD_ZERO + 307, 1009),
    1: (COORD_ZERO + 401, COORD_ZERO + 503, COORD_ZERO + 601, 2011),
    2: (COORD_ZERO + 701, COORD_ZERO + 809, COORD_ZERO + 907, 3011),
}
SHIP_COUNTERS = {
    "action_serial": 101,
    "claim_serial": 211,
    "discovery_serial": 307,
    "satellite_serial": 401,
    "civilization_scan_serial": 503,
}
EXPLICIT_SELECTION_MODE = "explicit_action_identity"
SURVEY_SELECTION_MILESTONES: tuple[tuple[str, int, int], ...] = (
    ("SurveySector_01_Sparse", 1, 4),
    ("SurveySector_02_Standard", 2, 8),
    ("SurveySector_03_Rich", 3, 32),
    ("SurveySector_04_Ancient", 4, 128),
    ("SurveySector_05_Anomalous", 5, 256),
)
CIVILIZATION_SELECTION_MILESTONES: tuple[tuple[str, int, int], ...] = (
    ("MaterializeCivilizationTypeI", 1, 64),
    ("MaterializeCivilizationTypeII", 2, 1_024),
    ("MaterializeCivilizationTypeIII", 3, 16_384),
)
SELECTION_MILESTONE_ACTIONS = {
    action
    for action, _selected_code, _minimum in (
        *SURVEY_SELECTION_MILESTONES,
        *CIVILIZATION_SELECTION_MILESTONES,
    )
}
CAPACITY_MINIMUMS: dict[str, dict[int, int]] = {
    "v1": {10: 18_000, 3: 9_001, 1: 9_000},
    "v2": {10: 40_000, 3: 31_000, 1: 9_000},
}
DIRECT_POSITION_DESTINATION = (
    COORD_ZERO + 1103,
    COORD_ZERO + 1201,
    COORD_ZERO + 1301,
)
DIRECT_TIME_DESTINATION = 4001
SHIP_TIERS = {
    "Small": (10, 1),
    "Medium": (50, 5),
    "Large": (250, 25),
}
SHAPE_J_CONSTRUCTOR_ROLE_CONTRACTS: dict[str, tuple[tuple[str, str], ...]] = {
    "ConstructWormholeLink": (
        ("output", "MicroverseWormholeLink"),
        ("input", "MicroversePositionAnchor"),
        ("input", "MicroversePositionAnchor"),
        ("input", "MicroverseResource"),
        ("input", "MicroverseResource"),
        ("mutate", "MicroverseShip"),
    ),
    "ConstructTemporalLink": (
        ("output", "MicroverseTemporalLink"),
        ("input", "MicroverseTimeAnchor"),
        ("input", "MicroverseTimeAnchor"),
        ("input", "MicroverseResource"),
        ("input", "MicroverseResource"),
        ("mutate", "MicroverseShip"),
    ),
    "ComposeRendezvousCoordinate": (
        ("output", "MicroverseRendezvousCoordinate"),
        ("input", "MicroversePositionAnchor"),
        ("input", "MicroverseTimeAnchor"),
        ("input", "MicroverseResource"),
        ("input", "MicroverseResource"),
        ("mutate", "MicroverseShip"),
    ),
}
FINAL_PRODUCTION_HASHES = {
    "production_plugin_sha256": "d96fc8c22480f88375b49752cee2de86b7723c413719be6b00fa6d3b38b65236",
    "production_manifest_sha256": "b019a23bdaea44fbdc14515e4e3ac590cccf18f1b83b2a5c73e7d840b3b18181",
    "production_module_hash": "92b83e13252fff2cd258d6de0b36b922e7e064185b6bc698fdd923496e48e02f",
    "production_warp_catalog_sha256": "25a045616fbe4921fb667f31568ae287c6576b0de23a56e03c8953f28c2f0cdb",
    "production_catalog_index_sha256": "8ceffab36fae6a97e0bca45bcf4c132c4542c36f4547a22da48d498515825470",
    "production_schema_counts_sha256": "c2a845287737c3df45eb6784d9e688898a4eaa1af4a7ec9a7d6a367526fb8a61",
    "production_universe_contract_sha256": "2981efd1147275b3e32bd59e6c944362b56e29a461e1be4b4392a9eeaa7777ef",
    "production_action_contract_sha256": "e4b63f1ef344da4df6b42cbaa833e6b6dc16a9d2413e88c9288905ce0b9ec628",
}

# The warp shard keeps every production helper because helper definitions are
# shared source, even when their action wrappers belong to another shard.
# Bind the VDF-owning helper set to the reviewed Phase 4--6 contracts plus the
# two chart-reveal cores so a newly introduced helper cannot be stripped
# without an explicit test-harness review.
WARP_SHARD_APPROVED_VDF_HELPERS = frozenset({
    *(name for name, _kind, _iterations, _representative in validator.PHASE4_ECONOMY_HELPERS),
    *validator.PHASE5_KNOWN_HELPER_NAMES,
    *validator.PHASE6_VDF_HELPERS.values(),
    "reveal_chart_p",
    "reveal_chart_t",
})
WARP_SHARD_APPROVED_VDF_HELPER_COUNT = 45
WARP_SHARD_APPROVED_VDF_HELPERS_SHA256 = (
    "b9d48dbac953fce8af5f0353cc456f499792740c6920dd6e124dbae2a62aad78"
)
assert len(WARP_SHARD_APPROVED_VDF_HELPERS) == WARP_SHARD_APPROVED_VDF_HELPER_COUNT
assert hashlib.sha256(
    ("\n".join(sorted(WARP_SHARD_APPROVED_VDF_HELPERS)) + "\n").encode("utf-8")
).hexdigest() == WARP_SHARD_APPROVED_VDF_HELPERS_SHA256

VDF_BLOCK = re.compile(
    r"\n(?P<indent>[ \t]*)var\s+"
    r"(?P<work>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
    r"action\.intro_vdf\(\s*(?P<iterations>[0-9]+)\s*,\s*"
    r"(?P<object>[A-Za-z_][A-Za-z0-9_]*)\s*\);\s*\r?\n"
    r"(?P=indent)(?P=object)\.update\(\"work\",\s*(?P=work)\);"
)


def stable_json(value: Any) -> str:
    return json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def write_utf8(path: Path, value: str) -> None:
    """Write deterministic LF bytes even when generation runs on Windows."""
    path.write_text(value, encoding="utf-8", newline="\n")


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def sha256_path(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def direct_role_contract(source: str) -> list[dict[str, Any]]:
    """Return 1-based source-order role references for an action wrapper."""

    matches = re.findall(
        r"\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
        r"action\.(output|input|mutate)\s*\(\s*\"([^\"]+)\"\s*\)",
        source,
    )
    class_occurrences: Counter[tuple[str, str]] = Counter()
    produced_ordinal = 0
    rows: list[dict[str, Any]] = []
    for ordinal, (variable, mode, class_name) in enumerate(matches, start=1):
        class_occurrences[(mode, class_name)] += 1
        output_ordinal: int | None = None
        if mode in {"output", "mutate"}:
            produced_ordinal += 1
            output_ordinal = produced_ordinal
        normalized_ref = f'{variable}=action.{mode}("{class_name}")'
        rows.append(
            {
                "ordinal": ordinal,
                "variable": variable,
                "mode": mode,
                "class": class_name,
                "class_occurrence": class_occurrences[(mode, class_name)],
                "output_ordinal": output_ordinal,
                "normalized_ref": normalized_ref,
                "normalized_ref_sha256": sha256_text(normalized_ref),
            }
        )
    return rows


def direct_helper_calls(
    function_name: str,
    functions: Mapping[str, str],
    action_names: set[str],
) -> list[str]:
    source = functions[function_name]
    body = source[source.find("{") + 1 :]
    calls = re.findall(
        r"(?<![.A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(",
        validator.strip_rhai_comments(body),
    )
    result: list[str] = []
    for call in calls:
        if call in functions and call not in action_names and call not in result:
            result.append(call)
    return result


def transitive_helper_contract(
    function_name: str,
    production_functions: Mapping[str, str],
    test_functions: Mapping[str, str],
    action_names: set[str],
) -> tuple[list[str], list[dict[str, Any]]]:
    """Describe every reachable plain helper and all acyclic call paths."""

    paths: list[tuple[str, ...]] = []

    def visit(name: str, path: tuple[str, ...]) -> None:
        for helper in direct_helper_calls(name, production_functions, action_names):
            next_path = (*path, helper)
            if helper in path:
                raise RuntimeError(
                    f"helper cycle while expanding {function_name}: {' -> '.join(next_path)}"
                )
            paths.append(next_path)
            visit(helper, next_path)

    visit(function_name, (function_name,))
    closure = sorted({path[-1] for path in paths})
    rows = [
        {
            "path": list(path),
            "helper": path[-1],
            "production_sha256": sha256_text(production_functions[path[-1]]),
            "test_sha256": sha256_text(test_functions[path[-1]]),
        }
        for path in paths
    ]
    return closure, rows


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def remove_vdf_blocks(source: str, label: str) -> tuple[str, int]:
    expected = source.count("action.intro_vdf(")
    transformed, removed = VDF_BLOCK.subn("", source)
    if removed != expected or "action.intro_vdf(" in transformed:
        raise RuntimeError(
            f"VDF transform mismatch for {label}: expected {expected}, "
            f"removed {removed}, remaining={transformed.count('action.intro_vdf(')}"
        )
    return transformed, removed


def production_source_subset(
    source: str,
    functions: Mapping[str, str],
    all_actions: Sequence[str],
    retained_actions: set[str],
) -> str:
    if not retained_actions.issubset(all_actions):
        raise RuntimeError(
            f"unknown retained production actions: {sorted(retained_actions-set(all_actions))}"
        )
    result = source
    for action in all_actions:
        if action in retained_actions:
            continue
        original = functions[action]
        if result.count(original) != 1:
            raise RuntimeError(f"cannot safely omit production action source {action}")
        result = result.replace(original, "", 1)
    remaining = validator.extract_rhai_functions(result)
    remaining_actions = set(remaining) & set(all_actions)
    if remaining_actions != retained_actions:
        raise RuntimeError(
            f"production source subset mismatch: missing="
            f"{sorted(retained_actions-remaining_actions)[:20]}, extra="
            f"{sorted(remaining_actions-retained_actions)[:20]}"
        )
    return result


def production_module_hash(manifest: str) -> str:
    match = re.search(r'(?m)^module_hash\s*=\s*"([0-9a-fA-F]{64})"\s*$', manifest)
    if not match:
        raise RuntimeError("production manifest lacks a canonical 64-hex module_hash")
    return match.group(1).lower()


def filter_manifest_actions(production: str, retained_actions: set[str]) -> str:
    block_pattern = re.compile(
        r"(?ms)^\[\[actions\]\]\r?\n.*?(?=^\[\[|\Z)"
    )

    def retain(match: re.Match[str]) -> str:
        block = match.group(0)
        name = re.search(
            r'(?m)^name\s*=\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*$', block
        )
        return block if name and name.group(1) in retained_actions else ""

    filtered = block_pattern.sub(retain, production)
    actual = set(validator.manifest_action_names(filtered))
    if actual != retained_actions:
        raise RuntimeError(
            f"manifest subset mismatch: missing={sorted(retained_actions-actual)[:20]}, "
            f"extra={sorted(actual-retained_actions)[:20]}"
        )
    return filtered


def test_manifest(
    production: str,
    fixture_rows: Sequence[Mapping[str, Any]],
    *,
    package_name: str = TEST_PACKAGE_NAME,
    retained_actions: set[str] | None = None,
) -> str:
    if retained_actions is not None:
        production = filter_manifest_actions(production, retained_actions)
    result, name_changes = re.subn(
        r'(?m)^(name\s*=\s*)"[^"]+"\s*$',
        rf'\1"{package_name}"',
        production,
        count=1,
    )
    if name_changes != 1:
        raise RuntimeError("could not replace production package name")
    result, hash_changes = re.subn(
        r'(?m)^(module_hash\s*=\s*)"[0-9a-fA-F]{64}"\s*$',
        rf'\1"{ZERO_HASH}"',
        result,
        count=1,
    )
    if hash_changes != 1:
        raise RuntimeError("could not clear production module hash")
    blocks: list[str] = []
    for row in fixture_rows:
        description = str(row["description"]).replace('"', "'")
        blocks.append(
            "\n".join(
                [
                    "[[actions]]",
                    f'name = "{row["action"]}"',
                    'emoji = "TEST"',
                    f'description = "TEST ONLY: {description}."',
                    "hidden = true",
                    "",
                ]
            )
        )
    return result.rstrip() + "\n\n" + "\n".join(blocks)


def ship_fixture_source(
    action_name: str,
    skill_code: int,
    tier_name: str,
    *,
    x: int = FIXTURE_LOCATIONS[0][0],
    y: int = FIXTURE_LOCATIONS[0][1],
    z: int = FIXTURE_LOCATIONS[0][2],
    epoch: int = FIXTURE_LOCATIONS[0][3],
    counters: Mapping[str, int] | None = None,
) -> str:
    extraction_amount, rare_extraction_amount = SHIP_TIERS[tier_name]
    counters = {**SHIP_COUNTERS, **(counters or {})}
    return f"""
fn {action_name}(action) {{
  var ship = action.output("MicroverseShip");
  var ship_id = action.random();
  ship.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["extraction_amount", {extraction_amount}],
    ["rare_extraction_amount", {rare_extraction_amount}],
    ["x", {x}],
    ["y", {y}],
    ["z", {z}],
    ["epoch", {epoch}],
    ["active_skill_type", {skill_code}],
    ["action_serial", {counters['action_serial']}],
    ["claim_serial", {counters['claim_serial']}],
    ["discovery_serial", {counters['discovery_serial']}],
    ["satellite_serial", {counters['satellite_serial']}],
    ["civilization_scan_serial", {counters['civilization_scan_serial']}],
    ["ship_id", ship_id]
  ]);
}}
"""


def body_fixture_source(
    action_name: str,
    body: Mapping[str, Any],
    *,
    x: int = FIXTURE_LOCATIONS[0][0],
    y: int = FIXTURE_LOCATIONS[0][1],
    z: int = FIXTURE_LOCATIONS[0][2],
    epoch: int = FIXTURE_LOCATIONS[0][3],
) -> str:
    reserves = body["reserves"]
    return f"""
fn {action_name}(action) {{
  var body = action.output("MicroverseCelestialBody");
  var source_signal_identifier = action.random();
  body.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["body_bank_version", 2],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", {x}],
    ["sector_y", {y}],
    ["sector_z", {z}],
    ["sector_epoch", {epoch}],
    ["candidate_code", {int(body['candidate_code'])}],
    ["body_type", {int(body['body_type'])}],
    ["life_stat", {int(body['life_stat'])}],
    ["matter_remaining", {int(reserves['matter'])}],
    ["crystal_remaining", {int(reserves['crystal'])}],
    ["gas_remaining", {int(reserves['gas'])}],
    ["energy_remaining", {int(reserves['energy'])}],
    ["satellites_remaining", {int(body['satellites'])}],
    ["next_satellite_serial", 601],
    ["civilization_discovered", 0]
  ]);
}}
"""


def empty_sector_fixture_source(
    action_name: str,
    *,
    x: int = FIXTURE_LOCATIONS[0][0],
    y: int = FIXTURE_LOCATIONS[0][1],
    z: int = FIXTURE_LOCATIONS[0][2],
    epoch: int = FIXTURE_LOCATIONS[0][3],
) -> str:
    return f"""
fn {action_name}(action) {{
  var sector = action.output("MicroverseSector");
  sector.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["body_bank_version", 2],
    ["x", {x}],
    ["y", {y}],
    ["z", {z}],
    ["epoch", {epoch}],
    ["sector_type", 0],
    ["survey_profile", 0],
    ["planet_remaining", 0],
    ["star_remaining", 0],
    ["gas_giant_remaining", 0],
    ["ice_giant_remaining", 0],
    ["neutron_star_remaining", 0],
    ["black_hole_remaining", 0],
    ["anomaly_remaining", 0],
    ["megastructure_remaining", 0],
    ["gas_cluster_remaining", 0],
    ["stellar_remnant_remaining", 0],
    ["minor_body_field_remaining", 0],
    ["next_planet_serial", 0],
    ["next_star_serial", 0],
    ["next_gas_giant_serial", 0],
    ["next_ice_giant_serial", 0],
    ["next_neutron_star_serial", 0],
    ["next_black_hole_serial", 0],
    ["next_anomaly_serial", 0],
    ["next_megastructure_serial", 0],
    ["next_gas_cluster_serial", 0],
    ["next_stellar_remnant_serial", 0],
    ["next_minor_body_field_serial", 0],
    ["revision", 0]
  ]);
  let zero = action.top_limb_u256(0);
  sector.update("key", zero);
}}
"""


def life_signal_fixture_source(
    action_name: str,
    *,
    x: int = FIXTURE_LOCATIONS[0][0],
    y: int = FIXTURE_LOCATIONS[0][1],
    z: int = FIXTURE_LOCATIONS[0][2],
    epoch: int = FIXTURE_LOCATIONS[0][3],
) -> str:
    return f"""
fn {action_name}(action) {{
  var life_signal = action.output("MicroverseLifeSignal");
  var source_body_identifier = action.random();
  life_signal.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["civilization_version", 2],
    ["source_body_identifier", source_body_identifier],
    ["sector_x", {x}],
    ["sector_y", {y}],
    ["sector_z", {z}],
    ["origin_epoch", {epoch}]
  ]);
  let zero = action.top_limb_u256(0);
  life_signal.update("key", zero);
}}
"""


def composite_fixture_source(
    action_name: str,
    parent_code: int,
    amounts: Mapping[int, int],
) -> str:
    return f"""
fn {action_name}(action) {{
  var resource = action.output("MicroverseCompositeResource");
  resource.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["resource_type", {parent_code}],
    ["sector_x", {FIXTURE_LOCATIONS[0][0]}],
    ["sector_y", {FIXTURE_LOCATIONS[0][1]}],
    ["sector_z", {FIXTURE_LOCATIONS[0][2]}],
    ["origin_epoch", {FIXTURE_LOCATIONS[0][3]}],
    ["child_1_remaining", {amounts.get(1, 0)}],
    ["child_2_remaining", {amounts.get(2, 0)}],
    ["child_3_remaining", {amounts.get(3, 0)}]
  ]);
}}
"""


def civilization_fixture_source(action_name: str, civilization_type: int) -> str:
    return f"""
fn {action_name}(action) {{
  var civilization = action.output("MicroverseCivilization");
  var source_life_signal_identifier = action.random();
  civilization.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["civilization_version", 2],
    ["source_life_signal_identifier", source_life_signal_identifier],
    ["sector_x", {FIXTURE_LOCATIONS[0][0]}],
    ["sector_y", {FIXTURE_LOCATIONS[0][1]}],
    ["sector_z", {FIXTURE_LOCATIONS[0][2]}],
    ["origin_epoch", {FIXTURE_LOCATIONS[0][3]}],
    ["civilization_type", {civilization_type}]
  ]);
}}
"""


def revealed_coordinate_fixture_source(
    action_name: str,
    *,
    time_only: bool,
    uses: int,
) -> str:
    class_name = "MicroverseTimeCoordinate" if time_only else "MicroverseWarpCoordinate"
    destination_fields = (
        f'    ["destination_epoch", {DIRECT_TIME_DESTINATION}],\n'
        if time_only
        else (
            f'    ["destination_x", {DIRECT_POSITION_DESTINATION[0]}],\n'
            f'    ["destination_y", {DIRECT_POSITION_DESTINATION[1]}],\n'
            f'    ["destination_z", {DIRECT_POSITION_DESTINATION[2]}],\n'
        )
    )
    return f"""
fn {action_name}(action) {{
  var coordinate = action.output("{class_name}");
  var source_body_identifier = action.random();
  coordinate.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["source_body_identifier", source_body_identifier],
    ["source_pool_before", 100],
    ["revealed", 1],
    ["destination_code", 1],
{destination_fields.rstrip()}
    ["uses_remaining", {uses}]
  ]);
}}
"""


def sealed_coordinate_fixture_source(
    action_name: str,
    *,
    time_only: bool,
    source_pool_before: int,
) -> str:
    class_name = "MicroverseTimeCoordinate" if time_only else "MicroverseWarpCoordinate"
    destination_fields = (
        '    ["destination_epoch", 0],\n'
        if time_only
        else (
            '    ["destination_x", 0],\n'
            '    ["destination_y", 0],\n'
            '    ["destination_z", 0],\n'
        )
    )
    return f"""
fn {action_name}(action) {{
  var coordinate = action.output("{class_name}");
  let zero = action.top_limb_u256(0);
  coordinate.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["source_body_identifier", zero],
    ["source_pool_before", {source_pool_before}],
    ["revealed", 0],
    ["destination_code", 0],
{destination_fields.rstrip()}
    ["uses_remaining", 0]
  ]);
  coordinate.update("key", zero);
}}
"""


def warp_object_fixture_source(
    action_name: str,
    class_name: str,
    *,
    uses: int,
    variant: int,
    destination: Mapping[str, Any] | None = None,
) -> str:
    destination = destination or {}
    raw_declarations = ""
    if class_name in {"MicroverseWarpChart", "MicroverseEpochChart"}:
        fields = [
            '["schema_version", 2]',
            '["mechanics_version", 2]',
            '["universe_version", 2]',
            '["catalog_version", 2]',
            '["source_body_identifier", raw_a]',
            '["source_pool_before", 9000]',
            '["revealed", 1]',
            f'["destination_code", {int(destination.get("code", 1))}]',
        ]
        if class_name == "MicroverseWarpChart":
            fields.extend(
                [
                    f'["destination_x", {int(destination.get("x", COORD_ZERO + 101))}]',
                    f'["destination_y", {int(destination.get("y", COORD_ZERO + 211))}]',
                    f'["destination_z", {int(destination.get("z", COORD_ZERO + 307))}]',
                ]
            )
        else:
            fields.append(
                f'["destination_epoch", {int(destination.get("epoch", 101))}]'
            )
        fields.append(f'["uses_remaining", {uses}]')
        raw_declarations = "  var raw_a = action.random();\n"
    elif class_name == "MicroversePositionAnchor":
        coordinates = FIXTURE_LOCATIONS[0 if variant == 1 else 1][:3]
        fields = [
            '["schema_version", 2]',
            '["mechanics_version", 2]',
            '["universe_version", 2]',
            '["anchor_version", 2]',
            '["source_ship_id", raw_a]',
            f'["x", {coordinates[0]}]',
            f'["y", {coordinates[1]}]',
            f'["z", {coordinates[2]}]',
            f'["uses_remaining", {uses}]',
        ]
        raw_declarations = "  var raw_a = action.random();\n"
    elif class_name == "MicroverseTimeAnchor":
        epoch = FIXTURE_LOCATIONS[0 if variant == 1 else 1][3]
        fields = [
            '["schema_version", 2]',
            '["mechanics_version", 2]',
            '["universe_version", 2]',
            '["anchor_version", 2]',
            '["source_ship_id", raw_a]',
            f'["epoch", {epoch}]',
            f'["uses_remaining", {uses}]',
        ]
        raw_declarations = "  var raw_a = action.random();\n"
    elif class_name == "MicroverseWormholeLink":
        fields = [
            '["schema_version", 2]',
            '["mechanics_version", 2]',
            '["universe_version", 2]',
            '["link_version", 2]',
            '["endpoint_a_anchor_identifier", raw_a]',
            '["endpoint_b_anchor_identifier", raw_b]',
            f'["endpoint_a_x", {FIXTURE_LOCATIONS[0][0]}]',
            f'["endpoint_a_y", {FIXTURE_LOCATIONS[0][1]}]',
            f'["endpoint_a_z", {FIXTURE_LOCATIONS[0][2]}]',
            f'["endpoint_b_x", {FIXTURE_LOCATIONS[1][0]}]',
            f'["endpoint_b_y", {FIXTURE_LOCATIONS[1][1]}]',
            f'["endpoint_b_z", {FIXTURE_LOCATIONS[1][2]}]',
            f'["uses_remaining", {uses}]',
        ]
        raw_declarations = (
            "  var raw_a = action.random();\n  var raw_b = action.random();\n"
        )
    elif class_name == "MicroverseTemporalLink":
        fields = [
            '["schema_version", 2]',
            '["mechanics_version", 2]',
            '["universe_version", 2]',
            '["link_version", 2]',
            '["endpoint_a_anchor_identifier", raw_a]',
            '["endpoint_b_anchor_identifier", raw_b]',
            f'["endpoint_a_epoch", {FIXTURE_LOCATIONS[0][3]}]',
            f'["endpoint_b_epoch", {FIXTURE_LOCATIONS[1][3]}]',
            f'["uses_remaining", {uses}]',
        ]
        raw_declarations = (
            "  var raw_a = action.random();\n  var raw_b = action.random();\n"
        )
    elif class_name == "MicroverseRendezvousCoordinate":
        fields = [
            '["schema_version", 2]',
            '["mechanics_version", 2]',
            '["universe_version", 2]',
            '["coordinate_version", 2]',
            '["position_anchor_identifier", raw_a]',
            '["time_anchor_identifier", raw_b]',
            f'["destination_x", {FIXTURE_LOCATIONS[2][0]}]',
            f'["destination_y", {FIXTURE_LOCATIONS[2][1]}]',
            f'["destination_z", {FIXTURE_LOCATIONS[2][2]}]',
            f'["destination_epoch", {FIXTURE_LOCATIONS[2][3]}]',
            f'["uses_remaining", {uses}]',
        ]
        raw_declarations = (
            "  var raw_a = action.random();\n  var raw_b = action.random();\n"
        )
    else:
        raise RuntimeError(f"unsupported warp fixture class {class_name}")
    rendered_fields = ",\n    ".join(fields)
    return f"""
fn {action_name}(action) {{
  var object = action.output("{class_name}");
{raw_declarations}  object.set([
    {rendered_fields}
  ]);
}}
"""


def sealed_chart_fixture_source(
    action_name: str,
    *,
    time_only: bool,
    source_pool_before: int,
) -> str:
    class_name = "MicroverseEpochChart" if time_only else "MicroverseWarpChart"
    destination_fields = (
        '    ["destination_epoch", 0],\n'
        if time_only
        else (
            '    ["destination_x", 0],\n'
            '    ["destination_y", 0],\n'
            '    ["destination_z", 0],\n'
        )
    )
    return f"""
fn {action_name}(action) {{
  var chart = action.output("{class_name}");
  let zero = action.top_limb_u256(0);
  chart.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["catalog_version", 2],
    ["source_body_identifier", zero],
    ["source_pool_before", {source_pool_before}],
    ["revealed", 0],
    ["destination_code", 0],
{destination_fields.rstrip()}
    ["uses_remaining", 0]
  ]);
  chart.update("key", zero);
}}
"""


def resource_fixture_source(action_name: str, code: int, amount: int) -> str:
    return f"""
fn {action_name}(action) {{
  var resource = action.output("MicroverseResource");
  resource.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["resource_type", {code}],
    ["amount", {amount}]
  ]);
}}
"""


def skill_fixture_source(action_name: str, code: int) -> str:
    return f"""
fn {action_name}(action) {{
  var skill = action.output("MicroverseTechnologySkill");
  skill.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["civilization_version", 2],
    ["skill_type", {code}],
    ["reusable", 1]
  ]);
}}
"""


def fixture_action_name(kind: str, *values: int) -> str:
    rendered = "".join(f"{value:03d}" for value in values)
    return f"TestMintExpansion{kind}{rendered}"


def warp_tree_action_names(warp_catalog: Mapping[str, Any]) -> set[str]:
    """Return the exact authored 622-action warp tree, excluding setup actions."""

    names: set[str] = set()
    for catalog_version in ("v1", "v2"):
        version = warp_catalog.get(catalog_version)
        if not isinstance(version, Mapping):
            raise RuntimeError(f"warp catalog lacks {catalog_version}")
        for section_name in ("position", "time"):
            section = version.get(section_name)
            if not isinstance(section, Mapping):
                raise RuntimeError(
                    f"warp catalog lacks {catalog_version}.{section_name}"
                )
            names.add(str(section["extract_action"]))
            names.update(str(row["reveal_action"]) for row in validator.section_rows(section))
            names.update(str(action) for action in section.get("use_actions", []))
    section_classes = {
        "MicroverseWarpCoordinate",
        "MicroverseTimeCoordinate",
        "MicroverseWarpChart",
        "MicroverseEpochChart",
    }
    for object_type in warp_catalog.get("object_types", []):
        if not isinstance(object_type, Mapping):
            continue
        if str(object_type.get("class_name")) in section_classes:
            continue
        for row in object_type.get("creation_actions", []):
            if isinstance(row, Mapping):
                names.add(str(row["name"]))
        for row in object_type.get("use_actions", []):
            if isinstance(row, Mapping):
                names.add(str(row["name"]))
    if len(names) != 622:
        raise RuntimeError(f"warp tree must contain exactly 622 actions, got {len(names)}")
    return names


def validate_explicit_selection_metadata(
    index: Mapping[str, Any],
    universe_contract: Mapping[str, Any],
    action_contract: Mapping[str, Any],
) -> None:
    """Bind executable fixtures to the final explicit-selection contracts."""

    index_by_name = {
        str(row.get("name")): row
        for row in validator.action_rows(index)
        if isinstance(row, Mapping)
    }
    action_rows = action_contract.get("actions")
    if not isinstance(action_rows, list):
        raise RuntimeError("production action contract lacks actions")
    action_by_name = {
        str(row.get("name")): row
        for row in action_rows
        if isinstance(row, Mapping)
    }
    universe_survey_rows = universe_contract.get("survey_profiles")
    universe_civilization_rows = universe_contract.get("civilization_types")
    if not isinstance(universe_survey_rows, list) or not isinstance(
        universe_civilization_rows, list
    ):
        raise RuntimeError("production universe contract lacks selection metadata")
    survey_by_action = {
        str(row.get("action")): row
        for row in universe_survey_rows
        if isinstance(row, Mapping)
    }
    civilization_by_action = {
        str(row.get("action")): row
        for row in universe_civilization_rows
        if isinstance(row, Mapping)
    }

    def require_explicit_intro(action: str, row: Mapping[str, Any]) -> None:
        intro = row.get("intro_contract")
        explicit = intro.get("explicit_action_identity") if isinstance(intro, Mapping) else None
        if explicit != {
            "owner": "action",
            "selection_mode": EXPLICIT_SELECTION_MODE,
            "stable_identifier_used": False,
        }:
            raise RuntimeError(f"{action}: action-contract selection metadata drift")
        if intro.get("vdf") is not None:
            raise RuntimeError(f"{action}: selection milestone unexpectedly owns a VDF")

    for action, selected_code, minimum in SURVEY_SELECTION_MILESTONES:
        index_row = index_by_name.get(action)
        action_row = action_by_name.get(action)
        universe_row = survey_by_action.get(action)
        if not all(
            isinstance(row, Mapping)
            for row in (index_row, action_row, universe_row)
        ):
            raise RuntimeError(f"{action}: missing explicit-selection metadata row")
        expected_literals = {
            "selection_mode": EXPLICIT_SELECTION_MODE,
            "survey_profile": selected_code,
            "minimum_claim_serial": minimum,
        }
        if index_row.get("fixed_literals") != expected_literals:
            raise RuntimeError(f"{action}: index selection literals drift")
        if any(action_row.get(key) != value for key, value in expected_literals.items()):
            raise RuntimeError(f"{action}: action-contract selection literals drift")
        if any(universe_row.get(key) != value for key, value in expected_literals.items()):
            raise RuntimeError(f"{action}: universe selection literals drift")
        require_explicit_intro(action, action_row)

    for action, selected_code, minimum in CIVILIZATION_SELECTION_MILESTONES:
        index_row = index_by_name.get(action)
        action_row = action_by_name.get(action)
        universe_row = civilization_by_action.get(action)
        if not all(
            isinstance(row, Mapping)
            for row in (index_row, action_row, universe_row)
        ):
            raise RuntimeError(f"{action}: missing explicit-selection metadata row")
        expected_literals = {
            "selection_mode": EXPLICIT_SELECTION_MODE,
            "civilization_type": selected_code,
            "minimum_civilization_scan_serial": minimum,
        }
        if index_row.get("fixed_literals") != expected_literals:
            raise RuntimeError(f"{action}: index selection literals drift")
        if (
            action_row.get("selection_mode") != EXPLICIT_SELECTION_MODE
            or action_row.get("minimum_civilization_scan_serial") != minimum
            or universe_row.get("selection_mode") != EXPLICIT_SELECTION_MODE
            or universe_row.get("code") != selected_code
            or universe_row.get("minimum_civilization_scan_serial") != minimum
        ):
            raise RuntimeError(f"{action}: civilization selection literals drift")
        require_explicit_intro(action, action_row)

    reveal_prefixes = (
        "RevealWarpCoordinate",
        "RevealTimeCoordinate",
        "RevealWarpChart",
        "RevealEpochChart",
    )
    reveal_rows = [
        row
        for name, row in action_by_name.items()
        if name.startswith(reveal_prefixes)
    ]
    if len(reveal_rows) != 595:
        raise RuntimeError(
            f"action contract must bind 595 explicit reveals, got {len(reveal_rows)}"
        )
    v2_vdf_rows = 0
    for row in reveal_rows:
        name = str(row["name"])
        intro = row.get("intro_contract")
        explicit = intro.get("explicit_action_identity") if isinstance(intro, Mapping) else None
        explicit_owner = (
            "reveal_p"
            if name.startswith("RevealWarpCoordinate")
            else (
                "reveal_t"
                if name.startswith("RevealTimeCoordinate")
                else (
                    "reveal_chart_p"
                    if name.startswith("RevealWarpChart")
                    else "reveal_chart_t"
                )
            )
        )
        if explicit != {
            "owner": explicit_owner,
            "selection_mode": EXPLICIT_SELECTION_MODE,
            "stable_identifier_used": False,
        }:
            raise RuntimeError(f"{name}: reveal explicit-selection contract drift")
        vdf = intro.get("vdf")
        if name.startswith(("RevealWarpChart", "RevealEpochChart")):
            if not isinstance(vdf, Mapping) or vdf.get("count") != 1:
                raise RuntimeError(f"{name}: v2 reveal VDF contract drift")
            v2_vdf_rows += 1
        elif vdf is not None:
            raise RuntimeError(f"{name}: frozen v1 reveal unexpectedly owns a VDF")
    if v2_vdf_rows != 384:
        raise RuntimeError(
            f"action contract must bind 384 v2 reveal VDF actions, got {v2_vdf_rows}"
        )


class FixtureRegistry:
    def __init__(self) -> None:
        self.rows: list[dict[str, Any]] = []
        self.sources: list[str] = []
        self.names: set[str] = set()

    def add(
        self,
        name: str,
        class_name: str,
        kind: str,
        description: str,
        source: str,
        **metadata: Any,
    ) -> str:
        if name in self.names:
            return name
        self.names.add(name)
        self.rows.append(
            {
                "action": name,
                "class": class_name,
                "kind": kind,
                "description": description,
                "output_only": True,
                **metadata,
            }
        )
        self.sources.append(source)
        return name

    def ship(
        self,
        skill_code: int,
        tier_name: str = "Large",
        *,
        location_code: int = 0,
        counters: Mapping[str, int] | None = None,
    ) -> str:
        tier_number = {"Small": 0, "Medium": 1, "Large": 2}[tier_name]
        x, y, z, epoch = FIXTURE_LOCATIONS[location_code]
        resolved_counters = {**SHIP_COUNTERS, **(counters or {})}
        if set(resolved_counters) != set(SHIP_COUNTERS):
            raise RuntimeError(
                f"ship fixture counter fields changed: {sorted(resolved_counters)}"
            )
        if counters:
            changed_counters = [
                (ordinal, resolved_counters[field])
                for ordinal, field in enumerate(SHIP_COUNTERS, start=1)
                if resolved_counters[field] != SHIP_COUNTERS[field]
            ]
            if not changed_counters:
                raise RuntimeError("ship fixture counter override changes no value")
            name = fixture_action_name(
                "ShipCounters",
                tier_number,
                skill_code,
                location_code,
                *(value for pair in changed_counters for value in pair),
            )
        else:
            name = fixture_action_name(
                "ShipTierSkillLocation", tier_number, skill_code, location_code
            )
        return self.add(
            name,
            "MicroverseShip",
            "ship",
            f"mint a {tier_name} Ship prepared with skill {skill_code}",
            ship_fixture_source(
                name,
                skill_code,
                tier_name,
                x=x,
                y=y,
                z=z,
                epoch=epoch,
                counters=resolved_counters,
            ),
            skill_code=skill_code,
            ship_tier=tier_name,
            location_code=location_code,
            literal_fields={
                "schema_version": 2,
                "mechanics_version": 2,
                "universe_version": 2,
                "extraction_amount": SHIP_TIERS[tier_name][0],
                "rare_extraction_amount": SHIP_TIERS[tier_name][1],
                "x": x,
                "y": y,
                "z": z,
                "epoch": epoch,
                "active_skill_type": skill_code,
                **resolved_counters,
            },
            invariants=[
                "x_y_z_pairwise_distinct",
                "epoch_nonzero_and_distinct_from_axes",
                "serial_counters_distinct_nonzero",
                "extraction_amounts_distinct",
            ],
        )

    def empty_sector(self, *, location_code: int = 0) -> str:
        x, y, z, epoch = FIXTURE_LOCATIONS[location_code]
        name = fixture_action_name("EmptySectorLocation", location_code)
        zero_fields = {
            "sector_type": 0,
            "survey_profile": 0,
            "planet_remaining": 0,
            "star_remaining": 0,
            "gas_giant_remaining": 0,
            "ice_giant_remaining": 0,
            "neutron_star_remaining": 0,
            "black_hole_remaining": 0,
            "anomaly_remaining": 0,
            "megastructure_remaining": 0,
            "gas_cluster_remaining": 0,
            "stellar_remnant_remaining": 0,
            "minor_body_field_remaining": 0,
            "next_planet_serial": 0,
            "next_star_serial": 0,
            "next_gas_giant_serial": 0,
            "next_ice_giant_serial": 0,
            "next_neutron_star_serial": 0,
            "next_black_hole_serial": 0,
            "next_anomaly_serial": 0,
            "next_megastructure_serial": 0,
            "next_gas_cluster_serial": 0,
            "next_stellar_remnant_serial": 0,
            "next_minor_body_field_serial": 0,
            "revision": 0,
        }
        return self.add(
            name,
            "MicroverseSector",
            "empty_sector",
            "mint a schema-complete EMPTY Sector for explicit survey selection",
            empty_sector_fixture_source(name, x=x, y=y, z=z, epoch=epoch),
            location_code=location_code,
            literal_fields={
                "schema_version": 2,
                "mechanics_version": 2,
                "universe_version": 2,
                "body_bank_version": 2,
                "x": x,
                "y": y,
                "z": z,
                "epoch": epoch,
                **zero_fields,
            },
            invariants=[
                "axes_pairwise_distinct",
                "epoch_nonzero_and_distinct_from_axes",
                "empty_sector_zero_allocation",
                "co_location_keyed_by_location_code",
                "zero_key_raw",
            ],
        )

    def life_signal(self, *, location_code: int = 0) -> str:
        x, y, z, epoch = FIXTURE_LOCATIONS[location_code]
        name = fixture_action_name("LifeSignalLocation", location_code)
        return self.add(
            name,
            "MicroverseLifeSignal",
            "life_signal",
            "mint a schema-complete intelligent-life signal with a Raw source binding",
            life_signal_fixture_source(name, x=x, y=y, z=z, epoch=epoch),
            location_code=location_code,
            literal_fields={
                "schema_version": 2,
                "mechanics_version": 2,
                "universe_version": 2,
                "civilization_version": 2,
                "sector_x": x,
                "sector_y": y,
                "sector_z": z,
                "origin_epoch": epoch,
            },
            invariants=[
                "sector_axes_pairwise_distinct",
                "origin_epoch_nonzero_and_distinct_from_axes",
                "source_body_identifier_is_raw_random",
                "co_location_keyed_by_location_code",
                "zero_key_raw",
            ],
        )

    def resource(self, code: int, amount: int) -> str:
        name = fixture_action_name("Resource", code, amount)
        return self.add(
            name,
            "MicroverseResource",
            "resource",
            f"mint exact Resource {code} amount {amount}",
            resource_fixture_source(name, code, amount),
            resource_code=code,
            amount=amount,
        )

    def skill(self, code: int) -> str:
        name = fixture_action_name("Skill", code)
        return self.add(
            name,
            "MicroverseTechnologySkill",
            "skill",
            f"mint reusable Technology Skill {code}",
            skill_fixture_source(name, code),
            skill_code=code,
        )

    def body(self, body: Mapping[str, Any], *, location_code: int = 0) -> str:
        code = int(body["candidate_code"])
        name = (
            fixture_action_name("Body", code)
            if location_code == 0
            else fixture_action_name("BodyLocation", code, location_code)
        )
        x, y, z, epoch = FIXTURE_LOCATIONS[location_code]
        return self.add(
            name,
            "MicroverseCelestialBody",
            "body",
            f"mint a full body candidate {code}",
            body_fixture_source(name, body, x=x, y=y, z=z, epoch=epoch),
            candidate_code=code,
            location_code=location_code,
            literal_fields={
                "sector_x": x,
                "sector_y": y,
                "sector_z": z,
                "sector_epoch": epoch,
                "candidate_code": code,
                "body_type": int(body["body_type"]),
                "energy_remaining": int(body["reserves"]["energy"]),
                "next_satellite_serial": 601,
            },
            invariants=[
                "sector_axes_pairwise_distinct",
                "sector_epoch_nonzero_and_distinct_from_axes",
                "co_location_keyed_by_location_code",
            ],
        )

    def composite(self, parent_code: int, amounts: Mapping[int, int]) -> str:
        # Amounts are part of the fixture identity so depleted/incorrect variants
        # cannot silently alias the positive fixture.
        values = tuple(int(amounts.get(slot, 0)) for slot in (1, 2, 3))
        name = fixture_action_name("Composite", parent_code, *values)
        return self.add(
            name,
            "MicroverseCompositeResource",
            "composite_resource",
            f"mint composite {parent_code} with child amounts {values}",
            composite_fixture_source(name, parent_code, amounts),
            parent_resource_code=parent_code,
            child_amounts=list(values),
            location_code=0,
            invariants=["co_location_keyed_by_location_code"],
        )

    def civilization(self, civilization_type: int) -> str:
        name = fixture_action_name("Civilization", civilization_type)
        return self.add(
            name,
            "MicroverseCivilization",
            "civilization",
            f"mint Type {civilization_type} civilization",
            civilization_fixture_source(name, civilization_type),
            civilization_type=civilization_type,
            location_code=0,
            invariants=["co_location_keyed_by_location_code"],
        )

    def coordinate(self, *, time_only: bool, uses: int) -> str:
        kind = "TimeCoordinate" if time_only else "WarpCoordinate"
        name = fixture_action_name(kind, uses)
        class_name = (
            "MicroverseTimeCoordinate" if time_only else "MicroverseWarpCoordinate"
        )
        return self.add(
            name,
            class_name,
            "revealed_time_coordinate" if time_only else "revealed_warp_coordinate",
            f"mint a revealed {kind} with {uses} uses",
            revealed_coordinate_fixture_source(name, time_only=time_only, uses=uses),
            uses=uses,
        )

    def warp_object(
        self,
        class_name: str,
        *,
        uses: int,
        variant: int = 1,
        destination: Mapping[str, Any] | None = None,
    ) -> str:
        class_code = {
            "MicroverseWarpChart": 1,
            "MicroverseEpochChart": 2,
            "MicroversePositionAnchor": 3,
            "MicroverseTimeAnchor": 4,
            "MicroverseWormholeLink": 5,
            "MicroverseTemporalLink": 6,
            "MicroverseRendezvousCoordinate": 7,
        }[class_name]
        destination_code = int((destination or {}).get("code", 0))
        invariant_map = {
            "MicroverseWarpChart": ["destination_axes_pairwise_distinct"],
            "MicroverseEpochChart": ["destination_epoch_nonzero"],
            "MicroversePositionAnchor": [
                "anchor_axes_pairwise_distinct",
                "source_ship_id_is_raw_random",
            ],
            "MicroverseTimeAnchor": [
                "anchor_epoch_nonzero",
                "source_ship_id_is_raw_random",
            ],
            "MicroverseWormholeLink": [
                "endpoint_axes_pairwise_distinct",
                "directional_endpoints_match_ship_locations",
            ],
            "MicroverseTemporalLink": [
                "endpoint_epochs_distinct_nonzero",
                "directional_endpoints_match_ship_epochs",
            ],
            "MicroverseRendezvousCoordinate": [
                "destination_axes_pairwise_distinct",
                "destination_epoch_nonzero",
            ],
        }
        name = fixture_action_name(
            "WarpObject", class_code, uses, variant, destination_code
        )
        return self.add(
            name,
            class_name,
            "warp_object",
            f"mint {class_name} variant {variant} with {uses} uses",
            warp_object_fixture_source(
                name,
                class_name,
                uses=uses,
                variant=variant,
                destination=destination,
            ),
            uses=uses,
            variant=variant,
            destination_code=destination_code,
            invariants=invariant_map[class_name],
        )

    def sealed_chart(
        self,
        *,
        time_only: bool,
        source_pool_before: int = 9_000,
    ) -> str:
        class_name = "MicroverseEpochChart" if time_only else "MicroverseWarpChart"
        kind = "EpochChart" if time_only else "WarpChart"
        name = (
            f"TestMintExpansionSealed{kind}"
            if source_pool_before == 9_000
            else fixture_action_name(f"Sealed{kind}Pool", source_pool_before)
        )
        return self.add(
            name,
            class_name,
            "sealed_epoch_chart" if time_only else "sealed_warp_chart",
            f"mint a deterministic sealed {class_name} at pool {source_pool_before}",
            sealed_chart_fixture_source(
                name,
                time_only=time_only,
                source_pool_before=source_pool_before,
            ),
            time_only=time_only,
            source_pool_before=source_pool_before,
            literal_fields={
                "schema_version": 2,
                "mechanics_version": 2,
                "universe_version": 2,
                "catalog_version": 2,
                "source_pool_before": source_pool_before,
                "revealed": 0,
                "destination_code": 0,
                "uses_remaining": 0,
            },
            invariants=["sealed_zero_destination", "zero_key_raw"],
        )

    def sealed_coordinate(
        self,
        *,
        time_only: bool,
        source_pool_before: int = 9_000,
    ) -> str:
        class_name = (
            "MicroverseTimeCoordinate" if time_only else "MicroverseWarpCoordinate"
        )
        kind = "TimeCoordinate" if time_only else "WarpCoordinate"
        name = (
            f"TestMintExpansionSealed{kind}"
            if source_pool_before == 9_000
            else fixture_action_name(f"Sealed{kind}Pool", source_pool_before)
        )
        return self.add(
            name,
            class_name,
            "sealed_time_coordinate" if time_only else "sealed_warp_coordinate",
            f"mint a deterministic sealed {class_name} at pool {source_pool_before}",
            sealed_coordinate_fixture_source(
                name,
                time_only=time_only,
                source_pool_before=source_pool_before,
            ),
            time_only=time_only,
            source_pool_before=source_pool_before,
            literal_fields={
                "schema_version": 2,
                "mechanics_version": 2,
                "universe_version": 2,
                "source_pool_before": source_pool_before,
                "revealed": 0,
                "destination_code": 0,
                "uses_remaining": 0,
            },
            invariants=["sealed_zero_destination", "zero_key_raw"],
        )


def component_scenarios(
    component_catalog: Mapping[str, Any],
    fixtures: FixtureRegistry,
    production_actions: set[str],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], set[str]]:
    positive: list[dict[str, Any]] = []
    negative: list[dict[str, Any]] = []
    required: set[str] = set()
    for component in component_catalog.get("components", []):
        if not isinstance(component, Mapping):
            continue
        code = int(component["code"])
        skill_code = int(component["skill_code"])
        wrong_skill = 2 if skill_code == 1 else 1
        ship = fixtures.ship(skill_code)
        wrong_ship = fixtures.ship(wrong_skill)
        material_fixtures = [
            fixtures.resource(int(row["resource_code"]), int(row["amount"]))
            for row in component["materials"]
        ]
        catalyst_code = int(component["catalyst"]["resource_code"])
        catalyst_one = fixtures.resource(catalyst_code, 1)
        catalyst_two = fixtures.resource(catalyst_code, 2)
        skill_fixture = fixtures.skill(skill_code)
        reusable = str(component["actions"]["reusable"])
        final = str(component["actions"]["final"])
        for action in (reusable, final):
            if action not in production_actions:
                raise RuntimeError(
                    f"component {code} references missing production action {action}"
                )
            required.add(action)
        positive.extend(
            [
                {
                    "name": f"component-{code}-reusable-positive",
                    "actions": [ship, *material_fixtures, catalyst_two, reusable],
                    "covers": [reusable],
                    "real_sample": code in (390, 405, 420, 434),
                },
                {
                    "name": f"component-{code}-final-positive",
                    "actions": [ship, *material_fixtures, catalyst_one, final],
                    "covers": [final],
                    "real_sample": code in (390, 405, 420, 434),
                },
                {
                    "name": f"component-{code}-reusable-then-final-chain",
                    "actions": [
                        ship,
                        *material_fixtures,
                        catalyst_two,
                        reusable,
                        skill_fixture,
                        "UseTechnologySkill",
                        *material_fixtures,
                        final,
                    ],
                    "covers": [reusable, final],
                    "real_sample": False,
                },
            ]
        )
        rejection_tokens = ["constraint", "predicate", "plan", "unsatisfied"]
        negative.extend(
            [
                {
                    "name": f"component-{code}-wrong-skill-rejected",
                    "actions": [
                        wrong_ship,
                        *material_fixtures,
                        catalyst_one,
                        final,
                    ],
                    "covers": [final],
                    "expected_error_contains": rejection_tokens,
                },
                {
                    "name": f"component-{code}-reusable-at-one-rejected",
                    "actions": [
                        ship,
                        *material_fixtures,
                        catalyst_one,
                        reusable,
                    ],
                    "covers": [reusable],
                    "expected_error_contains": rejection_tokens,
                },
                {
                    "name": f"component-{code}-final-at-two-rejected",
                    "actions": [
                        ship,
                        *material_fixtures,
                        catalyst_two,
                        final,
                    ],
                    "covers": [final],
                    "expected_error_contains": rejection_tokens,
                },
                {
                    "name": f"component-{code}-missing-third-material-rejected",
                    "actions": [
                        ship,
                        *material_fixtures[:2],
                        catalyst_one,
                        final,
                    ],
                    "covers": [final],
                    "expected_error_contains": [
                        "microverseresource",
                        "resource",
                        "input",
                        "plan",
                    ],
                },
            ]
        )
    return positive, negative, required


def action_slug(value: str) -> str:
    return "".join(
        token[:1].upper() + token[1:]
        for token in re.findall(r"[A-Za-z0-9]+", value)
    )


def resource_scenarios(
    resource_catalog: Mapping[str, Any],
    fixtures: FixtureRegistry,
    production_actions: set[str],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], set[str]]:
    """Build every v2 extraction/refinement route and its rejection matrix."""

    positive: list[dict[str, Any]] = []
    negative: list[dict[str, Any]] = []
    required: set[str] = set()
    bodies = {
        int(row["candidate_code"]): row
        for row in resource_catalog.get("bodies", [])
        if isinstance(row, Mapping)
    }
    sources = {
        int(row["resource_id"]): row
        for row in resource_catalog.get("source_resources", [])
        if isinstance(row, Mapping)
    }
    refined = {
        int(row["resource_id"]): row
        for row in resource_catalog.get("refined_resources", [])
        if isinstance(row, Mapping)
    }
    tier_names = ["Small", "Medium", "Large"]
    body_fixtures = {code: fixtures.body(body) for code, body in bodies.items()}

    extraction_actions: dict[tuple[int, str], str] = {}
    for source_code, source in sorted(sources.items()):
        body_code = int(source["body_id"])
        body = bodies[body_code]
        skill_code = int(source["extraction_skill_id"])
        wrong_skill = 2 if skill_code == 1 else 1
        minimum = int(source["min_capacity_tier"])
        base = f"Extract{body['slug']}{action_slug(str(source['name']))}"
        for tier_index in range(minimum, 3):
            tier_name = tier_names[tier_index]
            action = base if tier_index == minimum else f"{base}{tier_name}"
            if action not in production_actions:
                raise RuntimeError(
                    f"source resource {source_code} references missing production action {action}"
                )
            required.add(action)
            extraction_actions[(source_code, tier_name)] = action
            ship = fixtures.ship(skill_code, tier_name)
            wrong_ship = fixtures.ship(wrong_skill, tier_name)
            wrong_tier = tier_names[(tier_index + 1) % 3]
            wrong_tier_ship = fixtures.ship(skill_code, wrong_tier)
            body_fixture = body_fixtures[body_code]
            positive.append(
                {
                    "name": f"extract-{source_code}-{tier_name.lower()}-positive",
                    "actions": [ship, body_fixture, action],
                    "covers": [action],
                    "real_sample": source_code in (435, 464, 493)
                    and tier_name == "Large",
                }
            )
            rejection_tokens = ["constraint", "predicate", "unsatisfied", "plan"]
            negative.extend(
                [
                    {
                        "name": f"extract-{source_code}-{tier_name.lower()}-wrong-skill-rejected",
                        "actions": [wrong_ship, body_fixture, action],
                        "covers": [action],
                        "expected_error_contains": rejection_tokens,
                    },
                    {
                        "name": f"extract-{source_code}-{tier_name.lower()}-wrong-tier-rejected",
                        "actions": [wrong_tier_ship, body_fixture, action],
                        "covers": [action],
                        "expected_error_contains": rejection_tokens,
                    },
                ]
            )

    parent_rows = {
        int(row["resource_id"]): row
        for row in resource_catalog.get("refinement_parents", [])
        if isinstance(row, Mapping)
    }
    for parent_code, parent in sorted(parent_rows.items()):
        source = sources[parent_code]
        child_rows = [refined[int(row["resource_id"])] for row in parent["children"]]
        large_amounts = {
            int(row["slot"]): int(row["produced_amounts"]["Large"])
            for row in child_rows
        }
        parent_fixture = fixtures.composite(parent_code, large_amounts)
        wrong_parent_code = next(code for code in parent_rows if code != parent_code)
        wrong_parent_fixture = fixtures.composite(wrong_parent_code, large_amounts)
        large_extract = extraction_actions[(parent_code, "Large")]
        body_fixture = body_fixtures[int(source["body_id"])]
        extraction_ship = fixtures.ship(int(source["extraction_skill_id"]), "Large")
        for child in child_rows:
            child_code = int(child["resource_id"])
            skill_code = int(child["refinement_skill_id"])
            wrong_skill = 2 if skill_code == 1 else 1
            action = (
                f"Refine{action_slug(str(parent['parent_name']))}"
                f"To{action_slug(str(child['name']))}"
            )
            if action not in production_actions:
                raise RuntimeError(
                    f"refined resource {child_code} references missing production action {action}"
                )
            required.add(action)
            ship = fixtures.ship(skill_code)
            wrong_ship = fixtures.ship(wrong_skill)
            depleted = dict(large_amounts)
            depleted[int(child["slot"])] = 0
            depleted_fixture = fixtures.composite(parent_code, depleted)
            positive.extend(
                [
                    {
                        "name": f"refine-{child_code}-positive",
                        "actions": [ship, parent_fixture, action],
                        "covers": [action],
                        "real_sample": child_code in (494, 561, 628),
                    },
                    {
                        "name": f"extract-refine-{child_code}-end-to-end",
                        "actions": [
                            extraction_ship,
                            body_fixture,
                            large_extract,
                            fixtures.skill(skill_code),
                            "UseTechnologySkill",
                            action,
                        ],
                        "covers": [large_extract, action],
                        "real_sample": False,
                    },
                ]
            )
            rejection_tokens = ["constraint", "predicate", "unsatisfied", "plan"]
            negative.extend(
                [
                    {
                        "name": f"refine-{child_code}-wrong-skill-rejected",
                        "actions": [wrong_ship, parent_fixture, action],
                        "covers": [action],
                        "expected_error_contains": rejection_tokens,
                    },
                    {
                        "name": f"refine-{child_code}-wrong-parent-rejected",
                        "actions": [ship, wrong_parent_fixture, action],
                        "covers": [action],
                        "expected_error_contains": rejection_tokens,
                    },
                    {
                        "name": f"refine-{child_code}-depleted-slot-rejected",
                        "actions": [ship, depleted_fixture, action],
                        "covers": [action],
                        "expected_error_contains": rejection_tokens,
                    },
                ]
            )
    return positive, negative, required


def iter_skills(skill_catalog: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    rows: list[Mapping[str, Any]] = []
    for root in skill_catalog.get("roots", []):
        if not isinstance(root, Mapping):
            continue
        rows.append(root)
        rows.extend(
            row for row in root.get("specializations", []) if isinstance(row, Mapping)
        )
        mastery = root.get("mastery")
        if isinstance(mastery, Mapping):
            rows.append(mastery)
    return rows


def skill_scenarios(
    skill_catalog: Mapping[str, Any],
    component_catalog: Mapping[str, Any],
    index: Mapping[str, Any],
    fixtures: FixtureRegistry,
    production_actions: set[str],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]], set[str]]:
    positive: list[dict[str, Any]] = []
    negative: list[dict[str, Any]] = []
    required: set[str] = set()
    component_codes = {
        str(row["name"]): int(row["code"])
        for row in component_catalog.get("components", [])
        if isinstance(row, Mapping)
    }
    resource_codes = {
        str(name): int(code)
        for name, code in index.get("resource_codes", {}).items()
        if isinstance(name, str) and isinstance(code, int)
    }
    resource_codes.update(component_codes)
    rejection_tokens = ["constraint", "predicate", "unsatisfied", "plan", "input"]

    for skill in iter_skills(skill_catalog):
        code = int(skill["code"])
        action = str(skill["develop_action"])
        if action not in production_actions:
            raise RuntimeError(f"skill {code} references missing production action {action}")
        required.add(action)
        recipe = skill.get("development_recipe", {})
        if not isinstance(recipe, Mapping):
            raise RuntimeError(f"skill {code} lacks development_recipe")
        tier = str(skill.get("tier", skill.get("kind", "")))
        if tier == "root":
            civilization_type = int(skill["civilization_type"])
            wrong_civilization = 2 if civilization_type == 1 else 1
            good_actions = [
                fixtures.ship(0),
                fixtures.civilization(civilization_type),
                action,
            ]
            bad_actions = [
                fixtures.ship(0),
                fixtures.civilization(wrong_civilization),
                action,
            ]
        else:
            parent_code = int(skill["parent_code"])
            item_actions: list[str] = []
            for item in recipe.get("items", []):
                if not isinstance(item, Mapping):
                    continue
                resource_code = item.get("resource_code") or item.get("component_code")
                if not isinstance(resource_code, int):
                    resource_code = resource_codes.get(
                        str(item.get("resource_name") or item.get("component_name"))
                    )
                if not isinstance(resource_code, int):
                    raise RuntimeError(
                        f"skill {code} recipe item has no resolved resource code: {item}"
                    )
                amount = int(item.get("amount", 1))
                item_actions.append(fixtures.resource(resource_code, amount))
            prerequisite_actions = [
                fixtures.skill(int(row["skill_code"]))
                for row in recipe.get("prerequisite_skill_inputs", [])
                if isinstance(row, Mapping) and isinstance(row.get("skill_code"), int)
            ]
            good_actions = [
                fixtures.ship(parent_code),
                *prerequisite_actions,
                *item_actions,
                action,
            ]
            wrong_parent = 2 if parent_code == 1 else 1
            bad_actions = [
                fixtures.ship(wrong_parent),
                *prerequisite_actions,
                *item_actions,
                action,
            ]
            if item_actions:
                negative.append(
                    {
                        "name": f"skill-{code}-missing-recipe-item-rejected",
                        "actions": [
                            fixtures.ship(parent_code),
                            *prerequisite_actions,
                            *item_actions[:-1],
                            action,
                        ],
                        "covers": [action],
                        "expected_error_contains": rejection_tokens,
                    }
                )
        positive.append(
            {
                "name": f"skill-{code}-develop-positive",
                "actions": good_actions,
                "covers": [action],
                "real_sample": code in (1, 19, 73, 90),
            }
        )
        negative.append(
            {
                "name": f"skill-{code}-wrong-prerequisite-rejected",
                "actions": bad_actions,
                "covers": [action],
                "expected_error_contains": rejection_tokens,
            }
        )

    for artifact in skill_catalog.get("capability_artifacts", []):
        if not isinstance(artifact, Mapping):
            continue
        skill_code = int(artifact["skill_code"])
        action = str(artifact["action"])
        if action not in production_actions:
            raise RuntimeError(
                f"capability artifact for skill {skill_code} references missing action {action}"
            )
        required.add(action)
        inputs = [
            fixtures.resource(int(row["resource_code"]), int(row.get("amount", 1)))
            for row in artifact.get("fixed_inputs", [])
            if isinstance(row, Mapping)
        ]
        wrong_skill = 2 if skill_code == 1 else 1
        positive.extend(
            [
                {
                    "name": f"capability-{skill_code}-positive",
                    "actions": [fixtures.ship(skill_code), *inputs, action],
                    "covers": [action],
                    "real_sample": skill_code in (19, 55, 73, 90),
                },
                {
                    "name": f"capability-{skill_code}-skill-use-chain",
                    "actions": [
                        fixtures.ship(0),
                        fixtures.skill(skill_code),
                        "UseTechnologySkill",
                        *inputs,
                        action,
                    ],
                    "covers": [action],
                    "real_sample": False,
                },
            ]
        )
        negative.extend(
            [
                {
                    "name": f"capability-{skill_code}-wrong-skill-rejected",
                    "actions": [fixtures.ship(wrong_skill), *inputs, action],
                    "covers": [action],
                    "expected_error_contains": rejection_tokens,
                },
                {
                    "name": f"capability-{skill_code}-missing-input-rejected",
                    "actions": [fixtures.ship(skill_code), *inputs[:-1], action],
                    "covers": [action],
                    "expected_error_contains": rejection_tokens,
                },
            ]
        )
    return positive, negative, required


def warp_lifecycle_scenarios(
    warp_catalog: Mapping[str, Any],
    resource_catalog: Mapping[str, Any],
    fixtures: FixtureRegistry,
    production_actions: set[str],
) -> tuple[
    list[dict[str, Any]],
    list[dict[str, Any]],
    set[str],
    list[dict[str, Any]],
]:
    positive: list[dict[str, Any]] = []
    negative: list[dict[str, Any]] = []
    required: set[str] = set()
    explicit_reveal_representatives: list[dict[str, Any]] = []
    for time_only in (False, True):
        kind = "time" if time_only else "position"
        reusable = (
            "TimeWarpToCoordinateReusable" if time_only else "WarpToCoordinateReusable"
        )
        final = "TimeWarpToCoordinateFinal" if time_only else "WarpToCoordinateFinal"
        for action in (reusable, final):
            if action not in production_actions:
                raise RuntimeError(f"missing production warp lifecycle action {action}")
            required.add(action)
        positive.extend(
            [
                {
                    "name": f"warp-{kind}-reusable-then-final-chain",
                    "actions": [
                        fixtures.ship(0),
                        fixtures.coordinate(time_only=time_only, uses=2),
                        reusable,
                        final,
                    ],
                    "covers": [reusable, final],
                    "real_sample": True,
                    "movement_contract": [
                        {
                            "action": reusable,
                            "source": {
                                "x": FIXTURE_LOCATIONS[0][0],
                                "y": FIXTURE_LOCATIONS[0][1],
                                "z": FIXTURE_LOCATIONS[0][2],
                                "epoch": FIXTURE_LOCATIONS[0][3],
                            },
                            "destination": (
                                {"epoch": DIRECT_TIME_DESTINATION}
                                if time_only
                                else {
                                    "x": DIRECT_POSITION_DESTINATION[0],
                                    "y": DIRECT_POSITION_DESTINATION[1],
                                    "z": DIRECT_POSITION_DESTINATION[2],
                                }
                            ),
                        },
                        {
                            "action": final,
                            "consumes_reusable_result": True,
                        },
                    ],
                },
                {
                    "name": f"warp-{kind}-final-positive",
                    "actions": [
                        fixtures.ship(0),
                        fixtures.coordinate(time_only=time_only, uses=1),
                        final,
                    ],
                    "covers": [final],
                    "real_sample": False,
                    "movement_contract": [
                        {
                            "action": final,
                            "source": {
                                "x": FIXTURE_LOCATIONS[0][0],
                                "y": FIXTURE_LOCATIONS[0][1],
                                "z": FIXTURE_LOCATIONS[0][2],
                                "epoch": FIXTURE_LOCATIONS[0][3],
                            },
                            "destination": (
                                {"epoch": DIRECT_TIME_DESTINATION}
                                if time_only
                                else {
                                    "x": DIRECT_POSITION_DESTINATION[0],
                                    "y": DIRECT_POSITION_DESTINATION[1],
                                    "z": DIRECT_POSITION_DESTINATION[2],
                                }
                            ),
                        }
                    ],
                },
            ]
        )
        negative.extend(
            [
                {
                    "name": f"warp-{kind}-reusable-at-one-rejected",
                    "actions": [
                        fixtures.ship(0),
                        fixtures.coordinate(time_only=time_only, uses=1),
                        reusable,
                    ],
                    "covers": [reusable],
                    "expected_error_contains": ["constraint", "predicate", "plan"],
                },
                {
                    "name": f"warp-{kind}-final-at-two-rejected",
                    "actions": [
                        fixtures.ship(0),
                        fixtures.coordinate(time_only=time_only, uses=2),
                        final,
                    ],
                    "covers": [final],
                    "expected_error_contains": ["constraint", "predicate", "plan"],
                },
            ]
        )
    bodies = {
        int(row["candidate_code"]): row
        for row in resource_catalog.get("bodies", [])
        if isinstance(row, Mapping)
    }
    anomaly_body = {
        "candidate_code": 11,
        "body_type": 7,
        "life_stat": 0,
        "satellites": 0,
        "reserves": {
            "matter": 0,
            "crystal": 0,
            "gas": 0,
            "energy": 18_000,
        },
    }
    object_types = {
        str(row["class_name"]): row
        for row in warp_catalog.get("object_types", [])
        if isinstance(row, Mapping)
    }
    v1 = warp_catalog.get("v1", {})
    v2 = warp_catalog.get("v2", {})
    if not isinstance(v1, Mapping) or not isinstance(v2, Mapping):
        raise RuntimeError("warp catalog must contain v1 and v2 mappings")
    position_rows = validator.section_rows(v2.get("position", {}))
    time_rows = validator.section_rows(v2.get("time", {}))
    first_destination = {
        "MicroverseWarpChart": position_rows[0],
        "MicroverseEpochChart": time_rows[0],
    }

    # The two frozen-v1 extractors were previously absent from the late-game
    # shard.  They share one honest Anomaly at location A; v2 position uses A
    # while v2 epoch uses B, giving varied co-location without fixture aliases.
    anomaly_fixture = fixtures.body(anomaly_body, location_code=0)
    for action in (
        "ExtractAnomalyWarpCoordinate",
        "ExtractAnomalyTimeCoordinate",
    ):
        if action not in production_actions:
            raise RuntimeError(f"missing production frozen-v1 extraction action {action}")
        required.add(action)
        positive.append(
            {
                "name": f"warp-create-{action}-positive",
                "actions": [fixtures.ship(14, location_code=0), anomaly_fixture, action],
                "covers": [action],
                "real_sample": action == "ExtractAnomalyWarpCoordinate",
                "co_location": {
                    "ship_location_code": 0,
                    "body_location_code": 0,
                    "fields": ["x", "y", "z", "epoch"],
                },
            }
        )
        negative.extend(
            [
                {
                    "name": f"warp-create-{action}-wrong-skill-rejected",
                    "actions": [fixtures.ship(1, location_code=0), anomaly_fixture, action],
                    "covers": [action],
                    "expected_error_contains": [
                        "constraint", "predicate", "unsatisfied", "plan", "input"
                    ],
                },
                {
                    "name": f"warp-create-{action}-missing-input-rejected",
                    "actions": [fixtures.ship(14, location_code=0), action],
                    "covers": [action],
                    "expected_error_contains": [
                        "constraint", "predicate", "unsatisfied", "plan", "input"
                    ],
                    "expected_rejection_stage": "input_selection",
                },
            ]
        )

    # Every explicit Survey/Civilization choice has an at-threshold positive
    # and an N-1 rejection.  The selected result is fixed by the action name;
    # the Ship counter is only a deterministic progression eligibility gate.
    empty_sector_fixture = fixtures.empty_sector(location_code=0)
    life_signal_fixture = fixtures.life_signal(location_code=0)
    rejection_tokens = ["constraint", "predicate", "unsatisfied", "plan", "input"]
    for action, selected_code, minimum in SURVEY_SELECTION_MILESTONES:
        if action not in production_actions:
            raise RuntimeError(f"missing production survey milestone action {action}")
        required.add(action)
        for expected, fixture_counter in (("accept", minimum), ("reject", minimum - 1)):
            scenario = {
                "name": (
                    f"selection-survey-profile-{selected_code:02d}-"
                    f"{'at-threshold' if expected == 'accept' else 'below-threshold-rejected'}"
                ),
                "actions": [
                    fixtures.ship(0, counters={"claim_serial": fixture_counter}),
                    empty_sector_fixture,
                    action,
                ],
                "covers": [action],
                "selection_gate": {
                    "selection_mode": EXPLICIT_SELECTION_MODE,
                    "selection_kind": "survey_profile",
                    "selected_code": selected_code,
                    "counter_field": "claim_serial",
                    "minimum_inclusive": minimum,
                    "fixture_counter": fixture_counter,
                    "expected": expected,
                },
            }
            if expected == "accept":
                scenario["real_sample"] = selected_code == 5
                positive.append(scenario)
            else:
                scenario["expected_error_contains"] = rejection_tokens
                negative.append(scenario)
    for action, selected_code, minimum in CIVILIZATION_SELECTION_MILESTONES:
        if action not in production_actions:
            raise RuntimeError(
                f"missing production civilization milestone action {action}"
            )
        required.add(action)
        for expected, fixture_counter in (("accept", minimum), ("reject", minimum - 1)):
            scenario = {
                "name": (
                    f"selection-civilization-type-{selected_code}-"
                    f"{'at-threshold' if expected == 'accept' else 'below-threshold-rejected'}"
                ),
                "actions": [
                    fixtures.ship(
                        0,
                        counters={"civilization_scan_serial": fixture_counter},
                    ),
                    life_signal_fixture,
                    action,
                ],
                "covers": [action],
                "selection_gate": {
                    "selection_mode": EXPLICIT_SELECTION_MODE,
                    "selection_kind": "civilization_type",
                    "selected_code": selected_code,
                    "counter_field": "civilization_scan_serial",
                    "minimum_inclusive": minimum,
                    "fixture_counter": fixture_counter,
                    "expected": expected,
                },
            }
            if expected == "accept":
                scenario["real_sample"] = selected_code == 3
                scenario["output_relations"] = [
                    {
                        "normalized_relation": (
                            "civilization.source_life_signal_identifier == "
                            "life_signal.stable_identifier"
                        ),
                        "output": {
                            "scope": "output",
                            "variable": "civilization",
                            "output_ordinal": 1,
                            "class": "MicroverseCivilization",
                            "field": "source_life_signal_identifier",
                            "field_type": "Raw",
                        },
                        "equals": [
                            {
                                "scope": "input",
                                "variable": "life_signal",
                                "field": "stable_identifier",
                                "field_type": "Raw",
                            }
                        ],
                        "source_expression_closure": {
                            "call_path": [action],
                            "operations": [
                                "action.random",
                                "var_assign",
                                "life_signal.stable_identifier",
                                "life_signal.update.stable_identifier",
                                "civilization.set.source_life_signal_identifier",
                            ],
                        },
                    }
                ]
                positive.append(scenario)
            else:
                scenario["expected_error_contains"] = rejection_tokens
                negative.append(scenario)

    # Four representatives execute one concrete action from each of the 595
    # explicitly named reveal families.  Their ordered covered-action lists
    # preserve full tree coverage without pretending a runtime selector exists.
    # Capacity twins separately exercise every frozen minimum and monotonic
    # high-pool/lower-use case.
    for catalog_version, version_catalog in (("v1", v1), ("v2", v2)):
        for section_name, time_only in (("position", False), ("time", True)):
            section = version_catalog.get(section_name, {})
            if not isinstance(section, Mapping):
                raise RuntimeError(
                    f"warp catalog {catalog_version}.{section_name} must be a mapping"
                )
            rows = validator.section_rows(section)
            if section.get("selection_mode") != EXPLICIT_SELECTION_MODE:
                raise RuntimeError(
                    f"{catalog_version}.{section_name} selection mode changed"
                )
            action_names = [str(row["reveal_action"]) for row in rows]
            missing_reveals = sorted(set(action_names) - production_actions)
            if missing_reveals:
                raise RuntimeError(
                    f"missing production {catalog_version} reveal actions: "
                    f"{missing_reveals[:20]}"
                )
            required.update(action_names)
            if catalog_version == "v1":
                ship_fixture = fixtures.ship(0, location_code=0)
                class_name = (
                    "MicroverseTimeCoordinate"
                    if time_only
                    else "MicroverseWarpCoordinate"
                )
                prefix = "RevealTimeCoordinate" if time_only else "RevealWarpCoordinate"
                vdf_mode = "source_absent_default_zero"
            else:
                creation = next(
                    row
                    for row in object_types[
                        "MicroverseEpochChart" if time_only else "MicroverseWarpChart"
                    ]["creation_actions"]
                    if "{slug}" in str(row.get("name"))
                )
                ship_fixture = fixtures.ship(int(creation["skill_code"]), location_code=0)
                class_name = (
                    "MicroverseEpochChart" if time_only else "MicroverseWarpChart"
                )
                prefix = "RevealEpochChart" if time_only else "RevealWarpChart"
                vdf_mode = "vdf_stripped_default_zero"
            by_code = {int(row["code"]): row for row in rows}
            representative_row = by_code[1]
            representative_pool = int(
                representative_row["minimum_source_pool_inclusive"]
            )
            fixture = (
                fixtures.sealed_coordinate(
                    time_only=time_only,
                    source_pool_before=representative_pool,
                )
                if catalog_version == "v1"
                else fixtures.sealed_chart(
                    time_only=time_only,
                    source_pool_before=representative_pool,
                )
            )
            explicit_reveal_representatives.append(
                {
                    "name": f"{catalog_version}-{section_name}-reveal",
                    "fixture": fixture,
                    "ship_fixture": ship_fixture,
                    "ship_fixture_required_by_target": catalog_version == "v2",
                    "state_pressure_decoy_fixture": anomaly_fixture,
                    "class": class_name,
                    "catalog_version": catalog_version,
                    "catalog_section": section_name,
                    "action_prefix": prefix,
                    "representative_action": str(representative_row["reveal_action"]),
                    "destination_count": len(rows),
                    "covered_actions": action_names,
                    "vdf_mode": vdf_mode,
                    "selection_mode": EXPLICIT_SELECTION_MODE,
                    "real_sample": True,
                }
            )

            capacity_minima = CAPACITY_MINIMUMS[catalog_version]
            catalog_name = f"{catalog_version}.{section_name}"

            def sealed_capacity_fixture(source_pool_before: int) -> str:
                if catalog_version == "v1":
                    return fixtures.sealed_coordinate(
                        time_only=time_only,
                        source_pool_before=source_pool_before,
                    )
                return fixtures.sealed_chart(
                    time_only=time_only,
                    source_pool_before=source_pool_before,
                )

            def capacity_actions(source_pool_before: int, action: str) -> list[str]:
                fixture_name = sealed_capacity_fixture(source_pool_before)
                if catalog_version == "v1":
                    return [fixture_name, action]
                return [ship_fixture, fixture_name, action]

            for destination_code, uses in ((1, 10), (2, 3), (5, 1)):
                row = by_code[destination_code]
                action = str(row["reveal_action"])
                minimum = capacity_minima[uses]
                if (
                    int(row["uses"]) != uses
                    or int(row["minimum_source_pool_inclusive"]) != minimum
                ):
                    raise RuntimeError(
                        f"{catalog_name} code {destination_code} capacity drift"
                    )
                for expected, source_pool_before in (
                    ("accept", minimum),
                    ("reject", minimum - 1),
                ):
                    scenario = {
                        "name": (
                            f"capacity-{catalog_version}-{section_name}-"
                            f"code-{destination_code:03d}-"
                            f"{'at-minimum' if expected == 'accept' else 'below-minimum-rejected'}"
                        ),
                        "actions": capacity_actions(source_pool_before, action),
                        "covers": [action],
                        "capacity_gate": {
                            "selection_mode": EXPLICIT_SELECTION_MODE,
                            "catalog": catalog_name,
                            "action": action,
                            "destination_code": destination_code,
                            "uses": uses,
                            "minimum_source_pool_inclusive": minimum,
                            "fixture_source_pool_before": source_pool_before,
                            "expected": expected,
                        },
                    }
                    if expected == "accept":
                        scenario["real_sample"] = destination_code == 1
                        positive.append(scenario)
                    else:
                        scenario["expected_error_contains"] = rejection_tokens
                        negative.append(scenario)

            high_pool = capacity_minima[10]
            for destination_code, uses in ((2, 3), (5, 1)):
                row = by_code[destination_code]
                action = str(row["reveal_action"])
                minimum = capacity_minima[uses]
                positive.append(
                    {
                        "name": (
                            f"capacity-{catalog_version}-{section_name}-"
                            f"code-{destination_code:03d}-high-pool-lower-use"
                        ),
                        "actions": capacity_actions(high_pool, action),
                        "covers": [action],
                        "real_sample": False,
                        "capacity_gate": {
                            "selection_mode": EXPLICIT_SELECTION_MODE,
                            "catalog": catalog_name,
                            "action": action,
                            "destination_code": destination_code,
                            "uses": uses,
                            "minimum_source_pool_inclusive": minimum,
                            "fixture_source_pool_before": high_pool,
                            "expected": "accept",
                        },
                    }
                )

    def recipe_input_fixture(item: Mapping[str, Any], ordinal: int) -> str:
        class_name = str(item.get("class"))
        if class_name == "MicroverseResource":
            return fixtures.resource(int(item["resource_code"]), int(item.get("amount", 1)))
        if class_name in {"MicroversePositionAnchor", "MicroverseTimeAnchor"}:
            return fixtures.warp_object(
                class_name,
                uses=1,
                variant=1 if ordinal == 0 else 2,
            )
        raise RuntimeError(f"unsupported warp recipe input fixture: {item}")

    for class_name, object_type in object_types.items():
        if class_name in {"MicroverseWarpCoordinate", "MicroverseTimeCoordinate"}:
            continue
        for creation in object_type.get("creation_actions", []):
            if not isinstance(creation, Mapping):
                continue
            action = str(creation.get("name"))
            if "{slug}" in action:
                continue
            if action not in production_actions:
                raise RuntimeError(f"missing production warp creation action {action}")
            required.add(action)
            skill_code = int(creation.get("skill_code") or 0)
            wrong_skill = 2 if skill_code == 1 else 1
            ship_location_code = 0
            if action.startswith("ExtractWormhole"):
                ship_location_code = (
                    1 if action == "ExtractWormholeEpochChart" else 0
                )
                inputs = [
                    fixtures.body(bodies[22], location_code=ship_location_code)
                ]
            else:
                recipe = creation.get("recipe")
                if not isinstance(recipe, Mapping):
                    title_key = class_name.removeprefix("Microverse")
                    recipe = warp_catalog.get("recipes", {}).get(title_key, {})
                inputs = [
                    recipe_input_fixture(item, index)
                    for index, item in enumerate(recipe.get("inputs", []))
                    if isinstance(item, Mapping)
                ]
            positive_row = {
                "name": f"warp-create-{action}-positive",
                "actions": [
                    fixtures.ship(skill_code, location_code=ship_location_code),
                    *inputs,
                    action,
                ],
                "covers": [action],
                "real_sample": action in {
                    "ExtractWormholeWarpChart",
                    "CapturePositionAnchor",
                    "ConstructWormholeLink",
                    "ComposeRendezvousCoordinate",
                },
            }
            if action in SHAPE_J_CONSTRUCTOR_ROLE_CONTRACTS:
                positive_row["post_state_assertion"] = "shape_j_constructor"
            if action.startswith("ExtractWormhole"):
                positive_row["co_location"] = {
                    "ship_location_code": ship_location_code,
                    "body_location_code": ship_location_code,
                    "fields": ["x", "y", "z", "epoch"],
                }
            if action in {"CapturePositionAnchor", "CaptureTimeAnchor"}:
                anchor_class = (
                    "MicroversePositionAnchor"
                    if action == "CapturePositionAnchor"
                    else "MicroverseTimeAnchor"
                )
                positive_row["post_state_assertion"] = (
                    "capture_anchor_source_ship_id_raw"
                )
                positive_row["output_relations"] = [
                    {
                        "normalized_relation": (
                            "anchor.source_ship_id == ship.ship_id == "
                            "next_ship.ship_id"
                        ),
                        "output": {
                            "scope": "output",
                            "variable": "anchor",
                            "output_ordinal": 2,
                            "class": anchor_class,
                            "field": "source_ship_id",
                            "field_type": "Raw",
                        },
                        "equals": [
                            {
                                "scope": "input",
                                "variable": "ship",
                                "field": "ship_id",
                                "field_type": "Raw",
                            },
                            {
                                "scope": "output",
                                "variable": "next_ship",
                                "output_ordinal": 1,
                                "field": "ship_id",
                                "field_type": "Raw",
                            },
                        ],
                        "source_expression_closure": {
                            "call_path": [
                                action,
                                "consume_prepared_ship_core",
                                "bind_ship_id",
                            ],
                            "operations": [
                                "action.random",
                                "var_assign",
                                "ship.ship_id",
                                "next_ship.set.ship_id",
                                "anchor.set.source_ship_id",
                            ],
                        },
                    }
                ]
            positive.append(positive_row)
            negative.append(
                {
                    "name": f"warp-create-{action}-wrong-skill-rejected",
                    "actions": [
                        fixtures.ship(wrong_skill, location_code=ship_location_code),
                        *inputs,
                        action,
                    ],
                    "covers": [action],
                    "expected_error_contains": rejection_tokens,
                }
            )
            if inputs:
                negative.append(
                    {
                        "name": f"warp-create-{action}-missing-input-rejected",
                        "actions": [
                            fixtures.ship(skill_code, location_code=ship_location_code),
                            *inputs[:-1],
                            action,
                        ],
                        "covers": [action],
                        "expected_error_contains": rejection_tokens,
                        "expected_rejection_stage": "input_selection",
                    }
                )

        use_rows = [
            row for row in object_type.get("use_actions", []) if isinstance(row, Mapping)
        ]
        for use in use_rows:
            action = str(use["name"])
            if action not in production_actions:
                raise RuntimeError(f"missing production warp use action {action}")
            required.add(action)
            skill_code = int(use.get("skill_code") or 0)
            final_use = use.get("final_use") is True
            uses = 1 if final_use else 2
            wrong_uses = 2 if final_use else 1
            location_code = 1 if "BToA" in action else 0
            destination = first_destination.get(class_name)
            source_location = FIXTURE_LOCATIONS[location_code]
            if class_name == "MicroverseWormholeLink":
                destination_fields = {
                    "x": FIXTURE_LOCATIONS[0 if "BToA" in action else 1][0],
                    "y": FIXTURE_LOCATIONS[0 if "BToA" in action else 1][1],
                    "z": FIXTURE_LOCATIONS[0 if "BToA" in action else 1][2],
                }
            elif class_name == "MicroverseTemporalLink":
                destination_fields = {
                    "epoch": FIXTURE_LOCATIONS[0 if "BToA" in action else 1][3]
                }
            elif class_name == "MicroverseRendezvousCoordinate":
                destination_fields = {
                    "x": FIXTURE_LOCATIONS[2][0],
                    "y": FIXTURE_LOCATIONS[2][1],
                    "z": FIXTURE_LOCATIONS[2][2],
                    "epoch": FIXTURE_LOCATIONS[2][3],
                }
            elif class_name == "MicroverseWarpChart" and destination:
                destination_fields = {
                    key: int(destination[key]) for key in ("x", "y", "z")
                }
            elif class_name == "MicroverseEpochChart" and destination:
                destination_fields = {"epoch": int(destination["epoch"])}
            else:
                destination_fields = {}
            positive.append(
                {
                    "name": f"warp-use-{action}-positive",
                    "actions": [
                        fixtures.ship(skill_code, location_code=location_code),
                        fixtures.warp_object(
                            class_name,
                            uses=uses,
                            destination=destination,
                        ),
                        action,
                    ],
                    "covers": [action],
                    "real_sample": action in {
                        "WarpShipToPositionCoordinateFinal",
                        "TraverseWormholeAToBFinal",
                        "WarpToRendezvousCoordinateFinal",
                    },
                    "movement_contract": [
                        {
                            "action": action,
                            "direction": (
                                "b_to_a" if "BToA" in action else "a_to_b"
                            ),
                            "source": {
                                "x": source_location[0],
                                "y": source_location[1],
                                "z": source_location[2],
                                "epoch": source_location[3],
                            },
                            "destination": destination_fields,
                        }
                    ],
                }
            )
            negative.extend(
                [
                    {
                        "name": f"warp-use-{action}-wrong-uses-rejected",
                        "actions": [
                            fixtures.ship(skill_code, location_code=location_code),
                            fixtures.warp_object(
                                class_name,
                                uses=wrong_uses,
                                destination=destination,
                            ),
                            action,
                        ],
                        "covers": [action],
                        "expected_error_contains": rejection_tokens,
                    },
                    {
                        "name": f"warp-use-{action}-wrong-skill-rejected",
                        "actions": [
                            fixtures.ship(2 if skill_code == 1 else 1, location_code=location_code),
                            fixtures.warp_object(
                                class_name,
                                uses=uses,
                                destination=destination,
                            ),
                            action,
                        ],
                        "covers": [action],
                        "expected_error_contains": rejection_tokens,
                    },
                ]
            )

        reusable_rows = [row for row in use_rows if row.get("final_use") is False]
        final_rows = [row for row in use_rows if row.get("final_use") is True]
        if reusable_rows and final_rows:
            reusable = next(
                (row for row in reusable_rows if "AToB" in str(row["name"])),
                reusable_rows[0],
            )
            final = next(
                (row for row in final_rows if "BToA" in str(row["name"])),
                final_rows[0],
            )
            skill_code = int(reusable.get("skill_code") or 0)
            positive.append(
                {
                    "name": f"warp-{class_name}-reusable-final-chain",
                    "actions": [
                        fixtures.ship(skill_code),
                        fixtures.warp_object(
                            class_name,
                            uses=2,
                            destination=first_destination.get(class_name),
                        ),
                        str(reusable["name"]),
                        fixtures.skill(skill_code),
                        "UseTechnologySkill",
                        str(final["name"]),
                    ],
                    "covers": [str(reusable["name"]), str(final["name"])],
                    "real_sample": False,
                }
            )
    expected_required = warp_tree_action_names(warp_catalog) | SELECTION_MILESTONE_ACTIONS
    if required != expected_required:
        raise RuntimeError(
            "warp/selection scenario coverage drift: "
            f"missing={sorted(expected_required-required)[:20]}, "
            f"extra={sorted(required-expected_required)[:20]}"
        )
    return positive, negative, required, explicit_reveal_representatives


def production_plan_inventory(
    production_root: Path,
    actions: Sequence[str],
    family_by_action: Mapping[str, str],
    *,
    production_plugin_sha256: str,
    production_manifest_sha256: str,
) -> dict[str, Any]:
    return {
        "policy": (
            "Direct stock-PEXE inspect plan only. No proof generation and no "
            "network submission."
        ),
        "production_plugin_sha256": production_plugin_sha256,
        "production_manifest_sha256": production_manifest_sha256,
        "action_count": len(actions),
        "actions": [
            {
                "action": action,
                "family": family_by_action.get(action),
                "command": [
                    "pexe",
                    "inspect",
                    "plan",
                    str(production_root),
                    "--action",
                    action,
                    "--seed",
                    "1",
                    "--show",
                    "summary,totals",
                ],
            }
            for action in actions
        ],
    }


def fixture_source_schema_contract(
    action: str,
    class_name: str,
    source: str,
    class_row: Mapping[str, Any],
) -> dict[str, Any]:
    """Prove one output-only fixture covers its entire final class schema."""

    fields = class_row.get("fields")
    if not isinstance(fields, list):
        raise RuntimeError(f"fixture class {class_name} lacks schema fields")
    expected_types = {
        str(field["name"]): str(field["type"])
        for field in fields
        if isinstance(field, Mapping)
    }
    sdk_live = class_row.get("sdk_managed_live_fields", [])
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
    roles = direct_role_contract(source)
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
        if re.fullmatch(r"-?[0-9]+", expression):
            return "Int"
        if expression in raw_variables:
            return "Raw"
        if expression in integer_variables:
            return "Int"
        raise RuntimeError(
            f"fixture {action} has untyped expression {expression!r}"
        )

    assignments: dict[str, dict[str, Any]] = {}
    set_pattern = re.compile(
        rf"\b{re.escape(output_variable)}\.set\s*\(\s*\[(?P<body>.*?)\]\s*\)\s*;",
        re.DOTALL,
    )
    set_matches = list(set_pattern.finditer(source))
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
        # Updates execute after the grouped set and therefore define the final
        # fixture value/source when the same schema field appears in both.
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
        if field_name in expected_types and field_name not in assignments:
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
        "field_sources": {
            name: assignments[name] for name in sorted(assignments)
        },
        "missing_fields": [],
        "wrong_type_fields": {},
    }


def enrich_fixture_contract_rows(
    rows: Sequence[dict[str, Any]],
    sources_by_name: Mapping[str, str],
    schema_counts: Mapping[str, Any],
) -> None:
    classes = schema_counts.get("classes")
    if not isinstance(classes, Mapping):
        raise RuntimeError("schema-counts sidecar lacks classes")
    for row in rows:
        action = str(row["action"])
        source = sources_by_name[action]
        class_name = str(row["class"])
        class_row = classes.get(class_name)
        if not isinstance(class_row, Mapping):
            raise RuntimeError(f"fixture {action} has unknown class {class_name}")
        fields = class_row.get("fields")
        if not isinstance(fields, list):
            raise RuntimeError(f"fixture class {class_name} lacks schema fields")
        field_types = {
            str(field["name"]): str(field["type"])
            for field in fields
            if isinstance(field, Mapping)
        }
        literal_pairs = re.findall(
            r'\[\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*,\s*(-?[0-9]+)\s*\]',
            source,
        )
        literal_fields = {name: int(value) for name, value in literal_pairs}
        unknown_literals = sorted(set(literal_fields) - set(field_types))
        if unknown_literals:
            raise RuntimeError(
                f"fixture {action} sets unknown literal fields {unknown_literals}"
            )
        raw_variables = set(
            re.findall(
                r"\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*action\.random\(\s*\)\s*;",
                source,
            )
        )
        raw_relations: list[dict[str, Any]] = []
        for field_name, variable in re.findall(
            r'\[\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*,\s*'
            r"([A-Za-z_][A-Za-z0-9_]*)\s*\]",
            source,
        ):
            if variable not in raw_variables:
                continue
            if field_types.get(field_name) != "Raw":
                raise RuntimeError(
                    f"fixture {action} assigns random Raw {variable} to non-Raw "
                    f"field {field_name}:{field_types.get(field_name)}"
                )
            expression = f"{variable}=action.random();{field_name}={variable}"
            raw_relations.append(
                {
                    "field": field_name,
                    "field_type": "Raw",
                    "variable": variable,
                    "producer_expression": expression,
                    "normalized_expression_sha256": sha256_text(expression),
                }
            )
        roles = direct_role_contract(source)
        schema_completeness = fixture_source_schema_contract(
            action, class_name, source, class_row
        )
        row["source_sha256"] = sha256_text(source)
        row["direct_roles"] = roles
        row["outputs"] = [role for role in roles if role["output_ordinal"] is not None]
        row["literal_fields"] = literal_fields
        row["field_types"] = field_types
        row["raw_relations"] = raw_relations
        row["schema_completeness"] = schema_completeness


def enrich_runtime_relation_hashes(
    positive: Sequence[dict[str, Any]],
    functions: Mapping[str, str],
) -> None:
    for scenario in positive:
        relations = scenario.get("output_relations")
        if not isinstance(relations, list):
            continue
        for relation in relations:
            if not isinstance(relation, dict):
                raise RuntimeError(f"invalid output relation in {scenario.get('name')}")
            normalized = str(relation["normalized_relation"])
            relation["normalized_relation_sha256"] = sha256_text(normalized)
            closure = relation.get("source_expression_closure")
            if not isinstance(closure, dict):
                raise RuntimeError(f"relation in {scenario.get('name')} lacks closure")
            path = closure.get("call_path")
            if not isinstance(path, list) or not all(name in functions for name in path):
                raise RuntimeError(
                    f"relation in {scenario.get('name')} has invalid call path {path}"
                )
            function_rows = [
                {"name": name, "production_sha256": sha256_text(functions[name])}
                for name in path
            ]
            closure["functions"] = function_rows
            closure["source_expression_sha256"] = sha256_text(
                "\n".join(functions[name] for name in path)
            )


def validate_fixture_location_system(
    fixture_rows: Sequence[Mapping[str, Any]],
    scenario_groups: Sequence[Sequence[Mapping[str, Any]]],
) -> None:
    """Reject equal-value and cross-fixture co-location drift before writing."""

    by_action = {str(row["action"]): row for row in fixture_rows}
    location_fields = {
        "MicroverseShip": ("x", "y", "z", "epoch"),
        "MicroverseSector": ("x", "y", "z", "epoch"),
        "MicroverseCelestialBody": (
            "sector_x", "sector_y", "sector_z", "sector_epoch"
        ),
        "MicroverseLifeSignal": (
            "sector_x", "sector_y", "sector_z", "origin_epoch"
        ),
        "MicroverseCompositeResource": (
            "sector_x", "sector_y", "sector_z", "origin_epoch"
        ),
        "MicroverseCivilization": (
            "sector_x", "sector_y", "sector_z", "origin_epoch"
        ),
    }
    for row in fixture_rows:
        class_name = str(row["class"])
        fields = row.get("literal_fields")
        if not isinstance(fields, Mapping):
            raise RuntimeError(f"fixture {row['action']} lacks literal_fields")
        location_code = row.get("location_code")
        if class_name in location_fields and isinstance(location_code, int):
            expected = FIXTURE_LOCATIONS[location_code]
            actual = tuple(int(fields[name]) for name in location_fields[class_name])
            if actual != expected:
                raise RuntimeError(
                    f"fixture {row['action']} location drift: expected={expected}, "
                    f"actual={actual}"
                )
        for prefix in ("", "sector_", "destination_", "endpoint_a_", "endpoint_b_"):
            names = tuple(f"{prefix}{axis}" for axis in ("x", "y", "z"))
            if all(name in fields for name in names):
                values = tuple(int(fields[name]) for name in names)
                if row.get("kind", "").startswith("sealed_"):
                    continue
                if len(set(values)) != 3:
                    raise RuntimeError(
                        f"fixture {row['action']} has non-distinct {prefix}axes {values}"
                    )
    co_located_classes = {
        "MicroverseSector",
        "MicroverseCelestialBody",
        "MicroverseCompositeResource",
        "MicroverseLifeSignal",
        "MicroverseCivilization",
    }
    for scenarios in scenario_groups:
        for scenario in scenarios:
            rows = [
                by_action[action]
                for action in scenario.get("actions", [])
                if action in by_action
            ]
            ship_locations = {
                int(row["location_code"])
                for row in rows
                if row.get("class") == "MicroverseShip"
                and isinstance(row.get("location_code"), int)
            }
            paired_locations = {
                int(row["location_code"])
                for row in rows
                if row.get("class") in co_located_classes
                and isinstance(row.get("location_code"), int)
            }
            if (
                ship_locations
                and paired_locations
                and not paired_locations.issubset(ship_locations)
            ):
                raise RuntimeError(
                    f"scenario {scenario.get('name')} has co-location drift: "
                    f"ship={sorted(ship_locations)}, paired={sorted(paired_locations)}"
                )


def representative_real_targets(
    index_actions: Sequence[Mapping[str, Any]],
    skill_catalog: Mapping[str, Any],
    expansion_resource_actions: Sequence[str] | set[str],
) -> dict[str, Any]:
    by_family: dict[str, list[Mapping[str, Any]]] = {}
    by_name: dict[str, Mapping[str, Any]] = {}
    for row in index_actions:
        family = str(row.get("family", "unknown"))
        name = str(row.get("name"))
        by_family.setdefault(family, []).append(row)
        by_name[name] = row

    # These are the families absent from the preserved pre-expansion action
    # contract.  Keeping the list explicit makes design drift visible rather
    # than allowing a token heuristic to silently omit a novel mechanic.
    new_structural_families = (
        "analyze_resource",
        "assemble_causal_transit_node",
        "capture_position_anchor",
        "capture_time_anchor",
        "compile_position_atlas",
        "compose_rendezvous_coordinate",
        "construct_temporal_link",
        "construct_wormhole_link",
        "craft_component",
        "develop_derived_skill",
        "extract_epoch_chart",
        "extract_position_chart",
        "fabricate_component",
        "reveal_epoch_chart",
        "reveal_position_chart",
        "traverse_temporal_link",
        "traverse_wormhole_link",
        "warp_ship_to_epoch_chart",
        "warp_ship_to_position_chart",
        "warp_to_rendezvous_coordinate",
    )
    missing_families = sorted(set(new_structural_families) - set(by_family))
    if missing_families:
        raise RuntimeError(
            f"representative target inventory lacks new families {missing_families}"
        )
    expansion_resource_action_set = set(expansion_resource_actions)
    unknown_resource_actions = sorted(
        expansion_resource_action_set - set(by_name)
    )
    if unknown_resource_actions:
        raise RuntimeError(
            "representative resource samples contain actions absent from "
            f"the production index: {unknown_resource_actions[:20]}"
        )

    targets_by_name: dict[str, dict[str, Any]] = {}

    def role_count(row: Mapping[str, Any], mode: str | None = None) -> int:
        roles = row.get("roles")
        if not isinstance(roles, list):
            return 0
        if mode is None:
            return len(roles)
        return sum(
            1
            for role in roles
            if isinstance(role, Mapping) and role.get("mode") == mode
        )

    def add(row: Mapping[str, Any], reason: str) -> None:
        name = str(row.get("name"))
        target = targets_by_name.get(name)
        if target is None:
            target = {
                "action": name,
                "family": str(row.get("family")),
                "role_count": role_count(row),
                "input_role_count": role_count(row, "input"),
                "selection": reason,
            }
            targets_by_name[name] = target
        elif reason not in str(target["selection"]).split("; "):
            target["selection"] = f"{target['selection']}; {reason}"

    def structural_samples(rows: Sequence[Mapping[str, Any]]) -> list[Mapping[str, Any]]:
        if not rows:
            return []
        indexes = sorted({0, len(rows) // 2, len(rows) - 1})
        return [rows[index] for index in indexes]

    all_variant_families = {
        "traverse_temporal_link",
        "traverse_wormhole_link",
        "warp_ship_to_epoch_chart",
        "warp_ship_to_position_chart",
        "warp_to_rendezvous_coordinate",
    }
    separately_selected = {
        "analyze_resource",
        "assemble_causal_transit_node",
        "compile_position_atlas",
        "craft_component",
        "develop_derived_skill",
        "fabricate_component",
    }
    for family in new_structural_families:
        rows = by_family[family]
        if family in separately_selected:
            continue
        selected = rows if family in all_variant_families else structural_samples(rows)
        for row in selected:
            add(
                row,
                (
                    "all reusable/final/directional variants"
                    if family in all_variant_families
                    else "first/middle/last new-family structural sample"
                ),
            )

    # Component fabrication has paired reusable/final catalyst semantics.  Take
    # three components across the catalog and retain both modes for each.
    fabrication_rows = by_family["fabricate_component"]
    fabrication_groups: dict[str, list[Mapping[str, Any]]] = {}
    for row in fabrication_rows:
        base = re.sub(r"(?:Reusable|Final)$", "", str(row.get("name")))
        fabrication_groups.setdefault(base, []).append(row)
    group_names = list(fabrication_groups)
    for base in [group_names[index] for index in sorted({0, len(group_names) // 2, len(group_names) - 1})]:
        for row in fabrication_groups[base]:
            add(row, "paired reusable/final component fabrication sample")

    # Capability artifacts are authoritative in the skill catalog.  Sample
    # every capability action family rather than assuming they are all generic
    # craft actions.
    capability_by_family: dict[str, list[Mapping[str, Any]]] = {}
    capability_rows = skill_catalog.get("capability_artifacts", [])
    if not isinstance(capability_rows, list):
        raise RuntimeError("skill capability_artifacts must be a list")
    for capability in capability_rows:
        if not isinstance(capability, Mapping):
            continue
        action = str(capability.get("action"))
        row = by_name.get(action)
        if row is None:
            raise RuntimeError(f"capability action is absent from index: {action}")
        family = str(capability.get("action_family"))
        capability_by_family.setdefault(family, []).append(row)
    for family, rows in sorted(capability_by_family.items()):
        for row in structural_samples(rows):
            add(row, f"capability-artifact family sample ({family})")

    # One root development action proves the one-evidence shape; derived
    # specialization/mastery actions cover two and three resource-evidence
    # shapes respectively.
    evidence_shapes: dict[int, Mapping[str, Any]] = {}
    for row in by_family.get("develop_technology_skill", []):
        if role_count(row, "input") == 1:
            evidence_shapes.setdefault(1, row)
    for row in by_family["develop_derived_skill"]:
        roles = row.get("roles", [])
        resource_inputs = sum(
            1
            for role in roles
            if isinstance(role, Mapping)
            and role.get("mode") == "input"
            and role.get("class") == "MicroverseResource"
        )
        if resource_inputs in {2, 3}:
            evidence_shapes.setdefault(resource_inputs, row)
    if set(evidence_shapes) != {1, 2, 3}:
        raise RuntimeError(
            f"expected 1/2/3-evidence skill shapes, found {sorted(evidence_shapes)}"
        )
    for evidence_count, row in sorted(evidence_shapes.items()):
        add(row, f"skill development {evidence_count}-evidence shape")

    # Resource extraction/refinement predate the new structural-family list,
    # but the v2 catalog adds hundreds of new routes. Select only the exact
    # production actions retained by the catalog-driven resource shard; this
    # prevents legacy rows from being mislabeled as expansion coverage.
    sampled_resource_actions: set[str] = set()
    for family in (
        "extract_civilization_tech_resource",
        "refine_resource",
    ):
        rows = [
            row
            for row in by_family.get(family, [])
            if str(row.get("name")) in expansion_resource_action_set
        ]
        if len(rows) < 3:
            raise RuntimeError(
                f"expected at least three retained v2 {family} actions, "
                f"found {len(rows)}"
            )
        for row in structural_samples(rows):
            sampled_resource_actions.add(str(row.get("name")))
            add(row, "first/middle/last retained v2 resource-route sample")

    # Role count is the best static proxy for payload pressure before proofs.
    # Include a maximum-arity member of every new family so the later plan/proof
    # runs measure the structural worst cases instead of only easy wrappers.
    for family in new_structural_families:
        rows = by_family[family]
        maximum = max(role_count(row) for row in rows)
        candidate = next(row for row in rows if role_count(row) == maximum)
        add(candidate, "highest-arity family sample")

    targets = list(targets_by_name.values())
    if len(targets) != 52:
        raise RuntimeError(
            f"representative expansion target count drifted: {len(targets)} != 52"
        )
    selected_family_counts = Counter(row["family"] for row in targets)
    return {
        "policy": (
            "Targets are for reachable-state --target-real execution against "
            "the real production PEXE only. Test fixtures are prohibited. "
            "Proofs remain local and are never submitted. Target actions still "
            "require production-reachable prerequisite chains."
        ),
        "new_structural_families": list(new_structural_families),
        "new_structural_family_coverage": {
            family: selected_family_counts.get(family, 0)
            for family in new_structural_families
        },
        "skill_evidence_shapes": [1, 2, 3],
        "retained_v2_resource_sample_actions": sorted(
            sampled_resource_actions
        ),
        "all_resource_samples_are_catalog_retained": (
            sampled_resource_actions <= expansion_resource_action_set
        ),
        "maximum_selected_role_count": max(row["role_count"] for row in targets),
        "target_count": len(targets),
        "targets": targets,
    }


def generate(
    production_root: Path,
    output: Path,
    *,
    catalog_dir: Path | None = None,
) -> dict[str, Any]:
    plugin_path = production_root / "plugin.rhai"
    manifest_path = production_root / "manifest.toml"
    catalog_dir = catalog_dir or production_root / "catalog"
    resource_path = catalog_dir / "microverse-resource-tree-v2.json"
    component_path = catalog_dir / "microverse-component-tree-v2.json"
    skill_path = catalog_dir / "microverse-skill-tree-v2.json"
    warp_path = catalog_dir / "microverse-warp-tree-v2.json"
    index_path = catalog_dir / "microverse-catalog-index-v2.json"
    schema_counts_path = production_root / "generated" / "schema-counts.json"
    universe_contract_path = production_root / "generated" / "universe-contract.json"
    action_contract_path = production_root / "generated" / "action-contract.json"
    for path in (
        plugin_path,
        manifest_path,
        resource_path,
        component_path,
        skill_path,
        warp_path,
        index_path,
        schema_counts_path,
        universe_contract_path,
        action_contract_path,
    ):
        if not path.exists():
            raise RuntimeError(f"missing required production input: {path}")

    production_plugin = plugin_path.read_text(encoding="utf-8")
    production_manifest = manifest_path.read_text(encoding="utf-8")
    resource_catalog = load_json(resource_path)
    component_catalog = load_json(component_path)
    skill_catalog = load_json(skill_path)
    warp_catalog = load_json(warp_path)
    index = load_json(index_path)
    schema_counts = load_json(schema_counts_path)
    universe_contract = load_json(universe_contract_path)
    action_contract = load_json(action_contract_path)
    if not all(
        isinstance(value, Mapping)
        for value in (
            resource_catalog,
            component_catalog,
            skill_catalog,
            warp_catalog,
            index,
            schema_counts,
            universe_contract,
            action_contract,
        )
    ):
        raise RuntimeError("all canonical expansion catalogs must be JSON objects")
    production_actions = validator.manifest_action_names(production_manifest)
    production_action_set = set(production_actions)
    functions = validator.extract_rhai_functions(production_plugin)
    missing = sorted(production_action_set - set(functions))
    if missing:
        raise RuntimeError(f"production actions missing source functions: {missing[:20]}")
    validate_explicit_selection_metadata(index, universe_contract, action_contract)

    fixtures = FixtureRegistry()
    resource_positive, resource_negative, resource_required = resource_scenarios(
        resource_catalog,
        fixtures,
        production_action_set,
    )
    component_positive, component_negative, component_required = component_scenarios(
        component_catalog,
        fixtures,
        production_action_set,
    )
    skill_positive, skill_negative, skill_required = skill_scenarios(
        skill_catalog,
        component_catalog,
        index,
        fixtures,
        production_action_set,
    )
    (
        warp_positive,
        warp_negative,
        warp_required,
        explicit_reveal_representatives,
    ) = warp_lifecycle_scenarios(
        warp_catalog,
        resource_catalog,
        fixtures,
        production_action_set,
    )
    warp_tree_actions = warp_tree_action_names(warp_catalog)
    warp_setup_actions = {"UseTechnologySkill"}
    expected_warp_required = warp_tree_actions | SELECTION_MILESTONE_ACTIONS
    if warp_required != expected_warp_required:
        raise RuntimeError(
            "warp required-action set is not the exact 622-action tree plus "
            "8 selection milestones"
        )
    if not (
        warp_tree_actions | warp_setup_actions | SELECTION_MILESTONE_ACTIONS
    ).issubset(production_action_set):
        raise RuntimeError("warp tree/setup/selection actions are absent from production")
    output.mkdir(parents=True, exist_ok=True)
    generated = output / "generated"
    generated.mkdir(parents=True, exist_ok=True)
    module_hash = production_module_hash(production_manifest)
    production_plugin_sha256 = sha256_text(production_plugin)
    production_manifest_sha256 = sha256_text(production_manifest)
    hash_bindings = {
        "production_plugin_sha256": production_plugin_sha256,
        "production_manifest_sha256": production_manifest_sha256,
        "production_module_hash": module_hash,
        "production_warp_catalog_sha256": sha256_path(warp_path),
        "production_catalog_index_sha256": sha256_path(index_path),
        "production_schema_counts_sha256": sha256_path(schema_counts_path),
        "production_universe_contract_sha256": sha256_path(
            universe_contract_path
        ),
        "production_action_contract_sha256": sha256_path(action_contract_path),
        "paths": {
            "production_plugin_sha256": "plugin.rhai",
            "production_manifest_sha256": "manifest.toml",
            "production_warp_catalog_sha256": "catalog/microverse-warp-tree-v2.json",
            "production_catalog_index_sha256": "catalog/microverse-catalog-index-v2.json",
            "production_schema_counts_sha256": "generated/schema-counts.json",
            "production_universe_contract_sha256": "generated/universe-contract.json",
            "production_action_contract_sha256": "generated/action-contract.json",
        },
    }
    actual_final_hashes = {
        key: value for key, value in hash_bindings.items() if key in FINAL_PRODUCTION_HASHES
    }
    if actual_final_hashes != FINAL_PRODUCTION_HASHES:
        raise RuntimeError(
            "production inputs do not match the approved final source tuple: "
            f"expected={FINAL_PRODUCTION_HASHES}, actual={actual_final_hashes}"
        )
    fixture_sources_by_name = {
        str(row["action"]): source
        for row, source in zip(fixtures.rows, fixtures.sources, strict=True)
    }
    enrich_fixture_contract_rows(fixtures.rows, fixture_sources_by_name, schema_counts)
    enrich_runtime_relation_hashes(warp_positive, functions)
    validate_fixture_location_system(
        fixtures.rows,
        (
            resource_positive,
            resource_negative,
            component_positive,
            component_negative,
            skill_positive,
            skill_negative,
            warp_positive,
            warp_negative,
        ),
    )
    index_actions = validator.action_rows(index)
    family_by_action = {
        str(row.get("name")): str(row.get("family")) for row in index_actions
    }
    index_actions_by_name = {
        str(row.get("name")): row for row in index_actions
    }
    for action, expected_roles in SHAPE_J_CONSTRUCTOR_ROLE_CONTRACTS.items():
        row = index_actions_by_name.get(action)
        expected_role_rows = [
            {"mode": mode, "class": class_name}
            for mode, class_name in expected_roles
        ]
        actual_role_rows = row.get("roles") if isinstance(row, Mapping) else None
        source_roles = re.findall(
            r'\baction\.(output|input|mutate)\s*\(\s*"([^"]+)"\s*\)',
            functions[action],
        )
        if actual_role_rows != expected_role_rows or source_roles != list(expected_roles):
            raise RuntimeError(
                f"{action}: Shape J role contract mismatch: "
                f"index={actual_role_rows}, source={source_roles}, "
                f"expected={expected_role_rows}"
            )
    write_utf8(
        generated / "production-plan-actions.json",
        stable_json(
            production_plan_inventory(
                production_root,
                production_actions,
                family_by_action,
                production_plugin_sha256=production_plugin_sha256,
                production_manifest_sha256=production_manifest_sha256,
            )
        ),
    )
    representative_targets = representative_real_targets(
        index_actions,
        skill_catalog,
        resource_required,
    )
    write_utf8(
        generated / "representative-real-proof-targets.json",
        stable_json(representative_targets),
    )

    fixture_rows_by_name = {str(row["action"]): row for row in fixtures.rows}
    fixture_sources_by_name = {
        str(row["action"]): source
        for row, source in zip(fixtures.rows, fixtures.sources, strict=True)
    }
    for representative in explicit_reveal_representatives:
        decoy = fixture_rows_by_name.get(
            str(representative["state_pressure_decoy_fixture"])
        )
        if (
            not isinstance(decoy, Mapping)
            or decoy.get("class") != "MicroverseCelestialBody"
            or decoy.get("output_only") is not True
        ):
            raise RuntimeError(
                f"{representative['name']}: state-pressure decoy must be an "
                "output-only MicroverseCelestialBody fixture"
            )
    shard_specs = {
        "resource": {
            "positive": resource_positive,
            "negative": resource_negative,
            "required": resource_required,
            "representatives": [],
        },
        "component": {
            "positive": component_positive,
            "negative": component_negative,
            "required": component_required,
            "representatives": [],
        },
        "skill": {
            "positive": skill_positive,
            "negative": skill_negative,
            "required": skill_required,
            "representatives": [],
        },
        "warp": {
            "positive": warp_positive,
            "negative": warp_negative,
            "required": warp_required,
            "representatives": explicit_reveal_representatives,
        },
    }
    shard_audits: list[dict[str, Any]] = []
    for shard_name, spec in shard_specs.items():
        positive = spec["positive"]
        negative = spec["negative"]
        representatives = spec["representatives"]
        referenced_names = {
            str(action)
            for scenario in positive + negative
            for action in scenario["actions"]
        }
        for scenario in representatives:
            referenced_names.add(str(scenario["fixture"]))
            referenced_names.add(str(scenario["ship_fixture"]))
            referenced_names.add(str(scenario["state_pressure_decoy_fixture"]))
        retained_actions = referenced_names & production_action_set
        for scenario in representatives:
            covered_actions = scenario.get("covered_actions")
            if not isinstance(covered_actions, list):
                raise RuntimeError(
                    f"{shard_name}: explicit reveal representative lacks covered_actions"
                )
            retained_actions.update(str(action) for action in covered_actions)
        if shard_name == "warp":
            expected_retained = (
                warp_tree_actions
                | warp_setup_actions
                | SELECTION_MILESTONE_ACTIONS
            )
            if retained_actions != expected_retained:
                raise RuntimeError(
                    "warp retained action set drift: "
                    f"missing={sorted(expected_retained-retained_actions)[:20]}, "
                    f"extra={sorted(retained_actions-expected_retained)[:20]}"
                )
        fixture_names = referenced_names - production_action_set
        unknown_fixtures = fixture_names - set(fixture_rows_by_name)
        if unknown_fixtures:
            raise RuntimeError(
                f"{shard_name} scenarios reference unknown fixtures: "
                f"{sorted(unknown_fixtures)[:20]}"
            )
        fixture_rows = [
            row for row in fixtures.rows if row["action"] in fixture_names
        ]
        fixture_source = "".join(
            fixture_sources_by_name[str(row["action"])] for row in fixture_rows
        )

        subset = production_source_subset(
            production_plugin,
            functions,
            production_actions,
            retained_actions,
        )
        if shard_name == "warp":
            production_vdf_helpers = {
                name
                for name, function in functions.items()
                if name not in production_action_set
                and "action.intro_vdf(" in function
            }
            if production_vdf_helpers != WARP_SHARD_APPROVED_VDF_HELPERS:
                raise RuntimeError(
                    "warp shard VDF-helper inventory drift: "
                    f"missing={sorted(WARP_SHARD_APPROVED_VDF_HELPERS-production_vdf_helpers)}, "
                    f"extra={sorted(production_vdf_helpers-WARP_SHARD_APPROVED_VDF_HELPERS)}"
                )
        transformed_plugin, removed_total = remove_vdf_blocks(subset, shard_name)
        test_functions = validator.extract_rhai_functions(transformed_plugin)
        parity_rows: list[dict[str, Any]] = []
        parity_removed = 0
        reachable_helper_names: set[str] = set()
        for action in sorted(retained_actions):
            original = functions[action]
            transformed, removed = remove_vdf_blocks(original, action)
            parity_removed += removed
            roles = direct_role_contract(original)
            indexed_action = index_actions_by_name.get(action)
            indexed_roles = (
                indexed_action.get("roles")
                if isinstance(indexed_action, Mapping)
                else None
            )
            role_shape = [
                {"mode": row["mode"], "class": row["class"]} for row in roles
            ]
            if indexed_roles != role_shape:
                raise RuntimeError(
                    f"{shard_name}:{action} source/index role mismatch: "
                    f"source={role_shape}, index={indexed_roles}"
                )
            closure, call_paths = transitive_helper_contract(
                action,
                functions,
                test_functions,
                production_action_set,
            )
            reachable_helper_names.update(closure)
            parity_rows.append(
                {
                    "action": action,
                    "symbol": action,
                    "kind": "production_action",
                    "scope": (
                        "tree"
                        if action in warp_tree_actions and shard_name == "warp"
                        else (
                            "setup"
                            if action in warp_setup_actions and shard_name == "warp"
                            else (
                                "selection_milestone"
                                if action in SELECTION_MILESTONE_ACTIONS
                                and shard_name == "warp"
                                else "shard"
                            )
                        )
                    ),
                    "production_sha256": sha256_text(original),
                    "test_sha256": sha256_text(test_functions[action]),
                    "vdf_blocks_removed": removed,
                    "only_approved_transform": True,
                    "retained_verbatim_except_vdf": True,
                    "direct_roles": roles,
                    "outputs": [
                        row for row in roles if row["output_ordinal"] is not None
                    ],
                    "direct_helpers": direct_helper_calls(
                        action, functions, production_action_set
                    ),
                    "transitive_helper_closure": closure,
                    "helper_call_paths": call_paths,
                }
            )
        # A shared straight-line helper may own the VDF block used by many
        # fixed wrappers (the v2 chart reveal cores do this).  Audit those
        # helper transforms explicitly instead of assuming every VDF lives in
        # an action wrapper.
        subset_functions = validator.extract_rhai_functions(subset)
        if shard_name == "warp":
            subset_vdf_helpers = {
                name
                for name, function in subset_functions.items()
                if name not in production_action_set
                and "action.intro_vdf(" in function
            }
            if subset_vdf_helpers != WARP_SHARD_APPROVED_VDF_HELPERS:
                raise RuntimeError(
                    "warp shard subset VDF-helper inventory drift: "
                    f"missing={sorted(WARP_SHARD_APPROVED_VDF_HELPERS-subset_vdf_helpers)}, "
                    f"extra={sorted(subset_vdf_helpers-WARP_SHARD_APPROVED_VDF_HELPERS)}"
                )
        for helper, original in sorted(subset_functions.items()):
            if helper in production_action_set or "action.intro_vdf(" not in original:
                continue
            transformed, removed = remove_vdf_blocks(original, helper)
            parity_removed += removed
            closure, call_paths = transitive_helper_contract(
                helper,
                functions,
                test_functions,
                production_action_set,
            )
            reachable_helper_names.update(closure)
            parity_rows.append(
                {
                    "action": helper,
                    "symbol": helper,
                    "kind": "production_helper",
                    "scope": "helper",
                    "production_sha256": sha256_text(original),
                    "test_sha256": sha256_text(test_functions[helper]),
                    "vdf_blocks_removed": removed,
                    "only_approved_transform": True,
                    "retained_verbatim_except_vdf": True,
                    "direct_roles": [],
                    "outputs": [],
                    "direct_helpers": direct_helper_calls(
                        helper, functions, production_action_set
                    ),
                    "transitive_helper_closure": closure,
                    "helper_call_paths": call_paths,
                }
            )
            reachable_helper_names.add(helper)
        if parity_removed != removed_total:
            raise RuntimeError(
                f"{shard_name}: unaudited VDF block outside retained production symbols: "
                f"plugin={removed_total}, action sum={parity_removed}"
            )
        helper_bindings = [
            {
                "symbol": helper,
                "production_sha256": sha256_text(functions[helper]),
                "test_sha256": sha256_text(test_functions[helper]),
                "vdf_blocks_removed": (
                    functions[helper].count("action.intro_vdf(")
                    - test_functions[helper].count("action.intro_vdf(")
                ),
                "direct_helpers": direct_helper_calls(
                    helper, functions, production_action_set
                ),
            }
            for helper in sorted(reachable_helper_names)
        ]
        if len(helper_bindings) != len({row["symbol"] for row in helper_bindings}):
            raise RuntimeError(f"{shard_name}: duplicate helper binding symbols")
        shard_plugin = transformed_plugin.rstrip() + "\n" + fixture_source
        package_name = f"{TEST_PACKAGE_NAME}-{shard_name}"
        shard_manifest = test_manifest(
            production_manifest,
            fixture_rows,
            package_name=package_name,
            retained_actions=retained_actions,
        )
        plugin_bytes = len(shard_plugin.encode("utf-8"))
        if plugin_bytes > 990_000:
            raise RuntimeError(
                f"{shard_name} test plugin is {plugin_bytes} bytes, above the "
                "990,000-byte safety limit"
            )

        if shard_name == "warp":
            representative_covered = {
                str(action)
                for scenario in representatives
                for action in scenario["covered_actions"]
            }
            production_parity_count = sum(
                row["kind"] == "production_action" for row in parity_rows
            )
            helper_parity_count = sum(
                row["kind"] == "production_helper" for row in parity_rows
            )
            helper_parity_symbols = {
                str(row["symbol"])
                for row in parity_rows
                if row["kind"] == "production_helper"
            }
            if helper_parity_symbols != WARP_SHARD_APPROVED_VDF_HELPERS:
                raise RuntimeError(
                    "warp shard helper-parity inventory drift: "
                    f"missing={sorted(WARP_SHARD_APPROVED_VDF_HELPERS-helper_parity_symbols)}, "
                    f"extra={sorted(helper_parity_symbols-WARP_SHARD_APPROVED_VDF_HELPERS)}"
                )
            exact_counts = {
                "tree": len(warp_tree_actions),
                "setup": len(warp_setup_actions),
                "selection_milestones": len(SELECTION_MILESTONE_ACTIONS),
                "retained": len(retained_actions),
                "production_parity": production_parity_count,
                "helper_parity": helper_parity_count,
                "parity": len(parity_rows),
                "fixtures": len(fixture_rows),
                "positive": len(positive),
                "negative": len(negative),
                "explicit_reveal_representatives": len(representatives),
                "explicit_reveal_actions": len(representative_covered),
            }
            expected_counts = {
                "tree": 622,
                "setup": 1,
                "selection_milestones": 8,
                "retained": 631,
                "production_parity": 631,
                "helper_parity": 45,
                "parity": 676,
                "fixtures": 89,
                "positive": 60,
                "negative": 70,
                "explicit_reveal_representatives": 4,
                "explicit_reveal_actions": 595,
            }
            if exact_counts != expected_counts:
                raise RuntimeError(
                    f"warp shard exact-count contract drift: expected="
                    f"{expected_counts}, actual={exact_counts}"
                )

        shard_root = output / shard_name
        shard_generated = shard_root / "generated"
        shard_generated.mkdir(parents=True, exist_ok=True)
        shard_plugin_path = shard_root / "plugin.rhai"
        shard_manifest_path = shard_root / "manifest.toml"
        write_utf8(shard_plugin_path, shard_plugin)
        write_utf8(shard_manifest_path, shard_manifest)
        disk_plugin = shard_plugin_path.read_bytes()
        disk_manifest = shard_manifest_path.read_bytes()
        if (
            len(disk_plugin) != plugin_bytes
            or hashlib.sha256(disk_plugin).hexdigest()
            != sha256_text(shard_plugin)
            or len(disk_manifest) != len(shard_manifest.encode("utf-8"))
            or hashlib.sha256(disk_manifest).hexdigest()
            != sha256_text(shard_manifest)
        ):
            raise RuntimeError(
                f"{shard_name}: on-disk source bytes differ from audited LF bytes"
            )
        contract = {
            "schema_version": 1,
            "warning": "TEST ONLY. NEVER RELEASE OR INSTALL AS PRODUCTION.",
            "shard": shard_name,
            "production_module_hash": module_hash,
            "production_plugin_sha256": production_plugin_sha256,
            "production_manifest_sha256": production_manifest_sha256,
            **{
                key: value
                for key, value in hash_bindings.items()
                if key != "paths"
            },
            "hash_bindings": hash_bindings,
            "production_action_count": len(production_actions),
            "retained_production_action_count": len(retained_actions),
            "tree_action_count": (
                len(warp_tree_actions) if shard_name == "warp" else 0
            ),
            "setup_action_count": (
                len(warp_setup_actions) if shard_name == "warp" else 0
            ),
            "selection_milestone_action_count": (
                len(SELECTION_MILESTONE_ACTIONS) if shard_name == "warp" else 0
            ),
            "selection_milestone_actions": (
                sorted(SELECTION_MILESTONE_ACTIONS)
                if shard_name == "warp"
                else []
            ),
            "tree_actions": (
                sorted(warp_tree_actions) if shard_name == "warp" else []
            ),
            "setup_actions": (
                sorted(warp_setup_actions) if shard_name == "warp" else []
            ),
            "required_action_coverage": sorted(spec["required"]),
            "positive": positive,
            "negative": negative,
            "explicit_reveal_representatives": representatives,
            "coverage_by_family": {
                f"{shard_name}_positive": len(positive),
                f"{shard_name}_negative": len(negative),
            },
        }
        write_utf8(
            shard_generated / "expansion-test-contract.json",
            stable_json(contract),
        )
        write_utf8(
            shard_generated / "source-parity.json",
            stable_json(
                {
                    "schema_version": 2,
                    **{
                        key: value
                        for key, value in hash_bindings.items()
                        if key != "paths"
                    },
                    "hash_bindings": hash_bindings,
                    "tree_action_count": (
                        len(warp_tree_actions) if shard_name == "warp" else 0
                    ),
                    "setup_action_count": (
                        len(warp_setup_actions) if shard_name == "warp" else 0
                    ),
                    "selection_milestone_action_count": (
                        len(SELECTION_MILESTONE_ACTIONS)
                        if shard_name == "warp"
                        else 0
                    ),
                    "selection_milestone_actions": (
                        sorted(SELECTION_MILESTONE_ACTIONS)
                        if shard_name == "warp"
                        else []
                    ),
                    "production_action_row_count": sum(
                        row["kind"] == "production_action" for row in parity_rows
                    ),
                    "vdf_helper_row_count": sum(
                        row["kind"] == "production_helper" for row in parity_rows
                    ),
                    "parity_row_count": len(parity_rows),
                    "vdf_blocks_removed": removed_total,
                    "vdf_helper_symbols": sorted(
                        row["symbol"]
                        for row in parity_rows
                        if row["kind"] == "production_helper"
                    ),
                    "vdf_helper_symbols_sha256": hashlib.sha256(
                        (
                            "\n".join(
                                sorted(
                                    row["symbol"]
                                    for row in parity_rows
                                    if row["kind"] == "production_helper"
                                )
                            )
                            + "\n"
                        ).encode("utf-8")
                    ).hexdigest(),
                    "actions": parity_rows,
                    "helper_bindings": helper_bindings,
                }
            ),
        )
        runtime_output_relations = [
            {
                "scenario": scenario["name"],
                "target_action": scenario["actions"][-1],
                "relations": scenario["output_relations"],
            }
            for scenario in positive
            if "output_relations" in scenario
        ]
        write_utf8(
            shard_generated / "fixture-catalog.json",
            stable_json(
                {
                    "schema_version": 2,
                    **{
                        key: value
                        for key, value in hash_bindings.items()
                        if key != "paths"
                    },
                    "hash_bindings": hash_bindings,
                    "fixtures": fixture_rows,
                    "runtime_output_relations": runtime_output_relations,
                }
            ),
        )
        if representatives:
            write_utf8(
                shard_generated / "warp-coordinate-contract.json",
                stable_json(
                    {
                        "schema_version": 2,
                        **{
                            key: value
                            for key, value in hash_bindings.items()
                            if key != "paths"
                        },
                        "hash_bindings": hash_bindings,
                        "v1": warp_catalog.get("v1"),
                        "v2": warp_catalog.get("v2"),
                    }
                ),
            )
        shard_audit = {
            "status": "pass",
            "shard": shard_name,
            "package": package_name,
            "retained_production_action_count": len(retained_actions),
            "fixture_action_count": len(fixture_rows),
            "positive_scenario_count": len(positive),
            "negative_scenario_count": len(negative),
            "explicit_reveal_representative_scenario_count": len(
                representatives
            ),
            "vdf_blocks_removed": removed_total,
            "plugin_bytes": plugin_bytes,
            "manifest_bytes": len(shard_manifest.encode("utf-8")),
            "plugin_sha256": sha256_text(shard_plugin),
            "manifest_sha256": sha256_text(shard_manifest),
            "production_plugin_sha256": production_plugin_sha256,
            "production_manifest_sha256": production_manifest_sha256,
            **{
                key: value
                for key, value in hash_bindings.items()
                if key != "paths"
            },
            "hash_bindings": hash_bindings,
            "tree_action_count": (
                len(warp_tree_actions) if shard_name == "warp" else 0
            ),
            "setup_action_count": (
                len(warp_setup_actions) if shard_name == "warp" else 0
            ),
            "selection_milestone_action_count": (
                len(SELECTION_MILESTONE_ACTIONS) if shard_name == "warp" else 0
            ),
            "selection_milestone_actions": (
                sorted(SELECTION_MILESTONE_ACTIONS)
                if shard_name == "warp"
                else []
            ),
            "source_parity_row_count": len(parity_rows),
            "source_parity_helper_count": sum(
                row["kind"] == "production_helper" for row in parity_rows
            ),
            "source_parity_vdf_helper_symbols": sorted(
                row["symbol"]
                for row in parity_rows
                if row["kind"] == "production_helper"
            ),
            "source_parity_vdf_helper_symbols_sha256": hashlib.sha256(
                (
                    "\n".join(
                        sorted(
                            row["symbol"]
                            for row in parity_rows
                            if row["kind"] == "production_helper"
                        )
                    )
                    + "\n"
                ).encode("utf-8")
            ).hexdigest(),
            "source_parity_vdf_blocks_removed": sum(
                int(row["vdf_blocks_removed"]) for row in parity_rows
            ),
        }
        write_utf8(
            shard_generated / "static-audit.json",
            stable_json(shard_audit),
        )
        shard_audits.append(shard_audit)

    write_utf8(
        generated / "shards.json",
        stable_json(
            {
                "schema_version": 1,
                "warning": "TEST ONLY. NEVER RELEASE OR INSTALL AS PRODUCTION.",
                "shards": [
                    {"name": row["shard"], "root": row["shard"]}
                    for row in shard_audits
                ],
            }
        ),
    )
    audit = {
        "status": "pass",
        "warning": "TEST ONLY. NEVER RELEASE OR INSTALL AS PRODUCTION.",
        "production_root": str(production_root),
        "output": str(output),
        "production_module_hash": module_hash,
        "production_plugin_sha256": production_plugin_sha256,
        "production_manifest_sha256": production_manifest_sha256,
        **{
            key: value
            for key, value in hash_bindings.items()
            if key != "paths"
        },
        "hash_bindings": hash_bindings,
        "production_action_count": len(production_actions),
        "representative_real_target_count": representative_targets["target_count"],
        "shard_count": len(shard_audits),
        "fixture_action_count_unioned": len(fixtures.rows),
        "positive_scenario_count": sum(len(spec["positive"]) for spec in shard_specs.values()),
        "negative_scenario_count": sum(len(spec["negative"]) for spec in shard_specs.values()),
        "covered_production_action_count": len(
            resource_required | component_required | skill_required | warp_required
        ),
        "explicit_reveal_representative_scenario_count": len(
            explicit_reveal_representatives
        ),
        "largest_shard_plugin_bytes": max(row["plugin_bytes"] for row in shard_audits),
        "shards": shard_audits,
        "sdk_modified": False,
        "submission_supported": False,
    }
    write_utf8(
        generated / "static-audit.json",
        stable_json(audit),
    )
    return audit


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--production-root", type=Path, default=ROOT)
    parser.add_argument(
        "--catalog-dir",
        type=Path,
        help="canonical catalog directory when the audited render is in a checkpoint",
    )
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args(argv)
    audit = generate(
        args.production_root.resolve(),
        args.output.resolve(),
        catalog_dir=args.catalog_dir.resolve() if args.catalog_dir else None,
    )
    print(stable_json(audit), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
