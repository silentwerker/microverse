use std::{
    any::Any,
    collections::{BTreeMap, HashSet},
    env, fs,
    panic::{AssertUnwindSafe, catch_unwind},
    path::{Path, PathBuf},
    sync::Arc,
    time::Instant,
};

use anyhow::{Context, Result, anyhow, bail};
use payload::{
    payload::{Payload, PayloadProof},
    shrink::{ShrunkMainPodBuild, ShrunkMainPodSetup, shrink_compress_pod},
    test_state::TestState,
};
use pod2::middleware::{
    EMPTY_VALUE, F, Hash, Params, RawValue, StrKey, Value as PodValue, containers::Dictionary,
};
use sdk::SpendableObject;
use serde::Deserialize;
use serde_json::{Value as JsonValue, json};
use txlib::{GroundingWitness, StateHeader, compute_nullifier, with_stable_identifier};

#[derive(Clone)]
struct LiveObject {
    class: String,
    object: SpendableObject,
}

const PAYLOAD_HARD_LIMIT_BYTES: usize = 126_945;
const DIRECT_SHIP_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "extraction_amount",
    "rare_extraction_amount",
    "x",
    "y",
    "z",
    "epoch",
    "active_skill_type",
    "action_serial",
    "claim_serial",
    "discovery_serial",
    "satellite_serial",
    "civilization_scan_serial",
    "ship_id",
];
const DIRECT_SECTOR_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "body_bank_version",
    "x",
    "y",
    "z",
    "epoch",
    "sector_type",
    "survey_profile",
    "planet_remaining",
    "star_remaining",
    "gas_giant_remaining",
    "ice_giant_remaining",
    "neutron_star_remaining",
    "black_hole_remaining",
    "anomaly_remaining",
    "megastructure_remaining",
    "gas_cluster_remaining",
    "stellar_remnant_remaining",
    "next_planet_serial",
    "next_star_serial",
    "next_gas_giant_serial",
    "next_ice_giant_serial",
    "next_neutron_star_serial",
    "next_black_hole_serial",
    "next_anomaly_serial",
    "next_megastructure_serial",
    "next_gas_cluster_serial",
    "next_stellar_remnant_serial",
    "revision",
];
const CELESTIAL_SIGNAL_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "body_bank_version",
    "sector_x",
    "sector_y",
    "sector_z",
    "sector_epoch",
    "category_code",
    "candidate_code",
    "slot_serial",
];
const CELESTIAL_BODY_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "body_bank_version",
    "sector_x",
    "sector_y",
    "sector_z",
    "sector_epoch",
    "candidate_code",
    "body_type",
    "life_stat",
    "matter_remaining",
    "crystal_remaining",
    "gas_remaining",
    "energy_remaining",
    "satellites_remaining",
    "next_satellite_serial",
    "civilization_discovered",
];
const RESOURCE_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "resource_type",
    "amount",
];
const COMPOSITE_RESOURCE_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "resource_type",
    "sector_x",
    "sector_y",
    "sector_z",
    "origin_epoch",
    "child_1_remaining",
    "child_2_remaining",
    "child_3_remaining",
];
const SATELLITE_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "sector_x",
    "sector_y",
    "sector_z",
    "sector_epoch",
    "satellite_serial",
];
const LIFE_SIGNAL_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "civilization_version",
    "sector_x",
    "sector_y",
    "sector_z",
    "origin_epoch",
];
const CIVILIZATION_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "civilization_version",
    "sector_x",
    "sector_y",
    "sector_z",
    "origin_epoch",
    "civilization_type",
];
const TECHNOLOGY_SKILL_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "civilization_version",
    "skill_type",
    "reusable",
];
const SHIP_SEMANTIC_FIELDS: &[&str] = &[
    "schema_version",
    "mechanics_version",
    "universe_version",
    "extraction_amount",
    "rare_extraction_amount",
    "x",
    "y",
    "z",
    "epoch",
    "claim_serial",
    "discovery_serial",
    "satellite_serial",
    "civilization_scan_serial",
];
const SHIP_LOGICAL_FIELDS: &[&str] = &[
    "schema_version",
    "mechanics_version",
    "universe_version",
    "extraction_amount",
    "rare_extraction_amount",
    "x",
    "y",
    "z",
    "epoch",
    "action_serial",
    "claim_serial",
    "discovery_serial",
    "satellite_serial",
    "civilization_scan_serial",
];
const DIRECT_COORD_ZERO: i64 = 1_000_000_000_000;
const ROUTE_COORD_UPPER_BOUND: i64 = 2_000_000_000_000;
const ROUTE_EPOCH_UPPER_BOUND: i64 = 1_000_000_000_000;
const ROUTE_ACTION_COST_HARD_LIMIT: u64 = 100_000;
const CIVILIZATION_TARGET_TOP_LIMB: u64 = 288_230_376_151_711_744;
const CIVILIZATION_TYPE_I_LOWER: u64 = 18_014_398_509_481_985;
const CIVILIZATION_TYPE_II_LOWER: u64 = 1_125_899_906_842_625;
const CIVILIZATION_TYPE_III_LOWER: u64 = 0;
const ROUTE_DESCRIPTOR_KIND: &str = "microverse_producer_route_qualification";
const ROUTE_COMMITMENT_STAGE: &str = "post_tx_insert_at_creation";
const ROUTE_CLASS_NAMES: &[&str] = &[
    "MicroverseShip",
    "MicroverseSector",
    "MicroverseCelestialSignal",
    "MicroverseCelestialBody",
    "MicroverseResource",
    "MicroverseSatellite",
    "MicroverseLifeSignal",
    "MicroverseCivilization",
];

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct SpecializedResourceSpec {
    action: &'static str,
    resource_type: i64,
    candidate_code: i64,
    remaining_field: &'static str,
}

const SPECIALIZED_RESOURCE_SPECS: &[SpecializedResourceSpec] = &[
    SpecializedResourceSpec {
        action: "ExtractStarStellarPlasma",
        resource_type: 5,
        candidate_code: 0,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStarFusionFuel",
        resource_type: 6,
        candidate_code: 0,
        remaining_field: "gas_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStarRadiantEnergy",
        resource_type: 7,
        candidate_code: 0,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStarMagneticFlux",
        resource_type: 8,
        candidate_code: 0,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStarHeavyElement",
        resource_type: 9,
        candidate_code: 0,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStarCoreMatter",
        resource_type: 10,
        candidate_code: 0,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractSterilePlanetOre",
        resource_type: 11,
        candidate_code: 3,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractSterilePlanetSilicate",
        resource_type: 12,
        candidate_code: 3,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractSterilePlanetCrystal",
        resource_type: 13,
        candidate_code: 3,
        remaining_field: "crystal_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractSterilePlanetGas",
        resource_type: 14,
        candidate_code: 3,
        remaining_field: "gas_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractSterilePlanetIce",
        resource_type: 15,
        candidate_code: 3,
        remaining_field: "crystal_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractSterilePlanetIsotope",
        resource_type: 16,
        candidate_code: 3,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractLivingPlanetBiomass",
        resource_type: 17,
        candidate_code: 5,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractLivingPlanetGeneticMaterial",
        resource_type: 18,
        candidate_code: 5,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractLivingPlanetBiochemicalCompound",
        resource_type: 19,
        candidate_code: 5,
        remaining_field: "gas_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractLivingPlanetMicrobialCulture",
        resource_type: 20,
        candidate_code: 5,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractLivingPlanetOrganismSample",
        resource_type: 21,
        candidate_code: 5,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractLivingPlanetLivingMaterial",
        resource_type: 22,
        candidate_code: 5,
        remaining_field: "crystal_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractGasClusterHydrogen",
        resource_type: 23,
        candidate_code: 13,
        remaining_field: "gas_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractGasClusterHelium",
        resource_type: 24,
        candidate_code: 13,
        remaining_field: "gas_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractGasClusterNobleGas",
        resource_type: 25,
        candidate_code: 13,
        remaining_field: "gas_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractGasClusterVolatileCompound",
        resource_type: 26,
        candidate_code: 13,
        remaining_field: "gas_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractGasClusterOrganicMolecule",
        resource_type: 27,
        candidate_code: 13,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractGasClusterIonizedGas",
        resource_type: 28,
        candidate_code: 13,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStellarRemnantMetalRichEjecta",
        resource_type: 29,
        candidate_code: 14,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStellarRemnantRadioactiveIsotope",
        resource_type: 30,
        candidate_code: 14,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStellarRemnantSupernovaDust",
        resource_type: 31,
        candidate_code: 14,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStellarRemnantShockHeatedPlasma",
        resource_type: 32,
        candidate_code: 14,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStellarRemnantRelativisticParticle",
        resource_type: 33,
        candidate_code: 14,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractStellarRemnantHighEnergyRadiation",
        resource_type: 34,
        candidate_code: 14,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractAnomalyWormhole",
        resource_type: 35,
        candidate_code: 11,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractAnomalyTemporalRift",
        resource_type: 36,
        candidate_code: 11,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractAnomalyGravitationalKnot",
        resource_type: 37,
        candidate_code: 11,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractAnomalyDarkMatterBloom",
        resource_type: 38,
        candidate_code: 11,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractAnomalyVacuumFracture",
        resource_type: 39,
        candidate_code: 11,
        remaining_field: "gas_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractAnomalyDimensionalPocket",
        resource_type: 40,
        candidate_code: 11,
        remaining_field: "crystal_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractMegastructureStructuralSegment",
        resource_type: 41,
        candidate_code: 12,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractMegastructurePowerCore",
        resource_type: 42,
        candidate_code: 12,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractMegastructureComputationCore",
        resource_type: 43,
        candidate_code: 12,
        remaining_field: "crystal_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractMegastructureFabricationModule",
        resource_type: 44,
        candidate_code: 12,
        remaining_field: "matter_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractMegastructureTransitModule",
        resource_type: 45,
        candidate_code: 12,
        remaining_field: "energy_remaining",
    },
    SpecializedResourceSpec {
        action: "ExtractMegastructureDataArchive",
        resource_type: 46,
        candidate_code: 12,
        remaining_field: "crystal_remaining",
    },
];

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct CivilizationTypeSpec {
    action: &'static str,
    civilization_type: i64,
    lower: u64,
    upper: u64,
}

const CIVILIZATION_TYPE_SPECS: &[CivilizationTypeSpec] = &[
    CivilizationTypeSpec {
        action: "MaterializeCivilizationTypeI",
        civilization_type: 1,
        lower: CIVILIZATION_TYPE_I_LOWER,
        upper: CIVILIZATION_TARGET_TOP_LIMB,
    },
    CivilizationTypeSpec {
        action: "MaterializeCivilizationTypeII",
        civilization_type: 2,
        lower: CIVILIZATION_TYPE_II_LOWER,
        upper: CIVILIZATION_TYPE_I_LOWER - 1,
    },
    CivilizationTypeSpec {
        action: "MaterializeCivilizationTypeIII",
        civilization_type: 3,
        lower: CIVILIZATION_TYPE_III_LOWER,
        upper: CIVILIZATION_TYPE_II_LOWER - 1,
    },
];

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct TechnologySkillSpec {
    action: &'static str,
    skill_type: i64,
    civilization_type: i64,
}

const TECHNOLOGY_SKILL_SPECS: &[TechnologySkillSpec] = &[
    TechnologySkillSpec {
        action: "DevelopTypeIIndustrialFabricationSkill",
        skill_type: 1,
        civilization_type: 1,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIElectronicsSkill",
        skill_type: 2,
        civilization_type: 1,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIChemicalEngineeringSkill",
        skill_type: 3,
        civilization_type: 1,
    },
    TechnologySkillSpec {
        action: "DevelopTypeINuclearEngineeringSkill",
        skill_type: 4,
        civilization_type: 1,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIGeneticEngineeringSkill",
        skill_type: 5,
        civilization_type: 1,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIPlanetaryInfrastructureSkill",
        skill_type: 6,
        civilization_type: 1,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIMetamaterialEngineeringSkill",
        skill_type: 7,
        civilization_type: 2,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIStellarEnergySystemsSkill",
        skill_type: 8,
        civilization_type: 2,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIISyntheticIntelligenceSkill",
        skill_type: 9,
        civilization_type: 2,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIMolecularFabricationSkill",
        skill_type: 10,
        civilization_type: 2,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIInterstellarNavigationSkill",
        skill_type: 11,
        civilization_type: 2,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIBiosphereEngineeringSkill",
        skill_type: 12,
        civilization_type: 2,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIIExoticMatterEngineeringSkill",
        skill_type: 13,
        civilization_type: 3,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIISpacetimeEngineeringSkill",
        skill_type: 14,
        civilization_type: 3,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIIGalacticIntelligenceArchitectureSkill",
        skill_type: 15,
        civilization_type: 3,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIIStellarEngineeringSkill",
        skill_type: 16,
        civilization_type: 3,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIIWorldSeedingSkill",
        skill_type: 17,
        civilization_type: 3,
    },
    TechnologySkillSpec {
        action: "DevelopTypeIIICivilizationEngineeringSkill",
        skill_type: 18,
        civilization_type: 3,
    },
];

fn specialized_resource_spec(action_name: &str) -> Option<SpecializedResourceSpec> {
    SPECIALIZED_RESOURCE_SPECS
        .iter()
        .copied()
        .find(|spec| spec.action == action_name)
}

fn civilization_type_spec(action_name: &str) -> Option<CivilizationTypeSpec> {
    CIVILIZATION_TYPE_SPECS
        .iter()
        .copied()
        .find(|spec| spec.action == action_name)
}

fn technology_skill_spec(action_name: &str) -> Option<TechnologySkillSpec> {
    TECHNOLOGY_SKILL_SPECS
        .iter()
        .copied()
        .find(|spec| spec.action == action_name)
}

fn candidate_code_from_action(action_name: &str, prefix: &str) -> Option<i64> {
    action_name
        .strip_prefix(prefix)?
        .split_once('_')
        .and_then(|(code, _)| code.parse().ok())
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct LifecycleFamilySpec {
    name: &'static str,
    target_class: &'static str,
    child_class: Option<&'static str>,
    ship_serial: Option<&'static str>,
}

fn is_reveal_audit_target(action_name: &str) -> bool {
    action_name.starts_with("SurveySector_")
}

fn lifecycle_family_spec(action_name: &str) -> Option<LifecycleFamilySpec> {
    if let Some(resource) = specialized_resource_spec(action_name) {
        // Tech-tree v2 composite extractions have a different output schema
        // and decrement a whole selected body pool. Their exact source shape
        // is enforced by the generator audit; this v1 lifecycle reporter
        // deliberately leaves them not-applicable instead of misreporting
        // them as one-unit terminal Resource extractions.
        const COMPOSITE_RESOURCE_TYPES: &[i64] = &[
            6, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 25, 26, 27, 29, 30, 31, 41, 42,
            43, 44, 45, 46,
        ];
        if COMPOSITE_RESOURCE_TYPES.contains(&resource.resource_type) {
            None
        } else {
            Some(LifecycleFamilySpec {
                name: "specialized-resource",
                target_class: "celestial_body",
                child_class: Some("resource"),
                ship_serial: Some("resource_serial"),
            })
        }
    } else if technology_skill_spec(action_name).is_some() {
        Some(LifecycleFamilySpec {
            name: "develop-technology-skill",
            target_class: "civilization",
            child_class: Some("technology_skill"),
            ship_serial: None,
        })
    } else if action_name == "UseTechnologySkill" {
        // v2 follows CraftRocket TouchMachine semantics: possession is proven
        // by mutating and key-rotating the reusable skill, without anchoring
        // that portable skill to the Ship's current coordinates.
        None
    } else if is_reveal_audit_target(action_name) {
        Some(LifecycleFamilySpec {
            name: "survey-sector",
            target_class: "sector",
            child_class: None,
            ship_serial: None,
        })
    } else if action_name.starts_with("DetectCelestialSignal_") {
        Some(LifecycleFamilySpec {
            name: "detect-celestial-signal",
            target_class: "sector",
            child_class: Some("celestial_signal"),
            ship_serial: Some("discovery_serial"),
        })
    } else if matches!(
        action_name,
        "ExtractAnomalyWarpCoordinate" | "ExtractAnomalyTimeCoordinate"
    ) {
        // Coordinate extraction has its own sealed-object lifecycle and does
        // not emit MicroverseResource. It is covered by the dedicated
        // late-game scenario suite rather than the generic resource audit.
        None
    } else if extracted_resource_field(action_name).is_some() {
        // Only the four legacy one-unit terminal Resource actions use this
        // reporter. Tech-tree v2 advanced extractions have replacement-Ship
        // and direct/composite output shapes that are exercised by the
        // exhaustive suites and dedicated producer-derived sequences.
        Some(LifecycleFamilySpec {
            name: "extract-resource",
            target_class: "celestial_body",
            child_class: Some("resource"),
            ship_serial: Some("resource_serial"),
        })
    } else if action_name == "DiscoverSatellite" {
        Some(LifecycleFamilySpec {
            name: "discover-satellite",
            target_class: "celestial_body",
            child_class: Some("satellite"),
            ship_serial: Some("satellite_serial"),
        })
    } else if action_name == "DetectIntelligentLife" {
        Some(LifecycleFamilySpec {
            name: "detect-intelligent-life",
            target_class: "celestial_body",
            child_class: Some("life_signal"),
            ship_serial: Some("civilization_scan_serial"),
        })
    } else {
        None
    }
}

fn lifecycle_class_fields(class: &str) -> Option<&'static [&'static str]> {
    match class {
        "spaceship" => Some(DIRECT_SHIP_FIELDS),
        "sector" => Some(DIRECT_SECTOR_FIELDS),
        "celestial_signal" => Some(CELESTIAL_SIGNAL_FIELDS),
        "celestial_body" => Some(CELESTIAL_BODY_FIELDS),
        "composite_resource" => Some(COMPOSITE_RESOURCE_FIELDS),
        "resource" => Some(RESOURCE_FIELDS),
        "satellite" => Some(SATELLITE_FIELDS),
        "life_signal" => Some(LIFE_SIGNAL_FIELDS),
        "civilization" => Some(CIVILIZATION_FIELDS),
        "technology_skill" => Some(TECHNOLOGY_SKILL_FIELDS),
        _ => None,
    }
}

fn lifecycle_location_fields(class: &str) -> Option<[&'static str; 4]> {
    match class {
        "sector" => Some(["x", "y", "z", "epoch"]),
        "celestial_signal" | "celestial_body" | "satellite" => {
            Some(["sector_x", "sector_y", "sector_z", "sector_epoch"])
        }
        "composite_resource" | "life_signal" | "civilization" => {
            Some(["sector_x", "sector_y", "sector_z", "origin_epoch"])
        }
        _ => None,
    }
}

fn extracted_resource_field(action_name: &str) -> Option<(&'static str, i64)> {
    match action_name {
        "ExtractMatter" => Some(("matter_remaining", 1)),
        "ExtractCrystal" => Some(("crystal_remaining", 2)),
        "ExtractGas" => Some(("gas_remaining", 3)),
        "ExtractEnergy" => Some(("energy_remaining", 4)),
        _ => None,
    }
}

fn allowed_target_mutations(action_name: &str, family: &str) -> Result<Vec<&'static str>> {
    match family {
        "survey-sector" => Ok(vec![
            "key",
            "sector_type",
            "survey_profile",
            "planet_remaining",
            "star_remaining",
            "gas_giant_remaining",
            "ice_giant_remaining",
            "neutron_star_remaining",
            "black_hole_remaining",
            "anomaly_remaining",
            "megastructure_remaining",
            "gas_cluster_remaining",
            "stellar_remnant_remaining",
            "revision",
        ]),
        "detect-celestial-signal" => Ok(vec![
            "key",
            "planet_remaining",
            "star_remaining",
            "gas_giant_remaining",
            "ice_giant_remaining",
            "neutron_star_remaining",
            "black_hole_remaining",
            "anomaly_remaining",
            "megastructure_remaining",
            "gas_cluster_remaining",
            "stellar_remnant_remaining",
            "next_planet_serial",
            "next_star_serial",
            "next_gas_giant_serial",
            "next_ice_giant_serial",
            "next_neutron_star_serial",
            "next_black_hole_serial",
            "next_anomaly_serial",
            "next_megastructure_serial",
            "next_gas_cluster_serial",
            "next_stellar_remnant_serial",
            "revision",
        ]),
        "specialized-resource" => {
            let spec = specialized_resource_spec(action_name)
                .ok_or_else(|| anyhow!("unsupported specialized resource action {action_name}"))?;
            Ok(vec!["key", "work", spec.remaining_field])
        }
        "extract-resource" => {
            let (remaining_field, _) = extracted_resource_field(action_name)
                .ok_or_else(|| anyhow!("unsupported extraction action {action_name}"))?;
            Ok(vec!["key", "work", remaining_field])
        }
        "discover-satellite" => Ok(vec!["key", "satellites_remaining", "next_satellite_serial"]),
        "detect-intelligent-life" => Ok(vec!["key", "civilization_discovered"]),
        "develop-technology-skill" | "use-technology-skill" => Ok(vec!["key"]),
        _ => bail!("unsupported lifecycle family {family}"),
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct MaterializerSpec {
    input_class: &'static str,
    output_class: &'static str,
}

fn materializer_spec(action_name: &str) -> Option<MaterializerSpec> {
    if action_name.starts_with("ScanCelestialBody_") {
        Some(MaterializerSpec {
            input_class: "celestial_signal",
            output_class: "celestial_body",
        })
    } else if civilization_type_spec(action_name).is_some() {
        Some(MaterializerSpec {
            input_class: "life_signal",
            output_class: "civilization",
        })
    } else {
        None
    }
}

fn exact_action_occurrences(actions: &[String], target: &str) -> usize {
    actions
        .iter()
        .filter(|action| action.as_str() == target)
        .count()
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq)]
#[serde(deny_unknown_fields)]
struct RoutePoint {
    x: i64,
    y: i64,
    z: i64,
    epoch: i64,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq)]
#[serde(deny_unknown_fields)]
struct RouteCandidate {
    code: i64,
    name: String,
    slug: String,
    body_type: i64,
    body_profile: i64,
    nominal_denominator: u64,
    target_top_limb: i64,
    life_stat: i64,
    matter: i64,
    crystal: i64,
    gas: i64,
    energy: i64,
    satellites: i64,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct RouteSearch {
    candidate_code: i64,
    requirement: String,
    max_action_cost: u64,
    #[serde(default = "default_route_minimum_epoch")]
    minimum_epoch: i64,
    minimum_possible_action_cost: u64,
    ordering: RouteOrdering,
    points_tested: u64,
    seconds: f64,
}

fn default_route_minimum_epoch() -> i64 {
    1
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq)]
#[serde(deny_unknown_fields)]
struct RouteOrdering {
    primary: String,
    tie_breakers: Vec<String>,
    spatial_metric: String,
    zero_displacement_policy: String,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq)]
#[serde(deny_unknown_fields)]
struct RouteNavigation {
    dx: i64,
    dy: i64,
    dz: i64,
    spatial_move_count: u64,
    timewarp_count: u64,
}

#[derive(Clone, Debug, Deserialize, Eq, PartialEq)]
#[serde(deny_unknown_fields)]
struct RouteCoordinateValidation {
    source: String,
    start: RoutePoint,
    derived_final: RoutePoint,
    expected_final: RoutePoint,
    pass: bool,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct RouteActions {
    actions: Vec<String>,
    action_count: u64,
    action_cost: u64,
    cost_model: String,
    action_counts: BTreeMap<String, u64>,
    navigation: RouteNavigation,
    coordinate_validation: RouteCoordinateValidation,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct ExpectedRouteObject {
    created_by_action: String,
    commitment_stage: String,
    initial_stable_identifier: String,
    full_object_commitment: String,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct ExpectedRouteObjects {
    sector: ExpectedRouteObject,
    celestial_signal: ExpectedRouteObject,
    celestial_body: ExpectedRouteObject,
    life_signal: Option<ExpectedRouteObject>,
    civilization: Option<ExpectedRouteObject>,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct RouteQualificationCheck {
    input: String,
    comparison: String,
    value_raw_u256: String,
    value_limbs_le: [u64; 4],
    target_raw_u256: String,
    target_limbs_le: [u64; 4],
    target_top_limb: u64,
    passes: bool,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct RouteQualification {
    celestial_signal: RouteQualificationCheck,
    life_signal: Option<RouteQualificationCheck>,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct RouteBodyBankDescriptor {
    source: String,
    body_bank_version: u64,
    candidate_count: u64,
}

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct LifecycleRouteDescriptor {
    schema_version: u64,
    kind: String,
    status: String,
    descriptor_only: bool,
    descriptor_notice: String,
    module_hash: String,
    class_hashes: BTreeMap<String, String>,
    body_bank: RouteBodyBankDescriptor,
    search: RouteSearch,
    candidate: RouteCandidate,
    point: RoutePoint,
    route: RouteActions,
    expected_objects: ExpectedRouteObjects,
    qualification: RouteQualification,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct DirectTierExpectation {
    ship_tier: i64,
    movement_step: i64,
    timewarp_step: i64,
}

fn direct_tier_expectation(action_name: &str) -> Option<DirectTierExpectation> {
    match action_name {
        "ClaimSectorSmall" => Some(DirectTierExpectation {
            ship_tier: 0,
            movement_step: 1,
            timewarp_step: 1,
        }),
        "ClaimSectorMedium" => Some(DirectTierExpectation {
            ship_tier: 1,
            movement_step: 10,
            timewarp_step: 10,
        }),
        "ClaimSectorLarge" => Some(DirectTierExpectation {
            ship_tier: 2,
            movement_step: 100,
            timewarp_step: 100,
        }),
        _ => None,
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum ClaimProfile {
    C01,
    C02,
    C03,
    C04,
    C05,
    C06,
    DirectReplacement,
    Production,
}

impl ClaimProfile {
    fn parse(value: &str) -> Result<Self> {
        match value.to_ascii_lowercase().as_str() {
            "c01" => Ok(Self::C01),
            "c02" => Ok(Self::C02),
            "c03" => Ok(Self::C03),
            "c04" => Ok(Self::C04),
            "c05" => Ok(Self::C05),
            "c06" => Ok(Self::C06),
            "direct" | "direct-replacement" | "replacement" => Ok(Self::DirectReplacement),
            "production" | "final" => Ok(Self::Production),
            _ => bail!(
                "unknown Claim audit profile {value}; expected c01, c02, c03, c04, c05, c06, direct-replacement, or production"
            ),
        }
    }

    fn name(self) -> &'static str {
        match self {
            Self::C01 => "c01",
            Self::C02 => "c02",
            Self::C03 => "c03",
            Self::C04 => "c04",
            Self::C05 => "c05",
            Self::C06 => "c06",
            Self::DirectReplacement => "direct-replacement",
            Self::Production => "production",
        }
    }

    fn requires_binding(self) -> bool {
        !matches!(self, Self::C01)
    }

    fn requires_full_sector(self) -> bool {
        matches!(
            self,
            Self::C03
                | Self::C04
                | Self::C05
                | Self::C06
                | Self::DirectReplacement
                | Self::Production
        )
    }

    fn expected_serial_delta(self) -> i64 {
        if matches!(
            self,
            Self::C04 | Self::C05 | Self::C06 | Self::DirectReplacement | Self::Production
        ) {
            1
        } else {
            0
        }
    }

    fn expects_work_change(self) -> bool {
        matches!(self, Self::C05 | Self::C06 | Self::DirectReplacement)
    }

    fn requires_collision(self) -> bool {
        matches!(self, Self::Production)
    }

    fn is_direct_replacement(self) -> bool {
        matches!(self, Self::DirectReplacement)
    }
}

struct PayloadMetrics {
    payload_bytes: usize,
    serialized_proof_bytes: usize,
    live_count: usize,
    nullifier_count: usize,
    seconds: f64,
    headroom_bytes: i64,
    utilization: f64,
    utilization_percent: f64,
    fits_hard_limit: bool,
}

struct AuditStep {
    inputs: Vec<SpendableObject>,
    selected_indices: Vec<usize>,
    input_classes: Vec<String>,
    output_classes: Vec<String>,
    outputs: sdk::SpendableObjects,
    payload: PayloadMetrics,
    live_commitments: Vec<Hash>,
    nullifiers: Vec<Hash>,
    planning_seconds: f64,
    execution_seconds: f64,
    statements: usize,
    operations: usize,
    pods: usize,
    state_root: Hash,
}

fn exact_raw_string(value: &PodValue) -> String {
    hash_string(Hash::from(value.raw()))
}

fn value_report(value: &PodValue) -> JsonValue {
    json!({
        "display": value.to_string(),
        "raw": exact_raw_string(value),
        "int": value.as_int(),
    })
}

fn object_field(object: &SpendableObject, field: &str) -> Result<PodValue> {
    object
        .obj
        .get(&StrKey::from(field))?
        .ok_or_else(|| anyhow!("object is missing required field {field}"))
}

fn object_int(object: &SpendableObject, field: &str) -> Result<i64> {
    object_field(object, field)?
        .as_int()
        .ok_or_else(|| anyhow!("object field {field} is not an integer"))
}

fn object_has_exact_fields(object: &SpendableObject, expected: &[&str]) -> Result<bool> {
    let actual = object
        .obj
        .iter()
        .map(|entry| entry.map(|(field, _)| field))
        .collect::<Result<HashSet<_>, _>>()?;
    let expected = expected
        .iter()
        .map(|field| (*field).to_string())
        .collect::<HashSet<_>>();
    Ok(actual == expected)
}

fn object_report(class: &str, object: &SpendableObject) -> Result<JsonValue> {
    let mut fields = BTreeMap::new();
    for entry in object.obj.iter() {
        let (field, value) = entry?;
        fields.insert(field, value_report(&value));
    }
    Ok(json!({
        "class": class,
        "commitment": hash_string(object.obj.commitment()),
        "fields": fields,
    }))
}

fn object_fields(object: &SpendableObject) -> Result<BTreeMap<String, PodValue>> {
    object
        .obj
        .iter()
        .map(|entry| {
            entry
                .map(|(field, value)| (field, value))
                .map_err(anyhow::Error::from)
        })
        .collect()
}

fn fields_equal(left: &SpendableObject, right: &SpendableObject, fields: &[&str]) -> Result<bool> {
    fields
        .iter()
        .map(|field| {
            object_field(left, field)
                .and_then(|left_value| {
                    object_field(right, field).map(|right_value| left_value == right_value)
                })
                .map(|same| (*field, same))
        })
        .collect::<Result<Vec<_>>>()
        .map(|comparisons| comparisons.iter().all(|(_, same)| *same))
}

fn fields_equal_except(
    before: &SpendableObject,
    after: &SpendableObject,
    excluded_fields: &[&str],
) -> Result<bool> {
    let mut before_fields = object_fields(before)?;
    let mut after_fields = object_fields(after)?;
    for field in excluded_fields {
        before_fields.remove(*field);
        after_fields.remove(*field);
    }
    Ok(before_fields == after_fields)
}

fn sorted_hash_strings(values: &HashSet<Hash>) -> Vec<String> {
    let mut strings = values
        .iter()
        .map(|value| hash_string(*value))
        .collect::<Vec<_>>();
    strings.sort();
    strings
}

fn inventory_objects_report(inventory: &[LiveObject]) -> Result<Vec<JsonValue>> {
    inventory
        .iter()
        .enumerate()
        .map(|(index, item)| {
            Ok(json!({
                "inventory_index": index,
                "object": object_report(&item.class, &item.object)?,
            }))
        })
        .collect()
}

fn harness_snapshot(
    state: &TestState,
    inventory: &[LiveObject],
    globally_created: &HashSet<Hash>,
    globally_nullified: &HashSet<Hash>,
) -> Result<JsonValue> {
    let (created_root, nullifiers_root, prior_state_history_root) = state.roots();
    Ok(json!({
        "state_block": state.block_number,
        "state_root": hash_string(state_header(state).hash()),
        "created_root": hash_string(created_root),
        "nullifiers_root": hash_string(nullifiers_root),
        "prior_state_history_root": hash_string(prior_state_history_root),
        "inventory": inventory_objects_report(inventory)?,
        "globally_created": sorted_hash_strings(globally_created),
        "globally_nullified": sorted_hash_strings(globally_nullified),
    }))
}

fn panic_message(payload: Box<dyn Any + Send>) -> String {
    if let Some(message) = payload.downcast_ref::<&str>() {
        (*message).to_string()
    } else if let Some(message) = payload.downcast_ref::<String>() {
        message.clone()
    } else {
        "non-string panic payload".to_string()
    }
}

fn object_initial_commitment(object: &SpendableObject) -> Result<Hash> {
    let mut initial: Dictionary = object.obj.clone();
    initial
        .delete(&StrKey::from("stable_identifier"))
        .context("removing stable_identifier to reconstruct initial object")?;
    Ok(initial.commitment())
}

fn class_matches(class: &str, suffix: &str) -> bool {
    fn normalized(value: &str) -> String {
        value
            .strip_prefix("microverse__")
            .or_else(|| value.strip_prefix("Microverse"))
            .unwrap_or(value)
            .chars()
            .filter(|character| character.is_ascii_alphanumeric())
            .flat_map(char::to_lowercase)
            .collect()
    }

    let class = normalized(class);
    let suffix = normalized(suffix);
    class == suffix
        || matches!(
            (class.as_str(), suffix.as_str()),
            ("ship", "spaceship") | ("spaceship", "ship")
        )
}

fn class_sequence_matches(classes: &[String], expected_suffixes: &[&str]) -> bool {
    classes.len() == expected_suffixes.len()
        && classes
            .iter()
            .zip(expected_suffixes)
            .all(|(class, suffix)| class_matches(class, suffix))
}

fn unique_class_object<'a>(
    classes: &'a [String],
    objects: &'a [SpendableObject],
    suffix: &str,
) -> Result<(&'a str, &'a SpendableObject)> {
    let matches = classes
        .iter()
        .zip(objects)
        .filter(|(class, _)| class_matches(class, suffix))
        .collect::<Vec<_>>();
    if matches.len() != 1 {
        bail!(
            "expected exactly one {suffix} object, found {} in {:?}",
            matches.len(),
            classes
        );
    }
    Ok((matches[0].0.as_str(), matches[0].1))
}

fn unique_inventory_object<'a>(
    inventory: &'a [LiveObject],
    suffix: &str,
) -> Result<(&'a str, &'a SpendableObject)> {
    let matches = inventory
        .iter()
        .filter(|item| class_matches(&item.class, suffix))
        .collect::<Vec<_>>();
    if matches.len() != 1 {
        bail!(
            "expected exactly one live {suffix} object, found {}",
            matches.len()
        );
    }
    Ok((matches[0].class.as_str(), &matches[0].object))
}

fn bool_assertion(assertions: &mut BTreeMap<String, bool>, name: impl Into<String>, value: bool) {
    assertions.insert(name.into(), value);
}

fn fixed_int_is(object: &SpendableObject, field: &str, expected: i64) -> bool {
    object_int(object, field).is_ok_and(|actual| actual == expected)
}

fn load_module(plugin_root: &Path) -> Result<(pexe::PluginSource, std::rc::Rc<sdk::SdkModule>)> {
    let source = pexe::PluginSource::read(plugin_root)?;
    let manifest = source.parse_manifest()?;
    let action_names: Vec<&str> = manifest
        .actions
        .iter()
        .map(|action| action.name.as_str())
        .collect();
    let module = sdk::Sdk::default()
        .load_module_from_src_actions(&source.script, &action_names)
        .context("loading generated module")?;
    Ok((source, module))
}

fn hash_string(hash: pod2::middleware::Hash) -> String {
    format!("{hash:#}").to_ascii_lowercase()
}

fn inspect_module(plugin_root: &Path) -> Result<()> {
    let (source, module) = load_module(plugin_root)?;
    let manifest = source.parse_manifest()?;
    let classes: Vec<_> = module
        .classes()
        .iter()
        .map(|class| {
            json!({
                "name": class.name,
                "hash": module.class_hash(&class.name).map(hash_string),
                "bridge_count": class.actions.len(),
                "branches": class.actions.iter().map(|(action, object_index)| {
                    json!({"action": action, "object_index": object_index})
                }).collect::<Vec<_>>(),
            })
        })
        .collect();
    let actions: Vec<_> = module
        .actions()
        .iter()
        .map(|action| {
            json!({
                "name": action.name,
                "hash": module.action_hash(&action.name).map(hash_string),
                "inputs": action.total_inputs().map(|item| item.class.clone()).collect::<Vec<_>>(),
                "outputs": action.total_outputs().map(|item| item.class.clone()).collect::<Vec<_>>(),
            })
        })
        .collect();
    let bridge_count = module
        .classes()
        .iter()
        .map(|class| class.actions.len())
        .sum::<usize>();
    println!(
        "{}",
        serde_json::to_string_pretty(&json!({
            "module_hash": hash_string(module.module().batch.id()),
            "manifest_module_hash": hash_string(manifest.plugin.module_hash),
            "action_count": actions.len(),
            "class_count": classes.len(),
            "bridge_count": bridge_count,
            "actions": actions,
            "classes": classes,
        }))?
    );
    Ok(())
}

fn plan_action(plugin_root: &Path, action_name: &str) -> Result<()> {
    let (_source, module) = load_module(plugin_root)?;
    let action = module
        .actions()
        .iter()
        .find(|action| action.name == action_name)
        .ok_or_else(|| anyhow!("unknown action {action_name}"))?;
    let input_classes: Vec<String> = action
        .total_inputs()
        .map(|object| object.class.clone())
        .collect();
    let minted = pexe::fixtures::mint_classes(&module, &input_classes)?;
    let state = pexe::fixtures::build_synthetic_state(&minted)?;
    let executor = module.executor(true, state.grounding_witness);
    let started = Instant::now();
    let plan = executor.plan_action(action_name, state.spendable)?;
    let elapsed = started.elapsed().as_secs_f64();
    let solution = plan.solved.solution();
    let pods = solution.pod_statements.len();
    println!(
        "{}",
        serde_json::to_string_pretty(&json!({
            "action": action_name,
            "seconds": elapsed,
            "statements": plan.statements.len(),
            "operations": plan.operations.len(),
            "pods": pods,
            "output_pods": (0..pods).filter(|index| solution.is_output_pod(*index)).count(),
            "assigned_statement_slots": solution.pod_statements.iter().map(Vec::len).sum::<usize>(),
            "input_classes": input_classes,
            "synthetic_fixture": true,
        }))?
    );
    Ok(())
}

fn update_fixture_field(object: &mut Dictionary, field: &str, value: PodValue) -> Result<()> {
    let key = StrKey::from(field);
    if object.get(&key)?.is_some() {
        object
            .update(&key, &value)
            .with_context(|| format!("updating synthetic fixture field {field}"))
            .map(|_| ())
    } else {
        object
            .insert(&key, &value)
            .with_context(|| format!("inserting synthetic fixture field {field}"))
            .map(|_| ())
    }
}

fn restamp_fixture(object: &mut Dictionary) -> Result<()> {
    object
        .delete(&StrKey::from("stable_identifier"))
        .context("removing stale synthetic stable_identifier")?;
    *object = with_stable_identifier(object);
    Ok(())
}

fn action_script<'a>(script: &'a str, action_name: &str) -> Option<&'a str> {
    let action_marker = format!("fn {action_name}(action)");
    let action_start = script.find(&action_marker)?;
    let action_tail = &script[action_start..];
    let action_end = action_tail[1..]
        .find("\nfn ")
        .map(|offset| offset + 1)
        .unwrap_or(action_tail.len());
    Some(&action_tail[..action_end])
}

fn action_int_literal_constraint(script: &str, action_name: &str, field: &str) -> Option<i64> {
    let action_source = action_script(script, action_name)?;
    let constraint_prefix = format!("action.st_sum({field},0,");
    action_source.lines().find_map(|line| {
        line.chars()
            .filter(|character| !character.is_ascii_whitespace())
            .collect::<String>()
            .strip_prefix(&constraint_prefix)
            .and_then(|value| value.strip_suffix(");"))
            .and_then(|value| value.parse::<i64>().ok())
    })
}

fn action_core_ship_capacity(script: &str, action_name: &str) -> Option<i64> {
    let action_source = action_script(script, action_name)?;
    let marker = if action_source.contains("extract_direct_resource_core(") {
        "extract_direct_resource_core("
    } else if action_source.contains("extract_composite_resource_core(") {
        "extract_composite_resource_core("
    } else {
        return None;
    };
    let call = action_source.split_once(marker)?.1.split_once(");")?.0;
    let literals = call
        .lines()
        .filter_map(|line| line.trim().trim_end_matches(',').parse::<i64>().ok())
        .collect::<Vec<_>>();
    // Generic resources pass resource_type before extraction_amount.
    // Individual-class resources omit resource_type. Composite calls have
    // additional common/uncommon pool amounts, so argument count alone cannot
    // distinguish the two forms.
    let generic_output = action_source.contains("action.output(\"MicroverseResource\")")
        || action_source.contains("action.output(\"MicroverseCompositeResource\")");
    if generic_output {
        literals.get(1).copied()
    } else {
        literals.first().copied()
    }
}

fn action_core_ship_skill(script: &str, action_name: &str) -> Option<i64> {
    let action_source = action_script(script, action_name)?;
    let marker = if action_source.contains("extract_direct_resource_core(") {
        "extract_direct_resource_core("
    } else if action_source.contains("extract_composite_resource_core(") {
        "extract_composite_resource_core("
    } else {
        return None;
    };
    action_source
        .split_once(marker)?
        .1
        .split_once(");")?
        .0
        .lines()
        .filter_map(|line| line.trim().trim_end_matches(',').parse::<i64>().ok())
        .last()
}

fn reveal_coordinate_lower_limb(script: &str, action_name: &str) -> Option<u64> {
    let action_source = action_script(script, action_name)?;
    let (marker, lower_index) = if action_source.contains("reveal_p(") {
        ("reveal_p(", 7_usize)
    } else if action_source.contains("reveal_t(") {
        ("reveal_t(", 5_usize)
    } else if action_source.contains("reveal_position_coordinate_core(") {
        ("reveal_position_coordinate_core(", 7_usize)
    } else if action_source.contains("reveal_time_coordinate_core(") {
        ("reveal_time_coordinate_core(", 5_usize)
    } else {
        return None;
    };
    action_source
        .split_once(marker)?
        .1
        .split_once(");")?
        .0
        .split(',')
        .nth(lower_index)?
        .trim()
        .parse::<i64>()
        .ok()
        .map(|value| value as u64)
}

fn individual_use_skill_type(action_name: &str) -> Option<i64> {
    let suffix = action_name.strip_prefix("Use")?;
    TECHNOLOGY_SKILL_SPECS
        .iter()
        .find(|spec| spec.action.ends_with(suffix))
        .map(|spec| spec.skill_type)
}

fn configure_synthetic_inputs(
    action_name: &str,
    ship_capacity: i64,
    source_skill_type: Option<i64>,
    source_parent_type: Option<i64>,
    source_body_type: Option<i64>,
    reveal_lower_limb: Option<u64>,
    input_classes: &[String],
    objects: &mut [Dictionary],
) -> Result<()> {
    let rare_capacity = match ship_capacity {
        10 => 1,
        50 => 5,
        250 => 25,
        _ => bail!("synthetic Ship capacity must be 10, 50, or 250"),
    };
    let resources = resource_requirements(action_name);
    let permits = permit_requirements(action_name);
    let desired_candidate = desired_body_code(action_name)
        .or_else(|| specialized_resource_spec(action_name).map(|spec| spec.candidate_code));
    let desired_skill = source_skill_type
        .or_else(|| desired_skill_type(action_name))
        .or_else(|| individual_use_skill_type(action_name))
        .unwrap_or(0);
    let mut resource_index = 0_usize;
    let mut permit_index = 0_usize;

    for (class, object) in input_classes.iter().zip(objects.iter_mut()) {
        if class_matches(class, "spaceship") {
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("extraction_amount", ship_capacity),
                ("rare_extraction_amount", rare_capacity),
                ("x", 1_000),
                ("y", 1_000),
                ("z", 1_000),
                ("epoch", 100),
                ("active_skill_type", desired_skill),
                ("action_serial", 0),
                ("claim_serial", 0),
                ("discovery_serial", 0),
                ("satellite_serial", 0),
                ("civilization_scan_serial", 0),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if class_matches(class, "resource") {
            let (resource_type, amount) =
                resources.get(resource_index).copied().with_context(|| {
                    format!(
                        "missing synthetic recipe requirement {} for {action_name}",
                        resource_index + 1
                    )
                })?;
            resource_index += 1;
            update_fixture_field(object, "resource_type", PodValue::from(resource_type))?;
            update_fixture_field(object, "amount", PodValue::from(amount))?;
        } else if class_matches(class, "composite_resource") {
            let parent_type = source_parent_type
                .or_else(|| refinement_parent_resource_type(action_name))
                .with_context(|| {
                    format!("missing synthetic composite parent type for {action_name}")
                })?;
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("resource_type", parent_type),
                ("sector_x", 1_000),
                ("sector_y", 1_000),
                ("sector_z", 1_000),
                ("origin_epoch", 100),
                ("child_1_remaining", 100),
                ("child_2_remaining", 100),
                ("child_3_remaining", 100),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if class_matches(class, "civilization") {
            let stage = technology_skill_spec(action_name)
                .map(|skill| skill.civilization_type)
                .unwrap_or(1);
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("civilization_version", 1),
                ("sector_x", 1_000),
                ("sector_y", 1_000),
                ("sector_z", 1_000),
                ("origin_epoch", 100),
                ("civilization_type", stage),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if class_matches(class, "life_signal") {
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("civilization_version", 1),
                ("sector_x", 1_000),
                ("sector_y", 1_000),
                ("sector_z", 1_000),
                ("origin_epoch", 100),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if class_matches(class, "technology_skill") {
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("civilization_version", 1),
                ("skill_type", desired_skill.max(1)),
                ("reusable", 1),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if class_matches(class, "shipyard_permit") {
            let permit_type = permits.get(permit_index).copied().unwrap_or(1);
            permit_index += 1;
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("permit_type", permit_type),
                ("x", 1_000),
                ("y", 1_000),
                ("z", 1_000),
                ("epoch", 100),
                (
                    "industrial_authorized",
                    i64::from(action_name == "BuildShipLarge"),
                ),
                (
                    "electronics_authorized",
                    i64::from(action_name == "BuildShipLarge"),
                ),
                (
                    "molecular_authorized",
                    i64::from(action_name == "BuildShipLarge"),
                ),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if class_matches(class, "warp_coordinate") {
            update_fixture_field(
                object,
                "source_body_identifier",
                PodValue::from(Hash::from(target_raw_value(1))),
            )?;
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("source_pool_before", 9_000),
                ("revealed", i64::from(!action_name.starts_with("Reveal"))),
                ("destination_code", 1),
                ("destination_x", 100),
                ("destination_y", 200),
                ("destination_z", 300),
                (
                    "uses_remaining",
                    if action_name.ends_with("Reusable") {
                        3
                    } else {
                        1
                    },
                ),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if class_matches(class, "time_coordinate") {
            update_fixture_field(
                object,
                "source_body_identifier",
                PodValue::from(Hash::from(target_raw_value(1))),
            )?;
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("source_pool_before", 9_000),
                ("revealed", i64::from(!action_name.starts_with("Reveal"))),
                ("destination_code", 1),
                ("destination_epoch", 100),
                (
                    "uses_remaining",
                    if action_name.ends_with("Reusable") {
                        3
                    } else {
                        1
                    },
                ),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if class_matches(class, "celestial_body") {
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("body_bank_version", 1),
                ("sector_x", 1_000),
                ("sector_y", 1_000),
                ("sector_z", 1_000),
                ("sector_epoch", 100),
                ("candidate_code", desired_candidate.unwrap_or(3)),
                ("body_type", source_body_type.unwrap_or(1)),
                (
                    "life_stat",
                    if action_name == "DetectIntelligentLife" {
                        4
                    } else {
                        0
                    },
                ),
                ("matter_remaining", 50_000),
                ("crystal_remaining", 50_000),
                ("gas_remaining", 50_000),
                ("energy_remaining", 50_000),
                ("satellites_remaining", 1),
                ("next_satellite_serial", 0),
                ("civilization_discovered", 0),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if individual_use_skill_type(action_name).is_some() {
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("civilization_version", 1),
                ("reusable", 1),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if action_name.starts_with("Refine") {
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("sector_x", 1_000),
                ("sector_y", 1_000),
                ("sector_z", 1_000),
                ("origin_epoch", 100),
                ("child_1_remaining", 100),
                ("child_2_remaining", 100),
                ("child_3_remaining", 100),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        } else if let Some((_legacy_resource_type, amount)) = resources.get(resource_index).copied()
        {
            resource_index += 1;
            for (field, value) in [
                ("schema_version", 1),
                ("mechanics_version", 1),
                ("universe_version", 1),
                ("amount", amount),
            ] {
                update_fixture_field(object, field, PodValue::from(value))?;
            }
        }
        restamp_fixture(object)?;
        if class_matches(class, "life_signal") {
            if let Some(civilization_type) = civilization_type_spec(action_name) {
                update_fixture_field(
                    object,
                    "stable_identifier",
                    PodValue::from(Hash::from(target_raw_value(civilization_type.lower))),
                )?;
            }
        } else if (class_matches(class, "warp_coordinate")
            || class_matches(class, "time_coordinate"))
            && action_name.starts_with("Reveal")
        {
            let lower_limb = reveal_lower_limb
                .with_context(|| format!("missing reveal lower-limb literal for {action_name}"))?;
            update_fixture_field(
                object,
                "stable_identifier",
                PodValue::from(Hash::from(target_raw_value(lower_limb))),
            )?;
        }
    }

    Ok(())
}

#[derive(Clone)]
struct SyntheticNegativeCase {
    action: String,
    category: &'static str,
    label: String,
    class_suffix: &'static str,
    occurrence: usize,
    field: &'static str,
    value: i64,
}

fn action_core_remaining_field(script: &str, action_name: &str) -> Option<String> {
    let action_source = action_script(script, action_name)?;
    let marker = if action_source.contains("extract_direct_resource_core(") {
        "extract_direct_resource_core("
    } else if action_source.contains("extract_composite_resource_core(") {
        "extract_composite_resource_core("
    } else {
        return None;
    };
    action_source
        .split_once(marker)?
        .1
        .split_once(");")?
        .0
        .lines()
        .map(str::trim)
        .find_map(|line| {
            line.strip_prefix('"')
                .and_then(|value| value.strip_suffix("\","))
                .map(str::to_string)
        })
}

fn action_refinement_pool_field(script: &str, action_name: &str) -> Option<&'static str> {
    let source = action_script(script, action_name)?;
    [
        "child_1_remaining",
        "child_2_remaining",
        "child_3_remaining",
    ]
    .into_iter()
    .find(|field| source.contains(&format!("action.st_gt(parent.{field}, 0);")))
}

fn add_negative_case(
    cases: &mut Vec<SyntheticNegativeCase>,
    action: &str,
    category: &'static str,
    label: impl Into<String>,
    class_suffix: &'static str,
    occurrence: usize,
    field: &'static str,
    value: i64,
) {
    cases.push(SyntheticNegativeCase {
        action: action.to_string(),
        category,
        label: label.into(),
        class_suffix,
        occurrence,
        field,
        value,
    });
}

fn synthetic_negative_cases(
    source: &pexe::PluginSource,
    module: &sdk::SdkModule,
) -> Vec<SyntheticNegativeCase> {
    let mut cases = Vec::new();
    for action in module.actions() {
        let name = action.name.as_str();
        let action_source = action_script(&source.script, name).unwrap_or_default();
        let core_skill = action_core_ship_skill(&source.script, name);
        let literal_skill =
            action_int_literal_constraint(&source.script, name, "ship.active_skill_type");
        if let Some(required_skill) = literal_skill.or(core_skill) {
            let wrong_skill = if required_skill == 18 {
                17
            } else {
                required_skill + 1
            };
            add_negative_case(
                &mut cases,
                name,
                "wrong_skill",
                format!("required_{required_skill}_provided_{wrong_skill}"),
                "spaceship",
                0,
                "active_skill_type",
                wrong_skill,
            );
        }

        if let Some(candidate) =
            action_int_literal_constraint(&source.script, name, "body.candidate_code")
        {
            add_negative_case(
                &mut cases,
                name,
                "wrong_body_candidate",
                format!("required_{candidate}"),
                "celestial_body",
                0,
                "candidate_code",
                (candidate + 1) % 15,
            );
            add_negative_case(
                &mut cases,
                name,
                "location_mismatch",
                "body_sector_x_differs_from_ship",
                "celestial_body",
                0,
                "sector_x",
                1_001,
            );
        }
        if let Some(body_type) =
            action_int_literal_constraint(&source.script, name, "body.body_type")
        {
            add_negative_case(
                &mut cases,
                name,
                "wrong_body_type",
                format!("required_{body_type}"),
                "celestial_body",
                0,
                "body_type",
                body_type + 1,
            );
        }
        if let Some(remaining_field) = action_core_remaining_field(&source.script, name) {
            let field = match remaining_field.as_str() {
                "matter_remaining" => "matter_remaining",
                "crystal_remaining" => "crystal_remaining",
                "gas_remaining" => "gas_remaining",
                "energy_remaining" => "energy_remaining",
                _ => continue,
            };
            add_negative_case(
                &mut cases,
                name,
                "depleted_body_pool",
                field,
                "celestial_body",
                0,
                field,
                0,
            );
            let required_capacity = action_core_ship_capacity(&source.script, name).unwrap_or(10);
            add_negative_case(
                &mut cases,
                name,
                "wrong_ship_tier",
                format!("required_capacity_{required_capacity}"),
                "spaceship",
                0,
                "extraction_amount",
                if required_capacity == 10 { 50 } else { 10 },
            );
        }

        if matches!(
            name,
            "ExtractAnomalyWarpCoordinate" | "ExtractAnomalyTimeCoordinate"
        ) {
            add_negative_case(
                &mut cases,
                name,
                "depleted_body_pool",
                "energy_below_9000",
                "celestial_body",
                0,
                "energy_remaining",
                8_999,
            );
            add_negative_case(
                &mut cases,
                name,
                "wrong_ship_tier",
                "coordinate_extraction_requires_large_ship",
                "spaceship",
                0,
                "extraction_amount",
                10,
            );
        }

        if let Some(parent_type) =
            action_int_literal_constraint(&source.script, name, "parent.resource_type")
        {
            add_negative_case(
                &mut cases,
                name,
                "wrong_refinement_parent",
                format!("required_{parent_type}"),
                "composite_resource",
                0,
                "resource_type",
                parent_type + 1,
            );
            add_negative_case(
                &mut cases,
                name,
                "location_mismatch",
                "parent_sector_x_differs_from_ship",
                "composite_resource",
                0,
                "sector_x",
                1_001,
            );
        }
        if let Some(pool_field) = action_refinement_pool_field(&source.script, name) {
            add_negative_case(
                &mut cases,
                name,
                "depleted_refinement_pool",
                pool_field,
                "composite_resource",
                0,
                pool_field,
                0,
            );
        }

        if let Some(civilization_type) =
            technology_skill_spec(name).map(|spec| spec.civilization_type)
        {
            add_negative_case(
                &mut cases,
                name,
                "wrong_civilization_tier",
                format!("required_{civilization_type}"),
                "civilization",
                0,
                "civilization_type",
                if civilization_type == 3 {
                    2
                } else {
                    civilization_type + 1
                },
            );
        }

        for (index, (resource_type, amount)) in resource_requirements(name).iter().enumerate() {
            add_negative_case(
                &mut cases,
                name,
                "wrong_recipe_type",
                format!("ingredient_{}", index + 1),
                "resource",
                index,
                "resource_type",
                resource_type + 1,
            );
            add_negative_case(
                &mut cases,
                name,
                "wrong_recipe_amount",
                format!("ingredient_{}", index + 1),
                "resource",
                index,
                "amount",
                amount + 1,
            );
        }

        for (index, permit_type) in permit_requirements(name).iter().enumerate() {
            add_negative_case(
                &mut cases,
                name,
                "wrong_permit_type",
                format!("permit_{}", index + 1),
                "shipyard_permit",
                index,
                "permit_type",
                permit_type + 1,
            );
            if action_source.contains("action.st_sum(permit.x, 0, x);") {
                add_negative_case(
                    &mut cases,
                    name,
                    "location_mismatch",
                    "permit_x_differs_from_ship",
                    "shipyard_permit",
                    index,
                    "x",
                    1_001,
                );
            }
        }

        if name == "BuildShipLarge" {
            for field in [
                "industrial_authorized",
                "electronics_authorized",
                "molecular_authorized",
            ] {
                add_negative_case(
                    &mut cases,
                    name,
                    "missing_permit_authorization",
                    field,
                    "shipyard_permit",
                    0,
                    field,
                    0,
                );
            }
        }
        if name.starts_with("AuthorizeLargeShip") {
            let field = if name.ends_with("Industrial") {
                "industrial_authorized"
            } else if name.ends_with("Electronics") {
                "electronics_authorized"
            } else {
                "molecular_authorized"
            };
            add_negative_case(
                &mut cases,
                name,
                "already_authorized",
                field,
                "shipyard_permit",
                0,
                field,
                1,
            );
        }

        if name.starts_with("RevealWarpCoordinate") {
            add_negative_case(
                &mut cases,
                name,
                "already_revealed_coordinate",
                "revealed_is_one",
                "warp_coordinate",
                0,
                "revealed",
                1,
            );
            add_negative_case(
                &mut cases,
                name,
                "invalid_coordinate_source",
                "negative_source_pool",
                "warp_coordinate",
                0,
                "source_pool_before",
                -1,
            );
        } else if name.starts_with("RevealTimeCoordinate") {
            add_negative_case(
                &mut cases,
                name,
                "already_revealed_coordinate",
                "revealed_is_one",
                "time_coordinate",
                0,
                "revealed",
                1,
            );
            add_negative_case(
                &mut cases,
                name,
                "invalid_coordinate_source",
                "negative_source_pool",
                "time_coordinate",
                0,
                "source_pool_before",
                -1,
            );
        }

        let coordinate_suffix = if name.starts_with("WarpToCoordinate") {
            Some("warp_coordinate")
        } else if name.starts_with("TimeWarpToCoordinate") {
            Some("time_coordinate")
        } else {
            None
        };
        if let Some(coordinate_suffix) = coordinate_suffix {
            add_negative_case(
                &mut cases,
                name,
                "unrevealed_coordinate",
                "revealed_is_zero",
                coordinate_suffix,
                0,
                "revealed",
                0,
            );
            add_negative_case(
                &mut cases,
                name,
                "spent_coordinate",
                "uses_remaining_is_zero",
                coordinate_suffix,
                0,
                "uses_remaining",
                0,
            );
            let (field, value) = if coordinate_suffix == "warp_coordinate" {
                ("destination_x", 2_000_000_000_000_i64)
            } else {
                ("destination_epoch", 1_000_000_000_000_i64)
            };
            add_negative_case(
                &mut cases,
                name,
                "coordinate_out_of_bounds",
                field,
                coordinate_suffix,
                0,
                field,
                value,
            );
            add_negative_case(
                &mut cases,
                name,
                "wrong_coordinate_use_count",
                "reusable_and_final_use_partition",
                coordinate_suffix,
                0,
                "uses_remaining",
                if name.ends_with("Reusable") { 1 } else { 2 },
            );
        }

        if name == "UseTechnologySkill" {
            add_negative_case(
                &mut cases,
                name,
                "non_reusable_skill",
                "reusable_is_zero",
                "technology_skill",
                0,
                "reusable",
                0,
            );
        }
    }
    cases
}

fn apply_synthetic_negative_case(
    case: &SyntheticNegativeCase,
    input_classes: &[String],
    objects: &mut [Dictionary],
) -> Result<()> {
    let index = input_classes
        .iter()
        .enumerate()
        .filter(|(_, class)| class_matches(class, case.class_suffix))
        .nth(case.occurrence)
        .map(|(index, _)| index)
        .with_context(|| {
            format!(
                "{} lacks {} input occurrence {} for negative case {}",
                case.action, case.class_suffix, case.occurrence, case.label
            )
        })?;
    update_fixture_field(&mut objects[index], case.field, PodValue::from(case.value))?;
    restamp_fixture(&mut objects[index])
}

fn restore_reveal_qualification_after_mutation(
    action_name: &str,
    reveal_lower_limb: Option<u64>,
    input_classes: &[String],
    objects: &mut [Dictionary],
) -> Result<()> {
    let suffix = if action_name.starts_with("RevealWarpCoordinate") {
        Some("warp_coordinate")
    } else if action_name.starts_with("RevealTimeCoordinate") {
        Some("time_coordinate")
    } else {
        None
    };
    let Some(suffix) = suffix else {
        return Ok(());
    };
    let lower_limb = reveal_lower_limb
        .with_context(|| format!("missing reveal lower-limb literal for {action_name}"))?;
    let index = input_classes
        .iter()
        .position(|class| class_matches(class, suffix))
        .with_context(|| format!("{action_name} lacks its coordinate input"))?;
    update_fixture_field(
        &mut objects[index],
        "stable_identifier",
        PodValue::from(Hash::from(target_raw_value(lower_limb))),
    )
}

fn synthetic_negative_suite(plugin_root: &Path, output: Option<PathBuf>) -> Result<()> {
    let (source, module) = load_module(plugin_root)?;
    let cases = synthetic_negative_cases(&source, module.as_ref());
    let started = Instant::now();
    let mut passed = 0_usize;
    let mut failed = 0_usize;
    let mut category_totals = BTreeMap::<String, usize>::new();
    let mut category_passed = BTreeMap::<String, usize>::new();
    let mut details = Vec::with_capacity(cases.len());
    let previous_panic_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(|_| {}));

    for (index, case) in cases.iter().enumerate() {
        println!(
            "offline negative suite {}/{}: {} [{}:{}]",
            index + 1,
            cases.len(),
            case.action,
            case.category,
            case.label
        );
        *category_totals
            .entry(case.category.to_string())
            .or_default() += 1;
        let setup_and_execute = catch_unwind(AssertUnwindSafe(|| -> Result<bool> {
            let action = module
                .actions()
                .iter()
                .find(|action| action.name == case.action)
                .with_context(|| format!("unknown action {}", case.action))?;
            let input_classes = action
                .total_inputs()
                .map(|object| object.class.clone())
                .collect::<Vec<_>>();
            let mut minted = pexe::fixtures::mint_classes(&module, &input_classes)?;
            let ship_capacity = action_int_literal_constraint(
                &source.script,
                &case.action,
                "ship.extraction_amount",
            )
            .or_else(|| action_core_ship_capacity(&source.script, &case.action))
            .unwrap_or(10);
            let source_skill_type = action_int_literal_constraint(
                &source.script,
                &case.action,
                "ship.active_skill_type",
            )
            .or_else(|| action_core_ship_skill(&source.script, &case.action));
            let source_parent_type =
                action_int_literal_constraint(&source.script, &case.action, "parent.resource_type");
            let source_body_type =
                action_int_literal_constraint(&source.script, &case.action, "body.body_type");
            let reveal_lower_limb = reveal_coordinate_lower_limb(&source.script, &case.action);
            configure_synthetic_inputs(
                &case.action,
                ship_capacity,
                source_skill_type,
                source_parent_type,
                source_body_type,
                reveal_lower_limb,
                &input_classes,
                &mut minted,
            )?;
            apply_synthetic_negative_case(case, &input_classes, &mut minted)?;
            restore_reveal_qualification_after_mutation(
                &case.action,
                reveal_lower_limb,
                &input_classes,
                &mut minted,
            )?;
            let state = pexe::fixtures::build_synthetic_state(&minted)?;
            Ok(module
                .executor(true, state.grounding_witness)
                .action(&case.action, state.spendable)
                .is_err())
        }));
        let (status, rejection) = match setup_and_execute {
            Err(payload) => ("pass", format!("panic: {}", panic_message(payload))),
            Ok(Ok(true)) => ("pass", "executor returned rejection".to_string()),
            Ok(Ok(false)) => (
                "fail",
                "invalid input was accepted by the action".to_string(),
            ),
            Ok(Err(error)) => (
                "fail",
                format!("negative test setup failed before execution: {error:#}"),
            ),
        };
        if status == "pass" {
            passed += 1;
            *category_passed
                .entry(case.category.to_string())
                .or_default() += 1;
        } else {
            failed += 1;
        }
        details.push(json!({
            "status": status,
            "action": case.action,
            "category": case.category,
            "label": case.label,
            "mutated_class": case.class_suffix,
            "mutated_occurrence": case.occurrence,
            "mutated_field": case.field,
            "mutated_value": case.value,
            "result": rejection,
        }));
    }
    std::panic::set_hook(previous_panic_hook);

    let category_summary = category_totals
        .iter()
        .map(|(category, total)| {
            let category_passed = category_passed.get(category).copied().unwrap_or(0);
            (
                category.clone(),
                json!({
                    "status": if category_passed == *total { "pass" } else { "fail" },
                    "passed": category_passed,
                    "failed": total - category_passed,
                    "total": total,
                }),
            )
        })
        .collect::<BTreeMap<_, _>>();
    let report = json!({
        "status": if failed == 0 { "pass" } else { "fail" },
        "mode": "offline-synthetic-expected-rejection",
        "external_network_used": false,
        "external_state_committed": false,
        "published_commitments": 0,
        "published_nullifiers": 0,
        "elapsed_seconds": started.elapsed().as_secs_f64(),
        "case_count": cases.len(),
        "passed": passed,
        "failed": failed,
        "categories": category_summary,
        "cases": details,
    });
    let encoded = serde_json::to_string_pretty(&report)? + "\n";
    if let Some(path) = output {
        fs::write(&path, &encoded).with_context(|| format!("writing {}", path.display()))?;
    }
    println!("{encoded}");
    if failed > 0 {
        bail!("{failed} offline negative cases failed");
    }
    Ok(())
}

fn synthetic_proof(
    plugin_root: &Path,
    action_name: &str,
    ship_capacity: i64,
    real: bool,
    output: Option<PathBuf>,
) -> Result<()> {
    let (source, module) = load_module(plugin_root)?;
    let action = module
        .actions()
        .iter()
        .find(|action| action.name == action_name)
        .ok_or_else(|| anyhow!("unknown action {action_name}"))?;
    let input_classes = action
        .total_inputs()
        .map(|object| object.class.clone())
        .collect::<Vec<_>>();
    let output_classes = action
        .total_outputs()
        .map(|object| object.class.clone())
        .collect::<Vec<_>>();
    let mut minted = pexe::fixtures::mint_classes(&module, &input_classes)?;
    let source_skill_type =
        action_int_literal_constraint(&source.script, action_name, "ship.active_skill_type")
            .or_else(|| action_core_ship_skill(&source.script, action_name));
    let source_parent_type =
        action_int_literal_constraint(&source.script, action_name, "parent.resource_type");
    let source_body_type =
        action_int_literal_constraint(&source.script, action_name, "body.body_type");
    let reveal_lower_limb = reveal_coordinate_lower_limb(&source.script, action_name);
    configure_synthetic_inputs(
        action_name,
        ship_capacity,
        source_skill_type,
        source_parent_type,
        source_body_type,
        reveal_lower_limb,
        &input_classes,
        &mut minted,
    )?;
    let state = pexe::fixtures::build_synthetic_state(&minted)?;
    let state_root = state.grounding_witness.state_header.hash();
    let started = Instant::now();
    let plan = module
        .executor(true, state.grounding_witness.clone())
        .plan_action(action_name, state.spendable.clone())
        .with_context(|| format!("planning synthetic proof action {action_name}"))?;
    let planning_seconds = started.elapsed().as_secs_f64();
    let execution_started = Instant::now();
    let outputs = module
        .executor(!real, state.grounding_witness)
        .action(action_name, state.spendable)
        .with_context(|| format!("proving synthetic action {action_name}"))?;
    let execution_seconds = execution_started.elapsed().as_secs_f64();
    let payload = structural_payload(&outputs, state_root, real)?;
    let report = json!({
        "status": if payload.fits_hard_limit { "pass" } else { "fail" },
        "action": action_name,
        "mode": if real { "synthetic-input-real" } else { "synthetic-input-mock" },
        "input_source": "class-shaped synthetic fixtures with exact recipe, tier, and authorization fields",
        "ship_extraction_amount": ship_capacity,
        "input_classes": input_classes,
        "output_classes": output_classes,
        "planning_seconds": planning_seconds,
        "execution_seconds": execution_seconds,
        "payload_generation_seconds": payload.seconds,
        "statements": plan.statements.len(),
        "operations": plan.operations.len(),
        "payload_bytes": payload.payload_bytes,
        "serialized_proof_bytes": payload.serialized_proof_bytes,
        "payload_hard_limit_bytes": PAYLOAD_HARD_LIMIT_BYTES,
        "payload_headroom_bytes": payload.headroom_bytes,
        "payload_utilization_percent": payload.utilization_percent,
        "payload_fits_hard_limit": payload.fits_hard_limit,
        "live_commitments": payload.live_count,
        "nullifiers": payload.nullifier_count,
        "outputs": class_object_reports(&output_classes, &outputs.objs)?,
    });
    let encoded = serde_json::to_string_pretty(&report)? + "\n";
    if let Some(path) = output {
        fs::write(&path, &encoded).with_context(|| format!("writing {}", path.display()))?;
    }
    println!("{encoded}");
    if !payload.fits_hard_limit {
        bail!("synthetic proof payload exceeds hard limit");
    }
    Ok(())
}

fn synthetic_suite(plugin_root: &Path, output: Option<PathBuf>) -> Result<()> {
    let (source, module) = load_module(plugin_root)?;
    let action_names = module
        .actions()
        .iter()
        .map(|action| action.name.clone())
        .collect::<Vec<_>>();
    let started = Instant::now();
    let mut passed = 0_usize;
    let mut failed = 0_usize;
    let mut producer_route_required = 0_usize;
    let mut max_statements = 0_usize;
    let mut max_operations = 0_usize;
    let mut max_payload_bytes = 0_usize;
    let mut details = Vec::with_capacity(action_names.len());
    let previous_panic_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(|_| {}));

    for (index, action_name) in action_names.iter().enumerate() {
        println!(
            "offline synthetic suite {}/{}: {}",
            index + 1,
            action_names.len(),
            action_name
        );
        if action_name.starts_with("SurveySector_")
            || action_name.starts_with("DetectCelestialSignal_")
            || action_name.starts_with("ScanCelestialBody_")
            || action_name.starts_with("MaterializeCivilizationType")
        {
            producer_route_required += 1;
            details.push(json!({
                "status": "producer-route-required",
                "action": action_name,
                "reason": "stable-identifier qualification must be derived from its canonical producer route",
            }));
            continue;
        }
        let result =
            std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| -> Result<JsonValue> {
                let action = module
                    .actions()
                    .iter()
                    .find(|action| action.name == *action_name)
                    .ok_or_else(|| anyhow!("unknown action {action_name}"))?;
                let input_classes = action
                    .total_inputs()
                    .map(|object| object.class.clone())
                    .collect::<Vec<_>>();
                let output_classes = action
                    .total_outputs()
                    .map(|object| object.class.clone())
                    .collect::<Vec<_>>();
                let mut minted = pexe::fixtures::mint_classes(&module, &input_classes)?;
                let ship_capacity = action_int_literal_constraint(
                    &source.script,
                    action_name,
                    "ship.extraction_amount",
                )
                .or_else(|| action_core_ship_capacity(&source.script, action_name))
                .unwrap_or(10);
                let source_skill_type = action_int_literal_constraint(
                    &source.script,
                    action_name,
                    "ship.active_skill_type",
                )
                .or_else(|| action_core_ship_skill(&source.script, action_name));
                let source_parent_type = action_int_literal_constraint(
                    &source.script,
                    action_name,
                    "parent.resource_type",
                );
                let source_body_type =
                    action_int_literal_constraint(&source.script, action_name, "body.body_type");
                let reveal_lower_limb = reveal_coordinate_lower_limb(&source.script, action_name);
                configure_synthetic_inputs(
                    action_name,
                    ship_capacity,
                    source_skill_type,
                    source_parent_type,
                    source_body_type,
                    reveal_lower_limb,
                    &input_classes,
                    &mut minted,
                )?;
                let state = pexe::fixtures::build_synthetic_state(&minted)?;
                let state_root = state.grounding_witness.state_header.hash();

                let planning_started = Instant::now();
                let plan = module
                    .executor(true, state.grounding_witness.clone())
                    .plan_action(action_name, state.spendable.clone())
                    .with_context(|| format!("planning synthetic suite action {action_name}"))?;
                let planning_seconds = planning_started.elapsed().as_secs_f64();

                let execution_started = Instant::now();
                let outputs = module
                    .executor(true, state.grounding_witness)
                    .action(action_name, state.spendable)
                    .with_context(|| format!("executing synthetic suite action {action_name}"))?;
                let execution_seconds = execution_started.elapsed().as_secs_f64();
                if outputs.objs.len() != output_classes.len() {
                    bail!(
                        "output metadata mismatch: expected {}, received {}",
                        output_classes.len(),
                        outputs.objs.len()
                    );
                }
                let payload = structural_payload(&outputs, state_root, false)?;
                if !payload.fits_hard_limit {
                    bail!(
                        "mock structural payload {} exceeds {}",
                        payload.payload_bytes,
                        PAYLOAD_HARD_LIMIT_BYTES
                    );
                }

                max_statements = max_statements.max(plan.statements.len());
                max_operations = max_operations.max(plan.operations.len());
                max_payload_bytes = max_payload_bytes.max(payload.payload_bytes);
                Ok(json!({
                    "status": "pass",
                    "action": action_name,
                    "ship_extraction_amount": ship_capacity,
                    "input_classes": input_classes,
                    "output_classes": output_classes,
                    "planning_seconds": planning_seconds,
                    "execution_seconds": execution_seconds,
                    "statements": plan.statements.len(),
                    "operations": plan.operations.len(),
                    "payload_bytes": payload.payload_bytes,
                    "live_commitments": payload.live_count,
                    "nullifiers": payload.nullifier_count,
                }))
            }));

        match result {
            Ok(Ok(detail)) => {
                passed += 1;
                details.push(detail);
            }
            Ok(Err(error)) => {
                failed += 1;
                details.push(json!({
                    "status": "fail",
                    "action": action_name,
                    "error": format!("{error:#}"),
                }));
            }
            Err(panic) => {
                failed += 1;
                let message = if let Some(message) = panic.downcast_ref::<String>() {
                    message.clone()
                } else if let Some(message) = panic.downcast_ref::<&str>() {
                    (*message).to_string()
                } else {
                    "non-string panic payload".to_string()
                };
                details.push(json!({
                    "status": "fail",
                    "action": action_name,
                    "error": format!("panic: {message}"),
                }));
            }
        }
    }
    std::panic::set_hook(previous_panic_hook);

    let status = if failed == 0 { "pass" } else { "fail" };
    let report = json!({
        "status": status,
        "mode": "offline-synthetic-mock",
        "external_network_used": false,
        "external_state_committed": false,
        "published_commitments": 0,
        "published_nullifiers": 0,
        "action_count": action_names.len(),
        "passed": passed,
        "failed": failed,
        "producer_route_required": producer_route_required,
        "elapsed_seconds": started.elapsed().as_secs_f64(),
        "max_statements": max_statements,
        "max_operations": max_operations,
        "max_mock_payload_bytes": max_payload_bytes,
        "actions": details,
    });
    let encoded = serde_json::to_string_pretty(&report)? + "\n";
    if let Some(path) = output {
        fs::write(&path, &encoded).with_context(|| format!("writing {}", path.display()))?;
    }
    println!(
        "{}",
        serde_json::to_string_pretty(&json!({
            "status": status,
            "mode": "offline-synthetic-mock",
            "external_state_committed": false,
            "action_count": action_names.len(),
            "passed": passed,
            "failed": failed,
            "producer_route_required": producer_route_required,
            "elapsed_seconds": started.elapsed().as_secs_f64(),
            "max_statements": max_statements,
            "max_operations": max_operations,
            "max_mock_payload_bytes": max_payload_bytes,
        }))?
    );
    if failed != 0 {
        bail!("{failed} offline synthetic actions failed");
    }
    Ok(())
}

fn state_header(state: &TestState) -> StateHeader {
    let (created_root, nullifiers_root, prior_state_history_root) = state.roots();
    StateHeader::new(
        state.block_number,
        created_root,
        nullifiers_root,
        prior_state_history_root,
    )
}

fn grounding_witness(state: &TestState, inputs: &[SpendableObject]) -> Arc<GroundingWitness> {
    let commitments: Vec<Hash> = inputs.iter().map(|input| input.obj.commitment()).collect();
    state.build_grounding_witness(
        &commitments,
        |block_number, created_root, nullifiers_root, prior_state_history_root, created_proofs| {
            Arc::new(GroundingWitness::new(
                StateHeader::new(
                    block_number,
                    created_root,
                    nullifiers_root,
                    prior_state_history_root,
                ),
                created_proofs,
            ))
        },
    )
}

fn refinement_parent_resource_type(action_name: &str) -> Option<i64> {
    [
        ("RefineFerrousOreTo", 122),
        ("RefineBaseMetalOreTo", 123),
        ("RefineSilicateMineralTo", 124),
        ("RefineLightMetalOreTo", 136),
        ("RefinePreciousMetalOreTo", 137),
        ("RefineCarbonaceousDepositTo", 139),
        ("RefineStructuralSalvageTo", 148),
        ("RefineFusionFuelTo", 6),
        ("RefineHeavyElementTo", 9),
        ("RefineOreTo", 11),
        ("RefineSilicateTo", 12),
        ("RefineCrystalTo", 13),
        ("RefineGasTo", 14),
        ("RefineIceTo", 15),
        ("RefineIsotopeTo", 16),
        ("RefineBiomassTo", 17),
        ("RefineGeneticMaterialTo", 18),
        ("RefineBiochemicalCompoundTo", 19),
        ("RefineMicrobialCultureTo", 20),
        ("RefineOrganismSampleTo", 21),
        ("RefineLivingMaterialTo", 22),
        ("RefineNobleGasTo", 25),
        ("RefineVolatileCompoundTo", 26),
        ("RefineOrganicMoleculeTo", 27),
        ("RefineMetalRichEjectaTo", 29),
        ("RefineRadioactiveIsotopeTo", 30),
        ("RefineSupernovaDustTo", 31),
        ("RefineStructuralSegmentTo", 41),
        ("RefinePowerCoreTo", 42),
        ("RefineComputationCoreTo", 43),
        ("RefineFabricationModuleTo", 44),
        ("RefineTransitModuleTo", 45),
        ("RefineDataArchiveTo", 46),
    ]
    .into_iter()
    .find_map(|(prefix, resource_type)| action_name.starts_with(prefix).then_some(resource_type))
}

fn refinement_child_pool_field(action_name: &str) -> Option<&'static str> {
    [
        ("RefineFerrousOreToIron", "child_1_remaining"),
        ("RefineBaseMetalOreToCopper", "child_1_remaining"),
        ("RefineSilicateMineralToSilicon", "child_1_remaining"),
        ("RefineLightMetalOreToAluminum", "child_1_remaining"),
        ("RefineLightMetalOreToTitanium", "child_2_remaining"),
        ("RefinePreciousMetalOreToGold", "child_2_remaining"),
        ("RefineCarbonaceousDepositToCarbon", "child_1_remaining"),
        ("RefineStructuralSalvageToSteel", "child_1_remaining"),
        (
            "RefineStructuralSalvageToCarbonComposite",
            "child_3_remaining",
        ),
    ]
    .into_iter()
    .find_map(|(name, field)| (action_name == name).then_some(field))
}

fn desired_body_code(action_name: &str) -> Option<i64> {
    [
        ("ExtractRedDwarf", 0),
        ("ExtractMainSequenceStar", 1),
        ("ExtractGiantStar", 2),
        ("ExtractRockyPlanet", 3),
        ("ExtractOceanPlanet", 4),
        ("ExtractGardenPlanet", 5),
        ("ExtractGasGiant", 6),
        ("ExtractIceGiant", 7),
        ("ExtractBarrenPlanet", 8),
        ("ExtractNeutronStar", 9),
        ("ExtractBlackHole", 10),
        ("ExtractAnomaly", 11),
        ("ExtractMegastructure", 12),
        ("ExtractGasCluster", 13),
        ("ExtractStellarRemnant", 14),
    ]
    .into_iter()
    .find_map(|(prefix, code)| action_name.starts_with(prefix).then_some(code))
}

fn desired_skill_type(action_name: &str) -> Option<i64> {
    [
        ("AuthorizeLargeShipIndustrial", 1),
        ("AuthorizeLargeShipElectronics", 2),
        ("AuthorizeLargeShipMolecular", 10),
        ("ExtractRedDwarfFusionGas", 8),
        ("ExtractBlackHoleHighEnergyRadiation", 8),
        ("ExtractMegastructureStructuralSalvage", 6),
        ("RefineFerrousOreTo", 1),
        ("RefineBaseMetalOreTo", 1),
        ("RefineSilicateMineralTo", 3),
        ("RefineLightMetalOreTo", 1),
        ("RefinePreciousMetalOreTo", 1),
        ("RefineCarbonaceousDepositTo", 3),
        ("RefineStructuralSalvageTo", 1),
    ]
    .into_iter()
    .find_map(|(prefix, code)| action_name.starts_with(prefix).then_some(code))
}

fn desired_civilization_type(action_name: &str) -> Option<i64> {
    technology_skill_spec(action_name).map(|skill| skill.civilization_type)
}

fn resource_requirements(action_name: &str) -> &'static [(i64, i64)] {
    const MEDIUM: &[(i64, i64)] = &[
        (1, 10),
        (2, 10),
        (4, 10),
        (156, 6),
        (196, 6),
        (161, 6),
        (164, 6),
        (205, 6),
    ];
    const LARGE: &[(i64, i64)] = &[
        (1, 50),
        (2, 50),
        (4, 50),
        (211, 30),
        (196, 30),
        (197, 15),
        (161, 30),
        (164, 30),
        (200, 15),
        (212, 5),
    ];
    const AUX_SMALL: &[(i64, i64)] = &[(1, 10), (156, 6), (196, 6), (161, 6), (164, 6)];
    match action_name {
        "BuildShipMedium" | "BuildAuxiliaryShipMedium" => MEDIUM,
        "BuildShipLarge" => LARGE,
        "BuildAuxiliaryShipSmall" => AUX_SMALL,
        _ => &[],
    }
}

fn permit_requirements(action_name: &str) -> &'static [i64] {
    match action_name {
        "BuildShipLarge"
        | "AuthorizeLargeShipIndustrial"
        | "AuthorizeLargeShipElectronics"
        | "AuthorizeLargeShipMolecular" => &[1],
        "BuildAuxiliaryShipSmall" => &[2],
        "BuildAuxiliaryShipMedium" => &[2],
        _ => &[],
    }
}

fn desired_ship_extraction_amount(action_name: &str) -> Option<i64> {
    if action_name.ends_with("Large")
        || action_name == "TimeWarpLarge"
        || action_name == "IssueAuxiliaryShipPermit"
        || action_name.starts_with("BuildAuxiliaryShip")
    {
        Some(250)
    } else if action_name.ends_with("Medium") || action_name == "TimeWarpMedium" {
        Some(50)
    } else if matches!(
        action_name,
        "MovePositiveX"
            | "MoveNegativeX"
            | "MovePositiveY"
            | "MoveNegativeY"
            | "MovePositiveZ"
            | "MoveNegativeZ"
            | "TimeWarpSmall"
    ) {
        Some(10)
    } else {
        None
    }
}

fn select_inputs_for_action(
    inventory: &[LiveObject],
    classes: &[String],
    action_name: &str,
) -> Result<(Vec<SpendableObject>, Vec<usize>)> {
    let desired_body_code = desired_body_code(action_name)
        .or_else(|| specialized_resource_spec(action_name).map(|resource| resource.candidate_code));
    let desired_parent_type = refinement_parent_resource_type(action_name);
    let desired_parent_pool_field = refinement_child_pool_field(action_name);
    let resource_requirements = resource_requirements(action_name);
    let permit_requirements = permit_requirements(action_name);
    let desired_skill_type = desired_skill_type(action_name);
    let desired_civilization_type = desired_civilization_type(action_name);
    let desired_ship_extraction_amount = desired_ship_extraction_amount(action_name);
    let mut resource_index = 0_usize;
    let mut permit_index = 0_usize;
    let mut selected_indices = Vec::new();
    for class in classes {
        let matching = inventory
            .iter()
            .enumerate()
            .filter(|(index, item)| item.class == *class && !selected_indices.contains(index));
        let preferred = if class_matches(class, "celestial_body") {
            let preferred_ship = inventory
                .iter()
                .filter(|item| class_matches(&item.class, "spaceship"))
                .max_by_key(|item| object_int(&item.object, "extraction_amount").unwrap_or(0));
            matching
                .filter(|(_, item)| {
                    let candidate_matches = if let Some(candidate_code) = desired_body_code {
                        fixed_int_is(&item.object, "candidate_code", candidate_code)
                    } else if action_name == "DetectIntelligentLife" {
                        object_int(&item.object, "life_stat").is_ok_and(|life_stat| life_stat > 0)
                            && fixed_int_is(&item.object, "civilization_discovered", 0)
                    } else {
                        true
                    };
                    let location_matches = preferred_ship.is_none_or(|ship| {
                        [
                            ("sector_x", "x"),
                            ("sector_y", "y"),
                            ("sector_z", "z"),
                            ("sector_epoch", "epoch"),
                        ]
                        .into_iter()
                        .all(|(body_field, ship_field)| {
                            cross_field_equal(&item.object, body_field, &ship.object, ship_field)
                        })
                    });
                    candidate_matches && location_matches
                })
                .map(|(index, _)| index)
                .next()
        } else if class_matches(class, "spaceship") {
            matching
                .filter(|(_, item)| {
                    desired_ship_extraction_amount.is_none_or(|amount| {
                        fixed_int_is(&item.object, "extraction_amount", amount)
                    })
                })
                .max_by_key(|(_, item)| object_int(&item.object, "extraction_amount").unwrap_or(0))
                .map(|(index, _)| index)
        } else if class_matches(class, "civilization") {
            matching
                .filter(|(_, item)| {
                    desired_civilization_type.is_none_or(|civilization_type| {
                        fixed_int_is(&item.object, "civilization_type", civilization_type)
                    })
                })
                .map(|(index, _)| index)
                .next()
        } else if class_matches(class, "technology_skill") {
            matching
                .filter(|(_, item)| {
                    desired_skill_type.is_none_or(|skill_type| {
                        fixed_int_is(&item.object, "skill_type", skill_type)
                    })
                })
                .map(|(index, _)| index)
                .next()
        } else if class_matches(class, "shipyard_permit") {
            let requirement = permit_requirements.get(permit_index).copied();
            permit_index += 1;
            matching
                .filter(|(_, item)| {
                    requirement.is_none_or(|permit_type| {
                        fixed_int_is(&item.object, "permit_type", permit_type)
                    })
                })
                .map(|(index, _)| index)
                .next()
        } else if class_matches(class, "resource") {
            let requirement = resource_requirements.get(resource_index).copied();
            resource_index += 1;
            matching
                .filter(|(_, item)| {
                    requirement.is_none_or(|(resource_type, amount)| {
                        fixed_int_is(&item.object, "resource_type", resource_type)
                            && fixed_int_is(&item.object, "amount", amount)
                    })
                })
                .map(|(index, _)| index)
                .next()
        } else if class_matches(class, "sector") {
            let ship = selected_indices
                .iter()
                .map(|index| &inventory[*index])
                .find(|item| class_matches(&item.class, "spaceship"))
                .or_else(|| {
                    inventory
                        .iter()
                        .find(|item| class_matches(&item.class, "spaceship"))
                });
            matching
                .filter(|(_, item)| {
                    ship.is_some_and(|ship| {
                        ["x", "y", "z", "epoch"].into_iter().all(|field| {
                            cross_field_equal(&ship.object, field, &item.object, field)
                        })
                    })
                })
                .map(|(index, _)| index)
                .next()
        } else if class_matches(class, "composite_resource") {
            matching
                .filter(|(_, item)| {
                    desired_parent_type.is_none_or(|resource_type| {
                        fixed_int_is(&item.object, "resource_type", resource_type)
                    }) && desired_parent_pool_field.is_none_or(|field| {
                        object_int(&item.object, field).is_ok_and(|amount| amount > 0)
                    })
                })
                .map(|(index, _)| index)
                .next()
        } else {
            matching.map(|(index, _)| index).next()
        };
        let index = preferred.ok_or_else(|| {
            anyhow!("missing live input class {class} satisfying action {action_name}")
        })?;
        selected_indices.push(index);
    }
    let inputs = selected_indices
        .iter()
        .map(|index| inventory[*index].object.clone())
        .collect();
    Ok((inputs, selected_indices))
}

fn structural_payload(
    outputs: &sdk::SpendableObjects,
    state_root: Hash,
    real: bool,
) -> Result<PayloadMetrics> {
    let started = Instant::now();
    let proof = if real {
        let params = Params::default();
        let shrunk_main_pod = ShrunkMainPodSetup::new(&params)
            .build()
            .context("building shrunk MainPod wrapper circuit")?;
        let compressed = shrink_compress_pod(&shrunk_main_pod, outputs.tx_pod.clone())
            .context("shrinking and compressing the transaction proof")?;
        PayloadProof::Plonky2(Box::new(compressed))
    } else {
        PayloadProof::empty_for_test()
    };
    let mut serialized_proof = Vec::new();
    proof.write_bytes(&mut serialized_proof);
    let payload = Payload {
        proof,
        tx_final: outputs.tx.dict().commitment(),
        state_root,
        nullifiers: outputs.tx.nullifier_hashes()?,
        live: outputs.tx.live_commitments()?,
    };
    let payload_bytes = payload.to_bytes().len();
    let utilization = payload_bytes as f64 / PAYLOAD_HARD_LIMIT_BYTES as f64;
    Ok(PayloadMetrics {
        payload_bytes,
        serialized_proof_bytes: serialized_proof.len(),
        live_count: payload.live.len(),
        nullifier_count: payload.nullifiers.len(),
        seconds: started.elapsed().as_secs_f64(),
        headroom_bytes: PAYLOAD_HARD_LIMIT_BYTES as i64 - payload_bytes as i64,
        utilization,
        utilization_percent: utilization * 100.0,
        fits_hard_limit: payload_bytes <= PAYLOAD_HARD_LIMIT_BYTES,
    })
}

fn execute_audit_step(
    module: &std::rc::Rc<sdk::SdkModule>,
    state: &TestState,
    inventory: &[LiveObject],
    action_name: &str,
    step_real: bool,
) -> Result<AuditStep> {
    let metadata = module
        .actions()
        .iter()
        .find(|action| action.name == action_name)
        .ok_or_else(|| anyhow!("unknown action {action_name}"))?;
    let input_classes = metadata
        .total_inputs()
        .map(|object| object.class.clone())
        .collect::<Vec<_>>();
    let output_classes = metadata
        .total_outputs()
        .map(|object| object.class.clone())
        .collect::<Vec<_>>();
    let (inputs, selected_indices) =
        select_inputs_for_action(inventory, &input_classes, action_name)?;
    let witness = grounding_witness(state, &inputs);
    let state_root = witness.state_header.hash();

    let planning_started = Instant::now();
    let plan = module
        .executor(true, witness.clone())
        .plan_action(action_name, inputs.clone())
        .with_context(|| format!("planning Claim audit action {action_name}"))?;
    let planning_seconds = planning_started.elapsed().as_secs_f64();
    let solution = plan.solved.solution();

    let execution_started = Instant::now();
    let outputs = module
        .executor(!step_real, witness)
        .action(action_name, inputs.clone())
        .with_context(|| format!("executing Claim audit action {action_name}"))?;
    let execution_seconds = execution_started.elapsed().as_secs_f64();
    if outputs.objs.len() != output_classes.len() {
        bail!("output metadata mismatch for {action_name}");
    }

    let payload = structural_payload(&outputs, state_root, step_real)?;
    let live_commitments = outputs.tx.live_commitments()?;
    let nullifiers = outputs.tx.nullifier_hashes()?;
    Ok(AuditStep {
        inputs,
        selected_indices,
        input_classes,
        output_classes,
        outputs,
        payload,
        live_commitments,
        nullifiers,
        planning_seconds,
        execution_seconds,
        statements: plan.statements.len(),
        operations: plan.operations.len(),
        pods: solution.pod_statements.len(),
        state_root,
    })
}

fn audit_step_report(
    step_number: usize,
    action_name: &str,
    step_real: bool,
    state_block_after: i64,
    step: &AuditStep,
) -> JsonValue {
    json!({
        "step": step_number,
        "action": action_name,
        "proof_mode": if step_real { "real" } else { "mock" },
        "input_classes": step.input_classes,
        "output_classes": step.output_classes,
        "planning_seconds": step.planning_seconds,
        "execution_seconds": step.execution_seconds,
        "payload_generation_seconds": step.payload.seconds,
        "statements": step.statements,
        "operations": step.operations,
        "pods": step.pods,
        "serialized_proof_bytes": step.payload.serialized_proof_bytes,
        "payload_bytes": step.payload.payload_bytes,
        "payload_hard_limit_bytes": PAYLOAD_HARD_LIMIT_BYTES,
        "payload_headroom_bytes": step.payload.headroom_bytes,
        "payload_utilization": step.payload.utilization,
        "payload_utilization_percent": step.payload.utilization_percent,
        "payload_fits_hard_limit": step.payload.fits_hard_limit,
        "live_commitments": step.payload.live_count,
        "nullifiers": step.payload.nullifier_count,
        "state_root_before": hash_string(step.state_root),
        "state_block_after": state_block_after,
    })
}

fn seen_hashes(values: &[Hash], seen: &HashSet<Hash>) -> Vec<Hash> {
    values
        .iter()
        .filter(|value| seen.contains(value))
        .copied()
        .collect()
}

fn created_collisions(step: &AuditStep, globally_created: &HashSet<Hash>) -> Vec<Hash> {
    seen_hashes(&step.live_commitments, globally_created)
}

fn nullifier_collisions(step: &AuditStep, globally_nullified: &HashSet<Hash>) -> Vec<Hash> {
    seen_hashes(&step.nullifiers, globally_nullified)
}

fn descending_unique_indices(indices: &[usize]) -> Vec<usize> {
    let mut ordered = indices.to_vec();
    ordered.sort_unstable();
    ordered.dedup();
    ordered.reverse();
    ordered
}

fn apply_audit_step(
    state: &mut TestState,
    inventory: &mut Vec<LiveObject>,
    globally_created: &mut HashSet<Hash>,
    globally_nullified: &mut HashSet<Hash>,
    step: &AuditStep,
) -> Result<()> {
    let reused_nullifiers = nullifier_collisions(step, globally_nullified);
    if !reused_nullifiers.is_empty() {
        bail!(
            "local synchronizer-style nullifier reuse: {:?}",
            reused_nullifiers
                .iter()
                .map(|hash| hash_string(*hash))
                .collect::<Vec<_>>()
        );
    }
    let collisions = created_collisions(step, globally_created);
    if !collisions.is_empty() {
        bail!(
            "local synchronizer-style creation collision: {:?}",
            collisions
                .iter()
                .map(|hash| hash_string(*hash))
                .collect::<Vec<_>>()
        );
    }
    globally_created.extend(step.live_commitments.iter().copied());
    globally_nullified.extend(step.nullifiers.iter().copied());
    state.apply_tx(
        step.live_commitments.iter().copied(),
        step.nullifiers.iter().copied(),
    );

    for index in descending_unique_indices(&step.selected_indices) {
        inventory.remove(index);
    }
    for (class, object) in step.output_classes.iter().zip(step.outputs.objs.iter()) {
        inventory.push(LiveObject {
            class: class.clone(),
            object: object.clone(),
        });
    }
    Ok(())
}

#[derive(Clone)]
struct ClaimFacts {
    sector: SpendableObject,
    sector_initial_commitment: Hash,
}

fn same_field(left: &SpendableObject, right: &SpendableObject, field: &str) -> bool {
    object_field(left, field)
        .and_then(|left_value| {
            object_field(right, field).map(|right_value| left_value == right_value)
        })
        .unwrap_or(false)
}

fn cross_field_equal(
    left: &SpendableObject,
    left_field: &str,
    right: &SpendableObject,
    right_field: &str,
) -> bool {
    object_field(left, left_field)
        .and_then(|left_value| {
            object_field(right, right_field).map(|right_value| left_value == right_value)
        })
        .unwrap_or(false)
}

fn serial_delta(before: &SpendableObject, after: &SpendableObject, field: &str) -> Option<i64> {
    object_int(after, field)
        .ok()
        .zip(object_int(before, field).ok())
        .map(|(after, before)| after - before)
}

fn audit_claim_transaction(
    profile: ClaimProfile,
    action_name: &str,
    step: &AuditStep,
) -> Result<(ClaimFacts, JsonValue, bool)> {
    let (pre_ship_class, pre_ship) =
        unique_class_object(&step.input_classes, &step.inputs, "spaceship")?;
    let (post_ship_class, post_ship) =
        unique_class_object(&step.output_classes, &step.outputs.objs, "spaceship")?;
    let (sector_class, sector) =
        unique_class_object(&step.output_classes, &step.outputs.objs, "sector")?;

    let pre_ship_commitment = pre_ship.obj.commitment();
    let post_ship_commitment = post_ship.obj.commitment();
    let sector_commitment = sector.obj.commitment();
    let expected_ship_nullifier = compute_nullifier(&pre_ship.obj);
    let post_ship_initial_commitment = object_initial_commitment(post_ship)?;
    let sector_initial_commitment = object_initial_commitment(sector)?;
    let direct_tier = if profile.is_direct_replacement() {
        Some(
            direct_tier_expectation(action_name).with_context(|| {
                format!(
                    "direct-replacement profile requires ClaimSectorSmall, ClaimSectorMedium, or ClaimSectorLarge; got {action_name}"
                )
            })?,
        )
    } else {
        None
    };

    let pre_stable_identifier = object_field(pre_ship, "stable_identifier")?;
    let post_stable_identifier = object_field(post_ship, "stable_identifier")?;
    let sector_stable_identifier = object_field(sector, "stable_identifier")?;
    let pre_key = object_field(pre_ship, "key")?;
    let post_key = object_field(post_ship, "key")?;
    let pre_work = object_field(pre_ship, "work")?;
    let post_work = object_field(post_ship, "work")?;
    let sector_key = object_field(sector, "key")?;
    let sector_work = object_field(sector, "work")?;

    let action_serial_delta = serial_delta(pre_ship, post_ship, "action_serial");
    let claim_serial_delta = serial_delta(pre_ship, post_ship, "claim_serial");
    let mut assertions = BTreeMap::new();
    bool_assertion(
        &mut assertions,
        "ship_stable_identifier_preserved",
        pre_stable_identifier == post_stable_identifier,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_stable_identifier_is_fresh",
        pre_stable_identifier != post_stable_identifier,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_stable_identifier_matches_initial_commitment",
        post_stable_identifier.raw() == post_ship_initial_commitment.raw(),
    );
    bool_assertion(
        &mut assertions,
        "ship_commitment_changed",
        pre_ship_commitment != post_ship_commitment,
    );
    for field in ["x", "y", "z", "epoch"] {
        bool_assertion(
            &mut assertions,
            format!("ship_{field}_unchanged"),
            same_field(pre_ship, post_ship, field),
        );
        bool_assertion(
            &mut assertions,
            format!("sector_{field}_matches_pre_claim_ship"),
            same_field(pre_ship, sector, field),
        );
    }
    for field in [
        "type",
        "schema_version",
        "mechanics_version",
        "universe_version",
        "ship_tier",
        "movement_step",
        "timewarp_step",
        "discovery_serial",
        "resource_serial",
        "satellite_serial",
        "civilization_scan_serial",
    ] {
        bool_assertion(
            &mut assertions,
            format!("replacement_ship_{field}_preserved"),
            same_field(pre_ship, post_ship, field),
        );
    }
    bool_assertion(
        &mut assertions,
        "direct_signature_is_input_ship_output_ship_sector",
        step.input_classes.len() == 1
            && class_matches(&step.input_classes[0], "spaceship")
            && step.output_classes.len() == 2
            && class_matches(&step.output_classes[0], "spaceship")
            && class_matches(&step.output_classes[1], "sector"),
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_schema_is_exact",
        object_has_exact_fields(post_ship, DIRECT_SHIP_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "sector_schema_is_exact",
        object_has_exact_fields(sector, DIRECT_SECTOR_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "direct_pre_claim_route_matches_tier",
        direct_tier.is_some_and(|tier| {
            fixed_int_is(pre_ship, "schema_version", 1)
                && fixed_int_is(pre_ship, "mechanics_version", 1)
                && fixed_int_is(pre_ship, "universe_version", 1)
                && fixed_int_is(pre_ship, "ship_tier", tier.ship_tier)
                && fixed_int_is(pre_ship, "movement_step", tier.movement_step)
                && fixed_int_is(pre_ship, "timewarp_step", tier.timewarp_step)
                && fixed_int_is(pre_ship, "x", DIRECT_COORD_ZERO + tier.movement_step)
                && fixed_int_is(pre_ship, "y", DIRECT_COORD_ZERO - tier.movement_step)
                && fixed_int_is(pre_ship, "z", DIRECT_COORD_ZERO)
                && fixed_int_is(pre_ship, "epoch", tier.timewarp_step)
                && fixed_int_is(pre_ship, "action_serial", 3)
                && fixed_int_is(pre_ship, "claim_serial", 0)
                && fixed_int_is(pre_ship, "discovery_serial", 0)
                && fixed_int_is(pre_ship, "resource_serial", 0)
                && fixed_int_is(pre_ship, "satellite_serial", 0)
                && fixed_int_is(pre_ship, "civilization_scan_serial", 0)
        }),
    );
    bool_assertion(
        &mut assertions,
        "direct_post_claim_serials_are_exact",
        fixed_int_is(post_ship, "action_serial", 4) && fixed_int_is(post_ship, "claim_serial", 1),
    );
    bool_assertion(
        &mut assertions,
        "pre_claim_work_is_nonzero",
        pre_work.raw() != EMPTY_VALUE,
    );
    bool_assertion(
        &mut assertions,
        "action_serial_delta_matches_profile",
        action_serial_delta == Some(profile.expected_serial_delta()),
    );
    bool_assertion(
        &mut assertions,
        "claim_serial_delta_matches_profile",
        claim_serial_delta == Some(profile.expected_serial_delta()),
    );
    bool_assertion(&mut assertions, "ship_key_changed", pre_key != post_key);
    bool_assertion(
        &mut assertions,
        "ship_work_change_matches_profile",
        (pre_work != post_work) == profile.expects_work_change(),
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_work_is_sdk_empty",
        post_work.raw() == EMPTY_VALUE,
    );
    bool_assertion(
        &mut assertions,
        "sector_key_is_fixed_zero",
        sector_key.raw() == EMPTY_VALUE,
    );
    bool_assertion(
        &mut assertions,
        "sector_work_is_initial_zero",
        sector_work.raw() == EMPTY_VALUE,
    );
    bool_assertion(
        &mut assertions,
        "sector_stable_identifier_matches_initial_commitment",
        sector_stable_identifier.raw() == sector_initial_commitment.raw(),
    );
    bool_assertion(
        &mut assertions,
        "old_ship_nullified",
        step.nullifiers.contains(&expected_ship_nullifier),
    );
    bool_assertion(
        &mut assertions,
        "new_ship_is_live",
        step.live_commitments.contains(&post_ship_commitment),
    );
    bool_assertion(
        &mut assertions,
        "sector_is_live",
        step.live_commitments.contains(&sector_commitment),
    );
    bool_assertion(
        &mut assertions,
        "exactly_one_nullifier",
        step.nullifiers.len() == 1,
    );
    bool_assertion(
        &mut assertions,
        "exactly_two_live_objects",
        step.live_commitments.len() == 2,
    );
    bool_assertion(
        &mut assertions,
        "payload_fits_hard_limit",
        step.payload.fits_hard_limit,
    );
    bool_assertion(
        &mut assertions,
        "sector_fixed_schema_values",
        fixed_int_is(sector, "schema_version", 1)
            && fixed_int_is(sector, "mechanics_version", 1)
            && fixed_int_is(sector, "universe_version", 1)
            && fixed_int_is(sector, "body_bank_version", 1)
            && fixed_int_is(sector, "revealed", 0)
            && fixed_int_is(sector, "revision", 0),
    );

    let mut required = vec![
        "ship_commitment_changed",
        "ship_x_unchanged",
        "ship_y_unchanged",
        "ship_z_unchanged",
        "ship_epoch_unchanged",
        "action_serial_delta_matches_profile",
        "claim_serial_delta_matches_profile",
        "ship_key_changed",
        "sector_stable_identifier_matches_initial_commitment",
        "old_ship_nullified",
        "new_ship_is_live",
        "sector_is_live",
        "exactly_one_nullifier",
        "exactly_two_live_objects",
        "payload_fits_hard_limit",
    ];
    if profile.is_direct_replacement() {
        required.extend([
            "replacement_ship_stable_identifier_is_fresh",
            "replacement_ship_stable_identifier_matches_initial_commitment",
            "direct_signature_is_input_ship_output_ship_sector",
            "replacement_ship_schema_is_exact",
            "sector_schema_is_exact",
            "direct_pre_claim_route_matches_tier",
            "direct_post_claim_serials_are_exact",
            "replacement_ship_type_preserved",
            "replacement_ship_schema_version_preserved",
            "replacement_ship_mechanics_version_preserved",
            "replacement_ship_universe_version_preserved",
            "replacement_ship_ship_tier_preserved",
            "replacement_ship_movement_step_preserved",
            "replacement_ship_timewarp_step_preserved",
            "replacement_ship_discovery_serial_preserved",
            "replacement_ship_resource_serial_preserved",
            "replacement_ship_satellite_serial_preserved",
            "replacement_ship_civilization_scan_serial_preserved",
            "replacement_ship_work_is_sdk_empty",
            "pre_claim_work_is_nonzero",
        ]);
    } else {
        required.extend([
            "ship_stable_identifier_preserved",
            "ship_work_change_matches_profile",
        ]);
    }
    if profile.requires_binding() {
        required.extend([
            "sector_x_matches_pre_claim_ship",
            "sector_y_matches_pre_claim_ship",
            "sector_z_matches_pre_claim_ship",
            "sector_epoch_matches_pre_claim_ship",
        ]);
    }
    if profile.requires_full_sector() {
        required.extend([
            "sector_key_is_fixed_zero",
            "sector_work_is_initial_zero",
            "sector_fixed_schema_values",
        ]);
    }
    let all_required_pass = required
        .iter()
        .all(|name| assertions.get(*name).copied().unwrap_or(false));

    let facts = ClaimFacts {
        sector: sector.clone(),
        sector_initial_commitment,
    };
    let report = json!({
        "action": action_name,
        "profile": profile.name(),
        "status": if all_required_pass { "pass" } else { "fail" },
        "required_assertions": required,
        "assertions": assertions,
        "observed_deltas": {
            "action_serial": action_serial_delta,
            "claim_serial": claim_serial_delta,
        },
        "pre_claim_ship": object_report(pre_ship_class, pre_ship)?,
        "post_claim_ship": object_report(post_ship_class, post_ship)?,
        "sector": object_report(sector_class, sector)?,
        "expected_old_ship_nullifier": hash_string(expected_ship_nullifier),
        "claim_live_commitments": step.live_commitments.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
        "claim_nullifiers": step.nullifiers.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
        "replacement_ship_initial_commitment": hash_string(post_ship_initial_commitment),
        "sector_initial_commitment": hash_string(sector_initial_commitment),
        "sector_materialized_commitment": hash_string(sector_commitment),
    });
    Ok((facts, report, all_required_pass))
}

#[derive(Clone)]
struct RevealFacts {
    old_ship_nullifier: Hash,
    old_sector_nullifier: Hash,
    replacement_ship_commitment: Hash,
    revealed_sector_commitment: Hash,
}

fn audit_reveal_transaction(
    action_name: &str,
    step: &AuditStep,
) -> Result<(RevealFacts, JsonValue, bool)> {
    let (pre_ship_class, pre_ship) =
        unique_class_object(&step.input_classes, &step.inputs, "spaceship")?;
    let (pre_sector_class, pre_sector) =
        unique_class_object(&step.input_classes, &step.inputs, "sector")?;
    let (post_ship_class, post_ship) =
        unique_class_object(&step.output_classes, &step.outputs.objs, "spaceship")?;
    let (post_sector_class, post_sector) =
        unique_class_object(&step.output_classes, &step.outputs.objs, "sector")?;

    let pre_ship_commitment = pre_ship.obj.commitment();
    let pre_sector_commitment = pre_sector.obj.commitment();
    let post_ship_commitment = post_ship.obj.commitment();
    let post_sector_commitment = post_sector.obj.commitment();
    let old_ship_nullifier = compute_nullifier(&pre_ship.obj);
    let old_sector_nullifier = compute_nullifier(&pre_sector.obj);
    let post_ship_initial_commitment = object_initial_commitment(post_ship)?;

    let pre_ship_stable = object_field(pre_ship, "stable_identifier")?;
    let post_ship_stable = object_field(post_ship, "stable_identifier")?;
    let pre_sector_stable = object_field(pre_sector, "stable_identifier")?;
    let post_sector_stable = object_field(post_sector, "stable_identifier")?;
    let pre_ship_key = object_field(pre_ship, "key")?;
    let post_ship_key = object_field(post_ship, "key")?;
    let pre_sector_key = object_field(pre_sector, "key")?;
    let post_sector_key = object_field(post_sector, "key")?;
    let pre_ship_work = object_field(pre_ship, "work")?;
    let post_ship_work = object_field(post_ship, "work")?;
    let pre_sector_work = object_field(pre_sector, "work")?;
    let post_sector_work = object_field(post_sector, "work")?;
    let action_serial_delta = serial_delta(pre_ship, post_ship, "action_serial");
    let ship_nullifier_occurrences = step
        .nullifiers
        .iter()
        .filter(|nullifier| **nullifier == old_ship_nullifier)
        .count();
    let sector_nullifier_occurrences = step
        .nullifiers
        .iter()
        .filter(|nullifier| **nullifier == old_sector_nullifier)
        .count();

    let mut assertions = BTreeMap::new();
    bool_assertion(
        &mut assertions,
        "signature_is_output_ship_input_ship_mutate_sector",
        step.input_classes.len() == 2
            && class_matches(&step.input_classes[0], "spaceship")
            && class_matches(&step.input_classes[1], "sector")
            && step.output_classes.len() == 2
            && class_matches(&step.output_classes[0], "spaceship")
            && class_matches(&step.output_classes[1], "sector"),
    );
    bool_assertion(
        &mut assertions,
        "pre_reveal_ship_schema_is_exact",
        object_has_exact_fields(pre_ship, DIRECT_SHIP_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_schema_is_exact",
        object_has_exact_fields(post_ship, DIRECT_SHIP_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "pre_reveal_sector_schema_is_exact",
        object_has_exact_fields(pre_sector, DIRECT_SECTOR_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "revealed_sector_schema_is_exact",
        object_has_exact_fields(post_sector, DIRECT_SECTOR_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_semantic_fields_preserved",
        fields_equal(pre_ship, post_ship, SHIP_SEMANTIC_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_action_serial_incremented_once",
        action_serial_delta == Some(1),
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_stable_identifier_is_fresh",
        pre_ship_stable != post_ship_stable,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_stable_identifier_matches_initial_commitment",
        post_ship_stable.raw() == post_ship_initial_commitment.raw(),
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_type_preserved",
        same_field(pre_ship, post_ship, "type"),
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_key_is_fresh",
        pre_ship_key != post_ship_key,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_work_is_sdk_empty",
        pre_ship_work.raw() != EMPTY_VALUE && post_ship_work.raw() == EMPTY_VALUE,
    );
    bool_assertion(
        &mut assertions,
        "sector_stable_identifier_preserved",
        pre_sector_stable == post_sector_stable,
    );
    bool_assertion(
        &mut assertions,
        "sector_commitment_changed",
        pre_sector_commitment != post_sector_commitment,
    );
    bool_assertion(
        &mut assertions,
        "sector_key_rotated",
        pre_sector_key != post_sector_key,
    );
    bool_assertion(
        &mut assertions,
        "sector_work_preserved",
        pre_sector_work == post_sector_work,
    );
    bool_assertion(
        &mut assertions,
        "sector_fields_preserved_except_reveal_revision_and_key",
        fields_equal_except(pre_sector, post_sector, &["key", "revealed", "revision"])?,
    );
    bool_assertion(
        &mut assertions,
        "sector_revealed_from_zero_to_one",
        fixed_int_is(pre_sector, "revealed", 0) && fixed_int_is(post_sector, "revealed", 1),
    );
    bool_assertion(
        &mut assertions,
        "sector_revision_incremented_once",
        serial_delta(pre_sector, post_sector, "revision") == Some(1),
    );
    for field in ["x", "y", "z", "epoch"] {
        bool_assertion(
            &mut assertions,
            format!("pre_reveal_ship_sector_{field}_equal"),
            same_field(pre_ship, pre_sector, field),
        );
        bool_assertion(
            &mut assertions,
            format!("replacement_ship_{field}_preserved"),
            same_field(pre_ship, post_ship, field),
        );
        bool_assertion(
            &mut assertions,
            format!("revealed_sector_{field}_preserved"),
            same_field(pre_sector, post_sector, field),
        );
        bool_assertion(
            &mut assertions,
            format!("post_reveal_ship_sector_{field}_equal"),
            same_field(post_ship, post_sector, field),
        );
    }
    bool_assertion(
        &mut assertions,
        "old_ship_consumed_exactly_once",
        ship_nullifier_occurrences == 1,
    );
    bool_assertion(
        &mut assertions,
        "old_sector_state_nullified_exactly_once",
        sector_nullifier_occurrences == 1,
    );
    bool_assertion(
        &mut assertions,
        "exactly_two_nullifiers",
        step.nullifiers.len() == 2,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_is_live",
        step.live_commitments.contains(&post_ship_commitment),
    );
    bool_assertion(
        &mut assertions,
        "revealed_sector_state_is_live",
        step.live_commitments.contains(&post_sector_commitment),
    );
    bool_assertion(
        &mut assertions,
        "exactly_two_live_objects",
        step.live_commitments.len() == 2,
    );
    bool_assertion(
        &mut assertions,
        "old_commitments_are_not_live_outputs",
        !step.live_commitments.contains(&pre_ship_commitment)
            && !step.live_commitments.contains(&pre_sector_commitment),
    );
    bool_assertion(
        &mut assertions,
        "payload_fits_hard_limit",
        step.payload.fits_hard_limit,
    );

    let required = assertions.keys().cloned().collect::<Vec<_>>();
    let all_required_pass = assertions.values().all(|value| *value);
    let facts = RevealFacts {
        old_ship_nullifier,
        old_sector_nullifier,
        replacement_ship_commitment: post_ship_commitment,
        revealed_sector_commitment: post_sector_commitment,
    };
    let report = json!({
        "action": action_name,
        "status": if all_required_pass { "pass" } else { "fail" },
        "required_assertions": required,
        "assertions": assertions,
        "observed_deltas": {
            "ship_action_serial": action_serial_delta,
            "sector_revision": serial_delta(pre_sector, post_sector, "revision"),
        },
        "pre_reveal_ship": object_report(pre_ship_class, pre_ship)?,
        "replacement_ship": object_report(post_ship_class, post_ship)?,
        "pre_reveal_sector": object_report(pre_sector_class, pre_sector)?,
        "revealed_sector": object_report(post_sector_class, post_sector)?,
        "expected_old_ship_nullifier": hash_string(old_ship_nullifier),
        "expected_old_sector_nullifier": hash_string(old_sector_nullifier),
        "reveal_live_commitments": step.live_commitments.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
        "reveal_nullifiers": step.nullifiers.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
        "replacement_ship_initial_commitment": hash_string(post_ship_initial_commitment),
    });
    Ok((facts, report, all_required_pass))
}

fn class_object_reports(classes: &[String], objects: &[SpendableObject]) -> Result<Vec<JsonValue>> {
    if classes.len() != objects.len() {
        bail!(
            "class/object report length mismatch: {} classes and {} objects",
            classes.len(),
            objects.len()
        );
    }
    classes
        .iter()
        .zip(objects)
        .map(|(class, object)| object_report(class, object))
        .collect()
}

fn audit_ship_gated_lifecycle_step(
    action_name: &str,
    spec: LifecycleFamilySpec,
    input_classes: &[String],
    inputs: &[SpendableObject],
    output_classes: &[String],
    outputs: &[SpendableObject],
    live_commitments: &[Hash],
    nullifiers: &[Hash],
) -> Result<(JsonValue, bool)> {
    let (pre_ship_class, pre_ship) = unique_class_object(input_classes, inputs, "spaceship")?;
    let (post_ship_class, post_ship) = unique_class_object(output_classes, outputs, "spaceship")?;
    let (pre_target_class, pre_target) =
        unique_class_object(input_classes, inputs, spec.target_class)?;
    let (post_target_class, post_target) =
        unique_class_object(output_classes, outputs, spec.target_class)?;
    let child = spec
        .child_class
        .map(|child_class| unique_class_object(output_classes, outputs, child_class))
        .transpose()?;

    let pre_ship_stable = object_field(pre_ship, "stable_identifier")?;
    let post_ship_stable = object_field(post_ship, "stable_identifier")?;
    let pre_target_stable = object_field(pre_target, "stable_identifier")?;
    let post_target_stable = object_field(post_target, "stable_identifier")?;
    let post_ship_initial_commitment = object_initial_commitment(post_ship)?;
    let expected_ship_nullifier = compute_nullifier(&pre_ship.obj);
    let expected_target_nullifier = compute_nullifier(&pre_target.obj);
    let post_ship_commitment = post_ship.obj.commitment();
    let post_target_commitment = post_target.obj.commitment();
    let expected_output_count = 2 + usize::from(spec.child_class.is_some());
    let child_output_count = spec.child_class.map_or(0, |child_class| {
        output_classes
            .iter()
            .filter(|class| class_matches(class, child_class))
            .count()
    });
    let input_shape_exact =
        class_sequence_matches(input_classes, &["spaceship", spec.target_class]);
    let expected_output_suffixes = if let Some(child_class) = spec.child_class {
        vec!["spaceship", child_class, spec.target_class]
    } else {
        vec!["spaceship", spec.target_class]
    };
    let output_shape_exact = class_sequence_matches(output_classes, &expected_output_suffixes)
        && output_classes.len() == expected_output_count
        && child_output_count == usize::from(spec.child_class.is_some());
    let target_fields = lifecycle_class_fields(spec.target_class)
        .ok_or_else(|| anyhow!("missing exact schema for {}", spec.target_class))?;
    let allowed_target_fields = allowed_target_mutations(action_name, spec.name)?;

    let mut assertions = BTreeMap::new();
    bool_assertion(
        &mut assertions,
        "exact_ordered_input_shape_is_old_ship_then_persistent_target",
        input_shape_exact,
    );
    bool_assertion(
        &mut assertions,
        "exact_ordered_output_shape_is_replacement_ship_child_then_target",
        output_shape_exact,
    );
    bool_assertion(
        &mut assertions,
        "old_ship_schema_is_exact",
        object_has_exact_fields(pre_ship, DIRECT_SHIP_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_schema_is_exact",
        object_has_exact_fields(post_ship, DIRECT_SHIP_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "persistent_target_input_schema_is_exact",
        object_has_exact_fields(pre_target, target_fields)?,
    );
    bool_assertion(
        &mut assertions,
        "persistent_target_output_schema_is_exact",
        object_has_exact_fields(post_target, target_fields)?,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_type_preserved",
        same_field(pre_ship, post_ship, "type"),
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_key_is_fresh",
        !same_field(pre_ship, post_ship, "key"),
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_work_is_sdk_empty",
        object_field(post_ship, "work")?.raw() == EMPTY_VALUE,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_stable_identifier_changes",
        pre_ship_stable != post_ship_stable,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_stable_identifier_matches_initial_commitment",
        post_ship_stable.raw() == post_ship_initial_commitment.raw(),
    );
    for field in SHIP_LOGICAL_FIELDS {
        let assertion_name = if *field == "action_serial" {
            "replacement_ship_action_serial_incremented_once".to_string()
        } else if spec.ship_serial == Some(*field) {
            format!("replacement_ship_{field}_incremented_once")
        } else {
            format!("replacement_ship_{field}_preserved")
        };
        let passes = if *field == "action_serial" || spec.ship_serial == Some(*field) {
            serial_delta(pre_ship, post_ship, field) == Some(1)
        } else {
            same_field(pre_ship, post_ship, field)
        };
        bool_assertion(&mut assertions, assertion_name, passes);
    }
    bool_assertion(
        &mut assertions,
        "persistent_target_stable_identifier_preserved",
        pre_target_stable == post_target_stable,
    );
    bool_assertion(
        &mut assertions,
        "persistent_target_commitment_changed",
        pre_target.obj.commitment() != post_target.obj.commitment(),
    );
    bool_assertion(
        &mut assertions,
        "persistent_target_key_is_rotated",
        !same_field(pre_target, post_target, "key"),
    );
    bool_assertion(
        &mut assertions,
        "persistent_target_only_declared_fields_changed",
        fields_equal_except(pre_target, post_target, &allowed_target_fields)?,
    );
    let target_location_fields = lifecycle_location_fields(spec.target_class)
        .ok_or_else(|| anyhow!("missing location schema for {}", spec.target_class))?;
    for (ship_field, target_field) in ["x", "y", "z", "epoch"].iter().zip(target_location_fields) {
        bool_assertion(
            &mut assertions,
            format!("old_ship_{ship_field}_matches_target_{target_field}"),
            cross_field_equal(pre_ship, ship_field, pre_target, target_field),
        );
        bool_assertion(
            &mut assertions,
            format!("replacement_ship_{ship_field}_matches_target_{target_field}"),
            cross_field_equal(post_ship, ship_field, post_target, target_field),
        );
        bool_assertion(
            &mut assertions,
            format!("persistent_target_{target_field}_preserved"),
            same_field(pre_target, post_target, target_field),
        );
    }
    if matches!(spec.target_class, "civilization" | "technology_skill") {
        bool_assertion(
            &mut assertions,
            "persistent_target_civilization_version_is_one",
            fixed_int_is(pre_target, "civilization_version", 1)
                && fixed_int_is(post_target, "civilization_version", 1),
        );
    }
    if spec.name == "develop-technology-skill" {
        let skill = technology_skill_spec(action_name)
            .ok_or_else(|| anyhow!("missing technology skill spec for {action_name}"))?;
        bool_assertion(
            &mut assertions,
            "civilization_type_matches_skill_tier_and_is_preserved",
            fixed_int_is(pre_target, "civilization_type", skill.civilization_type)
                && fixed_int_is(post_target, "civilization_type", skill.civilization_type),
        );
    }
    if spec.name == "use-technology-skill" {
        bool_assertion(
            &mut assertions,
            "technology_skill_is_declared_reusable",
            fixed_int_is(pre_target, "reusable", 1) && fixed_int_is(post_target, "reusable", 1),
        );
    }
    if let Some((child_class, child)) = child {
        let child_fields = lifecycle_class_fields(spec.child_class.expect("child class exists"))
            .ok_or_else(|| {
                anyhow!(
                    "missing exact schema for {}",
                    spec.child_class.expect("child class exists")
                )
            })?;
        let child_initial_commitment = object_initial_commitment(child)?;
        bool_assertion(
            &mut assertions,
            "child_schema_is_exact",
            object_has_exact_fields(child, child_fields)?,
        );
        bool_assertion(
            &mut assertions,
            "child_stable_identifier_matches_initial_commitment",
            object_field(child, "stable_identifier")?.raw() == child_initial_commitment.raw(),
        );
        let child_key = object_field(child, "key")?.raw();
        if spec.name == "detect-celestial-signal" {
            bool_assertion(
                &mut assertions,
                "signal_key_is_deterministic_zero",
                child_key == EMPTY_VALUE,
            );
        } else {
            bool_assertion(
                &mut assertions,
                "portable_child_retains_sdk_random_key",
                child_key != EMPTY_VALUE,
            );
        }
        bool_assertion(
            &mut assertions,
            "child_work_is_sdk_empty",
            object_field(child, "work")?.raw() == EMPTY_VALUE,
        );
        bool_assertion(
            &mut assertions,
            "child_fixed_protocol_versions",
            fixed_int_is(child, "schema_version", 1)
                && fixed_int_is(child, "mechanics_version", 1)
                && fixed_int_is(child, "universe_version", 1),
        );
        match spec.name {
            "detect-celestial-signal" => {
                let candidate_code =
                    candidate_code_from_action(action_name, "DetectCelestialSignal_").ok_or_else(
                        || anyhow!("malformed celestial signal action name {action_name}"),
                    )?;
                bool_assertion(
                    &mut assertions,
                    "signal_body_bank_version_is_one",
                    fixed_int_is(child, "body_bank_version", 1),
                );
                bool_assertion(
                    &mut assertions,
                    "signal_candidate_code_matches_action_name",
                    fixed_int_is(child, "candidate_code", candidate_code),
                );
                for (child_field, target_field) in [
                    ("sector_x", "x"),
                    ("sector_y", "y"),
                    ("sector_z", "z"),
                    ("sector_epoch", "epoch"),
                ] {
                    bool_assertion(
                        &mut assertions,
                        format!("signal_{child_field}_matches_sector_{target_field}"),
                        cross_field_equal(child, child_field, pre_target, target_field),
                    );
                }
                bool_assertion(
                    &mut assertions,
                    "sector_revision_incremented_once",
                    serial_delta(pre_target, post_target, "revision") == Some(1),
                );
            }
            "specialized-resource" => {
                let resource = specialized_resource_spec(action_name).ok_or_else(|| {
                    anyhow!("unsupported specialized resource action {action_name}")
                })?;
                bool_assertion(
                    &mut assertions,
                    "resource_type_matches_specialized_action",
                    fixed_int_is(child, "resource_type", resource.resource_type),
                );
                bool_assertion(
                    &mut assertions,
                    "resource_parent_candidate_matches_specialized_action",
                    fixed_int_is(pre_target, "candidate_code", resource.candidate_code)
                        && fixed_int_is(post_target, "candidate_code", resource.candidate_code),
                );
                bool_assertion(
                    &mut assertions,
                    "resource_amount_is_one",
                    fixed_int_is(child, "amount", 1),
                );
                bool_assertion(
                    &mut assertions,
                    "selected_specialized_pool_was_positive",
                    object_int(pre_target, resource.remaining_field).is_ok_and(|value| value > 0),
                );
                bool_assertion(
                    &mut assertions,
                    "selected_specialized_pool_decremented_once",
                    serial_delta(pre_target, post_target, resource.remaining_field) == Some(-1),
                );
                bool_assertion(
                    &mut assertions,
                    "specialized_resource_body_work_is_preserved_or_vdf_rotated",
                    same_field(pre_target, post_target, "work")
                        || object_field(post_target, "work")?.raw() != EMPTY_VALUE,
                );
            }
            "extract-resource" => {
                let (remaining_field, resource_type) = extracted_resource_field(action_name)
                    .ok_or_else(|| anyhow!("unsupported extraction action {action_name}"))?;
                bool_assertion(
                    &mut assertions,
                    "resource_type_matches_action",
                    fixed_int_is(child, "resource_type", resource_type),
                );
                bool_assertion(
                    &mut assertions,
                    "resource_amount_is_one",
                    fixed_int_is(child, "amount", 1),
                );
                bool_assertion(
                    &mut assertions,
                    "selected_resource_remaining_decremented_once",
                    serial_delta(pre_target, post_target, remaining_field) == Some(-1),
                );
                bool_assertion(
                    &mut assertions,
                    "target_work_is_refreshed_by_vdf",
                    !same_field(pre_target, post_target, "work")
                        && object_field(post_target, "work")?.raw() != EMPTY_VALUE,
                );
            }
            "discover-satellite" => {
                for field in ["sector_x", "sector_y", "sector_z", "sector_epoch"] {
                    bool_assertion(
                        &mut assertions,
                        format!("satellite_{field}_matches_body"),
                        same_field(child, pre_target, field),
                    );
                }
                bool_assertion(
                    &mut assertions,
                    "satellite_serial_matches_target",
                    cross_field_equal(
                        child,
                        "satellite_serial",
                        post_target,
                        "next_satellite_serial",
                    ),
                );
                bool_assertion(
                    &mut assertions,
                    "target_satellite_serial_incremented_once",
                    serial_delta(pre_target, post_target, "next_satellite_serial") == Some(1),
                );
                bool_assertion(
                    &mut assertions,
                    "target_satellites_remaining_decremented_once",
                    serial_delta(pre_target, post_target, "satellites_remaining") == Some(-1),
                );
            }
            "detect-intelligent-life" => {
                bool_assertion(
                    &mut assertions,
                    "life_signal_civilization_version_is_one",
                    fixed_int_is(child, "civilization_version", 1),
                );
                for (child_field, target_field) in [
                    ("sector_x", "sector_x"),
                    ("sector_y", "sector_y"),
                    ("sector_z", "sector_z"),
                    ("origin_epoch", "sector_epoch"),
                ] {
                    bool_assertion(
                        &mut assertions,
                        format!("life_signal_{child_field}_matches_planet_{target_field}"),
                        cross_field_equal(child, child_field, pre_target, target_field),
                    );
                }
                bool_assertion(
                    &mut assertions,
                    "target_civilization_discovered_changes_zero_to_one",
                    fixed_int_is(pre_target, "civilization_discovered", 0)
                        && fixed_int_is(post_target, "civilization_discovered", 1),
                );
            }
            "develop-technology-skill" => {
                let skill = technology_skill_spec(action_name)
                    .ok_or_else(|| anyhow!("missing technology skill spec for {action_name}"))?;
                bool_assertion(
                    &mut assertions,
                    "technology_skill_civilization_version_is_one",
                    fixed_int_is(child, "civilization_version", 1),
                );
                bool_assertion(
                    &mut assertions,
                    "technology_skill_type_matches_action",
                    fixed_int_is(child, "skill_type", skill.skill_type),
                );
                bool_assertion(
                    &mut assertions,
                    "technology_skill_is_reusable",
                    fixed_int_is(child, "reusable", 1),
                );
            }
            _ => {}
        }
        let _ = child_class;
    }
    bool_assertion(
        &mut assertions,
        "old_ship_nullifier_present_once",
        nullifiers
            .iter()
            .filter(|nullifier| **nullifier == expected_ship_nullifier)
            .count()
            == 1,
    );
    bool_assertion(
        &mut assertions,
        "old_target_nullifier_present_once",
        nullifiers
            .iter()
            .filter(|nullifier| **nullifier == expected_target_nullifier)
            .count()
            == 1,
    );
    bool_assertion(
        &mut assertions,
        "exactly_two_nullifiers",
        nullifiers.len() == 2,
    );
    bool_assertion(
        &mut assertions,
        "replacement_ship_is_live",
        live_commitments.contains(&post_ship_commitment),
    );
    bool_assertion(
        &mut assertions,
        "persistent_target_new_state_is_live",
        live_commitments.contains(&post_target_commitment),
    );
    bool_assertion(
        &mut assertions,
        "live_commitment_count_matches_outputs",
        live_commitments.len() == expected_output_count,
    );
    bool_assertion(
        &mut assertions,
        "every_declared_output_object_is_live",
        outputs
            .iter()
            .all(|output| live_commitments.contains(&output.obj.commitment())),
    );

    let required_assertions = assertions.keys().cloned().collect::<Vec<_>>();
    let all_pass = assertions.values().all(|value| *value);
    Ok((
        json!({
            "kind": "refactored-ship-gated-action",
            "family": spec.name,
            "action": action_name,
            "status": if all_pass { "pass" } else { "fail" },
            "target_class": spec.target_class,
            "expected_child_class": spec.child_class,
            "family_specific_ship_serial": spec.ship_serial,
            "required_assertions": required_assertions,
            "assertions": assertions,
            "identity_transitions": {
                "old_ship_stable_identifier": exact_raw_string(&pre_ship_stable),
                "replacement_ship_stable_identifier": exact_raw_string(&post_ship_stable),
                "persistent_target_stable_identifier_before": exact_raw_string(&pre_target_stable),
                "persistent_target_stable_identifier_after": exact_raw_string(&post_target_stable),
                "old_ship_commitment": hash_string(pre_ship.obj.commitment()),
                "replacement_ship_commitment": hash_string(post_ship_commitment),
                "persistent_target_commitment_before": hash_string(pre_target.obj.commitment()),
                "persistent_target_commitment_after": hash_string(post_target_commitment),
            },
            "observed_ship_serial_deltas": {
                "action_serial": serial_delta(pre_ship, post_ship, "action_serial"),
                "family_specific": spec.ship_serial.and_then(|field| serial_delta(pre_ship, post_ship, field)),
            },
            "old_ship": object_report(pre_ship_class, pre_ship)?,
            "replacement_ship": object_report(post_ship_class, post_ship)?,
            "persistent_target_before": object_report(pre_target_class, pre_target)?,
            "persistent_target_after": object_report(post_target_class, post_target)?,
        }),
        all_pass,
    ))
}

fn audit_materializer_lifecycle_step(
    action_name: &str,
    spec: MaterializerSpec,
    input_classes: &[String],
    inputs: &[SpendableObject],
    output_classes: &[String],
    outputs: &[SpendableObject],
    live_commitments: &[Hash],
    nullifiers: &[Hash],
) -> Result<(JsonValue, bool)> {
    let (candidate_class, candidate) =
        unique_class_object(input_classes, inputs, spec.input_class)?;
    let (pre_ship_class, pre_ship) = unique_class_object(input_classes, inputs, "spaceship")?;
    let (final_class, final_object) =
        unique_class_object(output_classes, outputs, spec.output_class)?;
    let (post_ship_class, post_ship) = unique_class_object(output_classes, outputs, "spaceship")?;
    let candidate_nullifier = compute_nullifier(&candidate.obj);
    let ship_nullifier = compute_nullifier(&pre_ship.obj);
    let final_commitment = final_object.obj.commitment();
    let post_ship_commitment = post_ship.obj.commitment();
    let final_initial_commitment = object_initial_commitment(final_object)?;
    let final_stable_identifier = object_field(final_object, "stable_identifier")?;
    let pre_ship_stable_identifier = object_field(pre_ship, "stable_identifier")?;
    let post_ship_stable_identifier = object_field(post_ship, "stable_identifier")?;
    let candidate_fields = lifecycle_class_fields(spec.input_class)
        .ok_or_else(|| anyhow!("missing exact schema for {}", spec.input_class))?;
    let final_fields = lifecycle_class_fields(spec.output_class)
        .ok_or_else(|| anyhow!("missing exact schema for {}", spec.output_class))?;
    let candidate_location_fields = lifecycle_location_fields(spec.input_class)
        .ok_or_else(|| anyhow!("missing location schema for {}", spec.input_class))?;
    let final_location_fields = lifecycle_location_fields(spec.output_class)
        .ok_or_else(|| anyhow!("missing location schema for {}", spec.output_class))?;
    let mut assertions = BTreeMap::new();
    bool_assertion(
        &mut assertions,
        "exact_ordered_input_shape_is_candidate_then_mutated_ship",
        class_sequence_matches(input_classes, &[spec.input_class, "spaceship"]),
    );
    bool_assertion(
        &mut assertions,
        "exact_ordered_output_shape_is_final_then_mutated_ship",
        class_sequence_matches(output_classes, &[spec.output_class, "spaceship"]),
    );
    bool_assertion(
        &mut assertions,
        "candidate_schema_is_exact",
        object_has_exact_fields(candidate, candidate_fields)?,
    );
    bool_assertion(
        &mut assertions,
        "final_schema_is_exact",
        object_has_exact_fields(final_object, final_fields)?,
    );
    bool_assertion(
        &mut assertions,
        "old_ship_schema_is_exact",
        object_has_exact_fields(pre_ship, DIRECT_SHIP_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "mutated_ship_schema_is_exact",
        object_has_exact_fields(post_ship, DIRECT_SHIP_FIELDS)?,
    );
    bool_assertion(
        &mut assertions,
        "mutated_ship_type_preserved",
        same_field(pre_ship, post_ship, "type"),
    );
    bool_assertion(
        &mut assertions,
        "mutated_ship_stable_identifier_preserved",
        pre_ship_stable_identifier == post_ship_stable_identifier,
    );
    bool_assertion(
        &mut assertions,
        "mutated_ship_key_is_rotated",
        !same_field(pre_ship, post_ship, "key"),
    );
    bool_assertion(
        &mut assertions,
        "mutated_ship_only_key_and_action_serial_changed",
        fields_equal_except(pre_ship, post_ship, &["key", "action_serial"])?,
    );
    bool_assertion(
        &mut assertions,
        "mutated_ship_work_preserved",
        same_field(pre_ship, post_ship, "work"),
    );
    for field in SHIP_LOGICAL_FIELDS {
        let passes = if *field == "action_serial" {
            serial_delta(pre_ship, post_ship, field) == Some(1)
        } else {
            same_field(pre_ship, post_ship, field)
        };
        bool_assertion(
            &mut assertions,
            if *field == "action_serial" {
                "mutated_ship_action_serial_incremented_once".to_string()
            } else {
                format!("mutated_ship_{field}_preserved")
            },
            passes,
        );
    }
    for ((ship_field, candidate_field), final_field) in ["x", "y", "z", "epoch"]
        .iter()
        .zip(candidate_location_fields)
        .zip(final_location_fields)
    {
        bool_assertion(
            &mut assertions,
            format!("old_ship_{ship_field}_matches_candidate_{candidate_field}"),
            cross_field_equal(pre_ship, ship_field, candidate, candidate_field),
        );
        bool_assertion(
            &mut assertions,
            format!("mutated_ship_{ship_field}_matches_candidate_{candidate_field}"),
            cross_field_equal(post_ship, ship_field, candidate, candidate_field),
        );
        bool_assertion(
            &mut assertions,
            format!("final_{final_field}_matches_candidate_{candidate_field}"),
            cross_field_equal(final_object, final_field, candidate, candidate_field),
        );
    }
    bool_assertion(
        &mut assertions,
        "final_stable_identifier_matches_initial_commitment",
        final_stable_identifier.raw() == final_initial_commitment.raw(),
    );
    bool_assertion(
        &mut assertions,
        "portable_final_retains_sdk_random_key",
        object_field(final_object, "key")?.raw() != EMPTY_VALUE,
    );
    bool_assertion(
        &mut assertions,
        "final_work_is_sdk_empty",
        object_field(final_object, "work")?.raw() == EMPTY_VALUE,
    );
    bool_assertion(
        &mut assertions,
        "final_fixed_protocol_versions",
        fixed_int_is(final_object, "schema_version", 1)
            && fixed_int_is(final_object, "mechanics_version", 1)
            && fixed_int_is(final_object, "universe_version", 1),
    );
    bool_assertion(
        &mut assertions,
        "candidate_consumed_exactly_once",
        nullifiers
            .iter()
            .filter(|nullifier| **nullifier == candidate_nullifier)
            .count()
            == 1,
    );
    bool_assertion(
        &mut assertions,
        "old_ship_consumed_exactly_once",
        nullifiers
            .iter()
            .filter(|nullifier| **nullifier == ship_nullifier)
            .count()
            == 1,
    );
    bool_assertion(
        &mut assertions,
        "exactly_two_nullifiers",
        nullifiers.len() == 2,
    );
    bool_assertion(
        &mut assertions,
        "exactly_final_and_mutated_ship_are_live",
        live_commitments.len() == 2
            && live_commitments.contains(&final_commitment)
            && live_commitments.contains(&post_ship_commitment),
    );
    bool_assertion(
        &mut assertions,
        "every_declared_output_object_is_live",
        outputs
            .iter()
            .all(|output| live_commitments.contains(&output.obj.commitment())),
    );
    match spec.input_class {
        "celestial_signal" => {
            let candidate_code = candidate_code_from_action(action_name, "ScanCelestialBody_")
                .ok_or_else(|| {
                    anyhow!("malformed celestial body materializer name {action_name}")
                })?;
            bool_assertion(
                &mut assertions,
                "body_versions_and_initial_counters_are_canonical",
                fixed_int_is(final_object, "body_bank_version", 1)
                    && fixed_int_is(final_object, "next_satellite_serial", 0)
                    && fixed_int_is(final_object, "civilization_discovered", 0),
            );
            bool_assertion(
                &mut assertions,
                "signal_and_body_candidate_code_match_action_name",
                fixed_int_is(candidate, "candidate_code", candidate_code)
                    && fixed_int_is(final_object, "candidate_code", candidate_code),
            );
            for field in [
                "sector_x",
                "sector_y",
                "sector_z",
                "sector_epoch",
                "candidate_code",
            ] {
                bool_assertion(
                    &mut assertions,
                    format!("body_{field}_matches_signal"),
                    same_field(candidate, final_object, field),
                );
            }
        }
        "life_signal" => {
            let civilization_type = civilization_type_spec(action_name)
                .ok_or_else(|| anyhow!("missing Civilization type spec for {action_name}"))?;
            bool_assertion(
                &mut assertions,
                "civilization_version_and_type_are_canonical",
                fixed_int_is(final_object, "civilization_version", 1)
                    && fixed_int_is(
                        final_object,
                        "civilization_type",
                        civilization_type.civilization_type,
                    ),
            );
            for field in ["sector_x", "sector_y", "sector_z", "origin_epoch"] {
                bool_assertion(
                    &mut assertions,
                    format!("civilization_{field}_matches_life_signal"),
                    same_field(candidate, final_object, field),
                );
            }
        }
        _ => {}
    }
    let required_assertions = assertions.keys().cloned().collect::<Vec<_>>();
    let all_pass = assertions.values().all(|value| *value);
    Ok((
        json!({
            "kind": "candidate-materializer-with-direct-ship-mutation",
            "action": action_name,
            "status": if all_pass { "pass" } else { "fail" },
            "candidate_class": spec.input_class,
            "final_class": spec.output_class,
            "ship_transition": "direct_mutation_action_serial_and_key_only",
            "required_assertions": required_assertions,
            "assertions": assertions,
            "identity_transitions": {
                "ship_stable_identifier_before": exact_raw_string(&pre_ship_stable_identifier),
                "ship_stable_identifier_after": exact_raw_string(&post_ship_stable_identifier),
                "ship_commitment_before": hash_string(pre_ship.obj.commitment()),
                "ship_commitment_after": hash_string(post_ship_commitment),
                "final_stable_identifier": exact_raw_string(&final_stable_identifier),
                "final_commitment": hash_string(final_commitment),
            },
            "candidate": object_report(candidate_class, candidate)?,
            "final_object": object_report(final_class, final_object)?,
            "ship_before": object_report(pre_ship_class, pre_ship)?,
            "ship_after": object_report(post_ship_class, post_ship)?,
        }),
        all_pass,
    ))
}

fn audit_sequence_lifecycle_step(
    action_name: &str,
    input_classes: &[String],
    inputs: &[SpendableObject],
    output_classes: &[String],
    outputs: &[SpendableObject],
    live_commitments: &[Hash],
    nullifiers: &[Hash],
) -> Result<Option<(JsonValue, bool)>> {
    if let Some(spec) = lifecycle_family_spec(action_name) {
        audit_ship_gated_lifecycle_step(
            action_name,
            spec,
            input_classes,
            inputs,
            output_classes,
            outputs,
            live_commitments,
            nullifiers,
        )
        .map(Some)
    } else if let Some(spec) = materializer_spec(action_name) {
        audit_materializer_lifecycle_step(
            action_name,
            spec,
            input_classes,
            inputs,
            output_classes,
            outputs,
            live_commitments,
            nullifiers,
        )
        .map(Some)
    } else {
        Ok(None)
    }
}

fn lifecycle_step_evidence(
    step_number: usize,
    action_name: &str,
    step_real: bool,
    state_block_after: i64,
    step: &AuditStep,
) -> Result<(JsonValue, bool)> {
    let lifecycle_audit = audit_sequence_lifecycle_step(
        action_name,
        &step.input_classes,
        &step.inputs,
        &step.output_classes,
        &step.outputs.objs,
        &step.live_commitments,
        &step.nullifiers,
    )?;
    let (lifecycle_report, lifecycle_pass) = lifecycle_audit.map_or_else(
        || {
            (
                json!({
                    "status": "not_applicable",
                    "reason": "action is not a refactored Ship-gated lifecycle family or candidate materializer",
                }),
                true,
            )
        },
        |(report, passes)| (report, passes),
    );
    let selected_input_identity = step
        .input_classes
        .iter()
        .zip(&step.inputs)
        .map(|(class, object)| {
            Ok(json!({
                "class": class,
                "commitment": hash_string(object.obj.commitment()),
                "nullifier": hash_string(compute_nullifier(&object.obj)),
                "stable_identifier": exact_raw_string(&object_field(object, "stable_identifier")?),
            }))
        })
        .collect::<Result<Vec<_>>>()?;
    let output_identity = step
        .output_classes
        .iter()
        .zip(&step.outputs.objs)
        .map(|(class, object)| {
            Ok(json!({
                "class": class,
                "commitment": hash_string(object.obj.commitment()),
                "stable_identifier": exact_raw_string(&object_field(object, "stable_identifier")?),
            }))
        })
        .collect::<Result<Vec<_>>>()?;
    Ok((
        json!({
            "metrics": audit_step_report(
                step_number,
                action_name,
                step_real,
                state_block_after,
                step,
            ),
            "selected_input_indices": step.selected_indices,
            "selected_input_identity": selected_input_identity,
            "producer_derived_input_objects": class_object_reports(&step.input_classes, &step.inputs)?,
            "output_identity": output_identity,
            "producer_derived_output_objects": class_object_reports(&step.output_classes, &step.outputs.objs)?,
            "transaction_nullifiers": step.nullifiers.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
            "transaction_live_commitments": step.live_commitments.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
            "automatic_lifecycle_audit": lifecycle_report,
        }),
        lifecycle_pass,
    ))
}

fn valid_lower_hex_256(value: &str) -> bool {
    value.len() == 66
        && value.starts_with("0x")
        && value[2..]
            .bytes()
            .all(|byte| byte.is_ascii_digit() || (b'a'..=b'f').contains(&byte))
}

fn require_lower_hex_256(label: &str, value: &str) -> Result<()> {
    if !valid_lower_hex_256(value) {
        bail!("{label} must be lowercase 0x-prefixed 256-bit hex");
    }
    Ok(())
}

fn parse_lower_hex_256_limbs(label: &str, value: &str) -> Result<[u64; 4]> {
    require_lower_hex_256(label, value)?;
    let encoded = &value[2..];
    let mut limbs = [0_u64; 4];
    for (limb_index, limb) in limbs.iter_mut().enumerate() {
        let end = encoded.len() - limb_index * 16;
        let start = end - 16;
        *limb = u64::from_str_radix(&encoded[start..end], 16)
            .with_context(|| format!("parsing {label} limb {limb_index}"))?;
    }
    Ok(limbs)
}

fn raw_limbs(hash: Hash) -> [u64; 4] {
    let raw = RawValue::from(hash);
    [raw.0[0].0, raw.0[1].0, raw.0[2].0, raw.0[3].0]
}

fn u256_lte(lhs: [u64; 4], rhs: [u64; 4]) -> bool {
    for index in (0..4).rev() {
        if lhs[index] != rhs[index] {
            return lhs[index] < rhs[index];
        }
    }
    true
}

fn target_raw_value(top_limb: u64) -> RawValue {
    RawValue([F(0), F(0), F(0), F(top_limb)])
}

fn raw_value_string(raw: RawValue) -> String {
    hash_string(Hash::from(raw))
}

fn route_expected_object<'a>(
    expected: &'a ExpectedRouteObjects,
    class: &str,
) -> Option<&'a ExpectedRouteObject> {
    if class_matches(class, "sector") {
        Some(&expected.sector)
    } else if class_matches(class, "celestial_signal") {
        Some(&expected.celestial_signal)
    } else if class_matches(class, "celestial_body") {
        Some(&expected.celestial_body)
    } else if class_matches(class, "life_signal") {
        expected.life_signal.as_ref()
    } else if class_matches(class, "civilization") {
        expected.civilization.as_ref()
    } else {
        None
    }
}

fn route_action_counts(actions: &[String]) -> BTreeMap<String, u64> {
    actions.iter().fold(BTreeMap::new(), |mut counts, action| {
        *counts.entry(action.clone()).or_default() += 1;
        counts
    })
}

fn append_repeated_action(actions: &mut Vec<String>, action: &str, count: u64) -> Result<()> {
    let count = usize::try_from(count).context("route repetition count exceeds usize")?;
    actions.reserve(count);
    for _ in 0..count {
        actions.push(action.to_string());
    }
    Ok(())
}

fn canonical_route_actions(
    point: &RoutePoint,
    candidate: &RouteCandidate,
    survey_action: &str,
    civilization_action: Option<&str>,
    max_action_cost: u64,
) -> Result<(Vec<String>, RouteNavigation)> {
    if max_action_cost > ROUTE_ACTION_COST_HARD_LIMIT {
        bail!(
            "descriptor max_action_cost exceeds hard safety limit {ROUTE_ACTION_COST_HARD_LIMIT}"
        );
    }
    if !(0 < point.x && point.x < ROUTE_COORD_UPPER_BOUND)
        || !(0 < point.y && point.y < ROUTE_COORD_UPPER_BOUND)
        || !(0 < point.z && point.z < ROUTE_COORD_UPPER_BOUND)
        || !(0 < point.epoch && point.epoch < ROUTE_EPOCH_UPPER_BOUND)
    {
        bail!("route point is outside the canonical coordinate or epoch domain");
    }
    let dx = point
        .x
        .checked_sub(DIRECT_COORD_ZERO)
        .context("route x displacement overflow")?;
    let dy = point
        .y
        .checked_sub(DIRECT_COORD_ZERO)
        .context("route y displacement overflow")?;
    let dz = point
        .z
        .checked_sub(DIRECT_COORD_ZERO)
        .context("route z displacement overflow")?;
    if point.epoch < 0 {
        bail!("canonical Small route cannot reach a negative epoch");
    }
    if candidate.code < 0 {
        bail!("candidate code cannot be negative");
    }
    if !matches!(
        survey_action,
        "SurveySector_01_Sparse"
            | "SurveySector_02_Standard"
            | "SurveySector_03_Rich"
            | "SurveySector_04_Ancient"
            | "SurveySector_05_Anomalous"
    ) {
        bail!("unsupported SurveySector action in canonical route");
    }
    let x_moves = dx.unsigned_abs();
    let y_moves = dy.unsigned_abs();
    let z_moves = dz.unsigned_abs();
    let spatial_move_count = x_moves
        .checked_add(y_moves)
        .and_then(|count| count.checked_add(z_moves))
        .context("spatial route length overflow")?;
    if spatial_move_count == 0 {
        bail!("scanner route excludes zero spatial displacement");
    }
    let timewarp_count = u64::try_from(point.epoch).context("negative route epoch")?;
    if let Some(action) = civilization_action {
        if civilization_type_spec(action).is_none() {
            bail!("unsupported Civilization type action in canonical route");
        }
    }
    let fixed_action_cost = if civilization_action.is_some() {
        7_u64
    } else {
        5_u64
    };
    let total_action_cost = fixed_action_cost
        .checked_add(spatial_move_count)
        .and_then(|cost| cost.checked_add(timewarp_count))
        .context("route action cost overflow")?;
    if total_action_cost > max_action_cost {
        bail!(
            "canonical route cost {total_action_cost} exceeds descriptor max_action_cost {max_action_cost}"
        );
    }
    let suffix = format!("{:02}_{}", candidate.code, candidate.slug);
    let mut actions = vec!["BuildShipSmall".to_string()];
    append_repeated_action(
        &mut actions,
        if dx < 0 {
            "MoveNegativeX"
        } else {
            "MovePositiveX"
        },
        x_moves,
    )?;
    append_repeated_action(
        &mut actions,
        if dy < 0 {
            "MoveNegativeY"
        } else {
            "MovePositiveY"
        },
        y_moves,
    )?;
    append_repeated_action(
        &mut actions,
        if dz < 0 {
            "MoveNegativeZ"
        } else {
            "MovePositiveZ"
        },
        z_moves,
    )?;
    append_repeated_action(&mut actions, "TimeWarpSmall", timewarp_count)?;
    actions.extend([
        "ClaimSector".to_string(),
        survey_action.to_string(),
        format!("DetectCelestialSignal_{suffix}"),
        format!("ScanCelestialBody_{suffix}"),
    ]);
    if let Some(civilization_action) = civilization_action {
        actions.extend([
            "DetectIntelligentLife".to_string(),
            civilization_action.to_string(),
        ]);
    }
    Ok((
        actions,
        RouteNavigation {
            dx,
            dy,
            dz,
            spatial_move_count,
            timewarp_count,
        },
    ))
}

#[derive(Deserialize)]
struct RouteBodyBank {
    body_bank_version: u64,
    candidate_count: u64,
    candidates: Vec<RouteCandidate>,
}

fn validate_qualification_shape(
    label: &str,
    check: &RouteQualificationCheck,
    expected_value: &str,
    target_top_limb: u64,
) -> Result<()> {
    let value_limbs =
        parse_lower_hex_256_limbs(&format!("{label}.value_raw_u256"), &check.value_raw_u256)?;
    let encoded_target_limbs =
        parse_lower_hex_256_limbs(&format!("{label}.target_raw_u256"), &check.target_raw_u256)?;
    let target_limbs = [0, 0, 0, target_top_limb];
    if check.input
        != if label == "celestial_signal" {
            "complete_post_stable_identifier_celestial_signal"
        } else {
            "life_signal.stable_identifier"
        }
    {
        bail!("{label} qualification input description mismatch");
    }
    if check.comparison != "full_four_limb_u256_lte_most_significant_limb_first" {
        bail!("{label} qualification comparison description mismatch");
    }
    if check.value_raw_u256 != expected_value {
        bail!("{label} qualification value does not match expected object commitment");
    }
    if check.value_limbs_le != value_limbs {
        bail!("{label} qualification value limbs do not encode value_raw_u256");
    }
    if check.target_top_limb != target_top_limb
        || check.target_limbs_le != target_limbs
        || encoded_target_limbs != target_limbs
        || check.target_raw_u256 != raw_value_string(target_raw_value(target_top_limb))
    {
        bail!("{label} qualification target mismatch");
    }
    let exact_passes = u256_lte(value_limbs, target_limbs);
    if check.passes != exact_passes || !exact_passes {
        bail!("{label} descriptor exact U256 qualification result mismatch");
    }
    Ok(())
}

fn validate_expected_creation(
    label: &str,
    expected: &ExpectedRouteObject,
    created_by_action: &str,
) -> Result<()> {
    if expected.created_by_action != created_by_action {
        bail!(
            "{label} created_by_action mismatch: expected {created_by_action}, descriptor has {}",
            expected.created_by_action
        );
    }
    if expected.commitment_stage != ROUTE_COMMITMENT_STAGE {
        bail!("{label} commitment_stage mismatch");
    }
    require_lower_hex_256(
        &format!("{label}.initial_stable_identifier"),
        &expected.initial_stable_identifier,
    )?;
    require_lower_hex_256(
        &format!("{label}.full_object_commitment"),
        &expected.full_object_commitment,
    )
}

fn validate_lifecycle_route_descriptor(
    plugin_root: &Path,
    module: &sdk::SdkModule,
    descriptor: &LifecycleRouteDescriptor,
    target_real_action: &str,
) -> Result<JsonValue> {
    if descriptor.schema_version != 1
        || descriptor.kind != ROUTE_DESCRIPTOR_KIND
        || descriptor.status != "found"
        || !descriptor.descriptor_only
        || descriptor.descriptor_notice.trim().is_empty()
    {
        bail!("unsupported or incomplete lifecycle route descriptor header");
    }
    require_lower_hex_256("module_hash", &descriptor.module_hash)?;
    let actual_module_hash = hash_string(module.module().batch.id());
    if descriptor.module_hash != actual_module_hash {
        bail!(
            "descriptor module hash mismatch: expected {}, loaded {actual_module_hash}",
            descriptor.module_hash
        );
    }

    let expected_class_names = ROUTE_CLASS_NAMES
        .iter()
        .map(|name| (*name).to_string())
        .collect::<HashSet<_>>();
    let descriptor_class_names = descriptor
        .class_hashes
        .keys()
        .cloned()
        .collect::<HashSet<_>>();
    if descriptor_class_names != expected_class_names {
        bail!("descriptor class hash map must contain exactly the eight canonical classes");
    }
    let mut actual_class_hashes = BTreeMap::new();
    for class in ROUTE_CLASS_NAMES {
        let descriptor_hash = descriptor
            .class_hashes
            .get(*class)
            .context("missing descriptor class hash")?;
        require_lower_hex_256(&format!("class_hashes.{class}"), descriptor_hash)?;
        let actual_hash = module
            .class_hash(class)
            .with_context(|| format!("loaded module is missing class {class}"))?;
        let actual_hash = hash_string(actual_hash);
        if descriptor_hash != &actual_hash {
            bail!("descriptor class hash mismatch for {class}");
        }
        actual_class_hashes.insert((*class).to_string(), actual_hash);
    }

    let target_occurrences =
        exact_action_occurrences(&descriptor.route.actions, target_real_action);
    let loaded_actions = module
        .actions()
        .iter()
        .map(|action| action.name.as_str())
        .collect::<HashSet<_>>();
    for action in &descriptor.route.actions {
        if !loaded_actions.contains(action.as_str()) {
            bail!("descriptor route contains unknown action {action}");
        }
    }

    if descriptor.search.candidate_code != descriptor.candidate.code {
        bail!("descriptor search candidate_code does not match candidate record");
    }
    if descriptor.search.points_tested == 0 {
        bail!("descriptor search must test at least one distinct producer point");
    }
    if descriptor.search.minimum_epoch < 1
        || descriptor.point.epoch < descriptor.search.minimum_epoch
    {
        bail!("descriptor search minimum_epoch is invalid or unmet");
    }
    let civilization_route = match descriptor.search.requirement.as_str() {
        "materializable" => false,
        "civilization" => true,
        other => bail!("unsupported descriptor search requirement {other}"),
    };
    let expected_ordering = RouteOrdering {
        primary: "action_cost_ascending".to_string(),
        tie_breakers: vec![
            "epoch_ascending".to_string(),
            "dx_ascending".to_string(),
            "dy_ascending".to_string(),
            "dz_ascending".to_string(),
        ],
        spatial_metric: "manhattan_distance".to_string(),
        zero_displacement_policy: "excluded".to_string(),
    };
    if descriptor.search.ordering != expected_ordering {
        bail!("descriptor search ordering mismatch");
    }
    let fixed_action_cost = if civilization_route { 7 } else { 5 };
    if descriptor.search.minimum_possible_action_cost != fixed_action_cost + 2
        || !descriptor.search.seconds.is_finite()
        || descriptor.search.seconds < 0.0
    {
        bail!("descriptor search cost floor or elapsed time mismatch");
    }

    let body_bank_path = plugin_root.join("generated/body-bank.json");
    let body_bank: RouteBodyBank = serde_json::from_str(
        &fs::read_to_string(&body_bank_path)
            .with_context(|| format!("reading {}", body_bank_path.display()))?,
    )
    .with_context(|| format!("parsing {}", body_bank_path.display()))?;
    if descriptor.body_bank.source != "generated/body-bank.json"
        || descriptor.body_bank.body_bank_version != 1
        || body_bank.body_bank_version != 1
        || descriptor.body_bank.body_bank_version != body_bank.body_bank_version
        || descriptor.body_bank.candidate_count != body_bank.candidate_count
        || body_bank.candidate_count
            != u64::try_from(body_bank.candidates.len())
                .context("body-bank candidate count exceeds u64")?
    {
        bail!("descriptor body-bank metadata mismatch");
    }
    let matching_candidates = body_bank
        .candidates
        .iter()
        .filter(|candidate| candidate.code == descriptor.candidate.code)
        .collect::<Vec<_>>();
    if matching_candidates.len() != 1 || matching_candidates[0] != &descriptor.candidate {
        bail!("descriptor candidate record does not exactly match generated body-bank.json");
    }

    let has_life_objects = descriptor.expected_objects.life_signal.is_some()
        && descriptor.expected_objects.civilization.is_some();
    if descriptor.expected_objects.life_signal.is_some()
        != descriptor.expected_objects.civilization.is_some()
        || has_life_objects != civilization_route
        || descriptor.qualification.life_signal.is_some() != civilization_route
    {
        bail!("descriptor requirement, life objects, and life qualification disagree");
    }
    if civilization_route
        && (descriptor.candidate.body_type != 1 || descriptor.candidate.life_stat <= 0)
    {
        bail!("civilization descriptor candidate is not a living planet");
    }

    let survey_actions = descriptor
        .route
        .actions
        .iter()
        .filter(|action| action.starts_with("SurveySector_"))
        .collect::<Vec<_>>();
    if survey_actions.len() != 1 {
        bail!("descriptor route must contain exactly one SurveySector action");
    }
    let civilization_actions = descriptor
        .route
        .actions
        .iter()
        .filter(|action| civilization_type_spec(action).is_some())
        .map(String::as_str)
        .collect::<Vec<_>>();
    if civilization_actions.len() != usize::from(civilization_route) {
        bail!("descriptor route has the wrong number of Civilization type actions");
    }
    let civilization_action = civilization_actions.first().copied();
    let (canonical_actions, canonical_navigation) = canonical_route_actions(
        &descriptor.point,
        &descriptor.candidate,
        survey_actions[0],
        civilization_action,
        descriptor.search.max_action_cost,
    )?;
    if descriptor.route.actions != canonical_actions {
        bail!("descriptor action route is not the canonical producer-derived Small route");
    }
    let action_count =
        u64::try_from(descriptor.route.actions.len()).context("route action count overflow")?;
    if descriptor.route.action_count != action_count
        || descriptor.route.action_cost != action_count
        || descriptor.route.cost_model != "one_unit_per_action"
        || descriptor.route.action_cost > descriptor.search.max_action_cost
        || descriptor.route.action_counts != route_action_counts(&descriptor.route.actions)
    {
        bail!("descriptor route count, cost, or action_counts mismatch");
    }
    if descriptor.route.navigation != canonical_navigation {
        bail!("descriptor navigation summary mismatch");
    }
    let start = RoutePoint {
        x: DIRECT_COORD_ZERO,
        y: DIRECT_COORD_ZERO,
        z: DIRECT_COORD_ZERO,
        epoch: 0,
    };
    if descriptor.route.coordinate_validation.start != start
        || descriptor.route.coordinate_validation.source != "action_counts"
        || descriptor.route.coordinate_validation.derived_final != descriptor.point
        || descriptor.route.coordinate_validation.expected_final != descriptor.point
        || !descriptor.route.coordinate_validation.pass
    {
        bail!("descriptor coordinate validation mismatch");
    }

    let suffix = format!(
        "{:02}_{}",
        descriptor.candidate.code, descriptor.candidate.slug
    );
    let detect_action = format!("DetectCelestialSignal_{suffix}");
    let materialize_action = format!("ScanCelestialBody_{suffix}");
    validate_expected_creation("sector", &descriptor.expected_objects.sector, "ClaimSector")?;
    validate_expected_creation(
        "celestial_signal",
        &descriptor.expected_objects.celestial_signal,
        &detect_action,
    )?;
    validate_expected_creation(
        "celestial_body",
        &descriptor.expected_objects.celestial_body,
        &materialize_action,
    )?;
    if let Some(expected) = &descriptor.expected_objects.life_signal {
        validate_expected_creation("life_signal", expected, "DetectIntelligentLife")?;
    }
    if let Some(expected) = &descriptor.expected_objects.civilization {
        validate_expected_creation(
            "civilization",
            expected,
            civilization_action.context("missing Civilization type action")?,
        )?;
    }

    let candidate_target = u64::try_from(descriptor.candidate.target_top_limb)
        .context("candidate target_top_limb must be nonnegative")?;
    validate_qualification_shape(
        "celestial_signal",
        &descriptor.qualification.celestial_signal,
        &descriptor
            .expected_objects
            .celestial_signal
            .full_object_commitment,
        candidate_target,
    )?;
    if let Some(check) = &descriptor.qualification.life_signal {
        validate_qualification_shape(
            "life_signal",
            check,
            &descriptor
                .expected_objects
                .life_signal
                .as_ref()
                .context("missing expected LifeSignal")?
                .initial_stable_identifier,
            CIVILIZATION_TARGET_TOP_LIMB,
        )?;
    }
    if target_occurrences != 1 {
        bail!(
            "lifecycle-route requires exactly one occurrence of target action {target_real_action}; found {target_occurrences}"
        );
    }

    Ok(json!({
        "status": "pass",
        "schema_version": descriptor.schema_version,
        "kind": descriptor.kind,
        "module_hash": descriptor.module_hash,
        "actual_module_hash": actual_module_hash,
        "class_hashes": actual_class_hashes,
        "candidate_code": descriptor.candidate.code,
        "candidate_slug": descriptor.candidate.slug,
        "point": {
            "x": descriptor.point.x,
            "y": descriptor.point.y,
            "z": descriptor.point.z,
            "epoch": descriptor.point.epoch,
        },
        "canonical_route_match": true,
        "body_bank_candidate_exact_match": true,
        "target_real_action_route_occurrences": target_occurrences,
    }))
}

fn qualification_observation(
    label: &str,
    object: &SpendableObject,
    check: &RouteQualificationCheck,
    target_top_limb: u64,
) -> Result<JsonValue> {
    let selector = if label == "life_signal" {
        Hash::from(object_field(object, "stable_identifier")?.raw())
    } else {
        object.obj.commitment()
    };
    let value_limbs = raw_limbs(selector);
    let target_limbs = [0, 0, 0, target_top_limb];
    let value_raw = hash_string(selector);
    let target_raw = raw_value_string(target_raw_value(target_top_limb));
    let passes = u256_lte(value_limbs, target_limbs);
    let descriptor_match = check.value_raw_u256 == value_raw
        && check.value_limbs_le == value_limbs
        && check.target_raw_u256 == target_raw
        && check.target_limbs_le == target_limbs
        && check.target_top_limb == target_top_limb
        && check.passes == passes;
    if !descriptor_match {
        bail!("{label} runtime qualification does not match descriptor");
    }
    if !passes {
        bail!("{label} is above its exact U256 threshold");
    }
    Ok(json!({
        "status": "pass",
        "label": label,
        "input": check.input,
        "value_raw_u256": value_raw,
        "value_limbs_le": value_limbs,
        "target_raw_u256": target_raw,
        "target_limbs_le": target_limbs,
        "target_top_limb": target_top_limb,
        "comparison_order": "limb_3_to_limb_0",
        "passes": passes,
        "descriptor_exact_match": descriptor_match,
    }))
}

fn materializer_qualification_preflight(
    action_name: &str,
    inventory: &[LiveObject],
    descriptor: &LifecycleRouteDescriptor,
) -> Result<Option<JsonValue>> {
    if action_name.starts_with("ScanCelestialBody_") {
        let (_, signal) = unique_inventory_object(inventory, "celestial_signal")?;
        let target = u64::try_from(descriptor.candidate.target_top_limb)
            .context("candidate target_top_limb must be nonnegative")?;
        qualification_observation(
            "celestial_signal",
            signal,
            &descriptor.qualification.celestial_signal,
            target,
        )
        .map(Some)
    } else if let Some(civilization_type) = civilization_type_spec(action_name) {
        let (_, signal) = unique_inventory_object(inventory, "life_signal")?;
        let check = descriptor
            .qualification
            .life_signal
            .as_ref()
            .context("descriptor lacks LifeSignal qualification")?;
        let stable_identifier = object_field(signal, "stable_identifier")?;
        let selector = RawValue::from(stable_identifier.raw());
        let lower = target_raw_value(civilization_type.lower);
        let upper = target_raw_value(civilization_type.upper);
        if selector < lower || selector > upper {
            bail!(
                "LifeSignal stable_identifier is outside the {} rarity band",
                civilization_type.action
            );
        }
        qualification_observation("life_signal", signal, check, CIVILIZATION_TARGET_TOP_LIMB)
            .map(Some)
    } else {
        Ok(None)
    }
}

fn route_identity_report(
    phase: &str,
    class: &str,
    object: &SpendableObject,
    expected: &ExpectedRouteObject,
    require_full_commitment: bool,
) -> Result<(JsonValue, bool)> {
    let stable_identifier = exact_raw_string(&object_field(object, "stable_identifier")?);
    let commitment = hash_string(object.obj.commitment());
    let stable_matches = stable_identifier == expected.initial_stable_identifier;
    let full_matches = commitment == expected.full_object_commitment;
    let passes = stable_matches && (!require_full_commitment || full_matches);
    Ok((
        json!({
            "status": if passes { "pass" } else { "fail" },
            "phase": phase,
            "class": class,
            "stable_identifier": stable_identifier,
            "expected_stable_identifier": expected.initial_stable_identifier,
            "stable_identifier_matches": stable_matches,
            "full_object_commitment": commitment,
            "expected_creation_commitment": expected.full_object_commitment,
            "full_creation_commitment_required": require_full_commitment,
            "full_creation_commitment_matches": full_matches,
        }),
        passes,
    ))
}

fn creation_semantics_report(
    class: &str,
    object: &SpendableObject,
    descriptor: &LifecycleRouteDescriptor,
) -> Result<(JsonValue, bool)> {
    let mut assertions = BTreeMap::new();
    let point = &descriptor.point;
    if class_matches(class, "sector") {
        bool_assertion(&mut assertions, "x", object_int(object, "x")? == point.x);
        bool_assertion(&mut assertions, "y", object_int(object, "y")? == point.y);
        bool_assertion(&mut assertions, "z", object_int(object, "z")? == point.z);
        bool_assertion(
            &mut assertions,
            "epoch",
            object_int(object, "epoch")? == point.epoch,
        );
        bool_assertion(
            &mut assertions,
            "sector_type_at_creation",
            object_int(object, "sector_type")? == 0,
        );
        bool_assertion(
            &mut assertions,
            "survey_profile_at_creation",
            object_int(object, "survey_profile")? == 0,
        );
        bool_assertion(
            &mut assertions,
            "revision_at_creation",
            object_int(object, "revision")? == 0,
        );
    } else {
        bool_assertion(
            &mut assertions,
            "sector_x",
            object_int(object, "sector_x")? == point.x,
        );
        bool_assertion(
            &mut assertions,
            "sector_y",
            object_int(object, "sector_y")? == point.y,
        );
        bool_assertion(
            &mut assertions,
            "sector_z",
            object_int(object, "sector_z")? == point.z,
        );
        let epoch_field =
            if class_matches(class, "celestial_signal") || class_matches(class, "celestial_body") {
                "sector_epoch"
            } else {
                "origin_epoch"
            };
        bool_assertion(
            &mut assertions,
            epoch_field,
            object_int(object, epoch_field)? == point.epoch,
        );
    }
    if class_matches(class, "celestial_signal") || class_matches(class, "celestial_body") {
        bool_assertion(
            &mut assertions,
            "candidate_code",
            object_int(object, "candidate_code")? == descriptor.candidate.code,
        );
    }
    if class_matches(class, "celestial_body") {
        for (field, expected) in [
            ("body_type", descriptor.candidate.body_type),
            ("life_stat", descriptor.candidate.life_stat),
            ("matter_remaining", descriptor.candidate.matter),
            ("crystal_remaining", descriptor.candidate.crystal),
            ("gas_remaining", descriptor.candidate.gas),
            ("energy_remaining", descriptor.candidate.energy),
            ("satellites_remaining", descriptor.candidate.satellites),
        ] {
            bool_assertion(
                &mut assertions,
                field,
                object_int(object, field)? == expected,
            );
        }
    }
    let passes = assertions.values().all(|value| *value);
    Ok((
        json!({
            "status": if passes { "pass" } else { "fail" },
            "class": class,
            "assertions": assertions,
        }),
        passes,
    ))
}

fn full_creation_commitment_required_before(action_name: &str, class: &str) -> bool {
    (action_name.starts_with("SurveySector_") && class_matches(class, "sector"))
        || (action_name.starts_with("ScanCelestialBody_")
            && class_matches(class, "celestial_signal"))
        || (action_name == "DetectIntelligentLife" && class_matches(class, "celestial_body"))
        || (civilization_type_spec(action_name).is_some() && class_matches(class, "life_signal"))
}

fn descriptor_stage_evidence(
    action_name: &str,
    step: &AuditStep,
    descriptor: &LifecycleRouteDescriptor,
) -> Result<(JsonValue, bool)> {
    let mut input_checks = Vec::new();
    let mut output_checks = Vec::new();
    let mut creation_checks = Vec::new();
    let mut all_pass = true;

    for (class, object) in step.input_classes.iter().zip(&step.inputs) {
        if let Some(expected) = route_expected_object(&descriptor.expected_objects, class) {
            let (report, passes) = route_identity_report(
                "before_action",
                class,
                object,
                expected,
                full_creation_commitment_required_before(action_name, class),
            )?;
            all_pass &= passes;
            input_checks.push(report);
        }
    }
    for (class, object) in step.output_classes.iter().zip(&step.outputs.objs) {
        if let Some(expected) = route_expected_object(&descriptor.expected_objects, class) {
            let is_creation = expected.created_by_action == action_name;
            let (identity, identity_passes) =
                route_identity_report("after_action", class, object, expected, is_creation)?;
            all_pass &= identity_passes;
            output_checks.push(identity);
            if is_creation {
                let (semantics, semantics_pass) =
                    creation_semantics_report(class, object, descriptor)?;
                all_pass &= semantics_pass;
                let qualification = if class_matches(class, "celestial_signal") {
                    let target = u64::try_from(descriptor.candidate.target_top_limb)
                        .context("candidate target_top_limb must be nonnegative")?;
                    Some(qualification_observation(
                        "celestial_signal",
                        object,
                        &descriptor.qualification.celestial_signal,
                        target,
                    )?)
                } else if class_matches(class, "life_signal") {
                    Some(qualification_observation(
                        "life_signal",
                        object,
                        descriptor
                            .qualification
                            .life_signal
                            .as_ref()
                            .context("descriptor lacks LifeSignal qualification")?,
                        CIVILIZATION_TARGET_TOP_LIMB,
                    )?)
                } else {
                    None
                };
                creation_checks.push(json!({
                    "class": class,
                    "created_by_action": action_name,
                    "commitment_stage": ROUTE_COMMITMENT_STAGE,
                    "identity": output_checks.last(),
                    "semantic_binding": semantics,
                    "qualification": qualification,
                }));
            }
        }
    }

    Ok((
        json!({
            "status": if all_pass { "pass" } else { "fail" },
            "input_identity_checks": input_checks,
            "output_identity_checks": output_checks,
            "creation_checkpoints": creation_checks,
        }),
        all_pass,
    ))
}

fn execute_sequence(
    plugin_root: &Path,
    actions: Vec<String>,
    output: Option<PathBuf>,
    real: bool,
    target_real: bool,
) -> Result<()> {
    if actions.is_empty() {
        bail!("sequence requires at least one action");
    }
    if real && target_real {
        bail!("--real and --target-real are mutually exclusive");
    }
    let (_source, module) = load_module(plugin_root)?;
    let mut state = TestState::default();
    let mut inventory: Vec<LiveObject> = Vec::new();
    let mut globally_created: HashSet<Hash> = HashSet::new();
    let mut globally_nullified: HashSet<Hash> = HashSet::new();
    let mut action_counts: BTreeMap<String, usize> = BTreeMap::new();
    let mut step_reports = Vec::new();
    let started = Instant::now();
    let mut worst_payload = 0;
    let mut max_live = 0;
    let mut max_nullifiers = 0;
    let mut all_payloads_fit = true;
    let mut failed_payload_actions = Vec::new();
    let mut real_step_count = 0_usize;
    let mut lifecycle_audited_step_count = 0_usize;
    let mut all_lifecycle_assertions_pass = true;
    let mut failed_lifecycle_actions = Vec::new();
    let mut latest_ship_commitment: Option<Hash> = None;
    let mut latest_ship_chain_checked_step_count = 0_usize;
    let mut all_latest_ship_chain_assertions_pass = true;
    let mut failed_latest_ship_chain_actions = Vec::new();

    for (step_index, action_name) in actions.iter().enumerate() {
        println!(
            "sequence step {}/{}: {}",
            step_index + 1,
            actions.len(),
            action_name
        );
        let step_real = real || (target_real && step_index + 1 == actions.len());
        if step_real {
            real_step_count += 1;
        }
        let metadata = module
            .actions()
            .iter()
            .find(|action| action.name == *action_name)
            .ok_or_else(|| anyhow!("unknown action {action_name}"))?;
        let input_classes: Vec<String> = metadata
            .total_inputs()
            .map(|object| object.class.clone())
            .collect();
        let output_classes: Vec<String> = metadata
            .total_outputs()
            .map(|object| object.class.clone())
            .collect();
        let selection_hint = if action_name == "UseTechnologySkill" {
            actions
                .get(step_index + 1)
                .map(String::as_str)
                .unwrap_or(action_name)
        } else {
            action_name.as_str()
        };
        let (inputs, selected_indices) =
            select_inputs_for_action(&inventory, &input_classes, selection_hint)?;
        let witness = grounding_witness(&state, &inputs);
        let state_root = witness.state_header.hash();
        let planning_started = Instant::now();
        let plan = module
            .executor(true, witness.clone())
            .plan_action(action_name, inputs.clone())
            .with_context(|| format!("planning step {} ({action_name})", step_index + 1))?;
        let planning_seconds = planning_started.elapsed().as_secs_f64();
        let solution = plan.solved.solution();
        let execution_started = Instant::now();
        let outputs = module
            .executor(!step_real, witness)
            .action(action_name, inputs.clone())
            .with_context(|| format!("executing step {} ({action_name})", step_index + 1))?;
        let execution_seconds = execution_started.elapsed().as_secs_f64();
        if outputs.objs.len() != output_classes.len() {
            bail!("output metadata mismatch for {action_name}");
        }
        let payload = structural_payload(&outputs, state_root, step_real)?;
        worst_payload = worst_payload.max(payload.payload_bytes);
        max_live = max_live.max(payload.live_count);
        max_nullifiers = max_nullifiers.max(payload.nullifier_count);
        all_payloads_fit &= payload.fits_hard_limit;
        if !payload.fits_hard_limit {
            failed_payload_actions.push(action_name.clone());
        }

        let live_commitments = outputs.tx.live_commitments()?;
        let nullifiers = outputs.tx.nullifier_hashes()?;
        let ship_input_commitments = input_classes
            .iter()
            .zip(&inputs)
            .filter(|(class, _)| class_matches(class, "spaceship"))
            .map(|(_, object)| object.obj.commitment())
            .collect::<Vec<_>>();
        let ship_output_commitments = output_classes
            .iter()
            .zip(&outputs.objs)
            .filter(|(class, _)| class_matches(class, "spaceship"))
            .map(|(_, object)| object.obj.commitment())
            .collect::<Vec<_>>();
        let preferred_ship_output_commitment = output_classes
            .iter()
            .zip(&outputs.objs)
            .filter(|(class, _)| class_matches(class, "spaceship"))
            .max_by_key(|(_, object)| object_int(object, "extraction_amount").unwrap_or(0))
            .map(|(_, object)| object.obj.commitment());
        let prior_latest_ship_commitment = latest_ship_commitment;
        let (ship_chain_shape_pass, ship_input_is_latest, next_latest_ship_commitment) = match (
            ship_input_commitments.as_slice(),
            ship_output_commitments.as_slice(),
            prior_latest_ship_commitment,
        ) {
            ([], [output], None) => (true, true, Some(*output)),
            ([], [_output, ..], Some(_expected)) => (true, true, preferred_ship_output_commitment),
            ([input], [_output, ..], Some(expected)) => {
                latest_ship_chain_checked_step_count += 1;
                (true, *input == expected, preferred_ship_output_commitment)
            }
            ([], [], prior) => (true, true, prior),
            _ => (false, false, prior_latest_ship_commitment),
        };
        let ship_output_is_declared_live = ship_output_commitments
            .iter()
            .all(|commitment| live_commitments.contains(commitment));
        let lifecycle_audit = audit_sequence_lifecycle_step(
            action_name,
            &input_classes,
            &inputs,
            &output_classes,
            &outputs.objs,
            &live_commitments,
            &nullifiers,
        )?;
        let lifecycle_audit_report = if let Some((report, passes)) = lifecycle_audit {
            lifecycle_audited_step_count += 1;
            all_lifecycle_assertions_pass &= passes;
            if !passes {
                failed_lifecycle_actions.push(action_name.clone());
            }
            report
        } else {
            json!({
                "status": "not_applicable",
                "reason": "action is not a refactored Ship-gated lifecycle family or candidate materializer",
            })
        };
        let selected_input_commitments = inputs
            .iter()
            .map(|input| hash_string(input.obj.commitment()))
            .collect::<Vec<_>>();
        let selected_input_nullifiers = inputs
            .iter()
            .map(|input| hash_string(compute_nullifier(&input.obj)))
            .collect::<Vec<_>>();
        let output_object_commitments = outputs
            .objs
            .iter()
            .map(|object| hash_string(object.obj.commitment()))
            .collect::<Vec<_>>();
        let selected_input_identity = input_classes
            .iter()
            .zip(&inputs)
            .map(|(class, object)| {
                Ok(json!({
                    "class": class,
                    "commitment": hash_string(object.obj.commitment()),
                    "nullifier": hash_string(compute_nullifier(&object.obj)),
                    "stable_identifier": exact_raw_string(&object_field(object, "stable_identifier")?),
                }))
            })
            .collect::<Result<Vec<_>>>()?;
        let output_identity = output_classes
            .iter()
            .zip(&outputs.objs)
            .map(|(class, object)| {
                Ok(json!({
                    "class": class,
                    "commitment": hash_string(object.obj.commitment()),
                    "stable_identifier": exact_raw_string(&object_field(object, "stable_identifier")?),
                }))
            })
            .collect::<Result<Vec<_>>>()?;
        let input_object_reports = class_object_reports(&input_classes, &inputs)?;
        let output_object_reports = class_object_reports(&output_classes, &outputs.objs)?;
        let reused_nullifiers = nullifiers
            .iter()
            .filter(|nullifier| globally_nullified.contains(nullifier))
            .map(|nullifier| hash_string(*nullifier))
            .collect::<Vec<_>>();
        if !reused_nullifiers.is_empty() {
            bail!(
                "synchronizer-style nullifier reuse at step {} ({action_name}): {:?}",
                step_index + 1,
                reused_nullifiers
            );
        }
        let duplicate_commitments: Vec<String> = live_commitments
            .iter()
            .filter(|commitment| globally_created.contains(commitment))
            .map(|commitment| hash_string(*commitment))
            .collect();
        if !duplicate_commitments.is_empty() {
            bail!(
                "synchronizer-style creation collision at step {} ({action_name}): {:?}",
                step_index + 1,
                duplicate_commitments
            );
        }
        globally_created.extend(live_commitments.iter().copied());
        globally_nullified.extend(nullifiers.iter().copied());
        state.apply_tx(live_commitments.iter().copied(), nullifiers.iter().copied());

        for index in descending_unique_indices(&selected_indices) {
            inventory.remove(index);
        }
        for (class, object) in output_classes.iter().zip(outputs.objs.iter()) {
            inventory.push(LiveObject {
                class: class.clone(),
                object: object.clone(),
            });
        }
        let live_inventory_ship_commitments = inventory
            .iter()
            .filter(|item| class_matches(&item.class, "spaceship"))
            .map(|item| item.object.obj.commitment())
            .collect::<Vec<_>>();
        let inventory_has_exact_latest_ship = match next_latest_ship_commitment {
            Some(expected) => live_inventory_ship_commitments.contains(&expected),
            None => live_inventory_ship_commitments.is_empty(),
        };
        let ship_chain_step_pass = ship_chain_shape_pass
            && ship_input_is_latest
            && ship_output_is_declared_live
            && inventory_has_exact_latest_ship;
        all_latest_ship_chain_assertions_pass &= ship_chain_step_pass;
        if !ship_chain_step_pass {
            failed_latest_ship_chain_actions.push(action_name.clone());
        }
        latest_ship_commitment = next_latest_ship_commitment;
        let latest_ship_chain_audit = json!({
            "status": if ship_chain_step_pass { "pass" } else { "fail" },
            "prior_latest_ship_commitment": prior_latest_ship_commitment.map(hash_string),
            "ship_input_commitments": ship_input_commitments.iter().copied().map(hash_string).collect::<Vec<_>>(),
            "ship_output_commitments": ship_output_commitments.iter().copied().map(hash_string).collect::<Vec<_>>(),
            "shape_is_single_producer_or_single_transition": ship_chain_shape_pass,
            "ship_input_is_immediately_previous_ship_output": ship_input_is_latest,
            "ship_outputs_are_declared_live": ship_output_is_declared_live,
            "inventory_has_exactly_the_latest_ship_after_step": inventory_has_exact_latest_ship,
            "inventory_ship_commitments_after_step": live_inventory_ship_commitments.iter().copied().map(hash_string).collect::<Vec<_>>(),
            "next_latest_ship_commitment": next_latest_ship_commitment.map(hash_string),
        });
        *action_counts.entry(action_name.clone()).or_default() += 1;

        step_reports.push(json!({
            "step": step_index + 1,
            "action": action_name,
            "proof_mode": if step_real { "real" } else { "mock" },
            "input_classes": input_classes,
            "output_classes": output_classes,
            "selected_input_indices": selected_indices,
            "selected_input_commitments": selected_input_commitments,
            "selected_input_nullifiers": selected_input_nullifiers,
            "selected_input_identity": selected_input_identity,
            "producer_derived_input_objects": input_object_reports,
            "output_object_commitments": output_object_commitments,
            "output_identity": output_identity,
            "producer_derived_output_objects": output_object_reports,
            "transaction_nullifiers": nullifiers.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
            "transaction_live_commitments": live_commitments.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
            "automatic_lifecycle_audit": lifecycle_audit_report,
            "latest_ship_chain_audit": latest_ship_chain_audit,
            "planning_seconds": planning_seconds,
            "execution_seconds": execution_seconds,
            "payload_generation_seconds": payload.seconds,
            "statements": plan.statements.len(),
            "operations": plan.operations.len(),
            "pods": solution.pod_statements.len(),
            "serialized_proof_bytes": payload.serialized_proof_bytes,
            "payload_bytes": payload.payload_bytes,
            "payload_hard_limit_bytes": PAYLOAD_HARD_LIMIT_BYTES,
            "payload_headroom_bytes": payload.headroom_bytes,
            "payload_utilization": payload.utilization,
            "payload_utilization_percent": payload.utilization_percent,
            "payload_fits_hard_limit": payload.fits_hard_limit,
            "live_commitments": payload.live_count,
            "nullifiers": payload.nullifier_count,
            "state_block_after": state.block_number,
        }));
    }

    let inventory_counts = inventory.iter().fold(BTreeMap::new(), |mut counts, item| {
        *counts.entry(item.class.clone()).or_insert(0_usize) += 1;
        counts
    });
    let overall_pass =
        all_lifecycle_assertions_pass && all_latest_ship_chain_assertions_pass && all_payloads_fit;
    let report = json!({
        "status": if overall_pass { "pass" } else { "fail" },
        "mode": if real { "real" } else if target_real { "target-real" } else { "mock" },
        "proof_policy": if real { "all steps real" } else if target_real { "mock producer setup; final target real" } else { "all steps mock" },
        "real_step_count": real_step_count,
        "mock_step_count": actions.len() - real_step_count,
        "input_source": "producer-derived action outputs only",
        "minted_or_hand_edited_fixtures": 0,
        "steps": actions.len(),
        "seconds": started.elapsed().as_secs_f64(),
        "action_counts": action_counts,
        "sampled_step_metrics": step_reports,
        "step_metrics_complete": true,
        "lifecycle_audited_step_count": lifecycle_audited_step_count,
        "all_automatic_lifecycle_assertions_pass": all_lifecycle_assertions_pass,
        "failed_lifecycle_actions": failed_lifecycle_actions,
        "latest_ship_chain_checked_step_count": latest_ship_chain_checked_step_count,
        "all_latest_ship_chain_assertions_pass": all_latest_ship_chain_assertions_pass,
        "failed_latest_ship_chain_actions": failed_latest_ship_chain_actions,
        "latest_ship_commitment": latest_ship_commitment.map(hash_string),
        "final_state_block": state.block_number,
        "final_state_root": hash_string(state_header(&state).hash()),
        "final_inventory": inventory_counts,
        "worst_payload_bytes": worst_payload,
        "payload_hard_limit_bytes": PAYLOAD_HARD_LIMIT_BYTES,
        "worst_payload_headroom_bytes": PAYLOAD_HARD_LIMIT_BYTES as i64 - worst_payload as i64,
        "worst_payload_utilization": worst_payload as f64 / PAYLOAD_HARD_LIMIT_BYTES as f64,
        "worst_payload_utilization_percent": worst_payload as f64 / PAYLOAD_HARD_LIMIT_BYTES as f64 * 100.0,
        "all_payloads_fit_hard_limit": all_payloads_fit,
        "failed_payload_actions": failed_payload_actions,
        "max_live_commitments": max_live,
        "max_nullifiers": max_nullifiers,
        "synchronizer_style_created_collision_checks": globally_created.len(),
        "synchronizer_style_nullifier_reuse_checks": globally_nullified.len(),
    });
    let encoded = serde_json::to_string_pretty(&report)? + "\n";
    if let Some(path) = output {
        fs::write(&path, &encoded).with_context(|| format!("writing {}", path.display()))?;
    }
    println!("{encoded}");
    if !overall_pass {
        bail!(
            "sequence acceptance failed: lifecycle={all_lifecycle_assertions_pass}, latest_ship_chain={all_latest_ship_chain_assertions_pass}, payload_limit={all_payloads_fit}"
        );
    }
    Ok(())
}

fn emit_report(output: Option<&PathBuf>, report: &JsonValue) -> Result<()> {
    let encoded = serde_json::to_string_pretty(report)? + "\n";
    if let Some(path) = output {
        fs::write(path, &encoded).with_context(|| format!("writing {}", path.display()))?;
    }
    println!("{encoded}");
    Ok(())
}

fn execute_lifecycle_route(
    plugin_root: &Path,
    descriptor_path: &Path,
    target_real_action: String,
    output: PathBuf,
) -> Result<()> {
    let descriptor_text = fs::read_to_string(descriptor_path)
        .with_context(|| format!("reading {}", descriptor_path.display()))?;
    let descriptor: LifecycleRouteDescriptor = serde_json::from_str(&descriptor_text)
        .with_context(|| format!("parsing {}", descriptor_path.display()))?;
    let (_source, module) = load_module(plugin_root)?;
    let descriptor_validation = validate_lifecycle_route_descriptor(
        plugin_root,
        &module,
        &descriptor,
        &target_real_action,
    )?;
    let actions = &descriptor.route.actions;
    let mut state = TestState::default();
    let mut inventory = Vec::new();
    let mut globally_created = HashSet::new();
    let mut globally_nullified = HashSet::new();
    let mut step_reports = Vec::new();
    let mut target_real_step_count = 0_usize;
    let mut worst_payload_bytes = 0_usize;
    let mut all_payloads_fit = true;
    let mut all_lifecycle_assertions_pass = true;
    let mut all_descriptor_assertions_pass = true;
    let started = Instant::now();
    let mut qualification_preflights = Vec::new();

    for (step_index, action_name) in actions.iter().enumerate() {
        let qualification_preflight =
            materializer_qualification_preflight(action_name, &inventory, &descriptor)
                .with_context(|| {
                    format!(
                        "exact local threshold preflight before step {} ({action_name})",
                        step_index + 1
                    )
                })?;
        if let Some(preflight) = &qualification_preflight {
            qualification_preflights.push(json!({
                "step": step_index + 1,
                "action": action_name,
                "qualification": preflight,
            }));
        }
        let step_real = action_name == &target_real_action;
        let step = execute_audit_step(&module, &state, &inventory, action_name, step_real)
            .with_context(|| {
                format!(
                    "lifecycle descriptor replay step {} ({action_name})",
                    step_index + 1
                )
            })?;
        let (step_report, lifecycle_pass) = lifecycle_step_evidence(
            step_index + 1,
            action_name,
            step_real,
            state.block_number + 1,
            &step,
        )?;
        let (descriptor_stage, descriptor_pass) =
            descriptor_stage_evidence(action_name, &step, &descriptor)?;
        all_lifecycle_assertions_pass &= lifecycle_pass;
        all_descriptor_assertions_pass &= descriptor_pass;
        if !lifecycle_pass || !descriptor_pass {
            bail!(
                "lifecycle or descriptor assertions failed at step {} ({action_name})",
                step_index + 1
            );
        }
        worst_payload_bytes = worst_payload_bytes.max(step.payload.payload_bytes);
        all_payloads_fit &= step.payload.fits_hard_limit;
        apply_audit_step(
            &mut state,
            &mut inventory,
            &mut globally_created,
            &mut globally_nullified,
            &step,
        )?;
        if step_real {
            target_real_step_count += 1;
        }
        step_reports.push(json!({
            "step_evidence": step_report,
            "descriptor_stage_evidence": descriptor_stage,
            "materializer_exact_threshold_preflight": qualification_preflight,
        }));
    }

    if target_real_step_count != 1 {
        bail!("expected exactly one real target action, observed {target_real_step_count}");
    }
    if !all_payloads_fit {
        bail!("one or more lifecycle route payloads exceeded the hard limit");
    }
    let inventory_counts = inventory.iter().fold(BTreeMap::new(), |mut counts, item| {
        *counts.entry(item.class.clone()).or_insert(0_usize) += 1;
        counts
    });
    let report = json!({
        "status": "pass",
        "command": "lifecycle-route",
        "proof_policy": "all producer setup actions mock; exactly the named target action real",
        "target_real_action": target_real_action,
        "target_real_action_route_occurrences": exact_action_occurrences(actions, &target_real_action),
        "target_real_step_count": target_real_step_count,
        "descriptor_path": descriptor_path.display().to_string(),
        "descriptor_validation": descriptor_validation,
        "input_source": "fresh producer-derived outputs from the descriptor's exact action route",
        "descriptor_objects_loaded_as_fixtures": 0,
        "minted_or_hand_edited_fixtures": 0,
        "network_submission_performed": false,
        "network_acceptance_claimed": false,
        "install_performed": false,
        "single_linear_route": true,
        "actions": actions,
        "accepted_step_count": step_reports.len(),
        "accepted_steps": step_reports,
        "qualification_source": "exact local four-limb U256 comparison of producer-derived post-TxInsert candidate commitments",
        "qualification_preflights": qualification_preflights,
        "same_parent_retry_attempts": 0,
        "mock_materializer_used_as_eligibility_oracle": false,
        "all_automatic_lifecycle_assertions_pass": all_lifecycle_assertions_pass,
        "all_descriptor_stage_assertions_pass": all_descriptor_assertions_pass,
        "seconds": started.elapsed().as_secs_f64(),
        "worst_payload_bytes": worst_payload_bytes,
        "payload_hard_limit_bytes": PAYLOAD_HARD_LIMIT_BYTES,
        "worst_payload_headroom_bytes": PAYLOAD_HARD_LIMIT_BYTES as i64 - worst_payload_bytes as i64,
        "all_accepted_payloads_fit_hard_limit": all_payloads_fit,
        "final_state_block": state.block_number,
        "final_state_root": hash_string(state_header(&state).hash()),
        "final_inventory_counts": inventory_counts,
        "final_inventory_objects": inventory_objects_report(&inventory)?,
        "globally_created_commitments": sorted_hash_strings(&globally_created),
        "globally_consumed_nullifiers": sorted_hash_strings(&globally_nullified),
    });
    emit_report(Some(&output), &report)?;
    Ok(())
}

fn run_collision_audit(
    module: &std::rc::Rc<sdk::SdkModule>,
    actions: &[String],
    profile: ClaimProfile,
    real: bool,
    target_real: bool,
) -> Result<(JsonValue, bool)> {
    let (claim_action, producer_actions) = actions
        .split_last()
        .context("collision audit requires a Claim action")?;
    if producer_actions.is_empty() {
        bail!("collision audit requires at least one producer action before Claim");
    }

    let mut state = TestState::default();
    let mut globally_created = HashSet::new();
    let mut globally_nullified = HashSet::new();
    let mut branch_a = Vec::new();
    let mut branch_b = Vec::new();
    let mut producer_reports = Vec::new();

    for (branch_name, inventory) in [("A", &mut branch_a), ("B", &mut branch_b)] {
        for (step_index, action_name) in producer_actions.iter().enumerate() {
            let step = execute_audit_step(module, &state, inventory, action_name, real)
                .with_context(|| {
                    format!(
                        "collision producer branch {branch_name} step {} ({action_name})",
                        step_index + 1
                    )
                })?;
            apply_audit_step(
                &mut state,
                inventory,
                &mut globally_created,
                &mut globally_nullified,
                &step,
            )?;
            producer_reports.push(json!({
                "branch": branch_name,
                "metrics": audit_step_report(
                    step_index + 1,
                    action_name,
                    real,
                    state.block_number,
                    &step,
                ),
            }));
        }
    }

    let (ship_a_class, ship_a_before) = unique_inventory_object(&branch_a, "spaceship")?;
    let ship_a_class = ship_a_class.to_string();
    let ship_a_before = ship_a_before.clone();
    let (ship_b_class, ship_b_before) = unique_inventory_object(&branch_b, "spaceship")?;
    let ship_b_class = ship_b_class.to_string();
    let ship_b_before = ship_b_before.clone();
    let ship_b_commitment_before = ship_b_before.obj.commitment();
    let ship_b_stable_before = object_field(&ship_b_before, "stable_identifier")?;
    let ship_b_nullifier = compute_nullifier(&ship_b_before.obj);

    let claim_real = real || target_real;
    let claim_a = execute_audit_step(module, &state, &branch_a, claim_action, claim_real)
        .context("executing first collision Claim")?;
    let (facts_a, audit_a, audit_a_pass) =
        audit_claim_transaction(profile, claim_action, &claim_a)?;
    let first_collisions = created_collisions(&claim_a, &globally_created);
    let first_accepted = audit_a_pass && first_collisions.is_empty();
    if first_accepted {
        apply_audit_step(
            &mut state,
            &mut branch_a,
            &mut globally_created,
            &mut globally_nullified,
            &claim_a,
        )?;
    }

    let state_root_before_second = state_header(&state).hash();
    let block_before_second = state.block_number;
    let claim_b = execute_audit_step(module, &state, &branch_b, claim_action, claim_real)
        .context("executing second collision Claim")?;
    let (facts_b, audit_b, audit_b_pass) =
        audit_claim_transaction(profile, claim_action, &claim_b)?;
    let second_collisions = created_collisions(&claim_b, &globally_created);
    let sector_collision_detected = second_collisions.contains(&facts_b.sector.obj.commitment());

    // A synchronizer rejects a transaction before state application when any
    // created commitment already exists. Model that boundary exactly here:
    // do not call apply_audit_step for the losing transaction.
    let second_rejected = audit_b_pass && sector_collision_detected;
    let state_root_after_rejection = state_header(&state).hash();
    let ship_b_after = unique_inventory_object(&branch_b, "spaceship")?.1.clone();

    let mut assertions = BTreeMap::new();
    bool_assertion(
        &mut assertions,
        "producer_ships_are_distinct",
        ship_a_before.obj.commitment() != ship_b_before.obj.commitment()
            && object_field(&ship_a_before, "stable_identifier")? != ship_b_stable_before,
    );
    for field in ["x", "y", "z", "epoch"] {
        bool_assertion(
            &mut assertions,
            format!("producer_ships_same_{field}"),
            same_field(&ship_a_before, &ship_b_before, field),
        );
    }
    bool_assertion(
        &mut assertions,
        "both_claim_transactions_pass_profile",
        audit_a_pass && audit_b_pass,
    );
    bool_assertion(
        &mut assertions,
        "same_sector_initial_commitment",
        facts_a.sector_initial_commitment == facts_b.sector_initial_commitment,
    );
    bool_assertion(
        &mut assertions,
        "same_sector_materialized_commitment",
        facts_a.sector.obj.commitment() == facts_b.sector.obj.commitment(),
    );
    bool_assertion(
        &mut assertions,
        "first_claim_has_no_created_collision",
        first_collisions.is_empty(),
    );
    bool_assertion(&mut assertions, "first_claim_applied", first_accepted);
    bool_assertion(
        &mut assertions,
        "second_claim_sector_collision_detected",
        sector_collision_detected,
    );
    bool_assertion(
        &mut assertions,
        "second_claim_rejected_without_apply",
        second_rejected,
    );
    bool_assertion(
        &mut assertions,
        "state_unchanged_by_rejected_second_claim",
        state.block_number == block_before_second
            && state_header(&state).hash() == state_root_before_second
            && state_root_after_rejection == state_root_before_second,
    );
    bool_assertion(
        &mut assertions,
        "losing_ship_commitment_unchanged",
        ship_b_after.obj.commitment() == ship_b_commitment_before,
    );
    bool_assertion(
        &mut assertions,
        "losing_ship_stable_identifier_unchanged",
        object_field(&ship_b_after, "stable_identifier")? == ship_b_stable_before,
    );
    bool_assertion(
        &mut assertions,
        "losing_ship_remains_live",
        !globally_nullified.contains(&ship_b_nullifier),
    );

    let all_pass = assertions.values().all(|value| *value);
    Ok((
        json!({
            "status": if all_pass { "pass" } else { "fail" },
            "scope": "local synchronizer-style global-created-set preflight",
            "network_submission_performed": false,
            "network_acceptance_claimed": false,
            "atomicity_model": "the second valid transaction is fully constructed, then rejected before TestState/app inventory application when its Sector commitment already exists",
            "proof_policy": if real {
                "all producer and Claim steps real"
            } else if target_real {
                "producer setup mock; both Claim transactions real"
            } else {
                "all steps mock"
            },
            "producer_actions": producer_actions,
            "claim_action": claim_action,
            "producer_step_metrics": producer_reports,
            "ship_a_before": object_report(&ship_a_class, &ship_a_before)?,
            "ship_b_before": object_report(&ship_b_class, &ship_b_before)?,
            "claim_a": audit_a,
            "claim_b": audit_b,
            "first_created_collisions": first_collisions.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
            "second_created_collisions": second_collisions.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
            "state_root_before_second_claim": hash_string(state_root_before_second),
            "state_root_after_rejection": hash_string(state_root_after_rejection),
            "assertions": assertions,
        }),
        all_pass,
    ))
}

fn execute_claim_audit(
    plugin_root: &Path,
    profile: ClaimProfile,
    actions: Vec<String>,
    output: Option<PathBuf>,
    real: bool,
    target_real: bool,
    collision: bool,
) -> Result<()> {
    if actions.len() < 2 {
        bail!("claim-audit requires at least one producer action followed by Claim");
    }
    if real && target_real {
        bail!("--real and --target-real are mutually exclusive");
    }
    if profile.requires_collision() && !collision {
        bail!("the production profile requires --collision");
    }

    let (_source, module) = load_module(plugin_root)?;
    let mut state = TestState::default();
    let mut inventory = Vec::new();
    let mut globally_created = HashSet::new();
    let mut globally_nullified = HashSet::new();
    let mut step_reports = Vec::new();
    let mut claim_report = None;
    let mut claim_pass = false;
    let started = Instant::now();

    for (step_index, action_name) in actions.iter().enumerate() {
        let is_claim = step_index + 1 == actions.len();
        let step_real = real || (target_real && is_claim);
        let step = execute_audit_step(&module, &state, &inventory, action_name, step_real)
            .with_context(|| format!("Claim audit step {} ({action_name})", step_index + 1))?;

        if is_claim {
            let (_facts, report, pass) = audit_claim_transaction(profile, action_name, &step)?;
            claim_report = Some(report);
            claim_pass = pass;
        }
        if !is_claim || claim_pass {
            apply_audit_step(
                &mut state,
                &mut inventory,
                &mut globally_created,
                &mut globally_nullified,
                &step,
            )?;
        }
        step_reports.push(audit_step_report(
            step_index + 1,
            action_name,
            step_real,
            state.block_number,
            &step,
        ));
    }

    let (collision_report, collision_pass) = if collision {
        let (report, pass) = run_collision_audit(&module, &actions, profile, real, target_real)?;
        (report, pass)
    } else {
        (
            json!({
                "status": "not_requested",
                "network_submission_performed": false,
                "network_acceptance_claimed": false,
            }),
            true,
        )
    };
    let overall_pass = claim_pass && collision_pass;
    let inventory_counts = inventory.iter().fold(BTreeMap::new(), |mut counts, item| {
        *counts.entry(item.class.clone()).or_insert(0_usize) += 1;
        counts
    });
    let report = json!({
        "status": if overall_pass { "pass" } else { "fail" },
        "command": "claim-audit",
        "profile": profile.name(),
        "mode": if real { "real" } else if target_real { "target-real" } else { "mock" },
        "proof_policy": if real { "all steps real" } else if target_real { "mock producer setup; final Claim real" } else { "all steps mock" },
        "input_source": "producer-derived action outputs only",
        "minted_or_hand_edited_fixtures": 0,
        "actions": actions,
        "seconds": started.elapsed().as_secs_f64(),
        "sampled_step_metrics": step_reports,
        "claim": claim_report.context("Claim report was not produced")?,
        "claim_applied_to_local_state": claim_pass,
        "collision": collision_report,
        "final_state_block": state.block_number,
        "final_state_root": hash_string(state_header(&state).hash()),
        "final_inventory": inventory_counts,
    });
    let encoded = serde_json::to_string_pretty(&report)? + "\n";
    if let Some(path) = output {
        fs::write(&path, &encoded).with_context(|| format!("writing {}", path.display()))?;
    }
    println!("{encoded}");
    if !overall_pass {
        bail!("one or more required Claim audit assertions failed");
    }
    Ok(())
}

fn execute_reveal_audit(
    plugin_root: &Path,
    actions: Vec<String>,
    output: Option<PathBuf>,
    target_real: bool,
) -> Result<()> {
    if actions.len() < 2 {
        bail!(
            "survey-audit requires at least one producer action followed by SurveySector_<profile>"
        );
    }
    let (reveal_action, producer_actions) = actions
        .split_last()
        .context("survey-audit requires a SurveySector action")?;
    if !is_reveal_audit_target(reveal_action) {
        bail!("survey-audit target must be SurveySector_<profile>; got {reveal_action}");
    }

    let (_source, module) = load_module(plugin_root)?;
    let mut state = TestState::default();
    let mut inventory = Vec::new();
    let mut globally_created = HashSet::new();
    let mut globally_nullified = HashSet::new();
    let mut step_reports = Vec::new();
    let started = Instant::now();

    for (step_index, action_name) in producer_actions.iter().enumerate() {
        let step = execute_audit_step(&module, &state, &inventory, action_name, false)
            .with_context(|| {
                format!(
                    "Reveal audit producer step {} ({action_name})",
                    step_index + 1
                )
            })?;
        apply_audit_step(
            &mut state,
            &mut inventory,
            &mut globally_created,
            &mut globally_nullified,
            &step,
        )?;
        step_reports.push(audit_step_report(
            step_index + 1,
            action_name,
            false,
            state.block_number,
            &step,
        ));
    }

    let pre_reveal_snapshot =
        harness_snapshot(&state, &inventory, &globally_created, &globally_nullified)?;
    let reveal = execute_audit_step(&module, &state, &inventory, reveal_action, target_real)
        .with_context(|| format!("executing audited {reveal_action}"))?;
    let (reveal_facts, reveal_report, reveal_pass) =
        audit_reveal_transaction(reveal_action, &reveal)?;

    // Construct a second valid Reveal from the exact same producer-derived old
    // state before accepting the winner. It remains mock even when the audited
    // target is real, so --target-real produces exactly one proof.
    let concurrent_loser = execute_audit_step(&module, &state, &inventory, reveal_action, false)
        .with_context(|| format!("constructing concurrent old-state {reveal_action}"))?;
    let (concurrent_facts, concurrent_semantics, concurrent_semantics_pass) =
        audit_reveal_transaction(reveal_action, &concurrent_loser)?;

    let mut target_applied = false;
    if reveal_pass {
        apply_audit_step(
            &mut state,
            &mut inventory,
            &mut globally_created,
            &mut globally_nullified,
            &reveal,
        )?;
        target_applied = true;
    }
    step_reports.push(audit_step_report(
        producer_actions.len() + 1,
        reveal_action,
        target_real,
        state.block_number,
        &reveal,
    ));

    let concurrent_snapshot_before =
        harness_snapshot(&state, &inventory, &globally_created, &globally_nullified)?;
    let reused_nullifiers = nullifier_collisions(&concurrent_loser, &globally_nullified);
    let concurrent_rejection = if target_applied {
        apply_audit_step(
            &mut state,
            &mut inventory,
            &mut globally_created,
            &mut globally_nullified,
            &concurrent_loser,
        )
        .err()
        .map(|error| error.to_string())
    } else {
        None
    };
    let concurrent_snapshot_after =
        harness_snapshot(&state, &inventory, &globally_created, &globally_nullified)?;
    let mut concurrent_assertions = BTreeMap::new();
    bool_assertion(&mut concurrent_assertions, "winner_applied", target_applied);
    bool_assertion(
        &mut concurrent_assertions,
        "both_transactions_pass_reveal_semantics",
        reveal_pass && concurrent_semantics_pass,
    );
    bool_assertion(
        &mut concurrent_assertions,
        "both_transactions_consume_same_old_ship",
        reveal_facts.old_ship_nullifier == concurrent_facts.old_ship_nullifier,
    );
    bool_assertion(
        &mut concurrent_assertions,
        "both_transactions_consume_same_old_sector",
        reveal_facts.old_sector_nullifier == concurrent_facts.old_sector_nullifier,
    );
    bool_assertion(
        &mut concurrent_assertions,
        "loser_reuses_both_old_state_nullifiers",
        reused_nullifiers.len() == 2
            && reused_nullifiers.contains(&reveal_facts.old_ship_nullifier)
            && reused_nullifiers.contains(&reveal_facts.old_sector_nullifier),
    );
    bool_assertion(
        &mut concurrent_assertions,
        "loser_rejected_by_nullifier_preflight",
        concurrent_rejection
            .as_ref()
            .is_some_and(|error| error.contains("nullifier reuse")),
    );
    bool_assertion(
        &mut concurrent_assertions,
        "state_inventory_and_tracking_unchanged_by_loser",
        concurrent_snapshot_before == concurrent_snapshot_after,
    );
    let concurrent_pass = concurrent_assertions.values().all(|value| *value);
    let concurrent_report = json!({
        "status": if concurrent_pass { "pass" } else { "fail" },
        "scope": "local synchronizer-style old-state nullifier preflight",
        "network_submission_performed": false,
        "network_acceptance_claimed": false,
        "assertions": concurrent_assertions,
        "reused_nullifiers": reused_nullifiers.iter().map(|hash| hash_string(*hash)).collect::<Vec<_>>(),
        "rejection_error": concurrent_rejection,
        "losing_transaction_semantics": concurrent_semantics,
        "snapshot_before_rejection": concurrent_snapshot_before,
        "snapshot_after_rejection": concurrent_snapshot_after,
    });

    let second_reveal_snapshot_before =
        harness_snapshot(&state, &inventory, &globally_created, &globally_nullified)?;
    let second_reveal_attempt = catch_unwind(AssertUnwindSafe(|| {
        execute_audit_step(&module, &state, &inventory, reveal_action, false)
    }));
    let (second_reveal_error, second_reveal_returned_error, second_reveal_panicked) =
        match second_reveal_attempt {
            Ok(Err(error)) => (Some(error.to_string()), true, false),
            Ok(Ok(_)) => (None, false, false),
            Err(payload) => (Some(panic_message(payload)), false, true),
        };
    let second_reveal_snapshot_after =
        harness_snapshot(&state, &inventory, &globally_created, &globally_nullified)?;
    let current_ship = unique_inventory_object(&inventory, "spaceship")?.1;
    let current_sector = unique_inventory_object(&inventory, "sector")?.1;
    let current_ship_nullifier = compute_nullifier(&current_ship.obj);
    let current_sector_nullifier = compute_nullifier(&current_sector.obj);
    let mut second_reveal_assertions = BTreeMap::new();
    bool_assertion(
        &mut second_reveal_assertions,
        "second_reveal_rejected_and_process_survived",
        second_reveal_returned_error || second_reveal_panicked,
    );
    bool_assertion(
        &mut second_reveal_assertions,
        "state_inventory_and_tracking_unchanged",
        second_reveal_snapshot_before == second_reveal_snapshot_after,
    );
    bool_assertion(
        &mut second_reveal_assertions,
        "replacement_ship_remains_live_and_unchanged",
        current_ship.obj.commitment() == reveal_facts.replacement_ship_commitment
            && globally_created.contains(&current_ship.obj.commitment())
            && !globally_nullified.contains(&current_ship_nullifier),
    );
    bool_assertion(
        &mut second_reveal_assertions,
        "revealed_sector_remains_live_and_unchanged",
        current_sector.obj.commitment() == reveal_facts.revealed_sector_commitment
            && globally_created.contains(&current_sector.obj.commitment())
            && !globally_nullified.contains(&current_sector_nullifier),
    );
    let second_reveal_pass = second_reveal_assertions.values().all(|value| *value);
    let second_reveal_report = json!({
        "status": if second_reveal_pass { "pass" } else { "fail" },
        "attempt": format!("repeat {reveal_action} against its producer-derived replacement Ship and revealed Sector"),
        "error": second_reveal_error,
        "rejection_modality": if second_reveal_panicked {
            "caught_panic"
        } else if second_reveal_returned_error {
            "returned_error"
        } else {
            "unexpected_success"
        },
        "panic_observed": second_reveal_panicked,
        "transaction_applied": false,
        "assertions": second_reveal_assertions,
        "snapshot_before_attempt": second_reveal_snapshot_before,
        "snapshot_after_attempt": second_reveal_snapshot_after,
    });

    let inventory_counts = inventory.iter().fold(BTreeMap::new(), |mut counts, item| {
        *counts.entry(item.class.clone()).or_insert(0_usize) += 1;
        counts
    });
    let final_inventory_exact = inventory.len() == 2
        && inventory_counts
            .iter()
            .find(|(class, _)| class_matches(class, "spaceship"))
            .is_some_and(|(_, count)| *count == 1)
        && inventory_counts
            .iter()
            .find(|(class, _)| class_matches(class, "sector"))
            .is_some_and(|(_, count)| *count == 1);
    let overall_pass =
        reveal_pass && concurrent_pass && second_reveal_pass && final_inventory_exact;
    let report = json!({
        "status": if overall_pass { "pass" } else { "fail" },
        "command": "reveal-audit",
        "mode": if target_real { "target-real" } else { "mock" },
        "proof_policy": if target_real {
            "mock producer setup; audited Reveal target real; rejection attempts mock"
        } else {
            "all accepted and rejection attempts mock"
        },
        "input_source": "producer-derived action outputs only",
        "minted_or_hand_edited_fixtures": 0,
        "actions": actions,
        "seconds": started.elapsed().as_secs_f64(),
        "pre_reveal_snapshot": pre_reveal_snapshot,
        "sampled_step_metrics": step_reports,
        "reveal": reveal_report,
        "reveal_applied_to_local_state": target_applied,
        "concurrent_old_state_rejection": concurrent_report,
        "failed_second_reveal_atomicity": second_reveal_report,
        "final_inventory_exactly_one_ship_and_sector": final_inventory_exact,
        "final_inventory_counts": inventory_counts,
        "final_inventory_objects": inventory_objects_report(&inventory)?,
        "final_state_block": state.block_number,
        "final_state_root": hash_string(state_header(&state).hash()),
    });
    let encoded = serde_json::to_string_pretty(&report)? + "\n";
    if let Some(path) = output {
        fs::write(&path, &encoded).with_context(|| format!("writing {}", path.display()))?;
    }
    println!("{encoded}");
    if !overall_pass {
        bail!("one or more required Reveal audit assertions failed");
    }
    Ok(())
}

// Current-v2 release canaries. This path is intentionally isolated from the
// legacy v1 synthetic fixture and lifecycle-audit code above.
const V2_CANARY_SCHEMA: &str = "microverse-v2-proof-canaries/v1";
const V2_EXTRACTION_OWNER_MATRIX: &[&str] = &[
    "ExtractGas",
    "ExtractMegastructureArchiveData",
    "ExtractOceanPlanetWaterMedium",
    "ExtractRedDwarfFlareSpectrumDataLarge",
    "ExtractAnomalyRadiationObservation",
    "ExtractGardenPlanetBiochemicalMixtureMedium",
    "ExtractRockyPlanetFerrousOre",
    "ExtractMagnetarDenseNuclearCondensate",
    "ExtractRedDwarfRedDwarfPlasmaLarge",
];
const V2_CANARY_ACTIONS: &[&str] = &[
    "ClaimSector",
    "SurveySector_01_Sparse",
    "ScanCelestialBody_04_OceanPlanet",
    "ExtractGas",
    "ExtractMegastructureArchiveData",
    "ExtractOceanPlanetWaterMedium",
    "ExtractRedDwarfFlareSpectrumDataLarge",
    "ExtractAnomalyRadiationObservation",
    "ExtractGardenPlanetBiochemicalMixtureMedium",
    "ExtractRockyPlanetFerrousOre",
    "ExtractMagnetarDenseNuclearCondensate",
    "ExtractRedDwarfRedDwarfPlasmaLarge",
    "ExtractNeutronStarPulsarEmissionData",
    "ExtractRockyPlanetBaseMetalOre",
    "RefineFerrousOreToIron",
    "DevelopTypeIIndustrialFabricationSkill",
    "DevelopStructuralMetallurgySkill",
    "FabricatePrecisionToolhead",
    "ExtractAnomalyWarpCoordinate",
    "RevealWarpCoordinate001",
    "AuthorizeLargeShipIndustrial",
    "BuildShipLarge",
];

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum V2ShipIdentityMode {
    Replacement,
    Mutation,
}

impl V2ShipIdentityMode {
    fn report_name(self) -> &'static str {
        match self {
            Self::Replacement => "expect-ship-replacement",
            Self::Mutation => "expect-ship-mutation",
        }
    }
}

#[derive(Clone, Copy)]
struct V2ExtractionSpec {
    owner: &'static str,
    coverage: &'static str,
    selector_gate: &'static str,
    vdf_iterations: i64,
    producer_category: i64,
    producer_candidate: i64,
    body_type: i64,
    body_pools: [i64; 4],
    satellites: i64,
    stable_identifier_band: Option<(u64, u64)>,
    signal_commitment_band: (u64, u64),
    required_skill: i64,
    remaining_field: &'static str,
    output_resource_type: i64,
    extraction_amount: i64,
    rare_extraction_amount: i64,
    child_amounts: Option<[i64; 3]>,
}

fn v2_extraction_spec(action: &str) -> Option<V2ExtractionSpec> {
    match action {
        "ExtractGas" => Some(V2ExtractionSpec {
            owner: "extract_base_action",
            coverage: "nine-owner-matrix",
            selector_gate: "base-no-candidate",
            vdf_iterations: 2,
            producer_category: 3,
            producer_candidate: 6,
            body_type: 3,
            body_pools: [2_000, 0, 24_000, 6_000],
            satellites: 4,
            stable_identifier_band: None,
            signal_commitment_band: (0, u64::MAX),
            required_skill: 0,
            remaining_field: "gas_remaining",
            output_resource_type: 3,
            extraction_amount: 10,
            rare_extraction_amount: 1,
            child_amounts: None,
        }),
        "ExtractMegastructureArchiveData" => Some(V2ExtractionSpec {
            owner: "extract_direct_ungated_action",
            coverage: "nine-owner-matrix",
            selector_gate: "candidate-only",
            vdf_iterations: 32,
            producer_category: 8,
            producer_candidate: 12,
            body_type: 8,
            body_pools: [10_000, 10_000, 0, 10_000],
            satellites: 0,
            stable_identifier_band: None,
            signal_commitment_band: (0, u64::MAX),
            required_skill: 18,
            remaining_field: "crystal_remaining",
            output_resource_type: 151,
            extraction_amount: 250,
            rare_extraction_amount: 25,
            child_amounts: None,
        }),
        "ExtractOceanPlanetWaterMedium" => Some(V2ExtractionSpec {
            owner: "extract_direct_upper_action",
            coverage: "nine-owner-matrix",
            selector_gate: "upper",
            vdf_iterations: 2,
            producer_category: 1,
            producer_candidate: 4,
            body_type: 1,
            body_pools: [14_000, 3_000, 14_000, 3_000],
            satellites: 2,
            stable_identifier_band: Some((0, 6_148_914_689_804_861_439)),
            signal_commitment_band: (7_976_970_408_395_495_922, 9_971_213_010_494_369_902),
            required_skill: 0,
            remaining_field: "matter_remaining",
            output_resource_type: 126,
            extraction_amount: 50,
            rare_extraction_amount: 5,
            child_amounts: None,
        }),
        "ExtractRedDwarfFlareSpectrumDataLarge" => Some(V2ExtractionSpec {
            owner: "extract_direct_lower_action",
            coverage: "nine-owner-matrix",
            selector_gate: "lower",
            vdf_iterations: 12,
            producer_category: 2,
            producer_candidate: 0,
            body_type: 2,
            body_pools: [4_000, 0, 4_000, 22_000],
            satellites: 0,
            stable_identifier_band: Some((12_297_829_379_609_722_880, u64::MAX)),
            signal_commitment_band: (0, 14_223_995_427_018_474_656),
            required_skill: 8,
            remaining_field: "energy_remaining",
            output_resource_type: 225,
            extraction_amount: 250,
            rare_extraction_amount: 25,
            child_amounts: None,
        }),
        "ExtractAnomalyRadiationObservation" => Some(V2ExtractionSpec {
            owner: "extract_direct_range_action",
            coverage: "nine-owner-matrix",
            selector_gate: "range-lower-then-upper",
            vdf_iterations: 20,
            producer_category: 7,
            producer_candidate: 11,
            body_type: 7,
            body_pools: [18_000, 9_000, 9_000, 18_000],
            satellites: 0,
            stable_identifier_band: Some((4_611_686_017_353_646_080, 9_223_372_034_707_292_159)),
            signal_commitment_band: (0, 6_148_914_689_804_861_439),
            required_skill: 14,
            remaining_field: "energy_remaining",
            output_resource_type: 252,
            extraction_amount: 250,
            rare_extraction_amount: 25,
            child_amounts: None,
        }),
        "ExtractGardenPlanetBiochemicalMixtureMedium" => Some(V2ExtractionSpec {
            owner: "extract_composite_ungated_action",
            coverage: "nine-owner-matrix",
            selector_gate: "candidate-only",
            vdf_iterations: 4,
            producer_category: 1,
            producer_candidate: 5,
            body_type: 1,
            body_pools: [17_000, 9_000, 6_000, 6_000],
            satellites: 1,
            stable_identifier_band: None,
            signal_commitment_band: (9_971_213_010_494_369_903, 10_469_773_661_019_088_397),
            required_skill: 0,
            remaining_field: "gas_remaining",
            output_resource_type: 131,
            extraction_amount: 50,
            rare_extraction_amount: 5,
            child_amounts: Some([25, 15, 10]),
        }),
        "ExtractRockyPlanetFerrousOre" => Some(V2ExtractionSpec {
            owner: "extract_composite_upper_action",
            coverage: "nine-owner-matrix",
            selector_gate: "upper",
            vdf_iterations: 8,
            producer_category: 1,
            producer_candidate: 3,
            body_type: 1,
            body_pools: [19_000, 5_000, 3_000, 3_000],
            satellites: 1,
            stable_identifier_band: Some((0, 3_074_457_344_902_430_719)),
            signal_commitment_band: (0, 7_976_970_408_395_495_921),
            required_skill: 0,
            remaining_field: "matter_remaining",
            output_resource_type: 122,
            extraction_amount: 10,
            rare_extraction_amount: 1,
            child_amounts: Some([7, 2, 1]),
        }),
        "ExtractMagnetarDenseNuclearCondensate" => Some(V2ExtractionSpec {
            owner: "extract_composite_lower_action",
            coverage: "nine-owner-matrix",
            selector_gate: "lower",
            vdf_iterations: 20,
            producer_category: 5,
            producer_candidate: 21,
            body_type: 5,
            body_pools: [4_000, 12_000, 0, 32_000],
            satellites: 0,
            stable_identifier_band: Some((9_223_372_034_707_292_160, u64::MAX)),
            signal_commitment_band: (12_297_829_379_609_722_880, u64::MAX),
            required_skill: 13,
            remaining_field: "crystal_remaining",
            output_resource_type: 483,
            extraction_amount: 250,
            rare_extraction_amount: 25,
            child_amounts: Some([175, 50, 25]),
        }),
        "ExtractRedDwarfRedDwarfPlasmaLarge" => Some(V2ExtractionSpec {
            owner: "extract_composite_range_action",
            coverage: "nine-owner-matrix",
            selector_gate: "range-lower-then-upper",
            vdf_iterations: 12,
            producer_category: 2,
            producer_candidate: 0,
            body_type: 2,
            body_pools: [4_000, 0, 4_000, 22_000],
            satellites: 0,
            stable_identifier_band: Some((6_148_914_689_804_861_440, 12_297_829_379_609_722_879)),
            signal_commitment_band: (0, 14_223_995_427_018_474_656),
            required_skill: 8,
            remaining_field: "energy_remaining",
            output_resource_type: 223,
            extraction_amount: 250,
            rare_extraction_amount: 25,
            child_amounts: Some([150, 75, 25]),
        }),
        "ExtractNeutronStarPulsarEmissionData" => Some(V2ExtractionSpec {
            owner: "extract_direct_range_action",
            coverage: "supplemental-existing-range",
            selector_gate: "range-lower-then-upper",
            vdf_iterations: 12,
            producer_category: 5,
            producer_candidate: 9,
            body_type: 5,
            body_pools: [2_000, 1_000, 0, 43_000],
            satellites: 0,
            stable_identifier_band: Some((6_148_914_689_804_861_440, 12_297_829_379_609_722_879)),
            signal_commitment_band: (0, 12_297_829_379_609_722_879),
            required_skill: 16,
            remaining_field: "energy_remaining",
            output_resource_type: 246,
            extraction_amount: 250,
            rare_extraction_amount: 25,
            child_amounts: None,
        }),
        "ExtractRockyPlanetBaseMetalOre" => Some(V2ExtractionSpec {
            owner: "extract_composite_range_action",
            coverage: "supplemental-existing-range",
            selector_gate: "range-lower-then-upper",
            vdf_iterations: 8,
            producer_category: 1,
            producer_candidate: 3,
            body_type: 1,
            body_pools: [19_000, 5_000, 3_000, 3_000],
            satellites: 1,
            stable_identifier_band: Some((3_074_457_344_902_430_720, 6_148_914_689_804_861_439)),
            signal_commitment_band: (0, 7_976_970_408_395_495_921),
            required_skill: 0,
            remaining_field: "matter_remaining",
            output_resource_type: 123,
            extraction_amount: 10,
            rare_extraction_amount: 1,
            child_amounts: Some([7, 2, 1]),
        }),
        _ => None,
    }
}

const V2_SHIP_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "extraction_amount",
    "rare_extraction_amount",
    "x",
    "y",
    "z",
    "epoch",
    "active_skill_type",
    "action_serial",
    "discovery_serial",
    "satellite_serial",
    "civilization_scan_serial",
    "ship_id",
];
const V2_SECTOR_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "body_bank_version",
    "x",
    "y",
    "z",
    "epoch",
    "sector_type",
    "survey_profile",
    "planet_remaining",
    "star_remaining",
    "gas_giant_remaining",
    "ice_giant_remaining",
    "neutron_star_remaining",
    "black_hole_remaining",
    "anomaly_remaining",
    "megastructure_remaining",
    "gas_cluster_remaining",
    "stellar_remnant_remaining",
    "minor_body_field_remaining",
    "next_planet_serial",
    "next_star_serial",
    "next_gas_giant_serial",
    "next_ice_giant_serial",
    "next_neutron_star_serial",
    "next_black_hole_serial",
    "next_anomaly_serial",
    "next_megastructure_serial",
    "next_gas_cluster_serial",
    "next_stellar_remnant_serial",
    "next_minor_body_field_serial",
    "revision",
];
const V2_SIGNAL_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "body_bank_version",
    "sector_x",
    "sector_y",
    "sector_z",
    "sector_epoch",
    "category_code",
    "candidate_code",
    "slot_serial",
];
const V2_BODY_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "body_bank_version",
    "source_signal_identifier",
    "sector_x",
    "sector_y",
    "sector_z",
    "sector_epoch",
    "candidate_code",
    "body_type",
    "life_stat",
    "matter_remaining",
    "crystal_remaining",
    "gas_remaining",
    "energy_remaining",
    "satellites_remaining",
    "next_satellite_serial",
    "civilization_discovered",
];
const V2_RESOURCE_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "resource_type",
    "amount",
];
const V2_COMPOSITE_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "resource_type",
    "sector_x",
    "sector_y",
    "sector_z",
    "origin_epoch",
    "child_1_remaining",
    "child_2_remaining",
    "child_3_remaining",
];
const V2_LIFE_SIGNAL_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "civilization_version",
    "source_body_identifier",
    "sector_x",
    "sector_y",
    "sector_z",
    "origin_epoch",
];
const V2_CIVILIZATION_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "civilization_version",
    "source_life_signal_identifier",
    "sector_x",
    "sector_y",
    "sector_z",
    "origin_epoch",
    "civilization_type",
];
const V2_TECHNOLOGY_SKILL_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "civilization_version",
    "skill_type",
    "reusable",
];
const V2_PERMIT_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "permit_type",
    "x",
    "y",
    "z",
    "epoch",
    "industrial_authorized",
    "electronics_authorized",
    "molecular_authorized",
];
const V2_WARP_COORDINATE_FIELDS: &[&str] = &[
    "type",
    "key",
    "work",
    "stable_identifier",
    "schema_version",
    "mechanics_version",
    "universe_version",
    "source_body_identifier",
    "source_pool_before",
    "revealed",
    "destination_code",
    "destination_x",
    "destination_y",
    "destination_z",
    "uses_remaining",
];

struct V2CanaryFixture {
    input_classes: Vec<String>,
    objects: Vec<Dictionary>,
    derivation: JsonValue,
}

fn v2_case_seed(action: &str) -> Option<u64> {
    V2_CANARY_ACTIONS
        .iter()
        .position(|candidate| *candidate == action)
        .map(|index| 0x4d56_3200_0000_0000_u64 + index as u64 * 0x101 + 0x51)
}

fn v2_schema_update(
    object: &mut Dictionary,
    exact_schema: &[&str],
    field: &str,
    value: PodValue,
) -> Result<()> {
    if !exact_schema.contains(&field) {
        bail!("current-v2 fixture update rejected unregistered field {field}");
    }
    let key = StrKey::from(field);
    if object.get(&key)?.is_some() {
        object
            .update(&key, &value)
            .with_context(|| format!("updating current-v2 fixture field {field}"))?;
    } else {
        object
            .insert(&key, &value)
            .with_context(|| format!("inserting registered current-v2 fixture field {field}"))?;
    }
    Ok(())
}

fn v2_field(object: &Dictionary, field: &str) -> Result<PodValue> {
    object
        .get(&StrKey::from(field))?
        .ok_or_else(|| anyhow!("current-v2 fixture is missing required field {field}"))
}

fn v2_assert_exact_schema(object: &Dictionary, expected: &[&str], label: &str) -> Result<()> {
    let actual = object
        .iter()
        .map(|entry| entry.map(|(field, _)| field))
        .collect::<Result<HashSet<_>, _>>()?;
    let expected = expected
        .iter()
        .map(|field| (*field).to_string())
        .collect::<HashSet<_>>();
    if actual != expected {
        let mut missing = expected.difference(&actual).cloned().collect::<Vec<_>>();
        let mut extra = actual.difference(&expected).cloned().collect::<Vec<_>>();
        missing.sort();
        extra.sort();
        bail!("{label} current-v2 schema mismatch; missing={missing:?}, extra={extra:?}");
    }
    Ok(())
}

fn v2_expected_fields(class: &str) -> Result<&'static [&'static str]> {
    if class_matches(class, "spaceship") {
        Ok(V2_SHIP_FIELDS)
    } else if class_matches(class, "sector") {
        Ok(V2_SECTOR_FIELDS)
    } else if class_matches(class, "celestial_signal") {
        Ok(V2_SIGNAL_FIELDS)
    } else if class_matches(class, "celestial_body") {
        Ok(V2_BODY_FIELDS)
    } else if class_matches(class, "resource") {
        Ok(V2_RESOURCE_FIELDS)
    } else if class_matches(class, "composite_resource") {
        Ok(V2_COMPOSITE_FIELDS)
    } else if class_matches(class, "life_signal") {
        Ok(V2_LIFE_SIGNAL_FIELDS)
    } else if class_matches(class, "civilization") {
        Ok(V2_CIVILIZATION_FIELDS)
    } else if class_matches(class, "technology_skill") {
        Ok(V2_TECHNOLOGY_SKILL_FIELDS)
    } else if class_matches(class, "shipyard_permit") {
        Ok(V2_PERMIT_FIELDS)
    } else if class_matches(class, "warp_coordinate") {
        Ok(V2_WARP_COORDINATE_FIELDS)
    } else {
        bail!("no fail-closed current-v2 schema registered for class {class}")
    }
}

fn v2_object_mut<'a>(
    classes: &[String],
    objects: &'a mut [Dictionary],
    suffix: &str,
    occurrence: usize,
) -> Result<&'a mut Dictionary> {
    let index = classes
        .iter()
        .enumerate()
        .filter(|(_, class)| class_matches(class, suffix))
        .nth(occurrence)
        .map(|(index, _)| index)
        .ok_or_else(|| anyhow!("missing current-v2 input {suffix} occurrence {occurrence}"))?;
    objects
        .get_mut(index)
        .ok_or_else(|| anyhow!("current-v2 input index {index} is out of range"))
}

fn v2_expected_topology(
    action: &str,
) -> Result<(Vec<(&'static str, usize)>, Vec<(&'static str, usize)>)> {
    if let Some(spec) = v2_extraction_spec(action) {
        let output = if spec.child_amounts.is_some() {
            vec![
                ("spaceship", 1),
                ("composite_resource", 1),
                ("celestial_body", 1),
            ]
        } else {
            vec![("spaceship", 1), ("resource", 1), ("celestial_body", 1)]
        };
        return Ok((vec![("spaceship", 1), ("celestial_body", 1)], output));
    }
    let topology = match action {
        "ClaimSector" => (
            vec![("spaceship", 1)],
            vec![("sector", 1), ("spaceship", 1)],
        ),
        "SurveySector_01_Sparse" => (
            vec![("spaceship", 1), ("sector", 1)],
            vec![("spaceship", 1), ("sector", 1)],
        ),
        "ScanCelestialBody_04_OceanPlanet" => (
            vec![("celestial_signal", 1), ("spaceship", 1)],
            vec![("celestial_body", 1), ("spaceship", 1)],
        ),
        "RefineFerrousOreToIron" => (
            vec![("spaceship", 1), ("composite_resource", 1)],
            vec![("spaceship", 1), ("resource", 1), ("composite_resource", 1)],
        ),
        "DevelopTypeIIndustrialFabricationSkill" => (
            vec![("spaceship", 1), ("civilization", 1)],
            vec![
                ("spaceship", 1),
                ("technology_skill", 1),
                ("civilization", 1),
            ],
        ),
        "DevelopStructuralMetallurgySkill" => (
            vec![("spaceship", 1), ("resource", 2)],
            vec![("spaceship", 1), ("technology_skill", 1)],
        ),
        "FabricatePrecisionToolhead" => (
            vec![("spaceship", 1), ("resource", 1)],
            vec![("spaceship", 1), ("resource", 1)],
        ),
        "ExtractAnomalyWarpCoordinate" => (
            vec![("spaceship", 1), ("celestial_body", 1)],
            vec![
                ("spaceship", 1),
                ("warp_coordinate", 1),
                ("celestial_body", 1),
            ],
        ),
        "RevealWarpCoordinate001" => (vec![("warp_coordinate", 1)], vec![("warp_coordinate", 1)]),
        "AuthorizeLargeShipIndustrial" => (
            vec![("spaceship", 1), ("shipyard_permit", 1)],
            vec![("spaceship", 1), ("shipyard_permit", 1)],
        ),
        "BuildShipLarge" => (
            vec![("shipyard_permit", 1), ("resource", 10)],
            vec![("spaceship", 1)],
        ),
        _ => bail!("no fail-closed topology registered for {action}"),
    };
    Ok(topology)
}

fn v2_assert_class_counts(
    classes: &[String],
    expected: &[(&str, usize)],
    label: &str,
) -> Result<()> {
    let expected_total = expected.iter().map(|(_, count)| *count).sum::<usize>();
    if classes.len() != expected_total {
        bail!(
            "{label} class count mismatch: expected {expected_total}, got {}",
            classes.len()
        );
    }
    let expected_order = expected
        .iter()
        .flat_map(|(suffix, count)| std::iter::repeat_n(*suffix, *count))
        .collect::<Vec<_>>();
    if !classes
        .iter()
        .zip(&expected_order)
        .all(|(class, suffix)| class_matches(class, suffix))
    {
        bail!("{label} class order mismatch: expected {expected_order:?}, got {classes:?}");
    }
    for (suffix, expected_count) in expected {
        let actual = classes
            .iter()
            .filter(|class| class_matches(class, suffix))
            .count();
        if actual != *expected_count {
            bail!("{label} expected {expected_count} {suffix} classes, got {actual}");
        }
    }
    if classes.iter().any(|class| {
        !expected
            .iter()
            .any(|(suffix, _)| class_matches(class, suffix))
    }) {
        bail!("{label} contains an unregistered class: {classes:?}");
    }
    Ok(())
}

fn v2_assert_output_schemas(
    action: &str,
    classes: &[String],
    objects: &[SpendableObject],
) -> Result<()> {
    if classes.len() != objects.len() {
        bail!("{action} output class/object count mismatch");
    }
    for (index, (class, object)) in classes.iter().zip(objects).enumerate() {
        if !object_has_exact_fields(object, v2_expected_fields(class)?)? {
            bail!("{action} output {index} ({class}) violates current-v2 exact schema");
        }
    }
    Ok(())
}

fn v2_set_fixed_versions(object: &mut Dictionary, exact_schema: &[&str]) -> Result<()> {
    for field in ["schema_version", "mechanics_version", "universe_version"] {
        v2_schema_update(object, exact_schema, field, PodValue::from(2))?;
    }
    Ok(())
}

fn v2_set_zero_key(object: &mut Dictionary, exact_schema: &[&str]) -> Result<()> {
    v2_schema_update(
        object,
        exact_schema,
        "key",
        PodValue::from(Hash::from(target_raw_value(0))),
    )
}

fn v2_set_ship(
    object: &mut Dictionary,
    extraction: i64,
    rare: i64,
    x: i64,
    y: i64,
    z: i64,
    epoch: i64,
    skill: i64,
) -> Result<()> {
    v2_set_fixed_versions(object, V2_SHIP_FIELDS)?;
    for (field, value) in [
        ("extraction_amount", extraction),
        ("rare_extraction_amount", rare),
        ("x", x),
        ("y", y),
        ("z", z),
        ("epoch", epoch),
        ("active_skill_type", skill),
        ("action_serial", 0),
        ("discovery_serial", 0),
        ("satellite_serial", 0),
        ("civilization_scan_serial", 0),
    ] {
        v2_schema_update(object, V2_SHIP_FIELDS, field, PodValue::from(value))?;
    }
    if object.get(&StrKey::from("claim_serial"))?.is_some() {
        bail!("current-v2 Ship unexpectedly contains removed claim_serial");
    }
    restamp_fixture(object)
}

fn v2_set_nonzero_ship_work(object: &mut Dictionary) -> Result<()> {
    v2_schema_update(
        object,
        V2_SHIP_FIELDS,
        "work",
        PodValue::from(Hash::from(target_raw_value(1))),
    )?;
    restamp_fixture(object)
}

fn v2_set_sector(object: &mut Dictionary, x: i64) -> Result<()> {
    v2_set_fixed_versions(object, V2_SECTOR_FIELDS)?;
    v2_schema_update(
        object,
        V2_SECTOR_FIELDS,
        "body_bank_version",
        PodValue::from(2),
    )?;
    for (field, value) in [
        ("x", x),
        ("y", 1_000_000_000_000),
        ("z", 1_000_000_000_000),
        ("epoch", 0),
        ("sector_type", 0),
        ("survey_profile", 0),
        ("planet_remaining", 0),
        ("star_remaining", 0),
        ("gas_giant_remaining", 0),
        ("ice_giant_remaining", 0),
        ("neutron_star_remaining", 0),
        ("black_hole_remaining", 0),
        ("anomaly_remaining", 0),
        ("megastructure_remaining", 0),
        ("gas_cluster_remaining", 0),
        ("stellar_remnant_remaining", 0),
        ("minor_body_field_remaining", 0),
        ("next_planet_serial", 0),
        ("next_star_serial", 0),
        ("next_gas_giant_serial", 0),
        ("next_ice_giant_serial", 0),
        ("next_neutron_star_serial", 0),
        ("next_black_hole_serial", 0),
        ("next_anomaly_serial", 0),
        ("next_megastructure_serial", 0),
        ("next_gas_cluster_serial", 0),
        ("next_stellar_remnant_serial", 0),
        ("next_minor_body_field_serial", 0),
        ("revision", 0),
    ] {
        v2_schema_update(object, V2_SECTOR_FIELDS, field, PodValue::from(value))?;
    }
    v2_set_zero_key(object, V2_SECTOR_FIELDS)?;
    restamp_fixture(object)
}

fn v2_set_signal(object: &mut Dictionary, category: i64, x: i64) -> Result<()> {
    v2_set_fixed_versions(object, V2_SIGNAL_FIELDS)?;
    v2_schema_update(
        object,
        V2_SIGNAL_FIELDS,
        "body_bank_version",
        PodValue::from(2),
    )?;
    for (field, value) in [
        ("sector_x", x),
        ("sector_y", 1_000_000_000_000),
        ("sector_z", 1_000_000_000_000),
        ("sector_epoch", 0),
        ("category_code", category),
        ("candidate_code", -1),
        ("slot_serial", 0),
    ] {
        v2_schema_update(object, V2_SIGNAL_FIELDS, field, PodValue::from(value))?;
    }
    v2_set_zero_key(object, V2_SIGNAL_FIELDS)?;
    restamp_fixture(object)
}

fn v2_hash_in_band(hash: Hash, lower_top: u64, upper_top: u64) -> bool {
    let limbs = raw_limbs(hash);
    u256_lte([0_u64, 0, 0, lower_top], limbs) && u256_lte(limbs, [0_u64, 0, 0, upper_top])
}

fn v2_assert_stable_identifier_provenance(object: &Dictionary, label: &str) -> Result<Hash> {
    let stable_identifier = Hash::from(v2_field(object, "stable_identifier")?.raw());
    let mut initial = object.clone();
    initial
        .delete(&StrKey::from("stable_identifier"))
        .with_context(|| format!("removing {label} stable identifier for provenance check"))?;
    let expected = initial.commitment();
    if stable_identifier != expected {
        bail!(
            "{label} stable identifier lacks commitment provenance: {} != {}",
            hash_string(stable_identifier),
            hash_string(expected)
        );
    }
    Ok(stable_identifier)
}

fn v2_stamp_with_bands(
    object: &mut Dictionary,
    varying_field: &str,
    start: i64,
    stable_identifier_band: Option<(u64, u64)>,
    object_commitment_band: Option<(u64, u64)>,
    producer_class: &str,
) -> Result<(i64, JsonValue)> {
    if stable_identifier_band.is_none() && object_commitment_band.is_none() {
        bail!("{producer_class} selector search requires at least one band");
    }
    let exact_schema = v2_expected_fields(producer_class)?;
    for offset in 0_i64..4096 {
        let value = start
            .checked_add(offset)
            .context("current-v2 selector search coordinate overflow")?;
        v2_schema_update(object, exact_schema, varying_field, PodValue::from(value))?;
        restamp_fixture(object)?;
        let stable_identifier = v2_assert_stable_identifier_provenance(object, producer_class)?;
        let object_commitment = object.commitment();
        let stable_identifier_passes = stable_identifier_band
            .is_none_or(|(lower, upper)| v2_hash_in_band(stable_identifier, lower, upper));
        let object_commitment_passes = object_commitment_band
            .is_none_or(|(lower, upper)| v2_hash_in_band(object_commitment, lower, upper));
        if stable_identifier_passes && object_commitment_passes {
            return Ok((
                value,
                json!({
                    "producer_class": producer_class,
                    "varying_field": varying_field,
                    "varying_value": value,
                    "stable_identifier": hash_string(stable_identifier),
                    "stable_identifier_limbs_le": raw_limbs(stable_identifier),
                    "stable_identifier_commitment_provenance": true,
                    "stable_identifier_band_top_limbs": stable_identifier_band.map(|(lower, upper)| json!({"lower": lower, "upper": upper})),
                    "stable_identifier_band_passes": stable_identifier_passes,
                    "object_commitment": hash_string(object_commitment),
                    "object_commitment_limbs_le": raw_limbs(object_commitment),
                    "object_commitment_band_top_limbs": object_commitment_band.map(|(lower, upper)| json!({"lower": lower, "upper": upper})),
                    "object_commitment_band_passes": object_commitment_passes,
                    "attempts": offset + 1,
                    "selector_is_commitment_derived": true,
                }),
            ));
        }
    }
    bail!("unable to derive {producer_class} selector(s) in requested band(s) within 4096 attempts")
}

fn v2_mint_one(module: &sdk::SdkModule, class: &str) -> Result<Dictionary> {
    let classes = vec![class.to_string()];
    let mut objects = pexe::fixtures::mint_classes(module, &classes)?;
    if objects.len() != 1 {
        bail!(
            "expected one temporary {class} fixture, got {}",
            objects.len()
        );
    }
    Ok(objects.remove(0))
}

fn v2_tuned_signal(
    module: &sdk::SdkModule,
    category: i64,
    stable_identifier_band: Option<(u64, u64)>,
    object_commitment_band: (u64, u64),
) -> Result<(PodValue, i64, JsonValue)> {
    let mut signal = v2_mint_one(module, "microverse__celestial_signal")?;
    v2_set_signal(&mut signal, category, 1_000_000_000_000)?;
    v2_assert_exact_schema(&signal, V2_SIGNAL_FIELDS, "temporary CelestialSignal")?;
    let (x, derivation) = v2_stamp_with_bands(
        &mut signal,
        "sector_x",
        1_000_000_000_000,
        stable_identifier_band,
        Some(object_commitment_band),
        "microverse__celestial_signal",
    )?;
    Ok((v2_field(&signal, "stable_identifier")?, x, derivation))
}

fn v2_tuned_life_signal(
    module: &sdk::SdkModule,
    stable_identifier_band: (u64, u64),
    object_commitment_band: (u64, u64),
) -> Result<(PodValue, i64, JsonValue)> {
    let mut signal = v2_mint_one(module, "microverse__life_signal")?;
    v2_set_fixed_versions(&mut signal, V2_LIFE_SIGNAL_FIELDS)?;
    v2_schema_update(
        &mut signal,
        V2_LIFE_SIGNAL_FIELDS,
        "civilization_version",
        PodValue::from(2),
    )?;
    v2_schema_update(
        &mut signal,
        V2_LIFE_SIGNAL_FIELDS,
        "source_body_identifier",
        PodValue::from(Hash::from(target_raw_value(1))),
    )?;
    for (field, value) in [
        ("sector_x", 1_000_000_000_000_i64),
        ("sector_y", 1_000_000_000_000),
        ("sector_z", 1_000_000_000_000),
        ("origin_epoch", 0),
    ] {
        v2_schema_update(
            &mut signal,
            V2_LIFE_SIGNAL_FIELDS,
            field,
            PodValue::from(value),
        )?;
    }
    v2_set_zero_key(&mut signal, V2_LIFE_SIGNAL_FIELDS)?;
    restamp_fixture(&mut signal)?;
    v2_assert_exact_schema(&signal, V2_LIFE_SIGNAL_FIELDS, "temporary LifeSignal")?;
    let (x, derivation) = v2_stamp_with_bands(
        &mut signal,
        "sector_x",
        1_000_000_000_000,
        Some(stable_identifier_band),
        Some(object_commitment_band),
        "microverse__life_signal",
    )?;
    Ok((v2_field(&signal, "stable_identifier")?, x, derivation))
}

#[allow(clippy::too_many_arguments)]
fn v2_set_body(
    object: &mut Dictionary,
    source_signal_identifier: PodValue,
    x: i64,
    candidate: i64,
    body_type: i64,
    life_stat: i64,
    matter: i64,
    crystal: i64,
    gas: i64,
    energy: i64,
    satellites: i64,
) -> Result<()> {
    v2_set_fixed_versions(object, V2_BODY_FIELDS)?;
    v2_schema_update(
        object,
        V2_BODY_FIELDS,
        "body_bank_version",
        PodValue::from(2),
    )?;
    v2_schema_update(
        object,
        V2_BODY_FIELDS,
        "source_signal_identifier",
        source_signal_identifier,
    )?;
    for (field, value) in [
        ("sector_x", x),
        ("sector_y", 1_000_000_000_000),
        ("sector_z", 1_000_000_000_000),
        ("sector_epoch", 0),
        ("candidate_code", candidate),
        ("body_type", body_type),
        ("life_stat", life_stat),
        ("matter_remaining", matter),
        ("crystal_remaining", crystal),
        ("gas_remaining", gas),
        ("energy_remaining", energy),
        ("satellites_remaining", satellites),
        ("next_satellite_serial", 0),
        ("civilization_discovered", 0),
    ] {
        v2_schema_update(object, V2_BODY_FIELDS, field, PodValue::from(value))?;
    }
    v2_set_zero_key(object, V2_BODY_FIELDS)?;
    restamp_fixture(object)
}

fn v2_set_resource(object: &mut Dictionary, resource_type: i64, amount: i64) -> Result<()> {
    v2_set_fixed_versions(object, V2_RESOURCE_FIELDS)?;
    v2_schema_update(
        object,
        V2_RESOURCE_FIELDS,
        "resource_type",
        PodValue::from(resource_type),
    )?;
    v2_schema_update(object, V2_RESOURCE_FIELDS, "amount", PodValue::from(amount))?;
    restamp_fixture(object)
}

fn v2_set_composite(
    object: &mut Dictionary,
    resource_type: i64,
    child_1: i64,
    child_2: i64,
    child_3: i64,
) -> Result<()> {
    v2_set_fixed_versions(object, V2_COMPOSITE_FIELDS)?;
    for (field, value) in [
        ("resource_type", resource_type),
        ("sector_x", 1_000_000_000_000),
        ("sector_y", 1_000_000_000_000),
        ("sector_z", 1_000_000_000_000),
        ("origin_epoch", 0),
        ("child_1_remaining", child_1),
        ("child_2_remaining", child_2),
        ("child_3_remaining", child_3),
    ] {
        v2_schema_update(object, V2_COMPOSITE_FIELDS, field, PodValue::from(value))?;
    }
    restamp_fixture(object)
}

fn v2_set_civilization(
    object: &mut Dictionary,
    source_life_signal_identifier: PodValue,
    x: i64,
    civilization_type: i64,
) -> Result<()> {
    v2_set_fixed_versions(object, V2_CIVILIZATION_FIELDS)?;
    v2_schema_update(
        object,
        V2_CIVILIZATION_FIELDS,
        "civilization_version",
        PodValue::from(2),
    )?;
    v2_schema_update(
        object,
        V2_CIVILIZATION_FIELDS,
        "source_life_signal_identifier",
        source_life_signal_identifier,
    )?;
    for (field, value) in [
        ("sector_x", x),
        ("sector_y", 1_000_000_000_000),
        ("sector_z", 1_000_000_000_000),
        ("origin_epoch", 0),
        ("civilization_type", civilization_type),
    ] {
        v2_schema_update(object, V2_CIVILIZATION_FIELDS, field, PodValue::from(value))?;
    }
    v2_set_zero_key(object, V2_CIVILIZATION_FIELDS)?;
    restamp_fixture(object)
}

fn v2_set_permit(
    object: &mut Dictionary,
    industrial: i64,
    electronics: i64,
    molecular: i64,
) -> Result<()> {
    v2_set_fixed_versions(object, V2_PERMIT_FIELDS)?;
    for (field, value) in [
        ("permit_type", 1),
        ("x", 1_000_000_000_000),
        ("y", 1_000_000_000_000),
        ("z", 1_000_000_000_000),
        ("epoch", 0),
        ("industrial_authorized", industrial),
        ("electronics_authorized", electronics),
        ("molecular_authorized", molecular),
    ] {
        v2_schema_update(object, V2_PERMIT_FIELDS, field, PodValue::from(value))?;
    }
    restamp_fixture(object)
}

fn v2_set_warp_coordinate(object: &mut Dictionary) -> Result<()> {
    v2_set_fixed_versions(object, V2_WARP_COORDINATE_FIELDS)?;
    v2_schema_update(
        object,
        V2_WARP_COORDINATE_FIELDS,
        "source_body_identifier",
        PodValue::from(Hash::from(target_raw_value(1))),
    )?;
    for (field, value) in [
        ("source_pool_before", 18_000),
        ("revealed", 0),
        ("destination_code", 0),
        ("destination_x", 0),
        ("destination_y", 0),
        ("destination_z", 0),
        ("uses_remaining", 0),
    ] {
        v2_schema_update(
            object,
            V2_WARP_COORDINATE_FIELDS,
            field,
            PodValue::from(value),
        )?;
    }
    v2_set_zero_key(object, V2_WARP_COORDINATE_FIELDS)?;
    restamp_fixture(object)
}

fn v2_build_fixture(module: &sdk::SdkModule, action_name: &str) -> Result<V2CanaryFixture> {
    let fixture_seed = v2_case_seed(action_name)
        .ok_or_else(|| anyhow!("unsupported current-v2 canary action {action_name}"))?;
    pod2utils::set_seed(fixture_seed);
    let action = module
        .actions()
        .iter()
        .find(|action| action.name == action_name)
        .ok_or_else(|| anyhow!("module is missing current-v2 canary action {action_name}"))?;
    let input_classes = action
        .total_inputs()
        .map(|object| object.class.clone())
        .collect::<Vec<_>>();
    let output_classes = action
        .total_outputs()
        .map(|object| object.class.clone())
        .collect::<Vec<_>>();
    let (expected_inputs, expected_outputs) = v2_expected_topology(action_name)?;
    v2_assert_class_counts(
        &input_classes,
        &expected_inputs,
        &format!("{action_name} inputs"),
    )?;
    v2_assert_class_counts(
        &output_classes,
        &expected_outputs,
        &format!("{action_name} outputs"),
    )?;
    let mut objects = pexe::fixtures::mint_classes(module, &input_classes)?;
    let mut derivations = Vec::new();

    if let Some(spec) = v2_extraction_spec(action_name) {
        let (source, x, producer_derivation) = v2_tuned_signal(
            module,
            spec.producer_category,
            spec.stable_identifier_band,
            spec.signal_commitment_band,
        )?;
        let ship = v2_object_mut(&input_classes, &mut objects, "spaceship", 0)?;
        v2_set_ship(
            ship,
            spec.extraction_amount,
            spec.rare_extraction_amount,
            x,
            1_000_000_000_000,
            1_000_000_000_000,
            0,
            spec.required_skill,
        )?;
        v2_set_nonzero_ship_work(ship)?;
        let ship_stable_identifier =
            v2_assert_stable_identifier_provenance(ship, "extraction input Ship")?;
        let body = v2_object_mut(&input_classes, &mut objects, "celestial_body", 0)?;
        v2_set_body(
            body,
            source,
            x,
            spec.producer_candidate,
            spec.body_type,
            0,
            spec.body_pools[0],
            spec.body_pools[1],
            spec.body_pools[2],
            spec.body_pools[3],
            spec.satellites,
        )?;
        let body_stable_identifier =
            v2_assert_stable_identifier_provenance(body, "extraction input CelestialBody")?;
        let known_structural_limitation = matches!(
            spec.selector_gate,
            "upper" | "lower" | "range-lower-then-upper"
        )
        .then_some(
            "Synthetic planning of source_signal_identifier U256 selectors may panic when the mutated field is exposed as AnchoredKey. This case remains fail-closed and is not caught or converted into PASS.",
        );
        derivations.push(json!({
            "extraction_matrix": {
                "owner": spec.owner,
                "coverage": spec.coverage,
                "is_nine_owner_representative": V2_EXTRACTION_OWNER_MATRIX.contains(&action_name),
                "selector_gate": spec.selector_gate,
                "known_structural_limitation": known_structural_limitation,
                "vdf_iterations": spec.vdf_iterations,
                "producer_category": spec.producer_category,
                "producer_candidate": spec.producer_candidate,
                "producer_body_type": spec.body_type,
                "producer_body_pools": {
                    "matter_remaining": spec.body_pools[0],
                    "crystal_remaining": spec.body_pools[1],
                    "gas_remaining": spec.body_pools[2],
                    "energy_remaining": spec.body_pools[3],
                },
                "required_skill": spec.required_skill,
                "remaining_field": spec.remaining_field,
                "output_class": if spec.child_amounts.is_some() { "composite_resource" } else { "resource" },
                "output_resource_type": spec.output_resource_type,
                "extraction_amount": spec.extraction_amount,
                "rare_extraction_amount": spec.rare_extraction_amount,
                "child_amounts": spec.child_amounts,
                "stable_identifier_band_top_limbs": spec.stable_identifier_band,
                "signal_commitment_band_top_limbs": spec.signal_commitment_band,
                "input_ship_stable_identifier": hash_string(ship_stable_identifier),
                "input_ship_stable_identifier_commitment_provenance": true,
                "input_body_stable_identifier": hash_string(body_stable_identifier),
                "input_body_stable_identifier_commitment_provenance": true,
                "producer_derivation": producer_derivation,
            }
        }));
    } else {
        match action_name {
            "ClaimSector" => {
                v2_set_ship(
                    v2_object_mut(&input_classes, &mut objects, "spaceship", 0)?,
                    10,
                    1,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    0,
                    0,
                )?;
            }
            "SurveySector_01_Sparse" => {
                let (x, derivation) = {
                    let sector = v2_object_mut(&input_classes, &mut objects, "sector", 0)?;
                    v2_set_sector(sector, 1_000_000_000_000)?;
                    v2_stamp_with_bands(
                        sector,
                        "x",
                        1_000_000_000_000,
                        Some((0, 7_723_496_582_334_330_630)),
                        None,
                        "microverse__sector",
                    )?
                };
                derivations.push(derivation);
                v2_set_ship(
                    v2_object_mut(&input_classes, &mut objects, "spaceship", 0)?,
                    10,
                    1,
                    x,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    0,
                    0,
                )?;
            }
            "ScanCelestialBody_04_OceanPlanet" => {
                let (x, derivation) = {
                    let signal =
                        v2_object_mut(&input_classes, &mut objects, "celestial_signal", 0)?;
                    v2_set_signal(signal, 1, 1_000_000_000_000)?;
                    v2_stamp_with_bands(
                        signal,
                        "sector_x",
                        1_000_000_000_000,
                        None,
                        Some((7_976_970_408_395_495_922, 9_971_213_010_494_369_902)),
                        "microverse__celestial_signal",
                    )?
                };
                derivations.push(derivation);
                v2_set_ship(
                    v2_object_mut(&input_classes, &mut objects, "spaceship", 0)?,
                    10,
                    1,
                    x,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    0,
                    0,
                )?;
            }
            "RefineFerrousOreToIron" => {
                let ship = v2_object_mut(&input_classes, &mut objects, "spaceship", 0)?;
                v2_set_ship(
                    ship,
                    10,
                    1,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    0,
                    1,
                )?;
                v2_set_nonzero_ship_work(ship)?;
                v2_set_composite(
                    v2_object_mut(&input_classes, &mut objects, "composite_resource", 0)?,
                    122,
                    7,
                    2,
                    1,
                )?;
            }
            "DevelopTypeIIndustrialFabricationSkill" => {
                let (source, x, derivation) = v2_tuned_life_signal(
                    module,
                    (0, 3_074_457_344_902_430_719),
                    (0, 17_298_045_720_769_720_094),
                )?;
                derivations.push(derivation);
                v2_set_ship(
                    v2_object_mut(&input_classes, &mut objects, "spaceship", 0)?,
                    10,
                    1,
                    x,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    0,
                    0,
                )?;
                v2_set_civilization(
                    v2_object_mut(&input_classes, &mut objects, "civilization", 0)?,
                    source,
                    x,
                    1,
                )?;
            }
            "DevelopStructuralMetallurgySkill" => {
                v2_set_ship(
                    v2_object_mut(&input_classes, &mut objects, "spaceship", 0)?,
                    10,
                    1,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    0,
                    1,
                )?;
                v2_set_resource(
                    v2_object_mut(&input_classes, &mut objects, "resource", 0)?,
                    390,
                    1,
                )?;
                v2_set_resource(
                    v2_object_mut(&input_classes, &mut objects, "resource", 1)?,
                    211,
                    6,
                )?;
            }
            "FabricatePrecisionToolhead" => {
                v2_set_ship(
                    v2_object_mut(&input_classes, &mut objects, "spaceship", 0)?,
                    10,
                    1,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    0,
                    20,
                )?;
                v2_set_resource(
                    v2_object_mut(&input_classes, &mut objects, "resource", 0)?,
                    395,
                    1,
                )?;
            }
            "ExtractAnomalyWarpCoordinate" => {
                let (source, x, derivation) =
                    v2_tuned_signal(module, 7, None, (0, 6_148_914_689_804_861_439))?;
                derivations.push(derivation);
                v2_set_ship(
                    v2_object_mut(&input_classes, &mut objects, "spaceship", 0)?,
                    250,
                    25,
                    x,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    0,
                    14,
                )?;
                v2_set_body(
                    v2_object_mut(&input_classes, &mut objects, "celestial_body", 0)?,
                    source,
                    x,
                    11,
                    7,
                    0,
                    18_000,
                    9_000,
                    9_000,
                    18_000,
                    0,
                )?;
            }
            "RevealWarpCoordinate001" => {
                v2_set_warp_coordinate(v2_object_mut(
                    &input_classes,
                    &mut objects,
                    "warp_coordinate",
                    0,
                )?)?;
            }
            "AuthorizeLargeShipIndustrial" => {
                v2_set_ship(
                    v2_object_mut(&input_classes, &mut objects, "spaceship", 0)?,
                    10,
                    1,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    1_000_000_000_000,
                    0,
                    1,
                )?;
                v2_set_permit(
                    v2_object_mut(&input_classes, &mut objects, "shipyard_permit", 0)?,
                    0,
                    0,
                    0,
                )?;
            }
            "BuildShipLarge" => {
                v2_set_permit(
                    v2_object_mut(&input_classes, &mut objects, "shipyard_permit", 0)?,
                    1,
                    1,
                    1,
                )?;
                let recipe = [
                    (1, 50),
                    (2, 50),
                    (4, 50),
                    (211, 30),
                    (196, 30),
                    (197, 15),
                    (161, 30),
                    (164, 30),
                    (200, 15),
                    (212, 5),
                ];
                for (occurrence, (resource_type, amount)) in recipe.into_iter().enumerate() {
                    v2_set_resource(
                        v2_object_mut(&input_classes, &mut objects, "resource", occurrence)?,
                        resource_type,
                        amount,
                    )?;
                }
            }
            _ => bail!("unsupported current-v2 canary action {action_name}"),
        }
    }

    if input_classes.len() != objects.len() {
        bail!("current-v2 fixture class/object count mismatch");
    }
    for (index, (class, object)) in input_classes.iter().zip(&objects).enumerate() {
        v2_assert_exact_schema(
            object,
            v2_expected_fields(class)?,
            &format!("{action_name} input {index} ({class})"),
        )?;
    }
    Ok(V2CanaryFixture {
        input_classes,
        objects,
        derivation: json!({
            "fixture_seed": fixture_seed,
            "selectors": derivations,
            "predecessor_transactions_proved": false,
            "fixtures_are_offline_class_shaped": true,
        }),
    })
}

fn v2_sorted_hashes(mut values: Vec<Hash>) -> Vec<String> {
    let mut encoded = values.drain(..).map(hash_string).collect::<Vec<_>>();
    encoded.sort();
    encoded
}

fn v2_payload_with_build(
    outputs: &sdk::SpendableObjects,
    state_root: Hash,
    proof_build: Option<&ShrunkMainPodBuild>,
) -> Result<PayloadMetrics> {
    let started = Instant::now();
    let proof = if let Some(proof_build) = proof_build {
        let compressed = shrink_compress_pod(proof_build, outputs.tx_pod.clone())
            .context("shrinking and compressing current-v2 canary proof")?;
        PayloadProof::Plonky2(Box::new(compressed))
    } else {
        PayloadProof::empty_for_test()
    };
    let mut serialized_proof = Vec::new();
    proof.write_bytes(&mut serialized_proof);
    let payload = Payload {
        proof,
        tx_final: outputs.tx.dict().commitment(),
        state_root,
        nullifiers: outputs.tx.nullifier_hashes()?,
        live: outputs.tx.live_commitments()?,
    };
    let payload_bytes = payload.to_bytes().len();
    let utilization = payload_bytes as f64 / PAYLOAD_HARD_LIMIT_BYTES as f64;
    Ok(PayloadMetrics {
        payload_bytes,
        serialized_proof_bytes: serialized_proof.len(),
        live_count: payload.live.len(),
        nullifier_count: payload.nullifiers.len(),
        seconds: started.elapsed().as_secs_f64(),
        headroom_bytes: PAYLOAD_HARD_LIMIT_BYTES as i64 - payload_bytes as i64,
        utilization,
        utilization_percent: utilization * 100.0,
        fits_hard_limit: payload_bytes <= PAYLOAD_HARD_LIMIT_BYTES,
    })
}

fn v2_expect_int(
    assertions: &mut BTreeMap<String, bool>,
    classes: &[String],
    objects: &[SpendableObject],
    suffix: &str,
    field: &str,
    expected: i64,
) {
    let result = unique_class_object(classes, objects, suffix)
        .and_then(|(_, object)| object_int(object, field))
        .is_ok_and(|actual| actual == expected);
    assertions.insert(format!("{suffix}.{field}_equals_{expected}"), result);
}

fn v2_extraction_assertions(
    assertions: &mut BTreeMap<String, bool>,
    spec: V2ExtractionSpec,
    ship_identity_mode: V2ShipIdentityMode,
    input_classes: &[String],
    inputs: &[SpendableObject],
    output_classes: &[String],
    outputs: &[SpendableObject],
    live_commitments: &[String],
    nullifiers: &[String],
) {
    let input_ship = unique_class_object(input_classes, inputs, "spaceship")
        .ok()
        .map(|(_, object)| object);
    let output_ship = unique_class_object(output_classes, outputs, "spaceship")
        .ok()
        .map(|(_, object)| object);
    let input_body = unique_class_object(input_classes, inputs, "celestial_body")
        .ok()
        .map(|(_, object)| object);
    let output_body = unique_class_object(output_classes, outputs, "celestial_body")
        .ok()
        .map(|(_, object)| object);

    bool_assertion(
        assertions,
        "extraction.owner_is_registered",
        matches!(
            spec.owner,
            "extract_base_action"
                | "extract_direct_ungated_action"
                | "extract_direct_upper_action"
                | "extract_direct_lower_action"
                | "extract_direct_range_action"
                | "extract_composite_ungated_action"
                | "extract_composite_upper_action"
                | "extract_composite_lower_action"
                | "extract_composite_range_action"
        ),
    );
    let mut expected_live_commitments = outputs
        .iter()
        .map(|output| hash_string(output.obj.commitment()))
        .collect::<Vec<_>>();
    expected_live_commitments.sort();
    let expected_ship_nullifier = input_ship.map(|ship| hash_string(compute_nullifier(&ship.obj)));
    let expected_body_nullifier = input_body.map(|body| hash_string(compute_nullifier(&body.obj)));
    let mut expected_nullifiers = expected_ship_nullifier
        .iter()
        .chain(expected_body_nullifier.iter())
        .cloned()
        .collect::<Vec<_>>();
    expected_nullifiers.sort();
    bool_assertion(
        assertions,
        "transaction.exactly_three_outputs_are_live",
        outputs.len() == 3 && live_commitments.len() == 3,
    );
    bool_assertion(
        assertions,
        "transaction.exactly_two_inputs_are_nullified",
        inputs.len() == 2 && nullifiers.len() == 2,
    );
    bool_assertion(
        assertions,
        "transaction.exact_live_commitments_match_all_three_declared_outputs",
        outputs.len() == 3
            && live_commitments.len() == 3
            && live_commitments == expected_live_commitments.as_slice(),
    );
    bool_assertion(
        assertions,
        "transaction.exact_nullifiers_match_ship_and_body_inputs",
        inputs.len() == 2 && nullifiers.len() == 2 && nullifiers == expected_nullifiers.as_slice(),
    );
    bool_assertion(
        assertions,
        "transaction.ship_input_nullifier_appears_exactly_once",
        expected_ship_nullifier.is_some_and(|expected| {
            nullifiers
                .iter()
                .filter(|nullifier| nullifier.as_str() == expected.as_str())
                .count()
                == 1
        }),
    );
    bool_assertion(
        assertions,
        "transaction.body_input_nullifier_appears_exactly_once",
        expected_body_nullifier.is_some_and(|expected| {
            nullifiers
                .iter()
                .filter(|nullifier| nullifier.as_str() == expected.as_str())
                .count()
                == 1
        }),
    );
    bool_assertion(
        assertions,
        "spaceship.input_work_is_nonzero",
        input_ship.is_some_and(|ship| {
            object_field(ship, "work").is_ok_and(|work| work.raw() != EMPTY_VALUE)
        }),
    );
    bool_assertion(
        assertions,
        "spaceship.output_work_is_exact_zero",
        output_ship.is_some_and(|ship| {
            object_field(ship, "work").is_ok_and(|work| work.raw() == EMPTY_VALUE)
        }),
    );
    bool_assertion(
        assertions,
        "spaceship.input_skill_matches_action",
        input_ship.is_some_and(|ship| fixed_int_is(ship, "active_skill_type", spec.required_skill)),
    );
    bool_assertion(
        assertions,
        "spaceship.output_skill_is_reset",
        output_ship.is_some_and(|ship| fixed_int_is(ship, "active_skill_type", 0)),
    );
    bool_assertion(
        assertions,
        "spaceship.action_serial_increments_once",
        input_ship
            .zip(output_ship)
            .is_some_and(|(before, after)| serial_delta(before, after, "action_serial") == Some(1)),
    );
    bool_assertion(
        assertions,
        "spaceship.key_rotates",
        input_ship
            .zip(output_ship)
            .is_some_and(|(before, after)| !same_field(before, after, "key")),
    );
    match ship_identity_mode {
        V2ShipIdentityMode::Replacement => {
            bool_assertion(
                assertions,
                "spaceship.replacement_mode_stable_identifier_changes",
                input_ship
                    .zip(output_ship)
                    .is_some_and(|(before, after)| !same_field(before, after, "stable_identifier")),
            );
            bool_assertion(
                assertions,
                "spaceship.replacement_mode_no_fields_outside_managed_set_change",
                input_ship.zip(output_ship).is_some_and(|(before, after)| {
                    fields_equal_except(
                        before,
                        after,
                        &[
                            "key",
                            "work",
                            "active_skill_type",
                            "action_serial",
                            "stable_identifier",
                        ],
                    )
                    .unwrap_or(false)
                }),
            );
        }
        V2ShipIdentityMode::Mutation => {
            bool_assertion(
                assertions,
                "spaceship.mutation_mode_stable_identifier_is_preserved",
                input_ship
                    .zip(output_ship)
                    .is_some_and(|(before, after)| same_field(before, after, "stable_identifier")),
            );
            bool_assertion(
                assertions,
                "spaceship.mutation_mode_no_fields_outside_managed_set_change",
                input_ship.zip(output_ship).is_some_and(|(before, after)| {
                    fields_equal_except(
                        before,
                        after,
                        &["key", "work", "active_skill_type", "action_serial"],
                    )
                    .unwrap_or(false)
                }),
            );
        }
    }
    bool_assertion(
        assertions,
        "spaceship.capacity_matches_action_and_is_preserved",
        input_ship.zip(output_ship).is_some_and(|(before, after)| {
            fixed_int_is(before, "extraction_amount", spec.extraction_amount)
                && fixed_int_is(
                    before,
                    "rare_extraction_amount",
                    spec.rare_extraction_amount,
                )
                && same_field(before, after, "extraction_amount")
                && same_field(before, after, "rare_extraction_amount")
        }),
    );
    bool_assertion(
        assertions,
        "celestial_body.producer_candidate_and_body_type_match",
        input_body.is_some_and(|body| {
            fixed_int_is(body, "candidate_code", spec.producer_candidate)
                && fixed_int_is(body, "body_type", spec.body_type)
                && fixed_int_is(body, "body_bank_version", 2)
        }),
    );
    bool_assertion(
        assertions,
        "celestial_body.key_rotates",
        input_body
            .zip(output_body)
            .is_some_and(|(before, after)| !same_field(before, after, "key")),
    );
    bool_assertion(
        assertions,
        "celestial_body.stable_identifier_is_preserved",
        input_body
            .zip(output_body)
            .is_some_and(|(before, after)| same_field(before, after, "stable_identifier")),
    );
    bool_assertion(
        assertions,
        "celestial_body.work_is_refreshed_by_vdf",
        input_body.zip(output_body).is_some_and(|(before, after)| {
            !same_field(before, after, "work")
                && object_field(after, "work").is_ok_and(|work| work.raw() != EMPTY_VALUE)
        }),
    );
    bool_assertion(
        assertions,
        "celestial_body.only_key_work_and_selected_pool_change",
        input_body.zip(output_body).is_some_and(|(before, after)| {
            fields_equal_except(before, after, &["key", "work", spec.remaining_field])
                .unwrap_or(false)
        }),
    );

    let pool_fields = [
        "matter_remaining",
        "crystal_remaining",
        "gas_remaining",
        "energy_remaining",
    ];
    for (index, field) in pool_fields.iter().enumerate() {
        let expected_before = spec.body_pools[index];
        bool_assertion(
            assertions,
            format!("celestial_body.input_{field}_is_producer_shaped"),
            input_body.is_some_and(|body| fixed_int_is(body, field, expected_before)),
        );
        if *field == spec.remaining_field {
            let expected_after = expected_before - spec.extraction_amount;
            bool_assertion(
                assertions,
                format!("celestial_body.selected_{field}_decrements_exactly"),
                output_body.is_some_and(|body| fixed_int_is(body, field, expected_after)),
            );
        } else {
            bool_assertion(
                assertions,
                format!("celestial_body.nonselected_{field}_is_unchanged"),
                input_body
                    .zip(output_body)
                    .is_some_and(|(before, after)| same_field(before, after, field)),
            );
        }
    }

    for (ship_field, body_field) in [
        ("x", "sector_x"),
        ("y", "sector_y"),
        ("z", "sector_z"),
        ("epoch", "sector_epoch"),
    ] {
        bool_assertion(
            assertions,
            format!("location.input_ship_{ship_field}_matches_body_{body_field}"),
            input_ship
                .zip(input_body)
                .is_some_and(|(ship, body)| cross_field_equal(ship, ship_field, body, body_field)),
        );
        bool_assertion(
            assertions,
            format!("location.output_ship_{ship_field}_matches_body_{body_field}"),
            output_ship
                .zip(output_body)
                .is_some_and(|(ship, body)| cross_field_equal(ship, ship_field, body, body_field)),
        );
    }

    let output_suffix = if spec.child_amounts.is_some() {
        "composite_resource"
    } else {
        "resource"
    };
    let extracted = unique_class_object(output_classes, outputs, output_suffix)
        .ok()
        .map(|(_, object)| object);
    bool_assertion(
        assertions,
        format!("{output_suffix}.fixed_protocol_versions"),
        extracted.is_some_and(|object| {
            fixed_int_is(object, "schema_version", 2)
                && fixed_int_is(object, "mechanics_version", 2)
                && fixed_int_is(object, "universe_version", 2)
        }),
    );
    bool_assertion(
        assertions,
        format!("{output_suffix}.resource_type_matches_action"),
        extracted
            .is_some_and(|object| fixed_int_is(object, "resource_type", spec.output_resource_type)),
    );
    bool_assertion(
        assertions,
        format!("{output_suffix}.work_is_exact_zero"),
        extracted.is_some_and(|object| {
            object_field(object, "work").is_ok_and(|work| work.raw() == EMPTY_VALUE)
        }),
    );
    if let Some(children) = spec.child_amounts {
        for (field, expected) in [
            ("child_1_remaining", children[0]),
            ("child_2_remaining", children[1]),
            ("child_3_remaining", children[2]),
        ] {
            bool_assertion(
                assertions,
                format!("composite_resource.{field}_matches_action"),
                extracted.is_some_and(|object| fixed_int_is(object, field, expected)),
            );
        }
        for (resource_field, ship_field) in [
            ("sector_x", "x"),
            ("sector_y", "y"),
            ("sector_z", "z"),
            ("origin_epoch", "epoch"),
        ] {
            bool_assertion(
                assertions,
                format!("composite_resource.{resource_field}_matches_ship_{ship_field}"),
                extracted.zip(input_ship).is_some_and(|(resource, ship)| {
                    cross_field_equal(resource, resource_field, ship, ship_field)
                }),
            );
        }
    } else {
        bool_assertion(
            assertions,
            "resource.amount_matches_extraction_capacity",
            extracted
                .is_some_and(|resource| fixed_int_is(resource, "amount", spec.extraction_amount)),
        );
    }
}

fn v2_case_assertions(
    action: &str,
    ship_identity_mode: V2ShipIdentityMode,
    input_classes: &[String],
    inputs: &[SpendableObject],
    output_classes: &[String],
    outputs: &[SpendableObject],
    live_commitments: &[String],
    nullifiers: &[String],
) -> BTreeMap<String, bool> {
    let mut assertions = BTreeMap::new();
    if let Some(spec) = v2_extraction_spec(action) {
        v2_extraction_assertions(
            &mut assertions,
            spec,
            ship_identity_mode,
            input_classes,
            inputs,
            output_classes,
            outputs,
            live_commitments,
            nullifiers,
        );
        return assertions;
    }
    match action {
        "ClaimSector" => {
            for (field, expected) in [
                ("sector_type", 0),
                ("survey_profile", 0),
                ("planet_remaining", 0),
                ("star_remaining", 0),
                ("minor_body_field_remaining", 0),
                ("next_minor_body_field_serial", 0),
            ] {
                v2_expect_int(
                    &mut assertions,
                    output_classes,
                    outputs,
                    "sector",
                    field,
                    expected,
                );
            }
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "spaceship",
                "action_serial",
                1,
            );
        }
        "SurveySector_01_Sparse" => {
            for (field, expected) in [
                ("sector_type", 1),
                ("survey_profile", 1),
                ("planet_remaining", 1),
                ("star_remaining", 1),
                ("minor_body_field_remaining", 1),
                ("revision", 1),
            ] {
                v2_expect_int(
                    &mut assertions,
                    output_classes,
                    outputs,
                    "sector",
                    field,
                    expected,
                );
            }
        }
        "ScanCelestialBody_04_OceanPlanet" => {
            for (field, expected) in [
                ("candidate_code", 4),
                ("body_type", 1),
                ("life_stat", 0),
                ("matter_remaining", 14_000),
                ("crystal_remaining", 3_000),
                ("gas_remaining", 14_000),
                ("energy_remaining", 3_000),
                ("satellites_remaining", 2),
            ] {
                v2_expect_int(
                    &mut assertions,
                    output_classes,
                    outputs,
                    "celestial_body",
                    field,
                    expected,
                );
            }
        }
        "RefineFerrousOreToIron" => {
            let input_work_is_nonzero = unique_class_object(input_classes, inputs, "spaceship")
                .and_then(|(_, ship)| object_field(ship, "work"))
                .is_ok_and(|work| work.raw() != EMPTY_VALUE);
            assertions.insert(
                "spaceship.input_work_is_nonzero".to_string(),
                input_work_is_nonzero,
            );
            let output_work_is_exact_zero =
                unique_class_object(output_classes, outputs, "spaceship")
                    .and_then(|(_, ship)| object_field(ship, "work"))
                    .is_ok_and(|work| work.raw() == EMPTY_VALUE);
            assertions.insert(
                "spaceship.output_work_is_exact_zero".to_string(),
                output_work_is_exact_zero,
            );
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "resource",
                "resource_type",
                156,
            );
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "resource",
                "amount",
                7,
            );
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "composite_resource",
                "child_1_remaining",
                0,
            );
        }
        "DevelopTypeIIndustrialFabricationSkill" => {
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "technology_skill",
                "skill_type",
                1,
            );
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "technology_skill",
                "reusable",
                1,
            );
        }
        "DevelopStructuralMetallurgySkill" => {
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "technology_skill",
                "skill_type",
                19,
            );
        }
        "FabricatePrecisionToolhead" => {
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "resource",
                "resource_type",
                630,
            );
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "resource",
                "amount",
                1,
            );
        }
        "ExtractAnomalyWarpCoordinate" => {
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "warp_coordinate",
                "source_pool_before",
                18_000,
            );
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "celestial_body",
                "energy_remaining",
                9_000,
            );
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "warp_coordinate",
                "revealed",
                0,
            );
        }
        "RevealWarpCoordinate001" => {
            for (field, expected) in [
                ("revealed", 1),
                ("destination_code", 1),
                ("destination_x", 793_814_733),
                ("destination_y", 968_149_119_310),
                ("destination_z", 42_019_687_806),
                ("uses_remaining", 10),
            ] {
                v2_expect_int(
                    &mut assertions,
                    output_classes,
                    outputs,
                    "warp_coordinate",
                    field,
                    expected,
                );
            }
        }
        "AuthorizeLargeShipIndustrial" => {
            for (field, expected) in [
                ("industrial_authorized", 1),
                ("electronics_authorized", 0),
                ("molecular_authorized", 0),
            ] {
                v2_expect_int(
                    &mut assertions,
                    output_classes,
                    outputs,
                    "shipyard_permit",
                    field,
                    expected,
                );
            }
        }
        "BuildShipLarge" => {
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "spaceship",
                "extraction_amount",
                250,
            );
            v2_expect_int(
                &mut assertions,
                output_classes,
                outputs,
                "spaceship",
                "rare_extraction_amount",
                25,
            );
            for field in ["x", "y", "z"] {
                v2_expect_int(
                    &mut assertions,
                    output_classes,
                    outputs,
                    "spaceship",
                    field,
                    1_000_000_000_000,
                );
            }
        }
        _ => {
            assertions.insert("known_action".to_string(), false);
        }
    }
    assertions
}

fn v2_run_case(
    module: &std::rc::Rc<sdk::SdkModule>,
    action_name: &str,
    ship_identity_mode: V2ShipIdentityMode,
    proof_build: Option<&ShrunkMainPodBuild>,
    mock_only: bool,
) -> Result<JsonValue> {
    let fixture = v2_build_fixture(module, action_name)?;
    let state = pexe::fixtures::build_synthetic_state(&fixture.objects)?;
    let input_reports = class_object_reports(&fixture.input_classes, &state.spendable)?;
    let state_root = state.grounding_witness.state_header.hash();
    let action = module
        .actions()
        .iter()
        .find(|action| action.name == action_name)
        .ok_or_else(|| anyhow!("module is missing current-v2 canary action {action_name}"))?;
    let output_classes = action
        .total_outputs()
        .map(|object| object.class.clone())
        .collect::<Vec<_>>();

    let planning_started = Instant::now();
    let plan = module
        .executor(true, state.grounding_witness.clone())
        .plan_action(action_name, state.spendable.clone())
        .with_context(|| format!("planning current-v2 canary {action_name}"))?;
    let planning_seconds = planning_started.elapsed().as_secs_f64();
    let solution = plan.solved.solution();
    let pods = solution.pod_statements.len();
    let output_pods = (0..pods)
        .filter(|index| solution.is_output_pod(*index))
        .count();
    let assigned_statement_slots = solution.pod_statements.iter().map(Vec::len).sum::<usize>();

    let action_seed = v2_case_seed(action_name)
        .context("current-v2 canary action has no deterministic seed")?
        ^ 0xa5a5_a5a5_a5a5_a5a5;
    pod2utils::set_seed(action_seed);
    let mock_started = Instant::now();
    let mock = module
        .executor(true, state.grounding_witness.clone())
        .action(action_name, state.spendable.clone())
        .with_context(|| format!("executing mock current-v2 canary {action_name}"))?;
    let mock_execution_seconds = mock_started.elapsed().as_secs_f64();

    if mock_only {
        if proof_build.is_some() {
            bail!("mock-only current-v2 canary unexpectedly received a real proof build");
        }
        v2_assert_output_schemas(action_name, &output_classes, &mock.objs)?;
        let mock_outputs = class_object_reports(&output_classes, &mock.objs)?;
        let mock_live = v2_sorted_hashes(mock.tx.live_commitments()?);
        let mock_nullifiers = v2_sorted_hashes(mock.tx.nullifier_hashes()?);
        let mock_payload = v2_payload_with_build(&mock, state_root, None)?;
        let semantic_assertions = v2_case_assertions(
            action_name,
            ship_identity_mode,
            &fixture.input_classes,
            &state.spendable,
            &output_classes,
            &mock.objs,
            &mock_live,
            &mock_nullifiers,
        );
        let semantic_pass = semantic_assertions.values().all(|pass| *pass);
        let payload_pass = mock_payload.fits_hard_limit;
        return Ok(json!({
            "status": if semantic_pass && payload_pass { "pass" } else { "fail" },
            "mode": "mock-only",
            "real_executor_invoked": false,
            "shrink_proof_build_constructed": false,
            "action": action_name,
            "ship_identity_expectation": ship_identity_mode.report_name(),
            "fixture": fixture.derivation,
            "input_classes": fixture.input_classes,
            "output_classes": output_classes,
            "inputs": input_reports,
            "plan": {
                "seconds": planning_seconds,
                "statements": plan.statements.len(),
                "operations": plan.operations.len(),
                "pods": pods,
                "output_pods": output_pods,
                "assigned_statement_slots": assigned_statement_slots,
            },
            "state_root": hash_string(state_root),
            "action_seed": action_seed,
            "semantic_assertions": semantic_assertions,
            "mock": {
                "execution_seconds": mock_execution_seconds,
                "outputs": mock_outputs,
                "live_commitments": mock_live,
                "nullifiers": mock_nullifiers,
                "payload_bytes": mock_payload.payload_bytes,
                "proof_bytes": mock_payload.serialized_proof_bytes,
                "payload_seconds": mock_payload.seconds,
                "payload_headroom_bytes": mock_payload.headroom_bytes,
                "payload_fits_hard_limit": mock_payload.fits_hard_limit,
            },
        }));
    }

    pod2utils::set_seed(action_seed);
    let real_started = Instant::now();
    let real = module
        .executor(false, state.grounding_witness.clone())
        .action(action_name, state.spendable.clone())
        .with_context(|| format!("executing real current-v2 canary {action_name}"))?;
    let real_execution_seconds = real_started.elapsed().as_secs_f64();

    v2_assert_output_schemas(action_name, &output_classes, &mock.objs)?;
    v2_assert_output_schemas(action_name, &output_classes, &real.objs)?;

    let mock_outputs = class_object_reports(&output_classes, &mock.objs)?;
    let real_outputs = class_object_reports(&output_classes, &real.objs)?;
    let mock_live = v2_sorted_hashes(mock.tx.live_commitments()?);
    let real_live = v2_sorted_hashes(real.tx.live_commitments()?);
    let mock_nullifiers = v2_sorted_hashes(mock.tx.nullifier_hashes()?);
    let real_nullifiers = v2_sorted_hashes(real.tx.nullifier_hashes()?);
    let mock_payload = v2_payload_with_build(&mock, state_root, None)?;
    let real_payload = v2_payload_with_build(&real, state_root, proof_build)?;
    let semantic_assertions = v2_case_assertions(
        action_name,
        ship_identity_mode,
        &fixture.input_classes,
        &state.spendable,
        &output_classes,
        &real.objs,
        &real_live,
        &real_nullifiers,
    );
    let semantic_pass = semantic_assertions.values().all(|pass| *pass);
    let pair_assertions = json!({
        "mock_real_full_outputs_equal": mock_outputs == real_outputs,
        "mock_real_live_commitments_equal": mock_live == real_live,
        "mock_real_nullifiers_equal": mock_nullifiers == real_nullifiers,
        "mock_payload_fits_hard_limit": mock_payload.fits_hard_limit,
        "real_payload_fits_hard_limit": real_payload.fits_hard_limit,
    });
    let pair_pass = pair_assertions
        .as_object()
        .is_some_and(|values| values.values().all(|value| value == &JsonValue::Bool(true)));

    Ok(json!({
        "status": if pair_pass && semantic_pass { "pass" } else { "fail" },
        "action": action_name,
        "ship_identity_expectation": ship_identity_mode.report_name(),
        "fixture": fixture.derivation,
        "input_classes": fixture.input_classes,
        "output_classes": output_classes,
        "inputs": input_reports,
        "plan": {
            "seconds": planning_seconds,
            "statements": plan.statements.len(),
            "operations": plan.operations.len(),
            "pods": pods,
            "output_pods": output_pods,
            "assigned_statement_slots": assigned_statement_slots,
        },
        "state_root": hash_string(state_root),
        "action_seed": action_seed,
        "pair_assertions": pair_assertions,
        "semantic_assertions": semantic_assertions,
        "mock": {
            "execution_seconds": mock_execution_seconds,
            "outputs": mock_outputs,
            "live_commitments": mock_live,
            "nullifiers": mock_nullifiers,
            "payload_bytes": mock_payload.payload_bytes,
            "proof_bytes": mock_payload.serialized_proof_bytes,
            "payload_seconds": mock_payload.seconds,
            "payload_headroom_bytes": mock_payload.headroom_bytes,
            "payload_fits_hard_limit": mock_payload.fits_hard_limit,
        },
        "real": {
            "execution_seconds": real_execution_seconds,
            "outputs": real_outputs,
            "live_commitments": real_live,
            "nullifiers": real_nullifiers,
            "payload_bytes": real_payload.payload_bytes,
            "proof_bytes": real_payload.serialized_proof_bytes,
            "payload_seconds": real_payload.seconds,
            "payload_headroom_bytes": real_payload.headroom_bytes,
            "payload_fits_hard_limit": real_payload.fits_hard_limit,
        },
    }))
}

fn v2_atomic_write_new(path: &Path, encoded: &str) -> Result<()> {
    if path.exists() {
        bail!(
            "refusing to overwrite durable canary evidence {}",
            path.display()
        );
    }
    let parent = path
        .parent()
        .ok_or_else(|| anyhow!("durable canary evidence path has no parent"))?;
    if !parent.is_dir() {
        bail!(
            "durable canary evidence directory does not exist: {}",
            parent.display()
        );
    }
    let file_name = path
        .file_name()
        .and_then(|name| name.to_str())
        .context("durable canary evidence filename is not UTF-8")?;
    let temporary = parent.join(format!(".{file_name}.tmp-{}", std::process::id()));
    if temporary.exists() {
        bail!(
            "durable canary temporary path already exists: {}",
            temporary.display()
        );
    }
    fs::write(&temporary, encoded)
        .with_context(|| format!("writing temporary evidence {}", temporary.display()))?;
    fs::rename(&temporary, path)
        .with_context(|| format!("atomically publishing evidence {}", path.display()))?;
    Ok(())
}

fn v2_case_evidence_path(case_dir: &Path, action: &str) -> Result<PathBuf> {
    let index = V2_CANARY_ACTIONS
        .iter()
        .position(|candidate| *candidate == action)
        .ok_or_else(|| anyhow!("unsupported current-v2 canary action {action}"))?;
    Ok(case_dir.join(format!("{:02}-{action}.json", index + 1)))
}

#[allow(clippy::too_many_arguments)]
fn v2_top_level_report(
    status: &str,
    mock_only: bool,
    ship_identity_mode: V2ShipIdentityMode,
    module_hash: &str,
    manifest_hash: &str,
    selected_actions: &[String],
    cases: &[JsonValue],
    case_evidence: &[String],
    started: Instant,
    blocked: Option<JsonValue>,
) -> JsonValue {
    let passed = cases
        .iter()
        .filter(|case| case.get("status") == Some(&JsonValue::String("pass".to_string())))
        .count();
    json!({
        "schema": V2_CANARY_SCHEMA,
        "status": status,
        "mode": if mock_only { "mock-only" } else { "paired-mock-real" },
        "ship_identity_expectation": ship_identity_mode.report_name(),
        "scope": if mock_only {
            "offline current-v2 plan + mock action canaries"
        } else {
            "offline current-v2 plan + paired mock/real action proofs"
        },
        "real_executor_invoked": !mock_only,
        "shrink_proof_build_constructed": !mock_only,
        "module_hash": module_hash,
        "manifest_module_hash": manifest_hash,
        "selected_actions": selected_actions,
        "selected_action_count": selected_actions.len(),
        "extraction_owner_matrix": V2_EXTRACTION_OWNER_MATRIX,
        "completed_case_count": cases.len(),
        "passed": passed,
        "failed": cases.len() - passed + usize::from(blocked.is_some()),
        "seconds": started.elapsed().as_secs_f64(),
        "case_evidence": case_evidence,
        "blocked": blocked,
        "external_network_used": false,
        "external_state_committed": false,
        "driver_used": false,
        "synchronizer_used": false,
        "install_performed": false,
        "publish_performed": false,
        "published_commitments": 0,
        "published_nullifiers": 0,
        "limitations": [
            "Input membership is fabricated offline; predecessor transactions are not proved.",
            "Survey, Scan, extraction, and initial-skill selectors are derived from exact producer-shaped object commitments.",
            "Synthetic planning may panic when a mutated CelestialBody source_signal_identifier is exposed as AnchoredKey to an upper/lower/range U256 comparison. Selector-bearing extraction cases retain that fail-closed behavior; base and candidate-only owner cases remain independently selectable.",
            "Authorization and Build are independently proved; Build receives a fully authorized offline permit fixture.",
        ],
        "cases": cases,
    })
}

fn v2_proof_canaries(
    plugin_root: &Path,
    output: &Path,
    case_dir: &Path,
    selected_actions: &[String],
    mock_only: bool,
    ship_identity_mode: V2ShipIdentityMode,
) -> Result<()> {
    if selected_actions.is_empty() {
        bail!("current-v2 canary selection may not be empty");
    }
    if !case_dir.is_dir() {
        bail!("required --case-dir does not exist: {}", case_dir.display());
    }
    let (_source, module) = load_module(plugin_root)?;
    let manifest = pexe::PluginSource::read(plugin_root)?.parse_manifest()?;
    let module_hash = hash_string(module.module().batch.id());
    let manifest_hash = hash_string(manifest.plugin.module_hash);
    if module_hash != manifest_hash {
        bail!(
            "current-v2 canary module hash differs from manifest: {module_hash} != {manifest_hash}"
        );
    }

    let proof_build = if mock_only {
        None
    } else {
        let params = Params::default();
        Some(
            ShrunkMainPodSetup::new(&params)
                .build()
                .context("building current-v2 canary shrink wrapper")?,
        )
    };
    let started = Instant::now();
    let mut cases = Vec::with_capacity(selected_actions.len());
    let mut case_evidence = Vec::with_capacity(selected_actions.len());
    for action in selected_actions {
        println!(
            "current-v2 proof canary {}/{}: {action}",
            cases.len() + 1,
            selected_actions.len()
        );
        let case = match v2_run_case(
            &module,
            action,
            ship_identity_mode,
            proof_build.as_ref(),
            mock_only,
        ) {
            Ok(case) => case,
            Err(error) => {
                pod2utils::clear_seed();
                let report = v2_top_level_report(
                    "fail",
                    mock_only,
                    ship_identity_mode,
                    &module_hash,
                    &manifest_hash,
                    selected_actions,
                    &cases,
                    &case_evidence,
                    started,
                    Some(json!({
                        "action": action,
                        "rejection_modality": "returned_error",
                        "error": format!("{error:#}"),
                    })),
                );
                let encoded = serde_json::to_string_pretty(&report)? + "\n";
                v2_atomic_write_new(output, &encoded)?;
                println!("{encoded}");
                return Err(error)
                    .with_context(|| format!("current-v2 canary {action} returned an error"));
            }
        };
        let case_path = v2_case_evidence_path(case_dir, action)?;
        let encoded_case = serde_json::to_string_pretty(&case)? + "\n";
        v2_atomic_write_new(&case_path, &encoded_case)?;
        case_evidence.push(
            case_path
                .file_name()
                .and_then(|name| name.to_str())
                .context("durable case evidence filename is not UTF-8")?
                .to_string(),
        );
        cases.push(case);
    }
    pod2utils::clear_seed();
    let passed = cases
        .iter()
        .filter(|case| case.get("status") == Some(&JsonValue::String("pass".to_string())))
        .count();
    let report = v2_top_level_report(
        if passed == cases.len() {
            "pass"
        } else {
            "fail"
        },
        mock_only,
        ship_identity_mode,
        &module_hash,
        &manifest_hash,
        selected_actions,
        &cases,
        &case_evidence,
        started,
        None,
    );
    let encoded = serde_json::to_string_pretty(&report)? + "\n";
    v2_atomic_write_new(output, &encoded)?;
    println!("{encoded}");
    if passed != selected_actions.len() {
        bail!("one or more current-v2 proof canaries failed");
    }
    Ok(())
}

fn v2_normalize_pair_report(report: &mut JsonValue) {
    fn walk(value: &mut JsonValue, key: Option<&str>) {
        if key.is_some_and(|key| key == "seconds" || key.ends_with("_seconds")) {
            *value = JsonValue::Null;
            return;
        }
        match value {
            JsonValue::Object(map) => {
                for (child_key, child) in map.iter_mut() {
                    walk(child, Some(child_key));
                }
            }
            JsonValue::Array(values) => {
                for child in values {
                    walk(child, None);
                }
            }
            _ => {}
        }
    }
    walk(report, None);
}

fn v2_compare_reports(
    baseline_path: &Path,
    candidate_path: &Path,
    output: Option<PathBuf>,
) -> Result<()> {
    let mut baseline: JsonValue = serde_json::from_slice(
        &fs::read(baseline_path).with_context(|| format!("reading {}", baseline_path.display()))?,
    )?;
    let mut candidate: JsonValue = serde_json::from_slice(
        &fs::read(candidate_path)
            .with_context(|| format!("reading {}", candidate_path.display()))?,
    )?;
    if baseline.get("schema") != Some(&JsonValue::String(V2_CANARY_SCHEMA.to_string()))
        || candidate.get("schema") != Some(&JsonValue::String(V2_CANARY_SCHEMA.to_string()))
    {
        bail!("baseline/candidate reports are not {V2_CANARY_SCHEMA}");
    }
    if baseline.get("selected_actions") != candidate.get("selected_actions") {
        bail!("baseline/candidate reports do not select the same exact action list/order");
    }
    if baseline.get("selected_action_count") != candidate.get("selected_action_count") {
        bail!("baseline/candidate selected action counts differ");
    }
    if baseline.get("module_hash") != candidate.get("module_hash")
        || baseline.get("manifest_module_hash") != candidate.get("manifest_module_hash")
    {
        bail!("baseline/candidate reports do not identify the same module");
    }
    if baseline.get("status") != Some(&JsonValue::String("pass".to_string()))
        || candidate.get("status") != Some(&JsonValue::String("pass".to_string()))
    {
        bail!("baseline/candidate reports must both be complete PASS reports");
    }
    v2_normalize_pair_report(&mut baseline);
    v2_normalize_pair_report(&mut candidate);
    let exact = baseline == candidate;
    let report = json!({
        "schema": "microverse-v2-proof-canary-comparison/v1",
        "status": if exact { "pass" } else { "fail" },
        "baseline": baseline_path.display().to_string(),
        "candidate": candidate_path.display().to_string(),
        "normalization": "timing fields only",
        "normalized_reports_exactly_equal": exact,
        "external_network_used": false,
        "external_state_committed": false,
    });
    let encoded = serde_json::to_string_pretty(&report)? + "\n";
    if let Some(path) = output {
        fs::write(&path, &encoded).with_context(|| format!("writing {}", path.display()))?;
    }
    println!("{encoded}");
    if !exact {
        bail!("normalized current-v2 baseline/candidate reports differ");
    }
    Ok(())
}

fn usage() -> &'static str {
    "usage:\n  microverse-reachable-harness inspect-module <plugin-root>\n  \
     microverse-reachable-harness plan <plugin-root> <action>\n  \
     microverse-reachable-harness synthetic-proof <plugin-root> <action> \
     [--ship-capacity <10|50|250>] [--mock] [--output <json>]\n  \
     microverse-reachable-harness synthetic-suite <plugin-root> \
     [--output <json>]\n  \
     microverse-reachable-harness synthetic-negative-suite <plugin-root> \
     [--output <json>]\n  \
     microverse-reachable-harness sequence <plugin-root> <action>... \
     [--real | --target-real] [--output <json>]\n  \
     microverse-reachable-harness claim-audit <plugin-root> \
     <profile:c01|c02|c03|c04|c05|c06|direct-replacement|production> <producer-action>... \
     <claim-action> [--real | --target-real] [--collision] [--output <json>]\n  \
     microverse-reachable-harness reveal-audit <plugin-root> <producer-action>... \
     <SurveySector_01_Sparse|SurveySector_02_Standard|SurveySector_03_Rich|SurveySector_04_Ancient|SurveySector_05_Anomalous> [--target-real] [--output <json>]\n  \
     microverse-reachable-harness v2-proof-canaries <plugin-root> --case-dir <dir> --output <json> \
     --action <exact-action> [--action <exact-action>...] \
     (--expect-ship-replacement | --expect-ship-mutation) [--mock-only]\n  \
     microverse-reachable-harness v2-compare-reports <baseline.json> <candidate.json> [--output <json>]\n  \
     microverse-reachable-harness lifecycle-route <plugin-root> <qualification.json> \
     --target-real-action <exact-action-name> --output <json>"
}

fn main() -> Result<()> {
    let mut args = env::args().skip(1);
    let first = args.next();
    let command = if first.as_deref() == Some("--seed") {
        let seed = args
            .next()
            .context("--seed needs a u64 value")?
            .parse::<u64>()?;
        pod2utils::set_seed(seed);
        args.next()
    } else {
        first
    };
    match command.as_deref() {
        Some("inspect-module") => {
            let root = args.next().context("missing plugin root")?;
            if args.next().is_some() {
                bail!("{}", usage());
            }
            inspect_module(Path::new(&root))
        }
        Some("plan") => {
            let root = args.next().context("missing plugin root")?;
            let action = args.next().context("missing action")?;
            if args.next().is_some() {
                bail!("{}", usage());
            }
            plan_action(Path::new(&root), &action)
        }
        Some("synthetic-proof") => {
            let root = args.next().context("missing plugin root")?;
            let action = args.next().context("missing action")?;
            let remaining = args.collect::<Vec<_>>();
            let mut ship_capacity = 10_i64;
            let mut real = true;
            let mut output = None;
            let mut index = 0_usize;
            while index < remaining.len() {
                if remaining[index] == "--ship-capacity" {
                    index += 1;
                    ship_capacity = remaining
                        .get(index)
                        .context("--ship-capacity needs a value")?
                        .parse()?;
                } else if remaining[index] == "--output" {
                    index += 1;
                    output = Some(PathBuf::from(
                        remaining.get(index).context("--output needs a path")?,
                    ));
                } else if remaining[index] == "--mock" {
                    real = false;
                } else {
                    bail!("{}", usage());
                }
                index += 1;
            }
            synthetic_proof(Path::new(&root), &action, ship_capacity, real, output)
        }
        Some("synthetic-suite") => {
            let root = args.next().context("missing plugin root")?;
            let remaining = args.collect::<Vec<_>>();
            let mut output = None;
            let mut index = 0_usize;
            while index < remaining.len() {
                if remaining[index] == "--output" {
                    index += 1;
                    output = Some(PathBuf::from(
                        remaining.get(index).context("--output needs a path")?,
                    ));
                } else {
                    bail!("{}", usage());
                }
                index += 1;
            }
            synthetic_suite(Path::new(&root), output)
        }
        Some("synthetic-negative-suite") => {
            let root = args.next().context("missing plugin root")?;
            let remaining = args.collect::<Vec<_>>();
            let mut output = None;
            let mut index = 0_usize;
            while index < remaining.len() {
                if remaining[index] == "--output" {
                    index += 1;
                    output = Some(PathBuf::from(
                        remaining.get(index).context("--output needs a path")?,
                    ));
                } else {
                    bail!("{}", usage());
                }
                index += 1;
            }
            synthetic_negative_suite(Path::new(&root), output)
        }
        Some("sequence") => {
            let root = args.next().context("missing plugin root")?;
            let remaining: Vec<String> = args.collect();
            let mut actions = Vec::new();
            let mut output = None;
            let mut real = false;
            let mut target_real = false;
            let mut index = 0;
            while index < remaining.len() {
                if remaining[index] == "--output" {
                    index += 1;
                    output = Some(PathBuf::from(
                        remaining.get(index).context("--output needs a path")?,
                    ));
                } else if remaining[index] == "--real" {
                    real = true;
                } else if remaining[index] == "--target-real" {
                    target_real = true;
                } else {
                    actions.push(remaining[index].clone());
                }
                index += 1;
            }
            execute_sequence(Path::new(&root), actions, output, real, target_real)
        }
        Some("claim-audit") => {
            let root = args.next().context("missing plugin root")?;
            let profile = ClaimProfile::parse(&args.next().context("missing Claim profile")?)?;
            let remaining: Vec<String> = args.collect();
            let mut actions = Vec::new();
            let mut output = None;
            let mut real = false;
            let mut target_real = false;
            let mut collision = false;
            let mut index = 0;
            while index < remaining.len() {
                if remaining[index] == "--output" {
                    index += 1;
                    output = Some(PathBuf::from(
                        remaining.get(index).context("--output needs a path")?,
                    ));
                } else if remaining[index] == "--real" {
                    real = true;
                } else if remaining[index] == "--target-real" {
                    target_real = true;
                } else if remaining[index] == "--collision" {
                    collision = true;
                } else {
                    actions.push(remaining[index].clone());
                }
                index += 1;
            }
            execute_claim_audit(
                Path::new(&root),
                profile,
                actions,
                output,
                real,
                target_real,
                collision,
            )
        }
        Some("reveal-audit") => {
            let root = args.next().context("missing plugin root")?;
            let remaining: Vec<String> = args.collect();
            let mut actions = Vec::new();
            let mut output = None;
            let mut target_real = false;
            let mut index = 0;
            while index < remaining.len() {
                if remaining[index] == "--output" {
                    index += 1;
                    output = Some(PathBuf::from(
                        remaining.get(index).context("--output needs a path")?,
                    ));
                } else if remaining[index] == "--target-real" {
                    target_real = true;
                } else if remaining[index].starts_with("--") {
                    bail!("unknown reveal-audit option {}", remaining[index]);
                } else {
                    actions.push(remaining[index].clone());
                }
                index += 1;
            }
            execute_reveal_audit(Path::new(&root), actions, output, target_real)
        }
        Some("v2-proof-canaries") => {
            let root = args.next().context("missing plugin root")?;
            let remaining = args.collect::<Vec<_>>();
            let mut output = None;
            let mut case_dir = None;
            let mut requested_actions = Vec::new();
            let mut mock_only = false;
            let mut ship_identity_mode: Option<V2ShipIdentityMode> = None;
            let mut index = 0_usize;
            while index < remaining.len() {
                if remaining[index] == "--output" {
                    index += 1;
                    output = Some(PathBuf::from(
                        remaining.get(index).context("--output needs a path")?,
                    ));
                } else if remaining[index] == "--case-dir" {
                    index += 1;
                    if case_dir.is_some() {
                        bail!("--case-dir may only be supplied once");
                    }
                    case_dir = Some(PathBuf::from(
                        remaining.get(index).context("--case-dir needs a path")?,
                    ));
                } else if remaining[index] == "--action" {
                    index += 1;
                    let action = remaining
                        .get(index)
                        .context("--action needs an exact action name")?;
                    if !V2_CANARY_ACTIONS.contains(&action.as_str()) {
                        bail!("unknown current-v2 canary action {action}");
                    }
                    if requested_actions.contains(action) {
                        bail!("duplicate current-v2 canary action {action}");
                    }
                    requested_actions.push(action.clone());
                } else if remaining[index] == "--mock-only" {
                    if mock_only {
                        bail!("--mock-only may only be supplied once");
                    }
                    mock_only = true;
                } else if remaining[index] == "--expect-ship-replacement" {
                    if let Some(existing) = ship_identity_mode {
                        bail!(
                            "Ship identity expectation may only be supplied once; already selected --{}",
                            existing.report_name()
                        );
                    }
                    ship_identity_mode = Some(V2ShipIdentityMode::Replacement);
                } else if remaining[index] == "--expect-ship-mutation" {
                    if let Some(existing) = ship_identity_mode {
                        bail!(
                            "Ship identity expectation may only be supplied once; already selected --{}",
                            existing.report_name()
                        );
                    }
                    ship_identity_mode = Some(V2ShipIdentityMode::Mutation);
                } else if remaining[index].starts_with("--") {
                    bail!("unknown v2-proof-canaries option {}", remaining[index]);
                } else {
                    bail!("{}", usage());
                }
                index += 1;
            }
            if requested_actions.is_empty() {
                bail!("at least one --action is required");
            }
            let ship_identity_mode = ship_identity_mode.context(
                "exactly one of --expect-ship-replacement or --expect-ship-mutation is required",
            )?;
            let selected_actions = V2_CANARY_ACTIONS
                .iter()
                .filter(|action| {
                    requested_actions
                        .iter()
                        .any(|requested| requested == *action)
                })
                .map(|action| (*action).to_string())
                .collect::<Vec<_>>();
            v2_proof_canaries(
                Path::new(&root),
                &output.context("missing required --output")?,
                &case_dir.context("missing required --case-dir")?,
                &selected_actions,
                mock_only,
                ship_identity_mode,
            )
        }
        Some("v2-compare-reports") => {
            let baseline = PathBuf::from(args.next().context("missing baseline report")?);
            let candidate = PathBuf::from(args.next().context("missing candidate report")?);
            let remaining = args.collect::<Vec<_>>();
            let mut output = None;
            let mut index = 0_usize;
            while index < remaining.len() {
                if remaining[index] == "--output" {
                    index += 1;
                    output = Some(PathBuf::from(
                        remaining.get(index).context("--output needs a path")?,
                    ));
                } else {
                    bail!("{}", usage());
                }
                index += 1;
            }
            v2_compare_reports(&baseline, &candidate, output)
        }
        Some("lifecycle-route") => {
            let root = args.next().context("missing plugin root")?;
            let descriptor = PathBuf::from(args.next().context("missing qualification.json")?);
            let remaining: Vec<String> = args.collect();
            let mut output = None;
            let mut target_real_action = None;
            let mut index = 0;
            while index < remaining.len() {
                if remaining[index] == "--output" {
                    index += 1;
                    output = Some(PathBuf::from(
                        remaining.get(index).context("--output needs a path")?,
                    ));
                } else if remaining[index] == "--target-real-action" {
                    index += 1;
                    target_real_action = Some(
                        remaining
                            .get(index)
                            .context("--target-real-action needs an exact action name")?
                            .clone(),
                    );
                } else if remaining[index].starts_with("--") {
                    bail!("unknown lifecycle-route option {}", remaining[index]);
                } else {
                    bail!("unexpected lifecycle-route argument {}", remaining[index]);
                }
                index += 1;
            }
            execute_lifecycle_route(
                Path::new(&root),
                &descriptor,
                target_real_action.context("missing --target-real-action")?,
                output.context("missing --output")?,
            )
        }
        _ => bail!("{}", usage()),
    }
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use super::*;
    use txlib::with_stable_identifier;

    #[test]
    fn claim_profiles_encode_the_probe_ladder() {
        assert_eq!(ClaimProfile::parse("c01").unwrap(), ClaimProfile::C01);
        assert_eq!(ClaimProfile::parse("C06").unwrap(), ClaimProfile::C06);
        assert_eq!(
            ClaimProfile::parse("final").unwrap(),
            ClaimProfile::Production
        );
        assert_eq!(
            ClaimProfile::parse("direct-replacement").unwrap(),
            ClaimProfile::DirectReplacement
        );
        assert_eq!(
            ClaimProfile::parse("direct").unwrap(),
            ClaimProfile::DirectReplacement
        );
        assert!(!ClaimProfile::C01.requires_binding());
        assert!(ClaimProfile::C02.requires_binding());
        assert!(ClaimProfile::DirectReplacement.requires_binding());
        assert!(ClaimProfile::DirectReplacement.requires_full_sector());
        assert_eq!(ClaimProfile::C03.expected_serial_delta(), 0);
        assert_eq!(ClaimProfile::C04.expected_serial_delta(), 1);
        assert_eq!(ClaimProfile::DirectReplacement.expected_serial_delta(), 1);
        assert!(!ClaimProfile::C04.expects_work_change());
        assert!(ClaimProfile::DirectReplacement.expects_work_change());
        assert!(!ClaimProfile::Production.expects_work_change());
        assert!(!ClaimProfile::DirectReplacement.requires_collision());
        assert!(ClaimProfile::DirectReplacement.is_direct_replacement());
        assert!(ClaimProfile::C05.expects_work_change());
        assert!(ClaimProfile::Production.requires_collision());
    }

    #[test]
    fn direct_claim_tiers_encode_the_requested_routes() {
        assert_eq!(
            direct_tier_expectation("ClaimSectorSmall"),
            Some(DirectTierExpectation {
                ship_tier: 0,
                movement_step: 1,
                timewarp_step: 1,
            })
        );
        assert_eq!(
            direct_tier_expectation("ClaimSectorMedium"),
            Some(DirectTierExpectation {
                ship_tier: 1,
                movement_step: 10,
                timewarp_step: 10,
            })
        );
        assert_eq!(
            direct_tier_expectation("ClaimSectorLarge"),
            Some(DirectTierExpectation {
                ship_tier: 2,
                movement_step: 100,
                timewarp_step: 100,
            })
        );
        assert_eq!(direct_tier_expectation("ClaimSector"), None);
    }

    #[test]
    fn synthetic_fixture_reads_generated_skill_and_parent_literals() {
        let script = r#"
fn ExtractExample(action) {
    action.st_sum(ship.active_skill_type, 0, 17);
}

fn RefineExample(action) {
    action.st_sum(ship.active_skill_type, 0, 13);
    action.st_sum(parent.resource_type, 0, 248);
}

fn ExtractCoreExample(action) {
    var composite_resource = action.output("MicroverseCompositeResource");
    extract_composite_resource_core(
        action,
        next_ship,
        composite_resource,
        ship,
        body,
        "matter_remaining",
        122,
        50,
        5,
        30,
        15,
        7
    );
}

fn RevealWarpCoordinateExample(action) {
    reveal_p(action, coordinate, 1, 100, 200, 300, 1, -2, -1);
}
"#;
        assert_eq!(
            action_int_literal_constraint(script, "ExtractExample", "ship.active_skill_type",),
            Some(17)
        );
        assert_eq!(
            action_int_literal_constraint(script, "RefineExample", "parent.resource_type",),
            Some(248)
        );
        assert_eq!(
            action_int_literal_constraint(script, "ExtractExample", "parent.resource_type",),
            None
        );
        assert_eq!(
            action_core_ship_capacity(script, "ExtractCoreExample"),
            Some(50)
        );
        assert_eq!(
            action_core_ship_skill(script, "ExtractCoreExample"),
            Some(7)
        );
        assert_eq!(
            action_core_remaining_field(script, "ExtractCoreExample").as_deref(),
            Some("matter_remaining")
        );
        assert_eq!(
            reveal_coordinate_lower_limb(script, "RevealWarpCoordinateExample"),
            Some(u64::MAX - 1)
        );
    }

    #[test]
    fn selected_inventory_indices_are_removed_in_descending_order() {
        assert_eq!(descending_unique_indices(&[1, 0]), vec![1, 0]);
        assert_eq!(descending_unique_indices(&[0, 1]), vec![1, 0]);
        assert_eq!(descending_unique_indices(&[2, 0, 2, 1]), vec![2, 1, 0]);
    }

    #[test]
    fn reconstructs_the_deterministic_initial_commitment() {
        let mut fields = HashMap::new();
        fields.insert(StrKey::from("key"), PodValue::from(EMPTY_VALUE));
        fields.insert(StrKey::from("work"), PodValue::from(EMPTY_VALUE));
        fields.insert(StrKey::from("x"), PodValue::from(17_i64));
        fields.insert(StrKey::from("y"), PodValue::from(-3_i64));
        fields.insert(StrKey::from("z"), PodValue::from(9_i64));
        fields.insert(StrKey::from("epoch"), PodValue::from(4_i64));
        let initial = Dictionary::new(fields);
        let materialized = SpendableObject {
            obj: with_stable_identifier(&initial),
        };
        assert_eq!(
            object_initial_commitment(&materialized).unwrap(),
            initial.commitment()
        );
        assert_eq!(
            object_field(&materialized, "stable_identifier")
                .unwrap()
                .raw(),
            initial.commitment().raw()
        );
    }

    #[test]
    fn seen_hashes_detects_reused_nullifiers_without_mutating_tracking() {
        let first = Hash::from(PodValue::from(1_i64).raw());
        let second = Hash::from(PodValue::from(2_i64).raw());
        let third = Hash::from(PodValue::from(3_i64).raw());
        let seen = HashSet::from([first, third]);

        assert_eq!(seen_hashes(&[first, second], &seen), vec![first]);
        assert_eq!(seen, HashSet::from([first, third]));
    }

    #[test]
    fn sector_field_comparison_allows_only_declared_reveal_changes() {
        fn object(x: i64, revealed: i64, revision: i64, key: i64) -> SpendableObject {
            let mut fields = HashMap::new();
            fields.insert(StrKey::from("x"), PodValue::from(x));
            fields.insert(StrKey::from("revealed"), PodValue::from(revealed));
            fields.insert(StrKey::from("revision"), PodValue::from(revision));
            fields.insert(StrKey::from("key"), PodValue::from(key));
            fields.insert(
                StrKey::from("stable_identifier"),
                PodValue::from(EMPTY_VALUE),
            );
            SpendableObject {
                obj: Dictionary::new(fields),
            }
        }

        let before = object(17, 0, 0, 1);
        let valid_after = object(17, 1, 1, 2);
        let invalid_after = object(18, 1, 1, 2);
        let excluded = ["key", "revealed", "revision"];

        assert!(fields_equal_except(&before, &valid_after, &excluded).unwrap());
        assert!(!fields_equal_except(&before, &invalid_after, &excluded).unwrap());
    }

    #[test]
    fn cross_field_comparison_requires_both_named_fields_and_equal_values() {
        fn object(field: &str, value: i64) -> SpendableObject {
            SpendableObject {
                obj: Dictionary::new(HashMap::from([(
                    StrKey::from(field),
                    PodValue::from(value),
                )])),
            }
        }

        let satellite = object("satellite_serial", 3);
        let body = object("next_satellite_serial", 3);
        let wrong_body = object("next_satellite_serial", 4);

        assert!(cross_field_equal(
            &satellite,
            "satellite_serial",
            &body,
            "next_satellite_serial"
        ));
        assert!(!cross_field_equal(
            &satellite,
            "satellite_serial",
            &wrong_body,
            "next_satellite_serial"
        ));
        assert!(!cross_field_equal(
            &satellite,
            "missing",
            &body,
            "next_satellite_serial"
        ));
    }

    #[test]
    fn lifecycle_exact_schema_and_mutation_tables_cover_every_family() {
        assert_eq!(
            lifecycle_class_fields("celestial_signal"),
            Some(CELESTIAL_SIGNAL_FIELDS)
        );
        assert_eq!(
            lifecycle_class_fields("celestial_body"),
            Some(CELESTIAL_BODY_FIELDS)
        );
        assert_eq!(
            lifecycle_class_fields("civilization"),
            Some(CIVILIZATION_FIELDS)
        );
        assert_eq!(
            lifecycle_class_fields("technology_skill"),
            Some(TECHNOLOGY_SKILL_FIELDS)
        );
        assert_eq!(
            extracted_resource_field("ExtractMatter"),
            Some(("matter_remaining", 1))
        );
        assert_eq!(
            extracted_resource_field("ExtractEnergy"),
            Some(("energy_remaining", 4))
        );
        assert_eq!(
            allowed_target_mutations("ExtractGas", "extract-resource").unwrap(),
            ["key", "work", "gas_remaining"]
        );
        assert_eq!(
            allowed_target_mutations("DiscoverSatellite", "discover-satellite").unwrap(),
            ["key", "satellites_remaining", "next_satellite_serial"]
        );
        assert_eq!(
            allowed_target_mutations("ExtractMegastructureTransitModule", "specialized-resource")
                .unwrap(),
            ["key", "work", "energy_remaining"]
        );
        assert_eq!(
            allowed_target_mutations(
                "DevelopTypeIIICivilizationEngineeringSkill",
                "develop-technology-skill"
            )
            .unwrap(),
            ["key"]
        );
        assert!(allowed_target_mutations("ExtractUnknown", "extract-resource").is_err());
    }

    #[test]
    fn civilization_tech_v1_tables_are_exact_complete_and_unambiguous() {
        assert_eq!(SPECIALIZED_RESOURCE_SPECS.len(), 42);
        assert_eq!(CIVILIZATION_TYPE_SPECS.len(), 3);
        assert_eq!(TECHNOLOGY_SKILL_SPECS.len(), 18);

        let resource_actions = SPECIALIZED_RESOURCE_SPECS
            .iter()
            .map(|spec| spec.action)
            .collect::<HashSet<_>>();
        let resource_types = SPECIALIZED_RESOURCE_SPECS
            .iter()
            .map(|spec| spec.resource_type)
            .collect::<HashSet<_>>();
        assert_eq!(resource_actions.len(), 42);
        assert_eq!(resource_types, (5_i64..=46).collect::<HashSet<_>>());
        let expected_pools = [
            "energy_remaining",
            "gas_remaining",
            "energy_remaining",
            "energy_remaining",
            "matter_remaining",
            "matter_remaining",
            "matter_remaining",
            "matter_remaining",
            "crystal_remaining",
            "gas_remaining",
            "crystal_remaining",
            "energy_remaining",
            "matter_remaining",
            "matter_remaining",
            "gas_remaining",
            "matter_remaining",
            "matter_remaining",
            "crystal_remaining",
            "gas_remaining",
            "gas_remaining",
            "gas_remaining",
            "gas_remaining",
            "matter_remaining",
            "energy_remaining",
            "matter_remaining",
            "energy_remaining",
            "matter_remaining",
            "energy_remaining",
            "energy_remaining",
            "energy_remaining",
            "energy_remaining",
            "energy_remaining",
            "matter_remaining",
            "matter_remaining",
            "gas_remaining",
            "crystal_remaining",
            "matter_remaining",
            "energy_remaining",
            "crystal_remaining",
            "matter_remaining",
            "energy_remaining",
            "crystal_remaining",
        ];
        let expected_candidates = [
            0, 0, 0, 0, 0, 0, 3, 3, 3, 3, 3, 3, 5, 5, 5, 5, 5, 5, 13, 13, 13, 13, 13, 13, 14, 14,
            14, 14, 14, 14, 11, 11, 11, 11, 11, 11, 12, 12, 12, 12, 12, 12,
        ];
        assert_eq!(
            SPECIALIZED_RESOURCE_SPECS
                .iter()
                .map(|spec| spec.remaining_field)
                .collect::<Vec<_>>(),
            expected_pools
        );
        assert_eq!(
            SPECIALIZED_RESOURCE_SPECS
                .iter()
                .map(|spec| spec.candidate_code)
                .collect::<Vec<_>>(),
            expected_candidates
        );

        assert_eq!(
            specialized_resource_spec("ExtractStarStellarPlasma"),
            Some(SpecializedResourceSpec {
                action: "ExtractStarStellarPlasma",
                resource_type: 5,
                candidate_code: 0,
                remaining_field: "energy_remaining",
            })
        );
        assert_eq!(
            specialized_resource_spec("ExtractSterilePlanetIsotope").expect("sterile isotope"),
            SpecializedResourceSpec {
                action: "ExtractSterilePlanetIsotope",
                resource_type: 16,
                candidate_code: 3,
                remaining_field: "energy_remaining",
            }
        );
        assert_eq!(
            specialized_resource_spec("ExtractGasClusterOrganicMolecule")
                .expect("gas-cluster organic molecule"),
            SpecializedResourceSpec {
                action: "ExtractGasClusterOrganicMolecule",
                resource_type: 27,
                candidate_code: 13,
                remaining_field: "matter_remaining",
            }
        );
        assert_eq!(
            specialized_resource_spec("ExtractStellarRemnantRadioactiveIsotope")
                .expect("stellar-remnant isotope"),
            SpecializedResourceSpec {
                action: "ExtractStellarRemnantRadioactiveIsotope",
                resource_type: 30,
                candidate_code: 14,
                remaining_field: "energy_remaining",
            }
        );
        assert_eq!(
            specialized_resource_spec("ExtractAnomalyDimensionalPocket").expect("anomaly pocket"),
            SpecializedResourceSpec {
                action: "ExtractAnomalyDimensionalPocket",
                resource_type: 40,
                candidate_code: 11,
                remaining_field: "crystal_remaining",
            }
        );
        assert_eq!(
            specialized_resource_spec("ExtractMegastructureDataArchive")
                .expect("megastructure archive"),
            SpecializedResourceSpec {
                action: "ExtractMegastructureDataArchive",
                resource_type: 46,
                candidate_code: 12,
                remaining_field: "crystal_remaining",
            }
        );

        assert_eq!(
            CIVILIZATION_TYPE_SPECS,
            [
                CivilizationTypeSpec {
                    action: "MaterializeCivilizationTypeI",
                    civilization_type: 1,
                    lower: CIVILIZATION_TYPE_I_LOWER,
                    upper: CIVILIZATION_TARGET_TOP_LIMB,
                },
                CivilizationTypeSpec {
                    action: "MaterializeCivilizationTypeII",
                    civilization_type: 2,
                    lower: CIVILIZATION_TYPE_II_LOWER,
                    upper: CIVILIZATION_TYPE_I_LOWER - 1,
                },
                CivilizationTypeSpec {
                    action: "MaterializeCivilizationTypeIII",
                    civilization_type: 3,
                    lower: CIVILIZATION_TYPE_III_LOWER,
                    upper: CIVILIZATION_TYPE_II_LOWER - 1,
                },
            ]
        );
        let skill_actions = TECHNOLOGY_SKILL_SPECS
            .iter()
            .map(|spec| spec.action)
            .collect::<HashSet<_>>();
        let skill_types = TECHNOLOGY_SKILL_SPECS
            .iter()
            .map(|spec| spec.skill_type)
            .collect::<HashSet<_>>();
        assert_eq!(skill_actions.len(), 18);
        assert_eq!(skill_types, (1_i64..=18).collect::<HashSet<_>>());
        assert_eq!(
            technology_skill_spec("DevelopTypeIIICivilizationEngineeringSkill"),
            Some(TechnologySkillSpec {
                action: "DevelopTypeIIICivilizationEngineeringSkill",
                skill_type: 18,
                civilization_type: 3,
            })
        );
        assert_eq!(
            desired_civilization_type("DevelopTypeIIMolecularFabricationSkill"),
            Some(2)
        );
        assert_eq!(desired_civilization_type("UseTechnologySkill"), None);
        assert!(specialized_resource_spec("ExtractMatter").is_none());
        assert!(technology_skill_spec("UseTechnologySkill").is_none());
    }

    #[test]
    fn world_objects_bind_location_while_portable_skills_do_not() {
        assert_eq!(
            lifecycle_location_fields("celestial_body"),
            Some(["sector_x", "sector_y", "sector_z", "sector_epoch"])
        );
        assert_eq!(
            lifecycle_location_fields("civilization"),
            Some(["sector_x", "sector_y", "sector_z", "origin_epoch"])
        );
        assert_eq!(lifecycle_location_fields("technology_skill"), None);
        assert_eq!(
            candidate_code_from_action(
                "DetectCelestialSignal_13_GasCluster",
                "DetectCelestialSignal_"
            ),
            Some(13)
        );
        assert_eq!(
            candidate_code_from_action("ScanCelestialBody_14_StellarRemnant", "ScanCelestialBody_"),
            Some(14)
        );
        assert_eq!(
            candidate_code_from_action("MaterializeCivilizationTypeI", "ScanCelestialBody_",),
            None
        );
    }

    #[test]
    fn reveal_ship_semantic_fields_exclude_only_managed_and_action_serial_fields() {
        assert_eq!(SHIP_SEMANTIC_FIELDS.len(), 13);
        assert!(SHIP_SEMANTIC_FIELDS.contains(&"claim_serial"));
        assert!(SHIP_SEMANTIC_FIELDS.contains(&"civilization_scan_serial"));
        assert!(!SHIP_SEMANTIC_FIELDS.contains(&"action_serial"));
        assert!(!SHIP_SEMANTIC_FIELDS.contains(&"key"));
        assert!(!SHIP_SEMANTIC_FIELDS.contains(&"work"));
        assert!(!SHIP_SEMANTIC_FIELDS.contains(&"stable_identifier"));
    }

    #[test]
    fn reveal_audit_accepts_minimal_and_full_targets_only() {
        assert!(is_reveal_audit_target("SurveySector_01_Sparse"));
        assert!(is_reveal_audit_target("SurveySector_02_Standard"));
        assert!(!is_reveal_audit_target("SurveySectorDirect"));
        assert!(!is_reveal_audit_target("ClaimSector"));
    }

    #[test]
    fn lifecycle_family_specs_encode_ship_serial_and_child_rules() {
        assert_eq!(
            lifecycle_family_spec("SurveySector_02_Standard"),
            Some(LifecycleFamilySpec {
                name: "survey-sector",
                target_class: "sector",
                child_class: None,
                ship_serial: None,
            })
        );
        assert_eq!(
            lifecycle_family_spec("DetectCelestialSignal_01_RedDwarf"),
            Some(LifecycleFamilySpec {
                name: "detect-celestial-signal",
                target_class: "sector",
                child_class: Some("celestial_signal"),
                ship_serial: Some("discovery_serial"),
            })
        );
        assert_eq!(
            lifecycle_family_spec("ExtractMatter")
                .expect("ExtractMatter family")
                .ship_serial,
            Some("resource_serial")
        );
        assert_eq!(
            lifecycle_family_spec("DiscoverSatellite")
                .expect("DiscoverSatellite family")
                .child_class,
            Some("satellite")
        );
        assert_eq!(
            lifecycle_family_spec("DetectIntelligentLife")
                .expect("DetectIntelligentLife family")
                .ship_serial,
            Some("civilization_scan_serial")
        );
        assert_eq!(
            lifecycle_family_spec("ExtractGasClusterIonizedGas"),
            Some(LifecycleFamilySpec {
                name: "specialized-resource",
                target_class: "celestial_body",
                child_class: Some("resource"),
                ship_serial: Some("resource_serial"),
            })
        );
        assert_eq!(
            lifecycle_family_spec("DevelopTypeIIInterstellarNavigationSkill"),
            Some(LifecycleFamilySpec {
                name: "develop-technology-skill",
                target_class: "civilization",
                child_class: Some("technology_skill"),
                ship_serial: None,
            })
        );
        assert!(lifecycle_family_spec("UseTechnologySkill").is_none());
        assert!(lifecycle_family_spec("ExtractAnomalyWarpCoordinate").is_none());
        assert!(lifecycle_family_spec("ExtractAnomalyTimeCoordinate").is_none());
        assert!(lifecycle_family_spec("ExtractRedDwarfRadiantEnergy").is_none());
        assert!(lifecycle_family_spec("ExtractRedDwarfFusionGas").is_none());
        assert!(lifecycle_family_spec("MaterializeCivilizationTypeI").is_none());
        assert_eq!(SHIP_LOGICAL_FIELDS.len(), 14);
    }

    #[test]
    fn materializer_specs_identify_candidate_and_final_around_direct_ship_mutation() {
        assert_eq!(
            materializer_spec("ScanCelestialBody_01_RedDwarf"),
            Some(MaterializerSpec {
                input_class: "celestial_signal",
                output_class: "celestial_body",
            })
        );
        assert_eq!(
            materializer_spec("MaterializeCivilizationTypeI"),
            Some(MaterializerSpec {
                input_class: "life_signal",
                output_class: "civilization",
            })
        );
        assert!(materializer_spec("DetectIntelligentLife").is_none());
        for action in [
            "ScanCelestialBody_12_Megastructure",
            "ScanCelestialBody_13_GasCluster",
            "ScanCelestialBody_14_StellarRemnant",
        ] {
            assert_eq!(
                materializer_spec(action),
                Some(MaterializerSpec {
                    input_class: "celestial_signal",
                    output_class: "celestial_body",
                })
            );
        }
        for action in [
            "DetectCelestialSignal_12_Megastructure",
            "DetectCelestialSignal_13_GasCluster",
            "DetectCelestialSignal_14_StellarRemnant",
        ] {
            assert_eq!(
                lifecycle_family_spec(action),
                Some(LifecycleFamilySpec {
                    name: "detect-celestial-signal",
                    target_class: "sector",
                    child_class: Some("celestial_signal"),
                    ship_serial: Some("discovery_serial"),
                })
            );
        }
        let changed_or_new_target_count = 3_usize
            + 15
            + 1
            + SPECIALIZED_RESOURCE_SPECS.len()
            + CIVILIZATION_TYPE_SPECS.len()
            + TECHNOLOGY_SKILL_SPECS.len()
            + 1;
        assert_eq!(changed_or_new_target_count, 83);
    }

    #[test]
    fn exact_role_order_helper_rejects_reordered_ship_parent_shapes() {
        let inputs = vec![
            "MicroverseShip".to_string(),
            "MicroverseCivilization".to_string(),
        ];
        let reversed = vec![
            "MicroverseCivilization".to_string(),
            "MicroverseShip".to_string(),
        ];
        assert!(class_sequence_matches(
            &inputs,
            &["spaceship", "civilization"]
        ));
        assert!(!class_sequence_matches(
            &reversed,
            &["spaceship", "civilization"]
        ));
    }

    #[test]
    fn exact_u256_comparison_checks_all_limbs_most_significant_first() {
        let target = [0, 0, 0, 10];
        assert!(u256_lte([0, 0, 0, 10], target));
        assert!(u256_lte([u64::MAX, u64::MAX, u64::MAX, 9], target));
        assert!(!u256_lte([1, 0, 0, 10], target));
        assert!(!u256_lte([0, 0, 0, 11], target));
    }

    #[test]
    fn upfront_qualification_validation_recomputes_encoded_limbs_and_result() {
        let value = raw_value_string(RawValue([F(1), F(2), F(3), F(9)]));
        let target = raw_value_string(target_raw_value(10));
        let valid = RouteQualificationCheck {
            input: "complete_post_stable_identifier_celestial_signal".to_string(),
            comparison: "full_four_limb_u256_lte_most_significant_limb_first".to_string(),
            value_raw_u256: value.clone(),
            value_limbs_le: [1, 2, 3, 9],
            target_raw_u256: target,
            target_limbs_le: [0, 0, 0, 10],
            target_top_limb: 10,
            passes: true,
        };
        validate_qualification_shape("celestial_signal", &valid, &value, 10).unwrap();

        let mut tampered_limbs = valid;
        tampered_limbs.value_limbs_le[0] = 2;
        assert!(
            validate_qualification_shape("celestial_signal", &tampered_limbs, &value, 10)
                .unwrap_err()
                .to_string()
                .contains("value limbs")
        );
    }

    #[test]
    fn canonical_descriptor_route_uses_distinct_producer_point_actions() {
        let point = RoutePoint {
            x: DIRECT_COORD_ZERO - 1,
            y: DIRECT_COORD_ZERO,
            z: DIRECT_COORD_ZERO + 1,
            epoch: 1,
        };
        let candidate = RouteCandidate {
            code: 0,
            name: "Red Dwarf".to_string(),
            slug: "RedDwarf".to_string(),
            body_type: 2,
            body_profile: 10,
            nominal_denominator: 8,
            target_top_limb: 2_305_843_009_213_693_952,
            life_stat: 0,
            matter: 2,
            crystal: 0,
            gas: 2,
            energy: 12,
            satellites: 0,
        };
        let (actions, navigation) =
            canonical_route_actions(&point, &candidate, "SurveySector_02_Standard", None, 100)
                .unwrap();
        assert_eq!(
            actions,
            [
                "BuildShipSmall",
                "MoveNegativeX",
                "MovePositiveZ",
                "TimeWarpSmall",
                "ClaimSector",
                "SurveySector_02_Standard",
                "DetectCelestialSignal_00_RedDwarf",
                "ScanCelestialBody_00_RedDwarf",
            ]
        );
        assert_eq!(
            navigation,
            RouteNavigation {
                dx: -1,
                dy: 0,
                dz: 1,
                spatial_move_count: 2,
                timewarp_count: 1,
            }
        );
    }

    #[test]
    fn canonical_civilization_route_appends_only_the_two_life_stages() {
        let point = RoutePoint {
            x: DIRECT_COORD_ZERO + 1,
            y: DIRECT_COORD_ZERO,
            z: DIRECT_COORD_ZERO,
            epoch: 1,
        };
        let candidate = RouteCandidate {
            code: 4,
            name: "Ocean Planet".to_string(),
            slug: "OceanPlanet".to_string(),
            body_type: 1,
            body_profile: 21,
            nominal_denominator: 32,
            target_top_limb: 576_460_752_303_423_488,
            life_stat: 2,
            matter: 4,
            crystal: 1,
            gas: 4,
            energy: 1,
            satellites: 2,
        };
        let (actions, _) = canonical_route_actions(
            &point,
            &candidate,
            "SurveySector_02_Standard",
            Some("MaterializeCivilizationTypeII"),
            100,
        )
        .unwrap();
        assert_eq!(
            &actions[actions.len() - 2..],
            ["DetectIntelligentLife", "MaterializeCivilizationTypeII"]
        );
        assert_eq!(
            exact_action_occurrences(&actions, "MaterializeCivilizationTypeII"),
            1
        );
    }

    #[test]
    fn canonical_route_rejects_unbounded_expansion_before_allocating() {
        let point = RoutePoint {
            x: ROUTE_COORD_UPPER_BOUND - 1,
            y: DIRECT_COORD_ZERO,
            z: DIRECT_COORD_ZERO,
            epoch: 1,
        };
        let candidate = RouteCandidate {
            code: 0,
            name: "Red Dwarf".to_string(),
            slug: "RedDwarf".to_string(),
            body_type: 2,
            body_profile: 10,
            nominal_denominator: 8,
            target_top_limb: 2_305_843_009_213_693_952,
            life_stat: 0,
            matter: 2,
            crystal: 0,
            gas: 2,
            energy: 12,
            satellites: 0,
        };
        let error =
            canonical_route_actions(&point, &candidate, "SurveySector_02_Standard", None, 40)
                .unwrap_err();
        assert!(
            error
                .to_string()
                .contains("exceeds descriptor max_action_cost")
        );
        let error = canonical_route_actions(
            &RoutePoint {
                x: DIRECT_COORD_ZERO + 1,
                ..point
            },
            &candidate,
            "SurveySector_02_Standard",
            None,
            ROUTE_ACTION_COST_HARD_LIMIT + 1,
        )
        .unwrap_err();
        assert!(error.to_string().contains("hard safety limit"));
    }

    #[test]
    fn descriptor_hash_encoding_rejects_uppercase_and_wrong_width() {
        assert!(valid_lower_hex_256(&format!("0x{}", "ab".repeat(32))));
        assert!(!valid_lower_hex_256(&format!("0x{}", "AB".repeat(32))));
        assert!(!valid_lower_hex_256(&format!("0x{}", "ab".repeat(31))));
        assert!(!valid_lower_hex_256(&format!("{}", "ab".repeat(33))));
    }

    #[test]
    fn creation_commitments_are_required_at_exact_lifecycle_boundaries() {
        assert!(full_creation_commitment_required_before(
            "SurveySector_02_Standard",
            "MicroverseSector"
        ));
        assert!(full_creation_commitment_required_before(
            "ScanCelestialBody_00_RedDwarf",
            "MicroverseCelestialSignal"
        ));
        assert!(full_creation_commitment_required_before(
            "DetectIntelligentLife",
            "MicroverseCelestialBody"
        ));
        assert!(full_creation_commitment_required_before(
            "MaterializeCivilizationTypeI",
            "MicroverseLifeSignal"
        ));
        assert!(!full_creation_commitment_required_before(
            "DetectCelestialSignal_00_RedDwarf",
            "MicroverseSector"
        ));
    }

    #[test]
    fn scanner_find_route_v1_descriptor_deserializes_without_objects() {
        for (name, action_count, has_life) in [
            ("qualification-red-dwarf.json", 8, false),
            ("qualification-ocean-civilization.json", 17, true),
        ] {
            let descriptor_path = Path::new(env!("CARGO_MANIFEST_DIR"))
                .join("../../generated/lifecycle-refactor/staged-full/evidence")
                .join(name);
            let encoded = fs::read_to_string(&descriptor_path)
                .unwrap_or_else(|error| panic!("reading {}: {error}", descriptor_path.display()));
            let descriptor: LifecycleRouteDescriptor = serde_json::from_str(&encoded)
                .unwrap_or_else(|error| panic!("parsing {}: {error}", descriptor_path.display()));
            assert_eq!(descriptor.schema_version, 1);
            assert_eq!(descriptor.kind, ROUTE_DESCRIPTOR_KIND);
            assert!(descriptor.descriptor_only);
            assert_eq!(descriptor.route.action_count, action_count);
            assert!(
                descriptor
                    .route
                    .actions
                    .contains(&"ClaimSector".to_string())
            );
            assert_eq!(descriptor.expected_objects.life_signal.is_some(), has_life);
            assert_eq!(descriptor.expected_objects.civilization.is_some(), has_life);
        }
    }
}
