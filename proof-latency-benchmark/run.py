#!/usr/bin/env python3
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import uuid


ROOT = Path(__file__).resolve().parent
FIXTURES = ROOT / "fixtures"
HARNESS_SOURCE = ROOT / "harness"
WORK = ROOT / ".work"
LIBS = ("payload", "pexe", "pod2utils", "sdk", "txlib")


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def action_blocks(path):
    blocks = {}
    for block in re.findall(
        rb"(?ms)^\[\[actions\]\]\r?\n.*?(?=^\[\[actions\]\]|\Z)",
        path.read_bytes(),
    ):
        match = re.search(rb'(?m)^name = "([^"]+)"\s*$', block)
        if not match:
            raise RuntimeError(f"unnamed action block in {path}")
        name = match.group(1).decode()
        if name in blocks:
            raise RuntimeError(f"duplicate action {name} in {path}")
        blocks[name] = block
    return blocks


def load_and_verify():
    expected = json.loads((ROOT / "expected.json").read_text(encoding="utf-8"))
    if digest(FIXTURES / "plugin.rhai") != expected["plugin_sha256"]:
        raise RuntimeError("plugin.rhai hash mismatch")
    if digest(HARNESS_SOURCE / "src/main.rs") != expected["harness_source_sha256"]:
        raise RuntimeError("harness source hash mismatch")
    if digest(HARNESS_SOURCE / "Cargo.lock") != expected["harness_lock_sha256"]:
        raise RuntimeError("harness lockfile hash mismatch")

    maps = []
    for configuration in expected["configurations"]:
        manifest = FIXTURES / configuration["manifest"]
        if digest(manifest) != configuration["manifest_sha256"]:
            raise RuntimeError(f"manifest hash mismatch: {manifest.name}")
        blocks = action_blocks(manifest)
        if len(blocks) != 1650:
            raise RuntimeError(f"expected 1,650 actions in {manifest.name}")
        maps.append(blocks)

    for name, block in maps[0].items():
        if maps[1].get(name) != block:
            raise RuntimeError(f"action block differs after reordering: {name}")
    return expected


def toml_path(path):
    return json.dumps(path.resolve().as_posix())


def build_harness(stack):
    stack = stack.resolve()
    paths = {name: stack / "libs" / name for name in LIBS}
    missing = [str(path) for path in paths.values() if not path.is_dir()]
    if missing:
        raise RuntimeError("missing PR212 library paths:\n" + "\n".join(missing))

    project = WORK / "harness"
    (project / "src").mkdir(parents=True, exist_ok=True)
    shutil.copyfile(HARNESS_SOURCE / "src/main.rs", project / "src/main.rs")
    shutil.copyfile(HARNESS_SOURCE / "Cargo.lock", project / "Cargo.lock")
    cargo_toml = f'''[package]
name = "microverse-reachable-harness"
version = "0.1.0"
edition = "2024"

[dependencies]
anyhow = "1"
payload = {{ path = {toml_path(paths['payload'])}, features = ["test-utils"] }}
pexe = {{ path = {toml_path(paths['pexe'])} }}
pod2 = {{ git = "https://github.com/0xPARC/pod2", rev = "da6c08f3c3341a51aa8f7f0f863ec694bcb9d9a3", default-features = false, features = ["backend_plonky2", "disk_cache", "zk"] }}
pod2utils = {{ path = {toml_path(paths['pod2utils'])} }}
sdk = {{ path = {toml_path(paths['sdk'])} }}
serde = {{ version = "1", features = ["derive"] }}
serde_json = "1"
txlib = {{ path = {toml_path(paths['txlib'])} }}
'''
    (project / "Cargo.toml").write_text(cargo_toml, encoding="utf-8", newline="\n")

    command = [
        "cargo",
        "+nightly-2026-01-25",
        "build",
        "--release",
        "--locked",
        "--manifest-path",
        str(project / "Cargo.toml"),
    ]
    print("Building harness...", flush=True)
    try:
        subprocess.run(command, check=True)
    except FileNotFoundError as error:
        raise RuntimeError("cargo was not found on PATH") from error
    metadata = subprocess.run(
        [
            "cargo",
            "+nightly-2026-01-25",
            "metadata",
            "--no-deps",
            "--format-version=1",
            "--manifest-path",
            str(project / "Cargo.toml"),
        ],
        check=True,
        text=True,
        capture_output=True,
    )
    executable = "microverse-reachable-harness.exe" if os.name == "nt" else "microverse-reachable-harness"
    return Path(json.loads(metadata.stdout)["target_directory"]) / "release" / executable


def run_configuration(harness, expected, configuration, real):
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    result_root = WORK / "results" / run_id / configuration["name"]
    fixture_root = result_root / "plugin"
    case_dir = result_root / "cases"
    fixture_root.mkdir(parents=True)
    case_dir.mkdir(parents=True)
    shutil.copyfile(FIXTURES / "plugin.rhai", fixture_root / "plugin.rhai")
    shutil.copyfile(FIXTURES / configuration["manifest"], fixture_root / "manifest.toml")
    report_path = result_root / "report.json"

    command = [
        str(harness),
        "v2-proof-canaries",
        str(fixture_root),
        "--case-dir",
        str(case_dir),
        "--output",
        str(report_path),
        "--action",
        expected["action"],
        "--expect-ship-mutation",
    ]
    if not real:
        command.append("--mock-only")

    print(f"Running {configuration['name']}...", flush=True)
    completed = subprocess.run(command, text=True, capture_output=True)
    (result_root / "harness.log").write_text(
        completed.stdout + completed.stderr, encoding="utf-8", newline="\n"
    )
    if completed.returncode:
        raise RuntimeError(
            f"{configuration['name']} failed ({completed.returncode}); "
            f"see {result_root / 'harness.log'}"
        )

    report = json.loads(report_path.read_text(encoding="utf-8"))
    case = report["cases"][0]
    plan = case["plan"]
    if report["status"] != "pass" or case["status"] != "pass":
        raise RuntimeError(f"{configuration['name']} did not pass")
    if case["action"] != expected["action"]:
        raise RuntimeError("unexpected action in report")
    if case["fixture"]["fixture_seed"] != expected["fixture_seed"] or case["action_seed"] != expected["action_seed"]:
        raise RuntimeError("fixture or action seed mismatch")
    if report["module_hash"] != configuration["module_hash"]:
        raise RuntimeError("module hash mismatch")
    if (
        plan["operations"] != configuration["operations"]
        or plan["statements"] != configuration["operations"]
        or plan["assigned_statement_slots"] != configuration["operations"]
        or plan["pods"] != configuration["pods"]
        or plan["output_pods"] != configuration["output_pods"]
    ):
        raise RuntimeError(f"unexpected plan: {plan}")
    if not all(case["semantic_assertions"].values()):
        raise RuntimeError("semantic assertion failed")
    if real and (not report["real_executor_invoked"] or not report["shrink_proof_build_constructed"]):
        raise RuntimeError("real proof was not constructed")
    return {
        "name": configuration["name"],
        "operations": plan["operations"],
        "pods": plan["pods"],
        "recorded_real": configuration["recorded_real_execution_seconds"],
        "run_real": case.get("real", {}).get("execution_seconds") if real else None,
    }


def main():
    parser = argparse.ArgumentParser()
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--stack", type=Path, help="PR212 stack checkout")
    source.add_argument("--harness", type=Path, help="prebuilt harness executable")
    parser.add_argument("--real", action="store_true", help="construct real proofs")
    parser.add_argument("--verify-only", action="store_true", help="only verify included fixtures")
    args = parser.parse_args()

    expected = load_and_verify()
    if args.verify_only:
        print("Fixtures verified: same plugin and 1,650 byte-identical action blocks.")
        return
    if args.stack is None and args.harness is None:
        parser.error("provide --stack or --harness (or use --verify-only)")

    harness = build_harness(args.stack) if args.stack else args.harness.resolve()
    if not harness.is_file():
        raise RuntimeError(f"harness executable not found: {harness}")
    rows = [
        run_configuration(harness, expected, configuration, args.real)
        for configuration in expected["configurations"]
    ]

    print(f"{'Configuration':<18} {'Operations':>10} {'PODs':>6} {'Recorded real':>14}")
    for row in rows:
        print(f"{row['name']:<18} {row['operations']:>10} {row['pods']:>6} {row['recorded_real']:>14.2f}")
    before, after = rows
    reduction = 100 * (before["recorded_real"] - after["recorded_real"]) / before["recorded_real"]
    print(f"Recorded real-proof reduction: {reduction:.2f}%")
    if args.real:
        print(f"This run: {before['run_real']:.2f}s -> {after['run_real']:.2f}s")


if __name__ == "__main__":
    main()
