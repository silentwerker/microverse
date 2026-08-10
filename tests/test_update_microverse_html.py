from __future__ import annotations

import base64
import hashlib
import importlib.util
import json
import re
import unittest
from pathlib import Path

import tomli


ROOT = Path(__file__).resolve().parents[1]
UPDATER_PATH = ROOT / "tools" / "update_microverse_html.py"
SPEC = importlib.util.spec_from_file_location("update_microverse_html", UPDATER_PATH)
assert SPEC and SPEC.loader
UPDATER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(UPDATER)


def assigned_json(source: str, prefix: str):
    position = source.index(prefix) + len(prefix)
    end = UPDATER.find_balanced(source, position)
    return json.loads(source[position:end])


class UpdateMicroverseHtmlTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = (ROOT / "microverse.html").read_text(encoding="utf-8")
        cls.updated, cls.report = UPDATER.build_updated_html(cls.source)
        cls.index = UPDATER.load_json(
            ROOT / "catalog" / "microverse-catalog-index-v2.json"
        )
        cls.skills = UPDATER.load_json(
            ROOT / "catalog" / "microverse-skill-tree-v2.json"
        )

    def test_update_is_idempotent_and_binds_current_package(self):
        self.assertEqual(self.updated, self.source)
        self.assertEqual(self.report["actions"], 1650)
        self.assertEqual(self.report["classes"], 20)
        self.assertEqual(self.report["resource_items"], 586)
        self.assertEqual(self.report["skills"], 90)

        manifest = tomli.loads((ROOT / "manifest.toml").read_text(encoding="utf-8"))
        module_hash = manifest["plugin"]["module_hash"]
        pexe_hash = hashlib.sha256((ROOT / "microverse.pexe").read_bytes()).hexdigest()
        self.assertIn(f'microverse.{module_hash}', self.source)
        self.assertIn(f'ec="{module_hash}"', self.source)
        self.assertIn(f'sa="{pexe_hash}"', self.source)
        self.assertNotIn("weight_bps", self.source)
        self.assertIn('N(A,"source_pool")', self.source)
        self.assertIn('FA(cd(Qc)===140,"warp use total")', self.source)
        self.assertIn('FA(cd(hc)===101,"time use total")', self.source)

    def test_embedded_contracts_are_byte_semantic_matches(self):
        for prefix, path in (
            ("var Xo=", "action-contract.json"),
            ("var Qo=", "body-bank.json"),
            ("var ho=", "warp-coordinate-contract.json"),
            ("var Eo=", "time-coordinate-contract.json"),
            ("var Vo=", "universe-contract.json"),
        ):
            self.assertEqual(
                assigned_json(self.source, prefix),
                UPDATER.load_json(ROOT / "generated" / path),
            )

        classes = assigned_json(self.source, ",ta=")
        manifest = tomli.loads((ROOT / "manifest.toml").read_text(encoding="utf-8"))
        self.assertEqual(
            [row["class"] for row in classes["classes"]],
            [row["name"] for row in manifest["classes"]],
        )

    def test_resource_and_skill_payloads_are_complete(self):
        resource_pairs = assigned_json(self.source, "Ec=new Map(")
        self.assertEqual(len(resource_pairs), 586)
        self.assertEqual(
            {row[0]: row[1]["display_name"] for row in resource_pairs},
            {row["code"]: row["name"] for row in self.index["resource_code_rows"]},
        )

        skills = assigned_json(self.source, "ma=")
        self.assertEqual([row["code"] for row in skills], list(range(1, 91)))
        expected_skills = {
            root["name"]
            for root in self.skills["roots"]
        } | {
            specialization["name"]
            for root in self.skills["roots"]
            for specialization in root["specializations"]
        } | {
            root["mastery"]["name"] for root in self.skills["roots"]
        }
        self.assertEqual({row["name"] for row in skills}, expected_skills)

        _, _, shell = UPDATER.js_string_span(self.source, "var Wo=")
        catalog_match = re.search(
            r'<script id="catalog-data" type="application/json">(.*?)</script>',
            shell,
            re.S,
        )
        self.assertIsNotNone(catalog_match)
        catalog = json.loads(catalog_match.group(1))
        self.assertEqual(
            catalog["summary"],
            {"items": 586, "bodies": 23, "components": 45, "skills": 90, "artifacts": 72},
        )
        self.assertEqual(len(catalog["records"]), 699)
        self.assertEqual(
            {
                row["code"]: row["name"]
                for row in catalog["records"]
                if row["kind"] not in {"Skill", "Body"}
            },
            {row["code"]: row["name"] for row in self.index["resource_code_rows"]},
        )

    def test_tree_and_wasm_payloads_are_current(self):
        _, _, viewer_b64 = UPDATER.js_string_span(
            self.source, "var ResourceTreeViewerB64="
        )
        viewer = base64.b64decode(viewer_b64).decode("utf-8")
        data_match = re.search(
            r'<script id="data" type="application/json">(.*?)</script>', viewer, re.S
        )
        self.assertIsNotNone(data_match)
        tree = json.loads(data_match.group(1))
        self.assertEqual(
            {
                "bodies": len(tree["bodies"]),
                "base": len(tree["base"]),
                "source": len(tree["prim"]),
                "refined": len(tree["ref"]),
                "skills": len(tree["skills"]),
                "components": len(tree["components"]),
                "artifacts": len(tree["artifacts"]),
            },
            {
                "bodies": 23,
                "base": 4,
                "source": 149,
                "refined": 316,
                "skills": 90,
                "components": 45,
                "artifacts": 72,
            },
        )
        component_catalog = UPDATER.load_json(
            ROOT / "catalog" / "microverse-component-tree-v2.json"
        )
        self.assertEqual(
            {
                row["code"]: (row["name"], row["skill_code"])
                for row in tree["components"]
            },
            {
                row["code"]: (row["name"], row["skill_code"])
                for row in component_catalog["components"]
            },
        )
        self.assertTrue(
            all(
                row["description"]
                and row["materials"]
                and row["catalyst"]
                and row["actions"]
                for row in tree["components"]
            )
        )
        expected_artifacts = {
            row["fallback_resource"]["code"]: (
                row["fallback_resource"]["name"],
                row["skill_code"],
            )
            for row in self.skills["capability_artifacts"]
        }
        self.assertEqual(
            {
                row["code"]: (row["name"], row["skill_code"])
                for row in tree["artifacts"]
            },
            expected_artifacts,
        )
        self.assertTrue(
            all(
                row["description"] and row["inputs"] and row["action"]
                for row in tree["artifacts"]
            )
        )
        for expected_fragment in (
            "kind:'component'",
            "kind:'artifact'",
            "kind:'skilllink'",
            "window.__microverseTreeCensus",
            "D.components.forEach",
            "D.artifacts.forEach",
        ):
            self.assertIn(expected_fragment, viewer)
        wasm_source = (
            ROOT / "tools" / "commitment-wasm" / "src" / "lib.rs"
        ).read_text(encoding="utf-8")
        self.assertTrue(
            all(
                field in wasm_source
                for field in (
                    "minor_body_field_remaining",
                    "next_minor_body_field_serial",
                )
            )
        )

        _, _, wasm_b64 = UPDATER.js_string_span(self.source, "var ym=")
        embedded = base64.b64decode(wasm_b64)
        compiled = UPDATER.WASM.read_bytes()
        self.assertEqual(embedded, compiled)
        self.assertEqual(embedded[:4], b"\0asm")
        self.assertEqual(
            set(re.findall(rb"__wbg___wbindgen_throw_[0-9a-f]{16}", embedded)),
            {b"__wbg___wbindgen_throw_bb96b2010945f0bc"},
        )
        self.assertEqual(
            self.source.count("__wbg___wbindgen_throw_bb96b2010945f0bc"), 2
        )
        self.assertEqual(
            hashlib.sha256(embedded).hexdigest(),
            "0b9895559132f017304163a09225c1fc846b447cbb8af65ebd3e1cfd2c7c8dae",
        )


if __name__ == "__main__":
    unittest.main()
