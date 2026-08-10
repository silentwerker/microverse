#!/usr/bin/env python3
"""Execute every generated production inspect-plan command, never proofs/submits."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import time
from typing import Any, Mapping, Sequence

import run_microverse_expansion_tests as expansion_runner


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PEXE = Path(r"C:\Users\Rich\.dobj\bin\pexe.exe")
DEFAULT_INVENTORY = (
    ROOT
    / "target"
    / "microverse-expansion-test"
    / "generated"
    / "production-plan-actions.json"
)
DEFAULT_OUTPUT = (
    ROOT
    / "target"
    / "microverse-expansion-test"
    / "generated"
    / "production-plan-results.json"
)


def stable_json(value: Any) -> str:
    return json.dumps(value, indent=2, sort_keys=True) + "\n"


def sha256_text(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def sha256_path(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def decode_plan_output(stdout: str) -> Mapping[str, Any] | None:
    """Decode the CLI's JSON plan output without retaining the full payload."""
    stripped = stdout.strip()
    if not stripped:
        return None
    candidates = [stripped]
    object_start = stripped.find("{")
    object_end = stripped.rfind("}")
    if object_start >= 0 and object_end > object_start:
        candidates.append(stripped[object_start : object_end + 1])
    for candidate in candidates:
        try:
            decoded = json.loads(candidate)
        except json.JSONDecodeError:
            continue
        if isinstance(decoded, Mapping):
            return decoded
    return None


def numeric_leaves(value: Any, prefix: str = "") -> dict[str, int | float]:
    leaves: dict[str, int | float] = {}
    if isinstance(value, bool):
        return leaves
    if isinstance(value, (int, float)):
        leaves[prefix or "value"] = value
    elif isinstance(value, Mapping):
        for key, child in value.items():
            child_prefix = f"{prefix}.{key}" if prefix else str(key)
            leaves.update(numeric_leaves(child, child_prefix))
    return leaves


def execute_inventory(
    pexe: Path,
    inventory: Mapping[str, Any],
    *,
    target: Path | None = None,
    progress_every: int = 50,
    max_subprocess_actions: int | None = 100,
) -> dict[str, Any]:
    rows = inventory.get("actions")
    if not isinstance(rows, list) or not rows:
        raise RuntimeError("production plan inventory must contain actions")
    if inventory.get("action_count") != len(rows):
        raise RuntimeError("production plan inventory action_count mismatch")
    if max_subprocess_actions is not None and len(rows) > max_subprocess_actions:
        raise RuntimeError(
            f"refusing {len(rows)} separate full-module PEXE subprocesses; "
            "use the reachable harness `synthetic-suite` single-process batch "
            "instead (or explicitly pass --allow-slow-subprocess-sweep)"
        )
    seen: set[str] = set()
    results: list[dict[str, Any]] = []
    started = time.perf_counter()
    for index, row in enumerate(rows, start=1):
        if not isinstance(row, Mapping):
            raise RuntimeError(f"invalid plan inventory row {index}")
        action = row.get("action")
        command = row.get("command")
        if not isinstance(action, str) or not action or action in seen:
            raise RuntimeError(f"invalid or duplicate plan action {action!r}")
        seen.add(action)
        if (
            not isinstance(command, list)
            or len(command) < 4
            or command[1:3] != ["inspect", "plan"]
            or command.count("--action") != 1
            or command[command.index("--action") + 1] != action
        ):
            raise RuntimeError(f"invalid inspect-plan command for {action}")
        command_tail = [str(item) for item in command[1:]]
        if target is not None:
            # Inventory commands are canonical ``pexe inspect plan TARGET ...``
            # rows.  Repoint TARGET to the already-built production archive so
            # all 1,650 calls avoid repeated source compilation.
            command_tail[2] = str(target)
        rendered = [str(pexe), *command_tail]
        expansion_runner.safe_command(rendered)
        action_started = time.perf_counter()
        completed = subprocess.run(
            rendered,
            cwd=ROOT,
            text=True,
            encoding="utf-8",
            errors="replace",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        result = {
            "action": action,
            "family": row.get("family"),
            "exit_code": completed.returncode,
            "seconds": time.perf_counter() - action_started,
            "stdout_sha256": sha256_text(completed.stdout),
            "stderr_sha256": sha256_text(completed.stderr),
        }
        decoded = decode_plan_output(completed.stdout)
        if decoded is not None:
            summary = decoded.get("summary")
            totals = decoded.get("totals")
            if summary is not None:
                result["summary"] = summary
            if totals is not None:
                result["totals"] = totals
        if completed.returncode != 0:
            result["stdout_tail"] = completed.stdout[-4_000:]
            result["stderr_tail"] = completed.stderr[-4_000:]
        results.append(result)
        if progress_every > 0 and (index % progress_every == 0 or index == len(rows)):
            print(
                f"inspect-plan progress {index}/{len(rows)}; "
                f"failures={sum(item['exit_code'] != 0 for item in results)}",
                file=sys.stderr,
                flush=True,
            )
    failures = [row["action"] for row in results if row["exit_code"] != 0]
    maxima: dict[str, dict[str, Any]] = {}
    parsed_totals = 0
    for row in results:
        if "totals" not in row:
            continue
        parsed_totals += 1
        for field, value in numeric_leaves(row["totals"]).items():
            previous = maxima.get(field)
            if previous is None or value > previous["value"]:
                maxima[field] = {"value": value, "action": row["action"]}
    return {
        "status": "pass" if not failures else "fail",
        "policy": "stock PEXE inspect plan only; no proof and no submission",
        "action_count": len(results),
        "passed": len(results) - len(failures),
        "failed": len(failures),
        "failed_actions": failures,
        "parsed_totals": parsed_totals,
        "max_totals": maxima,
        "seconds": time.perf_counter() - started,
        "results": results,
        "submission_attempts": 0,
    }


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pexe", type=Path, default=DEFAULT_PEXE)
    parser.add_argument("--inventory", type=Path, default=DEFAULT_INVENTORY)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--target",
        type=Path,
        help="already-built production .pexe archive used as every plan target",
    )
    parser.add_argument("--progress-every", type=int, default=50)
    parser.add_argument(
        "--allow-slow-subprocess-sweep",
        action="store_true",
        help=(
            "override the safety refusal for inventories over 100 actions; a "
            "single-process synthetic-suite is normally required"
        ),
    )
    args = parser.parse_args(argv)
    pexe = args.pexe.resolve()
    if not pexe.exists():
        raise RuntimeError(f"missing stock PEXE CLI: {pexe}")
    target = args.target.resolve() if args.target is not None else None
    if target is not None and not target.exists():
        raise RuntimeError(f"missing inspect-plan target: {target}")
    inventory = json.loads(args.inventory.resolve().read_text(encoding="utf-8"))
    if not isinstance(inventory, Mapping):
        raise RuntimeError("production plan inventory root must be an object")
    source_bindings = {
        "production_plugin_sha256": ROOT / "plugin.rhai",
        "production_manifest_sha256": ROOT / "manifest.toml",
    }
    for field, path in source_bindings.items():
        expected = inventory.get(field)
        actual = sha256_path(path)
        if expected != actual:
            raise RuntimeError(
                f"stale production plan inventory: {field}={expected!r}, "
                f"current {path.name}={actual}"
            )
    result = execute_inventory(
        pexe,
        inventory,
        target=target,
        progress_every=args.progress_every,
        max_subprocess_actions=(
            None if args.allow_slow_subprocess_sweep else 100
        ),
    )
    result["pexe_cli"] = str(pexe)
    result["pexe_cli_sha256"] = sha256_path(pexe)
    result["inspect_target"] = str(target) if target is not None else str(ROOT)
    result["inspect_target_sha256"] = (
        sha256_path(target) if target is not None and target.is_file() else None
    )
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(stable_json(result), encoding="utf-8")
    print(stable_json({key: value for key, value in result.items() if key != "results"}), end="")
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
