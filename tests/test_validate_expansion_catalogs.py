#!/usr/bin/env python3
"""Focused regression tests for validate_expansion_catalogs.py."""

from __future__ import annotations

from collections import Counter
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import validate_expansion_catalogs as validator  # noqa: E402


class ExpansionValidatorTests(unittest.TestCase):
    def test_universe_selection_metadata_is_action_and_index_bound(self) -> None:
        universe_path = ROOT / "generated" / "universe-contract.json"
        index_path = ROOT / "catalog" / "microverse-catalog-index-v2.json"
        universe = json.loads(universe_path.read_text(encoding="utf-8"))
        index = json.loads(index_path.read_text(encoding="utf-8"))
        validation = validator.Validation()
        validator.validate_universe_selection_contract(
            universe,
            universe_path,
            validation,
            index,
        )
        self.assertEqual(set(), self.finding_codes(validation))

        missing_action = json.loads(json.dumps(universe))
        missing_action["survey_profiles"][0].pop("action")
        validation = validator.Validation()
        validator.validate_universe_selection_contract(
            missing_action,
            universe_path,
            validation,
            index,
        )
        self.assertIn(
            "universe.survey_profile_row",
            self.finding_codes(validation),
        )

    def test_warp_schemas_are_exact_raw_int_contracts_end_to_end(self) -> None:
        warp_path = ROOT / "catalog" / "microverse-warp-tree-v2.json"
        index_path = ROOT / "catalog" / "microverse-catalog-index-v2.json"
        sidecar_path = ROOT / "generated" / "schema-counts.json"
        warp = json.loads(warp_path.read_text(encoding="utf-8"))
        index = json.loads(index_path.read_text(encoding="utf-8"))
        sidecar = json.loads(sidecar_path.read_text(encoding="utf-8"))

        validation = validator.Validation()
        warp_state = validator.validate_warp_catalog(
            warp, warp_path, validation
        )
        validator.validate_index(
            index,
            index_path,
            validation,
            {"warp": warp_state, "resources": {"profile": "full"}},
        )
        validator.validate_schema_sidecar(
            sidecar, sidecar_path, validation, warp_state, index
        )
        schema_codes = {
            code
            for code in self.finding_codes(validation)
            if "schema" in code
        }
        self.assertEqual(set(), schema_codes)

        for class_name in (
            "MicroversePositionAnchor",
            "MicroverseTimeAnchor",
        ):
            fields = next(
                row["schema_fields"]
                for row in warp["object_types"]
                if row["class_name"] == class_name
            )
            self.assertEqual(
                "Raw",
                next(row["type"] for row in fields if row["name"] == "source_ship_id"),
            )

        bad_warp = json.loads(json.dumps(warp))
        position_anchor = next(
            row
            for row in bad_warp["object_types"]
            if row["class_name"] == "MicroversePositionAnchor"
        )
        next(
            field
            for field in position_anchor["schema_fields"]
            if field["name"] == "source_ship_id"
        )["type"] = "Int"
        validation = validator.Validation()
        validator.validate_warp_catalog(bad_warp, warp_path, validation)
        self.assertTrue(
            {"warp.object_schema", "warp.object_schema_types"}
            <= self.finding_codes(validation)
        )

        bad_index = json.loads(json.dumps(index))
        indexed_anchor = next(
            row
            for row in bad_index["warp"]["object_types"]
            if row["class_name"] == "MicroverseTimeAnchor"
        )
        next(
            field
            for field in indexed_anchor["schema_fields"]
            if field["name"] == "source_ship_id"
        )["type"] = "Int"
        validation = validator.Validation()
        validator.validate_index(
            bad_index,
            index_path,
            validation,
            {"warp": warp_state, "resources": {"profile": "full"}},
        )
        self.assertIn("index.warp_schema_exact", self.finding_codes(validation))

        bad_sidecar = json.loads(json.dumps(sidecar))
        bad_sidecar["classes"]["MicroverseShip"]["fields"][-3]["type"] = "Int"
        validation = validator.Validation()
        validator.validate_schema_sidecar(
            bad_sidecar, sidecar_path, validation, warp_state, index
        )
        self.assertIn(
            "schema_sidecar.field_types", self.finding_codes(validation)
        )

    def test_shape_j_warp_catalog_roles_and_lifecycle_are_enforced(self) -> None:
        warp_path = ROOT / "catalog" / "microverse-warp-tree-v2.json"
        index_path = ROOT / "catalog" / "microverse-catalog-index-v2.json"
        warp = json.loads(warp_path.read_text(encoding="utf-8"))

        validation = validator.Validation()
        warp_state = validator.validate_warp_catalog(
            warp, warp_path, validation
        )
        codes = self.finding_codes(validation)
        self.assertNotIn("warp.shape_j_constructor_roles", codes)
        self.assertNotIn("warp.shape_j_ship_lifecycle", codes)

        bad_warp = json.loads(json.dumps(warp))
        constructor = next(
            action
            for object_type in bad_warp["object_types"]
            for action in object_type.get("creation_actions", [])
            if action.get("name") == "ConstructWormholeLink"
        )
        constructor["roles"][0]["class"] = "MicroverseShip"
        constructor["field_copy_update_rules"][0] = (
            "Copy all Ship semantic fields into a replacement Ship."
        )
        validation = validator.Validation()
        validator.validate_warp_catalog(bad_warp, warp_path, validation)
        codes = self.finding_codes(validation)
        self.assertIn("warp.shape_j_constructor_roles", codes)
        self.assertIn("warp.shape_j_ship_lifecycle", codes)

        bad_index = json.loads(index_path.read_text(encoding="utf-8"))
        indexed_constructor = next(
            row
            for row in bad_index["actions"]
            if row.get("name") == "ConstructWormholeLink"
        )
        indexed_constructor["roles"][0]["class"] = "MicroverseShip"
        validation = validator.Validation()
        validator.validate_index(
            bad_index,
            index_path,
            validation,
            {"warp": warp_state, "resources": {"profile": "full"}},
        )
        self.assertIn(
            "index.warp_role_contract",
            self.finding_codes(validation),
        )

    def test_numeric_literal_audit_preserves_sign(self) -> None:
        self.assertTrue(validator.literal_in_source("let x = 1;", 1))
        self.assertTrue(validator.literal_in_source("let x = -1;", -1))
        self.assertFalse(validator.literal_in_source("let x = -1;", 1))
        self.assertFalse(validator.literal_in_source("let x = 1;", -1))

    def test_rhai_mask_does_not_treat_comment_markers_in_strings_as_comments(self) -> None:
        source = 'let label = "https://example.invalid/if"; if true { 1 } // loop\n'
        masked = validator.strip_rhai_comments(source)
        self.assertNotIn("https", masked)
        self.assertIn("if true", masked)
        self.assertNotIn("loop", masked)

    def finding_codes(self, validation: validator.Validation) -> set[str]:
        return {item.code for item in validation.findings}

    def test_current_production_rhai_has_no_forbidden_control_flow(self) -> None:
        validation = validator.Validation()
        state = validator.validate_rhai(
            ROOT / "plugin.rhai",
            ROOT / "manifest.toml",
            {},
            validation,
        )
        manifest = (ROOT / "manifest.toml").read_text(encoding="utf-8")
        self.assertEqual(
            len(validator.manifest_action_names(manifest)),
            state["action_count"],
        )
        codes = self.finding_codes(validation)
        self.assertNotIn("rhai.control_flow", codes)
        self.assertNotIn("rhai.anchor_ship_id_raw_helper", codes)
        self.assertNotIn("rhai.anchor_ship_id_raw_output", codes)

    def test_rhai_audit_rejects_numeric_anchor_ship_id_coercion(self) -> None:
        source = (ROOT / "plugin.rhai").read_text(encoding="utf-8")
        mutated = source.replace(
            '["anchor_version",2],\n["source_ship_id",source_ship_id],\n["x",ax]',
            '["anchor_version",2],\n["source_ship_id",ax],\n["x",ax]',
            1,
        )
        self.assertNotEqual(source, mutated)
        source = mutated
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "plugin.rhai").write_text(source, encoding="utf-8")
            (root / "manifest.toml").write_text(
                (ROOT / "manifest.toml").read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            validation = validator.Validation()
            validator.validate_rhai(
                root / "plugin.rhai", root / "manifest.toml", {}, validation
            )
        self.assertIn(
            "rhai.anchor_ship_id_raw_output", self.finding_codes(validation)
        )

    def test_rhai_audit_rejects_branch_modulo_and_subaction(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "plugin.rhai").write_text(
                """fn Bad(action) {
  if true { action.subaction(1); }
  let x = 10 % 3;
}
""",
                encoding="utf-8",
            )
            (root / "manifest.toml").write_text(
                """[plugin]
name = "bad"
version = "1"
module_hash = "0"

[[actions]]
name = "Bad"
emoji = "X"
description = "bad"
hidden = false
""",
                encoding="utf-8",
            )
            validation = validator.Validation()
            validator.validate_rhai(
                root / "plugin.rhai",
                root / "manifest.toml",
                {},
                validation,
            )
            codes = self.finding_codes(validation)
            self.assertIn("rhai.control_flow", codes)
            self.assertIn("rhai.modulo", codes)
            self.assertIn("rhai.subaction", codes)

    def test_rhai_audit_uses_flat_wrapper_literals_not_semantic_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "plugin.rhai").write_text(
                """fn Good(action) {
  var object = action.output("Thing");
  action.st_sum(object.value, 0, 5);
}
""",
                encoding="utf-8",
            )
            (root / "manifest.toml").write_text(
                """name = "unit"
module_hash = "0"
[[actions]]
name = "Good"
""",
                encoding="utf-8",
            )
            index = {
                "actions": [
                    {
                        "name": "Good",
                        "roles": [["output", "Thing"]],
                        "fixed_literals": {"semantic_name": "not executable"},
                        "wrapper_literals": [5],
                    }
                ]
            }
            validation = validator.Validation()
            validator.validate_rhai(
                root / "plugin.rhai", root / "manifest.toml", index, validation
            )
            self.assertNotIn("rhai.wrapper_literal", self.finding_codes(validation))
            index["actions"][0]["wrapper_literals"] = [7]
            validation = validator.Validation()
            validator.validate_rhai(
                root / "plugin.rhai", root / "manifest.toml", index, validation
            )
            self.assertIn("rhai.wrapper_literal", self.finding_codes(validation))

    def test_rhai_audit_rejects_reordered_object_roles(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "plugin.rhai").write_text(
                """fn Ordered(action) {
  var consumed = action.input("Consumed");
  var produced = action.output("Produced");
}
""",
                encoding="utf-8",
            )
            (root / "manifest.toml").write_text(
                """name = "unit"
module_hash = "0"
[[actions]]
name = "Ordered"
""",
                encoding="utf-8",
            )
            index = {
                "actions": [
                    {
                        "name": "Ordered",
                        "roles": [
                            ["output", "Produced"],
                            ["input", "Consumed"],
                        ],
                        "wrapper_literals": [],
                    }
                ]
            }
            validation = validator.Validation()
            validator.validate_rhai(
                root / "plugin.rhai", root / "manifest.toml", index, validation
            )
            self.assertIn("rhai.wrapper_objects", self.finding_codes(validation))

    def test_rhai_audit_rejects_transitive_unsafe_witness_collision(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "plugin.rhai").write_text(
                """fn inner_helper(object) {
  var x = unsafe { object.x - 0 };
}
fn outer_helper(object) {
  inner_helper(object);
}
fn Colliding(action) {
  var object = action.input("Thing");
  outer_helper(object);
  var x = unsafe { object.x - 0 };
}
""",
                encoding="utf-8",
            )
            (root / "manifest.toml").write_text(
                """name = "unit"
module_hash = "0"
[[actions]]
name = "Colliding"
""",
                encoding="utf-8",
            )
            validation = validator.Validation()
            validator.validate_rhai(
                root / "plugin.rhai", root / "manifest.toml", {}, validation
            )
            self.assertIn(
                "rhai.unsafe_witness_collision", self.finding_codes(validation)
            )

    def test_rhai_audit_requires_witnessed_late_anchor_updates(self) -> None:
        manifest = """name = "unit"
module_hash = "0"
[[actions]]
name = "ConstructWormholeLink"
"""
        good = """fn ConstructWormholeLink(action) {
  var link = action.output("MicroverseWormholeLink");
  let placeholder_identifier = action.top_limb_u256(0);
  link.set([
    ["schema_version", 2],
    ["mechanics_version", 2],
    ["universe_version", 2],
    ["link_version", 2],
    ["endpoint_a_anchor_identifier", placeholder_identifier],
    ["endpoint_a_x", 0],
    ["endpoint_a_y", 0],
    ["endpoint_a_z", 0],
    ["endpoint_b_anchor_identifier", placeholder_identifier],
    ["endpoint_b_x", 0],
    ["endpoint_b_y", 0],
    ["endpoint_b_z", 0],
    ["uses_remaining", 3]
  ]);
  var anchor_a = action.input("MicroversePositionAnchor");
  prove_object_version_core(action, anchor_a, "anchor_version");
  action.st_sum(anchor_a.uses_remaining, 0, 1);
  var endpoint_a_x = unsafe { anchor_a.x - 0 };
  action.st_sum(anchor_a.x, 0, endpoint_a_x);
  link.update("endpoint_a_x", endpoint_a_x);
  var endpoint_a_y = unsafe { anchor_a.y - 0 };
  action.st_sum(anchor_a.y, 0, endpoint_a_y);
  link.update("endpoint_a_y", endpoint_a_y);
  var endpoint_a_z = unsafe { anchor_a.z - 0 };
  action.st_sum(anchor_a.z, 0, endpoint_a_z);
  link.update("endpoint_a_z", endpoint_a_z);
  var endpoint_a_anchor_identifier = action.random();
  var_assign(endpoint_a_anchor_identifier, anchor_a.stable_identifier);
  anchor_a.update("stable_identifier", endpoint_a_anchor_identifier);
  link.update("endpoint_a_anchor_identifier", endpoint_a_anchor_identifier);
  var anchor_b = action.input("MicroversePositionAnchor");
  prove_object_version_core(action, anchor_b, "anchor_version");
  action.st_sum(anchor_b.uses_remaining, 0, 1);
  var endpoint_b_x = unsafe { anchor_b.x - 0 };
  action.st_sum(anchor_b.x, 0, endpoint_b_x);
  link.update("endpoint_b_x", endpoint_b_x);
  var endpoint_b_y = unsafe { anchor_b.y - 0 };
  action.st_sum(anchor_b.y, 0, endpoint_b_y);
  link.update("endpoint_b_y", endpoint_b_y);
  var endpoint_b_z = unsafe { anchor_b.z - 0 };
  action.st_sum(anchor_b.z, 0, endpoint_b_z);
  link.update("endpoint_b_z", endpoint_b_z);
  var endpoint_b_anchor_identifier = action.random();
  var_assign(endpoint_b_anchor_identifier, anchor_b.stable_identifier);
  anchor_b.update("stable_identifier", endpoint_b_anchor_identifier);
  link.update("endpoint_b_anchor_identifier", endpoint_b_anchor_identifier);
  var material_1 = action.input("MicroverseResource");
  prove_resource_stack_core(action, material_1, 432, 1);
  var material_2 = action.input("MicroverseResource");
  prove_resource_stack_core(action, material_2, 410, 1);
  var work = action.intro_vdf(32, link);
  link.update("work", work);
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, ship);
  action.st_sum(ship.active_skill_type, 0, 59);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_constructor_ship_key = action.random();
  rotate_key(ship, next_constructor_ship_key);
}
"""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "manifest.toml").write_text(manifest, encoding="utf-8")
            (root / "plugin.rhai").write_text(good, encoding="utf-8")
            validation = validator.Validation()
            validator.validate_rhai(
                root / "plugin.rhai", root / "manifest.toml", {}, validation
            )
            self.assertNotIn(
                "rhai.witnessed_anchor_binding",
                self.finding_codes(validation),
            )
            self.assertNotIn(
                "rhai.direct_anchor_output_value",
                self.finding_codes(validation),
            )
            good_checks = validator.witnessed_constructor_checks(
                good,
                validator.WITNESSED_ANCHOR_CONSTRUCTORS[
                    "ConstructWormholeLink"
                ],
            )
            self.assertTrue(all(good_checks.values()), good_checks)

            vdf_block = (
                "  var work = action.intro_vdf(32, link);\n"
                '  link.update("work", work);\n'
            )
            ship_declaration = (
                '  var ship = action.mutate("MicroverseShip");\n'
            )
            vdf_after_ship = good.replace(
                vdf_block + ship_declaration,
                ship_declaration + vdf_block,
                1,
            )
            checks = validator.witnessed_constructor_checks(
                vdf_after_ship,
                validator.WITNESSED_ANCHOR_CONSTRUCTORS[
                    "ConstructWormholeLink"
                ],
            )
            self.assertFalse(
                checks["vdf_after_final_semantic_update_before_ship_mutation"]
            )

            wrong_role = good.replace(
                'action.mutate("MicroverseShip")',
                'action.input("MicroverseShip")',
                1,
            )
            checks = validator.witnessed_constructor_checks(
                wrong_role,
                validator.WITNESSED_ANCHOR_CONSTRUCTORS[
                    "ConstructWormholeLink"
                ],
            )
            self.assertFalse(
                checks["action_roles_target_anchors_materials_ship_mutate"]
            )
            self.assertFalse(checks["ship_mutate_lifecycle_exact"])

            missing_serial_update = good.replace(
                '  ship.update("action_serial", next_action_serial);\n',
                "",
                1,
            )
            checks = validator.witnessed_constructor_checks(
                missing_serial_update,
                validator.WITNESSED_ANCHOR_CONSTRUCTORS[
                    "ConstructWormholeLink"
                ],
            )
            self.assertFalse(checks["ship_mutate_lifecycle_exact"])

            direct = good.replace(
                '["endpoint_a_y", 0]',
                '["endpoint_a_y", anchor_a.y]',
                1,
            )
            (root / "plugin.rhai").write_text(direct, encoding="utf-8")
            validation = validator.Validation()
            validator.validate_rhai(
                root / "plugin.rhai", root / "manifest.toml", {}, validation
            )
            codes = self.finding_codes(validation)
            self.assertIn("rhai.witnessed_anchor_binding", codes)
            self.assertIn("rhai.direct_anchor_output_value", codes)

            late_touch = good.replace(
                'link.update("endpoint_a_anchor_identifier", '
                "endpoint_a_anchor_identifier);",
                'link.update("endpoint_a_anchor_identifier", '
                "endpoint_a_anchor_identifier);\n"
                "  action.st_sum(anchor_a.x, 0, endpoint_a_x);",
                1,
            )
            (root / "plugin.rhai").write_text(late_touch, encoding="utf-8")
            validation = validator.Validation()
            validator.validate_rhai(
                root / "plugin.rhai", root / "manifest.toml", {}, validation
            )
            self.assertIn(
                "rhai.witnessed_anchor_binding",
                self.finding_codes(validation),
            )

    def test_rhai_audit_rejects_update_of_unset_chart_destination(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for action, fields in validator.CHART_DESTINATION_INITIALIZERS.items():
                with self.subTest(action=action):
                    manifest = (
                        'name = "unit"\nmodule_hash = "0"\n[[actions]]\n'
                        f'name = "{action}"\n'
                    )
                    updates = "\n".join(
                        f'  chart.update("{field}", 0);' for field in fields
                    )
                    bad = (
                        f"fn {action}(action) {{\n"
                        '  var chart = action.output("Chart");\n'
                        f"{updates}\n"
                        "}\n"
                    )
                    (root / "manifest.toml").write_text(
                        manifest, encoding="utf-8"
                    )
                    (root / "plugin.rhai").write_text(bad, encoding="utf-8")
                    validation = validator.Validation()
                    validator.validate_rhai(
                        root / "plugin.rhai",
                        root / "manifest.toml",
                        {},
                        validation,
                    )
                    self.assertIn(
                        "rhai.chart_destination_initialization",
                        self.finding_codes(validation),
                    )

                    values = {
                        "source_body_identifier": "source_body_identifier",
                        "source_pool_before": "source_pool_before",
                    }
                    entries = ",\n".join(
                        f'    ["{field}", {values.get(field, "0")}]'
                        for field in validator.CHART_EXTRACTION_SET_FIELDS[action]
                    )
                    good = (
                        f"fn {action}(action) {{\n"
                        '  var chart = action.output("Chart");\n'
                        '  var body = action.mutate("Body");\n'
                        "  var source_body_identifier = action.random();\n"
                        "  var_assign(source_body_identifier, "
                        "body.stable_identifier);\n"
                        '  body.update("stable_identifier", '
                        "source_body_identifier);\n"
                        "  var source_pool_before = unsafe { "
                        "body.energy_remaining - 0 };\n"
                        "  action.st_sum(body.energy_remaining, 0, "
                        "source_pool_before);\n"
                        f"  chart.set([\n{entries}\n  ]);\n"
                        "}\n"
                    )
                    (root / "plugin.rhai").write_text(good, encoding="utf-8")
                    validation = validator.Validation()
                    validator.validate_rhai(
                        root / "plugin.rhai",
                        root / "manifest.toml",
                        {},
                        validation,
                    )
                    self.assertNotIn(
                        "rhai.chart_destination_initialization",
                        self.finding_codes(validation),
                    )

    def test_non_integral_75_20_5_split_is_rejected_at_amount_10(self) -> None:
        parent = {
            "parent_id": 500,
            "children": [
                {"slot": 1, "output_id": 501, "pct": 75},
                {"slot": 2, "output_id": 502, "pct": 20},
                {"slot": 3, "output_id": 503, "pct": 5},
            ],
        }
        route = {"resource_id": 500, "min_capacity_tier": 0}
        validation = validator.Validation()
        validator.validate_integer_conservation(
            [parent],
            [route],
            {0: 10, 1: 50, 2: 250},
            validation,
        )
        self.assertIn("allocation.non_integer", self.finding_codes(validation))

    def test_explicit_integer_allocations_conserve(self) -> None:
        parent = {
            "parent_id": 500,
            "children": [
                {
                    "slot": 1,
                    "output_id": 501,
                    "amounts_by_tier": {"0": 7, "1": 37, "2": 187},
                },
                {
                    "slot": 2,
                    "output_id": 502,
                    "amounts_by_tier": {"0": 2, "1": 10, "2": 50},
                },
                {
                    "slot": 3,
                    "output_id": 503,
                    "amounts_by_tier": {"0": 1, "1": 3, "2": 13},
                },
            ],
        }
        validation = validator.Validation()
        validator.validate_integer_conservation(
            [parent],
            [{"resource_id": 500, "min_capacity_tier": 0}],
            {0: 10, 1: 50, 2: 250},
            validation,
        )
        self.assertEqual([], validation.errors)

    def test_warp_validator_rejects_retired_band_and_wrong_capacity(self) -> None:
        catalog = json.loads(
            (ROOT / "catalog" / "microverse-warp-tree-v2.json").read_text(
                encoding="utf-8"
            )
        )
        rows = json.loads(json.dumps(catalog["v1"]["position"]["rows"]))
        rows[0]["weight_bps"] = 10_000
        rows[0]["minimum_source_pool_inclusive"] = 17_999
        validation = validator.Validation()
        validator.validate_warp_rows(
            rows,
            125,
            False,
            "warp.v1.position",
            validation,
            action_prefix="RevealWarpCoordinate",
            slug_width=3,
            capacity_minimums={10: 18_000, 3: 9_001, 1: 9_000},
        )
        self.assertIn(
            "warp.retired_selection_fields",
            self.finding_codes(validation),
        )
        self.assertIn(
            "warp.maximum_capacity_minimum",
            self.finding_codes(validation),
        )

    def test_component_catalog_has_no_cross_body_intersection(self) -> None:
        component_path = ROOT / "catalog" / "microverse-component-tree-v2.json"
        if not component_path.exists():
            self.skipTest("component catalog is not present")
        catalog = json.loads(component_path.read_text(encoding="utf-8"))
        validation = validator.Validation()
        validator.validate_component_catalog(
            catalog,
            component_path,
            validation,
            {},
            {},
        )
        forbidden = {
            "component.single_body_recipe",
            "component.cross_body_span",
            "component.material_count",
            "component.catalyst_modes",
        }
        self.assertTrue(forbidden.isdisjoint(self.finding_codes(validation)))

    def test_phase5_component_index_route_is_exact(self) -> None:
        resource_path = ROOT / "catalog" / "microverse-resource-tree-v2.json"
        component_path = ROOT / "catalog" / "microverse-component-tree-v2.json"
        if not all(path.exists() for path in (resource_path, component_path)):
            self.skipTest("canonical Phase 5 inputs are not present")
        import generate_microverse as production_generator

        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        production_generator.configure_vdf_profile("economy")
        bank = production_generator.candidate_bank(
            len(production_generator.BODY_BANK)
        )
        actions = production_generator.build_actions(bank)
        resources = json.loads(resource_path.read_text(encoding="utf-8"))
        components = json.loads(component_path.read_text(encoding="utf-8"))
        index = production_generator.expansion_catalog_index(bank, actions)
        resource_state = validator.validate_resource_catalog(
            resources, resource_path, validator.Validation()
        )
        component_rows = [
            row for row in index["actions"]
            if isinstance(row.get("fixed_literals", {}).get("component"), dict)
        ]
        self.assertEqual(90, len(component_rows))
        self.assertTrue(all(len(row["helpers"]) == 1 for row in component_rows))
        validation = validator.Validation()
        validator.validate_component_catalog(
            components, component_path, validation, resource_state, index
        )
        self.assertNotIn("component.action_helpers", self.finding_codes(validation))
        route = next(
            row for row in index["actions"]
            if row["name"] == "FabricateStructuralAlloyReusable"
        )
        self.assertEqual(
            ["fabricate_component_reusable_vdf_8_core"], route["helpers"]
        )
        for mutation in (
            ["fabricate_component_final_vdf_8_core"],
            ["fabricate_component_reusable_vdf_12_core"],
            ["forged_fabricate_component_reusable_vdf_8_core"],
            ["fabricate_component_reusable_vdf_8_core", "fabricate_component_final_vdf_8_core"],
        ):
            changed = json.loads(json.dumps(index))
            changed_route = next(
                row for row in changed["actions"]
                if row["name"] == route["name"]
            )
            changed_route["helpers"] = mutation
            validation = validator.Validation()
            validator.validate_component_catalog(
                components, component_path, validation, resource_state, changed
            )
            self.assertIn("component.action_helpers", self.finding_codes(validation))

    def test_current_profile_binds_shared_actions_before_translating_vdf(self) -> None:
        index_path = ROOT / "catalog" / "microverse-catalog-index-v2.json"
        resource_path = ROOT / "catalog" / "microverse-resource-tree-v2.json"
        if not all(path.exists() for path in (index_path, resource_path)):
            self.skipTest("canonical current-profile inputs are not present")
        import generate_microverse as production_generator

        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        try:
            production_generator.configure_vdf_profile("economy")
            economy_bank = production_generator.candidate_bank(
                len(production_generator.BODY_BANK)
            )
            economy_actions = production_generator.build_actions(economy_bank)
            index = production_generator.expansion_catalog_index(
                economy_bank, economy_actions
            )
            production_generator.configure_vdf_profile("current")
            bank = production_generator.candidate_bank(
                len(production_generator.BODY_BANK)
            )
            actions = production_generator.build_actions(bank)
            plugin = production_generator.render_plugin(
                actions, production_generator.sources_for_bank(bank)
            )
            classes = [
                class_name
                for class_name in production_generator.CLASS_ORDER
                if any(
                    obj["class"] == class_name
                    for action in actions
                    for obj in action["objects"]
                )
            ]
            manifest = production_generator.render_manifest(
                classes, actions, "microverse-current-test"
            )
        finally:
            production_generator.configure_vdf_profile("economy")
        resources = json.loads(resource_path.read_text(encoding="utf-8"))
        functions = validator.extract_rhai_functions(plugin)

        def findings(source: str) -> set[str]:
            with tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                rhai = root / "plugin.rhai"
                manifest_file = root / "manifest.toml"
                rhai.write_text(source, encoding="utf-8")
                manifest_file.write_text(manifest, encoding="utf-8")
                validation = validator.Validation()
                validator.validate_rhai(
                    rhai, manifest_file, index, validation, resources
                )
                return self.finding_codes(validation)

        self.assertFalse(findings(plugin))
        matter = functions["ExtractMatter"]
        crystal = functions["ExtractCrystal"]
        detect = functions["DetectCelestialSignal_00_RedDwarf"]
        build_small = functions["BuildShipSmall"]
        move_positive_x = functions["MovePositiveX"]
        helper_swap = plugin.replace(
            matter,
            matter.replace("extract_base_vdf_4_core(", "extract_base_vdf_8_core(", 1),
            1,
        ).replace(
            crystal,
            crystal.replace("extract_base_vdf_8_core(", "extract_base_vdf_4_core(", 1),
            1,
        )
        mutations = {
            "same_distribution_helper_swap": helper_swap,
            "role": plugin.replace(
                matter,
                matter.replace(
                    'action.output("MicroverseShip")',
                    'action.input("MicroverseShip")',
                    1,
                ),
                1,
            ),
            "literal": plugin.replace(
                matter, matter.replace('"matter_remaining"', '"gas_remaining"', 1), 1
            ),
            "non_profile_helper": plugin.replace(
                detect,
                detect.replace("detect_signal_core(", "forged_detect_signal_core(", 1),
                1,
            ),
            "build_vdf_cost": plugin.replace(
                build_small,
                build_small.replace("action.intro_vdf(4,ship)", "action.intro_vdf(999,ship)", 1),
                1,
            ),
            "commented_build_tail": plugin.replace(
                build_small,
                build_small.replace(
                    "var work=action.intro_vdf(4,ship);\n"
                    'ship.update("work",work);',
                    "/* var work=action.intro_vdf(4,ship); "
                    'ship.update("work",work); */',
                    1,
                ),
                1,
            ),
            "move_extra_vdf_work": plugin.replace(
                move_positive_x,
                move_positive_x.replace(
                    "\n}",
                    "\nvar extra_work = action.intro_vdf(4, ship);\n"
                    'ship.update("work", extra_work);\n}',
                    1,
                ),
                1,
            ),
        }
        for name, mutant in mutations.items():
            with self.subTest(mutation=name):
                self.assertNotEqual(plugin, mutant)
                self.assertTrue(findings(mutant), name)
        self.assertIn(
            "rhai.current_build_vdf_tail", findings(mutations["build_vdf_cost"])
        )
        self.assertIn(
            "rhai.current_build_vdf_tail", findings(mutations["commented_build_tail"])
        )
        self.assertIn(
            "rhai.current_base_move_shape", findings(mutations["move_extra_vdf_work"])
        )

    def test_every_source_route_is_checked_not_only_the_last_one(self) -> None:
        resource_path = ROOT / "catalog" / "microverse-resource-tree-v2.json"
        if not resource_path.exists():
            self.skipTest("resource catalog is not present")
        catalog = json.loads(resource_path.read_text(encoding="utf-8"))
        catalog["source_resources"][0]["body_id"] = 999
        validation = validator.Validation()
        validator.validate_resource_catalog(catalog, resource_path, validation)
        self.assertIn("resource.body_reference", self.finding_codes(validation))

    def test_phase4_bulk_validator_binds_all_routes_literals_and_vdf_tails(self) -> None:
        import generate_microverse as production_generator

        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        resources = json.loads(
            (ROOT / "catalog" / "microverse-resource-tree-v2.json").read_text(
                encoding="utf-8"
            )
        )

        def render(profile: str) -> tuple[list[dict], str, dict]:
            production_generator.configure_vdf_profile(profile)
            bank = production_generator.candidate_bank(
                len(production_generator.BODY_BANK)
            )
            actions = production_generator.build_actions(bank)
            return (
                actions,
                production_generator.render_plugin(
                    actions, production_generator.sources_for_bank(bank)
                ),
                production_generator.expansion_catalog_index(bank, actions),
            )

        def findings(actions: list[dict], source: str, index: dict) -> set[str]:
            validation = validator.Validation()
            validator.validate_phase4_adapter_canaries(
                source,
                validator.extract_rhai_functions(source),
                {action["name"] for action in actions},
                index,
                resources,
                validation,
                ROOT / "phase4-canary.rhai",
            )
            return self.finding_codes(validation)

        try:
            for profile in ("current", "economy"):
                with self.subTest(profile=profile):
                    actions, plugin, index = render(profile)
                    self.assertFalse(
                        {
                            code for code in findings(actions, plugin, index)
                            if code.startswith("rhai.phase4_")
                        }
                    )

            actions, plugin, index = render("economy")
            functions = validator.extract_rhai_functions(plugin)
            helper = functions["extract_base_vdf_2_core"]
            wrapper = functions["ExtractGas"]
            tail = (
                "var work=action.intro_vdf(2,body);\n"
                'body.update("work",work);'
            )

            def replace_helper(transform):
                return plugin.replace(helper, transform(helper), 1)

            vdf_mutations = {
                "wrong_cost": replace_helper(
                    lambda value: value.replace(
                        "action.intro_vdf(2,body)",
                        "action.intro_vdf(3,body)",
                        1,
                    )
                ),
                "parameterized_cost": replace_helper(
                    lambda value: value.replace(
                        "action.intro_vdf(2,body)",
                        "action.intro_vdf(vdf_cost,body)",
                        1,
                    )
                ),
                "renamed_witness": replace_helper(
                    lambda value: value.replace("var work=", "var other_work=", 1)
                ),
                "reversed_tail": replace_helper(
                    lambda value: value.replace(
                        tail,
                        'body.update("work",work);\n'
                        "var work=action.intro_vdf(2,body);",
                        1,
                    )
                ),
                "missing_tail_update": replace_helper(
                    lambda value: value.replace(
                        tail, "var work=action.intro_vdf(2,body);", 1
                    )
                ),
                "duplicate_tail_update": replace_helper(
                    lambda value: value.replace(
                        tail,
                        tail + '\nbody.update("work",work);',
                        1,
                    )
                ),
            }
            for name, mutant in vdf_mutations.items():
                with self.subTest(vdf_mutation=name):
                    self.assertNotEqual(plugin, mutant)
                    self.assertIn(
                        "rhai.phase4_vdf_owner",
                        findings(actions, mutant, index),
                    )

            resource_rows = [
                row for row in index["actions"]
                if row["family"] in validator.PHASE4_RESOURCE_FAMILIES
            ]
            boundary_rows = (
                resource_rows[0],
                resource_rows[len(resource_rows) // 2],
                resource_rows[-1],
            )
            for row in boundary_rows:
                action_name = row["name"]
                helper_name = row["helpers"][0]
                action_source = functions[action_name]
                omitted_wrapper = re.sub(
                    rf"\s*{re.escape(helper_name)}\s*\([^()]*\)\s*;",
                    "",
                    action_source,
                    count=1,
                    flags=re.DOTALL,
                )
                mutant = plugin.replace(action_source, omitted_wrapper, 1)
                with self.subTest(omitted_boundary=action_name):
                    codes = findings(actions, mutant, index)
                    self.assertTrue(
                        {
                            "rhai.phase4_wrapper_arguments",
                            "rhai.phase4_distribution",
                        }
                        <= codes,
                        codes,
                    )

            orphan_row = next(
                row for row in resource_rows
                if row["helpers"] == ["extract_direct_body_vdf_32_core"]
            )
            orphan_source = functions[orphan_row["name"]]
            orphan_wrapper = re.sub(
                r"\s*extract_direct_body_vdf_32_core\s*\([^()]*\)\s*;",
                "",
                orphan_source,
                count=1,
                flags=re.DOTALL,
            )
            orphan_mutant = plugin.replace(orphan_source, orphan_wrapper, 1)
            self.assertIn(
                "rhai.phase4_helper_reachability",
                findings(actions, orphan_mutant, index),
            )

            call_match = re.search(
                r"extract_base_vdf_2_core\s*\([^()]*\)\s*;",
                wrapper,
                flags=re.DOTALL,
            )
            self.assertIsNotNone(call_match)
            duplicated_wrapper = wrapper.replace(
                call_match.group(0),
                call_match.group(0) + "\n" + call_match.group(0),
                1,
            )
            duplicate_call = plugin.replace(wrapper, duplicated_wrapper, 1)
            self.assertIn(
                "rhai.phase4_wrapper_arguments",
                findings(actions, duplicate_call, index),
            )

            wrong_helper_wrapper = functions["ExtractRedDwarfRadiantEnergy"].replace(
                "extract_direct_body_vdf_4_core(",
                "extract_direct_body_vdf_12_core(",
                1,
            )
            wrong_helper = plugin.replace(
                functions["ExtractRedDwarfRadiantEnergy"],
                wrong_helper_wrapper,
                1,
            )
            wrong_literal = plugin.replace(
                wrapper,
                wrapper.replace(
                    '0,"gas_remaining",3,',
                    '0,"crystal_remaining",3,',
                    1,
                ),
                1,
            )
            forged_adapter = plugin.replace(
                wrapper,
                wrapper.replace(
                    "extract_base_vdf_2_core(",
                    "forged_extract_base_vdf_2_core(",
                    1,
                ),
                1,
            )
            old_scaffolding_wrapper = wrapper.replace(
                ");}",
                ");\nvar next_work=action.intro_vdf(2,body);\n"
                'body.update("work",next_work);\n}',
                1,
            )
            old_scaffolding = plugin.replace(
                wrapper, old_scaffolding_wrapper, 1
            )
            _current_actions, current_plugin, _current_index = render("current")
            current_only_helper = validator.extract_rhai_functions(current_plugin)[
                "extract_direct_body_no_vdf_core"
            ]
            mixed_profile = plugin + "\n" + current_only_helper + "\n"
            mutations = {
                "forged_adapter": forged_adapter,
                "wrong_helper": wrong_helper,
                "wrong_literal": wrong_literal,
                "old_scaffolding": old_scaffolding,
                "mixed_profile": mixed_profile,
                "wrong_underlying_core": replace_helper(
                    lambda value: value.replace(
                        "extract_direct_resource_core(",
                        "extract_composite_resource_core(",
                        1,
                ),
                ),
            }
            for name, mutant in mutations.items():
                with self.subTest(mutation=name):
                    self.assertNotEqual(plugin, mutant)
                    codes = findings(actions, mutant, index)
                    self.assertTrue(
                        any(code.startswith("rhai.phase4_") for code in codes),
                        codes,
                    )
            self.assertIn(
                "rhai.phase4_wrapper_arguments",
                findings(actions, wrong_literal, index),
            )
            self.assertIn(
                "rhai.phase4_core_route",
                findings(actions, mutations["wrong_underlying_core"], index),
            )
            self.assertIn(
                "rhai.phase4_unknown_adapter",
                findings(actions, forged_adapter, index),
            )
            self.assertIn(
                "rhai.phase4_wrapper_scaffolding",
                findings(actions, old_scaffolding, index),
            )
            self.assertIn(
                "rhai.phase4_active_profile",
                findings(actions, mixed_profile, index),
            )
        finally:
            production_generator.configure_vdf_profile("economy")

    def test_phase5_canary_validator_binds_recipe_topologies(self) -> None:
        import generate_microverse as production_generator

        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")

        def render(profile: str) -> tuple[list[dict], str, dict]:
            production_generator.configure_vdf_profile(profile)
            bank = production_generator.candidate_bank(
                len(production_generator.BODY_BANK)
            )
            actions = production_generator.build_actions(bank)
            return (
                actions,
                production_generator.render_plugin(
                    actions, production_generator.sources_for_bank(bank)
                ),
                production_generator.expansion_catalog_index(bank, actions),
            )

        def findings(actions: list[dict], source: str, index: dict) -> set[str]:
            validation = validator.Validation()
            validator.validate_phase5_adapter_canaries(
                source,
                validator.extract_rhai_functions(source),
                {action["name"] for action in actions},
                index,
                validation,
                ROOT / "phase5-canary.rhai",
            )
            return self.finding_codes(validation)

        try:
            for profile in ("economy", "current"):
                with self.subTest(profile=profile):
                    actions, plugin, index = render(profile)
                    functions = validator.extract_rhai_functions(plugin)
                    bulk_routes = sum(
                        bool(validator.phase5_adapter_like_names(
                            functions.get(action["name"], "")
                        ))
                        for action in actions
                    )
                    if bulk_routes != 234:
                        self.skipTest("Phase 5 bulk generator routing is not active")
                    self.assertFalse(
                        {
                            code for code in findings(actions, plugin, index)
                            if code.startswith("rhai.phase5_")
                        }
                    )
                    component = functions["FabricateStructuralAlloyReusable"]
                    helper = functions["fabricate_component_reusable_vdf_8_core"]
                    derived = functions["DevelopStructuralMetallurgySkill"]
                    derived_helper = functions[
                        "develop_derived_skill_2_evidence_vdf_8_core"
                    ]
                    artifact_helper = functions[
                        "produce_capability_artifact_1_evidence_vdf_8_core"
                    ]
                    non_canary = functions["UseTechnologySkill"]
                    derived_tail = (
                        "var work=action.intro_vdf(8,technology_skill);\n"
                        'technology_skill.update("work",work);'
                    )
                    derived_core = (
                        "develop_derived_skill_core(action,next_ship,technology_skill,ship,"
                        "parent_skill_type,output_skill_type);\n"
                        "prove_resource_stack_core(action,evidence_1,evidence_1_type,"
                        "evidence_1_amount);\n"
                        "prove_resource_stack_core(action,evidence_2,evidence_2_type,"
                        "evidence_2_amount);"
                    )
                    component_call = re.search(
                        r"fabricate_component_reusable_vdf_8_core\s*\([^()]*\)\s*;",
                        component,
                        flags=re.DOTALL,
                    )
                    self.assertIsNotNone(component_call)
                    last_component_role = (
                        'var k=action.mutate("MicroverseResource");'
                    )

                    mutations = {
                        "wrong_mode": plugin.replace(
                            component,
                            component.replace(
                                'action.mutate("MicroverseResource")',
                                'action.input("MicroverseResource")',
                                1,
                            ),
                            1,
                        ),
                        "adapter_before_last_role": plugin.replace(
                            component,
                            component.replace(
                                last_component_role + "\n" + component_call.group(0),
                                component_call.group(0) + "\n" + last_component_role,
                                1,
                            ),
                            1,
                        ),
                        "duplicate_call": plugin.replace(
                            component,
                            component.replace(
                                component_call.group(0),
                                component_call.group(0) + "\n" + component_call.group(0),
                                1,
                            ),
                            1,
                        ),
                        "commented_wrapper_call": plugin.replace(
                            component,
                            component.replace(
                                component_call.group(0),
                                "/* " + component_call.group(0) + " */",
                                1,
                            ),
                            1,
                        ),
                        "extra_wrapper_proof": plugin.replace(
                            component,
                            component.replace(
                                ");}",
                                ");\naction.st_sum(0,0,0);\n}",
                                1,
                            ),
                            1,
                        ),
                        "wrong_literal": plugin.replace(
                            component,
                            component.replace("211,6", "212,6", 1),
                            1,
                        ),
                        "wrong_core": plugin.replace(
                            helper,
                            helper.replace(
                                "fabricate_component_core(",
                                "produce_capability_artifact_core(",
                                1,
                            ),
                            1,
                        ),
                        "commented_helper_core": plugin.replace(
                            helper,
                            re.sub(
                                r"fabricate_component_core\s*\([^()]*\)\s*;",
                                lambda match: "/* " + match.group(0) + " */",
                                helper,
                                count=1,
                                flags=re.DOTALL,
                            ),
                            1,
                        ),
                        "wrong_catalyst": plugin.replace(
                            helper,
                            helper.replace(
                                "consume_component_catalyst_reusable_core(",
                                "consume_component_catalyst_final_core(",
                                1,
                            ),
                            1,
                        ),
                        "evidence_order": plugin.replace(
                            derived_helper,
                            derived_helper.replace(
                                "evidence_1,evidence_1_type,evidence_1_amount);\n"
                                "prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);",
                                "evidence_2,evidence_2_type,evidence_2_amount);\n"
                                "prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);",
                                1,
                            ),
                            1,
                        ),
                        "wrong_evidence": plugin.replace(
                            derived_helper,
                            derived_helper.replace(
                                "evidence_1_type,evidence_1_amount",
                                "evidence_2_type,evidence_1_amount",
                                1,
                            ),
                            1,
                        ),
                        "wrong_vdf_tail": plugin.replace(
                            artifact_helper,
                            artifact_helper.replace(
                                'artifact.update("work",work);',
                                'technology_skill.update("work",work);',
                                1,
                            ),
                            1,
                        ),
                        "tail_before_core": plugin.replace(
                            derived_helper,
                            derived_helper.replace(
                                derived_core + "\n" + derived_tail,
                                derived_tail + "\n" + derived_core,
                                1,
                            ),
                            1,
                        ),
                        "unknown_inventory": plugin + "\nfn forged_fabricate_component_reusable_vdf_8_core(action) {}\n",
                        "hidden_non_recipe_caller": plugin + "\nfn hidden_phase5_caller(action) { fabricate_component_reusable_vdf_8_core(); }\n",
                        "orphan_helper": re.sub(
                            r"fabricate_component_reusable_vdf_8_core\s*\([^()]*\)\s*;",
                            "",
                            plugin,
                            flags=re.DOTALL,
                        ),
                        "non_canary_route": plugin.replace(
                            non_canary,
                            non_canary.replace(
                                "\n}",
                                "\nfabricate_component_reusable_vdf_8_core();\n}",
                                1,
                            ),
                            1,
                        ),
                    }
                    expected_routes = [
                        row for row in index["actions"]
                        if validator.phase5_expected_route(row) is not None
                    ]
                    self.assertEqual(234, len(expected_routes))
                    for row in (
                        expected_routes[0],
                        expected_routes[len(expected_routes) // 2],
                        expected_routes[-1],
                    ):
                        route = validator.phase5_expected_route(row)
                        self.assertIsNotNone(route)
                        action_name = row["name"]
                        wrapper = functions[action_name]
                        omitted = re.sub(
                            rf"\s*{re.escape(route[0])}\s*\([^()]*\)\s*;",
                            "",
                            wrapper,
                            count=1,
                            flags=re.DOTALL,
                        )
                        with self.subTest(profile=profile, omission=action_name):
                            codes = findings(
                                actions, plugin.replace(wrapper, omitted, 1), index
                            )
                            self.assertIn("rhai.phase5_wrapper_arguments", codes)
                    for mutation, mutant in mutations.items():
                        with self.subTest(profile=profile, mutation=mutation):
                            self.assertNotEqual(plugin, mutant)
                            codes = findings(actions, mutant, index)
                            self.assertTrue(
                                any(code.startswith("rhai.phase5_") for code in codes),
                                codes,
                            )
                    self.assertIn(
                        "rhai.phase5_wrapper_arguments",
                        findings(actions, mutations["wrong_mode"], index),
                    )
                    self.assertIn(
                        "rhai.phase5_helper_shape",
                        findings(actions, mutations["evidence_order"], index),
                    )
                    self.assertIn(
                        "rhai.phase5_helper_shape",
                        findings(actions, mutations["tail_before_core"], index),
                    )
                    self.assertIn(
                        "rhai.phase5_wrapper_arguments",
                        findings(actions, mutations["adapter_before_last_role"], index),
                    )
                    self.assertIn(
                        "rhai.phase5_wrapper_arguments",
                        findings(actions, mutations["extra_wrapper_proof"], index),
                    )
                    self.assertIn(
                        "rhai.phase5_wrapper_arguments",
                        findings(actions, mutations["commented_wrapper_call"], index),
                    )
                    self.assertIn(
                        "rhai.phase5_helper_shape",
                        findings(actions, mutations["commented_helper_core"], index),
                    )
                    self.assertIn(
                        "rhai.phase5_helper_shape",
                        findings(actions, mutations["hidden_non_recipe_caller"], index),
                    )
                    self.assertIn(
                        "rhai.phase5_unknown_adapter",
                        findings(actions, mutations["unknown_inventory"], index),
                    )
                    self.assertIn(
                        "rhai.phase5_routing",
                        findings(actions, mutations["non_canary_route"], index),
                    )
        finally:
            production_generator.configure_vdf_profile("economy")

    def test_phase6_canary_validator_binds_movement_timewarp_topologies(self) -> None:
        import generate_microverse as production_generator

        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")

        def render(profile: str) -> tuple[list[dict], str, dict]:
            production_generator.configure_vdf_profile(profile)
            bank = production_generator.candidate_bank(
                len(production_generator.BODY_BANK)
            )
            actions = production_generator.build_actions(bank)
            return (
                actions,
                production_generator.render_plugin(
                    actions, production_generator.sources_for_bank(bank)
                ),
                production_generator.expansion_catalog_index(bank, actions),
            )

        def findings(actions: list[dict], source: str, index: dict) -> set[str]:
            validation = validator.Validation()
            validator.validate_phase6_movement_canaries(
                source,
                validator.extract_rhai_functions(source),
                {action["name"] for action in actions},
                index,
                validation,
                ROOT / "phase6-canary.rhai",
            )
            return self.finding_codes(validation)

        try:
            current_actions, current_plugin, current_index = render("current")
            self.assertFalse(
                validator.phase6_adapter_like_names(current_plugin)
            )
            self.assertFalse(
                set(validator.extract_rhai_functions(current_plugin))
                & validator.PHASE6_KNOWN_HELPER_NAMES
            )
            self.assertFalse(findings(current_actions, current_plugin, current_index))
            self.assertFalse(findings(
                current_actions,
                current_plugin + "\n/* fn move_positive_core(action) {} */\n",
                current_index,
            ))
            self.assertFalse(findings(
                current_actions,
                current_plugin + "\n/*\nfn move_positive_core(action) {}\n*/\n",
                current_index,
            ))
            self.assertIn(
                "rhai.phase6_current_inventory",
                findings(
                    current_actions,
                    current_plugin
                    + "\nfn forged_move_positive_core(action) {}\n",
                    current_index,
                ),
            )

            actions, plugin, index = render("economy")
            functions = validator.extract_rhai_functions(plugin)
            if not (set(functions) & validator.PHASE6_KNOWN_HELPER_NAMES):
                self.skipTest("Phase 6 canary generator routing is not active")
            self.assertFalse({
                code for code in findings(actions, plugin, index)
                if code.startswith("rhai.phase6_")
            })
            self.assertEqual(21, len(validator.PHASE6_ECONOMY_ROUTES))
            self.assertEqual(
                {
                    "move_positive_core": 9,
                    "move_negative_core": 9,
                    "advance_ship_epoch_core": 3,
                    "update_ship_work_vdf_4_core": 7,
                    "update_ship_work_vdf_12_core": 7,
                    "update_ship_work_vdf_28_core": 7,
                },
                dict(Counter(
                    helper_name
                    for route in validator.PHASE6_ECONOMY_ROUTES.values()
                    for helper_name, _arguments in route
                )),
            )
            string_only_reference = (
                plugin
                + '\nfn hidden_phase6_note(action) { let note = "move_positive_core(action)"; }\n'
            )
            self.assertFalse({
                code for code in findings(actions, string_only_reference, index)
                if code.startswith("rhai.phase6_")
            })

            positive = functions["move_positive_core"]
            vdf4 = functions["update_ship_work_vdf_4_core"]
            epoch_helper = functions["advance_ship_epoch_core"]
            positive_x = functions["MovePositiveX"]
            negative_y_medium = functions["MoveNegativeYMedium"]
            negative_z_large = functions["MoveNegativeZLarge"]
            positive_y_medium = functions["MovePositiveYMedium"]
            negative_x_large = functions["MoveNegativeXLarge"]
            timewarp_small = functions["TimeWarpSmall"]
            timewarp_medium = functions["TimeWarpMedium"]
            timewarp_large = functions["TimeWarpLarge"]
            first_call = re.search(
                r"move_positive_core\s*\([^()]*\)\s*;",
                positive_x,
            ).group(0)
            second_call = re.search(
                r"update_ship_work_vdf_4_core\s*\([^()]*\)\s*;",
                positive_x,
            ).group(0)
            epoch_call = re.search(
                r"advance_ship_epoch_core\s*\([^()]*\)\s*;",
                timewarp_small,
            ).group(0)
            timewarp_vdf_call = re.search(
                r"update_ship_work_vdf_4_core\s*\([^()]*\)\s*;",
                timewarp_small,
            ).group(0)
            mutations = {
                "wrong_field": plugin.replace(
                    positive_x,
                    positive_x.replace('"x"', '"y"', 1),
                    1,
                ),
                "wrong_direction": plugin.replace(
                    positive,
                    positive.replace("current_coordinate-(0-step)", "current_coordinate-step", 1),
                    1,
                ),
                "wrong_tier": plugin.replace(
                    negative_y_medium,
                    re.sub(
                        r"move_negative_core\s*\([^()]*\)\s*;",
                        'move_negative_core(action, ship, ship.y, "y", 1, 10, 1);',
                        negative_y_medium,
                        1,
                    ),
                    1,
                ),
                "wrong_capacity": plugin.replace(
                    positive_x,
                    re.sub(
                        r"move_positive_core\s*\([^()]*\)\s*;",
                        'move_positive_core(action, ship, ship.x, "x", 1, 11, 1);',
                        positive_x,
                        1,
                    ),
                    1,
                ),
                "wrong_current_coordinate": plugin.replace(
                    negative_z_large,
                    negative_z_large.replace("ship.z,\"z\"", "ship.y,\"z\"", 1),
                    1,
                ),
                "wrong_bulk_step": plugin.replace(
                    positive_y_medium,
                    positive_y_medium.replace(",10,50,5);", ",100,50,5);", 1),
                    1,
                ),
                "wrong_bulk_vdf_tier": plugin.replace(
                    negative_x_large,
                    negative_x_large.replace(
                        "update_ship_work_vdf_28_core(",
                        "update_ship_work_vdf_12_core(",
                        1,
                    ),
                    1,
                ),
                "wrong_timewarp_medium_step": plugin.replace(
                    timewarp_medium,
                    timewarp_medium.replace(
                        "action.st_sum(ship.epoch,10,next_epoch);",
                        "action.st_sum(ship.epoch,1,next_epoch);",
                        1,
                    ),
                    1,
                ),
                "wrong_timewarp_large_capacity": plugin.replace(
                    timewarp_large,
                    timewarp_large.replace(
                        "action.st_sum(ship.extraction_amount,0,250);",
                        "action.st_sum(ship.extraction_amount,0,50);",
                        1,
                    ),
                    1,
                ),
                "wrong_vdf_cost": plugin.replace(
                    vdf4,
                    vdf4.replace("action.intro_vdf(4,ship)", "action.intro_vdf(5,ship)", 1),
                    1,
                ),
                "wrong_vdf_target": plugin.replace(
                    vdf4,
                    vdf4.replace('ship.update("work",work)', 'body.update("work",work)', 1),
                    1,
                ),
                "wrong_vdf_witness": plugin.replace(
                    vdf4,
                    vdf4.replace("var work=", "var next_work=", 1),
                    1,
                ),
                "wrong_call_order": plugin.replace(
                    positive_x,
                    positive_x.replace(
                        first_call + "\n" + second_call,
                        second_call + "\n" + first_call,
                        1,
                    ),
                    1,
                ),
                "moved_helper_call": plugin.replace(
                    positive_x,
                    re.sub(
                        r"(var\s+ship\s*=\s*action\.mutate\s*\(\s*\"MicroverseShip\"\s*\)\s*;)(\s*)"
                        + re.escape(first_call),
                        first_call + r"\2\1",
                        positive_x,
                        count=1,
                    ),
                    1,
                ),
                "commented_wrapper_call": plugin.replace(
                    positive_x,
                    positive_x.replace(first_call, "/* " + first_call + " */", 1),
                    1,
                ),
                "commented_helper_statement": plugin.replace(
                    positive,
                    positive.replace(
                        "rotate_key(ship,next_ship_key);",
                        "/* rotate_key(ship,next_ship_key); */",
                        1,
                    ),
                    1,
                ),
                "missing_helper": plugin.replace(positive, "", 1),
                "missing_all_adapters": re.sub(
                    r"\b(?:move_positive_core|move_negative_core|advance_ship_epoch_core|"
                    r"update_ship_work_vdf_(?:4|12|28)_core)\b",
                    "legacy_phase6_core",
                    plugin,
                ),
                "duplicate_helper": plugin + "\n" + positive + "\n",
                "outside_caller": plugin
                + "\nfn hidden_phase6_caller(action) { move_positive_core(action, ship, ship.x, \"x\", 1, 10, 1); }\n",
                "outside_nested_caller": plugin
                + "\nfn hidden_nested_phase6_caller(action) { move_positive_core(action, action.random(), ship.x, \"x\", 1, 10, 1); }\n",
                "outside_final_expression_caller": plugin
                + "\nfn hidden_final_phase6_caller(action) { move_positive_core(action, ship, ship.x, \"x\", 1, 10, 1) }\n",
                "outside_nested_expression_caller": plugin
                + "\nfn hidden_expression_phase6_caller(action) { identity(move_positive_core(action, ship, ship.x, \"x\", 1, 10, 1)); }\n",
                "orphan_helper": plugin.replace(second_call, "", 1),
                "orphan_vdf4_helper": re.sub(
                    r"update_ship_work_vdf_4_core\s*\([^()]*\)\s*;",
                    "",
                    plugin,
                ),
                "trailing_live_helper_code": plugin.replace(
                    positive,
                    positive.replace(
                        "rotate_key(ship,next_ship_key);",
                        "rotate_key(ship,next_ship_key);\n// }\n"
                        "action.st_sum(0,0,0);",
                        1,
                    ),
                    1,
                ),
                "extra_wrapper_statement": plugin.replace(
                    timewarp_small,
                    timewarp_small.replace(
                        "\n}", "\naction.st_sum(0, 0, 0);\n}", 1
                    ),
                    1,
                ),
                "missing_wrapper_epoch_sum": plugin.replace(
                    timewarp_small,
                    timewarp_small.replace(
                        "action.st_sum(ship.epoch,1,next_epoch);\n",
                        "",
                        1,
                    ),
                    1,
                ),
                "wrong_wrapper_epoch_sum": plugin.replace(
                    timewarp_small,
                    timewarp_small.replace(
                        "action.st_sum(ship.epoch,1,next_epoch);",
                        "action.st_sum(ship.epoch,2,next_epoch);",
                        1,
                    ),
                    1,
                ),
                "epoch_sum_moved_to_helper": plugin.replace(
                    timewarp_small,
                    timewarp_small.replace(
                        "action.st_sum(ship.epoch,1,next_epoch);\n",
                        "",
                        1,
                    ),
                    1,
                ).replace(
                    epoch_helper,
                    epoch_helper.replace(
                        "{\n",
                        "{\naction.st_sum(ship.epoch,1,next_epoch);\n",
                        1,
                    ),
                    1,
                ),
                "reordered_timewarp_helpers": plugin.replace(
                    timewarp_small,
                    timewarp_small.replace(
                        epoch_call + "\n" + timewarp_vdf_call,
                        timewarp_vdf_call + "\n" + epoch_call,
                        1,
                    ),
                    1,
                ),
                "extra_helper_epoch_proof": plugin.replace(
                    epoch_helper,
                    epoch_helper.replace(
                        "{\n",
                        "{\naction.st_sum(ship.epoch,0,next_epoch);\n",
                        1,
                    ),
                    1,
                ),
                "role_order": plugin.replace(
                    positive_x,
                    positive_x.replace(
                        'action.mutate("MicroverseShip")',
                        'action.input("MicroverseShip")',
                        1,
                    ),
                    1,
                ),
            }
            for name, mutant in mutations.items():
                with self.subTest(mutation=name):
                    self.assertNotEqual(plugin, mutant)
                    codes = findings(actions, mutant, index)
                    self.assertTrue(
                        any(code.startswith("rhai.phase6_") for code in codes),
                        codes,
                    )
            self.assertIn(
                "rhai.phase6_vdf_owner",
                findings(actions, mutations["wrong_vdf_cost"], index),
            )
            self.assertIn(
                "rhai.phase6_wrapper_arguments",
                findings(actions, mutations["role_order"], index),
            )
            self.assertIn(
                "rhai.phase6_routing",
                findings(actions, mutations["outside_caller"], index),
            )
            self.assertIn(
                "rhai.phase6_routing",
                findings(actions, mutations["outside_nested_caller"], index),
            )
            for mutation in (
                "outside_final_expression_caller",
                "outside_nested_expression_caller",
            ):
                with self.subTest(outside_expression=mutation):
                    self.assertIn(
                        "rhai.phase6_routing",
                        findings(actions, mutations[mutation], index),
                    )
            self.assertIn(
                "rhai.phase6_helper_shape",
                findings(actions, mutations["trailing_live_helper_code"], index),
            )
            self.assertIn(
                "rhai.phase6_active_inventory",
                findings(actions, mutations["missing_all_adapters"], index),
            )
            for mutation in (
                "missing_wrapper_epoch_sum",
                "wrong_wrapper_epoch_sum",
                "reordered_timewarp_helpers",
            ):
                with self.subTest(wrapper_epoch_mutation=mutation):
                    self.assertIn(
                        "rhai.phase6_wrapper_arguments",
                        findings(actions, mutations[mutation], index),
                    )
            for mutation in (
                "epoch_sum_moved_to_helper",
                "extra_helper_epoch_proof",
            ):
                with self.subTest(helper_epoch_mutation=mutation):
                    self.assertIn(
                        "rhai.phase6_helper_shape",
                        findings(actions, mutations[mutation], index),
                    )
            for mutation, action_name, helpers in (
                ("empty", "MovePositiveX", []),
                ("omitted", "MoveNegativeYMedium", None),
                (
                    "reversed",
                    "TimeWarpSmall",
                    ["update_ship_work_vdf_4_core", "advance_ship_epoch_core"],
                ),
            ):
                changed_index = json.loads(json.dumps(index))
                row = next(
                    item for item in changed_index["actions"]
                    if item["name"] == action_name
                )
                if helpers is None:
                    row.pop("helpers")
                else:
                    row["helpers"] = helpers
                with self.subTest(index_mutation=mutation):
                    self.assertIn(
                        "rhai.phase6_index_metadata",
                        findings(actions, plugin, changed_index),
                    )
            current_with_unrelated_helper = json.loads(json.dumps(current_index))
            next(
                item for item in current_with_unrelated_helper["actions"]
                if item["name"] == "BuildShipSmall"
            )["helpers"] = ["update_ship_work_vdf_4_core"]
            self.assertIn(
                "rhai.phase6_current_index_metadata",
                findings(
                    current_actions,
                    current_plugin,
                    current_with_unrelated_helper,
                ),
            )
        finally:
            production_generator.configure_vdf_profile("economy")

    def test_phase6_adapter_layout_is_canonical_and_fail_closed(self) -> None:
        import generate_microverse as production_generator

        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")

        def render(profile: str) -> tuple[list[dict], str, dict]:
            production_generator.configure_vdf_profile(profile)
            bank = production_generator.candidate_bank(
                len(production_generator.BODY_BANK)
            )
            actions = production_generator.build_actions(bank)
            return (
                actions,
                production_generator.render_plugin(
                    actions, production_generator.sources_for_bank(bank)
                ),
                production_generator.expansion_catalog_index(bank, actions),
            )

        def findings(actions: list[dict], source: str, index: dict) -> set[str]:
            validation = validator.Validation()
            validator.validate_phase6_layout_contract(
                source,
                validator.extract_rhai_functions(source),
                {action["name"] for action in actions},
                index,
                validation,
                ROOT / "phase6-layout.rhai",
            )
            return self.finding_codes(validation)

        sample = (
            'fn Note(action) { // ignored helper(action)\n'
            'let note = "https://example.invalid/move_positive_core(action)";\n'
            '}\n'
        )
        canonical_sample = validator.phase6_layout_minify(sample)
        self.assertEqual(
            'fn Note(action){\n'
            'let note="https://example.invalid/move_positive_core(action)";\n'
            '}\n',
            canonical_sample,
        )
        self.assertEqual(
            validator.phase6_layout_tokens(sample),
            validator.phase6_layout_tokens(canonical_sample),
        )
        self.assertEqual(
            canonical_sample,
            validator.phase6_layout_minify(canonical_sample),
        )

        try:
            for profile in ("economy", "current"):
                with self.subTest(profile=profile):
                    actions, plugin, index = render(profile)
                    self.assertEqual(
                        921, len(validator.phase6_layout_adapter_names(index))
                    )
                    self.assertFalse({
                        code for code in findings(actions, plugin, index)
                        if code.startswith("rhai.phase6_layout_")
                    })

            actions, plugin, index = render("economy")
            functions = validator.extract_rhai_functions(plugin)
            first = functions["ExtractGas"]
            second = functions["ExtractEnergy"]
            noncanonical = plugin.replace(
                first,
                first.replace("var next_ship=", "var next_ship = ", 1),
                1,
            )
            commented = plugin.replace(
                first, first.replace(");}", ");\n// redundant\n}", 1), 1
            )
            simple_overflow = plugin.replace(
                first,
                first.replace("var next_ship=", "var" + (" " * 145) + "next_ship=", 1),
                1,
            )
            identifier_merge = plugin.replace(
                first, first.replace("var next_ship=", "varnext_ship=", 1), 1
            )
            complex_join_wrapper = re.sub(
                r"\n(extract_base_vdf_2_core\()",
                r"\1",
                first,
                count=1,
            )
            complex_join = plugin.replace(first, complex_join_wrapper, 1)
            marker = "__PHASE6_LAYOUT_SWAP__"
            wrong_order = plugin.replace(first, marker, 1).replace(
                second, first, 1
            ).replace(marker, second, 1)
            mutations = {
                "noncanonical": (
                    noncanonical, "rhai.phase6_layout_token_equality"
                ),
                "commented": (
                    commented, "rhai.phase6_layout_token_equality"
                ),
                "crlf": (
                    plugin.replace("\n", "\r\n"),
                    "rhai.phase6_layout_line_endings",
                ),
                "missing_final_newline": (
                    plugin.rstrip("\n"), "rhai.phase6_layout_line_endings"
                ),
                "space_only_terminal_line": (
                    plugin + " \n", "rhai.phase6_layout_line_endings"
                ),
                "tab_only_terminal_line": (
                    plugin + "\t\n", "rhai.phase6_layout_line_endings"
                ),
                "wrong_order": (
                    wrong_order, "rhai.phase6_layout_inventory_order"
                ),
                "global_overflow": (
                    plugin + ("//" + ("x" * 278) + "\n"),
                    "rhai.phase6_layout_global_line_limit",
                ),
                "simple_overflow": (
                    simple_overflow, "rhai.phase6_layout_simple_line_limit"
                ),
                "identifier_merge": (
                    identifier_merge, "rhai.phase6_layout_identifier_merge"
                ),
                "complex_join": (
                    complex_join, "rhai.phase6_layout_complex_join"
                ),
            }
            for mutation, (source, expected_code) in mutations.items():
                with self.subTest(layout_mutation=mutation):
                    self.assertNotEqual(plugin, source)
                    self.assertIn(expected_code, findings(actions, source, index))
            for terminal_whitespace in (plugin + " \n", plugin + "\t\n"):
                self.assertIn(
                    "rhai.phase6_layout_global_canonical",
                    findings(actions, terminal_whitespace, index),
                )
        finally:
            production_generator.configure_vdf_profile("economy")


if __name__ == "__main__":
    unittest.main()
