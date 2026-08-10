#!/usr/bin/env python3
"""Regression tests for the isolated, no-submit expansion harness tooling."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import generate_microverse_expansion_test as generator  # noqa: E402
import generate_microverse as production_generator  # noqa: E402
import run_microverse_expansion_tests as runner  # noqa: E402
import run_microverse_expansion_plans as plan_runner  # noqa: E402
import validate_expansion_catalogs as validator  # noqa: E402


class ExpansionTestToolingTests(unittest.TestCase):
    def load(self, name: str) -> dict:
        return json.loads((ROOT / "catalog" / name).read_text(encoding="utf-8"))

    @staticmethod
    def string_forge_first_call(source: str, name: str) -> str:
        start = production_generator.rhai_call_positions(source, name)[0]
        end = source.find(";", start) + 1
        call = source[start:end]
        escaped = call.replace("\\", "\\\\").replace('"', '\\"')
        return source[:start] + f'let marker="{escaped}";' + source[end:]

    def test_generated_text_is_written_as_exact_lf_utf8_bytes(self) -> None:
        value = "one\ntwo\n"
        with tempfile.TemporaryDirectory() as temp_dir:
            path = Path(temp_dir) / "generated.txt"
            generator.write_utf8(path, value)
            disk_bytes = path.read_bytes()
        self.assertEqual(b"one\ntwo\n", disk_bytes)
        self.assertEqual(
            generator.sha256_text(value),
            hashlib.sha256(disk_bytes).hexdigest(),
        )

    def production_audit_inputs(self) -> tuple[list[dict], str]:
        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(
                ROOT / "catalog"
            )
        production_generator.configure_vdf_profile("economy")
        bank = production_generator.candidate_bank(
            len(production_generator.BODY_BANK)
        )
        actions = production_generator.build_actions(bank)
        return (
            actions,
            production_generator.render_plugin(
                actions,
                production_generator.sources_for_bank(bank),
            ),
        )

    def all_fixture_rows(self) -> tuple[generator.FixtureRegistry, dict]:
        resource = self.load("microverse-resource-tree-v2.json")
        component = self.load("microverse-component-tree-v2.json")
        skill = self.load("microverse-skill-tree-v2.json")
        warp = self.load("microverse-warp-tree-v2.json")
        index = self.load("microverse-catalog-index-v2.json")
        schemas = json.loads(
            (ROOT / "generated" / "schema-counts.json").read_text(
                encoding="utf-8"
            )
        )
        actions = set(
            generator.validator.manifest_action_names(
                (ROOT / "manifest.toml").read_text(encoding="utf-8")
            )
        )
        fixtures = generator.FixtureRegistry()
        generator.resource_scenarios(resource, fixtures, actions)
        generator.component_scenarios(component, fixtures, actions)
        generator.skill_scenarios(skill, component, index, fixtures, actions)
        generator.warp_lifecycle_scenarios(warp, resource, fixtures, actions)
        source_by_name = {
            row["action"]: source
            for row, source in zip(fixtures.rows, fixtures.sources, strict=True)
        }
        generator.enrich_fixture_contract_rows(
            fixtures.rows, source_by_name, schemas
        )
        return fixtures, schemas

    def test_exact_schema_types_are_frozen_across_generator_artifacts(self) -> None:
        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        production_generator.validate_all_schema_field_types()
        self.assertEqual(20, len(production_generator.CLASS_ORDER))
        self.assertEqual(
            set(production_generator.CLASS_ORDER),
            set(production_generator.SCHEMAS),
        )
        for class_name in production_generator.CLASS_ORDER:
            for field_name, field_type in production_generator.SCHEMAS[class_name]:
                self.assertEqual(
                    production_generator.expected_schema_field_type(field_name),
                    field_type,
                    f"{class_name}.{field_name}",
                )

        warp_catalog = self.load("microverse-warp-tree-v2.json")
        catalog_by_class = {
            row["class_name"]: row["schema_fields"]
            for row in warp_catalog["object_types"]
        }
        sidecar = production_generator.schema_sidecar(
            list(production_generator.CLASS_ORDER)
        )
        actions, _plugin = self.production_audit_inputs()
        index = production_generator.expansion_catalog_index(
            production_generator.candidate_bank(
                len(production_generator.BODY_BANK)
            ),
            actions,
        )
        index_by_class = {
            row["class_name"]: row["schema_fields"]
            for row in index["warp"]["object_types"]
        }
        for class_name, expected_schema in (
            production_generator.EXPECTED_WARP_OBJECT_SCHEMAS.items()
        ):
            expected_fields = [
                {"name": field_name, "type": field_type}
                for field_name, field_type in expected_schema
            ]
            self.assertEqual(expected_fields, catalog_by_class[class_name])
            self.assertEqual(expected_fields, index_by_class[class_name])
            self.assertEqual(
                expected_fields, sidecar["classes"][class_name]["fields"]
            )

        bad_catalog = json.loads(json.dumps(warp_catalog))
        position_anchor = next(
            row
            for row in bad_catalog["object_types"]
            if row["class_name"] == "MicroversePositionAnchor"
        )
        next(
            field
            for field in position_anchor["schema_fields"]
            if field["name"] == "source_ship_id"
        )["type"] = "Int"
        with self.assertRaisesRegex(ValueError, "exact warp schema changed"):
            production_generator.configure_warp_catalog(bad_catalog)

    def test_chart_extraction_inserts_destination_keys_before_reveal(self) -> None:
        cases = (
            (
                False,
                (
                    "schema_version",
                    "mechanics_version",
                    "universe_version",
                    "catalog_version",
                    "source_body_identifier",
                    "source_pool_before",
                    "revealed",
                    "destination_code",
                    "destination_x",
                    "destination_y",
                    "destination_z",
                    "uses_remaining",
                ),
            ),
            (
                True,
                (
                    "schema_version",
                    "mechanics_version",
                    "universe_version",
                    "catalog_version",
                    "source_body_identifier",
                    "source_pool_before",
                    "revealed",
                    "destination_code",
                    "destination_epoch",
                    "uses_remaining",
                ),
            ),
        )
        for time_only, fields in cases:
            with self.subTest(time_only=time_only):
                source = production_generator.extract_v2_chart_source(
                    time_only=time_only
                )
                self.assertEqual(1, source.count("chart.set("))
                self.assertEqual(
                    list(fields),
                    production_generator.object_set_fields(source, "chart"),
                )
                for token in (
                    "var source_body_identifier = action.random();",
                    "var_assign(source_body_identifier, body.stable_identifier);",
                    'body.update("stable_identifier", source_body_identifier);',
                    "var source_pool_before = unsafe { body.energy_remaining - 0 };",
                    "action.st_sum(body.energy_remaining, 0, source_pool_before);",
                    '["source_body_identifier", source_body_identifier]',
                    '["source_pool_before", source_pool_before]',
                ):
                    self.assertIn(token, source)
                for field in fields:
                    if field.startswith("destination_"):
                        self.assertNotIn(f'chart.update("{field}"', source)
        helper = production_generator.named_function_source(
            production_generator.common_helpers(), "extract_v2_chart_core"
        )
        self.assertNotIn("chart.set(", helper)
        self.assertNotIn("source_body_identifier", helper)
        self.assertNotIn("source_pool_before", helper)
        self.assertNotIn('body.update("stable_identifier"', helper)

    def test_runtime_proven_constructor_shape_is_frozen(self) -> None:
        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        expected = {
            "ConstructWormholeLink": (
                production_generator.construct_link_source(time_only=False),
                2823,
                "1bcf30984cf78185ad80e71d23ea2cb018a9215d6821c262e803757b0913a24e",
            ),
            "ConstructTemporalLink": (
                production_generator.construct_link_source(time_only=True),
                2255,
                "428c5f0bae141e1dcf48c5a80f3197dd789fa83fb3d5f21d83ecc9ada66a868b",
            ),
            "ComposeRendezvousCoordinate": (
                production_generator.compose_rendezvous_source(),
                2677,
                "3c846ee729190805c00bc214b6e4b6985dbb77908775a10c5e3ae8f4cc8f375d",
            ),
        }
        for name, (source, expected_bytes, expected_sha256) in expected.items():
            with self.subTest(action=name):
                rendered = production_generator.compact_rhai_layout(source)
                vdf_free, removed = generator.remove_vdf_blocks(rendered, name)
                runtime_shape = vdf_free.rstrip().encode("utf-8")
                self.assertEqual(1, removed)
                self.assertEqual(expected_bytes, len(runtime_shape))
                self.assertEqual(
                    expected_sha256,
                    hashlib.sha256(runtime_shape).hexdigest(),
                )
                checks = production_generator.constructor_witness_copy_audit(
                    rendered,
                    production_generator.CONSTRUCTOR_COPY_SPECS[name],
                )
                self.assertTrue(all(checks.values()), checks)
        actions = production_generator.build_actions(
            production_generator.candidate_bank(
                len(production_generator.BODY_BANK)
            )
        )
        actions_by_name = {row["name"]: row for row in actions}
        for name, spec in production_generator.CONSTRUCTOR_COPY_SPECS.items():
            with self.subTest(action_roles=name):
                self.assertEqual(
                    list(spec["roles"]),
                    production_generator.action_object_roles(
                        actions_by_name[name]
                    ),
                )

    def test_component_wrappers_use_exact_compact_locals_and_roles(self) -> None:
        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        component = production_generator.COMPONENT_RECIPES[0]
        for final_use in (False, True):
            with self.subTest(final_use=final_use):
                source = production_generator.compact_rhai_layout(
                    production_generator.fabricate_component_source(
                        component,
                        final_use=final_use,
                    )
                )
                role = "input" if final_use else "mutate"
                declarations = (
                    f'var n = action.output("{production_generator.SHIP}");',
                    f'var c = action.output("{production_generator.RESOURCE}");',
                    f'var s = action.input("{production_generator.SHIP}");',
                    f'var a = action.input("{production_generator.RESOURCE}");',
                    f'var b = action.input("{production_generator.RESOURCE}");',
                    f'var d = action.input("{production_generator.RESOURCE}");',
                    f'var k = action.{role}("{production_generator.RESOURCE}");',
                )
                cursor = 0
                for declaration in declarations:
                    position = source.find(declaration, cursor)
                    self.assertGreaterEqual(position, 0, declaration)
                    cursor = position + len(declaration)
                for legacy in (
                    "next_ship",
                    "component_work",
                    "material_1",
                    "material_2",
                    "material_3",
                    "catalyst",
                ):
                    self.assertNotRegex(source, rf"\bvar\s+{legacy}\s*=")
                helper = production_generator.phase5_helper_for(
                    component["actions"]["final" if final_use else "reusable"]
                )
                if helper is not None:
                    self.assertIn(f"{helper}(", source)
                    self.assertNotIn("fabricate_component_core(", source)
                    self.assertNotIn("intro_vdf", source)
                else:
                    self.assertIn(
                        "fabricate_component_core(\naction,\nn,\nc,\ns,\na,\nb,\nd,\nk,",
                        source,
                    )
                    catalyst_helper = (
                        "consume_component_catalyst_final_core"
                        if final_use
                        else "consume_component_catalyst_reusable_core"
                    )
                    self.assertIn(f"{catalyst_helper}(action, k);", source)
                    self.assertIn("var w = action.intro_vdf(", source)
                    self.assertIn('c.update("work", w);', source)

    def test_phase5_canary_adapters_are_fixed_and_fail_closed(self) -> None:
        actions, plugin = self.production_audit_inputs()
        audit = production_generator.phase5_adapter_canary_audit(plugin, actions)
        self.assertEqual("pass", audit["status"])
        self.assertEqual(20, len(audit["helpers"]))
        self.assertEqual(234, len(audit["route_details"]))
        self.assertEqual(
            production_generator.PHASE5_BULK_HELPER_DISTRIBUTION,
            audit["helper_distribution"],
        )
        self.assertEqual(
            production_generator.PHASE5_BULK_COST_DISTRIBUTION,
            audit["cost_distribution"],
        )
        self.assertTrue(all(audit["checks"].values()), audit["checks"])

        header_decoy = (
            '\nlet phase5_header_decoy = '
            '"fn fabricate_component_reusable_vdf_8_core(action){}";\n'
        )
        missing_with_decoy = production_generator.replace_named_function(
            plugin,
            "fabricate_component_reusable_vdf_8_core",
            lambda source: source.replace(
                "fn fabricate_component_reusable_vdf_8_core(",
                "fn removed_component_helper(",
                1,
            ),
        ) + header_decoy
        missing_audit = production_generator.phase5_adapter_canary_audit(
            missing_with_decoy,
            actions,
            include_semantic_closure=False,
            include_witness_scope=False,
        )
        self.assertEqual("fail", missing_audit["status"])
        self.assertFalse(
            missing_audit["helpers"][
                "fabricate_component_reusable_vdf_8_core"
            ]["checks"]["helper_present_once"]
        )
        real_with_decoy = production_generator.phase5_adapter_canary_audit(
            plugin + header_decoy,
            actions,
            include_semantic_closure=False,
            include_witness_scope=False,
        )
        self.assertEqual("pass", real_with_decoy["status"], real_with_decoy)
        self.assertTrue(
            real_with_decoy["helpers"][
                "fabricate_component_reusable_vdf_8_core"
            ]["checks"]["helper_present_once"]
        )

        def swap_statements(source: str, first: str, second: str) -> str:
            lines = source.splitlines()
            first_index = next(
                index for index, line in enumerate(lines) if first in line
            )
            second_index = next(
                index for index, line in enumerate(lines) if second in line
            )
            lines[first_index], lines[second_index] = (
                lines[second_index],
                lines[first_index],
            )
            return "\n".join(lines)

        def move_vdf_tail_before_core(source: str, core: str) -> str:
            lines = source.splitlines()
            tail_index = next(
                index for index, line in enumerate(lines) if "var work=" in line
            )
            tail = lines[tail_index : tail_index + 2]
            del lines[tail_index : tail_index + 2]
            core_index = next(
                index for index, line in enumerate(lines) if core in line
            )
            lines[core_index:core_index] = tail
            return "\n".join(lines)

        def move_adapter_before_last_role(source: str, helper: str) -> str:
            lines = source.splitlines()
            adapter_start = next(
                index for index, line in enumerate(lines) if helper in line
            )
            adapter = lines.pop(adapter_start)
            self.assertTrue(adapter.endswith(");}"))
            lines.append("}")
            role_index = next(
                index
                for index, line in enumerate(lines)
                if 'var k=action.mutate("MicroverseResource");' in line
            )
            lines.insert(role_index, adapter[:-1])
            return "\n".join(lines)

        mutations = {
            "role_order": production_generator.replace_action_function(
                plugin,
                "FabricateStructuralAlloyReusable",
                lambda source: source.replace(
                    'var c=action.output("MicroverseResource");\n'
                    'var s=action.input("MicroverseShip");',
                    'var s=action.input("MicroverseShip");\n'
                    'var c=action.output("MicroverseResource");',
                    1,
                ),
            ),
            "catalyst_role_mode": production_generator.replace_action_function(
                plugin,
                "FabricateStructuralAlloyReusable",
                lambda source: source.replace(
                    'k=action.mutate("MicroverseResource")',
                    'k=action.input("MicroverseResource")',
                    1,
                ),
            ),
            "missing_adapter": production_generator.replace_action_function(
                plugin,
                "FabricateStructuralAlloyReusable",
                lambda source: source.replace(
                    "fabricate_component_reusable_vdf_8_core(",
                    "forged_component_adapter(",
                    1,
                ),
            ),
            "duplicate_adapter": production_generator.replace_action_function(
                plugin,
                "FabricateStructuralAlloyReusable",
                lambda source: source.replace(
                    ");}",
                    ");\nfabricate_component_reusable_vdf_8_core(action);\n}",
                    1,
                ),
            ),
            "wrong_adapter": production_generator.replace_action_function(
                plugin,
                "FabricateStructuralAlloyReusable",
                lambda source: source.replace(
                    "fabricate_component_reusable_vdf_8_core(",
                    "fabricate_component_final_vdf_8_core(",
                    1,
                ),
            ),
            "non_recipe_hidden_caller": production_generator.replace_action_function(
                plugin,
                "BuildShipSmall",
                lambda source: source.replace(
                    "\n}",
                    "\nfabricate_component_reusable_vdf_8_core(action);\n}",
                    1,
                ),
            ),
            "commented_wrapper_adapter_line": (
                production_generator.replace_action_function(
                    plugin,
                    "FabricateStructuralAlloyReusable",
                    lambda source: source.replace(
                        "fabricate_component_reusable_vdf_8_core(",
                        "// fabricate_component_reusable_vdf_8_core(",
                        1,
                    ),
                )
            ),
            "commented_helper_core_line": (
                production_generator.replace_named_function(
                    plugin,
                    "fabricate_component_reusable_vdf_8_core",
                    lambda source: source.replace(
                        "fabricate_component_core(",
                        "// fabricate_component_core(",
                        1,
                    ),
                )
            ),
            "string_forged_helper_core_line": (
                production_generator.replace_named_function(
                    plugin,
                    "fabricate_component_reusable_vdf_8_core",
                    lambda source: self.string_forge_first_call(
                        source, "fabricate_component_core"
                    ),
                )
            ),
            "commented_helper_vdf_line": (
                production_generator.replace_named_function(
                    plugin,
                    "fabricate_component_reusable_vdf_8_core",
                    lambda source: source.replace(
                        "var work=action.intro_vdf(8,component);",
                        "// var work=action.intro_vdf(8,component);",
                        1,
                    ),
                )
            ),
            "adapter_before_last_role": production_generator.replace_action_function(
                plugin,
                "FabricateStructuralAlloyReusable",
                lambda source: move_adapter_before_last_role(
                    source, "fabricate_component_reusable_vdf_8_core("
                ),
            ),
            "extra_wrapper_proof": production_generator.replace_action_function(
                plugin,
                "FabricateStructuralAlloyReusable",
                lambda source: source.replace(
                    ");}", ");\naction.st_sum(1,0,1);\n}", 1
                ),
            ),
            "unknown_helper": (
                plugin
                + "\nfn fabricate_component_reusable_vdf_99_core(action) {\n}\n"
            ),
            "missing_helper": production_generator.replace_named_function(
                plugin,
                "fabricate_component_reusable_vdf_8_core",
                lambda source: source.replace(
                    "fn fabricate_component_reusable_vdf_8_core(",
                    "fn removed_component_helper(",
                    1,
                ),
            ),
            "component_literal_order": production_generator.replace_action_function(
                plugin,
                "FabricateStructuralAlloyReusable",
                lambda source: source.replace("211,6,196,3", "196,3,211,6", 1),
            ),
            "catalyst_before_component_core": production_generator.replace_named_function(
                plugin,
                "fabricate_component_reusable_vdf_8_core",
                lambda source: swap_statements(
                    source,
                    "fabricate_component_core(",
                    "consume_component_catalyst_reusable_core(",
                ),
            ),
            "reusable_final_swap": production_generator.replace_named_function(
                plugin,
                "fabricate_component_reusable_vdf_8_core",
                lambda source: source.replace(
                    "consume_component_catalyst_reusable_core",
                    "consume_component_catalyst_final_core",
                    1,
                ),
            ),
            "derived_core_args": production_generator.replace_named_function(
                plugin,
                "develop_derived_skill_3_evidence_vdf_8_core",
                lambda source: source.replace(
                    "ship,parent_skill_type,output_skill_type",
                    "ship,output_skill_type,parent_skill_type",
                    1,
                ),
            ),
            "derived_evidence_order": production_generator.replace_named_function(
                plugin,
                "develop_derived_skill_3_evidence_vdf_8_core",
                lambda source: swap_statements(
                    source,
                    "prove_resource_stack_core(action,evidence_1",
                    "prove_resource_stack_core(action,evidence_2",
                ),
            ),
            "artifact_evidence_type_amount": production_generator.replace_named_function(
                plugin,
                "produce_capability_artifact_3_evidence_vdf_12_core",
                lambda source: source.replace(
                    "evidence_1_type,evidence_1_amount",
                    "evidence_1_amount,evidence_1_type",
                    1,
                ),
            ),
            "parameterized_vdf": production_generator.replace_named_function(
                plugin,
                "produce_capability_artifact_3_evidence_vdf_32_core",
                lambda source: source.replace("intro_vdf(32,artifact)", "intro_vdf(output_amount,artifact)", 1),
            ),
            "wrong_vdf_target": production_generator.replace_named_function(
                plugin,
                "produce_capability_artifact_3_evidence_vdf_32_core",
                lambda source: source.replace("intro_vdf(32,artifact)", "intro_vdf(32,ship)", 1),
            ),
            "renamed_vdf_witness": production_generator.replace_named_function(
                plugin,
                "produce_capability_artifact_3_evidence_vdf_32_core",
                lambda source: source.replace("var work=", "var renamed_work=", 1),
            ),
            "reversed_vdf_tail": production_generator.replace_named_function(
                plugin,
                "produce_capability_artifact_3_evidence_vdf_32_core",
                lambda source: source.replace(
                    "var work=action.intro_vdf(32,artifact);\nartifact.update(\"work\",work);",
                    "artifact.update(\"work\",work);\nvar work=action.intro_vdf(32,artifact);",
                    1,
                ),
            ),
            "vdf_tail_before_recipe_core": production_generator.replace_named_function(
                plugin,
                "produce_capability_artifact_3_evidence_vdf_32_core",
                lambda source: move_vdf_tail_before_core(
                    source, "produce_capability_artifact_core("
                ),
            ),
            "missing_vdf_update": production_generator.replace_named_function(
                plugin,
                "produce_capability_artifact_3_evidence_vdf_32_core",
                lambda source: source.replace(
                    '\nartifact.update("work",work);',
                    "",
                    1,
                ),
            ),
            "duplicate_vdf_update": production_generator.replace_named_function(
                plugin,
                "produce_capability_artifact_3_evidence_vdf_32_core",
                lambda source: source.replace(
                    'artifact.update("work",work);',
                    'artifact.update("work",work);\nartifact.update("work",work);',
                    1,
                ),
            ),
            "logical_proof_drift": production_generator.replace_named_function(
                plugin,
                "produce_capability_artifact_3_evidence_vdf_32_core",
                lambda source: source.replace(
                    "var work=", "action.st_sum(1,0,1);\nvar work=", 1
                ),
            ),
            "output_closure_drift": production_generator.replace_named_function(
                plugin,
                "produce_capability_artifact_3_evidence_vdf_32_core",
                lambda source: source.replace(
                    'artifact.update("work",work);',
                    'artifact.update("work",work);\nartifact.update("amount",2);',
                    1,
                ),
            ),
            "witness_collision": production_generator.replace_named_function(
                plugin,
                "fabricate_component_reusable_vdf_8_core",
                lambda source: source.replace(
                    "var work=",
                    "var next_ship_key=action.random();\nvar work=",
                    1,
                ),
            ),
        }
        phase5_families = {
            "component": [
                action_name
                for component in production_generator.COMPONENT_RECIPES
                for action_name in component["actions"].values()
            ],
            "derived": [
                skill["action"] for skill in production_generator.DERIVED_SKILLS
            ],
            "artifact": [
                capability["action"]
                for capability in production_generator.SKILL_CAPABILITIES
            ],
        }

        def change_first_adapter_literal(source: str, helper: str) -> str:
            start = source.find(f"{helper}(") + len(helper) + 1
            suffix = re.sub(
                r"(?<![A-Za-z0-9_])([0-9]+)(?![A-Za-z0-9_])",
                lambda match: str(int(match.group(1)) + 1),
                source[start:],
                count=1,
            )
            return source[:start] + suffix

        for family, action_names in phase5_families.items():
            for position, action_name in (
                ("first", action_names[0]),
                ("middle", action_names[len(action_names) // 2]),
                ("last", action_names[-1]),
            ):
                helper = production_generator.phase5_helper_for(action_name)
                wrong_helper = next(
                    spec[0]
                    for spec in production_generator.PHASE5_ADAPTER_HELPERS
                    if spec[0] != helper
                )
                mutations.update({
                    f"{family}_{position}_missing": (
                        production_generator.replace_action_function(
                            plugin,
                            action_name,
                            lambda source, helper=helper: source.replace(
                                f"{helper}(", "missing_phase5_adapter(", 1
                            ),
                        )
                    ),
                    f"{family}_{position}_duplicate": (
                        production_generator.replace_action_function(
                            plugin,
                            action_name,
                            lambda source, helper=helper: source.replace(
                                ");}", f");\n{helper}(action);\n}}", 1
                            ),
                        )
                    ),
                    f"{family}_{position}_wrong_topology": (
                        production_generator.replace_action_function(
                            plugin,
                            action_name,
                            lambda source, helper=helper, wrong_helper=wrong_helper:
                            source.replace(f"{helper}(", f"{wrong_helper}(", 1),
                        )
                    ),
                    f"{family}_{position}_literal": (
                        production_generator.replace_action_function(
                            plugin,
                            action_name,
                            lambda source, helper=helper:
                            change_first_adapter_literal(source, helper),
                        )
                    ),
                })
        deep_semantic_mutations = {
            "logical_proof_drift",
            "output_closure_drift",
            "witness_collision",
            "string_forged_helper_core_line",
        }
        for name, mutated in mutations.items():
            with self.subTest(mutation=name):
                self.assertNotEqual(plugin, mutated)
                self.assertEqual(
                    "fail",
                    production_generator.phase5_adapter_canary_audit(
                        mutated,
                        actions,
                        include_semantic_closure=(
                            name in deep_semantic_mutations
                        ),
                        include_witness_scope=(name == "witness_collision"),
                    )["status"],
                )

    def test_phase6_movement_canaries_are_fixed_and_fail_closed(self) -> None:
        actions, plugin = self.production_audit_inputs()
        audit = production_generator.phase6_movement_canary_audit(
            plugin,
            actions,
            include_witness_scope=False,
            include_intro_audit=False,
        )
        self.assertEqual("pass", audit["status"], audit)
        self.assertTrue(all(audit["checks"].values()), audit["checks"])
        expected_routes = {
            name: list(route)
            for name, route
            in production_generator.PHASE6_MOVEMENT_CANARY_ROUTES.items()
        }
        self.assertEqual(
            expected_routes,
            {name: calls for name, calls in audit["routes"].items() if calls},
        )
        self.assertEqual(21, len(expected_routes))
        self.assertEqual(
            {
                "advance_ship_epoch_core": 3,
                "move_negative_core": 9,
                "move_positive_core": 9,
                "update_ship_work_vdf_12_core": 7,
                "update_ship_work_vdf_28_core": 7,
                "update_ship_work_vdf_4_core": 7,
            },
            audit["route_distribution"],
        )
        timewarp = production_generator.action_function_source(
            plugin, "TimeWarpLarge"
        )
        epoch_helper = production_generator.named_function_source(
            plugin, "advance_ship_epoch_core"
        )
        self.assertIn("st_sum(ship.epoch,100,next_epoch)", timewarp)
        self.assertNotIn("st_sum(ship.epoch", epoch_helper)
        self.assertLessEqual(
            max(
                len(line)
                for action_name in audit["route_details"]
                for line in production_generator.action_function_source(
                    plugin, action_name
                ).splitlines()
            ),
            278,
        )
        self.assertEqual(278, max(map(len, plugin.splitlines())))
        self.assertNotIn("update_ship_work_vdf_None_core", plugin)
        mutations = {
            "missing_movement_helper": production_generator.replace_action_function(
                plugin,
                "MovePositiveX",
                lambda source: source.replace(
                    "move_positive_core(", "forged_move_positive_core(", 1
                ),
            ),
            "wrong_coordinate_literal": production_generator.replace_action_function(
                plugin,
                "MovePositiveX",
                lambda source: source.replace(
                    'ship.x,"x",1,10,1', 'ship.x,"y",1,10,1', 1
                ),
            ),
            "commented_movement_helper": production_generator.replace_action_function(
                plugin,
                "MovePositiveX",
                lambda source: source.replace(
                    "move_positive_core(", "/* move_positive_core( */", 1
                ),
            ),
            "string_forged_movement_helper": production_generator.replace_action_function(
                plugin,
                "MovePositiveX",
                lambda source: self.string_forge_first_call(
                    source, "move_positive_core"
                ),
            ),
            "string_forged_movement_body": production_generator.replace_named_function(
                plugin,
                "move_positive_core",
                lambda source: self.string_forge_first_call(
                    source, "ship.update"
                ),
            ),
            "commented_vdf_tail": production_generator.replace_named_function(
                plugin,
                "update_ship_work_vdf_4_core",
                lambda source: source.replace(
                    "var work=action.intro_vdf(4,ship);",
                    "/* var work=action.intro_vdf(4,ship); */",
                    1,
                ),
            ),
            "parameterized_vdf": production_generator.replace_named_function(
                plugin,
                "update_ship_work_vdf_12_core",
                lambda source: source.replace(
                    "intro_vdf(12,ship)", "intro_vdf(step,ship)", 1
                ),
            ),
            "wrong_epoch_step": production_generator.replace_action_function(
                plugin,
                "TimeWarpLarge",
                lambda source: source.replace(
                    "st_sum(ship.epoch,100,next_epoch)",
                    "st_sum(ship.epoch,99,next_epoch)",
                    1,
                ),
            ),
            "commented_epoch_sum": production_generator.replace_action_function(
                plugin,
                "TimeWarpLarge",
                lambda source: source.replace(
                    "action.st_sum(ship.epoch,100,next_epoch);",
                    "// action.st_sum(ship.epoch,100,next_epoch);",
                    1,
                ),
            ),
            "wrong_bulk_vdf_tier": production_generator.replace_action_function(
                plugin,
                "MoveNegativeXLarge",
                lambda source: source.replace(
                    "update_ship_work_vdf_28_core(",
                    "update_ship_work_vdf_12_core(",
                    1,
                ),
            ),
            "helper_owned_role": production_generator.replace_named_function(
                plugin,
                "move_negative_core",
                lambda source: source.replace(
                    "{", '\nvar forged=action.input("MicroverseShip");\n{', 1
                ),
            ),
            "unknown_helper": plugin + "\nfn update_ship_work_vdf_99_core(action,ship){}\n",
            "logical_proof_drift": production_generator.replace_named_function(
                plugin,
                "move_positive_core",
                lambda source: source.replace(
                    "var next_coordinate=",
                    "action.st_sum(1,0,1);\nvar next_coordinate=",
                    1,
                ),
            ),
            "output_closure_drift": production_generator.replace_named_function(
                plugin,
                "update_ship_work_vdf_28_core",
                lambda source: source.replace(
                    'ship.update("work",work);',
                    'ship.update("work",work);\nship.update("amount",2);',
                    1,
                ),
            ),
            "witness_collision": production_generator.replace_named_function(
                plugin,
                "move_positive_core",
                lambda source: source.replace(
                    "var next_coordinate=",
                    "var next_ship_key=action.random();\nvar next_coordinate=",
                    1,
                ),
            ),
        }
        deep_mutations = {
            "logical_proof_drift", "output_closure_drift", "witness_collision",
            "string_forged_movement_helper",
        }
        for name, mutated in mutations.items():
            with self.subTest(mutation=name):
                self.assertNotEqual(plugin, mutated)
                self.assertEqual(
                    "fail",
                    production_generator.phase6_movement_canary_audit(
                        mutated,
                        actions,
                        include_semantic_closure=name in deep_mutations,
                        include_witness_scope=name == "witness_collision",
                        include_intro_audit=False,
                    )["status"],
                )

    def test_phase6_movement_canary_clean_gates_cover_both_profiles(self) -> None:
        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        try:
            for profile in ("economy", "current"):
                with self.subTest(profile=profile):
                    production_generator.configure_vdf_profile(profile)
                    bank = production_generator.candidate_bank(
                        len(production_generator.BODY_BANK)
                    )
                    actions = production_generator.build_actions(bank)
                    plugin = production_generator.render_plugin(
                        actions, production_generator.sources_for_bank(bank)
                    )
                    audit = production_generator.phase6_movement_canary_audit(
                        plugin,
                        actions,
                        include_witness_scope=False,
                        include_intro_audit=False,
                    )
                    self.assertEqual("pass", audit["status"], audit)
                    self.assertTrue(all(audit["checks"].values()), audit)
                    helpers = {
                        name
                        for name in production_generator.PHASE6_MOVEMENT_HELPERS
                        if f"fn {name}(" in plugin
                    }
                    self.assertEqual(
                        set(production_generator.PHASE6_MOVEMENT_HELPERS)
                        if profile == "economy"
                        else set(),
                        helpers,
                    )
                    self.assertEqual(
                        "pass",
                        production_generator.intro_audit(plugin, actions)["status"],
                    )
                    self.assertEqual(
                        "pass",
                        production_generator.flattened_witness_scope_audit(
                            plugin, actions
                        )["status"],
                    )
                    layout = production_generator.phase6_token_layout_audit(
                        plugin, actions, bank
                    )
                    self.assertEqual("pass", layout["status"], layout)
                    self.assertTrue(all(layout["checks"].values()), layout)
                    self.assertEqual(921, layout["simple_wrapper_count"])
                    self.assertEqual(
                        production_generator.REFACTOR_PHASE6_LAYOUT_TARGETS[
                            profile
                        ],
                        layout["target"],
                    )
                    self.assertNotIn("_None_core", plugin)
        finally:
            production_generator.configure_vdf_profile("economy")

    def test_phase6_layout_is_token_exact_idempotent_and_fail_closed(self) -> None:
        actions, plugin = self.production_audit_inputs()
        simple_routes = production_generator.phase6_simple_adapter_helpers()
        self.assertEqual(921, len(simple_routes))
        extract_gas = production_generator.action_function_source(
            plugin, "ExtractGas"
        )
        self.assertLessEqual(max(map(len, extract_gas.splitlines())), 144)
        self.assertTrue(extract_gas.splitlines()[-1].endswith(");}"))
        self.assertEqual(
            extract_gas,
            production_generator.compact_simple_adapter_wrapper(
                extract_gas + "\n", simple_routes["ExtractGas"]
            ).rstrip("\n"),
        )

        commented = 'var value = "// literal"; // ignored\n/* ignored */ value+=1;'
        uncommented = 'var value = "// literal";\nvalue+=1;'
        self.assertEqual(
            production_generator.rhai_lexical_tokens(commented),
            production_generator.rhai_lexical_tokens(uncommented),
        )
        self.assertNotEqual(
            production_generator.rhai_lexical_tokens("var value=1;"),
            production_generator.rhai_lexical_tokens("varvalue=1;"),
        )
        oversized = (
            'fn Adapter(action){\nvar ship=action.mutate("MicroverseShip");\n'
            f'helper(action,ship,{"x" * 300});\n}}\n'
        )
        with self.assertRaises(ValueError):
            production_generator.compact_simple_adapter_wrapper(
                oversized, "helper"
            )

        mutations = {
            "string_literal": plugin.replace(
                '"matter_remaining"', '"forged_remaining"', 1
            ),
            "identifier_merge": plugin.replace("var work=", "varwork=", 1),
            "complex_action_join": production_generator.replace_action_function(
                plugin,
                "MovePositiveX",
                lambda source: source.replace(
                    ';\nmove_positive_core(', ';move_positive_core(', 1
                ),
            ),
            "simple_adapter_split": production_generator.replace_action_function(
                plugin,
                "ExtractGas",
                lambda source: source.replace(");}", ");\n}", 1),
            ),
        }
        for name, mutated in mutations.items():
            with self.subTest(mutation=name):
                self.assertNotEqual(plugin, mutated)
                audit = production_generator.phase6_token_layout_audit(
                    mutated,
                    actions,
                    include_baseline=(name in {"string_literal", "complex_action_join"}),
                )
                self.assertEqual("fail", audit["status"], audit)

    def test_phase6_routes_survive_fresh_current_to_economy_configuration(self) -> None:
        script = """
import json
import sys
from pathlib import Path
sys.path.insert(0, "tools")
import generate_microverse as generator
generator.configure_expansion_catalogs(Path("catalog"))
generator.configure_vdf_profile("current")
generator.configure_vdf_profile("economy")
actions = generator.build_actions(generator.BODY_BANK)
plugin = generator.render_plugin(actions, generator.sources_for_bank(generator.BODY_BANK))
print(json.dumps({
    "vdf_helpers": sorted({route[-1] for route in generator.PHASE6_MOVEMENT_CANARY_ROUTES.values()}),
    "none_route": any("None" in helper for route in generator.PHASE6_MOVEMENT_CANARY_ROUTES.values() for helper in route),
    "none_source": "_None_core" in plugin,
}))
"""
        completed = subprocess.run(
            [sys.executable, "-c", script],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        result = json.loads(completed.stdout)
        self.assertEqual(
            [
                "update_ship_work_vdf_12_core",
                "update_ship_work_vdf_28_core",
                "update_ship_work_vdf_4_core",
            ],
            result["vdf_helpers"],
        )
        self.assertFalse(result["none_route"])
        self.assertFalse(result["none_source"])

    def test_compact_layout_internal_audits_are_profile_safe(self) -> None:
        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        deterministic_classes = {
            production_generator.SECTOR,
            production_generator.SIGNAL,
            production_generator.BODY,
            production_generator.SATELLITE,
            production_generator.LIFE_SIGNAL,
            production_generator.CIVILIZATION,
            production_generator.WARP_COORDINATE,
            production_generator.TIME_COORDINATE,
            production_generator.WARP_CHART,
            production_generator.EPOCH_CHART,
        }
        try:
            for profile in ("economy", "current"):
                with self.subTest(profile=profile):
                    production_generator.configure_vdf_profile(profile)
                    bank = production_generator.BODY_BANK
                    actions = production_generator.build_actions(bank)
                    plugin = production_generator.render_plugin(
                        actions, production_generator.sources_for_bank(bank)
                    )
                    audits = {
                        "zero": production_generator.deterministic_zero_key_audit(
                            plugin, actions, deterministic_classes
                        ),
                        "lifecycle": production_generator.lifecycle_refactor_audit(
                            actions, plugin, bank
                        ),
                        "civilization": production_generator.civilization_tech_audit(
                            actions, plugin, bank
                        ),
                        "warp_v1": production_generator.warp_coordinate_audit(
                            actions, plugin
                        ),
                        "warp_v2": production_generator.warp_v2_catalog_audit(
                            plugin, actions
                        ),
                        "component": production_generator.component_catalog_audit(
                            plugin, actions
                        ),
                        "skill": production_generator.skill_catalog_audit(
                            plugin, actions
                        ),
                        "refactor": production_generator.refactor_census(
                            plugin, actions
                        ),
                    }
                    self.assertEqual(
                        {name: "pass" for name in audits},
                        {name: audit["status"] for name, audit in audits.items()},
                        audits,
                    )
                    extract_gas = production_generator.raw_action_function_source(
                        plugin, "ExtractGas"
                    )
                    self.assertTrue(extract_gas.endswith(");}"))
                    self.assertNotIn("fn ExtractGasMedium", extract_gas)

            production_generator.configure_vdf_profile("economy")
            bank = production_generator.BODY_BANK
            actions = production_generator.build_actions(bank)
            plugin = production_generator.render_plugin(
                actions, production_generator.sources_for_bank(bank)
            )
            mutated = plugin
            for action_name in (
                "ExtractGas",
                "RefineFusionGasToHydrogen",
                "FabricateStructuralAlloyReusable",
                "DevelopStructuralMetallurgySkill",
            ):
                mutated = production_generator.replace_action_function(
                    mutated,
                    action_name,
                    lambda source: source.replace(");}", "); // }\n}", 1),
                )
            self.assertEqual(
                production_generator.rhai_lexical_tokens(plugin),
                production_generator.rhai_lexical_tokens(mutated),
            )
            self.assertEqual(
                "pass",
                production_generator.civilization_tech_audit(
                    actions, mutated, bank
                )["status"],
            )
            self.assertEqual(
                "pass",
                production_generator.component_catalog_audit(
                    mutated, actions
                )["status"],
            )
            self.assertEqual(
                "pass",
                production_generator.skill_catalog_audit(
                    mutated, actions
                )["status"],
            )
            self.assertEqual(
                "fail",
                production_generator.phase6_token_layout_audit(
                    mutated, actions, include_baseline=False
                )["status"],
            )
            synthetic = (
                'fn First(action){\nlet marker="}";/* } */\n// }\n}\n'
                "fn Second(action){\n}\n"
            )
            parsed = production_generator.rhai_function_sources(synthetic)
            self.assertEqual(["First", "Second"], list(parsed))
            self.assertNotIn("fn Second", parsed["First"])
            semantic_source = production_generator.RhaiAuditSource(
                '// forged_core(action);\n'
                'let marker="forged_core(action);";\n'
                "real_core(action);\n"
                "real_core ( action ) ;\n"
            )
            self.assertNotIn("forged_core(action);", semantic_source)
            self.assertEqual(0, semantic_source.count("forged_core(action);"))
            self.assertIn("real_core(action);", semantic_source)
            self.assertEqual(2, semantic_source.count("real_core(action);"))
        finally:
            production_generator.configure_vdf_profile("economy")

    def test_warp_v2_update_axes_and_definition_inventory_fail_closed(self) -> None:
        actions, plugin = self.production_audit_inputs()
        clean = production_generator.warp_v2_catalog_audit(plugin, actions)
        self.assertEqual("pass", clean["status"], clean)

        v1_pool_proof = production_generator.replace_named_function(
            plugin,
            "reveal_p",
            lambda source: source.replace(
                "\n}",
                '\naction.st_sum(coordinate["source_pool_maximum"],0,0);\n}',
                1,
            ),
        )
        v1_pool_audit = production_generator.warp_coordinate_audit(
            actions, v1_pool_proof
        )
        self.assertEqual("fail", v1_pool_audit["status"])
        self.assertFalse(
            v1_pool_audit["checks"][
                "reveal_helpers_use_explicit_action_identity_only"
            ]
        )

        v2_pool_proof = production_generator.replace_named_function(
            plugin,
            "reveal_chart_p",
            lambda source: source.replace(
                "\n}",
                '\naction.st_sum(chart["source_pool_maximum"],0,0);\n}',
                1,
            ),
        )
        v2_pool_audit = production_generator.warp_v2_catalog_audit(
            v2_pool_proof, actions
        )
        self.assertEqual("fail", v2_pool_audit["status"])
        self.assertFalse(
            v2_pool_audit["checks"][
                "reveal_explicit_action_identity_constraints_exact"
            ]
        )

        for helper, handle, audit_function in (
            ("reveal_p", "coordinate", lambda source: (
                production_generator.warp_coordinate_audit(actions, source)
            )),
            ("reveal_chart_p", "chart", lambda source: (
                production_generator.warp_v2_catalog_audit(source, actions)
            )),
        ):
            harmless = production_generator.replace_named_function(
                plugin,
                helper,
                lambda source, handle=handle: source.replace(
                    "\n}",
                    (
                        f'\n// action.st_sum({handle}["source_pool_maximum"],0,0);'
                        f'\nlet marker="action.st_sum({handle}['
                        '\\"source_pool_maximum\\"],0,0);";\n}'
                    ),
                    1,
                ),
            )
            harmless_core = production_generator.named_function_source(
                harmless, helper
            )
            self.assertFalse(
                production_generator.rhai_call_uses_indexed_field(
                    harmless_core, "action.st_sum", "source_pool_maximum"
                )
            )
            self.assertEqual("pass", audit_function(harmless)["status"])

        wrong_position = production_generator.replace_named_function(
            plugin,
            "reveal_chart_p",
            lambda source: source.replace(
                'chart.update("destination_x",x);',
                'chart.update("destination_epoch",x);',
                1,
            ),
        )
        wrong_epoch = production_generator.replace_named_function(
            plugin,
            "reveal_chart_t",
            lambda source: source.replace(
                'chart.update("destination_epoch",epoch);',
                'chart.update("destination_x",epoch);',
                1,
            ),
        )
        self.assertFalse(
            production_generator.warp_v2_catalog_audit(
                wrong_position, actions
            )["checks"]["position_reveal_updates_xyz_only"]
        )
        self.assertFalse(
            production_generator.warp_v2_catalog_audit(
                wrong_epoch, actions
            )["checks"]["epoch_reveal_updates_epoch_only"]
        )

        harmless_comment = production_generator.replace_named_function(
            plugin,
            "reveal_chart_p",
            lambda source: source.replace(
                "\n}",
                '\n// chart.update("destination_epoch",epoch);\n}',
                1,
            ),
        )
        self.assertEqual(
            "pass",
            production_generator.warp_v2_catalog_audit(
                harmless_comment, actions
            )["status"],
        )
        string_only = production_generator.RhaiAuditSource(
            'let note="chart.update(\\"destination_epoch\\",epoch);";\n'
            'chart.update("destination_x",x);'
        )
        self.assertEqual(
            [("destination_x", "x")],
            production_generator.object_update_pairs(string_only, "chart"),
        )

        helper_name = "prove_object_version_core"
        helper_source = production_generator.raw_named_function_source(
            plugin, helper_name
        )
        missing = plugin.replace(
            helper_source,
            helper_source.replace(
                f"fn {helper_name}(", "fn removed_object_version_core(", 1
            ),
            1,
        )
        duplicate = plugin + "\n" + helper_source + "\n"
        comment_forged = missing + f"\n// fn {helper_name}(action){{}}\n"
        for name, mutant in (
            ("missing", missing),
            ("duplicate", duplicate),
            ("comment_forged", comment_forged),
        ):
            with self.subTest(definition=name):
                audit = production_generator.warp_v2_catalog_audit(
                    mutant, actions
                )
                self.assertFalse(
                    audit["checks"]["shared_helpers_present_once"], audit
                )
        self.assertEqual(
            0,
            production_generator.rhai_function_definition_count(
                comment_forged, helper_name
            ),
        )
        self.assertEqual(
            2,
            production_generator.rhai_function_definition_count(
                duplicate, helper_name
            ),
        )
        malformed = (
            "fn unbalanced_core(action){\n"
            "fn following_core(action){\n}\n"
        )
        self.assertEqual(
            -1,
            production_generator.rhai_function_definition_count(
                malformed, "unbalanced_core"
            ),
        )

    def test_executable_call_and_closure_parsers_ignore_noncode_decoys(self) -> None:
        synthetic = (
            'let header="fn Core(forged){";\n'
            "fn Core(action,artifact){\n"
            'let proof_marker="action.st_sum(9,9,9);";\n'
            'let update_marker="artifact.update(\\\"amount\\\",9);";\n'
            "action.st_sum(1,0,1);\n"
            'artifact.update("amount",1);\n'
            "}\n"
            "fn Wrapper(action){\n"
            '// var forged=action.input("Forged");\n'
            'let role_marker="action.mutate(\\\"Forged\\\")";\n'
            'var artifact=action.output("MicroverseResource");\n'
            'let call_marker="Core(action,artifact);";\n'
            "Core(action,artifact);\n"
            "}\n"
        )
        self.assertEqual(
            ["action", "artifact"],
            production_generator.rhai_function_parameters(synthetic, "Core"),
        )
        wrapper = production_generator.named_function_source(
            synthetic, "Wrapper"
        )
        self.assertEqual(
            [("output", "MicroverseResource")],
            production_generator.source_action_object_roles(wrapper),
        )
        self.assertEqual(
            [["action", "artifact"]],
            production_generator.rhai_call_arguments(wrapper, "Core"),
        )
        census = production_generator.transitive_action_census(
            "Wrapper", production_generator.rhai_function_sources(synthetic)
        )
        self.assertEqual(1, census["counts"]["st_sum"])
        self.assertEqual(1, sum(census["counts"].values()))
        self.assertEqual(1, len(census["output_transforms"]))
        self.assertEqual(
            '"amount",1', census["output_transforms"][0]["expression"]
        )
        self.assertEqual([["Wrapper"], ["Wrapper", "Core"]], census["call_paths"])

        string_only = production_generator.replace_named_function(
            synthetic,
            "Wrapper",
            lambda source: self.string_forge_first_call(source, "Core"),
        )
        string_census = production_generator.transitive_action_census(
            "Wrapper", production_generator.rhai_function_sources(string_only)
        )
        self.assertEqual(0, sum(string_census["counts"].values()))
        self.assertEqual([["Wrapper"]], string_census["call_paths"])

        nested = (
            "fn NestedWrapper(action){\n"
            '/* ignored_helper(action,999); */\n'
            'let marker="string_helper(action,888);";\n'
            'helper(action,nested(a,b),[1,2],"comma,value");\n'
            "}\n"
        )
        self.assertEqual(
            [["action", "nested(a,b)", "[1,2]", '"comma,value"']],
            production_generator.rhai_call_arguments(nested, "helper"),
        )
        self.assertEqual(
            ["helper"], production_generator.rhai_wrapper_helpers(nested)
        )
        literals = production_generator.rhai_wrapper_literals(nested)
        self.assertNotIn(999, literals)
        self.assertIn('comma,value', literals)

        headers = (
            'let marker="line one\nfn StringForged(action){}";\n'
            "// fn CommentForged(action){}\n"
            "fn LiveAction(action){}\n"
            "fn Helper(action,value){}\n"
            "fn Unbalanced(action){\n"
        )
        self.assertEqual(
            ["LiveAction"],
            production_generator.rhai_action_function_names(headers),
        )

        live_zero = (
            "let zero=action.top_limb_u256(0);\n"
            'body.update("key",zero);\n'
        )
        self.assertEqual(
            [("body", "zero")],
            production_generator.semantic_zero_key_updates(live_zero),
        )
        for noncode_zero in (
            '// let zero=action.top_limb_u256(0);\nbody.update("key",zero);',
            'let zero=action.top_limb_u256(0);\n// body.update("key",zero);',
            'let marker="let zero=action.top_limb_u256(0); '
            'body.update(\\\"key\\\",zero);";',
        ):
            self.assertEqual(
                [], production_generator.semantic_zero_key_updates(noncode_zero)
            )
        self.assertEqual(
            [],
            production_generator.object_set_fields(
                '/* component.set([["schema_version",1]]); */', "component"
            ),
        )

    def test_phase3_to_phase6_string_forged_calls_fail_closed(self) -> None:
        actions, plugin = self.production_audit_inputs()

        phase3 = production_generator.phase3_helper_canary_audit(
            plugin, production_generator.BODY_BANK
        )
        phase3_route = production_generator.replace_action_function(
            plugin,
            phase3["survey_action"],
            lambda source: self.string_forge_first_call(
                source, "prove_empty_survey_sector_core"
            ),
        )
        phase3_body = production_generator.replace_named_function(
            plugin,
            "prove_empty_survey_sector_core",
            lambda source: self.string_forge_first_call(
                source, "action.st_sum"
            ),
        )
        for mutant in (phase3_route, phase3_body):
            self.assertEqual(
                "fail",
                production_generator.phase3_helper_canary_audit(
                    mutant, production_generator.BODY_BANK
                )["status"],
            )

        phase4_route = production_generator.replace_action_function(
            plugin,
            "ExtractGas",
            lambda source: self.string_forge_first_call(
                source, "extract_base_vdf_2_core"
            ),
        )
        phase4_tail = production_generator.replace_named_function(
            plugin,
            "extract_base_vdf_2_core",
            lambda source: source.replace(
                "var work=action.intro_vdf(2,body);",
                'let marker="action.intro_vdf(2,body);";',
                1,
            ),
        )
        for mutant in (phase4_route, phase4_tail):
            self.assertEqual(
                "fail",
                production_generator.phase4_adapter_canary_audit(
                    mutant, actions, production_generator.BODY_BANK
                )["status"],
            )

        phase5_core = production_generator.replace_named_function(
            plugin,
            "fabricate_component_reusable_vdf_8_core",
            lambda source: self.string_forge_first_call(
                source, "fabricate_component_core"
            ),
        )
        phase5_audit = production_generator.phase5_adapter_canary_audit(
            phase5_core,
            actions,
            include_semantic_closure=True,
            include_witness_scope=False,
        )
        self.assertEqual("fail", phase5_audit["status"])
        self.assertFalse(phase5_audit["checks"]["semantic_closure_exact"])
        phase5_terminal_drift = production_generator.replace_action_function(
            plugin,
            "FabricateStructuralAlloyReusable",
            lambda source: source.replace(
                ");}", ");\naction.st_sum(1,0,1);\n}", 1
            ),
        )
        terminal_audit = production_generator.phase5_adapter_canary_audit(
            phase5_terminal_drift,
            actions,
            include_semantic_closure=False,
            include_witness_scope=False,
        )
        self.assertEqual("fail", terminal_audit["status"])
        self.assertFalse(
            terminal_audit["helpers"][
                "fabricate_component_reusable_vdf_8_core"
            ]["checks"]["wrapper_roles_precede_final_adapter"]
        )
        phase5_terminal_comment = production_generator.replace_action_function(
            plugin,
            "FabricateStructuralAlloyReusable",
            lambda source: source.replace(");}", "); // harmless helper();\n}", 1),
        )
        self.assertEqual(
            "pass",
            production_generator.phase5_adapter_canary_audit(
                phase5_terminal_comment,
                actions,
                include_semantic_closure=False,
                include_witness_scope=False,
            )["status"],
        )

        phase6_route = production_generator.replace_action_function(
            plugin,
            "MovePositiveX",
            lambda source: self.string_forge_first_call(
                source, "move_positive_core"
            ),
        )
        phase6_route_audit = production_generator.phase6_movement_canary_audit(
            phase6_route,
            actions,
            include_semantic_closure=True,
            include_witness_scope=False,
            include_intro_audit=False,
        )
        self.assertEqual("fail", phase6_route_audit["status"])
        self.assertFalse(
            phase6_route_audit["checks"]["logical_and_output_closure_exact"]
        )
        phase6_body = production_generator.replace_named_function(
            plugin,
            "move_positive_core",
            lambda source: self.string_forge_first_call(
                source, "ship.update"
            ),
        )
        self.assertEqual(
            "fail",
            production_generator.phase6_movement_canary_audit(
                phase6_body,
                actions,
                include_semantic_closure=False,
                include_witness_scope=False,
                include_intro_audit=False,
            )["status"],
        )

        def comment_component_set(source: str) -> str:
            start = source.index("component.set([")
            end = source.index("]);", start) + 3
            return source[:start] + "/*" + source[start:end] + "*/" + source[end:]

        commented_component_set = production_generator.replace_named_function(
            plugin, "fabricate_component_core", comment_component_set
        )
        component_audit = production_generator.component_catalog_audit(
            commented_component_set, actions
        )
        self.assertEqual("fail", component_audit["status"])
        self.assertFalse(
            component_audit["checks"]["component_output_fields_exact"]
        )

    def test_phase5_canary_clean_gates_cover_both_profiles(self) -> None:
        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        try:
            for profile in ("economy", "current"):
                with self.subTest(profile=profile):
                    production_generator.configure_vdf_profile(profile)
                    bank = production_generator.candidate_bank(
                        len(production_generator.BODY_BANK)
                    )
                    actions = production_generator.build_actions(bank)
                    plugin = production_generator.render_plugin(
                        actions, production_generator.sources_for_bank(bank)
                    )
                    audit = production_generator.phase5_adapter_canary_audit(
                        plugin, actions
                    )
                    self.assertEqual("pass", audit["status"], audit)
                    self.assertEqual(
                        sorted(
                            helper[0]
                            for helper in production_generator.PHASE5_ADAPTER_HELPERS
                        ),
                        audit["phase5_like_helpers"],
                    )
                    self.assertEqual(234, len(audit["route_details"]))
                    self.assertEqual(
                        production_generator.PHASE5_BULK_HELPER_DISTRIBUTION,
                        audit["helper_distribution"],
                    )
                    self.assertEqual(
                        production_generator.PHASE5_BULK_COST_DISTRIBUTION,
                        audit["cost_distribution"],
                    )
                    self.assertTrue(all(audit["checks"].values()), audit)
                    self.assertEqual(
                        "pass",
                        production_generator.intro_audit(plugin, actions)["status"],
                    )
                    self.assertEqual(
                        "pass",
                        production_generator.flattened_witness_scope_audit(
                            plugin, actions
                        )["status"],
                    )
                    self.assertEqual(
                        "pass",
                        production_generator.refactor_census(plugin, actions)[
                            "status"
                        ],
                    )
        finally:
            production_generator.configure_vdf_profile("economy")

    def test_intro_audit_expands_every_action_and_helper_call(self) -> None:
        actions, plugin = self.production_audit_inputs()
        audit = production_generator.intro_audit(plugin, actions)
        self.assertEqual("pass", audit["status"])
        self.assertEqual(
            {
                "expected_vdf_calls": 1352,
                "expected_threshold_u256_calls": 23,
                "explicit_action_identity_actions": 603,
                "expected_stable_identifier_selection_calls": 0,
                "expected_total_calls": 1375,
                "observed_vdf_calls": 1352,
                "observed_threshold_u256_calls": 23,
                "observed_stable_identifier_selection_calls": 0,
                "observed_total_calls": 1375,
                "physical_vdf_calls": 71,
                "physical_u256_calls": 1,
                "passed": True,
            },
            audit["configured_catalog_coverage"],
        )
        self.assertTrue(
            all("intro_contract" in action for action in actions)
        )

        mutant = production_generator.replace_named_function(
            plugin,
            "reveal_chart_p",
            lambda source: source.replace(
                "action.intro_vdf(20,chart)",
                "action.intro_vdf(19,chart)",
                1,
            ),
        )
        mutant_audit = production_generator.intro_audit(mutant, actions)
        self.assertEqual("fail", mutant_audit["status"])
        self.assertEqual("fail", mutant_audit["helpers"]["reveal_chart_p"]["status"])

    def test_phase3_helper_canaries_are_exact_and_fail_closed(self) -> None:
        actions, plugin = self.production_audit_inputs()
        audit = production_generator.phase3_helper_canary_audit(
            plugin,
            production_generator.BODY_BANK,
        )
        self.assertEqual("pass", audit["status"], audit)
        survey_core = production_generator.named_function_source(
            plugin, "prove_empty_survey_sector_core"
        )
        zero_fields = re.findall(
            r"action\.st_sum\(sector\.([A-Za-z0-9_]+),\s*0,\s*0\);",
            survey_core,
        )
        self.assertEqual(24, len(zero_fields))
        self.assertEqual("minor_body_field_remaining", zero_fields[12])
        self.assertEqual("next_minor_body_field_serial", zero_fields[-1])

        census = production_generator.refactor_census(plugin, actions)
        self.assertEqual("pass", census["status"], census)
        detect_transforms = census["normalized_output_transforms"][
            audit["detect_action"]
        ]
        signal_set = next(
            expression
            for target, method, expression in detect_transforms
            if (target, method) == ("signal", "set")
        )
        self.assertIn('["category_code",2]', signal_set)
        self.assertIn('["candidate_code",0]', signal_set)
        self.assertNotIn('["2",2]', signal_set)
        self.assertNotIn('["0",0]', signal_set)

        self.assertEqual(23, sum(
            source.count("detect_signal_core(") == 1
            for name, source in (
                (action["name"], production_generator.action_function_source(plugin, action["name"]))
                for action in actions
                if action["name"].startswith("DetectCelestialSignal_")
            )
        ))
        self.assertEqual(5, sum(
            production_generator.action_function_source(plugin, action["name"])
            .count("prove_empty_survey_sector_core(") == 1
            for action in actions
            if action["name"].startswith("SurveySector_")
        ))

        manifest = "[plugin]\nname = \"phase3-validator-test\"\nversion = \"0\"\nmodule_hash = \"0\"\n" + "".join(
            f'\n[[actions]]\nname = "{action["name"]}"\n' for action in actions
        )

        def validator_codes(mutant: str) -> set[str]:
            with tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                rhai = root / "plugin.rhai"
                manifest_path = root / "manifest.toml"
                rhai.write_text(mutant, encoding="utf-8")
                manifest_path.write_text(manifest, encoding="utf-8")
                validation = validator.Validation()
                validator.validate_rhai(
                    rhai,
                    manifest_path,
                    {},
                    validation,
                    self.load("microverse-resource-tree-v2.json"),
                )
            return {finding.code for finding in validation.findings}

        mutations = {
            "arity": production_generator.replace_named_function(
                plugin,
                "detect_signal_core",
                lambda source: source.replace("serial_field){", "){", 1),
            ),
            "order": production_generator.replace_named_function(
                plugin,
                "prove_empty_survey_sector_core",
                lambda source: source.replace(
                    "action.st_sum(sector.survey_profile,0,0);",
                    "action.st_sum(sector.sector_type,0,0);",
                    1,
                ),
            ),
            "category_literal": production_generator.replace_action_function(
                plugin,
                audit["detect_action"],
                lambda source: source.replace(
                    "sector,2,0,", "sector,0,0,", 1
                ),
            ),
            "helper_call": production_generator.replace_action_function(
                plugin,
                audit["detect_action"],
                lambda source: source.replace(
                    "detect_signal_core(", "forged_detect_signal_core(", 1
                ),
            ),
            "survey_remaining_field": production_generator.replace_named_function(
                plugin,
                "prove_empty_survey_sector_core",
                lambda source: source.replace(
                    "sector.minor_body_field_remaining",
                    "sector.planet_remaining",
                    1,
                ),
            ),
            "survey_serial_field": production_generator.replace_named_function(
                plugin,
                "prove_empty_survey_sector_core",
                lambda source: source.replace(
                    "sector.next_minor_body_field_serial",
                    "sector.next_planet_serial",
                    1,
                ),
            ),
            "revision_in_helper": production_generator.replace_named_function(
                plugin,
                "prove_empty_survey_sector_core",
                lambda source: source.replace(
                    "\n}",
                    "\n    action.st_sum(sector.revision, 0, 0);\n}",
                    1,
                ),
            ),
            "serial_literal": production_generator.replace_action_function(
                plugin,
                audit["detect_action"],
                lambda source: source.replace(
                    '"next_star_serial"', '"next_planet_serial"', 1
                ),
            ),
            "helper_owned_role": production_generator.replace_named_function(
                plugin,
                "detect_signal_core",
                lambda source: source.replace(
                    "\n}",
                    '\n    var illicit_ship = action.input("MicroverseShip");\n}',
                    1,
                ),
            ),
        }
        for candidate in (
            production_generator.BODY_BANK[0],
            production_generator.BODY_BANK[len(production_generator.BODY_BANK) // 2],
            production_generator.BODY_BANK[-1],
        ):
            category = production_generator.celestial_category(candidate)
            remaining_field = category["remaining_field"]
            serial_field = category["serial_field"]
            action_name = (
                f"DetectCelestialSignal_{candidate['code']:02d}_{candidate['slug']}"
            )
            mutations.update({
                f"category_{candidate['code']}": production_generator.replace_action_function(
                    plugin, action_name, lambda source, category=category, candidate=candidate:
                    source.replace(
                        f"sector,{category['code']},{candidate['code']},",
                        f"sector,0,{candidate['code']},", 1),
                ),
                f"candidate_{candidate['code']}": production_generator.replace_action_function(
                    plugin, action_name, lambda source, category=category, candidate=candidate:
                    source.replace(
                        f"sector,{category['code']},{candidate['code']},",
                        f"sector,{category['code']},99,", 1),
                ),
                f"remaining_{candidate['code']}": production_generator.replace_action_function(
                    plugin, action_name, lambda source, remaining_field=remaining_field:
                    source.replace(f'"{remaining_field}"', '"forged_remaining"', 1),
                ),
                f"serial_{candidate['code']}": production_generator.replace_action_function(
                    plugin, action_name, lambda source, serial_field=serial_field:
                    source.replace(f'"{serial_field}"', '"forged_serial"', 1),
                ),
            })
        revision_update_mutant = production_generator.replace_named_function(
            plugin,
            "prove_empty_survey_sector_core",
            lambda source: source.replace(
                "\n}",
                '\n    sector.update("revision", 0);\n}',
                1,
            ),
        )
        revision_update_audit = production_generator.phase3_helper_canary_audit(
            revision_update_mutant,
            production_generator.BODY_BANK,
        )
        self.assertEqual("fail", revision_update_audit["status"])
        self.assertFalse(
            revision_update_audit["checks"][
                "survey_core_ordered_configured_zeros_exact"
            ]
        )
        survey_string_route = production_generator.replace_action_function(
            plugin,
            audit["survey_action"],
            lambda source: self.string_forge_first_call(
                source, "prove_empty_survey_sector_core"
            ),
        )
        self.assertEqual(
            "fail",
            production_generator.phase3_helper_canary_audit(
                survey_string_route, production_generator.BODY_BANK
            )["status"],
        )
        survey_route_census = production_generator.transitive_action_census(
            audit["survey_action"],
            production_generator.rhai_function_sources(survey_string_route),
        )
        self.assertFalse(any(
            path[-1] == "prove_empty_survey_sector_core"
            for path in survey_route_census["call_paths"]
        ))
        survey_string_body = production_generator.replace_named_function(
            plugin,
            "prove_empty_survey_sector_core",
            lambda source: self.string_forge_first_call(
                source, "action.st_sum"
            ),
        )
        self.assertEqual(
            "fail",
            production_generator.phase3_helper_canary_audit(
                survey_string_body, production_generator.BODY_BANK
            )["status"],
        )
        for name, mutant in mutations.items():
            with self.subTest(mutation=name):
                mutant_audit = production_generator.phase3_helper_canary_audit(
                    mutant,
                    production_generator.BODY_BANK,
                )
                self.assertEqual("fail", mutant_audit["status"], mutant_audit)
                self.assertEqual(
                    "fail",
                    production_generator.lifecycle_refactor_audit(
                        actions, mutant
                    )["status"],
                )
                codes = validator_codes(mutant)
                self.assertTrue(
                    any(code.startswith("rhai.phase3_") for code in codes),
                    codes,
                )
        for harmless in (
            production_generator.replace_named_function(
                plugin,
                "prove_empty_survey_sector_core",
                lambda source: source.replace(
                    "\n}",
                    '\n    // sector.update("revision", 0);\n}',
                    1,
                ),
            ),
            production_generator.replace_named_function(
                plugin,
                "prove_empty_survey_sector_core",
                lambda source: source.replace(
                    "\n}",
                    '\n    let marker = "sector.update(\\\"revision\\\", 0);";\n}',
                    1,
                ),
            ),
        ):
            harmless_core = production_generator.named_function_source(
                harmless, "prove_empty_survey_sector_core"
            )
            self.assertNotIn(
                ("revision", "0"),
                production_generator.object_update_pairs(
                    harmless_core, "sector"
                ),
            )
            self.assertEqual(
                "pass",
                production_generator.phase3_helper_canary_audit(
                    harmless, production_generator.BODY_BANK
                )["status"],
            )
        for action_name, helper in (
            (audit["detect_action"], "detect_signal_core"),
            (audit["survey_action"], "prove_empty_survey_sector_core"),
        ):
            self.assertTrue(
                any(
                    path[-1] == helper
                    for path in census["transitive_actions"][action_name]["call_paths"]
                )
            )

    def test_phase4_adapters_are_profile_isolated_and_fail_closed(self) -> None:
        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        try:
            rendered: dict[str, tuple[list[dict], str]] = {}
            for profile, expected_count in (("current", 6), ("economy", 20)):
                production_generator.configure_vdf_profile(profile)
                bank = production_generator.candidate_bank(
                    len(production_generator.BODY_BANK)
                )
                actions = production_generator.build_actions(bank)
                plugin = production_generator.render_plugin(
                    actions, production_generator.sources_for_bank(bank)
                )
                audit = production_generator.phase4_adapter_canary_audit(
                    plugin, actions, bank
                )
                profile_census = production_generator.phase4_profile_census(
                    plugin, actions, bank
                )
                self.assertEqual("pass", audit["status"], audit)
                self.assertEqual("pass", profile_census["status"], profile_census)
                self.assertEqual(expected_count, len(audit["helpers"]))
                self.assertEqual(687, len(audit["route_details"]))
                self.assertTrue(
                    all(
                        detail["calls_exact"] and detail["sole_adapter"]
                        for detail in audit["route_details"].values()
                    ),
                    audit,
                )
                intro = production_generator.intro_audit(plugin, actions)
                self.assertEqual("pass", intro["status"], intro)
                self.assertEqual(
                    659 if profile == "current" else 1352,
                    intro["configured_catalog_coverage"]["observed_vdf_calls"],
                )
                self.assertEqual(
                    54 if profile == "current" else 71,
                    intro["configured_catalog_coverage"]["physical_vdf_calls"],
                )
                self.assertEqual(
                    (
                        {
                            "st_sum": 574, "st_gt": 74, "unsafe": 288,
                            "random": 66, "var_assign": 17,
                            "rotate_key": 44, "intro_vdf": 54,
                            "intro_lt_eq_u256": 1,
                        }
                        if profile == "current"
                        else {
                            "st_sum": 586, "st_gt": 64, "unsafe": 278,
                            "random": 60, "var_assign": 17,
                            "rotate_key": 38, "intro_vdf": 71,
                            "intro_lt_eq_u256": 1,
                        }
                    ),
                    profile_census["physical"],
                )
                routed_counts: dict[str, int] = {}
                for adapters in audit["routes"].values():
                    if adapters:
                        self.assertEqual(1, len(adapters), audit)
                        routed_counts[adapters[0]] = (
                            routed_counts.get(adapters[0], 0) + 1
                        )
                self.assertEqual(
                    (
                        {
                            "extract_base_vdf_4_core": 3,
                            "extract_base_vdf_8_core": 6,
                            "extract_base_vdf_12_core": 3,
                            "extract_direct_body_no_vdf_core": 77,
                            "extract_composite_no_vdf_core": 274,
                            "refine_resource_no_vdf_core": 324,
                        }
                        if profile == "current"
                        else {
                            "extract_base_vdf_2_core": 3,
                            "extract_base_vdf_4_core": 3,
                            "extract_base_vdf_8_core": 6,
                            "extract_direct_body_vdf_2_core": 3,
                            "extract_direct_body_vdf_4_core": 12,
                            "extract_direct_body_vdf_12_core": 44,
                            "extract_direct_body_vdf_20_core": 17,
                            "extract_direct_body_vdf_32_core": 1,
                            "extract_composite_vdf_2_core": 17,
                            "extract_composite_vdf_4_core": 55,
                            "extract_composite_vdf_8_core": 98,
                            "extract_composite_vdf_12_core": 64,
                            "extract_composite_vdf_20_core": 24,
                            "extract_composite_vdf_32_core": 16,
                            "refine_resource_vdf_2_core": 12,
                            "refine_resource_vdf_4_core": 63,
                            "refine_resource_vdf_8_core": 102,
                            "refine_resource_vdf_12_core": 66,
                            "refine_resource_vdf_20_core": 63,
                            "refine_resource_vdf_32_core": 18,
                        }
                    ),
                    routed_counts,
                )
                rendered[profile] = (actions, plugin)

            for order in (("economy", "current"), ("current", "economy")):
                for profile in order:
                    production_generator.configure_vdf_profile(profile)
                    bank = production_generator.candidate_bank(len(production_generator.BODY_BANK))
                    actions = production_generator.build_actions(bank)
                    plugin = production_generator.render_plugin(actions, production_generator.sources_for_bank(bank))
                    self.assertEqual("pass", production_generator.intro_audit(plugin, actions)["status"])

            current_plugin = rendered["current"][1]
            economy_plugin = rendered["economy"][1]
            self.assertNotIn("extract_direct_body_no_vdf_core", economy_plugin)
            self.assertNotIn("extract_direct_body_vdf_2_core", current_plugin)

            actions, plugin = rendered["economy"]
            mutations = {
                "suffix": production_generator.replace_named_function(
                    plugin, "extract_base_vdf_2_core",
                    lambda source: source.replace("intro_vdf(2,body)", "intro_vdf(3,body)", 1),
                ),
                "renamed_witness": production_generator.replace_named_function(
                    plugin, "extract_base_vdf_2_core",
                    lambda source: source.replace("var work=", "var renamed_work=", 1),
                ),
                "reversed_tail": production_generator.replace_named_function(
                    plugin, "extract_base_vdf_2_core",
                    lambda source: source.replace(
                        'var work=action.intro_vdf(2,body);\nbody.update("work",work);',
                        'body.update("work",work);\nvar work=action.intro_vdf(2,body);',
                        1,
                    ),
                ),
                "missing_adapter": production_generator.replace_action_function(
                    plugin, "ExtractGas",
                    lambda source: source.replace("extract_base_vdf_2_core(", "forged_extract_base_vdf_2_core(", 1),
                ),
                "string_forged_adapter": production_generator.replace_action_function(
                    plugin,
                    "ExtractGas",
                    lambda source: self.string_forge_first_call(
                        source, "extract_base_vdf_2_core"
                    ),
                ),
                "string_forged_vdf_tail": production_generator.replace_named_function(
                    plugin,
                    "extract_base_vdf_2_core",
                    lambda source: source.replace(
                        "var work=action.intro_vdf(2,body);",
                        'let marker="action.intro_vdf(2,body);";',
                        1,
                    ),
                ),
                "extra_adapter": production_generator.replace_action_function(
                    plugin, "ExtractGas",
                    lambda source: source.replace(
                        ");}",
                        ");\nextract_base_vdf_2_core(action, next_ship, resource, ship, body, 0, \"gas_remaining\", 3, 10, 1);\n}",
                        1,
                    ),
                ),
                "role_order": production_generator.replace_action_function(
                    plugin, "ExtractGas",
                    lambda source: source.replace(
                        'var resource=action.output("MicroverseResource");\nvar ship=action.input("MicroverseShip");',
                        'var ship=action.input("MicroverseShip");\nvar resource=action.output("MicroverseResource");',
                        1,
                    ),
                ),
                "wrong_bulk_helper": production_generator.replace_action_function(
                    plugin,
                    "ExtractMatterMedium",
                    lambda source: source.replace(
                        "extract_base_vdf_8_core(",
                        "extract_base_vdf_4_core(",
                        1,
                    ),
                ),
                "wrong_bulk_literal": production_generator.replace_action_function(
                    plugin,
                    "ExtractMatterMedium",
                    lambda source: source.replace(
                        '"matter_remaining"',
                        '"forged_remaining"',
                        1,
                    ),
                ),
            }
            forged_phase4_census = production_generator.transitive_action_census(
                "ExtractGas",
                production_generator.rhai_function_sources(
                    mutations["string_forged_adapter"]
                ),
            )
            self.assertFalse(any(
                path[-1] == "extract_base_vdf_2_core"
                for path in forged_phase4_census["call_paths"]
            ))
            for name, mutant in mutations.items():
                with self.subTest(mutation=name):
                    self.assertNotEqual(plugin, mutant)
                    self.assertEqual(
                        "fail",
                        production_generator.phase4_adapter_canary_audit(
                            mutant,
                            actions,
                            production_generator.BODY_BANK,
                        )["status"],
                    )
                    if name != "wrong_bulk_literal":
                        self.assertEqual(
                            "fail",
                            production_generator.intro_audit(mutant, actions)[
                                "status"
                            ],
                        )

            production_generator.configure_vdf_profile("current")
            bank = production_generator.candidate_bank(
                len(production_generator.BODY_BANK)
            )
            current_actions = production_generator.build_actions(bank)
            current_plugin = production_generator.render_plugin(
                current_actions, production_generator.sources_for_bank(bank)
            )
            no_vdf_mutant = production_generator.replace_named_function(
                current_plugin,
                "extract_direct_body_no_vdf_core",
                lambda source: source.replace(
                    "\n}",
                    '\n    var work = action.intro_vdf(2, body);\n    body.update("work", work);\n}',
                    1,
                ),
            )
            self.assertEqual(
                "fail",
                production_generator.phase4_adapter_canary_audit(
                    no_vdf_mutant, current_actions, bank
                )["status"],
            )
            self.assertEqual(
                "fail",
                production_generator.intro_audit(
                    no_vdf_mutant, current_actions
                )["status"],
            )
        finally:
            production_generator.configure_vdf_profile("economy")

    def test_current_profile_refactor_census_is_frozen_and_fail_closed(self) -> None:
        if not production_generator.EXPANSION_CATALOGS:
            production_generator.configure_expansion_catalogs(ROOT / "catalog")
        try:
            production_generator.configure_vdf_profile("current")
            bank = production_generator.candidate_bank(len(production_generator.BODY_BANK))
            actions = production_generator.build_actions(bank)
            plugin = production_generator.render_plugin(actions, production_generator.sources_for_bank(bank))
            census = production_generator.refactor_census(plugin, actions)
            self.assertEqual("pass", census["status"], census)
            self.assertEqual("current", census["profile"])
            self.assertFalse(census["canonical_release_profile"])
            self.assertEqual(1638, census["plugin"]["action_count"])
            self.assertEqual(659, census["logical_proof_counts"]["intro_vdf"])
            self.assertEqual(23, census["logical_proof_counts"]["intro_lt_eq_u256"])
            self.assertEqual(
                {
                    "st_sum": -327, "st_gt": 0, "unsafe": 0,
                    "random": 0, "var_assign": 0, "rotate_key": 0,
                    "intro_vdf": 0, "intro_lt_eq_u256": 0,
                },
                census["current_phase1_ledger"],
            )
            self.assertEqual(
                production_generator.REFACTOR_CURRENT_PHASE5_PHYSICAL_DELTAS,
                census["current_phase1_phase3_physical_ledger"],
            )
            self.assertEqual(54, census["plugin"]["physical_vdf_calls"])
            for mutant, mutant_actions in (
                (plugin, actions[:-1]),
                (production_generator.replace_named_function(plugin, "extract_base_vdf_4_core", lambda s: s.replace("extract_direct_resource_core", "action.st_sum(ship.x, 0, ship.x);\nextract_direct_resource_core", 1)), actions),
                (plugin + '\nfn unused_current_proof() { action.st_sum(1, 0, 1); }\n', actions),
                (production_generator.replace_named_function(plugin, "extract_base_vdf_4_core", lambda s: s.replace("intro_vdf(4,body)", "intro_vdf(5,body)", 1)), actions),
                (plugin.replace("action.intro_lt_eq_u256(signal,target);", "action.intro_lt_eq_u256(signal,target);\naction.intro_lt_eq_u256(signal,target);", 1), actions),
            ):
                self.assertEqual("fail", production_generator.refactor_census(mutant, mutant_actions)["status"])
        finally:
            production_generator.configure_vdf_profile("economy")

    def test_refactor_census_enforces_phase_one_ledger_and_closure(self) -> None:
        actions, plugin = self.production_audit_inputs()
        census = production_generator.refactor_census(plugin, actions)
        self.assertEqual("pass", census["status"])
        self.assertEqual("economy", census["profile"])
        self.assertTrue(census["canonical_release_profile"])
        self.assertEqual(
            production_generator.REFACTOR_PHASE6_CANARY_ECONOMY_PHYSICAL_DELTAS,
            census["phase5_bulk_physical_ledger"],
        )
        self.assertEqual(
            {"st_sum": -327, "st_gt": 0, "unsafe": 0, "random": 0,
             "var_assign": 0, "rotate_key": 0, "intro_vdf": 0,
             "intro_lt_eq_u256": 0},
            census["phase1_ledger"]["logical"],
        )
        extraction_closure = census["output_closure"]["ExtractMatter"]
        self.assertTrue(extraction_closure["transforms"])
        self.assertTrue(
            any(
                "extract_direct_resource_core" in row["path"]
                for row in extraction_closure["transforms"]
            )
        )

        refinement_duplicate = production_generator.replace_named_function(
            plugin,
            "refine_resource_core",
            lambda source: source.replace(
                "prove_fixed_versions(action,parent);",
                "prove_fixed_versions(action,parent);\n"
                "action.st_sum(parent.schema_version,0,2);",
                1,
            ),
        )
        duplicate_census = production_generator.refactor_census(
            refinement_duplicate, actions
        )
        self.assertFalse(
            duplicate_census["checks"]["phase1_logical_ledger_exact"]
        )

        permit_duplicate = production_generator.replace_named_function(
            plugin,
            "authorize_large_ship_permit_core",
            lambda source: source.replace(
                "prove_fixed_versions(action,permit);",
                "prove_fixed_versions(action,permit);\n"
                "action.st_sum(permit.schema_version,0,2);",
                1,
            ),
        )
        duplicate_census = production_generator.refactor_census(
            permit_duplicate, actions
        )
        self.assertFalse(
            duplicate_census["checks"]["phase1_logical_ledger_exact"]
        )

        capacity_literal_reintroduced = production_generator.replace_named_function(
            plugin,
            "extract_v2_chart_core",
            lambda source: source.replace(
                "action.st_sum(ship.extraction_amount,0,extraction_amount);",
                "action.st_sum(ship.extraction_amount,0,250);",
                1,
            ),
        )
        capacity_census = production_generator.refactor_census(
            capacity_literal_reintroduced, actions
        )
        self.assertFalse(
            capacity_census["checks"]["phase1_capacity_paths_exact"]
        )

    def test_explicit_selection_capacity_and_progression_are_exact(self) -> None:
        actions, plugin = self.production_audit_inputs()
        selected = [
            action
            for action in actions
            if action.get("selection_mode")
            == production_generator.EXPLICIT_SELECTION_MODE
        ]
        self.assertEqual(603, len(selected))
        self.assertEqual(1, plugin.count("action.intro_lt_eq_u256("))
        self.assertNotIn("stable_identifier_profile_band", json.dumps(actions))

        by_name = {action["name"]: action for action in actions}
        for profile in production_generator.SURVEY_PROFILES:
            name = f"SurveySector_{profile['code']:02d}_{profile['slug']}"
            source = production_generator.action_function_source(plugin, name)
            self.assertEqual(
                profile["minimum_claim_serial"],
                by_name[name]["minimum_claim_serial"],
            )
            self.assertTrue(
                production_generator.rhai_whitespace_insensitive_contains(
                    source,
                    "action.st_gt(ship.claim_serial, "
                    f"{profile['minimum_claim_serial'] - 1});",
                )
            )
            self.assertNotIn("intro_lt_eq_u256", source)
            self.assertNotIn("sector.stable_identifier", source)

        for civilization_type in production_generator.CIVILIZATION_TYPES:
            name = civilization_type["action"]
            source = production_generator.action_function_source(plugin, name)
            self.assertEqual(
                civilization_type["minimum_civilization_scan_serial"],
                by_name[name]["minimum_civilization_scan_serial"],
            )
            self.assertTrue(
                production_generator.rhai_whitespace_insensitive_contains(
                    source,
                    "action.st_gt(ship.civilization_scan_serial, "
                    f"{civilization_type['minimum_civilization_scan_serial'] - 1});",
                )
            )

        self.assertEqual(
            "pass",
            production_generator.warp_coordinate_audit(actions, plugin)[
                "status"
            ],
        )
        self.assertEqual(
            "pass",
            production_generator.warp_v2_catalog_audit(plugin, actions)[
                "status"
            ],
        )

    def test_civilization_raw_binding_adversarial_checks_are_live(self) -> None:
        actions, plugin = self.production_audit_inputs()
        bank = production_generator.candidate_bank(
            len(production_generator.BODY_BANK)
        )
        audit = (
            production_generator.civilization_selection_adversarial_self_check(
                actions,
                plugin,
                bank,
            )
        )
        self.assertEqual("pass", audit["status"])
        self.assertEqual(3, audit["mutation_count"])
        self.assertTrue(all(audit["checks"].values()))

    def test_lifecycle_raw_binding_adversarial_checks_are_live(self) -> None:
        actions, plugin = self.production_audit_inputs()
        bank = production_generator.candidate_bank(
            len(production_generator.BODY_BANK)
        )
        audit = production_generator.lifecycle_raw_binding_adversarial_self_check(
            actions, plugin, bank
        )
        self.assertEqual("pass", audit["status"], audit)
        self.assertEqual(7, audit["mutation_count"])
        self.assertTrue(all(audit["checks"].values()), audit)
        self.assertTrue(
            all(audit["targeted_subcheck_failures"].values()), audit
        )
        self.assertTrue(audit["all_mutations_are_single_exact_replacements"])

    def test_runner_accepts_only_explicit_reveal_representatives(self) -> None:
        action = "RevealWarpCoordinate001"
        representative = {
            "name": "explicit-v1-position",
            "fixture": "TestMintCoordinate",
            "ship_fixture": "TestMintShip",
            "ship_fixture_required_by_target": False,
            "state_pressure_decoy_fixture": "TestMintBodyDecoy",
            "class": production_generator.WARP_COORDINATE,
            "catalog_section": "position",
            "catalog_version": "v1",
            "action_prefix": "RevealWarpCoordinate",
            "representative_action": action,
            "real_sample": False,
            "covered_actions": [action],
            "destination_count": 1,
            "vdf_mode": "source_absent_default_zero",
            "selection_mode": "explicit_action_identity",
        }
        contract = {
            "schema_version": 1,
            "required_action_coverage": [action],
            "positive": [],
            "negative": [],
            "explicit_reveal_representatives": [representative],
        }
        self.assertEqual([], runner.validate_contract(contract))

        retired = dict(contract)
        retired["dynamic_reveals"] = []
        errors = runner.validate_contract(retired)
        self.assertTrue(
            any("dynamic_reveals is retired" in error for error in errors)
        )

        wrong_mode = json.loads(json.dumps(contract))
        wrong_mode["explicit_reveal_representatives"][0][
            "selection_mode"
        ] = "stable_identifier_band"
        errors = runner.validate_contract(wrong_mode)
        self.assertTrue(any("selection mode changed" in error for error in errors))

    def test_runner_closes_selection_and_capacity_gate_censuses(self) -> None:
        positive: list[dict] = []
        negative: list[dict] = []
        survey = (
            (1, "Sparse", 4),
            (2, "Standard", 8),
            (3, "Rich", 32),
            (4, "Ancient", 128),
            (5, "Anomalous", 256),
        )
        civilization = ((1, "I", 64), (2, "II", 1_024), (3, "III", 16_384))
        for selection_kind, rows, counter_field in (
            ("survey_profile", survey, "claim_serial"),
            ("civilization_type", civilization, "civilization_scan_serial"),
        ):
            for code, slug, minimum in rows:
                action = (
                    f"SurveySector_{code:02d}_{slug}"
                    if selection_kind == "survey_profile"
                    else f"MaterializeCivilizationType{slug}"
                )
                for kind, expected, fixture_counter, target in (
                    (positive, "accept", minimum, "positive"),
                    (negative, "reject", minimum - 1, "negative"),
                ):
                    row = {
                        "name": f"{target}-{selection_kind}-{code}",
                        "actions": [f"Fixture{selection_kind}{code}", action],
                        "covers": [action],
                        "selection_gate": {
                            "selection_mode": "explicit_action_identity",
                            "selection_kind": selection_kind,
                            "selected_code": code,
                            "counter_field": counter_field,
                            "minimum_inclusive": minimum,
                            "fixture_counter": fixture_counter,
                            "expected": expected,
                        },
                    }
                    if target == "negative":
                        row["expected_error_contains"] = ["st_gt"]
                    kind.append(row)

        catalog_specs = {
            "v1.position": ("RevealWarpCoordinate", 3, {10: 18_000, 3: 9_001, 1: 9_000}),
            "v1.time": ("RevealTimeCoordinate", 2, {10: 18_000, 3: 9_001, 1: 9_000}),
            "v2.position": ("RevealWarpChart", 3, {10: 40_000, 3: 31_000, 1: 9_000}),
            "v2.time": ("RevealEpochChart", 3, {10: 40_000, 3: 31_000, 1: 9_000}),
        }
        for catalog_name, (prefix, width, minima) in catalog_specs.items():
            for code, uses in ((1, 10), (2, 3), (5, 1)):
                action = f"{prefix}{code:0{width}d}"
                for target, expected, fixture_pool in (
                    (positive, "accept", minima[uses]),
                    (negative, "reject", minima[uses] - 1),
                ):
                    row = {
                        "name": (
                            f"{expected}-{catalog_name}-{code}-"
                            f"{fixture_pool}"
                        ),
                        "actions": [f"Fixture{catalog_name}{fixture_pool}", action],
                        "covers": [action],
                        "capacity_gate": {
                            "selection_mode": "explicit_action_identity",
                            "catalog": catalog_name,
                            "action": action,
                            "destination_code": code,
                            "uses": uses,
                            "minimum_source_pool_inclusive": minima[uses],
                            "fixture_source_pool_before": fixture_pool,
                            "expected": expected,
                        },
                    }
                    if expected == "reject":
                        row["expected_error_contains"] = ["st_gt"]
                    target.append(row)
            for code, uses in ((2, 3), (5, 1)):
                action = f"{prefix}{code:0{width}d}"
                positive.append(
                    {
                        "name": f"high-{catalog_name}-{code}",
                        "actions": [f"FixtureHigh{catalog_name}", action],
                        "covers": [action],
                        "capacity_gate": {
                            "selection_mode": "explicit_action_identity",
                            "catalog": catalog_name,
                            "action": action,
                            "destination_code": code,
                            "uses": uses,
                            "minimum_source_pool_inclusive": minima[uses],
                            "fixture_source_pool_before": minima[10],
                            "expected": "accept",
                        },
                    }
                )
        required = sorted(
            {
                action
                for row in positive
                for action in row["covers"]
            }
        )
        contract = {
            "schema_version": 1,
            "required_action_coverage": required,
            "positive": positive,
            "negative": negative,
            "explicit_reveal_representatives": [],
        }
        self.assertEqual([], runner.validate_contract(contract))
        self.assertEqual(28, len(positive))
        self.assertEqual(20, len(negative))

        mutant = json.loads(json.dumps(contract))
        capacity = next(
            row["capacity_gate"]
            for row in mutant["positive"]
            if "capacity_gate" in row
        )
        capacity["fixture_source_pool_before"] -= 1
        self.assertTrue(
            any(
                "capacity_gate" in error
                for error in runner.validate_contract(mutant)
            )
        )

    def test_fixed_zero_keys_are_bound_to_exact_output_classes(self) -> None:
        actions, plugin = self.production_audit_inputs()
        deterministic_classes = {
            production_generator.SECTOR,
            production_generator.SIGNAL,
            production_generator.BODY,
            production_generator.SATELLITE,
            production_generator.LIFE_SIGNAL,
            production_generator.CIVILIZATION,
            production_generator.WARP_COORDINATE,
            production_generator.TIME_COORDINATE,
            production_generator.WARP_CHART,
            production_generator.EPOCH_CHART,
        }
        audit = production_generator.deterministic_zero_key_audit(
            plugin,
            actions,
            deterministic_classes,
        )
        self.assertEqual("pass", audit["status"])
        self.assertEqual(56, audit["expected_action_count"])
        self.assertEqual(12, audit["physical_update_count"])

        alias_mutant = production_generator.replace_action_function(
            plugin,
            "ExtractWormholeWarpChart",
            lambda source: source.replace("chart_zero", "sealed_zero"),
        )
        self.assertEqual(
            "pass",
            production_generator.deterministic_zero_key_audit(
                alias_mutant,
                actions,
                deterministic_classes,
            )["status"],
        )

        wrong_output_mutant = production_generator.replace_action_function(
            plugin,
            "ExtractWormholeWarpChart",
            lambda source: source.replace(
                'chart.update("key",chart_zero);',
                'next_ship.update("key",chart_zero);',
                1,
            ),
        )
        wrong_output_audit = production_generator.deterministic_zero_key_audit(
            wrong_output_mutant,
            actions,
            deterministic_classes,
        )
        self.assertEqual("fail", wrong_output_audit["status"])
        self.assertFalse(
            wrong_output_audit["actions"]["ExtractWormholeWarpChart"]
            ["checks"]["fixed_zero_targets_exact_deterministic_outputs"]
        )

        commented_update = production_generator.replace_action_function(
            plugin,
            "ExtractWormholeWarpChart",
            lambda source: source.replace(
                'chart.update("key",chart_zero);',
                '// chart.update("key",chart_zero);',
                1,
            ),
        )
        self.assertEqual(
            "fail",
            production_generator.deterministic_zero_key_audit(
                commented_update, actions, deterministic_classes
            )["status"],
        )
        commented_declaration = production_generator.replace_action_function(
            plugin,
            "ExtractWormholeWarpChart",
            lambda source: source.replace(
                "let chart_zero=action.top_limb_u256(0);",
                "// let chart_zero=action.top_limb_u256(0);",
                1,
            ),
        )
        self.assertEqual(
            "fail",
            production_generator.deterministic_zero_key_audit(
                commented_declaration, actions, deterministic_classes
            )["status"],
        )

    def test_vdf_removal_accepts_only_paired_work_block(self) -> None:
        source = """fn Action(action) {
  var work = action.intro_vdf(
    12, object
  );
  object.update("work", work);
  action.st_sum(object.amount, 0, 1);
}
"""
        transformed, removed = generator.remove_vdf_blocks(source, "Action")
        self.assertEqual(1, removed)
        self.assertNotIn("intro_vdf", transformed)
        self.assertIn("action.st_sum", transformed)

    def test_vdf_removal_rejects_unpaired_call(self) -> None:
        with self.assertRaises(RuntimeError):
            generator.remove_vdf_blocks(
                "fn Bad(action) { action.intro_vdf(8, object); }", "Bad"
            )

    def test_shared_helper_vdf_uses_the_same_audited_transform(self) -> None:
        source = """fn helper(action, object) {
  var work = action.intro_vdf(12, object);
  object.update(\"work\", work);
}
"""
        transformed, removed = generator.remove_vdf_blocks(source, "helper")
        self.assertEqual(1, removed)
        self.assertNotIn("intro_vdf", transformed)

    def test_runner_has_no_submission_path(self) -> None:
        with self.assertRaises(RuntimeError):
            runner.safe_command(["pexe", "proof", "submit"])
        runner.safe_command(["pexe", "inspect", "plan"])

    def test_plan_output_decoder_extracts_summary_and_totals(self) -> None:
        decoded = plan_runner.decode_plan_output(
            'diagnostic\n{"summary":{"action":"A"},"totals":{"rows":12}}\n'
        )
        self.assertIsNotNone(decoded)
        self.assertEqual(12, decoded["totals"]["rows"])
        self.assertEqual(
            {"outer.rows": 12, "outer.depth": 3.5},
            plan_runner.numeric_leaves(
                {"outer": {"rows": 12, "depth": 3.5, "ok": True}}
            ),
        )

    def test_plan_runner_refuses_large_subprocess_sweep_by_default(self) -> None:
        rows = [
            {
                "action": f"Action{index}",
                "family": "unit",
                "command": [
                    "pexe",
                    "inspect",
                    "plan",
                    ".",
                    "--action",
                    f"Action{index}",
                ],
            }
            for index in range(101)
        ]
        with self.assertRaisesRegex(RuntimeError, "single-process batch"):
            plan_runner.execute_inventory(
                Path("pexe"),
                {"action_count": len(rows), "actions": rows},
            )

    def test_package_audit_recomputes_source_parity_hashes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            generated = root / "generated"
            generated.mkdir()
            plugin = """fn Keep(action) {
  var object = action.output("Thing");
}
fn TestFixture(action) {
  var object = action.output("Thing");
}
"""
            manifest = """name = "microverse-expansion-test-only-unit"
module_hash = "0000000000000000000000000000000000000000000000000000000000000000"
[[actions]]
name = "Keep"
[[actions]]
name = "TestFixture"
"""
            (root / "plugin.rhai").write_text(plugin, encoding="utf-8")
            (root / "manifest.toml").write_text(manifest, encoding="utf-8")
            functions = generator.validator.extract_rhai_functions(plugin)
            keep_hash = generator.sha256_text(functions["Keep"])
            (generated / "source-parity.json").write_text(
                json.dumps(
                    {
                        "actions": [
                            {
                                "action": "Keep",
                                "symbol": "Keep",
                                "kind": "production_action",
                                "production_sha256": keep_hash,
                                "test_sha256": keep_hash,
                                "vdf_blocks_removed": 0,
                                "only_approved_transform": True,
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            (generated / "fixture-catalog.json").write_text(
                json.dumps(
                    {
                        "fixtures": [
                            {
                                "action": "TestFixture",
                                "output_only": True,
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            contract = {
                "production_module_hash": "b" * 64,
                "production_plugin_sha256": runner.sha256_text(plugin),
                "production_manifest_sha256": runner.sha256_text(manifest),
                "retained_production_action_count": 1,
            }
            self.assertEqual(
                [], runner.audit_test_package(root, contract, production_root=root)
            )
            parity = json.loads(
                (generated / "source-parity.json").read_text(encoding="utf-8")
            )
            parity["actions"][0]["test_sha256"] = "0" * 64
            (generated / "source-parity.json").write_text(
                json.dumps(parity), encoding="utf-8"
            )
            self.assertTrue(
                any(
                    "test source hash mismatch" in error
                    for error in runner.audit_test_package(
                        root, contract, production_root=root
                    )
                )
            )

    def test_production_subset_keeps_helpers_and_only_selected_actions(self) -> None:
        source = """fn helper(value) {
  value.update(\"serial\", 1);
}

fn Keep(action) {
  helper(action.output(\"Thing\"));
}

fn Omit(action) {
  helper(action.output(\"Thing\"));
}
"""
        functions = generator.validator.extract_rhai_functions(source)
        subset = generator.production_source_subset(
            source,
            functions,
            ["Keep", "Omit"],
            {"Keep"},
        )
        remaining = generator.validator.extract_rhai_functions(subset)
        self.assertEqual({"helper", "Keep"}, set(remaining))
        self.assertEqual(functions["Keep"], remaining["Keep"])

    def test_manifest_subset_preserves_non_action_tables(self) -> None:
        manifest = """name = \"microverse\"
module_hash = \"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"

[[classes]]
name = \"Thing\"

[[actions]]
name = \"Keep\"
description = \"kept\"

[[actions]]
name = \"Omit\"
description = \"omitted\"
"""
        filtered = generator.filter_manifest_actions(manifest, {"Keep"})
        self.assertIn('[[classes]]\nname = "Thing"', filtered)
        self.assertIn('name = "Keep"', filtered)
        self.assertNotIn('name = "Omit"', filtered)
        self.assertEqual(["Keep"], generator.validator.manifest_action_names(filtered))

    def test_expansion_fixtures_use_v2_protocol_versions(self) -> None:
        source = generator.ship_fixture_source("TestShip", 1, "Large")
        self.assertIn('["schema_version", 2]', source)
        self.assertIn('["mechanics_version", 2]', source)
        self.assertIn('["universe_version", 2]', source)
        self.assertNotIn('["schema_version", 1]', source)

    def test_anchor_fixtures_keep_runtime_copy_values_pairwise_distinct(self) -> None:
        position_a = generator.warp_object_fixture_source(
            "PositionA",
            "MicroversePositionAnchor",
            uses=1,
            variant=1,
        )
        position_b = generator.warp_object_fixture_source(
            "PositionB",
            "MicroversePositionAnchor",
            uses=1,
            variant=2,
        )
        time_a = generator.warp_object_fixture_source(
            "TimeA",
            "MicroverseTimeAnchor",
            uses=1,
            variant=1,
        )
        time_b = generator.warp_object_fixture_source(
            "TimeB",
            "MicroverseTimeAnchor",
            uses=1,
            variant=2,
        )
        for field, value in zip(
            ("x", "y", "z"), generator.FIXTURE_LOCATIONS[0][:3], strict=True
        ):
            token = f'["{field}", {value}]'
            self.assertIn(token, position_a)
        for field, value in zip(
            ("x", "y", "z"), generator.FIXTURE_LOCATIONS[1][:3], strict=True
        ):
            token = f'["{field}", {value}]'
            self.assertIn(token, position_b)
        self.assertIn(
            f'["epoch", {generator.FIXTURE_LOCATIONS[0][3]}]', time_a
        )
        self.assertIn(
            f'["epoch", {generator.FIXTURE_LOCATIONS[1][3]}]', time_b
        )

    def test_component_matrix_is_exhaustive(self) -> None:
        catalog = self.load("microverse-component-tree-v2.json")
        actions = {
            str(action)
            for component in catalog["components"]
            for action in component["actions"].values()
        }
        fixtures = generator.FixtureRegistry()
        positive, negative, required = generator.component_scenarios(
            catalog, fixtures, actions
        )
        self.assertEqual(135, len(positive))
        self.assertEqual(180, len(negative))
        self.assertEqual(actions, required)

    def test_resource_matrix_covers_every_expansion_route(self) -> None:
        catalog = self.load("microverse-resource-tree-v2.json")
        bodies = {row["body_id"]: row for row in catalog["bodies"]}
        actions: set[str] = {"UseTechnologySkill"}
        extraction_count = 0
        for source in catalog["source_resources"]:
            base = (
                f"Extract{bodies[source['body_id']]['slug']}"
                f"{generator.action_slug(source['name'])}"
            )
            minimum = source["min_capacity_tier"]
            for tier_index, tier_name in enumerate(("Small", "Medium", "Large")):
                if tier_index < minimum:
                    continue
                actions.add(base if tier_index == minimum else f"{base}{tier_name}")
                extraction_count += 1
        for parent in catalog["refinement_parents"]:
            for child in parent["children"]:
                actions.add(
                    f"Refine{generator.action_slug(parent['parent_name'])}"
                    f"To{generator.action_slug(child['name'])}"
                )
        fixtures = generator.FixtureRegistry()
        positive, negative, required = generator.resource_scenarios(
            catalog, fixtures, actions
        )
        self.assertEqual(extraction_count + 270, len(positive))
        self.assertEqual(2 * extraction_count + 405, len(negative))
        self.assertEqual(extraction_count + 135, len(required))

    def test_skill_and_capability_matrix_is_exhaustive(self) -> None:
        skills = self.load("microverse-skill-tree-v2.json")
        components = self.load("microverse-component-tree-v2.json")
        actions = {
            str(row["develop_action"])
            for row in generator.iter_skills(skills)
        } | {str(row["action"]) for row in skills["capability_artifacts"]}
        fixtures = generator.FixtureRegistry()
        positive, negative, required = generator.skill_scenarios(
            skills,
            components,
            {"resource_codes": {}},
            fixtures,
            actions,
        )
        self.assertEqual(234, len(positive))
        self.assertEqual(306, len(negative))
        self.assertEqual(162, len(required))

    def test_warp_matrix_covers_exact_full_622_action_tree(self) -> None:
        warp = self.load("microverse-warp-tree-v2.json")
        resources = self.load("microverse-resource-tree-v2.json")
        tree_actions = generator.warp_tree_action_names(warp)
        self.assertEqual(622, len(tree_actions))
        milestone_actions = {
            action
            for action, _selected_code, _minimum in (
                generator.SURVEY_SELECTION_MILESTONES
                + generator.CIVILIZATION_SELECTION_MILESTONES
            )
        }
        actions = tree_actions | milestone_actions | {"UseTechnologySkill"}
        fixtures = generator.FixtureRegistry()
        positive, negative, required, representatives = (
            generator.warp_lifecycle_scenarios(
                warp,
                resources,
                fixtures,
                actions,
            )
        )
        self.assertEqual(tree_actions | milestone_actions, required)
        self.assertEqual(60, len(positive))
        self.assertEqual(70, len(negative))
        self.assertEqual(4, len(representatives))
        self.assertEqual(
            595,
            sum(row["destination_count"] for row in representatives),
        )
        self.assertEqual(
            {"v1", "v2"},
            {row["catalog_version"] for row in representatives},
        )
        self.assertEqual(
            {"source_absent_default_zero", "vdf_stripped_default_zero"},
            {row["vdf_mode"] for row in representatives},
        )
        referenced = {
            action
            for scenario in positive + negative
            for action in scenario["actions"]
        }
        for scenario in representatives:
            referenced.update((scenario["fixture"], scenario["ship_fixture"]))
        fixture_rows = [
            row for row in fixtures.rows if row["action"] in referenced - actions
        ]
        self.assertEqual(89, len(fixture_rows))
        shape_j_rows = {
            row["actions"][-1]: row
            for row in positive
            if row["actions"][-1]
            in generator.SHAPE_J_CONSTRUCTOR_ROLE_CONTRACTS
        }
        self.assertEqual(
            set(generator.SHAPE_J_CONSTRUCTOR_ROLE_CONTRACTS),
            set(shape_j_rows),
        )
        self.assertTrue(
            all(
                row.get("post_state_assertion") == "shape_j_constructor"
                for row in shape_j_rows.values()
            )
        )
        self.assertTrue(
            all(
                "post_state_assertion" not in row
                for row in positive
                if row["actions"][-1] not in shape_j_rows
                and row["actions"][-1]
                not in {"CapturePositionAnchor", "CaptureTimeAnchor"}
            )
        )
        capture_rows = {
            row["actions"][-1]: row
            for row in positive
            if row["actions"][-1]
            in {"CapturePositionAnchor", "CaptureTimeAnchor"}
        }
        self.assertEqual(2, len(capture_rows))
        for row in capture_rows.values():
            self.assertEqual(
                "capture_anchor_source_ship_id_raw",
                row["post_state_assertion"],
            )
            relation = row["output_relations"][0]
            self.assertEqual("Raw", relation["output"]["field_type"])
            self.assertEqual(2, relation["output"]["output_ordinal"])
        index = self.load("microverse-catalog-index-v2.json")
        by_name = {row["name"]: row for row in index["actions"]}
        for action, roles in generator.SHAPE_J_CONSTRUCTOR_ROLE_CONTRACTS.items():
            with self.subTest(shape_j_role_contract=action):
                self.assertEqual(
                    [
                        {"mode": mode, "class": class_name}
                        for mode, class_name in roles
                    ],
                    by_name[action]["roles"],
                )

    def test_full_warp_subset_has_exact_roles_helpers_vdf_and_size(self) -> None:
        warp = self.load("microverse-warp-tree-v2.json")
        source = (ROOT / "plugin.rhai").read_text(encoding="utf-8")
        manifest = (ROOT / "manifest.toml").read_text(encoding="utf-8")
        functions = generator.validator.extract_rhai_functions(source)
        actions = generator.validator.manifest_action_names(manifest)
        action_set = set(actions)
        tree = generator.warp_tree_action_names(warp)
        milestone_actions = {
            action
            for action, _selected_code, _minimum in (
                generator.SURVEY_SELECTION_MILESTONES
                + generator.CIVILIZATION_SELECTION_MILESTONES
            )
        }
        retained = tree | milestone_actions | {"UseTechnologySkill"}
        subset = generator.production_source_subset(
            source, functions, actions, retained
        )
        transformed, removed = generator.remove_vdf_blocks(subset, "warp-622")
        self.assertEqual(66, removed)
        self.assertEqual(631, len(retained))
        self.assertLess(len(transformed.encode("utf-8")), 230_000)

        test_functions = generator.validator.extract_rhai_functions(transformed)
        vdf_helpers = {
            name
            for name, function in generator.validator.extract_rhai_functions(
                subset
            ).items()
            if name not in action_set and "action.intro_vdf(" in function
        }
        self.assertEqual(
            generator.WARP_SHARD_APPROVED_VDF_HELPERS,
            vdf_helpers,
        )
        self.assertEqual(
            generator.WARP_SHARD_APPROVED_VDF_HELPER_COUNT,
            len(vdf_helpers),
        )
        roles = generator.direct_role_contract(functions["CapturePositionAnchor"])
        self.assertEqual(
            [
                (1, "next_ship", "output", "MicroverseShip", 1),
                (2, "anchor", "output", "MicroversePositionAnchor", 2),
                (3, "ship", "input", "MicroverseShip", None),
                (4, "material_1", "input", "MicroverseResource", None),
                (5, "material_2", "input", "MicroverseResource", None),
            ],
            [
                (
                    row["ordinal"],
                    row["variable"],
                    row["mode"],
                    row["class"],
                    row["output_ordinal"],
                )
                for row in roles
            ],
        )
        closure, paths = generator.transitive_helper_contract(
            "CapturePositionAnchor",
            functions,
            test_functions,
            action_set,
        )
        self.assertIn("consume_prepared_ship_core", closure)
        self.assertIn("bind_ship_id", closure)
        self.assertTrue(
            any(
                row["path"]
                == [
                    "CapturePositionAnchor",
                    "consume_prepared_ship_core",
                    "bind_ship_id",
                ]
                for row in paths
            )
        )

    def test_generated_shards_fail_closed_on_vdf_helper_parity_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "expansion"
            generator.generate(ROOT, output, catalog_dir=ROOT / "catalog")
            warp_root = output / "warp"
            generated = warp_root / "generated"
            contract = json.loads(
                (generated / "expansion-test-contract.json").read_text(
                    encoding="utf-8"
                )
            )
            self.assertEqual(
                [],
                runner.audit_test_package(warp_root, contract, production_root=ROOT),
            )
            parity_path = generated / "source-parity.json"
            parity = json.loads(parity_path.read_text(encoding="utf-8"))
            helper_rows = [
                row
                for row in parity["actions"]
                if row["kind"] == "production_helper"
            ]
            self.assertEqual(
                sorted(generator.WARP_SHARD_APPROVED_VDF_HELPERS),
                parity["vdf_helper_symbols"],
            )
            self.assertEqual(45, len(helper_rows))
            self.assertEqual(66, parity["vdf_blocks_removed"])

            altered = json.loads(json.dumps(parity))
            altered["vdf_helper_symbols"] = altered["vdf_helper_symbols"][1:]
            parity_path.write_text(json.dumps(altered), encoding="utf-8")
            self.assertTrue(
                any(
                    "vdf_helper_symbols mismatch" in error
                    for error in runner.audit_test_package(
                        warp_root, contract, production_root=ROOT
                    )
                )
            )

            altered = json.loads(json.dumps(parity))
            next(
                row
                for row in altered["actions"]
                if row["kind"] == "production_helper"
            )["direct_roles"] = [{"forged": True}]
            parity_path.write_text(json.dumps(altered), encoding="utf-8")
            self.assertTrue(
                any(
                    "direct role contract mismatch" in error
                    for error in runner.audit_test_package(
                        warp_root, contract, production_root=ROOT
                    )
                )
            )

            altered = json.loads(json.dumps(parity))
            binding = next(
                row for row in altered["helper_bindings"] if row["direct_helpers"]
            )
            binding["direct_helpers"] = ["forged_helper"]
            parity_path.write_text(json.dumps(altered), encoding="utf-8")
            self.assertTrue(
                any(
                    "helper direct call mismatch" in error
                    for error in runner.audit_test_package(
                        warp_root, contract, production_root=ROOT
                    )
                )
            )

            altered = json.loads(json.dumps(parity))
            altered["vdf_blocks_removed"] = 0
            parity_path.write_text(json.dumps(altered), encoding="utf-8")
            self.assertTrue(
                any(
                    "vdf_blocks_removed mismatch" in error
                    for error in runner.audit_test_package(
                        warp_root, contract, production_root=ROOT
                    )
                )
            )

            parity_path.write_text(json.dumps(parity), encoding="utf-8")
            plugin_path = warp_root / "plugin.rhai"
            plugin_source = plugin_path.read_text(encoding="utf-8")
            production_source = (ROOT / "plugin.rhai").read_text(encoding="utf-8")
            production_functions = validator.extract_rhai_functions(production_source)
            production_actions = set(
                validator.manifest_action_names(
                    (ROOT / "manifest.toml").read_text(encoding="utf-8")
                )
            )
            helper = next(
                name
                for name in sorted(production_functions)
                if name not in production_actions
                and name not in generator.WARP_SHARD_APPROVED_VDF_HELPERS
            )
            plugin_path.write_text(
                plugin_source.replace(production_functions[helper], "", 1),
                encoding="utf-8",
            )
            self.assertTrue(
                any(
                    "test source omits production helpers" in error
                    for error in runner.audit_test_package(
                        warp_root, contract, production_root=ROOT
                    )
                )
            )

    def test_fixture_coordinates_counters_and_raw_anchor_types_are_distinct(self) -> None:
        for location in generator.FIXTURE_LOCATIONS.values():
            x, y, z, epoch = location
            self.assertEqual(3, len({x, y, z}))
            self.assertNotEqual(0, epoch)
            self.assertNotIn(epoch, {x, y, z})
        self.assertEqual(
            len(generator.SHIP_COUNTERS),
            len(set(generator.SHIP_COUNTERS.values())),
        )
        self.assertNotIn(0, generator.SHIP_COUNTERS.values())

        schemas = json.loads(
            (ROOT / "generated" / "schema-counts.json").read_text(
                encoding="utf-8"
            )
        )
        fixtures = generator.FixtureRegistry()
        for class_name in (
            "MicroversePositionAnchor",
            "MicroverseTimeAnchor",
        ):
            fixtures.warp_object(class_name, uses=1)
        source_by_name = {
            row["action"]: source
            for row, source in zip(fixtures.rows, fixtures.sources, strict=True)
        }
        generator.enrich_fixture_contract_rows(
            fixtures.rows, source_by_name, schemas
        )
        for row in fixtures.rows:
            self.assertEqual("Raw", row["field_types"]["source_ship_id"])
            relation = next(
                relation
                for relation in row["raw_relations"]
                if relation["field"] == "source_ship_id"
            )
            self.assertEqual("raw_a", relation["variable"])
            self.assertIn("action.random", relation["producer_expression"])

    def test_every_fixture_source_is_schema_complete_and_exactly_typed(self) -> None:
        fixtures, schemas = self.all_fixture_rows()
        self.assertEqual(714, len(fixtures.rows))
        self.assertEqual(17, len({row["class"] for row in fixtures.rows}))
        source_by_name = {
            row["action"]: source
            for row, source in zip(fixtures.rows, fixtures.sources, strict=True)
        }
        for row in fixtures.rows:
            with self.subTest(action=row["action"]):
                class_row = schemas["classes"][row["class"]]
                expected_fields = {
                    field["name"] for field in class_row["fields"]
                }
                completeness = row["schema_completeness"]
                self.assertEqual("complete", completeness["status"])
                self.assertEqual([], completeness["missing_fields"])
                self.assertEqual({}, completeness["wrong_type_fields"])
                self.assertEqual(
                    ["key", "stable_identifier", "type", "work"],
                    completeness["sdk_managed_runtime_fields"],
                )
                self.assertEqual(
                    expected_fields | {"type", "work"},
                    set(completeness["field_sources"]),
                )
                independently_reconstructed = runner.fixture_source_schema_contract(
                    row["action"],
                    row["class"],
                    source_by_name[row["action"]],
                    class_row,
                )
                self.assertEqual(completeness, independently_reconstructed)

        for class_name, field_name in (
            ("MicroverseCelestialBody", "source_signal_identifier"),
            ("MicroverseCivilization", "source_life_signal_identifier"),
        ):
            class_rows = [
                row for row in fixtures.rows if row["class"] == class_name
            ]
            self.assertTrue(class_rows)
            for row in class_rows:
                with self.subTest(action=row["action"], raw_field=field_name):
                    field_source = row["schema_completeness"]["field_sources"][
                        field_name
                    ]
                    self.assertEqual("set", field_source["source"])
                    self.assertEqual("Raw", field_source["inferred_type"])
                    relation = next(
                        relation
                        for relation in row["raw_relations"]
                        if relation["field"] == field_name
                    )
                    self.assertEqual("Raw", relation["field_type"])
                    self.assertIn("action.random", relation["producer_expression"])

    def test_fixture_schema_completeness_rejects_omission_and_wrong_type(self) -> None:
        schemas = json.loads(
            (ROOT / "generated" / "schema-counts.json").read_text(
                encoding="utf-8"
            )
        )
        body = self.load("microverse-resource-tree-v2.json")["bodies"][0]
        source = generator.body_fixture_source("TestBodyCompleteness", body)
        class_row = schemas["classes"]["MicroverseCelestialBody"]
        omitted = source.replace(
            '    ["source_signal_identifier", source_signal_identifier],\n',
            "",
            1,
        )
        self.assertNotEqual(source, omitted)
        with self.assertRaisesRegex(
            RuntimeError, "schema-incomplete.*source_signal_identifier"
        ):
            generator.fixture_source_schema_contract(
                "TestBodyCompleteness",
                "MicroverseCelestialBody",
                omitted,
                class_row,
            )
        wrong_type = source.replace(
            '["source_signal_identifier", source_signal_identifier]',
            '["source_signal_identifier", 1]',
            1,
        )
        self.assertNotEqual(source, wrong_type)
        with self.assertRaisesRegex(
            RuntimeError, "wrong field types.*source_signal_identifier"
        ):
            generator.fixture_source_schema_contract(
                "TestBodyCompleteness",
                "MicroverseCelestialBody",
                wrong_type,
                class_row,
            )
        updated = source.replace(
            "  ]);\n}",
            '  ]);\n  body.update("candidate_code", 999);\n}',
            1,
        )
        last_write = generator.fixture_source_schema_contract(
            "TestBodyCompleteness",
            "MicroverseCelestialBody",
            updated,
            class_row,
        )
        self.assertEqual(
            {
                "source": "update",
                "expression": "999",
                "inferred_type": "Int",
            },
            last_write["field_sources"]["candidate_code"],
        )

    def test_location_system_rejects_composite_ship_drift(self) -> None:
        schemas = json.loads(
            (ROOT / "generated" / "schema-counts.json").read_text(
                encoding="utf-8"
            )
        )
        fixtures = generator.FixtureRegistry()
        ship = fixtures.ship(1)
        composite = fixtures.composite(435, {1: 175, 2: 50, 3: 25})
        source_by_name = {
            row["action"]: source
            for row, source in zip(fixtures.rows, fixtures.sources, strict=True)
        }
        generator.enrich_fixture_contract_rows(
            fixtures.rows, source_by_name, schemas
        )
        generator.validate_fixture_location_system(
            fixtures.rows,
            ([{"name": "co-located", "actions": [ship, composite]}],),
        )
        composite_row = next(
            row for row in fixtures.rows if row["action"] == composite
        )
        composite_row["literal_fields"]["sector_x"] = generator.COORD_ZERO
        with self.assertRaisesRegex(RuntimeError, "location drift"):
            generator.validate_fixture_location_system(
                fixtures.rows,
                ([{"name": "drifted", "actions": [ship, composite]}],),
            )

    def test_final_source_hash_bindings_are_exact(self) -> None:
        actual = {
            "production_plugin_sha256": generator.sha256_path(ROOT / "plugin.rhai"),
            "production_manifest_sha256": generator.sha256_path(ROOT / "manifest.toml"),
            "production_module_hash": generator.production_module_hash(
                (ROOT / "manifest.toml").read_text(encoding="utf-8")
            ),
            "production_warp_catalog_sha256": generator.sha256_path(
                ROOT / "catalog" / "microverse-warp-tree-v2.json"
            ),
            "production_catalog_index_sha256": generator.sha256_path(
                ROOT / "catalog" / "microverse-catalog-index-v2.json"
            ),
            "production_schema_counts_sha256": generator.sha256_path(
                ROOT / "generated" / "schema-counts.json"
            ),
            "production_universe_contract_sha256": generator.sha256_path(
                ROOT / "generated" / "universe-contract.json"
            ),
            "production_action_contract_sha256": generator.sha256_path(
                ROOT / "generated" / "action-contract.json"
            ),
        }
        self.assertEqual(generator.FINAL_PRODUCTION_HASHES, actual)

    def test_representative_real_targets_cover_new_structural_risks(self) -> None:
        index = self.load("microverse-catalog-index-v2.json")
        skills = self.load("microverse-skill-tree-v2.json")
        resources = self.load("microverse-resource-tree-v2.json")
        production_actions = {str(row["name"]) for row in index["actions"]}
        _positive, _negative, resource_required = (
            generator.resource_scenarios(
                resources,
                generator.FixtureRegistry(),
                production_actions,
            )
        )
        document = generator.representative_real_targets(
            index["actions"],
            skills,
            resource_required,
        )
        targets = document["targets"]
        selected = {row["action"] for row in targets}
        selected_families = {row["family"] for row in targets}
        expected_families = set(document["new_structural_families"])
        self.assertTrue(expected_families.issubset(selected_families))
        self.assertTrue(
            {
                "CapturePositionAnchor",
                "CaptureTimeAnchor",
                "ConstructWormholeLink",
                "ConstructTemporalLink",
                "ComposeRendezvousCoordinate",
                "WarpToRendezvousCoordinateReusable",
                "WarpToRendezvousCoordinateFinal",
            }.issubset(selected)
        )
        for family in (
            "traverse_wormhole_link",
            "traverse_temporal_link",
            "warp_ship_to_epoch_chart",
            "warp_ship_to_position_chart",
        ):
            actions = {
                row["name"] for row in index["actions"] if row["family"] == family
            }
            self.assertTrue(actions.issubset(selected), family)
        for count in (1, 2, 3):
            self.assertTrue(
                any(
                    f"skill development {count}-evidence shape" in row["selection"]
                    for row in targets
                ),
                count,
            )
        capability_families = {
            row["action_family"] for row in skills["capability_artifacts"]
        }
        for family in capability_families:
            capability_actions = {
                row["action"]
                for row in skills["capability_artifacts"]
                if row["action_family"] == family
            }
            self.assertTrue(selected & capability_actions, family)
        reusable_bases = {
            name.removesuffix("Reusable")
            for name in selected
            if name.startswith("Fabricate") and name.endswith("Reusable")
        }
        final_bases = {
            name.removesuffix("Final")
            for name in selected
            if name.startswith("Fabricate") and name.endswith("Final")
        }
        self.assertTrue(reusable_bases & final_bases)
        structural_rows = [
            row
            for row in index["actions"]
            if row["family"] in expected_families
        ]
        self.assertEqual(
            max(len(row["roles"]) for row in structural_rows),
            document["maximum_selected_role_count"],
        )
        self.assertEqual(52, document["target_count"])
        self.assertTrue(document["all_resource_samples_are_catalog_retained"])
        self.assertEqual(
            6,
            len(document["retained_v2_resource_sample_actions"]),
        )
        self.assertTrue(
            set(document["retained_v2_resource_sample_actions"])
            <= resource_required
        )

    def test_deterministic_hierarchy_is_pexe_owned_and_fail_closed(self) -> None:
        actions, plugin = self.production_audit_inputs()
        bank = production_generator.candidate_bank(
            len(production_generator.BODY_BANK)
        )
        audit = production_generator.deterministic_hierarchy_audit(
            plugin, actions, bank
        )
        self.assertEqual("pass", audit["status"])
        self.assertEqual(400, audit["route_count"])
        self.assertEqual(23, audit["detect_alias_count"])

        rocky = production_generator.action_function_source(
            plugin, "ScanCelestialBody_03_RockyPlanet"
        )
        selector_calls = production_generator.rhai_method_statement_calls(
            rocky, "intro_lt_eq_u256"
        )
        self.assertTrue(selector_calls)
        selector_statement = (
            "action.intro_lt_eq_u256(signal,body_selector_upper);"
        )
        self.assertIn(selector_statement, rocky)
        forged = plugin.replace(selector_statement, "", 1)
        self.assertEqual(
            "fail",
            production_generator.deterministic_hierarchy_audit(
                forged, actions, bank
            )["status"],
        )

        detect = production_generator.action_function_source(
            plugin, "DetectCelestialSignal_03_RockyPlanet"
        )
        self.assertIn(
            str(production_generator.UNRESOLVED_CANDIDATE_CODE), detect
        )
        forged_detect = plugin.replace(
            detect,
            detect.replace(
                str(production_generator.UNRESOLVED_CANDIDATE_CODE),
                "3",
                1,
            ),
            1,
        )
        self.assertEqual(
            "fail",
            production_generator.deterministic_hierarchy_audit(
                forged_detect, actions, bank
            )["status"],
        )


if __name__ == "__main__":
    unittest.main()
