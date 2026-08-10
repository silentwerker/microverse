#!/usr/bin/env python3
"""Validate the authored and generated Microverse v2 expansion catalogs.

The validator is deliberately independent of the DON SDK.  It reads JSON,
the generated Rhai source, and the manifest, but never mutates a PEXE or an
object.  The canonical inputs are:

* catalog/microverse-resource-tree-v2.json
* catalog/microverse-component-tree-v2.json
* catalog/microverse-skill-tree-v2.json
* catalog/microverse-warp-tree-v2.json
* catalog/microverse-catalog-index-v2.json (generator-produced)

During catalog authoring, ``--allow-missing-generated`` permits the index and
warp catalog to be absent.  Release validation must use the default strict
mode.  ``--rhai-only`` is useful for auditing an intermediate generated Rhai
file before the catalogs are ready.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from dataclasses import dataclass, field
import hashlib
import json
from pathlib import Path
import re
import sys
from typing import Any, Iterable, Mapping, Sequence


POSITION_MINIMUM = 100
POSITION_MAXIMUM_EXCLUSIVE = 2_000_000_000_000
TIME_MINIMUM = 101
TIME_MAXIMUM_EXCLUSIVE = 1_000_000_000_000
EXPLICIT_SELECTION_MODE = "explicit_action_identity"
DETERMINISTIC_SELECTOR_MODE = "stable_identifier_band_v1"

V1_COORDINATE_POOL_MINIMUMS = {10: 18_000, 3: 9_001, 1: 9_000}
V2_CHART_POOL_MINIMUMS = {10: 40_000, 3: 31_000, 1: 9_000}

SURVEY_SELECTIONS: tuple[tuple[str, int, int], ...] = (
    ("SurveySector_01_Sparse", 1, 4),
    ("SurveySector_02_Standard", 2, 8),
    ("SurveySector_03_Rich", 3, 32),
    ("SurveySector_04_Ancient", 4, 128),
    ("SurveySector_05_Anomalous", 5, 256),
)

PHASE3_DETECT_ACTION = "DetectCelestialSignal_00_RedDwarf"
PHASE3_SURVEY_ACTION = "SurveySector_01_Sparse"
PHASE3_DETECT_PARAMETERS = (
    "action", "next_ship", "signal", "ship", "sector", "category_code",
    "candidate_code", "remaining_field", "serial_field",
)
PHASE3_SURVEY_PARAMETERS = ("action", "sector")
PHASE3_DETECT_SELECTIONS = (
    (0,"RedDwarf",2,"star_remaining","next_star_serial"),(1,"MainSequenceStar",2,"star_remaining","next_star_serial"),(2,"GiantStar",2,"star_remaining","next_star_serial"),(3,"RockyPlanet",1,"planet_remaining","next_planet_serial"),(4,"OceanPlanet",1,"planet_remaining","next_planet_serial"),(5,"GardenPlanet",1,"planet_remaining","next_planet_serial"),(6,"GasGiant",3,"gas_giant_remaining","next_gas_giant_serial"),(7,"IceGiant",4,"ice_giant_remaining","next_ice_giant_serial"),(8,"BarrenPlanet",1,"planet_remaining","next_planet_serial"),(9,"NeutronStar",5,"neutron_star_remaining","next_neutron_star_serial"),(10,"BlackHole",6,"black_hole_remaining","next_black_hole_serial"),(11,"Anomaly",7,"anomaly_remaining","next_anomaly_serial"),(12,"Megastructure",8,"megastructure_remaining","next_megastructure_serial"),(13,"GasCluster",9,"gas_cluster_remaining","next_gas_cluster_serial"),(14,"StellarRemnant",10,"stellar_remnant_remaining","next_stellar_remnant_serial"),(15,"AsteroidBelt",11,"minor_body_field_remaining","next_minor_body_field_serial"),(16,"VolcanicPlanet",1,"planet_remaining","next_planet_serial"),(17,"Nebula",9,"gas_cluster_remaining","next_gas_cluster_serial"),(18,"CometCluster",11,"minor_body_field_remaining","next_minor_body_field_serial"),(19,"BrownDwarf",2,"star_remaining","next_star_serial"),(20,"WhiteDwarf",10,"stellar_remnant_remaining","next_stellar_remnant_serial"),(21,"Magnetar",5,"neutron_star_remaining","next_neutron_star_serial"),(22,"WormholeMouth",7,"anomaly_remaining","next_anomaly_serial"),
)
# The configured resource catalog appends Minor-Body Field after these ten
# established Sector pools.  The validator reads that appended row rather
# than duplicating its fields, so catalog drift cannot silently weaken the
# Phase 3 survey proof.
PHASE3_BASE_SURVEY_FIELDS = (
    "sector_type", "survey_profile", "planet_remaining", "star_remaining",
    "gas_giant_remaining", "ice_giant_remaining", "neutron_star_remaining",
    "black_hole_remaining", "anomaly_remaining", "megastructure_remaining",
    "gas_cluster_remaining", "stellar_remnant_remaining", "next_planet_serial",
    "next_star_serial", "next_gas_giant_serial", "next_ice_giant_serial",
    "next_neutron_star_serial", "next_black_hole_serial", "next_anomaly_serial",
    "next_megastructure_serial", "next_gas_cluster_serial",
    "next_stellar_remnant_serial",
)
PHASE3_MINOR_BODY_SURVEY_FIELDS = (
    "minor_body_field_remaining", "next_minor_body_field_serial",
)

PHASE4_ECONOMY_HELPERS = (
    ("extract_base_vdf_2_core", "base", 2, "ExtractGas"),
    ("extract_base_vdf_4_core", "base", 4, "ExtractEnergy"),
    ("extract_base_vdf_8_core", "base", 8, "ExtractMatter"),
    ("extract_direct_body_vdf_2_core", "body", 2, "ExtractOceanPlanetWater"),
    ("extract_direct_body_vdf_4_core", "body", 4, "ExtractRedDwarfRadiantEnergy"),
    ("extract_direct_body_vdf_12_core", "body", 12, "ExtractRedDwarfFlareSpectrumData"),
    ("extract_direct_body_vdf_20_core", "body", 20, "ExtractNeutronStarGravitationalData"),
    ("extract_direct_body_vdf_32_core", "body", 32, "ExtractMegastructureArchiveData"),
    ("extract_composite_vdf_2_core", "composite", 2, "ExtractOceanPlanetAtmosphericGas"),
    ("extract_composite_vdf_4_core", "composite", 4, "ExtractOceanPlanetSeawaterMinerals"),
    ("extract_composite_vdf_8_core", "composite", 8, "ExtractRockyPlanetFerrousOre"),
    ("extract_composite_vdf_12_core", "composite", 12, "ExtractRedDwarfFusionGas"),
    ("extract_composite_vdf_20_core", "composite", 20, "ExtractNeutronStarRProcessEjecta"),
    ("extract_composite_vdf_32_core", "composite", 32, "ExtractMegastructureStructuralSalvage"),
    ("refine_resource_vdf_2_core", "refine", 2, "RefineAtmosphericGasToNitrogen"),
    ("refine_resource_vdf_4_core", "refine", 4, "RefineSeawaterMineralsToSodiumChloride"),
    ("refine_resource_vdf_8_core", "refine", 8, "RefineFerrousOreToIron"),
    ("refine_resource_vdf_12_core", "refine", 12, "RefineFusionGasToHydrogen"),
    ("refine_resource_vdf_20_core", "refine", 20, "RefineRProcessEjectaToOsmium"),
    ("refine_resource_vdf_32_core", "refine", 32, "RefineStructuralSalvageToSteel"),
)
PHASE4_CURRENT_HELPERS = (
    ("extract_base_vdf_4_core", "base", 4, "ExtractMatter"),
    ("extract_base_vdf_8_core", "base", 8, "ExtractCrystal"),
    ("extract_base_vdf_12_core", "base", 12, "ExtractEnergy"),
    ("extract_direct_body_no_vdf_core", "body", None, "ExtractRedDwarfRadiantEnergy"),
    ("extract_composite_no_vdf_core", "composite", None, "ExtractRedDwarfFusionGas"),
    ("refine_resource_no_vdf_core", "refine", None, "RefineFusionGasToHydrogen"),
)
PHASE4_HELPER_PARAMETERS = {
    "base": ("action", "next_ship", "resource", "ship", "body", "required_skill_type", "remaining_field", "resource_type", "extraction_amount", "rare_extraction_amount"),
    "body": ("action", "next_ship", "resource", "ship", "body", "candidate_code", "required_skill_type", "remaining_field", "resource_type", "extraction_amount", "rare_extraction_amount"),
    "composite": ("action", "next_ship", "composite_resource", "ship", "body", "candidate_code", "required_skill_type", "remaining_field", "composite_resource_type", "extraction_amount", "rare_extraction_amount", "child_1_amount", "child_2_amount", "child_3_amount"),
    "refine": ("action", "next_ship", "resource", "ship", "parent", "required_skill_type", "parent_resource_type", "child_remaining_field", "output_resource_type"),
}
PHASE4_PROFILE_HELPERS = {
    "economy": PHASE4_ECONOMY_HELPERS,
    "current": PHASE4_CURRENT_HELPERS,
}
PHASE4_KNOWN_HELPER_NAMES = {
    name
    for specs in PHASE4_PROFILE_HELPERS.values()
    for name, _kind, _iterations, _representative in specs
}
PHASE4_RESOURCE_FAMILIES = {
    "extract_resource",
    "extract_civilization_tech_resource",
    "refine_resource",
}
PHASE4_EXPECTED_DISTRIBUTIONS = {
    "economy": {
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
    },
    "current": {
        "extract_base_vdf_4_core": 3,
        "extract_base_vdf_8_core": 6,
        "extract_base_vdf_12_core": 3,
        "extract_direct_body_no_vdf_core": 77,
        "extract_composite_no_vdf_core": 274,
        "refine_resource_no_vdf_core": 324,
    },
}

PHASE5_HELPERS = (
    ("fabricate_component_reusable_vdf_8_core", "component", "reusable", 8, "FabricateStructuralAlloyReusable"),
    ("fabricate_component_final_vdf_8_core", "component", "final", 8, "FabricateStructuralAlloyFinal"),
    ("fabricate_component_reusable_vdf_12_core", "component", "reusable", 12, "FabricateFusionCellReusable"),
    ("fabricate_component_final_vdf_12_core", "component", "final", 12, "FabricateFusionCellFinal"),
    ("fabricate_component_reusable_vdf_32_core", "component", "reusable", 32, "FabricateNeutronArmourReusable"),
    ("fabricate_component_final_vdf_32_core", "component", "final", 32, "FabricateNeutronArmourFinal"),
    ("develop_derived_skill_2_evidence_vdf_8_core", "derived", 2, 8, "DevelopStructuralMetallurgySkill"),
    ("develop_derived_skill_2_evidence_vdf_12_core", "derived", 2, 12, "DevelopPhotonicMaterialsSkill"),
    ("develop_derived_skill_2_evidence_vdf_32_core", "derived", 2, 32, "DevelopDegenerateMatterScienceSkill"),
    ("develop_derived_skill_3_evidence_vdf_8_core", "derived", 3, 8, "DevelopRadiationProtectionSkill"),
    ("develop_derived_skill_3_evidence_vdf_12_core", "derived", 3, 12, "DevelopIntegratedIndustrialSystemsMastery"),
    ("develop_derived_skill_3_evidence_vdf_32_core", "derived", 3, 32, "DevelopProgrammableMatterMastery"),
    ("produce_capability_artifact_1_evidence_vdf_8_core", "artifact", 1, 8, "ForgeReinforcedHullFrame"),
    ("produce_capability_artifact_1_evidence_vdf_12_core", "artifact", 1, 12, "FabricateAdaptiveOptic"),
    ("produce_capability_artifact_1_evidence_vdf_32_core", "artifact", 1, 32, "AssembleDegenerateContainmentCell"),
    ("produce_capability_artifact_2_evidence_vdf_8_core", "artifact", 2, 8, "AssembleHabitatFoundation"),
    ("produce_capability_artifact_2_evidence_vdf_12_core", "artifact", 2, 12, "AssemblePlasmaContainmentRing"),
    ("produce_capability_artifact_2_evidence_vdf_32_core", "artifact", 2, 32, "CompileTradeNetworkCharter"),
    ("produce_capability_artifact_3_evidence_vdf_12_core", "artifact", 3, 12, "AssembleOrbitalFoundryCore"),
    ("produce_capability_artifact_3_evidence_vdf_32_core", "artifact", 3, 32, "SynthesizeProgrammableMatterMatrix"),
)
PHASE5_KNOWN_HELPER_NAMES = {spec[0] for spec in PHASE5_HELPERS}
PHASE5_COMPONENT_ADAPTERS = {
    representative: helper_name
    for helper_name, family, _shape, _iterations, representative in PHASE5_HELPERS
    if family == "component"
}
PHASE5_COMPONENT_PARAMETERS = (
    "action", "next_ship", "component", "ship", "material_1", "material_2",
    "material_3", "catalyst", "skill_type", "material_1_type",
    "material_1_amount", "material_2_type", "material_2_amount",
    "material_3_type", "material_3_amount", "catalyst_type",
    "component_type", "component_amount",
)
PHASE6_MOVE_PARAMETERS = (
    "action", "ship", "current_coordinate", "coordinate_field", "step",
    "extraction_amount", "rare_extraction_amount",
)
PHASE6_EPOCH_PARAMETERS = ("action", "ship", "next_epoch")
PHASE6_VDF_HELPERS = {
    4: "update_ship_work_vdf_4_core",
    12: "update_ship_work_vdf_12_core",
    28: "update_ship_work_vdf_28_core",
}
PHASE6_KNOWN_HELPER_NAMES = {
    "move_positive_core",
    "move_negative_core",
    "advance_ship_epoch_core",
    *PHASE6_VDF_HELPERS.values(),
}
PHASE6_TIER_SPECS = {
    "": (1, 10, 1, 4),
    "Medium": (10, 50, 5, 12),
    "Large": (100, 250, 25, 28),
}
PHASE6_TIMEWARP_SPECS = {
    "Small": (1, 10, 1, 4),
    "Medium": (10, 50, 5, 12),
    "Large": (100, 250, 25, 28),
}
PHASE6_ECONOMY_ROUTES = {
    **{
        f"Move{direction}{axis}{suffix}": (
            (
                f"move_{direction.lower()}_core",
                [
                    "action", "ship", f"ship.{axis.lower()}",
                    f'"{axis.lower()}"', str(step), str(extraction), str(rare),
                ],
            ),
            (f"update_ship_work_vdf_{vdf}_core", ["action", "ship"]),
        )
        for direction in ("Positive", "Negative")
        for axis in ("X", "Y", "Z")
        for suffix, (step, extraction, rare, vdf) in PHASE6_TIER_SPECS.items()
    },
    **{
        f"TimeWarp{suffix}": (
            ("advance_ship_epoch_core", ["action", "ship", "next_epoch"]),
            (f"update_ship_work_vdf_{vdf}_core", ["action", "ship"]),
        )
        for suffix, (_step, _extraction, _rare, vdf)
        in PHASE6_TIMEWARP_SPECS.items()
    },
}
CURRENT_PROFILE_ACTION_COUNT = 1_638
CURRENT_PROFILE_OMITTED_ACTIONS = {
    f"Move{direction}{axis}{tier}"
    for direction in ("Positive", "Negative")
    for axis in ("X", "Y", "Z")
    for tier in ("Medium", "Large")
}
CURRENT_PROFILE_VDF_LITERAL_EXEMPTIONS = {
    "BuildShipSmall": {17},
    "BuildShipMedium": {51},
    "BuildShipLarge": {510},
    "BuildAuxiliaryShipSmall": {34},
    "BuildAuxiliaryShipMedium": {102},
    **{
        f"Move{direction}{axis}": {10, 4, "work"}
        for direction in ("Positive", "Negative")
        for axis in ("X", "Y", "Z")
    },
}
assert sum(
    len(values) for values in CURRENT_PROFILE_VDF_LITERAL_EXEMPTIONS.values()
) == 23
CURRENT_PROFILE_BUILD_VDF_TAILS = {
    "BuildShipSmall": (4, "ship"),
    "BuildShipMedium": (12, "ship"),
    "BuildShipLarge": (28, "ship"),
    "BuildAuxiliaryShipSmall": (8, "child_ship"),
    "BuildAuxiliaryShipMedium": (24, "child_ship"),
}
CURRENT_PROFILE_BASE_MOVES = {
    f"Move{direction}{axis}"
    for direction in ("Positive", "Negative")
    for axis in ("X", "Y", "Z")
}

assert all(
    sum(distribution.values()) == 687
    and set(distribution)
    == {
        name
        for name, _kind, _iterations, _representative
        in PHASE4_PROFILE_HELPERS[profile]
    }
    for profile, distribution in PHASE4_EXPECTED_DISTRIBUTIONS.items()
)
CIVILIZATION_SELECTIONS: tuple[tuple[str, int, int], ...] = (
    ("MaterializeCivilizationTypeI", 1, 64),
    ("MaterializeCivilizationTypeII", 2, 1_024),
    ("MaterializeCivilizationTypeIII", 3, 16_384),
)

EXACT_WARP_SELECTION_SEMANTICS = {
    "mode": EXPLICIT_SELECTION_MODE,
    "selector_source": "action name",
    "stable_identifier_used": False,
    "runtime_modulo": False,
    "runtime_branching": False,
    "runtime_loops": False,
    "catalog_isolation": (
        "v1/v2 use distinct classes; every v2 reveal/use also checks "
        "catalog_version = 2."
    ),
}

RETIRED_WARP_SELECTION_FIELDS = {
    "selector_semantics",
    "selector_policy",
    "stable_identifier_selector",
    "stable_identifier_band",
    "weight_bps",
    "probability_bps",
    "selection_probability",
    "use_rarity_policy",
    "rarity_tier",
    "lower_top_limb",
    "upper_top_limb",
    "lower_literal",
    "upper_literal",
    "source_pool_minimum_inclusive",
    "source_pool_maximum_inclusive",
}

SHAPE_J_SHIP_LIFECYCLE_RULE = (
    "After the target semantic fields and intro_vdf(32) work are finalized, "
    "mutate the Ship in place: preserve stable_identifier, ship_id, and every "
    "other field except reset active_skill_type to 0, increment action_serial "
    "by 1, and rotate the key."
)
SHAPE_J_WARP_CONSTRUCTOR_ROLES: dict[
    str, tuple[tuple[str, str, int], ...]
] = {
    "ConstructWormholeLink": (
        ("output", "MicroverseWormholeLink", 1),
        ("input", "MicroversePositionAnchor", 1),
        ("input", "MicroversePositionAnchor", 2),
        ("input", "MicroverseResource", 1),
        ("input", "MicroverseResource", 2),
        ("mutate", "MicroverseShip", 1),
    ),
    "ConstructTemporalLink": (
        ("output", "MicroverseTemporalLink", 1),
        ("input", "MicroverseTimeAnchor", 1),
        ("input", "MicroverseTimeAnchor", 2),
        ("input", "MicroverseResource", 1),
        ("input", "MicroverseResource", 2),
        ("mutate", "MicroverseShip", 1),
    ),
    "ComposeRendezvousCoordinate": (
        ("output", "MicroverseRendezvousCoordinate", 1),
        ("input", "MicroversePositionAnchor", 1),
        ("input", "MicroverseTimeAnchor", 1),
        ("input", "MicroverseResource", 1),
        ("input", "MicroverseResource", 2),
        ("mutate", "MicroverseShip", 1),
    ),
}

EXPECTED_WARP_OBJECT_SCHEMAS: dict[str, tuple[tuple[str, str], ...]] = {
    "MicroverseWarpCoordinate": (
        ("schema_version", "Int"), ("mechanics_version", "Int"),
        ("universe_version", "Int"), ("source_body_identifier", "Raw"),
        ("source_pool_before", "Int"), ("revealed", "Int"),
        ("destination_code", "Int"), ("destination_x", "Int"),
        ("destination_y", "Int"), ("destination_z", "Int"),
        ("uses_remaining", "Int"), ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    "MicroverseTimeCoordinate": (
        ("schema_version", "Int"), ("mechanics_version", "Int"),
        ("universe_version", "Int"), ("source_body_identifier", "Raw"),
        ("source_pool_before", "Int"), ("revealed", "Int"),
        ("destination_code", "Int"), ("destination_epoch", "Int"),
        ("uses_remaining", "Int"), ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    "MicroverseWarpChart": (
        ("schema_version", "Int"), ("mechanics_version", "Int"),
        ("universe_version", "Int"), ("catalog_version", "Int"),
        ("source_body_identifier", "Raw"), ("source_pool_before", "Int"),
        ("revealed", "Int"), ("destination_code", "Int"),
        ("destination_x", "Int"), ("destination_y", "Int"),
        ("destination_z", "Int"), ("uses_remaining", "Int"),
        ("key", "Raw"), ("stable_identifier", "Raw"),
    ),
    "MicroverseEpochChart": (
        ("schema_version", "Int"), ("mechanics_version", "Int"),
        ("universe_version", "Int"), ("catalog_version", "Int"),
        ("source_body_identifier", "Raw"), ("source_pool_before", "Int"),
        ("revealed", "Int"), ("destination_code", "Int"),
        ("destination_epoch", "Int"), ("uses_remaining", "Int"),
        ("key", "Raw"), ("stable_identifier", "Raw"),
    ),
    "MicroversePositionAnchor": (
        ("schema_version", "Int"), ("mechanics_version", "Int"),
        ("universe_version", "Int"), ("anchor_version", "Int"),
        ("source_ship_id", "Raw"), ("x", "Int"), ("y", "Int"),
        ("z", "Int"), ("uses_remaining", "Int"), ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    "MicroverseTimeAnchor": (
        ("schema_version", "Int"), ("mechanics_version", "Int"),
        ("universe_version", "Int"), ("anchor_version", "Int"),
        ("source_ship_id", "Raw"), ("epoch", "Int"),
        ("uses_remaining", "Int"), ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    "MicroverseWormholeLink": (
        ("schema_version", "Int"), ("mechanics_version", "Int"),
        ("universe_version", "Int"), ("link_version", "Int"),
        ("endpoint_a_anchor_identifier", "Raw"),
        ("endpoint_b_anchor_identifier", "Raw"),
        ("endpoint_a_x", "Int"), ("endpoint_a_y", "Int"),
        ("endpoint_a_z", "Int"), ("endpoint_b_x", "Int"),
        ("endpoint_b_y", "Int"), ("endpoint_b_z", "Int"),
        ("uses_remaining", "Int"), ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    "MicroverseTemporalLink": (
        ("schema_version", "Int"), ("mechanics_version", "Int"),
        ("universe_version", "Int"), ("link_version", "Int"),
        ("endpoint_a_anchor_identifier", "Raw"),
        ("endpoint_b_anchor_identifier", "Raw"),
        ("endpoint_a_epoch", "Int"), ("endpoint_b_epoch", "Int"),
        ("uses_remaining", "Int"), ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    "MicroverseRendezvousCoordinate": (
        ("schema_version", "Int"), ("mechanics_version", "Int"),
        ("universe_version", "Int"), ("coordinate_version", "Int"),
        ("position_anchor_identifier", "Raw"),
        ("time_anchor_identifier", "Raw"),
        ("destination_x", "Int"), ("destination_y", "Int"),
        ("destination_z", "Int"), ("destination_epoch", "Int"),
        ("uses_remaining", "Int"), ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
}


def expected_schema_field_type(field_name: str) -> str:
    return (
        "Raw"
        if field_name == "key"
        or field_name.endswith("_identifier")
        or field_name.endswith("_id")
        else "Int"
    )

CANONICAL_FILES = {
    "resources": "microverse-resource-tree-v2.json",
    "components": "microverse-component-tree-v2.json",
    "skills": "microverse-skill-tree-v2.json",
    "warp": "microverse-warp-tree-v2.json",
    "index": "microverse-catalog-index-v2.json",
}

# Fingerprints cover the exact explicit-action v1 destination mapping and its
# deterministic maximum-capacity minima.  Any change would remap an action or
# alter the eligibility of an already extracted sealed object.
FROZEN_POSITION_V1_SHA256 = (
    "eebc9a926abe6e3c48923fbd7246ce2b36d687ec1e0c1e15fce6655fb988d125"
)
FROZEN_TIME_V1_SHA256 = (
    "14dcb468428ec38daa35c0b9dba05af6ae3f6c78e2844487fb7559f9db852c42"
)

FULL_BODY_NAMES = {
    "Asteroid Belt",
    "Volcanic Planet",
    "Nebula",
    "Comet Cluster",
    "Brown Dwarf",
    "White Dwarf",
    "Magnetar",
    "Wormhole Mouth",
}
BOLD_BODY_NAMES = {
    "Comet Cluster",
    "Brown Dwarf",
    "White Dwarf",
    "Magnetar",
    "Wormhole Mouth",
}

# The existing production universe is needed when an authored resource file
# contains expansion rows only.  Counts are pool-presence counts, not caps.
LEGACY_BODY_COUNT = 15
LEGACY_POOL_PRESENCE = {
    "matter": 14,
    "crystal": 8,
    "gas": 10,
    "energy": 14,
}

EXPECTED_EXPANSION_COUNTS = {
    "full": {
        "bodies": 8,
        "source_resources": 59,
        "composites": 45,
        "terminals": 14,
        "refinement_outputs": 135,
        "refined_resources": 135,
        "resource_types": 194,
    },
    "bold-five": {
        "bodies": 5,
        "source_resources": 38,
        "composites": 28,
        "terminals": 10,
        "refinement_outputs": 84,
        "refined_resources": 84,
        "resource_types": 122,
    },
}

APPROVED_SPLIT_PROFILES = {
    "split_60_30_10": {
        "weights": [600, 300, 100],
        "minimum": 0,
        "outputs": {"Small": [6, 3, 1], "Medium": [30, 15, 5], "Large": [150, 75, 25]},
    },
    "split_70_20_10": {
        "weights": [700, 200, 100],
        "minimum": 0,
        "outputs": {"Small": [7, 2, 1], "Medium": [35, 10, 5], "Large": [175, 50, 25]},
    },
    "split_50_30_20": {
        "weights": [500, 300, 200],
        "minimum": 0,
        "outputs": {"Small": [5, 3, 2], "Medium": [25, 15, 10], "Large": [125, 75, 50]},
    },
    "split_90_08_02": {
        "weights": [900, 80, 20],
        "minimum": 1,
        "outputs": {"Medium": [45, 4, 1], "Large": [225, 20, 5]},
    },
    "split_80_10_10": {
        "weights": [800, 100, 100],
        "minimum": 0,
        "outputs": {"Small": [8, 1, 1], "Medium": [40, 5, 5], "Large": [200, 25, 25]},
    },
}
APPROVED_LEGACY_SPLIT_DISTRIBUTION = {
    "split_60_30_10": 17,
    "split_70_20_10": 15,
    "split_50_30_20": 12,
    "split_90_08_02": 11,
    "split_80_10_10": 8,
}
APPROVED_NEW_SPLIT_DISTRIBUTIONS = {
    "full": {
        "split_60_30_10": 10,
        "split_70_20_10": 8,
        "split_50_30_20": 11,
        "split_90_08_02": 8,
        "split_80_10_10": 8,
    },
    "bold-five": {
        "split_60_30_10": 6,
        "split_70_20_10": 4,
        "split_50_30_20": 6,
        "split_90_08_02": 7,
        "split_80_10_10": 5,
    },
}

ALLOWED_CATALYST_MODES = {"reusable", "final"}
VDF_DIFFICULTY_TIERS = {
    "common": 4,
    "solid": 8,
    "advanced": 12,
    "exotic": 20,
    "artifact": 32,
}
LOGICAL_GATE_FAMILIES = {
    "extraction",
    "extract_resource",
    "extract_civilization_tech_resource",
    "refinement",
    "refine_resource",
    "component",
    "craft_component",
}
RHAI_PLAIN_SDK_PRIMITIVES = {"var_assign"}


def stable_json(value: Any) -> str:
    return json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def canonical_sha256(rows: Any) -> str:
    encoded = json.dumps(
        rows,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def is_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def first_present(mapping: Mapping[str, Any], *names: str) -> Any:
    for name in names:
        if name in mapping:
            return mapping[name]
    return None


def list_value(mapping: Mapping[str, Any], *names: str) -> list[Any]:
    value = first_present(mapping, *names)
    return value if isinstance(value, list) else []


def normalized_name(value: Any) -> str:
    return re.sub(r"[^a-z0-9]+", "", str(value).lower())


def forbidden_key_paths(
    value: Any,
    forbidden: set[str],
    path: str = "",
) -> list[str]:
    """Return deterministic dotted paths for forbidden mapping keys."""
    found: list[str] = []
    if isinstance(value, Mapping):
        for key, child in value.items():
            child_path = f"{path}.{key}" if path else str(key)
            if key in forbidden:
                found.append(child_path)
            found.extend(forbidden_key_paths(child, forbidden, child_path))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            child_path = f"{path}[{index}]"
            found.extend(forbidden_key_paths(child, forbidden, child_path))
    return found


def normalized_pool(value: Any) -> str:
    if is_int(value):
        return {0: "matter", 1: "crystal", 2: "gas", 3: "energy"}.get(
            value, f"unknown:{value}"
        )
    text = str(value).strip().lower()
    return text.removesuffix("_remaining")


def normalized_role(row: Mapping[str, Any]) -> str:
    role = first_present(row, "role", "resource_role")
    if role in (0, "0"):
        return "composite"
    if role in (1, "1"):
        return "terminal"
    if isinstance(role, str):
        text = role.strip().lower().replace("_", "-")
        if text in {"composite", "parent"}:
            return "composite"
        if text in {"terminal", "direct", "data"}:
            return "terminal"
    if row.get("composite") is True:
        return "composite"
    if row.get("composite") is False:
        return "terminal"
    return "unknown"


def as_code(row: Mapping[str, Any], *extra_names: str) -> int | None:
    value = first_present(
        row,
        "code",
        "resource_code",
        "resource_id",
        "component_id",
        "skill_code",
        "skill_id",
        "body_code",
        "body_id",
        *extra_names,
    )
    return value if is_int(value) else None


@dataclass
class Finding:
    severity: str
    code: str
    path: str
    message: str


@dataclass
class Validation:
    findings: list[Finding] = field(default_factory=list)
    check_count: int = 0

    def check(
        self,
        condition: bool,
        code: str,
        message: str,
        path: str = "",
        *,
        warning: bool = False,
    ) -> bool:
        self.check_count += 1
        if not condition:
            self.findings.append(
                Finding("warning" if warning else "error", code, path, message)
            )
        return condition

    def error(self, code: str, message: str, path: str = "") -> None:
        self.check(False, code, message, path)

    def warning(self, code: str, message: str, path: str = "") -> None:
        self.check(False, code, message, path, warning=True)

    @property
    def errors(self) -> list[Finding]:
        return [item for item in self.findings if item.severity == "error"]

    @property
    def warnings(self) -> list[Finding]:
        return [item for item in self.findings if item.severity == "warning"]


def load_json(path: Path, validation: Validation) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        validation.error("file.missing", f"missing canonical catalog: {path}", str(path))
    except json.JSONDecodeError as error:
        validation.error(
            "json.invalid",
            f"invalid JSON at line {error.lineno}, column {error.colno}: {error.msg}",
            str(path),
        )
    except OSError as error:
        validation.error("file.read", str(error), str(path))
    return {}


def validate_catalog_identity(
    catalog: Mapping[str, Any],
    label: str,
    path: Path,
    validation: Validation,
) -> None:
    version = first_present(catalog, "schema_version", "version", "catalog_version")
    validation.check(
        (is_int(version) and version >= 1)
        or (isinstance(version, str) and bool(version.strip())),
        "catalog.version",
        f"{label} catalog must declare a nonempty version",
        str(path),
    )
    identity = first_present(catalog, "catalog_name", "catalog_id", "name")
    validation.check(
        isinstance(identity, str) and bool(identity.strip()),
        "catalog.identity",
        f"{label} catalog must declare catalog_name or catalog_id",
        str(path),
    )


def validate_unique_codes(
    rows: Sequence[Mapping[str, Any]],
    label: str,
    validation: Validation,
    *,
    expected_codes: set[int] | None = None,
    code_names: Sequence[str] = (),
) -> set[int]:
    codes: list[int] = []
    for index, row in enumerate(rows):
        value = first_present(row, *code_names) if code_names else as_code(row)
        validation.check(
            is_int(value),
            "code.type",
            f"{label} row must have an integer code",
            f"{label}[{index}]",
        )
        if is_int(value):
            validation.check(
                value >= 0,
                "code.range",
                f"{label} code must be nonnegative, got {value}",
                f"{label}[{index}]",
            )
            codes.append(value)
    duplicates = sorted(code for code, count in Counter(codes).items() if count > 1)
    validation.check(
        not duplicates,
        "code.duplicate",
        f"duplicate {label} codes: {duplicates}",
        label,
    )
    result = set(codes)
    if expected_codes is not None:
        validation.check(
            result == expected_codes,
            "code.exact_set",
            f"{label} codes must be {min(expected_codes)}..{max(expected_codes)}; "
            f"missing={sorted(expected_codes - result)}, extra={sorted(result - expected_codes)}",
            label,
        )
    return result


def declared_count(catalog: Mapping[str, Any], *names: str) -> int | None:
    counts = catalog.get("counts")
    if not isinstance(counts, Mapping):
        return None
    value = first_present(counts, *names)
    return value if is_int(value) else None


def check_declared_count(
    catalog: Mapping[str, Any],
    actual: int,
    validation: Validation,
    path: str,
    *names: str,
) -> None:
    expected = declared_count(catalog, *names)
    validation.check(
        expected is not None,
        "count.declared",
        f"counts must declare one of {names}",
        path,
    )
    if expected is not None:
        validation.check(
            expected == actual,
            "count.mismatch",
            f"declared {names[0]}={expected}, actual={actual}",
            path,
        )


def body_reserves(
    body: Mapping[str, Any],
    reserve_rows: Sequence[Mapping[str, Any]],
) -> dict[str, int]:
    body_code = as_code(body)
    nested = body.get("reserves")
    result: dict[str, int] = {}
    if isinstance(nested, Mapping):
        for pool, cap in nested.items():
            if is_int(cap):
                result[normalized_pool(pool)] = cap
    elif isinstance(nested, list):
        for row in nested:
            if isinstance(row, Mapping):
                cap = first_present(row, "cap", "capacity", "amount")
                if is_int(cap):
                    result[normalized_pool(first_present(row, "pool", "pool_id", "name"))] = cap
    for pool in ("matter", "crystal", "gas", "energy"):
        cap = first_present(body, pool, f"{pool}_cap", f"{pool}_reserve")
        if is_int(cap):
            result[pool] = cap
    for row in reserve_rows:
        if not isinstance(row, Mapping):
            continue
        row_body = first_present(row, "body_code", "body_id")
        if body_code is not None and row_body == body_code:
            cap = first_present(row, "cap", "capacity", "amount")
            if is_int(cap):
                result[normalized_pool(first_present(row, "pool", "pool_id", "name"))] = cap
    return result


def infer_resource_profile(body_names: set[str]) -> str | None:
    if body_names == FULL_BODY_NAMES:
        return "full"
    if body_names == BOLD_BODY_NAMES:
        return "bold-five"
    return None


def capacity_tiers(catalog: Mapping[str, Any]) -> dict[int, int]:
    rows = list_value(catalog, "capacity_tiers", "ship_tiers", "extraction_tiers")
    result: dict[int, int] = {}
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        tier = first_present(row, "tier_id", "tier", "capacity_tier")
        amount = first_present(
            row,
            "extraction_amount",
            "amount",
            "extraction_capacity",
            "min_extraction_capacity",
        )
        if is_int(tier) and is_int(amount) and amount > 0:
            result[tier] = amount
    return result


def allocation_weight(child: Mapping[str, Any]) -> tuple[int, int] | None:
    if is_int(child.get("allocation_per_1000")):
        return child["allocation_per_1000"], 1000
    if is_int(child.get("weight_bps")):
        return child["weight_bps"], 10_000
    value = first_present(child, "pct", "percent", "allocation_pct")
    if is_int(value):
        return value, 100
    return None


def explicit_allocation(
    child: Mapping[str, Any], tier: int
) -> int | None:
    mapping = first_present(child, "amounts_by_tier", "allocations_by_tier")
    if isinstance(mapping, Mapping):
        value = first_present(mapping, str(tier), tier)  # type: ignore[arg-type]
        return value if is_int(value) else None
    rows = child.get("tier_allocations")
    if isinstance(rows, list):
        for row in rows:
            if not isinstance(row, Mapping):
                continue
            row_tier = first_present(row, "tier", "tier_id", "capacity_tier")
            value = first_present(row, "amount", "units")
            if row_tier == tier and is_int(value):
                return value
    return None


def validate_integer_conservation(
    parents: Sequence[Mapping[str, Any]],
    extraction_routes: Sequence[Mapping[str, Any]],
    tiers: Mapping[int, int],
    validation: Validation,
) -> None:
    route_minimums: dict[int, list[int]] = defaultdict(list)
    for route in extraction_routes:
        if not isinstance(route, Mapping):
            continue
        resource_code = first_present(
            route, "resource_code", "resource_id", "parent_code", "parent_id"
        )
        minimum = first_present(
            route, "min_capacity_tier", "minimum_ship_tier", "min_tier"
        )
        if is_int(resource_code) and is_int(minimum):
            route_minimums[resource_code].append(minimum)

    validation.check(
        bool(tiers),
        "tiers.missing",
        "resource catalog must declare capacity tiers with extraction amounts",
        "resources.capacity_tiers",
    )
    if not tiers:
        return
    max_tier = max(tiers)
    for parent_index, parent in enumerate(parents):
        parent_code = first_present(
            parent, "code", "resource_code", "resource_id", "parent_code", "parent_id"
        )
        children = list_value(parent, "children", "outputs", "refine_outputs")
        if not is_int(parent_code) or len(children) != 3:
            continue
        minimums = route_minimums.get(parent_code, [])
        validation.check(
            bool(minimums),
            "refinement.unreachable_parent",
            f"composite {parent_code} has no extraction route",
            f"refinement_parents[{parent_index}]",
        )
        if not minimums:
            continue
        reachable = sorted(
            tier
            for tier in tiers
            if any(minimum <= tier <= max_tier for minimum in minimums)
        )
        for tier in reachable:
            extraction_amount = tiers[tier]
            amounts: list[int] = []
            for child_index, child in enumerate(children):
                if not isinstance(child, Mapping):
                    continue
                explicit = explicit_allocation(child, tier)
                if explicit is not None:
                    validation.check(
                        explicit >= 0,
                        "allocation.negative",
                        f"tier {tier} allocation must be nonnegative",
                        f"refinement_parents[{parent_index}].children[{child_index}]",
                    )
                    amounts.append(explicit)
                    continue
                weight = allocation_weight(child)
                validation.check(
                    weight is not None,
                    "allocation.missing",
                    f"child requires a percent/weight or explicit tier amount",
                    f"refinement_parents[{parent_index}].children[{child_index}]",
                )
                if weight is None:
                    continue
                numerator, denominator = weight
                product = extraction_amount * numerator
                validation.check(
                    product % denominator == 0,
                    "allocation.non_integer",
                    f"composite {parent_code}, extraction tier {tier} amount "
                    f"{extraction_amount}, weight {numerator}/{denominator} is non-integral",
                    f"refinement_parents[{parent_index}].children[{child_index}]",
                )
                if product % denominator == 0:
                    amounts.append(product // denominator)
            validation.check(
                len(amounts) == 3 and sum(amounts) == extraction_amount,
                "allocation.conservation",
                f"composite {parent_code}, tier {tier}: children {amounts} must sum "
                f"exactly to extraction amount {extraction_amount}",
                f"refinement_parents[{parent_index}]",
            )


def flat_refinement_parents(
    sources: Sequence[Mapping[str, Any]],
    refined: Sequence[Mapping[str, Any]],
    catalog: Mapping[str, Any],
) -> list[dict[str, Any]]:
    """Adapt the canonical flat v2 resource rows to the generic parent shape."""

    tier_names: dict[int, str] = {}
    for row in list_value(catalog, "capacity_tiers", "ship_tiers", "extraction_tiers"):
        if not isinstance(row, Mapping):
            continue
        tier = first_present(row, "tier_id", "tier", "capacity_tier")
        name = first_present(row, "name", "tier_name")
        if is_int(tier) and isinstance(name, str):
            tier_names[tier] = name

    children_by_parent: dict[int, list[dict[str, Any]]] = defaultdict(list)
    for row in refined:
        parent_code = first_present(row, "parent_resource_id", "parent_resource_code")
        if not is_int(parent_code):
            continue
        child = dict(row)
        produced = row.get("produced_amounts")
        if isinstance(produced, Mapping):
            child["amounts_by_tier"] = {
                str(tier): produced[name]
                for tier, name in tier_names.items()
                if is_int(produced.get(name))
            }
        children_by_parent[parent_code].append(child)

    result: list[dict[str, Any]] = []
    for source in sources:
        if normalized_role(source) != "composite":
            continue
        parent_code = first_present(source, "resource_id", "resource_code", "code")
        if not is_int(parent_code):
            continue
        parent = dict(source)
        parent["children"] = sorted(
            children_by_parent.get(parent_code, []),
            key=lambda row: first_present(row, "slot", "child_slot") or 0,
        )
        result.append(parent)
    return result


def validate_resource_catalog(
    catalog: Mapping[str, Any], path: Path, validation: Validation
) -> dict[str, Any]:
    validate_catalog_identity(catalog, "resource", path, validation)
    validation.check(
        catalog.get("schema_version") == 2
        and catalog.get("catalog_id") == "microverse-resource-tree-v2"
        and catalog.get("catalog_version") == "microverse-resource-tree-v2",
        "resource.catalog_header",
        "resource catalog must use the canonical v2 schema/id/version",
        "resources",
    )
    validation.check(
        catalog.get("versions")
        == {
            "resource_catalog_version": 2,
            "body_bank_version": 2,
            "skill_catalog_version": 2,
            "split_profile_version": 2,
        },
        "resource.version_contract",
        "resource catalog must bind the exact four-part v2 version vector",
        "resources.versions",
    )
    bodies = [row for row in list_value(catalog, "bodies") if isinstance(row, Mapping)]
    reserves = [row for row in list_value(catalog, "reserves") if isinstance(row, Mapping)]
    sources = [
        row
        for row in list_value(catalog, "source_resources", "resources")
        if isinstance(row, Mapping)
    ]
    routes = [
        row
        for row in list_value(catalog, "extraction_routes")
        if isinstance(row, Mapping)
    ]
    refined = [
        row
        for row in list_value(catalog, "refined_resources")
        if isinstance(row, Mapping)
    ]
    parents = [
        row
        for row in list_value(catalog, "refinement_parents")
        if isinstance(row, Mapping)
    ]
    if not parents and refined:
        parents = flat_refinement_parents(sources, refined, catalog)

    body_codes = validate_unique_codes(
        bodies, "bodies", validation, code_names=("code", "body_code", "body_id")
    )
    body_names = {str(row.get("name", "")) for row in bodies}
    profile = infer_resource_profile(body_names)
    validation.check(
        profile is not None,
        "body.exact_set",
        "body names must be exactly the Full Eight or Bold Five set; "
        f"got {sorted(body_names)}",
        "resources.bodies",
    )
    if profile is not None:
        expected_body_codes = set(range(15, 23)) if profile == "full" else set(range(18, 23))
        validation.check(
            body_codes == expected_body_codes,
            "body.code_reservation",
            f"{profile} body codes must be {sorted(expected_body_codes)}; got {sorted(body_codes)}",
            "resources.bodies",
        )

    pool_presence = dict(LEGACY_POOL_PRESENCE)
    for index, body in enumerate(bodies):
        body_id = first_present(body, "body_id", "body_code", "code")
        validation.check(
            body.get("candidate_code") == body_id,
            "body.candidate_identity",
            f"body {body_id!r} candidate_code must be identical to its body ID",
            f"resources.bodies[{index}]",
        )
        exponent = first_present(
            body,
            "occurrence_exponent",
            "scan_exponent",
            "exponent",
            "rarity_exponent",
        )
        validation.check(
            is_int(exponent) and 3 <= exponent <= 15,
            "body.occurrence_exponent",
            f"occurrence_exponent must be in 3..15, got {exponent!r}",
            f"resources.bodies[{index}]",
        )
        denominator = body.get("nominal_denominator")
        target = body.get("target_top_limb")
        if is_int(exponent):
            validation.check(
                denominator == 2**exponent,
                "body.nominal_denominator",
                f"nominal_denominator must equal 2^occurrence_exponent, got {denominator!r}",
                f"resources.bodies[{index}]",
            )
            validation.check(
                target == 2 ** (64 - exponent),
                "body.target_top_limb",
                f"target_top_limb must equal 2^(64-occurrence_exponent), got {target!r}",
                f"resources.bodies[{index}]",
            )
        validation.check(
            body.get("scan_threshold_subject")
            == "MicroverseCelestialSignal stable identifier"
            and body.get("scan_acceptance_comparison")
            == "fixed lower <= stable_identifier <= fixed upper"
            and body.get("scan_selector")
            == DETERMINISTIC_SELECTOR_MODE,
            "body.scan_threshold_semantics",
            "body Scan eligibility must use the deterministic stable-ID band",
            f"resources.bodies[{index}]",
        )
        movement = first_present(body, "min_movement", "minimum_movement")
        validation.check(
            movement is None,
            "body.unenforced_min_movement",
            "body min_movement must be omitted because production does not enforce it",
            f"resources.bodies[{index}]",
        )
        caps = body_reserves(body, reserves)
        validation.check(
            set(caps) == {"matter", "crystal", "gas", "energy"},
            "reserve.pool_rows",
            f"body must declare all four pools (zero allowed), got {caps}",
            f"resources.bodies[{index}]",
        )
        for pool, cap in caps.items():
            validation.check(
                is_int(cap) and cap >= 0,
                "reserve.cap",
                f"{pool} cap must be nonnegative integer, got {cap!r}",
                f"resources.bodies[{index}]",
            )
            if is_int(cap) and cap > 0:
                pool_presence[pool] += 1
        if is_int(exponent) and len(caps) == 4 and all(is_int(cap) for cap in caps.values()):
            expected_total = 24_000 + 2_000 * exponent
            validation.check(
                sum(caps.values()) == expected_total,
                "reserve.curve",
                f"reserve total {sum(caps.values())} must equal {expected_total} "
                f"for exponent {exponent}",
                f"resources.bodies[{index}]",
            )
        if body.get("name") == "Wormhole Mouth":
            validation.check(
                caps
                == {
                    "matter": 6_000,
                    "crystal": 6_000,
                    "gas": 0,
                    "energy": 40_000,
                },
                "reserve.wormhole_contract",
                "Wormhole Mouth reserves must be 6000/6000/0/40000",
                f"resources.bodies[{index}]",
            )

    total_bodies = LEGACY_BODY_COUNT + len(bodies)
    for pool, count in sorted(pool_presence.items()):
        validation.check(
            count * 100 >= 40 * total_bodies,
            "reserve.pool_coverage",
            f"{pool} appears on {count}/{total_bodies} bodies, below 40%",
            "resources.bodies",
        )

    source_codes = validate_unique_codes(
        sources,
        "source_resources",
        validation,
        code_names=("code", "resource_code", "resource_id"),
    )
    if profile == "full":
        validation.check(
            source_codes == set(range(435, 494)),
            "resource.source_code_reservation",
            "Full Eight source resource codes must be exactly 435..493",
            "resources.source_resources",
        )
    roles = Counter(normalized_role(row) for row in sources)
    validation.check(
        roles.get("unknown", 0) == 0,
        "resource.role",
        f"every source resource must be composite or terminal; role counts={dict(roles)}",
        "resources.source_resources",
    )
    for index, resource in enumerate(sources):
        tier = first_present(resource, "tier", "resource_tier")
        validation.check(
            tier in (1, "1", "primary", "tier-1"),
            "resource.source_tier",
            f"source resource must be tier 1, got {tier!r}",
            f"resources.source_resources[{index}]",
        )
        skill = first_present(resource, "extraction_skill_id", "skill_code", "skill_id")
        validation.check(
            is_int(skill) and 1 <= skill <= 18,
            "resource.extraction_skill",
            f"extraction skill must reference root skill 1..18, got {skill!r}",
            f"resources.source_resources[{index}]",
        )
        route_key = resource.get("route_key")
        validation.check(
            isinstance(route_key, str) and bool(route_key.strip()),
            "resource.route_key",
            "source resource must declare a nonempty route_key",
            f"resources.source_resources[{index}]",
        )
        body_code = first_present(resource, "body_code", "body_id")
        validation.check(
            body_code in body_codes,
            "resource.body_reference",
            f"source resource body {body_code!r} is not in the expansion body table",
            f"resources.source_resources[{index}]",
        )
        validation.check(
            normalized_pool(first_present(resource, "pool", "pool_id"))
            in {"matter", "crystal", "gas", "energy"},
            "resource.pool_reference",
            "source resource must reference one of four reserve pools",
            f"resources.source_resources[{index}]",
        )
        minimum = first_present(
            resource, "min_capacity_tier", "minimum_ship_tier", "min_tier"
        )
        validation.check(
            minimum in (0, 1, 2),
            "resource.min_capacity_tier",
            f"min_capacity_tier must be 0, 1, or 2, got {minimum!r}",
            f"resources.source_resources[{index}]",
        )
        vdf_tier = resource.get("vdf_tier")
        validation.check(
            vdf_tier in VDF_DIFFICULTY_TIERS
            and resource.get("vdf_iterations") == VDF_DIFFICULTY_TIERS.get(vdf_tier),
            "resource.vdf_tier",
            f"source VDF tier/iterations mismatch: {vdf_tier!r}/{resource.get('vdf_iterations')!r}",
            f"resources.source_resources[{index}]",
        )
        if normalized_role(resource) == "composite":
            refinement_vdf_tier = resource.get("refinement_vdf_tier")
            validation.check(
                refinement_vdf_tier in VDF_DIFFICULTY_TIERS
                and resource.get("refinement_vdf_iterations")
                == VDF_DIFFICULTY_TIERS.get(refinement_vdf_tier),
                "refinement.vdf_tier",
                "composite refinement VDF tier/iterations must match the fixed tier policy",
                f"resources.source_resources[{index}]",
            )

    source_route_keys = [row.get("route_key") for row in sources]
    validation.check(
        len(source_route_keys) == len(set(source_route_keys)),
        "resource.route_key_unique",
        "source resource route_key values must be unique",
        "resources.source_resources",
    )

    source_ids_by_body: dict[int, set[int]] = defaultdict(set)
    for source in sources:
        body_id = first_present(source, "body_id", "body_code")
        resource_id = first_present(source, "resource_id", "resource_code", "code")
        if is_int(body_id) and is_int(resource_id):
            source_ids_by_body[body_id].add(resource_id)
    for body_index, body in enumerate(bodies):
        body_id = first_present(body, "body_id", "body_code", "code")
        authored_ids = body.get("source_resource_ids")
        validation.check(
            isinstance(authored_ids, list)
            and all(is_int(code) for code in authored_ids)
            and set(authored_ids) == source_ids_by_body.get(body_id, set()),
            "body.source_resource_ids",
            f"body {body_id} source_resource_ids must exactly match its source rows",
            f"resources.bodies[{body_index}]",
        )

    parent_codes = validate_unique_codes(
        parents,
        "refinement_parents",
        validation,
        code_names=("code", "resource_code", "resource_id", "parent_code", "parent_id"),
    )
    composite_codes = {
        first_present(row, "code", "resource_code", "resource_id")
        for row in sources
        if normalized_role(row) == "composite"
    }
    validation.check(
        parent_codes == composite_codes,
        "refinement.parent_set",
        f"refinement parent codes must exactly match composite source codes; "
        f"missing={sorted(composite_codes-parent_codes)}, extra={sorted(parent_codes-composite_codes)}",
        "resources.refinement_parents",
    )

    child_codes: list[int] = []
    for parent_index, parent in enumerate(parents):
        children = list_value(parent, "children", "outputs", "refine_outputs")
        validation.check(
            len(children) == 3,
            "refinement.child_count",
            f"parent must have exactly three children, got {len(children)}",
            f"resources.refinement_parents[{parent_index}]",
        )
        slots: list[int] = []
        denominators: set[int] = set()
        weights: list[int] = []
        for child_index, child in enumerate(children):
            if not isinstance(child, Mapping):
                validation.error(
                    "refinement.child_shape",
                    "child row must be an object",
                    f"resources.refinement_parents[{parent_index}].children[{child_index}]",
                )
                continue
            slot = first_present(child, "slot", "child_slot")
            if is_int(slot):
                slots.append(slot)
            code = first_present(child, "code", "resource_code", "resource_id", "output_code", "output_id")
            if is_int(code):
                child_codes.append(code)
            else:
                validation.error(
                    "refinement.child_code",
                    "refinement child must have an integer output code",
                    f"resources.refinement_parents[{parent_index}].children[{child_index}]",
                )
            weight = allocation_weight(child)
            if weight is not None:
                weights.append(weight[0])
                denominators.add(weight[1])
        validation.check(
            set(slots) in ({0, 1, 2}, {1, 2, 3}),
            "refinement.slots",
            f"child slots must be exactly 0..2 or 1..3, got {slots}",
            f"resources.refinement_parents[{parent_index}]",
        )
        if len(weights) == 3:
            validation.check(
                len(denominators) == 1 and sum(weights) == next(iter(denominators)),
                "refinement.weight_sum",
                f"three allocation weights must use one denominator and sum to it; "
                f"weights={weights}, denominators={sorted(denominators)}",
                f"resources.refinement_parents[{parent_index}]",
            )

    child_duplicates = sorted(code for code, count in Counter(child_codes).items() if count > 1)
    validation.check(
        not child_duplicates,
        "refinement.child_code_duplicate",
        f"refined output codes must be unique; duplicates={child_duplicates}",
        "resources.refinement_parents",
    )
    validation.check(
        source_codes.isdisjoint(child_codes),
        "resource.code_namespace",
        f"source and refined codes overlap: {sorted(source_codes & set(child_codes))}",
        "resources",
    )
    if profile == "full":
        validation.check(
            set(child_codes) == set(range(494, 629)),
            "resource.refined_code_reservation",
            "Full Eight refined resource codes must be exactly 494..628",
            "resources.refined_resources",
        )

    if refined:
        source_by_code = {
            first_present(row, "resource_id", "resource_code", "code"): row
            for row in sources
        }
        tier_rows = [
            row
            for row in list_value(catalog, "capacity_tiers")
            if isinstance(row, Mapping)
        ]
        refined_route_keys: list[Any] = []
        for index, row in enumerate(refined):
            prefix = f"resources.refined_resources[{index}]"
            code = first_present(row, "resource_id", "resource_code", "code")
            parent_code = first_present(row, "parent_resource_id", "parent_resource_code")
            parent = source_by_code.get(parent_code)
            validation.check(
                isinstance(parent, Mapping) and normalized_role(parent) == "composite",
                "refinement.parent_reference",
                f"refined resource {code} parent {parent_code!r} must be a composite source",
                prefix,
            )
            if isinstance(parent, Mapping):
                validation.check(
                    first_present(row, "body_id", "body_code")
                    == first_present(parent, "body_id", "body_code"),
                    "refinement.body_reference",
                    f"refined resource {code} must inherit body from parent {parent_code}",
                    prefix,
                )
            skill = first_present(row, "refinement_skill_id", "skill_code", "skill_id")
            validation.check(
                is_int(skill) and 1 <= skill <= 18,
                "refinement.skill",
                f"refinement skill must reference root skill 1..18, got {skill!r}",
                prefix,
            )
            validation.check(
                first_present(row, "tier", "resource_tier") in (2, "2", "refined", "tier-2"),
                "refinement.tier",
                f"refined resource {code} must be tier 2",
                prefix,
            )
            route_key = row.get("route_key")
            refined_route_keys.append(route_key)
            validation.check(
                isinstance(route_key, str) and bool(route_key.strip()),
                "refinement.route_key",
                "refined resource must declare a nonempty route_key",
                prefix,
            )
            produced = row.get("produced_amounts")
            validation.check(
                isinstance(produced, Mapping) and bool(produced),
                "refinement.produced_amounts",
                "refined resource must declare exact produced_amounts",
                prefix,
            )
            if isinstance(produced, Mapping) and produced:
                values = [value for value in produced.values() if is_int(value)]
                validation.check(
                    len(values) == len(produced) and min(values) > 0,
                    "refinement.produced_amount_values",
                    "every produced amount must be a positive integer",
                    prefix,
                )
                validation.check(
                    row.get("minimum_reachable_amount") == min(values),
                    "refinement.minimum_reachable_amount",
                    "minimum_reachable_amount must equal the least produced amount",
                    prefix,
                )
                if isinstance(parent, Mapping):
                    minimum_tier = parent.get("min_capacity_tier")
                    allocation = row.get("allocation_per_1000")
                    expected_produced: dict[str, int] = {}
                    if is_int(minimum_tier) and is_int(allocation):
                        for tier_row in tier_rows:
                            tier_id = tier_row.get("tier_id")
                            tier_name = tier_row.get("name")
                            extraction_amount = tier_row.get("extraction_amount")
                            if (
                                is_int(tier_id)
                                and tier_id >= minimum_tier
                                and isinstance(tier_name, str)
                                and is_int(extraction_amount)
                            ):
                                product = extraction_amount * allocation
                                validation.check(
                                    product % 1000 == 0,
                                    "refinement.flat_non_integer",
                                    f"{extraction_amount} * {allocation}/1000 must be integral",
                                    prefix,
                                )
                                if product % 1000 == 0:
                                    expected_produced[tier_name] = product // 1000
                    validation.check(
                        dict(produced) == expected_produced,
                        "refinement.produced_amount_exact",
                        f"produced_amounts {dict(produced)} must exactly equal {expected_produced}",
                        prefix,
                    )
        validation.check(
            len(refined_route_keys) == len(set(refined_route_keys)),
            "refinement.route_key_unique",
            "refined resource route_key values must be unique",
            "resources.refined_resources",
        )
        nested_children = {
            first_present(child, "resource_id", "resource_code", "code"): child
            for parent in parents
            for child in list_value(parent, "children", "outputs", "refine_outputs")
            if isinstance(child, Mapping)
        }
        for index, row in enumerate(refined):
            code = first_present(row, "resource_id", "resource_code", "code")
            nested = nested_children.get(code)
            validation.check(
                isinstance(nested, Mapping)
                and all(
                    nested.get(field) == row.get(field)
                    for field in (
                        "name",
                        "slot",
                        "allocation_per_1000",
                        "refinement_skill_id",
                        "route_key",
                    )
                ),
                "refinement.nested_flat_consistency",
                f"nested and flat refined definitions must match for resource {code}",
                f"resources.refined_resources[{index}]",
            )

    split_profiles = [
        row for row in list_value(catalog, "split_profiles") if isinstance(row, Mapping)
    ]
    validation.check(
        len(split_profiles) == 5,
        "split_profile.exact_count",
        f"expected exactly five split profiles, got {len(split_profiles)}",
        "resources.split_profiles",
    )
    split_by_id: dict[str, Mapping[str, Any]] = {}
    for index, row in enumerate(split_profiles):
        split_id = row.get("split_profile_id")
        weights = row.get("child_allocations_per_1000")
        validation.check(
            isinstance(split_id, str) and split_id not in split_by_id,
            "split_profile.id",
            "split_profile_id must be a unique string",
            f"resources.split_profiles[{index}]",
        )
        if isinstance(split_id, str):
            split_by_id[split_id] = row
        validation.check(
            isinstance(weights, list)
            and len(weights) == 3
            and all(is_int(value) and value > 0 for value in weights)
            and sum(weights) == 1000,
            "split_profile.weights",
            f"split profile must contain three positive per-1000 weights summing to 1000, got {weights!r}",
            f"resources.split_profiles[{index}]",
        )
        approved = APPROVED_SPLIT_PROFILES.get(str(split_id))
        validation.check(
            approved is not None
            and weights == approved["weights"]
            and row.get("minimum_capacity_tier") == approved["minimum"]
            and row.get("tier_output_amounts") == approved["outputs"],
            "split_profile.approved_contract",
            f"split profile {split_id!r} differs from the approved integer-safe policy",
            f"resources.split_profiles[{index}]",
        )
    validation.check(
        set(split_by_id) == set(APPROVED_SPLIT_PROFILES),
        "split_profile.approved_set",
        "split profile IDs must exactly match the five approved policies",
        "resources.split_profiles",
    )
    for index, source in enumerate(sources):
        child_ids = source.get("child_resource_ids")
        if normalized_role(source) == "composite":
            split_id = source.get("split_profile_id")
            validation.check(
                split_id in split_by_id,
                "resource.split_profile_reference",
                f"composite source references unknown split profile {split_id!r}",
                f"resources.source_resources[{index}]",
            )
            authored = child_ids if isinstance(child_ids, list) else []
            actual_children = {
                first_present(row, "resource_id", "resource_code", "code")
                for row in refined
                if first_present(row, "parent_resource_id", "parent_resource_code")
                == first_present(source, "resource_id", "resource_code", "code")
            }
            validation.check(
                len(authored) == 3 and set(authored) == actual_children,
                "resource.child_resource_ids",
                "composite child_resource_ids must name exactly its three refined rows",
                f"resources.source_resources[{index}]",
            )
        else:
            validation.check(
                child_ids == [],
                "resource.terminal_children",
                "terminal source must declare an empty child_resource_ids list",
                f"resources.source_resources[{index}]",
            )

    legacy_splits = [
        row for row in list_value(catalog, "legacy_parent_splits") if isinstance(row, Mapping)
    ]
    validation.check(
        len(legacy_splits) == 63,
        "legacy_split.exact_count",
        f"expected exactly 63 explicit legacy split rows, got {len(legacy_splits)}",
        "resources.legacy_parent_splits",
    )
    legacy_parent_ids: list[Any] = []
    legacy_distribution: Counter[str] = Counter()
    for index, row in enumerate(legacy_splits):
        parent_id = row.get("parent_resource_id")
        legacy_parent_ids.append(parent_id)
        split_id = row.get("split_profile_id")
        if isinstance(split_id, str):
            legacy_distribution[split_id] += 1
        profile_row = split_by_id.get(str(split_id))
        validation.check(
            is_int(parent_id) and split_id in split_by_id,
            "legacy_split.reference",
            "legacy split must reference an integer parent and known split profile",
            f"resources.legacy_parent_splits[{index}]",
        )
        if profile_row is not None:
            validation.check(
                row.get("child_allocations_per_1000")
                == profile_row.get("child_allocations_per_1000"),
                "legacy_split.weights",
                "legacy split weights must exactly match its referenced profile",
                f"resources.legacy_parent_splits[{index}]",
            )
    validation.check(
        len(legacy_parent_ids) == len(set(legacy_parent_ids)),
        "legacy_split.parent_unique",
        "legacy parent split rows must be unique by parent_resource_id",
        "resources.legacy_parent_splits",
    )
    declared_distribution = catalog.get("legacy_parent_split_distribution")
    validation.check(
        isinstance(declared_distribution, Mapping)
        and dict(legacy_distribution) == dict(declared_distribution)
        and dict(legacy_distribution) == APPROVED_LEGACY_SPLIT_DISTRIBUTION,
        "legacy_split.distribution",
        f"legacy split distribution {dict(legacy_distribution)} does not match the approved policy",
        "resources.legacy_parent_split_distribution",
    )
    new_distribution = Counter(
        str(row.get("split_profile_id"))
        for row in sources
        if normalized_role(row) == "composite"
    )
    declared_new_distribution = catalog.get("new_parent_split_distribution")
    validation.check(
        isinstance(declared_new_distribution, Mapping)
        and dict(new_distribution) == dict(declared_new_distribution),
        "split_profile.new_distribution",
        f"new parent split distribution {dict(new_distribution)} does not match declaration",
        "resources.new_parent_split_distribution",
    )
    if profile is not None:
        validation.check(
            dict(new_distribution) == APPROVED_NEW_SPLIT_DISTRIBUTIONS[profile],
            "split_profile.approved_new_distribution",
            f"{profile} new-parent split distribution differs from the approved policy: "
            f"{dict(new_distribution)}",
            "resources.new_parent_split_distribution",
        )

    if not routes:
        # The compact nested shape places route fields on each source row.
        routes = list(sources)
    validate_integer_conservation(
        parents,
        routes,
        capacity_tiers(catalog),
        validation,
    )

    if profile is not None:
        expected = EXPECTED_EXPANSION_COUNTS[profile]
        actual = {
            "bodies": len(bodies),
            "source_resources": len(sources),
            "composites": roles.get("composite", 0),
            "terminals": roles.get("terminal", 0),
            "refinement_outputs": len(child_codes),
            "refined_resources": len(set(child_codes)),
            "resource_types": len(source_codes) + len(set(child_codes)),
        }
        for key, expected_value in expected.items():
            validation.check(
                actual[key] == expected_value,
                "resource.exact_count",
                f"{profile} {key}: expected {expected_value}, got {actual[key]}",
                "resources",
            )
            count_aliases = {
                "bodies": ("bodies", "new_body_count"),
                "source_resources": ("source_resources", "new_source_resource_count"),
                "composites": ("composites", "new_composite_count"),
                "terminals": ("terminals", "new_terminal_count"),
                "refinement_outputs": ("refinement_outputs", "new_refined_resource_count"),
                "refined_resources": ("refined_resources", "new_refined_resource_count"),
                "resource_types": ("resource_types", "new_typed_resource_count"),
            }
            declared = declared_count(catalog, *count_aliases[key])
            if declared is not None:
                validation.check(
                    declared == actual[key],
                    "resource.declared_count",
                    f"declared {key}={declared}, actual={actual[key]}",
                    "resources.counts",
                )

    return {
        "profile": profile,
        "bodies": bodies,
        "body_codes": body_codes,
        "sources": sources,
        "source_codes": source_codes,
        "terminal_codes": {
            first_present(row, "code", "resource_code", "resource_id")
            for row in sources
            if normalized_role(row) == "terminal"
        },
        "parents": parents,
        "refined": refined,
        "child_codes": set(child_codes),
        "tiers": capacity_tiers(catalog),
    }


def flatten_index_resources(index: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    rows = list_value(index, "resource_code_rows", "resources", "resource_types")
    if rows:
        return [
            {
                **row,
                "resource_code": first_present(row, "resource_code", "code"),
            }
            for row in rows
            if isinstance(row, Mapping)
        ]
    code_map = index.get("resource_codes")
    if isinstance(code_map, Mapping):
        return [
            {"name": name, "resource_code": code}
            for name, code in code_map.items()
            if is_int(code)
        ]
    catalog = index.get("catalog")
    if isinstance(catalog, Mapping):
        return [
            row
            for row in list_value(catalog, "resources", "resource_types")
            if isinstance(row, Mapping)
        ]
    return []


def production_rows(index: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    direct = list_value(index, "production", "resource_production", "provenance")
    if isinstance(index.get("production"), Mapping):
        result: list[Mapping[str, Any]] = []
        for code, rows in index["production"].items():
            if isinstance(rows, list):
                for row in rows:
                    if isinstance(row, Mapping):
                        result.append({"resource_code": int(code), **row})
        return result
    return [row for row in direct if isinstance(row, Mapping)]


def action_rows(index: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    return [row for row in list_value(index, "actions") if isinstance(row, Mapping)]


def validate_component_catalog(
    catalog: Mapping[str, Any],
    path: Path,
    validation: Validation,
    resource_state: Mapping[str, Any],
    index: Mapping[str, Any],
) -> dict[str, Any]:
    validate_catalog_identity(catalog, "component", path, validation)
    validation.check(
        catalog.get("schema_version") == 2
        and catalog.get("catalog_name") == "microverse-component-tree-v2",
        "component.catalog_header",
        "component catalog must use the canonical v2 schema/name",
        "components",
    )
    components = [
        row for row in list_value(catalog, "components") if isinstance(row, Mapping)
    ]
    validate_unique_codes(
        components,
        "components",
        validation,
        expected_codes=set(range(390, 435)),
        code_names=("code", "component_id", "resource_code"),
    )
    validation.check(
        len(components) == 45,
        "component.exact_count",
        f"expected exactly 45 components, got {len(components)}",
        "components",
    )
    check_declared_count(catalog, len(components), validation, "components.counts", "components", "total")
    code_range = catalog.get("code_range")
    validation.check(
        isinstance(code_range, Mapping)
        and first_present(code_range, "start", "minimum", "min") == 390
        and first_present(code_range, "end", "maximum", "max") == 434,
        "component.code_range",
        "code_range must declare inclusive 390..434",
        "components.code_range",
    )

    index_resources = flatten_index_resources(index)
    resource_by_code: dict[int, Mapping[str, Any]] = {}
    for row in index_resources:
        code = first_present(row, "code", "resource_code", "resource_id")
        if is_int(code):
            resource_by_code[code] = row
    for row in resource_state.get("sources", []):
        code = first_present(row, "code", "resource_code", "resource_id")
        if is_int(code):
            # The generated index deliberately keeps resource_code_rows compact
            # (name/code only).  The authoritative resource row carries the
            # terminal/composite tier semantics needed for catalyst checks.
            resource_by_code[code] = row
    production = production_rows(index)
    produced: dict[tuple[int, int], list[Mapping[str, Any]]] = defaultdict(list)
    for row in production:
        code = first_present(row, "resource_code", "resource_id", "output_code")
        amount = first_present(row, "amount", "output_amount", "units")
        if is_int(code) and is_int(amount):
            produced[(code, amount)].append(row)

    index_actions = {
        str(row.get("name")): row for row in action_rows(index) if row.get("name")
    }
    component_skill_counts: Counter[int] = Counter()
    action_names: set[str] = set()
    for component_index, component in enumerate(components):
        path_prefix = f"components.components[{component_index}]"
        code = first_present(component, "code", "component_id", "resource_code")
        validation.check(
            component.get("tier") in (1, 2, 3),
            "component.tier",
            f"component {code} progression tier must be 1, 2, or 3",
            path_prefix,
        )
        expected_vdf = {
            1: ("solid", 8),
            2: ("advanced", 12),
            3: ("artifact", 32),
        }.get(component.get("tier"))
        if expected_vdf is not None:
            validation.check(
                (
                    component.get("vdf_tier"),
                    component.get("vdf_iterations"),
                )
                == expected_vdf,
                "component.vdf_tier",
                f"tier {component.get('tier')} must use VDF {expected_vdf}, got "
                f"{(component.get('vdf_tier'), component.get('vdf_iterations'))}",
                path_prefix,
            )
        output_amount = component.get("output_amount")
        validation.check(
            is_int(output_amount) and output_amount > 0,
            "component.output_amount",
            "output_amount must be a positive integer",
            path_prefix,
        )
        skill_code = first_present(component, "skill_code", "skill_id")
        validation.check(
            is_int(skill_code) and 1 <= skill_code <= 18,
            "component.skill_code",
            f"skill_code must reference a root skill 1..18, got {skill_code!r}",
            path_prefix,
        )
        if is_int(skill_code):
            component_skill_counts[skill_code] += 1
        materials = list_value(component, "materials", "inputs")
        validation.check(
            len(materials) == 3,
            "component.material_count",
            f"component must have exactly three materials, got {len(materials)}",
            path_prefix,
        )
        slots = [
            first_present(row, "slot", "input_slot")
            for row in materials
            if isinstance(row, Mapping)
        ]
        validation.check(
            len(set(slots)) == 3 and set(slots) in ({0, 1, 2}, {1, 2, 3}),
            "component.material_slots",
            f"material slots must be 0..2 or 1..3, got {slots}",
            path_prefix,
        )
        source_sets: list[set[str]] = []
        for material_index, material in enumerate(materials):
            if not isinstance(material, Mapping):
                validation.error(
                    "component.material_shape",
                    "material must be an object",
                    f"{path_prefix}.materials[{material_index}]",
                )
                continue
            material_code = first_present(material, "resource_code", "resource_id", "code")
            amount = first_present(material, "amount", "qty", "units")
            validation.check(
                is_int(material_code) and material_code > 0,
                "component.material_code",
                "material resource_code must be a positive integer",
                f"{path_prefix}.materials[{material_index}]",
            )
            validation.check(
                is_int(amount) and amount > 0,
                "component.material_amount",
                "material amount must be a positive integer",
                f"{path_prefix}.materials[{material_index}]",
            )
            if is_int(material_code) and is_int(amount) and index:
                validation.check(
                    bool(produced.get((material_code, amount))),
                    "component.material_not_producible",
                    f"resource {material_code} is not producible in exact amount {amount}",
                    f"{path_prefix}.materials[{material_index}]",
                )
            sources = first_present(
                material,
                "possible_source_bodies",
                "source_bodies",
                "body_sources",
            )
            validation.check(
                isinstance(sources, list) and bool(sources),
                "component.material_sources",
                "possible_source_bodies must be a nonempty list",
                f"{path_prefix}.materials[{material_index}]",
            )
            if isinstance(sources, list):
                source_sets.append({normalized_name(item) for item in sources})
                if is_int(material_code) and is_int(amount) and index:
                    actual_sources = {
                        normalized_name(
                            first_present(
                                row,
                                "source_body_name",
                                "body_name",
                                "source_body_code",
                                "body_code",
                                "body_id",
                            )
                        )
                        for row in produced.get((material_code, amount), [])
                        if first_present(
                            row,
                            "source_body_name",
                            "body_name",
                            "source_body_code",
                            "body_code",
                            "body_id",
                        )
                        is not None
                    }
                    validation.check(
                        bool(source_sets[-1] & actual_sources),
                        "component.material_source_mismatch",
                        f"declared sources {sorted(source_sets[-1])} do not match exact "
                        f"production sources {sorted(actual_sources)}",
                        f"{path_prefix}.materials[{material_index}]",
                    )
        if len(source_sets) == 3:
            validation.check(
                not set.intersection(*source_sets),
                "component.single_body_recipe",
                "the three material source sets intersect; one body can supply the whole recipe: "
                f"{sorted(set.intersection(*source_sets))}",
                path_prefix,
            )
            validation.check(
                len(set.union(*source_sets)) >= 2,
                "component.cross_body_span",
                "component materials must span at least two source bodies",
                path_prefix,
            )

        catalyst = component.get("catalyst")
        validation.check(
            isinstance(catalyst, Mapping),
            "component.catalyst",
            "component must declare one catalyst object",
            path_prefix,
        )
        if isinstance(catalyst, Mapping):
            catalyst_code = first_present(
                catalyst, "resource_code", "resource_id", "catalyst_id", "code"
            )
            validation.check(
                is_int(catalyst_code),
                "component.catalyst_code",
                "catalyst resource_code must be an integer",
                f"{path_prefix}.catalyst",
            )
            resource = resource_by_code.get(catalyst_code) if is_int(catalyst_code) else None
            if index:
                validation.check(
                    resource is not None,
                    "component.catalyst_reference",
                    f"catalyst resource {catalyst_code!r} is absent from generated resource index",
                    f"{path_prefix}.catalyst",
                )
            if resource is not None:
                produced_as_terminal_primary = any(
                    first_present(row, "resource_code", "resource_id", "output_code")
                    == catalyst_code
                    and row.get("kind") == "direct_extraction"
                    for row in production
                )
                validation.check(
                    (
                        normalized_role(resource) == "terminal"
                        and first_present(resource, "tier", "resource_tier")
                        in (1, "1", "primary", "tier-1")
                    )
                    or produced_as_terminal_primary,
                    "component.catalyst_terminal",
                    f"catalyst {catalyst_code} must be a tier-1 terminal primary",
                    f"{path_prefix}.catalyst",
                )
            units = first_present(catalyst, "units_per_craft", "amount", "qty")
            validation.check(
                is_int(units) and units > 0,
                "component.catalyst_units",
                "catalyst units_per_craft must be positive integer",
                f"{path_prefix}.catalyst",
            )
            modes = catalyst.get("modes")
            validation.check(
                isinstance(modes, list) and set(modes) == ALLOWED_CATALYST_MODES,
                "component.catalyst_modes",
                "catalyst modes must be exactly ['reusable', 'final']",
                f"{path_prefix}.catalyst",
            )

        actions = component.get("actions")
        validation.check(
            isinstance(actions, Mapping),
            "component.actions",
            "component must declare reusable and final action names",
            path_prefix,
        )
        if isinstance(actions, Mapping):
            for mode in sorted(ALLOWED_CATALYST_MODES):
                action_name = actions.get(mode)
                validation.check(
                    isinstance(action_name, str) and bool(action_name),
                    "component.action_name",
                    f"missing {mode} action name",
                    f"{path_prefix}.actions",
                )
                if isinstance(action_name, str):
                    validation.check(
                        action_name not in action_names,
                        "component.action_duplicate",
                        f"duplicate component action {action_name}",
                        f"{path_prefix}.actions",
                    )
                    action_names.add(action_name)
                    if index:
                        action = index_actions.get(action_name)
                        validation.check(
                            action is not None,
                            "component.action_missing_index",
                            f"generated index lacks {action_name}",
                            f"{path_prefix}.actions",
                        )
                        if action is not None:
                            indexed_mode = first_present(
                                action, "catalyst_mode", "mode", "recipe_mode"
                            )
                            fixed = action.get("fixed_literals")
                            if indexed_mode is None and isinstance(fixed, Mapping):
                                indexed_mode = first_present(
                                    fixed,
                                    "catalyst_mode",
                                    "mode",
                                    "recipe_mode",
                                )
                            validation.check(
                                indexed_mode == mode,
                                "component.action_mode",
                                f"{action_name} index mode {indexed_mode!r} != {mode!r}",
                                f"{path_prefix}.actions",
                            )
                            helpers = action.get("helpers")
                            expected_catalyst_helper = (
                                "consume_component_catalyst_reusable_core"
                                if mode == "reusable"
                                else "consume_component_catalyst_final_core"
                            )
                            component_fixed = (
                                fixed.get("component")
                                if isinstance(fixed, Mapping) else None
                            )
                            phase5_adapter = None
                            if isinstance(component_fixed, Mapping):
                                phase5_mode = component_fixed.get("catalyst_mode")
                                phase5_iterations = component_fixed.get("vdf_iterations")
                                if (
                                    phase5_mode in {"reusable", "final"}
                                    and isinstance(phase5_iterations, int)
                                ):
                                    phase5_adapter = (
                                        f"fabricate_component_{phase5_mode}_vdf_"
                                        f"{phase5_iterations}_core"
                                    )
                            validation.check(
                                (
                                    isinstance(helpers, list)
                                    and helpers == [phase5_adapter]
                                    and phase5_adapter in PHASE5_KNOWN_HELPER_NAMES
                                )
                                if phase5_adapter is not None
                                else (
                                    isinstance(helpers, list)
                                    and "fabricate_component_core" in helpers
                                    and expected_catalyst_helper in helpers
                                ),
                                "component.action_helpers",
                                (
                                    f"{action_name} must route only through "
                                    f"{phase5_adapter}; its transitive component/catalyst "
                                    "semantics are checked by the Phase 5 Rhai audit"
                                    if phase5_adapter is not None
                                    else f"{action_name} must call fabricate_component_core and "
                                    f"{expected_catalyst_helper}"
                                ),
                                f"index.actions.{action_name}",
                            )
                            roles = first_present(action, "objects", "roles")
                            if isinstance(roles, list):
                                catalyst_roles = [
                                    row
                                    for row in roles
                                    if isinstance(row, Mapping)
                                    and first_present(row, "purpose", "role") == "catalyst"
                                ]
                                if catalyst_roles:
                                    validation.check(
                                        len(catalyst_roles) == 1,
                                        "component.catalyst_role",
                                        f"{action_name} must identify exactly one catalyst object role",
                                        f"index.actions.{action_name}",
                                    )
                                    object_mode = catalyst_roles[0].get("mode")
                                    expected_mode = "mutate" if mode == "reusable" else "input"
                                    validation.check(
                                        object_mode == expected_mode,
                                        "component.catalyst_object_mode",
                                        f"{mode} catalyst must be {expected_mode}, got {object_mode!r}",
                                        f"index.actions.{action_name}",
                                    )
                                else:
                                    role_pairs: list[tuple[str, str]] = []
                                    for role in roles:
                                        if isinstance(role, Mapping):
                                            role_pairs.append(
                                                (
                                                    str(first_present(role, "mode", "object_mode")),
                                                    str(first_present(role, "class", "class_name")),
                                                )
                                            )
                                        elif isinstance(role, (list, tuple)) and len(role) == 2:
                                            role_pairs.append((str(role[0]), str(role[1])))
                                    expected_modes = (
                                        Counter({"output": 2, "input": 4, "mutate": 1})
                                        if mode == "reusable"
                                        else Counter({"output": 2, "input": 5})
                                    )
                                    validation.check(
                                        Counter(item[0] for item in role_pairs) == expected_modes,
                                        "component.action_role_shape",
                                        f"{mode} action has wrong role modes: {role_pairs}",
                                        f"index.actions.{action_name}",
                                    )
                                    validation.check(
                                        Counter(item[1] for item in role_pairs)
                                        == Counter({"MicroverseShip": 2, "MicroverseResource": 5}),
                                        "component.action_class_shape",
                                        f"component action must use 2 Ship/5 Resource roles: {role_pairs}",
                                        f"index.actions.{action_name}",
                                    )
                            if mode == "reusable":
                                before = first_present(action, "catalyst_before", "catalyst_amount")
                                after = first_present(action, "catalyst_after", "next_catalyst_amount")
                                if before is not None or after is not None:
                                    validation.check(
                                        is_int(before)
                                        and is_int(after)
                                        and before - after
                                        == first_present(
                                            catalyst,
                                            "units_per_craft",
                                            "amount",
                                            "qty",
                                        ),
                                        "component.catalyst_decrement",
                                        f"reusable action must decrement catalyst by units_per_craft, "
                                        f"got {before}->{after}",
                                        f"index.actions.{action_name}",
                                    )

    declared_skill_counts = catalog.get("skill_gate_counts")
    if isinstance(declared_skill_counts, Mapping):
        for code, count in component_skill_counts.items():
            declared = first_present(declared_skill_counts, str(code), code)  # type: ignore[arg-type]
            if isinstance(declared, Mapping):
                declared = first_present(
                    declared,
                    "component_gates",
                    "count",
                    "gate_count",
                )
            validation.check(
                declared == count,
                "component.skill_gate_count",
                f"skill {code}: declared {declared!r}, actual component gates {count}",
                "components.skill_gate_counts",
            )
    else:
        validation.error(
            "component.skill_gate_counts_missing",
            "component catalog must declare skill_gate_counts",
            "components",
        )
    semantics = catalog.get("object_semantics")
    validation.check(
        isinstance(semantics, Mapping)
        and "catalyst" in " ".join(map(str, semantics.values())).lower(),
        "component.object_semantics",
        "object_semantics must explicitly document catalyst behavior",
        "components.object_semantics",
    )
    return {
        "components": components,
        "skill_counts": component_skill_counts,
        "action_names": action_names,
    }


def validate_skill_catalog(
    catalog: Mapping[str, Any],
    path: Path,
    validation: Validation,
    component_state: Mapping[str, Any],
    resource_state: Mapping[str, Any],
    index: Mapping[str, Any],
) -> dict[str, Any]:
    validate_catalog_identity(catalog, "skill", path, validation)
    validation.check(
        catalog.get("schema_version") == 2
        and catalog.get("catalog_id") == "microverse-skill-tree-v2"
        and catalog.get("catalog_version") == "2.0.0",
        "skill.catalog_header",
        "skill catalog must use the canonical v2 schema/id/version",
        "skills",
    )
    roots = [row for row in list_value(catalog, "roots") if isinstance(row, Mapping)]
    validate_unique_codes(
        roots,
        "skill_roots",
        validation,
        expected_codes=set(range(1, 19)),
        code_names=("code", "skill_code", "skill_id"),
    )
    validation.check(
        len(roots) == 18,
        "skill.root_count",
        f"expected 18 root skills, got {len(roots)}",
        "skills.roots",
    )
    specializations: list[Mapping[str, Any]] = []
    masteries: list[Mapping[str, Any]] = []
    develop_actions: list[str] = []
    for root_index, root in enumerate(roots):
        root_code = first_present(root, "code", "skill_code", "skill_id")
        root_kind = first_present(root, "kind", "tier")
        validation.check(
            root_kind in ("root", "root_skill", "root-skill"),
            "skill.root_kind",
            f"root {root_code} must declare kind=root",
            f"skills.roots[{root_index}]",
        )
        civilization = first_present(
            root, "civilization_tier", "civilization_type", "tier"
        )
        validation.check(
            civilization in (1, 2, 3),
            "skill.civilization_tier",
            f"root {root_code} civilization tier must be 1..3",
            f"skills.roots[{root_index}]",
        )
        development = first_present(root, "develop_action", "development_action")
        if isinstance(development, str):
            develop_actions.append(development)
        else:
            validation.error(
                "skill.develop_action",
                f"root {root_code} must declare develop_action",
                f"skills.roots[{root_index}]",
            )
        children = [
            row
            for row in list_value(root, "specializations")
            if isinstance(row, Mapping)
        ]
        validation.check(
            len(children) == 3,
            "skill.specialization_count",
            f"root {root_code} must have exactly three specializations, got {len(children)}",
            f"skills.roots[{root_index}]",
        )
        for child_index, child in enumerate(children):
            child_code = first_present(child, "code", "skill_code", "skill_id")
            parent_code = first_present(child, "parent_code", "parent_skill_code", "root_code")
            validation.check(
                parent_code == root_code,
                "skill.specialization_parent",
                f"specialization {child_code} parent {parent_code!r} != root {root_code}",
                f"skills.roots[{root_index}].specializations[{child_index}]",
            )
            validation.check(
                first_present(child, "kind", "tier")
                in ("specialization", "specialisation"),
                "skill.specialization_kind",
                f"skill {child_code} must declare kind=specialization",
                f"skills.roots[{root_index}].specializations[{child_index}]",
            )
            validate_derived_skill(child, child_code, validation, f"skills.roots[{root_index}].specializations[{child_index}]")
            specializations.append(child)
            action = first_present(child, "develop_action", "development_action")
            if isinstance(action, str):
                develop_actions.append(action)
        mastery = root.get("mastery")
        validation.check(
            isinstance(mastery, Mapping),
            "skill.mastery",
            f"root {root_code} must have one mastery object",
            f"skills.roots[{root_index}]",
        )
        if isinstance(mastery, Mapping):
            mastery_code = first_present(mastery, "code", "skill_code", "skill_id")
            parent_code = first_present(
                mastery, "parent_code", "parent_skill_code", "root_code"
            )
            validation.check(
                parent_code == root_code,
                "skill.mastery_parent",
                f"mastery {mastery_code} parent {parent_code!r} != root {root_code}",
                f"skills.roots[{root_index}].mastery",
            )
            validation.check(
                first_present(mastery, "kind", "tier") == "mastery",
                "skill.mastery_kind",
                f"skill {mastery_code} must declare kind=mastery",
                f"skills.roots[{root_index}].mastery",
            )
            required = list_value(
                mastery, "required_specialization_codes", "specialization_codes"
            )
            if required:
                child_codes = {
                    first_present(child, "code", "skill_code", "skill_id")
                    for child in children
                }
                validation.check(
                    set(required).issubset(child_codes),
                    "skill.mastery_specializations",
                    f"mastery {mastery_code} references specialization outside its root: {required}",
                    f"skills.roots[{root_index}].mastery",
                )
            validate_derived_skill(
                mastery,
                mastery_code,
                validation,
                f"skills.roots[{root_index}].mastery",
            )
            masteries.append(mastery)
            action = first_present(mastery, "develop_action", "development_action")
            if isinstance(action, str):
                develop_actions.append(action)

    validate_unique_codes(
        specializations,
        "skill_specializations",
        validation,
        expected_codes=set(range(19, 73)),
        code_names=("code", "skill_code", "skill_id"),
    )
    validate_unique_codes(
        masteries,
        "skill_masteries",
        validation,
        expected_codes=set(range(73, 91)),
        code_names=("code", "skill_code", "skill_id"),
    )
    all_codes = [
        first_present(row, "code", "skill_code", "skill_id")
        for row in roots + specializations + masteries
    ]
    validation.check(
        len(all_codes) == len(set(all_codes)) == 90,
        "skill.code_global_uniqueness",
        "all 90 skill codes must be globally unique",
        "skills",
    )
    validation.check(
        len(develop_actions) == len(set(develop_actions)) == 90,
        "skill.develop_action_uniqueness",
        f"all 90 skills must have unique development actions, got "
        f"{len(develop_actions)} names/{len(set(develop_actions))} unique",
        "skills",
    )
    for root_index, root in enumerate(roots):
        recipe = root.get("development_recipe")
        root_code = first_present(root, "code", "skill_code", "skill_id")
        validation.check(
            root.get("reusable") == 1,
            "skill.reusable",
            f"root skill {root_code} must be reusable",
            f"skills.roots[{root_index}]",
        )
        validation.check(
            isinstance(recipe, Mapping)
            and recipe.get("action") == root.get("develop_action")
            and recipe.get("output_skill_code") == root_code
            and recipe.get("parent_skill_input") is None
            and recipe.get("items") == []
            and isinstance(recipe.get("civilization_source"), Mapping)
            and recipe["civilization_source"].get("civilization_type")
            == root.get("civilization_type"),
            "skill.root_recipe",
            f"root skill {root_code} must preserve its civilization-issued fixed recipe",
            f"skills.roots[{root_index}].development_recipe",
        )

    all_skill_rows = roots + specializations + masteries
    skill_by_code = {
        first_present(row, "code", "skill_code", "skill_id"): row
        for row in all_skill_rows
    }
    capability_rows = [
        row
        for row in list_value(catalog, "capability_artifacts")
        if isinstance(row, Mapping)
    ]
    validation.check(
        len(capability_rows) == 72,
        "skill.capability_count",
        f"expected exactly 72 derived capability artifacts, got {len(capability_rows)}",
        "skills.capability_artifacts",
    )
    capability_codes: list[int] = []
    capability_skill_codes: list[int] = []
    capability_actions: list[str] = []
    capability_routes: list[str] = []
    for artifact_index, artifact in enumerate(capability_rows):
        prefix = f"skills.capability_artifacts[{artifact_index}]"
        skill_code = artifact.get("skill_code")
        fallback = artifact.get("fallback_resource")
        output_code = fallback.get("code") if isinstance(fallback, Mapping) else None
        action = artifact.get("action")
        route_key = artifact.get("route_key")
        validation.check(
            is_int(skill_code) and 19 <= skill_code <= 90,
            "skill.capability_skill_code",
            f"capability must reference derived skill 19..90, got {skill_code!r}",
            prefix,
        )
        validation.check(
            is_int(output_code) and 629 <= output_code <= 700,
            "skill.capability_output_code",
            f"capability fallback output code must be in 629..700, got {output_code!r}",
            prefix,
        )
        validation.check(
            isinstance(fallback, Mapping)
            and isinstance(fallback.get("name"), str)
            and fallback.get("amount") == 1,
            "skill.capability_output",
            "capability fallback resource must have a name and amount 1",
            prefix,
        )
        validation.check(
            isinstance(action, str) and bool(action)
            and isinstance(route_key, str) and bool(route_key),
            "skill.capability_identity",
            "capability action and route_key must be nonempty strings",
            prefix,
        )
        fixed_inputs = artifact.get("fixed_inputs")
        expected_input_count = 3 if is_int(skill_code) and skill_code >= 73 else None
        validation.check(
            isinstance(fixed_inputs, list)
            and (
                len(fixed_inputs) == expected_input_count
                if expected_input_count is not None
                else 1 <= len(fixed_inputs) <= 2
            ),
            "skill.capability_inputs",
            (
                f"mastery capability for skill {skill_code} must have three fixed inputs"
                if expected_input_count is not None
                else f"specialization capability for skill {skill_code} must have one or two fixed inputs"
            ),
            prefix,
        )
        if isinstance(fixed_inputs, list):
            for input_index, item in enumerate(fixed_inputs):
                validation.check(
                    isinstance(item, Mapping)
                    and item.get("class") == "MicroverseResource"
                    and is_int(item.get("resource_code"))
                    and item.get("amount") == 1,
                    "skill.capability_input_shape",
                    "capability input must be one exact MicroverseResource object",
                    f"{prefix}.fixed_inputs[{input_index}]",
                )
        skill_row = skill_by_code.get(skill_code)
        civilization = (
            skill_row.get("civilization_type")
            if isinstance(skill_row, Mapping)
            else None
        )
        skill_tier = (
            first_present(skill_row, "kind", "tier")
            if isinstance(skill_row, Mapping)
            else None
        )
        expected_vdf = (
            {1: 8, 2: 12, 3: 32}.get(civilization)
            if skill_tier in ("specialization", "specialisation")
            else {1: 12, 2: 32, 3: 32}.get(civilization)
        )
        validation.check(
            artifact.get("vdf_iterations") == expected_vdf,
            "skill.capability_vdf",
            f"capability for skill {skill_code} must use {expected_vdf} VDF iterations",
            prefix,
        )
        if isinstance(skill_row, Mapping):
            gates = [
                gate
                for gate in list_value(skill_row, "gated_capabilities")
                if isinstance(gate, Mapping)
            ]
            validation.check(
                any(
                    gate.get("action") == action
                    and gate.get("route_key") == route_key
                    and first_present(gate, "output_resource_code", "resource_code")
                    == output_code
                    for gate in gates
                ),
                "skill.capability_link",
                f"capability {action} must exactly match skill {skill_code} gated_capabilities",
                prefix,
            )
        if is_int(output_code):
            capability_codes.append(output_code)
        if is_int(skill_code):
            capability_skill_codes.append(skill_code)
        if isinstance(action, str):
            capability_actions.append(action)
        if isinstance(route_key, str):
            capability_routes.append(route_key)
    validation.check(
        set(capability_codes) == set(range(629, 701))
        and len(capability_codes) == len(set(capability_codes)),
        "skill.capability_code_set",
        "capability artifact output codes must uniquely fill 629..700",
        "skills.capability_artifacts",
    )
    validation.check(
        set(capability_skill_codes) == set(range(19, 91))
        and len(capability_skill_codes) == len(set(capability_skill_codes)),
        "skill.capability_skill_set",
        "every derived skill 19..90 must own exactly one capability artifact",
        "skills.capability_artifacts",
    )
    validation.check(
        len(capability_actions) == len(set(capability_actions)) == 72
        and len(capability_routes) == len(set(capability_routes)) == 72,
        "skill.capability_unique_identity",
        "all capability action names and route keys must be unique",
        "skills.capability_artifacts",
    )
    occupied_resource_codes = (
        set(resource_state.get("source_codes", set()))
        | set(resource_state.get("child_codes", set()))
        | {
            first_present(row, "code", "component_id", "resource_code")
            for row in component_state.get("components", [])
        }
    )
    validation.check(
        occupied_resource_codes.isdisjoint(capability_codes),
        "skill.capability_code_namespace",
        "capability artifact codes overlap an existing resource/component code",
        "skills.capability_artifacts",
    )
    expected_counts = {"roots": 18, "specializations": 54, "masteries": 18, "total": 90}
    actual_counts = {
        "roots": len(roots),
        "specializations": len(specializations),
        "masteries": len(masteries),
        "total": len(roots) + len(specializations) + len(masteries),
    }
    for key, expected in expected_counts.items():
        validation.check(
            actual_counts[key] == expected,
            "skill.exact_count",
            f"{key}: expected {expected}, got {actual_counts[key]}",
            "skills",
        )
        declared = declared_count(
            catalog,
            key,
            "total_skills" if key == "total" else key,
        )
        validation.check(
            declared == expected,
            "skill.declared_count",
            f"counts.{key} must be {expected}, got {declared!r}",
            "skills.counts",
        )

    gates = logical_skill_gates(index)
    if gates:
        gate_counts = Counter(code for code, _route in gates)
    else:
        # Authoring fallback: existing audit plus authored new routes/components.
        gate_counts = Counter(component_state.get("skill_counts", {}))
        for root in roots:
            code = first_present(root, "code", "skill_code", "skill_id")
            audit = root.get("existing_gate_audit")
            if is_int(code) and isinstance(audit, Mapping):
                existing = first_present(
                    audit,
                    "logical_resource_routes",
                    "total_logical_resource_routes",
                    "logical_resource_route_count",
                    "route_count",
                )
                if is_int(existing):
                    gate_counts[code] += existing
        for resource in resource_state.get("sources", []):
            skill = first_present(
                resource, "extraction_skill_id", "skill_code", "skill_id"
            )
            if is_int(skill):
                gate_counts[skill] += 1
        for parent in resource_state.get("parents", []):
            for child in list_value(parent, "children", "outputs", "refine_outputs"):
                if isinstance(child, Mapping):
                    skill = first_present(
                        child, "refinement_skill_id", "skill_code", "skill_id"
                    )
                    if is_int(skill):
                        gate_counts[skill] += 1
    for code in range(1, 19):
        validation.check(
            gate_counts[code] >= 8,
            "skill.root_gate_minimum",
            f"root skill {code} gates {gate_counts[code]} logical resource routes; minimum is 8",
            "skills.root_gate_balance_summary",
        )
    declared_summary = catalog.get("root_gate_balance_summary")
    validation.check(
        isinstance(declared_summary, (Mapping, list)),
        "skill.gate_summary",
        "root_gate_balance_summary must be present",
        "skills",
    )
    return {
        "roots": roots,
        "specializations": specializations,
        "masteries": masteries,
        "gate_counts": gate_counts,
        "develop_actions": set(develop_actions),
        "capability_actions": set(capability_actions),
    }


def validate_derived_skill(
    skill: Mapping[str, Any],
    code: Any,
    validation: Validation,
    path: str,
) -> None:
    action = first_present(skill, "develop_action", "development_action")
    validation.check(
        isinstance(action, str) and bool(action),
        "skill.derived_develop_action",
        f"derived skill {code} needs a develop_action",
        path,
    )
    recipe = first_present(skill, "development_recipe", "recipe")
    validation.check(
        isinstance(recipe, (Mapping, list)) and bool(recipe),
        "skill.development_recipe",
        f"derived skill {code} needs a fixed nonempty development_recipe",
        path,
    )
    if isinstance(recipe, Mapping):
        validation.check(
            first_present(recipe, "action", "develop_action") == action,
            "skill.recipe_action",
            f"derived skill {code} recipe action must equal develop_action",
            path,
        )
        validation.check(
            first_present(recipe, "output_skill_code", "skill_code") == code,
            "skill.recipe_output_code",
            f"derived skill {code} recipe must emit the same skill code",
            path,
        )
        parent_input = recipe.get("parent_skill_input")
        parent_code = first_present(skill, "parent_code", "parent_skill_code")
        validation.check(
            isinstance(parent_input, Mapping)
            and first_present(parent_input, "skill_code", "code") == parent_code
            and parent_input.get("mode") == "prepared_ship_active_skill"
            and parent_input.get("consumed") is False,
            "skill.recipe_parent_input",
            f"derived skill {code} must use reusable prepared parent skill {parent_code}",
            path,
        )
        items = recipe.get("items")
        validation.check(
            isinstance(items, list) and bool(items),
            "skill.recipe_items",
            f"derived skill {code} must have fixed nonempty recipe items",
            path,
        )
        if isinstance(items, list):
            for item_index, item in enumerate(items):
                item_path = f"{path}.development_recipe.items[{item_index}]"
                validation.check(
                    isinstance(item, Mapping),
                    "skill.recipe_item_shape",
                    "skill recipe item must be an object",
                    item_path,
                )
                if not isinstance(item, Mapping):
                    continue
                item_code = first_present(item, "resource_code", "component_code")
                validation.check(
                    is_int(item_code) and item_code > 0,
                    "skill.recipe_item_code",
                    f"skill recipe item requires a positive resolved code, got {item_code!r}",
                    item_path,
                )
                validation.check(
                    is_int(item.get("amount")) and item["amount"] > 0,
                    "skill.recipe_item_amount",
                    "skill recipe item amount must be a positive integer",
                    item_path,
                )
    capabilities = list_value(
        skill,
        "gated_capabilities",
        "gated_actions",
        "capabilities",
    )
    validation.check(
        bool(capabilities)
        and all(isinstance(item, (str, Mapping)) for item in capabilities),
        "skill.gated_capabilities",
        f"derived skill {code} must gate at least one named capability/action",
        path,
    )


def logical_skill_gates(index: Mapping[str, Any]) -> set[tuple[int, str]]:
    rows = list_value(index, "skill_gates", "logical_skill_gates")
    result: set[tuple[int, str]] = set()
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        code = first_present(row, "skill_code", "skill_id")
        family = str(first_present(row, "family", "route_family") or "").lower()
        route = first_present(
            row,
            "logical_route_id",
            "route_id",
            "route_key",
            "logical_key",
            "base_action",
            "action",
        )
        if is_int(code) and family in LOGICAL_GATE_FAMILIES and route is not None:
            result.add((code, str(route)))
    return result


def warp_sections(catalog: Mapping[str, Any]) -> tuple[Any, Any, Any, Any]:
    v1 = catalog.get("v1") if isinstance(catalog.get("v1"), Mapping) else {}
    v2 = catalog.get("v2") if isinstance(catalog.get("v2"), Mapping) else catalog
    pos_v1 = first_present(v1, "position", "position_warp", "position_catalog")
    time_v1 = first_present(v1, "time", "time_warp", "time_catalog")
    pos_v2 = first_present(v2, "position", "position_warp", "position_catalog")
    time_v2 = first_present(v2, "time", "time_warp", "time_catalog")
    frozen = catalog.get("frozen_v1")
    if isinstance(frozen, Mapping):
        pos_v1 = pos_v1 or first_present(frozen, "position", "position_catalog")
        time_v1 = time_v1 or first_present(frozen, "time", "time_catalog")
    return pos_v1, time_v1, pos_v2, time_v2


def section_rows(section: Any) -> list[Mapping[str, Any]]:
    if isinstance(section, list):
        return [row for row in section if isinstance(row, Mapping)]
    if isinstance(section, Mapping):
        return [
            row
            for row in list_value(section, "destinations", "rows", "coordinates")
            if isinstance(row, Mapping)
        ]
    return []


def frozen_warp_fingerprint(rows: Sequence[Mapping[str, Any]], time_only: bool) -> str:
    fields = (
        (
            "code",
            "slug",
            "epoch",
            "uses",
            "minimum_source_pool_inclusive",
            "reveal_action",
        )
        if time_only
        else (
            "code",
            "slug",
            "x",
            "y",
            "z",
            "uses",
            "minimum_source_pool_inclusive",
            "reveal_action",
        )
    )
    selected = [{key: row.get(key) for key in fields} for row in rows]
    return canonical_sha256(selected)


def validate_warp_rows(
    rows: Sequence[Mapping[str, Any]],
    expected_count: int,
    time_only: bool,
    label: str,
    validation: Validation,
    *,
    action_prefix: str,
    slug_width: int,
    capacity_minimums: Mapping[int, int],
    tier_field: str | None = None,
) -> None:
    validation.check(
        len(rows) == expected_count,
        "warp.exact_count",
        f"{label}: expected {expected_count} destinations, got {len(rows)}",
        label,
    )
    validate_unique_codes(
        rows,
        label,
        validation,
        expected_codes=set(range(1, expected_count + 1)),
        code_names=("code", "destination_code"),
    )
    coordinate_tuples: set[tuple[int, ...]] = set()
    required_fields = {
        "code",
        "slug",
        "uses",
        "reveal_action",
        "minimum_source_pool_inclusive",
        *( {"epoch"} if time_only else {"x", "y", "z"} ),
        *( {tier_field} if tier_field is not None else set() ),
    }
    use_counts: Counter[int] = Counter()
    for index, row in enumerate(rows):
        expected_code = index + 1
        expected_slug = f"{expected_code:0{slug_width}d}"
        validation.check(
            set(row) == required_fields,
            "warp.row_fields",
            f"{label} row must have exactly {sorted(required_fields)}, got "
            f"{sorted(row)}",
            f"{label}[{index}]",
        )
        validation.check(
            not (set(row) & RETIRED_WARP_SELECTION_FIELDS),
            "warp.retired_selection_fields",
            f"{label} row contains retired stable-ID/weight/capacity fields: "
            f"{sorted(set(row) & RETIRED_WARP_SELECTION_FIELDS)}",
            f"{label}[{index}]",
        )
        validation.check(
            row.get("code") == expected_code
            and row.get("slug") == expected_slug
            and row.get("reveal_action") == f"{action_prefix}{expected_slug}",
            "warp.explicit_action_mapping",
            f"{label} row {expected_code} must map exactly to "
            f"{action_prefix}{expected_slug}",
            f"{label}[{index}]",
        )
        uses = row.get("uses")
        expected_uses = 10 if expected_code == 1 else 3 if expected_code <= 4 else 1
        validation.check(
            uses == expected_uses,
            "warp.uses",
            f"{label} code {expected_code} must have {expected_uses} use(s), "
            f"got {uses!r}",
            f"{label}[{index}]",
        )
        if is_int(uses):
            use_counts[uses] += 1
        expected_minimum = capacity_minimums.get(uses) if is_int(uses) else None
        validation.check(
            expected_minimum is not None
            and row.get("minimum_source_pool_inclusive") == expected_minimum
            and "source_pool_maximum_inclusive" not in row,
            "warp.maximum_capacity_minimum",
            f"{label} code {expected_code} must use the singular inclusive "
            f"source-pool minimum {expected_minimum!r} with no upper bound; "
            f"got {row.get('minimum_source_pool_inclusive')!r}",
            f"{label}[{index}]",
        )
        if tier_field is not None:
            validation.check(
                isinstance(row.get(tier_field), str) and bool(row.get(tier_field)),
                "warp.tier_label",
                f"{label} row must declare a nonempty {tier_field}",
                f"{label}[{index}]",
            )
        if time_only:
            epoch = row.get("epoch")
            validation.check(
                is_int(epoch) and TIME_MINIMUM <= epoch < TIME_MAXIMUM_EXCLUSIVE,
                "warp.time_bounds",
                f"epoch must be in [{TIME_MINIMUM}, {TIME_MAXIMUM_EXCLUSIVE}), got {epoch!r}",
                f"{label}[{index}]",
            )
            if is_int(epoch):
                coordinate_tuples.add((epoch,))
        else:
            values = tuple(row.get(axis) for axis in ("x", "y", "z"))
            validation.check(
                all(
                    is_int(value)
                    and POSITION_MINIMUM <= value < POSITION_MAXIMUM_EXCLUSIVE
                    for value in values
                ),
                "warp.position_bounds",
                f"x/y/z must be in [{POSITION_MINIMUM}, {POSITION_MAXIMUM_EXCLUSIVE}), got {values}",
                f"{label}[{index}]",
            )
            if all(is_int(value) for value in values):
                coordinate_tuples.add(values)  # type: ignore[arg-type]
    validation.check(
        use_counts == Counter({10: 1, 3: 3, 1: max(expected_count - 4, 0)}),
        "warp.use_distribution",
        f"{label} use distribution must be one 10-use, three 3-use, and "
        f"{expected_count - 4} single-use rows; got {dict(use_counts)}",
        label,
    )
    validation.check(
        len(coordinate_tuples) == len(rows),
        "warp.destination_duplicate",
        f"destination coordinates/epochs must be unique; {len(coordinate_tuples)}/{len(rows)} unique",
        label,
    )


def validate_warp_catalog(
    catalog: Mapping[str, Any], path: Path, validation: Validation
) -> dict[str, Any]:
    validate_catalog_identity(catalog, "warp", path, validation)
    validation.check(
        catalog.get("schema_version") == 2
        and catalog.get("catalog_id") == "microverse-warp-tree-v2"
        and catalog.get("catalog_name") == "microverse-warp-tree-v2"
        and catalog.get("catalog_version") == "2.1.0",
        "warp.catalog_header",
        "warp catalog must use the canonical explicit-selection v2.1 identity",
        "warp",
    )
    versions = catalog.get("versions")
    validation.check(
        isinstance(versions, Mapping)
        and versions.get("schema_version") == 2
        and versions.get("mechanics_version") == 2
        and versions.get("universe_version") == 2
        and versions.get("frozen_position_catalog_version") == 1
        and versions.get("frozen_time_catalog_version") == 1
        and versions.get("position_chart_catalog_version") == 2
        and versions.get("epoch_chart_catalog_version") == 2
        and versions.get("anchor_link_catalog_version") == 2,
        "warp.version_contract",
        "warp protocol/catalog versions must exactly preserve frozen v1 and install v2",
        "warp.versions",
    )
    pos_v1, time_v1, pos_v2, time_v2 = warp_sections(catalog)
    pos1_rows = section_rows(pos_v1)
    time1_rows = section_rows(time_v1)
    pos2_rows = section_rows(pos_v2)
    time2_rows = section_rows(time_v2)
    validate_warp_rows(
        pos1_rows,
        125,
        False,
        "warp.v1.position",
        validation,
        action_prefix="RevealWarpCoordinate",
        slug_width=3,
        capacity_minimums=V1_COORDINATE_POOL_MINIMUMS,
    )
    validate_warp_rows(
        time1_rows,
        86,
        True,
        "warp.v1.time",
        validation,
        action_prefix="RevealTimeCoordinate",
        slug_width=2,
        capacity_minimums=V1_COORDINATE_POOL_MINIMUMS,
    )
    validate_warp_rows(
        pos2_rows,
        256,
        False,
        "warp.v2.position",
        validation,
        action_prefix="RevealWarpChart",
        slug_width=3,
        capacity_minimums=V2_CHART_POOL_MINIMUMS,
        tier_field="scale_tier",
    )
    validate_warp_rows(
        time2_rows,
        128,
        True,
        "warp.v2.time",
        validation,
        action_prefix="RevealEpochChart",
        slug_width=3,
        capacity_minimums=V2_CHART_POOL_MINIMUMS,
        tier_field="epoch_tier",
    )
    if pos1_rows:
        validation.check(
            frozen_warp_fingerprint(pos1_rows, False) == FROZEN_POSITION_V1_SHA256,
            "warp.v1_position_changed",
            "v1 position catalog fingerprint changed; existing sealed objects would remap",
            "warp.v1.position",
        )
    if time1_rows:
        validation.check(
            frozen_warp_fingerprint(time1_rows, True) == FROZEN_TIME_V1_SHA256,
            "warp.v1_time_changed",
            "v1 time catalog fingerprint changed; existing sealed objects would remap",
            "warp.v1.time",
        )
    frozen_fingerprints = catalog.get("frozen_v1_fingerprints")
    validation.check(
        isinstance(frozen_fingerprints, Mapping)
        and frozen_fingerprints.get("position_fields")
        == [
            "code",
            "slug",
            "x",
            "y",
            "z",
            "uses",
            "minimum_source_pool_inclusive",
            "reveal_action",
        ]
        and frozen_fingerprints.get("position_sha256")
        == FROZEN_POSITION_V1_SHA256
        and frozen_fingerprints.get("time_fields")
        == [
            "code",
            "slug",
            "epoch",
            "uses",
            "minimum_source_pool_inclusive",
            "reveal_action",
        ]
        and frozen_fingerprints.get("time_sha256") == FROZEN_TIME_V1_SHA256,
        "warp.v1_fingerprint_contract",
        "frozen v1 fingerprints must cover the exact action mapping, "
        "destination, uses, and inclusive capacity minimum",
        "warp.frozen_v1_fingerprints",
    )
    counts = catalog.get("counts")
    expected_counts = {
        "frozen_v1_position_destinations": 125,
        "frozen_v1_time_destinations": 86,
        "v2_position_destinations": 256,
        "v2_time_destinations": 128,
        "total_position_destinations": 381,
        "total_time_destinations": 214,
        "total_fixed_destinations": 595,
        "object_types": 9,
        "v1_fixed_reveal_actions": 211,
        "v2_fixed_reveal_actions": 384,
        "total_fixed_reveal_actions": 595,
        "total_fixed_actions_after_expansion": 622,
    }
    validation.check(
        isinstance(counts, Mapping),
        "warp.counts",
        "warp catalog must declare exact counts",
        "warp.counts",
    )
    if isinstance(counts, Mapping):
        for name, expected in expected_counts.items():
            validation.check(
                counts.get(name) == expected,
                "warp.declared_count",
                f"counts.{name} must be {expected}, got {counts.get(name)!r}",
                "warp.counts",
            )
    selection = catalog.get("selection_semantics")
    validation.check(
        selection == EXACT_WARP_SELECTION_SEMANTICS,
        "warp.selection_semantics",
        "warp selection must be exact action identity and must not use the "
        "object stable identifier",
        "warp.selection_semantics",
    )
    retired_paths = forbidden_key_paths(catalog, RETIRED_WARP_SELECTION_FIELDS)
    validation.check(
        not retired_paths,
        "warp.retired_selection_contract",
        "warp catalog contains retired stable-ID selector/band, probability, "
        f"weight, rarity, or capacity-upper fields: {retired_paths[:20]}",
        "warp",
    )
    validation.check(
        catalog.get("use_capacity_policy")
        == {
            "mode": "maximum_capacity_eligibility",
            "row_assignment": {
                "ten_use": {"rows": 1, "uses": 10},
                "three_use": {"rows": 3, "uses": 3},
                "single_use": {"rows": "all remaining", "uses": 1},
            },
            "v1_minimum_source_pool": {
                "10_uses": 18_000,
                "3_uses": 9_001,
                "1_use": 9_000,
            },
            "v2_minimum_source_pool": {
                "10_uses": 40_000,
                "3_uses": 31_000,
                "1_use": 9_000,
            },
            "selection_note": (
                "Use counts are fixed selectable capacities, not probability "
                "or rarity odds. A higher source snapshot may select any "
                "lower-use action."
            ),
        },
        "warp.capacity_policy",
        "warp use-capacity policy must use the exact singular inclusive minima "
        "and permit higher snapshots to choose lower-use actions",
        "warp.use_capacity_policy",
    )
    for section_label, section, capacity_minimums, pristine, sequence in (
        (
            "v1.position",
            pos_v1,
            V1_COORDINATE_POOL_MINIMUMS,
            [18_000, 9_000],
            [10, 1],
        ),
        (
            "v1.time",
            time_v1,
            V1_COORDINATE_POOL_MINIMUMS,
            [18_000, 9_000],
            [10, 1],
        ),
        (
            "v2.position",
            pos_v2,
            V2_CHART_POOL_MINIMUMS,
            [40_000, 31_000, 22_000, 13_000],
            [10, 3, 1, 1],
        ),
        (
            "v2.time",
            time_v2,
            V2_CHART_POOL_MINIMUMS,
            [40_000, 31_000, 22_000, 13_000],
            [10, 3, 1, 1],
        ),
    ):
        capacity = (
            section.get("capacity_selection")
            if isinstance(section, Mapping)
            else None
        )
        expected_tiers = [
            {
                "uses": uses,
                "minimum_source_pool_inclusive": capacity_minimums[uses],
            }
            for uses in (10, 3, 1)
        ]
        validation.check(
            isinstance(section, Mapping)
            and section.get("selection_mode") == EXPLICIT_SELECTION_MODE,
            "warp.section_selection_mode",
            f"{section_label} must declare explicit action identity selection",
            f"warp.{section_label}",
        )
        validation.check(
            isinstance(capacity, Mapping)
            and capacity.get("source_field") == "source_pool_before"
            and capacity.get("mode") == "maximum_capacity_eligibility"
            and capacity.get("tiers") == expected_tiers
            and capacity.get("pristine_example") == pristine
            and capacity.get("pristine_capacity_sequence") == sequence
            and "source_pool_maximum_inclusive" not in capacity,
            "warp.section_capacity_policy",
            f"{section_label} must freeze source_pool_before and enforce only "
            f"the exact inclusive minima {expected_tiers}, with no upper gate",
            f"warp.{section_label}.capacity_selection",
        )
    record_schema = catalog.get("record_schema")
    validation.check(
        isinstance(record_schema, Mapping)
        and record_schema.get("capacity_required_fields")
        == ["minimum_source_pool_inclusive"],
        "warp.capacity_record_schema",
        "warp row schema must require the singular inclusive capacity minimum",
        "warp.record_schema",
    )
    v2_fingerprints = catalog.get("v2_fingerprints")
    validation.check(
        isinstance(v2_fingerprints, Mapping)
        and v2_fingerprints.get("position_full_rows_sha256")
        == canonical_sha256(pos2_rows)
        and v2_fingerprints.get("time_full_rows_sha256")
        == canonical_sha256(time2_rows),
        "warp.v2_fingerprint",
        "v2 full-row fingerprints must match the authored destination rows",
        "warp.v2_fingerprints",
    )
    for label, section in (("position", pos_v2), ("time", time_v2)):
        if isinstance(section, Mapping):
            version = first_present(section, "catalog_version", "version")
            validation.check(
                version in (2, "2", "v2"),
                "warp.v2_version",
                f"v2 {label} catalog must declare version 2, got {version!r}",
                f"warp.v2.{label}",
            )
            class_name = first_present(section, "class", "class_name", "object_class")
            validation.check(
                isinstance(class_name, str)
                and "v2" in class_name.lower()
                or class_name in ("MicroverseWarpChart", "MicroverseEpochChart"),
                "warp.v2_class",
                f"v2 {label} must use a distinct class, got {class_name!r}",
                f"warp.v2.{label}",
            )
    object_types = [
        row for row in list_value(catalog, "object_types") if isinstance(row, Mapping)
    ]
    class_names = [row.get("class_name") for row in object_types]
    validation.check(
        len(object_types) == 9
        and len(class_names) == len(set(class_names))
        and class_names == list(EXPECTED_WARP_OBJECT_SCHEMAS)
        and all(isinstance(name, str) and name for name in class_names),
        "warp.object_types",
        "warp catalog must declare the exact nine object types in protocol order",
        "warp.object_types",
    )
    reveal_rows_by_class = {
        "MicroverseWarpCoordinate": pos1_rows,
        "MicroverseTimeCoordinate": time1_rows,
        "MicroverseWarpChart": pos2_rows,
        "MicroverseEpochChart": time2_rows,
    }
    expanded_actions: list[str] = []
    expanded_action_contracts: dict[str, list[tuple[str, str]]] = {}
    for object_index, object_type in enumerate(object_types):
        class_name = object_type.get("class_name")
        schema_fields = object_type.get("schema_fields")
        schema = [
            (str(row.get("name")), str(row.get("type")))
            for row in schema_fields
            if isinstance(row, Mapping)
        ] if isinstance(schema_fields, list) else []
        expected_schema = EXPECTED_WARP_OBJECT_SCHEMAS.get(str(class_name))
        validation.check(
            isinstance(schema_fields, list)
            and expected_schema is not None
            and tuple(schema) == expected_schema,
            "warp.object_schema",
            f"{class_name} must declare the exact protocol Raw/Int schema; "
            f"expected {list(expected_schema or ())}, got {schema}",
            f"warp.object_types[{object_index}]",
        )
        validation.check(
            len(schema) == len({name for name, _field_type in schema})
            and all(
                field_type == expected_schema_field_type(field_name)
                for field_name, field_type in schema
            ),
            "warp.object_schema_types",
            f"{class_name} has a duplicate field or an identifier/numeric type mismatch",
            f"warp.object_types[{object_index}]",
        )
        for group in ("creation_actions", "use_actions"):
            for action in list_value(object_type, group):
                if not isinstance(action, Mapping):
                    validation.error(
                        "warp.action_shape",
                        "warp action must be an object",
                        f"warp.object_types[{object_index}].{group}",
                    )
                    continue
                name = action.get("name")
                roles = action.get("roles")
                validation.check(
                    isinstance(name, str)
                    and isinstance(roles, list)
                    and bool(roles)
                    and all(
                        isinstance(role, Mapping)
                        and role.get("mode") in {"input", "output", "mutate"}
                        and isinstance(role.get("class"), str)
                        for role in roles
                    ),
                    "warp.action_contract",
                    "warp action requires a name and fixed object roles",
                    f"warp.object_types[{object_index}].{group}",
                )
                if not isinstance(name, str):
                    continue
                role_pairs = [
                    (str(role.get("mode")), str(role.get("class")))
                    for role in roles
                    if isinstance(role, Mapping)
                ] if isinstance(roles, list) else []
                if name in SHAPE_J_WARP_CONSTRUCTOR_ROLES:
                    role_triples = [
                        (
                            str(role.get("mode")),
                            str(role.get("class")),
                            role.get("slot"),
                        )
                        for role in roles
                        if isinstance(role, Mapping)
                    ] if isinstance(roles, list) else []
                    rules = action.get("field_copy_update_rules")
                    validation.check(
                        role_triples
                        == list(SHAPE_J_WARP_CONSTRUCTOR_ROLES[name]),
                        "warp.shape_j_constructor_roles",
                        f"{name} authored roles must be target output, ordered "
                        f"anchors/materials, then Ship mutate; got {role_triples}",
                        f"warp.object_types[{object_index}].{group}.{name}",
                    )
                    validation.check(
                        isinstance(rules, list)
                        and bool(rules)
                        and rules[0] == SHAPE_J_SHIP_LIFECYCLE_RULE
                        and all(
                            not (
                                isinstance(role, Mapping)
                                and role.get("purpose") == "replacement Ship"
                            )
                            for role in roles
                        ),
                        "warp.shape_j_ship_lifecycle",
                        f"{name} must document the exact in-place Ship lifecycle "
                        "and must not claim replacement-Ship semantics",
                        f"warp.object_types[{object_index}].{group}.{name}",
                    )
                if "{slug}" in name:
                    rows = reveal_rows_by_class.get(str(class_name), [])
                    for row in rows:
                        expanded_name = name.replace(
                            "{slug}", str(row.get("slug"))
                        )
                        expanded_actions.append(expanded_name)
                        expanded_action_contracts[expanded_name] = role_pairs
                else:
                    expanded_actions.append(name)
                    expanded_action_contracts[name] = role_pairs
    validation.check(
        len(expanded_actions) == len(set(expanded_actions)) == 622,
        "warp.action_count",
        f"expanded warp action contracts must be 622 unique names, got "
        f"{len(expanded_actions)}/{len(set(expanded_actions))} unique",
        "warp.object_types",
    )
    recipes = catalog.get("recipes")
    validation.check(
        isinstance(recipes, Mapping) and len(recipes) == 5,
        "warp.recipe_count",
        "warp catalog must define exactly five fixed construction recipes",
        "warp.recipes",
    )
    if isinstance(recipes, Mapping):
        for name, recipe in recipes.items():
            inputs = recipe.get("inputs") if isinstance(recipe, Mapping) else None
            validation.check(
                isinstance(inputs, list)
                and bool(inputs)
                and all(
                    isinstance(item, Mapping)
                    and is_int(item.get("slot"))
                    and item.get("amount") == 1
                    and item.get("consumed") is True
                    for item in inputs
                ),
                "warp.recipe_shape",
                f"warp recipe {name} must have fixed consumed one-object inputs",
                f"warp.recipes.{name}",
            )
    return {
        "catalog_version": catalog.get("catalog_version"),
        "selection_semantics": selection,
        "frozen_v1_fingerprints": frozen_fingerprints,
        "v2_fingerprints": v2_fingerprints,
        "capacity_selections": {
            "v1.position": (
                pos_v1.get("capacity_selection")
                if isinstance(pos_v1, Mapping)
                else None
            ),
            "v1.time": (
                time_v1.get("capacity_selection")
                if isinstance(time_v1, Mapping)
                else None
            ),
            "v2.position": (
                pos_v2.get("capacity_selection")
                if isinstance(pos_v2, Mapping)
                else None
            ),
            "v2.time": (
                time_v2.get("capacity_selection")
                if isinstance(time_v2, Mapping)
                else None
            ),
        },
        "position_v1": pos1_rows,
        "time_v1": time1_rows,
        "position_v2": pos2_rows,
        "time_v2": time2_rows,
        "actions": set(expanded_actions),
        "action_contracts": expanded_action_contracts,
        "object_types": object_types,
    }


def validate_index(
    index: Mapping[str, Any],
    path: Path,
    validation: Validation,
    states: Mapping[str, Mapping[str, Any]],
) -> None:
    validate_catalog_identity(index, "generated index", path, validation)
    validation.check(
        index.get("schema_version") == 2
        and index.get("catalog_id") == "microverse-catalog-index-v2"
        and index.get("catalog_version") == "2.1.0",
        "index.generator_provenance",
        "catalog index must use the canonical generator-owned v2.1 identity",
        "index",
    )
    source_catalogs = index.get("source_catalogs")
    expected_source_identities = {
        "component": "microverse-component-tree-v2",
        "resource": "Microverse Resource Tree v2",
        "skill": "microverse-skill-tree-v2",
        "warp": "microverse-warp-tree-v2",
    }
    validation.check(
        isinstance(source_catalogs, Mapping)
        and set(source_catalogs) == set(expected_source_identities)
        and all(
            isinstance(source_catalogs.get(name), Mapping)
            and source_catalogs[name].get("schema_version") == 2
            and source_catalogs[name].get("identity") == identity
            for name, identity in expected_source_identities.items()
        ),
        "index.source_catalogs",
        "generated index must bind all four exact authoritative v2 catalog identities",
        "index.source_catalogs",
    )
    versions = index.get("versions")
    validation.check(
        versions
        == {
            "schema_version": 2,
            "mechanics_version": 2,
            "universe_version": 2,
            "body_bank_version": 2,
            "civilization_version": 2,
        },
        "index.versions",
        "generated index must bind the exact production v2 version vector",
        "index",
    )
    if isinstance(versions, Mapping):
        for name, value in versions.items():
            validation.check(
                is_int(value) and value >= 1,
                "index.version_value",
                f"version {name} must be positive integer, got {value!r}",
                "index.versions",
            )
    actions = action_rows(index)
    validation.check(
        bool(actions),
        "index.actions",
        "generated index must enumerate actions",
        "index",
    )
    resource_profile = states.get("resources", {}).get("profile")
    expected_actions = {"full": 1_650, "bold-five": 1_538}.get(
        str(resource_profile)
    )
    if expected_actions is not None:
        validation.check(
            len(actions) == expected_actions,
            "index.exact_action_count",
            f"{resource_profile} expansion must enumerate exactly {expected_actions} actions, "
            f"got {len(actions)}",
            "index.actions",
        )
    names = [row.get("name") for row in actions]
    name_set = {name for name in names if isinstance(name, str)}
    validation.check(
        all(isinstance(name, str) and name for name in names),
        "index.action_names",
        "every indexed action needs a name",
        "index.actions",
    )
    validation.check(
        len(names) == len(set(names)),
        "index.action_duplicate",
        "indexed action names must be unique",
        "index.actions",
    )
    expected_catalog_actions = {
        "component": set(states.get("components", {}).get("action_names", set())),
        "skill": set(states.get("skills", {}).get("develop_actions", set()))
        | set(states.get("skills", {}).get("capability_actions", set())),
        "warp": set(states.get("warp", {}).get("actions", set())),
    }
    for family, expected in expected_catalog_actions.items():
        if expected:
            validation.check(
                expected.issubset(name_set),
                "index.catalog_action_coverage",
                f"generated index is missing {family} catalog actions: "
                f"{sorted(expected-name_set)[:20]}",
                "index.actions",
            )
    indexed_actions_by_name = {
        str(row.get("name")): row for row in actions if row.get("name")
    }
    warp_state = states.get("warp", {})
    index_warp = index.get("warp")
    validation.check(
        isinstance(index_warp, Mapping)
        and index_warp.get("catalog_id") == "microverse-warp-tree-v2"
        and index_warp.get("catalog_version") == "2.1.0"
        and index_warp.get("selection_semantics")
        == EXACT_WARP_SELECTION_SEMANTICS,
        "index.warp_selection_provenance",
        "generated index warp provenance must bind catalog v2.1 and the exact "
        "explicit-action selection semantics",
        "index.warp",
    )
    indexed_warp_catalogs = (
        index_warp.get("catalogs") if isinstance(index_warp, Mapping) else None
    )
    frozen_hashes = warp_state.get("frozen_v1_fingerprints", {})
    v2_hashes = warp_state.get("v2_fingerprints", {})
    capacity_selections = warp_state.get("capacity_selections", {})
    expected_warp_catalogs = [
        {
            "catalog": "v1.position",
            "object_class": "MicroverseWarpCoordinate",
            "row_count": 125,
            "row_sha256": (
                frozen_hashes.get("position_sha256")
                if isinstance(frozen_hashes, Mapping)
                else None
            ),
            "reveal_action_prefix": "RevealWarpCoordinate",
            "selection_mode": EXPLICIT_SELECTION_MODE,
            "capacity_selection": (
                capacity_selections.get("v1.position")
                if isinstance(capacity_selections, Mapping)
                else None
            ),
        },
        {
            "catalog": "v1.time",
            "object_class": "MicroverseTimeCoordinate",
            "row_count": 86,
            "row_sha256": (
                frozen_hashes.get("time_sha256")
                if isinstance(frozen_hashes, Mapping)
                else None
            ),
            "reveal_action_prefix": "RevealTimeCoordinate",
            "selection_mode": EXPLICIT_SELECTION_MODE,
            "capacity_selection": (
                capacity_selections.get("v1.time")
                if isinstance(capacity_selections, Mapping)
                else None
            ),
        },
        {
            "catalog": "v2.position",
            "object_class": "MicroverseWarpChart",
            "row_count": 256,
            "row_sha256": (
                v2_hashes.get("position_full_rows_sha256")
                if isinstance(v2_hashes, Mapping)
                else None
            ),
            "reveal_action_prefix": "RevealWarpChart",
            "selection_mode": EXPLICIT_SELECTION_MODE,
            "capacity_selection": (
                capacity_selections.get("v2.position")
                if isinstance(capacity_selections, Mapping)
                else None
            ),
        },
        {
            "catalog": "v2.time",
            "object_class": "MicroverseEpochChart",
            "row_count": 128,
            "row_sha256": (
                v2_hashes.get("time_full_rows_sha256")
                if isinstance(v2_hashes, Mapping)
                else None
            ),
            "reveal_action_prefix": "RevealEpochChart",
            "selection_mode": EXPLICIT_SELECTION_MODE,
            "capacity_selection": (
                capacity_selections.get("v2.time")
                if isinstance(capacity_selections, Mapping)
                else None
            ),
        },
    ]
    validation.check(
        indexed_warp_catalogs == expected_warp_catalogs,
        "index.warp_catalog_provenance",
        "generated index must bind all four explicit-action warp catalogs, "
        "row counts, fingerprints, classes, and action prefixes exactly",
        "index.warp.catalogs",
    )

    expected_warp_actions: dict[str, tuple[str, Mapping[str, Any]]] = {}
    for catalog_name, state_key in (
        ("v1.position", "position_v1"),
        ("v1.time", "time_v1"),
        ("v2.position", "position_v2"),
        ("v2.time", "time_v2"),
    ):
        rows = warp_state.get(state_key, [])
        if isinstance(rows, list):
            for row in rows:
                if isinstance(row, Mapping) and isinstance(
                    row.get("reveal_action"), str
                ):
                    expected_warp_actions[str(row["reveal_action"])] = (
                        catalog_name,
                        row,
                    )
    indexed_reveal_names = {
        str(row.get("name"))
        for row in actions
        if row.get("family")
        in {
            "reveal_warp_coordinate",
            "reveal_time_coordinate",
            "reveal_position_chart",
            "reveal_epoch_chart",
        }
    }
    validation.check(
        len(expected_warp_actions) == 595
        and indexed_reveal_names == set(expected_warp_actions),
        "index.explicit_warp_action_set",
        "index must expose exactly the 595 catalog-authored reveal actions; "
        f"missing={sorted(set(expected_warp_actions)-indexed_reveal_names)[:20]}, "
        f"extra={sorted(indexed_reveal_names-set(expected_warp_actions))[:20]}",
        "index.actions",
    )
    for action_name, (catalog_name, destination) in expected_warp_actions.items():
        indexed_action = indexed_actions_by_name.get(action_name)
        fixed = (
            indexed_action.get("fixed_literals")
            if isinstance(indexed_action, Mapping)
            else None
        )
        expected_destination = {
            "catalog": catalog_name,
            "selection_mode": EXPLICIT_SELECTION_MODE,
            **{
                field: destination[field]
                for field in (
                    "code",
                    "uses",
                    "minimum_source_pool_inclusive",
                    "x",
                    "y",
                    "z",
                    "epoch",
                )
                if field in destination
            },
        }
        validation.check(
            isinstance(fixed, Mapping)
            and fixed.get("selection_mode") == EXPLICIT_SELECTION_MODE
            and fixed.get("warp_catalog") == catalog_name
            and fixed.get("destination_code") == destination.get("code")
            and fixed.get("uses") == destination.get("uses")
            and fixed.get("minimum_source_pool_inclusive")
            == destination.get("minimum_source_pool_inclusive")
            and fixed.get("warp_destination") == expected_destination,
            "index.explicit_warp_destination",
            f"{action_name} index metadata must map one action identity to "
            "exactly one catalog row and its singular capacity minimum",
            f"index.actions.{action_name}",
        )
        retired = forbidden_key_paths(fixed, RETIRED_WARP_SELECTION_FIELDS)
        validation.check(
            not retired,
            "index.retired_warp_selection_fields",
            f"{action_name} contains retired selector/band/weight/upper-bound "
            f"metadata: {retired}",
            f"index.actions.{action_name}.fixed_literals",
        )

    expected_survey = {name: (profile, minimum) for name, profile, minimum in SURVEY_SELECTIONS}
    indexed_survey = {
        str(row.get("name")): row
        for row in actions
        if row.get("family") == "survey_sector"
    }
    validation.check(
        set(indexed_survey) == set(expected_survey),
        "index.survey_action_set",
        "index must expose exactly the five deterministic Survey profile actions",
        "index.actions",
    )
    for action_name, (profile, minimum) in expected_survey.items():
        row = indexed_survey.get(action_name)
        fixed = row.get("fixed_literals") if isinstance(row, Mapping) else None
        validation.check(
            isinstance(fixed, Mapping)
            and fixed.get("selection_mode")
            == DETERMINISTIC_SELECTOR_MODE
            and fixed.get("selector_subject") == "sector.stable_identifier"
            and isinstance(fixed.get("selector_band"), Mapping)
            and fixed.get("survey_profile") == profile
            and fixed.get("minimum_claim_serial") == minimum,
            "index.survey_selection",
            f"{action_name} must bind survey profile {profile} to "
            f"claim_serial >= {minimum}",
            f"index.actions.{action_name}",
        )

    expected_civilizations = {
        name: (civilization_type, minimum)
        for name, civilization_type, minimum in CIVILIZATION_SELECTIONS
    }
    indexed_civilizations = {
        str(row.get("name")): row
        for row in actions
        if row.get("family") == "materialize_civilization"
    }
    validation.check(
        set(indexed_civilizations) == set(expected_civilizations),
        "index.civilization_action_set",
        "index must expose exactly the three deterministic Civilization actions",
        "index.actions",
    )
    for action_name, (civilization_type, minimum) in expected_civilizations.items():
        row = indexed_civilizations.get(action_name)
        fixed = row.get("fixed_literals") if isinstance(row, Mapping) else None
        validation.check(
            isinstance(fixed, Mapping)
            and fixed.get("selection_mode")
            == DETERMINISTIC_SELECTOR_MODE
            and fixed.get("selector_subject")
            == "life_signal.stable_identifier"
            and isinstance(fixed.get("selector_band"), Mapping)
            and fixed.get("civilization_type") == civilization_type
            and fixed.get("minimum_civilization_scan_serial") == minimum,
            "index.civilization_selection",
            f"{action_name} must bind civilization type {civilization_type} "
            f"to civilization_scan_serial >= {minimum}",
            f"index.actions.{action_name}",
        )

    scan_rows = [row for row in actions if row.get("family") == "scan_body"]
    validation.check(
        len(scan_rows) == 23,
        "index.scan_action_count",
        f"index must retain exactly 23 named whole-object Scan actions, got {len(scan_rows)}",
        "index.actions",
    )
    for body in states.get("resources", {}).get("bodies", []):
        if not isinstance(body, Mapping):
            continue
        code = first_present(body, "body_id", "body_code", "code")
        action_name = f"ScanCelestialBody_{code:02d}_{body.get('slug')}" if is_int(code) else ""
        row = indexed_actions_by_name.get(action_name)
        fixed = row.get("fixed_literals") if isinstance(row, Mapping) else None
        wrapper_literals = (
            row.get("wrapper_literals") if isinstance(row, Mapping) else None
        )
        validation.check(
            isinstance(fixed, Mapping)
            and fixed.get("candidate_code") == code
            and fixed.get("selection_mode")
            == DETERMINISTIC_SELECTOR_MODE
            and fixed.get("selector_subject") == "signal.stable_identifier"
            and isinstance(fixed.get("selector_band"), Mapping)
            and fixed.get("required_signal_candidate_code") == -1
            and isinstance(wrapper_literals, list),
            "index.scan_threshold_binding",
            f"{action_name} must bind the named candidate and its stable-ID band",
            f"index.actions.{action_name}",
        )
    warp_action_contracts = states.get("warp", {}).get(
        "action_contracts", {}
    )
    if isinstance(warp_action_contracts, Mapping):
        for action_name, expected_roles in warp_action_contracts.items():
            row = indexed_actions_by_name.get(str(action_name))
            actual_roles = []
            if isinstance(row, Mapping):
                roles = row.get("roles")
                if isinstance(roles, list):
                    actual_roles = [
                        (str(role.get("mode")), str(role.get("class")))
                        for role in roles
                        if isinstance(role, Mapping)
                    ]
            validation.check(
                actual_roles == list(expected_roles),
                "index.warp_role_contract",
                f"{action_name} index roles differ from the authored warp "
                f"contract: expected {list(expected_roles)}, got {actual_roles}",
                f"index.actions.{action_name}",
            )
    authored_warp_objects = states.get("warp", {}).get("object_types", [])
    index_warp = index.get("warp")
    indexed_warp_objects = (
        index_warp.get("object_types", [])
        if isinstance(index_warp, Mapping)
        else []
    )
    validation.check(
        isinstance(authored_warp_objects, list)
        and isinstance(indexed_warp_objects, list)
        and [row.get("class_name") for row in indexed_warp_objects if isinstance(row, Mapping)]
        == list(EXPECTED_WARP_OBJECT_SCHEMAS),
        "index.warp_schema_classes",
        "generated index must enumerate the exact nine warp schema classes in order",
        "index.warp.object_types",
    )
    authored_warp_by_class = {
        str(row.get("class_name")): row
        for row in authored_warp_objects
        if isinstance(row, Mapping)
    } if isinstance(authored_warp_objects, list) else {}
    indexed_warp_by_class = {
        str(row.get("class_name")): row
        for row in indexed_warp_objects
        if isinstance(row, Mapping)
    } if isinstance(indexed_warp_objects, list) else {}
    for class_name, expected_schema in EXPECTED_WARP_OBJECT_SCHEMAS.items():
        expected_fields = [
            {"name": field_name, "type": field_type}
            for field_name, field_type in expected_schema
        ]
        authored_fields = authored_warp_by_class.get(class_name, {}).get(
            "schema_fields"
        )
        indexed_fields = indexed_warp_by_class.get(class_name, {}).get(
            "schema_fields"
        )
        validation.check(
            authored_fields == expected_fields
            and indexed_fields == expected_fields
            and indexed_fields == authored_fields,
            "index.warp_schema_exact",
            f"{class_name} catalog/index schema must both equal the exact "
            f"protocol schema; catalog={authored_fields}, index={indexed_fields}",
            f"index.warp.object_types.{class_name}",
        )
    for action_index, action in enumerate(actions):
        wrapper_literals = action.get("wrapper_literals")
        validation.check(
            isinstance(wrapper_literals, list)
            and all(
                isinstance(value, (str, int, bool))
                for value in wrapper_literals
            ),
            "index.wrapper_literals",
            "every indexed action must declare a flat scalar wrapper_literals list",
            f"index.actions[{action_index}]",
        )
        helpers = action.get("helpers")
        validation.check(
            isinstance(helpers, list)
            and len(helpers) == len(set(helpers))
            and all(isinstance(value, str) and value for value in helpers),
            "index.helpers",
            "every indexed action must declare a unique flat helpers list",
            f"index.actions[{action_index}]",
        )
    counts = index.get("counts")
    if isinstance(counts, Mapping):
        declared_actions = first_present(counts, "actions", "action_count")
        validation.check(
            declared_actions == len(actions),
            "index.action_count",
            f"index declares {declared_actions!r} actions, enumerates {len(actions)}",
            "index.counts",
        )
    production = production_rows(index)
    validation.check(
        bool(production),
        "index.production",
        "generated index must enumerate exact resource production provenance",
        "index",
    )
    gates = logical_skill_gates(index)
    validation.check(
        bool(gates),
        "index.skill_gates",
        "generated index must enumerate logical resource skill gates",
        "index",
    )


def validate_schema_sidecar(
    sidecar: Mapping[str, Any],
    path: Path,
    validation: Validation,
    warp_state: Mapping[str, Any],
    index: Mapping[str, Any],
) -> None:
    """Cross-check all class field types and exact warp schemas end-to-end."""
    classes = sidecar.get("classes")
    validation.check(
        isinstance(classes, Mapping) and len(classes) == 20,
        "schema_sidecar.class_count",
        "schema sidecar must enumerate exactly all 20 production classes",
        str(path),
    )
    if not isinstance(classes, Mapping):
        return
    for class_name, class_row in classes.items():
        fields = class_row.get("fields") if isinstance(class_row, Mapping) else None
        schema = [
            (str(row.get("name")), str(row.get("type")))
            for row in fields
            if isinstance(row, Mapping)
        ] if isinstance(fields, list) else []
        validation.check(
            isinstance(fields, list)
            and len(schema) == len(fields)
            and len(schema) == len({field_name for field_name, _ in schema})
            and all(
                field_type == expected_schema_field_type(field_name)
                for field_name, field_type in schema
            ),
            "schema_sidecar.field_types",
            f"{class_name} must list unique fields with Raw identifiers/ids/key "
            "and Int numeric fields; no coercion is allowed",
            f"{path}:{class_name}",
        )
        validation.check(
            isinstance(class_row, Mapping)
            and class_row.get("listed_key_count") == len(schema)
            and class_row.get("sdk_managed_live_fields") == ["type", "work"],
            "schema_sidecar.class_metadata",
            f"{class_name} sidecar count/SDK-managed fields mismatch",
            f"{path}:{class_name}",
        )

    authored_objects = warp_state.get("object_types", [])
    authored_by_class = {
        str(row.get("class_name")): row
        for row in authored_objects
        if isinstance(row, Mapping)
    } if isinstance(authored_objects, list) else {}
    index_warp = index.get("warp")
    indexed_objects = (
        index_warp.get("object_types", [])
        if isinstance(index_warp, Mapping)
        else []
    )
    indexed_by_class = {
        str(row.get("class_name")): row
        for row in indexed_objects
        if isinstance(row, Mapping)
    } if isinstance(indexed_objects, list) else {}
    for class_name, expected_schema in EXPECTED_WARP_OBJECT_SCHEMAS.items():
        expected_fields = [
            {"name": field_name, "type": field_type}
            for field_name, field_type in expected_schema
        ]
        sidecar_row = classes.get(class_name)
        sidecar_fields = (
            sidecar_row.get("fields") if isinstance(sidecar_row, Mapping) else None
        )
        authored_fields = authored_by_class.get(class_name, {}).get("schema_fields")
        indexed_fields = indexed_by_class.get(class_name, {}).get("schema_fields")
        validation.check(
            sidecar_fields == expected_fields
            and authored_fields == expected_fields
            and indexed_fields == expected_fields,
            "schema_sidecar.warp_exact",
            f"{class_name} must match exactly across catalog, generated index, "
            f"and schema sidecar",
            f"{path}:{class_name}",
        )


def validate_universe_selection_contract(
    universe: Mapping[str, Any],
    path: Path,
    validation: Validation,
    index: Mapping[str, Any],
) -> None:
    """Cross-bind explicit Survey/Civilization unlock metadata."""
    expected_surveys = (
        (1, "Sparse", 4),
        (2, "Standard", 8),
        (3, "Rich", 32),
        (4, "Ancient", 128),
        (5, "Anomalous", 256),
    )
    expected_civilizations = (
        (1, "Type I Civilization", "TypeI", "I", 64),
        (2, "Type II Civilization", "TypeII", "II", 1_024),
        (3, "Type III Civilization", "TypeIII", "III", 16_384),
    )
    surveys = universe.get("survey_profiles")
    civilizations = universe.get("civilization_types")
    validation.check(
        isinstance(surveys, list) and len(surveys) == 5,
        "universe.survey_profiles",
        "universe contract must contain exactly five Survey profile rows",
        str(path),
    )
    validation.check(
        isinstance(civilizations, list) and len(civilizations) == 3,
        "universe.civilization_types",
        "universe contract must contain exactly three Civilization type rows",
        str(path),
    )
    survey_rows = surveys if isinstance(surveys, list) else []
    civilization_rows = civilizations if isinstance(civilizations, list) else []
    index_actions = {
        row.get("name"): row
        for row in index.get("actions", [])
        if isinstance(row, Mapping) and isinstance(row.get("name"), str)
    }
    for offset, (code, slug, minimum) in enumerate(expected_surveys):
        row = survey_rows[offset] if offset < len(survey_rows) else {}
        action = f"SurveySector_{code:02d}_{slug}"
        validation.check(
            isinstance(row, Mapping)
            and set(row)
            == {
                "code",
                "name",
                "slug",
                "selection_mode",
                "minimum_claim_serial",
                "counts",
                "survey_profile",
                "action",
            }
            and row.get("code") == code
            and row.get("name") == slug
            and row.get("slug") == slug
            and row.get("selection_mode") == DETERMINISTIC_SELECTOR_MODE
            and row.get("minimum_claim_serial") == minimum
            and row.get("survey_profile") == code
            and row.get("action") == action
            and isinstance(row.get("counts"), Mapping),
            "universe.survey_profile_row",
            f"Survey profile {code} metadata/action binding changed",
            f"{path}:survey_profiles[{offset}]",
        )
        fixed = index_actions.get(action, {}).get("fixed_literals", {})
        validation.check(
            isinstance(fixed, Mapping)
            and fixed.get("selection_mode") == DETERMINISTIC_SELECTOR_MODE
            and fixed.get("selector_subject") == "sector.stable_identifier"
            and isinstance(fixed.get("selector_band"), Mapping)
            and fixed.get("survey_profile") == code
            and fixed.get("minimum_claim_serial") == minimum,
            "universe.survey_index_binding",
            f"Survey profile {code} does not match indexed action literals",
            f"{path}:survey_profiles[{offset}]",
        )
    for offset, (code, name, slug, suffix, minimum) in enumerate(
        expected_civilizations
    ):
        row = (
            civilization_rows[offset]
            if offset < len(civilization_rows)
            else {}
        )
        action = f"MaterializeCivilizationType{suffix}"
        validation.check(
            isinstance(row, Mapping)
            and set(row)
            == {
                "code",
                "name",
                "slug",
                "action",
                "selection_mode",
                "minimum_civilization_scan_serial",
            }
            and row.get("code") == code
            and row.get("name") == name
            and row.get("slug") == slug
            and row.get("action") == action
            and row.get("selection_mode") == DETERMINISTIC_SELECTOR_MODE
            and row.get("minimum_civilization_scan_serial") == minimum,
            "universe.civilization_type_row",
            f"Civilization type {code} metadata/action binding changed",
            f"{path}:civilization_types[{offset}]",
        )
        fixed = index_actions.get(action, {}).get("fixed_literals", {})
        validation.check(
            isinstance(fixed, Mapping)
            and fixed.get("selection_mode") == DETERMINISTIC_SELECTOR_MODE
            and fixed.get("selector_subject")
            == "life_signal.stable_identifier"
            and isinstance(fixed.get("selector_band"), Mapping)
            and fixed.get("civilization_type") == code
            and fixed.get("minimum_civilization_scan_serial") == minimum,
            "universe.civilization_index_binding",
            f"Civilization type {code} does not match indexed action literals",
            f"{path}:civilization_types[{offset}]",
        )
    expected_policy = {
        "selection_mode": DETERMINISTIC_SELECTOR_MODE,
        "outcome_source": "immutable stable-ID hierarchy",
        "stable_identifier_used": True,
        "unlock_scope": "current compatible Ship",
        "transfer_policy": (
            "Any compatible co-located Ship that meets the milestone may "
            "service a stored Sector or LifeSignal; the creator Ship is not "
            "bound."
        ),
        "retroactivity": (
            "Stored compatible Sectors and LifeSignals remain usable after a "
            "Ship reaches a later milestone."
        ),
        "survey": {
            "counter_field": "claim_serial",
            "counter_meaning": (
                "claims completed by the current Ship, not distinct coordinates"
            ),
            "minimums_by_profile": {
                "1": 4,
                "2": 8,
                "3": 32,
                "4": 128,
                "5": 256,
            },
            "selected_profile_is_unique": True,
        },
        "civilization": {
            "counter_field": "civilization_scan_serial",
            "counter_meaning": (
                "qualifying intelligent-life detections completed by the "
                "current Ship"
            ),
            "minimums_by_type": {"1": 64, "2": 1_024, "3": 16_384},
            "selected_type_is_unique": True,
        },
        "root_skill": {
            "selector_field": (
                "civilization.source_life_signal_identifier"
            ),
            "band_count_per_civilization_type": 6,
        },
        "advanced_resource": {
            "selector_field": "body.source_signal_identifier",
            "partition_scope": (
                "candidate_code + required skill + reserve pool"
            ),
        },
        "intelligent_life": {
            "action": "DetectIntelligentLife",
            "selector_field": "body.source_signal_identifier",
            "eligible_candidate_codes": [4, 5],
            "initial_life_stat": 0,
            "selected_life_stat": 1,
            "selection_mode": DETERMINISTIC_SELECTOR_MODE,
            "selector_band": {
                "lower_top_limb": 8_974_091_709_444_932_912,
                "upper_top_limb": 10_220_493_335_756_729_149,
            },
        },
    }
    life_fixed = index_actions.get("DetectIntelligentLife", {}).get(
        "fixed_literals", {}
    )
    validation.check(
        isinstance(life_fixed, Mapping)
        and life_fixed.get("selection_mode")
        == DETERMINISTIC_SELECTOR_MODE
        and life_fixed.get("selector_subject")
        == "body.source_signal_identifier"
        and life_fixed.get("selector_band")
        == expected_policy["intelligent_life"]["selector_band"]
        and life_fixed.get("initial_life_stat") == 0
        and life_fixed.get("selected_life_stat") == 1
        and life_fixed.get("candidate_codes") == [4, 5],
        "universe.intelligent_life_index_binding",
        "Intelligent-life stable-ID transition does not match the index",
        str(path),
    )
    validation.check(
        universe.get("selection_progression_policy") == expected_policy,
        "universe.selection_progression_policy",
        "deterministic current-Ship unlock/transfer policy changed",
        str(path),
    )


def strip_rhai_comments(source: str) -> str:
    # Mask strings and comments in one lexical pass so comment markers inside a
    # string cannot accidentally hide live code that follows the string.
    pattern = re.compile(
        r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/',
        re.DOTALL,
    )

    def mask(match: re.Match[str]) -> str:
        value = match.group(0)
        if value.startswith('"'):
            return '""' + "\n" * value.count("\n")
        return "".join("\n" if char == "\n" else " " for char in value)

    return pattern.sub(mask, source)


def mask_rhai_comments(source: str) -> str:
    """Mask comments while retaining quoted Rhai literals for source contracts."""
    pattern = re.compile(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/', re.DOTALL)

    def mask(match: re.Match[str]) -> str:
        value = match.group(0)
        return value if value.startswith('"') else "".join(
            "\n" if char == "\n" else " " for char in value
        )

    return pattern.sub(mask, source)


def extract_rhai_functions(source: str) -> dict[str, str]:
    functions: dict[str, str] = {}
    structural_source = mask_rhai_comments(source)
    header = re.compile(r"(?m)^fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")
    for match in header.finditer(structural_source):
        name = match.group(1)
        open_brace = structural_source.find("{", match.end())
        if open_brace < 0:
            continue
        depth = 0
        in_string = False
        escaped = False
        end = None
        for index in range(open_brace, len(structural_source)):
            char = structural_source[index]
            if in_string:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    in_string = False
                continue
            if char == '"':
                in_string = True
            elif char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    end = index + 1
                    break
        if end is not None:
            functions[name] = source[match.start() : end]
    return functions


def flattened_unsafe_witness_scope(
    action_name: str,
    functions: Mapping[str, str],
    action_names: set[str],
) -> tuple[list[tuple[str, str]], list[str]]:
    """Model rc.43's flattened symbolic scope for named unsafe witnesses.

    The installed evaluator expands plain helper calls into the calling
    action's symbolic scope.  A ``var name = unsafe { ... }`` declaration in a
    wrapper therefore collides with the same witness name in any transitively
    called helper (or in a helper reached more than once).  Ordinary Rhai
    locals intentionally are not included: rc.43 permits harmless repeated
    names such as ``work`` in separate function scopes.
    """

    witnesses: list[tuple[str, str]] = []
    cycles: list[str] = []

    def visit(function_name: str, path: tuple[str, ...]) -> None:
        if function_name in path:
            cycles.append(" -> ".join((*path, function_name)))
            return
        source = functions.get(function_name)
        if not source:
            return
        masked = strip_rhai_comments(source)
        body = masked[masked.find("{") + 1 :]
        origin = " -> ".join((*path, function_name))
        for witness_name in re.findall(
            r"\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*unsafe\s*\{",
            body,
        ):
            witnesses.append((witness_name, origin))
        calls = re.findall(
            r"(?<![.A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(",
            body,
        )
        next_path = (*path, function_name)
        for callee in calls:
            if callee in functions and callee not in action_names:
                visit(callee, next_path)

    visit(action_name, ())
    return witnesses, cycles


WITNESSED_ANCHOR_CONSTRUCTORS: dict[str, dict[str, Any]] = {
    "ConstructWormholeLink": {
        "target": "link",
        "target_class": "MicroverseWormholeLink",
        "skill_code": 59,
        "roles": (
            ("output", "MicroverseWormholeLink"),
            ("input", "MicroversePositionAnchor"),
            ("input", "MicroversePositionAnchor"),
            ("input", "MicroverseResource"),
            ("input", "MicroverseResource"),
            ("mutate", "MicroverseShip"),
        ),
        "set_fields": (
            "schema_version", "mechanics_version", "universe_version",
            "link_version", "endpoint_a_anchor_identifier", "endpoint_a_x",
            "endpoint_a_y", "endpoint_a_z", "endpoint_b_anchor_identifier",
            "endpoint_b_x", "endpoint_b_y", "endpoint_b_z", "uses_remaining",
        ),
        "anchors": (
            (
                "anchor_a", "endpoint_a_anchor_identifier",
                (("x", "endpoint_a_x"), ("y", "endpoint_a_y"), ("z", "endpoint_a_z")),
            ),
            (
                "anchor_b", "endpoint_b_anchor_identifier",
                (("x", "endpoint_b_x"), ("y", "endpoint_b_y"), ("z", "endpoint_b_z")),
            ),
        ),
    },
    "ConstructTemporalLink": {
        "target": "link",
        "target_class": "MicroverseTemporalLink",
        "skill_code": 60,
        "roles": (
            ("output", "MicroverseTemporalLink"),
            ("input", "MicroverseTimeAnchor"),
            ("input", "MicroverseTimeAnchor"),
            ("input", "MicroverseResource"),
            ("input", "MicroverseResource"),
            ("mutate", "MicroverseShip"),
        ),
        "set_fields": (
            "schema_version", "mechanics_version", "universe_version",
            "link_version", "endpoint_a_anchor_identifier", "endpoint_a_epoch",
            "endpoint_b_anchor_identifier", "endpoint_b_epoch", "uses_remaining",
        ),
        "anchors": (
            ("anchor_a", "endpoint_a_anchor_identifier", (("epoch", "endpoint_a_epoch"),)),
            ("anchor_b", "endpoint_b_anchor_identifier", (("epoch", "endpoint_b_epoch"),)),
        ),
    },
    "ComposeRendezvousCoordinate": {
        "target": "coordinate",
        "target_class": "MicroverseRendezvousCoordinate",
        "skill_code": 86,
        "roles": (
            ("output", "MicroverseRendezvousCoordinate"),
            ("input", "MicroversePositionAnchor"),
            ("input", "MicroverseTimeAnchor"),
            ("input", "MicroverseResource"),
            ("input", "MicroverseResource"),
            ("mutate", "MicroverseShip"),
        ),
        "set_fields": (
            "schema_version", "mechanics_version", "universe_version",
            "coordinate_version", "position_anchor_identifier", "destination_x",
            "destination_y", "destination_z", "time_anchor_identifier",
            "destination_epoch", "uses_remaining",
        ),
        "anchors": (
            (
                "position_anchor", "position_anchor_identifier",
                (("x", "destination_x"), ("y", "destination_y"), ("z", "destination_z")),
            ),
            ("time_anchor", "time_anchor_identifier", (("epoch", "destination_epoch"),)),
        ),
    },
}

CHART_DESTINATION_INITIALIZERS: dict[str, tuple[str, ...]] = {
    "ExtractWormholeWarpChart": (
        "destination_x",
        "destination_y",
        "destination_z",
    ),
    "ExtractWormholeEpochChart": ("destination_epoch",),
}

CHART_EXTRACTION_SET_FIELDS: dict[str, tuple[str, ...]] = {
    "ExtractWormholeWarpChart": (
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
    "ExtractWormholeEpochChart": (
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
}


def literal_object_set_fields(source: str, handle: str) -> list[list[str]]:
    """Return literal field names for every direct ``handle.set`` call."""
    return [
        re.findall(r'\[\s*"([^"]+)"\s*,', body)
        for body in re.findall(
            rf"\b{re.escape(handle)}\.set\s*\(\s*\[(.*?)\]\s*\)\s*;",
            source,
            flags=re.DOTALL,
        )
    ]


def literal_object_update_pairs(source: str, handle: str) -> list[tuple[str, str]]:
    """Return literal-key updates for one object handle in source order."""
    return [
        (field, value.strip())
        for field, value in re.findall(
            rf'(?m)^\s*{re.escape(handle)}\.update\('
            r'"([^"]+)",\s*([^\r\n]+?)\);\s*$',
            source,
        )
    ]


def compact_rhai_tokens(source: str) -> str:
    """Normalize whitespace outside strings for formatting-independent audits."""
    compacted_lines: list[str] = []
    for source_line in source.splitlines():
        output: list[str] = []
        index = 0
        in_string = False
        escaped = False
        while index < len(source_line):
            char = source_line[index]
            if in_string:
                output.append(char)
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    in_string = False
                index += 1
                continue
            if char == '"':
                in_string = True
                output.append(char)
                index += 1
                continue
            if char == "/" and source_line[index:index + 2] == "//":
                break
            if char.isspace():
                next_index = index + 1
                while next_index < len(source_line) and source_line[next_index].isspace():
                    next_index += 1
                previous = output[-1] if output else ""
                following = source_line[next_index] if next_index < len(source_line) else ""
                if (
                    (previous.isalnum() or previous == "_")
                    and (following.isalnum() or following == "_")
                ):
                    output.append(" ")
                index = next_index
                continue
            output.append(char)
            index += 1
        compacted = "".join(output).strip()
        if compacted:
            compacted_lines.append(compacted)
    return "\n".join(compacted_lines) + "\n"


def ordered_rhai_tokens(source: str, tokens: Sequence[str]) -> bool:
    compact = compact_rhai_tokens(source)
    cursor = 0
    for token in tokens:
        needle = compact_rhai_tokens(token).strip()
        position = compact.find(needle, cursor)
        if not needle or position < 0:
            return False
        cursor = position + len(needle)
    return True


def flat_rhai_call_arguments(source: str, function_name: str) -> list[list[str]]:
    """Extract calls whose arguments contain no nested function calls."""
    return [
        [argument.strip() for argument in arguments.split(",")]
        for arguments in re.findall(
            rf"\b{re.escape(function_name)}\s*\(([^()]*)\)\s*;",
            source,
            flags=re.DOTALL,
        )
    ]


def rhai_named_call_count(source: str, function_name: str) -> int:
    """Count balanced named calls in any expression context."""
    count = 0
    header = re.compile(rf"(?<![.A-Za-z0-9_]){re.escape(function_name)}\s*\(")
    for match in header.finditer(source):
        open_paren = source.find("(", match.start(), match.end())
        depth = 0
        in_string = False
        escaped = False
        close_paren = None
        for index in range(open_paren, len(source)):
            char = source[index]
            if in_string:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    in_string = False
                continue
            if char == '"':
                in_string = True
            elif char == "(":
                depth += 1
            elif char == ")":
                depth -= 1
                if depth == 0:
                    close_paren = index
                    break
        if close_paren is not None:
            count += 1
    return count


def rhai_function_parameters(source: str, name: str) -> list[str]:
    match = re.search(
        rf"\bfn\s+{re.escape(name)}\s*\(([^()]*)\)\s*\{{",
        source,
        flags=re.DOTALL,
    )
    return [item.strip() for item in match.group(1).split(",")] if match else []


def rhai_object_roles(source: str) -> list[tuple[str, str]]:
    return re.findall(
        r'\baction\.(output|input|mutate)\s*\(\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*\)',
        source,
    )


def configured_phase3_survey_fields(
    resource_catalog: Mapping[str, Any] | None,
) -> list[str]:
    """Return the configured 24-field zero-proof order for the Survey canary."""
    fallback = [
        *PHASE3_BASE_SURVEY_FIELDS[:12],
        PHASE3_MINOR_BODY_SURVEY_FIELDS[0],
        *PHASE3_BASE_SURVEY_FIELDS[12:],
        PHASE3_MINOR_BODY_SURVEY_FIELDS[1],
    ]
    categories = (
        resource_catalog.get("celestial_categories", [])
        if isinstance(resource_catalog, Mapping)
        else []
    )
    minor_body = next(
        (
            row
            for row in categories
            if isinstance(row, Mapping) and row.get("category_code") == 11
        ),
        None,
    )
    if not categories:
        return fallback
    if not isinstance(minor_body, Mapping):
        return []
    remaining = minor_body.get("remaining_field")
    serial = minor_body.get("serial_field")
    if (remaining, serial) != PHASE3_MINOR_BODY_SURVEY_FIELDS:
        return []
    return fallback


def validate_phase3_canaries(
    source: str,
    functions: Mapping[str, str],
    action_set: set[str],
    resource_catalog: Mapping[str, Any] | None,
    validation: Validation,
    rhai_path: Path,
) -> None:
    """Fail closed when the released Phase 3 helper-canary shape is present."""
    phase3_present = any(
        token in source
        for token in (
            "fn detect_signal_core(",
            "fn prove_empty_survey_sector_core(",
            "detect_signal_core(",
            "prove_empty_survey_sector_core(",
        )
    )
    if not phase3_present:
        return

    detect_core = functions.get("detect_signal_core", "")
    survey_core = functions.get("prove_empty_survey_sector_core", "")
    detect_wrapper = functions.get(PHASE3_DETECT_ACTION, "")
    survey_wrapper = functions.get(PHASE3_SURVEY_ACTION, "")
    expected_fields = configured_phase3_survey_fields(resource_catalog)
    helper_forbidden = (
        r"\baction\.(?:output|input|mutate)\s*\(", r"\b(?:if|for|while|match)\b",
        r"#\{", r"\.call\s*\(", r"\bsubaction\s*\(",
    )
    helper_code = tuple(strip_rhai_comments(item) for item in (detect_core, survey_core))
    validation.check(
        source.count("fn detect_signal_core(") == 1
        and source.count("fn prove_empty_survey_sector_core(") == 1
        and rhai_function_parameters(detect_core, "detect_signal_core")
        == list(PHASE3_DETECT_PARAMETERS)
        and rhai_function_parameters(survey_core, "prove_empty_survey_sector_core")
        == list(PHASE3_SURVEY_PARAMETERS),
        "rhai.phase3_helper_definitions",
        "Phase 3 canaries require exactly one fixed-arity detect and Survey helper",
        str(rhai_path),
    )
    validation.check(
        bool(detect_core)
        and bool(survey_core)
        and all(
            not re.search(pattern, helper)
            for helper in helper_code
            for pattern in helper_forbidden
        ),
        "rhai.phase3_helper_straight_line",
        "Phase 3 helpers may not declare roles or contain control flow, maps, dispatch, or subactions",
        str(rhai_path),
    )
    actual_zero_fields = re.findall(
        r"action\.st_sum\(sector\.([A-Za-z0-9_]+),\s*0,\s*0\);",
        survey_core,
    )
    validation.check(
        len(expected_fields) == 24
        and actual_zero_fields == expected_fields
        and survey_core.count("action.st_sum(") == len(expected_fields)
        and "revision" not in strip_rhai_comments(survey_core),
        "rhai.phase3_survey_zero_proof",
        "Survey helper must contain the configured ordered 24 zero assertions, including Minor-Body Field, and no revision work",
        f"{rhai_path}:prove_empty_survey_sector_core",
    )
    validation.check(
        rhai_object_roles(detect_wrapper)
        == [
            ("output", "MicroverseShip"),
            ("output", "MicroverseCelestialSignal"),
            ("input", "MicroverseShip"),
            ("mutate", "MicroverseSector"),
        ]
        and flat_rhai_call_arguments(detect_wrapper, "detect_signal_core")
        == [[
            "action", "next_ship", "signal", "ship", "sector", "2", "0",
            '"star_remaining"', '"next_star_serial"',
        ]],
        "rhai.phase3_detect_wrapper",
        "DetectCelestialSignal_00_RedDwarf must retain direct roles and one exact 9-argument helper call",
        f"{rhai_path}:{PHASE3_DETECT_ACTION}",
    )
    for candidate_code, slug, category_code, remaining_field, serial_field in PHASE3_DETECT_SELECTIONS:
        action_name = f"DetectCelestialSignal_{candidate_code:02d}_{slug}"
        wrapper = functions.get(action_name, "")
        validation.check(
            rhai_object_roles(wrapper)
            == [("output", "MicroverseShip"), ("output", "MicroverseCelestialSignal"), ("input", "MicroverseShip"), ("mutate", "MicroverseSector")]
            and flat_rhai_call_arguments(wrapper, "detect_signal_core")
            == [["action", "next_ship", "signal", "ship", "sector", str(category_code), str(candidate_code), f'"{remaining_field}"', f'"{serial_field}"']],
            "rhai.phase3_detect_wrapper",
            f"{action_name} must retain direct roles and its exact category/candidate/remaining/serial helper arguments",
            f"{rhai_path}:{action_name}",
        )
    validation.check(
        rhai_object_roles(survey_wrapper)
        == [
            ("output", "MicroverseShip"),
            ("input", "MicroverseShip"),
            ("mutate", "MicroverseSector"),
        ]
        and flat_rhai_call_arguments(survey_wrapper, "survey_replacement_ship_core")
        == [["action", "next_ship", "ship", "sector"]]
        and flat_rhai_call_arguments(survey_wrapper, "prove_empty_survey_sector_core")
        == [["action", "sector"]]
        and survey_wrapper.count("sector.revision") == 2,
        "rhai.phase3_survey_wrapper",
        "SurveySector_01_Sparse must keep direct roles, ship replacement, and revision work outside its one helper call",
        f"{rhai_path}:{PHASE3_SURVEY_ACTION}",
    )
    detect_routes = {
        name
        for name in action_set
        if name.startswith("DetectCelestialSignal_")
        and flat_rhai_call_arguments(functions.get(name, ""), "detect_signal_core")
    }
    survey_routes = {
        name
        for name in action_set
        if name.startswith("SurveySector_")
        and flat_rhai_call_arguments(
            functions.get(name, ""), "prove_empty_survey_sector_core"
        )
    }
    validation.check(
        detect_routes
        == {name for name in action_set if name.startswith("DetectCelestialSignal_")}
        and survey_routes
        == {name for name in action_set if name.startswith("SurveySector_")},
        "rhai.phase3_bulk_routing",
        "every Detect and Survey wrapper must route exactly once through its Phase 3 helper",
        str(rhai_path),
    )
    compact_detect_core = compact_rhai_tokens(detect_core)
    validation.check(
        all(
            compact_rhai_tokens(token).strip() in compact_detect_core
            for token in (
                "action.st_gt(sector[remaining_field], 0);",
                "action.st_sum(sector[serial_field], 0, slot_serial);",
                "sector.update(remaining_field, next_remaining);",
                "sector.update(serial_field, next_serial);",
                '["category_code", category_code]',
                '["candidate_code", candidate_code]',
            )
        ),
        "rhai.phase3_detect_field_closure",
        "Detect helper must preserve category/candidate and remaining/serial field closure",
        f"{rhai_path}:detect_signal_core",
    )


def rhai_extraction_core_names(source: str) -> set[str]:
    """Return extraction/refinement core calls, excluding SDK method calls."""
    return {
        name
        for name in re.findall(
            r"(?<![.A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(",
            strip_rhai_comments(source),
        )
        if name.endswith("_core")
        and ("extract_" in name or "refine_" in name)
    }


def phase4_adapter_like_names(source: str) -> set[str]:
    """Return Phase 4 adapter names, including forged marker-bearing names."""
    markers = (
        "extract_base_vdf_", "extract_direct_body_vdf_",
        "extract_composite_vdf_", "refine_resource_vdf_",
        "extract_direct_body_no_vdf_", "extract_composite_no_vdf_",
        "refine_resource_no_vdf_",
    )
    return {
        name for name in rhai_extraction_core_names(source)
        if any(marker in name for marker in markers)
    }


def phase4_expected_call_arguments(
    index: Mapping[str, Any],
    resource_catalog: Mapping[str, Any] | None,
    action_name: str,
    kind: str,
) -> list[str] | None:
    """Derive one adapter call from catalog-index and capacity metadata."""
    action_rows = index.get("actions")
    if not isinstance(action_rows, list) or not isinstance(resource_catalog, Mapping):
        return None
    action = next(
        (
            row for row in action_rows
            if isinstance(row, Mapping) and row.get("name") == action_name
        ),
        None,
    )
    if not isinstance(action, Mapping):
        return None
    fixed = action.get("fixed_literals")
    wrapper_literals = action.get("wrapper_literals")
    capacity_tiers = resource_catalog.get("capacity_tiers")
    if not isinstance(fixed, Mapping) or not isinstance(wrapper_literals, list):
        return None
    tier_name = fixed.get("extraction_ship_tier")
    tier = next(
        (
            row for row in capacity_tiers or []
            if isinstance(row, Mapping) and row.get("name") == tier_name
        ),
        None,
    )
    remaining_fields = [
        value for value in wrapper_literals
        if isinstance(value, str) and value.endswith("_remaining")
    ]
    if kind == "base":
        code_rows = index.get("resource_code_rows")
        base_action = fixed.get("base_extraction_action")
        resource_name = (
            base_action.removeprefix("Extract")
            if isinstance(base_action, str)
            else None
        )
        resource_code = next(
            (
                row.get("code") for row in code_rows or []
                if isinstance(row, Mapping) and row.get("name") == resource_name
            ),
            None,
        )
        extraction_amount = tier.get("extraction_amount") if isinstance(tier, Mapping) else None
        rare_extraction_amount = (
            tier.get("rare_extraction_amount") if isinstance(tier, Mapping) else None
        )
        if (
            not isinstance(tier, Mapping)
            or len(remaining_fields) != 1
            or not isinstance(resource_code, int)
            or not isinstance(extraction_amount, int)
            or not isinstance(rare_extraction_amount, int)
        ):
            return None
        return [
            "action", "next_ship", "resource", "ship", "body", "0",
            json.dumps(remaining_fields[0]), str(resource_code),
            str(extraction_amount), str(rare_extraction_amount),
        ]

    if kind in {"body", "composite"}:
        candidate_code = fixed.get("candidate_code")
        resource_code = fixed.get("resource_code")
        skill_code = fixed.get("skill_code", 0)
        extraction_amount = tier.get("extraction_amount") if isinstance(tier, Mapping) else None
        rare_extraction_amount = (
            tier.get("rare_extraction_amount") if isinstance(tier, Mapping) else None
        )
        if (
            not isinstance(tier, Mapping)
            or len(remaining_fields) != 1
            or not isinstance(candidate_code, int)
            or not isinstance(resource_code, int)
            or not isinstance(skill_code, int)
            or not isinstance(extraction_amount, int)
            or not isinstance(rare_extraction_amount, int)
        ):
            return None
        output_handle = "composite_resource" if kind == "composite" else "resource"
        expected = [
            "action", "next_ship", output_handle, "ship", "body",
            str(candidate_code), str(skill_code), json.dumps(remaining_fields[0]),
            str(resource_code), str(extraction_amount),
            str(rare_extraction_amount),
        ]
        if kind == "body":
            return expected
        split = next(
            (
                row for row in resource_catalog.get("legacy_parent_splits", [])
                if isinstance(row, Mapping)
                and row.get("parent_resource_id") == resource_code
            ),
            None,
        )
        if not isinstance(split, Mapping):
            split = next(
                (
                    row for row in resource_catalog.get("source_resources", [])
                    if isinstance(row, Mapping)
                    and row.get("resource_id") == resource_code
                    and row.get("role") == "composite"
                ),
                None,
            )
        split_profile_id = (
            split.get("split_profile_id") if isinstance(split, Mapping) else None
        )
        split_profile = next(
            (
                row for row in resource_catalog.get("split_profiles", [])
                if isinstance(row, Mapping)
                and row.get("split_profile_id") == split_profile_id
            ),
            None,
        )
        tier_outputs = (
            split_profile.get("tier_output_amounts")
            if isinstance(split_profile, Mapping)
            else None
        )
        child_amounts = (
            tier_outputs.get(tier_name)
            if isinstance(tier_outputs, Mapping) and isinstance(tier_name, str)
            else None
        )
        if (
            not isinstance(child_amounts, list)
            or len(child_amounts) != 3
            or any(not isinstance(amount, int) for amount in child_amounts)
        ):
            return None
        if sum(child_amounts) != extraction_amount:
            return None
        return [*expected, *(str(amount) for amount in child_amounts)]

    if kind == "refine":
        child_fields = [
            value for value in wrapper_literals
            if isinstance(value, str)
            and re.fullmatch(r"child_[1-3]_remaining", value)
        ]
        skill_code = fixed.get("skill_code")
        parent_code = fixed.get("parent_resource_code")
        output_code = fixed.get("resource_code")
        if (
            len(child_fields) != 1
            or not all(isinstance(value, int) for value in (skill_code, parent_code, output_code))
        ):
            return None
        return [
            "action", "next_ship", "resource", "ship", "parent",
            str(skill_code), str(parent_code), json.dumps(child_fields[0]),
            str(output_code),
        ]
    return None


def phase4_core_call_arguments(kind: str) -> tuple[str, list[str]]:
    """Return the sole underlying fixed core call permitted in an adapter."""
    if kind in {"base", "body"}:
        return (
            "extract_direct_resource_core",
            ["action", "next_ship", "resource", "ship", "body", "remaining_field", "resource_type", "extraction_amount", "rare_extraction_amount"],
        )
    if kind == "composite":
        return (
            "extract_composite_resource_core",
            ["action", "next_ship", "composite_resource", "ship", "body", "remaining_field", "composite_resource_type", "extraction_amount", "rare_extraction_amount", "child_1_amount", "child_2_amount", "child_3_amount"],
        )
    return (
        "refine_resource_core",
        ["action", "next_ship", "resource", "ship", "parent", "required_skill_type", "parent_resource_type", "child_remaining_field", "output_resource_type"],
    )


def phase4_literal_vdf_tail_exact(source: str, iterations: int, target: str) -> bool:
    """Require one adjacent, named literal VDF result-to-work update tail."""
    masked = re.sub(r"//[^\n]*|/\*.*?\*/", "", source, flags=re.DOTALL)
    tail = re.compile(
        rf"\bvar\s+work\s*=\s*action\.intro_vdf\(\s*{iterations}\s*,\s*"
        rf"{re.escape(target)}\s*\)\s*;\s*{re.escape(target)}\.update\(\s*"
        r'"work"\s*,\s*work\s*\)\s*;'
    )
    return (
        len(tail.findall(masked)) == 1
        and len(re.findall(r"\baction\.intro_vdf\s*\(", masked)) == 1
        and len(re.findall(r'\.[Uu]pdate\s*\(\s*"work"', masked)) == 1
    )


def phase4_index_action_kind(action: Mapping[str, Any]) -> str | None:
    """Classify one indexed resource-family action into its fixed adapter kind."""
    family = action.get("family")
    if family == "extract_resource":
        return "base"
    if family == "refine_resource":
        return "refine"
    if family != "extract_civilization_tech_resource":
        return None
    roles = action.get("roles")
    if not isinstance(roles, list) or len(roles) != 4:
        return None
    output_class = roles[1].get("class") if isinstance(roles[1], Mapping) else None
    if output_class == "MicroverseResource":
        return "body"
    if output_class == "MicroverseCompositeResource":
        return "composite"
    return None


def phase4_expected_roles(kind: str) -> list[tuple[str, str]]:
    output_class = (
        "MicroverseCompositeResource"
        if kind == "composite"
        else "MicroverseResource"
    )
    mutate_class = (
        "MicroverseCompositeResource"
        if kind == "refine"
        else "MicroverseCelestialBody"
    )
    return [
        ("output", "MicroverseShip"),
        ("output", output_class),
        ("input", "MicroverseShip"),
        ("mutate", mutate_class),
    ]


def phase4_index_roles(action: Mapping[str, Any]) -> list[tuple[str, str]]:
    roles = action.get("roles")
    if not isinstance(roles, list):
        return []
    normalized: list[tuple[str, str]] = []
    for role in roles:
        if not isinstance(role, Mapping):
            return []
        mode = role.get("mode")
        class_name = role.get("class")
        if not isinstance(mode, str) or not isinstance(class_name, str):
            return []
        normalized.append((mode, class_name))
    return normalized


def phase4_wrapper_body_exact(
    wrapper: str,
    kind: str,
    helper_name: str,
    arguments: Sequence[str],
) -> bool:
    """Require four direct roles followed by one adapter call and nothing else."""
    output_handle = "composite_resource" if kind == "composite" else "resource"
    output_class = (
        "MicroverseCompositeResource"
        if kind == "composite"
        else "MicroverseResource"
    )
    mutate_handle = "parent" if kind == "refine" else "body"
    mutate_class = (
        "MicroverseCompositeResource"
        if kind == "refine"
        else "MicroverseCelestialBody"
    )
    expected = "\n".join((
        'var next_ship = action.output("MicroverseShip");',
        f'var {output_handle} = action.output("{output_class}");',
        'var ship = action.input("MicroverseShip");',
        f'var {mutate_handle} = action.mutate("{mutate_class}");',
        f"{helper_name}({', '.join(arguments)});",
    ))
    open_brace = wrapper.find("{")
    close_brace = wrapper.rfind("}")
    if open_brace < 0 or close_brace <= open_brace:
        return False
    actual = wrapper[open_brace + 1 : close_brace]
    def normalized(value: str) -> str:
        return compact_rhai_tokens(value).replace("\n", "")

    return normalized(actual) == normalized(expected)


def phase4_current_wrapper_exact(
    wrapper: str,
    kind: str,
    helper_name: str,
) -> bool:
    """Validate the current-profile adapter shape without economy literals."""
    parameters = PHASE4_HELPER_PARAMETERS[kind]
    calls = flat_rhai_call_arguments(wrapper, helper_name)
    wrapper_calls = phase4_adapter_like_names(wrapper)
    return (
        rhai_object_roles(wrapper) == phase4_expected_roles(kind)
        and wrapper_calls == {helper_name}
        and len(calls) == 1
        and len(calls[0]) == len(parameters)
        and "intro_vdf" not in wrapper
        and not re.search(r'\.update\s*\(\s*"work"', wrapper)
        and not (rhai_extraction_core_names(wrapper) & {
            "extract_direct_resource_core", "extract_composite_resource_core",
            "refine_resource_core",
        })
    )


def phase4_current_expected_helper(action: Mapping[str, Any]) -> str | None:
    """Resolve one indexed resource action to its frozen current adapter."""
    kind = phase4_index_action_kind(action)
    if kind == "body":
        return "extract_direct_body_no_vdf_core"
    if kind == "composite":
        return "extract_composite_no_vdf_core"
    if kind == "refine":
        return "refine_resource_no_vdf_core"
    fixed = action.get("fixed_literals")
    base_action = fixed.get("base_extraction_action") if isinstance(fixed, Mapping) else None
    return {
        "ExtractMatter": "extract_base_vdf_4_core",
        "ExtractCrystal": "extract_base_vdf_8_core",
        "ExtractGas": "extract_base_vdf_8_core",
        "ExtractEnergy": "extract_base_vdf_12_core",
    }.get(base_action) if kind == "base" else None


def validate_phase4_adapter_canaries(
    source: str,
    functions: Mapping[str, str],
    action_set: set[str],
    index: Mapping[str, Any],
    resource_catalog: Mapping[str, Any] | None,
    validation: Validation,
    rhai_path: Path,
) -> None:
    """Fail closed on all 687 role-preserving Phase 4 adapter routes."""
    adapter_names = phase4_adapter_like_names(source)
    action_rows = index.get("actions")
    resource_rows = (
        [
            row for row in action_rows
            if isinstance(row, Mapping)
            and row.get("family") in PHASE4_RESOURCE_FAMILIES
        ]
        if isinstance(action_rows, list)
        else []
    )
    indexed_phase4_routes = any(
        isinstance(row.get("helpers"), list)
        and any(
            helper in PHASE4_KNOWN_HELPER_NAMES
            for helper in row["helpers"]
        )
        for row in resource_rows
    )
    if not adapter_names and not indexed_phase4_routes:
        return

    observed_names = set(functions) & PHASE4_KNOWN_HELPER_NAMES
    matching_profiles = [
        profile for profile, specs in PHASE4_PROFILE_HELPERS.items()
        if observed_names == {name for name, _kind, _iterations, _rep in specs}
    ]
    profile = matching_profiles[0] if len(matching_profiles) == 1 else None
    validation.check(
        profile is not None,
        "rhai.phase4_active_profile",
        "Phase 4 must declare exactly one complete known helper profile",
        str(rhai_path),
    )
    specs = PHASE4_PROFILE_HELPERS[profile] if profile is not None else ()
    expected_names = {name for name, _kind, _iterations, _rep in specs}
    validation.check(
        profile is not None
        and len(observed_names) == (20 if profile == "economy" else 6)
        and observed_names == expected_names,
        "rhai.phase4_active_inventory",
        "Phase 4 emits exactly one complete active-profile adapter inventory",
        str(rhai_path),
    )
    unknown_adapters = adapter_names - PHASE4_KNOWN_HELPER_NAMES
    validation.check(
        not unknown_adapters,
        "rhai.phase4_unknown_adapter",
        f"unknown or forged extraction/refinement adapter(s): {sorted(unknown_adapters)}",
        str(rhai_path),
    )
    forbidden = (
        r"\baction\.(?:output|input|mutate)\s*\(",
        r"\b(?:if|for|while|match)\b", r"#\{", r"\.call\s*\(",
        r"\bsubaction\s*\(",
    )
    helper_kinds = {
        name: kind for name, kind, _iterations, _representative in specs
    }
    for name, kind, iterations, _representative in specs:
        helper = functions.get(name, "")
        target = "parent" if kind == "refine" else "body"
        core_name, core_arguments = phase4_core_call_arguments(kind)
        helper_calls = rhai_extraction_core_names(
            helper[helper.find("{") + 1 :]
        )
        validation.check(
            source.count(f"fn {name}(") == 1
            and rhai_function_parameters(helper, name)
            == list(PHASE4_HELPER_PARAMETERS[kind])
            and all(not re.search(pattern, strip_rhai_comments(helper)) for pattern in forbidden),
            "rhai.phase4_helper_shape",
            f"{name} must retain its fixed arity and straight-line helper shape",
            f"{rhai_path}:{name}",
        )
        validation.check(
            flat_rhai_call_arguments(helper, core_name) == [core_arguments]
            and helper_calls == {core_name},
            "rhai.phase4_core_route",
            f"{name} must make exactly one fixed call to {core_name}",
            f"{rhai_path}:{name}",
        )
        valid_vdf_owner = (
            (
                iterations is None
                and "intro_vdf" not in helper
                and '"work"' not in helper
            )
            or (
                iterations is not None
                and phase4_literal_vdf_tail_exact(helper, iterations, target)
            )
        )
        validation.check(
            valid_vdf_owner,
            "rhai.phase4_vdf_owner",
            f"{name} must own exactly its adjacent literal VDF tail (or no VDF tail)",
            f"{rhai_path}:{name}",
        )

    # The current profile intentionally predates the canonical economy index:
    # it omits twelve movement actions and has a distinct VDF schedule.  Its
    # source must therefore be checked against its frozen helper inventory and
    # route census, not economy wrapper literals from the canonical index.
    if profile == "current":
        current_routes: Counter[str] = Counter()
        all_current_wrappers_exact = True
        resource_names = [row.get("name") for row in resource_rows]
        for action in resource_rows:
            action_name = action.get("name")
            kind = phase4_index_action_kind(action)
            expected_helper = phase4_current_expected_helper(action)
            expected_arguments = (
                phase4_expected_call_arguments(
                    index, resource_catalog, action_name, kind
                )
                if isinstance(action_name, str) and isinstance(kind, str)
                else None
            )
            wrapper = functions.get(action_name, "") if isinstance(action_name, str) else ""
            exact = (
                isinstance(action_name, str)
                and kind in {"base", "body", "composite", "refine"}
                and expected_helper in expected_names
                and expected_arguments is not None
                and phase4_index_roles(action) == phase4_expected_roles(kind)
                and phase4_wrapper_body_exact(
                    wrapper, kind, expected_helper, expected_arguments
                )
            )
            all_current_wrappers_exact = all_current_wrappers_exact and exact
            if exact and isinstance(expected_helper, str):
                current_routes[expected_helper] += 1
            validation.check(
                exact,
                "rhai.phase4_current_wrapper",
                f"{action_name} must retain its exact current-profile adapter and literals",
                f"{rhai_path}:{action_name}",
            )
        unexpected_routes = {
            action_name: sorted(phase4_adapter_like_names(functions.get(action_name, "")))
            for action_name in action_set - {name for name in resource_names if isinstance(name, str)}
            if phase4_adapter_like_names(functions.get(action_name, ""))
        }
        validation.check(
            all_current_wrappers_exact
            and len(resource_names) == 687
            and all(isinstance(name, str) and name in action_set for name in resource_names)
            and sum(current_routes.values()) == 687
            and dict(current_routes) == PHASE4_EXPECTED_DISTRIBUTIONS["current"]
            and not unexpected_routes,
            "rhai.phase4_current_distribution",
            "current profile must retain all 687 resource/refinement routes in the frozen distribution",
            str(rhai_path),
        )
        validation.check(
            set(current_routes) == expected_names
            and all(current_routes[name] > 0 for name in expected_names),
            "rhai.phase4_helper_reachability",
            "every active current-profile helper must be reached exactly through resource/refinement wrappers",
            str(rhai_path),
        )
        return

    resource_names = [row.get("name") for row in resource_rows]
    names_are_unique = (
        all(isinstance(name, str) for name in resource_names)
        and len(resource_names) == len(set(resource_names))
    )
    validation.check(
        len(resource_rows) == 687
        and names_are_unique
        and all(isinstance(name, str) and name in action_set for name in resource_names),
        "rhai.phase4_bulk_catalog",
        "the authoritative index must contain exactly 687 unique manifest resource actions",
        str(rhai_path),
    )

    observed_distribution: Counter[str] = Counter()
    all_wrappers_exact = True
    old_scaffolding_absent = True
    for action in resource_rows:
        action_name = action.get("name")
        kind = phase4_index_action_kind(action)
        metadata_helpers = action.get("helpers")
        expected_helper = (
            metadata_helpers[0]
            if isinstance(metadata_helpers, list)
            and len(metadata_helpers) == 1
            and isinstance(metadata_helpers[0], str)
            else None
        )
        wrapper = functions.get(action_name, "") if isinstance(action_name, str) else ""
        expected_arguments = (
            phase4_expected_call_arguments(
                index, resource_catalog, action_name, kind
            )
            if isinstance(action_name, str) and isinstance(kind, str)
            else None
        )
        wrapper_core_calls = rhai_extraction_core_names(
            wrapper[wrapper.find("{") + 1 :]
        )
        adapter_calls = phase4_adapter_like_names(wrapper)
        exact = (
            isinstance(action_name, str)
            and kind in {"base", "body", "composite", "refine"}
            and expected_helper in expected_names
            and helper_kinds.get(expected_helper) == kind
            and expected_arguments is not None
            and phase4_index_roles(action) == phase4_expected_roles(kind)
            and rhai_object_roles(wrapper) == phase4_expected_roles(kind)
            and adapter_calls == {expected_helper}
            and flat_rhai_call_arguments(wrapper, expected_helper)
            == [expected_arguments]
            and wrapper_core_calls == {expected_helper}
            and phase4_wrapper_body_exact(
                wrapper, kind, expected_helper, expected_arguments
            )
        )
        no_old_scaffolding = (
            "intro_vdf" not in wrapper
            and not re.search(r'\.update\s*\(\s*"work"', wrapper)
            and not (wrapper_core_calls & {
                "extract_direct_resource_core",
                "extract_composite_resource_core",
                "refine_resource_core",
            })
        )
        all_wrappers_exact = all_wrappers_exact and exact
        old_scaffolding_absent = old_scaffolding_absent and no_old_scaffolding
        if exact:
            observed_distribution[expected_helper] += 1
        validation.check(
            exact,
            "rhai.phase4_wrapper_arguments",
            f"{action_name} must make its one exact metadata-bound adapter call",
            f"{rhai_path}:{action_name}",
        )
        validation.check(
            no_old_scaffolding,
            "rhai.phase4_wrapper_scaffolding",
            f"{action_name} must not retain direct old core or VDF scaffolding",
            f"{rhai_path}:{action_name}",
        )

    expected_distribution = (
        PHASE4_EXPECTED_DISTRIBUTIONS[profile]
        if profile is not None
        else {}
    )
    validation.check(
        all_wrappers_exact
        and old_scaffolding_absent
        and dict(observed_distribution) == expected_distribution,
        "rhai.phase4_distribution",
        "all 687 wrappers must match the exact active-profile helper distribution",
        str(rhai_path),
    )
    validation.check(
        set(observed_distribution) == expected_names
        and all(observed_distribution[name] > 0 for name in expected_names),
        "rhai.phase4_helper_reachability",
        "every active-profile helper must be reached and no helper may be orphaned",
        str(rhai_path),
    )
    unexpected_routes = {
        name: sorted(phase4_adapter_like_names(functions.get(name, "")))
        for name in action_set - {name for name in resource_names if isinstance(name, str)}
        if phase4_adapter_like_names(functions.get(name, ""))
    }
    validation.check(
        not unexpected_routes,
        "rhai.phase4_non_resource_route",
        f"non-resource actions route through Phase 4 adapters: {unexpected_routes}",
        str(rhai_path),
    )


def phase5_adapter_like_names(source: str) -> set[str]:
    """Return Phase 5 adapter names, including forged marker-bearing names."""
    marker = re.compile(
        r"(?:fabricate_component_(?:reusable|final)_vdf_|"
        r"develop_derived_skill_[23]_evidence_vdf_|"
        r"produce_capability_artifact_[123]_evidence_vdf_)"
    )
    return {
        name
        for name in re.findall(
            r"(?<![.A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(",
            strip_rhai_comments(source),
        )
        if name.endswith("_core") and marker.search(name)
    }


def phase5_parameters(family: str, evidence_count: int | str) -> list[str]:
    """Return the fixed signature for one Phase 5 helper topology."""
    if family == "component":
        return list(PHASE5_COMPONENT_PARAMETERS)
    count = int(evidence_count)
    evidence = [f"evidence_{index}" for index in range(1, count + 1)]
    literals = [
        value
        for index in range(1, count + 1)
        for value in (f"evidence_{index}_type", f"evidence_{index}_amount")
    ]
    if family == "derived":
        return [
            "action", "next_ship", "technology_skill", "ship", *evidence,
            "parent_skill_type", "output_skill_type", *literals,
        ]
    return [
        "action", "next_ship", "artifact", "ship", *evidence,
        "required_skill_type", "output_resource_type", "output_amount", *literals,
    ]


def phase5_literal_vdf_tail_exact(source: str, iterations: int, target: str) -> bool:
    """Require the literal VDF/update pair to end the role-free helper."""
    open_brace = source.find("{")
    close_brace = source.rfind("}")
    if open_brace < 0 or close_brace <= open_brace:
        return False
    body = source[open_brace + 1 : close_brace]
    final_tail = re.compile(
        rf"\bvar\s+work\s*=\s*action\.intro_vdf\(\s*{iterations}\s*,\s*"
        rf"{re.escape(target)}\s*\)\s*;\s*{re.escape(target)}\.update\(\s*"
        r'"work"\s*,\s*work\s*\)\s*;\s*\Z',
        flags=re.DOTALL,
    )
    return phase4_literal_vdf_tail_exact(source, iterations, target) and bool(
        final_tail.search(body)
    )


def current_literal_vdf_tail_exact(
    source: str, iterations: int, target: str,
) -> bool:
    """Require the sole current-profile VDF tail as final executable code."""
    masked = mask_rhai_comments(source)
    open_brace = masked.find("{")
    close_brace = masked.rfind("}")
    if open_brace < 0 or close_brace <= open_brace:
        return False
    body = masked[open_brace + 1 : close_brace]
    tail = re.compile(
        rf"\bvar\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*action\.intro_vdf\(\s*"
        rf"{iterations}\s*,\s*{re.escape(target)}\s*\)\s*;\s*"
        rf"{re.escape(target)}\.update\(\s*\"work\"\s*,\s*\1\s*\)\s*;"
        r"\s*\Z",
        flags=re.DOTALL,
    )
    return (
        len(tail.findall(body)) == 1
        and len(re.findall(r"\baction\.intro_vdf\s*\(", body)) == 1
        and len(re.findall(r'\.update\s*\(\s*"work"', body)) == 1
    )


def phase5_index_literals(
    action: Mapping[str, Any], family: str, evidence_count: int | str,
) -> tuple[list[str], list[tuple[str, str]]] | None:
    """Bind a canary wrapper's ordered literals and direct roles to index data."""
    fixed = action.get("fixed_literals")
    if not isinstance(fixed, Mapping):
        return None
    if family == "component":
        component = fixed.get("component")
        if not isinstance(component, Mapping):
            return None
        materials = component.get("materials")
        catalyst_code = component.get("catalyst_resource_code")
        values = (
            component.get("skill_code"), component.get("code"),
            component.get("output_amount"), catalyst_code,
        )
        if (
            not isinstance(materials, list) or len(materials) != 3
            or not all(isinstance(item, Mapping) for item in materials)
            or not all(isinstance(value, int) for value in values)
        ):
            return None
        mode = component.get("catalyst_mode")
        if mode not in {"reusable", "final"}:
            return None
        material_values: list[str] = []
        for material in materials:
            code = material.get("resource_code")
            amount = material.get("amount")
            if not isinstance(code, int) or not isinstance(amount, int):
                return None
            material_values.extend((str(code), str(amount)))
        return (
            [
                "action", "n", "c", "s", "a", "b", "d", "k",
                str(component["skill_code"]), *material_values,
                str(catalyst_code), str(component["code"]),
                str(component["output_amount"]),
            ],
            [
                ("output", "MicroverseShip"), ("output", "MicroverseResource"),
                ("input", "MicroverseShip"),
                ("input", "MicroverseResource"),
                ("input", "MicroverseResource"),
                ("input", "MicroverseResource"),
                ("input" if mode == "final" else "mutate", "MicroverseResource"),
            ],
        )

    count = int(evidence_count)
    key = "derived_skill" if family == "derived" else "capability_artifact"
    recipe = fixed.get(key)
    if not isinstance(recipe, Mapping):
        return None
    items = recipe.get("evidence" if family == "derived" else "fixed_inputs")
    if (
        not isinstance(items, list) or len(items) != count
        or not all(isinstance(item, Mapping) for item in items)
    ):
        return None
    literals: list[str] = []
    for item in items:
        code = item.get("resource_code")
        amount = item.get("amount")
        if not isinstance(code, int) or not isinstance(amount, int):
            return None
        literals.extend((str(code), str(amount)))
    if family == "derived":
        parent = recipe.get("parent_skill_code")
        output = recipe.get("output_skill_code")
        if not isinstance(parent, int) or not isinstance(output, int):
            return None
        return (
            [
                "action", "next_ship", "technology_skill", "ship",
                *(f"evidence_{index}" for index in range(1, count + 1)),
                str(parent), str(output), *literals,
            ],
            [
                ("output", "MicroverseShip"),
                ("output", "MicroverseTechnologySkill"),
                ("input", "MicroverseShip"),
                *[("input", "MicroverseResource") for _ in items],
            ],
        )
    skill = recipe.get("skill_code")
    resource = recipe.get("resource_code")
    amount = recipe.get("amount")
    if not all(isinstance(value, int) for value in (skill, resource, amount)):
        return None
    return (
        [
            "action", "next_ship", "artifact", "ship",
            *(f"evidence_{index}" for index in range(1, count + 1)),
            str(skill), str(resource), str(amount), *literals,
        ],
        [
            ("output", "MicroverseShip"), ("output", "MicroverseResource"),
            ("input", "MicroverseShip"),
            *[("input", "MicroverseResource") for _ in items],
        ],
    )


def phase5_helper_calls_exact(
    helper: str,
    family: str,
    shape: int | str,
) -> bool:
    """Require each adapter's one core call and ordered evidence/catalyst work."""
    body = helper[helper.find("{") + 1 : helper.rfind("}")]
    plain_calls = re.findall(
        r"(?<![.A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(", body
    )
    if family == "component":
        catalyst_core = (
            "consume_component_catalyst_final_core"
            if shape == "final"
            else "consume_component_catalyst_reusable_core"
        )
        return (
            plain_calls == ["fabricate_component_core", catalyst_core]
            and
            flat_rhai_call_arguments(helper, "fabricate_component_core")
            == [[
                "action", "next_ship", "component", "ship", "material_1",
                "material_2", "material_3", "catalyst", "skill_type",
                "material_1_type", "material_1_amount", "material_2_type",
                "material_2_amount", "material_3_type", "material_3_amount",
                "catalyst_type", "component_type", "component_amount",
            ]]
            and flat_rhai_call_arguments(helper, catalyst_core)
            == [["action", "catalyst"]]
            and not flat_rhai_call_arguments(
                helper,
                "consume_component_catalyst_final_core"
                if catalyst_core.endswith("reusable_core")
                else "consume_component_catalyst_reusable_core",
            )
        )
    count = int(shape)
    core = (
        "develop_derived_skill_core"
        if family == "derived"
        else "produce_capability_artifact_core"
    )
    core_arguments = (
        ["action", "next_ship", "technology_skill", "ship", "parent_skill_type", "output_skill_type"]
        if family == "derived"
        else ["action", "next_ship", "artifact", "ship", "required_skill_type", "output_resource_type", "output_amount"]
    )
    evidence_arguments = [
        ["action", f"evidence_{index}", f"evidence_{index}_type", f"evidence_{index}_amount"]
        for index in range(1, count + 1)
    ]
    return (
        plain_calls == [core, *(["prove_resource_stack_core"] * count)]
        and flat_rhai_call_arguments(helper, core) == [core_arguments]
        and flat_rhai_call_arguments(helper, "prove_resource_stack_core")
        == evidence_arguments
    )


def phase5_expected_route(
    action: Mapping[str, Any],
) -> tuple[str, str, int | str, int] | None:
    """Derive one fixed Phase 5 adapter from canonical action metadata."""
    fixed = action.get("fixed_literals")
    if not isinstance(fixed, Mapping):
        return None
    component = fixed.get("component")
    if isinstance(component, Mapping):
        mode = component.get("catalyst_mode")
        iterations = component.get("vdf_iterations")
        if mode in {"reusable", "final"} and isinstance(iterations, int):
            return (
                f"fabricate_component_{mode}_vdf_{iterations}_core",
                "component", mode, iterations,
            )
        return None
    skill = fixed.get("derived_skill")
    if isinstance(skill, Mapping):
        evidence = skill.get("evidence")
        iterations = skill.get("vdf_iterations")
        if isinstance(evidence, list) and len(evidence) in {2, 3} and isinstance(iterations, int):
            return (
                f"develop_derived_skill_{len(evidence)}_evidence_vdf_{iterations}_core",
                "derived", len(evidence), iterations,
            )
        return None
    artifact = fixed.get("capability_artifact")
    if isinstance(artifact, Mapping):
        evidence = artifact.get("fixed_inputs")
        iterations = artifact.get("vdf_iterations")
        if isinstance(evidence, list) and len(evidence) in {1, 2, 3} and isinstance(iterations, int):
            return (
                f"produce_capability_artifact_{len(evidence)}_evidence_vdf_{iterations}_core",
                "artifact", len(evidence), iterations,
            )
    return None


def phase5_helper_body_exact(
    helper: str,
    family: str,
    shape: int | str,
    iterations: int,
    target: str,
) -> bool:
    """Require the entire helper body to be its fixed core/evidence/VDF sequence."""
    if family == "component":
        catalyst_core = (
            "consume_component_catalyst_final_core"
            if shape == "final"
            else "consume_component_catalyst_reusable_core"
        )
        statements = [
            "fabricate_component_core(action, next_ship, component, ship, material_1, material_2, material_3, catalyst, skill_type, material_1_type, material_1_amount, material_2_type, material_2_amount, material_3_type, material_3_amount, catalyst_type, component_type, component_amount);",
            f"{catalyst_core}(action, catalyst);",
        ]
    else:
        count = int(shape)
        statements = [
            (
                "develop_derived_skill_core(action, next_ship, technology_skill, ship, parent_skill_type, output_skill_type);"
                if family == "derived"
                else "produce_capability_artifact_core(action, next_ship, artifact, ship, required_skill_type, output_resource_type, output_amount);"
            ),
            *[
                f"prove_resource_stack_core(action, evidence_{index}, evidence_{index}_type, evidence_{index}_amount);"
                for index in range(1, count + 1)
            ],
        ]
    statements.extend((
        f"var work = action.intro_vdf({iterations}, {target});",
        f'{target}.update("work", work);',
    ))
    open_brace = helper.find("{")
    close_brace = helper.rfind("}")
    if open_brace < 0 or close_brace <= open_brace:
        return False
    actual = helper[open_brace + 1 : close_brace]
    return (
        compact_rhai_tokens(actual).replace("\n", "")
        == compact_rhai_tokens("\n".join(statements)).replace("\n", "")
    )


def phase5_wrapper_body_exact(
    wrapper: str,
    family: str,
    shape: int | str,
    helper_name: str,
    arguments: Sequence[str],
) -> bool:
    """Require direct roles in order followed only by the expected adapter call."""
    if family == "component":
        statements = [
            'var n = action.output("MicroverseShip");',
            'var c = action.output("MicroverseResource");',
            'var s = action.input("MicroverseShip");',
            'var a = action.input("MicroverseResource");',
            'var b = action.input("MicroverseResource");',
            'var d = action.input("MicroverseResource");',
            'var k = action.'
            + ("input" if shape == "final" else "mutate")
            + '("MicroverseResource");',
        ]
    else:
        count = int(shape)
        output_handle = "technology_skill" if family == "derived" else "artifact"
        output_class = (
            "MicroverseTechnologySkill"
            if family == "derived" else "MicroverseResource"
        )
        statements = [
            'var next_ship = action.output("MicroverseShip");',
            f'var {output_handle} = action.output("{output_class}");',
            'var ship = action.input("MicroverseShip");',
            *[
                'var evidence_' + str(index)
                + ' = action.input("MicroverseResource");'
                for index in range(1, count + 1)
            ],
        ]
    statements.append(f"{helper_name}({', '.join(arguments)});")
    open_brace = wrapper.find("{")
    close_brace = wrapper.rfind("}")
    if open_brace < 0 or close_brace <= open_brace:
        return False
    actual = wrapper[open_brace + 1 : close_brace]
    return (
        compact_rhai_tokens(actual).replace("\n", "")
        == compact_rhai_tokens("\n".join(statements)).replace("\n", "")
    )


def validate_phase5_adapter_canaries(
    source: str,
    functions: Mapping[str, str],
    action_set: set[str],
    index: Mapping[str, Any],
    validation: Validation,
    rhai_path: Path,
) -> None:
    """Fail closed on all 234 fixed-arity Phase 5 recipe adapter routes."""
    adapter_names = phase5_adapter_like_names(source)
    action_rows = index.get("actions")
    rows = (
        {row.get("name"): row for row in action_rows if isinstance(row, Mapping)}
        if isinstance(action_rows, list)
        else {}
    )
    expected_names = set(PHASE5_KNOWN_HELPER_NAMES)
    expected_routes = {
        str(action_name): route
        for action_name, action in rows.items()
        if isinstance(action_name, str)
        and (route := phase5_expected_route(action)) is not None
    }
    indexed_routes = any(
        isinstance(row, Mapping)
        and isinstance(row.get("helpers"), list)
        and any(name in expected_names for name in row["helpers"])
        for row in rows.values()
    )
    if not adapter_names and not indexed_routes:
        return

    observed_names = set(functions) & expected_names
    validation.check(
        observed_names == expected_names and len(observed_names) == 20,
        "rhai.phase5_active_inventory",
        "Phase 5 requires exactly the fixed twenty-helper inventory",
        str(rhai_path),
    )
    unknown_adapters = adapter_names - expected_names
    validation.check(
        not unknown_adapters,
        "rhai.phase5_unknown_adapter",
        f"unknown or forged component/skill adapter(s): {sorted(unknown_adapters)}",
        str(rhai_path),
    )
    forbidden = (
        r"\baction\.(?:output|input|mutate)\s*\(",
        r"\b(?:if|for|while|match)\b", r"#\{", r"\.call\s*\(",
        r"\bsubaction\s*\(",
    )
    route_distribution = Counter(route[0] for route in expected_routes.values())
    for name, family, shape, iterations, _representative in PHASE5_HELPERS:
        helper = functions.get(name, "")
        target = {
            "component": "component", "derived": "technology_skill", "artifact": "artifact",
        }[family]
        helper_exact = (
            source.count(f"fn {name}(") == 1
            and len(re.findall(
                rf"(?<![.A-Za-z0-9_]){re.escape(name)}\s*\(",
                strip_rhai_comments(source),
            )) == route_distribution[name] + 1
            and rhai_function_parameters(helper, name) == phase5_parameters(family, shape)
            and all(not re.search(pattern, strip_rhai_comments(helper)) for pattern in forbidden)
            and phase5_helper_calls_exact(helper, family, shape)
            and phase5_literal_vdf_tail_exact(helper, iterations, target)
            and phase5_helper_body_exact(helper, family, shape, iterations, target)
        )
        validation.check(
            helper_exact,
            "rhai.phase5_helper_shape",
            f"{name} must retain its fixed, role-free recipe and VDF shape",
            f"{rhai_path}:{name}",
        )

    observed_distribution: Counter[str] = Counter()
    all_wrappers_exact = True
    for action_name, (helper_name, family, shape, _iterations) in expected_routes.items():
        action = rows.get(action_name)
        wrapper = functions.get(action_name, "")
        bound = (
            phase5_index_literals(action, family, shape)
            if isinstance(action, Mapping) else None
        )
        arguments, roles = bound if bound is not None else (None, None)
        wrapper_calls = phase5_adapter_like_names(wrapper)
        wrapper_exact = (
            action_name in action_set
            and isinstance(arguments, list)
            and isinstance(roles, list)
            and rhai_object_roles(wrapper) == roles
            and wrapper_calls == {helper_name}
            and flat_rhai_call_arguments(wrapper, helper_name) == [arguments]
            and phase5_wrapper_body_exact(
                wrapper, family, shape, helper_name, arguments
            )
            and "intro_vdf" not in wrapper
            and not re.search(r'\.update\s*\(\s*"work"', wrapper)
            and not any(
                flat_rhai_call_arguments(wrapper, core)
                for core in (
                    "fabricate_component_core", "develop_derived_skill_core",
                    "produce_capability_artifact_core", "prove_resource_stack_core",
                    "consume_component_catalyst_reusable_core",
                    "consume_component_catalyst_final_core",
                )
            )
        )
        all_wrappers_exact = all_wrappers_exact and wrapper_exact
        if wrapper_exact:
            observed_distribution[helper_name] += 1
        validation.check(
            wrapper_exact,
            "rhai.phase5_wrapper_arguments",
            f"{action_name} must retain direct roles and one exact adapter call",
            f"{rhai_path}:{action_name}",
        )

    non_canary_routes = {
        action_name: phase5_adapter_like_names(functions.get(action_name, ""))
        for action_name in action_set - set(expected_routes)
        if phase5_adapter_like_names(functions.get(action_name, ""))
    }
    validation.check(
        len(expected_routes) == 234
        and all_wrappers_exact
        and not non_canary_routes
        and dict(observed_distribution) == dict(route_distribution)
        and sum(observed_distribution.values()) == 234
        and Counter(
            iterations for _helper, _family, _shape, iterations in expected_routes.values()
        ) == Counter({8: 66, 12: 78, 32: 90}),
        "rhai.phase5_routing",
        "all 234 catalog recipe actions must route once through the exact fixed Phase 5 adapter",
        str(rhai_path),
    )


def phase6_adapter_like_names(source: str) -> set[str]:
    """Return Phase 6 helper-like calls, including forged marker-bearing names."""
    markers = (
        "move_positive_core",
        "move_negative_core",
        "advance_ship_epoch_core",
        "update_ship_work_vdf_",
    )
    return {
        name
        for name in re.findall(
            r"(?<![.A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(",
            strip_rhai_comments(source),
        )
        if any(marker in name for marker in markers)
    }


def phase6_expected_index_helpers(action_name: str) -> list[str] | None:
    route = PHASE6_ECONOMY_ROUTES.get(action_name)
    return [helper_name for helper_name, _arguments in route] if route else None


def phase6_index_metadata_exact(
    index: Mapping[str, Any],
    action_set: set[str],
    current_profile: bool,
) -> bool:
    action_rows = index.get("actions")
    if not isinstance(action_rows, list):
        return True
    rows = {
        str(row.get("name")): row
        for row in action_rows
        if isinstance(row, Mapping) and isinstance(row.get("name"), str)
    }
    if current_profile:
        return all(
            name not in action_set
            or (
                not (
                    isinstance(row.get("helpers"), list)
                    and set(row["helpers"]) & PHASE6_KNOWN_HELPER_NAMES
                )
                or phase6_expected_index_helpers(name) == row.get("helpers")
            )
            for name, row in rows.items()
        )
    return (
        all(
            phase6_expected_index_helpers(name) == rows.get(name, {}).get("helpers")
            for name in PHASE6_ECONOMY_ROUTES
        )
        and all(
            not (
                isinstance(row.get("helpers"), list)
                and set(row["helpers"]) & PHASE6_KNOWN_HELPER_NAMES
            )
            or phase6_expected_index_helpers(name) == row.get("helpers")
            for name, row in rows.items()
        )
    )


def phase6_normalized_body(source: str) -> str:
    return compact_rhai_tokens(mask_rhai_comments(source)).replace("\n", "")


def phase6_function_body_exact(source: str, statements: Sequence[str]) -> bool:
    open_brace = source.find("{")
    close_brace = source.rfind("}")
    return (
        open_brace >= 0
        and close_brace > open_brace
        and phase6_normalized_body(source[open_brace + 1 : close_brace])
        == phase6_normalized_body("\n".join(statements))
    )


def phase6_move_body_exact(source: str, positive: bool) -> bool:
    arithmetic = (
        "var next_coordinate = unsafe { current_coordinate - (0 - step) };"
        if positive
        else "var next_coordinate = unsafe { current_coordinate - step };"
    )
    sum_statement = (
        "action.st_sum(current_coordinate, step, next_coordinate);"
        if positive
        else "action.st_sum(next_coordinate, step, current_coordinate);"
    )
    return phase6_function_body_exact(source, (
        "action.st_sum(ship.extraction_amount, 0, extraction_amount);",
        "action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);",
        arithmetic,
        sum_statement,
        "action.st_gt(next_coordinate, 0);",
        f"action.st_gt({POSITION_MAXIMUM_EXCLUSIVE}, next_coordinate);",
        "var next_action_serial = unsafe { ship.action_serial - (0 - 1) };",
        "action.st_sum(ship.action_serial, 1, next_action_serial);",
        "ship.update(coordinate_field, next_coordinate);",
        'ship.update("active_skill_type", 0);',
        'ship.update("action_serial", next_action_serial);',
        "var next_ship_key = action.random();",
        "rotate_key(ship, next_ship_key);",
    ))


def phase6_epoch_body_exact(source: str) -> bool:
    return phase6_function_body_exact(source, (
        f"action.st_gt({TIME_MAXIMUM_EXCLUSIVE}, next_epoch);",
        "var next_action_serial = unsafe { ship.action_serial - (0 - 1) };",
        "action.st_sum(ship.action_serial, 1, next_action_serial);",
        'ship.update("epoch", next_epoch);',
        'ship.update("active_skill_type", 0);',
        'ship.update("action_serial", next_action_serial);',
        "var next_ship_key = action.random();",
        "rotate_key(ship, next_ship_key);",
    ))


def phase6_vdf_body_exact(source: str, iterations: int) -> bool:
    return phase6_function_body_exact(source, (
        f"var work = action.intro_vdf({iterations}, ship);",
        'ship.update("work", work);',
    ))


def phase6_wrapper_body_exact(
    action_name: str,
    wrapper: str,
    route: Sequence[tuple[str, Sequence[str]]],
) -> bool:
    statements = ['var ship = action.mutate("MicroverseShip");']
    if action_name.startswith("TimeWarp"):
        suffix = action_name.removeprefix("TimeWarp")
        spec = PHASE6_TIMEWARP_SPECS.get(suffix)
        if spec is None:
            return False
        step, extraction, rare, _vdf = spec
        statements.extend((
            f"action.st_sum(ship.extraction_amount, 0, {extraction});",
            f"action.st_sum(ship.rare_extraction_amount, 0, {rare});",
            f"var next_epoch = unsafe {{ ship.epoch - (0 - {step}) }};",
            f"action.st_sum(ship.epoch, {step}, next_epoch);",
        ))
    statements.extend(
        f"{helper_name}({', '.join(arguments)});"
        for helper_name, arguments in route
    )
    return phase6_function_body_exact(wrapper, statements)


def validate_phase6_movement_canaries(
    source: str,
    functions: Mapping[str, str],
    action_set: set[str],
    index: Mapping[str, Any],
    validation: Validation,
    rhai_path: Path,
) -> None:
    """Bind the economy-only Phase 6 movement/timewarp canary helpers exactly."""
    adapter_names = phase6_adapter_like_names(source)
    uncommented_source = strip_rhai_comments(source)
    live_helper_names = {
        helper_name
        for helper_name in PHASE6_KNOWN_HELPER_NAMES
        if re.search(rf"(?m)^fn\s+{re.escape(helper_name)}\s*\(", uncommented_source)
    }
    phase4_observed = set(functions) & PHASE4_KNOWN_HELPER_NAMES
    current_profile = phase4_observed == {
        name for name, _kind, _iterations, _representative in PHASE4_CURRENT_HELPERS
    }
    if current_profile:
        validation.check(
            not adapter_names and not live_helper_names,
            "rhai.phase6_current_inventory",
            "current profile must not declare or call Phase 6 movement/timewarp helpers",
            str(rhai_path),
        )
        validation.check(
            phase6_index_metadata_exact(index, action_set, True),
            "rhai.phase6_current_index_metadata",
            "current profile may translate Phase 6 helper metadata only for exact surviving canary routes",
            str(rhai_path),
        )
        return

    validation.check(
        phase6_index_metadata_exact(index, action_set, False),
        "rhai.phase6_index_metadata",
        "economy index must bind exactly the 21 ordered Phase 6 helper routes and no others",
        str(rhai_path),
    )

    observed_names = live_helper_names
    validation.check(
        observed_names == PHASE6_KNOWN_HELPER_NAMES,
        "rhai.phase6_active_inventory",
        "economy Phase 6 bulk routing requires exactly its six fixed helpers",
        str(rhai_path),
    )
    validation.check(
        not (adapter_names - PHASE6_KNOWN_HELPER_NAMES),
        "rhai.phase6_unknown_adapter",
        f"unknown or forged movement/timewarp helper(s): {sorted(adapter_names - PHASE6_KNOWN_HELPER_NAMES)}",
        str(rhai_path),
    )
    forbidden = (
        r"\baction\.(?:output|input|mutate)\s*\(",
        r"\b(?:if|for|while|match)\b",
        r"#\{",
        r"\.call\s*\(",
        r"\bsubaction\s*\(",
    )
    helper_checks = (
        ("move_positive_core", PHASE6_MOVE_PARAMETERS, phase6_move_body_exact, True),
        ("move_negative_core", PHASE6_MOVE_PARAMETERS, phase6_move_body_exact, False),
        ("advance_ship_epoch_core", PHASE6_EPOCH_PARAMETERS, phase6_epoch_body_exact, None),
    )
    for helper_name, parameters, body_check, argument in helper_checks:
        helper = functions.get(helper_name, "")
        exact_body = (
            body_check(helper, argument)
            if argument is not None
            else body_check(helper)
        )
        validation.check(
            len(re.findall(
                rf"(?m)^fn\s+{re.escape(helper_name)}\s*\(", uncommented_source
            )) == 1
            and rhai_function_parameters(helper, helper_name) == list(parameters)
            and all(
                not re.search(pattern, strip_rhai_comments(helper))
                for pattern in forbidden
            )
            and exact_body,
            "rhai.phase6_helper_shape",
            f"{helper_name} must retain its exact role-free straight-line movement/timewarp body",
            f"{rhai_path}:{helper_name}",
        )
    for iterations, helper_name in PHASE6_VDF_HELPERS.items():
        helper = functions.get(helper_name, "")
        validation.check(
            len(re.findall(
                rf"(?m)^fn\s+{re.escape(helper_name)}\s*\(", uncommented_source
            )) == 1
            and rhai_function_parameters(helper, helper_name) == ["action", "ship"]
            and all(
                not re.search(pattern, strip_rhai_comments(helper))
                for pattern in forbidden
            )
            and phase4_literal_vdf_tail_exact(helper, iterations, "ship")
            and phase6_vdf_body_exact(helper, iterations),
            "rhai.phase6_vdf_owner",
            f"{helper_name} must own exactly one literal VDF/work tail for ship",
            f"{rhai_path}:{helper_name}",
        )

    expected_callers: dict[str, set[str]] = defaultdict(set)
    all_wrappers_exact = True
    for action_name, route in PHASE6_ECONOMY_ROUTES.items():
        wrapper = functions.get(action_name, "")
        exact = (
            action_name in action_set
            and rhai_object_roles(wrapper) == [("mutate", "MicroverseShip")]
            and phase6_wrapper_body_exact(action_name, wrapper, route)
            and "intro_vdf" not in strip_rhai_comments(wrapper)
            and not re.search(r'\.update\s*\(\s*"work"', strip_rhai_comments(wrapper))
        )
        all_wrappers_exact = all_wrappers_exact and exact
        for helper_name, arguments in route:
            expected_callers[helper_name].add(action_name)
            exact = exact and flat_rhai_call_arguments(
                mask_rhai_comments(wrapper), helper_name
            ) == [list(arguments)]
        validation.check(
            exact,
            "rhai.phase6_wrapper_arguments",
            f"{action_name} must retain its direct role, literals, and ordered Phase 6 helper calls",
            f"{rhai_path}:{action_name}",
        )

    observed_callers: dict[str, set[str]] = defaultdict(set)
    for function_name, function in functions.items():
        masked = strip_rhai_comments(function)
        open_brace = masked.find("{")
        close_brace = masked.rfind("}")
        body = (
            masked[open_brace + 1 : close_brace]
            if open_brace >= 0 and close_brace > open_brace
            else ""
        )
        for helper_name in PHASE6_KNOWN_HELPER_NAMES:
            if rhai_named_call_count(body, helper_name):
                observed_callers[helper_name].add(function_name)
    validation.check(
        all_wrappers_exact
        and set(PHASE6_ECONOMY_ROUTES).issubset(action_set)
        and dict(observed_callers) == dict(expected_callers),
        "rhai.phase6_routing",
        "all 21 Phase 6 actions must route exactly once with no outside or orphan helper callers",
        str(rhai_path),
    )
    route_distribution = Counter(
        helper_name
        for route in PHASE6_ECONOMY_ROUTES.values()
        for helper_name, _arguments in route
    )
    validation.check(
        len(PHASE6_ECONOMY_ROUTES) == 21
        and route_distribution == Counter({
            "move_positive_core": 9,
            "move_negative_core": 9,
            "advance_ship_epoch_core": 3,
            "update_ship_work_vdf_4_core": 7,
            "update_ship_work_vdf_12_core": 7,
            "update_ship_work_vdf_28_core": 7,
        }),
        "rhai.phase6_bulk_distribution",
        "Phase 6 economy routes must retain 9 positive, 9 negative, 3 epoch, and 7 callers per VDF tier",
        str(rhai_path),
    )


def phase6_layout_minify(source: str) -> str:
    """Canonical line-preserving Rhai token layout for adapter wrappers."""
    masked = mask_rhai_comments(source)
    compacted_lines: list[str] = []
    for source_line in masked.splitlines():
        output: list[str] = []
        index = 0
        in_string = False
        escaped = False
        while index < len(source_line):
            char = source_line[index]
            if in_string:
                output.append(char)
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == '"':
                    in_string = False
                index += 1
                continue
            if char == '"':
                in_string = True
                output.append(char)
                index += 1
                continue
            if char.isspace():
                next_index = index + 1
                while (
                    next_index < len(source_line)
                    and source_line[next_index].isspace()
                ):
                    next_index += 1
                previous = output[-1] if output else ""
                following = (
                    source_line[next_index]
                    if next_index < len(source_line)
                    else ""
                )
                if (
                    (previous.isalnum() or previous == "_")
                    and (following.isalnum() or following == "_")
                ):
                    output.append(" ")
                index = next_index
                continue
            output.append(char)
            index += 1
        compacted = "".join(output).strip()
        if compacted:
            compacted_lines.append(compacted)
    return "\n".join(compacted_lines) + "\n"


def phase6_layout_tokens(source: str) -> list[str]:
    """Return comment-free lexical tokens while preserving quoted literals."""
    return re.findall(
        r'"(?:\\.|[^"\\])*"|[A-Za-z_][A-Za-z0-9_]*|'
        r"[0-9]+|==|!=|<=|>=|&&|\|\||[-+*/%=<>{}()[\],;.]",
        mask_rhai_comments(source),
    )


def phase6_layout_adapter_names(index: Mapping[str, Any]) -> list[str]:
    rows = index.get("actions")
    if not isinstance(rows, list):
        return []
    return [
        str(row.get("name"))
        for row in rows
        if isinstance(row, Mapping)
        and (
            row.get("family") in PHASE4_RESOURCE_FAMILIES
            or phase5_expected_route(row) is not None
        )
        and isinstance(row.get("name"), str)
    ]


def phase6_layout_adapter_canonical(
    source: str,
    helper_name: str,
) -> str:
    """Return the fixed compact layout for one role-only adapter wrapper."""
    compacted = phase6_layout_minify(source)
    lines = compacted.splitlines()
    starts = [
        index
        for index, line in enumerate(lines)
        if line == f"{helper_name}(" or line.startswith(f"{helper_name}(")
    ]
    if len(starts) != 1:
        return ""
    start = starts[0]
    if lines[start].endswith(");}"):
        return compacted if start == len(lines) - 1 else ""
    closes = [
        index
        for index in range(start, len(lines))
        if lines[index].endswith(");")
    ]
    if len(closes) != 1:
        return ""
    close = closes[0]
    if lines[close + 1 :] != ["}"]:
        return ""
    role_pattern = re.compile(
        r'var [A-Za-z_][A-Za-z0-9_]*=action\.(?:output|input|mutate)\("[^\"]+"\);'
    )
    if (
        not lines
        or not lines[0].startswith("fn ")
        or not all(role_pattern.fullmatch(line) for line in lines[1:start])
    ):
        return ""
    joined = "".join(lines[start : close + 1]) + "}"
    return "\n".join([*lines[:start], joined]) + "\n"


def validate_phase6_layout_contract(
    source: str,
    functions: Mapping[str, str],
    action_set: set[str],
    index: Mapping[str, Any],
    validation: Validation,
    rhai_path: Path,
) -> None:
    """Bind canonical readable-token layout for all Phase 4/5 adapters."""
    adapter_names = phase6_layout_adapter_names(index)
    if not adapter_names:
        return
    adapter_set = set(adapter_names)
    observed_order = [name for name in functions if name in adapter_set]
    validation.check(
        len(adapter_names) == len(adapter_set) == 921
        and adapter_set.issubset(action_set)
        and observed_order == adapter_names,
        "rhai.phase6_layout_inventory_order",
        "layout contract requires exactly 921 ordered Phase 4/5 adapter wrappers",
        str(rhai_path),
    )
    validation.check(
        "\r" not in source
        and source.endswith("\n")
        and source == source.rstrip() + "\n",
        "rhai.phase6_layout_line_endings",
        "generated Rhai must use LF and one exact non-whitespace terminal newline",
        str(rhai_path),
    )
    validation.check(
        phase6_layout_minify(source) == source,
        "rhai.phase6_layout_global_canonical",
        "generated Rhai must equal its string/comment-aware canonical token layout",
        str(rhai_path),
    )
    validation.check(
        max(map(len, source.splitlines()), default=0) <= 278,
        "rhai.phase6_layout_global_line_limit",
        "generated Rhai lines must not exceed 278 characters",
        str(rhai_path),
    )

    all_canonical = True
    all_idempotent = True
    all_tokens_equal = True
    all_simple_lines = True
    no_identifier_merge = True
    no_complex_join = True
    for action_name in adapter_names:
        wrapper = functions.get(action_name, "")
        helper_names = (
            phase4_adapter_like_names(wrapper)
            | phase5_adapter_like_names(wrapper)
        )
        canonical = (
            phase6_layout_adapter_canonical(wrapper, next(iter(helper_names)))
            if len(helper_names) == 1
            else ""
        )
        all_canonical &= wrapper == canonical.rstrip("\n")
        all_idempotent &= bool(canonical) and (
            phase6_layout_adapter_canonical(
                canonical, next(iter(helper_names))
            )
            == canonical
        )
        all_tokens_equal &= phase6_layout_tokens(wrapper) == phase6_layout_tokens(canonical)
        lines = wrapper.splitlines()
        all_simple_lines &= bool(lines) and max(map(len, lines), default=0) <= 144
        masked = mask_rhai_comments(wrapper)
        no_identifier_merge &= not re.search(
            r"(?m)\b(?:fn|var|let)[A-Za-z0-9_]", masked
        )
        role_pattern = re.compile(
            r'var [A-Za-z_][A-Za-z0-9_]*=action\.(?:output|input|mutate)\("[^\"]+"\);'
        )
        role_count = len(rhai_object_roles(wrapper))
        no_complex_join &= (
            len(helper_names) == 1
            and len(lines) == role_count + 2
            and all(role_pattern.fullmatch(line) for line in lines[1:-1])
            and lines[-1].startswith(f"{next(iter(helper_names))}(")
            and lines[-1].endswith(");}")
            and lines[-1].count(";") == 1
        )
    validation.check(
        all_canonical and all_tokens_equal,
        "rhai.phase6_layout_token_equality",
        "all 921 adapter wrappers must equal their string/comment-aware canonical token layout",
        str(rhai_path),
    )
    validation.check(
        all_idempotent,
        "rhai.phase6_layout_idempotence",
        "canonical adapter layout must be idempotent",
        str(rhai_path),
    )
    validation.check(
        all_simple_lines,
        "rhai.phase6_layout_simple_line_limit",
        "adapter-only wrapper lines must not exceed 144 characters",
        str(rhai_path),
    )
    validation.check(
        no_identifier_merge,
        "rhai.phase6_layout_identifier_merge",
        "layout must retain required whitespace after Rhai declaration keywords",
        str(rhai_path),
    )
    validation.check(
        no_complex_join,
        "rhai.phase6_layout_complex_join",
        "adapter calls may join only their structural brace; direct role statements must remain separate lines",
        str(rhai_path),
    )


def witnessed_constructor_checks(
    source: str,
    spec: Mapping[str, Any],
) -> dict[str, bool]:
    """Validate the empirically rc.43-safe anchor-copy constructor shape."""
    target = str(spec["target"])
    target_class = str(spec["target_class"])
    skill_code = int(spec["skill_code"])
    anchors = spec["anchors"]
    set_match = re.search(
        rf"\b{re.escape(target)}\.set\(\[(.*?)\]\);",
        source,
        flags=re.DOTALL,
    )
    set_body = set_match.group(1) if set_match else ""
    updates = literal_object_update_pairs(source, target)
    expected_updates: list[tuple[str, str]] = []
    copied_fields: list[tuple[str, str, str]] = []
    identifier_fields: list[tuple[str, str]] = []
    ordered: list[str] = [
        f'var {target} = action.output("{target_class}");',
        "let placeholder_identifier = action.top_limb_u256(0);",
        f"{target}.set([",
    ]
    for anchor, identifier_field, numeric_fields in anchors:
        identifier_fields.append((anchor, identifier_field))
        ordered.extend(
            (
                f"var {anchor} = action.input(",
                f'prove_object_version_core(action, {anchor}, "anchor_version");',
                f"action.st_sum({anchor}.uses_remaining, 0, 1);",
            )
        )
        for source_field, target_field in numeric_fields:
            copied_fields.append((anchor, source_field, target_field))
            expected_updates.append((target_field, target_field))
            ordered.extend(
                (
                    f"var {target_field} = unsafe {{ {anchor}.{source_field} - 0 }};",
                    f"action.st_sum({anchor}.{source_field}, 0, {target_field});",
                    f'{target}.update("{target_field}", {target_field});',
                )
            )
        expected_updates.append((identifier_field, identifier_field))
        ordered.extend(
            (
                f"var {identifier_field} = action.random();",
                f"var_assign({identifier_field}, {anchor}.stable_identifier);",
                f'{anchor}.update("stable_identifier", {identifier_field});',
                f'{target}.update("{identifier_field}", {identifier_field});',
            )
        )
    expected_updates.append(("work", "work"))
    ordered.extend(
        (
            'var material_1 = action.input("MicroverseResource");',
            "prove_resource_stack_core(action, material_1,",
            'var material_2 = action.input("MicroverseResource");',
            "prove_resource_stack_core(action, material_2,",
            f"var work = action.intro_vdf(32, {target});",
            f'{target}.update("work", work);',
            'var ship = action.mutate("MicroverseShip");',
            "prove_fixed_versions(action, ship);",
            f"action.st_sum(ship.active_skill_type, 0, {skill_code});",
            "var next_action_serial = unsafe { ship.action_serial - (0 - 1) };",
            "action.st_sum(ship.action_serial, 1, next_action_serial);",
            'ship.update("active_skill_type", 0);',
            'ship.update("action_serial", next_action_serial);',
            "var next_constructor_ship_key = action.random();",
            "rotate_key(ship, next_constructor_ship_key);",
        )
    )

    compact = compact_rhai_tokens(source)
    compact_set_body = compact_rhai_tokens(set_body)

    def token_count(token: str) -> int:
        return compact.count(compact_rhai_tokens(token).strip())

    untouched = True
    for anchor, identifier_field in identifier_fields:
        export = compact_rhai_tokens(
            f'{target}.update("{identifier_field}", {identifier_field});'
        ).strip()
        position = compact.find(export)
        if position < 0 or f"{anchor}." in compact[position + len(export):]:
            untouched = False

    direct_input_values = any(
        f"{anchor}." in set_body
        or any(f"{anchor}." in value for _field, value in updates)
        for anchor, _identifier, _numeric_fields in anchors
    )
    role_sequence = re.findall(
        r'\baction\.(output|input|mutate)\s*\(\s*"([^"]+)"\s*\)',
        source,
    )
    final_identifier_field = identifier_fields[-1][1]
    semantic_vdf_tokens = (
        f'{target}.update("{final_identifier_field}", {final_identifier_field});',
        f"var work = action.intro_vdf(32, {target});",
        f'{target}.update("work", work);',
        'var ship = action.mutate("MicroverseShip");',
    )
    ship_updates = literal_object_update_pairs(source, "ship")
    return {
        "action_roles_target_anchors_materials_ship_mutate": (
            role_sequence == list(spec["roles"])
        ),
        "single_complete_placeholder_set": (
            source.count(f"{target}.set(") == 1
            and literal_object_set_fields(source, target) == [list(spec["set_fields"])]
            and token_count(
                "let placeholder_identifier = action.top_limb_u256(0);"
            )
            == 1
            and all(
                compact_rhai_tokens(
                    f'["{identifier_field}", placeholder_identifier]'
                ).strip()
                in compact_set_body
                for _anchor, identifier_field in identifier_fields
            )
            and all(
                compact_rhai_tokens(f'["{target_field}", 0]').strip()
                in compact_set_body
                for _anchor, _source_field, target_field in copied_fields
            )
        ),
        "witnessed_updates_exact": updates == expected_updates,
        "anchor_blocks_contiguous_and_ordered": ordered_rhai_tokens(source, ordered),
        "anchors_untouched_after_identifier_export": untouched,
        "vdf_after_final_semantic_update_before_ship_mutation": (
            ordered_rhai_tokens(source, semantic_vdf_tokens)
            and token_count(f"action.intro_vdf(32, {target})") == 1
        ),
        "ship_mutate_lifecycle_exact": (
            token_count('action.mutate("MicroverseShip")') == 1
            and token_count('action.input("MicroverseShip")') == 0
            and token_count('action.output("MicroverseShip")') == 0
            and token_count("consume_prepared_ship_core(") == 0
            and literal_object_set_fields(source, "ship") == []
            and ship_updates
            == [
                ("active_skill_type", "0"),
                ("action_serial", "next_action_serial"),
            ]
            and token_count('ship.update("stable_identifier"') == 0
            and token_count("var next_constructor_ship_key = action.random();") == 1
            and token_count("rotate_key(ship, next_constructor_ship_key);") == 1
        ),
        "no_direct_input_entries_in_output_mutation": not direct_input_values,
    }


def manifest_action_names(source: str) -> list[str]:
    result: list[str] = []
    in_action = False
    for line in source.splitlines():
        stripped = line.strip()
        if stripped == "[[actions]]":
            in_action = True
            continue
        if stripped.startswith("[["):
            in_action = False
        if in_action:
            match = re.fullmatch(r'name\s*=\s*"([A-Za-z_][A-Za-z0-9_]*)"', stripped)
            if match:
                result.append(match.group(1))
                in_action = False
    return result


def literal_in_source(source: str, value: Any) -> bool:
    if isinstance(value, str):
        return json.dumps(value) in source
    if is_int(value):
        rendered = str(value)
        # A positive fixed literal must not be satisfied by the same digits in
        # a negative value (for example, required `1` accidentally matching
        # `-1`).  Negative literals include their sign in the exact token.
        left_boundary = r"(?<![A-Za-z0-9_])" if value < 0 else r"(?<![A-Za-z0-9_-])"
        return (
            re.search(
                rf"{left_boundary}{re.escape(rendered)}(?![A-Za-z0-9_])",
                source,
            )
            is not None
        )
    if isinstance(value, bool):
        return re.search(rf"\b{str(value).lower()}\b", source) is not None
    return False


def validate_rhai(
    rhai_path: Path,
    manifest_path: Path,
    index: Mapping[str, Any],
    validation: Validation,
    resource_catalog: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    try:
        source = rhai_path.read_text(encoding="utf-8")
    except OSError as error:
        validation.error("rhai.read", str(error), str(rhai_path))
        return {}
    stripped = strip_rhai_comments(source)
    source_bytes = len(source.encode("utf-8"))
    validation.check(
        source_bytes <= 1_000_000,
        "rhai.hard_size_limit",
        f"Rhai source is {source_bytes} bytes; hard limit is 1,000,000",
        str(rhai_path),
    )
    validation.check(
        source_bytes <= 990_000,
        "rhai.safety_size_limit",
        f"Rhai source is {source_bytes} bytes; release safety limit is 990,000",
        str(rhai_path),
    )
    forbidden_words = ("if", "else", "for", "while", "loop", "match", "switch", "break", "continue")
    for word in forbidden_words:
        hits = list(re.finditer(rf"\b{word}\b", stripped))
        validation.check(
            not hits,
            "rhai.control_flow",
            f"prohibited control-flow keyword {word!r} appears {len(hits)} time(s)",
            str(rhai_path),
        )
    validation.check(
        "%" not in stripped and not re.search(r"\bmod(?:ulo)?\b", stripped, re.I),
        "rhai.modulo",
        "Rhai must not use %, mod, or modulo",
        str(rhai_path),
    )
    validation.check(
        ".subaction(" not in stripped and "subaction(" not in stripped,
        "rhai.subaction",
        "Rhai must not use subactions",
        str(rhai_path),
    )
    stable_identifier_projection = re.findall(
        r"\btop_limb_u256\s*\([^)]*stable_identifier[^)]*\)",
        source,
        flags=re.DOTALL,
    )
    validation.check(
        not stable_identifier_projection,
        "rhai.stable_identifier_projection",
        "Rhai must not project a stable identifier into an integer selection "
        f"value; found {len(stable_identifier_projection)} occurrence(s)",
        str(rhai_path),
    )
    functions = extract_rhai_functions(source)
    validation.check(
        len(functions) == len(re.findall(r"(?m)^fn\s+", mask_rhai_comments(source))),
        "rhai.function_parse",
        "all Rhai function definitions must have a canonical balanced source shape",
        str(rhai_path),
    )
    manifest_names: list[str] = []
    try:
        manifest_names = manifest_action_names(manifest_path.read_text(encoding="utf-8"))
    except OSError as error:
        validation.error("manifest.read", str(error), str(manifest_path))
    validation.check(
        len(manifest_names) == len(set(manifest_names)),
        "manifest.action_duplicate",
        "manifest action names must be unique",
        str(manifest_path),
    )
    missing_wrappers = sorted(set(manifest_names) - set(functions))
    validation.check(
        not missing_wrappers,
        "rhai.wrapper_missing",
        f"manifest actions missing Rhai wrappers: {missing_wrappers[:20]}",
        str(rhai_path),
    )
    action_set = set(manifest_names)
    phase4_observed = set(functions) & PHASE4_KNOWN_HELPER_NAMES
    current_rhai_profile = (
        phase4_observed
        == {
            name for name, _kind, _iterations, _representative
            in PHASE4_CURRENT_HELPERS
        }
    )
    if current_rhai_profile:
        validation.check(
            len(manifest_names) == CURRENT_PROFILE_ACTION_COUNT,
            "rhai.current_action_count",
            f"current profile must expose exactly {CURRENT_PROFILE_ACTION_COUNT} actions, got {len(manifest_names)}",
            str(manifest_path),
        )
        indexed_names = {
            str(row.get("name"))
            for row in action_rows(index)
            if isinstance(row.get("name"), str)
        }
        validation.check(
            bool(indexed_names)
            and action_set.issubset(indexed_names)
            and indexed_names - action_set == CURRENT_PROFILE_OMITTED_ACTIONS,
            "rhai.current_action_omissions",
            "current profile may omit only the frozen medium/large movement actions",
            str(rhai_path),
        )
        for action_name, (iterations, target) in CURRENT_PROFILE_BUILD_VDF_TAILS.items():
            function = functions.get(action_name, "")
            validation.check(
                current_literal_vdf_tail_exact(function, iterations, target),
                "rhai.current_build_vdf_tail",
                f"{action_name} must own exactly one adjacent literal VDF/work tail "
                f"with cost {iterations} on {target}",
                f"{rhai_path}:{action_name}",
            )
        for action_name in CURRENT_PROFILE_BASE_MOVES:
            function = functions.get(action_name, "")
            validation.check(
                action_name in action_set
                and "intro_vdf" not in function
                and not re.search(r'\.update\s*\(\s*"work"', function)
                and "ship.extraction_amount" not in function
                and "ship.rare_extraction_amount" not in function,
                "rhai.current_base_move_shape",
                f"{action_name} must not retain VDF/work or economy extraction-capacity gates",
                f"{rhai_path}:{action_name}",
            )
    validate_phase3_canaries(
        source,
        functions,
        action_set,
        resource_catalog,
        validation,
        rhai_path,
    )
    validate_phase4_adapter_canaries(
        source,
        functions,
        action_set,
        index,
        resource_catalog,
        validation,
        rhai_path,
    )
    validate_phase5_adapter_canaries(
        source,
        functions,
        action_set,
        index,
        validation,
        rhai_path,
    )
    validate_phase6_movement_canaries(
        source,
        functions,
        action_set,
        index,
        validation,
        rhai_path,
    )
    validate_phase6_layout_contract(
        source,
        functions,
        action_set,
        index,
        validation,
        rhai_path,
    )
    for action in manifest_names:
        function = functions.get(action, "")
        signature = re.match(rf"fn\s+{re.escape(action)}\s*\(\s*action\s*\)", function)
        validation.check(
            signature is not None,
            "rhai.wrapper_signature",
            f"action wrapper {action} must have exactly one `action` parameter",
            f"{rhai_path}:{action}",
        )
        plain_calls = set(
            re.findall(
                r"(?<![.A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(",
                function[function.find("{") + 1 :],
            )
        )
        routed = sorted(plain_calls & action_set)
        validation.check(
            not routed,
            "rhai.action_to_action",
            f"action {action} calls action wrapper(s) {routed}",
            f"{rhai_path}:{action}",
        )
        witness_rows, helper_cycles = flattened_unsafe_witness_scope(
            action,
            functions,
            action_set,
        )
        validation.check(
            not helper_cycles,
            "rhai.helper_cycle",
            f"action {action} has transitive helper cycle(s) {helper_cycles[:5]}",
            f"{rhai_path}:{action}",
        )
        witness_origins: defaultdict[str, list[str]] = defaultdict(list)
        for witness_name, origin in witness_rows:
            witness_origins[witness_name].append(origin)
        witness_collisions = {
            name: origins
            for name, origins in witness_origins.items()
            if len(origins) > 1
        }
        validation.check(
            not witness_collisions,
            "rhai.unsafe_witness_collision",
            f"action {action} repeats flattened unsafe witness name(s) "
            f"{dict(list(witness_collisions.items())[:5])}",
            f"{rhai_path}:{action}",
        )

    reveal_action_sets = {
        "v1.position": {
            name for name in action_set if re.fullmatch(r"RevealWarpCoordinate\d{3}", name)
        },
        "v1.time": {
            name for name in action_set if re.fullmatch(r"RevealTimeCoordinate\d{2}", name)
        },
        "v2.position": {
            name for name in action_set if re.fullmatch(r"RevealWarpChart\d{3}", name)
        },
        "v2.time": {
            name for name in action_set if re.fullmatch(r"RevealEpochChart\d{3}", name)
        },
    }
    expected_reveal_sets = {
        "v1.position": {f"RevealWarpCoordinate{code:03d}" for code in range(1, 126)},
        "v1.time": {f"RevealTimeCoordinate{code:02d}" for code in range(1, 87)},
        "v2.position": {f"RevealWarpChart{code:03d}" for code in range(1, 257)},
        "v2.time": {f"RevealEpochChart{code:03d}" for code in range(1, 129)},
    }
    validation.check(
        reveal_action_sets == expected_reveal_sets,
        "rhai.explicit_reveal_action_set",
        "manifest/Rhai must expose exactly 595 contiguous explicit reveal "
        "actions across the four catalogs",
        str(rhai_path),
    )
    for helper_name, object_handle in (
        ("reveal_p", "coordinate"),
        ("reveal_t", "coordinate"),
        ("reveal_chart_p", "chart"),
        ("reveal_chart_t", "chart"),
    ):
        helper_source = functions.get(helper_name, "")
        compact_helper = re.sub(r"\s+", "", strip_rhai_comments(helper_source))
        validation.check(
            bool(helper_source)
            and compact_helper.count(
                f"action.st_gt({object_handle}.source_pool_before,"
                "minimum_source_pool_exclusive);"
            )
            == 1
            and "stable_identifier" not in helper_source
            and "top_limb_u256" not in helper_source
            and "intro_lt_eq_u256" not in helper_source,
            "rhai.explicit_reveal_helper",
            f"{helper_name} must enforce exactly one singular source_pool_before "
            "lower bound and must not use a stable-ID selector, top limb, or "
            "LtEq comparison",
            f"{rhai_path}:{helper_name}",
        )

    indexed_source_actions = action_rows(index)
    indexed_source_by_name = {
        str(row.get("name")): row
        for row in indexed_source_actions
        if isinstance(row.get("name"), str)
    }
    for catalog_name, expected_names in expected_reveal_sets.items():
        helper_name = {
            "v1.position": "reveal_p",
            "v1.time": "reveal_t",
            "v2.position": "reveal_chart_p",
            "v2.time": "reveal_chart_t",
        }[catalog_name]
        for action_name in expected_names:
            row = indexed_source_by_name.get(action_name)
            fixed = row.get("fixed_literals") if isinstance(row, Mapping) else None
            destination = (
                fixed.get("warp_destination")
                if isinstance(fixed, Mapping)
                and isinstance(fixed.get("warp_destination"), Mapping)
                else None
            )
            if not isinstance(destination, Mapping):
                continue
            minimum = destination.get("minimum_source_pool_inclusive")
            if not is_int(minimum):
                continue
            expected_arguments = (
                ["action", "c"]
                if catalog_name.startswith("v1.")
                else ["action", "n", "s", "c"]
            )
            expected_arguments.extend([str(destination.get("code"))])
            if catalog_name.endswith("position"):
                expected_arguments.extend(
                    str(destination.get(axis)) for axis in ("x", "y", "z")
                )
            else:
                expected_arguments.append(str(destination.get("epoch")))
            expected_arguments.extend(
                [str(destination.get("uses")), str(minimum - 1)]
            )
            function = functions.get(action_name, "")
            validation.check(
                flat_rhai_call_arguments(function, helper_name)
                == [expected_arguments]
                and "stable_identifier" not in function
                and "intro_lt_eq_u256" not in function
                and "top_limb_u256" not in function,
                "rhai.explicit_reveal_wrapper",
                f"{action_name} must call {helper_name} once with the exact "
                "catalog destination and inclusive minimum minus one, with no "
                "stable-ID selector",
                f"{rhai_path}:{action_name}",
            )

    expected_survey = {
        name: (profile, minimum) for name, profile, minimum in SURVEY_SELECTIONS
    }
    actual_survey_names = {
        name for name in action_set if name.startswith("SurveySector_")
    }
    validation.check(
        actual_survey_names == set(expected_survey),
        "rhai.survey_action_set",
        "Rhai must expose exactly five explicit Survey profile actions",
        str(rhai_path),
    )
    for action_name, (profile, minimum) in expected_survey.items():
        function = functions.get(action_name, "")
        compact_function = re.sub(r"\s+", "", function)
        validation.check(
            compact_function.count(
                f"action.st_gt(ship.claim_serial,{minimum - 1});"
            )
            == 1
            and compact_function.count(
                f'sector.update("survey_profile",{profile});'
            )
            == 1
            and "intro_lt_eq_u256" not in function
            and "stable_identifier" not in function
            and "top_limb_u256" not in function,
            "rhai.survey_selection_gate",
            f"{action_name} must deterministically select profile {profile} "
            f"and prove claim_serial >= {minimum}, without a stable-ID range",
            f"{rhai_path}:{action_name}",
        )

    expected_civilizations = {
        name: (civilization_type, minimum)
        for name, civilization_type, minimum in CIVILIZATION_SELECTIONS
    }
    actual_civilization_names = {
        name for name in action_set if name.startswith("MaterializeCivilization")
    }
    validation.check(
        actual_civilization_names == set(expected_civilizations),
        "rhai.civilization_action_set",
        "Rhai must expose exactly three explicit Civilization actions",
        str(rhai_path),
    )
    for action_name, (civilization_type, minimum) in expected_civilizations.items():
        function = functions.get(action_name, "")
        compact_function = re.sub(r"\s+", "", function)
        binding_patterns = (
            r"var\s+source_life_signal_identifier\s*=\s*action\.random\(\)\s*;",
            r"var_assign\s*\(\s*source_life_signal_identifier\s*,\s*"
            r"life_signal\.stable_identifier\s*\)\s*;",
            r"life_signal\.update\s*\(\s*\"stable_identifier\"\s*,\s*"
            r"source_life_signal_identifier\s*\)\s*;",
            r"\[\s*\"source_life_signal_identifier\"\s*,\s*"
            r"source_life_signal_identifier\s*\]",
        )
        binding_matches = [
            list(re.finditer(pattern, function, flags=re.DOTALL))
            for pattern in binding_patterns
        ]
        ordered_binding = (
            all(len(matches) == 1 for matches in binding_matches)
            and all(
                binding_matches[index][0].start()
                < binding_matches[index + 1][0].start()
                for index in range(len(binding_matches) - 1)
            )
        )
        validation.check(
            compact_function.count(
                "action.st_gt(ship.civilization_scan_serial,"
                f"{minimum - 1});"
            )
            == 1
            and compact_function.count(
                f'["civilization_type",{civilization_type}]'
            )
            == 1
            and ordered_binding
            and "unsafe{source_life_signal_identifier" not in compact_function
            and "st_sum(source_life_signal_identifier" not in compact_function
            and "intro_lt_eq_u256" not in function
            and "top_limb_u256(life_signal.stable_identifier" not in compact_function,
            "rhai.civilization_selection_and_raw_binding",
            f"{action_name} must prove civilization_scan_serial >= {minimum}, "
            "select its fixed type, and securely bind the consumed LifeSignal "
            "Raw stable identifier through random/var_assign/no-op update",
            f"{rhai_path}:{action_name}",
        )

    scan_names = {
        name for name in action_set if name.startswith("ScanCelestialBody_")
    }
    scan_helper = functions.get("scan_body_core", "")
    compact_scan_helper = re.sub(r"\s+", "", scan_helper)
    validation.check(
        len(scan_names) == 23
        and compact_scan_helper.count(
            "lettarget=action.top_limb_u256(target_top_limb);"
        )
        == 1
        and compact_scan_helper.count(
            "action.intro_lt_eq_u256(signal,target);"
        )
        == 1
        and "intro_lt_eq_u256(signal.stable_identifier" not in compact_scan_helper
        and sum(
            strip_rhai_comments(function).count("action.intro_lt_eq_u256(")
            for function in functions.values()
        )
        == 1,
        "rhai.scan_whole_object_threshold",
        "the 23 named Scan actions must share the sole physical LtEq call, "
        "comparing the complete CelestialSignal object to fixed target_top_limb",
        f"{rhai_path}:scan_body_core",
    )
    for action_name in scan_names:
        validation.check(
            len(flat_rhai_call_arguments(functions.get(action_name, ""), "scan_body_core"))
            == 1
            and "intro_lt_eq_u256" not in functions.get(action_name, ""),
            "rhai.scan_named_action",
            f"{action_name} must call scan_body_core exactly once and must not "
            "own an additional LtEq comparison",
            f"{rhai_path}:{action_name}",
        )

    anchor_capture_actions = {"CapturePositionAnchor", "CaptureTimeAnchor"}
    if anchor_capture_actions.issubset(action_set):
        bind_ship_id = functions.get("bind_ship_id", "")
        prepared_ship = functions.get("consume_prepared_ship_core", "")
        capture_sources = [
            functions.get(action, "") for action in sorted(anchor_capture_actions)
        ]
        validation.check(
            ordered_rhai_tokens(
                bind_ship_id,
                (
                    "var bound_ship_id = action.random();",
                    "var_assign(bound_ship_id, ship.ship_id);",
                    'ship.update("ship_id", bound_ship_id);',
                    "bound_ship_id",
                ),
            )
            and ordered_rhai_tokens(
                prepared_ship,
                (
                    "var ship_id = bind_ship_id(action, ship);",
                    "action.st_sum(ship.active_skill_type, 0, required_skill_type);",
                    "ship_id",
                ),
            ),
            "rhai.anchor_ship_id_raw_helper",
            "anchor source_ship_id must originate in the random+var_assign Raw "
            "ship_id binding and flow unchanged through consume_prepared_ship_core",
            f"{rhai_path}:consume_prepared_ship_core",
        )
        validation.check(
            all(
                compact_rhai_tokens(source).count(compact_rhai_tokens(
                    "var source_ship_id = consume_prepared_ship_core("
                ).strip()) == 1
                and compact_rhai_tokens(source).count(compact_rhai_tokens(
                    '["source_ship_id", source_ship_id]'
                ).strip()) == 1
                and compact_rhai_tokens("unsafe { source_ship_id").strip()
                not in compact_rhai_tokens(source)
                and compact_rhai_tokens("st_sum(source_ship_id").strip()
                not in compact_rhai_tokens(source)
                for source in capture_sources
            ),
            "rhai.anchor_ship_id_raw_output",
            "both anchor outputs must set source_ship_id from the Raw helper "
            "binding without unsafe arithmetic or st_sum coercion",
            str(rhai_path),
        )

    for action, spec in WITNESSED_ANCHOR_CONSTRUCTORS.items():
        if action not in action_set:
            continue
        function = functions.get(action, "")
        checks = witnessed_constructor_checks(function, spec)
        validation.check(
            all(checks.values()),
            "rhai.witnessed_anchor_binding",
            f"{action} must use the rc.43-safe Shape J order: target, "
            f"contiguous witnessed anchors, materials, target VDF/work, then "
            f"the exact Ship-mutate lifecycle; failed="
            f"{[name for name, passed in checks.items() if not passed]}",
            f"{rhai_path}:{action}",
        )
        validation.check(
            checks["no_direct_input_entries_in_output_mutation"],
            "rhai.direct_anchor_output_value",
            f"{action} must not pass an input anchor entry directly to output "
            "set/update; each copied value requires an equality witness",
            f"{rhai_path}:{action}",
        )

    for action, fields in CHART_DESTINATION_INITIALIZERS.items():
        if action not in action_set:
            continue
        function = functions.get(action, "")
        set_field_groups = literal_object_set_fields(function, "chart")
        expected_set_fields = list(CHART_EXTRACTION_SET_FIELDS[action])
        missing_set_fields = [
            field
            for field in fields
            if re.search(
                rf'\[\s*"{re.escape(field)}"\s*,\s*0\s*\]',
                function,
            )
            is None
        ]
        invalid_updates = [
            field
            for field in fields
            if re.search(
                rf'\bchart\.update\s*\(\s*"{re.escape(field)}"',
                function,
            )
            is not None
        ]
        compact_function = compact_rhai_tokens(function)
        missing_source_bindings = [
            token
            for token in (
                "var source_body_identifier = action.random();",
                "var_assign(source_body_identifier, body.stable_identifier);",
                'body.update("stable_identifier", source_body_identifier);',
                "var source_pool_before = unsafe { body.energy_remaining - 0 };",
                "action.st_sum(body.energy_remaining, 0, source_pool_before);",
                '["source_body_identifier", source_body_identifier]',
                '["source_pool_before", source_pool_before]',
            )
            if compact_rhai_tokens(token).strip() not in compact_function
        ]
        validation.check(
            set_field_groups == [expected_set_fields]
            and not missing_set_fields
            and not invalid_updates,
            "rhai.chart_destination_initialization",
            f"{action} must use exactly one complete grouped chart.set before "
            f"any update; expected={expected_set_fields}, "
            f"actual={set_field_groups}, missing destination fields="
            f"{missing_set_fields}, invalid updates={invalid_updates}",
            f"{rhai_path}:{action}",
        )
        validation.check(
            not missing_source_bindings,
            "rhai.chart_source_witness_binding",
            f"{action} must bind the pre-mutation body identifier and energy "
            f"through wrapper-local equality witnesses before its grouped set; "
            f"missing={missing_source_bindings}",
            f"{rhai_path}:{action}",
        )

    if set(CHART_DESTINATION_INITIALIZERS).issubset(action_set):
        extraction_helper = functions.get("extract_v2_chart_core", "")
        validation.check(
            not literal_object_set_fields(extraction_helper, "chart"),
            "rhai.chart_single_set_owner",
            "extract_v2_chart_core must not set chart fields; each extraction "
            "wrapper owns the one complete grouped chart.set",
            f"{rhai_path}:extract_v2_chart_core",
        )
        helper_copy_artifacts = [
            token
            for token in (
                "source_body_identifier",
                "source_pool_before",
                'body.update("stable_identifier"',
            )
            if token in extraction_helper
        ]
        validation.check(
            not helper_copy_artifacts,
            "rhai.chart_source_copy_artifact",
            "extract_v2_chart_core must not copy/no-op export body source "
            f"fields; found={helper_copy_artifacts}",
            f"{rhai_path}:extract_v2_chart_core",
        )

    indexed_actions = action_rows(index)
    if indexed_actions:
        # These two wrappers intentionally move their semantic work into the
        # fixed Phase 3 helpers.  Their full direct/transitive contracts are
        # checked above; applying index metadata as a *direct-wrapper* audit
        # here would reject the approved helper shape.
        phase3_transitively_validated_actions = {
            name
            for name in action_set
            if name.startswith("DetectCelestialSignal_")
            or name.startswith("SurveySector_")
        } if (
            "detect_signal_core" in functions
            or "prove_empty_survey_sector_core" in functions
        ) else set()
        indexed_names = {str(row.get("name")) for row in indexed_actions}
        if not current_rhai_profile:
            validation.check(
                indexed_names == action_set,
                "rhai.index_action_set",
                f"index/manifest action mismatch: index-only={sorted(indexed_names-action_set)[:20]}, "
                f"manifest-only={sorted(action_set-indexed_names)[:20]}",
                str(rhai_path),
            )
        for row in indexed_actions:
            name = str(row.get("name"))
            if name not in action_set:
                continue
            function = functions.get(name, "")
            current_phase4_route = (
                current_rhai_profile
                and row.get("family") in PHASE4_RESOURCE_FAMILIES
            )
            helper = first_present(row, "helper", "core_helper", "wrapper_helper")
            current_phase6_route = (
                current_rhai_profile
                and phase6_expected_index_helpers(name) == row.get("helpers")
            )
            direct_wrapper_metadata = name not in phase3_transitively_validated_actions
            if (
                direct_wrapper_metadata
                and not current_phase4_route
                and not current_phase6_route
                and isinstance(helper, str)
                and helper
            ):
                validation.check(
                    re.search(rf"\b{re.escape(helper)}\s*\(", function) is not None,
                    "rhai.wrapper_helper",
                    f"{name} must call helper {helper}",
                    f"{rhai_path}:{name}",
                )
            helpers = row.get("helpers")
            if helpers is not None:
                validation.check(
                    isinstance(helpers, list)
                    and all(isinstance(item, str) and item for item in helpers),
                    "rhai.wrapper_helpers_shape",
                    f"{name} helpers must be a flat list of function names",
                    f"{rhai_path}:{name}",
                )
                if isinstance(helpers, list):
                    for helper_name in helpers:
                        if not isinstance(helper_name, str):
                            continue
                        if (
                            direct_wrapper_metadata
                            and not current_phase4_route
                            and not current_phase6_route
                        ):
                            validation.check(
                                (
                                    helper_name in functions
                                    or helper_name in RHAI_PLAIN_SDK_PRIMITIVES
                                )
                                and re.search(
                                    rf"\b{re.escape(helper_name)}\s*\(", function
                                )
                                is not None,
                                "rhai.wrapper_helper",
                                f"{name} must call indexed helper {helper_name}",
                                f"{rhai_path}:{name}",
                            )
            # `fixed_literals` is rich semantic/provenance metadata and may
            # contain names, modes, and nested catalog records that are not
            # source literals.  `wrapper_literals` is the generator-owned flat
            # executable contract and is therefore the authoritative source
            # audit input.
            literals = first_present(
                row,
                "wrapper_literals",
                "literal_arguments",
                "fixed_literals",
            )
            values: Iterable[Any] = ()
            if isinstance(literals, Mapping):
                values = literals.values()
            elif isinstance(literals, list):
                values = literals
            if direct_wrapper_metadata:
                for value in values:
                    if (
                        current_rhai_profile
                        and value in CURRENT_PROFILE_VDF_LITERAL_EXEMPTIONS.get(
                            name, set()
                        )
                    ):
                        continue
                    validation.check(
                        literal_in_source(function, value),
                        "rhai.wrapper_literal",
                        f"{name} lacks required fixed literal {value!r}",
                        f"{rhai_path}:{name}",
                    )
            expected_objects = first_present(row, "objects", "roles")
            if isinstance(expected_objects, list):
                actual_objects = re.findall(
                    r'action\.(output|input|mutate)\("([A-Za-z_][A-Za-z0-9_]*)"\)',
                    function,
                )
                expected_pairs: list[tuple[str, str]] = []
                for item in expected_objects:
                    if isinstance(item, Mapping):
                        expected_pairs.append(
                            (
                                str(first_present(item, "mode", "object_mode")),
                                str(first_present(item, "class", "class_name")),
                            )
                        )
                    elif (
                        isinstance(item, (list, tuple))
                        and len(item) == 2
                    ):
                        expected_pairs.append((str(item[0]), str(item[1])))
                validation.check(
                    actual_objects == expected_pairs,
                    "rhai.wrapper_objects",
                    f"{name} object declaration order differs: expected {expected_pairs}, "
                    f"got {actual_objects}",
                    f"{rhai_path}:{name}",
                )
        counts = index.get("counts")
        if isinstance(counts, Mapping) and not current_rhai_profile:
            expected_count = first_present(counts, "actions", "action_count")
            validation.check(
                expected_count == len(manifest_names),
                "rhai.action_count",
                f"expected {expected_count!r} actions, manifest has {len(manifest_names)}",
                str(manifest_path),
            )
            family_counts = first_present(counts, "actions_by_family", "action_families")
            if isinstance(family_counts, Mapping):
                actual_families = Counter(
                    str(row.get("family")) for row in indexed_actions
                )
                validation.check(
                    dict(actual_families) == dict(family_counts),
                    "rhai.family_counts",
                    f"indexed action family counts {dict(actual_families)} != declared {dict(family_counts)}",
                    "index.counts",
                )
    return {
        "bytes": source_bytes,
        "function_count": len(functions),
        "action_count": len(manifest_names),
    }


def result_document(
    validation: Validation,
    catalog_dir: Path,
    rhai_state: Mapping[str, Any],
) -> dict[str, Any]:
    findings = [
        {
            "severity": item.severity,
            "code": item.code,
            "path": item.path,
            "message": item.message,
        }
        for item in validation.findings
    ]
    return {
        "status": "pass" if not validation.errors else "fail",
        "catalog_dir": str(catalog_dir),
        "checks": validation.check_count,
        "error_count": len(validation.errors),
        "warning_count": len(validation.warnings),
        "rhai": dict(rhai_state),
        "findings": findings,
    }


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--catalog-dir",
        type=Path,
        default=Path("catalog"),
        help="directory containing the five canonical v2 JSON catalogs",
    )
    parser.add_argument("--rhai", type=Path, default=Path("plugin.rhai"))
    parser.add_argument("--manifest", type=Path, default=Path("manifest.toml"))
    parser.add_argument(
        "--schema-sidecar",
        type=Path,
        help=(
            "generated schema-counts.json; defaults to "
            "<rhai-parent>/generated/schema-counts.json"
        ),
    )
    parser.add_argument(
        "--universe-contract",
        type=Path,
        help=(
            "generated universe-contract.json; defaults to "
            "<rhai-parent>/generated/universe-contract.json"
        ),
    )
    parser.add_argument(
        "--allow-missing-generated",
        action="store_true",
        help="allow warp/index catalogs to be absent during catalog authoring",
    )
    parser.add_argument(
        "--rhai-only",
        action="store_true",
        help="skip catalog validation and run the static Rhai/manifest audit only",
    )
    parser.add_argument(
        "--skip-rhai",
        action="store_true",
        help="validate catalogs without auditing generated Rhai",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="emit the complete machine-readable result rather than a concise summary",
    )
    args = parser.parse_args(argv)

    validation = Validation()
    catalog_dir = args.catalog_dir.resolve()
    catalogs: dict[str, Mapping[str, Any]] = {}
    if not args.rhai_only:
        for label, filename in CANONICAL_FILES.items():
            path = catalog_dir / filename
            if (
                args.allow_missing_generated
                and label in {"warp", "index"}
                and not path.exists()
            ):
                validation.warning(
                    "file.deferred",
                    f"deferred generated catalog is absent: {path}",
                    str(path),
                )
                catalogs[label] = {}
                continue
            value = load_json(path, validation)
            validation.check(
                isinstance(value, Mapping),
                "catalog.shape",
                f"{filename} root must be a JSON object",
                str(path),
            )
            catalogs[label] = value if isinstance(value, Mapping) else {}

    index = catalogs.get("index", {})
    resource_state: Mapping[str, Any] = {}
    component_state: Mapping[str, Any] = {}
    skill_state: Mapping[str, Any] = {}
    warp_state: Mapping[str, Any] = {}
    if catalogs.get("resources"):
        resource_state = validate_resource_catalog(
            catalogs["resources"],
            catalog_dir / CANONICAL_FILES["resources"],
            validation,
        )
    if catalogs.get("components"):
        component_state = validate_component_catalog(
            catalogs["components"],
            catalog_dir / CANONICAL_FILES["components"],
            validation,
            resource_state,
            index,
        )
    if catalogs.get("skills"):
        skill_state = validate_skill_catalog(
            catalogs["skills"],
            catalog_dir / CANONICAL_FILES["skills"],
            validation,
            component_state,
            resource_state,
            index,
        )
    if catalogs.get("warp"):
        warp_state = validate_warp_catalog(
            catalogs["warp"],
            catalog_dir / CANONICAL_FILES["warp"],
            validation,
        )
    if index:
        validate_index(
            index,
            catalog_dir / CANONICAL_FILES["index"],
            validation,
            {
                "resources": resource_state,
                "components": component_state,
                "skills": skill_state,
                "warp": warp_state,
            },
        )
    if index and warp_state:
        schema_sidecar_path = (
            args.schema_sidecar.resolve()
            if args.schema_sidecar is not None
            else args.rhai.resolve().parent / "generated" / "schema-counts.json"
        )
        schema_sidecar = load_json(schema_sidecar_path, validation)
        validation.check(
            isinstance(schema_sidecar, Mapping),
            "schema_sidecar.shape",
            "generated schema sidecar root must be an object",
            str(schema_sidecar_path),
        )
        if isinstance(schema_sidecar, Mapping):
            validate_schema_sidecar(
                schema_sidecar,
                schema_sidecar_path,
                validation,
                warp_state,
                index,
            )
        universe_contract_path = (
            args.universe_contract.resolve()
            if args.universe_contract is not None
            else args.rhai.resolve().parent
            / "generated"
            / "universe-contract.json"
        )
        universe_contract = load_json(universe_contract_path, validation)
        validation.check(
            isinstance(universe_contract, Mapping),
            "universe.shape",
            "generated universe contract root must be an object",
            str(universe_contract_path),
        )
        if isinstance(universe_contract, Mapping):
            validate_universe_selection_contract(
                universe_contract,
                universe_contract_path,
                validation,
                index,
            )

    rhai_state: Mapping[str, Any] = {}
    if not args.skip_rhai:
        rhai_state = validate_rhai(
            args.rhai.resolve(),
            args.manifest.resolve(),
            index,
            validation,
            catalogs.get("resources"),
        )

    result = result_document(validation, catalog_dir, rhai_state)
    if args.json:
        print(stable_json(result), end="")
    else:
        print(
            f"[{result['status']}] {result['checks']} checks; "
            f"{result['error_count']} error(s), {result['warning_count']} warning(s)"
        )
        for finding in result["findings"]:
            location = f" ({finding['path']})" if finding["path"] else ""
            print(
                f"{finding['severity'].upper()} {finding['code']}: "
                f"{finding['message']}{location}"
            )
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
