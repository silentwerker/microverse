#!/usr/bin/env python3
"""Deterministically generate the Microverse prototype and compiler variants."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
from collections import Counter, defaultdict
from functools import lru_cache
from pathlib import Path
from typing import Any, Iterable


PACKAGE_NAME = "microverse-celestial-prototype"
PLUGIN_VERSION = "0.1.0"
ZERO_HASH = "0" * 64
RHAI_HARD_LIMIT_BYTES = 1_000_000
RHAI_SAFETY_LIMIT_BYTES = 990_000
WARP_CAPACITY_SWEEP_MAX_COUNT = 10_000

RESOURCE_CATALOG_FILENAME = "microverse-resource-tree-v2.json"
COMPONENT_CATALOG_FILENAME = "microverse-component-tree-v2.json"
SKILL_CATALOG_FILENAME = "microverse-skill-tree-v2.json"
WARP_CATALOG_FILENAME = "microverse-warp-tree-v2.json"
CATALOG_INDEX_FILENAME = "microverse-catalog-index-v2.json"

# Populated only when configure_expansion_catalogs() is explicitly called.
# Keeping catalog loading opt-in preserves a byte-exact canonical baseline for
# audits while the v2 catalogs are authored independently.
EXPANSION_CATALOGS: dict[str, dict[str, Any]] = {}
COMPONENT_RECIPES: list[dict[str, Any]] = []
DERIVED_SKILLS: list[dict[str, Any]] = []
SKILL_CAPABILITIES: list[dict[str, Any]] = []
POSITION_CHART_DESTINATIONS: list[dict[str, Any]] = []
EPOCH_CHART_DESTINATIONS: list[dict[str, Any]] = []
WARP_OBJECT_ACTIONS: dict[str, dict[str, Any]] = {}
WARP_RECIPES: dict[str, dict[str, Any]] = {}

VERSIONS = {
    "schema_version": 2,
    "mechanics_version": 2,
    "universe_version": 2,
    "body_bank_version": 2,
    "civilization_version": 2,
}

COORD_ZERO = 1_000_000_000_000
COORD_UPPER_BOUND = 2_000_000_000_000
EPOCH_UPPER_BOUND = 1_000_000_000_000
EPOCH_RENDER_YEARS = 1_000
EXPLICIT_SELECTION_MODE = "explicit_action_identity"
DETERMINISTIC_SELECTOR_MODE = "stable_identifier_band_v1"
UNRESOLVED_CANDIDATE_CODE = -1
GOLDILOCKS_TOP_LIMB_MODULUS = 0xFFFFFFFF00000001
INTELLIGENT_LIFE_CANDIDATE_CODES = (4, 5)


def _signed_u64(value: int) -> int:
    if not 0 <= value < 2**64:
        raise ValueError(f"top-limb value is outside u64: {value}")
    return value if value < 2**63 else value - 2**64


def deterministic_selector_bands(
    rows: list[dict[str, Any]],
    *,
    key: str,
    weights: list[int] | None = None,
) -> dict[Any, dict[str, int | None]]:
    """Partition the canonical stable-ID top limb into fixed action bands.

    LtEqU256 is inclusive. Adjacent bounds therefore leave only the exact
    lower-limb boundary interval between ``upper`` and ``lower`` instead of
    allowing two actions to accept the same object. The excluded probability
    is one top-limb boundary per split (less than 1 / 2^64 each).
    """
    if not rows:
        return {}
    selected_weights = weights or [1] * len(rows)
    if len(selected_weights) != len(rows) or any(
        not isinstance(weight, int) or weight <= 0
        for weight in selected_weights
    ):
        raise ValueError("deterministic selector weights must be positive")
    total = sum(selected_weights)
    cuts = [0]
    cumulative = 0
    for weight in selected_weights[:-1]:
        cumulative += weight
        cuts.append((cumulative * GOLDILOCKS_TOP_LIMB_MODULUS) // total)
    cuts.append(GOLDILOCKS_TOP_LIMB_MODULUS)
    result: dict[Any, dict[str, int | None]] = {}
    for index, row in enumerate(rows):
        lower = cuts[index] if index > 0 else None
        upper = cuts[index + 1] - 1 if index + 1 < len(rows) else None
        result[row[key]] = {"lower_top_limb": lower, "upper_top_limb": upper}
    return result


def selector_constraints_source(
    selector: str,
    band: dict[str, int | None],
    *,
    prefix: str,
    indent: str = "    ",
) -> str:
    statements: list[str] = []
    lower = band["lower_top_limb"]
    upper = band["upper_top_limb"]
    if lower is not None:
        statements.extend(
            [
                f"{indent}let {prefix}_lower = action.top_limb_u256({_signed_u64(lower)});",
                f"{indent}action.intro_lt_eq_u256({prefix}_lower, {selector});",
            ]
        )
    if upper is not None:
        statements.extend(
            [
                f"{indent}let {prefix}_upper = action.top_limb_u256({_signed_u64(upper)});",
                f"{indent}action.intro_lt_eq_u256({selector}, {prefix}_upper);",
            ]
        )
    return "\n".join(statements)

SHIP = "MicroverseShip"
SECTOR = "MicroverseSector"
SIGNAL = "MicroverseCelestialSignal"
BODY = "MicroverseCelestialBody"
RESOURCE = "MicroverseResource"
COMPOSITE_RESOURCE = "MicroverseCompositeResource"
SATELLITE = "MicroverseSatellite"
LIFE_SIGNAL = "MicroverseLifeSignal"
CIVILIZATION = "MicroverseCivilization"
TECHNOLOGY_SKILL = "MicroverseTechnologySkill"
SHIPYARD_PERMIT = "MicroverseShipyardPermit"
WARP_COORDINATE = "MicroverseWarpCoordinate"
TIME_COORDINATE = "MicroverseTimeCoordinate"
WARP_CHART = "MicroverseWarpChart"
EPOCH_CHART = "MicroverseEpochChart"
POSITION_ANCHOR = "MicroversePositionAnchor"
TIME_ANCHOR = "MicroverseTimeAnchor"
WORMHOLE_LINK = "MicroverseWormholeLink"
TEMPORAL_LINK = "MicroverseTemporalLink"
RENDEZVOUS_COORDINATE = "MicroverseRendezvousCoordinate"

CLASS_ORDER = [
    SHIP,
    SECTOR,
    SIGNAL,
    BODY,
    COMPOSITE_RESOURCE,
    RESOURCE,
    SATELLITE,
    LIFE_SIGNAL,
    CIVILIZATION,
    TECHNOLOGY_SKILL,
    SHIPYARD_PERMIT,
    WARP_COORDINATE,
    TIME_COORDINATE,
    WARP_CHART,
    EPOCH_CHART,
    POSITION_ANCHOR,
    TIME_ANCHOR,
    WORMHOLE_LINK,
    TEMPORAL_LINK,
    RENDEZVOUS_COORDINATE,
]

CLASS_PRESENTATION = {
    SHIP: {
        "title": "Microverse Ship",
        "emoji": "🚀",
        "description": (
            "Microverse Small, Medium, or Large Ship; the tier is encoded "
            "in its movement and extraction fields."
        ),
    },
    SECTOR: {
        "title": "Microverse Sector",
        "emoji": "🧭",
        "description": "A claimed region of the Microverse.",
    },
    SIGNAL: {
        "title": "Microverse Celestial Signal",
        "emoji": "📡",
        "description": "A detected celestial signal ready to be scanned.",
    },
    BODY: {
        "title": "Microverse Celestial Body",
        "emoji": "🪐",
        "description": "A scanned celestial body with resource pools.",
    },
    COMPOSITE_RESOURCE: {
        "title": "Microverse Composite Resource",
        "emoji": "🧱",
        "description": "A Microverse resource that can yield component resources.",
    },
    RESOURCE: {
        "title": "Microverse Resource",
        "emoji": "📦",
        "description": "A transferable quantity of a Microverse resource.",
    },
    SATELLITE: {
        "title": "Microverse Satellite",
        "emoji": "🛰️",
        "description": "A satellite discovered around a celestial body.",
    },
    LIFE_SIGNAL: {
        "title": "Microverse Life Signal",
        "emoji": "🧬",
        "description": "A detected intelligent-life signal.",
    },
    CIVILIZATION: {
        "title": "Microverse Civilization",
        "emoji": "🏛️",
        "description": "A Type I, Type II, or Type III Microverse civilization.",
    },
    TECHNOLOGY_SKILL: {
        "title": "Microverse Technology Skill",
        "emoji": "🧠",
        "description": "A reusable technology capability learned from a civilization.",
    },
    SHIPYARD_PERMIT: {
        "title": "Microverse Shipyard Permit",
        "emoji": "🏗️",
        "description": "A location-bound permit for constructing a Microverse Ship.",
    },
    WARP_COORDINATE: {
        "title": "Microverse Warp Coordinate",
        "emoji": "WC",
        "description": "A sealed, deterministic, limited-use position destination.",
    },
    TIME_COORDINATE: {
        "title": "Microverse Time Coordinate",
        "emoji": "TC",
        "description": "A sealed, deterministic, limited-use absolute epoch destination.",
    },
    WARP_CHART: {
        "title": "Microverse Warp Chart",
        "emoji": "WC2",
        "description": "A sealed v2 position chart extracted from a Wormhole Mouth.",
    },
    EPOCH_CHART: {
        "title": "Microverse Epoch Chart",
        "emoji": "EC2",
        "description": "A sealed v2 epoch chart extracted from a Wormhole Mouth.",
    },
    POSITION_ANCHOR: {
        "title": "Microverse Position Anchor",
        "emoji": "PA",
        "description": "A fixed x/y/z anchor captured from a Ship.",
    },
    TIME_ANCHOR: {
        "title": "Microverse Time Anchor",
        "emoji": "TA",
        "description": "A fixed epoch anchor captured from a Ship.",
    },
    WORMHOLE_LINK: {
        "title": "Microverse Wormhole Link",
        "emoji": "WL",
        "description": "A limited-use bidirectional link between position anchors.",
    },
    TEMPORAL_LINK: {
        "title": "Microverse Temporal Link",
        "emoji": "TL",
        "description": "A limited-use bidirectional link between time anchors.",
    },
    RENDEZVOUS_COORDINATE: {
        "title": "Microverse Rendezvous Coordinate",
        "emoji": "RC",
        "description": "A limited-use combined position and epoch destination.",
    },
}

WARP_ENERGY_COST = 9_000
WARP_ANOMALY_CANDIDATE = 11
WARP_SKILL_TYPE = 14
V1_COORDINATE_POOL_MINIMUMS = {
    10: 18_000,
    3: 9_001,
    1: 9_000,
}
V2_CHART_POOL_MINIMUMS = {
    10: 40_000,
    3: 31_000,
    1: 9_000,
}
# Each reveal action names one exact catalog destination. Stable identifiers
# are object identity/nullifier material only; they do not select destinations.
# Position and time are intentionally separate object families: a position
# warp changes x/y/z but preserves epoch; a time warp changes epoch but
# preserves x/y/z.
POSITION_WARP_MINIMUM = 100
POSITION_WARP_COUNT = 125
POSITION_WARP_SEED = "microverse:position-warp-coordinate:v1"
POSITION_WARP_MAGNITUDE_STRATA = (
    (100, 1_000),
    (1_000, 10_000),
    (10_000, 100_000),
    (100_000, 1_000_000),
    (1_000_000, 10_000_000),
    (10_000_000, 100_000_000),
    (100_000_000, 1_000_000_000),
    (1_000_000_000, 10_000_000_000),
    (10_000_000_000, 100_000_000_000),
    (100_000_000_000, 1_000_000_000_000),
    (1_000_000_000_000, COORD_UPPER_BOUND),
)


def deterministic_bounded_int(
    seed: str,
    label: str,
    lower_inclusive: int,
    upper_exclusive: int,
) -> int:
    """Map a SHA-256-derived integer into a fixed interval without modulo."""
    if lower_inclusive >= upper_exclusive:
        raise ValueError("deterministic interval must be nonempty")
    digest = hashlib.sha256(f"{seed}:{label}".encode("utf-8")).digest()
    sample = int.from_bytes(digest, "big")
    span = upper_exclusive - lower_inclusive
    return lower_inclusive + (sample * span // 2**256)


def deterministic_position_component(code: int, axis: str) -> int:
    stratum_index = deterministic_bounded_int(
        POSITION_WARP_SEED,
        # The frozen v1 seed label remains ``band`` for byte-stable coordinates.
        f"{code}:{axis}:band",
        0,
        len(POSITION_WARP_MAGNITUDE_STRATA),
    )
    lower, upper = POSITION_WARP_MAGNITUDE_STRATA[stratum_index]
    return deterministic_bounded_int(
        POSITION_WARP_SEED,
        f"{code}:{axis}:value",
        lower,
        upper,
    )


def catalog_uses(code: int, count: int) -> int:
    """Return the fixed charge count assigned to an explicit catalog action."""
    if count < 4:
        raise ValueError("Coordinate catalogs require at least four rows")
    if code == 1:
        return 10
    if code <= 4:
        return 3
    return 1


def v2_chart_pool_minimum(uses: int) -> int:
    """Return the minimum shared-Energy snapshot for a v2 chart capacity."""
    try:
        return V2_CHART_POOL_MINIMUMS[uses]
    except KeyError as error:
        raise ValueError(f"unsupported v2 chart capacity: {uses}") from error


def v1_coordinate_pool_minimum(uses: int) -> int:
    """Return the minimum shared-Energy snapshot for a v1 capacity."""
    try:
        return V1_COORDINATE_POOL_MINIMUMS[uses]
    except KeyError as error:
        raise ValueError(f"unsupported v1 coordinate capacity: {uses}") from error


_position_rows: list[dict[str, Any]] = []
for _code in range(1, POSITION_WARP_COUNT + 1):
    _position_rows.append(
        {
            "code": _code,
            "slug": f"{_code:03d}",
            "x": deterministic_position_component(_code, "x"),
            "y": deterministic_position_component(_code, "y"),
            "z": deterministic_position_component(_code, "z"),
            "uses": catalog_uses(_code, POSITION_WARP_COUNT),
            "minimum_source_pool_inclusive": v1_coordinate_pool_minimum(
                catalog_uses(_code, POSITION_WARP_COUNT)
            ),
        }
    )
POSITION_WARP_DESTINATIONS = _position_rows

# A quartic curve provides dense early epochs while still reaching the full
# time range. These are fixed generator outputs, not runtime arithmetic.
TIME_WARP_COUNT = 86
_time_epochs = [
    101
    + (
        (EPOCH_UPPER_BOUND - 102)
        * index**4
        // (TIME_WARP_COUNT - 1) ** 4
    )
    for index in range(TIME_WARP_COUNT)
]
_time_rows: list[dict[str, Any]] = []
for _index, _epoch in enumerate(_time_epochs, 1):
    _time_rows.append(
        {
            "code": _index,
            "slug": f"{_index:02d}",
            "epoch": _epoch,
            "uses": catalog_uses(_index, TIME_WARP_COUNT),
            "minimum_source_pool_inclusive": v1_coordinate_pool_minimum(
                catalog_uses(_index, TIME_WARP_COUNT)
            ),
        }
    )
TIME_WARP_DESTINATIONS = _time_rows

SECTOR_TYPE_EMPTY = 0
SECTOR_TYPE_CELESTIAL = 1

CELESTIAL_CATEGORIES: list[dict[str, Any]] = [
    {"code": 1, "name": "Planet", "slug": "Planet", "body_type": 1},
    {"code": 2, "name": "Star", "slug": "Star", "body_type": 2},
    {"code": 3, "name": "Gas Giant", "slug": "GasGiant", "body_type": 3},
    {"code": 4, "name": "Ice Giant", "slug": "IceGiant", "body_type": 4},
    {"code": 5, "name": "Neutron Star", "slug": "NeutronStar", "body_type": 5},
    {"code": 6, "name": "Black Hole", "slug": "BlackHole", "body_type": 6},
    {"code": 7, "name": "Anomaly", "slug": "Anomaly", "body_type": 7},
    {"code": 8, "name": "Megastructure", "slug": "Megastructure", "body_type": 8},
    {"code": 9, "name": "Gas Cluster", "slug": "GasCluster", "body_type": 9},
    {
        "code": 10,
        "name": "Stellar Remnant",
        "slug": "StellarRemnant",
        "body_type": 10,
    },
]
for _category in CELESTIAL_CATEGORIES:
    _stem = re.sub(r"(?<!^)(?=[A-Z])", "_", _category["slug"]).lower()
    _category["remaining_field"] = f"{_stem}_remaining"
    _category["serial_field"] = f"next_{_stem}_serial"

# Each Survey action proves the claimed Sector stable ID falls in its profile band.
SURVEY_PROFILES: list[dict[str, Any]] = [
    {
        "code": 1,
        "name": "Sparse",
        "slug": "Sparse",
        "selection_mode": DETERMINISTIC_SELECTOR_MODE,
        "minimum_claim_serial": 4,
        "counts": {
            "planet_remaining": 1,
            "star_remaining": 1,
        },
    },
    {
        "code": 2,
        "name": "Standard",
        "slug": "Standard",
        "selection_mode": DETERMINISTIC_SELECTOR_MODE,
        "minimum_claim_serial": 8,
        "counts": {
            "planet_remaining": 3,
            "star_remaining": 1,
            "gas_giant_remaining": 1,
            "ice_giant_remaining": 1,
            "gas_cluster_remaining": 2,
            "stellar_remnant_remaining": 1,
        },
    },
    {
        "code": 3,
        "name": "Rich",
        "slug": "Rich",
        "selection_mode": DETERMINISTIC_SELECTOR_MODE,
        "minimum_claim_serial": 32,
        "counts": {
            "planet_remaining": 6,
            "star_remaining": 2,
            "gas_giant_remaining": 2,
            "ice_giant_remaining": 2,
            "neutron_star_remaining": 1,
            "megastructure_remaining": 2,
            "gas_cluster_remaining": 4,
            "stellar_remnant_remaining": 2,
        },
    },
    {
        "code": 4,
        "name": "Ancient",
        "slug": "Ancient",
        "selection_mode": DETERMINISTIC_SELECTOR_MODE,
        "minimum_claim_serial": 128,
        "counts": {
            "planet_remaining": 3,
            "star_remaining": 2,
            "gas_giant_remaining": 1,
            "ice_giant_remaining": 1,
            "neutron_star_remaining": 1,
            "megastructure_remaining": 9,
            "gas_cluster_remaining": 2,
            "stellar_remnant_remaining": 2,
        },
    },
    {
        "code": 5,
        "name": "Anomalous",
        "slug": "Anomalous",
        "selection_mode": DETERMINISTIC_SELECTOR_MODE,
        "minimum_claim_serial": 256,
        "counts": {
            "planet_remaining": 3,
            "star_remaining": 2,
            "gas_giant_remaining": 1,
            "ice_giant_remaining": 1,
            "neutron_star_remaining": 1,
            "black_hole_remaining": 1,
            "anomaly_remaining": 1,
            "megastructure_remaining": 9,
            "gas_cluster_remaining": 2,
            "stellar_remnant_remaining": 2,
        },
    },
]

# Keep Phase 3 constrained to one representative wrapper of each shape until
# the combined full package has passed the installed compiler.

SCHEMAS: dict[str, list[tuple[str, str]]] = {
    SHIP: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("extraction_amount", "Int"),
        ("rare_extraction_amount", "Int"),
        ("x", "Int"),
        ("y", "Int"),
        ("z", "Int"),
        ("epoch", "Int"),
        ("active_skill_type", "Int"),
        ("action_serial", "Int"),
        ("claim_serial", "Int"),
        ("discovery_serial", "Int"),
        ("satellite_serial", "Int"),
        ("civilization_scan_serial", "Int"),
        ("ship_id", "Raw"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    SECTOR: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("body_bank_version", "Int"),
        ("x", "Int"),
        ("y", "Int"),
        ("z", "Int"),
        ("epoch", "Int"),
        ("sector_type", "Int"),
        ("survey_profile", "Int"),
        *[
            (category["remaining_field"], "Int")
            for category in CELESTIAL_CATEGORIES
        ],
        *[
            (category["serial_field"], "Int")
            for category in CELESTIAL_CATEGORIES
        ],
        ("revision", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    SIGNAL: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("body_bank_version", "Int"),
        ("sector_x", "Int"),
        ("sector_y", "Int"),
        ("sector_z", "Int"),
        ("sector_epoch", "Int"),
        ("category_code", "Int"),
        ("candidate_code", "Int"),
        ("slot_serial", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    BODY: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("body_bank_version", "Int"),
        ("source_signal_identifier", "Raw"),
        ("sector_x", "Int"),
        ("sector_y", "Int"),
        ("sector_z", "Int"),
        ("sector_epoch", "Int"),
        ("candidate_code", "Int"),
        ("body_type", "Int"),
        ("life_stat", "Int"),
        ("matter_remaining", "Int"),
        ("crystal_remaining", "Int"),
        ("gas_remaining", "Int"),
        ("energy_remaining", "Int"),
        ("satellites_remaining", "Int"),
        ("next_satellite_serial", "Int"),
        ("civilization_discovered", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    COMPOSITE_RESOURCE: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("resource_type", "Int"),
        ("sector_x", "Int"),
        ("sector_y", "Int"),
        ("sector_z", "Int"),
        ("origin_epoch", "Int"),
        ("child_1_remaining", "Int"),
        ("child_2_remaining", "Int"),
        ("child_3_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    RESOURCE: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("resource_type", "Int"),
        ("amount", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    SATELLITE: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("parent_body_identifier", "Raw"),
        ("sector_x", "Int"),
        ("sector_y", "Int"),
        ("sector_z", "Int"),
        ("sector_epoch", "Int"),
        ("satellite_serial", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    LIFE_SIGNAL: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("civilization_version", "Int"),
        ("source_body_identifier", "Raw"),
        ("sector_x", "Int"),
        ("sector_y", "Int"),
        ("sector_z", "Int"),
        ("origin_epoch", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    CIVILIZATION: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("civilization_version", "Int"),
        ("source_life_signal_identifier", "Raw"),
        ("sector_x", "Int"),
        ("sector_y", "Int"),
        ("sector_z", "Int"),
        ("origin_epoch", "Int"),
        ("civilization_type", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    TECHNOLOGY_SKILL: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("civilization_version", "Int"),
        ("skill_type", "Int"),
        ("reusable", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    SHIPYARD_PERMIT: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("permit_type", "Int"),
        ("x", "Int"),
        ("y", "Int"),
        ("z", "Int"),
        ("epoch", "Int"),
        ("industrial_authorized", "Int"),
        ("electronics_authorized", "Int"),
        ("molecular_authorized", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    WARP_COORDINATE: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("source_body_identifier", "Raw"),
        ("source_pool_before", "Int"),
        ("revealed", "Int"),
        ("destination_code", "Int"),
        ("destination_x", "Int"),
        ("destination_y", "Int"),
        ("destination_z", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
    TIME_COORDINATE: [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("source_body_identifier", "Raw"),
        ("source_pool_before", "Int"),
        ("revealed", "Int"),
        ("destination_code", "Int"),
        ("destination_epoch", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ],
}

# Protocol field types are explicit. Raw identifiers must never be silently
# treated as arithmetic integers merely because both representations are
# field-backed inside the SDK.
EXPECTED_WARP_OBJECT_SCHEMAS: dict[str, tuple[tuple[str, str], ...]] = {
    WARP_COORDINATE: tuple(SCHEMAS[WARP_COORDINATE]),
    TIME_COORDINATE: tuple(SCHEMAS[TIME_COORDINATE]),
    WARP_CHART: (
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("catalog_version", "Int"),
        ("source_body_identifier", "Raw"),
        ("source_pool_before", "Int"),
        ("revealed", "Int"),
        ("destination_code", "Int"),
        ("destination_x", "Int"),
        ("destination_y", "Int"),
        ("destination_z", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    EPOCH_CHART: (
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("catalog_version", "Int"),
        ("source_body_identifier", "Raw"),
        ("source_pool_before", "Int"),
        ("revealed", "Int"),
        ("destination_code", "Int"),
        ("destination_epoch", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    POSITION_ANCHOR: (
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("anchor_version", "Int"),
        ("source_ship_id", "Raw"),
        ("x", "Int"),
        ("y", "Int"),
        ("z", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    TIME_ANCHOR: (
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("anchor_version", "Int"),
        ("source_ship_id", "Raw"),
        ("epoch", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    WORMHOLE_LINK: (
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("link_version", "Int"),
        ("endpoint_a_anchor_identifier", "Raw"),
        ("endpoint_b_anchor_identifier", "Raw"),
        ("endpoint_a_x", "Int"),
        ("endpoint_a_y", "Int"),
        ("endpoint_a_z", "Int"),
        ("endpoint_b_x", "Int"),
        ("endpoint_b_y", "Int"),
        ("endpoint_b_z", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    TEMPORAL_LINK: (
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("link_version", "Int"),
        ("endpoint_a_anchor_identifier", "Raw"),
        ("endpoint_b_anchor_identifier", "Raw"),
        ("endpoint_a_epoch", "Int"),
        ("endpoint_b_epoch", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
    RENDEZVOUS_COORDINATE: (
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("coordinate_version", "Int"),
        ("position_anchor_identifier", "Raw"),
        ("time_anchor_identifier", "Raw"),
        ("destination_x", "Int"),
        ("destination_y", "Int"),
        ("destination_z", "Int"),
        ("destination_epoch", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ),
}


def expected_schema_field_type(field_name: str) -> str:
    """Return the canonical listed type for identifier and numeric fields."""
    return (
        "Raw"
        if field_name == "key"
        or field_name.endswith("_identifier")
        or field_name.endswith("_id")
        else "Int"
    )


def validate_all_schema_field_types() -> None:
    """Audit all 20 class schemas and reject any implicit type coercion."""
    if len(CLASS_ORDER) != 20 or set(SCHEMAS) != set(CLASS_ORDER):
        raise ValueError("generator must define exactly the 20 canonical class schemas")
    for class_name in CLASS_ORDER:
        schema = SCHEMAS[class_name]
        names = [field_name for field_name, _field_type in schema]
        if len(names) != len(set(names)):
            raise ValueError(f"duplicate schema field in {class_name}")
        for field_name, field_type in schema:
            expected_type = expected_schema_field_type(field_name)
            if field_type != expected_type:
                raise ValueError(
                    f"{class_name}.{field_name} must be {expected_type}, got {field_type}"
                )

SHIP_SEMANTIC_FIELDS = (
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
)
SHIP_MANAGED_FIELDS = ("type", "key", "work", "stable_identifier")
SHIP_SECONDARY_SERIAL_FIELDS = (
    "claim_serial",
    "discovery_serial",
    "satellite_serial",
    "civilization_scan_serial",
)
SECTOR_LISTED_FIELDS = (
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
    *tuple(
        category["remaining_field"] for category in CELESTIAL_CATEGORIES
    ),
    *tuple(category["serial_field"] for category in CELESTIAL_CATEGORIES),
    "revision",
    "key",
    "stable_identifier",
)

BODY_BANK: list[dict[str, Any]] = [
    {"code": 0, "name": "Red Dwarf", "slug": "RedDwarf", "body_type": 2, "body_profile": 10, "nominal_denominator": 8, "target_top_limb": 2_305_843_009_213_693_952, "life_stat": 0, "matter": 4_000, "crystal": 0, "gas": 4_000, "energy": 22_000, "satellites": 0},
    {"code": 1, "name": "Main Sequence Star", "slug": "MainSequenceStar", "body_type": 2, "body_profile": 11, "nominal_denominator": 32, "target_top_limb": 576_460_752_303_423_488, "life_stat": 0, "matter": 3_000, "crystal": 0, "gas": 4_000, "energy": 27_000, "satellites": 0},
    {"code": 2, "name": "Giant Star", "slug": "GiantStar", "body_type": 2, "body_profile": 12, "nominal_denominator": 256, "target_top_limb": 72_057_594_037_927_936, "life_stat": 0, "matter": 3_000, "crystal": 0, "gas": 4_000, "energy": 33_000, "satellites": 0},
    {"code": 3, "name": "Rocky Planet", "slug": "RockyPlanet", "body_type": 1, "body_profile": 20, "nominal_denominator": 8, "target_top_limb": 2_305_843_009_213_693_952, "life_stat": 0, "matter": 19_000, "crystal": 5_000, "gas": 3_000, "energy": 3_000, "satellites": 1},
    {"code": 4, "name": "Ocean Planet", "slug": "OceanPlanet", "body_type": 1, "body_profile": 21, "nominal_denominator": 32, "target_top_limb": 576_460_752_303_423_488, "life_stat": 0, "matter": 14_000, "crystal": 3_000, "gas": 14_000, "energy": 3_000, "satellites": 2},
    {"code": 5, "name": "Garden Planet", "slug": "GardenPlanet", "body_type": 1, "body_profile": 22, "nominal_denominator": 128, "target_top_limb": 144_115_188_075_855_872, "life_stat": 0, "matter": 17_000, "crystal": 9_000, "gas": 6_000, "energy": 6_000, "satellites": 1},
    {"code": 6, "name": "Gas Giant", "slug": "GasGiant", "body_type": 3, "body_profile": 30, "nominal_denominator": 16, "target_top_limb": 1_152_921_504_606_846_976, "life_stat": 0, "matter": 2_000, "crystal": 0, "gas": 24_000, "energy": 6_000, "satellites": 4},
    {"code": 7, "name": "Ice Giant", "slug": "IceGiant", "body_type": 4, "body_profile": 31, "nominal_denominator": 32, "target_top_limb": 576_460_752_303_423_488, "life_stat": 0, "matter": 4_000, "crystal": 9_000, "gas": 17_000, "energy": 4_000, "satellites": 3},
    {"code": 8, "name": "Barren Planet", "slug": "BarrenPlanet", "body_type": 1, "body_profile": 23, "nominal_denominator": 16, "target_top_limb": 1_152_921_504_606_846_976, "life_stat": 0, "matter": 23_000, "crystal": 9_000, "gas": 0, "energy": 0, "satellites": 0},
    {"code": 9, "name": "Neutron Star", "slug": "NeutronStar", "body_type": 5, "body_profile": 40, "nominal_denominator": 2_048, "target_top_limb": 9_007_199_254_740_992, "life_stat": 0, "matter": 2_000, "crystal": 1_000, "gas": 0, "energy": 43_000, "satellites": 0},
    {"code": 10, "name": "Black Hole", "slug": "BlackHole", "body_type": 6, "body_profile": 50, "nominal_denominator": 8_192, "target_top_limb": 2_251_799_813_685_248, "life_stat": 0, "matter": 0, "crystal": 0, "gas": 0, "energy": 50_000, "satellites": 0},
    {"code": 11, "name": "Anomaly", "slug": "Anomaly", "body_type": 7, "body_profile": 60, "nominal_denominator": 32_768, "target_top_limb": 562_949_953_421_312, "life_stat": 0, "matter": 18_000, "crystal": 9_000, "gas": 9_000, "energy": 18_000, "satellites": 0},
    {"code": 12, "name": "Megastructure", "slug": "Megastructure", "body_type": 8, "body_profile": 70, "nominal_denominator": 8, "target_top_limb": 2_305_843_009_213_693_952, "life_stat": 0, "matter": 10_000, "crystal": 10_000, "gas": 0, "energy": 10_000, "satellites": 0},
    {"code": 13, "name": "Gas Cluster", "slug": "GasCluster", "body_type": 9, "body_profile": 80, "nominal_denominator": 8, "target_top_limb": 2_305_843_009_213_693_952, "life_stat": 0, "matter": 5_000, "crystal": 0, "gas": 20_000, "energy": 5_000, "satellites": 0},
    {"code": 14, "name": "Stellar Remnant", "slug": "StellarRemnant", "body_type": 10, "body_profile": 90, "nominal_denominator": 8, "target_top_limb": 2_305_843_009_213_693_952, "life_stat": 0, "matter": 10_000, "crystal": 0, "gas": 0, "energy": 20_000, "satellites": 0},
]

BODY_TREE_CATEGORIES: list[dict[str, Any]] = [
    {
        "name": candidate["name"],
        "candidate_code": candidate["code"],
        "body_type": candidate["body_type"],
        "body_profile": candidate["body_profile"],
        "life_stat": candidate["life_stat"],
    }
    for candidate in BODY_BANK
]

# v3 resource routes use source-profile-specific actions while preserving one
# resource_type for the same logical commodity across every valid source.
# Resource entries are (name, CelestialBody pool field, extraction skill code).
_RESOURCE_GROUPS: list[
    tuple[str, int, list[tuple[str, str, int | None]]]
] = [
    (
        "Red Dwarf",
        0,
        [
            ("Fusion Gas", "gas_remaining", 8),
            ("Metal-Rich Ore", "matter_remaining", 16),
            ("Radiant Energy", "energy_remaining", 8),
            ("Red-Dwarf Plasma", "energy_remaining", 8),
            ("Magnetic Stellar Condensate", "matter_remaining", 7),
            ("Flare Spectrum Data", "energy_remaining", 8),
            ("Stellar Refractory Dust", "matter_remaining", 7),
        ],
    ),
    (
        "Main Sequence Star",
        1,
        [
            ("Fusion Gas", "gas_remaining", 8),
            ("Metal-Rich Ore", "matter_remaining", 16),
            ("Radiant Energy", "energy_remaining", 8),
            ("Photospheric Plasma", "energy_remaining", 8),
            ("Photospheric Mineral", "matter_remaining", 8),
            ("Stellar Spectrum Data", "energy_remaining", 8),
            ("Solar-Wind Condensate", "matter_remaining", 4),
        ],
    ),
    (
        "Giant Star",
        2,
        [
            ("Fusion Gas", "gas_remaining", 8),
            ("Metal-Rich Ore", "matter_remaining", 16),
            ("Radiant Energy", "energy_remaining", 8),
            ("Helium-Carbon Ejecta", "gas_remaining", 16),
            ("Heavy-Element Condensate", "matter_remaining", 16),
            ("Neutrino Data", "energy_remaining", 16),
            ("S-Process Ejecta", "matter_remaining", 16),
        ],
    ),
    (
        "Rocky Planet",
        3,
        [
            ("Ferrous Ore", "matter_remaining", None),
            ("Base-Metal Ore", "matter_remaining", None),
            ("Silicate Mineral", "matter_remaining", None),
            ("Industrial Mineral", "matter_remaining", None),
            ("Igneous Rock", "matter_remaining", None),
            ("Geothermal Energy", "energy_remaining", None),
            ("Sedimentary Rock", "matter_remaining", None),
        ],
    ),
    (
        "Ocean Planet",
        4,
        [
            ("Water", "matter_remaining", None),
            ("Seawater Minerals", "crystal_remaining", None),
            ("Atmospheric Gas", "gas_remaining", None),
            ("Seafloor Sulfide Ore", "matter_remaining", None),
            ("Marine Biomass", "matter_remaining", None),
            ("Tidal Energy", "energy_remaining", None),
            ("Dissolved Trace Minerals", "crystal_remaining", None),
        ],
    ),
    (
        "Garden Planet",
        5,
        [
            ("Biomass", "matter_remaining", None),
            ("Genetic Material", "matter_remaining", None),
            ("Biochemical Mixture", "gas_remaining", None),
            ("Microbial Culture", "matter_remaining", None),
            ("Natural Material", "crystal_remaining", None),
            ("Living Soil", "matter_remaining", 17),
            ("Plant Extract", "matter_remaining", None),
        ],
    ),
    (
        "Gas Giant",
        6,
        [
            ("Fusion Gas", "gas_remaining", None),
            ("Atmospheric Gas", "gas_remaining", None),
            ("Noble Gas", "gas_remaining", None),
            ("Deep-Atmosphere Gas", "gas_remaining", 3),
            ("Hydrocarbon Cloud", "gas_remaining", None),
            ("Storm Field Data", "energy_remaining", 11),
            ("Sulfur Cloud", "gas_remaining", 3),
        ],
    ),
    (
        "Ice Giant",
        7,
        [
            ("Fusion Gas", "gas_remaining", None),
            ("Volatile Ice", "crystal_remaining", None),
            ("Noble Gas", "gas_remaining", None),
            ("Cryogenic Volatile", "gas_remaining", 3),
            ("Ice-Mantle Material", "crystal_remaining", 7),
            ("High-Pressure Phase Data", "energy_remaining", 7),
            ("Cryosphere Spectrum Data", "energy_remaining", 7),
        ],
    ),
    (
        "Barren Planet",
        8,
        [
            ("Light-Metal Ore", "matter_remaining", None),
            ("Precious-Metal Ore", "crystal_remaining", None),
            ("Nuclear Ore", "crystal_remaining", None),
            ("Carbonaceous Deposit", "matter_remaining", None),
            ("Fertilizer Mineral", "matter_remaining", None),
            ("Dense-Metal Ore", "matter_remaining", None),
            ("Rare-Earth Ore", "crystal_remaining", None),
            ("Alkali Mineral Ore", "matter_remaining", None),
        ],
    ),
    (
        "Neutron Star",
        9,
        [
            ("Metal-Rich Ore", "matter_remaining", 16),
            ("High-Energy Radiation", "energy_remaining", 8),
            ("Gravitational Data", "energy_remaining", 16),
            ("R-Process Ejecta", "matter_remaining", 13),
            ("Degenerate-Crust Material", "crystal_remaining", 13),
            ("Pulsar Emission Data", "energy_remaining", 16),
            ("Magnetospheric Particle Flux", "energy_remaining", 13),
            ("Pulsar Timing Data", "energy_remaining", 16),
        ],
    ),
    (
        "Black Hole",
        10,
        [
            ("High-Energy Radiation", "energy_remaining", 8),
            ("Gravitational Data", "energy_remaining", 16),
            ("Accretion Data", "energy_remaining", 16),
            ("Accretion-Disk Matter", "energy_remaining", 13),
            ("Relativistic Plasma", "energy_remaining", 13),
            ("Lensing Data", "energy_remaining", 14),
            ("Accretion Aerosol", "energy_remaining", 13),
            ("Hawking Radiation Data", "energy_remaining", 14),
        ],
    ),
    (
        "Anomaly",
        11,
        [
            ("Temporal Data", "energy_remaining", 14),
            ("Gravitational Data", "matter_remaining", 14),
            ("Field Data", "crystal_remaining", 14),
            ("Phase-Shifted Matter", "matter_remaining", 13),
            ("Magnetic Observation", "crystal_remaining", 14),
            ("Radiation Observation", "energy_remaining", 14),
            ("Polarization Data", "energy_remaining", 14),
            ("Vacuum Fluctuation Data", "energy_remaining", 14),
        ],
    ),
    (
        "Megastructure",
        12,
        [
            ("Structural Salvage", "matter_remaining", 6),
            ("Electronic Salvage", "crystal_remaining", 2),
            ("Ceramic Salvage", "matter_remaining", 1),
            ("Archive Data", "crystal_remaining", 18),
            ("Polymer Salvage", "matter_remaining", 10),
            ("Optical Salvage", "crystal_remaining", 15),
            ("Mechanical Salvage", "matter_remaining", 1),
        ],
    ),
    (
        "Gas Cluster",
        13,
        [
            ("Fusion Gas", "gas_remaining", None),
            ("Noble Gas", "gas_remaining", None),
            ("Organic Ore", "matter_remaining", None),
            ("Molecular-Cloud Gas", "gas_remaining", None),
            ("Interstellar Dust", "matter_remaining", None),
            ("Molecular Spectrum Data", "energy_remaining", 11),
            ("Prebiotic Molecule Mixture", "matter_remaining", 5),
        ],
    ),
    (
        "Stellar Remnant",
        14,
        [
            ("Metal-Rich Ore", "matter_remaining", 16),
            ("Nuclear Ore", "energy_remaining", 16),
            ("Carbonaceous Deposit", "matter_remaining", 16),
            ("Supernova Ejecta", "matter_remaining", 16),
            ("Radioisotope Deposit", "energy_remaining", 4),
            ("Shockwave Spectrum Data", "energy_remaining", 16),
            ("Decay Spectrum Data", "energy_remaining", 16),
        ],
    ),
]


def _slug(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9]", "", value)


V3_SOURCE_RESOURCE_CODE_START = 119
V3_LEGACY_SOURCE_RESOURCE_NAMES = (
    "Fusion Gas",
    "Metal-Rich Ore",
    "Radiant Energy",
    "Ferrous Ore",
    "Base-Metal Ore",
    "Silicate Mineral",
    "Industrial Mineral",
    "Water",
    "Seawater Minerals",
    "Atmospheric Gas",
    "Biomass",
    "Genetic Material",
    "Biochemical Mixture",
    "Microbial Culture",
    "Natural Material",
    "Noble Gas",
    "Volatile Ice",
    "Light-Metal Ore",
    "Precious-Metal Ore",
    "Nuclear Ore",
    "Carbonaceous Deposit",
    "Fertilizer Mineral",
    "Dense-Metal Ore",
    "Rare-Earth Ore",
    "High-Energy Radiation",
    "Gravitational Data",
    "Accretion Data",
    "Temporal Data",
    "Field Data",
    "Structural Salvage",
    "Electronic Salvage",
    "Ceramic Salvage",
    "Archive Data",
    "Organic Ore",
)
V3_LEGACY_REFINED_RESOURCE_NAMES = (
    "Hydrogen",
    "Helium",
    "Deuterium",
    "Iron",
    "Nickel",
    "Cobalt",
    "Chromium",
    "Manganese",
    "Copper",
    "Zinc",
    "Tin",
    "Silicon",
    "Magnesium",
    "Quartz",
    "Limestone",
    "Clay",
    "Gypsum",
    "Sodium Chloride",
    "Calcium",
    "Nitrogen",
    "Oxygen",
    "Carbon Dioxide",
    "Cellulose",
    "Protein",
    "Lipid",
    "DNA",
    "RNA",
    "Plasmid",
    "Amino Acid",
    "Enzyme",
    "Alkaloid",
    "Bacterial Culture",
    "Fungal Culture",
    "Archaeal Culture",
    "Wood Fiber",
    "Chitin",
    "Natural Rubber",
    "Argon",
    "Neon",
    "Xenon",
    "Water Ice",
    "Methane Ice",
    "Ammonia Ice",
    "Aluminum",
    "Titanium",
    "Lithium",
    "Silver",
    "Gold",
    "Platinum",
    "Uranium",
    "Thorium",
    "Radium",
    "Carbon",
    "Graphite",
    "Diamond",
    "Phosphate",
    "Sulfur",
    "Potash",
    "Steel",
    "Carbon Composite",
    "Ceramic",
    "Glass",
    "Silicon Carbide",
    "Methanol",
    "Formaldehyde",
    "Benzene",
    "Lead",
    "Cerium",
    "Lanthanum",
    "Neodymium",
)
V3_LEGACY_REFINED_RESOURCE_CODE_START = (
    V3_SOURCE_RESOURCE_CODE_START + len(V3_LEGACY_SOURCE_RESOURCE_NAMES)
)
V4_SOURCE_RESOURCE_CODE_START = (
    V3_LEGACY_REFINED_RESOURCE_CODE_START
    + len(V3_LEGACY_REFINED_RESOURCE_NAMES)
)
V4_LEGACY_SOURCE_RESOURCE_NAMES = (
    "Red-Dwarf Plasma",
    "Magnetic Stellar Condensate",
    "Flare Spectrum Data",
    "Photospheric Plasma",
    "Photospheric Mineral",
    "Stellar Spectrum Data",
    "Helium-Carbon Ejecta",
    "Heavy-Element Condensate",
    "Neutrino Data",
    "Igneous Rock",
    "Geothermal Energy",
    "Seafloor Sulfide Ore",
    "Marine Biomass",
    "Tidal Energy",
    "Living Soil",
    "Deep-Atmosphere Gas",
    "Hydrocarbon Cloud",
    "Storm Field Data",
    "Cryogenic Volatile",
    "Ice-Mantle Material",
    "High-Pressure Phase Data",
    "R-Process Ejecta",
    "Degenerate-Crust Material",
    "Pulsar Emission Data",
    "Accretion-Disk Matter",
    "Relativistic Plasma",
    "Lensing Data",
    "Phase-Shifted Matter",
    "Magnetic Observation",
    "Radiation Observation",
    "Polymer Salvage",
    "Optical Salvage",
    "Molecular-Cloud Gas",
    "Interstellar Dust",
    "Molecular Spectrum Data",
    "Supernova Ejecta",
    "Radioisotope Deposit",
    "Shockwave Spectrum Data",
)
V4_LEGACY_REFINED_RESOURCE_NAMES = (
    "Ionized Hydrogen",
    "Ionized Helium",
    "Electron Plasma",
    "Ferrite Dust",
    "Magnetite Grain",
    "Cobalt Ferrite",
    "Proton Plasma",
    "Alpha-Particle Plasma",
    "Photospheric Electron Plasma",
    "Calcium Ion Dust",
    "Sodium Ion Dust",
    "Magnesium Ion Dust",
    "Helium-3",
    "Carbon-12",
    "Oxygen-16",
    "Strontium",
    "Barium",
    "Europium",
    "Basalt",
    "Granite",
    "Obsidian",
    "Pyrite",
    "Chalcopyrite",
    "Sphalerite",
    "Algal Fiber",
    "Marine Protein",
    "Algal Oil",
    "Humus",
    "Mycorrhizal Culture",
    "Soil Microbiome",
    "Ammonia Vapor",
    "Methane Vapor",
    "Hydrogen Sulfide",
    "Ethane",
    "Propane",
    "Acetylene",
    "Liquid Methane",
    "Liquid Ammonia",
    "Superionic Water",
    "High-Pressure Ice",
    "Methane Clathrate",
    "Ammonia Hydrate",
    "Osmium",
    "Iridium",
    "Rhenium",
    "Nuclear Pasta",
    "Neutron-Rich Alloy",
    "Superdense Carbon",
    "Ionized Iron",
    "Carbon Plasma",
    "Silicate Plasma",
    "Pair Plasma",
    "Synchrotron Plasma",
    "Relativistic Ion Beam",
    "Metastable Isotope",
    "Phase-Locked Crystal",
    "Vacuum-Polarized Matter",
    "Thermoplastic",
    "Thermoset Resin",
    "Elastomer",
    "Optical Glass",
    "Photonic Crystal",
    "Laser Crystal",
    "Molecular Hydrogen",
    "Carbon Monoxide",
    "Hydrogen Cyanide",
    "Silicate Dust",
    "Carbon Dust",
    "Ice Grain",
    "Calcium-44",
    "Titanium-44",
    "Nickel-56",
    "Cobalt-60",
    "Cesium-137",
    "Strontium-90",
)
V4_REFINED_RESOURCE_CODE_START = (
    V4_SOURCE_RESOURCE_CODE_START + len(V4_LEGACY_SOURCE_RESOURCE_NAMES)
)
V5_SOURCE_RESOURCE_CODE_START = (
    V4_REFINED_RESOURCE_CODE_START
    + len(V4_LEGACY_REFINED_RESOURCE_NAMES)
)

# Preserve every issued v3/v4 resource_type. The final primitive-fill source
# codes are appended after the complete earlier source/refined ranges.
SOURCE_RESOURCE_CODES: dict[str, int] = {
    name: V3_SOURCE_RESOURCE_CODE_START + index
    for index, name in enumerate(V3_LEGACY_SOURCE_RESOURCE_NAMES)
}
SOURCE_RESOURCE_CODES.update(
    {
        name: V4_SOURCE_RESOURCE_CODE_START + index
        for index, name in enumerate(V4_LEGACY_SOURCE_RESOURCE_NAMES)
    }
)
for _category, _candidate_code, _resources in _RESOURCE_GROUPS:
    for _resource_name, _remaining_field, _skill_code in _resources:
        if _resource_name not in SOURCE_RESOURCE_CODES:
            SOURCE_RESOURCE_CODES[_resource_name] = (
                V5_SOURCE_RESOURCE_CODE_START
                + len(SOURCE_RESOURCE_CODES)
                - len(V3_LEGACY_SOURCE_RESOURCE_NAMES)
                - len(V4_LEGACY_SOURCE_RESOURCE_NAMES)
            )

CIVILIZATION_TECH_RESOURCES: list[dict[str, Any]] = []
for _category, _candidate_code, _resources in _RESOURCE_GROUPS:
    _category_slug = _slug(_category)
    for _resource_name, _remaining_field, _skill_code in _resources:
        _resource_code = SOURCE_RESOURCE_CODES[_resource_name]
        _resource_slug = _slug(_resource_name)
        CIVILIZATION_TECH_RESOURCES.append(
            {
                "code": _resource_code,
                "name": _resource_name,
                "slug": _resource_slug,
                "action": f"Extract{_category_slug}{_resource_slug}",
                "category": _category,
                "candidate_code": _candidate_code,
                "remaining_field": _remaining_field,
                "amount": 1,
                "skill_code": _skill_code,
                "vdf_iterations": None,
            }
        )

_REFINEMENT_GROUP_ROWS: list[
    tuple[str, list[tuple[str, int, int]]]
] = [
    ("Fusion Gas", [("Hydrogen", 600, 4), ("Helium", 300, 4), ("Deuterium", 100, 4)]),
    ("Metal-Rich Ore", [("Iron", 600, 1), ("Nickel", 300, 1), ("Cobalt", 100, 1)]),
    ("Ferrous Ore", [("Iron", 600, 1), ("Chromium", 300, 1), ("Manganese", 100, 1)]),
    ("Base-Metal Ore", [("Copper", 600, 1), ("Zinc", 300, 1), ("Tin", 100, 1)]),
    ("Silicate Mineral", [("Silicon", 600, 3), ("Magnesium", 300, 3), ("Quartz", 100, 3)]),
    ("Industrial Mineral", [("Limestone", 600, 3), ("Clay", 300, 3), ("Gypsum", 100, 3)]),
    ("Seawater Minerals", [("Sodium Chloride", 600, 3), ("Magnesium", 300, 3), ("Calcium", 100, 3)]),
    ("Atmospheric Gas", [("Nitrogen", 600, 3), ("Oxygen", 300, 3), ("Carbon Dioxide", 100, 3)]),
    ("Biomass", [("Cellulose", 600, 12), ("Protein", 300, 12), ("Lipid", 100, 12)]),
    ("Genetic Material", [("DNA", 600, 5), ("RNA", 300, 5), ("Plasmid", 100, 5)]),
    ("Biochemical Mixture", [("Amino Acid", 600, 5), ("Enzyme", 300, 5), ("Alkaloid", 100, 5)]),
    ("Microbial Culture", [("Bacterial Culture", 600, 12), ("Fungal Culture", 300, 12), ("Archaeal Culture", 100, 12)]),
    ("Natural Material", [("Wood Fiber", 600, 12), ("Chitin", 300, 12), ("Natural Rubber", 100, 12)]),
    ("Noble Gas", [("Argon", 600, 3), ("Neon", 300, 3), ("Xenon", 100, 3)]),
    ("Volatile Ice", [("Water Ice", 600, 3), ("Methane Ice", 300, 3), ("Ammonia Ice", 100, 3)]),
    ("Light-Metal Ore", [("Aluminum", 600, 1), ("Titanium", 300, 1), ("Lithium", 100, 1)]),
    ("Precious-Metal Ore", [("Silver", 600, 1), ("Gold", 300, 1), ("Platinum", 100, 1)]),
    ("Nuclear Ore", [("Uranium", 600, 4), ("Thorium", 300, 4), ("Radium", 100, 4)]),
    ("Carbonaceous Deposit", [("Carbon", 600, 3), ("Graphite", 300, 3), ("Diamond", 100, 3)]),
    ("Fertilizer Mineral", [("Phosphate", 600, 3), ("Sulfur", 300, 3), ("Potash", 100, 3)]),
    ("Structural Salvage", [("Steel", 600, 1), ("Aluminum", 300, 1), ("Carbon Composite", 100, 1)]),
    ("Electronic Salvage", [("Copper", 600, 2), ("Silicon", 300, 2), ("Gold", 100, 2)]),
    ("Ceramic Salvage", [("Ceramic", 600, 3), ("Glass", 300, 3), ("Silicon Carbide", 100, 3)]),
    ("Organic Ore", [("Methanol", 600, 3), ("Formaldehyde", 300, 3), ("Benzene", 100, 3)]),
    ("Dense-Metal Ore", [("Lead", 600, 1), ("Nickel", 300, 1), ("Cobalt", 100, 1)]),
    ("Rare-Earth Ore", [("Cerium", 600, 1), ("Lanthanum", 300, 1), ("Neodymium", 100, 1)]),
    (
        "Red-Dwarf Plasma",
        [
            ("Ionized Hydrogen", 600, 8),
            ("Ionized Helium", 300, 8),
            ("Electron Plasma", 100, 8),
        ],
    ),
    (
        "Magnetic Stellar Condensate",
        [
            ("Ferrite Dust", 600, 7),
            ("Magnetite Grain", 300, 7),
            ("Cobalt Ferrite", 100, 7),
        ],
    ),
    (
        "Photospheric Plasma",
        [
            ("Proton Plasma", 600, 8),
            ("Alpha-Particle Plasma", 300, 8),
            ("Photospheric Electron Plasma", 100, 8),
        ],
    ),
    (
        "Photospheric Mineral",
        [
            ("Calcium Ion Dust", 600, 8),
            ("Sodium Ion Dust", 300, 8),
            ("Magnesium Ion Dust", 100, 8),
        ],
    ),
    (
        "Helium-Carbon Ejecta",
        [
            ("Helium-3", 600, 16),
            ("Carbon-12", 300, 16),
            ("Oxygen-16", 100, 16),
        ],
    ),
    (
        "Heavy-Element Condensate",
        [
            ("Strontium", 600, 16),
            ("Barium", 300, 16),
            ("Europium", 100, 16),
        ],
    ),
    (
        "Igneous Rock",
        [
            ("Basalt", 600, 6),
            ("Granite", 300, 6),
            ("Obsidian", 100, 6),
        ],
    ),
    (
        "Seafloor Sulfide Ore",
        [
            ("Pyrite", 600, 1),
            ("Chalcopyrite", 300, 1),
            ("Sphalerite", 100, 1),
        ],
    ),
    (
        "Marine Biomass",
        [
            ("Algal Fiber", 600, 12),
            ("Marine Protein", 300, 12),
            ("Algal Oil", 100, 12),
        ],
    ),
    (
        "Living Soil",
        [
            ("Humus", 600, 17),
            ("Mycorrhizal Culture", 300, 17),
            ("Soil Microbiome", 100, 17),
        ],
    ),
    (
        "Deep-Atmosphere Gas",
        [
            ("Ammonia Vapor", 600, 3),
            ("Methane Vapor", 300, 3),
            ("Hydrogen Sulfide", 100, 3),
        ],
    ),
    (
        "Hydrocarbon Cloud",
        [
            ("Ethane", 600, 3),
            ("Propane", 300, 3),
            ("Acetylene", 100, 3),
        ],
    ),
    (
        "Cryogenic Volatile",
        [
            ("Liquid Methane", 600, 3),
            ("Liquid Ammonia", 300, 3),
            ("Superionic Water", 100, 7),
        ],
    ),
    (
        "Ice-Mantle Material",
        [
            ("High-Pressure Ice", 600, 7),
            ("Methane Clathrate", 300, 7),
            ("Ammonia Hydrate", 100, 7),
        ],
    ),
    (
        "R-Process Ejecta",
        [
            ("Osmium", 600, 13),
            ("Iridium", 300, 13),
            ("Rhenium", 100, 13),
        ],
    ),
    (
        "Degenerate-Crust Material",
        [
            ("Nuclear Pasta", 600, 13),
            ("Neutron-Rich Alloy", 300, 13),
            ("Superdense Carbon", 100, 13),
        ],
    ),
    (
        "Accretion-Disk Matter",
        [
            ("Ionized Iron", 600, 13),
            ("Carbon Plasma", 300, 13),
            ("Silicate Plasma", 100, 13),
        ],
    ),
    (
        "Relativistic Plasma",
        [
            ("Pair Plasma", 600, 13),
            ("Synchrotron Plasma", 300, 13),
            ("Relativistic Ion Beam", 100, 13),
        ],
    ),
    (
        "Phase-Shifted Matter",
        [
            ("Metastable Isotope", 600, 13),
            ("Phase-Locked Crystal", 300, 14),
            ("Vacuum-Polarized Matter", 100, 14),
        ],
    ),
    (
        "Polymer Salvage",
        [
            ("Thermoplastic", 600, 10),
            ("Thermoset Resin", 300, 10),
            ("Elastomer", 100, 10),
        ],
    ),
    (
        "Optical Salvage",
        [
            ("Optical Glass", 600, 15),
            ("Photonic Crystal", 300, 15),
            ("Laser Crystal", 100, 15),
        ],
    ),
    (
        "Molecular-Cloud Gas",
        [
            ("Molecular Hydrogen", 600, 3),
            ("Carbon Monoxide", 300, 3),
            ("Hydrogen Cyanide", 100, 3),
        ],
    ),
    (
        "Interstellar Dust",
        [
            ("Silicate Dust", 600, 3),
            ("Carbon Dust", 300, 3),
            ("Ice Grain", 100, 3),
        ],
    ),
    (
        "Supernova Ejecta",
        [
            ("Calcium-44", 600, 16),
            ("Titanium-44", 300, 16),
            ("Nickel-56", 100, 16),
        ],
    ),
    (
        "Radioisotope Deposit",
        [
            ("Cobalt-60", 600, 4),
            ("Cesium-137", 300, 4),
            ("Strontium-90", 100, 4),
        ],
    ),
    (
        "Stellar Refractory Dust",
        [
            ("Corundum", 600, 7),
            ("Spinel", 300, 7),
            ("Perovskite", 100, 7),
        ],
    ),
    (
        "Solar-Wind Condensate",
        [
            ("Lithium-7", 600, 4),
            ("Beryllium-9", 300, 4),
            ("Boron-11", 100, 4),
        ],
    ),
    (
        "S-Process Ejecta",
        [
            ("Yttrium", 600, 16),
            ("Zirconium", 300, 16),
            ("Molybdenum", 100, 16),
        ],
    ),
    (
        "Sedimentary Rock",
        [
            ("Sandstone", 600, 3),
            ("Shale", 300, 3),
            ("Dolomite", 100, 3),
        ],
    ),
    (
        "Dissolved Trace Minerals",
        [
            ("Bromine", 600, 3),
            ("Iodine", 300, 3),
            ("Boron", 100, 3),
        ],
    ),
    (
        "Plant Extract",
        [
            ("Starch", 600, 12),
            ("Sucrose", 300, 12),
            ("Lignin", 100, 12),
        ],
    ),
    (
        "Sulfur Cloud",
        [
            ("Sulfur Dioxide", 600, 3),
            ("Ammonium Hydrosulfide", 300, 3),
            ("Polysulfur Aerosol", 100, 3),
        ],
    ),
    (
        "Alkali Mineral Ore",
        [
            ("Sodium", 600, 3),
            ("Potassium", 300, 3),
            ("Rubidium", 100, 3),
        ],
    ),
    (
        "Magnetospheric Particle Flux",
        [
            ("Positron Plasma", 600, 13),
            ("Muon Flux", 300, 13),
            ("Heavy-Ion Flux", 100, 13),
        ],
    ),
    (
        "Accretion Aerosol",
        [
            ("Iron Oxide Aerosol", 600, 13),
            ("Silicate Aerosol", 300, 13),
            ("Carbonaceous Aerosol", 100, 13),
        ],
    ),
    (
        "Mechanical Salvage",
        [
            ("Bearing Steel", 600, 1),
            ("Tool Steel", 300, 1),
            ("Industrial Lubricant", 100, 1),
        ],
    ),
    (
        "Prebiotic Molecule Mixture",
        [
            ("Glycine", 600, 5),
            ("Formamide", 300, 5),
            ("Acetonitrile", 100, 5),
        ],
    ),
]

V5_REFINED_RESOURCE_CODE_START = (
    V5_SOURCE_RESOURCE_CODE_START
    + len(SOURCE_RESOURCE_CODES)
    - len(V3_LEGACY_SOURCE_RESOURCE_NAMES)
    - len(V4_LEGACY_SOURCE_RESOURCE_NAMES)
)
REFINED_RESOURCE_CODES: dict[str, int] = {
    name: V3_LEGACY_REFINED_RESOURCE_CODE_START + index
    for index, name in enumerate(V3_LEGACY_REFINED_RESOURCE_NAMES)
}
REFINED_RESOURCE_CODES.update(
    {
        name: V4_REFINED_RESOURCE_CODE_START + index
        for index, name in enumerate(V4_LEGACY_REFINED_RESOURCE_NAMES)
    }
)
REFINEMENT_ROUTES: list[dict[str, Any]] = []
for _parent_name, _children in _REFINEMENT_GROUP_ROWS:
    for _child_slot, (
        _child_name,
        _allocation_per_1000_units,
        _skill_code,
    ) in enumerate(
        _children,
        start=1,
    ):
        if _child_name not in REFINED_RESOURCE_CODES:
            REFINED_RESOURCE_CODES[_child_name] = (
                V5_REFINED_RESOURCE_CODE_START
                + len(REFINED_RESOURCE_CODES)
                - len(V3_LEGACY_REFINED_RESOURCE_NAMES)
                - len(V4_LEGACY_REFINED_RESOURCE_NAMES)
            )
        REFINEMENT_ROUTES.append(
            {
                "parent_name": _parent_name,
                "parent_slug": _slug(_parent_name),
                "child_name": _child_name,
                "child_slug": _slug(_child_name),
                "child_slot": _child_slot,
                "allocation_per_1000_units": _allocation_per_1000_units,
                "skill_code": _skill_code,
                "vdf_tier": None,
                "vdf_iterations": None,
                "resource_code": REFINED_RESOURCE_CODES[_child_name],
                "action": (
                    f"Refine{_slug(_parent_name)}To{_slug(_child_name)}"
                ),
            }
        )

_body_by_code = {item["code"]: item for item in BODY_BANK}
_children_by_parent = {
    parent_name: children
    for parent_name, children in _REFINEMENT_GROUP_ROWS
}
for _resource in CIVILIZATION_TECH_RESOURCES:
    _source_body = _body_by_code[_resource["candidate_code"]]
    _pool_name = _resource["remaining_field"].removesuffix("_remaining")
    _resource["maximum_units"] = _source_body[_pool_name]
    _resource["composite"] = _resource["name"] in _children_by_parent
    _resource["output_class"] = (
        COMPOSITE_RESOURCE if _resource["composite"] else RESOURCE
    )
    _resource["child_allocations"] = [
        {
            "slot": slot,
            "name": child_name,
            "resource_code": REFINED_RESOURCE_CODES[child_name],
            "maximum_units": (
                _resource["maximum_units"]
                * allocation_per_1000_units
                // 1_000
            ),
            "allocation_per_1000_units": allocation_per_1000_units,
            "skill_code": skill_code,
        }
        for slot, (
            child_name,
            allocation_per_1000_units,
            skill_code,
        ) in enumerate(
            _children_by_parent.get(_resource["name"], []),
            start=1,
        )
    ]

assert len(_REFINEMENT_GROUP_ROWS) == 63
assert len(REFINEMENT_ROUTES) == 189
assert len(REFINED_RESOURCE_CODES) == 181
assert len(SOURCE_RESOURCE_CODES) == 90
assert len(CIVILIZATION_TECH_RESOURCES) == 109
assert set(resource["candidate_code"] for resource in CIVILIZATION_TECH_RESOURCES) == set(range(15))
assert set(SOURCE_RESOURCE_CODES).isdisjoint(REFINED_RESOURCE_CODES)
assert set(SOURCE_RESOURCE_CODES.values()).isdisjoint(
    REFINED_RESOURCE_CODES.values()
)
assert all(
    SOURCE_RESOURCE_CODES[name] == V3_SOURCE_RESOURCE_CODE_START + index
    for index, name in enumerate(V3_LEGACY_SOURCE_RESOURCE_NAMES)
)
assert all(
    REFINED_RESOURCE_CODES[name]
    == V3_LEGACY_REFINED_RESOURCE_CODE_START + index
    for index, name in enumerate(V3_LEGACY_REFINED_RESOURCE_NAMES)
)
assert all(
    SOURCE_RESOURCE_CODES[name] == V4_SOURCE_RESOURCE_CODE_START + index
    for index, name in enumerate(V4_LEGACY_SOURCE_RESOURCE_NAMES)
)
assert all(
    REFINED_RESOURCE_CODES[name]
    == V4_REFINED_RESOURCE_CODE_START + index
    for index, name in enumerate(V4_LEGACY_REFINED_RESOURCE_NAMES)
)
_resource_name_frequency = Counter(
    resource["name"] for resource in CIVILIZATION_TECH_RESOURCES
)
assert all(
    7
    <= sum(
        resource["candidate_code"] == candidate_code
        for resource in CIVILIZATION_TECH_RESOURCES
    )
    <= 8
    for candidate_code in range(15)
)
assert all(
    sum(
        resource["candidate_code"] == candidate_code
        and _resource_name_frequency[resource["name"]] == 1
        for resource in CIVILIZATION_TECH_RESOURCES
    )
    >= 4
    for candidate_code in range(15)
)
assert all(
    resource["maximum_units"] % 1_000 == 0
    for resource in CIVILIZATION_TECH_RESOURCES
    if resource["composite"]
)
assert all(
    sum(child["maximum_units"] for child in resource["child_allocations"])
    == resource["maximum_units"]
    for resource in CIVILIZATION_TECH_RESOURCES
    if resource["composite"]
)

CIVILIZATION_TYPES: list[dict[str, Any]] = [
    {
        "code": 1,
        "name": "Type I Civilization",
        "slug": "TypeI",
        "action": "MaterializeCivilizationTypeI",
        "selection_mode": DETERMINISTIC_SELECTOR_MODE,
        "minimum_civilization_scan_serial": 64,
    },
    {
        "code": 2,
        "name": "Type II Civilization",
        "slug": "TypeII",
        "action": "MaterializeCivilizationTypeII",
        "selection_mode": DETERMINISTIC_SELECTOR_MODE,
        "minimum_civilization_scan_serial": 1_024,
    },
    {
        "code": 3,
        "name": "Type III Civilization",
        "slug": "TypeIII",
        "action": "MaterializeCivilizationTypeIII",
        "selection_mode": DETERMINISTIC_SELECTOR_MODE,
        "minimum_civilization_scan_serial": 16_384,
    },
]

EXPLICIT_COUNTER_GATES: dict[str, dict[str, Any]] = {
    **{
        f"SurveySector_{profile['code']:02d}_{profile['slug']}": {
            "selection_mode": DETERMINISTIC_SELECTOR_MODE,
            "selection_kind": "survey_profile",
            "selected_code": profile["code"],
            "counter_field": "claim_serial",
            "minimum_inclusive": profile["minimum_claim_serial"],
        }
        for profile in SURVEY_PROFILES
    },
    **{
        civilization_type["action"]: {
            "selection_mode": DETERMINISTIC_SELECTOR_MODE,
            "selection_kind": "civilization_type",
            "selected_code": civilization_type["code"],
            "counter_field": "civilization_scan_serial",
            "minimum_inclusive": civilization_type[
                "minimum_civilization_scan_serial"
            ],
        }
        for civilization_type in CIVILIZATION_TYPES
    },
}
assert len(EXPLICIT_COUNTER_GATES) == 8

_SKILL_GROUPS: list[tuple[int, str, list[str]]] = [
    (
        1,
        "TypeI",
        [
            "Industrial Fabrication",
            "Electronics",
            "Chemical Engineering",
            "Nuclear Engineering",
            "Genetic Engineering",
            "Planetary Infrastructure",
        ],
    ),
    (
        2,
        "TypeII",
        [
            "Metamaterial Engineering",
            "Stellar Energy Systems",
            "Synthetic Intelligence",
            "Molecular Fabrication",
            "Interstellar Navigation",
            "Biosphere Engineering",
        ],
    ),
    (
        3,
        "TypeIII",
        [
            "Exotic Matter Engineering",
            "Spacetime Engineering",
            "Galactic Intelligence Architecture",
            "Stellar Engineering",
            "World Seeding",
            "Civilization Engineering",
        ],
    ),
]

TECHNOLOGY_SKILLS: list[dict[str, Any]] = []
for _type_index, (_civilization_type, _type_slug, _skills) in enumerate(_SKILL_GROUPS):
    for _skill_index, _skill_name in enumerate(_skills):
        _skill_code = 1 + _type_index * 6 + _skill_index
        _skill_slug = _slug(_skill_name)
        TECHNOLOGY_SKILLS.append(
            {
                "code": _skill_code,
                "name": f"{_skill_name} Skill",
                "slug": _skill_slug,
                "action": f"Develop{_type_slug}{_skill_slug}Skill",
                "civilization_type": _civilization_type,
                "reusable": 1,
            }
        )

SHIP_TIERS = [
    {"name": "Small", "tier": 0, "extraction_amount": 10, "rare_extraction_amount": 1, "move": 1, "timewarp": 1, "build_vdf": 4, "move_vdf": None, "timewarp_vdf": 4},
    {"name": "Medium", "tier": 1, "extraction_amount": 50, "rare_extraction_amount": 5, "move": 10, "timewarp": 10, "build_vdf": 12, "move_vdf": None, "timewarp_vdf": 12},
    {"name": "Large", "tier": 2, "extraction_amount": 250, "rare_extraction_amount": 25, "move": 100, "timewarp": 100, "build_vdf": 28, "move_vdf": None, "timewarp_vdf": 28},
]

BASE_RESOURCE_CODES = {
    "Matter": 1,
    "Crystal": 2,
    "Gas": 3,
    "Energy": 4,
}


def recipe_entry(name: str, amount: int) -> dict[str, Any]:
    resource_code = BASE_RESOURCE_CODES.get(name)
    if resource_code is None:
        resource_code = REFINED_RESOURCE_CODES[name]
    return {
        "name": name,
        "slug": _slug(name),
        "resource_code": resource_code,
        "amount": amount,
    }


MEDIUM_SHIP_RECIPE = [
    recipe_entry("Matter", 10),
    recipe_entry("Crystal", 10),
    recipe_entry("Energy", 10),
    recipe_entry("Iron", 6),
    recipe_entry("Aluminum", 6),
    recipe_entry("Copper", 6),
    recipe_entry("Silicon", 6),
    recipe_entry("Carbon", 6),
]

LARGE_SHIP_RECIPE = [
    recipe_entry("Matter", 50),
    recipe_entry("Crystal", 50),
    recipe_entry("Energy", 50),
    recipe_entry("Steel", 30),
    recipe_entry("Aluminum", 30),
    recipe_entry("Titanium", 15),
    recipe_entry("Copper", 30),
    recipe_entry("Silicon", 30),
    recipe_entry("Gold", 15),
    recipe_entry("Carbon Composite", 5),
]

AUXILIARY_SMALL_RECIPE = [
    recipe_entry("Matter", 10),
    recipe_entry("Iron", 6),
    recipe_entry("Aluminum", 6),
    recipe_entry("Copper", 6),
    recipe_entry("Silicon", 6),
]

LARGE_CONSTRUCTION_SKILLS = [
    {
        "name": "Industrial Fabrication",
        "slug": "Industrial",
        "skill_code": 1,
        "field": "industrial_authorized",
    },
    {
        "name": "Electronics",
        "slug": "Electronics",
        "skill_code": 2,
        "field": "electronics_authorized",
    },
    {
        "name": "Molecular Fabrication",
        "slug": "Molecular",
        "skill_code": 10,
        "field": "molecular_authorized",
    },
]

# Every ingredient in both initial construction recipes remains reachable by
# a Small Ship. Higher tier gates apply only to post-bootstrap environments
# and resource families.
MEDIUM_EXTRACTION_CANDIDATES = {0, 1, 2, 6, 7, 14}
LARGE_EXTRACTION_CANDIDATES = {9, 10, 11}
MEDIUM_EXTRACTION_RESOURCES = {
    (8, "Nuclear Ore"),
    (8, "Dense-Metal Ore"),
    (8, "Rare-Earth Ore"),
    (12, "Electronic Salvage"),
    (12, "Ceramic Salvage"),
}
LARGE_EXTRACTION_RESOURCES = {
    (12, "Archive Data"),
}
for _resource in CIVILIZATION_TECH_RESOURCES:
    _resource["minimum_ship_tier"] = (
        2
        if (
            _resource["candidate_code"] in LARGE_EXTRACTION_CANDIDATES
            or (
                _resource["candidate_code"],
                _resource["name"],
            )
            in LARGE_EXTRACTION_RESOURCES
        )
        else 1
        if (
            _resource["candidate_code"] in MEDIUM_EXTRACTION_CANDIDATES
            or (
                _resource["candidate_code"],
                _resource["name"],
            )
            in MEDIUM_EXTRACTION_RESOURCES
        )
        else 0
    )

VDF_DIFFICULTY_TIERS: dict[str, dict[str, Any]] = {
    "light": {
        "iterations": 2,
        "description": "free gases, noble gases, and simple volatiles",
    },
    "common": {
        "iterations": 4,
        "description": "ices, biomass, organics, and accessible energy",
    },
    "solid": {
        "iterations": 8,
        "description": "ore, silicate, crystal, living samples, and industrial solids",
    },
    "advanced": {
        "iterations": 12,
        "description": "fusion, isotopes, stellar matter, and hazardous energy",
    },
    "exotic": {
        "iterations": 20,
        "description": "anomalies, exotic matter, and relativistic materials",
    },
    "artifact": {
        "iterations": 32,
        "description": "megastructure systems and advanced artifact components",
    },
}

ECONOMY_SHIP_BUILD_VDF = {
    # At approximately 3.53 seconds per iteration on the reference machine,
    # these target about 1 minute, 3 minutes, and 30 minutes.
    "Small": 17,
    "Medium": 51,
    "Large": 510,
}

ECONOMY_BASE_EXTRACTION_VDF = {
    "Matter": "solid",
    "Crystal": "solid",
    "Gas": "light",
    "Energy": "common",
}

ECONOMY_RESOURCE_VDF_TIER = {
    "Fusion Gas": "advanced",
    "Metal-Rich Ore": "advanced",
    "Radiant Energy": "common",
    "Ferrous Ore": "solid",
    "Base-Metal Ore": "solid",
    "Silicate Mineral": "solid",
    "Industrial Mineral": "solid",
    "Water": "light",
    "Seawater Minerals": "common",
    "Atmospheric Gas": "light",
    "Biomass": "common",
    "Genetic Material": "solid",
    "Biochemical Mixture": "common",
    "Microbial Culture": "solid",
    "Natural Material": "solid",
    "Noble Gas": "light",
    "Volatile Ice": "common",
    "Light-Metal Ore": "solid",
    "Precious-Metal Ore": "solid",
    "Nuclear Ore": "advanced",
    "Carbonaceous Deposit": "solid",
    "Fertilizer Mineral": "solid",
    "Dense-Metal Ore": "solid",
    "Rare-Earth Ore": "solid",
    "High-Energy Radiation": "advanced",
    "Gravitational Data": "exotic",
    "Accretion Data": "exotic",
    "Temporal Data": "exotic",
    "Field Data": "exotic",
    "Structural Salvage": "artifact",
    "Electronic Salvage": "artifact",
    "Ceramic Salvage": "artifact",
    "Archive Data": "artifact",
    "Organic Ore": "common",
    "Red-Dwarf Plasma": "advanced",
    "Magnetic Stellar Condensate": "advanced",
    "Flare Spectrum Data": "advanced",
    "Photospheric Plasma": "advanced",
    "Photospheric Mineral": "advanced",
    "Stellar Spectrum Data": "advanced",
    "Helium-Carbon Ejecta": "advanced",
    "Heavy-Element Condensate": "advanced",
    "Neutrino Data": "advanced",
    "Igneous Rock": "solid",
    "Geothermal Energy": "common",
    "Seafloor Sulfide Ore": "solid",
    "Marine Biomass": "common",
    "Tidal Energy": "common",
    "Living Soil": "solid",
    "Deep-Atmosphere Gas": "light",
    "Hydrocarbon Cloud": "common",
    "Storm Field Data": "advanced",
    "Cryogenic Volatile": "common",
    "Ice-Mantle Material": "solid",
    "High-Pressure Phase Data": "advanced",
    "R-Process Ejecta": "exotic",
    "Degenerate-Crust Material": "exotic",
    "Pulsar Emission Data": "advanced",
    "Accretion-Disk Matter": "exotic",
    "Relativistic Plasma": "exotic",
    "Lensing Data": "exotic",
    "Phase-Shifted Matter": "exotic",
    "Magnetic Observation": "exotic",
    "Radiation Observation": "exotic",
    "Polymer Salvage": "artifact",
    "Optical Salvage": "artifact",
    "Molecular-Cloud Gas": "light",
    "Interstellar Dust": "solid",
    "Molecular Spectrum Data": "advanced",
    "Supernova Ejecta": "advanced",
    "Radioisotope Deposit": "advanced",
    "Shockwave Spectrum Data": "advanced",
    "Stellar Refractory Dust": "advanced",
    "Solar-Wind Condensate": "advanced",
    "S-Process Ejecta": "advanced",
    "Sedimentary Rock": "solid",
    "Dissolved Trace Minerals": "common",
    "Plant Extract": "common",
    "Sulfur Cloud": "common",
    "Cryosphere Spectrum Data": "advanced",
    "Alkali Mineral Ore": "solid",
    "Magnetospheric Particle Flux": "exotic",
    "Pulsar Timing Data": "advanced",
    "Accretion Aerosol": "exotic",
    "Hawking Radiation Data": "exotic",
    "Polarization Data": "exotic",
    "Vacuum Fluctuation Data": "exotic",
    "Mechanical Salvage": "artifact",
    "Prebiotic Molecule Mixture": "common",
    "Decay Spectrum Data": "advanced",
}

ECONOMY_REFINEMENT_VDF_TIER = {
    "Fusion Gas": "advanced",
    "Metal-Rich Ore": "advanced",
    "Ferrous Ore": "solid",
    "Base-Metal Ore": "solid",
    "Silicate Mineral": "solid",
    "Industrial Mineral": "solid",
    "Seawater Minerals": "common",
    "Atmospheric Gas": "light",
    "Biomass": "common",
    "Genetic Material": "solid",
    "Biochemical Mixture": "common",
    "Microbial Culture": "solid",
    "Natural Material": "solid",
    "Noble Gas": "light",
    "Volatile Ice": "common",
    "Light-Metal Ore": "solid",
    "Precious-Metal Ore": "solid",
    "Nuclear Ore": "advanced",
    "Carbonaceous Deposit": "solid",
    "Fertilizer Mineral": "solid",
    "Structural Salvage": "artifact",
    "Electronic Salvage": "artifact",
    "Ceramic Salvage": "artifact",
    "Organic Ore": "common",
    "Dense-Metal Ore": "solid",
    "Rare-Earth Ore": "solid",
    "Red-Dwarf Plasma": "advanced",
    "Magnetic Stellar Condensate": "advanced",
    "Photospheric Plasma": "advanced",
    "Photospheric Mineral": "advanced",
    "Helium-Carbon Ejecta": "advanced",
    "Heavy-Element Condensate": "advanced",
    "Igneous Rock": "solid",
    "Seafloor Sulfide Ore": "solid",
    "Marine Biomass": "common",
    "Living Soil": "solid",
    "Deep-Atmosphere Gas": "light",
    "Hydrocarbon Cloud": "common",
    "Cryogenic Volatile": "common",
    "Ice-Mantle Material": "solid",
    "R-Process Ejecta": "exotic",
    "Degenerate-Crust Material": "exotic",
    "Accretion-Disk Matter": "exotic",
    "Relativistic Plasma": "exotic",
    "Phase-Shifted Matter": "exotic",
    "Polymer Salvage": "artifact",
    "Optical Salvage": "artifact",
    "Molecular-Cloud Gas": "light",
    "Interstellar Dust": "solid",
    "Supernova Ejecta": "advanced",
    "Radioisotope Deposit": "advanced",
    "Stellar Refractory Dust": "advanced",
    "Solar-Wind Condensate": "advanced",
    "S-Process Ejecta": "advanced",
    "Sedimentary Rock": "solid",
    "Dissolved Trace Minerals": "common",
    "Plant Extract": "common",
    "Sulfur Cloud": "common",
    "Alkali Mineral Ore": "solid",
    "Magnetospheric Particle Flux": "exotic",
    "Accretion Aerosol": "exotic",
    "Mechanical Salvage": "artifact",
    "Prebiotic Molecule Mixture": "common",
}

CURRENT_BASE_EXTRACTION_VDF = {
    "Matter": 4,
    "Crystal": 8,
    "Gas": 8,
    "Energy": 12,
}
BASE_EXTRACTION_VDF = dict(CURRENT_BASE_EXTRACTION_VDF)
ACTIVE_VDF_PROFILE = "current"
PHASE4_ADAPTER_CANARIES_ENABLED = True
PHASE5_ADAPTER_CANARIES_ENABLED = True
PHASE6_MOVEMENT_CANARIES_ENABLED = True
PHASE6_TOKEN_LAYOUT_ENABLED = True
RHAI_MAX_LINE_LENGTH = 278
RHAI_SIMPLE_WRAPPER_MAX_LINE_LENGTH = 144

# Phase 4 inventories are profile-specific so every emitted fixed helper has
# active callers and inactive-profile helpers cannot change the source shape.
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

# Representatives pin the fixed shape of each compiled Phase 5 topology.
PHASE5_ADAPTER_HELPERS = (
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
PHASE5_BULK_HELPER_DISTRIBUTION = {
    "fabricate_component_reusable_vdf_8_core": 15,
    "fabricate_component_final_vdf_8_core": 15,
    "fabricate_component_reusable_vdf_12_core": 15,
    "fabricate_component_final_vdf_12_core": 15,
    "fabricate_component_reusable_vdf_32_core": 15,
    "fabricate_component_final_vdf_32_core": 15,
    "develop_derived_skill_2_evidence_vdf_8_core": 17,
    "develop_derived_skill_2_evidence_vdf_12_core": 18,
    "develop_derived_skill_2_evidence_vdf_32_core": 18,
    "develop_derived_skill_3_evidence_vdf_8_core": 1,
    "develop_derived_skill_3_evidence_vdf_12_core": 6,
    "develop_derived_skill_3_evidence_vdf_32_core": 12,
    "produce_capability_artifact_1_evidence_vdf_8_core": 16,
    "produce_capability_artifact_1_evidence_vdf_12_core": 16,
    "produce_capability_artifact_1_evidence_vdf_32_core": 17,
    "produce_capability_artifact_2_evidence_vdf_8_core": 2,
    "produce_capability_artifact_2_evidence_vdf_12_core": 2,
    "produce_capability_artifact_2_evidence_vdf_32_core": 1,
    "produce_capability_artifact_3_evidence_vdf_12_core": 6,
    "produce_capability_artifact_3_evidence_vdf_32_core": 12,
}
PHASE5_BULK_COST_DISTRIBUTION = {8: 66, 12: 78, 32: 90}

PHASE6_MOVEMENT_HELPERS = (
    "move_positive_core",
    "move_negative_core",
    "advance_ship_epoch_core",
    "update_ship_work_vdf_4_core",
    "update_ship_work_vdf_12_core",
    "update_ship_work_vdf_28_core",
)
PHASE6_MOVEMENT_CANARY_ROUTES = {
    **{
        (
            f"Move{'Positive' if positive else 'Negative'}{axis}"
            + ("" if tier["name"] == "Small" else tier["name"])
        ): (
            "move_positive_core" if positive else "move_negative_core",
            f"update_ship_work_vdf_{tier['timewarp_vdf']}_core",
        )
        for axis in "XYZ"
        for positive in (True, False)
        for tier in SHIP_TIERS
    },
    **{
        f"TimeWarp{tier['name']}": (
            "advance_ship_epoch_core",
            f"update_ship_work_vdf_{tier['timewarp_vdf']}_core",
        )
        for tier in SHIP_TIERS
    },
}


def phase4_helper_specs() -> tuple[tuple[str, str, int | None, str], ...]:
    """Return the fixed Phase 4 helper inventory for the active profile."""
    return (
        PHASE4_ECONOMY_HELPERS
        if ACTIVE_VDF_PROFILE == "economy"
        else PHASE4_CURRENT_HELPERS
    )


def phase4_helper_for(
    action_name: str,
    kind: str,
    iterations: int | None = None,
) -> str | None:
    """Return the active fixed helper for one resource/refinement wrapper."""
    if not PHASE4_ADAPTER_CANARIES_ENABLED:
        return None
    for helper_name, helper_kind, _iterations, representative in phase4_helper_specs():
        if helper_kind == kind and (representative == action_name or _iterations == iterations):
            return helper_name
    return None


def phase5_helper_for(action_name: str) -> str | None:
    """Return the fixed helper for one component, skill, or artifact wrapper."""
    if not PHASE5_ADAPTER_CANARIES_ENABLED:
        return None
    topology: tuple[str, str | int, int] | None = None
    for component in COMPONENT_RECIPES:
        for mode, name in component["actions"].items():
            if name == action_name:
                topology = ("component", mode, component["vdf_iterations"])
                break
        if topology is not None:
            break
    if topology is None:
        skill = next(
            (item for item in DERIVED_SKILLS if item["action"] == action_name),
            None,
        )
        if skill is not None:
            topology = (
                "derived", len(skill["items"]), skill["vdf_iterations"]
            )
    if topology is None:
        capability = next(
            (
                item
                for item in SKILL_CAPABILITIES
                if item["action"] == action_name
            ),
            None,
        )
        if capability is not None:
            topology = (
                "artifact",
                len(capability["fixed_inputs"]),
                capability["vdf_iterations"],
            )
    if topology is None:
        return None
    family, shape, iterations = topology
    return next(
        (
            helper_name
            for helper_name, helper_family, helper_shape, helper_iterations, _representative
            in PHASE5_ADAPTER_HELPERS
            if (helper_family, helper_shape, helper_iterations)
            == (family, shape, iterations)
        ),
        None,
    )


def phase6_movement_route_for(action_name: str) -> tuple[str, ...]:
    """Return the economy-only fixed helper route for a Phase 6 wrapper."""
    if (
        PHASE6_MOVEMENT_CANARIES_ENABLED
        and ACTIVE_VDF_PROFILE == "economy"
    ):
        return PHASE6_MOVEMENT_CANARY_ROUTES.get(action_name, ())
    return ()


def phase6_vdf_helper_for(action_name: str) -> str | None:
    """Return the literal VDF helper when a Phase 6 wrapper owns the tail."""
    route = phase6_movement_route_for(action_name)
    return route[-1] if route and route[-1].startswith("update_ship_work_") else None


def phase4_kind_for_action(action: dict[str, Any]) -> str | None:
    """Classify the four fixed Phase 4 wrapper shapes without runtime lookup."""
    family = action["family"]
    if family == "extract_resource":
        return "base"
    if family == "refine_resource":
        return "refine"
    if family != "extract_civilization_tech_resource":
        return None
    resource = next(
        (
            item
            for item in CIVILIZATION_TECH_RESOURCES
            if item["action"] == action["base_extraction_action"]
        ),
        None,
    )
    if resource is None:
        raise ValueError(
            f"missing Phase 4 resource route for {action['name']}"
        )
    return "composite" if resource["composite"] else "body"


def configure_vdf_profile(profile: str) -> None:
    global ACTIVE_VDF_PROFILE, BASE_EXTRACTION_VDF

    ACTIVE_VDF_PROFILE = profile
    if profile == "current":
        current_build = {"Small": 4, "Medium": 12, "Large": 28}
        for tier in SHIP_TIERS:
            tier["build_vdf"] = current_build[tier["name"]]
            tier["move_vdf"] = None
        BASE_EXTRACTION_VDF = dict(CURRENT_BASE_EXTRACTION_VDF)
        for resource in CIVILIZATION_TECH_RESOURCES:
            resource["vdf_tier"] = None
            resource["vdf_iterations"] = None
        for route in REFINEMENT_ROUTES:
            route["vdf_tier"] = None
            route["vdf_iterations"] = None
        return

    if profile != "economy":
        raise ValueError(f"unsupported VDF profile: {profile}")

    for tier in SHIP_TIERS:
        tier["build_vdf"] = ECONOMY_SHIP_BUILD_VDF[tier["name"]]
        tier["move_vdf"] = tier["timewarp_vdf"]
    BASE_EXTRACTION_VDF = {
        resource_name: VDF_DIFFICULTY_TIERS[tier_name]["iterations"]
        for resource_name, tier_name in ECONOMY_BASE_EXTRACTION_VDF.items()
    }
    for resource in CIVILIZATION_TECH_RESOURCES:
        tier_name = ECONOMY_RESOURCE_VDF_TIER[resource["name"]]
        resource["vdf_tier"] = tier_name
        resource["vdf_iterations"] = VDF_DIFFICULTY_TIERS[tier_name][
            "iterations"
        ]
    for route in REFINEMENT_ROUTES:
        tier_name = ECONOMY_REFINEMENT_VDF_TIER[route["parent_name"]]
        route["vdf_tier"] = tier_name
        route["vdf_iterations"] = VDF_DIFFICULTY_TIERS[tier_name][
            "iterations"
        ]


assert set(ECONOMY_RESOURCE_VDF_TIER) == {
    resource["name"] for resource in CIVILIZATION_TECH_RESOURCES
}
assert set(ECONOMY_REFINEMENT_VDF_TIER) == {
    parent_name for parent_name, _children in _REFINEMENT_GROUP_ROWS
}


def movement_variants() -> list[tuple[str, str, bool, dict[str, Any] | None]]:
    variants: list[tuple[str, str, bool, dict[str, Any] | None]] = []
    for axis in "XYZ":
        for positive in (True, False):
            direction = "Positive" if positive else "Negative"
            base_name = f"Move{direction}{axis}"
            if ACTIVE_VDF_PROFILE == "economy":
                for tier in SHIP_TIERS:
                    action_name = (
                        base_name
                        if tier["name"] == "Small"
                        else f"{base_name}{tier['name']}"
                    )
                    variants.append((action_name, axis, positive, tier))
            else:
                variants.append((base_name, axis, positive, None))
    return variants


def extraction_tier_variants(
    base_action_name: str,
    minimum_ship_tier: int,
) -> list[tuple[str, dict[str, Any]]]:
    variants: list[tuple[str, dict[str, Any]]] = []
    for tier in SHIP_TIERS[minimum_ship_tier:]:
        action_name = (
            base_action_name
            if tier["tier"] == minimum_ship_tier
            else f"{base_action_name}{tier['name']}"
        )
        variants.append((action_name, tier))
    return variants


def stable_json(value: Any) -> str:
    return json.dumps(value, indent=2, sort_keys=True, ensure_ascii=False) + "\n"


def read_catalog_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise FileNotFoundError(f"required Microverse catalog is missing: {path}") from error
    except json.JSONDecodeError as error:
        raise ValueError(f"invalid JSON catalog {path}: {error}") from error
    if not isinstance(value, dict):
        raise ValueError(f"catalog root must be an object: {path}")
    if value.get("schema_version") != 2:
        raise ValueError(f"catalog schema_version must be 2: {path}")
    return value


def _catalog_resource_code(
    record: dict[str, Any],
    *,
    code_field: str = "resource_code",
    name_field: str = "name",
) -> tuple[int, str]:
    code = record.get(code_field)
    name = record.get(name_field)
    if not isinstance(code, int) or code <= 0:
        raise ValueError(f"invalid {code_field}: {record!r}")
    if not isinstance(name, str) or not name.strip():
        raise ValueError(f"invalid {name_field}: {record!r}")
    return code, name


def refresh_sector_schema() -> None:
    global SECTOR_LISTED_FIELDS

    fields = [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("body_bank_version", "Int"),
        ("x", "Int"),
        ("y", "Int"),
        ("z", "Int"),
        ("epoch", "Int"),
        ("sector_type", "Int"),
        ("survey_profile", "Int"),
        *[
            (category["remaining_field"], "Int")
            for category in CELESTIAL_CATEGORIES
        ],
        *[
            (category["serial_field"], "Int")
            for category in CELESTIAL_CATEGORIES
        ],
        ("revision", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ]
    SCHEMAS[SECTOR] = fields
    SECTOR_LISTED_FIELDS = tuple(field for field, _field_type in fields)


def refresh_refinement_derivations() -> None:
    """Rebuild all derived child allocations after catalog split changes."""
    global _children_by_parent, _body_by_code

    _children_by_parent = {
        parent_name: children
        for parent_name, children in _REFINEMENT_GROUP_ROWS
    }
    _body_by_code = {item["code"]: item for item in BODY_BANK}
    route_by_parent_slot = {
        (route["parent_name"], route["child_slot"]): route
        for route in REFINEMENT_ROUTES
    }
    for parent_name, children in _REFINEMENT_GROUP_ROWS:
        for slot, (
            child_name,
            allocation_per_1000_units,
            skill_code,
        ) in enumerate(children, start=1):
            route = route_by_parent_slot[(parent_name, slot)]
            if route["child_name"] != child_name:
                raise ValueError(
                    f"refinement child identity changed for {parent_name} slot {slot}"
                )
            route["allocation_per_1000_units"] = allocation_per_1000_units
            route["skill_code"] = skill_code
    for resource in CIVILIZATION_TECH_RESOURCES:
        source_body = _body_by_code[resource["candidate_code"]]
        pool_name = resource["remaining_field"].removesuffix("_remaining")
        resource["maximum_units"] = source_body[pool_name]
        resource["composite"] = resource["name"] in _children_by_parent
        resource["output_class"] = (
            COMPOSITE_RESOURCE if resource["composite"] else RESOURCE
        )
        resource["child_allocations"] = [
            {
                "slot": slot,
                "name": child_name,
                "resource_code": REFINED_RESOURCE_CODES[child_name],
                "maximum_units": (
                    resource["maximum_units"]
                    * allocation_per_1000_units
                    // 1_000
                ),
                "allocation_per_1000_units": allocation_per_1000_units,
                "skill_code": skill_code,
            }
            for slot, (
                child_name,
                allocation_per_1000_units,
                skill_code,
            ) in enumerate(
                _children_by_parent.get(resource["name"], []), start=1
            )
        ]
        if resource["composite"] and (
            sum(
                child["maximum_units"]
                for child in resource["child_allocations"]
            )
            != resource["maximum_units"]
        ):
            raise ValueError(
                f"maximum child allocation does not conserve {resource['name']}"
            )


def configure_resource_catalog(catalog: dict[str, Any]) -> None:
    """Install v2 body rows and exact legacy split overrides."""
    global _REFINEMENT_GROUP_ROWS

    if catalog.get("catalog_version") != "microverse-resource-tree-v2":
        raise ValueError("unexpected resource catalog_version")
    declared_versions = catalog.get("versions", {})
    if declared_versions.get("resource_catalog_version") != 2:
        raise ValueError("resource catalog version must be 2")
    if declared_versions.get("body_bank_version") != VERSIONS["body_bank_version"]:
        raise ValueError("resource catalog body_bank_version mismatch")

    profiles = {
        profile["split_profile_id"]: profile
        for profile in catalog.get("split_profiles", [])
    }
    split_rows = catalog.get("legacy_parent_splits")
    if not isinstance(split_rows, list) or len(split_rows) != len(
        _REFINEMENT_GROUP_ROWS
    ):
        raise ValueError("resource catalog must assign every legacy parent split")
    existing_parent_rows = dict(_REFINEMENT_GROUP_ROWS)
    source_parent_codes = {
        resource["name"]: resource["code"]
        for resource in CIVILIZATION_TECH_RESOURCES
        if resource["composite"]
    }
    replacement_rows: list[tuple[str, list[tuple[str, int, int]]]] = []
    seen_parents: set[str] = set()
    for split_row in split_rows:
        parent_name = split_row.get("parent_name")
        if parent_name not in existing_parent_rows or parent_name in seen_parents:
            raise ValueError(f"unknown or duplicate legacy split parent: {parent_name}")
        if split_row.get("parent_resource_id") != source_parent_codes[parent_name]:
            raise ValueError(f"legacy split resource code mismatch: {parent_name}")
        profile = profiles.get(split_row.get("split_profile_id"))
        allocations = split_row.get("child_allocations_per_1000")
        if profile is None or allocations != profile.get(
            "child_allocations_per_1000"
        ):
            raise ValueError(f"legacy split profile mismatch: {parent_name}")
        if (
            len(allocations) != 3
            or any(not isinstance(value, int) or value <= 0 for value in allocations)
            or sum(allocations) != 1_000
        ):
            raise ValueError(f"invalid legacy split allocation: {parent_name}")
        minimum_tier = min(
            resource["minimum_ship_tier"]
            for resource in CIVILIZATION_TECH_RESOURCES
            if resource["name"] == parent_name
        )
        if split_row.get("minimum_capacity_tier") != minimum_tier:
            raise ValueError(f"legacy split minimum tier mismatch: {parent_name}")
        if minimum_tier < profile.get("minimum_capacity_tier", 0):
            raise ValueError(
                f"legacy split is not representable at minimum tier: {parent_name}"
            )
        children = existing_parent_rows[parent_name]
        replacement_rows.append(
            (
                parent_name,
                [
                    (child_name, allocations[index], skill_code)
                    for index, (child_name, _old_allocation, skill_code)
                    in enumerate(children)
                ],
            )
        )
        seen_parents.add(parent_name)
    if seen_parents != set(existing_parent_rows):
        raise ValueError("legacy split catalog coverage is incomplete")
    _REFINEMENT_GROUP_ROWS = replacement_rows

    existing_categories = {
        category["code"]: category for category in CELESTIAL_CATEGORIES
    }
    profile_by_name = {profile["name"]: profile for profile in SURVEY_PROFILES}
    for category_row in catalog.get("celestial_categories", []):
        code = category_row["category_code"]
        runtime_name = category_row.get("runtime_name", category_row["name"])
        if code in existing_categories:
            category = existing_categories[code]
            if any(
                (
                    category["name"] != runtime_name,
                    category["body_type"] != category_row["body_type"],
                    category["remaining_field"]
                    != category_row["remaining_field"],
                    category["serial_field"] != category_row["serial_field"],
                )
            ):
                raise ValueError(f"existing celestial category changed: {code}")
        else:
            category = {
                "code": code,
                "name": runtime_name,
                "slug": _slug(runtime_name),
                "body_type": category_row["body_type"],
                "remaining_field": category_row["remaining_field"],
                "serial_field": category_row["serial_field"],
            }
            CELESTIAL_CATEGORIES.append(category)
            existing_categories[code] = category
        for profile_name, count in category_row["survey_profile_counts"].items():
            if profile_name not in profile_by_name or not isinstance(count, int) or count < 0:
                raise ValueError(f"invalid survey count for category {code}")
            if count == 0:
                profile_by_name[profile_name]["counts"].pop(
                    category["remaining_field"], None
                )
            else:
                profile_by_name[profile_name]["counts"][
                    category["remaining_field"]
                ] = count
    CELESTIAL_CATEGORIES.sort(key=lambda item: item["code"])

    existing_body_codes = {body["code"] for body in BODY_BANK}
    new_bodies = catalog.get("bodies")
    if not isinstance(new_bodies, list):
        raise ValueError("resource catalog bodies must be a list")
    if catalog.get("rules", {}).get("scan_threshold_note") != (
        "The exponent weights a deterministic, non-overlapping stable-identifier "
        "band within the Signal category. A named Scan succeeds only for its "
        "assigned band; Survey profile, civilization type, root skill, and "
        "advanced resource yields use the same immutable hierarchy."
    ):
        raise ValueError("resource catalog Scan threshold semantics changed")
    for body_row in new_bodies:
        code = body_row["candidate_code"]
        if body_row.get("body_id") != code or code in existing_body_codes:
            raise ValueError(f"invalid or duplicate v2 body code: {code}")
        denominator = body_row["nominal_denominator"]
        exponent = body_row["occurrence_exponent"]
        if (
            body_row.get("scan_threshold_subject")
            != "MicroverseCelestialSignal stable identifier"
            or body_row.get("scan_acceptance_comparison")
            != "fixed lower <= stable_identifier <= fixed upper"
            or body_row.get("scan_selector")
            != DETERMINISTIC_SELECTOR_MODE
        ):
            raise ValueError(
                f"body Scan must use its deterministic stable-ID band: {code}"
            )
        if denominator != 2**exponent:
            raise ValueError(f"body denominator/exponent mismatch: {code}")
        category = existing_categories.get(body_row["category_code"])
        if category is None or category["body_type"] != body_row["body_type"]:
            raise ValueError(f"body/category mismatch: {code}")
        if body_row["survey_pool"]["remaining_field"] != category[
            "remaining_field"
        ]:
            raise ValueError(f"body survey pool mismatch: {code}")
        reserves = body_row["reserves"]
        BODY_BANK.append(
            {
                "code": code,
                "name": body_row["name"],
                "slug": body_row["slug"],
                "body_type": body_row["body_type"],
                "body_profile": body_row["body_profile"],
                "nominal_denominator": denominator,
                "target_top_limb": body_row["target_top_limb"],
                "life_stat": body_row["life_stat"],
                "matter": reserves["matter"],
                "crystal": reserves["crystal"],
                "gas": reserves["gas"],
                "energy": reserves["energy"],
                "satellites": body_row["satellites"],
            }
        )
        BODY_TREE_CATEGORIES.append(
            {
                "name": body_row["name"],
                "candidate_code": code,
                "body_type": body_row["body_type"],
                "body_profile": body_row["body_profile"],
                "life_stat": body_row["life_stat"],
            }
        )
        existing_body_codes.add(code)
    BODY_BANK.sort(key=lambda item: item["code"])
    BODY_TREE_CATEGORIES.sort(key=lambda item: item["candidate_code"])
    if [body["code"] for body in BODY_BANK] != list(range(len(BODY_BANK))):
        raise ValueError("body candidate codes must remain contiguous from zero")

    source_rows = catalog.get("source_resources")
    refined_rows = catalog.get("refined_resources")
    if not isinstance(source_rows, list) or not isinstance(refined_rows, list):
        raise ValueError("resource catalog source/refined rows must be lists")
    counts = catalog.get("counts", {})
    if len(source_rows) != counts.get("new_source_resource_count"):
        raise ValueError("new source resource count metadata is inconsistent")
    if len(refined_rows) != counts.get("new_refined_resource_count"):
        raise ValueError("new refined resource count metadata is inconsistent")
    code_policy = catalog.get("code_policy", {})
    source_policy = code_policy.get("v2_source_resources", {})
    refined_policy = code_policy.get("v2_refined_resources", {})
    expected_source_codes = list(
        range(source_policy.get("first", 0), source_policy.get("last", -1) + 1)
    )
    expected_refined_codes = list(
        range(refined_policy.get("first", 0), refined_policy.get("last", -1) + 1)
    )
    if [row.get("resource_id") for row in source_rows] != expected_source_codes:
        raise ValueError("v2 source resource codes must fill their declared range")
    if [row.get("resource_id") for row in refined_rows] != expected_refined_codes:
        raise ValueError("v2 refined resource codes must fill their declared range")
    occupied_codes = (
        set(BASE_RESOURCE_CODES.values())
        | set(SOURCE_RESOURCE_CODES.values())
        | set(REFINED_RESOURCE_CODES.values())
        | set(range(390, 435))
    )
    if occupied_codes.intersection(expected_source_codes + expected_refined_codes):
        raise ValueError("v2 resource code range overlaps an existing allocation")
    occupied_names = (
        set(BASE_RESOURCE_CODES)
        | set(SOURCE_RESOURCE_CODES)
        | set(REFINED_RESOURCE_CODES)
    )
    new_names = [row.get("name") for row in source_rows + refined_rows]
    if (
        any(not isinstance(name, str) or not name for name in new_names)
        or len(new_names) != len(set(new_names))
        or occupied_names.intersection(new_names)
    ):
        raise ValueError("v2 resource names must be new and unique")

    body_by_code = {body["code"]: body for body in BODY_BANK}
    pool_by_id = {pool["pool_id"]: pool for pool in catalog.get("pools", [])}
    source_by_code = {row["resource_id"]: row for row in source_rows}
    refined_by_code = {row["resource_id"]: row for row in refined_rows}
    for row in source_rows:
        SOURCE_RESOURCE_CODES[row["name"]] = row["resource_id"]
    for row in refined_rows:
        REFINED_RESOURCE_CODES[row["name"]] = row["resource_id"]

    for source_row in source_rows:
        body = body_by_code.get(source_row["body_id"])
        pool = pool_by_id.get(source_row["pool_id"])
        if body is None or pool is None:
            raise ValueError(f"unknown body or pool for {source_row['name']}")
        if source_row["remaining_field"] != pool["remaining_field"]:
            raise ValueError(f"pool field mismatch for {source_row['name']}")
        minimum_tier = source_row["min_capacity_tier"]
        if minimum_tier not in (0, 1, 2):
            raise ValueError(f"invalid minimum capacity tier: {source_row['name']}")
        vdf_tier = source_row.get("vdf_tier")
        vdf_iterations = source_row.get("vdf_iterations")
        if (
            vdf_tier not in VDF_DIFFICULTY_TIERS
            or VDF_DIFFICULTY_TIERS[vdf_tier]["iterations"]
            != vdf_iterations
        ):
            raise ValueError(f"missing or invalid extraction VDF: {source_row['name']}")
        role = source_row["role"]
        child_codes = source_row["child_resource_ids"]
        if role == "terminal":
            if child_codes:
                raise ValueError(f"terminal resource has children: {source_row['name']}")
        elif role == "composite":
            if len(child_codes) != 3:
                raise ValueError(f"composite must have three children: {source_row['name']}")
            refinement_vdf_tier = source_row.get("refinement_vdf_tier")
            refinement_vdf_iterations = source_row.get(
                "refinement_vdf_iterations"
            )
            if (
                refinement_vdf_tier not in VDF_DIFFICULTY_TIERS
                or VDF_DIFFICULTY_TIERS[refinement_vdf_tier]["iterations"]
                != refinement_vdf_iterations
            ):
                raise ValueError(
                    f"missing or invalid refinement VDF: {source_row['name']}"
                )
            child_rows = [refined_by_code.get(code) for code in child_codes]
            if any(child is None for child in child_rows):
                raise ValueError(f"unknown composite child: {source_row['name']}")
            child_rows = sorted(child_rows, key=lambda child: child["slot"])
            if [child["slot"] for child in child_rows] != [1, 2, 3]:
                raise ValueError(f"invalid child slots: {source_row['name']}")
            allocations = [
                child["allocation_per_1000"] for child in child_rows
            ]
            profile = profiles.get(source_row.get("split_profile_id"))
            if (
                profile is None
                or allocations != profile["child_allocations_per_1000"]
                or sum(allocations) != 1_000
            ):
                raise ValueError(f"new parent split mismatch: {source_row['name']}")
            if minimum_tier < profile.get("minimum_capacity_tier", 0):
                raise ValueError(
                    f"new parent split is not representable at minimum tier: "
                    f"{source_row['name']}"
                )
            children = []
            for child in child_rows:
                if (
                    child["body_id"] != source_row["body_id"]
                    or child["parent_resource_id"] != source_row["resource_id"]
                ):
                    raise ValueError(f"child provenance mismatch: {child['name']}")
                children.append(
                    (
                        child["name"],
                        child["allocation_per_1000"],
                        child["refinement_skill_id"],
                    )
                )
                REFINEMENT_ROUTES.append(
                    {
                        "parent_name": source_row["name"],
                        "parent_slug": _slug(source_row["name"]),
                        "child_name": child["name"],
                        "child_slug": _slug(child["name"]),
                        "child_slot": child["slot"],
                        "allocation_per_1000_units": child[
                            "allocation_per_1000"
                        ],
                        "skill_code": child["refinement_skill_id"],
                        "vdf_tier": refinement_vdf_tier,
                        "vdf_iterations": refinement_vdf_iterations,
                        "resource_code": child["resource_id"],
                        "action": (
                            f"Refine{_slug(source_row['name'])}To"
                            f"{_slug(child['name'])}"
                        ),
                    }
                )
            _REFINEMENT_GROUP_ROWS.append((source_row["name"], children))
            ECONOMY_REFINEMENT_VDF_TIER[source_row["name"]] = (
                refinement_vdf_tier
            )
        else:
            raise ValueError(f"invalid source resource role: {role}")

        action_name = f"Extract{body['slug']}{_slug(source_row['name'])}"
        CIVILIZATION_TECH_RESOURCES.append(
            {
                "code": source_row["resource_id"],
                "name": source_row["name"],
                "slug": _slug(source_row["name"]),
                "action": action_name,
                "category": body["name"],
                "candidate_code": body["code"],
                "remaining_field": source_row["remaining_field"],
                "amount": 1,
                "skill_code": source_row["extraction_skill_id"],
                "vdf_tier": vdf_tier,
                "vdf_iterations": vdf_iterations,
                "minimum_ship_tier": minimum_tier,
                "route_key": source_row["route_key"],
            }
        )
        ECONOMY_RESOURCE_VDF_TIER[source_row["name"]] = vdf_tier

    referenced_children = {
        code for source_row in source_rows for code in source_row["child_resource_ids"]
    }
    if referenced_children != set(expected_refined_codes):
        raise ValueError("every v2 refined resource must have one catalog parent")

    refresh_sector_schema()
    refresh_refinement_derivations()
    installed_by_code = {
        resource["code"]: resource
        for resource in CIVILIZATION_TECH_RESOURCES
    }
    for source_row in source_rows:
        if source_row["role"] != "composite":
            continue
        resource = installed_by_code[source_row["resource_id"]]
        child_rows = sorted(
            (refined_by_code[code] for code in source_row["child_resource_ids"]),
            key=lambda child: child["slot"],
        )
        for _action_name, tier in extraction_tier_variants(
            resource["action"], resource["minimum_ship_tier"]
        ):
            actual = composite_child_amounts(
                resource["child_allocations"],
                tier["extraction_amount"],
                route_name=resource["action"],
                ship_tier_name=tier["name"],
            )
            expected = tuple(
                child["produced_amounts"][tier["name"]]
                for child in child_rows
            )
            if actual != expected:
                raise ValueError(
                    f"catalog produced amounts mismatch for {resource['name']} "
                    f"at {tier['name']} tier"
                )


def configure_component_catalog(catalog: dict[str, Any]) -> None:
    """Validate and install fixed component recipes from the v2 catalog."""
    global COMPONENT_RECIPES

    if catalog.get("catalog_name") != "microverse-component-tree-v2":
        raise ValueError("unexpected component catalog_name")
    rows = catalog.get("components")
    if not isinstance(rows, list) or not rows:
        raise ValueError("component catalog must contain a nonempty components list")
    known_codes = {
        **{code: name for name, code in BASE_RESOURCE_CODES.items()},
        **{code: name for name, code in SOURCE_RESOURCE_CODES.items()},
        **{code: name for name, code in REFINED_RESOURCE_CODES.items()},
    }
    normalized: list[dict[str, Any]] = []
    component_codes: set[int] = set()
    component_names: set[str] = set()
    action_names: set[str] = set()
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError("every component row must be an object")
        code = row.get("code")
        name = row.get("name")
        slug = row.get("slug")
        if not isinstance(code, int) or code <= 0:
            raise ValueError(f"invalid component code: {row!r}")
        if code in known_codes or code in component_codes:
            raise ValueError(f"duplicate resource_type {code} for component {name}")
        if not isinstance(name, str) or not name.strip() or name in component_names:
            raise ValueError(f"invalid or duplicate component name: {name!r}")
        if slug != _slug(name):
            raise ValueError(f"component slug must equal deterministic slug for {name}")
        tier = row.get("tier")
        skill_code = row.get("skill_code")
        output_amount = row.get("output_amount")
        vdf_iterations = row.get("vdf_iterations")
        if tier not in (1, 2, 3):
            raise ValueError(f"component tier must be 1, 2, or 3: {name}")
        if not isinstance(skill_code, int) or skill_code <= 0:
            raise ValueError(f"component skill_code must be positive: {name}")
        if not isinstance(output_amount, int) or output_amount <= 0:
            raise ValueError(f"component output_amount must be positive: {name}")
        if not isinstance(vdf_iterations, int) or vdf_iterations <= 0:
            raise ValueError(f"component vdf_iterations must be positive: {name}")

        materials = row.get("materials")
        if not isinstance(materials, list) or len(materials) != 3:
            raise ValueError(f"component must have exactly three materials: {name}")
        normalized_materials: list[dict[str, Any]] = []
        for expected_slot, material in enumerate(materials, start=1):
            if not isinstance(material, dict) or material.get("slot") != expected_slot:
                raise ValueError(f"component material slots must be 1..3: {name}")
            material_code, material_name = _catalog_resource_code(material)
            if known_codes.get(material_code) != material_name:
                raise ValueError(
                    f"unknown or mismatched material {material_name}/{material_code} in {name}"
                )
            amount = material.get("amount")
            if not isinstance(amount, int) or amount <= 0:
                raise ValueError(f"material amount must be positive in {name}")
            normalized_materials.append(
                {"slot": expected_slot, "resource_code": material_code,
                 "name": material_name, "amount": amount}
            )

        catalyst = row.get("catalyst")
        if not isinstance(catalyst, dict):
            raise ValueError(f"component catalyst must be an object: {name}")
        catalyst_code, catalyst_name = _catalog_resource_code(catalyst)
        if known_codes.get(catalyst_code) != catalyst_name:
            raise ValueError(
                f"unknown or mismatched catalyst {catalyst_name}/{catalyst_code} in {name}"
            )
        if catalyst.get("units_per_craft") != 1:
            raise ValueError(f"component catalyst units_per_craft must be 1: {name}")
        if catalyst.get("modes") != ["reusable", "final"]:
            raise ValueError(
                f"component catalyst modes must be reusable then final: {name}"
            )
        actions = row.get("actions")
        if not isinstance(actions, dict):
            raise ValueError(f"component actions must be an object: {name}")
        expected_actions = {
            "reusable": f"Fabricate{slug}Reusable",
            "final": f"Fabricate{slug}Final",
        }
        if actions != expected_actions:
            raise ValueError(
                f"component action names must be fixed and deterministic for {name}"
            )
        if action_names.intersection(actions.values()):
            raise ValueError(f"duplicate component action name for {name}")

        component_codes.add(code)
        component_names.add(name)
        action_names.update(actions.values())
        normalized.append(
            {
                **row,
                "code": code,
                "name": name,
                "slug": slug,
                "tier": tier,
                "skill_code": skill_code,
                "output_amount": output_amount,
                "vdf_iterations": vdf_iterations,
                "materials": normalized_materials,
                "catalyst": {
                    "resource_code": catalyst_code,
                    "name": catalyst_name,
                    "units_per_craft": 1,
                    "modes": ["reusable", "final"],
                },
                "actions": expected_actions,
            }
        )

    if [row["code"] for row in normalized] != sorted(component_codes):
        raise ValueError("component rows must be sorted by append-only resource_type")
    code_range = catalog.get("code_range")
    if not isinstance(code_range, dict):
        raise ValueError("component catalog must declare code_range")
    expected_codes = list(
        range(code_range.get("start", 0), code_range.get("end", -1) + 1)
    )
    if [row["code"] for row in normalized] != expected_codes:
        raise ValueError("component codes must exactly fill the declared code_range")
    if code_range.get("count") != len(normalized):
        raise ValueError("component code_range count is inconsistent")
    counts = catalog.get("counts", {})
    if counts.get("components") != len(normalized):
        raise ValueError("component count metadata is inconsistent")
    if counts.get("component_actions") != 2 * len(normalized):
        raise ValueError("component action count metadata is inconsistent")
    COMPONENT_RECIPES = normalized


def validate_component_material_reachability() -> None:
    producible: set[tuple[int, int]] = set()
    for resource in CIVILIZATION_TECH_RESOURCES:
        if not resource["composite"]:
            continue
        for _action_name, tier in extraction_tier_variants(
            resource["action"], resource["minimum_ship_tier"]
        ):
            amounts = composite_child_amounts(
                resource["child_allocations"],
                tier["extraction_amount"],
                route_name=resource["action"],
                ship_tier_name=tier["name"],
            )
            for child, amount in zip(
                sorted(
                    resource["child_allocations"],
                    key=lambda item: item["slot"],
                ),
                amounts,
                strict=True,
            ):
                producible.add((child["resource_code"], amount))
    missing = [
        {
            "component": component["name"],
            "material": material["name"],
            "resource_code": material["resource_code"],
            "amount": material["amount"],
        }
        for component in COMPONENT_RECIPES
        for material in component["materials"]
        if (material["resource_code"], material["amount"])
        not in producible
    ]
    if missing:
        raise ValueError(
            "component material stacks are not producible by fixed v2 routes: "
            + json.dumps(missing, ensure_ascii=False, sort_keys=True)
        )


def configure_skill_catalog(catalog: dict[str, Any]) -> None:
    """Validate and install the fixed v2 derived-skill/action catalog."""
    global DERIVED_SKILLS, SKILL_CAPABILITIES

    if catalog.get("catalog_id") != "microverse-skill-tree-v2":
        raise ValueError("unexpected skill catalog_id")
    roots = catalog.get("roots")
    capabilities = catalog.get("capability_artifacts")
    if not isinstance(roots, list) or len(roots) != len(TECHNOLOGY_SKILLS):
        raise ValueError("skill catalog must contain the 18 existing roots")
    if not isinstance(capabilities, list) or len(capabilities) != 72:
        raise ValueError("skill catalog must contain 72 capability artifacts")

    root_by_code = {skill["code"]: skill for skill in TECHNOLOGY_SKILLS}
    if len(root_by_code) != len(TECHNOLOGY_SKILLS):
        raise ValueError("existing root skill codes are not unique")
    derived_rows: list[dict[str, Any]] = []
    for root in roots:
        if not isinstance(root, dict):
            raise ValueError("every root skill row must be an object")
        code = root.get("code")
        existing = root_by_code.get(code)
        if existing is None:
            raise ValueError(f"unknown root skill code {code!r}")
        expected_root = {
            "tier": "root",
            "parent_code": None,
            "civilization_type": existing["civilization_type"],
            "develop_action": existing["action"],
            "reusable": existing["reusable"],
        }
        for field, expected in expected_root.items():
            if root.get(field) != expected:
                raise ValueError(
                    f"root skill {code} changed {field}: "
                    f"{root.get(field)!r} != {expected!r}"
                )
        specializations = root.get("specializations")
        mastery = root.get("mastery")
        if not isinstance(specializations, list) or len(specializations) != 3:
            raise ValueError(f"root skill {code} must have three specializations")
        if not isinstance(mastery, dict):
            raise ValueError(f"root skill {code} must have one mastery")
        for node in [*specializations, mastery]:
            if not isinstance(node, dict):
                raise ValueError(f"derived skill under root {code} must be an object")
            if node.get("parent_code") != code:
                raise ValueError(
                    f"derived skill {node.get('code')} has the wrong parent"
                )
            if node.get("civilization_type") != existing["civilization_type"]:
                raise ValueError(
                    f"derived skill {node.get('code')} changed civilization type"
                )
            derived_rows.append(dict(node))

    derived_rows.sort(key=lambda row: row.get("code", -1))
    if [row.get("code") for row in derived_rows] != list(range(19, 91)):
        raise ValueError("derived skill codes must exactly fill 19..90")

    normalized_capabilities: list[dict[str, Any]] = []
    capability_codes: set[int] = set()
    capability_actions: set[str] = set()
    for row in capabilities:
        if not isinstance(row, dict):
            raise ValueError("every capability artifact row must be an object")
        skill_code = row.get("skill_code")
        route_key = row.get("route_key")
        action_name = row.get("action")
        action_family = row.get("action_family")
        output_class = row.get("primary_output_class")
        fallback = row.get("fallback_resource")
        inputs = row.get("fixed_inputs")
        vdf_iterations = row.get("vdf_iterations")
        if not isinstance(skill_code, int) or not 19 <= skill_code <= 90:
            raise ValueError(f"invalid capability skill_code: {row!r}")
        if not isinstance(route_key, str) or not route_key:
            raise ValueError(f"invalid capability route_key for skill {skill_code}")
        if not isinstance(action_name, str) or not action_name:
            raise ValueError(f"invalid capability action for skill {skill_code}")
        if action_name in capability_actions:
            raise ValueError(f"duplicate capability action {action_name}")
        if not isinstance(action_family, str) or not action_family:
            raise ValueError(f"invalid capability family for {action_name}")
        if not isinstance(output_class, str) or not output_class:
            raise ValueError(f"invalid primary output class for {action_name}")
        if not isinstance(fallback, dict):
            raise ValueError(f"missing fallback resource for {action_name}")
        output_code, output_name = _catalog_resource_code(
            fallback,
            code_field="code",
            name_field="name",
        )
        output_amount = fallback.get("amount")
        if not isinstance(output_amount, int) or output_amount <= 0:
            raise ValueError(f"invalid fallback amount for {action_name}")
        if output_code in capability_codes:
            raise ValueError(f"duplicate capability resource_type {output_code}")
        if not isinstance(inputs, list) or not 1 <= len(inputs) <= 3:
            raise ValueError(f"capability {action_name} must have 1..3 fixed inputs")
        normalized_inputs: list[dict[str, Any]] = []
        for fixed_input in inputs:
            if not isinstance(fixed_input, dict):
                raise ValueError(f"invalid fixed input for {action_name}")
            resource_code = fixed_input.get("resource_code")
            amount = fixed_input.get("amount")
            if fixed_input.get("class") != RESOURCE:
                raise ValueError(
                    f"capability fallback inputs must use {RESOURCE}: {action_name}"
                )
            if not isinstance(resource_code, int) or resource_code <= 0:
                raise ValueError(f"invalid fixed input code for {action_name}")
            if not isinstance(amount, int) or amount <= 0:
                raise ValueError(f"invalid fixed input amount for {action_name}")
            normalized_inputs.append(
                {"class": RESOURCE, "resource_code": resource_code, "amount": amount}
            )
        if not isinstance(vdf_iterations, int) or vdf_iterations <= 0:
            raise ValueError(f"invalid capability VDF for {action_name}")
        capability_codes.add(output_code)
        capability_actions.add(action_name)
        normalized_capabilities.append(
            {
                **row,
                "skill_code": skill_code,
                "route_key": route_key,
                "action_family": action_family,
                "action": action_name,
                "primary_output_class": output_class,
                "output_resource_code": output_code,
                "output_resource_name": output_name,
                "output_amount": output_amount,
                "fixed_inputs": normalized_inputs,
                "vdf_iterations": vdf_iterations,
            }
        )
    normalized_capabilities.sort(key=lambda row: row["output_resource_code"])
    if [row["output_resource_code"] for row in normalized_capabilities] != list(
        range(629, 701)
    ):
        raise ValueError("capability artifact codes must exactly fill 629..700")
    if [row["skill_code"] for row in normalized_capabilities] != list(range(19, 91)):
        raise ValueError("every derived skill must have exactly one capability artifact")

    known_resource_names = {
        **{code: name for name, code in BASE_RESOURCE_CODES.items()},
        **{code: name for name, code in SOURCE_RESOURCE_CODES.items()},
        **{code: name for name, code in REFINED_RESOURCE_CODES.items()},
        **{component["code"]: component["name"] for component in COMPONENT_RECIPES},
        **{
            capability["output_resource_code"]: capability["output_resource_name"]
            for capability in normalized_capabilities
        },
    }
    expected_known_count = (
        len(BASE_RESOURCE_CODES)
        + len(SOURCE_RESOURCE_CODES)
        + len(REFINED_RESOURCE_CODES)
        + len(COMPONENT_RECIPES)
        + len(normalized_capabilities)
    )
    if len(known_resource_names) != expected_known_count:
        raise ValueError("skill catalog resource codes collide with installed catalogs")

    vdf_policy = catalog.get("derived_skill_development_vdf")
    if not isinstance(vdf_policy, dict):
        raise ValueError("skill catalog is missing derived skill VDF policy")
    normalized_skills: list[dict[str, Any]] = []
    develop_actions: set[str] = set()
    capability_by_skill = {
        capability["skill_code"]: capability
        for capability in normalized_capabilities
    }
    for node in derived_rows:
        code = node["code"]
        tier = node.get("tier")
        parent_code = node.get("parent_code")
        civilization_type = node.get("civilization_type")
        action_name = node.get("develop_action")
        recipe = node.get("development_recipe")
        gates = node.get("gated_capabilities")
        if tier not in ("specialization", "mastery"):
            raise ValueError(f"invalid derived skill tier for {code}")
        expected_range = range(19, 73) if tier == "specialization" else range(73, 91)
        if code not in expected_range:
            raise ValueError(f"derived skill {code} is outside its tier range")
        if not isinstance(parent_code, int) or parent_code not in root_by_code:
            raise ValueError(f"derived skill {code} has invalid parent")
        if civilization_type != root_by_code[parent_code]["civilization_type"]:
            raise ValueError(f"derived skill {code} has invalid civilization type")
        if node.get("reusable") != 1:
            raise ValueError(f"derived skill {code} must be reusable")
        if not isinstance(action_name, str) or not action_name:
            raise ValueError(f"derived skill {code} has invalid develop action")
        if action_name in develop_actions:
            raise ValueError(f"duplicate derived develop action {action_name}")
        if not isinstance(recipe, dict):
            raise ValueError(f"derived skill {code} is missing a recipe")
        expected_parent_input = {
            "skill_code": parent_code,
            "mode": "prepared_ship_active_skill",
            "consumed": False,
        }
        if recipe.get("action") != action_name:
            raise ValueError(f"derived skill {code} recipe action mismatch")
        if recipe.get("output_skill_code") != code:
            raise ValueError(f"derived skill {code} recipe output mismatch")
        if recipe.get("parent_skill_input") != expected_parent_input:
            raise ValueError(f"derived skill {code} parent skill input mismatch")
        if recipe.get("prerequisite_skill_inputs") != []:
            raise ValueError(f"derived skill {code} cannot have dynamic skill inputs")
        items = recipe.get("items")
        if not isinstance(items, list) or not 2 <= len(items) <= 3:
            raise ValueError(
                f"derived skill {code} must have two or three evidence items"
            )
        if tier == "mastery" and len(items) != 3:
            raise ValueError(f"mastery skill {code} must have three branch artifacts")
        normalized_items: list[dict[str, Any]] = []
        for slot, item in enumerate(items, start=1):
            if not isinstance(item, dict) or item.get("kind") not in (
                "resource",
                "component",
            ):
                raise ValueError(f"invalid recipe item for derived skill {code}")
            kind = item["kind"]
            code_field = "resource_code" if kind == "resource" else "component_code"
            name_field = "resource_name" if kind == "resource" else "component_name"
            resource_code = item.get(code_field)
            resource_name = item.get(name_field)
            amount = item.get("amount")
            amount_unit = item.get("amount_unit")
            if known_resource_names.get(resource_code) != resource_name:
                raise ValueError(
                    f"unknown or mismatched evidence {resource_name}/{resource_code} "
                    f"for derived skill {code}"
                )
            if not isinstance(amount, int) or amount <= 0:
                raise ValueError(f"invalid evidence amount for derived skill {code}")
            if amount_unit not in ("object", "resource_units"):
                raise ValueError(f"invalid amount_unit for derived skill {code}")
            if item.get("consumed") is not True:
                raise ValueError(f"derived skill evidence must be consumed: {code}")
            if not isinstance(item.get("catalyst"), bool):
                raise ValueError(f"derived skill catalyst marker must be Boolean: {code}")
            normalized_items.append(
                {
                    "slot": slot,
                    "kind": kind,
                    "resource_code": resource_code,
                    "name": resource_name,
                    "amount": amount,
                    "amount_unit": amount_unit,
                    "catalyst": item["catalyst"],
                    "consumed": True,
                }
            )
        policy_group = vdf_policy.get(f"{tier}_by_civilization_type")
        policy_row = (
            policy_group.get(str(civilization_type))
            if isinstance(policy_group, dict)
            else None
        )
        if not isinstance(policy_row, dict):
            raise ValueError(f"missing derived skill VDF policy for {code}")
        vdf_tier = policy_row.get("vdf_tier")
        vdf_iterations = policy_row.get("vdf_iterations")
        if (
            vdf_tier not in VDF_DIFFICULTY_TIERS
            or VDF_DIFFICULTY_TIERS[vdf_tier]["iterations"] != vdf_iterations
        ):
            raise ValueError(f"invalid derived skill VDF policy for {code}")
        if not isinstance(gates, list) or len(gates) != 1:
            raise ValueError(f"derived skill {code} must expose one capability")
        capability = capability_by_skill[code]
        gate = gates[0]
        expected_gate = {
            "route_key": capability["route_key"],
            "action_family": capability["action_family"],
            "required_skill_code": code,
            "output_resource_code": capability["output_resource_code"],
            "action": capability["action"],
        }
        for field, expected in expected_gate.items():
            if gate.get(field) != expected:
                raise ValueError(
                    f"derived skill {code} capability changed {field}"
                )
        develop_actions.add(action_name)
        normalized_skills.append(
            {
                **node,
                "code": code,
                "tier": tier,
                "parent_code": parent_code,
                "civilization_type": civilization_type,
                "action": action_name,
                "reusable": 1,
                "items": normalized_items,
                "vdf_tier": vdf_tier,
                "vdf_iterations": vdf_iterations,
                "capability_action": capability["action"],
                "capability_resource_code": capability["output_resource_code"],
            }
        )

    counts = catalog.get("counts")
    if not isinstance(counts, dict):
        raise ValueError("skill catalog is missing counts")
    expected_counts = {
        "roots": 18,
        "specializations": 54,
        "masteries": 18,
        "total_skills": 90,
    }
    for field, expected in expected_counts.items():
        if counts.get(field) != expected:
            raise ValueError(f"skill count {field} is inconsistent")
    DERIVED_SKILLS = normalized_skills
    SKILL_CAPABILITIES = normalized_capabilities


def validate_skill_recipe_reachability() -> None:
    """Require every fixed skill/artifact input to be an exact output stack."""
    producible: set[tuple[int, int]] = set()
    for code in BASE_RESOURCE_CODES.values():
        for tier in SHIP_TIERS:
            producible.add((code, tier["extraction_amount"]))
    for resource in CIVILIZATION_TECH_RESOURCES:
        for _action_name, tier in extraction_tier_variants(
            resource["action"], resource["minimum_ship_tier"]
        ):
            if not resource["composite"]:
                producible.add((resource["code"], tier["extraction_amount"]))
                continue
            amounts = composite_child_amounts(
                resource["child_allocations"],
                tier["extraction_amount"],
                route_name=resource["action"],
                ship_tier_name=tier["name"],
            )
            for child, amount in zip(
                sorted(resource["child_allocations"], key=lambda item: item["slot"]),
                amounts,
                strict=True,
            ):
                producible.add((child["resource_code"], amount))
    producible.update(
        (component["code"], component["output_amount"])
        for component in COMPONENT_RECIPES
    )
    producible.update(
        (capability["output_resource_code"], capability["output_amount"])
        for capability in SKILL_CAPABILITIES
    )
    missing = [
        {
            "consumer": skill["action"],
            "resource_code": item["resource_code"],
            "amount": item["amount"],
        }
        for skill in DERIVED_SKILLS
        for item in skill["items"]
        if (item["resource_code"], item["amount"]) not in producible
    ]
    missing.extend(
        {
            "consumer": capability["action"],
            "resource_code": item["resource_code"],
            "amount": item["amount"],
        }
        for capability in SKILL_CAPABILITIES
        for item in capability["fixed_inputs"]
        if (item["resource_code"], item["amount"]) not in producible
    )
    if missing:
        raise ValueError(
            "skill catalog inputs are not exact producible stacks: "
            + json.dumps(missing, ensure_ascii=False, sort_keys=True)
        )


def _catalog_rows_sha256(rows: list[dict[str, Any]]) -> str:
    encoded = json.dumps(
        rows,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _validate_warp_destination_rows(
    rows: Any,
    *,
    count: int,
    time_only: bool,
    action_prefix: str,
    slug_width: int,
    capacity_minimums: Mapping[int, int],
    extra_fields: tuple[str, ...] = (),
) -> list[dict[str, Any]]:
    if not isinstance(rows, list) or len(rows) != count:
        raise ValueError(
            f"{action_prefix} must contain exactly {count} destination rows"
        )
    normalized: list[dict[str, Any]] = []
    destination_values: set[Any] = set()
    forbidden_selection_fields = {
        "weight_bps",
        "rarity_tier",
        "lower_top_limb",
        "upper_top_limb",
        "lower_literal",
        "upper_literal",
    }
    for expected_code, row in enumerate(rows, start=1):
        if not isinstance(row, dict):
            raise ValueError(f"{action_prefix} row must be an object")
        expected_fields = {
            "code",
            "slug",
            "uses",
            "reveal_action",
            "minimum_source_pool_inclusive",
            *extra_fields,
        }
        expected_fields.update(
            ("epoch",) if time_only else ("x", "y", "z")
        )
        if set(row) != expected_fields:
            raise ValueError(
                f"{action_prefix} row fields changed: expected "
                f"{sorted(expected_fields)}, got {sorted(row)}"
            )
        slug = f"{expected_code:0{slug_width}d}"
        if row.get("code") != expected_code or row.get("slug") != slug:
            raise ValueError(f"{action_prefix} codes/slugs must be contiguous")
        if row.get("reveal_action") != f"{action_prefix}{slug}":
            raise ValueError(f"{action_prefix} reveal action mismatch at {slug}")
        if row.get("uses") != catalog_uses(expected_code, count):
            raise ValueError(f"invalid explicit use policy at {action_prefix}{slug}")
        forbidden = forbidden_selection_fields.intersection(row)
        if forbidden:
            raise ValueError(
                f"stable-ID selection fields forbidden at {action_prefix}{slug}: "
                f"{sorted(forbidden)}"
            )
        expected_minimum = capacity_minimums[row["uses"]]
        if row.get("minimum_source_pool_inclusive") != expected_minimum:
            raise ValueError(
                f"maximum-capacity source-pool minimum mismatch at "
                f"{action_prefix}{slug}"
            )
        if "source_pool_maximum_inclusive" in row:
            raise ValueError(
                f"capacity upper bound forbidden at {action_prefix}{slug}"
            )
        if time_only:
            epoch = row.get("epoch")
            if not isinstance(epoch, int) or not 101 <= epoch < EPOCH_UPPER_BOUND:
                raise ValueError(f"epoch out of bounds at {action_prefix}{slug}")
            destination = epoch
        else:
            coordinates = tuple(row.get(axis) for axis in ("x", "y", "z"))
            if not all(
                isinstance(value, int)
                and POSITION_WARP_MINIMUM <= value < COORD_UPPER_BOUND
                for value in coordinates
            ):
                raise ValueError(f"position out of bounds at {action_prefix}{slug}")
            destination = coordinates
        if destination in destination_values:
            raise ValueError(f"duplicate destination at {action_prefix}{slug}")
        destination_values.add(destination)
        normalized.append(dict(row))
    if sum(row["uses"] == 10 for row in normalized) != 1:
        raise ValueError(f"{action_prefix} must have one ten-use action")
    if sum(row["uses"] == 3 for row in normalized) != 3:
        raise ValueError(f"{action_prefix} must have three three-use actions")
    if sum(row["uses"] == 1 for row in normalized) != count - 4:
        raise ValueError(f"{action_prefix} single-use action count mismatch")
    return normalized


def configure_warp_catalog(catalog: dict[str, Any]) -> None:
    """Validate and install the fixed v2 chart/anchor/link mechanics."""
    global POSITION_CHART_DESTINATIONS, EPOCH_CHART_DESTINATIONS
    global WARP_OBJECT_ACTIONS, WARP_RECIPES

    if catalog.get("catalog_id") != "microverse-warp-tree-v2":
        raise ValueError("unexpected warp catalog_id")
    if catalog.get("catalog_version") != "2.1.0":
        raise ValueError("unexpected warp catalog_version")
    if catalog.get("versions", {}).get("schema_version") != VERSIONS["schema_version"]:
        raise ValueError("warp catalog schema version does not match generator")
    if catalog.get("versions", {}).get("mechanics_version") != VERSIONS["mechanics_version"]:
        raise ValueError("warp catalog mechanics version does not match generator")
    if catalog.get("versions", {}).get("universe_version") != VERSIONS["universe_version"]:
        raise ValueError("warp catalog universe version does not match generator")
    selection_semantics = catalog.get("selection_semantics")
    if catalog.get("selector_semantics") is not None or selection_semantics != {
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
    }:
        raise ValueError("warp catalog explicit selection semantics changed")
    for version, kind in (("v1", "position"), ("v1", "time"), ("v2", "position"), ("v2", "time")):
        if catalog.get(version, {}).get(kind, {}).get("selection_mode") != EXPLICIT_SELECTION_MODE:
            raise ValueError(f"warp catalog {version}.{kind} selection mode changed")
    if catalog.get("use_capacity_policy") != {
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
            "Use counts are fixed selectable capacities, not probability or "
            "rarity odds. A higher source snapshot may select any lower-use "
            "action."
        ),
    }:
        raise ValueError("warp maximum-capacity policy changed")

    expected_capacity_sections = {
        "v1": {
            "minimums": V1_COORDINATE_POOL_MINIMUMS,
            "pristine_example": [18_000, 9_000],
            "pristine_capacity_sequence": [10, 1],
        },
        "v2": {
            "minimums": V2_CHART_POOL_MINIMUMS,
            "pristine_example": [40_000, 31_000, 22_000, 13_000],
            "pristine_capacity_sequence": [10, 3, 1, 1],
        },
    }
    for version, expected in expected_capacity_sections.items():
        for kind in ("position", "time"):
            policy = catalog[version][kind].get("capacity_selection")
            if (
                not isinstance(policy, dict)
                or set(policy)
                != {
                    "source_field",
                    "mode",
                    "meaning",
                    "tiers",
                    "shared_depletion_tradeoff",
                    "pristine_example",
                    "pristine_capacity_sequence",
                }
                or policy.get("source_field") != "source_pool_before"
                or policy.get("mode") != "maximum_capacity_eligibility"
                or policy.get("tiers")
                != [
                    {
                        "uses": uses,
                        "minimum_source_pool_inclusive": expected[
                            "minimums"
                        ][uses],
                    }
                    for uses in (10, 3, 1)
                ]
                or policy.get("pristine_example")
                != expected["pristine_example"]
                or policy.get("pristine_capacity_sequence")
                != expected["pristine_capacity_sequence"]
                or "upper" in policy.get("meaning", "").lower()
                and "no capacity upper gate" not in policy.get("meaning", "").lower()
            ):
                raise ValueError(
                    f"warp catalog {version}.{kind} capacity policy changed"
                )

    v1_position = _validate_warp_destination_rows(
        catalog.get("v1", {}).get("position", {}).get("rows"),
        count=len(POSITION_WARP_DESTINATIONS),
        time_only=False,
        action_prefix="RevealWarpCoordinate",
        slug_width=3,
        capacity_minimums=V1_COORDINATE_POOL_MINIMUMS,
    )
    v1_time = _validate_warp_destination_rows(
        catalog.get("v1", {}).get("time", {}).get("rows"),
        count=len(TIME_WARP_DESTINATIONS),
        time_only=True,
        action_prefix="RevealTimeCoordinate",
        slug_width=2,
        capacity_minimums=V1_COORDINATE_POOL_MINIMUMS,
    )
    for catalog_row, generated_row in zip(
        v1_position, POSITION_WARP_DESTINATIONS, strict=True
    ):
        for field, expected in generated_row.items():
            if catalog_row.get(field) != expected:
                raise ValueError(f"frozen v1 position row changed field {field}")
    for catalog_row, generated_row in zip(
        v1_time, TIME_WARP_DESTINATIONS, strict=True
    ):
        for field, expected in generated_row.items():
            if catalog_row.get(field) != expected:
                raise ValueError(f"frozen v1 time row changed field {field}")
    frozen_fingerprints = catalog.get("frozen_v1_fingerprints", {})
    for rows, fields_key, hash_key in (
        (v1_position, "position_fields", "position_sha256"),
        (v1_time, "time_fields", "time_sha256"),
    ):
        fields = frozen_fingerprints.get(fields_key)
        expected_hash = frozen_fingerprints.get(hash_key)
        if not isinstance(fields, list) or not isinstance(expected_hash, str):
            raise ValueError("warp catalog is missing frozen v1 fingerprints")
        projected = [{field: row[field] for field in fields} for row in rows]
        if _catalog_rows_sha256(projected) != expected_hash:
            raise ValueError(f"frozen warp fingerprint mismatch: {hash_key}")

    position_rows = _validate_warp_destination_rows(
        catalog.get("v2", {}).get("position", {}).get("rows"),
        count=256,
        time_only=False,
        action_prefix="RevealWarpChart",
        slug_width=3,
        capacity_minimums=V2_CHART_POOL_MINIMUMS,
        extra_fields=("scale_tier",),
    )
    epoch_rows = _validate_warp_destination_rows(
        catalog.get("v2", {}).get("time", {}).get("rows"),
        count=128,
        time_only=True,
        action_prefix="RevealEpochChart",
        slug_width=3,
        capacity_minimums=V2_CHART_POOL_MINIMUMS,
        extra_fields=("epoch_tier",),
    )
    v2_fingerprints = catalog.get("v2_fingerprints", {})
    if _catalog_rows_sha256(position_rows) != v2_fingerprints.get(
        "position_full_rows_sha256"
    ):
        raise ValueError("v2 position chart fingerprint mismatch")
    if _catalog_rows_sha256(epoch_rows) != v2_fingerprints.get(
        "time_full_rows_sha256"
    ):
        raise ValueError("v2 epoch chart fingerprint mismatch")

    object_types = catalog.get("object_types")
    if not isinstance(object_types, list) or len(object_types) != 9:
        raise ValueError("warp catalog must define exactly nine object types")
    expected_classes = list(EXPECTED_WARP_OBJECT_SCHEMAS)
    if [item.get("class_name") for item in object_types] != expected_classes:
        raise ValueError("warp object classes/order changed")
    action_specs: dict[str, dict[str, Any]] = {}
    for item in object_types:
        schema_fields = item.get("schema_fields")
        if not isinstance(schema_fields, list) or not schema_fields:
            raise ValueError(f"missing schema for {item.get('class_name')}")
        schema = [(field.get("name"), field.get("type")) for field in schema_fields]
        if not all(
            isinstance(name, str) and field_type in ("Int", "Raw")
            for name, field_type in schema
        ):
            raise ValueError(f"invalid schema for {item.get('class_name')}")
        class_name = item["class_name"]
        expected_schema = EXPECTED_WARP_OBJECT_SCHEMAS[class_name]
        if tuple(schema) != expected_schema:
            raise ValueError(
                f"exact warp schema changed for {class_name}: "
                f"expected {list(expected_schema)}, got {schema}"
            )
        if class_name in (WARP_COORDINATE, TIME_COORDINATE):
            if SCHEMAS[class_name] != schema:
                raise ValueError(f"frozen v1 schema changed for {class_name}")
        else:
            SCHEMAS[class_name] = schema
            CLASS_PRESENTATION[class_name] = {
                **CLASS_PRESENTATION[class_name],
                "title": item.get("title", CLASS_PRESENTATION[class_name]["title"]),
                "description": item.get(
                    "description", CLASS_PRESENTATION[class_name]["description"]
                ),
            }
        if class_name in (WARP_CHART, EPOCH_CHART):
            mechanics = item.get("mechanics", {})
            if (
                "selector_policy" in mechanics
                or mechanics.get("selection_policy")
                != (
                    "The reveal action name fixes one exact destination; "
                    "source_pool_before proves maximum-capacity eligibility."
                )
            ):
                raise ValueError(
                    f"retired chart selector mechanics at {class_name}"
                )
        for spec in [
            *item.get("creation_actions", []),
            *item.get("use_actions", []),
        ]:
            if not isinstance(spec, dict) or not isinstance(spec.get("name"), str):
                raise ValueError(f"invalid action metadata for {class_name}")
            name = spec["name"]
            if name in action_specs:
                raise ValueError(f"duplicate warp action metadata {name}")
            action_specs[name] = dict(spec)

    recipes = catalog.get("recipes")
    if not isinstance(recipes, dict) or set(recipes) != {
        "PositionAnchor",
        "TimeAnchor",
        "WormholeLink",
        "TemporalLink",
        "RendezvousCoordinate",
    }:
        raise ValueError("warp recipe catalog is incomplete")
    for recipe_name, recipe in recipes.items():
        if not isinstance(recipe, dict) or not isinstance(recipe.get("inputs"), list):
            raise ValueError(f"invalid warp recipe {recipe_name}")
        for expected_slot, recipe_input in enumerate(recipe["inputs"], start=1):
            if recipe_input.get("slot") != expected_slot or recipe_input.get("consumed") is not True:
                raise ValueError(f"invalid fixed slot in warp recipe {recipe_name}")
            if recipe_input.get("kind") == "component":
                code = recipe_input.get("resource_code")
                expected_name = next(
                    (
                        component["name"]
                        for component in COMPONENT_RECIPES
                        if component["code"] == code
                    ),
                    None,
                )
                if expected_name != recipe_input.get("name") or recipe_input.get("amount") != 1:
                    raise ValueError(f"invalid component in warp recipe {recipe_name}")

    POSITION_CHART_DESTINATIONS = position_rows
    EPOCH_CHART_DESTINATIONS = epoch_rows
    WARP_OBJECT_ACTIONS = action_specs
    WARP_RECIPES = {name: dict(recipe) for name, recipe in recipes.items()}
    validate_all_schema_field_types()


def configure_expansion_catalogs(catalog_dir: Path) -> None:
    """Load all authoritative v2 catalogs, then install supported mechanics."""
    global EXPANSION_CATALOGS

    paths = {
        "resource": catalog_dir / RESOURCE_CATALOG_FILENAME,
        "component": catalog_dir / COMPONENT_CATALOG_FILENAME,
        "skill": catalog_dir / SKILL_CATALOG_FILENAME,
        "warp": catalog_dir / WARP_CATALOG_FILENAME,
    }
    catalogs = {name: read_catalog_json(path) for name, path in paths.items()}
    EXPANSION_CATALOGS = catalogs
    configure_resource_catalog(catalogs["resource"])
    configure_component_catalog(catalogs["component"])
    validate_component_material_reachability()
    configure_skill_catalog(catalogs["skill"])
    validate_skill_recipe_reachability()
    configure_warp_catalog(catalogs["warp"])


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.replace("\r\n", "\n"), encoding="utf-8", newline="\n")


def write_json(path: Path, value: Any) -> None:
    write_text(path, stable_json(value))


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def candidate_bank(count: int) -> list[dict[str, Any]]:
    if count < len(BODY_BANK):
        raise ValueError(
            f"candidate count must be at least {len(BODY_BANK)}"
        )
    result = [dict(item) for item in BODY_BANK]
    for code in range(len(BODY_BANK), count):
        template = BODY_BANK[code % len(BODY_BANK)]
        item = dict(template)
        item.update(
            {
                "code": code,
                "name": f"Synthetic Candidate {code:03d}",
                "slug": f"SyntheticCandidate{code:03d}",
                "body_profile": 1000 + code,
                "nominal_denominator": 8,
                "target_top_limb": 2_305_843_009_213_693_952,
                "capacity_only": True,
            }
        )
        result.append(item)
    return result


def celestial_category(candidate: dict[str, Any]) -> dict[str, Any]:
    for category in CELESTIAL_CATEGORIES:
        if category["body_type"] == candidate["body_type"]:
            return category
    raise ValueError(
        f"candidate {candidate['code']} has unsupported body type "
        f"{candidate['body_type']}"
    )


def body_selector_bands(
    bank: list[dict[str, Any]],
) -> dict[int, dict[str, int | None]]:
    result: dict[int, dict[str, int | None]] = {}
    for category in CELESTIAL_CATEGORIES:
        rows = sorted(
            (
                candidate
                for candidate in bank
                if candidate["body_type"] == category["body_type"]
            ),
            key=lambda candidate: candidate["code"],
        )
        if not rows:
            continue
        maximum_denominator = max(
            candidate["nominal_denominator"] for candidate in rows
        )
        weights = [
            maximum_denominator // candidate["nominal_denominator"]
            for candidate in rows
        ]
        result.update(
            deterministic_selector_bands(rows, key="code", weights=weights)
        )
    return result


def intelligent_life_selector_band(
    bank: list[dict[str, Any]],
) -> dict[str, int | None]:
    """Select half of Ocean and half of Garden with one contiguous band.

    Ocean and Garden are adjacent in the Planet candidate partition. The band
    begins halfway through Ocean and ends halfway through Garden, so a single
    positive-only action can prove life for half of each candidate. Bodies
    outside the band remain at their initial ``life_stat = 0``.
    """
    bands = body_selector_bands(bank)
    ocean = bands[INTELLIGENT_LIFE_CANDIDATE_CODES[0]]
    garden = bands[INTELLIGENT_LIFE_CANDIDATE_CODES[1]]
    ocean_lower = ocean["lower_top_limb"]
    ocean_upper = ocean["upper_top_limb"]
    garden_lower = garden["lower_top_limb"]
    garden_upper = garden["upper_top_limb"]
    if not all(
        isinstance(value, int)
        for value in (
            ocean_lower,
            ocean_upper,
            garden_lower,
            garden_upper,
        )
    ):
        raise ValueError("Ocean and Garden life bands must be bounded")
    assert isinstance(ocean_lower, int)
    assert isinstance(ocean_upper, int)
    assert isinstance(garden_lower, int)
    assert isinstance(garden_upper, int)
    if ocean_upper + 1 != garden_lower:
        raise ValueError("Ocean and Garden bands must remain adjacent")
    ocean_width = ocean_upper - ocean_lower + 1
    garden_width = garden_upper - garden_lower + 1
    return {
        "lower_top_limb": ocean_lower + ocean_width // 2,
        "upper_top_limb": garden_lower + garden_width // 2 - 1,
    }


def survey_selector_bands() -> dict[int, dict[str, int | None]]:
    maximum = max(
        profile["minimum_claim_serial"] for profile in SURVEY_PROFILES
    )
    return deterministic_selector_bands(
        SURVEY_PROFILES,
        key="code",
        weights=[
            maximum // profile["minimum_claim_serial"]
            for profile in SURVEY_PROFILES
        ],
    )


def civilization_selector_bands() -> dict[int, dict[str, int | None]]:
    maximum = max(
        row["minimum_civilization_scan_serial"]
        for row in CIVILIZATION_TYPES
    )
    return deterministic_selector_bands(
        CIVILIZATION_TYPES,
        key="code",
        weights=[
            maximum // row["minimum_civilization_scan_serial"]
            for row in CIVILIZATION_TYPES
        ],
    )


def technology_skill_selector_bands() -> dict[int, dict[str, int | None]]:
    result: dict[int, dict[str, int | None]] = {}
    for civilization_type in sorted(
        {skill["civilization_type"] for skill in TECHNOLOGY_SKILLS}
    ):
        rows = [
            skill
            for skill in TECHNOLOGY_SKILLS
            if skill["civilization_type"] == civilization_type
        ]
        result.update(deterministic_selector_bands(rows, key="code"))
    return result


def resource_selector_bands() -> dict[str, dict[str, int | None]]:
    """Return one immutable-lineage band per logical advanced-resource route."""
    grouped: dict[tuple[int, int, str], list[dict[str, Any]]] = defaultdict(list)
    for resource in CIVILIZATION_TECH_RESOURCES:
        grouped[
            (
                resource["candidate_code"],
                resource["skill_code"],
                resource["remaining_field"],
            )
        ].append(resource)
    result: dict[str, dict[str, int | None]] = {}
    for rows in grouped.values():
        ordered = sorted(rows, key=lambda resource: resource["code"])
        result.update(
            deterministic_selector_bands(ordered, key="action")
        )
    return result


def action_record(
    name: str,
    family: str,
    objects: list[tuple[str, str]],
    *,
    candidate_code: int | None = None,
    skill_code: int | None = None,
    resource_code: int | None = None,
    parent_resource_code: int | None = None,
    description: str = "",
    hidden: bool = False,
) -> dict[str, Any]:
    result = {
        "name": name,
        "family": family,
        "objects": [{"mode": mode, "class": class_name} for mode, class_name in objects],
        "candidate_code": candidate_code,
        "description": description or family,
        "hidden": hidden,
    }
    if skill_code is not None:
        result["skill_code"] = skill_code
    if resource_code is not None:
        result["resource_code"] = resource_code
    if parent_resource_code is not None:
        result["parent_resource_code"] = parent_resource_code
    return result


def apply_intro_contracts(actions: list[dict[str, Any]]) -> None:
    """Attach an exhaustive, source-independent Intro contract to every action.

    An absent Intro primitive is represented explicitly by ``None``.  This is
    intentionally separate from the rendered Rhai so a missing or newly added
    circuit call cannot validate itself merely because it appears in source.
    """
    vdf_iterations_by_action: dict[str, int] = {}

    for tier in SHIP_TIERS:
        vdf_iterations_by_action[f"BuildShip{tier['name']}"] = tier[
            "build_vdf"
        ]
        vdf_iterations_by_action[f"TimeWarp{tier['name']}"] = tier[
            "timewarp_vdf"
        ]
    for action_name, _axis, _positive, tier in movement_variants():
        if tier is not None and tier["move_vdf"] is not None:
            vdf_iterations_by_action[action_name] = tier["move_vdf"]
    for resource_name in ("Matter", "Crystal", "Gas", "Energy"):
        iterations = BASE_EXTRACTION_VDF[resource_name]
        if iterations is None:
            continue
        for action_name, _tier in extraction_tier_variants(
            f"Extract{resource_name}", 0
        ):
            vdf_iterations_by_action[action_name] = iterations
    for resource in CIVILIZATION_TECH_RESOURCES:
        iterations = resource["vdf_iterations"]
        if iterations is None:
            continue
        for action_name, _tier in extraction_tier_variants(
            resource["action"], resource["minimum_ship_tier"]
        ):
            vdf_iterations_by_action[action_name] = iterations
    for route in REFINEMENT_ROUTES:
        if route["vdf_iterations"] is not None:
            vdf_iterations_by_action[route["action"]] = route[
                "vdf_iterations"
            ]
    for component in COMPONENT_RECIPES:
        for action_name in component["actions"].values():
            vdf_iterations_by_action[action_name] = component[
                "vdf_iterations"
            ]
    for tier in SHIP_TIERS:
        if tier["name"] in {"Small", "Medium"}:
            vdf_iterations_by_action[
                f"BuildAuxiliaryShip{tier['name']}"
            ] = tier["build_vdf"] * 2

    vdf_helper_owners = {
        "reveal_position_chart": "reveal_chart_p",
        "reveal_epoch_chart": "reveal_chart_t",
    }
    selection_helper_owners = {
        "reveal_warp_coordinate": "reveal_p",
        "reveal_time_coordinate": "reveal_t",
        "reveal_position_chart": "reveal_chart_p",
        "reveal_epoch_chart": "reveal_chart_t",
    }
    resource_by_action = {
        resource["action"]: resource for resource in CIVILIZATION_TECH_RESOURCES
    }
    for action in actions:
        name = action["name"]
        family = action["family"]
        resource = resource_by_action.get(name)
        iterations = vdf_iterations_by_action.get(name)
        if iterations is None and action.get("vdf_iterations") is not None:
            iterations = action["vdf_iterations"]
        vdf_owner = None
        if iterations is not None:
            phase4_kind = phase4_kind_for_action(action)
            phase4_owner = (
                phase4_helper_for(name, phase4_kind, iterations)
                if phase4_kind is not None
                else None
            )
            phase5_owner = phase5_helper_for(name)
            phase6_owner = phase6_vdf_helper_for(name)
            vdf_owner = (
                phase4_owner
                or phase5_owner
                or phase6_owner
                or vdf_helper_owners.get(family, "action")
            )
        threshold = None
        action["intro_contract"] = {
            "vdf": (
                {
                    "count": 1,
                    "owner": vdf_owner,
                    "iterations": iterations,
                    "argument_role": "complete object handle",
                }
                if iterations is not None
                else None
            ),
            "whole_object_threshold": threshold,
            "explicit_action_identity": (
                {
                    "selection_mode": EXPLICIT_SELECTION_MODE,
                    "owner": selection_helper_owners.get(family, "action"),
                    "stable_identifier_used": False,
                }
                if action.get("selection_mode")
                == EXPLICIT_SELECTION_MODE
                else None
            ),
            "deterministic_selector": (
                {
                    "selection_mode": DETERMINISTIC_SELECTOR_MODE,
                    "owner": "action",
                    "subject": action["selector_subject"],
                    "band": action["selector_band"],
                    "comparison": "inclusive fixed lower/upper LtEqU256",
                }
                if action.get("selection_mode")
                == DETERMINISTIC_SELECTOR_MODE
                else None
            ),
        }


def build_actions(bank: list[dict[str, Any]]) -> list[dict[str, Any]]:
    actions: list[dict[str, Any]] = []
    for tier in SHIP_TIERS:
        recipe = (
            []
            if tier["name"] == "Small"
            else MEDIUM_SHIP_RECIPE
            if tier["name"] == "Medium"
            else LARGE_SHIP_RECIPE
        )
        objects = [("output", SHIP)]
        if tier["name"] == "Large":
            objects.append(("input", SHIPYARD_PERMIT))
        objects.extend(("input", RESOURCE) for _ingredient in recipe)
        actions.append(
            action_record(
                f"BuildShip{tier['name']}",
                "build_ship",
                objects,
                description=(
                    "create a free VDF-gated Small Ship"
                    if tier["name"] == "Small"
                    else f"atomically construct a {tier['name']} Ship"
                ),
            )
        )
    for action_name, _axis, _positive, _tier in movement_variants():
        actions.append(action_record(action_name, "movement", [("mutate", SHIP)]))
    for tier in SHIP_TIERS:
        actions.append(action_record(f"TimeWarp{tier['name']}", "timewarp", [("mutate", SHIP)]))
    actions.append(
        action_record(
            "ClaimSector",
            "claim_sector",
            [("output", SECTOR), ("mutate", SHIP)],
            description="claim a deterministic Sector at the Ship's exact position and epoch",
        )
    )
    for profile in SURVEY_PROFILES:
        action_name = f"SurveySector_{profile['code']:02d}_{profile['slug']}"
        gate = EXPLICIT_COUNTER_GATES[action_name]
        action = action_record(
            action_name,
            "survey_sector",
            [("output", SHIP), ("input", SHIP), ("mutate", SECTOR)],
            description=(
                "survey an EMPTY Sector into its stable-ID-selected "
                f"{profile['name']} CELESTIAL allocation profile; requires "
                f"Ship claim_serial >= {profile['minimum_claim_serial']}"
            ),
        )
        action.update(
            {
                "selection_mode": gate["selection_mode"],
                "selector_subject": "sector.stable_identifier",
                "selector_band": survey_selector_bands()[profile["code"]],
                "survey_profile": gate["selected_code"],
                "minimum_claim_serial": gate["minimum_inclusive"],
            }
        )
        actions.append(action)
    for candidate in bank:
        action = action_record(
                f"DetectCelestialSignal_{candidate['code']:02d}_{candidate['slug']}",
                "detect_signal",
                [
                    ("output", SHIP),
                    ("output", SIGNAL),
                    ("input", SHIP),
                    ("mutate", SECTOR),
                ],
                candidate_code=candidate["code"],
            )
        action.update(
            {
                "signal_category_code": celestial_category(candidate)["code"],
                "output_candidate_code": UNRESOLVED_CANDIDATE_CODE,
                "selection_mode": "category_slot_only",
            }
        )
        actions.append(action)
    for candidate in bank:
        action = action_record(
                f"ScanCelestialBody_{candidate['code']:02d}_{candidate['slug']}",
                "scan_body",
                [("output", BODY), ("input", SIGNAL), ("mutate", SHIP)],
                candidate_code=candidate["code"],
            )
        action.update(
            {
                "selection_mode": DETERMINISTIC_SELECTOR_MODE,
                "selector_subject": "signal.stable_identifier",
                "selector_band": body_selector_bands(bank)[candidate["code"]],
                "required_signal_candidate_code": UNRESOLVED_CANDIDATE_CODE,
            }
        )
        actions.append(action)
    actions.append(
        action_record(
            "ExtractAnomalyWarpCoordinate",
            "extract_warp_coordinate",
            [
                ("output", SHIP),
                ("output", WARP_COORDINATE),
                ("input", SHIP),
                ("mutate", BODY),
            ],
            candidate_code=WARP_ANOMALY_CANDIDATE,
            skill_code=WARP_SKILL_TYPE,
            description=(
                "extract one sealed Warp Coordinate from an Anomaly with "
                "Spacetime Engineering"
            ),
        )
    )
    actions.append(
        action_record(
            "ExtractAnomalyTimeCoordinate",
            "extract_time_coordinate",
            [
                ("output", SHIP),
                ("output", TIME_COORDINATE),
                ("input", SHIP),
                ("mutate", BODY),
            ],
            candidate_code=WARP_ANOMALY_CANDIDATE,
            skill_code=WARP_SKILL_TYPE,
            description=(
                "extract one sealed Time Coordinate from an Anomaly with "
                "Spacetime Engineering"
            ),
        )
    )
    for destination in POSITION_WARP_DESTINATIONS:
        action = action_record(
            f"RevealWarpCoordinate{destination['slug']}",
            "reveal_warp_coordinate",
            [("mutate", WARP_COORDINATE)],
            description=(
                "reveal action-selected Warp Coordinate destination "
                f"{destination['code']} with {destination['uses']} use(s)"
            ),
        )
        action.update(
            {
                "selection_mode": EXPLICIT_SELECTION_MODE,
                "warp_catalog": "v1.position",
                "destination_code": destination["code"],
                "uses": destination["uses"],
                "minimum_source_pool_inclusive": destination[
                    "minimum_source_pool_inclusive"
                ],
            }
        )
        actions.append(action)
    for destination in TIME_WARP_DESTINATIONS:
        action = action_record(
            f"RevealTimeCoordinate{destination['slug']}",
            "reveal_time_coordinate",
            [("mutate", TIME_COORDINATE)],
            description=(
                "reveal action-selected Time Coordinate epoch "
                f"{destination['code']} with {destination['uses']} use(s)"
            ),
        )
        action.update(
            {
                "selection_mode": EXPLICIT_SELECTION_MODE,
                "warp_catalog": "v1.time",
                "destination_code": destination["code"],
                "uses": destination["uses"],
                "minimum_source_pool_inclusive": destination[
                    "minimum_source_pool_inclusive"
                ],
            }
        )
        actions.append(action)
    actions.extend(
        [
            action_record(
                "WarpToCoordinateReusable",
                "warp_to_coordinate",
                [
                    ("output", SHIP),
                    ("input", SHIP),
                    ("mutate", WARP_COORDINATE),
                ],
                description="warp a Ship and decrement a reusable Warp Coordinate",
            ),
            action_record(
                "WarpToCoordinateFinal",
                "warp_to_coordinate",
                [
                    ("output", SHIP),
                    ("input", SHIP),
                    ("input", WARP_COORDINATE),
                ],
                description="warp a Ship and consume the final Warp Coordinate use",
            ),
            action_record(
                "TimeWarpToCoordinateReusable",
                "time_warp_to_coordinate",
                [
                    ("output", SHIP),
                    ("input", SHIP),
                    ("mutate", TIME_COORDINATE),
                ],
                description="time-warp a Ship and decrement a reusable Time Coordinate",
            ),
            action_record(
                "TimeWarpToCoordinateFinal",
                "time_warp_to_coordinate",
                [
                    ("output", SHIP),
                    ("input", SHIP),
                    ("input", TIME_COORDINATE),
                ],
                description="time-warp a Ship and consume the final Time Coordinate use",
            ),
        ]
    )
    if POSITION_CHART_DESTINATIONS:
        for action_name, chart_class, skill_code in (
            ("ExtractWormholeWarpChart", WARP_CHART, 11),
            ("ExtractWormholeEpochChart", EPOCH_CHART, 14),
        ):
            action = action_record(
                action_name,
                WARP_OBJECT_ACTIONS[action_name]["family"],
                [
                    ("output", SHIP),
                    ("output", chart_class),
                    ("input", SHIP),
                    ("mutate", BODY),
                ],
                candidate_code=22,
                skill_code=skill_code,
                description="extract one sealed v2 chart from a Wormhole Mouth",
            )
            action["warp_catalog"] = "v2"
            action["vdf_iterations"] = 20
            actions.append(action)
        for destination in POSITION_CHART_DESTINATIONS:
            action = action_record(
                destination["reveal_action"],
                WARP_OBJECT_ACTIONS["RevealWarpChart{slug}"]["family"],
                [("output", SHIP), ("input", SHIP), ("mutate", WARP_CHART)],
                skill_code=50,
                description=(
                    "reveal one action-selected fixed v2 position-chart "
                    f"destination {destination['code']} with "
                    f"{destination['uses']} use(s)"
                ),
            )
            action.update(
                {
                    "warp_catalog": "v2.position",
                    "destination_code": destination["code"],
                    "uses": destination["uses"],
                    "selection_mode": EXPLICIT_SELECTION_MODE,
                    "minimum_source_pool_inclusive": destination[
                        "minimum_source_pool_inclusive"
                    ],
                    "vdf_iterations": 20,
                }
            )
            actions.append(action)
        for final_use in (False, True):
            name = (
                "WarpShipToPositionCoordinateFinal"
                if final_use
                else "WarpShipToPositionCoordinateReusable"
            )
            action = action_record(
                name,
                WARP_OBJECT_ACTIONS[name]["family"],
                [
                    ("output", SHIP),
                    ("input", SHIP),
                    (("input" if final_use else "mutate"), WARP_CHART),
                ],
                skill_code=51,
                description="use one fixed v2 position-chart destination",
            )
            action.update(
                {
                    "warp_catalog": "v2.position",
                    "final_use": final_use,
                    "vdf_iterations": 12,
                }
            )
            actions.append(action)
        for destination in EPOCH_CHART_DESTINATIONS:
            action = action_record(
                destination["reveal_action"],
                WARP_OBJECT_ACTIONS["RevealEpochChart{slug}"]["family"],
                [("output", SHIP), ("input", SHIP), ("mutate", EPOCH_CHART)],
                skill_code=58,
                description=(
                    "reveal one action-selected fixed v2 epoch-chart "
                    f"destination {destination['code']} with "
                    f"{destination['uses']} use(s)"
                ),
            )
            action.update(
                {
                    "warp_catalog": "v2.time",
                    "destination_code": destination["code"],
                    "uses": destination["uses"],
                    "selection_mode": EXPLICIT_SELECTION_MODE,
                    "minimum_source_pool_inclusive": destination[
                        "minimum_source_pool_inclusive"
                    ],
                    "vdf_iterations": 20,
                }
            )
            actions.append(action)
        for final_use in (False, True):
            name = (
                "WarpShipToEpochCoordinateFinal"
                if final_use
                else "WarpShipToEpochCoordinateReusable"
            )
            action = action_record(
                name,
                WARP_OBJECT_ACTIONS[name]["family"],
                [
                    ("output", SHIP),
                    ("input", SHIP),
                    (("input" if final_use else "mutate"), EPOCH_CHART),
                ],
                skill_code=58,
                description="use one fixed v2 epoch-chart destination",
            )
            action.update(
                {
                    "warp_catalog": "v2.time",
                    "final_use": final_use,
                    "vdf_iterations": 20,
                }
            )
            actions.append(action)
        for action_name, anchor_class, skill_code, recipe_name, vdf_iterations in (
            ("CapturePositionAnchor", POSITION_ANCHOR, 49, "PositionAnchor", 12),
            ("CaptureTimeAnchor", TIME_ANCHOR, 60, "TimeAnchor", 20),
        ):
            recipe = WARP_RECIPES[recipe_name]
            action = action_record(
                action_name,
                WARP_OBJECT_ACTIONS[action_name]["family"],
                [
                    ("output", SHIP),
                    ("output", anchor_class),
                    ("input", SHIP),
                    *[("input", item["class"]) for item in recipe["inputs"]],
                ],
                skill_code=skill_code,
                description=f"capture a fixed {recipe_name}",
            )
            action.update(
                {
                    "warp_catalog": "v2",
                    "warp_recipe": recipe_name,
                    "vdf_iterations": vdf_iterations,
                }
            )
            actions.append(action)
        for action_name, link_class, anchor_class, skill_code, recipe_name in (
            ("ConstructWormholeLink", WORMHOLE_LINK, POSITION_ANCHOR, 59, "WormholeLink"),
            ("ConstructTemporalLink", TEMPORAL_LINK, TIME_ANCHOR, 60, "TemporalLink"),
        ):
            recipe = WARP_RECIPES[recipe_name]
            action = action_record(
                action_name,
                WARP_OBJECT_ACTIONS[action_name]["family"],
                [
                    ("output", link_class),
                    ("input", anchor_class),
                    ("input", anchor_class),
                    ("input", RESOURCE),
                    ("input", RESOURCE),
                    ("mutate", SHIP),
                ],
                skill_code=skill_code,
                description=f"construct a fixed {recipe_name}",
            )
            action.update(
                {
                    "warp_catalog": "v2",
                    "warp_recipe": recipe_name,
                    "vdf_iterations": 32,
                }
            )
            actions.append(action)
        for time_only, kind, link_class, skill_code in (
            (False, "Wormhole", WORMHOLE_LINK, 59),
            (True, "Temporal", TEMPORAL_LINK, 60),
        ):
            for a_to_b, direction in ((True, "AToB"), (False, "BToA")):
                for final_use in (False, True):
                    name = (
                        f"Traverse{kind}{direction}"
                        + ("Final" if final_use else "Reusable")
                    )
                    action = action_record(
                        name,
                        WARP_OBJECT_ACTIONS[name]["family"],
                        [
                            ("output", SHIP),
                            ("input", SHIP),
                            (("input" if final_use else "mutate"), link_class),
                        ],
                        skill_code=skill_code,
                        description=f"traverse one {kind} link direction",
                    )
                    action.update(
                        {
                            "warp_catalog": "v2",
                            "direction": direction,
                            "final_use": final_use,
                            "vdf_iterations": 20,
                        }
                    )
                    actions.append(action)
        rendezvous_recipe = WARP_RECIPES["RendezvousCoordinate"]
        rendezvous = action_record(
            "ComposeRendezvousCoordinate",
            WARP_OBJECT_ACTIONS["ComposeRendezvousCoordinate"]["family"],
            [
                ("output", RENDEZVOUS_COORDINATE),
                *[("input", item["class"]) for item in rendezvous_recipe["inputs"]],
                ("mutate", SHIP),
            ],
            skill_code=86,
            description="compose a fixed position-and-time rendezvous destination",
        )
        rendezvous.update(
            {
                "warp_catalog": "v2",
                "warp_recipe": "RendezvousCoordinate",
                "vdf_iterations": 32,
            }
        )
        actions.append(rendezvous)
        for final_use in (False, True):
            name = (
                "WarpToRendezvousCoordinateFinal"
                if final_use
                else "WarpToRendezvousCoordinateReusable"
            )
            action = action_record(
                name,
                WARP_OBJECT_ACTIONS[name]["family"],
                [
                    ("output", SHIP),
                    ("input", SHIP),
                    (
                        ("input" if final_use else "mutate"),
                        RENDEZVOUS_COORDINATE,
                    ),
                ],
                skill_code=86,
                description="warp to one combined rendezvous destination",
            )
            action.update(
                {
                    "warp_catalog": "v2",
                    "final_use": final_use,
                    "vdf_iterations": 32,
                }
            )
            actions.append(action)
    for resource_name in ["Matter", "Crystal", "Gas", "Energy"]:
        base_action_name = f"Extract{resource_name}"
        for action_name, tier in extraction_tier_variants(
            base_action_name,
            0,
        ):
            action = action_record(
                action_name,
                "extract_resource",
                [
                    ("output", SHIP),
                    ("output", RESOURCE),
                    ("input", SHIP),
                    ("mutate", BODY),
                ],
                description=(
                    f"extract {resource_name} with a "
                    f"{tier['name']} Ship"
                ),
            )
            action["base_extraction_action"] = base_action_name
            action["extraction_ship_tier"] = tier["name"]
            actions.append(action)
    actions.append(
        action_record(
            "DiscoverSatellite",
            "discover_satellite",
            [
                ("output", SHIP),
                ("output", SATELLITE),
                ("input", SHIP),
                ("mutate", BODY),
            ],
        )
    )
    detect_life_action = action_record(
        "DetectIntelligentLife",
        "detect_intelligent_life",
        [
            ("output", SHIP),
            ("output", LIFE_SIGNAL),
            ("input", SHIP),
            ("mutate", BODY),
        ],
    )
    detect_life_action.update(
        {
            "selection_mode": DETERMINISTIC_SELECTOR_MODE,
            "selector_subject": "body.source_signal_identifier",
            "selector_band": intelligent_life_selector_band(bank),
            "initial_life_stat": 0,
            "selected_life_stat": 1,
            "candidate_codes": list(INTELLIGENT_LIFE_CANDIDATE_CODES),
        }
    )
    actions.append(detect_life_action)
    for civilization_type in CIVILIZATION_TYPES:
        gate = EXPLICIT_COUNTER_GATES[civilization_type["action"]]
        action = action_record(
            civilization_type["action"],
            "materialize_civilization",
            [
                ("output", CIVILIZATION),
                ("input", LIFE_SIGNAL),
                ("mutate", SHIP),
            ],
            description=(
                "materialize the stable-ID-selected "
                f"{civilization_type['name']}; requires Ship "
                "civilization_scan_serial >= "
                f"{civilization_type['minimum_civilization_scan_serial']}"
            ),
        )
        action.update(
            {
                "selection_mode": gate["selection_mode"],
                "selector_subject": "life_signal.stable_identifier",
                "selector_band": civilization_selector_bands()[
                    civilization_type["code"]
                ],
                "civilization_type": gate["selected_code"],
                "minimum_civilization_scan_serial": gate[
                    "minimum_inclusive"
                ],
            }
        )
        actions.append(action)
    for resource in CIVILIZATION_TECH_RESOURCES:
        for action_name, tier in extraction_tier_variants(
            resource["action"],
            resource["minimum_ship_tier"],
        ):
            action = action_record(
                action_name,
                "extract_civilization_tech_resource",
                [
                    ("output", SHIP),
                    ("output", resource["output_class"]),
                    ("input", SHIP),
                    ("mutate", BODY),
                ],
                candidate_code=resource["candidate_code"],
                skill_code=resource["skill_code"],
                resource_code=resource["code"],
                description=(
                    f"extract {resource['name']} from a "
                    f"{resource['category']} with a {tier['name']} Ship"
                ),
            )
            action["base_extraction_action"] = resource["action"]
            action["extraction_ship_tier"] = tier["name"]
            action["selection_mode"] = DETERMINISTIC_SELECTOR_MODE
            action["selector_subject"] = "body.source_signal_identifier"
            action["selector_band"] = resource_selector_bands()[
                resource["action"]
            ]
            actions.append(action)
    resource_code_by_name = {
        resource["name"]: resource["code"]
        for resource in CIVILIZATION_TECH_RESOURCES
    }
    for route in REFINEMENT_ROUTES:
        actions.append(
            action_record(
                route["action"],
                "refine_resource",
                [
                    ("output", SHIP),
                    ("output", RESOURCE),
                    ("input", SHIP),
                    ("mutate", COMPOSITE_RESOURCE),
                ],
                skill_code=route["skill_code"],
                resource_code=route["resource_code"],
                parent_resource_code=resource_code_by_name[
                    route["parent_name"]
                ],
                description=(
                    f"refine {route['child_name']} from "
                    f"{route['parent_name']}"
                ),
            )
        )
    for component in COMPONENT_RECIPES:
        for final_use in (False, True):
            mode = "final" if final_use else "reusable"
            catalyst_role = "input" if final_use else "mutate"
            action = action_record(
                component["actions"][mode],
                "fabricate_component",
                [
                    ("output", SHIP),
                    ("output", RESOURCE),
                    ("input", SHIP),
                    ("input", RESOURCE),
                    ("input", RESOURCE),
                    ("input", RESOURCE),
                    (catalyst_role, RESOURCE),
                ],
                skill_code=component["skill_code"],
                resource_code=component["code"],
                description=(
                    f"fabricate {component['name']} and "
                    + (
                        "consume the final catalyst unit"
                        if final_use
                        else "decrement a reusable catalyst stack"
                    )
                ),
            )
            action["component_code"] = component["code"]
            action["catalyst_mode"] = mode
            actions.append(action)
    for skill in TECHNOLOGY_SKILLS:
        action = action_record(
                skill["action"],
                "develop_technology_skill",
                [
                    ("output", SHIP),
                    ("output", TECHNOLOGY_SKILL),
                    ("input", SHIP),
                    ("mutate", CIVILIZATION),
                ],
                description=f"develop reusable {skill['name']}",
            )
        action.update(
            {
                "selection_mode": DETERMINISTIC_SELECTOR_MODE,
                "selector_subject": (
                    "civilization.source_life_signal_identifier"
                ),
                "selector_band": technology_skill_selector_bands()[
                    skill["code"]
                ],
                "skill_code": skill["code"],
            }
        )
        actions.append(action)
    for skill in DERIVED_SKILLS:
        action = action_record(
            skill["action"],
            "develop_derived_skill",
            [
                ("output", SHIP),
                ("output", TECHNOLOGY_SKILL),
                ("input", SHIP),
                *[("input", RESOURCE) for _item in skill["items"]],
            ],
            skill_code=skill["parent_code"],
            resource_code=skill["capability_resource_code"],
            description=(
                f"develop reusable {skill['name']} from fixed evidence"
            ),
        )
        action["output_skill_code"] = skill["code"]
        action["skill_tier"] = skill["tier"]
        action["vdf_iterations"] = skill["vdf_iterations"]
        actions.append(action)
    for capability in SKILL_CAPABILITIES:
        action = action_record(
            capability["action"],
            capability["action_family"],
            [
                ("output", SHIP),
                ("output", RESOURCE),
                ("input", SHIP),
                *[("input", RESOURCE) for _item in capability["fixed_inputs"]],
            ],
            skill_code=capability["skill_code"],
            resource_code=capability["output_resource_code"],
            description=(
                f"produce fixed capability artifact "
                f"{capability['output_resource_name']}"
            ),
        )
        action["route_key"] = capability["route_key"]
        action["vdf_iterations"] = capability["vdf_iterations"]
        actions.append(action)
    actions.append(
        action_record(
            "UseTechnologySkill",
            "use_technology_skill",
            [
                ("output", SHIP),
                ("input", SHIP),
                ("mutate", TECHNOLOGY_SKILL),
            ],
            description=(
                "prove possession of a reusable TechnologySkill and prepare "
                "the Ship for one gated action"
            ),
        )
    )
    actions.append(
        action_record(
            "CreateLargeShipConstructionPermit",
            "create_shipyard_permit",
            [("output", SHIPYARD_PERMIT), ("mutate", SHIP)],
            description=(
                "create a location-bound permit for one Large Ship"
            ),
        )
    )
    for skill in LARGE_CONSTRUCTION_SKILLS:
        actions.append(
            action_record(
                f"AuthorizeLargeShip{skill['slug']}",
                "authorize_shipyard_permit",
                [
                    ("output", SHIP),
                    ("input", SHIP),
                    ("mutate", SHIPYARD_PERMIT),
                ],
                skill_code=skill["skill_code"],
                description=(
                    f"authorize Large Ship construction with "
                    f"{skill['name']}"
                ),
            )
        )
    actions.append(
        action_record(
            "IssueAuxiliaryShipPermit",
            "issue_auxiliary_ship_permit",
            [("output", SHIPYARD_PERMIT), ("mutate", SHIP)],
            description=(
                "issue the one deterministic auxiliary build permit for a "
                "Large Ship"
            ),
        )
    )
    for tier_name, recipe in (
        ("Small", AUXILIARY_SMALL_RECIPE),
        ("Medium", MEDIUM_SHIP_RECIPE),
    ):
        actions.append(
            action_record(
                f"BuildAuxiliaryShip{tier_name}",
                "build_auxiliary_ship",
                [
                    ("output", SHIP),
                    ("input", SHIPYARD_PERMIT),
                    *[("input", RESOURCE) for _ingredient in recipe],
                ],
                description=(
                    f"atomically consume the Large Ship's one-use permit "
                    f"and complete the {tier_name} Ship recipe at the "
                    "permit's proven location"
                ),
            )
        )
    apply_intro_contracts(actions)
    return actions


def phase4_adapter_helpers_source() -> str:
    """Render the active Phase 4 fixed-topology canary helper inventory."""
    if not PHASE4_ADAPTER_CANARIES_ENABLED:
        return ""
    helpers: list[str] = []
    for helper_name, kind, iterations, _representative in phase4_helper_specs():
        if kind == "base":
            parameters = (
                "action, next_ship, resource, ship, body, required_skill_type, "
                "remaining_field, resource_type, extraction_amount, "
                "rare_extraction_amount"
            )
            body = """    action.st_sum(ship.active_skill_type, 0, required_skill_type);
    extract_direct_resource_core(action, next_ship, resource, ship, body, remaining_field, resource_type, extraction_amount, rare_extraction_amount);"""
            target = "body"
        elif kind == "body":
            parameters = (
                "action, next_ship, resource, ship, body, candidate_code, "
                "required_skill_type, remaining_field, resource_type, "
                "extraction_amount, rare_extraction_amount"
            )
            body = """    action.st_sum(body.candidate_code, 0, candidate_code);
    action.st_sum(ship.active_skill_type, 0, required_skill_type);
    extract_direct_resource_core(action, next_ship, resource, ship, body, remaining_field, resource_type, extraction_amount, rare_extraction_amount);"""
            target = "body"
        elif kind == "composite":
            parameters = (
                "action, next_ship, composite_resource, ship, body, "
                "candidate_code, required_skill_type, remaining_field, "
                "composite_resource_type, extraction_amount, "
                "rare_extraction_amount, child_1_amount, child_2_amount, "
                "child_3_amount"
            )
            body = """    action.st_sum(body.candidate_code, 0, candidate_code);
    action.st_sum(ship.active_skill_type, 0, required_skill_type);
    extract_composite_resource_core(action, next_ship, composite_resource, ship, body, remaining_field, composite_resource_type, extraction_amount, rare_extraction_amount, child_1_amount, child_2_amount, child_3_amount);"""
            target = "body"
        else:
            parameters = (
                "action, next_ship, resource, ship, parent, "
                "required_skill_type, parent_resource_type, "
                "child_remaining_field, output_resource_type"
            )
            body = """    refine_resource_core(action, next_ship, resource, ship, parent, required_skill_type, parent_resource_type, child_remaining_field, output_resource_type);"""
            target = "parent"
        vdf_tail = ""
        if iterations is not None:
            vdf_tail = (
                f"\n    var work = action.intro_vdf({iterations}, {target});\n"
                f'    {target}.update("work", work);'
            )
        helpers.append(
            f"""fn {helper_name}({parameters}) {{
{body}{vdf_tail}
}}
"""
        )
    return "\n".join(helpers)


def phase5_adapter_helpers_source() -> str:
    """Render the fixed Phase 5 component and skill helper inventory."""
    if not PHASE5_ADAPTER_CANARIES_ENABLED:
        return ""
    helpers: list[str] = []
    for helper_name, family, shape, iterations, _representative in PHASE5_ADAPTER_HELPERS:
        if family == "component":
            catalyst_helper = (
                "consume_component_catalyst_final_core"
                if shape == "final"
                else "consume_component_catalyst_reusable_core"
            )
            parameters = (
                "action, next_ship, component, ship, material_1, material_2, "
                "material_3, catalyst, skill_type, material_1_type, "
                "material_1_amount, material_2_type, material_2_amount, "
                "material_3_type, material_3_amount, catalyst_type, "
                "component_type, component_amount"
            )
            body = f"""    fabricate_component_core(action, next_ship, component, ship, material_1, material_2, material_3, catalyst, skill_type, material_1_type, material_1_amount, material_2_type, material_2_amount, material_3_type, material_3_amount, catalyst_type, component_type, component_amount);
    {catalyst_helper}(action, catalyst);
    var work = action.intro_vdf({iterations}, component);
    component.update(\"work\", work);"""
        elif family == "derived":
            evidence_count = int(shape)
            evidence_parameters = ", ".join(
                f"evidence_{index}" for index in range(1, evidence_count + 1)
            )
            evidence_literals = ", ".join(
                f"evidence_{index}_type, evidence_{index}_amount"
                for index in range(1, evidence_count + 1)
            )
            evidence_gates = "\n".join(
                f"    prove_resource_stack_core(action, evidence_{index}, evidence_{index}_type, evidence_{index}_amount);"
                for index in range(1, evidence_count + 1)
            )
            parameters = (
                "action, next_ship, technology_skill, ship, "
                f"{evidence_parameters}, parent_skill_type, output_skill_type, "
                f"{evidence_literals}"
            )
            body = f"""    develop_derived_skill_core(action, next_ship, technology_skill, ship, parent_skill_type, output_skill_type);
{evidence_gates}
    var work = action.intro_vdf({iterations}, technology_skill);
    technology_skill.update(\"work\", work);"""
        else:
            evidence_count = int(shape)
            evidence_parameters = ", ".join(
                f"evidence_{index}" for index in range(1, evidence_count + 1)
            )
            evidence_literals = ", ".join(
                f"evidence_{index}_type, evidence_{index}_amount"
                for index in range(1, evidence_count + 1)
            )
            evidence_gates = "\n".join(
                f"    prove_resource_stack_core(action, evidence_{index}, evidence_{index}_type, evidence_{index}_amount);"
                for index in range(1, evidence_count + 1)
            )
            parameters = (
                "action, next_ship, artifact, ship, "
                f"{evidence_parameters}, required_skill_type, "
                f"output_resource_type, output_amount, {evidence_literals}"
            )
            body = f"""    produce_capability_artifact_core(action, next_ship, artifact, ship, required_skill_type, output_resource_type, output_amount);
{evidence_gates}
    var work = action.intro_vdf({iterations}, artifact);
    artifact.update(\"work\", work);"""
        helpers.append(f"""fn {helper_name}({parameters}) {{
{body}
}}
""")
    return "\n".join(helpers)


def phase6_movement_helpers_source() -> str:
    """Render the economy-only fixed Phase 6 movement helpers."""
    if (
        not PHASE6_MOVEMENT_CANARIES_ENABLED
        or ACTIVE_VDF_PROFILE != "economy"
    ):
        return ""
    return f"""
fn move_positive_core(action, ship, current_coordinate, coordinate_field, step, extraction_amount, rare_extraction_amount) {{
    action.st_sum(ship.extraction_amount, 0, extraction_amount);
    action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);
    var next_coordinate = unsafe {{ current_coordinate - (0 - step) }};
    action.st_sum(current_coordinate, step, next_coordinate);
    action.st_gt(next_coordinate, 0);
    action.st_gt({COORD_UPPER_BOUND}, next_coordinate);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    ship.update(coordinate_field, next_coordinate);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_ship_key = action.random();
    rotate_key(ship, next_ship_key);
}}

fn move_negative_core(action, ship, current_coordinate, coordinate_field, step, extraction_amount, rare_extraction_amount) {{
    action.st_sum(ship.extraction_amount, 0, extraction_amount);
    action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);
    var next_coordinate = unsafe {{ current_coordinate - step }};
    action.st_sum(next_coordinate, step, current_coordinate);
    action.st_gt(next_coordinate, 0);
    action.st_gt({COORD_UPPER_BOUND}, next_coordinate);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    ship.update(coordinate_field, next_coordinate);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_ship_key = action.random();
    rotate_key(ship, next_ship_key);
}}

fn update_ship_work_vdf_4_core(action, ship) {{
    var work = action.intro_vdf(4, ship);
    ship.update("work", work);
}}

fn update_ship_work_vdf_12_core(action, ship) {{
    var work = action.intro_vdf(12, ship);
    ship.update("work", work);
}}

fn update_ship_work_vdf_28_core(action, ship) {{
    var work = action.intro_vdf(28, ship);
    ship.update("work", work);
}}

fn advance_ship_epoch_core(action, ship, next_epoch) {{
    action.st_gt({EPOCH_UPPER_BOUND}, next_epoch);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    ship.update("epoch", next_epoch);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_ship_key = action.random();
    rotate_key(ship, next_ship_key);
}}
"""


def common_helpers() -> str:
    technology_ship_state = replacement_ship_state_source(
        "civilization",
        ("sector_x", "sector_y", "sector_z", "origin_epoch"),
        None,
        "civilization_version",
    )
    authorization_ship_state = replacement_ship_state_source(
        "permit",
        ("x", "y", "z", "epoch"),
        None,
        None,
    )
    survey_ship_state = replacement_ship_state_source(
        "sector", ("x", "y", "z", "epoch"), None
    )
    component_ship_state = replacement_ship_state_source(
        "component",
        ("x", "y", "z", "epoch"),
        None,
        target_version_field=None,
        bind_target_location=False,
        prove_target=False,
    )
    chart_ship_state = replacement_ship_state_source(
        "body",
        ("sector_x", "sector_y", "sector_z", "sector_epoch"),
        None,
        "body_bank_version",
    )
    _detect_ship_prefix, detect_ship_finish = (
        detect_replacement_ship_state_parts()
    )
    survey_empty_sector_constraints = "\n".join(
        f"    action.st_sum(sector.{field}, 0, 0);"
        for field in (
            "sector_type",
            "survey_profile",
            *(category["remaining_field"] for category in CELESTIAL_CATEGORIES),
            *(category["serial_field"] for category in CELESTIAL_CATEGORIES),
        )
    )
    return f"""// Generated deterministically by tools/generate_microverse.py.
// Protocol versions: schema={VERSIONS['schema_version']} mechanics={VERSIONS['mechanics_version']} universe={VERSIONS['universe_version']} body_bank={VERSIONS['body_bank_version']} civilization={VERSIONS['civilization_version']}.

fn prove_fixed_versions(action, object) {{
    action.st_sum(object.schema_version, 0, {VERSIONS['schema_version']});
    action.st_sum(object.mechanics_version, 0, {VERSIONS['mechanics_version']});
    action.st_sum(object.universe_version, 0, {VERSIONS['universe_version']});
}}

fn bind_ship_id(action, ship) {{
    var bound_ship_id = action.random();
    var_assign(bound_ship_id, ship.ship_id);
    ship.update("ship_id", bound_ship_id);
    bound_ship_id
}}

fn warp_ship_core(
    action,
    next_ship,
    ship,
    destination_x,
    destination_y,
    destination_z,
    destination_epoch
) {{
    prove_fixed_versions(action, ship);
    var ship_id = bind_ship_id(action, ship);
    var extraction_amount = unsafe {{ ship.extraction_amount - 0 }};
    var rare_extraction_amount = unsafe {{ ship.rare_extraction_amount - 0 }};
    var x = unsafe {{ destination_x - 0 }};
    var y = unsafe {{ destination_y - 0 }};
    var z = unsafe {{ destination_z - 0 }};
    var epoch = unsafe {{ destination_epoch - 0 }};
    var claim_serial = unsafe {{ ship.claim_serial - 0 }};
    var discovery_serial = unsafe {{ ship.discovery_serial - 0 }};
    var satellite_serial = unsafe {{ ship.satellite_serial - 0 }};
    var civilization_scan_serial = unsafe {{ ship.civilization_scan_serial - 0 }};
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.extraction_amount, 0, extraction_amount);
    action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);
    action.st_sum(destination_x, 0, x);
    action.st_sum(destination_y, 0, y);
    action.st_sum(destination_z, 0, z);
    action.st_sum(destination_epoch, 0, epoch);
    action.st_sum(ship.claim_serial, 0, claim_serial);
    action.st_sum(ship.discovery_serial, 0, discovery_serial);
    action.st_sum(ship.satellite_serial, 0, satellite_serial);
    action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);
    action.st_sum(ship.action_serial, 1, next_action_serial);
    next_ship.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["extraction_amount", extraction_amount],
        ["rare_extraction_amount", rare_extraction_amount],
        ["x", x],
        ["y", y],
        ["z", z],
        ["epoch", epoch],
        ["active_skill_type", 0],
        ["action_serial", next_action_serial],
        ["claim_serial", claim_serial],
        ["discovery_serial", discovery_serial],
        ["satellite_serial", satellite_serial],
        ["civilization_scan_serial", civilization_scan_serial],
        ["ship_id", ship_id]
    ]);
}}

fn rotate_key(object, next_key) {{
    object.update("key", next_key);
}}

fn reveal_p(
    action,
    coordinate,
    destination_code,
    destination_x,
    destination_y,
    destination_z,
    uses,
    minimum_source_pool_exclusive
) {{
    prove_fixed_versions(action, coordinate);
    action.st_sum(coordinate.revealed, 0, 0);
    action.st_gt(
        coordinate.source_pool_before,
        minimum_source_pool_exclusive
    );
    coordinate.update("revealed", 1);
    coordinate.update("destination_code", destination_code);
    coordinate.update("destination_x", destination_x);
    coordinate.update("destination_y", destination_y);
    coordinate.update("destination_z", destination_z);
    coordinate.update("uses_remaining", uses);
    var next_key = action.random();
    rotate_key(coordinate, next_key);
}}

fn reveal_t(
    action,
    coordinate,
    destination_code,
    destination_epoch,
    uses,
    minimum_source_pool_exclusive
) {{
    prove_fixed_versions(action, coordinate);
    action.st_sum(coordinate.revealed, 0, 0);
    action.st_gt(
        coordinate.source_pool_before,
        minimum_source_pool_exclusive
    );
    coordinate.update("revealed", 1);
    coordinate.update("destination_code", destination_code);
    coordinate.update("destination_epoch", destination_epoch);
    coordinate.update("uses_remaining", uses);
    var next_key = action.random();
    rotate_key(coordinate, next_key);
}}

fn extract_direct_resource_core(
    action,
    next_ship,
    resource,
    ship,
    body,
    remaining_field,
    resource_type,
    extraction_amount,
    rare_extraction_amount
) {{
    var ship_id = bind_ship_id(action, ship);
    prove_fixed_versions(action, ship);
    prove_fixed_versions(action, body);
    action.st_sum(body.body_bank_version, 0, {VERSIONS['body_bank_version']});
    action.st_sum(ship.extraction_amount, 0, extraction_amount);
    action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

    var x = unsafe {{ ship.x - 0 }};
    var y = unsafe {{ ship.y - 0 }};
    var z = unsafe {{ ship.z - 0 }};
    var epoch = unsafe {{ ship.epoch - 0 }};
    action.st_sum(ship.x, 0, x);
    action.st_sum(body.sector_x, 0, x);
    action.st_sum(ship.y, 0, y);
    action.st_sum(body.sector_y, 0, y);
    action.st_sum(ship.z, 0, z);
    action.st_sum(body.sector_z, 0, z);
    action.st_sum(ship.epoch, 0, epoch);
    action.st_sum(body.sector_epoch, 0, epoch);

    var claim_serial = unsafe {{ ship.claim_serial - 0 }};
    var discovery_serial = unsafe {{ ship.discovery_serial - 0 }};
    var satellite_serial = unsafe {{ ship.satellite_serial - 0 }};
    var civilization_scan_serial = unsafe {{
        ship.civilization_scan_serial - 0
    }};
    action.st_sum(ship.claim_serial, 0, claim_serial);
    action.st_sum(ship.discovery_serial, 0, discovery_serial);
    action.st_sum(ship.satellite_serial, 0, satellite_serial);
    action.st_sum(
        ship.civilization_scan_serial,
        0,
        civilization_scan_serial
    );
    var next_action_serial = unsafe {{
        ship.action_serial - (0 - 1)
    }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    next_ship.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["extraction_amount", extraction_amount],
        ["rare_extraction_amount", rare_extraction_amount],
        ["x", x],
        ["y", y],
        ["z", z],
        ["epoch", epoch],
        ["active_skill_type", 0],
        ["action_serial", next_action_serial],
        ["claim_serial", claim_serial],
        ["discovery_serial", discovery_serial],
        ["satellite_serial", satellite_serial],
        ["civilization_scan_serial", civilization_scan_serial],
        ["ship_id", ship_id]
    ]);

    var next_remaining = unsafe {{
        body[remaining_field] - extraction_amount
    }};
    action.st_sum(
        next_remaining,
        extraction_amount,
        body[remaining_field]
    );
    action.st_gt(next_remaining, -1);

    resource.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["resource_type", resource_type],
        ["amount", extraction_amount]
    ]);
    body.update(remaining_field, next_remaining);
    var next_body_key = action.random();
    rotate_key(body, next_body_key);
}}

fn extract_composite_resource_core(
    action,
    next_ship,
    composite_resource,
    ship,
    body,
    remaining_field,
    resource_type,
    extraction_amount,
    rare_extraction_amount,
    child_1_amount,
    child_2_amount,
    child_3_amount
) {{
    var ship_id = bind_ship_id(action, ship);
    prove_fixed_versions(action, ship);
    prove_fixed_versions(action, body);
    action.st_sum(body.body_bank_version, 0, {VERSIONS['body_bank_version']});
    action.st_sum(ship.extraction_amount, 0, extraction_amount);
    action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

    var x = unsafe {{ ship.x - 0 }};
    var y = unsafe {{ ship.y - 0 }};
    var z = unsafe {{ ship.z - 0 }};
    var epoch = unsafe {{ ship.epoch - 0 }};
    action.st_sum(ship.x, 0, x);
    action.st_sum(body.sector_x, 0, x);
    action.st_sum(ship.y, 0, y);
    action.st_sum(body.sector_y, 0, y);
    action.st_sum(ship.z, 0, z);
    action.st_sum(body.sector_z, 0, z);
    action.st_sum(ship.epoch, 0, epoch);
    action.st_sum(body.sector_epoch, 0, epoch);

    var claim_serial = unsafe {{ ship.claim_serial - 0 }};
    var discovery_serial = unsafe {{ ship.discovery_serial - 0 }};
    var satellite_serial = unsafe {{ ship.satellite_serial - 0 }};
    var civilization_scan_serial = unsafe {{
        ship.civilization_scan_serial - 0
    }};
    action.st_sum(ship.claim_serial, 0, claim_serial);
    action.st_sum(ship.discovery_serial, 0, discovery_serial);
    action.st_sum(ship.satellite_serial, 0, satellite_serial);
    action.st_sum(
        ship.civilization_scan_serial,
        0,
        civilization_scan_serial
    );
    var next_action_serial = unsafe {{
        ship.action_serial - (0 - 1)
    }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    next_ship.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["extraction_amount", extraction_amount],
        ["rare_extraction_amount", rare_extraction_amount],
        ["x", x],
        ["y", y],
        ["z", z],
        ["epoch", epoch],
        ["active_skill_type", 0],
        ["action_serial", next_action_serial],
        ["claim_serial", claim_serial],
        ["discovery_serial", discovery_serial],
        ["satellite_serial", satellite_serial],
        ["civilization_scan_serial", civilization_scan_serial],
        ["ship_id", ship_id]
    ]);

    var next_remaining = unsafe {{
        body[remaining_field] - extraction_amount
    }};
    action.st_sum(
        next_remaining,
        extraction_amount,
        body[remaining_field]
    );
    action.st_gt(next_remaining, -1);
    composite_resource.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["resource_type", resource_type],
        ["sector_x", x],
        ["sector_y", y],
        ["sector_z", z],
        ["origin_epoch", epoch],
        ["child_1_remaining", child_1_amount],
        ["child_2_remaining", child_2_amount],
        ["child_3_remaining", child_3_amount]
    ]);
    body.update(remaining_field, next_remaining);
    var next_body_key = action.random();
    rotate_key(body, next_body_key);
}}

fn refine_resource_core(
    action,
    next_ship,
    resource,
    ship,
    parent,
    skill_type,
    parent_resource_type,
    child_remaining_field,
    output_resource_type
) {{
    prove_fixed_versions(action, ship);
    prove_fixed_versions(action, parent);
    var ship_id = bind_ship_id(action, ship);

    var extraction_amount = unsafe {{ ship.extraction_amount - 0 }};
    var rare_extraction_amount = unsafe {{ ship.rare_extraction_amount - 0 }};
    action.st_sum(ship.extraction_amount, 0, extraction_amount);
    action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

    var x = unsafe {{ ship.x - 0 }};
    var y = unsafe {{ ship.y - 0 }};
    var z = unsafe {{ ship.z - 0 }};
    var epoch = unsafe {{ ship.epoch - 0 }};
    action.st_sum(ship.x, 0, x);
    action.st_sum(parent.sector_x, 0, x);
    action.st_sum(ship.y, 0, y);
    action.st_sum(parent.sector_y, 0, y);
    action.st_sum(ship.z, 0, z);
    action.st_sum(parent.sector_z, 0, z);
    action.st_sum(ship.epoch, 0, epoch);
    action.st_sum(parent.origin_epoch, 0, epoch);

    var claim_serial = unsafe {{ ship.claim_serial - 0 }};
    action.st_sum(ship.claim_serial, 0, claim_serial);
    var discovery_serial = unsafe {{ ship.discovery_serial - 0 }};
    action.st_sum(ship.discovery_serial, 0, discovery_serial);
    var satellite_serial = unsafe {{ ship.satellite_serial - 0 }};
    action.st_sum(ship.satellite_serial, 0, satellite_serial);
    var civilization_scan_serial = unsafe {{ ship.civilization_scan_serial - 0 }};
    action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);

    next_ship.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["extraction_amount", extraction_amount],
        ["rare_extraction_amount", rare_extraction_amount],
        ["x", x],
        ["y", y],
        ["z", z],
        ["epoch", epoch],
        ["active_skill_type", 0],
        ["action_serial", next_action_serial],
        ["claim_serial", claim_serial],
        ["discovery_serial", discovery_serial],
        ["satellite_serial", satellite_serial],
        ["civilization_scan_serial", civilization_scan_serial],
        ["ship_id", ship_id]
    ]);

    action.st_sum(ship.active_skill_type, 0, skill_type);
    action.st_sum(parent.resource_type, 0, parent_resource_type);
    action.st_gt(parent[child_remaining_field], 0);
    var refinement_amount = unsafe {{
        parent[child_remaining_field] - 0
    }};
    action.st_sum(
        parent[child_remaining_field],
        0,
        refinement_amount
    );
    resource.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["resource_type", output_resource_type],
        ["amount", refinement_amount]
    ]);
    parent.update(child_remaining_field, 0);
    var next_parent_key = action.random();
    rotate_key(parent, next_parent_key);
}}

fn develop_technology_skill_core(
    action,
    next_ship,
    technology_skill,
    ship,
    civilization,
    civilization_type,
    skill_type,
    reusable
) {{
{technology_ship_state}

    action.st_sum(
        civilization.civilization_type,
        0,
        civilization_type
    );
    technology_skill.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["civilization_version", {VERSIONS['civilization_version']}],
        ["skill_type", skill_type],
        ["reusable", reusable]
    ]);
    var next_civilization_key = action.random();
    rotate_key(civilization, next_civilization_key);
}}

fn consume_prepared_ship_core(
    action,
    next_ship,
    ship,
    required_skill_type
) {{
{component_ship_state}
    action.st_sum(ship.active_skill_type, 0, required_skill_type);
    ship_id
}}

fn prove_resource_stack_core(action, resource, resource_type, amount) {{
    prove_fixed_versions(action, resource);
    action.st_sum(resource.resource_type, 0, resource_type);
    action.st_sum(resource.amount, 0, amount);
}}

fn prove_object_version_core(action, object, version_field) {{
    prove_fixed_versions(action, object);
    action.st_sum(object[version_field], 0, 2);
}}

fn consume_reusable_use_core(action, object) {{
    action.st_gt(object.uses_remaining, 1);
    var next_uses = unsafe {{ object.uses_remaining - 1 }};
    action.st_sum(next_uses, 1, object.uses_remaining);
    object.update("uses_remaining", next_uses);
    var next_key = action.random();
    rotate_key(object, next_key);
}}

fn consume_final_use_core(action, object) {{
    action.st_sum(object.uses_remaining, 0, 1);
}}

fn extract_v2_chart_core(
    action,
    next_ship,
    ship,
    body,
    skill_type
) {{
{chart_ship_state}
    action.st_sum(ship.extraction_amount, 0, 250);
    action.st_sum(ship.rare_extraction_amount, 0, 25);
    action.st_sum(ship.active_skill_type, 0, skill_type);
    action.st_sum(body.candidate_code, 0, 22);
    action.st_sum(body.body_type, 0, 7);
    var next_energy = unsafe {{ body.energy_remaining - {WARP_ENERGY_COST} }};
    action.st_sum(next_energy, {WARP_ENERGY_COST}, body.energy_remaining);
    action.st_gt(next_energy, -1);
    body.update("energy_remaining", next_energy);
    var next_body_key = action.random();
    rotate_key(body, next_body_key);
}}

fn reveal_chart_p(
    action, next_ship, ship, chart, code, x, y, z, uses,
    minimum_source_pool_exclusive
) {{
    consume_prepared_ship_core(action, next_ship, ship, 50);
    prove_object_version_core(action, chart, "catalog_version");
    action.st_sum(chart.revealed, 0, 0);
    action.st_gt(chart.source_pool_before, minimum_source_pool_exclusive);
    chart.update("revealed", 1);
    chart.update("destination_code", code);
    chart.update("destination_x", x);
    chart.update("destination_y", y);
    chart.update("destination_z", z);
    chart.update("uses_remaining", uses);
    var next_key = action.random();
    rotate_key(chart, next_key);
    var work = action.intro_vdf(20, chart);
    chart.update("work", work);
}}

fn reveal_chart_t(
    action, next_ship, ship, chart, code, epoch, uses,
    minimum_source_pool_exclusive
) {{
    consume_prepared_ship_core(action, next_ship, ship, 58);
    prove_object_version_core(action, chart, "catalog_version");
    action.st_sum(chart.revealed, 0, 0);
    action.st_gt(chart.source_pool_before, minimum_source_pool_exclusive);
    chart.update("revealed", 1);
    chart.update("destination_code", code);
    chart.update("destination_epoch", epoch);
    chart.update("uses_remaining", uses);
    var next_key = action.random();
    rotate_key(chart, next_key);
    var work = action.intro_vdf(20, chart);
    chart.update("work", work);
}}

fn develop_derived_skill_core(
    action,
    next_ship,
    technology_skill,
    ship,
    parent_skill_type,
    output_skill_type
) {{
    consume_prepared_ship_core(
        action,
        next_ship,
        ship,
        parent_skill_type
    );
    technology_skill.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["civilization_version", {VERSIONS['civilization_version']}],
        ["skill_type", output_skill_type],
        ["reusable", 1]
    ]);
}}

fn produce_capability_artifact_core(
    action,
    next_ship,
    artifact,
    ship,
    required_skill_type,
    output_resource_type,
    output_amount
) {{
    consume_prepared_ship_core(
        action,
        next_ship,
        ship,
        required_skill_type
    );
    artifact.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["resource_type", output_resource_type],
        ["amount", output_amount]
    ]);
}}

fn authorize_large_ship_permit_core(
    action,
    next_ship,
    ship,
    permit,
    skill_type,
    authorization_field
) {{
{authorization_ship_state}
    action.st_sum(ship.active_skill_type, 0, skill_type);
    action.st_sum(permit.permit_type, 0, 1);
    action.st_sum(permit[authorization_field], 0, 0);
    permit.update(authorization_field, 1);
    var next_permit_key = action.random();
    rotate_key(permit, next_permit_key);
}}

fn fabricate_component_core(
    action,
    next_ship,
    component,
    ship,
    material_1,
    material_2,
    material_3,
    catalyst,
    skill_type,
    material_1_type,
    material_1_amount,
    material_2_type,
    material_2_amount,
    material_3_type,
    material_3_amount,
    catalyst_type,
    component_type,
    component_amount
) {{
    consume_prepared_ship_core(action, next_ship, ship, skill_type);
    prove_fixed_versions(action, material_1);
    prove_fixed_versions(action, material_2);
    prove_fixed_versions(action, material_3);
    prove_fixed_versions(action, catalyst);
    action.st_sum(material_1.resource_type, 0, material_1_type);
    action.st_sum(material_1.amount, 0, material_1_amount);
    action.st_sum(material_2.resource_type, 0, material_2_type);
    action.st_sum(material_2.amount, 0, material_2_amount);
    action.st_sum(material_3.resource_type, 0, material_3_type);
    action.st_sum(material_3.amount, 0, material_3_amount);
    action.st_sum(catalyst.resource_type, 0, catalyst_type);
    component.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["resource_type", component_type],
        ["amount", component_amount]
    ]);
}}

fn consume_component_catalyst_reusable_core(action, catalyst) {{
    action.st_gt(catalyst.amount, 1);
    var next_catalyst_amount = unsafe {{ catalyst.amount - 1 }};
    action.st_sum(next_catalyst_amount, 1, catalyst.amount);
    catalyst.update("amount", next_catalyst_amount);
    var next_catalyst_key = action.random();
    rotate_key(catalyst, next_catalyst_key);
}}

fn consume_component_catalyst_final_core(action, catalyst) {{
    action.st_sum(catalyst.amount, 0, 1);
}}

fn scan_body_core(
    action,
    body,
    signal,
    ship,
    category_code,
    candidate_code,
    body_type,
    life_stat,
    matter_remaining,
    crystal_remaining,
    gas_remaining,
    energy_remaining,
    satellites_remaining
) {{
    prove_fixed_versions(action, signal);
    prove_fixed_versions(action, ship);
    action.st_sum(signal.body_bank_version, 0, {VERSIONS['body_bank_version']});
    action.st_sum(signal.category_code, 0, category_code);
    action.st_sum(signal.candidate_code, 0, {UNRESOLVED_CANDIDATE_CODE});

    action.st_gt(signal.slot_serial, -1);

    var source_signal_identifier = action.random();
    var_assign(source_signal_identifier, signal.stable_identifier);
    signal.update("stable_identifier", source_signal_identifier);

    var sector_x = unsafe {{ signal.sector_x - 0 }};
    var sector_y = unsafe {{ signal.sector_y - 0 }};
    var sector_z = unsafe {{ signal.sector_z - 0 }};
    var sector_epoch = unsafe {{ signal.sector_epoch - 0 }};
    action.st_sum(signal.sector_x, 0, sector_x);
    action.st_sum(signal.sector_y, 0, sector_y);
    action.st_sum(signal.sector_z, 0, sector_z);
    action.st_sum(signal.sector_epoch, 0, sector_epoch);
    action.st_sum(ship.x, 0, sector_x);
    action.st_sum(ship.y, 0, sector_y);
    action.st_sum(ship.z, 0, sector_z);
    action.st_sum(ship.epoch, 0, sector_epoch);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);

    body.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["body_bank_version", {VERSIONS['body_bank_version']}],
        ["source_signal_identifier", source_signal_identifier],
        ["sector_x", sector_x],
        ["sector_y", sector_y],
        ["sector_z", sector_z],
        ["sector_epoch", sector_epoch],
        ["candidate_code", candidate_code],
        ["body_type", body_type],
        ["life_stat", life_stat],
        ["matter_remaining", matter_remaining],
        ["crystal_remaining", crystal_remaining],
        ["gas_remaining", gas_remaining],
        ["energy_remaining", energy_remaining],
        ["satellites_remaining", satellites_remaining],
        ["next_satellite_serial", 0],
        ["civilization_discovered", 0]
    ]);
    let zero = action.top_limb_u256(0);
    body.update("key", zero);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_ship_key = action.random();
    rotate_key(ship, next_ship_key);
}}

fn survey_replacement_ship_core(action, next_ship, ship, sector) {{
{survey_ship_state}
}}

fn finish_detect_replacement_ship_core(
    action,
    next_ship,
    ship,
    ship_id,
    extraction_amount,
    rare_extraction_amount,
    x,
    y,
    z,
    epoch
) {{
{detect_ship_finish}
}}

fn detect_signal_core(action, next_ship, signal, ship, sector, category_code, candidate_code, remaining_field, serial_field) {{
{_detect_ship_prefix}

    finish_detect_replacement_ship_core(action, next_ship, ship, ship_id, extraction_amount, rare_extraction_amount, x, y, z, epoch);
    action.st_sum(sector.sector_type, 0, {SECTOR_TYPE_CELESTIAL});
    action.st_gt(sector.survey_profile, 0);
    action.st_gt(sector[remaining_field], 0);
    var slot_serial = unsafe {{ sector[serial_field] - 0 }};
    action.st_sum(sector[serial_field], 0, slot_serial);
    var next_remaining = unsafe {{ sector[remaining_field] - 1 }}; action.st_sum(next_remaining, 1, sector[remaining_field]);
    var next_serial = unsafe {{ sector[serial_field] - (0 - 1) }}; action.st_sum(sector[serial_field], 1, next_serial);
    signal.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["body_bank_version", {VERSIONS['body_bank_version']}],
        ["sector_x", x],
        ["sector_y", y],
        ["sector_z", z],
        ["sector_epoch", epoch],
        ["category_code", category_code],
        ["candidate_code", candidate_code],
        ["slot_serial", slot_serial]
    ]);
    let zero = action.top_limb_u256(0); signal.update("key", zero);
    var next_sector_revision = unsafe {{ sector.revision - (0 - 1) }};
    action.st_sum(sector.revision, 1, next_sector_revision);
    sector.update(remaining_field, next_remaining);
    sector.update(serial_field, next_serial);
    sector.update("revision", next_sector_revision);
    var next_sector_key = action.random(); rotate_key(sector, next_sector_key);
}}

fn prove_empty_survey_sector_core(action, sector) {{
{survey_empty_sector_constraints}
}}

{phase4_adapter_helpers_source()}

{phase5_adapter_helpers_source()}

{phase6_movement_helpers_source()}

"""


def replacement_ship_state_source(
    target_var: str,
    target_location_fields: tuple[str, str, str, str],
    incremented_serial: str | None,
    target_version_field: str | None = "body_bank_version",
    active_skill_expression: str | None = None,
    bind_target_location: bool = True,
    prove_target: bool = True,
) -> str:
    """Render the proven Gate-2 semantic Ship-copy shape inline.

    This is a Python source renderer, not a Rhai helper or subaction. The same
    constrained x/y/z/epoch witnesses bind the old Ship, persistent target,
    and replacement Ship.
    """
    if incremented_serial not in (*SHIP_SECONDARY_SERIAL_FIELDS, None):
        raise ValueError(f"unsupported Ship serial increment: {incremented_serial}")

    next_serial_vars = {
        "claim_serial": "next_claim_serial",
        "discovery_serial": "next_discovery_serial",
        "satellite_serial": "next_ship_satellite_serial",
        "civilization_scan_serial": "next_scan_serial",
    }
    lines = ["    prove_fixed_versions(action, ship);"]
    if prove_target:
        lines.append(f"    prove_fixed_versions(action, {target_var});")
    if prove_target and target_version_field is not None:
        if target_version_field not in VERSIONS:
            raise ValueError(
                f"unknown target version field: {target_version_field}"
            )
        lines.append(
            f"    action.st_sum({target_var}.{target_version_field}, 0, "
            f"{VERSIONS[target_version_field]});"
        )
    lines.append("    var ship_id = bind_ship_id(action, ship);")
    lines.append("")
    lines.extend([
        "    var extraction_amount = unsafe { ship.extraction_amount - 0 };",
        (
            "    var rare_extraction_amount = unsafe { "
            "ship.rare_extraction_amount - 0 };"
        ),
        "    action.st_sum(ship.extraction_amount, 0, extraction_amount);",
        (
            "    action.st_sum(ship.rare_extraction_amount, 0, "
            "rare_extraction_amount);"
        ),
        "",
    ])
    lines.extend([
        "    var x = unsafe { ship.x - 0 };",
        "    var y = unsafe { ship.y - 0 };",
        "    var z = unsafe { ship.z - 0 };",
        "    var epoch = unsafe { ship.epoch - 0 };",
    ])
    for field, target_field in zip(
        ("x", "y", "z", "epoch"), target_location_fields, strict=True
    ):
        lines.append(f"    action.st_sum(ship.{field}, 0, {field});")
        if bind_target_location:
            lines.append(
                f"    action.st_sum({target_var}.{target_field}, 0, {field});"
            )

    if active_skill_expression is not None:
        lines.extend(
            [
                "",
                (
                    "    var active_skill_type = unsafe { "
                    f"{active_skill_expression} - 0 "
                    "};"
                ),
                (
                    f"    action.st_sum({active_skill_expression}, 0, "
                    "active_skill_type);"
                ),
            ]
        )

    lines.append("")
    for field in SHIP_SECONDARY_SERIAL_FIELDS:
        if field == incremented_serial:
            continue
        lines.extend(
            [
                f"    var {field} = unsafe {{ ship.{field} - 0 }};",
                f"    action.st_sum(ship.{field}, 0, {field});",
            ]
        )

    lines.extend(
        [
            "",
            "    var next_action_serial = unsafe { ship.action_serial - (0 - 1) };",
            "    action.st_sum(ship.action_serial, 1, next_action_serial);",
        ]
    )
    if incremented_serial is not None:
        next_serial = next_serial_vars[incremented_serial]
        lines.extend(
            [
                (
                    f"    var {next_serial} = unsafe {{ ship.{incremented_serial} "
                    "- (0 - 1) };"
                ),
                (
                    f"    action.st_sum(ship.{incremented_serial}, 1, "
                    f"{next_serial});"
                ),
            ]
        )

    lines.extend(
        [
        ]
    )
    field_values = {
        "schema_version": str(VERSIONS["schema_version"]),
        "mechanics_version": str(VERSIONS["mechanics_version"]),
        "universe_version": str(VERSIONS["universe_version"]),
        "extraction_amount": "extraction_amount",
        "rare_extraction_amount": "rare_extraction_amount",
        "x": "x",
        "y": "y",
        "z": "z",
        "epoch": "epoch",
        "active_skill_type": (
            "active_skill_type"
            if active_skill_expression is not None
            else "0"
        ),
        "action_serial": "next_action_serial",
        **{
            field: (
                next_serial_vars[field] if field == incremented_serial else field
            )
            for field in SHIP_SECONDARY_SERIAL_FIELDS
        },
        "ship_id": "ship_id",
    }
    lines.extend(
        [
            "",
            "    next_ship.set([",
            *[
                (
                    f'        ["{field}", {field_values[field]}]'
                    + ("," if index + 1 < len(SHIP_SEMANTIC_FIELDS) else "")
                )
                for index, field in enumerate(SHIP_SEMANTIC_FIELDS)
            ],
            "    ]);",
        ]
    )
    return "\n".join(lines)


def detect_replacement_ship_state_parts() -> tuple[str, str]:
    """Split Detect's Ship replacement where no later wrapper uses locals."""
    source = replacement_ship_state_source(
        "sector",
        ("x", "y", "z", "epoch"),
        "discovery_serial",
    )
    marker = "    var claim_serial = unsafe { ship.claim_serial - 0 };"
    prefix, finish = source.split(marker, 1)
    return prefix.rstrip(), marker + finish


def extraction_ship_state_parts(
    *,
    bind_active_skill: bool,
) -> tuple[str, str, str]:
    """Render extraction's replacement Ship with location binding delayed.

    Keeping x/y/z/epoch adjacent to the two output dictionaries avoids carrying
    four public coordinate witnesses across the pool and Raw-checkpoint block.
    """
    prefix = [
        "",
        "    var ship_id = bind_ship_id(action, ship);",
        "    var extraction_amount = unsafe { ship.extraction_amount - 0 };",
        (
            "    var rare_extraction_amount = unsafe { "
            "ship.rare_extraction_amount - 0 };"
        ),
        "    action.st_sum(ship.extraction_amount, 0, extraction_amount);",
        (
            "    action.st_sum(ship.rare_extraction_amount, 0, "
            "rare_extraction_amount);"
        ),
    ]
    if bind_active_skill:
        prefix.extend(
            [
                (
                    "    var active_skill_type = unsafe { "
                    "ship.active_skill_type - 0 };"
                ),
                (
                    "    action.st_sum("
                    "ship.active_skill_type, 0, active_skill_type);"
                ),
            ]
        )
    prefix.append("")

    values = {
        "schema_version": str(VERSIONS["schema_version"]),
        "mechanics_version": str(VERSIONS["mechanics_version"]),
        "universe_version": str(VERSIONS["universe_version"]),
        "extraction_amount": "extraction_amount",
        "rare_extraction_amount": "rare_extraction_amount",
        "x": "x",
        "y": "y",
        "z": "z",
        "epoch": "epoch",
        "active_skill_type": "0",
        "action_serial": "next_action_serial",
        "claim_serial": "claim_serial",
        "discovery_serial": "discovery_serial",
        "satellite_serial": "satellite_serial",
        "civilization_scan_serial": "civilization_scan_serial",
        "ship_id": "ship_id",
    }
    location = [
        "    var x = unsafe { ship.x - 0 };",
        "    var y = unsafe { ship.y - 0 };",
        "    var z = unsafe { ship.z - 0 };",
        "    var epoch = unsafe { ship.epoch - 0 };",
    ]
    for field, target_field in zip(
        ("x", "y", "z", "epoch"),
        ("sector_x", "sector_y", "sector_z", "sector_epoch"),
        strict=True,
    ):
        location.extend(
            [
                f"    action.st_sum(ship.{field}, 0, {field});",
                f"    action.st_sum(body.{target_field}, 0, {field});",
            ]
        )
    finish = [""]
    for field in SHIP_SECONDARY_SERIAL_FIELDS:
        finish.extend(
            [
                f"    var {field} = unsafe {{ ship.{field} - 0 }};",
                f"    action.st_sum(ship.{field}, 0, {field});",
            ]
        )
    finish.extend(
        [
            "",
            "    var next_action_serial = unsafe { ship.action_serial - (0 - 1) };",
            "    action.st_sum(ship.action_serial, 1, next_action_serial);",
        ]
    )
    finish.extend(
        [
            "    next_ship.set([",
            *[
                (
                    f'        ["{field}", {values[field]}]'
                    + ("," if index + 1 < len(SHIP_SEMANTIC_FIELDS) else "")
                )
                for index, field in enumerate(SHIP_SEMANTIC_FIELDS)
            ],
            "    ]);",
        ]
    )
    return "\n".join(prefix), "\n".join(location), "\n".join(finish)


def raw_export_checkpoint_source(
    target_var: str,
    exports: tuple[tuple[str, str], ...],
) -> str:
    """Bind Raw fields exported from a Mutate target without weakening them.

    The installed SDK has no direct Raw Equal statement. A same-value
    ContainerUpdate exposes each field as a plain witness, while paired U256
    inequalities before and after all of those updates prove that the target
    dictionary commitment did not change. This preserves every checkpointed
    field across the bridge. Later semantic updates remain outside the
    checkpoint.
    """
    start, finish = raw_export_checkpoint_parts(target_var, exports)
    return f"{start}\n{finish}"


def raw_export_checkpoint_parts(
    target_var: str,
    exports: tuple[tuple[str, str], ...],
) -> tuple[str, str]:
    """Render a Raw export checkpoint in two statement-ordering phases."""
    checkpoint = f"{target_var}_raw_export_checkpoint"
    start_lines = [
        f"    var {checkpoint} = action.random();",
        f"    var_assign({checkpoint}, {target_var});",
        f"    action.intro_lt_eq_u256({target_var}, {checkpoint});",
        f"    action.intro_lt_eq_u256({checkpoint}, {target_var});",
        "",
    ]
    for field, witness in exports:
        start_lines.extend(
            [
                f"    var {witness} = action.random();",
                f"    var_assign({witness}, {target_var}.{field});",
                f'    {target_var}.update("{field}", {witness});',
            ]
        )
    finish_lines = [
        f"    action.intro_lt_eq_u256({target_var}, {checkpoint});",
        f"    action.intro_lt_eq_u256({checkpoint}, {target_var});",
    ]
    return "\n".join(start_lines), "\n".join(finish_lines)


def recipe_input_source(recipe: list[dict[str, Any]]) -> tuple[str, str]:
    declarations: list[str] = []
    constraints: list[str] = []
    for index, ingredient in enumerate(recipe, start=1):
        handle = f"ingredient_{index}_{ingredient['slug'].lower()}"
        declarations.append(
            f'    var {handle} = action.input("{RESOURCE}");'
        )
        constraints.extend(
            [
                (
                    f"    action.st_sum({handle}.resource_type, 0, "
                    f"{ingredient['resource_code']});"
                ),
                (
                    f"    action.st_sum({handle}.amount, 0, "
                    f"{ingredient['amount']});"
                ),
            ]
        )
    return "\n".join(declarations), "\n".join(constraints)


def ship_initial_state_source(
    ship_var: str,
    tier: dict[str, Any],
    *,
    x: str = str(COORD_ZERO),
    y: str = str(COORD_ZERO),
    z: str = str(COORD_ZERO),
    epoch: str = "0",
    vdf_iterations: int | None = None,
    apply_vdf: bool = True,
) -> str:
    vdf = tier["build_vdf"] if vdf_iterations is None else vdf_iterations
    vdf_source = (
        f"""
    var work = action.intro_vdf({vdf}, {ship_var});
    {ship_var}.update("work", work);"""
        if apply_vdf
        else ""
    )
    return f"""    var ship_id = action.random();
    {ship_var}.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["extraction_amount", {tier['extraction_amount']}],
        ["rare_extraction_amount", {tier['rare_extraction_amount']}],
        ["x", {x}],
        ["y", {y}],
        ["z", {z}],
        ["epoch", {epoch}],
        ["active_skill_type", 0],
        ["action_serial", 0],
        ["claim_serial", 0],
        ["discovery_serial", 0],
        ["satellite_serial", 0],
        ["civilization_scan_serial", 0],
        ["ship_id", ship_id]
    ]);{vdf_source}"""


def build_ship_source(tier: dict[str, Any]) -> str:
    if tier["name"] == "Small":
        return f"""
fn BuildShipSmall(action) {{
    var ship = action.output("{SHIP}");
{ship_initial_state_source("ship", tier)}
}}
"""

    recipe = (
        MEDIUM_SHIP_RECIPE
        if tier["name"] == "Medium"
        else LARGE_SHIP_RECIPE
    )
    declarations, constraints = recipe_input_source(recipe)
    permit_declaration = ""
    permit_constraints = ""
    location = {
        "x": str(COORD_ZERO),
        "y": str(COORD_ZERO),
        "z": str(COORD_ZERO),
        "epoch": "0",
    }
    if tier["name"] == "Large":
        permit_declaration = (
            f'    var permit = action.input("{SHIPYARD_PERMIT}");\n'
        )
        permit_constraints = f"""    prove_fixed_versions(action, permit);
    action.st_sum(permit.permit_type, 0, 1);
    action.st_sum(permit.industrial_authorized, 0, 1);
    action.st_sum(permit.electronics_authorized, 0, 1);
    action.st_sum(permit.molecular_authorized, 0, 1);
    var build_x = unsafe {{ permit.x - 0 }};
    var build_y = unsafe {{ permit.y - 0 }};
    var build_z = unsafe {{ permit.z - 0 }};
    var build_epoch = unsafe {{ permit.epoch - 0 }};
    action.st_sum(permit.x, 0, build_x);
    action.st_sum(permit.y, 0, build_y);
    action.st_sum(permit.z, 0, build_z);
    action.st_sum(permit.epoch, 0, build_epoch);
"""
        location = {
            "x": "build_x",
            "y": "build_y",
            "z": "build_z",
            "epoch": "build_epoch",
        }
    return f"""
fn BuildShip{tier['name']}(action) {{
    var ship = action.output("{SHIP}");
{permit_declaration}{declarations}
{permit_constraints}{constraints}
{ship_initial_state_source("ship", tier, **location)}
}}
"""


def movement_source(
    axis: str,
    positive: bool,
    name: str | None = None,
    tier: dict[str, Any] | None = None,
) -> str:
    axis_field = axis.lower()
    direction = "Positive" if positive else "Negative"
    action_name = name or f"Move{direction}{axis}"
    phase6_route = phase6_movement_route_for(action_name)
    if phase6_route:
        if tier is None:
            raise ValueError(f"Phase 6 movement canary requires a ship tier: {action_name}")
        movement_helper, vdf_helper = phase6_route
        return f"""
fn {action_name}(action) {{
    var ship = action.mutate("{SHIP}");
    {movement_helper}(action, ship, ship.{axis_field}, "{axis_field}", {tier['move']}, {tier['extraction_amount']}, {tier['rare_extraction_amount']});
    {vdf_helper}(action, ship);
}}
"""
    if positive:
        step_expression = (
            str(tier["move"]) if tier is not None else "1"
        )
        arithmetic = f"""    var next_coordinate = unsafe {{ ship.{axis_field} - (0 - {step_expression}) }};
    action.st_sum(ship.{axis_field}, {step_expression}, next_coordinate);"""
    else:
        step_expression = (
            str(tier["move"]) if tier is not None else "1"
        )
        arithmetic = f"""    var next_coordinate = unsafe {{ ship.{axis_field} - {step_expression} }};
    action.st_sum(next_coordinate, {step_expression}, ship.{axis_field});"""
    tier_constraints = ""
    vdf = ""
    if tier is not None:
        tier_constraints = f"""    action.st_sum(ship.extraction_amount, 0, {tier['extraction_amount']});
    action.st_sum(ship.rare_extraction_amount, 0, {tier['rare_extraction_amount']});
"""
        vdf = f"""    var next_work = action.intro_vdf({tier['move_vdf']}, ship);
    ship.update("work", next_work);
"""
    return f"""
fn {action_name}(action) {{
    var ship = action.mutate("{SHIP}");
{tier_constraints}{arithmetic}
    action.st_gt(next_coordinate, 0);
    action.st_gt({COORD_UPPER_BOUND}, next_coordinate);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    ship.update("{axis_field}", next_coordinate);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_ship_key = action.random();
    rotate_key(ship, next_ship_key);
{vdf}}}
"""


def timewarp_source(tier: dict[str, Any]) -> str:
    action_name = f"TimeWarp{tier['name']}"
    phase6_route = phase6_movement_route_for(action_name)
    if phase6_route:
        epoch_helper, vdf_helper = phase6_route
        return f"""
fn {action_name}(action) {{
    var ship = action.mutate("{SHIP}");
    action.st_sum(ship.extraction_amount, 0, {tier['extraction_amount']});
    action.st_sum(ship.rare_extraction_amount, 0, {tier['rare_extraction_amount']});
    var next_epoch = unsafe {{ ship.epoch - (0 - {tier['timewarp']}) }};
    action.st_sum(ship.epoch, {tier['timewarp']}, next_epoch);
    {epoch_helper}(action, ship, next_epoch);
    {vdf_helper}(action, ship);
}}
"""
    return f"""
fn {action_name}(action) {{
    var ship = action.mutate("{SHIP}");
    action.st_sum(ship.extraction_amount, 0, {tier['extraction_amount']});
    action.st_sum(ship.rare_extraction_amount, 0, {tier['rare_extraction_amount']});
    var next_epoch = unsafe {{ ship.epoch - (0 - {tier['timewarp']}) }};
    action.st_sum(ship.epoch, {tier['timewarp']}, next_epoch);
    action.st_gt({EPOCH_UPPER_BOUND}, next_epoch);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    ship.update("epoch", next_epoch);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_ship_key = action.random();
    rotate_key(ship, next_ship_key);
    var next_work = action.intro_vdf({tier['timewarp_vdf']}, ship);
    ship.update("work", next_work);
}}
"""


def claim_source() -> str:
    sector_defaults = "\n".join(
        [
            f'        ["{field}", 0],'
            for field in (
                "sector_type",
                "survey_profile",
                *(
                    category["remaining_field"]
                    for category in CELESTIAL_CATEGORIES
                ),
                *(
                    category["serial_field"]
                    for category in CELESTIAL_CATEGORIES
                ),
            )
        ]
    )
    return f"""
fn ClaimSector(action) {{
    var sector = action.output("{SECTOR}");
    var ship = action.mutate("{SHIP}");
    prove_fixed_versions(action, ship);
    var sector_x = unsafe {{ ship.x - 0 }};
    var sector_y = unsafe {{ ship.y - 0 }};
    var sector_z = unsafe {{ ship.z - 0 }};
    var sector_epoch = unsafe {{ ship.epoch - 0 }};
    action.st_sum(ship.x, 0, sector_x);
    action.st_sum(ship.y, 0, sector_y);
    action.st_sum(ship.z, 0, sector_z);
    action.st_sum(ship.epoch, 0, sector_epoch);
    sector.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["body_bank_version", {VERSIONS['body_bank_version']}],
        ["x", sector_x],
        ["y", sector_y],
        ["z", sector_z],
        ["epoch", sector_epoch],
{sector_defaults}
        ["revision", 0]
    ]);
    let zero = action.top_limb_u256(0);
    sector.update("key", zero);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    var next_claim_serial = unsafe {{ ship.claim_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    action.st_sum(ship.claim_serial, 1, next_claim_serial);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    ship.update("claim_serial", next_claim_serial);
    var next_ship_key = action.random();
    ship.update("key", next_ship_key);
}}
"""


def survey_source(profile: dict[str, Any]) -> str:
    name = f"SurveySector_{profile['code']:02d}_{profile['slug']}"
    empty_sector_constraints = "\n".join(
        [
            f"    action.st_sum(sector.{field}, 0, 0);"
            for field in (
                "sector_type",
                "survey_profile",
                *(
                    category["remaining_field"]
                    for category in CELESTIAL_CATEGORIES
                ),
                *(
                    category["serial_field"]
                    for category in CELESTIAL_CATEGORIES
                ),
            )
        ]
    )
    initial_constraints = "    prove_empty_survey_sector_core(action, sector);"
    count_updates = "\n".join(
        [
            f'    sector.update("{category["remaining_field"]}", '
            f'{profile["counts"].get(category["remaining_field"], 0)});'
            for category in CELESTIAL_CATEGORIES
            if profile["counts"].get(category["remaining_field"], 0) != 0
        ]
    )
    selector_constraints = selector_constraints_source(
        "sector",
        survey_selector_bands()[profile["code"]],
        prefix="survey_selector",
    )
    return f"""
fn {name}(action) {{
    var next_ship = action.output("{SHIP}");
    var ship = action.input("{SHIP}");
    var sector = action.mutate("{SECTOR}");
{selector_constraints}
    survey_replacement_ship_core(action, next_ship, ship, sector);
    action.st_gt(ship.claim_serial, {profile['minimum_claim_serial'] - 1});

{initial_constraints}
    var next_sector_revision = unsafe {{ sector.revision - (0 - 1) }};
    action.st_sum(sector.revision, 1, next_sector_revision);

    sector.update("sector_type", {SECTOR_TYPE_CELESTIAL});
    sector.update("survey_profile", {profile['code']});
{count_updates}
    sector.update("revision", next_sector_revision);
    var next_sector_key = action.random();
    rotate_key(sector, next_sector_key);
}}

"""


def detect_source(candidate: dict[str, Any]) -> str:
    name = f"DetectCelestialSignal_{candidate['code']:02d}_{candidate['slug']}"
    category = celestial_category(candidate)
    remaining_field = category["remaining_field"]
    serial_field = category["serial_field"]
    return f"""
fn {name}(action) {{
    var next_ship = action.output("{SHIP}");
    var signal = action.output("{SIGNAL}");
    var ship = action.input("{SHIP}");
    var sector = action.mutate("{SECTOR}");
detect_signal_core(action, next_ship, signal, ship, sector, {category['code']}, {UNRESOLVED_CANDIDATE_CODE}, "{remaining_field}", "{serial_field}");
}}
"""


def scan_source(
    candidate: dict[str, Any],
    bank: list[dict[str, Any]] | None = None,
) -> str:
    name = f"ScanCelestialBody_{candidate['code']:02d}_{candidate['slug']}"
    category = celestial_category(candidate)
    selector_constraints = selector_constraints_source(
        "signal",
        body_selector_bands(BODY_BANK if bank is None else bank)[
            candidate["code"]
        ],
        prefix="body_selector",
    )
    return f"""
fn {name}(action) {{
    var body = action.output("{BODY}");
    var signal = action.input("{SIGNAL}");
    var ship = action.mutate("{SHIP}");
{selector_constraints}
    scan_body_core(action, body, signal, ship, {category['code']}, {candidate['code']}, {candidate['body_type']}, {candidate['life_stat']}, {candidate['matter']}, {candidate['crystal']}, {candidate['gas']}, {candidate['energy']}, {candidate['satellites']});
}}
"""


def composite_child_amounts(
    child_allocations: list[dict[str, Any]],
    extraction_amount: int,
    *,
    route_name: str,
    ship_tier_name: str,
) -> tuple[int, int, int]:
    """Return three exact integer child pools for one fixed extraction action."""
    if len(child_allocations) != 3:
        raise ValueError(
            f"{route_name} must have exactly three child allocations"
        )
    ordered = sorted(child_allocations, key=lambda item: item["slot"])
    if [item["slot"] for item in ordered] != [1, 2, 3]:
        raise ValueError(
            f"{route_name} child slots must be exactly 1, 2, and 3"
        )
    weights = [item["allocation_per_1000_units"] for item in ordered]
    if any(not isinstance(weight, int) or weight <= 0 for weight in weights):
        raise ValueError(
            f"{route_name} child allocations must be positive integers"
        )
    if sum(weights) != 1_000:
        raise ValueError(
            f"{route_name} child allocations must sum to 1000"
        )
    numerators = [extraction_amount * weight for weight in weights]
    if any(numerator % 1_000 != 0 for numerator in numerators):
        raise ValueError(
            f"{route_name} split {weights} is not exactly representable "
            f"by {ship_tier_name} extraction amount {extraction_amount}"
        )
    amounts = tuple(numerator // 1_000 for numerator in numerators)
    if any(amount <= 0 for amount in amounts):
        raise ValueError(
            f"{route_name} produces an empty child pool for {ship_tier_name}"
        )
    if sum(amounts) != extraction_amount:
        raise ValueError(f"{route_name} child allocation does not conserve units")
    return amounts


def extract_source(
    resource_name: str,
    resource_type: int,
    field: str,
    vdf_iterations: int | None,
    *,
    action_name: str | None = None,
    selector_route_action: str | None = None,
    candidate: dict[str, Any] | None = None,
    child_allocations: list[dict[str, Any]] | None = None,
    skill_code: int | None = None,
    minimum_ship_tier: int = 0,
    ship_tier: dict[str, Any] | None = None,
) -> str:
    rendered_action_name = action_name or f"Extract{resource_name}"
    allocations = child_allocations or []
    output_class = COMPOSITE_RESOURCE if allocations else RESOURCE
    output_var = "composite_resource" if allocations else "resource"
    selected_tier = ship_tier or SHIP_TIERS[minimum_ship_tier]
    extraction_amount_literal = selected_tier["extraction_amount"]
    rare_amount_literal = selected_tier["rare_extraction_amount"]
    candidate_gate = ""
    selector_constraints = ""
    if candidate is not None:
        candidate_gate = (
            f"    action.st_sum(body.candidate_code, 0, "
            f"{candidate['code']});\n"
        )
        selector_constraints = selector_constraints_source(
            "body.source_signal_identifier",
            resource_selector_bands()[
                selector_route_action or rendered_action_name
            ],
            prefix="resource_selector",
        )
        if selector_constraints:
            selector_constraints += "\n"
    active_skill_literal = skill_code if skill_code is not None else 0
    skill_gate = (
        f"    action.st_sum(ship.active_skill_type,0,"
        f"{active_skill_literal});\n"
    )
    helper_kind = (
        "composite" if allocations else "body" if candidate is not None else "base"
    )
    phase4_helper = phase4_helper_for(rendered_action_name, helper_kind, vdf_iterations)
    if allocations:
        (
            child_1_amount_literal,
            child_2_amount_literal,
            child_3_amount_literal,
        ) = composite_child_amounts(
            allocations,
            extraction_amount_literal,
            route_name=rendered_action_name,
            ship_tier_name=selected_tier["name"],
        )
        core_call = (
            "    extract_composite_resource_core(\n"
            "action,\n"
            "next_ship,\n"
            "composite_resource,\n"
            "ship,\n"
            "body,\n"
            f'"{field}",\n'
            f"{resource_type},\n"
            f"{extraction_amount_literal},\n"
            f"{rare_amount_literal},\n"
            f"{child_1_amount_literal},\n"
            f"{child_2_amount_literal},\n"
            f"{child_3_amount_literal}\n"
            "    );"
        )
    else:
        core_call = (
            "    extract_direct_resource_core(\n"
            "action,\n"
            "next_ship,\n"
            "resource,\n"
            "ship,\n"
            "body,\n"
            f'"{field}",\n'
            f"{resource_type},\n"
            f"{extraction_amount_literal},\n"
            f"{rare_amount_literal}\n"
            "    );"
        )
    if phase4_helper is not None:
        if helper_kind == "base":
            core_call = (
                f"    {phase4_helper}(\n"
                "        action, next_ship, resource, ship, body,\n"
                f"        {active_skill_literal}, \"{field}\", {resource_type},\n"
                f"        {extraction_amount_literal}, {rare_amount_literal}\n"
                "    );"
            )
        elif helper_kind == "body":
            assert candidate is not None
            core_call = (
                f"    {phase4_helper}(\n"
                "        action, next_ship, resource, ship, body,\n"
                f"        {candidate['code']}, {active_skill_literal}, \"{field}\",\n"
                f"        {resource_type}, {extraction_amount_literal}, "
                f"{rare_amount_literal}\n"
                "    );"
            )
        else:
            assert candidate is not None
            core_call = (
                f"    {phase4_helper}(\n"
                "        action, next_ship, composite_resource, ship, body,\n"
                f"        {candidate['code']}, {active_skill_literal}, \"{field}\",\n"
                f"        {resource_type}, {extraction_amount_literal}, "
                f"{rare_amount_literal}, {child_1_amount_literal}, "
                f"{child_2_amount_literal}, {child_3_amount_literal}\n"
                "    );"
            )
        candidate_gate = ""
        skill_gate = ""
    wrapper_vdf = ""
    if vdf_iterations is not None and phase4_helper is None:
        wrapper_vdf = (
            f"\n    var next_work = action.intro_vdf("
            f"{vdf_iterations}, body);\n"
            '    body.update("work", next_work);'
        )
    return f"""
fn {rendered_action_name}(action) {{
    var next_ship = action.output("{SHIP}");
    var {output_var} = action.output("{output_class}");
    var ship = action.input("{SHIP}");
    var body = action.mutate("{BODY}");
{selector_constraints}{candidate_gate}{skill_gate}{core_call}{wrapper_vdf}
}}
"""


def refine_resource_source(
    route: dict[str, Any],
    parent_resource_code: int,
) -> str:
    child_remaining_field = f"child_{route['child_slot']}_remaining"
    phase4_helper = phase4_helper_for(route["action"], "refine", route["vdf_iterations"])
    vdf_source = ""
    if route["vdf_iterations"] is not None and phase4_helper is None:
        vdf_source = f"""
    var next_work = action.intro_vdf({route['vdf_iterations']}, parent);
    parent.update("work", next_work);"""
    core_name = phase4_helper or "refine_resource_core"
    return f"""
fn {route['action']}(action) {{
    var next_ship = action.output("{SHIP}");
    var resource = action.output("{RESOURCE}");
    var ship = action.input("{SHIP}");
    var parent = action.mutate("{COMPOSITE_RESOURCE}");
    {core_name}(
        action,
        next_ship,
        resource,
        ship,
        parent,
        {route['skill_code']},
        {parent_resource_code},
        "{child_remaining_field}",
        {route['resource_code']}
    );{vdf_source}
}}
"""


def fabricate_component_source(
    component: dict[str, Any],
    *,
    final_use: bool,
) -> str:
    mode = "final" if final_use else "reusable"
    action_name = component["actions"][mode]
    catalyst_role = "input" if final_use else "mutate"
    catalyst_helper = (
        "consume_component_catalyst_final_core"
        if final_use
        else "consume_component_catalyst_reusable_core"
    )
    materials = component["materials"]
    phase5_helper = phase5_helper_for(action_name)
    if phase5_helper is not None:
        return f"""
fn {action_name}(action) {{
    var n = action.output("{SHIP}");
    var c = action.output("{RESOURCE}");
    var s = action.input("{SHIP}");
    var a = action.input("{RESOURCE}");
    var b = action.input("{RESOURCE}");
    var d = action.input("{RESOURCE}");
    var k = action.{catalyst_role}("{RESOURCE}");
    {phase5_helper}(
        action, n, c, s, a, b, d, k,
        {component['skill_code']},
        {materials[0]['resource_code']}, {materials[0]['amount']},
        {materials[1]['resource_code']}, {materials[1]['amount']},
        {materials[2]['resource_code']}, {materials[2]['amount']},
        {component['catalyst']['resource_code']},
        {component['code']}, {component['output_amount']}
    );
}}
"""
    vdf_source = f"""
    var w = action.intro_vdf(
        {component['vdf_iterations']}, c
    );
    c.update("work", w);"""
    return f"""
fn {action_name}(action) {{
    var n = action.output("{SHIP}");
    var c = action.output("{RESOURCE}");
    var s = action.input("{SHIP}");
    var a = action.input("{RESOURCE}");
    var b = action.input("{RESOURCE}");
    var d = action.input("{RESOURCE}");
    var k = action.{catalyst_role}("{RESOURCE}");
    fabricate_component_core(
        action,
        n,
        c,
        s,
        a,
        b,
        d,
        k,
        {component['skill_code']},
        {materials[0]['resource_code']},
        {materials[0]['amount']},
        {materials[1]['resource_code']},
        {materials[1]['amount']},
        {materials[2]['resource_code']},
        {materials[2]['amount']},
        {component['catalyst']['resource_code']},
        {component['code']},
        {component['output_amount']}
    );
    {catalyst_helper}(action, k);{vdf_source}
}}
"""


def satellite_source() -> str:
    return f"""
fn DiscoverSatellite(action) {{
    var next_ship = action.output("{SHIP}");
    var satellite = action.output("{SATELLITE}");
    var ship = action.input("{SHIP}");
    var body = action.mutate("{BODY}");
{replacement_ship_state_source("body", ("sector_x", "sector_y", "sector_z", "sector_epoch"), "satellite_serial")}

    action.st_gt(body.satellites_remaining, 0);
    var next_remaining = unsafe {{ body.satellites_remaining - 1 }};
    action.st_sum(next_remaining, 1, body.satellites_remaining);
    var next_satellite_serial = unsafe {{ body.next_satellite_serial - (0 - 1) }};
    action.st_sum(body.next_satellite_serial, 1, next_satellite_serial);
    var parent_body_identifier = action.random();
    var_assign(parent_body_identifier, body.stable_identifier);
    body.update("stable_identifier", parent_body_identifier);
    satellite.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["parent_body_identifier", parent_body_identifier],
        ["sector_x", x],
        ["sector_y", y],
        ["sector_z", z],
        ["sector_epoch", epoch],
        ["satellite_serial", next_satellite_serial]
    ]);
    let zero = action.top_limb_u256(0);
    satellite.update("key", zero);
    body.update("satellites_remaining", next_remaining);
    body.update("next_satellite_serial", next_satellite_serial);
    var next_body_key = action.random();
    rotate_key(body, next_body_key);
}}
"""


def detect_intelligent_life_source(
    bank: list[dict[str, Any]] | None = None,
) -> str:
    selector_constraints = selector_constraints_source(
        "body.source_signal_identifier",
        intelligent_life_selector_band(BODY_BANK if bank is None else bank),
        prefix="life_selector",
    )
    return f"""
fn DetectIntelligentLife(action) {{
    var next_ship = action.output("{SHIP}");
    var life_signal = action.output("{LIFE_SIGNAL}");
    var ship = action.input("{SHIP}");
    var body = action.mutate("{BODY}");
{replacement_ship_state_source("body", ("sector_x", "sector_y", "sector_z", "sector_epoch"), "civilization_scan_serial")}

{selector_constraints}
    action.st_sum(body.body_type, 0, 1);
    action.st_sum(body.life_stat, 0, 0);
    action.st_sum(body.civilization_discovered, 0, 0);
    var source_body_identifier = action.random();
    var_assign(source_body_identifier, body.stable_identifier);
    body.update("stable_identifier", source_body_identifier);
    life_signal.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["civilization_version", {VERSIONS['civilization_version']}],
        ["source_body_identifier", source_body_identifier],
        ["sector_x", x],
        ["sector_y", y],
        ["sector_z", z],
        ["origin_epoch", epoch]
    ]);
    let zero = action.top_limb_u256(0);
    life_signal.update("key", zero);
    body.update("life_stat", 1);
    body.update("civilization_discovered", 1);
    var next_body_key = action.random();
    rotate_key(body, next_body_key);
}}
"""


def materialize_civilization_source(
    civilization_type: dict[str, Any],
) -> str:
    selector_constraints = selector_constraints_source(
        "life_signal",
        civilization_selector_bands()[civilization_type["code"]],
        prefix="civilization_selector",
    )
    return f"""
fn {civilization_type['action']}(action) {{
    var civilization = action.output("{CIVILIZATION}");
    var life_signal = action.input("{LIFE_SIGNAL}");
    var ship = action.mutate("{SHIP}");
{selector_constraints}
    prove_fixed_versions(action, life_signal);
    prove_fixed_versions(action, ship);
    action.st_sum(life_signal.civilization_version, 0, {VERSIONS['civilization_version']});
    action.st_gt(
        ship.civilization_scan_serial,
        {civilization_type['minimum_civilization_scan_serial'] - 1}
    );

    var sector_x = unsafe {{ life_signal.sector_x - 0 }};
    var sector_y = unsafe {{ life_signal.sector_y - 0 }};
    var sector_z = unsafe {{ life_signal.sector_z - 0 }};
    var origin_epoch = unsafe {{ life_signal.origin_epoch - 0 }};
    action.st_sum(life_signal.sector_x, 0, sector_x);
    action.st_sum(life_signal.sector_y, 0, sector_y);
    action.st_sum(life_signal.sector_z, 0, sector_z);
    action.st_sum(life_signal.origin_epoch, 0, origin_epoch);
    action.st_sum(ship.x, 0, sector_x);
    action.st_sum(ship.y, 0, sector_y);
    action.st_sum(ship.z, 0, sector_z);
    action.st_sum(ship.epoch, 0, origin_epoch);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);

    var source_life_signal_identifier = action.random();
    var_assign(
        source_life_signal_identifier,
        life_signal.stable_identifier
    );
    life_signal.update(
        "stable_identifier",
        source_life_signal_identifier
    );
    civilization.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["civilization_version", {VERSIONS['civilization_version']}],
        ["source_life_signal_identifier", source_life_signal_identifier],
        ["sector_x", sector_x],
        ["sector_y", sector_y],
        ["sector_z", sector_z],
        ["origin_epoch", origin_epoch],
        ["civilization_type", {civilization_type['code']}]
    ]);
    let zero = action.top_limb_u256(0);
    civilization.update("key", zero);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_ship_key = action.random();
    rotate_key(ship, next_ship_key);
}}
"""


def develop_technology_skill_source(skill: dict[str, Any]) -> str:
    selector_constraints = selector_constraints_source(
        "civilization.source_life_signal_identifier",
        technology_skill_selector_bands()[skill["code"]],
        prefix="skill_selector",
    )
    return f"""
fn {skill['action']}(action) {{
    var next_ship = action.output("{SHIP}");
    var technology_skill = action.output("{TECHNOLOGY_SKILL}");
    var ship = action.input("{SHIP}");
    var civilization = action.mutate("{CIVILIZATION}");
{selector_constraints}
    develop_technology_skill_core(
        action,
        next_ship,
        technology_skill,
        ship,
        civilization,
        {skill['civilization_type']},
        {skill['code']},
        {skill['reusable']}
    );
}}
"""


def develop_derived_skill_source(skill: dict[str, Any]) -> str:
    phase5_helper = phase5_helper_for(skill["action"])
    evidence_declarations = "\n".join(
        f'    var evidence_{item["slot"]} = action.input("{RESOURCE}");'
        for item in skill["items"]
    )
    evidence_gates = "\n".join(
        (
            f"    prove_resource_stack_core(action, evidence_{item['slot']}, "
            f"{item['resource_code']}, {item['amount']});"
        )
        for item in skill["items"]
    )
    if phase5_helper is not None:
        evidence_handles = ", ".join(
            f"evidence_{item['slot']}" for item in skill["items"]
        )
        evidence_literals = ", ".join(
            f"{item['resource_code']}, {item['amount']}"
            for item in skill["items"]
        )
        return f"""
fn {skill['action']}(action) {{
    var next_ship = action.output("{SHIP}");
    var technology_skill = action.output("{TECHNOLOGY_SKILL}");
    var ship = action.input("{SHIP}");
{evidence_declarations}
    {phase5_helper}(
        action, next_ship, technology_skill, ship, {evidence_handles},
        {skill['parent_code']}, {skill['code']}, {evidence_literals}
    );
}}
"""
    return f"""
fn {skill['action']}(action) {{
    var next_ship = action.output("{SHIP}");
    var technology_skill = action.output("{TECHNOLOGY_SKILL}");
    var ship = action.input("{SHIP}");
{evidence_declarations}
    develop_derived_skill_core(
        action,
        next_ship,
        technology_skill,
        ship,
        {skill['parent_code']},
        {skill['code']}
    );
{evidence_gates}
    var skill_work = action.intro_vdf(
        {skill['vdf_iterations']}, technology_skill
    );
    technology_skill.update("work", skill_work);
}}
"""


def capability_artifact_source(capability: dict[str, Any]) -> str:
    phase5_helper = phase5_helper_for(capability["action"])
    evidence_declarations = "\n".join(
        f'    var evidence_{index} = action.input("{RESOURCE}");'
        for index, _item in enumerate(capability["fixed_inputs"], start=1)
    )
    evidence_gates = "\n".join(
        (
            f"    prove_resource_stack_core(action, evidence_{index}, "
            f"{item['resource_code']}, {item['amount']});"
        )
        for index, item in enumerate(capability["fixed_inputs"], start=1)
    )
    if phase5_helper is not None:
        evidence_handles = ", ".join(
            f"evidence_{index}"
            for index, _item in enumerate(capability["fixed_inputs"], start=1)
        )
        evidence_literals = ", ".join(
            f"{item['resource_code']}, {item['amount']}"
            for item in capability["fixed_inputs"]
        )
        return f"""
fn {capability['action']}(action) {{
    var next_ship = action.output("{SHIP}");
    var artifact = action.output("{RESOURCE}");
    var ship = action.input("{SHIP}");
{evidence_declarations}
    {phase5_helper}(
        action, next_ship, artifact, ship, {evidence_handles},
        {capability['skill_code']}, {capability['output_resource_code']},
        {capability['output_amount']}, {evidence_literals}
    );
}}
"""
    return f"""
fn {capability['action']}(action) {{
    var next_ship = action.output("{SHIP}");
    var artifact = action.output("{RESOURCE}");
    var ship = action.input("{SHIP}");
{evidence_declarations}
    produce_capability_artifact_core(
        action,
        next_ship,
        artifact,
        ship,
        {capability['skill_code']},
        {capability['output_resource_code']},
        {capability['output_amount']}
    );
{evidence_gates}
    var artifact_work = action.intro_vdf(
        {capability['vdf_iterations']}, artifact
    );
    artifact.update("work", artifact_work);
}}
"""


def use_technology_skill_source() -> str:
    return f"""
fn UseTechnologySkill(action) {{
    var next_ship = action.output("{SHIP}");
    var ship = action.input("{SHIP}");
    var technology_skill = action.mutate("{TECHNOLOGY_SKILL}");
{replacement_ship_state_source(
    "technology_skill",
    ("sector_x", "sector_y", "sector_z", "origin_epoch"),
    None,
    "civilization_version",
    "technology_skill.skill_type",
    False,
)}

    action.st_sum(technology_skill.reusable, 0, 1);
    var next_skill_key = action.random();
    rotate_key(technology_skill, next_skill_key);
}}
"""


def create_large_ship_permit_source() -> str:
    return f"""
fn CreateLargeShipConstructionPermit(action) {{
    var permit = action.output("{SHIPYARD_PERMIT}");
    var ship = action.mutate("{SHIP}");
    prove_fixed_versions(action, ship);
    var x = unsafe {{ ship.x - 0 }};
    var y = unsafe {{ ship.y - 0 }};
    var z = unsafe {{ ship.z - 0 }};
    var epoch = unsafe {{ ship.epoch - 0 }};
    action.st_sum(ship.x, 0, x);
    action.st_sum(ship.y, 0, y);
    action.st_sum(ship.z, 0, z);
    action.st_sum(ship.epoch, 0, epoch);
    permit.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["permit_type", 1],
        ["x", x],
        ["y", y],
        ["z", z],
        ["epoch", epoch],
        ["industrial_authorized", 0],
        ["electronics_authorized", 0],
        ["molecular_authorized", 0]
    ]);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_ship_key = action.random();
    rotate_key(ship, next_ship_key);
}}
"""


def authorize_large_ship_permit_source(skill: dict[str, Any]) -> str:
    return f"""
fn AuthorizeLargeShip{skill['slug']}(action) {{
    var next_ship = action.output("{SHIP}");
    var ship = action.input("{SHIP}");
    var permit = action.mutate("{SHIPYARD_PERMIT}");
    authorize_large_ship_permit_core(
        action,
        next_ship,
        ship,
        permit,
        {skill['skill_code']},
        "{skill['field']}"
    );
}}
"""


def issue_auxiliary_ship_permit_source() -> str:
    return f"""
fn IssueAuxiliaryShipPermit(action) {{
    var permit = action.output("{SHIPYARD_PERMIT}");
    var ship = action.mutate("{SHIP}");
    prove_fixed_versions(action, ship);
    action.st_sum(ship.extraction_amount, 0, 250);
    action.st_sum(ship.rare_extraction_amount, 0, 25);
    var permit_x = unsafe {{ ship.x - 0 }};
    var permit_y = unsafe {{ ship.y - 0 }};
    var permit_z = unsafe {{ ship.z - 0 }};
    var permit_epoch = unsafe {{ ship.epoch - 0 }};
    action.st_sum(ship.x, 0, permit_x);
    action.st_sum(ship.y, 0, permit_y);
    action.st_sum(ship.z, 0, permit_z);
    action.st_sum(ship.epoch, 0, permit_epoch);
    permit.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["permit_type", 2],
        ["x", permit_x],
        ["y", permit_y],
        ["z", permit_z],
        ["epoch", permit_epoch],
        ["industrial_authorized", 0],
        ["electronics_authorized", 0],
        ["molecular_authorized", 0]
    ]);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_ship_key = action.random();
    rotate_key(ship, next_ship_key);
}}
"""


def assemble_auxiliary_ship_kit_source(
    tier_name: str,
    recipe: list[dict[str, Any]],
) -> str:
    declarations, constraints = recipe_input_source(recipe)
    kit_type = 3 if tier_name == "Small" else 4
    tier = next(tier for tier in SHIP_TIERS if tier["name"] == tier_name)
    auxiliary_vdf = tier["build_vdf"] * 2
    return f"""
fn AssembleAuxiliaryShip{tier_name}Kit(action) {{
    var kit = action.output("{SHIPYARD_PERMIT}");
    var permit = action.input("{SHIPYARD_PERMIT}");
{declarations}
    prove_fixed_versions(action, permit);
    action.st_sum(permit.permit_type, 0, 2);
{constraints}
    var build_x = unsafe {{ permit.x - 0 }};
    var build_y = unsafe {{ permit.y - 0 }};
    var build_z = unsafe {{ permit.z - 0 }};
    var build_epoch = unsafe {{ permit.epoch - 0 }};
    action.st_sum(permit.x, 0, build_x);
    action.st_sum(permit.y, 0, build_y);
    action.st_sum(permit.z, 0, build_z);
    action.st_sum(permit.epoch, 0, build_epoch);
    kit.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["permit_type", {kit_type}],
        ["x", build_x],
        ["y", build_y],
        ["z", build_z],
        ["epoch", build_epoch],
        ["industrial_authorized", 0],
        ["electronics_authorized", 0],
        ["molecular_authorized", 0]
    ]);
}}
"""


def build_auxiliary_ship_source(
    tier: dict[str, Any],
    recipe: list[dict[str, Any]],
) -> str:
    auxiliary_vdf = tier["build_vdf"] * 2
    declarations, constraints = recipe_input_source(recipe)
    return f"""
fn BuildAuxiliaryShip{tier['name']}(action) {{
    var child_ship = action.output("{SHIP}");
    var permit = action.input("{SHIPYARD_PERMIT}");
{declarations}
    prove_fixed_versions(action, permit);
    action.st_sum(permit.permit_type, 0, 2);
{constraints}
    var build_x = unsafe {{ permit.x - 0 }};
    var build_y = unsafe {{ permit.y - 0 }};
    var build_z = unsafe {{ permit.z - 0 }};
    var build_epoch = unsafe {{ permit.epoch - 0 }};
    action.st_sum(permit.x, 0, build_x);
    action.st_sum(permit.y, 0, build_y);
    action.st_sum(permit.z, 0, build_z);
    action.st_sum(permit.epoch, 0, build_epoch);
{ship_initial_state_source(
    "child_ship",
    tier,
    x="build_x",
    y="build_y",
    z="build_z",
    epoch="build_epoch",
    vdf_iterations=auxiliary_vdf,
)}
}}
"""


def extract_coordinate_source(*, time_only: bool) -> str:
    action_name = (
        "ExtractAnomalyTimeCoordinate"
        if time_only
        else "ExtractAnomalyWarpCoordinate"
    )
    coordinate_class = TIME_COORDINATE if time_only else WARP_COORDINATE
    destination_fields = (
        '        ["destination_epoch", 0],\n'
        if time_only
        else (
            '        ["destination_x", 0],\n'
            '        ["destination_y", 0],\n'
            '        ["destination_z", 0],\n'
        )
    )
    return f"""
fn {action_name}(action) {{
    var next_ship = action.output("{SHIP}");
    var coordinate = action.output("{coordinate_class}");
    var ship = action.input("{SHIP}");
    var body = action.mutate("{BODY}");
{replacement_ship_state_source(
    "body",
    ("sector_x", "sector_y", "sector_z", "sector_epoch"),
    None,
    "body_bank_version",
)}
    action.st_sum(ship.extraction_amount, 0, 250);
    action.st_sum(ship.rare_extraction_amount, 0, 25);
    action.st_sum(ship.active_skill_type, 0, {WARP_SKILL_TYPE});
    action.st_sum(body.candidate_code, 0, {WARP_ANOMALY_CANDIDATE});
    action.st_sum(body.body_type, 0, 7);

    var source_body_identifier = action.random();
    var_assign(source_body_identifier, body.stable_identifier);
    body.update("stable_identifier", source_body_identifier);
    var source_pool_before = unsafe {{ body.energy_remaining - 0 }};
    action.st_sum(body.energy_remaining, 0, source_pool_before);
    var next_energy = unsafe {{ source_pool_before - {WARP_ENERGY_COST} }};
    action.st_sum(next_energy, {WARP_ENERGY_COST}, source_pool_before);
    action.st_gt(next_energy, -1);

    coordinate.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["source_body_identifier", source_body_identifier],
        ["source_pool_before", source_pool_before],
        ["revealed", 0],
        ["destination_code", 0],
{destination_fields.rstrip()}
        ["uses_remaining", 0]
    ]);
    let zero = action.top_limb_u256(0);
    coordinate.update("key", zero);
    body.update("energy_remaining", next_energy);
    var next_body_key = action.random();
    rotate_key(body, next_body_key);
}}
"""


def reveal_position_coordinate_source(destination: dict[str, Any]) -> str:
    minimum_pool_exclusive = destination["minimum_source_pool_inclusive"] - 1
    return f"""
fn RevealWarpCoordinate{destination['slug']}(action) {{
    var c = action.mutate("{WARP_COORDINATE}");
    reveal_p(action, c, {destination['code']}, {destination['x']}, {destination['y']}, {destination['z']}, {destination['uses']}, {minimum_pool_exclusive});
}}
"""


def reveal_time_coordinate_source(destination: dict[str, Any]) -> str:
    minimum_pool_exclusive = destination["minimum_source_pool_inclusive"] - 1
    return f"""
fn RevealTimeCoordinate{destination['slug']}(action) {{
    var c = action.mutate("{TIME_COORDINATE}");
    reveal_t(action, c, {destination['code']}, {destination['epoch']}, {destination['uses']}, {minimum_pool_exclusive});
}}
"""


def warp_to_coordinate_source(*, final_use: bool, time_only: bool = False) -> str:
    name = (
        ("TimeWarpToCoordinateFinal" if final_use else "TimeWarpToCoordinateReusable")
        if time_only
        else ("WarpToCoordinateFinal" if final_use else "WarpToCoordinateReusable")
    )
    coordinate_mode = "input" if final_use else "mutate"
    coordinate_class = TIME_COORDINATE if time_only else WARP_COORDINATE
    use_check = (
        "    action.st_sum(coordinate.uses_remaining, 0, 1);"
        if final_use
        else """    action.st_gt(coordinate.uses_remaining, 1);
    var next_uses = unsafe { coordinate.uses_remaining - 1 };
    action.st_sum(next_uses, 1, coordinate.uses_remaining);"""
    )
    reuse_update = (
        ""
        if final_use
        else """    coordinate.update("uses_remaining", next_uses);
    var next_coordinate_key = action.random();
    rotate_key(coordinate, next_coordinate_key);"""
    )
    destination_checks = (
        f"""    action.st_gt(coordinate.destination_epoch, -1);
    action.st_gt({EPOCH_UPPER_BOUND}, coordinate.destination_epoch);"""
        if time_only
        else f"""    action.st_gt(coordinate.destination_x, 0);
    action.st_gt({COORD_UPPER_BOUND}, coordinate.destination_x);
    action.st_gt(coordinate.destination_y, 0);
    action.st_gt({COORD_UPPER_BOUND}, coordinate.destination_y);
    action.st_gt(coordinate.destination_z, 0);
    action.st_gt({COORD_UPPER_BOUND}, coordinate.destination_z);"""
    )
    warp_ship_call = (
        (
            "    warp_ship_core(action, next_ship, ship, ship.x, ship.y, "
            "ship.z, coordinate.destination_epoch);"
        )
        if time_only
        else (
            "    warp_ship_core(action, next_ship, ship, "
            "coordinate.destination_x, coordinate.destination_y, "
            "coordinate.destination_z, ship.epoch);"
        )
    )
    return f"""
fn {name}(action) {{
    var next_ship = action.output("{SHIP}");
    var ship = action.input("{SHIP}");
    var coordinate = action.{coordinate_mode}("{coordinate_class}");
    prove_fixed_versions(action, coordinate);
    action.st_sum(coordinate.revealed, 0, 1);
{use_check}
{destination_checks}
{warp_ship_call}
{reuse_update}
}}
"""


def extract_v2_chart_source(*, time_only: bool) -> str:
    action_name = (
        "ExtractWormholeEpochChart" if time_only else "ExtractWormholeWarpChart"
    )
    chart_class = EPOCH_CHART if time_only else WARP_CHART
    skill_code = 14 if time_only else 11
    chart_entries = (
        '        ["destination_epoch", 0]'
        if time_only
        else (
            '        ["destination_x", 0],\n'
            '        ["destination_y", 0],\n'
            '        ["destination_z", 0]'
        )
    )
    return f"""
fn {action_name}(action) {{
    var next_ship = action.output("{SHIP}");
    var chart = action.output("{chart_class}");
    var ship = action.input("{SHIP}");
    var body = action.mutate("{BODY}");
    var source_body_identifier = action.random();
    var_assign(source_body_identifier, body.stable_identifier);
    body.update("stable_identifier", source_body_identifier);
    var source_pool_before = unsafe {{ body.energy_remaining - 0 }};
    action.st_sum(body.energy_remaining, 0, source_pool_before);
    chart.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["catalog_version", 2],
        ["source_body_identifier", source_body_identifier],
        ["source_pool_before", source_pool_before],
        ["revealed", 0],
        ["destination_code", 0],
{chart_entries},
        ["uses_remaining", 0]
    ]);
    let chart_zero = action.top_limb_u256(0);
    chart.update("key", chart_zero);
    extract_v2_chart_core(action, next_ship, ship, body, {skill_code});
    var work = action.intro_vdf(20, chart);
    chart.update("work", work);
}}
"""


def reveal_v2_chart_source(
    destination: dict[str, Any],
    *,
    time_only: bool,
) -> str:
    action_name = destination["reveal_action"]
    chart_class = EPOCH_CHART if time_only else WARP_CHART
    minimum_pool_exclusive = destination["minimum_source_pool_inclusive"] - 1
    literal_arguments = (
        f"{destination['code']}, {destination['epoch']}, {destination['uses']}, "
        f"{minimum_pool_exclusive}"
        if time_only
        else (
            f"{destination['code']}, {destination['x']}, {destination['y']}, "
            f"{destination['z']}, {destination['uses']}, "
            f"{minimum_pool_exclusive}"
        )
    )
    helper = "reveal_chart_t" if time_only else "reveal_chart_p"
    return f"""
fn {action_name}(action) {{
    var n = action.output("{SHIP}");
    var s = action.input("{SHIP}");
    var c = action.mutate("{chart_class}");
    {helper}(action, n, s, c, {literal_arguments});
}}
"""


def v2_chart_transit_source(*, final_use: bool, time_only: bool) -> str:
    action_name = (
        ("WarpShipToEpochCoordinateFinal" if final_use else "WarpShipToEpochCoordinateReusable")
        if time_only
        else (
            "WarpShipToPositionCoordinateFinal"
            if final_use
            else "WarpShipToPositionCoordinateReusable"
        )
    )
    chart_class = EPOCH_CHART if time_only else WARP_CHART
    mode = "input" if final_use else "mutate"
    skill_code = 58 if time_only else 51
    vdf_iterations = 20 if time_only else 12
    use_helper = "consume_final_use_core" if final_use else "consume_reusable_use_core"
    destination_checks = (
        f"""    action.st_gt(chart.destination_epoch, 100);
    action.st_gt({EPOCH_UPPER_BOUND}, chart.destination_epoch);"""
        if time_only
        else f"""    action.st_gt(chart.destination_x, 99);
    action.st_gt({COORD_UPPER_BOUND}, chart.destination_x);
    action.st_gt(chart.destination_y, 99);
    action.st_gt({COORD_UPPER_BOUND}, chart.destination_y);
    action.st_gt(chart.destination_z, 99);
    action.st_gt({COORD_UPPER_BOUND}, chart.destination_z);"""
    )
    warp_call = (
        "warp_ship_core(action, next_ship, ship, ship.x, ship.y, ship.z, chart.destination_epoch);"
        if time_only
        else (
            "warp_ship_core(action, next_ship, ship, chart.destination_x, "
            "chart.destination_y, chart.destination_z, ship.epoch);"
        )
    )
    return f"""
fn {action_name}(action) {{
    var next_ship = action.output("{SHIP}");
    var ship = action.input("{SHIP}");
    var chart = action.{mode}("{chart_class}");
    prove_object_version_core(action, chart, "catalog_version");
    action.st_sum(chart.revealed, 0, 1);
    action.st_sum(ship.active_skill_type, 0, {skill_code});
{destination_checks}
    {warp_call}
    {use_helper}(action, chart);
    var work = action.intro_vdf({vdf_iterations}, next_ship);
    next_ship.update("work", work);
}}
"""


def capture_anchor_source(*, time_only: bool) -> str:
    action_name = "CaptureTimeAnchor" if time_only else "CapturePositionAnchor"
    anchor_class = TIME_ANCHOR if time_only else POSITION_ANCHOR
    recipe = WARP_RECIPES["TimeAnchor" if time_only else "PositionAnchor"]
    skill_code = 60 if time_only else 49
    vdf_iterations = 20 if time_only else 12
    coordinate_copy = (
        """    var ae = unsafe { ship.epoch - 0 };
    action.st_sum(ship.epoch, 0, ae);"""
        if time_only
        else """    var ax = unsafe { ship.x - 0 };
    var ay = unsafe { ship.y - 0 };
    var az = unsafe { ship.z - 0 };
    action.st_sum(ship.x, 0, ax);
    action.st_sum(ship.y, 0, ay);
    action.st_sum(ship.z, 0, az);"""
    )
    coordinate_fields = (
        '        ["epoch", ae],'
        if time_only
        else "\n".join(
            f'        ["{axis}", a{axis}],' for axis in ("x", "y", "z")
        )
    )
    return f"""
fn {action_name}(action) {{
    var next_ship = action.output("{SHIP}");
    var anchor = action.output("{anchor_class}");
    var ship = action.input("{SHIP}");
    var material_1 = action.input("{RESOURCE}");
    var material_2 = action.input("{RESOURCE}");
    var source_ship_id = consume_prepared_ship_core(
        action, next_ship, ship, {skill_code}
    );
    prove_resource_stack_core(action, material_1, {recipe['inputs'][0]['resource_code']}, 1);
    prove_resource_stack_core(action, material_2, {recipe['inputs'][1]['resource_code']}, 1);
{coordinate_copy}
    anchor.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["anchor_version", 2],
        ["source_ship_id", source_ship_id],
{coordinate_fields}
        ["uses_remaining", 1]
    ]);
    var work = action.intro_vdf({vdf_iterations}, anchor);
    anchor.update("work", work);
}}
"""


def construct_link_source(*, time_only: bool) -> str:
    action_name = "ConstructTemporalLink" if time_only else "ConstructWormholeLink"
    link_class = TEMPORAL_LINK if time_only else WORMHOLE_LINK
    anchor_class = TIME_ANCHOR if time_only else POSITION_ANCHOR
    recipe = WARP_RECIPES["TemporalLink" if time_only else "WormholeLink"]
    skill_code = 60 if time_only else 59
    copied_fields = ("epoch",) if time_only else ("x", "y", "z")
    placeholder_fields = "\n".join(
        [
            f'        ["endpoint_{endpoint}_anchor_identifier", placeholder_identifier],'
            if field == "anchor_identifier"
            else f'        ["endpoint_{endpoint}_{field}", 0],'
            for endpoint in ("a", "b")
            for field in ("anchor_identifier", *copied_fields)
        ]
    )
    anchor_blocks = "\n".join(
        "\n".join(
            [
                f'    var anchor_{endpoint} = action.input("{anchor_class}");',
                f'    prove_object_version_core(action, anchor_{endpoint}, "anchor_version");',
                f"    action.st_sum(anchor_{endpoint}.uses_remaining, 0, 1);",
                *[
                    "\n".join(
                        [
                            f"    var endpoint_{endpoint}_{field} = unsafe {{ "
                            f"anchor_{endpoint}.{field} - 0 }};",
                            f"    action.st_sum(anchor_{endpoint}.{field}, 0, "
                            f"endpoint_{endpoint}_{field});",
                            f'    link.update("endpoint_{endpoint}_{field}", '
                            f"endpoint_{endpoint}_{field});",
                        ]
                    )
                    for field in copied_fields
                ],
                f"    var endpoint_{endpoint}_anchor_identifier = action.random();",
                f"    var_assign(endpoint_{endpoint}_anchor_identifier, "
                f"anchor_{endpoint}.stable_identifier);",
                f'    anchor_{endpoint}.update("stable_identifier", '
                f"endpoint_{endpoint}_anchor_identifier);",
                f'    link.update("endpoint_{endpoint}_anchor_identifier", '
                f"endpoint_{endpoint}_anchor_identifier);",
            ]
        )
        for endpoint in ("a", "b")
    )
    return f"""
fn {action_name}(action) {{
    var link = action.output("{link_class}");
    let placeholder_identifier = action.top_limb_u256(0);
    link.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["link_version", 2],
{placeholder_fields}
        ["uses_remaining", {recipe['output_uses']}]
    ]);
{anchor_blocks}
    var material_1 = action.input("{RESOURCE}");
    prove_resource_stack_core(action, material_1, {recipe['inputs'][2]['resource_code']}, 1);
    var material_2 = action.input("{RESOURCE}");
    prove_resource_stack_core(action, material_2, {recipe['inputs'][3]['resource_code']}, 1);
    var work = action.intro_vdf(32, link);
    link.update("work", work);
    var ship = action.mutate("{SHIP}");
    prove_fixed_versions(action, ship);
    action.st_sum(ship.active_skill_type, 0, {skill_code});
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_constructor_ship_key = action.random();
    rotate_key(ship, next_constructor_ship_key);
}}
"""


def traverse_link_source(
    *,
    time_only: bool,
    a_to_b: bool,
    final_use: bool,
) -> str:
    kind = "Temporal" if time_only else "Wormhole"
    direction = "AToB" if a_to_b else "BToA"
    mode_suffix = "Final" if final_use else "Reusable"
    action_name = f"Traverse{kind}{direction}{mode_suffix}"
    link_class = TEMPORAL_LINK if time_only else WORMHOLE_LINK
    mode = "input" if final_use else "mutate"
    skill_code = 60 if time_only else 59
    source_endpoint = "a" if a_to_b else "b"
    destination_endpoint = "b" if a_to_b else "a"
    use_helper = "consume_final_use_core" if final_use else "consume_reusable_use_core"
    source_binding = (
        f"""    var source_epoch = unsafe {{ link.endpoint_{source_endpoint}_epoch - 0 }};
    action.st_sum(link.endpoint_{source_endpoint}_epoch, 0, source_epoch);
    action.st_sum(ship.epoch, 0, source_epoch);"""
        if time_only
        else "\n".join(
            (
                f"    var source_{axis} = unsafe {{ "
                f"link.endpoint_{source_endpoint}_{axis} - 0 }};\n"
                f"    action.st_sum(link.endpoint_{source_endpoint}_{axis}, 0, source_{axis});\n"
                f"    action.st_sum(ship.{axis}, 0, source_{axis});"
            )
            for axis in ("x", "y", "z")
        )
    )
    warp_call = (
        f"warp_ship_core(action, next_ship, ship, ship.x, ship.y, ship.z, link.endpoint_{destination_endpoint}_epoch);"
        if time_only
        else (
            f"warp_ship_core(action, next_ship, ship, "
            f"link.endpoint_{destination_endpoint}_x, "
            f"link.endpoint_{destination_endpoint}_y, "
            f"link.endpoint_{destination_endpoint}_z, ship.epoch);"
        )
    )
    return f"""
fn {action_name}(action) {{
    var next_ship = action.output("{SHIP}");
    var ship = action.input("{SHIP}");
    var link = action.{mode}("{link_class}");
    prove_object_version_core(action, link, "link_version");
    action.st_sum(ship.active_skill_type, 0, {skill_code});
{source_binding}
    {warp_call}
    {use_helper}(action, link);
    var work = action.intro_vdf(20, next_ship);
    next_ship.update("work", work);
}}
"""


def compose_rendezvous_source() -> str:
    recipe = WARP_RECIPES["RendezvousCoordinate"]
    return f"""
fn ComposeRendezvousCoordinate(action) {{
    var coordinate = action.output("{RENDEZVOUS_COORDINATE}");
    let placeholder_identifier = action.top_limb_u256(0);
    coordinate.set([
        ["schema_version", {VERSIONS['schema_version']}],
        ["mechanics_version", {VERSIONS['mechanics_version']}],
        ["universe_version", {VERSIONS['universe_version']}],
        ["coordinate_version", 2],
        ["position_anchor_identifier", placeholder_identifier],
        ["destination_x", 0],
        ["destination_y", 0],
        ["destination_z", 0],
        ["time_anchor_identifier", placeholder_identifier],
        ["destination_epoch", 0],
        ["uses_remaining", {recipe['output_uses']}]
    ]);
    var position_anchor = action.input("{POSITION_ANCHOR}");
    prove_object_version_core(action, position_anchor, "anchor_version");
    action.st_sum(position_anchor.uses_remaining, 0, 1);
    var destination_x = unsafe {{ position_anchor.x - 0 }};
    action.st_sum(position_anchor.x, 0, destination_x);
    coordinate.update("destination_x", destination_x);
    var destination_y = unsafe {{ position_anchor.y - 0 }};
    action.st_sum(position_anchor.y, 0, destination_y);
    coordinate.update("destination_y", destination_y);
    var destination_z = unsafe {{ position_anchor.z - 0 }};
    action.st_sum(position_anchor.z, 0, destination_z);
    coordinate.update("destination_z", destination_z);
    var position_anchor_identifier = action.random();
    var_assign(position_anchor_identifier, position_anchor.stable_identifier);
    position_anchor.update("stable_identifier", position_anchor_identifier);
    coordinate.update("position_anchor_identifier", position_anchor_identifier);
    var time_anchor = action.input("{TIME_ANCHOR}");
    prove_object_version_core(action, time_anchor, "anchor_version");
    action.st_sum(time_anchor.uses_remaining, 0, 1);
    var destination_epoch = unsafe {{ time_anchor.epoch - 0 }};
    action.st_sum(time_anchor.epoch, 0, destination_epoch);
    coordinate.update("destination_epoch", destination_epoch);
    var time_anchor_identifier = action.random();
    var_assign(time_anchor_identifier, time_anchor.stable_identifier);
    time_anchor.update("stable_identifier", time_anchor_identifier);
    coordinate.update("time_anchor_identifier", time_anchor_identifier);
    var material_1 = action.input("{RESOURCE}");
    prove_resource_stack_core(action, material_1, {recipe['inputs'][2]['resource_code']}, 1);
    var material_2 = action.input("{RESOURCE}");
    prove_resource_stack_core(action, material_2, {recipe['inputs'][3]['resource_code']}, 1);
    var work = action.intro_vdf(32, coordinate);
    coordinate.update("work", work);
    var ship = action.mutate("{SHIP}");
    prove_fixed_versions(action, ship);
    action.st_sum(ship.active_skill_type, 0, 86);
    var next_action_serial = unsafe {{ ship.action_serial - (0 - 1) }};
    action.st_sum(ship.action_serial, 1, next_action_serial);
    ship.update("active_skill_type", 0);
    ship.update("action_serial", next_action_serial);
    var next_constructor_ship_key = action.random();
    rotate_key(ship, next_constructor_ship_key);
}}
"""


def rendezvous_transit_source(*, final_use: bool) -> str:
    action_name = (
        "WarpToRendezvousCoordinateFinal"
        if final_use
        else "WarpToRendezvousCoordinateReusable"
    )
    mode = "input" if final_use else "mutate"
    use_helper = "consume_final_use_core" if final_use else "consume_reusable_use_core"
    return f"""
fn {action_name}(action) {{
    var next_ship = action.output("{SHIP}");
    var ship = action.input("{SHIP}");
    var coordinate = action.{mode}("{RENDEZVOUS_COORDINATE}");
    prove_object_version_core(action, coordinate, "coordinate_version");
    action.st_sum(ship.active_skill_type, 0, 86);
    warp_ship_core(
        action,
        next_ship,
        ship,
        coordinate.destination_x,
        coordinate.destination_y,
        coordinate.destination_z,
        coordinate.destination_epoch
    );
    {use_helper}(action, coordinate);
    var work = action.intro_vdf(32, next_ship);
    next_ship.update("work", work);
}}
"""


def sources_for_bank(bank: list[dict[str, Any]]) -> dict[str, str]:
    result: dict[str, str] = {}
    for tier in SHIP_TIERS:
        result[f"BuildShip{tier['name']}"] = build_ship_source(tier)
    for action_name, axis, positive, tier in movement_variants():
        result[action_name] = movement_source(
            axis,
            positive,
            name=action_name,
            tier=tier,
        )
    for tier in SHIP_TIERS:
        result[f"TimeWarp{tier['name']}"] = timewarp_source(tier)
    result["ClaimSector"] = claim_source()
    for profile in SURVEY_PROFILES:
        result[
            f"SurveySector_{profile['code']:02d}_{profile['slug']}"
        ] = survey_source(profile)
    for item in bank:
        result[f"DetectCelestialSignal_{item['code']:02d}_{item['slug']}"] = detect_source(item)
    for item in bank:
        result[
            f"ScanCelestialBody_{item['code']:02d}_{item['slug']}"
        ] = scan_source(item, bank)
    result["ExtractAnomalyWarpCoordinate"] = extract_coordinate_source(
        time_only=False
    )
    result["ExtractAnomalyTimeCoordinate"] = extract_coordinate_source(
        time_only=True
    )
    for destination in POSITION_WARP_DESTINATIONS:
        result[f"RevealWarpCoordinate{destination['slug']}"] = (
            reveal_position_coordinate_source(destination)
        )
    for destination in TIME_WARP_DESTINATIONS:
        result[f"RevealTimeCoordinate{destination['slug']}"] = (
            reveal_time_coordinate_source(destination)
        )
    result["WarpToCoordinateReusable"] = warp_to_coordinate_source(
        final_use=False
    )
    result["WarpToCoordinateFinal"] = warp_to_coordinate_source(
        final_use=True
    )
    result["TimeWarpToCoordinateReusable"] = warp_to_coordinate_source(
        final_use=False,
        time_only=True,
    )
    result["TimeWarpToCoordinateFinal"] = warp_to_coordinate_source(
        final_use=True,
        time_only=True,
    )
    if POSITION_CHART_DESTINATIONS:
        result["ExtractWormholeWarpChart"] = extract_v2_chart_source(
            time_only=False
        )
        result["ExtractWormholeEpochChart"] = extract_v2_chart_source(
            time_only=True
        )
        for destination in POSITION_CHART_DESTINATIONS:
            result[destination["reveal_action"]] = reveal_v2_chart_source(
                destination, time_only=False
            )
        result["WarpShipToPositionCoordinateReusable"] = (
            v2_chart_transit_source(final_use=False, time_only=False)
        )
        result["WarpShipToPositionCoordinateFinal"] = (
            v2_chart_transit_source(final_use=True, time_only=False)
        )
        for destination in EPOCH_CHART_DESTINATIONS:
            result[destination["reveal_action"]] = reveal_v2_chart_source(
                destination, time_only=True
            )
        result["WarpShipToEpochCoordinateReusable"] = (
            v2_chart_transit_source(final_use=False, time_only=True)
        )
        result["WarpShipToEpochCoordinateFinal"] = (
            v2_chart_transit_source(final_use=True, time_only=True)
        )
        result["CapturePositionAnchor"] = capture_anchor_source(
            time_only=False
        )
        result["CaptureTimeAnchor"] = capture_anchor_source(time_only=True)
        result["ConstructWormholeLink"] = construct_link_source(
            time_only=False
        )
        result["ConstructTemporalLink"] = construct_link_source(
            time_only=True
        )
        for time_only, kind in ((False, "Wormhole"), (True, "Temporal")):
            for a_to_b, direction in ((True, "AToB"), (False, "BToA")):
                for final_use in (False, True):
                    name = (
                        f"Traverse{kind}{direction}"
                        + ("Final" if final_use else "Reusable")
                    )
                    result[name] = traverse_link_source(
                        time_only=time_only,
                        a_to_b=a_to_b,
                        final_use=final_use,
                    )
        result["ComposeRendezvousCoordinate"] = compose_rendezvous_source()
        result["WarpToRendezvousCoordinateReusable"] = (
            rendezvous_transit_source(final_use=False)
        )
        result["WarpToRendezvousCoordinateFinal"] = (
            rendezvous_transit_source(final_use=True)
        )
    for resource_name, resource_type, remaining_field in [
        ("Matter", 1, "matter_remaining"),
        ("Crystal", 2, "crystal_remaining"),
        ("Gas", 3, "gas_remaining"),
        ("Energy", 4, "energy_remaining"),
    ]:
        base_action_name = f"Extract{resource_name}"
        for action_name, tier in extraction_tier_variants(
            base_action_name,
            0,
        ):
            result[action_name] = extract_source(
                resource_name,
                resource_type,
                remaining_field,
                BASE_EXTRACTION_VDF[resource_name],
                action_name=action_name,
                ship_tier=tier,
            )
    result["DiscoverSatellite"] = satellite_source()
    result["DetectIntelligentLife"] = detect_intelligent_life_source(bank)
    for civilization_type in CIVILIZATION_TYPES:
        result[civilization_type["action"]] = (
            materialize_civilization_source(civilization_type)
        )
    candidates_by_code = {candidate["code"]: candidate for candidate in bank}
    for resource in CIVILIZATION_TECH_RESOURCES:
        for action_name, tier in extraction_tier_variants(
            resource["action"],
            resource["minimum_ship_tier"],
        ):
            result[action_name] = extract_source(
                resource["name"],
                resource["code"],
                resource["remaining_field"],
                resource["vdf_iterations"],
                action_name=action_name,
                selector_route_action=resource["action"],
                candidate=candidates_by_code[resource["candidate_code"]],
                child_allocations=resource["child_allocations"],
                skill_code=resource["skill_code"],
                minimum_ship_tier=resource["minimum_ship_tier"],
                ship_tier=tier,
            )
    resource_code_by_name = {
        resource["name"]: resource["code"]
        for resource in CIVILIZATION_TECH_RESOURCES
    }
    for route in REFINEMENT_ROUTES:
        result[route["action"]] = refine_resource_source(
            route,
            resource_code_by_name[route["parent_name"]],
        )
    for component in COMPONENT_RECIPES:
        result[component["actions"]["reusable"]] = (
            fabricate_component_source(component, final_use=False)
        )
        result[component["actions"]["final"]] = (
            fabricate_component_source(component, final_use=True)
        )
    for skill in TECHNOLOGY_SKILLS:
        result[skill["action"]] = develop_technology_skill_source(skill)
    for skill in DERIVED_SKILLS:
        result[skill["action"]] = develop_derived_skill_source(skill)
    for capability in SKILL_CAPABILITIES:
        result[capability["action"]] = capability_artifact_source(capability)
    result["UseTechnologySkill"] = use_technology_skill_source()
    result["CreateLargeShipConstructionPermit"] = (
        create_large_ship_permit_source()
    )
    for skill in LARGE_CONSTRUCTION_SKILLS:
        result[f"AuthorizeLargeShip{skill['slug']}"] = (
            authorize_large_ship_permit_source(skill)
        )
    result["IssueAuxiliaryShipPermit"] = (
        issue_auxiliary_ship_permit_source()
    )
    tiers_by_name = {tier["name"]: tier for tier in SHIP_TIERS}
    result["BuildAuxiliaryShipSmall"] = build_auxiliary_ship_source(
        tiers_by_name["Small"],
        AUXILIARY_SMALL_RECIPE,
    )
    result["BuildAuxiliaryShipMedium"] = build_auxiliary_ship_source(
        tiers_by_name["Medium"],
        MEDIUM_SHIP_RECIPE,
    )
    if EXPANSION_CATALOGS and PHASE6_TOKEN_LAYOUT_ENABLED:
        result = {
            action_name: minify_rhai_source_tokens(source)
            for action_name, source in result.items()
        }
        simple_helpers = phase6_simple_adapter_helpers(bank)
        for action_name, helper_name in simple_helpers.items():
            result[action_name] = compact_simple_adapter_wrapper(
                result[action_name], helper_name
            )
    else:
        compact_action_names = {
            *(
                f"RevealWarpCoordinate{destination['slug']}"
                for destination in POSITION_WARP_DESTINATIONS
            ),
            *(
                f"RevealTimeCoordinate{destination['slug']}"
                for destination in TIME_WARP_DESTINATIONS
            ),
            *(
                destination["reveal_action"]
                for destination in POSITION_CHART_DESTINATIONS
            ),
            *(
                destination["reveal_action"]
                for destination in EPOCH_CHART_DESTINATIONS
            ),
            *(
                action_name
                for component in COMPONENT_RECIPES
                for action_name in component["actions"].values()
            ),
            *(skill["action"] for skill in DERIVED_SKILLS),
            *(capability["action"] for capability in SKILL_CAPABILITIES),
            *(route["action"] for route in REFINEMENT_ROUTES),
            *(
                action_name
                for action_name, _axis, _positive, _tier
                in movement_variants()
            ),
            *(skill["action"] for skill in TECHNOLOGY_SKILLS),
            *(
                f"SurveySector_{profile['code']:02d}_{profile['slug']}"
                for profile in SURVEY_PROFILES
            ),
        }
        for action_name in compact_action_names:
            result[action_name] = minify_rhai_source_tokens(
                result[action_name]
            )
    return result


def render_manifest(classes: Iterable[str], actions: list[dict[str, Any]], package_name: str) -> str:
    lines = [
        "[plugin]",
        f'name = "{package_name}"',
        f'version = "{PLUGIN_VERSION}"',
        f'module_hash = "{ZERO_HASH}"',
        "",
    ]
    for class_name in classes:
        presentation = CLASS_PRESENTATION.get(
            class_name,
            {
                "title": class_name,
                "emoji": "📦",
                "description": f"{class_name} protocol object.",
            },
        )
        lines.extend(
            [
                "[[classes]]",
                f'name = "{class_name}"',
                f'emoji = "{presentation["emoji"]}"',
                f'description = "{presentation["description"]}"',
                "",
            ]
        )
    for action in actions:
        lines.extend(
            [
                "[[actions]]",
                f'name = "{action["name"]}"',
                'emoji = "MV"',
                f'description = "{action["description"]}."',
                f'hidden = {"true" if action["hidden"] else "false"}',
                "",
            ]
        )
    return "\n".join(lines)


def compact_rhai_layout(source: str) -> str:
    """Remove nonsemantic layout/comment bytes while preserving line structure."""
    lines = [
        line.strip()
        for line in source.splitlines()
        if line.strip() and not line.lstrip().startswith("//")
    ]
    return "\n".join(lines) + "\n"


def minify_rhai_source_tokens(source: str) -> str:
    """Compact whitespace outside strings without merging identifier tokens."""
    source = mask_rhai_comments(source)
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


def rhai_lexical_tokens(source: str) -> tuple[str, ...]:
    """Return comment-free Rhai tokens while preserving string literals."""
    tokens: list[str] = []
    index = 0
    operator_chars = set("+-*/%<>=!&|^~?:")
    while index < len(source):
        char = source[index]
        if char.isspace():
            index += 1
            continue
        if source.startswith("//", index):
            newline = source.find("\n", index + 2)
            index = len(source) if newline < 0 else newline + 1
            continue
        if source.startswith("/*", index):
            close = source.find("*/", index + 2)
            index = len(source) if close < 0 else close + 2
            continue
        if char == '"':
            start = index
            index += 1
            escaped = False
            while index < len(source):
                current = source[index]
                index += 1
                if escaped:
                    escaped = False
                elif current == "\\":
                    escaped = True
                elif current == '"':
                    break
            tokens.append(source[start:index])
            continue
        if char.isalpha() or char == "_":
            start = index
            index += 1
            while index < len(source) and (
                source[index].isalnum() or source[index] == "_"
            ):
                index += 1
            tokens.append(source[start:index])
            continue
        if char.isdigit():
            start = index
            index += 1
            while index < len(source) and source[index].isdigit():
                index += 1
            tokens.append(source[start:index])
            continue
        if char in operator_chars:
            start = index
            index += 1
            while index < len(source) and source[index] in operator_chars:
                index += 1
            tokens.append(source[start:index])
            continue
        tokens.append(char)
        index += 1
    return tuple(tokens)


def rhai_token_occurrences(source: str, snippet: str) -> int:
    """Count exact lexical-token subsequences outside comments."""
    tokens = rhai_lexical_tokens(source)
    expected = rhai_lexical_tokens(snippet)
    if not expected or len(expected) > len(tokens):
        return 0
    return sum(
        tokens[index:index + len(expected)] == expected
        for index in range(len(tokens) - len(expected) + 1)
    )


class RhaiAuditSource(str):
    """Keep generator audits token-aware after canonical layout cleanup."""

    def __contains__(self, snippet: object) -> bool:
        if not isinstance(snippet, str):
            return super().__contains__(snippet)
        return bool(rhai_token_occurrences(self, snippet))

    def count(
        self,
        sub: str,
        start: int | None = None,
        end: int | None = None,
    ) -> int:
        source = self[
            0 if start is None else start:
            len(self) if end is None else end
        ]
        return rhai_token_occurrences(source, sub)

    def __add__(self, other: object) -> "RhaiAuditSource":
        return RhaiAuditSource(super().__add__(str(other)))

    def __radd__(self, other: object) -> "RhaiAuditSource":
        return RhaiAuditSource(str(other) + str(self))


def phase6_simple_adapter_helpers(
    bank: list[dict[str, Any]] | None = None,
) -> dict[str, str]:
    """Return the enabled Phase 4/5 adapter-only wrapper inventory."""
    actions = build_actions(BODY_BANK if bank is None else bank)
    routes: dict[str, str] = {}
    for action in actions:
        action_name = action["name"]
        if action["family"] == "extract_civilization_tech_resource":
            continue
        helper_name = phase5_helper_for(action_name)
        if helper_name is None:
            kind = phase4_kind_for_action(action)
            if kind is not None:
                vdf = action["intro_contract"]["vdf"]
                iterations = vdf["iterations"] if vdf is not None else None
                helper_name = phase4_helper_for(
                    action_name, kind, iterations
                )
        if helper_name is not None:
            routes[action_name] = helper_name
    return routes


def compact_simple_adapter_wrapper(source: str, helper_name: str) -> str:
    """Join one adapter call and its structural brace without joining roles."""
    compacted = minify_rhai_source_tokens(source)
    lines = compacted.splitlines()
    starts = [
        index
        for index, line in enumerate(lines)
        if line == f"{helper_name}(" or line.startswith(f"{helper_name}(")
    ]
    if len(starts) != 1:
        raise ValueError(f"expected one {helper_name} adapter call")
    start = starts[0]
    if lines[start].endswith(");}"):
        return compacted
    closes = [
        index
        for index in range(start, len(lines))
        if lines[index].endswith(");")
    ]
    if len(closes) != 1:
        raise ValueError(f"expected one {helper_name} adapter terminator")
    close = closes[0]
    if lines[close + 1:] != ["}"]:
        raise ValueError(f"{helper_name} must be the wrapper's final statement")
    role_pattern = re.compile(
        r'var [A-Za-z_][A-Za-z0-9_]*=action\.(?:output|input|mutate)\("[^\"]+"\);'
    )
    if not lines or not lines[0].startswith("fn ") or not all(
        role_pattern.fullmatch(line) for line in lines[1:start]
    ):
        raise ValueError(f"{helper_name} wrapper has non-role prefix work")
    joined = "".join(lines[start:close + 1]) + "}"
    if len(joined) > RHAI_MAX_LINE_LENGTH:
        raise ValueError(f"{helper_name} adapter line exceeds the Rhai cap")
    rewritten = "\n".join([*lines[:start], joined]) + "\n"
    if rhai_lexical_tokens(rewritten) != rhai_lexical_tokens(compacted):
        raise ValueError(f"{helper_name} layout rewrite changed Rhai tokens")
    return rewritten


def rhai_sources_equal(actual: str, expected: str) -> bool:
    return rhai_lexical_tokens(actual) == rhai_lexical_tokens(expected)


def rhai_contains(actual: str, expected: str) -> bool:
    return bool(rhai_token_occurrences(actual, expected))


def rhai_whitespace_insensitive_contains(actual: str, expected: str) -> bool:
    """Match a static Rhai snippet by comment-free lexical tokens."""
    return bool(rhai_token_occurrences(actual, expected))


def render_plugin(actions: list[dict[str, Any]], source_map: dict[str, str]) -> str:
    helpers = common_helpers()
    if EXPANSION_CATALOGS and PHASE6_TOKEN_LAYOUT_ENABLED:
        helpers = minify_rhai_source_tokens(helpers)
    plugin = helpers + "".join(
        source_map[action["name"]] for action in actions
    )
    plugin = re.sub(
        r"(?m)^(?: {4})+",
        lambda match: "  " * (len(match.group(0)) // 4),
        plugin,
    )
    plugin = plugin.replace("\n\nfn ", "\nfn ")
    return compact_rhai_layout(plugin) if EXPANSION_CATALOGS else plugin


def warp_coordinate_capacity_sweep(
    bank: list[dict[str, Any]],
) -> dict[str, Any]:
    """Measure both catalog ceilings from the canonical catalog split."""
    global POSITION_WARP_DESTINATIONS, TIME_WARP_DESTINATIONS
    canonical_destinations = POSITION_WARP_DESTINATIONS
    base_rows = [
        {
            key: value
            for key, value in destination.items()
            if key
            not in {"uses"}
        }
        for destination in canonical_destinations
    ]
    rows: list[dict[str, Any]] = []
    try:
        for count in range(
            len(base_rows), WARP_CAPACITY_SWEEP_MAX_COUNT + 1
        ):
            catalog_rows: list[dict[str, Any]] = []
            for code in range(1, count + 1):
                if code <= len(base_rows):
                    row = dict(base_rows[code - 1])
                else:
                    offset = code - len(base_rows)
                    row = {
                        "code": code,
                        "slug": f"{code:03d}",
                        # Full-width, distinct literals make the extension
                        # conservative for PEXE source-size measurement.
                        "x": COORD_UPPER_BOUND - 1 - offset,
                        "y": COORD_UPPER_BOUND - 100_001 - offset,
                        "z": COORD_UPPER_BOUND - 200_001 - offset,
                    }
                uses = catalog_uses(code, count)
                row.update(
                    uses=uses,
                    minimum_source_pool_inclusive=(
                        v1_coordinate_pool_minimum(uses)
                    ),
                )
                catalog_rows.append(row)
            POSITION_WARP_DESTINATIONS = catalog_rows
            sweep_actions = build_actions(bank)
            plugin_bytes = len(
                render_plugin(
                    sweep_actions,
                    sources_for_bank(bank),
                ).encode("utf-8")
            )
            manifest_bytes = len(
                render_manifest(
                    CLASS_ORDER,
                    sweep_actions,
                    PACKAGE_NAME,
                ).encode("utf-8")
            )
            rows.append(
                {
                    "position_count": count,
                    "time_count": len(TIME_WARP_DESTINATIONS),
                    "total_coordinate_count": (
                        count + len(TIME_WARP_DESTINATIONS)
                    ),
                    "plugin_bytes": plugin_bytes,
                    "manifest_bytes": manifest_bytes,
                    "under_safety_limit": (
                        plugin_bytes <= RHAI_SAFETY_LIMIT_BYTES
                    ),
                    "under_hard_limit": (
                        plugin_bytes <= RHAI_HARD_LIMIT_BYTES
                    ),
                }
            )
            if plugin_bytes > RHAI_HARD_LIMIT_BYTES:
                break
    finally:
        POSITION_WARP_DESTINATIONS = canonical_destinations

    position_rows = rows
    position_safety_rows = [
        row for row in position_rows if row["under_safety_limit"]
    ]
    position_hard_rows = [
        row for row in position_rows if row["under_hard_limit"]
    ]

    canonical_times = TIME_WARP_DESTINATIONS
    base_time_rows = [
        {
            key: value
            for key, value in destination.items()
            if key
            not in {"uses"}
        }
        for destination in canonical_times
    ]
    time_rows: list[dict[str, Any]] = []
    try:
        for count in range(
            len(base_time_rows), WARP_CAPACITY_SWEEP_MAX_COUNT + 1
        ):
            catalog_rows = []
            for code in range(1, count + 1):
                if code <= len(base_time_rows):
                    row = dict(base_time_rows[code - 1])
                else:
                    offset = code - len(base_time_rows)
                    row = {
                        "code": code,
                        "slug": f"{code:03d}",
                        "epoch": EPOCH_UPPER_BOUND - 1 - offset,
                    }
                uses = catalog_uses(code, count)
                row.update(
                    uses=uses,
                    minimum_source_pool_inclusive=(
                        v1_coordinate_pool_minimum(uses)
                    ),
                )
                catalog_rows.append(row)
            TIME_WARP_DESTINATIONS = catalog_rows
            sweep_actions = build_actions(bank)
            plugin_bytes = len(
                render_plugin(
                    sweep_actions,
                    sources_for_bank(bank),
                ).encode("utf-8")
            )
            manifest_bytes = len(
                render_manifest(
                    CLASS_ORDER,
                    sweep_actions,
                    PACKAGE_NAME,
                ).encode("utf-8")
            )
            time_rows.append(
                {
                    "position_count": len(POSITION_WARP_DESTINATIONS),
                    "time_count": count,
                    "total_coordinate_count": (
                        len(POSITION_WARP_DESTINATIONS) + count
                    ),
                    "plugin_bytes": plugin_bytes,
                    "manifest_bytes": manifest_bytes,
                    "under_safety_limit": (
                        plugin_bytes <= RHAI_SAFETY_LIMIT_BYTES
                    ),
                    "under_hard_limit": (
                        plugin_bytes <= RHAI_HARD_LIMIT_BYTES
                    ),
                }
            )
            if plugin_bytes > RHAI_HARD_LIMIT_BYTES:
                break
    finally:
        TIME_WARP_DESTINATIONS = canonical_times

    time_safety_rows = [
        row for row in time_rows if row["under_safety_limit"]
    ]
    time_hard_rows = [
        row for row in time_rows if row["under_hard_limit"]
    ]

    position_expansion = {
        "held_fixed": {
            "time_count": len(canonical_times),
        },
        "maximum_under_safety_limit": position_safety_rows[-1],
        "first_over_safety_limit": next(
            row for row in position_rows if not row["under_safety_limit"]
        ),
        "maximum_under_hard_limit": position_hard_rows[-1],
        "first_over_hard_limit": next(
            row for row in position_rows if not row["under_hard_limit"]
        ),
        "rows": position_rows,
    }
    time_expansion = {
        "held_fixed": {
            "position_count": len(canonical_destinations),
        },
        "maximum_under_safety_limit": time_safety_rows[-1],
        "first_over_safety_limit": next(
            row for row in time_rows if not row["under_safety_limit"]
        ),
        "maximum_under_hard_limit": time_hard_rows[-1],
        "first_over_hard_limit": next(
            row for row in time_rows if not row["under_hard_limit"]
        ),
        "rows": time_rows,
    }
    return {
        "method": (
            f"Each sweep starts from the canonical "
            f"{len(canonical_destinations)}-position/"
            f"{len(canonical_times)}-time catalog. One family is held fixed "
            "while distinct, full-width rows are added to the other."
        ),
        "safety_limit_bytes": RHAI_SAFETY_LIMIT_BYTES,
        "hard_limit_bytes": RHAI_HARD_LIMIT_BYTES,
        "canonical": position_rows[0],
        "upper_limit_from_canonical_without_removing_destinations": {
            "safety": time_safety_rows[-1],
            "hard": time_hard_rows[-1],
            "reason": (
                "Time reveal wrappers are smaller, so adding only time rows "
                "maximizes the total count from the canonical catalog."
            ),
        },
        "position_expansion": position_expansion,
        "time_expansion": time_expansion,
    }
def derived_counts(actions: list[dict[str, Any]], classes: list[str]) -> tuple[dict[str, int], dict[str, int]]:
    family_counts = Counter(action["family"] for action in actions)
    bridge_counts = Counter(
        obj["class"]
        for action in actions
        for obj in action["objects"]
    )
    action_counts = dict(sorted(family_counts.items()))
    action_counts["total"] = len(actions)
    bridges = {class_name: bridge_counts[class_name] for class_name in classes}
    bridges["total"] = sum(bridge_counts.values())
    return action_counts, bridges


def schema_sidecar(classes: list[str]) -> dict[str, Any]:
    validate_all_schema_field_types()
    result = {
        "project_record_arity_cap": 256,
        "largest_listed_key_count": max(len(SCHEMAS[name]) for name in classes),
        "classes": {
            name: {
                "listed_key_count": len(SCHEMAS[name]),
                "fields": [{"name": field, "type": field_type} for field, field_type in SCHEMAS[name]],
                "sdk_managed_live_fields": ["type", "work"],
            }
            for name in classes
        },
    }
    for class_name, expected_schema in EXPECTED_WARP_OBJECT_SCHEMAS.items():
        if class_name not in classes:
            continue
        fields = result["classes"][class_name]["fields"]
        expected_fields = [
            {"name": field_name, "type": field_type}
            for field_name, field_type in expected_schema
        ]
        if fields != expected_fields:
            raise ValueError(
                f"schema sidecar differs from exact warp schema for {class_name}"
            )
    return result


def civilization_tech_catalog(
    bank: list[dict[str, Any]],
    actions: list[dict[str, Any]],
    classes: list[str],
) -> dict[str, Any]:
    by_name = {action["name"]: action for action in actions}
    candidates_by_code = {candidate["code"]: candidate for candidate in bank}

    def roles(name: str) -> list[dict[str, str]]:
        return [
            {"mode": item["mode"], "class": item["class"]}
            for item in by_name[name]["objects"]
        ]

    body_categories = []
    for category in BODY_TREE_CATEGORIES:
        candidate = candidates_by_code[category["candidate_code"]]
        body_categories.append(
            {
                **category,
                "candidate_name": candidate["name"],
                "candidate_slug": candidate["slug"],
                "detect_action": (
                    f"DetectCelestialSignal_{candidate['code']:02d}_"
                    f"{candidate['slug']}"
                ),
                "materialize_action": (
                    f"ScanCelestialBody_{candidate['code']:02d}_"
                    f"{candidate['slug']}"
                ),
                "initial_life_stat": 0,
                "life_detection_action": (
                    "DetectIntelligentLife"
                    if candidate["code"]
                    in INTELLIGENT_LIFE_CANDIDATE_CODES
                    else None
                ),
                "life_selection_mode": (
                    DETERMINISTIC_SELECTOR_MODE
                    if candidate["code"]
                    in INTELLIGENT_LIFE_CANDIDATE_CODES
                    else "not_eligible"
                ),
            }
        )

    resources = []
    for resource in CIVILIZATION_TECH_RESOURCES:
        candidate = candidates_by_code[resource["candidate_code"]]
        resources.append(
            {
                **resource,
                "body_type": candidate["body_type"],
                "body_profile": candidate["body_profile"],
                "life_stat": candidate["life_stat"],
                "roles": roles(resource["action"]),
            }
        )

    parents_by_name = {
        parent_name: [
            resource
            for resource in CIVILIZATION_TECH_RESOURCES
            if resource["name"] == parent_name
        ]
        for parent_name, _children in _REFINEMENT_GROUP_ROWS
    }
    refinement_routes = [
        {
            **route,
            "parent_resource_code": SOURCE_RESOURCE_CODES[
                route["parent_name"]
            ],
            "candidate_codes": [
                resource["candidate_code"]
                for resource in parents_by_name[route["parent_name"]]
            ],
            "extraction_actions": [
                resource["action"]
                for resource in parents_by_name[route["parent_name"]]
            ],
            "extraction_skill_codes": [
                resource["skill_code"]
                for resource in parents_by_name[route["parent_name"]]
            ],
            "roles": roles(route["action"]),
        }
        for route in REFINEMENT_ROUTES
    ]
    refined_resources = [
        {
            "code": resource_code,
            "name": resource_name,
            "slug": _slug(resource_name),
            "source_routes": [
                route["action"]
                for route in REFINEMENT_ROUTES
                if route["child_name"] == resource_name
            ],
            "source_count": sum(
                route["child_name"] == resource_name
                for route in REFINEMENT_ROUTES
            ),
            "total_maximum_units": sum(
                child["maximum_units"]
                for resource in CIVILIZATION_TECH_RESOURCES
                for child in resource["child_allocations"]
                if child["name"] == resource_name
            ),
        }
        for resource_name, resource_code in REFINED_RESOURCE_CODES.items()
    ]

    civilization_types = [
        {
            **civilization_type,
            "roles": roles(civilization_type["action"]),
            "immutable": True,
        }
        for civilization_type in CIVILIZATION_TYPES
    ]
    skills = [
        {**skill, "roles": roles(skill["action"])}
        for skill in TECHNOLOGY_SKILLS
    ]
    components = [
        {
            **component,
            "roles": {
                mode: roles(action_name)
                for mode, action_name in component["actions"].items()
            },
        }
        for component in COMPONENT_RECIPES
    ]
    detect_actions = [
        f"DetectCelestialSignal_{candidate['code']:02d}_{candidate['slug']}"
        for candidate in bank
    ]
    body_materializers = [
        f"ScanCelestialBody_{candidate['code']:02d}_{candidate['slug']}"
        for candidate in bank
    ]
    civilization_routes: dict[str, list[str]] = {}
    for civilization_type in CIVILIZATION_TYPES:
        civilization_routes[civilization_type["slug"]] = [
            civilization_type["action"],
        ]
        civilization_routes[civilization_type["slug"]].extend(
            skill["action"]
            for skill in TECHNOLOGY_SKILLS
            if skill["civilization_type"] == civilization_type["code"]
        )
    action_counts, bridge_counts = derived_counts(actions, classes)
    catalog = {
        "schema_version": 2,
        "catalog_version": "2.0.0",
        "protocol_versions": dict(VERSIONS),
        "version": 4,
        "vdf_profile": ACTIVE_VDF_PROFILE,
        "vdf_difficulty_tiers": VDF_DIFFICULTY_TIERS,
        "ship_build_vdf": {
            tier["name"]: tier["build_vdf"] for tier in SHIP_TIERS
        },
        "base_extraction_vdf": BASE_EXTRACTION_VDF,
        "technology_skill_class": TECHNOLOGY_SKILL,
        "composite_resource_class": COMPOSITE_RESOURCE,
        "body_categories": body_categories,
        "resources": resources,
        "refinement_routes": refinement_routes,
        "refined_resources": refined_resources,
        "civilization_types": civilization_types,
        "technology_skills": skills,
        "components": components,
        "use_technology_skill": {
            "action": "UseTechnologySkill",
            "prerequisite_action": "DevelopTypeIIndustrialFabricationSkill",
            "sample_skill_type": 1,
            "reusable": 1,
            "roles": roles("UseTechnologySkill"),
        },
        "materializers": {
            "detect_actions": detect_actions,
            "body_actions": body_materializers,
            "civilization_actions": [
                item["action"] for item in CIVILIZATION_TYPES
            ],
            "body_roles": roles(body_materializers[0]),
            "civilization_roles": roles(CIVILIZATION_TYPES[0]["action"]),
        },
        "integrated_routes": {
            "resource_categories": {
                category["name"]: [
                    resource["action"]
                    for resource in CIVILIZATION_TECH_RESOURCES
                    if resource["category"] == category["name"]
                ]
                for category in BODY_TREE_CATEGORIES
            },
            "civilization": civilization_routes,
            "use_sample": [
                "MaterializeCivilizationTypeI",
                "DevelopTypeIIndustrialFabricationSkill",
                "UseTechnologySkill",
            ],
        },
        "derived_counts": {
            "class_count": len(classes),
            "action_count": action_counts["total"],
            "bridge_count": bridge_counts["total"],
            "resource_action_count": len(CIVILIZATION_TECH_RESOURCES),
            "composite_resource_route_count": sum(
                resource["composite"]
                for resource in CIVILIZATION_TECH_RESOURCES
            ),
            "composite_resource_count": len(_REFINEMENT_GROUP_ROWS),
            "source_resource_type_count": len(SOURCE_RESOURCE_CODES),
            "refinement_route_action_count": len(REFINEMENT_ROUTES),
            "refined_resource_count": len(REFINED_RESOURCE_CODES),
            "civilization_type_action_count": len(CIVILIZATION_TYPES),
            "technology_skill_action_count": len(TECHNOLOGY_SKILLS),
            "technology_skill_use_action_count": 1,
            "component_count": len(COMPONENT_RECIPES),
            "component_action_count": 2 * len(COMPONENT_RECIPES),
            "vdf_action_count": (
                10
                + sum(
                    tier is not None and tier["move_vdf"] is not None
                    for _name, _axis, _positive, tier in movement_variants()
                )
                + sum(
                    resource["vdf_iterations"] is not None
                    for resource in CIVILIZATION_TECH_RESOURCES
                )
                + sum(
                    route["vdf_iterations"] is not None
                    for route in REFINEMENT_ROUTES
                )
            ),
        },
    }
    if ACTIVE_VDF_PROFILE == "economy":
        catalog["ship_movement_vdf"] = {
            tier["name"]: tier["move_vdf"] for tier in SHIP_TIERS
        }
    return catalog


def rhai_wrapper_literals(source: str) -> list[int | str | bool]:
    """Return the typed scalar literals that occur in one fixed wrapper.

    The catalog index keeps richer route metadata under ``fixed_literals``.
    This separate list is intentionally lexical and flat so a validator can
    prove that every indexed scalar is actually present in the emitted Rhai
    wrapper without mistaking descriptive metadata for executable literals.
    """
    tokens = re.finditer(
        r'"(?:\\.|[^"\\])*"|'
        r'(?<![A-Za-z0-9_])-?\d+(?![A-Za-z0-9_])|\b(?:true|false)\b',
        mask_rhai_comments(source),
    )
    result: list[int | str | bool] = []
    seen: set[tuple[type[Any], Any]] = set()
    for match in tokens:
        token = match.group(0)
        if token.startswith('"'):
            value: int | str | bool = json.loads(token)
        elif token == "true":
            value = True
        elif token == "false":
            value = False
        else:
            value = int(token)
        key = (type(value), value)
        if key not in seen:
            seen.add(key)
            result.append(value)
    return result


def rhai_wrapper_helpers(source: str) -> list[str]:
    """List direct plain helper calls made by one wrapper.

    Method calls are excluded by the negative dot lookbehind, and the wrapper's
    own declaration is removed.  This deliberately includes short shared
    reveal helpers as well as names ending in ``_core``.
    """
    declaration = re.search(
        r"\bfn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(",
        mask_rhai_noncode(source),
    )
    declared_name = declaration.group(1) if declaration else None
    result: list[str] = []
    for helper, _arguments, _position in rhai_plain_statement_calls(source):
        if helper != declared_name and helper not in result:
            result.append(helper)
    return result


def expansion_catalog_index(
    bank: list[dict[str, Any]],
    actions: list[dict[str, Any]],
) -> dict[str, Any]:
    """Build the generator-owned v2 action and production provenance index."""
    source_map = sources_for_bank(bank)
    body_by_code = {body["code"]: body for body in bank}
    parent_codes = {
        resource["name"]: resource["code"]
        for resource in CIVILIZATION_TECH_RESOURCES
    }
    refinement_by_parent_slot = {
        (route["parent_name"], route["child_slot"]): route
        for route in REFINEMENT_ROUTES
    }
    component_by_action = {
        action_name: (component, mode)
        for component in COMPONENT_RECIPES
        for mode, action_name in component["actions"].items()
    }
    derived_skill_by_action = {
        skill["action"]: skill for skill in DERIVED_SKILLS
    }
    capability_by_action = {
        capability["action"]: capability
        for capability in SKILL_CAPABILITIES
    }
    warp_destination_by_action = {
        f"RevealWarpCoordinate{row['slug']}": ("v1.position", row)
        for row in POSITION_WARP_DESTINATIONS
    }
    warp_destination_by_action.update(
        {
            f"RevealTimeCoordinate{row['slug']}": ("v1.time", row)
            for row in TIME_WARP_DESTINATIONS
        }
    )
    warp_destination_by_action.update(
        {
            row["reveal_action"]: ("v2.position", row)
            for row in POSITION_CHART_DESTINATIONS
        }
    )
    warp_destination_by_action.update(
        {
            row["reveal_action"]: ("v2.time", row)
            for row in EPOCH_CHART_DESTINATIONS
        }
    )
    literal_fields = (
        "candidate_code",
        "skill_code",
        "resource_code",
        "parent_resource_code",
        "component_code",
        "catalyst_mode",
        "base_extraction_action",
        "extraction_ship_tier",
        "output_skill_code",
        "skill_tier",
        "route_key",
        "warp_catalog",
        "warp_recipe",
        "destination_code",
        "uses",
        "selection_mode",
        "selector_subject",
        "selector_band",
        "signal_category_code",
        "output_candidate_code",
        "required_signal_candidate_code",
        "survey_profile",
        "minimum_claim_serial",
        "civilization_type",
        "minimum_civilization_scan_serial",
        "initial_life_stat",
        "selected_life_stat",
        "candidate_codes",
        "minimum_source_pool_inclusive",
        "direction",
        "final_use",
        "vdf_iterations",
    )
    action_index = []
    for action in actions:
        fixed_literals = {
            field: action[field]
            for field in literal_fields
            if field in action and action[field] is not None
        }
        if action["name"] in component_by_action:
            component, mode = component_by_action[action["name"]]
            fixed_literals["component"] = {
                "code": component["code"],
                "output_amount": component["output_amount"],
                "skill_code": component["skill_code"],
                "materials": component["materials"],
                "catalyst_resource_code": component["catalyst"][
                    "resource_code"
                ],
                "catalyst_mode": mode,
                "catalyst_role_index": 6,
                "catalyst_units_per_craft": 1,
                "vdf_iterations": component["vdf_iterations"],
            }
        if action["name"] in derived_skill_by_action:
            skill = derived_skill_by_action[action["name"]]
            fixed_literals["derived_skill"] = {
                "output_skill_code": skill["code"],
                "parent_skill_code": skill["parent_code"],
                "tier": skill["tier"],
                "evidence": skill["items"],
                "vdf_iterations": skill["vdf_iterations"],
            }
        if action["name"] in capability_by_action:
            capability = capability_by_action[action["name"]]
            fixed_literals["capability_artifact"] = {
                "skill_code": capability["skill_code"],
                "route_key": capability["route_key"],
                "resource_code": capability["output_resource_code"],
                "amount": capability["output_amount"],
                "fixed_inputs": capability["fixed_inputs"],
                "vdf_iterations": capability["vdf_iterations"],
            }
        if action["name"] in warp_destination_by_action:
            catalog_name, destination = warp_destination_by_action[action["name"]]
            fixed_literals["warp_destination"] = {
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
        wrapper_source = source_map[action["name"]]
        action_index.append(
            {
                "name": action["name"],
                "family": action["family"],
                "roles": action["objects"],
                "fixed_literals": fixed_literals,
                "wrapper_literals": rhai_wrapper_literals(wrapper_source),
                "helpers": rhai_wrapper_helpers(wrapper_source),
            }
        )

    production: list[dict[str, Any]] = []
    for resource_name, resource_code, remaining_field in (
        ("Matter", 1, "matter_remaining"),
        ("Crystal", 2, "crystal_remaining"),
        ("Gas", 3, "gas_remaining"),
        ("Energy", 4, "energy_remaining"),
    ):
        for action_name, tier in extraction_tier_variants(
            f"Extract{resource_name}", 0
        ):
            production.append(
                {
                    "kind": "base_extraction",
                    "resource_code": resource_code,
                    "resource_name": resource_name,
                    "amount": tier["extraction_amount"],
                    "source_body_code": None,
                    "source_body": None,
                    "source_pool": remaining_field,
                    "action": action_name,
                    "ship_tier": tier["name"],
                }
            )
    for resource in CIVILIZATION_TECH_RESOURCES:
        body = body_by_code[resource["candidate_code"]]
        for extraction_action, tier in extraction_tier_variants(
            resource["action"], resource["minimum_ship_tier"]
        ):
            if not resource["composite"]:
                production.append(
                    {
                        "kind": "direct_extraction",
                        "resource_code": resource["code"],
                        "resource_name": resource["name"],
                        "amount": tier["extraction_amount"],
                        "source_body_code": body["code"],
                        "source_body": body["name"],
                        "source_pool": resource["remaining_field"],
                        "action": extraction_action,
                        "ship_tier": tier["name"],
                    }
                )
                continue
            child_amounts = composite_child_amounts(
                resource["child_allocations"],
                tier["extraction_amount"],
                route_name=extraction_action,
                ship_tier_name=tier["name"],
            )
            for child, amount in zip(
                sorted(resource["child_allocations"], key=lambda item: item["slot"]),
                child_amounts,
                strict=True,
            ):
                route = refinement_by_parent_slot[
                    (resource["name"], child["slot"])
                ]
                production.append(
                    {
                        "kind": "refinement",
                        "resource_code": child["resource_code"],
                        "resource_name": child["name"],
                        "amount": amount,
                        "source_body_code": body["code"],
                        "source_body": body["name"],
                        "source_pool": resource["remaining_field"],
                        "parent_resource_code": resource["code"],
                        "parent_resource_name": resource["name"],
                        "child_slot": child["slot"],
                        "source_extraction_action": extraction_action,
                        "action": route["action"],
                        "ship_tier": tier["name"],
                    }
                )
    for component in COMPONENT_RECIPES:
        for mode, action_name in component["actions"].items():
            production.append(
                {
                    "kind": "component_fabrication",
                    "resource_code": component["code"],
                    "resource_name": component["name"],
                    "amount": component["output_amount"],
                    "source_body_code": None,
                    "source_body": None,
                    "action": action_name,
                    "ship_tier": None,
                    "catalyst_mode": mode,
                }
            )
    for capability in SKILL_CAPABILITIES:
        production.append(
            {
                "kind": "capability_artifact",
                "resource_code": capability["output_resource_code"],
                "resource_name": capability["output_resource_name"],
                "amount": capability["output_amount"],
                "source_body_code": None,
                "source_body": None,
                "action": capability["action"],
                "ship_tier": None,
                "skill_code": capability["skill_code"],
                "route_key": capability["route_key"],
            }
        )
    for production_row in production:
        production_row["source_body_name"] = production_row.get(
            "source_body"
        )
        production_row["actions"] = [production_row["action"]]

    skill_gates: list[dict[str, Any]] = []
    for resource in CIVILIZATION_TECH_RESOURCES:
        if resource["skill_code"] is None:
            continue
        skill_gates.append(
            {
                "skill_code": resource["skill_code"],
                "family": "extraction",
                "route_key": (
                    f"body:{resource['candidate_code']}:resource:{resource['code']}"
                ),
                "actions": [
                    action_name
                    for action_name, _tier in extraction_tier_variants(
                        resource["action"], resource["minimum_ship_tier"]
                    )
                ],
            }
        )
    for route in REFINEMENT_ROUTES:
        skill_gates.append(
            {
                "skill_code": route["skill_code"],
                "family": "refinement",
                "route_key": (
                    f"parent:{parent_codes[route['parent_name']]}:slot:"
                    f"{route['child_slot']}"
                ),
                "actions": [route["action"]],
            }
        )
    for component in COMPONENT_RECIPES:
        skill_gates.append(
            {
                "skill_code": component["skill_code"],
                "family": "component",
                "route_key": f"component:{component['code']}",
                "actions": [
                    component["actions"]["reusable"],
                    component["actions"]["final"],
                ],
            }
        )
    for skill in DERIVED_SKILLS:
        skill_gates.append(
            {
                "skill_code": skill["parent_code"],
                "family": "derived_skill_development",
                "route_key": f"skill:{skill['code']}:develop",
                "actions": [skill["action"]],
                "output_skill_code": skill["code"],
            }
        )
    for capability in SKILL_CAPABILITIES:
        skill_gates.append(
            {
                "skill_code": capability["skill_code"],
                "family": capability["action_family"],
                "route_key": capability["route_key"],
                "actions": [capability["action"]],
                "output_resource_code": capability[
                    "output_resource_code"
                ],
            }
        )
    skill_gates.extend(
        [
            {
                "skill_code": WARP_SKILL_TYPE,
                "family": "warp_coordinate_extraction",
                "route_key": "warp-coordinate:position",
                "actions": ["ExtractAnomalyWarpCoordinate"],
            },
            {
                "skill_code": WARP_SKILL_TYPE,
                "family": "warp_coordinate_extraction",
                "route_key": "warp-coordinate:time",
                "actions": ["ExtractAnomalyTimeCoordinate"],
            },
        ]
    )
    if POSITION_CHART_DESTINATIONS:
        skill_gates.extend(
            [
                {
                    "skill_code": 11,
                    "family": "extract_position_chart",
                    "route_key": "warp:v2:position:extract",
                    "actions": ["ExtractWormholeWarpChart"],
                },
                {
                    "skill_code": 14,
                    "family": "extract_epoch_chart",
                    "route_key": "warp:v2:time:extract",
                    "actions": ["ExtractWormholeEpochChart"],
                },
                {
                    "skill_code": 50,
                    "family": "reveal_position_chart",
                    "route_key": "warp:v2:position:reveal",
                    "actions": [
                        destination["reveal_action"]
                        for destination in POSITION_CHART_DESTINATIONS
                    ],
                },
                {
                    "skill_code": 51,
                    "family": "warp_ship_to_position_chart",
                    "route_key": "warp:v2:position:use",
                    "actions": [
                        "WarpShipToPositionCoordinateReusable",
                        "WarpShipToPositionCoordinateFinal",
                    ],
                },
                {
                    "skill_code": 58,
                    "family": "reveal_epoch_chart",
                    "route_key": "warp:v2:time:reveal",
                    "actions": [
                        destination["reveal_action"]
                        for destination in EPOCH_CHART_DESTINATIONS
                    ],
                },
                {
                    "skill_code": 58,
                    "family": "warp_ship_to_epoch_chart",
                    "route_key": "warp:v2:time:use",
                    "actions": [
                        "WarpShipToEpochCoordinateReusable",
                        "WarpShipToEpochCoordinateFinal",
                    ],
                },
                {
                    "skill_code": 49,
                    "family": "capture_position_anchor",
                    "route_key": "warp:v2:position-anchor:capture",
                    "actions": ["CapturePositionAnchor"],
                },
                {
                    "skill_code": 60,
                    "family": "capture_time_anchor",
                    "route_key": "warp:v2:time-anchor:capture",
                    "actions": ["CaptureTimeAnchor"],
                },
                {
                    "skill_code": 59,
                    "family": "wormhole_link",
                    "route_key": "warp:v2:wormhole-link",
                    "actions": [
                        "ConstructWormholeLink",
                        "TraverseWormholeAToBReusable",
                        "TraverseWormholeAToBFinal",
                        "TraverseWormholeBToAReusable",
                        "TraverseWormholeBToAFinal",
                    ],
                },
                {
                    "skill_code": 60,
                    "family": "temporal_link",
                    "route_key": "warp:v2:temporal-link",
                    "actions": [
                        "ConstructTemporalLink",
                        "TraverseTemporalAToBReusable",
                        "TraverseTemporalAToBFinal",
                        "TraverseTemporalBToAReusable",
                        "TraverseTemporalBToAFinal",
                    ],
                },
                {
                    "skill_code": 86,
                    "family": "rendezvous_coordinate",
                    "route_key": "warp:v2:rendezvous",
                    "actions": [
                        "ComposeRendezvousCoordinate",
                        "WarpToRendezvousCoordinateReusable",
                        "WarpToRendezvousCoordinateFinal",
                    ],
                },
            ]
        )

    resource_codes = {
        **BASE_RESOURCE_CODES,
        **SOURCE_RESOURCE_CODES,
        **REFINED_RESOURCE_CODES,
        **{component["name"]: component["code"] for component in COMPONENT_RECIPES},
        **{
            capability["output_resource_name"]: capability[
                "output_resource_code"
            ]
            for capability in SKILL_CAPABILITIES
        },
    }
    warp_catalog = EXPANSION_CATALOGS.get("warp", {})
    frozen_warp_hashes = warp_catalog.get("frozen_v1_fingerprints", {})
    v2_warp_hashes = warp_catalog.get("v2_fingerprints", {})
    warp_object_types = [
        {
            "class_name": item.get("class_name"),
            "schema_fields": item.get("schema_fields", []),
            "creation_actions": [
                action.get("name")
                for action in item.get("creation_actions", [])
            ],
            "use_actions": [
                action.get("name")
                for action in item.get("use_actions", [])
            ],
        }
        for item in warp_catalog.get("object_types", [])
    ]
    for item in warp_object_types:
        class_name = item["class_name"]
        expected_schema = EXPECTED_WARP_OBJECT_SCHEMAS.get(class_name)
        expected_fields = (
            [
                {"name": field_name, "type": field_type}
                for field_name, field_type in expected_schema
            ]
            if expected_schema is not None
            else None
        )
        installed_fields = [
            {"name": field_name, "type": field_type}
            for field_name, field_type in SCHEMAS.get(class_name, [])
        ]
        if (
            expected_fields is None
            or item["schema_fields"] != expected_fields
            or installed_fields != expected_fields
        ):
            raise ValueError(
                f"catalog/index/SCHEMAS warp field contract differs for {class_name}"
            )
    warp_provenance = {
        "catalog_id": warp_catalog.get("catalog_id"),
        "catalog_version": warp_catalog.get("catalog_version"),
        "versions": warp_catalog.get("versions", {}),
        "selection_semantics": warp_catalog.get("selection_semantics"),
        "use_capacity_policy": warp_catalog.get("use_capacity_policy"),
        "catalogs": [
            {
                "catalog": "v1.position",
                "object_class": WARP_COORDINATE,
                "row_count": len(POSITION_WARP_DESTINATIONS),
                "row_sha256": frozen_warp_hashes.get("position_sha256"),
                "reveal_action_prefix": "RevealWarpCoordinate",
                "selection_mode": EXPLICIT_SELECTION_MODE,
                "capacity_selection": warp_catalog.get("v1", {})
                .get("position", {})
                .get("capacity_selection"),
            },
            {
                "catalog": "v1.time",
                "object_class": TIME_COORDINATE,
                "row_count": len(TIME_WARP_DESTINATIONS),
                "row_sha256": frozen_warp_hashes.get("time_sha256"),
                "reveal_action_prefix": "RevealTimeCoordinate",
                "selection_mode": EXPLICIT_SELECTION_MODE,
                "capacity_selection": warp_catalog.get("v1", {})
                .get("time", {})
                .get("capacity_selection"),
            },
            {
                "catalog": "v2.position",
                "object_class": WARP_CHART,
                "row_count": len(POSITION_CHART_DESTINATIONS),
                "row_sha256": v2_warp_hashes.get(
                    "position_full_rows_sha256"
                ),
                "reveal_action_prefix": "RevealWarpChart",
                "selection_mode": EXPLICIT_SELECTION_MODE,
                "capacity_selection": warp_catalog.get("v2", {})
                .get("position", {})
                .get("capacity_selection"),
            },
            {
                "catalog": "v2.time",
                "object_class": EPOCH_CHART,
                "row_count": len(EPOCH_CHART_DESTINATIONS),
                "row_sha256": v2_warp_hashes.get("time_full_rows_sha256"),
                "reveal_action_prefix": "RevealEpochChart",
                "selection_mode": EXPLICIT_SELECTION_MODE,
                "capacity_selection": warp_catalog.get("v2", {})
                .get("time", {})
                .get("capacity_selection"),
            },
        ],
        "object_types": warp_object_types,
        "recipes": WARP_RECIPES,
        "link_endpoint_policy": warp_catalog.get(
            "validation_contract", {}
        ).get("link_endpoint_distinctness"),
    }
    return {
        "catalog_id": "microverse-catalog-index-v2",
        "schema_version": 2,
        "catalog_version": "2.1.0",
        "source_catalogs": {
            name: {
                "identity": catalog.get("catalog_name")
                or catalog.get("catalog_id")
                or catalog.get("catalog_version"),
                "schema_version": catalog.get("schema_version"),
            }
            for name, catalog in sorted(EXPANSION_CATALOGS.items())
        },
        "versions": dict(VERSIONS),
        "counts": {
            "actions": len(actions),
            "action_families": dict(
                sorted(Counter(action["family"] for action in actions).items())
            ),
            "resource_types": len(resource_codes),
            "source_resources": len(SOURCE_RESOURCE_CODES),
            "refined_resources": len(REFINED_RESOURCE_CODES),
            "components": len(COMPONENT_RECIPES),
            "derived_skills": len(DERIVED_SKILLS),
            "capability_artifacts": len(SKILL_CAPABILITIES),
            "warp_destination_rows": (
                len(POSITION_WARP_DESTINATIONS)
                + len(TIME_WARP_DESTINATIONS)
                + len(POSITION_CHART_DESTINATIONS)
                + len(EPOCH_CHART_DESTINATIONS)
            ),
            "warp_actions": sum(
                action["family"]
                in {
                    "extract_warp_coordinate",
                    "reveal_warp_coordinate",
                    "warp_to_coordinate",
                    "extract_time_coordinate",
                    "reveal_time_coordinate",
                    "time_warp_to_coordinate",
                    "extract_position_chart",
                    "extract_epoch_chart",
                    "reveal_position_chart",
                    "reveal_epoch_chart",
                    "warp_ship_to_position_chart",
                    "warp_ship_to_epoch_chart",
                    "capture_position_anchor",
                    "capture_time_anchor",
                    "construct_wormhole_link",
                    "construct_temporal_link",
                    "traverse_wormhole_link",
                    "traverse_temporal_link",
                    "compose_rendezvous_coordinate",
                    "warp_to_rendezvous_coordinate",
                }
                for action in actions
            ),
            "production_routes": len(production),
            "logical_skill_gates": len(skill_gates),
        },
        "resource_codes": dict(
            sorted(resource_codes.items(), key=lambda item: item[1])
        ),
        "resource_code_rows": [
            {"name": name, "code": code}
            for name, code in sorted(
                resource_codes.items(), key=lambda item: item[1]
            )
        ],
        "actions": action_index,
        "production": production,
        "skill_gates": skill_gates,
        "warp": warp_provenance,
    }


@lru_cache(maxsize=4096)
def mask_rhai_noncode(source: str) -> str:
    """Mask comments and strings while preserving line numbers for source audits."""

    def mask(match: re.Match[str]) -> str:
        return "".join("\n" if char == "\n" else " " for char in match.group(0))

    return re.sub(
        r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/',
        mask,
        source,
        flags=re.DOTALL,
    )


def mask_rhai_comments(source: str) -> str:
    """Mask comments without treating comment markers inside strings as syntax."""

    def mask(match: re.Match[str]) -> str:
        token = match.group(0)
        if token.startswith('"'):
            return token
        return "".join("\n" if char == "\n" else " " for char in token)

    return re.sub(
        r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/',
        mask,
        source,
        flags=re.DOTALL,
    )


def straight_line_rhai_audit(plugin: str) -> dict[str, Any]:
    """Reject Rhai constructs outside DON's straight-line action model.

    The DON SDK loads every action symbolically before executing it with concrete
    inputs.  Generated gameplay therefore uses only fixed function dispatch and
    registered ActionHandle/ArgHandle operations: never Rhai control flow,
    recursion, dynamic calls, or prover-selectable action routing.
    """

    code = mask_rhai_noncode(plugin)
    forbidden_words = (
        "if",
        "else",
        "switch",
        "for",
        "while",
        "loop",
        "do",
        "break",
        "continue",
        "return",
        "throw",
        "try",
        "catch",
        "import",
        "export",
    )
    forbidden_word_lines = {
        word: [
            code.count("\n", 0, match.start()) + 1
            for match in re.finditer(rf"\b{word}\b", code)
        ]
        for word in forbidden_words
    }
    forbidden_word_lines = {
        word: lines for word, lines in forbidden_word_lines.items() if lines
    }

    forbidden_operator_counts = {
        operator: code.count(operator)
        for operator in ("==", "!=", "<=", ">=", "&&", "||", "??")
        if code.count(operator)
    }
    forbidden_dynamic_calls = {
        call: len(re.findall(rf"\b{call}\s*\(", code))
        for call in ("eval", "call", "call_fn", "curry", "Fn")
        if re.search(rf"\b{call}\s*\(", code)
    }

    definitions = re.findall(
        r"(?m)^fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(",
        code,
    )
    definition_set = set(definitions)
    duplicate_definitions = sorted(
        name for name, count in Counter(definitions).items() if count != 1
    )
    action_names = set(
        re.findall(
            r"(?m)^fn\s+([A-Z][A-Za-z0-9_]*)\s*\(action\)\s*\{",
            code,
        )
    )

    allowed_plain_calls = {"var_assign"}
    allowed_methods = {
        "output",
        "input",
        "mutate",
        "random",
        "st_gt",
        "st_sum",
        "intro_vdf",
        "intro_lt_eq_u256",
        "pow_obj_grind",
        "top_limb_u256",
        "set",
        "update",
    }
    unknown_plain_calls: dict[str, list[str]] = {}
    action_to_action_calls: dict[str, list[str]] = {}
    unextractable_functions: list[str] = []
    call_graph: dict[str, set[str]] = {name: set() for name in definitions}
    for name in definitions:
        source = raw_named_function_source(code, name)
        if not source:
            unextractable_functions.append(name)
            continue
        body = source[source.find("{") + 1 : source.rfind("}")]
        plain_calls = set(
            re.findall(
                r"(?<![.A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(",
                body,
            )
        )
        unknown = sorted(plain_calls - definition_set - allowed_plain_calls)
        if unknown:
            unknown_plain_calls[name] = unknown
        routed_actions = sorted(plain_calls & action_names)
        if routed_actions:
            action_to_action_calls[name] = routed_actions
        call_graph[name] = plain_calls & definition_set

    method_names = set(
        re.findall(r"\.([A-Za-z_][A-Za-z0-9_]*)\s*\(", code)
    )
    unknown_methods = sorted(method_names - allowed_methods)

    visiting: set[str] = set()
    visited: set[str] = set()
    recursive_cycles: list[list[str]] = []

    def visit(name: str, path: list[str]) -> None:
        if name in visiting:
            start = path.index(name)
            recursive_cycles.append(path[start:] + [name])
            return
        if name in visited:
            return
        visiting.add(name)
        for callee in sorted(call_graph[name]):
            visit(callee, path + [callee])
        visiting.remove(name)
        visited.add(name)

    for name in definitions:
        visit(name, [name])

    checks = {
        "no_control_flow_keywords": not forbidden_word_lines,
        "no_control_flow_operators": not forbidden_operator_counts,
        "no_dynamic_function_calls": not forbidden_dynamic_calls,
        "unique_function_definitions": not duplicate_definitions,
        "all_functions_have_canonical_source_shape": not unextractable_functions,
        "only_defined_plain_calls": not unknown_plain_calls,
        "only_registered_sdk_methods": not unknown_methods,
        "no_action_to_action_calls": not action_to_action_calls,
        "no_recursive_call_cycles": not recursive_cycles,
        "no_subactions": ".subaction(" not in code,
    }
    status_checks = checks if ACTIVE_VDF_PROFILE == "economy" else {
        key: value for key, value in checks.items()
        if key not in {"action_count_exact", "logical_intro_calls_exact", "phase5_bulk_physical_ledger_exact", "phase1_logical_ledger_exact"}
    }
    return {
        "status": "pass" if all(status_checks.values()) else "fail",
        "profile": ACTIVE_VDF_PROFILE,
        "canonical_release_profile": ACTIVE_VDF_PROFILE == "economy",
        "checks": checks,
        "forbidden_word_lines": forbidden_word_lines,
        "forbidden_operator_counts": forbidden_operator_counts,
        "forbidden_dynamic_calls": forbidden_dynamic_calls,
        "duplicate_definitions": duplicate_definitions,
        "unextractable_functions": unextractable_functions,
        "unknown_plain_calls": unknown_plain_calls,
        "unknown_methods": unknown_methods,
        "action_to_action_calls": action_to_action_calls,
        "recursive_cycles": recursive_cycles,
        "function_count": len(definitions),
        "action_count": len(action_names),
    }


def physical_proof_counts(source: str) -> dict[str, int]:
    """Count executable physical proof sites without comment/string forgeries."""
    code = mask_rhai_noncode(source)
    return {
        "st_sum": len(rhai_call_arguments(source, "action.st_sum")),
        "st_gt": len(rhai_call_arguments(source, "action.st_gt")),
        "unsafe": len(re.findall(r"unsafe\s*\{", code)),
        "random": len(rhai_call_arguments(source, "action.random")),
        "var_assign": len(rhai_call_arguments(source, "var_assign")),
        "rotate_key": (
            len(rhai_call_arguments(source, "rotate_key"))
            + max(rhai_function_definition_count(source, "rotate_key"), 0)
        ),
        "intro_vdf": len(rhai_call_arguments(source, "action.intro_vdf")),
        "intro_lt_eq_u256": len(
            rhai_call_arguments(source, "action.intro_lt_eq_u256")
        ),
    }


def field_access_audit(
    plugin: str,
    actions: list[dict[str, Any]],
) -> dict[str, Any]:
    forbidden = [
        "object.get(",
        ".get(",
        "sensor_radius",
        "DockAtSector",
        "dock",
        "modulo",
        ".clock",
        "resource_clock",
        '["clock"',
    ]
    hits = {
        token: (
            len(re.findall(r'\[\s*"clock"\s*\]', mask_rhai_comments(plugin)))
            if token == '["clock"'
            else rhai_token_occurrences(plugin, token)
        )
        for token in forbidden
    }
    deterministic_outputs = [
        SECTOR,
        SIGNAL,
        BODY,
        SATELLITE,
        LIFE_SIGNAL,
        CIVILIZATION,
        WARP_COORDINATE,
        TIME_COORDINATE,
        WARP_CHART,
        EPOCH_CHART,
    ]
    intro = intro_audit(plugin, actions)
    return {
        "status": "pass" if not any(hits.values()) and intro["status"] == "pass" else "fail",
        "forbidden_token_counts": hits,
        "literal_update_calls": sum(
            len(arguments) == 2
            and bool(re.fullmatch(r'"[a-z_]+"', arguments[0]))
            for _handle, method, arguments, _position
            in rhai_method_statement_calls(plugin, "update")
            if method == "update"
        ),
        "unsafe_arithmetic_blocks": physical_proof_counts(plugin)["unsafe"],
        "st_sum_statements": physical_proof_counts(plugin)["st_sum"],
        "st_gt_statements": physical_proof_counts(plugin)["st_gt"],
        "deterministic_output_classes": deterministic_outputs,
        "deterministic_zero_key_updates": len(
            semantic_zero_key_updates(plugin)
        ),
        "intro_audit_status": intro["status"],
        "note": "Unsafe additions/subtractions are each paired with explicit st_sum constraints in generated action templates.",
    }


def intro_audit(
    plugin: str,
    actions: list[dict[str, Any]],
) -> dict[str, Any]:
    """Validate every logical Intro call against per-action metadata.

    Direct action calls and calls owned by approved straight-line helpers are
    expanded per wrapper.  This prevents compact layout, multiline calls, or a
    newly introduced helper from silently escaping the audit.
    """

    def handles(source: str) -> dict[str, dict[str, str]]:
        return {
            name: {"mode": mode, "class": class_name}
            for name, mode, class_name in rhai_action_object_bindings(source)
        }

    def vdf_calls(source: str) -> list[tuple[int, str]]:
        calls: list[tuple[int, str]] = []
        for arguments in rhai_call_arguments(source, "action.intro_vdf"):
            if (
                len(arguments) == 2
                and re.fullmatch(r"[0-9]+", arguments[0])
                and re.fullmatch(r"[A-Za-z_]\w*", arguments[1])
            ):
                calls.append((int(arguments[0]), arguments[1]))
            else:
                calls.append((-1, ""))
        return calls

    def comparison_calls(source: str) -> list[tuple[str, str]]:
        return [
            (arguments[0], arguments[1]) if len(arguments) == 2 else ("", "")
            for arguments in rhai_call_arguments(
                source, "action.intro_lt_eq_u256"
            )
        ]

    def helper_calls(source: str, name: str) -> list[list[str]]:
        return rhai_call_arguments(source, name)

    def reveal_helper_audit(
        name: str,
        expected_parameters: list[str],
        object_parameter: str,
        *,
        expected_vdf: int | None,
    ) -> dict[str, Any]:
        source = named_function_source(plugin, name)
        parameters = rhai_function_parameters(source, name)
        stable_identifier_bindings = re.findall(
            r"var_assign\(\s*([A-Za-z_]\w*)\s*,\s*"
            rf"{re.escape(object_parameter)}\.stable_identifier\s*\)",
            mask_rhai_noncode(source),
        )
        comparisons = comparison_calls(source)
        observed_vdf = vdf_calls(source)
        expected_vdfs = (
            []
            if expected_vdf is None
            else [(expected_vdf, object_parameter)]
        )
        checks = {
            "source_present": bool(source),
            "parameters_exact": parameters == expected_parameters,
            "stable_identifier_selection_absent": (
                not stable_identifier_bindings
                and ".stable_identifier" not in source
            ),
            "top_limb_selection_absent": "top_limb_u256" not in source,
            "selection_comparisons_absent": not comparisons,
            "vdf_exact": observed_vdf == expected_vdfs,
        }
        if (
            name in phase4_helper_kinds
            or name in phase5_helper_names
            or name in phase6_vdf_helper_names
        ):
            target = object_parameter
            checks["adapter_work_tail_exact"] = (
                phase4_vdf_work_tail_exact(source, expected_vdf, target)
                if expected_vdf is not None
                else "intro_vdf" not in source and '"work"' not in source
            )
        return {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
            "parameters": parameters,
            "comparisons": comparisons,
            "vdf_calls": observed_vdf,
        }

    helper_specs = {
        "reveal_p": {
            "parameters": [
                "action", "coordinate", "destination_code",
                "destination_x", "destination_y", "destination_z", "uses",
                "minimum_source_pool_exclusive",
            ],
            "object": "coordinate",
            "vdf": None,
        },
        "reveal_t": {
            "parameters": [
                "action", "coordinate", "destination_code",
                "destination_epoch", "uses",
                "minimum_source_pool_exclusive",
            ],
            "object": "coordinate",
            "vdf": None,
        },
        "reveal_chart_p": {
            "parameters": [
                "action", "next_ship", "ship", "chart", "code", "x", "y",
                "z", "uses", "minimum_source_pool_exclusive",
            ],
            "object": "chart",
            "vdf": 20,
        },
        "reveal_chart_t": {
            "parameters": [
                "action", "next_ship", "ship", "chart", "code", "epoch",
                "uses", "minimum_source_pool_exclusive",
            ],
            "object": "chart",
            "vdf": 20,
        },
    }
    phase4_helper_kinds = {
        name: kind
        for name, kind, _iterations, _representative in phase4_helper_specs()
    }
    phase4_parameters = {
        "base": ["action", "next_ship", "resource", "ship", "body", "required_skill_type", "remaining_field", "resource_type", "extraction_amount", "rare_extraction_amount"],
        "body": ["action", "next_ship", "resource", "ship", "body", "candidate_code", "required_skill_type", "remaining_field", "resource_type", "extraction_amount", "rare_extraction_amount"],
        "composite": ["action", "next_ship", "composite_resource", "ship", "body", "candidate_code", "required_skill_type", "remaining_field", "composite_resource_type", "extraction_amount", "rare_extraction_amount", "child_1_amount", "child_2_amount", "child_3_amount"],
        "refine": ["action", "next_ship", "resource", "ship", "parent", "required_skill_type", "parent_resource_type", "child_remaining_field", "output_resource_type"],
    }
    for helper_name, kind, iterations, _representative in phase4_helper_specs():
        helper_specs[helper_name] = {
            "parameters": phase4_parameters[kind],
            "object": "parent" if kind == "refine" else "body",
            "vdf": iterations,
        }
    phase5_helper_names = {spec[0] for spec in PHASE5_ADAPTER_HELPERS}
    component_parameters = [
        "action", "next_ship", "component", "ship", "material_1",
        "material_2", "material_3", "catalyst", "skill_type",
        "material_1_type", "material_1_amount", "material_2_type",
        "material_2_amount", "material_3_type", "material_3_amount",
        "catalyst_type", "component_type", "component_amount",
    ]
    for helper_name, family, shape, iterations, _representative in PHASE5_ADAPTER_HELPERS:
        if family == "component":
            parameters = component_parameters
            object_parameter = "component"
        else:
            evidence_count = int(shape)
            evidence_parameters = [
                f"evidence_{index}" for index in range(1, evidence_count + 1)
            ]
            evidence_literals = [
                item
                for index in range(1, evidence_count + 1)
                for item in (f"evidence_{index}_type", f"evidence_{index}_amount")
            ]
            if family == "derived":
                parameters = [
                    "action", "next_ship", "technology_skill", "ship",
                    *evidence_parameters, "parent_skill_type",
                    "output_skill_type", *evidence_literals,
                ]
                object_parameter = "technology_skill"
            else:
                parameters = [
                    "action", "next_ship", "artifact", "ship",
                    *evidence_parameters, "required_skill_type",
                    "output_resource_type", "output_amount", *evidence_literals,
                ]
                object_parameter = "artifact"
        helper_specs[helper_name] = {
            "parameters": parameters,
            "object": object_parameter,
            "vdf": iterations,
        }
    phase6_vdf_helper_names = {
        helper_name
        for action_name in PHASE6_MOVEMENT_CANARY_ROUTES
        if (helper_name := phase6_vdf_helper_for(action_name)) is not None
    }
    for helper_name, iterations in (
        ("update_ship_work_vdf_4_core", 4),
        ("update_ship_work_vdf_12_core", 12),
        ("update_ship_work_vdf_28_core", 28),
    ):
        if helper_name in phase6_vdf_helper_names:
            helper_specs[helper_name] = {
                "parameters": ["action", "ship"],
                "object": "ship",
                "vdf": iterations,
            }
    helper_audits = {
        name: reveal_helper_audit(
            name,
            spec["parameters"],
            spec["object"],
            expected_vdf=spec["vdf"],
        )
        for name, spec in helper_specs.items()
    }
    scan_source = named_function_source(plugin, "scan_body_core")
    scan_parameters = rhai_function_parameters(scan_source, "scan_body_core")
    expected_scan_parameters = [
        "action", "body", "signal", "ship", "category_code",
        "candidate_code", "target_top_limb", "body_type", "life_stat",
        "matter_remaining", "crystal_remaining", "gas_remaining",
        "energy_remaining", "satellites_remaining",
    ]
    scan_checks = {
        "source_present": bool(scan_source),
        "parameters_exact": scan_parameters == expected_scan_parameters,
        "fixed_threshold_alias_exact": bool(
            re.search(
                r"\blet\s+target\s*=\s*action\.top_limb_u256\(\s*"
                r"target_top_limb\s*\)\s*;",
                mask_rhai_noncode(scan_source),
            )
        ),
        "whole_object_comparison_exact": (
            comparison_calls(scan_source) == [("signal", "target")]
        ),
        "no_vdf": not vdf_calls(scan_source),
    }
    helper_audits["scan_body_core"] = {
        "status": "pass" if all(scan_checks.values()) else "fail",
        "checks": scan_checks,
        "parameters": scan_parameters,
        "comparisons": comparison_calls(scan_source),
        "vdf_calls": vdf_calls(scan_source),
    }

    helper_names = set(helper_audits)
    expected_action_names = {action["name"] for action in actions}
    defined_action_names = set(rhai_action_function_names(plugin))
    calls: list[dict[str, Any]] = []
    action_details: dict[str, Any] = {}
    expected_vdf_actions: set[str] = set()
    expected_threshold_actions: set[str] = set()
    expected_explicit_selection_actions: set[str] = set()
    explicit_selection_helper_by_family = {
        "reveal_warp_coordinate": "reveal_p",
        "reveal_time_coordinate": "reveal_t",
        "reveal_position_chart": "reveal_chart_p",
        "reveal_epoch_chart": "reveal_chart_t",
    }

    for action in actions:
        name = action["name"]
        source = action_function_source(plugin, name)
        object_handles = handles(source)
        contract = action.get("intro_contract")
        contract_shape = (
            isinstance(contract, dict)
            and set(contract)
            == {
                "vdf",
                "whole_object_threshold",
                "explicit_action_identity",
            }
        )
        direct_vdfs = vdf_calls(source)
        direct_comparisons = comparison_calls(source)
        expected_helpers: set[str] = set()
        checks: dict[str, bool] = {
            "source_present": bool(source),
            "contract_shape_exact": contract_shape,
        }
        if not contract_shape:
            contract = {
                "vdf": None,
                "whole_object_threshold": None,
                "explicit_action_identity": None,
            }

        selection_helper = explicit_selection_helper_by_family.get(
            action["family"]
        )
        if selection_helper is not None:
            expected_helpers.add(selection_helper)
            wrapper_args = helper_calls(source, selection_helper)
            expected_count = len(helper_specs[selection_helper]["parameters"])
            prefix_count = (
                4 if selection_helper.startswith("reveal_chart_") else 2
            )
            args = wrapper_args[0] if len(wrapper_args) == 1 else []
            prefix_ok = (
                len(args) == expected_count
                and args[0] == "action"
                and (
                    (
                        prefix_count == 2
                        and object_handles.get(args[1], {}).get("mode")
                        == "mutate"
                    )
                    or (
                        prefix_count == 4
                        and object_handles.get(args[1])
                        == {"mode": "output", "class": SHIP}
                        and object_handles.get(args[2])
                        == {"mode": "input", "class": SHIP}
                        and object_handles.get(args[3], {}).get("mode")
                        == "mutate"
                    )
                )
            )
            checks["explicit_selection_wrapper_literals_and_roles_exact"] = (
                prefix_ok
                and all(
                    re.fullmatch(r"-?[0-9]+", item)
                    for item in args[prefix_count:]
                )
            )
            checks["explicit_selection_helper_semantics_exact"] = (
                helper_audits[selection_helper]["status"] == "pass"
            )

        vdf_contract = contract["vdf"]
        if vdf_contract is None:
            checks["vdf_absent_as_declared"] = not direct_vdfs
            no_vdf_kind = phase4_kind_for_action(action)
            no_vdf_owner = (
                phase4_helper_for(name, no_vdf_kind, None)
                if no_vdf_kind is not None
                else None
            )
            if no_vdf_owner is not None:
                expected_helpers.add(no_vdf_owner)
                no_vdf_calls = helper_calls(source, no_vdf_owner)
                helper_source = named_function_source(plugin, no_vdf_owner)
                no_vdf_kind = phase4_helper_kinds[no_vdf_owner]
                no_vdf_roles = (
                    [("output", SHIP), ("output", RESOURCE), ("input", SHIP), ("mutate", BODY)]
                    if no_vdf_kind == "body"
                    else [("output", SHIP), ("output", COMPOSITE_RESOURCE), ("input", SHIP), ("mutate", BODY)]
                    if no_vdf_kind == "composite"
                    else [("output", SHIP), ("output", RESOURCE), ("input", SHIP), ("mutate", COMPOSITE_RESOURCE)]
                )
                checks["phase4_no_vdf_adapter_route_exact"] = (
                    len(no_vdf_calls) == 1
                    and len(no_vdf_calls[0])
                    == len(helper_specs[no_vdf_owner]["parameters"])
                    and source_action_object_roles(source) == no_vdf_roles
                    and not vdf_calls(helper_source)
                    and '.update("work",' not in helper_source
                )
        else:
            expected_vdf_actions.add(name)
            owner = vdf_contract["owner"]
            iterations = vdf_contract["iterations"]
            if owner == "action":
                checks["direct_vdf_exact"] = (
                    len(direct_vdfs) == 1
                    and direct_vdfs[0][0] == iterations
                    and direct_vdfs[0][1] in object_handles
                )
                argument = (
                    direct_vdfs[0][1] if direct_vdfs else "missing"
                )
            else:
                expected_helpers.add(owner)
                checks["helper_owned_vdf_has_no_direct_duplicate"] = (
                    not direct_vdfs
                )
                checks["helper_owned_vdf_iterations_exact"] = (
                    helper_specs.get(owner, {}).get("vdf") == iterations
                )
                if owner in phase4_helper_kinds:
                    kind = phase4_helper_kinds[owner]
                    expected_prefix = {
                        "base": ["action", "next_ship", "resource", "ship", "body"],
                        "body": ["action", "next_ship", "resource", "ship", "body"],
                        "composite": ["action", "next_ship", "composite_resource", "ship", "body"],
                        "refine": ["action", "next_ship", "resource", "ship", "parent"],
                    }[kind]
                    expected_roles = (
                        [("output", SHIP), ("output", RESOURCE), ("input", SHIP), ("mutate", BODY)]
                        if kind in {"base", "body"}
                        else [("output", SHIP), ("output", COMPOSITE_RESOURCE), ("input", SHIP), ("mutate", BODY)]
                        if kind == "composite"
                        else [("output", SHIP), ("output", RESOURCE), ("input", SHIP), ("mutate", COMPOSITE_RESOURCE)]
                    )
                    adapter_calls = helper_calls(source, owner)
                    adapter_args = (
                        adapter_calls[0] if len(adapter_calls) == 1 else []
                    )
                    checks["phase4_adapter_route_and_literals_exact"] = (
                        len(adapter_args) == len(helper_specs[owner]["parameters"])
                        and adapter_args[:5] == expected_prefix
                        and source_action_object_roles(source) == expected_roles
                        and all(
                            re.fullmatch(r'-?[0-9]+|"[^"\\]*"', value)
                            for value in adapter_args[5:]
                        )
                    )
                argument = helper_specs.get(owner, {}).get(
                    "object", "missing"
                )
            calls.append(
                {
                    "action": name,
                    "primitive": "intro_vdf",
                    "owner": owner,
                    "argument": argument,
                    "argument_shape": "complete object handle",
                    "fixed_parameter": iterations,
                    "fixed_parameter_shape": "fixed positive integer literal",
                    "passed": all(
                        value
                        for key, value in checks.items()
                        if key.startswith("direct_vdf")
                        or key.startswith("helper_owned_vdf")
                        or key.startswith("phase4_adapter")
                    ),
                }
            )

        threshold_contract = contract["whole_object_threshold"]
        if threshold_contract is not None:
            expected_threshold_actions.add(name)
            owner = threshold_contract["owner"]
            expected_helpers.add(owner)
            wrapper_args = helper_calls(source, owner)
            wrapper_ok = (
                len(wrapper_args) == 1
                and len(wrapper_args[0]) == 14
                and wrapper_args[0][:4]
                == ["action", "body", "signal", "ship"]
                and all(
                    re.fullmatch(r"-?[0-9]+", item)
                    for item in wrapper_args[0][4:]
                )
                and object_handles.get("body")
                == {"mode": "output", "class": BODY}
                and object_handles.get("signal")
                == {"mode": "input", "class": SIGNAL}
                and object_handles.get("ship")
                == {"mode": "mutate", "class": SHIP}
            )
            checks["threshold_wrapper_literals_and_roles_exact"] = wrapper_ok
            checks["threshold_helper_semantics_exact"] = (
                helper_audits[owner]["status"] == "pass"
            )
            calls.append(
                {
                    "action": name,
                    "primitive": "intro_lt_eq_u256",
                    "owner": owner,
                    "role": "whole_object_threshold",
                    "argument": "signal",
                    "argument_shape": "complete input object handle",
                    "fixed_parameter": (
                        wrapper_args[0][6] if wrapper_args else "missing"
                    ),
                    "fixed_parameter_shape": "fixed literal U256 value",
                    "direction": "object_le_fixed_upper",
                    "passed": wrapper_ok
                    and helper_audits[owner]["status"] == "pass",
                }
            )

        explicit_contract = contract["explicit_action_identity"]
        if explicit_contract is not None:
            expected_explicit_selection_actions.add(name)
            expected_owner = explicit_selection_helper_by_family.get(
                action["family"], "action"
            )
            checks["explicit_action_identity_contract_exact"] = (
                explicit_contract
                == {
                    "selection_mode": EXPLICIT_SELECTION_MODE,
                    "owner": expected_owner,
                    "stable_identifier_used": False,
                }
                and action.get("selection_mode")
                == EXPLICIT_SELECTION_MODE
            )
        else:
            checks["explicit_action_identity_absent_as_declared"] = (
                action.get("selection_mode") != EXPLICIT_SELECTION_MODE
            )

        expected_direct_comparisons = 0
        checks["direct_comparison_count_exact"] = (
            len(direct_comparisons) == expected_direct_comparisons
        )
        observed_helpers = {
            helper: len(helper_calls(source, helper))
            for helper in helper_names
            if helper_calls(source, helper)
        }
        checks["intro_helper_call_set_and_multiplicity_exact"] = (
            observed_helpers
            == {helper: 1 for helper in expected_helpers}
        )
        action_details[name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "family": action["family"],
            "checks": checks,
            "contract": contract,
            "direct_vdf_calls": direct_vdfs,
            "direct_comparison_calls": direct_comparisons,
            "intro_helper_calls": observed_helpers,
        }

    expected_vdf_count = len(expected_vdf_actions)
    expected_threshold_count = len(expected_threshold_actions)
    observed_vdf_count = sum(
        call["primitive"] == "intro_vdf" for call in calls
    )
    observed_threshold_count = sum(
        call.get("role") == "whole_object_threshold" for call in calls
    )
    expected_physical_vdf_count = sum(
        action["intro_contract"]["vdf"] is not None
        and action["intro_contract"]["vdf"]["owner"] == "action"
        for action in actions
    ) + len({
        action["intro_contract"]["vdf"]["owner"]
        for action in actions
        if action["intro_contract"]["vdf"] is not None
        and action["intro_contract"]["vdf"]["owner"]
        in (
            set(phase4_helper_kinds)
            | phase5_helper_names
            | phase6_vdf_helper_names
        )
    }) + 2
    expected_physical_comparison_count = 1
    physical_vdf_count = len(vdf_calls(plugin))
    physical_comparison_count = len(comparison_calls(plugin))
    expected_total_count = (
        expected_vdf_count
        + expected_threshold_count
    )
    coverage_checks = {
        "action_contract_names_match_defined_actions": (
            expected_action_names == defined_action_names
        ),
        "every_action_has_explicit_intro_contract": all(
            detail["checks"]["contract_shape_exact"]
            for detail in action_details.values()
        ),
        "all_per_action_intro_contracts_pass": all(
            detail["status"] == "pass"
            for detail in action_details.values()
        ),
        "all_intro_helpers_have_exact_semantics": all(
            detail["status"] == "pass" for detail in helper_audits.values()
        ),
        "logical_vdf_action_set_and_count_exact": (
            {call["action"] for call in calls if call["primitive"] == "intro_vdf"}
            == expected_vdf_actions
            and observed_vdf_count == expected_vdf_count
        ),
        "logical_threshold_action_set_and_count_exact": (
            {
                call["action"]
                for call in calls
                if call.get("role") == "whole_object_threshold"
            }
            == expected_threshold_actions
            and observed_threshold_count == expected_threshold_count
        ),
        "explicit_action_identity_set_and_count_exact": (
            expected_explicit_selection_actions
            == {
                action["name"]
                for action in actions
                if action.get("selection_mode")
                == EXPLICIT_SELECTION_MODE
            }
            and len(expected_explicit_selection_actions) == 603
        ),
        "stable_identifier_selection_intro_calls_absent": (
            physical_comparison_count == 1
            and not any(
                call.get("role") == "stable_identifier_selection"
                for call in calls
            )
        ),
        "physical_vdf_calls_exact_no_unclassified_helpers": (
            physical_vdf_count == expected_physical_vdf_count
        ),
        "physical_comparisons_exact_no_unclassified_helpers": (
            physical_comparison_count == expected_physical_comparison_count
        ),
        "exact_total_logical_call_count_present": (
            len(calls) == expected_total_count
        ),
    }
    passed = (
        bool(calls)
        and all(call["passed"] for call in calls)
        and all(coverage_checks.values())
    )
    return {
        "status": "pass" if passed else "fail",
        "call_count": len(calls),
        "coverage_checks": coverage_checks,
        "configured_catalog_coverage": {
            "expected_vdf_calls": expected_vdf_count,
            "expected_threshold_u256_calls": expected_threshold_count,
            "explicit_action_identity_actions": len(
                expected_explicit_selection_actions
            ),
            "expected_stable_identifier_selection_calls": 0,
            "expected_total_calls": expected_total_count,
            "observed_vdf_calls": observed_vdf_count,
            "observed_threshold_u256_calls": observed_threshold_count,
            "observed_stable_identifier_selection_calls": 0,
            "observed_total_calls": len(calls),
            "physical_vdf_calls": physical_vdf_count,
            "physical_u256_calls": physical_comparison_count,
            "passed": all(coverage_checks.values()),
        },
        "expected_vdf_actions": sorted(expected_vdf_actions),
        "expected_threshold_u256_actions": sorted(
            expected_threshold_actions
        ),
        "expected_explicit_action_identity_actions": sorted(
            expected_explicit_selection_actions
        ),
        "helpers": helper_audits,
        "actions": action_details,
        "allowed_argument_shapes": [
            "complete object handle",
            "fixed literal U256 value",
        ],
        "forbidden_argument_shapes": [
            "direct object field accessor",
            "managed work field",
            "custom clock field",
            "unsafe unbound value",
        ],
        "calls": calls,
    }


def baseline(source_root: Path) -> dict[str, Any]:
    relative_files = [
        "Cargo.toml",
        "Cargo.lock",
        "libs/sdk/src/lib.rs",
        "libs/sdk/src/fmt_podlang.rs",
        "libs/sdk/src/manifest.rs",
        "libs/txlib/src/lib.rs",
        "libs/pexe/src/lib.rs",
        "libs/pexe/src/bin/pexe.rs",
        "libs/pexe/src/fixtures.rs",
        "libs/payload/src/blob.rs",
        "libs/payload/src/payload.rs",
        "services/synchronizer/src/state_machine.rs",
        "examples/craft-basics/plugin.rhai",
    ]
    source_files = {}
    for relative in relative_files:
        path = source_root / relative
        source_files[relative] = {
            "exists": path.is_file(),
            "bytes": path.stat().st_size if path.is_file() else None,
            "sha256": sha256_file(path) if path.is_file() else None,
        }
    pexe_path = Path(os.environ.get("MICROVERSE_PEXE", str(Path.home().joinpath('.dobj', 'bin', 'pexe.exe'))))
    pexe_version = None
    if pexe_path.is_file():
        completed = subprocess.run(
            [str(pexe_path), "--version"],
            capture_output=True,
            text=True,
            check=False,
        )
        pexe_version = (completed.stdout + completed.stderr).strip()
    rust_version = subprocess.run(["rustc", "--version"], capture_output=True, text=True, check=False).stdout.strip()
    cargo_version = subprocess.run(["cargo", "--version"], capture_output=True, text=True, check=False).stdout.strip()
    return {
        "review_baseline_commit": "97ef94b3f18851a4d8d472e16c70030f49caf8ce",
        "installed_source_kind": "exported tree without Git metadata",
        "installed_source_root": str(source_root),
        "source_files": source_files,
        "pod2_revision": "da6c08f3c3341a51aa8f7f0f863ec694bcb9d9a3",
        "plonky2_revision": "109d517d09c210ae4c2cee381d3e3fbc04aa3812",
        "pexe": {
            "path": str(pexe_path),
            "exists": pexe_path.is_file(),
            "version": pexe_version,
            "bytes": pexe_path.stat().st_size if pexe_path.is_file() else None,
            "sha256": sha256_file(pexe_path) if pexe_path.is_file() else None,
        },
        "host": {
            "platform": platform.platform(),
            "machine": platform.machine(),
            "processor": platform.processor(),
            "python": platform.python_version(),
            "rust": rust_version,
            "cargo": cargo_version,
        },
    }


def generate_package(
    root: Path,
    bank: list[dict[str, Any]],
    actions: list[dict[str, Any]],
    *,
    package_name: str,
    write_full_sidecars: bool = True,
) -> None:
    source_map = sources_for_bank(bank)
    used_classes = [
        class_name
        for class_name in CLASS_ORDER
        if any(obj["class"] == class_name for action in actions for obj in action["objects"])
    ]
    plugin = render_plugin(actions, source_map)
    manifest = render_manifest(used_classes, actions, package_name)
    write_text(root / "plugin.rhai", plugin)
    write_text(root / "manifest.toml", manifest)
    if not write_full_sidecars:
        return

    generated = root / "generated"
    generated.mkdir(parents=True, exist_ok=True)
    (generated / "compile-errors").mkdir(parents=True, exist_ok=True)
    action_counts, bridge_counts = derived_counts(actions, used_classes)
    tech_catalog = civilization_tech_catalog(bank, actions, used_classes)
    write_json(generated / "action-contract.json", {"actions": actions})
    write_json(generated / "action-counts.json", action_counts)
    write_json(generated / "bridge-counts.json", bridge_counts)
    write_json(generated / "schema-counts.json", schema_sidecar(used_classes))
    write_json(
        generated / "body-bank.json",
        {
            "body_bank_version": VERSIONS["body_bank_version"],
            "candidate_count": len(bank),
            "candidates": bank,
        },
    )
    write_json(
        generated / "warp-coordinate-contract.json",
        {
            "class": WARP_COORDINATE,
            "schema": [
                {"name": field, "type": field_type}
                for field, field_type in SCHEMAS[WARP_COORDINATE]
            ],
            "source_candidate": WARP_ANOMALY_CANDIDATE,
            "required_skill_type": WARP_SKILL_TYPE,
            "energy_cost": WARP_ENERGY_COST,
            "destination_count": len(POSITION_WARP_DESTINATIONS),
            "destinations": POSITION_WARP_DESTINATIONS,
            "destination_generation": {
                "kind": "deterministic SHA-256 pseudorandom magnitude bands",
                "seed": POSITION_WARP_SEED,
                "minimum_inclusive": POSITION_WARP_MINIMUM,
                "maximum_exclusive": COORD_UPPER_BOUND,
                "magnitude_strata": [
                    {"lower_inclusive": lower, "upper_exclusive": upper}
                    for lower, upper in POSITION_WARP_MAGNITUDE_STRATA
                ],
                "mapping": (
                    "lower + floor(sha256_integer * (upper - lower) / 2^256)"
                ),
                "runtime_randomness": False,
                "modulo_used": False,
            },
            "coordinate_selection": {
                "selection_mode": EXPLICIT_SELECTION_MODE,
                "selector_source": "action name",
                "mapping": (
                    "one action name maps to one fixed destination row"
                ),
                "stable_identifier_used": False,
            },
            "changes": ["x", "y", "z"],
            "preserves": ["epoch"],
        },
    )
    write_json(
        generated / "time-coordinate-contract.json",
        {
            "class": TIME_COORDINATE,
            "schema": [
                {"name": field, "type": field_type}
                for field, field_type in SCHEMAS[TIME_COORDINATE]
            ],
            "source_candidate": WARP_ANOMALY_CANDIDATE,
            "required_skill_type": WARP_SKILL_TYPE,
            "energy_cost": WARP_ENERGY_COST,
            "destination_count": len(TIME_WARP_DESTINATIONS),
            "destinations": TIME_WARP_DESTINATIONS,
            "coordinate_selection": {
                "selection_mode": EXPLICIT_SELECTION_MODE,
                "selector_source": "action name",
                "mapping": (
                    "one action name maps to one fixed destination row"
                ),
                "stable_identifier_used": False,
            },
            "changes": ["epoch"],
            "preserves": ["x", "y", "z"],
        },
    )
    write_json(
        generated / "warp-coordinate-capacity-sweep.json",
        warp_coordinate_capacity_sweep(bank),
    )
    write_json(generated / "civilization-tech-catalog.json", tech_catalog)
    write_json(
        generated / "universe-contract.json",
        {
            "package": package_name,
            "plugin_version": PLUGIN_VERSION,
            "module_hash": None,
            "class_hashes": {name: None for name in used_classes},
            "versions": VERSIONS,
            "coordinates": {
                "coord_zero": COORD_ZERO,
                "coord_upper_bound_exclusive": COORD_UPPER_BOUND,
                "epoch_upper_bound_exclusive": EPOCH_UPPER_BOUND,
                "epoch_render_years": EPOCH_RENDER_YEARS,
            },
            "civilization_types": CIVILIZATION_TYPES,
            "survey_profiles": [
                {
                    **profile,
                    "survey_profile": profile["code"],
                    "action": (
                        f"SurveySector_{profile['code']:02d}_"
                        f"{profile['slug']}"
                    ),
                }
                for profile in SURVEY_PROFILES
            ],
            "selection_progression_policy": {
                "selection_mode": DETERMINISTIC_SELECTOR_MODE,
                "outcome_source": "immutable stable-ID hierarchy",
                "stable_identifier_used": True,
                "unlock_scope": "current compatible Ship",
                "transfer_policy": (
                    "Any compatible co-located Ship that meets the milestone "
                    "may service a stored Sector or LifeSignal; the creator "
                    "Ship is not bound."
                ),
                "retroactivity": (
                    "Stored compatible Sectors and LifeSignals remain usable "
                    "after a Ship reaches a later milestone."
                ),
                "survey": {
                    "counter_field": "claim_serial",
                    "counter_meaning": (
                        "claims completed by the current Ship, not distinct "
                        "coordinates"
                    ),
                    "minimums_by_profile": {
                        str(profile["code"]): profile[
                            "minimum_claim_serial"
                        ]
                        for profile in SURVEY_PROFILES
                    },
                    "selected_profile_is_unique": True,
                },
                "civilization": {
                    "counter_field": "civilization_scan_serial",
                    "counter_meaning": (
                        "qualifying intelligent-life detections completed by "
                        "the current Ship"
                    ),
                    "minimums_by_type": {
                        str(civilization_type["code"]): civilization_type[
                            "minimum_civilization_scan_serial"
                        ]
                        for civilization_type in CIVILIZATION_TYPES
                    },
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
                    "eligible_candidate_codes": list(
                        INTELLIGENT_LIFE_CANDIDATE_CODES
                    ),
                    "initial_life_stat": 0,
                    "selected_life_stat": 1,
                    "selection_mode": DETERMINISTIC_SELECTOR_MODE,
                    "selector_band": intelligent_life_selector_band(bank),
                },
            },
            "body_bank": bank,
            "civilization_tech": tech_catalog,
            "versioned_universe_warning": "Class hashes are part of object commitments; a changed PEXE can reroll the map.",
        },
    )
    write_json(
        generated / "field-access-audit.json",
        field_access_audit(plugin, actions),
    )
    write_json(
        generated / "refactor-census.json",
        refactor_census(plugin, actions),
    )
    write_json(
        generated / "intro-audit.json",
        intro_audit(plugin, actions),
    )
    write_json(
        generated / "raw-equality-budget.json",
        {
            "whole_object_vdf_intros": [
                action["name"]
                for action in actions
                if "action.intro_vdf("
                in source_map[action["name"]]
            ],
            "whole_object_threshold_intros": [
                f"ScanCelestialBody_{item['code']:02d}_{item['slug']}" for item in bank
            ],
            "explicit_action_identity_selections": [
                f"RevealWarpCoordinate{destination['slug']}"
                for destination in POSITION_WARP_DESTINATIONS
            ] + [
                f"RevealTimeCoordinate{destination['slug']}"
                for destination in TIME_WARP_DESTINATIONS
            ] + [
                destination["reveal_action"]
                for destination in POSITION_CHART_DESTINATIONS
            ] + [
                destination["reveal_action"]
                for destination in EPOCH_CHART_DESTINATIONS
            ] + [
                f"SurveySector_{profile['code']:02d}_{profile['slug']}"
                for profile in SURVEY_PROFILES
            ] + [
                item["action"] for item in CIVILIZATION_TYPES
            ],
            "stable_identifier_selection_intro_count": 0,
            "whole_object_raw_export_checkpoints": {
                "actions": [],
                "u256_intros_per_action": 0,
                "purpose": (
                    "No production action exports parent Raw identifiers into "
                    "child objects."
                ),
            },
            "deterministic_output_key_type": (
                "Sector, CelestialSignal, and sealed coordinate objects use "
                "fixed Raw zero; portable outputs retain the SDK-provided "
                "random key."
            ),
            "raw_copy_relationships": [
                "Ship x/y/z/epoch -> Sector x/y/z/epoch",
                "Input Ship semantic fields -> replacement Ship semantic fields",
                "CelestialBody stable_identifier -> WarpCoordinate source_body_identifier",
                "WarpCoordinate destination_x/y/z -> Ship x/y/z",
                "TimeCoordinate destination_epoch -> Ship epoch",
            ],
            "parent_identifier_provenance_policy": (
                "Most children omit Raw parent identifiers; WarpCoordinate "
                "is the exception and binds its Anomaly source identifier "
                "through a no-op stable_identifier update in extraction."
            ),
        },
    )
    write_json(
        generated / "predicate-budget.json",
        {
            "named_pre_split_baseline": len(actions) + bridge_counts["total"] + len(used_classes),
            "action_predicates": len(actions),
            "class_bridges": bridge_counts["total"],
            "class_predicates": len(used_classes),
            "compiled_predicates": None,
            "split_predicates": None,
            "hard_limit": 65_536,
        },
    )
    write_json(
        generated / "payload-budget.json",
        {
            "hard_limit_bytes": 126_945,
            "max_object_io_occurrences_by_shape": 4,
            "max_live_commitments_by_shape": 3,
            "max_nullifiers_by_shape": 2,
            "live_commitment_hard_limit": 255,
            "nullifier_hard_limit": 255,
            "measured_actions": [],
            "worst_complete_payload_bytes": None,
        },
    )
    write_json(generated / "probe-results.json", {"status": "pending", "probes": []})
    write_json(generated / "capacity-sweep.json", {"status": "pending", "variants": []})
    write_json(generated / "civilization-capacity-sweep.json", {"status": "pending", "variants": []})
    write_json(generated / "build-vdf-calibration.json", {"status": "pending", "samples": []})
    write_json(generated / "real-proof-results.json", {"status": "pending", "actions": []})
    write_json(generated / "lifecycle-results.json", {"status": "pending", "tests": []})
    write_json(generated / "negative-test-results.json", {"status": "pending", "tests": []})
    write_json(generated / "distribution-report.json", {"status": "pending", "sample_size": 0})
    write_json(generated / "fixtures.json", {"status": "pending", "fixtures": {}})
    for empty_name in [
        "predicates.frontend.txt",
        "predicates.middleware.txt",
        "classes.txt",
        "action-graph.mmd",
        "archive-dump.txt",
        "command-log.txt",
    ]:
        write_text(generated / empty_name, "")


def selected_actions(all_actions: list[dict[str, Any]], names: list[str]) -> list[dict[str, Any]]:
    by_name = {action["name"]: action for action in all_actions}
    return [by_name[name] for name in names]


def probe_action_sets(bank: list[dict[str, Any]]) -> dict[str, list[str]]:
    build_names = [f"BuildShip{tier['name']}" for tier in SHIP_TIERS]
    movement_names = [
        action_name
        for action_name, _axis, _positive, _tier in movement_variants()
    ]
    timewarp_names = [f"TimeWarp{tier['name']}" for tier in SHIP_TIERS]
    detect_names = [
        f"DetectCelestialSignal_{item['code']:02d}_{item['slug']}" for item in bank
    ]
    materialize_names = [
        f"ScanCelestialBody_{item['code']:02d}_{item['slug']}" for item in bank
    ]
    claim_route = [
        "BuildShipSmall",
        "MovePositiveX",
        "MoveNegativeY",
        "TimeWarpSmall",
        "ClaimSector",
    ]
    surveyed_prefix = [
        *claim_route,
        "SurveySector_02_Standard",
    ]
    return {
        "P01-vdf-only-ship": build_names,
        "P02-movement": build_names + movement_names,
        "P03-whole-ship-timewarp": build_names + timewarp_names,
        "P04-claim-sector": claim_route,
        "P05-two-mutations": surveyed_prefix,
        "P06-all-detections": surveyed_prefix + detect_names,
        "P07-all-materializations": (
            surveyed_prefix + detect_names + materialize_names
        ),
        "P08-all-resources": surveyed_prefix
        + [
            "DetectCelestialSignal_07_IceGiant",
            "ScanCelestialBody_07_IceGiant",
            "ExtractMatter",
            "ExtractCrystal",
            "ExtractGas",
            "ExtractEnergy",
        ],
        "P09-satellite": surveyed_prefix
        + [
            "DetectCelestialSignal_07_IceGiant",
            "ScanCelestialBody_07_IceGiant",
            "DiscoverSatellite",
        ],
        "P10a-life-signal": surveyed_prefix
        + [
            "DetectCelestialSignal_05_GardenPlanet",
            "ScanCelestialBody_05_GardenPlanet",
            "DetectIntelligentLife",
        ],
        "P10b-civilization": surveyed_prefix
        + [
            "DetectCelestialSignal_05_GardenPlanet",
            "ScanCelestialBody_05_GardenPlanet",
            "DetectIntelligentLife",
            "MaterializeCivilizationTypeI",
        ],
    }


def generate_probes(project_root: Path, bank: list[dict[str, Any]]) -> None:
    all_actions = build_actions(bank)
    probes = probe_action_sets(bank)
    for probe_name, names in probes.items():
        path = project_root / "probes" / probe_name
        generate_package(
            path,
            bank,
            selected_actions(all_actions, names),
            package_name=f"microverse-{probe_name.lower()}",
            write_full_sidecars=False,
        )
        write_json(
            path / "probe-contract.json",
            {
                "probe": probe_name.split("-", 1)[0],
                "actions": names,
                "target_action": names[-1],
                "status": "pending",
            },
        )


def generate_capacity_variants(project_root: Path) -> None:
    for count in [15, 24, 48, 96, 192]:
        bank = candidate_bank(count)
        actions = build_actions(bank)
        generate_package(
            project_root / "capacity" / f"bank-{count}",
            bank,
            actions,
            package_name=f"microverse-capacity-bank-{count}",
            write_full_sidecars=False,
        )
        write_json(
            project_root / "capacity" / f"bank-{count}" / "variant-contract.json",
            {
                "kind": "candidate_bank",
                "candidate_count": count,
                "action_count": len(actions),
                "bridge_count": sum(len(action["objects"]) for action in actions),
                "named_pre_split_baseline": len(actions) + sum(len(action["objects"]) for action in actions) + len(CLASS_ORDER),
                "canonical": count == 15,
            },
        )

    base_bank = candidate_bank(15)
    base_sources = sources_for_bank(base_bank)
    for count in [32, 64, 128]:
        base_action = action_record("BuildShipSmall", "build_ship", [("output", SHIP)])
        actions = [base_action]
        sources = {"BuildShipSmall": base_sources["BuildShipSmall"]}
        for index in range(count):
            name = f"MoveVariant_{index:03d}"
            actions.append(action_record(name, "simple_movement_capacity", [("mutate", SHIP)]))
            sources[name] = movement_source("X", index % 2 == 0, name=name)
        path = project_root / "capacity" / f"simple-actions-{count}"
        write_text(path / "plugin.rhai", common_helpers() + "".join(sources[action["name"]] for action in actions))
        write_text(path / "manifest.toml", render_manifest([SHIP], actions, f"microverse-simple-actions-{count}"))
        write_json(
            path / "variant-contract.json",
            {
                "kind": "simple_movement",
                "movement_like_action_count": count,
                "total_action_count": len(actions),
                "bridge_count": len(actions),
                "canonical": False,
            },
        )
    generate_civilization_capacity_variants(project_root)


def render_capacity_project(
    path: Path,
    classes: list[str],
    actions: list[dict[str, Any]],
    sources: dict[str, str],
    package_name: str,
    contract: dict[str, Any],
) -> None:
    write_text(
        path / "plugin.rhai",
        "// Generated compile/proof capacity shape; not part of the final protocol.\n"
        + "".join(sources[action["name"]] for action in actions),
    )
    write_text(path / "manifest.toml", render_manifest(classes, actions, package_name))
    write_json(path / "variant-contract.json", contract)


def civilization_capacity_producer_source(class_name: str) -> str:
    return f"""
fn CreateCivilizationCapacity(action) {{
    var civilization = action.output("{class_name}");
    civilization.set([
        ["stage", 0],
        ["counter", 0]
    ]);
}}
"""


def civilization_c1_source(class_name: str, name: str) -> str:
    return f"""
fn {name}(action) {{
    var civilization = action.mutate("{class_name}");
    action.st_sum(civilization.stage, 0, 0);
    var next_counter = unsafe {{ civilization.counter - (0 - 1) }};
    action.st_sum(civilization.counter, 1, next_counter);
    civilization.update("counter", next_counter);
    var next_key = action.random();
    civilization.update("key", next_key);
}}
"""


def civilization_capacity_advance_source(class_name: str) -> str:
    return f"""
fn AdvanceCivilizationCapacity(action) {{
    var civilization = action.mutate("{class_name}");
    action.st_sum(civilization.stage, 0, 0);
    var next_counter = unsafe {{ civilization.counter - (0 - 1) }};
    action.st_sum(civilization.counter, 1, next_counter);
    civilization.update("counter", next_counter);
    var next_key = action.random();
    civilization.update("key", next_key);
}}
"""


def civilization_c2_source(
    civilization_class: str, event_class: str, name: str, code: int
) -> str:
    return f"""
fn {name}(action) {{
    var advanced_civilization = action.subaction("AdvanceCivilizationCapacity");
    var event = action.output("{event_class}");
    event.set([
        ["event_code", {code}]
    ]);
    let zero = action.top_limb_u256(0);
    event.update("key", zero);
}}
"""


def civilization_c3_prepare_source(
    civilization_class: str, candidate_class: str, name: str, code: int
) -> str:
    return f"""
fn {name}(action) {{
    var advanced_civilization = action.subaction("AdvanceCivilizationCapacity");
    var candidate = action.output("{candidate_class}");
    candidate.set([
        ["candidate_code", {code}]
    ]);
    let zero = action.top_limb_u256(0);
    candidate.update("key", zero);
}}
"""


def civilization_c3_materialize_source(
    candidate_class: str, child_class: str, name: str, code: int
) -> str:
    return f"""
fn {name}(action) {{
    var candidate = action.input("{candidate_class}");
    var child = action.output("{child_class}");
    action.st_sum(candidate.candidate_code, 0, {code});
    let target = action.top_limb_u256(9223372036854775807);
    action.intro_lt_eq_u256(candidate, target);
    child.set([
        ["candidate_code", {code}]
    ]);
    let zero = action.top_limb_u256(0);
    child.update("key", zero);
}}
"""


def generate_civilization_capacity_variants(project_root: Path) -> None:
    civilization_class = "MicroverseCivilizationCapacity"
    event_class = "MicroverseCivilizationEventCapacity"
    candidate_class = "MicroverseCivilizationCandidateCapacity"
    child_class = "MicroverseCivilizationChildCapacity"

    for count in [16, 32, 64, 128]:
        producer = action_record(
            "CreateCivilizationCapacity", "capacity_producer", [("output", civilization_class)]
        )
        actions = [producer]
        sources = {
            producer["name"]: civilization_capacity_producer_source(civilization_class)
        }
        for index in range(count):
            name = f"C1Advance_{index:03d}"
            actions.append(
                action_record(name, "civilization_c1", [("mutate", civilization_class)])
            )
            sources[name] = civilization_c1_source(civilization_class, name)
        render_capacity_project(
            project_root / "capacity" / f"civilization-c1-{count}",
            [civilization_class],
            actions,
            sources,
            f"microverse-civilization-c1-{count}",
            {
                "kind": "civilization_c1",
                "bank_size": count,
                "action_count": len(actions),
                "bridge_count": sum(len(action["objects"]) for action in actions),
                "classes": [civilization_class],
                "named_pre_split_baseline": (
                    len(actions)
                    + sum(len(action["objects"]) for action in actions)
                    + 1
                ),
                "proof_targets": [f"C1Advance_{0:03d}", f"C1Advance_{count - 1:03d}"],
                "canonical": False,
            },
        )

    for count in [8, 16, 32, 64]:
        producer = action_record(
            "CreateCivilizationCapacity", "capacity_producer", [("output", civilization_class)]
        )
        advance = action_record(
            "AdvanceCivilizationCapacity",
            "capacity_advance",
            [("mutate", civilization_class)],
            hidden=True,
        )
        actions = [producer, advance]
        sources = {
            producer["name"]: civilization_capacity_producer_source(civilization_class),
            advance["name"]: civilization_capacity_advance_source(civilization_class),
        }
        for index in range(count):
            name = f"C2EmitEvent_{index:03d}"
            actions.append(
                action_record(
                    name,
                    "civilization_c2",
                    [("mutate", civilization_class), ("output", event_class)],
                )
            )
            sources[name] = civilization_c2_source(
                civilization_class, event_class, name, index
            )
        render_capacity_project(
            project_root / "capacity" / f"civilization-c2-{count}",
            [civilization_class, event_class],
            actions,
            sources,
            f"microverse-civilization-c2-{count}",
            {
                "kind": "civilization_c2",
                "bank_size": count,
                "action_count": len(actions),
                "bridge_count": sum(len(action["objects"]) for action in actions),
                "classes": [civilization_class, event_class],
                "named_pre_split_baseline": (
                    len(actions)
                    + sum(len(action["objects"]) for action in actions)
                    + 2
                ),
                "capacity_only_output_binding": (
                    "fixed event_code plus fixed-zero key; intentionally omits a copied "
                    "Raw parent identifier so this sweep measures the requested "
                    "mutation-plus-deterministic-output shape independently of the "
                    "installed field-unification blocker"
                ),
                "mutation_factoring": (
                    "one-commit parent action invokes the earlier "
                    "AdvanceCivilizationCapacity mutation subaction, then emits the event"
                ),
                "proof_targets": [f"C2EmitEvent_{0:03d}", f"C2EmitEvent_{count - 1:03d}"],
                "canonical": False,
            },
        )

    for count in [8, 16]:
        producer = action_record(
            "CreateCivilizationCapacity", "capacity_producer", [("output", civilization_class)]
        )
        advance = action_record(
            "AdvanceCivilizationCapacity",
            "capacity_advance",
            [("mutate", civilization_class)],
            hidden=True,
        )
        actions = [producer, advance]
        sources = {
            producer["name"]: civilization_capacity_producer_source(civilization_class),
            advance["name"]: civilization_capacity_advance_source(civilization_class),
        }
        for index in range(count):
            prepare = f"C3Prepare_{index:03d}"
            materialize = f"C3Materialize_{index:03d}"
            actions.extend(
                [
                    action_record(
                        prepare,
                        "civilization_c3_prepare",
                        [("mutate", civilization_class), ("output", candidate_class)],
                    ),
                    action_record(
                        materialize,
                        "civilization_c3_materialize",
                        [("input", candidate_class), ("output", child_class)],
                    ),
                ]
            )
            sources[prepare] = civilization_c3_prepare_source(
                civilization_class, candidate_class, prepare, index
            )
            sources[materialize] = civilization_c3_materialize_source(
                candidate_class, child_class, materialize, index
            )
        render_capacity_project(
            project_root / "capacity" / f"civilization-c3-{count}",
            [civilization_class, candidate_class, child_class],
            actions,
            sources,
            f"microverse-civilization-c3-{count}",
            {
                "kind": "civilization_c3",
                "bank_size": count,
                "action_count": len(actions),
                "bridge_count": sum(len(action["objects"]) for action in actions),
                "classes": [civilization_class, candidate_class, child_class],
                "named_pre_split_baseline": (
                    len(actions)
                    + sum(len(action["objects"]) for action in actions)
                    + 3
                ),
                "intro_count": count,
                "intro_argument_shape": "complete candidate input object",
                "threshold_top_limb": 9_223_372_036_854_775_807,
                "capacity_only_output_binding": (
                    "fixed candidate_code plus fixed-zero key; intentionally omits copied "
                    "Raw parent fields so the two-stage whole-object threshold shape is "
                    "measured independently of the installed field-unification blocker"
                ),
                "mutation_factoring": (
                    "one-commit prepare action invokes the earlier "
                    "AdvanceCivilizationCapacity mutation subaction, then emits the candidate"
                ),
                "proof_targets": [
                    [f"C3Prepare_{0:03d}", f"C3Materialize_{0:03d}"],
                    [f"C3Prepare_{count - 1:03d}", f"C3Materialize_{count - 1:03d}"],
                ],
                "canonical": False,
            },
        )


def action_object_roles(action: dict[str, Any]) -> list[tuple[str, str]]:
    return [(item["mode"], item["class"]) for item in action["objects"]]


def rhai_action_object_bindings(source: str) -> list[tuple[str, str, str]]:
    """Return executable object handle, role, and class declarations."""
    code = mask_rhai_noncode(source)
    roles: list[tuple[str, str, str]] = []
    for match in re.finditer(
        r"\b(?:var|let)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
        r"action\.(output|input|mutate)\s*\((.*?)\)",
        code,
        flags=re.DOTALL,
    ):
        arguments = source[match.start(3) : match.end(3)]
        class_match = re.fullmatch(r'\s*"([^"]+)"\s*', arguments)
        if class_match:
            roles.append((
                match.group(1), match.group(2), class_match.group(1)
            ))
    return roles


def source_action_object_roles(source: str) -> list[tuple[str, str]]:
    """Return object declarations in their replay-sensitive source order."""
    return [
        (mode, class_name)
        for _handle, mode, class_name in rhai_action_object_bindings(source)
    ]


def raw_named_function_source(plugin: str, name: str) -> str:
    return rhai_function_sources(plugin).get(name, "")


def named_function_source(plugin: str, name: str) -> str:
    """Return any Rhai function in the generator's four-space form."""
    source = raw_named_function_source(plugin, name)
    return RhaiAuditSource(re.sub(
        r"(?m)^(?: {2})+",
        lambda match: "    " * (len(match.group(0)) // 2),
        source,
    ))


def raw_action_function_source(plugin: str, name: str) -> str:
    source = raw_named_function_source(plugin, name)
    return (
        source
        if re.match(rf"fn\s+{re.escape(name)}\s*\(action\)\s*\{{", source)
        else ""
    )


def action_function_source(plugin: str, name: str) -> str:
    """Return an action in the generator's canonical four-space form."""
    source = raw_action_function_source(plugin, name)
    return RhaiAuditSource(re.sub(
        r"(?m)^(?: {2})+",
        lambda match: "    " * (len(match.group(0)) // 2),
        source,
    ))


def flattened_witness_scope_audit(
    plugin: str,
    actions: list[dict[str, Any]],
) -> dict[str, Any]:
    """Reject transitive witness-name collisions in rc.43 action scope.

    The installed compiler flattens circuit witnesses introduced by ``unsafe``
    and ``action.random`` across a wrapper and every helper it invokes.  Rhai
    locals such as VDF ``work`` handles remain ordinary lexical locals and are
    intentionally outside this audit.  Calls are expanded with multiplicity,
    so invoking a witness-producing helper twice is also rejected.
    """
    function_names = list(rhai_function_sources(plugin))
    function_set = set(function_names)
    sources = {
        name: raw_named_function_source(plugin, name)
        for name in function_names
    }
    calls = {
        name: [
            callee
            for callee in re.findall(
                r"(?<![A-Za-z0-9_.])([A-Za-z_][A-Za-z0-9_]*)\s*\(",
                mask_rhai_noncode(source),
            )
            if callee in function_set and callee != name
        ]
        for name, source in sources.items()
    }
    witnesses = {
        name: re.findall(
            r"\b(?:var|let)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
            r"(?:unsafe\s*\{|action\.random\s*\()",
            mask_rhai_noncode(source),
        )
        for name, source in sources.items()
    }
    missing_actions = [
        action["name"] for action in actions if action["name"] not in function_set
    ]
    cycles: set[tuple[str, ...]] = set()
    collisions: list[dict[str, Any]] = []

    expansion_cache: dict[str, list[tuple[str, tuple[str, ...]]]] = {}

    def expand(
        function_name: str,
        path: tuple[str, ...],
    ) -> list[tuple[str, tuple[str, ...]]]:
        if function_name in path:
            cycle_start = path.index(function_name)
            cycles.add((*path[cycle_start:], function_name))
            return []
        if function_name in expansion_cache:
            return expansion_cache[function_name]
        rows = [
            (witness, (function_name,))
            for witness in witnesses[function_name]
        ]
        for callee in calls[function_name]:
            rows.extend(
                (witness, (function_name, *suffix))
                for witness, suffix in expand(callee, (*path, function_name))
            )
        expansion_cache[function_name] = rows
        return rows

    for action in actions:
        action_name = action["name"]
        if action_name not in function_set:
            continue
        origins: dict[str, list[str]] = defaultdict(list)
        for witness, path in expand(action_name, ()):
            origins[witness].append(" -> ".join(path))
        for witness, witness_origins in sorted(origins.items()):
            if len(witness_origins) > 1:
                collisions.append(
                    {
                        "action": action_name,
                        "witness": witness,
                        "origins": witness_origins,
                    }
                )

    checks = {
        "all_actions_present": not missing_actions,
        "call_graph_acyclic": not cycles,
        "transitive_witness_names_unique": not collisions,
    }
    current_compatibility = {
        key: value for key, value in checks.items() if key.startswith("current_")
    }
    economy_only = {
        "action_count_exact", "logical_intro_calls_exact",
        "phase5_bulk_physical_ledger_exact", "phase1_logical_ledger_exact",
    }
    status_checks = (
        checks if ACTIVE_VDF_PROFILE == "economy"
        else {key: value for key, value in checks.items()
              if key not in economy_only and not key.startswith("current_")}
        | current_compatibility
    )
    return {
        "status": "pass" if all(status_checks.values()) else "fail",
        "profile": ACTIVE_VDF_PROFILE,
        "canonical_release_profile": ACTIVE_VDF_PROFILE == "economy",
        "checks": checks,
        "function_count": len(function_names),
        "action_count": len(actions),
        "witness_declaration_count": sum(map(len, witnesses.values())),
        "missing_actions": missing_actions,
        "cycles": [list(cycle) for cycle in sorted(cycles)],
        "collisions": collisions,
    }


@lru_cache(maxsize=8)
def rhai_function_sources(source: str) -> dict[str, str]:
    """Extract balanced functions while ignoring comment/string braces."""
    functions: dict[str, str] = {}
    code = mask_rhai_noncode(source)
    header = re.compile(r"(?m)^fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")
    for match in header.finditer(code):
        open_brace = code.find("{", match.end())
        if open_brace < 0:
            continue
        depth = 0
        for index in range(open_brace, len(code)):
            char = code[index]
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    functions[match.group(1)] = RhaiAuditSource(
                        source[match.start() : index + 1]
                    )
                    break
    return functions


@lru_cache(maxsize=8)
def rhai_function_header_inventory(
    source: str,
) -> tuple[tuple[str, tuple[str, ...], bool], ...]:
    """Return ordered function names, parameters, and balanced-body status."""
    code = mask_rhai_noncode(source)
    header = re.compile(r"(?m)^fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(")
    matches = list(header.finditer(code))
    rows: list[tuple[str, tuple[str, ...], bool]] = []
    for position, match in enumerate(matches):
        name = match.group(1)
        boundary = (
            matches[position + 1].start()
            if position + 1 < len(matches)
            else len(code)
        )
        open_parenthesis = code.find("(", match.start(), match.end())
        depth = 0
        close_parenthesis = -1
        for index in range(open_parenthesis, boundary):
            if code[index] == "(":
                depth += 1
            elif code[index] == ")":
                depth -= 1
                if depth == 0:
                    close_parenthesis = index
                    break
        if close_parenthesis < 0:
            rows.append((name, (), False))
            continue
        parameters = tuple(split_rhai_top_level_arguments(
            source[open_parenthesis + 1:close_parenthesis]
        ))
        open_brace = code.find("{", close_parenthesis + 1, boundary)
        if open_brace < 0:
            rows.append((name, parameters, False))
            continue
        depth = 0
        closed = False
        for index in range(open_brace, boundary):
            if code[index] == "{":
                depth += 1
            elif code[index] == "}":
                depth -= 1
                if depth == 0:
                    closed = True
                    break
        rows.append((name, parameters, closed))
    return tuple(rows)


@lru_cache(maxsize=8)
def rhai_function_definition_inventory(
    source: str,
) -> tuple[tuple[str, ...], frozenset[str]]:
    """Return masked definition names and names with unbalanced bodies."""
    rows = rhai_function_header_inventory(source)
    return (
        tuple(name for name, _parameters, _balanced in rows),
        frozenset(
            name for name, _parameters, balanced in rows if not balanced
        ),
    )


def rhai_action_function_names(source: str) -> list[str]:
    """Return balanced functions whose sole parameter is exactly action."""
    return [
        name
        for name, parameters, balanced in rhai_function_header_inventory(source)
        if balanced and parameters == ("action",)
    ]


def rhai_function_definition_count(source: str, name: str) -> int:
    """Count balanced named definitions without comment/string forgeries."""
    names, unbalanced = rhai_function_definition_inventory(source)
    return -1 if name in unbalanced else names.count(name)


def split_rhai_top_level_arguments(source: str) -> list[str]:
    """Split one argument list without splitting nested or string commas."""
    if not source.strip():
        return []
    code = mask_rhai_noncode(source)
    depth = 0
    start = 0
    arguments: list[str] = []
    for index, char in enumerate(code):
        if char in "([{":
            depth += 1
        elif char in ")]}":
            depth -= 1
        elif char == "," and depth == 0:
            arguments.append(source[start:index].strip())
            start = index + 1
    arguments.append(source[start:].strip())
    return arguments


def _rhai_statement_argument_span(
    code: str, open_parenthesis: int
) -> tuple[int, int] | None:
    depth = 0
    for index in range(open_parenthesis, len(code)):
        if code[index] == "(":
            depth += 1
        elif code[index] == ")":
            depth -= 1
            if depth == 0:
                cursor = index + 1
                while cursor < len(code) and code[cursor].isspace():
                    cursor += 1
                return (
                    (open_parenthesis + 1, index)
                    if cursor < len(code) and code[cursor] == ";"
                    else None
                )
    return None


def _rhai_named_statement_call_spans(
    source: str, name: str
) -> list[tuple[int, int, int]]:
    code = mask_rhai_noncode(source)
    spans: list[tuple[int, int, int]] = []
    for match in re.finditer(
        rf"(?<![.A-Za-z0-9_]){re.escape(name)}\s*\(", code
    ):
        open_parenthesis = code.find("(", match.start(), match.end())
        argument_span = _rhai_statement_argument_span(code, open_parenthesis)
        if argument_span is not None:
            spans.append((match.start(), *argument_span))
    return spans


def rhai_plain_statement_calls(
    source: str,
) -> list[tuple[str, list[str], int]]:
    """Return executable plain statement calls in source order."""
    code = mask_rhai_noncode(source)
    calls: list[tuple[str, list[str], int]] = []
    for match in re.finditer(
        r"(?<![.A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\s*\(", code
    ):
        open_parenthesis = code.find("(", match.start(), match.end())
        argument_span = _rhai_statement_argument_span(code, open_parenthesis)
        if argument_span is None:
            continue
        start, end = argument_span
        calls.append((
            match.group(1),
            split_rhai_top_level_arguments(source[start:end]),
            match.start(),
        ))
    return calls


def rhai_method_statement_calls(
    source: str, method: str | None = None
) -> list[tuple[str, str, list[str], int]]:
    """Return executable method statement calls in source order."""
    code = mask_rhai_noncode(source)
    calls: list[tuple[str, str, list[str], int]] = []
    method_pattern = (
        re.escape(method) if method is not None else r"[A-Za-z_][A-Za-z0-9_]*"
    )
    for match in re.finditer(
        rf"\b([A-Za-z_][A-Za-z0-9_]*)\.({method_pattern})\s*\(", code
    ):
        open_parenthesis = code.find("(", match.start(), match.end())
        argument_span = _rhai_statement_argument_span(code, open_parenthesis)
        if argument_span is None:
            continue
        start, end = argument_span
        calls.append((
            match.group(1),
            match.group(2),
            split_rhai_top_level_arguments(source[start:end]),
            match.start(),
        ))
    return calls


def rhai_call_arguments(source: str, name: str) -> list[list[str]]:
    return [
        split_rhai_top_level_arguments(source[start:end])
        for _position, start, end in _rhai_named_statement_call_spans(
            source, name
        )
    ]


def rhai_call_positions(source: str, name: str) -> list[int]:
    """Locate executable calls while ignoring comment and string decoys."""
    return [
        position
        for position, _start, _end in _rhai_named_statement_call_spans(
            source, name
        )
    ]


def rhai_terminal_statement_call(source: str, name: str) -> bool:
    """Require exactly one executable call as a function's final statement."""
    spans = _rhai_named_statement_call_spans(source, name)
    if len(spans) != 1:
        return False
    _position, _start, close_parenthesis = spans[0]
    code = mask_rhai_noncode(source)
    cursor = close_parenthesis + 1
    while cursor < len(code) and code[cursor].isspace():
        cursor += 1
    if cursor >= len(code) or code[cursor] != ";":
        return False
    cursor += 1
    while cursor < len(code) and code[cursor].isspace():
        cursor += 1
    if cursor >= len(code) or code[cursor] != "}":
        return False
    return not code[cursor + 1:].strip()


def rhai_call_uses_indexed_field(source: str, name: str, field: str) -> bool:
    """Detect a quoted indexed field only inside executable call arguments."""
    pattern = re.compile(rf'\[\s*"{re.escape(field)}"\s*\]')
    return any(
        pattern.search(argument)
        for arguments in rhai_call_arguments(source, name)
        for argument in arguments
    )


def rhai_function_parameters(source: str, name: str) -> list[str]:
    code = mask_rhai_noncode(source)
    match = re.search(
        rf"fn\s+{re.escape(name)}\s*\(",
        code,
    )
    if not match:
        return []
    open_parenthesis = code.find("(", match.start(), match.end())
    depth = 0
    for index in range(open_parenthesis, len(code)):
        if code[index] == "(":
            depth += 1
        elif code[index] == ")":
            depth -= 1
            if depth == 0:
                return split_rhai_top_level_arguments(
                    source[open_parenthesis + 1:index]
                )
    return []


def substitute_rhai_identifiers(
    source: str,
    bindings: Mapping[str, str],
) -> str:
    """Resolve helper parameters without rewriting Rhai string literals.

    Output-field keys are strings.  A textual replacement would turn a key
    such as ``"category_code"`` into ``"2"`` while expanding a helper call,
    which makes the closure report look different even though the emitted
    transform did not change.  Only identifiers in executable Rhai code are
    eligible for substitution.
    """
    identifier = re.compile(r"\b[A-Za-z_][A-Za-z0-9_]*\b")
    noncode = re.compile(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/', re.DOTALL)

    def resolve_code(code: str) -> str:
        return identifier.sub(
            lambda match: bindings.get(match.group(0), match.group(0)),
            code,
        )

    chunks: list[str] = []
    cursor = 0
    for match in noncode.finditer(source):
        chunks.append(resolve_code(source[cursor : match.start()]))
        chunks.append(match.group(0))
        cursor = match.end()
    chunks.append(resolve_code(source[cursor:]))
    return "".join(chunks)


def transitive_action_census(
    action_name: str,
    functions: Mapping[str, str],
) -> dict[str, Any]:
    """Expand fixed helper calls to count proof work and output transforms."""
    function_names = set(functions)
    counts: Counter[str] = Counter()
    output_transforms: list[dict[str, str]] = []
    witness_names: list[dict[str, str]] = []
    call_paths: list[list[str]] = []

    def visit(
        name: str,
        bindings: Mapping[str, str],
        path: tuple[str, ...],
        output_handles: set[str],
    ) -> None:
        if name in path:
            raise RuntimeError(
                f"refactor census helper cycle: {' -> '.join((*path, name))}"
            )
        source = functions[name]
        code = mask_rhai_noncode(source)
        body_start = code.find("{") + 1
        body_end = code.rfind("}")
        body = source[body_start:body_end]
        body_code = code[body_start:body_end]
        current_path = (*path, name)
        call_paths.append(list(current_path))
        for metric, pattern in {
            "st_sum": r"action\.st_sum\(",
            "st_gt": r"action\.st_gt\(",
            "unsafe": r"unsafe\s*\{",
            "random": r"action\.random\(",
            "var_assign": r"var_assign\(",
            "rotate_key": r"rotate_key\(",
            "intro_vdf": r"action\.intro_vdf\(",
            "intro_lt_eq_u256": r"action\.intro_lt_eq_u256\(",
        }.items():
            counts[metric] += len(re.findall(pattern, code))
        witness_names.extend(
            {
                "name": witness,
                "path": " -> ".join(current_path),
            }
            for witness in re.findall(
                r"\b(?:var|let)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
                r"(?:unsafe\s*\{|action\.random\s*\()",
                code,
            )
        )
        for handle, method, call_arguments, _position in (
            rhai_method_statement_calls(body)
        ):
            if method not in {"set", "update"}:
                continue
            arguments = ",".join(call_arguments)
            resolved_handle = bindings.get(handle, handle)
            if resolved_handle in output_handles:
                output_transforms.append(
                    {
                        "path": " -> ".join(current_path),
                        "target": resolved_handle,
                        "method": method,
                        "expression": re.sub(
                            r"\s+",
                            "",
                            substitute_rhai_identifiers(arguments, bindings),
                        ),
                    }
                )
        for callee, arguments, _position in rhai_plain_statement_calls(body):
            if callee not in function_names:
                continue
            parameters = rhai_function_parameters(functions[callee], callee)
            if len(arguments) != len(parameters):
                raise RuntimeError(
                    f"refactor census call arity mismatch: {name} -> {callee}"
                )
            callee_bindings = {
                parameter: substitute_rhai_identifiers(argument, bindings)
                for parameter, argument in zip(parameters, arguments, strict=True)
            }
            visit(callee, callee_bindings, current_path, output_handles)

    wrapper = functions[action_name]
    outputs = {
        handle
        for handle, mode, _class_name in rhai_action_object_bindings(wrapper)
        if mode == "output"
    }
    visit(action_name, {}, (), outputs)
    return {
        "counts": dict(sorted(counts.items())),
        "output_transforms": output_transforms,
        "witness_names": witness_names,
        "call_paths": call_paths,
    }


REFACTOR_BASELINE = {
    "plugin_bytes": 764_380,
    "plugin_nonblank_lines": 28_710,
    "action_count": 1_650,
    "logical_intro_calls": 1_375,
    "physical_vdf_calls": 970,
    "physical_st_sum": 1_791,
    "physical_st_gt": 142,
    "physical_unsafe": 532,
    "physical_intro_lt_eq_u256": 1,
    "var_assign_calls": 17,
    "rotate_key_calls": 78,
    "random_calls": 100,
}

REFACTOR_PHASE1_DELTAS = {
    "logical": {"st_sum": -327, "unsafe": 0},
}
REFACTOR_PHASE3_BULK_PHYSICAL_DELTAS = {
    "st_sum": -450,
    "st_gt": -44,
    "unsafe": -220,
    "random": -22,
    "var_assign": 0,
    "rotate_key": -22,
    "intro_vdf": 0,
    "intro_lt_eq_u256": 0,
}
REFACTOR_PHASE4_ECONOMY_PHYSICAL = {
    "st_sum": 652, "st_gt": 98, "unsafe": 312, "random": 78,
    "var_assign": 17, "rotate_key": 56, "intro_vdf": 303,
    "intro_lt_eq_u256": 1,
}
REFACTOR_PHASE4_ECONOMY_PHYSICAL_DELTAS = {
    "st_sum": -1_139, "st_gt": -44, "unsafe": -220, "random": -22,
    "var_assign": 0, "rotate_key": -22, "intro_vdf": -667,
    "intro_lt_eq_u256": 0,
}
REFACTOR_PHASE4_ECONOMY_PHASE3_PHYSICAL_DELTAS = {
    "st_sum": -689, "st_gt": 0, "unsafe": 0, "random": 0,
    "var_assign": 0, "rotate_key": 0, "intro_vdf": -667,
    "intro_lt_eq_u256": 0,
}
REFACTOR_PHASE5_ECONOMY_PHYSICAL = {
    **REFACTOR_PHASE4_ECONOMY_PHYSICAL,
    "intro_vdf": 89,
}
REFACTOR_PHASE5_ECONOMY_PHYSICAL_DELTAS = {
    **REFACTOR_PHASE4_ECONOMY_PHYSICAL_DELTAS,
    "intro_vdf": -881,
}
REFACTOR_PHASE6_CANARY_ECONOMY_PHYSICAL = {
    "st_sum": 586, "st_gt": 64, "unsafe": 278, "random": 60,
    "var_assign": 17, "rotate_key": 38, "intro_vdf": 71,
    "intro_lt_eq_u256": 1,
}
REFACTOR_PHASE6_CANARY_ECONOMY_PHYSICAL_DELTAS = {
    "st_sum": -1_205, "st_gt": -78, "unsafe": -254, "random": -40,
    "var_assign": 0, "rotate_key": -40, "intro_vdf": -899,
    "intro_lt_eq_u256": 0,
}
REFACTOR_CURRENT_PHASE3_LOGICAL = {
    "st_sum": 35_041, "st_gt": 1_466, "unsafe": 15_525,
    "random": 2_857, "var_assign": 1_419, "rotate_key": 2_864,
    "intro_vdf": 659, "intro_lt_eq_u256": 23,
}
REFACTOR_CURRENT_ACCEPTED_LOGICAL = {
    **REFACTOR_CURRENT_PHASE3_LOGICAL, "st_sum": 34_714,
}
REFACTOR_CURRENT_PHASE3_PHYSICAL = {
    "st_sum": 1_731, "st_gt": 118, "unsafe": 508, "random": 88,
    "var_assign": 17, "rotate_key": 66, "intro_vdf": 277,
    "intro_lt_eq_u256": 1,
}
REFACTOR_CURRENT_ACCEPTED_PHYSICAL = {
    "st_sum": 1_281, "st_gt": 74, "unsafe": 288, "random": 66,
    "var_assign": 17, "rotate_key": 44, "intro_vdf": 277,
    "intro_lt_eq_u256": 1,
}
REFACTOR_CURRENT_PHASE4_PHYSICAL = {
    "st_sum": 574, "st_gt": 74, "unsafe": 288, "random": 66,
    "var_assign": 17, "rotate_key": 44, "intro_vdf": 268,
    "intro_lt_eq_u256": 1,
}
REFACTOR_CURRENT_PHASE4_PHYSICAL_DELTAS = {
    "st_sum": -1_157, "st_gt": -44, "unsafe": -220, "random": -22,
    "var_assign": 0, "rotate_key": -22, "intro_vdf": -9,
    "intro_lt_eq_u256": 0,
}
REFACTOR_CURRENT_PHASE4_PHASE3_RENDER_PHYSICAL_DELTAS = {
    "st_sum": -707, "st_gt": 0, "unsafe": 0, "random": 0,
    "var_assign": 0, "rotate_key": 0, "intro_vdf": -9,
    "intro_lt_eq_u256": 0,
}
REFACTOR_CURRENT_PHASE5_PHYSICAL = {
    **REFACTOR_CURRENT_PHASE4_PHYSICAL,
    "intro_vdf": 54,
}
REFACTOR_CURRENT_PHASE5_PHYSICAL_DELTAS = {
    **REFACTOR_CURRENT_PHASE4_PHYSICAL_DELTAS,
    "intro_vdf": -223,
}

REFACTOR_LOGICAL_BASELINE = {
    "st_sum": 35_101,
    "st_gt": 1_490,
    "unsafe": 15_549,
    "random": 2_869,
    "var_assign": 1_419,
    "rotate_key": 2_888,
    "intro_vdf": 1_352,
    "intro_lt_eq_u256": 23,
}

REFACTOR_FINAL_TARGETS = {
    "plugin_bytes": 600_000,
    "plugin_nonblank_lines": 15_000,
}

REFACTOR_PHASE6_LAYOUT_TARGETS = {
    "economy": {
        "plugin_bytes": 599_317,
        "plugin_nonblank_lines": 12_758,
        "sha256": "2e9f6416d12963273fa7bde5474bbfaad4d81e42010f3862654bd1ad2e423849",
        "baseline_bytes": 620_127,
        "baseline_nonblank_lines": 19_595,
        "actions": 1_650,
        "helpers": 75,
    },
    "current": {
        "plugin_bytes": 591_418,
        "plugin_nonblank_lines": 12_630,
        "sha256": "3955e24fb567ecfe9a942f61c761e2dffb8a6f7d6b049b6bf2393ecf2432f1d1",
        "baseline_bytes": 611_776,
        "baseline_nonblank_lines": 19_467,
        "actions": 1_638,
        "helpers": 55,
    },
}

REFACTOR_FAMILY_BASELINES = {
    "extraction_refinement": {
        "action_count": 687,
        "nonblank_lines": 14_589,
        "bytes": 335_594,
    },
    "deterministic_reveals": {
        "action_count": 595,
        "nonblank_lines": 3_148,
        "bytes": 112_314,
    },
    "signal_detection": {
        "action_count": 23,
        "nonblank_lines": 1_334,
        "bytes": 56_687,
    },
    "component_fabrication": {
        "action_count": 90,
        "nonblank_lines": 3_060,
        "bytes": 48_103,
    },
    "derived_skills": {
        "action_count": 72,
        "nonblank_lines": 1_550,
        "bytes": 44_162,
    },
    "capability_artifacts": {
        "action_count": 72,
        "nonblank_lines": 1_522,
        "bytes": 36_946,
    },
}


def refactor_family_name(action: Mapping[str, Any]) -> str | None:
    """Return the PRD family for actions tracked by the refactor budget."""
    family = action["family"]
    if family in {
        "extract_resource",
        "extract_civilization_tech_resource",
        "refine_resource",
    }:
        return "extraction_refinement"
    if str(action["name"]).startswith(
        (
            "RevealWarpCoordinate",
            "RevealTimeCoordinate",
            "RevealWarpChart",
            "RevealEpochChart",
        )
    ):
        return "deterministic_reveals"
    if family == "detect_signal":
        return "signal_detection"
    if family == "fabricate_component":
        return "component_fabrication"
    if family == "develop_derived_skill":
        return "derived_skills"
    if action["name"] in {capability["action"] for capability in SKILL_CAPABILITIES}:
        return "capability_artifacts"
    return None


def capacity_witness_copy_is_exact(source: str) -> bool:
    """Keep capacity fields in the proven rc.43-compatible witness form."""
    return (
        source.count(
            "var extraction_amount = unsafe { ship.extraction_amount - 0 };"
        )
        == 1
        and source.count(
            "var rare_extraction_amount = unsafe { "
            "ship.rare_extraction_amount - 0 };"
        )
        == 1
        and source.count(
            "action.st_sum(ship.extraction_amount, 0, extraction_amount);"
        )
        == 1
        and source.count(
            "action.st_sum(ship.rare_extraction_amount, 0, "
            "rare_extraction_amount);"
        )
        == 1
        and '["extraction_amount", extraction_amount]' in source
        and '["rare_extraction_amount", rare_extraction_amount]' in source
        and source.count("action.st_sum(ship.extraction_amount, 0, 250);")
        == 1
        and source.count(
            "action.st_sum(ship.rare_extraction_amount, 0, 25);"
        )
        == 1
    )


def refactor_census(plugin: str, actions: list[dict[str, Any]]) -> dict[str, Any]:
    """Record monotonic source budgets and proof-shape inventories.

    The final targets are intentionally reported separately from the passing
    baseline ceilings so intermediate refactor phases remain measurable without
    pretending an incomplete phase has already reached release size.
    """
    functions = rhai_function_sources(plugin)
    action_names = [action["name"] for action in actions]
    action_sources = {
        name: functions.get(name, "") for name in action_names
    }
    family_rows: dict[str, dict[str, Any]] = {}
    for family_name, baseline in REFACTOR_FAMILY_BASELINES.items():
        names = [
            action["name"]
            for action in actions
            if refactor_family_name(action) == family_name
        ]
        sources = [action_sources[name] for name in names]
        nonblank_lines = sum(
            sum(bool(line.strip()) for line in source.splitlines())
            for source in sources
        )
        source_bytes = sum(
            len(source.rstrip().encode("utf-8")) for source in sources
        )
        checks = {
            "action_count_exact": len(names) == baseline["action_count"],
            "nonblank_lines_monotonic": (
                nonblank_lines <= baseline["nonblank_lines"]
            ),
            "bytes_monotonic": source_bytes <= baseline["bytes"],
        }
        family_rows[family_name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "baseline_ceiling": baseline,
            "action_names": names,
            "action_count": len(names),
            "nonblank_lines": nonblank_lines,
            "bytes": source_bytes,
            "checks": checks,
        }

    direct_roles = {
        name: source_action_object_roles(source)
        for name, source in action_sources.items()
    }
    transitive_actions = {
        action_name: transitive_action_census(action_name, functions)
        for action_name in action_names
    }
    logical_counts: Counter[str] = Counter()
    for row in transitive_actions.values():
        logical_counts.update(row["counts"])
    logical_intro_calls = (
        logical_counts["intro_vdf"]
        + logical_counts["intro_lt_eq_u256"]
    )
    output_closure = {
        name: {
            "transforms": row["output_transforms"],
            "call_paths": row["call_paths"],
        }
        for name, row in transitive_actions.items()
    }
    normalized_output_transforms = {
        name: sorted(
            {
                (row["target"], row["method"], row["expression"])
                for row in closure["transforms"]
            }
        )
        for name, closure in output_closure.items()
    }
    plugin_nonblank_lines = sum(bool(line.strip()) for line in plugin.splitlines())
    physical_counts = physical_proof_counts(plugin)
    physical_vdf_calls = physical_counts["intro_vdf"]
    phase1_ledger = {
        "logical": {
            metric: logical_counts[metric] - baseline
            for metric, baseline in REFACTOR_LOGICAL_BASELINE.items()
        },
    }
    phase5_bulk_physical_ledger = {
        metric: physical_counts[metric] - REFACTOR_BASELINE[baseline_key]
        for metric, baseline_key in {
            "st_sum": "physical_st_sum", "st_gt": "physical_st_gt",
            "unsafe": "physical_unsafe", "random": "random_calls",
            "var_assign": "var_assign_calls", "rotate_key": "rotate_key_calls",
            "intro_vdf": "physical_vdf_calls", "intro_lt_eq_u256": "physical_intro_lt_eq_u256",
        }.items()
    }
    current_phase1_ledger = {
        metric: logical_counts[metric] - baseline
        for metric, baseline in REFACTOR_CURRENT_PHASE3_LOGICAL.items()
    }
    current_phase1_phase3_physical_ledger = {
        metric: physical_counts[metric] - baseline
        for metric, baseline in REFACTOR_CURRENT_PHASE3_PHYSICAL.items()
    }
    capacity_paths = {
        "v1_position_coordinate": functions[
            "ExtractAnomalyWarpCoordinate"
        ],
        "v1_time_coordinate": functions["ExtractAnomalyTimeCoordinate"],
        "v2_position_chart": functions["extract_v2_chart_core"],
        "v2_epoch_chart": functions["extract_v2_chart_core"],
    }
    capacity_paths_exact = all(
        capacity_witness_copy_is_exact(source)
        for source in capacity_paths.values()
    )
    phase3_canaries = phase3_helper_canary_audit(plugin, BODY_BANK)
    phase4_canaries = phase4_adapter_canary_audit(plugin, actions, BODY_BANK)
    phase5_canaries = phase5_adapter_canary_audit(plugin, actions)
    phase6_canaries = phase6_movement_canary_audit(plugin, actions)
    phase6_layout = phase6_token_layout_audit(
        plugin, actions, BODY_BANK
    )
    profile_census = phase4_profile_census(plugin, actions, BODY_BANK)
    expected_economy_physical_ledger = (
        REFACTOR_PHASE6_CANARY_ECONOMY_PHYSICAL_DELTAS
        if PHASE6_MOVEMENT_CANARIES_ENABLED
        else REFACTOR_PHASE5_ECONOMY_PHYSICAL_DELTAS
    )
    checks = {
        "plugin_bytes_monotonic": len(plugin.encode("utf-8")) <= REFACTOR_BASELINE["plugin_bytes"],
        "plugin_nonblank_lines_monotonic": (
            plugin_nonblank_lines
            <= REFACTOR_BASELINE["plugin_nonblank_lines"]
        ),
        "action_count_exact": len(actions) == REFACTOR_BASELINE["action_count"],
        "logical_intro_calls_exact": (
            logical_intro_calls == REFACTOR_BASELINE["logical_intro_calls"]
        ),
        "physical_vdf_calls_monotonic": (
            physical_vdf_calls <= REFACTOR_BASELINE["physical_vdf_calls"]
        ),
        "phase5_bulk_physical_ledger_exact": (
            phase5_bulk_physical_ledger
            == expected_economy_physical_ledger
        ),
        "phase1_logical_ledger_exact": (
            phase1_ledger["logical"]
            == {
                "st_sum": REFACTOR_PHASE1_DELTAS["logical"]["st_sum"],
                "st_gt": 0,
                "unsafe": REFACTOR_PHASE1_DELTAS["logical"]["unsafe"],
                "random": 0,
                "var_assign": 0,
                "rotate_key": 0,
                "intro_vdf": 0,
                "intro_lt_eq_u256": 0,
            }
        ),
        "phase1_capacity_paths_exact": capacity_paths_exact,
        "phase3_helper_canaries_exact": phase3_canaries["status"] == "pass",
        "phase4_adapter_canaries_exact": phase4_canaries["status"] == "pass",
        "phase5_adapter_canaries_exact": phase5_canaries["status"] == "pass",
        "phase6_movement_canaries_exact": phase6_canaries["status"] == "pass",
        "phase6_token_layout_exact": phase6_layout["status"] == "pass",
        "family_budgets": all(
            row["status"] == "pass" for row in family_rows.values()
        ),
    }
    common_check_names = {
        "plugin_bytes_monotonic",
        "plugin_nonblank_lines_monotonic",
        "physical_vdf_calls_monotonic",
        "phase1_capacity_paths_exact",
        "phase3_helper_canaries_exact",
        "phase4_adapter_canaries_exact",
        "phase5_adapter_canaries_exact",
        "phase6_movement_canaries_exact",
        "phase6_token_layout_exact",
        "family_budgets",
    }
    economy_check_names = {
        "action_count_exact",
        "logical_intro_calls_exact",
        "phase5_bulk_physical_ledger_exact",
        "phase1_logical_ledger_exact",
    }
    current_check_names: set[str] = set()
    if ACTIVE_VDF_PROFILE == "current":
        # Current intentionally has fewer wrappers and Intro calls than the
        # canonical economy release.  Its phase gate is a separate frozen
        # current/Phase-3 comparison, never a relaxed economy ledger.
        checks.update({
            "current_action_count_exact": len(actions) == 1_638,
            "current_logical_vdf_exact": logical_counts["intro_vdf"] == 659,
            "current_intro_lt_eq_exact": logical_counts["intro_lt_eq_u256"] == 23,
            "current_logical_intro_calls_exact": logical_intro_calls == 682,
            "current_phase1_logical_ledger_exact": (
                current_phase1_ledger
                == {
                    "st_sum": -327,
                    "st_gt": 0,
                    "unsafe": 0,
                    "random": 0,
                    "var_assign": 0,
                    "rotate_key": 0,
                    "intro_vdf": 0,
                    "intro_lt_eq_u256": 0,
                }
            ),
            "current_phase1_phase3_physical_ledger_exact": (
                current_phase1_phase3_physical_ledger
                == REFACTOR_CURRENT_PHASE5_PHYSICAL_DELTAS
            ),
            "current_profile_phase3_baseline_exact": profile_census["status"] == "pass",
        })
        current_check_names = {
            "current_action_count_exact",
            "current_logical_vdf_exact",
            "current_intro_lt_eq_exact",
            "current_logical_intro_calls_exact",
            "current_phase1_logical_ledger_exact",
            "current_phase1_phase3_physical_ledger_exact",
            "current_profile_phase3_baseline_exact",
        }
    controlling_check_names = common_check_names | (
        economy_check_names
        if ACTIVE_VDF_PROFILE == "economy"
        else current_check_names
    )
    return {
        "status": (
            "pass"
            if all(checks[name] for name in controlling_check_names)
            else "fail"
        ),
        "profile": ACTIVE_VDF_PROFILE,
        "canonical_release_profile": ACTIVE_VDF_PROFILE == "economy",
        "baseline": REFACTOR_BASELINE,
        "final_targets": REFACTOR_FINAL_TARGETS,
        "final_target_status": {
            "plugin_bytes": len(plugin.encode("utf-8"))
            <= REFACTOR_FINAL_TARGETS["plugin_bytes"],
            "plugin_nonblank_lines": plugin_nonblank_lines
            <= REFACTOR_FINAL_TARGETS["plugin_nonblank_lines"],
        },
        "plugin": {
            "sha256": hashlib.sha256(plugin.encode("utf-8")).hexdigest(),
            "bytes": len(plugin.encode("utf-8")),
            "nonblank_lines": plugin_nonblank_lines,
            "function_count": len(functions),
            "action_count": len(actions),
            "helper_count": len(functions) - len(actions),
            "physical_vdf_calls": physical_vdf_calls,
            "physical_proof_counts": physical_counts,
        },
        "families": family_rows,
        "direct_role_order": direct_roles,
        "output_closure": output_closure,
        "normalized_output_transforms": normalized_output_transforms,
        "intro": {
            "logical_intro_calls": logical_intro_calls,
            "physical_vdf_calls": physical_vdf_calls,
        },
        "logical_proof_counts": dict(sorted(logical_counts.items())),
        "phase1_ledger": phase1_ledger,
        "phase5_bulk_physical_ledger": phase5_bulk_physical_ledger,
        "current_phase1_ledger": current_phase1_ledger,
        "current_phase1_phase3_physical_ledger": (
            current_phase1_phase3_physical_ledger
        ),
        "controlling_checks": sorted(controlling_check_names),
        "phase1_capacity_paths": {
            "status": "pass" if capacity_paths_exact else "fail",
            "paths": sorted(capacity_paths),
        },
        "phase3_helper_canaries": phase3_canaries,
        "phase4_adapter_canaries": phase4_canaries,
        "phase5_adapter_canaries": phase5_canaries,
        "phase6_movement_canaries": phase6_canaries,
        "phase6_token_layout": phase6_layout,
        "profile_aware_phase4_census": profile_census,
        "transitive_actions": transitive_actions,
        "checks": checks,
    }


def object_set_fields(source: str, handle: str) -> list[str]:
    calls = [
        arguments
        for target, _method, arguments, _position
        in rhai_method_statement_calls(source, "set")
        if target == handle
    ]
    if len(calls) != 1 or len(calls[0]) != 1:
        return []
    return re.findall(
        r'\[\s*"([^"]+)"', mask_rhai_comments(calls[0][0])
    )


def object_update_pairs(source: str, handle: str) -> list[tuple[str, str]]:
    """Return literal-key updates for one Rhai object handle in source order."""
    return [
        (json.loads(arguments[0]), arguments[1])
        for target, _method, arguments, _position
        in rhai_method_statement_calls(source, "update")
        if target == handle
        and len(arguments) == 2
        and re.fullmatch(r'"(?:\\.|[^"\\])*"', arguments[0])
    ]


def semantic_zero_key_updates(source: str) -> list[tuple[str, str]]:
    """Return (object handle, zero alias) key updates in source order."""
    functions = rhai_function_sources(source)
    if len(functions) > 1:
        return [
            update
            for function_source in functions.values()
            for update in semantic_zero_key_updates(function_source)
        ]
    code = mask_rhai_noncode(source)
    zero_names = set(
        re.findall(
            r"\b(?:let|var)\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*"
            r"action\.top_limb_u256\(\s*0\s*\)\s*;",
            code,
        )
    )
    updates: list[tuple[str, str]] = []
    for handle, _method, arguments, _position in rhai_method_statement_calls(
        source, "update"
    ):
        if (
            len(arguments) == 2
            and arguments[0] == '"key"'
            and arguments[1] in zero_names
        ):
            updates.append((handle, arguments[1]))
    return updates


def has_literal_zero_key_update(source: str) -> bool:
    """Require a key update from a local fixed-zero U256 witness."""
    return bool(semantic_zero_key_updates(source))


def deterministic_zero_key_audit(
    plugin: str,
    actions: list[dict[str, Any]],
    deterministic_classes: set[str],
) -> dict[str, Any]:
    """Bind every fixed-zero key to its exact deterministic output class."""
    action_names = {action["name"] for action in actions}
    function_sources = rhai_function_sources(plugin)
    scan_helper = function_sources.get("scan_body_core", "")
    detect_helper = function_sources.get("detect_signal_core", "")
    helper_zero_updates = {
        name: semantic_zero_key_updates(source)
        for name, source in function_sources.items()
        if name not in action_names
        and semantic_zero_key_updates(source)
    }
    details: dict[str, Any] = {}
    expected_action_names: set[str] = set()
    actual_action_names: set[str] = set()
    direct_update_count = 0
    for action in actions:
        name = action["name"]
        source = function_sources.get(name, "")
        declarations = {
            handle: {"mode": mode, "class": class_name}
            for handle, mode, class_name in rhai_action_object_bindings(source)
        }
        expected = [
            {"mode": item["mode"], "class": item["class"]}
            for item in action["objects"]
            if item["mode"] == "output"
            and item["class"] in deterministic_classes
        ]
        if expected:
            expected_action_names.add(name)
        direct_updates = semantic_zero_key_updates(source)
        direct_update_count += len(direct_updates)
        actual = [
            declarations.get(
                handle,
                {"mode": "unknown", "class": "unknown"},
            )
            for handle, _alias in direct_updates
        ]
        if action["family"] == "scan_body":
            wrapper_calls = rhai_call_arguments(source, "scan_body_core")
            scan_args = wrapper_calls[0] if len(wrapper_calls) == 1 else []
            if (
                semantic_zero_key_updates(scan_helper) == [("body", "zero")]
                and len(scan_args) == 14
            ):
                actual.append(
                    declarations.get(
                        scan_args[1],
                        {"mode": "unknown", "class": "unknown"},
                    )
                )
        if name.startswith("DetectCelestialSignal_"):
            detect_args = rhai_call_arguments(
                source, "detect_signal_core"
            )
            if (
                semantic_zero_key_updates(detect_helper)
                == [("signal", "zero")]
                and len(detect_args) == 1
                and len(detect_args[0]) == 9
            ):
                actual.append(
                    declarations.get(
                        detect_args[0][2],
                        {"mode": "unknown", "class": "unknown"},
                    )
                )
        if actual:
            actual_action_names.add(name)
        checks = {
            "fixed_zero_targets_exact_deterministic_outputs": (
                actual == expected
            ),
            "no_sdk_default_or_nonoutput_key_zeroed": all(
                row["mode"] == "output"
                and row["class"] in deterministic_classes
                for row in actual
            ),
        }
        details[name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
            "expected": expected,
            "actual": actual,
            "direct_updates": direct_updates,
        }
    physical_count = sum(
        len(semantic_zero_key_updates(source))
        for source in function_sources.values()
    )
    expected_helper_zero_updates = {"scan_body_core": [("body", "zero")]}
    if detect_helper:
        expected_helper_zero_updates["detect_signal_core"] = [("signal", "zero")]
    helper_update_count = sum(
        len(updates) for updates in helper_zero_updates.values()
    )
    expected_physical_count = direct_update_count + helper_update_count
    checks = {
        "fixed_zero_action_set_exact": (
            actual_action_names == expected_action_names
        ),
        "all_action_targets_exact": all(
            detail["status"] == "pass" for detail in details.values()
        ),
        "only_released_helpers_own_fixed_zero_outputs": (
            helper_zero_updates == expected_helper_zero_updates
        ),
        "physical_fixed_zero_count_exact": (
            physical_count == expected_physical_count
            and direct_update_count + helper_update_count
            == expected_physical_count
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "checks": checks,
        "expected_action_count": len(expected_action_names),
        "actual_action_count": len(actual_action_names),
        "expected_physical_update_count": expected_physical_count,
        "physical_update_count": physical_count,
        "helper_zero_updates": helper_zero_updates,
        "actions": details,
    }




def replace_action_function(
    plugin: str,
    name: str,
    transform: Any,
) -> str:
    """Return an in-memory plugin with exactly one action source transformed."""
    source = raw_action_function_source(plugin, name)
    if not source:
        raise ValueError(f"action source not found: {name}")
    replacement = transform(source)
    if replacement == source:
        raise ValueError(f"adversarial transform made no change: {name}")
    if plugin.count(source) != 1:
        raise ValueError(f"action source is not unique: {name}")
    return plugin.replace(source, replacement, 1)


def replace_named_function(
    plugin: str,
    name: str,
    transform: Any,
) -> str:
    """Return an in-memory plugin with one named function transformed."""
    source = raw_named_function_source(plugin, name)
    if not source:
        raise ValueError(f"function source not found: {name}")
    replacement = transform(source)
    if replacement == source:
        raise ValueError(f"adversarial transform made no change: {name}")
    if plugin.count(source) != 1:
        raise ValueError(f"function source is not unique: {name}")
    return plugin.replace(source, replacement, 1)




def civilization_tech_audit(
    actions: list[dict[str, Any]],
    plugin: str,
    bank: list[dict[str, Any]],
) -> dict[str, Any]:
    """Validate the exact civilization-tech v3 catalog and rendered sources."""
    by_name = {action["name"]: action for action in actions}
    candidates_by_code = {candidate["code"]: candidate for candidate in bank}
    expected_new_candidates = {
        12: {
            "code": 12,
            "name": "Megastructure",
            "slug": "Megastructure",
            "body_type": 8,
            "body_profile": 70,
            "nominal_denominator": 8,
            "target_top_limb": 2_305_843_009_213_693_952,
            "life_stat": 0,
            "matter": 10_000,
            "crystal": 10_000,
            "gas": 0,
            "energy": 10_000,
            "satellites": 0,
        },
        13: {
            "code": 13,
            "name": "Gas Cluster",
            "slug": "GasCluster",
            "body_type": 9,
            "body_profile": 80,
            "nominal_denominator": 8,
            "target_top_limb": 2_305_843_009_213_693_952,
            "life_stat": 0,
            "matter": 5_000,
            "crystal": 0,
            "gas": 20_000,
            "energy": 5_000,
            "satellites": 0,
        },
        14: {
            "code": 14,
            "name": "Stellar Remnant",
            "slug": "StellarRemnant",
            "body_type": 10,
            "body_profile": 90,
            "nominal_denominator": 8,
            "target_top_limb": 2_305_843_009_213_693_952,
            "life_stat": 0,
            "matter": 10_000,
            "crystal": 0,
            "gas": 0,
            "energy": 20_000,
            "satellites": 0,
        },
    }

    resource_details: dict[str, Any] = {}
    for resource in CIVILIZATION_TECH_RESOURCES:
        candidate = candidates_by_code[resource["candidate_code"]]
        source = action_function_source(plugin, resource["action"])
        semantic_source = phase4_wrapper_semantic_source(
            plugin,
            resource["action"],
            "composite" if resource["composite"] else "body",
        )
        phase4_helper = phase4_helper_for(
            resource["action"],
            "composite" if resource["composite"] else "body",
            resource["vdf_iterations"],
        )
        expected_source = extract_source(
            resource["name"],
            resource["code"],
            resource["remaining_field"],
            resource["vdf_iterations"],
            action_name=resource["action"],
            candidate=candidate,
            child_allocations=resource["child_allocations"],
            skill_code=resource["skill_code"],
            minimum_ship_tier=resource["minimum_ship_tier"],
        ).strip()
        output_class = resource["output_class"]
        output_handle = (
            "composite_resource"
            if output_class == COMPOSITE_RESOURCE
            else "resource"
        )
        selected_tier = SHIP_TIERS[resource["minimum_ship_tier"]]
        expected_core = (
            "extract_composite_resource_core"
            if resource["composite"]
            else "extract_direct_resource_core"
        )
        checks = {
            "roles_exact": (
                resource["action"] in by_name
                and action_object_roles(by_name[resource["action"]])
                == [
                    ("output", SHIP),
                    ("output", output_class),
                    ("input", SHIP),
                    ("mutate", BODY),
                ]
            ),
            "source_exact": rhai_sources_equal(source, expected_source),
            "vdf_and_subaction_policy_exact": (
                (
                    f"action.intro_vdf({resource['vdf_iterations']}, body);"
                    in semantic_source
                    if resource["vdf_iterations"] is not None
                    else "intro_vdf" not in semantic_source
                )
                and "subaction" not in source
            ),
            "candidate_code_exact": (
                f"action.st_sum(body.candidate_code, 0, "
                f"{resource['candidate_code']});" in semantic_source
                or phase4_helper is not None
            ),
            "resource_type_exact": (
                f"\n{resource['code']},\n" in semantic_source
                or phase4_helper is not None
            ),
            "remaining_pool_exact": (
                f'"{resource["remaining_field"]}"' in semantic_source
                and f"\n{selected_tier['extraction_amount']},\n"
                in semantic_source
                or phase4_helper is not None
            ),
            "skill_gate_exact": (
                f"action.st_sum(ship.active_skill_type,0,"
                f"{resource['skill_code'] if resource['skill_code'] is not None else 0});"
                in semantic_source
                or phase4_helper is not None
            ),
            "native_random_output_key": (
                f"{expected_core}(" in semantic_source
                and f'{output_handle}.update("key", zero);'
                not in common_helpers()
            ),
            "composite_child_pools_exact": (
                (
                    "extract_composite_resource_core(" in semantic_source
                    and (
                        f"\n"
                        f"{selected_tier['rare_extraction_amount']},\n"
                    )
                    in semantic_source
                )
                if resource["composite"]
                else "extract_direct_resource_core(" in semantic_source
            ) or phase4_helper is not None,
        }
        resource_details[resource["action"]] = {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
        }

    technology_core = named_function_source(
        plugin, "develop_technology_skill_core"
    )
    technology_core_checks = {
        "present_once": (
            rhai_function_definition_count(
                plugin, "develop_technology_skill_core"
            ) == 1
        ),
        "no_object_role_declarations": not source_action_object_roles(
            technology_core
        ),
        "fixed_versions_proven": all(
            token in technology_core
            for token in (
                "prove_fixed_versions(action, ship);",
                "prove_fixed_versions(action, civilization);",
                (
                    "action.st_sum("
                    "civilization.civilization_version, 0, "
                    f"{VERSIONS['civilization_version']});"
                ),
            )
        ),
        "replacement_ship_fields_exact": (
            object_set_fields(technology_core, "next_ship")
            == list(SHIP_SEMANTIC_FIELDS)
            and '["active_skill_type", 0]' in technology_core
        ),
        "dynamic_skill_values_present": all(
            token in technology_core
            for token in (
                "civilization.civilization_type",
                '["skill_type", skill_type]',
                '["reusable", reusable]',
            )
        ),
        "technology_skill_fields_exact": (
            object_set_fields(technology_core, "technology_skill")
            == [
                "schema_version",
                "mechanics_version",
                "universe_version",
                "civilization_version",
                "skill_type",
                "reusable",
            ]
        ),
        "key_rotation_exact": (
            technology_core.count(
                "rotate_key(civilization, next_civilization_key);"
            )
            == 1
        ),
        "vdf_and_subaction_absent": (
            "intro_vdf" not in technology_core
            and "subaction" not in technology_core
        ),
    }
    skill_details: dict[str, Any] = {}
    for skill in TECHNOLOGY_SKILLS:
        source = action_function_source(plugin, skill["action"])
        calls = rhai_call_arguments(source, "develop_technology_skill_core")
        call_arguments = calls[0] if len(calls) == 1 else []
        expected_call_arguments = [
            "action",
            "next_ship",
            "technology_skill",
            "ship",
            "civilization",
            str(skill["civilization_type"]),
            str(skill["code"]),
            str(skill["reusable"]),
        ]
        checks = {
            "roles_exact": (
                skill["action"] in by_name
                and action_object_roles(by_name[skill["action"]])
                == [
                    ("output", SHIP),
                    ("output", TECHNOLOGY_SKILL),
                    ("input", SHIP),
                    ("mutate", CIVILIZATION),
                ]
            ),
            "source_exact": rhai_sources_equal(
                source, develop_technology_skill_source(skill)
            ),
            "core_arguments_exact": (
                call_arguments == expected_call_arguments
            ),
            "skill_type_exact": (
                call_arguments == expected_call_arguments
                and call_arguments[6] == str(skill["code"])
            ),
            "civilization_type_gate_exact": (
                call_arguments == expected_call_arguments
                and call_arguments[5]
                == str(skill["civilization_type"])
            ),
            "reusable_exact": (
                call_arguments == expected_call_arguments
                and call_arguments[7] == str(skill["reusable"])
            ),
            "no_vdf_or_subaction": (
                "intro_vdf" not in source
                and "subaction" not in source
                and technology_core_checks["vdf_and_subaction_absent"]
            ),
        }
        skill_details[skill["action"]] = {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
        }

    authorization_core = named_function_source(
        plugin, "authorize_large_ship_permit_core"
    )
    authorization_core_checks = {
        "present_once": (
            rhai_function_definition_count(
                plugin, "authorize_large_ship_permit_core"
            ) == 1
        ),
        "no_object_role_declarations": not source_action_object_roles(
            authorization_core
        ),
        "fixed_versions_proven": all(
            token in authorization_core
            for token in (
                "prove_fixed_versions(action, ship);",
                "prove_fixed_versions(action, permit);",
            )
        ) and (
            f"action.st_sum(permit.schema_version, 0, "
            f"{VERSIONS['schema_version']});"
            not in authorization_core
        ),
        "replacement_ship_fields_exact": (
            object_set_fields(authorization_core, "next_ship")
            == list(SHIP_SEMANTIC_FIELDS)
            and '["active_skill_type", 0]' in authorization_core
        ),
        "location_binding_exact": all(
            f"action.st_sum(permit.{field}, 0, {field});"
            in authorization_core
            for field in ("x", "y", "z", "epoch")
        ),
        "dynamic_authorization_exact": all(
            token in authorization_core
            for token in (
                (
                    "action.st_sum("
                    "ship.active_skill_type, 0, skill_type);"
                ),
                "action.st_sum(permit.permit_type, 0, 1);",
                (
                    "action.st_sum("
                    "permit[authorization_field], 0, 0);"
                ),
                "permit.update(authorization_field, 1);",
            )
        ),
        "key_rotation_exact": (
            authorization_core.count(
                "rotate_key(permit, next_permit_key);"
            )
            == 1
        ),
        "intro_vdf_and_subaction_absent": all(
            token not in authorization_core
            for token in ("intro_lt_eq_u256", "intro_vdf", "subaction")
        ),
    }
    authorization_details: dict[str, Any] = {}
    for authorization in LARGE_CONSTRUCTION_SKILLS:
        name = f"AuthorizeLargeShip{authorization['slug']}"
        source = action_function_source(plugin, name)
        calls = rhai_call_arguments(
            source, "authorize_large_ship_permit_core"
        )
        call_arguments = calls[0] if len(calls) == 1 else []
        expected_call_arguments = [
            "action",
            "next_ship",
            "ship",
            "permit",
            str(authorization["skill_code"]),
            f'"{authorization["field"]}"',
        ]
        checks = {
            "roles_exact": (
                name in by_name
                and action_object_roles(by_name[name])
                == [
                    ("output", SHIP),
                    ("input", SHIP),
                    ("mutate", SHIPYARD_PERMIT),
                ]
            ),
            "source_exact": rhai_sources_equal(
                source, authorize_large_ship_permit_source(authorization)
            ),
            "core_arguments_exact": (
                call_arguments == expected_call_arguments
            ),
            "skill_gate_exact": (
                call_arguments == expected_call_arguments
                and call_arguments[4]
                == str(authorization["skill_code"])
            ),
            "authorization_field_exact": (
                call_arguments == expected_call_arguments
                and call_arguments[5]
                == f'"{authorization["field"]}"'
            ),
            "no_intro_vdf_or_subaction": (
                all(
                    token not in source
                    for token in (
                        "intro_lt_eq_u256",
                        "intro_vdf",
                        "subaction",
                    )
                )
                and authorization_core_checks[
                    "intro_vdf_and_subaction_absent"
                ]
            ),
        }
        authorization_details[name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
        }

    scan_core = named_function_source(plugin, "scan_body_core")
    scan_core_checks = {
        "present_once": rhai_function_definition_count(
            plugin, "scan_body_core"
        ) == 1,
        "no_object_role_declarations": not source_action_object_roles(
            scan_core
        ),
        "fixed_versions_and_signal_gates": all(
            token in scan_core
            for token in (
                "prove_fixed_versions(action, signal);",
                "prove_fixed_versions(action, ship);",
                f"action.st_sum(signal.body_bank_version, 0, {VERSIONS['body_bank_version']});",
                "action.st_sum(signal.category_code, 0, category_code);",
                "action.st_sum(signal.candidate_code, 0, candidate_code);",
                "action.st_gt(signal.slot_serial, -1);",
            )
        ),
        "stable_identifier_export_exact": all(
            token in scan_core
            for token in (
                (
                    "var_assign(source_signal_identifier, "
                    "signal.stable_identifier);"
                ),
                (
                    'signal.update("stable_identifier", '
                    "source_signal_identifier);"
                ),
                (
                    '["source_signal_identifier", '
                    "source_signal_identifier]"
                ),
            )
        ),
        "direct_ship_xyze_binding_exact": all(
            line in scan_core
            for line in (
                "action.st_sum(ship.x, 0, sector_x);",
                "action.st_sum(ship.y, 0, sector_y);",
                "action.st_sum(ship.z, 0, sector_z);",
                "action.st_sum(ship.epoch, 0, sector_epoch);",
            )
        ),
        "threshold_exact": (
            "let target = action.top_limb_u256(target_top_limb);"
            in scan_core
            and "action.intro_lt_eq_u256(signal, target);" in scan_core
            and scan_core.count("action.intro_lt_eq_u256(") == 1
        ),
        "body_fields_exact": (
            object_set_fields(scan_core, "body")
            == [field for field, _field_type in SCHEMAS[BODY][:-2]]
        ),
        "deterministic_body_key_exact": (
            'body.update("key", zero);' in scan_core
        ),
        "ship_mutation_allowlist_exact": (
            object_update_pairs(scan_core, "ship")
            == [
                ("active_skill_type", "0"),
                ("action_serial", "next_action_serial"),
            ]
            and scan_core.count("rotate_key(ship, next_ship_key);") == 1
        ),
        "no_vdf_or_subaction": (
            "intro_vdf" not in scan_core and "subaction" not in scan_core
        ),
    }
    materializer_details: dict[str, Any] = {}
    for candidate in bank:
        name = (
            f"ScanCelestialBody_{candidate['code']:02d}_"
            f"{candidate['slug']}"
        )
        source = action_function_source(plugin, name)
        category = celestial_category(candidate)
        calls = rhai_call_arguments(source, "scan_body_core")
        call_arguments = calls[0] if len(calls) == 1 else []
        expected_call_arguments = [
            "action",
            "body",
            "signal",
            "ship",
            str(category["code"]),
            str(candidate["code"]),
            str(candidate["target_top_limb"]),
            str(candidate["body_type"]),
            str(candidate["life_stat"]),
            str(candidate["matter"]),
            str(candidate["crystal"]),
            str(candidate["gas"]),
            str(candidate["energy"]),
            str(candidate["satellites"]),
        ]
        checks = {
            "roles_exact": (
                name in by_name
                and action_object_roles(by_name[name])
                == [
                    ("output", BODY),
                    ("input", SIGNAL),
                    ("mutate", SHIP),
                ]
            ),
            "source_exact": rhai_sources_equal(source, scan_source(candidate)),
            "core_arguments_exact": (
                call_arguments == expected_call_arguments
            ),
            "candidate_constants_exact": (
                call_arguments == expected_call_arguments
                and call_arguments[4:] == expected_call_arguments[4:]
            ),
            "core_invariants_pass": all(scan_core_checks.values()),
            "no_vdf_or_subaction": (
                "intro_vdf" not in source
                and "subaction" not in source
                and scan_core_checks["no_vdf_or_subaction"]
            ),
        }
        materializer_details[name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
        }

    civilization_type_details: dict[str, Any] = {}
    for civilization_type in CIVILIZATION_TYPES:
        name = civilization_type["action"]
        source = action_function_source(plugin, name)
        source_without_whitespace = re.sub(r"\s+", "", source)
        action_metadata = by_name.get(name, {})
        binding_tokens = (
            "varsource_life_signal_identifier=action.random();",
            (
                "var_assign(source_life_signal_identifier,"
                "life_signal.stable_identifier);"
            ),
            (
                'life_signal.update("stable_identifier",'
                "source_life_signal_identifier);"
            ),
            (
                '["source_life_signal_identifier",'
                "source_life_signal_identifier]"
            ),
        )
        binding_positions = [
            source_without_whitespace.find(token) for token in binding_tokens
        ]
        checks = {
            "roles_exact": (
                name in by_name
                and action_object_roles(by_name[name])
                == [
                    ("output", CIVILIZATION),
                    ("input", LIFE_SIGNAL),
                    ("mutate", SHIP),
                ]
            ),
            "source_exact": rhai_sources_equal(
                source, materialize_civilization_source(civilization_type)
            ),
            "direct_ship_xyze_binding_exact": all(
                line in source
                for line in (
                    "action.st_sum(ship.x, 0, sector_x);",
                    "action.st_sum(ship.y, 0, sector_y);",
                    "action.st_sum(ship.z, 0, sector_z);",
                    "action.st_sum(ship.epoch, 0, origin_epoch);",
                )
            ),
            "explicit_selection_metadata_exact": (
                action_metadata.get("selection_mode")
                == EXPLICIT_SELECTION_MODE
                and action_metadata.get("civilization_type")
                == civilization_type["code"]
                and action_metadata.get(
                    "minimum_civilization_scan_serial"
                )
                == civilization_type["minimum_civilization_scan_serial"]
            ),
            "source_life_signal_identifier_raw_binding_exact": (
                all(position >= 0 for position in binding_positions)
                and binding_positions == sorted(binding_positions)
                and all(
                    source_without_whitespace.count(token) == 1
                    for token in binding_tokens
                )
                and "unsafe { source_life_signal_identifier" not in source
                and "st_sum(source_life_signal_identifier" not in source
            ),
            "stable_identifier_range_selection_absent": all(
                token not in source
                for token in (
                    "civilization_selector",
                    "type_lower",
                    "type_upper",
                    "intro_lt_eq_u256",
                )
            ),
            "milestone_gate_exact": (
                source_without_whitespace.count(
                    "action.st_gt(ship.civilization_scan_serial,"
                    f"{civilization_type['minimum_civilization_scan_serial'] - 1});"
                )
                == 1
            ),
            "civilization_type_written_directly": (
                f'["civilization_type", {civilization_type["code"]}]'
                in source
            ),
            "ship_mutation_allowlist_exact": (
                object_update_pairs(source, "ship")
                == [
                    ("active_skill_type", "0"),
                    ("action_serial", "next_action_serial"),
                ]
                and source.count("rotate_key(ship, next_ship_key);") == 1
            ),
            "no_vdf_or_subaction": (
                "intro_vdf" not in source and "subaction" not in source
            ),
        }
        civilization_type_details[name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
        }

    refinement_details: dict[str, Any] = {}
    refinement_core = named_function_source(plugin, "refine_resource_core")
    refinement_core_checks = {
        "present_once": rhai_function_definition_count(
            plugin, "refine_resource_core"
        ) == 1,
        "no_object_role_declarations": not source_action_object_roles(
            refinement_core
        ),
        "fixed_versions_proven": all(
            token in refinement_core
            for token in (
                "prove_fixed_versions(action, ship);",
                "prove_fixed_versions(action, parent);",
            )
        ) and (
            f"action.st_sum(parent.schema_version, 0, "
            f"{VERSIONS['schema_version']});"
            not in refinement_core
        ),
        "replacement_ship_fields_exact": (
            object_set_fields(refinement_core, "next_ship")
            == list(SHIP_SEMANTIC_FIELDS)
        ),
        "dynamic_route_gates_present": all(
            token in refinement_core
            for token in (
                "action.st_sum(ship.active_skill_type, 0, skill_type);",
                (
                    "action.st_sum(parent.resource_type, 0, "
                    "parent_resource_type);"
                ),
                "action.st_gt(parent[child_remaining_field], 0);",
                "parent[child_remaining_field] - 0",
                "parent.update(child_remaining_field, 0);",
            )
        ),
        "resource_output_fields_exact": (
            object_set_fields(refinement_core, "resource")
            == [
                "schema_version",
                "mechanics_version",
                "universe_version",
                "resource_type",
                "amount",
            ]
            and '["resource_type", output_resource_type]'
            in refinement_core
            and '["amount", refinement_amount]' in refinement_core
        ),
        "key_rotation_exact": (
            refinement_core.count("rotate_key(parent, next_parent_key);")
            == 1
        ),
        "vdf_and_subaction_absent": (
            "intro_vdf" not in refinement_core
            and "subaction" not in refinement_core
        ),
    }
    parent_codes = {
        resource["name"]: resource["code"]
        for resource in CIVILIZATION_TECH_RESOURCES
    }
    for route in REFINEMENT_ROUTES:
        source = action_function_source(plugin, route["action"])
        phase4_helper = phase4_helper_for(
            route["action"], "refine", route["vdf_iterations"]
        )
        semantic_source = phase4_wrapper_semantic_source(
            plugin, route["action"], "refine"
        )
        expected_source = refine_resource_source(
            route,
            parent_codes[route["parent_name"]],
        ).strip()
        child_field = f"child_{route['child_slot']}_remaining"
        calls = rhai_call_arguments(
            source, phase4_helper or "refine_resource_core"
        )
        call_arguments = calls[0] if len(calls) == 1 else []
        expected_call_arguments = [
            "action",
            "next_ship",
            "resource",
            "ship",
            "parent",
            str(route["skill_code"]),
            str(parent_codes[route["parent_name"]]),
            f'"{child_field}"',
            str(route["resource_code"]),
        ]
        checks = {
            "roles_exact": (
                route["action"] in by_name
                and action_object_roles(by_name[route["action"]])
                == [
                    ("output", SHIP),
                    ("output", RESOURCE),
                    ("input", SHIP),
                    ("mutate", COMPOSITE_RESOURCE),
                ]
            ),
            "source_exact": rhai_sources_equal(source, expected_source),
            "core_arguments_exact": call_arguments == expected_call_arguments,
            "parent_type_exact": (
                call_arguments == expected_call_arguments
                and call_arguments[6]
                == str(parent_codes[route["parent_name"]])
            ),
            "child_type_exact": (
                call_arguments == expected_call_arguments
                and call_arguments[8] == str(route["resource_code"])
            ),
            "child_pool_exact": (
                call_arguments == expected_call_arguments
                and call_arguments[7] == f'"{child_field}"'
            ),
            "skill_gate_exact": (
                call_arguments == expected_call_arguments
                and call_arguments[5] == str(route["skill_code"])
            ),
            "reusable_prepared_ship_cleared": (
                '["active_skill_type", 0]' in refinement_core
            ),
            "native_random_output_key": (
                'resource.update("key", zero);' not in refinement_core
            ),
            "vdf_and_subaction_policy_exact": (
                (
                    rhai_contains(
                        semantic_source,
                        f"action.intro_vdf({route['vdf_iterations']}, parent);",
                    )
                    if route["vdf_iterations"] is not None
                    else "intro_vdf" not in semantic_source
                )
                and "subaction" not in source
            ),
        }
        refinement_details[route["action"]] = {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
        }

    use_source = action_function_source(plugin, "UseTechnologySkill")
    use_checks = {
        "roles_exact": (
            "UseTechnologySkill" in by_name
            and action_object_roles(by_name["UseTechnologySkill"])
            == [
                ("output", SHIP),
                ("input", SHIP),
                ("mutate", TECHNOLOGY_SKILL),
            ]
        ),
        "source_exact": rhai_sources_equal(
            use_source, use_technology_skill_source()
        ),
        "reusable_required": (
            "action.st_sum(technology_skill.reusable, 0, 1);"
            in use_source
        ),
        "selected_skill_copied_to_replacement_ship": (
            '["active_skill_type", active_skill_type]' in use_source
            and '["active_skill_type", 0]' not in use_source
        ),
        "skill_only_key_rotates": (
            "technology_skill.update(" not in use_source
            and use_source.count(
                "rotate_key(technology_skill, next_skill_key);"
            )
            == 1
        ),
        "no_vdf_or_subaction": (
            "intro_vdf" not in use_source and "subaction" not in use_source
        ),
    }

    top_checks = {
        "technology_skill_schema_exact": SCHEMAS[TECHNOLOGY_SKILL]
        == [
            ("schema_version", "Int"),
            ("mechanics_version", "Int"),
            ("universe_version", "Int"),
            ("civilization_version", "Int"),
            ("skill_type", "Int"),
            ("reusable", "Int"),
            ("key", "Raw"),
            ("stable_identifier", "Raw"),
        ],
        "body_bank_codes_exact": [candidate["code"] for candidate in bank]
        == list(range(len(bank))),
        "new_candidates_exact": all(
            candidates_by_code.get(code) == expected
            for code, expected in expected_new_candidates.items()
        ),
        "required_legacy_pool_extensions_exact": (
            candidates_by_code[3]["gas"] == 3_000
            and candidates_by_code[3]["energy"] == 3_000
            and candidates_by_code[11]["matter"] == 18_000
            and candidates_by_code[11]["energy"] == 18_000
        ),
        "resource_route_count_exact": (
            len(CIVILIZATION_TECH_RESOURCES)
            == len(
                {
                    (resource["candidate_code"], resource["code"])
                    for resource in CIVILIZATION_TECH_RESOURCES
                }
            )
        ),
        "resource_routes_per_body_exact": all(
            7
            <= sum(
                resource["candidate_code"] == candidate_code
                for resource in CIVILIZATION_TECH_RESOURCES
            )
            <= 8
            for candidate_code in range(15)
        ),
        "body_signature_resource_minimum_exact": all(
            sum(
                resource["candidate_code"] == candidate_code
                and _resource_name_frequency[resource["name"]] == 1
                for resource in CIVILIZATION_TECH_RESOURCES
            )
            >= 4
            for candidate_code in range(15)
        ),
        "resource_action_tier_variants_exact": (
            len(
                [
                    action
                    for action in actions
                    if action["family"]
                    == "extract_civilization_tech_resource"
                ]
            )
            == sum(
                len(
                    extraction_tier_variants(
                        resource["action"],
                        resource["minimum_ship_tier"],
                    )
                )
                for resource in CIVILIZATION_TECH_RESOURCES
            )
        ),
        "source_resource_codes_exact": (
            all(
                SOURCE_RESOURCE_CODES[name]
                == V3_SOURCE_RESOURCE_CODE_START + index
                for index, name in enumerate(
                    V3_LEGACY_SOURCE_RESOURCE_NAMES
                )
            )
            and all(
                SOURCE_RESOURCE_CODES[name]
                == V4_SOURCE_RESOURCE_CODE_START + index
                for index, name in enumerate(
                    V4_LEGACY_SOURCE_RESOURCE_NAMES
                )
            )
            and len(SOURCE_RESOURCE_CODES.values())
            == len(set(SOURCE_RESOURCE_CODES.values()))
            and all(
                resource["code"]
                == SOURCE_RESOURCE_CODES[resource["name"]]
                for resource in CIVILIZATION_TECH_RESOURCES
            )
        ),
        "resource_source_coverage_exact": (
            {
                resource["candidate_code"]
                for resource in CIVILIZATION_TECH_RESOURCES
            }
            == set(range(len(BODY_BANK)))
        ),
        "resource_pool_map_exact": all(
            resource["remaining_field"]
            in {
                "matter_remaining",
                "crystal_remaining",
                "gas_remaining",
                "energy_remaining",
            }
            for resource in CIVILIZATION_TECH_RESOURCES
        ),
        "resource_actions_all_pass": all(
            detail["status"] == "pass"
            for detail in resource_details.values()
        ),
        "composite_resource_schema_exact": SCHEMAS[COMPOSITE_RESOURCE]
        == [
            ("schema_version", "Int"),
            ("mechanics_version", "Int"),
            ("universe_version", "Int"),
            ("resource_type", "Int"),
            ("sector_x", "Int"),
            ("sector_y", "Int"),
            ("sector_z", "Int"),
            ("origin_epoch", "Int"),
            ("child_1_remaining", "Int"),
            ("child_2_remaining", "Int"),
            ("child_3_remaining", "Int"),
            ("key", "Raw"),
            ("stable_identifier", "Raw"),
        ],
        "composite_parent_count_exact": (
            len(
                {
                    resource["name"]
                    for resource in CIVILIZATION_TECH_RESOURCES
                    if resource["composite"]
                }
            )
            == len(_REFINEMENT_GROUP_ROWS)
        ),
        "composite_source_route_count_exact": (
            all(
                len(resource["child_allocations"]) == 3
                for resource in CIVILIZATION_TECH_RESOURCES
                if resource["composite"]
            )
        ),
        "composite_allocations_conserved": all(
            sum(
                child["maximum_units"]
                for child in resource["child_allocations"]
            )
            == resource["maximum_units"]
            for resource in CIVILIZATION_TECH_RESOURCES
            if resource["composite"]
        ),
        "refinement_route_count_exact": (
            len(REFINEMENT_ROUTES) == 3 * len(_REFINEMENT_GROUP_ROWS)
        ),
        "refined_object_count_exact": (
            set(REFINED_RESOURCE_CODES)
            == {route["child_name"] for route in REFINEMENT_ROUTES}
        ),
        "refinement_core_all_pass": all(refinement_core_checks.values()),
        "refinement_actions_all_pass": all(
            detail["status"] == "pass"
            for detail in refinement_details.values()
        ),
        "civilization_type_explicit_selection_exact": [
            (
                civilization_type["code"],
                civilization_type["action"],
                civilization_type["selection_mode"],
                civilization_type["minimum_civilization_scan_serial"],
            )
            for civilization_type in CIVILIZATION_TYPES
        ]
        == [
            (
                1,
                "MaterializeCivilizationTypeI",
                EXPLICIT_SELECTION_MODE,
                64,
            ),
            (
                2,
                "MaterializeCivilizationTypeII",
                EXPLICIT_SELECTION_MODE,
                1_024,
            ),
            (
                3,
                "MaterializeCivilizationTypeIII",
                EXPLICIT_SELECTION_MODE,
                16_384,
            ),
        ],
        "civilization_milestones_are_monotone_permanent_unlocks": (
            [
                item["minimum_civilization_scan_serial"]
                for item in CIVILIZATION_TYPES
            ]
            == [64, 1_024, 16_384]
        ),
        "manual_civilization_advancement_absent": (
            "MaterializeCivilization" not in by_name
            and not any(
                name.startswith("AdvanceCivilizationToType")
                for name in by_name
            )
        ),
        "civilization_type_actions_all_pass": all(
            detail["status"] == "pass"
            for detail in civilization_type_details.values()
        ),
        "technology_skill_codes_exact": [
            skill["code"] for skill in TECHNOLOGY_SKILLS
        ]
        == list(range(1, 19)),
        "type_iii_resource_skill_coverage_exact": set(range(13, 19))
        <= {
            skill_code
            for skill_code in (
                [
                    resource["skill_code"]
                    for resource in CIVILIZATION_TECH_RESOURCES
                ]
                + [route["skill_code"] for route in REFINEMENT_ROUTES]
            )
            if skill_code is not None
        },
        "technology_skill_core_all_pass": all(
            technology_core_checks.values()
        ),
        "skill_actions_all_pass": all(
            detail["status"] == "pass"
            for detail in skill_details.values()
        ),
        "authorization_core_all_pass": all(
            authorization_core_checks.values()
        ),
        "large_ship_authorizations_all_pass": all(
            detail["status"] == "pass"
            for detail in authorization_details.values()
        ),
        "body_materializer_core_all_pass": all(scan_core_checks.values()),
        "body_materializers_all_pass": all(
            detail["status"] == "pass"
            for detail in materializer_details.values()
        ),
        "civilization_type_materializers_all_pass": all(
            detail["status"] == "pass"
            for detail in civilization_type_details.values()
        ),
        "use_technology_skill_pass": all(use_checks.values()),
    }
    return {
        "status": "pass" if all(top_checks.values()) else "fail",
        "checks": top_checks,
        "resource_actions": resource_details,
        "refinement_core": {
            "status": (
                "pass" if all(refinement_core_checks.values()) else "fail"
            ),
            "checks": refinement_core_checks,
        },
        "refinement_actions": refinement_details,
        "civilization_type_actions": civilization_type_details,
        "technology_skill_core": {
            "status": (
                "pass" if all(technology_core_checks.values()) else "fail"
            ),
            "checks": technology_core_checks,
        },
        "technology_skill_actions": skill_details,
        "large_ship_authorization_core": {
            "status": (
                "pass"
                if all(authorization_core_checks.values())
                else "fail"
            ),
            "checks": authorization_core_checks,
        },
        "large_ship_authorizations": authorization_details,
        "body_materializer_core": {
            "status": "pass" if all(scan_core_checks.values()) else "fail",
            "checks": scan_core_checks,
        },
        "body_materializers": materializer_details,
        "use_technology_skill": {
            "status": "pass" if all(use_checks.values()) else "fail",
            "checks": use_checks,
        },
    }


def civilization_selection_adversarial_self_check(
    actions: list[dict[str, Any]],
    plugin: str,
    bank: list[dict[str, Any]],
) -> dict[str, Any]:
    """Prove the Civilization milestone and Raw-lineage audit is active."""

    def replace_regex_exact(
        source: str,
        pattern: str,
        replacement: str,
    ) -> str:
        matches = re.findall(pattern, source, flags=re.DOTALL)
        if len(matches) != 1:
            raise ValueError(
                "civilization adversarial pattern must match exactly once: "
                f"{pattern!r}"
            )
        return re.sub(
            pattern,
            replacement,
            source,
            count=1,
            flags=re.DOTALL,
        )

    civilization_type = CIVILIZATION_TYPES[0]
    action_name = civilization_type["action"]
    minimum = civilization_type["minimum_civilization_scan_serial"]
    mutations = {
        "wrong_raw_lineage_source": replace_action_function(
            plugin,
            action_name,
            lambda source: replace_regex_exact(
                source,
                (
                    r"var_assign\(\s*source_life_signal_identifier\s*,\s*"
                    r"life_signal\.stable_identifier\s*\)\s*;"
                ),
                (
                    "var_assign(source_life_signal_identifier, "
                    "ship.ship_id);"
                ),
            ),
        ),
        "wrong_consumed_input_binding_field": replace_action_function(
            plugin,
            action_name,
            lambda source: replace_regex_exact(
                source,
                (
                    r"life_signal\.update\(\s*\"stable_identifier\"\s*,\s*"
                    r"source_life_signal_identifier\s*\)\s*;"
                ),
                (
                    'life_signal.update("key", '
                    "source_life_signal_identifier);"
                ),
            ),
        ),
        "weakened_civilization_milestone": replace_action_function(
            plugin,
            action_name,
            lambda source: replace_regex_exact(
                source,
                (
                    r"action\.st_gt\(\s*ship\.civilization_scan_serial\s*,\s*"
                    rf"{minimum - 1}\s*\)\s*;"
                ),
                (
                    "action.st_gt(ship.civilization_scan_serial, "
                    f"{minimum - 2});"
                ),
            ),
        ),
    }
    audits = {
        name: civilization_tech_audit(actions, mutant, bank)
        for name, mutant in mutations.items()
    }
    target_checks = {
        "wrong_raw_lineage_source": (
            not audits["wrong_raw_lineage_source"]
            ["civilization_type_actions"][action_name]["checks"]
            ["source_life_signal_identifier_raw_binding_exact"]
        ),
        "wrong_consumed_input_binding_field": (
            not audits["wrong_consumed_input_binding_field"]
            ["civilization_type_actions"][action_name]["checks"]
            ["source_life_signal_identifier_raw_binding_exact"]
        ),
        "weakened_civilization_milestone": (
            not audits["weakened_civilization_milestone"]
            ["civilization_type_actions"][action_name]["checks"]
            ["milestone_gate_exact"]
        ),
    }
    rejected = {
        name: (
            mutant != plugin
            and audits[name]["status"] == "fail"
            and target_checks[name]
        )
        for name, mutant in mutations.items()
    }
    return {
        "status": "pass" if all(rejected.values()) else "fail",
        "checks": rejected,
        "targeted_subcheck_failures": target_checks,
        "mutation_count": len(mutations),
        "all_mutations_are_single_exact_replacements": True,
        "action_under_test": action_name,
    }




def phase3_helper_canary_audit(
    plugin: str,
    bank: list[dict[str, Any]],
) -> dict[str, Any]:
    """Fail closed on the two released Phase 3 helper canary shapes."""
    detect_candidate = bank[0]
    survey_profile = SURVEY_PROFILES[0]
    category = celestial_category(detect_candidate)
    detect_name = (
        f"DetectCelestialSignal_{detect_candidate['code']:02d}_"
        f"{detect_candidate['slug']}"
    )
    survey_name = (
        f"SurveySector_{survey_profile['code']:02d}_"
        f"{survey_profile['slug']}"
    )
    detect_wrapper = action_function_source(plugin, detect_name)
    survey_wrapper = action_function_source(plugin, survey_name)
    detect_core = named_function_source(plugin, "detect_signal_core")
    survey_core = named_function_source(plugin, "prove_empty_survey_sector_core")
    detect_routes = {
        f"DetectCelestialSignal_{candidate['code']:02d}_{candidate['slug']}"
        for candidate in bank
        if rhai_call_arguments(
            action_function_source(
                plugin,
                f"DetectCelestialSignal_{candidate['code']:02d}_{candidate['slug']}",
            ),
            "detect_signal_core",
        )
    }
    survey_routes = {
        f"SurveySector_{profile['code']:02d}_{profile['slug']}"
        for profile in SURVEY_PROFILES
        if rhai_call_arguments(
            action_function_source(
                plugin,
                f"SurveySector_{profile['code']:02d}_{profile['slug']}",
            ),
            "prove_empty_survey_sector_core",
        )
    }
    expected_fields = [
        "sector_type",
        "survey_profile",
        *(category["remaining_field"] for category in CELESTIAL_CATEGORIES),
        *(category["serial_field"] for category in CELESTIAL_CATEGORIES),
    ]
    survey_zero_fields = [
        arguments[0].removeprefix("sector.")
        for arguments in rhai_call_arguments(survey_core, "action.st_sum")
        if len(arguments) == 3
        and arguments[0].startswith("sector.")
        and arguments[1:] == ["0", "0"]
    ]
    forbidden = (
        "action.output(", "action.input(", "action.mutate(", "subaction",
        "if ", "for ", "while ", "match ", "#{", ".call(",
    )
    all_detect_wrappers_exact = all(
        source_action_object_roles(
            action_function_source(
                plugin,
                f"DetectCelestialSignal_{candidate['code']:02d}_{candidate['slug']}",
            )
        ) == [("output", SHIP), ("output", SIGNAL), ("input", SHIP), ("mutate", SECTOR)]
        and rhai_call_arguments(
            action_function_source(
                plugin,
                f"DetectCelestialSignal_{candidate['code']:02d}_{candidate['slug']}",
            ),
            "detect_signal_core",
        ) == [[
            "action", "next_ship", "signal", "ship", "sector",
            str(celestial_category(candidate)["code"]), str(candidate["code"]),
            f'"{celestial_category(candidate)["remaining_field"]}"',
            f'"{celestial_category(candidate)["serial_field"]}"',
        ]]
        for candidate in bank
    )
    all_survey_wrappers_exact = all(
        source_action_object_roles(
            action_function_source(
                plugin, f"SurveySector_{profile['code']:02d}_{profile['slug']}"
            )
        ) == [("output", SHIP), ("input", SHIP), ("mutate", SECTOR)]
        and rhai_call_arguments(
            action_function_source(
                plugin, f"SurveySector_{profile['code']:02d}_{profile['slug']}"
            ),
            "prove_empty_survey_sector_core",
        ) == [["action", "sector"]]
        for profile in SURVEY_PROFILES
    )
    checks = {
        "helpers_present_once": (
            rhai_function_definition_count(plugin, "detect_signal_core") == 1
            and rhai_function_definition_count(
                plugin, "prove_empty_survey_sector_core"
            ) == 1
        ),
        "detect_core_arity_exact": (
            rhai_function_parameters(plugin, "detect_signal_core")
            == ["action", "next_ship", "signal", "ship", "sector",
                "category_code", "candidate_code", "remaining_field",
                "serial_field"]
        ),
        "survey_core_arity_exact": (
            rhai_function_parameters(plugin, "prove_empty_survey_sector_core")
            == ["action", "sector"]
        ),
        "helpers_declare_no_roles_or_control_flow": all(
            not source_action_object_roles(source)
            and all(token not in source for token in forbidden)
            for source in (detect_core, survey_core)
        ),
        "detect_wrapper_roles_call_and_literals_exact": (
            source_action_object_roles(detect_wrapper)
            == [("output", SHIP), ("output", SIGNAL), ("input", SHIP),
                ("mutate", SECTOR)]
            and detect_wrapper.count("detect_signal_core(") == 1
            and rhai_call_arguments(detect_wrapper, "detect_signal_core")
            == [["action", "next_ship", "signal", "ship", "sector",
                 str(category["code"]), str(detect_candidate["code"]),
                 f'"{category["remaining_field"]}"',
                 f'"{category["serial_field"]}"']]
        ),
        "all_phase3_wrappers_route_through_helpers": (
            detect_routes == {
                f"DetectCelestialSignal_{candidate['code']:02d}_{candidate['slug']}"
                for candidate in bank
            }
            and survey_routes == {
                f"SurveySector_{profile['code']:02d}_{profile['slug']}"
                for profile in SURVEY_PROFILES
            }
            and rhai_token_occurrences(plugin, "detect_signal_core(")
            == len(bank) + 1
            and rhai_token_occurrences(
                plugin, "prove_empty_survey_sector_core("
            )
            == len(SURVEY_PROFILES) + 1
        ),
        "all_wrapper_roles_and_literals_exact": (
            all_detect_wrappers_exact and all_survey_wrappers_exact
        ),
        "survey_wrapper_route_and_outside_work_exact": (
            source_action_object_roles(survey_wrapper)
            == [("output", SHIP), ("input", SHIP), ("mutate", SECTOR)]
            and survey_wrapper.count("survey_replacement_ship_core(") == 1
            and survey_wrapper.count("prove_empty_survey_sector_core(") == 1
            and survey_wrapper.count("sector.revision") == 2
        ),
        "survey_core_ordered_configured_zeros_exact": (
            len(expected_fields) == 24
            and survey_zero_fields == expected_fields
            and survey_core.count("action.st_sum(") == len(expected_fields)
            and not any(
                field == "revision"
                for field, _value in object_update_pairs(survey_core, "sector")
            )
        ),
        "detect_core_semantics_present": all(
            token in detect_core
            for token in (
                "finish_detect_replacement_ship_core(",
                "action.st_sum(sector.sector_type, 0, 1);",
                "action.st_gt(sector.survey_profile, 0);",
                "action.st_gt(sector[remaining_field], 0);",
                "sector.update(remaining_field, next_remaining);",
                "sector.update(serial_field, next_serial);",
            )
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "checks": checks,
        "detect_action": detect_name,
        "survey_action": survey_name,
    }


def phase4_vdf_work_tail_exact(
    source: str,
    iterations: int,
    target: str,
) -> bool:
    """Require the one approved literal VDF witness/update tail."""
    code = mask_rhai_noncode(source)
    vdf_positions = rhai_call_positions(source, "action.intro_vdf")
    update_positions = rhai_call_positions(source, f"{target}.update")
    return (
        bool(re.search(
            rf"var\s+work\s*=\s*action\.intro_vdf\(\s*{iterations}\s*,\s*"
            rf"{re.escape(target)}\s*\)\s*;",
            code,
        ))
        and rhai_call_arguments(source, "action.intro_vdf")
        == [[str(iterations), target]]
        and rhai_call_arguments(source, f"{target}.update")
        == [['"work"', "work"]]
        and len(vdf_positions) == len(update_positions) == 1
        and vdf_positions[0] < update_positions[0]
    )


def phase4_adapter_canary_audit(
    plugin: str,
    actions: list[dict[str, Any]],
    bank: list[dict[str, Any]],
) -> dict[str, Any]:
    """Fail closed on every active-profile Phase 4 resource adapter route."""
    specs = phase4_helper_specs()
    helpers = {name: (kind, iterations, representative) for name, kind, iterations, representative in specs}
    functions = rhai_function_sources(plugin)
    action_names = {action["name"] for action in actions}
    resource_by_action = {
        resource["action"]: resource for resource in CIVILIZATION_TECH_RESOURCES
    }
    route_by_action = {route["action"]: route for route in REFINEMENT_ROUTES}
    candidates = {candidate["code"]: candidate for candidate in bank}
    base_resources = {
        "ExtractMatter": (1, "matter_remaining"),
        "ExtractCrystal": (2, "crystal_remaining"),
        "ExtractGas": (3, "gas_remaining"),
        "ExtractEnergy": (4, "energy_remaining"),
    }
    parent_codes = {
        resource["name"]: resource["code"]
        for resource in CIVILIZATION_TECH_RESOURCES
    }
    forbidden = (
        "action.output(", "action.input(", "action.mutate(", "subaction",
        "if ", "for ", "while ", "match ", "#{", ".call(",
    )

    details: dict[str, dict[str, Any]] = {}
    for helper_name, (kind, iterations, representative) in helpers.items():
        wrapper = functions.get(representative, "")
        helper = functions.get(helper_name, "")
        expected_roles = (
            [("output", SHIP), ("output", RESOURCE), ("input", SHIP), ("mutate", BODY)]
            if kind in {"base", "body"}
            else [("output", SHIP), ("output", COMPOSITE_RESOURCE), ("input", SHIP), ("mutate", BODY)]
            if kind == "composite"
            else [("output", SHIP), ("output", RESOURCE), ("input", SHIP), ("mutate", COMPOSITE_RESOURCE)]
        )
        parameters = rhai_function_parameters(plugin, helper_name)
        expected_parameters = {
            "base": ["action", "next_ship", "resource", "ship", "body", "required_skill_type", "remaining_field", "resource_type", "extraction_amount", "rare_extraction_amount"],
            "body": ["action", "next_ship", "resource", "ship", "body", "candidate_code", "required_skill_type", "remaining_field", "resource_type", "extraction_amount", "rare_extraction_amount"],
            "composite": ["action", "next_ship", "composite_resource", "ship", "body", "candidate_code", "required_skill_type", "remaining_field", "composite_resource_type", "extraction_amount", "rare_extraction_amount", "child_1_amount", "child_2_amount", "child_3_amount"],
            "refine": ["action", "next_ship", "resource", "ship", "parent", "required_skill_type", "parent_resource_type", "child_remaining_field", "output_resource_type"],
        }[kind]
        call_arguments = rhai_call_arguments(wrapper, helper_name)
        expected_call: list[str] = []
        if kind == "base":
            resource_type, remaining_field = base_resources[representative]
            tier = SHIP_TIERS[0]
            expected_call = ["action", "next_ship", "resource", "ship", "body", "0", f'"{remaining_field}"', str(resource_type), str(tier["extraction_amount"]), str(tier["rare_extraction_amount"])]
        elif kind in {"body", "composite"}:
            resource = resource_by_action[representative]
            candidate = candidates[resource["candidate_code"]]
            tier = SHIP_TIERS[resource["minimum_ship_tier"]]
            output_handle = "composite_resource" if kind == "composite" else "resource"
            expected_call = ["action", "next_ship", output_handle, "ship", "body", str(candidate["code"]), str(resource["skill_code"] if resource["skill_code"] is not None else 0), f'"{resource["remaining_field"]}"', str(resource["code"]), str(tier["extraction_amount"]), str(tier["rare_extraction_amount"])]
            if kind == "composite":
                child_amounts = composite_child_amounts(resource["child_allocations"], tier["extraction_amount"], route_name=representative, ship_tier_name=tier["name"])
                expected_call.extend(str(amount) for amount in child_amounts)
        else:
            route = route_by_action[representative]
            expected_call = ["action", "next_ship", "resource", "ship", "parent", str(route["skill_code"]), str(parent_codes[route["parent_name"]]), f'"child_{route["child_slot"]}_remaining"', str(route["resource_code"])]
        target = "parent" if kind == "refine" else "body"
        checks = {
            "helper_present_once": rhai_function_definition_count(
                plugin, helper_name
            ) == 1,
            "arity_exact": parameters == expected_parameters,
            "helper_straight_line": (
                bool(helper)
                and not source_action_object_roles(helper)
                and all(token not in helper for token in forbidden)
            ),
            "wrapper_is_member_with_direct_roles": (
                representative in action_names
                and source_action_object_roles(wrapper) == expected_roles
            ),
            "one_adapter_call_with_literals": call_arguments == [expected_call],
            "vdf_owner_and_literal_exact": (
                phase4_vdf_work_tail_exact(helper, iterations, target)
                and "intro_vdf" not in wrapper
                if iterations is not None
                else "intro_vdf" not in helper + wrapper and '"work"' not in helper
            ),
            "core_route_exact": (
                ("extract_composite_resource_core(" in helper if kind == "composite" else "refine_resource_core(" in helper if kind == "refine" else "extract_direct_resource_core(" in helper)
            ),
        }
        details[helper_name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "representative": representative,
            "kind": kind,
            "iterations": iterations,
            "checks": checks,
        }
    helper_names = set(helpers)
    tier_by_name = {tier["name"]: tier for tier in SHIP_TIERS}

    def expected_route(
        action: dict[str, Any],
    ) -> tuple[str, list[str]] | None:
        kind = phase4_kind_for_action(action)
        if kind is None:
            return None
        vdf = action["intro_contract"]["vdf"]
        iterations = vdf["iterations"] if vdf is not None else None
        helper_name = phase4_helper_for(action["name"], kind, iterations)
        if helper_name is None:
            return None
        if kind == "base":
            resource_type, remaining_field = base_resources[
                action["base_extraction_action"]
            ]
            tier = tier_by_name[action["extraction_ship_tier"]]
            return helper_name, [
                "action", "next_ship", "resource", "ship", "body", "0",
                f'"{remaining_field}"', str(resource_type),
                str(tier["extraction_amount"]),
                str(tier["rare_extraction_amount"]),
            ]
        if kind in {"body", "composite"}:
            resource = resource_by_action[action["base_extraction_action"]]
            candidate = candidates[resource["candidate_code"]]
            tier = tier_by_name[action["extraction_ship_tier"]]
            output_handle = (
                "composite_resource" if kind == "composite" else "resource"
            )
            arguments = [
                "action", "next_ship", output_handle, "ship", "body",
                str(candidate["code"]),
                str(resource["skill_code"] if resource["skill_code"] is not None else 0),
                f'"{resource["remaining_field"]}"', str(resource["code"]),
                str(tier["extraction_amount"]),
                str(tier["rare_extraction_amount"]),
            ]
            if kind == "composite":
                arguments.extend(
                    str(amount)
                    for amount in composite_child_amounts(
                        resource["child_allocations"],
                        tier["extraction_amount"],
                        route_name=action["name"],
                        ship_tier_name=tier["name"],
                    )
                )
            return helper_name, arguments
        route = route_by_action[action["name"]]
        return helper_name, [
            "action", "next_ship", "resource", "ship", "parent",
            str(route["skill_code"]), str(parent_codes[route["parent_name"]]),
            f'"child_{route["child_slot"]}_remaining"',
            str(route["resource_code"]),
        ]

    expected_routes = {
        action["name"]: route
        for action in actions
        if (route := expected_route(action)) is not None
    }
    extraction_refinement_wrappers = {
        action["name"]
        for action in actions
        if phase4_kind_for_action(action) is not None
    }
    routed = {
        action_name: [
            name for name in helper_names
            if rhai_call_arguments(functions.get(action_name, ""), name)
        ]
        for action_name in extraction_refinement_wrappers
    }
    route_details = {
        action_name: {
            "helper": helper_name,
            "calls_exact": (
                rhai_call_arguments(functions.get(action_name, ""), helper_name)
                == [arguments]
            ),
            "sole_adapter": routed[action_name] == [helper_name],
        }
        for action_name, (helper_name, arguments) in expected_routes.items()
    }
    routing_exact = (
        len(expected_routes) == 687
        and all(
            detail["calls_exact"] and detail["sole_adapter"]
            for detail in route_details.values()
        )
        and all(
            not route for action_name, route in routed.items()
            if action_name not in expected_routes
        )
        and set(helper_name for helper_name, _arguments in expected_routes.values())
        == helper_names
    )
    checks = {
        "active_inventory_exact": (
            set(functions) & {
                name
                for name, _kind, _iterations, _representative
                in (*PHASE4_ECONOMY_HELPERS, *PHASE4_CURRENT_HELPERS)
            }
            == helper_names
            and len(helper_names)
            == (20 if ACTIVE_VDF_PROFILE == "economy" else 6)
        ),
        "representatives_exact": all(row["status"] == "pass" for row in details.values()),
        "all_resource_refinement_routes_exact": routing_exact,
        "zero_witness_collisions": all(
            "unsafe" not in functions[name]
            and "action.random(" not in functions[name]
            for name in helper_names
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "profile": ACTIVE_VDF_PROFILE,
        "helpers": details,
        "route_details": route_details,
        "routes": routed,
        "checks": checks,
    }


def phase5_adapter_canary_audit(
    plugin: str,
    actions: list[dict[str, Any]],
    *,
    include_semantic_closure: bool = True,
    include_witness_scope: bool = True,
) -> dict[str, Any]:
    """Fail closed on every fixed Phase 5 recipe-topology route."""
    code = mask_rhai_noncode(plugin)
    functions = rhai_function_sources(plugin)
    action_names = {action["name"] for action in actions}
    component_by_action = {
        action_name: (component, mode)
        for component in COMPONENT_RECIPES
        for mode, action_name in component["actions"].items()
    }
    skill_by_action = {skill["action"]: skill for skill in DERIVED_SKILLS}
    artifact_by_action = {
        capability["action"]: capability for capability in SKILL_CAPABILITIES
    }
    phase5_family_actions = {
        *component_by_action,
        *skill_by_action,
        *artifact_by_action,
    }
    component_parameters = [
        "action", "next_ship", "component", "ship", "material_1",
        "material_2", "material_3", "catalyst", "skill_type",
        "material_1_type", "material_1_amount", "material_2_type",
        "material_2_amount", "material_3_type", "material_3_amount",
        "catalyst_type", "component_type", "component_amount",
    ]
    forbidden = (
        "action.output(", "action.input(", "action.mutate(", "subaction",
        "if ", "for ", "while ", "match ", "#{", ".call(",
    )

    def helper_call_order(source: str) -> list[str]:
        return [
            name
            for name, _arguments, _position in rhai_plain_statement_calls(source)
            if name in {
                "fabricate_component_core",
                "consume_component_catalyst_reusable_core",
                "consume_component_catalyst_final_core",
                "develop_derived_skill_core",
                "produce_capability_artifact_core",
                "prove_resource_stack_core",
            }
        ]

    details: dict[str, dict[str, Any]] = {}
    for helper_name, family, shape, iterations, representative in PHASE5_ADAPTER_HELPERS:
        wrapper = functions.get(representative, "")
        helper = functions.get(helper_name, "")
        parameters = rhai_function_parameters(code, helper_name)
        call_arguments = rhai_call_arguments(wrapper, helper_name)
        expected_call: list[str]
        expected_roles: list[tuple[str, str]]
        target: str
        if family == "component":
            component, mode = component_by_action[representative]
            materials = component["materials"]
            expected_parameters = component_parameters
            expected_call = [
                "action", "n", "c", "s", "a", "b", "d", "k",
                str(component["skill_code"]),
                str(materials[0]["resource_code"]), str(materials[0]["amount"]),
                str(materials[1]["resource_code"]), str(materials[1]["amount"]),
                str(materials[2]["resource_code"]), str(materials[2]["amount"]),
                str(component["catalyst"]["resource_code"]),
                str(component["code"]), str(component["output_amount"]),
            ]
            expected_roles = [
                ("output", SHIP), ("output", RESOURCE), ("input", SHIP),
                ("input", RESOURCE), ("input", RESOURCE),
                ("input", RESOURCE),
                ("input" if mode == "final" else "mutate", RESOURCE),
            ]
            target = "component"
            catalyst_helper = (
                "consume_component_catalyst_final_core"
                if mode == "final"
                else "consume_component_catalyst_reusable_core"
            )
            expected_core_arguments = [
                "action", "next_ship", "component", "ship", "material_1",
                "material_2", "material_3", "catalyst", "skill_type",
                "material_1_type", "material_1_amount", "material_2_type",
                "material_2_amount", "material_3_type", "material_3_amount",
                "catalyst_type", "component_type", "component_amount",
            ]
            core_and_evidence_exact = (
                rhai_call_arguments(helper, "fabricate_component_core")
                == [expected_core_arguments]
                and rhai_call_arguments(helper, catalyst_helper)
                == [["action", "catalyst"]]
                and not rhai_call_arguments(
                    helper,
                    "consume_component_catalyst_final_core"
                    if catalyst_helper
                    == "consume_component_catalyst_reusable_core"
                    else "consume_component_catalyst_reusable_core",
                )
                and helper_call_order(helper)
                == ["fabricate_component_core", catalyst_helper]
            )
            wrapper_legacy_calls = (
                "fabricate_component_core(",
                "consume_component_catalyst_reusable_core(",
                "consume_component_catalyst_final_core(",
                "prove_resource_stack_core(",
            )
        elif family == "derived":
            skill = skill_by_action[representative]
            items = skill["items"]
            evidence_count = int(shape)
            expected_parameters = [
                "action", "next_ship", "technology_skill", "ship",
                *(f"evidence_{index}" for index in range(1, evidence_count + 1)),
                "parent_skill_type", "output_skill_type",
                *(
                    value
                    for index in range(1, evidence_count + 1)
                    for value in (
                        f"evidence_{index}_type", f"evidence_{index}_amount"
                    )
                ),
            ]
            expected_call = [
                "action", "next_ship", "technology_skill", "ship",
                *(f"evidence_{item['slot']}" for item in items),
                str(skill["parent_code"]), str(skill["code"]),
                *(
                    str(value)
                    for item in items
                    for value in (item["resource_code"], item["amount"])
                ),
            ]
            expected_roles = [
                ("output", SHIP), ("output", TECHNOLOGY_SKILL),
                ("input", SHIP), *[("input", RESOURCE) for _item in items],
            ]
            target = "technology_skill"
            expected_core_arguments = [
                "action", "next_ship", "technology_skill", "ship",
                "parent_skill_type", "output_skill_type",
            ]
            expected_evidence_arguments = [
                [
                    "action", f"evidence_{index}",
                    f"evidence_{index}_type", f"evidence_{index}_amount",
                ]
                for index in range(1, evidence_count + 1)
            ]
            core_and_evidence_exact = (
                rhai_call_arguments(helper, "develop_derived_skill_core")
                == [expected_core_arguments]
                and rhai_call_arguments(helper, "prove_resource_stack_core")
                == expected_evidence_arguments
                and helper_call_order(helper)
                == [
                    "develop_derived_skill_core",
                    *["prove_resource_stack_core"] * evidence_count,
                ]
            )
            wrapper_legacy_calls = (
                "develop_derived_skill_core(",
                "prove_resource_stack_core(",
            )
        else:
            capability = artifact_by_action[representative]
            items = capability["fixed_inputs"]
            evidence_count = int(shape)
            expected_parameters = [
                "action", "next_ship", "artifact", "ship",
                *(f"evidence_{index}" for index in range(1, evidence_count + 1)),
                "required_skill_type", "output_resource_type", "output_amount",
                *(
                    value
                    for index in range(1, evidence_count + 1)
                    for value in (
                        f"evidence_{index}_type", f"evidence_{index}_amount"
                    )
                ),
            ]
            expected_call = [
                "action", "next_ship", "artifact", "ship",
                *(f"evidence_{index}" for index in range(1, evidence_count + 1)),
                str(capability["skill_code"]),
                str(capability["output_resource_code"]),
                str(capability["output_amount"]),
                *(
                    str(value)
                    for item in items
                    for value in (item["resource_code"], item["amount"])
                ),
            ]
            expected_roles = [
                ("output", SHIP), ("output", RESOURCE), ("input", SHIP),
                *[("input", RESOURCE) for _item in items],
            ]
            target = "artifact"
            expected_core_arguments = [
                "action", "next_ship", "artifact", "ship",
                "required_skill_type", "output_resource_type", "output_amount",
            ]
            expected_evidence_arguments = [
                [
                    "action", f"evidence_{index}",
                    f"evidence_{index}_type", f"evidence_{index}_amount",
                ]
                for index in range(1, evidence_count + 1)
            ]
            core_and_evidence_exact = (
                rhai_call_arguments(helper, "produce_capability_artifact_core")
                == [expected_core_arguments]
                and rhai_call_arguments(helper, "prove_resource_stack_core")
                == expected_evidence_arguments
                and helper_call_order(helper)
                == [
                    "produce_capability_artifact_core",
                    *["prove_resource_stack_core"] * evidence_count,
                ]
            )
            wrapper_legacy_calls = (
                "produce_capability_artifact_core(",
                "prove_resource_stack_core(",
            )
        relevant_calls = helper_call_order(helper)
        relevant_positions = [
            position
            for name in set(relevant_calls)
            for position in rhai_call_positions(helper, name)
        ]
        work_match = re.search(
            r"\bvar\s+work\s*=", mask_rhai_noncode(helper)
        )
        work_tail_after_core = (
            bool(relevant_positions)
            and work_match is not None
            and max(relevant_positions) < work_match.start()
        )
        role_positions = sorted(
            position
            for mode in ("output", "input", "mutate")
            for position in rhai_call_positions(wrapper, f"action.{mode}")
        )
        adapter_positions = rhai_call_positions(wrapper, helper_name)
        adapter_start = adapter_positions[0] if adapter_positions else -1
        checks = {
            "helper_present_once": (
                rhai_function_definition_count(plugin, helper_name) == 1
            ),
            "arity_exact": parameters == expected_parameters,
            "helper_straight_line_role_free": (
                bool(helper)
                and not source_action_object_roles(helper)
                and all(token not in helper for token in forbidden)
            ),
            "wrapper_direct_roles_exact": (
                representative in action_names
                and source_action_object_roles(wrapper) == expected_roles
            ),
            "one_adapter_call_with_exact_literals": call_arguments == [expected_call],
            "wrapper_roles_precede_final_adapter": (
                bool(role_positions)
                and adapter_start > role_positions[-1]
                and rhai_terminal_statement_call(wrapper, helper_name)
            ),
            "wrapper_contains_no_legacy_recipe_or_vdf": (
                "intro_vdf" not in wrapper
                and all(token not in wrapper for token in wrapper_legacy_calls)
            ),
            "wrapper_contains_no_extra_proof_work": not any(
                token in wrapper
                for token in (
                    "action.st_sum(", "action.st_gt(", "unsafe {",
                    "action.random(", "var_assign(", "rotate_key(",
                    "action.intro_vdf(", "action.intro_lt_eq_u256(",
                )
            ),
            "core_and_evidence_order_exact": (
                core_and_evidence_exact and work_tail_after_core
            ),
            "literal_vdf_tail_exact": phase4_vdf_work_tail_exact(
                helper, iterations, target
            ) and "intro_vdf" not in wrapper,
        }
        details[helper_name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "representative": representative,
            "family": family,
            "shape": shape,
            "iterations": iterations,
            "checks": checks,
        }
    helper_names = {spec[0] for spec in PHASE5_ADAPTER_HELPERS}
    phase5_like_helpers = {
        name
        for name in functions
        if re.fullmatch(
            r"(?:fabricate_component|develop_derived_skill|"
            r"produce_capability_artifact)_(?:reusable|final|[1-3]_evidence)"
            r"_vdf_[0-9]+_core",
            name,
        )
    }

    def expected_route(
        action_name: str,
    ) -> tuple[str, list[str], list[tuple[str, str]], tuple[str, ...], int]:
        helper_name = phase5_helper_for(action_name)
        if helper_name is None:
            raise ValueError(f"missing Phase 5 route for {action_name}")
        if action_name in component_by_action:
            component, mode = component_by_action[action_name]
            materials = component["materials"]
            arguments = [
                "action", "n", "c", "s", "a", "b", "d", "k",
                str(component["skill_code"]),
                str(materials[0]["resource_code"]), str(materials[0]["amount"]),
                str(materials[1]["resource_code"]), str(materials[1]["amount"]),
                str(materials[2]["resource_code"]), str(materials[2]["amount"]),
                str(component["catalyst"]["resource_code"]),
                str(component["code"]), str(component["output_amount"]),
            ]
            roles = [
                ("output", SHIP), ("output", RESOURCE), ("input", SHIP),
                ("input", RESOURCE), ("input", RESOURCE), ("input", RESOURCE),
                ("input" if mode == "final" else "mutate", RESOURCE),
            ]
            legacy = (
                "fabricate_component_core(",
                "consume_component_catalyst_reusable_core(",
                "consume_component_catalyst_final_core(",
                "prove_resource_stack_core(",
            )
            return helper_name, arguments, roles, legacy, component["vdf_iterations"]
        if action_name in skill_by_action:
            skill = skill_by_action[action_name]
            arguments = [
                "action", "next_ship", "technology_skill", "ship",
                *(f"evidence_{item['slot']}" for item in skill["items"]),
                str(skill["parent_code"]), str(skill["code"]),
                *(
                    str(value)
                    for item in skill["items"]
                    for value in (item["resource_code"], item["amount"])
                ),
            ]
            roles = [
                ("output", SHIP), ("output", TECHNOLOGY_SKILL),
                ("input", SHIP),
                *[("input", RESOURCE) for _item in skill["items"]],
            ]
            return (
                helper_name, arguments, roles,
                ("develop_derived_skill_core(", "prove_resource_stack_core("),
                skill["vdf_iterations"],
            )
        capability = artifact_by_action[action_name]
        arguments = [
            "action", "next_ship", "artifact", "ship",
            *(
                f"evidence_{index}"
                for index in range(1, len(capability["fixed_inputs"]) + 1)
            ),
            str(capability["skill_code"]),
            str(capability["output_resource_code"]),
            str(capability["output_amount"]),
            *(
                str(value)
                for item in capability["fixed_inputs"]
                for value in (item["resource_code"], item["amount"])
            ),
        ]
        roles = [
            ("output", SHIP), ("output", RESOURCE), ("input", SHIP),
            *[("input", RESOURCE) for _item in capability["fixed_inputs"]],
        ]
        return (
            helper_name, arguments, roles,
            ("produce_capability_artifact_core(", "prove_resource_stack_core("),
            capability["vdf_iterations"],
        )

    expected_routes = {
        action_name: expected_route(action_name)
        for action_name in phase5_family_actions
    }
    routed = {
        action_name: [
            helper_name
            for helper_name in helper_names
            if rhai_call_arguments(functions.get(action_name, ""), helper_name)
        ]
        for action_name in action_names
    }
    helper_callers = {
        helper_name: [
            action_name
            for action_name in sorted(action_names)
            if rhai_call_arguments(functions.get(action_name, ""), helper_name)
        ]
        for helper_name in helper_names
    }
    route_details: dict[str, dict[str, Any]] = {}
    for action_name, (
        helper_name, expected_arguments, expected_roles, legacy_calls, _iterations
    ) in expected_routes.items():
        wrapper = functions.get(action_name, "")
        role_positions = sorted(
            position
            for mode in ("output", "input", "mutate")
            for position in rhai_call_positions(wrapper, f"action.{mode}")
        )
        adapter_positions = rhai_call_positions(wrapper, helper_name)
        adapter_start = adapter_positions[0] if adapter_positions else -1
        checks = {
            "direct_roles_exact": source_action_object_roles(wrapper) == expected_roles,
            "one_exact_adapter_call": (
                rhai_call_arguments(wrapper, helper_name) == [expected_arguments]
                and routed[action_name] == [helper_name]
            ),
            "roles_precede_final_adapter": (
                bool(role_positions)
                and adapter_start > role_positions[-1]
                and rhai_terminal_statement_call(wrapper, helper_name)
            ),
            "legacy_recipe_and_vdf_absent": (
                "intro_vdf" not in wrapper
                and 'update("work"' not in wrapper
                and all(token not in wrapper for token in legacy_calls)
            ),
            "extra_proof_work_absent": not any(
                token in wrapper
                for token in (
                    "action.st_sum(", "action.st_gt(", "unsafe {",
                    "action.random(", "var_assign(", "rotate_key(",
                    "action.intro_vdf(", "action.intro_lt_eq_u256(",
                )
            ),
        }
        route_details[action_name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "helper": helper_name,
            "checks": checks,
        }
    helper_distribution = Counter(
        helper_name
        for helper_name, _arguments, _roles, _legacy, _iterations
        in expected_routes.values()
    )
    cost_distribution = Counter(
        iterations
        for _helper, _arguments, _roles, _legacy, iterations
        in expected_routes.values()
    )
    physical = physical_proof_counts(plugin)
    expected_physical = (
        (
            REFACTOR_PHASE6_CANARY_ECONOMY_PHYSICAL
            if PHASE6_MOVEMENT_CANARIES_ENABLED
            else REFACTOR_PHASE5_ECONOMY_PHYSICAL
        )
        if ACTIVE_VDF_PROFILE == "economy"
        else REFACTOR_CURRENT_PHASE5_PHYSICAL
    )
    semantic_closure_exact = True
    if include_semantic_closure:
        global PHASE5_ADAPTER_CANARIES_ENABLED
        previous = PHASE5_ADAPTER_CANARIES_ENABLED
        PHASE5_ADAPTER_CANARIES_ENABLED = False
        try:
            baseline_plugin = render_plugin(actions, sources_for_bank(BODY_BANK))
        finally:
            PHASE5_ADAPTER_CANARIES_ENABLED = previous
        baseline_functions = rhai_function_sources(baseline_plugin)

        def normalized_closure(census: dict[str, Any]) -> list[tuple[str, str, str]]:
            return [
                (
                    row["target"],
                    row["method"],
                    '"work",<vdf>'
                    if row["method"] == "update"
                    and row["expression"].startswith('"work",')
                    else row["expression"],
                )
                for row in census["output_transforms"]
            ]

        for action_name in phase5_family_actions:
            current = transitive_action_census(action_name, functions)
            baseline = transitive_action_census(action_name, baseline_functions)
            current_closure = normalized_closure(current)
            baseline_closure = normalized_closure(baseline)
            if current["counts"] != baseline["counts"] or current_closure != baseline_closure:
                semantic_closure_exact = False
                break
    checks = {
        "inventory_exact": (
            phase5_like_helpers == helper_names and len(helper_names) == 20
        ),
        "representatives_exact": all(
            detail["status"] == "pass" for detail in details.values()
        ),
        "all_234_routes_exact": (
            len(route_details) == 234
            and all(
                detail["status"] == "pass"
                for detail in route_details.values()
            )
        ),
        "no_orphan_or_unknown_helper": all(
            helper_callers[helper_name]
            == sorted(
                action_name
                for action_name, route in expected_routes.items()
                if route[0] == helper_name
            )
            and rhai_token_occurrences(code, f"{helper_name}(")
            == PHASE5_BULK_HELPER_DISTRIBUTION[helper_name] + 1
            for helper_name in helper_names
        ),
        "all_non_recipe_wrappers_have_no_phase5_call": all(
            not routed[action_name]
            for action_name in action_names - phase5_family_actions
        ),
        "helper_distribution_exact": (
            dict(helper_distribution) == PHASE5_BULK_HELPER_DISTRIBUTION
        ),
        "cost_distribution_exact": (
            dict(cost_distribution) == PHASE5_BULK_COST_DISTRIBUTION
        ),
        "physical_ownership_ledger_exact": physical == expected_physical,
        "flattened_witness_scope_exact": (
            not include_witness_scope
            or flattened_witness_scope_audit(code, actions)["status"] == "pass"
        ),
        "semantic_closure_exact": semantic_closure_exact,
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "helpers": details,
        "routes": routed,
        "route_details": route_details,
        "helper_callers": helper_callers,
        "helper_distribution": dict(sorted(helper_distribution.items())),
        "cost_distribution": dict(sorted(cost_distribution.items())),
        "physical_ownership": physical,
        "phase5_like_helpers": sorted(phase5_like_helpers),
        "checks": checks,
    }


def phase5_wrapper_semantic_source(plugin: str, action_name: str) -> str:
    """Join one Phase 5 wrapper to its role-free adapter for audits."""
    helper_name = phase5_helper_for(action_name)
    wrapper = action_function_source(plugin, action_name)
    return (
        wrapper + named_function_source(plugin, helper_name)
        if helper_name is not None
        else wrapper
    )


def phase6_movement_canary_audit(
    plugin: str,
    actions: list[dict[str, Any]],
    *,
    include_semantic_closure: bool = True,
    include_witness_scope: bool = True,
    include_intro_audit: bool = True,
) -> dict[str, Any]:
    """Fail closed on all economy-only Phase 6 movement helper routes."""
    global PHASE6_MOVEMENT_CANARIES_ENABLED

    code = mask_rhai_noncode(plugin)
    functions = rhai_function_sources(plugin)
    action_names = {action["name"] for action in actions}
    expected_routes = (
        PHASE6_MOVEMENT_CANARY_ROUTES
        if ACTIVE_VDF_PROFILE == "economy" and PHASE6_MOVEMENT_CANARIES_ENABLED
        else {}
    )
    expected_helpers = {
        helper
        for route in expected_routes.values()
        for helper in route
    }
    phase6_like_helpers = {
        name
        for name in functions
        if re.fullmatch(
            r"(?:move_(?:positive|negative)|advance_ship_epoch|"
            r"update_ship_work_vdf_[0-9]+)_core",
            name,
        )
    }
    forbidden = (
        "action.output(", "action.input(", "action.mutate(", "subaction",
        "if ", "for ", "while ", "match ", "#{", ".call(",
    )
    movement_parameters = [
        "action", "ship", "current_coordinate", "coordinate_field", "step",
        "extraction_amount", "rare_extraction_amount",
    ]
    helper_checks: dict[str, dict[str, bool]] = {}
    for helper_name in expected_helpers:
        helper = functions.get(helper_name, "")
        compact = re.sub(r"\s+", "", mask_rhai_noncode(helper))
        if helper_name in {"move_positive_core", "move_negative_core"}:
            arithmetic = (
                "current_coordinate-(0-step)"
                if helper_name == "move_positive_core"
                else "current_coordinate-step"
            )
            sum_arguments = (
                ["current_coordinate", "step", "next_coordinate"]
                if helper_name == "move_positive_core"
                else ["next_coordinate", "step", "current_coordinate"]
            )
            checks = {
                "parameters_exact": rhai_function_parameters(code, helper_name)
                == movement_parameters,
                "movement_body_exact": (
                    rhai_call_arguments(helper, "action.st_sum")
                    == [
                        ["ship.extraction_amount", "0", "extraction_amount"],
                        ["ship.rare_extraction_amount", "0", "rare_extraction_amount"],
                        sum_arguments,
                        ["ship.action_serial", "1", "next_action_serial"],
                    ]
                    and rhai_call_arguments(helper, "action.st_gt")
                    == [
                        ["next_coordinate", "0"],
                        [str(COORD_UPPER_BOUND), "next_coordinate"],
                    ]
                    and f"varnext_coordinate=unsafe{{{arithmetic}}};" in compact
                    and "varnext_action_serial=unsafe{ship.action_serial-(0-1)};" in compact
                    and "ship.update(coordinate_field,next_coordinate);" in compact
                    and rhai_call_arguments(helper, "ship.update") == [
                        ["coordinate_field", "next_coordinate"],
                        ['"active_skill_type"', "0"],
                        ['"action_serial"', "next_action_serial"],
                    ]
                    and "varnext_ship_key=action.random();rotate_key(ship,next_ship_key);" in compact
                ),
            }
        elif helper_name.startswith("update_ship_work_vdf_"):
            iterations = int(helper_name.removeprefix("update_ship_work_vdf_").removesuffix("_core"))
            checks = {
                "parameters_exact": rhai_function_parameters(code, helper_name)
                == ["action", "ship"],
                "literal_vdf_tail_exact": phase4_vdf_work_tail_exact(
                    helper, iterations, "ship"
                ) and len(rhai_call_arguments(helper, "ship.update")) == 1,
            }
        else:
            checks = {
                "parameters_exact": rhai_function_parameters(code, helper_name)
                == ["action", "ship", "next_epoch"],
                "epoch_body_exact": (
                    rhai_call_arguments(helper, "action.st_sum")
                    == [
                        ["ship.action_serial", "1", "next_action_serial"],
                    ]
                    and rhai_call_arguments(helper, "action.st_gt")
                    == [[str(EPOCH_UPPER_BOUND), "next_epoch"]]
                    and "varnext_action_serial=unsafe{ship.action_serial-(0-1)};" in compact
                    and rhai_call_arguments(helper, "ship.update") == [
                        ['"epoch"', "next_epoch"],
                        ['"active_skill_type"', "0"],
                        ['"action_serial"', "next_action_serial"],
                    ]
                    and "varnext_ship_key=action.random();rotate_key(ship,next_ship_key);" in compact
                ),
            }
        checks["role_free_straight_line"] = (
            bool(helper)
            and not source_action_object_roles(helper)
            and all(token not in helper for token in forbidden)
        )
        helper_checks[helper_name] = checks

    route_arguments: dict[str, list[list[str]]] = {}
    movement_tiers: dict[str, dict[str, Any]] = {}
    for action_name, axis, _positive, tier in movement_variants():
        if tier is None:
            continue
        axis_field = axis.lower()
        movement_tiers[action_name] = tier
        route_arguments[action_name] = [
            [
                "action", "ship", f"ship.{axis_field}",
                f'"{axis_field}"', str(tier["move"]),
                str(tier["extraction_amount"]),
                str(tier["rare_extraction_amount"]),
            ],
            ["action", "ship"],
        ]
    timewarp_tiers = {
        f"TimeWarp{tier['name']}": tier for tier in SHIP_TIERS
    }
    route_arguments.update({
        action_name: [
            ["action", "ship", "next_epoch"],
            ["action", "ship"],
        ]
        for action_name in timewarp_tiers
    })
    route_details: dict[str, dict[str, bool]] = {}
    for action_name, route in expected_routes.items():
        wrapper = functions.get(action_name, "")
        role_positions = sorted(
            position
            for mode in ("output", "input", "mutate")
            for position in rhai_call_positions(wrapper, f"action.{mode}")
        )
        helper_calls = [
            rhai_call_arguments(wrapper, helper_name) for helper_name in route
        ]
        call_positions = [
            rhai_call_positions(wrapper, helper_name) for helper_name in route
        ]
        starts = [positions[0] if positions else -1 for positions in call_positions]
        route_details[action_name] = {
            "direct_role_exact": source_action_object_roles(wrapper) == [("mutate", SHIP)],
            "each_helper_once_with_fixed_literals": (
                helper_calls == [[arguments] for arguments in route_arguments[action_name]]
            ),
            "roles_precede_helpers_in_order": (
                bool(role_positions)
                and all(start > role_positions[-1] for start in starts)
                and starts == sorted(starts)
            ),
            "movement_wrapper_has_no_legacy_work": (
                "intro_vdf" not in wrapper
                and 'update("work"' not in wrapper
                and (
                    action_name.startswith("TimeWarp")
                    or not any(token in wrapper for token in (
                        "action.st_sum(", "action.st_gt(", "unsafe {",
                        "action.random(", "rotate_key(",
                    ))
                )
            ),
            "timewarp_prefix_exact": (
                not action_name.startswith("TimeWarp")
                or (
                    rhai_call_arguments(wrapper, "action.st_sum")
                    == [
                        [
                            "ship.extraction_amount", "0",
                            str(timewarp_tiers[action_name]["extraction_amount"]),
                        ],
                        [
                            "ship.rare_extraction_amount", "0",
                            str(timewarp_tiers[action_name]["rare_extraction_amount"]),
                        ],
                        [
                            "ship.epoch",
                            str(timewarp_tiers[action_name]["timewarp"]),
                            "next_epoch",
                        ],
                    ]
                    and (
                        "varnext_epoch=unsafe{ship.epoch-(0-"
                        f"{timewarp_tiers[action_name]['timewarp']})}};"
                    )
                    in re.sub(r"\s+", "", mask_rhai_noncode(wrapper))
                    and "action.st_gt(" not in wrapper
                    and "action.random(" not in wrapper
                    and "rotate_key(" not in wrapper
                )
            ),
            "rewritten_wrapper_max_line_at_most_278": max(
                map(len, wrapper.splitlines()), default=0
            ) <= 278,
        }
    routed = {
        action_name: [
            helper_name for helper_name in PHASE6_MOVEMENT_HELPERS
            if rhai_call_arguments(source, helper_name)
        ]
        for action_name, source in functions.items()
        if action_name in action_names
    }
    helper_callers = {
        helper_name: sorted(
            action_name for action_name, calls in routed.items()
            if helper_name in calls
        )
        for helper_name in expected_helpers
    }
    route_distribution = Counter(
        helper_name
        for route in expected_routes.values()
        for helper_name in route
    )
    semantic_closure_exact = True
    logical_counts_exact = True
    output_closure_exact = True
    if include_semantic_closure and expected_routes:
        previous = PHASE6_MOVEMENT_CANARIES_ENABLED
        PHASE6_MOVEMENT_CANARIES_ENABLED = False
        try:
            baseline_plugin = render_plugin(actions, sources_for_bank(BODY_BANK))
        finally:
            PHASE6_MOVEMENT_CANARIES_ENABLED = previous
        baseline_functions = rhai_function_sources(baseline_plugin)
        for action_name in expected_routes:
            current = transitive_action_census(action_name, functions)
            baseline = transitive_action_census(action_name, baseline_functions)
            logical_counts_exact &= current["counts"] == baseline["counts"]
            output_closure_exact &= (
                current["output_transforms"] == baseline["output_transforms"]
            )
        semantic_closure_exact = logical_counts_exact and output_closure_exact
    physical = physical_proof_counts(plugin)
    expected_physical = (
        REFACTOR_PHASE6_CANARY_ECONOMY_PHYSICAL
        if expected_routes
        else REFACTOR_CURRENT_PHASE5_PHYSICAL
    )
    intro = intro_audit(plugin, actions) if include_intro_audit else None
    checks = {
        "profile_inventory_exact": phase6_like_helpers == expected_helpers,
        "helper_bodies_exact": all(
            all(values.values()) for values in helper_checks.values()
        ),
        "routes_exact": (
            set(route_details) == set(expected_routes)
            and all(all(values.values()) for values in route_details.values())
            and all(
                routed.get(action_name, []) == list(route)
                for action_name, route in expected_routes.items()
            )
            and all(
                not calls
                for action_name, calls in routed.items()
                if action_name not in expected_routes
            )
        ),
        "helper_callers_exact": helper_callers == {
            helper_name: sorted(
                action_name for action_name, route in expected_routes.items()
                if helper_name in route
            )
            for helper_name in expected_helpers
        },
        "bulk_distribution_exact": (
            not expected_routes
            or (
                len(expected_routes) == 21
                and route_distribution == Counter({
                    "move_positive_core": 9,
                    "move_negative_core": 9,
                    "advance_ship_epoch_core": 3,
                    "update_ship_work_vdf_4_core": 7,
                    "update_ship_work_vdf_12_core": 7,
                    "update_ship_work_vdf_28_core": 7,
                })
            )
        ),
        "intro_contract_exact": (
            not include_intro_audit or intro["status"] == "pass"
        ),
        "physical_ledger_exact": physical == expected_physical,
        "logical_and_output_closure_exact": semantic_closure_exact,
        "flattened_witness_scope_exact": (
            not include_witness_scope
            or flattened_witness_scope_audit(plugin, actions)["status"] == "pass"
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "profile": ACTIVE_VDF_PROFILE,
        "helpers": helper_checks,
        "routes": routed,
        "route_details": route_details,
        "route_distribution": dict(sorted(route_distribution.items())),
        "physical": physical,
        "intro": intro,
        "checks": checks,
    }


def phase6_token_layout_audit(
    plugin: str,
    actions: list[dict[str, Any]],
    bank: list[dict[str, Any]] | None = None,
    *,
    include_baseline: bool = True,
) -> dict[str, Any]:
    """Bind the exact token-only and 921-wrapper Phase 6 layout pass."""
    global PHASE6_TOKEN_LAYOUT_ENABLED

    target = REFACTOR_PHASE6_LAYOUT_TARGETS[ACTIVE_VDF_PROFILE]
    functions = rhai_function_sources(plugin)
    action_names = {action["name"] for action in actions}
    simple_routes = phase6_simple_adapter_helpers(
        BODY_BANK if bank is None else bank
    )
    simple_names = set(simple_routes)
    helper_names = set(functions) - action_names
    simple_details: dict[str, dict[str, bool]] = {}
    for action_name, helper_name in simple_routes.items():
        wrapper = functions.get(action_name, "")
        lines = wrapper.splitlines()
        role_count = len(source_action_object_roles(wrapper))
        role_lines = [
            line
            for line in lines
            if re.search(r"action\.(?:output|input|mutate)\(", line)
        ]
        try:
            canonical_idempotent = (
                bool(wrapper)
                and compact_simple_adapter_wrapper(
                    wrapper + "\n", helper_name
                ).rstrip("\n") == wrapper
            )
        except ValueError:
            canonical_idempotent = False
        checks = {
            "canonical_idempotent": canonical_idempotent,
            "roles_one_statement_per_line": (
                len(role_lines) == role_count
                and all(line.count(";") == 1 for line in role_lines)
            ),
            "sole_adapter_statement_and_brace": (
                bool(lines)
                and lines[-1].startswith(f"{helper_name}(")
                and lines[-1].endswith(");}")
                and sum(line.count(";") for line in lines)
                == role_count + 1
            ),
            "simple_line_cap": (
                max(map(len, lines), default=0)
                <= RHAI_SIMPLE_WRAPPER_MAX_LINE_LENGTH
            ),
        }
        simple_details[action_name] = checks

    baseline_plugin = ""
    baseline_functions: dict[str, str] = {}
    if include_baseline:
        previous = PHASE6_TOKEN_LAYOUT_ENABLED
        PHASE6_TOKEN_LAYOUT_ENABLED = False
        try:
            baseline_plugin = render_plugin(
                actions,
                sources_for_bank(BODY_BANK if bank is None else bank),
            )
        finally:
            PHASE6_TOKEN_LAYOUT_ENABLED = previous
        baseline_functions = rhai_function_sources(baseline_plugin)

    tokens_equal = True
    strings_equal = True
    changed_line_inventory_exact = True
    complex_line_counts_equal = True
    if include_baseline:
        function_names_equal = set(functions) == set(baseline_functions)
        common_names = set(functions) & set(baseline_functions)
        tokens_equal = function_names_equal and all(
            rhai_lexical_tokens(functions[name])
            == rhai_lexical_tokens(baseline_functions[name])
            for name in common_names
        )
        strings_equal = function_names_equal and all(
            tuple(
                token for token in rhai_lexical_tokens(functions[name])
                if token.startswith('"')
            )
            == tuple(
                token
                for token in rhai_lexical_tokens(baseline_functions[name])
                if token.startswith('"')
            )
            for name in common_names
        )
        changed_lines = {
            name
            for name in common_names
            if len(functions[name].splitlines())
            != len(baseline_functions[name].splitlines())
        } | (set(functions) ^ set(baseline_functions))
        changed_line_inventory_exact = changed_lines == simple_names
        complex_line_counts_equal = function_names_equal and all(
            len(functions[name].splitlines())
            == len(baseline_functions[name].splitlines())
            for name in common_names - simple_names
        )

    plugin_lines = plugin.splitlines()
    plugin_nonblank_lines = sum(bool(line.strip()) for line in plugin_lines)
    checks = {
        "inventory_exact": (
            len(simple_routes) == len(simple_names) == 921
            and simple_names.issubset(action_names)
            and len(action_names) == target["actions"]
            and len(helper_names) == target["helpers"]
        ),
        "simple_wrappers_exact": all(
            all(detail.values()) for detail in simple_details.values()
        ),
        "tokens_equal_pre_layout": tokens_equal,
        "string_literals_equal_pre_layout": strings_equal,
        "only_simple_wrapper_lines_changed": (
            changed_line_inventory_exact and complex_line_counts_equal
        ),
        "global_line_cap": (
            max(map(len, plugin_lines), default=0) <= RHAI_MAX_LINE_LENGTH
        ),
        "token_compaction_idempotent": (
            minify_rhai_source_tokens(plugin) == plugin
        ),
        "line_endings_exact": (
            "\r" not in plugin
            and plugin.endswith("\n")
            and not plugin.endswith("\n\n")
        ),
        "frozen_source_exact": (
            len(plugin.encode("utf-8")) == target["plugin_bytes"]
            and plugin_nonblank_lines == target["plugin_nonblank_lines"]
            and hashlib.sha256(plugin.encode("utf-8")).hexdigest()
            == target["sha256"]
        ),
        "pre_layout_ledger_exact": (
            not include_baseline
            or (
                len(baseline_plugin.encode("utf-8"))
                == target["baseline_bytes"]
                and sum(
                    bool(line.strip())
                    for line in baseline_plugin.splitlines()
                ) == target["baseline_nonblank_lines"]
            )
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "profile": ACTIVE_VDF_PROFILE,
        "target": target,
        "simple_wrapper_count": len(simple_routes),
        "helper_count": len(helper_names),
        "plugin_bytes": len(plugin.encode("utf-8")),
        "plugin_nonblank_lines": plugin_nonblank_lines,
        "sha256": hashlib.sha256(plugin.encode("utf-8")).hexdigest(),
        "max_line": max(map(len, plugin_lines), default=0),
        "simple_details": simple_details,
        "checks": checks,
    }


def phase4_wrapper_semantic_source(
    plugin: str,
    action_name: str,
    kind: str,
) -> str:
    """Join a routed wrapper to its adapter for source-shape audits."""
    wrapper = action_function_source(plugin, action_name)
    helper_name = next(
        (
            name
            for name, helper_kind, _iterations, _representative
            in phase4_helper_specs()
            if helper_kind == kind and rhai_call_arguments(wrapper, name)
        ),
        None,
    )
    if helper_name is None:
        return wrapper
    return wrapper + named_function_source(plugin, helper_name)


def phase4_semantic_closure_audit(
    plugin: str,
    actions: list[dict[str, Any]],
    bank: list[dict[str, Any]],
) -> dict[str, Any]:
    """Compare ordered, multiplicity-preserving closures to frozen Phase 3."""
    global PHASE4_ADAPTER_CANARIES_ENABLED

    previous = PHASE4_ADAPTER_CANARIES_ENABLED
    PHASE4_ADAPTER_CANARIES_ENABLED = False
    try:
        phase3_plugin = render_plugin(actions, sources_for_bank(bank))
    finally:
        PHASE4_ADAPTER_CANARIES_ENABLED = previous
    current_functions = rhai_function_sources(plugin)
    phase3_functions = rhai_function_sources(phase3_plugin)
    mismatches: dict[str, dict[str, Any]] = {}
    for action in actions:
        name = action["name"]
        current = transitive_action_census(name, current_functions)
        baseline = transitive_action_census(name, phase3_functions)
        current_closure = [
            (row["target"], row["method"], row["expression"])
            for row in current["output_transforms"]
        ]
        baseline_closure = [
            (row["target"], row["method"], row["expression"])
            for row in baseline["output_transforms"]
        ]
        if current["counts"] != baseline["counts"] or current_closure != baseline_closure:
            mismatches[name] = {
                "counts_equal": current["counts"] == baseline["counts"],
                "closure_equal": current_closure == baseline_closure,
            }
    return {
        "status": "pass" if not mismatches else "fail",
        "profile": ACTIVE_VDF_PROFILE,
        "action_count": len(actions),
        "mismatches": mismatches,
    }


def phase4_profile_census(
    plugin: str,
    actions: list[dict[str, Any]],
    bank: list[dict[str, Any]],
) -> dict[str, Any]:
    """Measure every Phase 4 route against its same-profile Phase 3 source."""
    global PHASE4_ADAPTER_CANARIES_ENABLED

    previous = PHASE4_ADAPTER_CANARIES_ENABLED
    PHASE4_ADAPTER_CANARIES_ENABLED = False
    try:
        phase3_plugin = render_plugin(actions, sources_for_bank(bank))
    finally:
        PHASE4_ADAPTER_CANARIES_ENABLED = previous
    physical = physical_proof_counts(plugin)
    phase3_physical = physical_proof_counts(phase3_plugin)
    functions = rhai_function_sources(plugin)
    baseline_functions = rhai_function_sources(phase3_plugin)
    logical: Counter[str] = Counter()
    baseline_logical: Counter[str] = Counter()
    for action in actions:
        logical.update(transitive_action_census(action["name"], functions)["counts"])
        baseline_logical.update(
            transitive_action_census(action["name"], baseline_functions)["counts"]
        )
    expected_actions = 1_650 if ACTIVE_VDF_PROFILE == "economy" else 1_638
    expected_vdf = 1_352 if ACTIVE_VDF_PROFILE == "economy" else 659
    current_logical = dict(sorted(logical.items()))
    physical_delta = {
        key: physical[key] - phase3_physical[key]
        for key in physical
    }
    expected_physical = (
        (
            REFACTOR_PHASE6_CANARY_ECONOMY_PHYSICAL
            if PHASE6_MOVEMENT_CANARIES_ENABLED
            else REFACTOR_PHASE5_ECONOMY_PHYSICAL
        )
        if ACTIVE_VDF_PROFILE == "economy"
        else REFACTOR_CURRENT_PHASE5_PHYSICAL
    )
    expected_phase3_delta = (
        REFACTOR_PHASE4_ECONOMY_PHASE3_PHYSICAL_DELTAS
        if ACTIVE_VDF_PROFILE == "economy"
        else REFACTOR_CURRENT_PHASE4_PHASE3_RENDER_PHYSICAL_DELTAS
    )
    profile_baseline = (
        {
            "st_sum": REFACTOR_BASELINE["physical_st_sum"],
            "st_gt": REFACTOR_BASELINE["physical_st_gt"],
            "unsafe": REFACTOR_BASELINE["physical_unsafe"],
            "random": REFACTOR_BASELINE["random_calls"],
            "var_assign": REFACTOR_BASELINE["var_assign_calls"],
            "rotate_key": REFACTOR_BASELINE["rotate_key_calls"],
            "intro_vdf": REFACTOR_BASELINE["physical_vdf_calls"],
            "intro_lt_eq_u256": REFACTOR_BASELINE["physical_intro_lt_eq_u256"],
        }
        if ACTIVE_VDF_PROFILE == "economy"
        else REFACTOR_CURRENT_PHASE3_PHYSICAL
    )
    profile_baseline_delta = {
        key: physical[key] - profile_baseline[key]
        for key in physical
    }
    expected_profile_baseline_delta = (
        (
            REFACTOR_PHASE6_CANARY_ECONOMY_PHYSICAL_DELTAS
            if PHASE6_MOVEMENT_CANARIES_ENABLED
            else REFACTOR_PHASE5_ECONOMY_PHYSICAL_DELTAS
        )
        if ACTIVE_VDF_PROFILE == "economy"
        else REFACTOR_CURRENT_PHASE5_PHYSICAL_DELTAS
    )
    checks = {
        "profile_action_count_exact": len(actions) == expected_actions,
        "logical_vdf_exact": logical["intro_vdf"] == expected_vdf,
        "logical_counts_equal_phase3": logical == baseline_logical,
        "physical_counts_exact": physical == expected_physical,
        "physical_delta_from_phase3_exact": (
            physical_delta == expected_phase3_delta
        ),
        "physical_delta_from_profile_baseline_exact": (
            profile_baseline_delta == expected_profile_baseline_delta
        ),
        "zero_witness_collisions": (
            flattened_witness_scope_audit(plugin, actions)["status"] == "pass"
        ),
    }
    if ACTIVE_VDF_PROFILE == "current":
        checks.update({
            "frozen_current_logical_baseline_exact": (
                current_logical == REFACTOR_CURRENT_ACCEPTED_LOGICAL
            ),
            "frozen_current_physical_baseline_exact": (
                physical == REFACTOR_CURRENT_PHASE5_PHYSICAL
            ),
            "current_phase1_logical_delta_exact": (
                current_logical["st_sum"] - REFACTOR_CURRENT_PHASE3_LOGICAL["st_sum"] == -327
                and all(current_logical[key] == REFACTOR_CURRENT_PHASE3_LOGICAL[key]
                        for key in current_logical if key != "st_sum")
            ),
            "current_phase1_phase3_physical_delta_exact": (
                profile_baseline_delta
                == REFACTOR_CURRENT_PHASE5_PHYSICAL_DELTAS
            ),
        })
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "profile": ACTIVE_VDF_PROFILE,
        "checks": checks,
        "physical": physical,
        "phase3_physical": phase3_physical,
        "physical_delta_from_phase3": physical_delta,
        "physical_delta_from_profile_baseline": profile_baseline_delta,
        "logical": current_logical,
        "phase3_logical": dict(sorted(baseline_logical.items())),
    }


def lifecycle_raw_binding_audit(
    actions: list[dict[str, Any]],
    plugin: str,
    bank: list[dict[str, Any]],
) -> dict[str, Any]:
    """Audit the production Claim/Survey/Detect/Scan source templates.

    Exact comparison protects the positive-only lifecycle, explicit profile
    selection, milestone gates, counted Signal slots, co-location constraints,
    and canonical parent-identifier bindings for randomness-bearing children.
    """
    by_name = {action["name"]: action for action in actions}
    details: dict[str, dict[str, Any]] = {}
    scan_core = named_function_source(plugin, "scan_body_core")
    survey_ship_core = named_function_source(
        plugin, "survey_replacement_ship_core"
    )
    detect_ship_finish_core = named_function_source(
        plugin, "finish_detect_replacement_ship_core"
    )
    phase3_canaries = phase3_helper_canary_audit(plugin, bank)
    replacement_core_checks = {
        "survey_core_present_once": (
            rhai_function_definition_count(
                plugin, "survey_replacement_ship_core"
            ) == 1
        ),
        "detect_finish_core_present_once": (
            rhai_function_definition_count(
                plugin, "finish_detect_replacement_ship_core"
            ) == 1
        ),
        "no_object_role_declarations": (
            not source_action_object_roles(survey_ship_core)
            and not source_action_object_roles(detect_ship_finish_core)
        ),
        "replacement_ship_fields_exact": (
            object_set_fields(survey_ship_core, "next_ship")
            == list(SHIP_SEMANTIC_FIELDS)
            and object_set_fields(detect_ship_finish_core, "next_ship")
            == list(SHIP_SEMANTIC_FIELDS)
        ),
        "survey_versions_and_location_exact": all(
            token in survey_ship_core
            for token in (
                "prove_fixed_versions(action, ship);",
                "prove_fixed_versions(action, sector);",
                f"action.st_sum(sector.body_bank_version, 0, {VERSIONS['body_bank_version']});",
                "action.st_sum(sector.x, 0, x);",
                "action.st_sum(sector.y, 0, y);",
                "action.st_sum(sector.z, 0, z);",
                "action.st_sum(sector.epoch, 0, epoch);",
            )
        ),
        "action_serial_increments_exact": (
            "action.st_sum(ship.action_serial, 1, next_action_serial);"
            in survey_ship_core
            and "action.st_sum(ship.action_serial, 1, next_action_serial);"
            in detect_ship_finish_core
        ),
        "detect_discovery_increment_exact": all(
            token in detect_ship_finish_core
            for token in (
                (
                    "var next_discovery_serial = unsafe { "
                    "ship.discovery_serial - (0 - 1) };"
                ),
                (
                    "action.st_sum(ship.discovery_serial, 1, "
                    "next_discovery_serial);"
                ),
                '["discovery_serial", next_discovery_serial]',
            )
        ),
        "intro_vdf_and_subaction_absent": all(
            token not in survey_ship_core + detect_ship_finish_core
            for token in ("intro_lt_eq_u256", "intro_vdf", "subaction")
        ),
    }

    expected_sources: dict[str, str] = {"ClaimSector": claim_source()}
    for profile in SURVEY_PROFILES:
        name = f"SurveySector_{profile['code']:02d}_{profile['slug']}"
        expected_sources[name] = survey_source(profile)
    for candidate in bank:
        detect_name = (
            f"DetectCelestialSignal_{candidate['code']:02d}_"
            f"{candidate['slug']}"
        )
        scan_name = (
            f"ScanCelestialBody_{candidate['code']:02d}_"
            f"{candidate['slug']}"
        )
        expected_sources[detect_name] = detect_source(candidate)
        expected_sources[scan_name] = scan_source(candidate)

    for name, expected_source in expected_sources.items():
        actual_source = action_function_source(plugin, name)
        checks = {
            "action_present": name in by_name and bool(actual_source),
            "source_exact": rhai_sources_equal(actual_source, expected_source),
            "no_subaction": "subaction" not in actual_source,
        }
        if name.startswith("SurveySector_"):
            minified_actual = minify_rhai_source_tokens(actual_source)
            profile = next(
                item
                for item in SURVEY_PROFILES
                if name
                == f"SurveySector_{item['code']:02d}_{item['slug']}"
            )
            action_metadata = by_name.get(name, {})
            checks.update(
                {
                    "replacement_ship_core_route_exact": (
                        minified_actual.count(
                            "survey_replacement_ship_core("
                            "action,next_ship,ship,sector);"
                        )
                        == 1
                    ),
                    "empty_sector_proof_route_exact": (
                        minified_actual.count(
                            "prove_empty_survey_sector_core(action,sector);"
                        )
                        == 1
                    ),
                    "explicit_selection_metadata_exact": (
                        action_metadata.get("selection_mode")
                        == EXPLICIT_SELECTION_MODE
                        and action_metadata.get("survey_profile")
                        == profile["code"]
                        and action_metadata.get("minimum_claim_serial")
                        == profile["minimum_claim_serial"]
                    ),
                    "stable_identifier_selection_absent": all(
                        token not in actual_source
                        for token in (
                            "sector.stable_identifier",
                            "sector_selector",
                            "top_limb_u256",
                            "intro_lt_eq_u256",
                        )
                    ),
                    "milestone_gate_exact": (
                        minified_actual.count(
                            "action.st_gt(ship.claim_serial,"
                            f"{profile['minimum_claim_serial'] - 1});"
                        )
                        == 1
                    ),
                    "selected_profile_literal_exact": (
                        minified_actual.count(
                            f'sector.update("survey_profile",{profile["code"]});'
                        )
                        == 1
                    ),
                }
            )
        if name.startswith("DetectCelestialSignal_"):
            candidate = next(
                item for item in bank
                if name == f"DetectCelestialSignal_{item['code']:02d}_{item['slug']}"
            )
            detect_semantic_source = named_function_source(
                plugin, "detect_signal_core"
            )
            checks.update(
                {
                    "replacement_ship_finish_core_route_exact": (
                        actual_source.count("detect_signal_core(") == 1
                        and "finish_detect_replacement_ship_core("
                        not in actual_source
                    ),
                    "no_sector_identifier_export": (
                        "source_sector_identifier" not in actual_source
                        and 'sector.update("stable_identifier"' not in actual_source
                    ),
                    "counted_slot_is_bound": (
                        '["slot_serial", slot_serial]' in detect_semantic_source
                        and "action.st_gt(sector" in detect_semantic_source
                    ),
                }
            )
        if name.startswith("ScanCelestialBody_"):
            checks.update(
                {
                    "canonical_signal_identifier_export": (
                        "var_assign(source_signal_identifier, "
                        "signal.stable_identifier);"
                        in scan_core
                        and 'signal.update("stable_identifier", '
                        "source_signal_identifier);"
                        in scan_core
                        and '["source_signal_identifier", '
                        "source_signal_identifier]"
                        in scan_core
                    ),
                    "slot_serial_is_validated_not_copied": (
                        "action.st_gt(signal.slot_serial, -1);"
                        in scan_core
                        and "source_slot_serial" not in scan_core
                    ),
                }
            )
        details[name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
        }

    checks = {
        "replacement_ship_cores_all_pass": all(
            replacement_core_checks.values()
        ),
        "all_lifecycle_sources_exact": all(
            detail["status"] == "pass" for detail in details.values()
        ),
        "phase3_helper_canaries_exact": phase3_canaries["status"] == "pass",
        "old_lifecycle_names_absent": (
            "fn RevealSector(action)" not in plugin
            and "fn MaterializeCelestialBody_" not in plugin
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "checks": checks,
        "replacement_ship_cores": {
            "status": (
                "pass"
                if all(replacement_core_checks.values())
                else "fail"
            ),
            "checks": replacement_core_checks,
        },
        "actions": details,
        "phase3_helper_canaries": phase3_canaries,
    }


def lifecycle_raw_binding_adversarial_self_check(
    actions: list[dict[str, Any]],
    plugin: str,
    bank: list[dict[str, Any]],
) -> dict[str, Any]:
    """Prove the lifecycle source audit rejects meaningful regressions."""
    def replace_literal_exact(
        source: str,
        old: str,
        new: str,
    ) -> str:
        if source.count(old) != 1:
            raise ValueError(
                f"adversarial literal must occur exactly once: {old!r}"
            )
        return source.replace(old, new, 1)

    def replace_regex_exact(
        source: str,
        pattern: str,
        replacement: str,
    ) -> str:
        if len(re.findall(pattern, source, flags=re.DOTALL)) != 1:
            raise ValueError(
                f"adversarial pattern must match exactly once: {pattern!r}"
            )
        return re.sub(
            pattern,
            replacement,
            source,
            count=1,
            flags=re.DOTALL,
        )

    first_profile = SURVEY_PROFILES[0]
    first_candidate = bank[0]
    detect_name = (
        f"DetectCelestialSignal_{first_candidate['code']:02d}_"
        f"{first_candidate['slug']}"
    )
    scan_name = (
        f"ScanCelestialBody_{first_candidate['code']:02d}_"
        f"{first_candidate['slug']}"
    )
    survey_name = (
        f"SurveySector_{first_profile['code']:02d}_"
        f"{first_profile['slug']}"
    )
    mutations = {
        "survey_stable_id_selector_reintroduced": replace_action_function(
            plugin,
            survey_name,
            lambda source: replace_regex_exact(
                source,
                (
                    r"action\.st_gt\(\s*ship\.claim_serial\s*,\s*"
                    f"{first_profile['minimum_claim_serial'] - 1}"
                    r"\s*\);"
                ),
                (
                    "action.st_gt(ship.claim_serial, "
                    f"{first_profile['minimum_claim_serial'] - 1});\n"
                    "    let forbidden_selector = action.top_limb_u256(0);\n"
                    "    action.intro_lt_eq_u256("
                    "forbidden_selector, sector.stable_identifier);"
                ),
            ),
        ),
        "survey_profile_literal_forged": replace_action_function(
            plugin,
            survey_name,
            lambda source: replace_regex_exact(
                source,
                (
                    r'sector\.update\(\s*"survey_profile"\s*,\s*'
                    f'{first_profile["code"]}'
                    r"\s*\);"
                ),
                'sector.update("survey_profile", 0);',
            ),
        ),
        "survey_milestone_forged": replace_action_function(
            plugin,
            survey_name,
            lambda source: replace_regex_exact(
                source,
                (
                    r"action\.st_gt\(\s*ship\.claim_serial\s*,\s*"
                    f"{first_profile['minimum_claim_serial'] - 1}"
                    r"\s*\);"
                ),
                (
                    "action.st_gt(ship.claim_serial, "
                    f"{first_profile['minimum_claim_serial'] - 2});"
                ),
            ),
        ),
        "survey_replacement_ship_serial_forged": replace_named_function(
            plugin,
            "survey_replacement_ship_core",
            lambda source: replace_regex_exact(
                source,
                (
                    r"action\.st_sum\(\s*ship\.action_serial\s*,\s*1\s*,\s*"
                    r"next_action_serial\s*\);"
                ),
                "action.st_sum(ship.action_serial, 0, next_action_serial);",
            ),
        ),
        "detect_slot_serial_forged": replace_named_function(
            plugin,
            "detect_signal_core",
            lambda source: replace_regex_exact(
                source,
                r'\[\s*"slot_serial"\s*,\s*slot_serial\s*\]',
                '["slot_serial", 0]',
            ),
        ),
        "detect_replacement_ship_serial_forged": replace_named_function(
            plugin,
            "finish_detect_replacement_ship_core",
            lambda source: replace_regex_exact(
                source,
                (
                    r"action\.st_sum\(\s*ship\.action_serial\s*,\s*1\s*,\s*"
                    r"next_action_serial\s*\);"
                ),
                "action.st_sum(ship.action_serial, 0, next_action_serial);",
            ),
        ),
        "scan_negative_slot_allowed": replace_named_function(
            plugin,
            "scan_body_core",
            lambda source: replace_regex_exact(
                source,
                r"action\.st_gt\(\s*signal\.slot_serial\s*,\s*-1\s*\);",
                "action.st_gt(signal.slot_serial, -2);",
            ),
        ),
    }
    audits = {
        name: lifecycle_raw_binding_audit(actions, mutant, bank)
        for name, mutant in mutations.items()
    }
    targeted_failures = {
        "survey_stable_id_selector_reintroduced": (
            not audits["survey_stable_id_selector_reintroduced"]["actions"]
            [survey_name]["checks"]
            ["stable_identifier_selection_absent"]
        ),
        "survey_profile_literal_forged": (
            not audits["survey_profile_literal_forged"]["actions"]
            [survey_name]["checks"]
            ["selected_profile_literal_exact"]
        ),
        "survey_milestone_forged": (
            not audits["survey_milestone_forged"]["actions"]
            [survey_name]["checks"]["milestone_gate_exact"]
        ),
        "survey_replacement_ship_serial_forged": (
            not audits["survey_replacement_ship_serial_forged"]
            ["replacement_ship_cores"]["checks"]
            ["action_serial_increments_exact"]
        ),
        "detect_slot_serial_forged": (
            not audits["detect_slot_serial_forged"]["actions"]
            [detect_name]["checks"]["counted_slot_is_bound"]
        ),
        "detect_replacement_ship_serial_forged": (
            not audits["detect_replacement_ship_serial_forged"]
            ["replacement_ship_cores"]["checks"]
            ["action_serial_increments_exact"]
        ),
        "scan_negative_slot_allowed": (
            not audits["scan_negative_slot_allowed"]["actions"]
            [scan_name]["checks"]["slot_serial_is_validated_not_copied"]
        ),
    }
    rejected = {
        name: (
            mutant != plugin
            and audits[name]["status"] == "fail"
            and targeted_failures[name]
        )
        for name, mutant in mutations.items()
    }
    return {
        "status": "pass" if all(rejected.values()) else "fail",
        "checks": rejected,
        "targeted_subcheck_failures": targeted_failures,
        "mutation_count": len(mutations),
        "all_mutations_are_single_exact_replacements": True,
        "profile_under_test": (
            f"SurveySector_{first_profile['code']:02d}_"
            f"{first_profile['slug']}"
        ),
        "candidate_under_test": first_candidate["code"],
    }


def lifecycle_refactor_audit(
    actions: list[dict[str, Any]],
    plugin: str,
    bank: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    """Check the current positive-only Sector lifecycle and object roles."""
    audited_bank = bank if bank is not None else BODY_BANK
    by_name = {action["name"]: action for action in actions}
    family_counts = Counter(action["family"] for action in actions)
    survey_names = {
        f"SurveySector_{profile['code']:02d}_{profile['slug']}"
        for profile in SURVEY_PROFILES
    }
    detect_names = {
        f"DetectCelestialSignal_{candidate['code']:02d}_"
        f"{candidate['slug']}"
        for candidate in audited_bank
    }
    scan_names = {
        f"ScanCelestialBody_{candidate['code']:02d}_{candidate['slug']}"
        for candidate in audited_bank
    }
    survey_roles = [
        ("output", SHIP),
        ("input", SHIP),
        ("mutate", SECTOR),
    ]
    detect_roles = [
        ("output", SHIP),
        ("output", SIGNAL),
        ("input", SHIP),
        ("mutate", SECTOR),
    ]
    scan_roles = [
        ("output", BODY),
        ("input", SIGNAL),
        ("mutate", SHIP),
    ]
    raw_binding = lifecycle_raw_binding_audit(
        actions,
        plugin,
        audited_bank,
    )
    scan_core = named_function_source(plugin, "scan_body_core")
    checks = {
        "claim_roles_exact": (
            "ClaimSector" in by_name
            and action_object_roles(by_name["ClaimSector"])
            == [("output", SECTOR), ("mutate", SHIP)]
        ),
        "survey_action_set_exact": (
            {
                action["name"]
                for action in actions
                if action["family"] == "survey_sector"
            }
            == survey_names
        ),
        "survey_roles_exact": all(
            action_object_roles(by_name[name]) == survey_roles
            for name in survey_names
        ),
        "detect_action_set_exact": (
            {
                action["name"]
                for action in actions
                if action["family"] == "detect_signal"
            }
            == detect_names
        ),
        "detect_roles_exact": all(
            action_object_roles(by_name[name]) == detect_roles
            for name in detect_names
        ),
        "scan_action_set_exact": (
            {
                action["name"]
                for action in actions
                if action["family"] == "scan_body"
            }
            == scan_names
        ),
        "scan_roles_exact": all(
            action_object_roles(by_name[name]) == scan_roles
            for name in scan_names
        ),
        "family_counts_exact": (
            family_counts["claim_sector"] == 1
            and family_counts["survey_sector"] == len(SURVEY_PROFILES)
            and family_counts["detect_signal"] == len(audited_bank)
            and family_counts["scan_body"] == len(audited_bank)
        ),
        "sector_schema_is_counted_pool": (
            "sector_type" in dict(SCHEMAS[SECTOR])
            and "survey_profile" in dict(SCHEMAS[SECTOR])
            and all(
                category["remaining_field"] in dict(SCHEMAS[SECTOR])
                and category["serial_field"] in dict(SCHEMAS[SECTOR])
                for category in CELESTIAL_CATEGORIES
            )
        ),
        "signal_slot_is_consumed_not_copied": (
            "slot_serial" in dict(SCHEMAS[SIGNAL])
            and "source_slot_serial" not in dict(SCHEMAS[BODY])
        ),
        "body_identity_is_signal_derived": (
            "source_signal_identifier" in dict(SCHEMAS[BODY])
            and '["source_signal_identifier", source_signal_identifier]'
            in scan_core
            and 'body.update("key", zero);' in scan_core
            and all(
                "scan_body_core(" in action_function_source(plugin, name)
                for name in scan_names
            )
        ),
        "raw_binding_audit": raw_binding["status"] == "pass",
        "no_subactions": "subaction" not in plugin,
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "candidate_count": len(audited_bank),
        "survey_profile_count": len(SURVEY_PROFILES),
        "checks": checks,
        "raw_identifier_binding_audit": raw_binding,
    }


def warp_coordinate_audit(
    actions: list[dict[str, Any]],
    plugin: str,
) -> dict[str, Any]:
    by_name = {action["name"]: action for action in actions}
    position_reveal_names = {
        f"RevealWarpCoordinate{destination['slug']}"
        for destination in POSITION_WARP_DESTINATIONS
    }
    time_reveal_names = {
        f"RevealTimeCoordinate{destination['slug']}"
        for destination in TIME_WARP_DESTINATIONS
    }
    expected_position_schema = [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("source_body_identifier", "Raw"),
        ("source_pool_before", "Int"),
        ("revealed", "Int"),
        ("destination_code", "Int"),
        ("destination_x", "Int"),
        ("destination_y", "Int"),
        ("destination_z", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ]
    expected_time_schema = [
        ("schema_version", "Int"),
        ("mechanics_version", "Int"),
        ("universe_version", "Int"),
        ("source_body_identifier", "Raw"),
        ("source_pool_before", "Int"),
        ("revealed", "Int"),
        ("destination_code", "Int"),
        ("destination_epoch", "Int"),
        ("uses_remaining", "Int"),
        ("key", "Raw"),
        ("stable_identifier", "Raw"),
    ]
    position_reveal_sources = {
        f"RevealWarpCoordinate{destination['slug']}": action_function_source(
            plugin, f"RevealWarpCoordinate{destination['slug']}"
        )
        for destination in POSITION_WARP_DESTINATIONS
    }
    time_reveal_sources = {
        f"RevealTimeCoordinate{destination['slug']}": action_function_source(
            plugin, f"RevealTimeCoordinate{destination['slug']}"
        )
        for destination in TIME_WARP_DESTINATIONS
    }
    position_reusable = action_function_source(
        plugin, "WarpToCoordinateReusable"
    )
    position_final = action_function_source(plugin, "WarpToCoordinateFinal")
    time_reusable = action_function_source(
        plugin, "TimeWarpToCoordinateReusable"
    )
    time_final = action_function_source(
        plugin, "TimeWarpToCoordinateFinal"
    )
    coordinate_extraction_sources = (
        action_function_source(plugin, "ExtractAnomalyWarpCoordinate"),
        action_function_source(plugin, "ExtractAnomalyTimeCoordinate"),
    )

    def use_policy_is_valid(destinations: list[dict[str, Any]]) -> bool:
        return (
            sum(item["uses"] == 10 for item in destinations) == 1
            and sum(item["uses"] == 3 for item in destinations) == 3
            and sum(item["uses"] == 1 for item in destinations)
            == len(destinations) - 4
        )

    checks = {
        "position_schema_exact": (
            SCHEMAS[WARP_COORDINATE] == expected_position_schema
        ),
        "time_schema_exact": SCHEMAS[TIME_COORDINATE] == expected_time_schema,
        "position_extraction_roles_exact": (
            action_object_roles(by_name["ExtractAnomalyWarpCoordinate"])
            == [
                ("output", SHIP),
                ("output", WARP_COORDINATE),
                ("input", SHIP),
                ("mutate", BODY),
            ]
        ),
        "time_extraction_roles_exact": (
            action_object_roles(by_name["ExtractAnomalyTimeCoordinate"])
            == [
                ("output", SHIP),
                ("output", TIME_COORDINATE),
                ("input", SHIP),
                ("mutate", BODY),
            ]
        ),
        "position_extraction_source_exact": (
            rhai_sources_equal(
                action_function_source(plugin, "ExtractAnomalyWarpCoordinate"),
                extract_coordinate_source(time_only=False),
            )
        ),
        "time_extraction_source_exact": (
            rhai_sources_equal(
                action_function_source(plugin, "ExtractAnomalyTimeCoordinate"),
                extract_coordinate_source(time_only=True),
            )
        ),
        "exact_capacity_witness_copies_preserved": all(
            capacity_witness_copy_is_exact(source)
            for source in coordinate_extraction_sources
        ),
        "position_reveal_action_set_exact": (
            {
                action["name"]
                for action in actions
                if action["family"] == "reveal_warp_coordinate"
            }
            == position_reveal_names
        ),
        "time_reveal_action_set_exact": (
            {
                action["name"]
                for action in actions
                if action["family"] == "reveal_time_coordinate"
            }
            == time_reveal_names
        ),
        "position_reveal_sources_exact": all(
            rhai_sources_equal(
                position_reveal_sources[
                    f"RevealWarpCoordinate{destination['slug']}"
                ],
                reveal_position_coordinate_source(destination),
            )
            for destination in POSITION_WARP_DESTINATIONS
        ),
        "time_reveal_sources_exact": all(
            rhai_sources_equal(
                time_reveal_sources[
                    f"RevealTimeCoordinate{destination['slug']}"
                ],
                reveal_time_coordinate_source(destination),
            )
            for destination in TIME_WARP_DESTINATIONS
        ),
        "reveal_helpers_use_explicit_action_identity_only": (
            all(
                all(
                    token not in named_function_source(plugin, helper)
                    for token in (
                        ".stable_identifier",
                        "top_limb_u256",
                        "intro_lt_eq_u256",
                        "selector",
                    )
                )
                for helper in ("reveal_p", "reveal_t")
            )
            and all(
                rhai_whitespace_insensitive_contains(
                    named_function_source(plugin, helper),
                    "action.st_gt(coordinate.source_pool_before, "
                    "minimum_source_pool_exclusive);",
                )
                for helper in ("reveal_p", "reveal_t")
            )
            and all(
                rhai_contains(source, "reveal_p(action, c,")
                for source in position_reveal_sources.values()
            )
            and all(
                rhai_contains(source, "reveal_t(action, c,")
                for source in time_reveal_sources.values()
            )
            and all(
                named_function_source(plugin, helper).count(
                    "action.st_gt("
                )
                == 1
                and not rhai_call_uses_indexed_field(
                    named_function_source(plugin, helper),
                    "action.st_sum",
                    "source_pool_maximum",
                )
                for helper in ("reveal_p", "reveal_t")
            )
        ),
        "current_sdk_surface_only": all(
            forbidden not in plugin
            for forbidden in (
                "intro_warp_coordinates",
                "top_limb_u256_upper",
                "max_u256",
            )
        ),
        "position_catalog_exact_and_bounded": (
            len(POSITION_WARP_DESTINATIONS) == POSITION_WARP_COUNT
            and [item["code"] for item in POSITION_WARP_DESTINATIONS]
            == list(range(1, POSITION_WARP_COUNT + 1))
            and all(
                POSITION_WARP_MINIMUM
                <= destination[axis]
                < COORD_UPPER_BOUND
                for destination in POSITION_WARP_DESTINATIONS
                for axis in ("x", "y", "z")
            )
            and len(
                {
                    (item["x"], item["y"], item["z"])
                    for item in POSITION_WARP_DESTINATIONS
                }
            )
            == POSITION_WARP_COUNT
            and all(
                item[axis]
                == deterministic_position_component(item["code"], axis)
                for item in POSITION_WARP_DESTINATIONS
                for axis in ("x", "y", "z")
            )
            and all(
                any(
                    lower <= item[axis] < upper
                    for item in POSITION_WARP_DESTINATIONS
                    for axis in ("x", "y", "z")
                )
                for lower, upper in POSITION_WARP_MAGNITUDE_STRATA
            )
            and use_policy_is_valid(POSITION_WARP_DESTINATIONS)
        ),
        "time_catalog_exact_and_bounded": (
            len(TIME_WARP_DESTINATIONS) == TIME_WARP_COUNT
            and [item["code"] for item in TIME_WARP_DESTINATIONS]
            == list(range(1, TIME_WARP_COUNT + 1))
            and all(
                0 <= item["epoch"] < EPOCH_UPPER_BOUND
                for item in TIME_WARP_DESTINATIONS
            )
            and [item["epoch"] for item in TIME_WARP_DESTINATIONS]
            == sorted({item["epoch"] for item in TIME_WARP_DESTINATIONS})
            and TIME_WARP_DESTINATIONS[0]["epoch"] == 101
            and TIME_WARP_DESTINATIONS[-1]["epoch"]
            == EPOCH_UPPER_BOUND - 1
            and use_policy_is_valid(TIME_WARP_DESTINATIONS)
        ),
        "explicit_action_identity_mapping_exact": (
            all(
                by_name[name].get("selection_mode")
                == EXPLICIT_SELECTION_MODE
                and by_name[name].get("warp_catalog") == "v1.position"
                and by_name[name].get("destination_code")
                == destination["code"]
                and by_name[name].get("uses") == destination["uses"]
                and by_name[name].get("minimum_source_pool_inclusive")
                == destination["minimum_source_pool_inclusive"]
                and destination["minimum_source_pool_inclusive"]
                == v1_coordinate_pool_minimum(destination["uses"])
                for destination in POSITION_WARP_DESTINATIONS
                for name in [f"RevealWarpCoordinate{destination['slug']}"]
            )
            and all(
                by_name[name].get("selection_mode")
                == EXPLICIT_SELECTION_MODE
                and by_name[name].get("warp_catalog") == "v1.time"
                and by_name[name].get("destination_code")
                == destination["code"]
                and by_name[name].get("uses") == destination["uses"]
                and by_name[name].get("minimum_source_pool_inclusive")
                == destination["minimum_source_pool_inclusive"]
                and destination["minimum_source_pool_inclusive"]
                == v1_coordinate_pool_minimum(destination["uses"])
                for destination in TIME_WARP_DESTINATIONS
                for name in [f"RevealTimeCoordinate{destination['slug']}"]
            )
            and all(
                not {
                    "weight_bps",
                    "rarity_tier",
                    "lower_top_limb",
                    "upper_top_limb",
                    "lower_literal",
                    "upper_literal",
                }.intersection(destination)
                for destination in (
                    *POSITION_WARP_DESTINATIONS,
                    *TIME_WARP_DESTINATIONS,
                )
            )
        ),
        "position_capacity_literal_is_final_and_exact": all(
            rhai_whitespace_insensitive_contains(
                position_reveal_sources[
                    f"RevealWarpCoordinate{destination['slug']}"
                ],
                (
                    "reveal_p(action, c, "
                    f"{destination['code']}, {destination['x']}, "
                    f"{destination['y']}, {destination['z']}, "
                    f"{destination['uses']}, "
                    f"{destination['minimum_source_pool_inclusive'] - 1});"
                ),
            )
            for destination in POSITION_WARP_DESTINATIONS
        ),
        "time_capacity_literal_is_final_and_exact": all(
            rhai_whitespace_insensitive_contains(
                time_reveal_sources[
                    f"RevealTimeCoordinate{destination['slug']}"
                ],
                (
                    "reveal_t(action, c, "
                    f"{destination['code']}, {destination['epoch']}, "
                    f"{destination['uses']}, "
                    f"{destination['minimum_source_pool_inclusive'] - 1});"
                ),
            )
            for destination in TIME_WARP_DESTINATIONS
        ),
        "position_reusable_roles_and_source_exact": (
            action_object_roles(by_name["WarpToCoordinateReusable"])
            == [
                ("output", SHIP),
                ("input", SHIP),
                ("mutate", WARP_COORDINATE),
            ]
            and rhai_sources_equal(
                position_reusable,
                warp_to_coordinate_source(final_use=False),
            )
        ),
        "position_final_roles_and_source_exact": (
            action_object_roles(by_name["WarpToCoordinateFinal"])
            == [
                ("output", SHIP),
                ("input", SHIP),
                ("input", WARP_COORDINATE),
            ]
            and rhai_sources_equal(
                position_final,
                warp_to_coordinate_source(final_use=True),
            )
        ),
        "time_reusable_roles_and_source_exact": (
            action_object_roles(by_name["TimeWarpToCoordinateReusable"])
            == [
                ("output", SHIP),
                ("input", SHIP),
                ("mutate", TIME_COORDINATE),
            ]
            and rhai_sources_equal(
                time_reusable,
                warp_to_coordinate_source(
                    final_use=False,
                    time_only=True,
                ),
            )
        ),
        "time_final_roles_and_source_exact": (
            action_object_roles(by_name["TimeWarpToCoordinateFinal"])
            == [
                ("output", SHIP),
                ("input", SHIP),
                ("input", TIME_COORDINATE),
            ]
            and rhai_sources_equal(
                time_final,
                warp_to_coordinate_source(final_use=True, time_only=True),
            )
        ),
        "position_warp_changes_only_xyz": all(
            (
                "warp_ship_core(action, next_ship, ship, "
                "coordinate.destination_x, coordinate.destination_y, "
                "coordinate.destination_z, ship.epoch);"
            )
            in source
            and "coordinate.destination_epoch" not in source
            for source in (position_reusable, position_final)
        ),
        "time_warp_changes_only_epoch": all(
            (
                "warp_ship_core(action, next_ship, ship, ship.x, ship.y, "
                "ship.z, coordinate.destination_epoch);"
            )
            in source
            and all(
                f"coordinate.destination_{axis}" not in source
                for axis in ("x", "y", "z")
            )
            for source in (time_reusable, time_final)
        ),
        "final_consumes_and_reusable_decrements": all(
            'coordinate.update("uses_remaining", next_uses);' in reusable
            and 'coordinate.update("uses_remaining", next_uses);' not in final
            and "action.st_sum(coordinate.uses_remaining, 0, 1);" in final
            for reusable, final in (
                (position_reusable, position_final),
                (time_reusable, time_final),
            )
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "checks": checks,
    }


CONSTRUCTOR_COPY_SPECS: dict[str, dict[str, Any]] = {
    "ConstructWormholeLink": {
        "target": "link",
        "target_class": WORMHOLE_LINK,
        "skill_code": 59,
        "roles": (
            ("output", WORMHOLE_LINK),
            ("input", POSITION_ANCHOR),
            ("input", POSITION_ANCHOR),
            ("input", RESOURCE),
            ("input", RESOURCE),
            ("mutate", SHIP),
        ),
        "set_fields": (
            "schema_version",
            "mechanics_version",
            "universe_version",
            "link_version",
            "endpoint_a_anchor_identifier",
            "endpoint_a_x",
            "endpoint_a_y",
            "endpoint_a_z",
            "endpoint_b_anchor_identifier",
            "endpoint_b_x",
            "endpoint_b_y",
            "endpoint_b_z",
            "uses_remaining",
        ),
        "anchors": (
            (
                "anchor_a",
                "endpoint_a_anchor_identifier",
                (("x", "endpoint_a_x"), ("y", "endpoint_a_y"), ("z", "endpoint_a_z")),
            ),
            (
                "anchor_b",
                "endpoint_b_anchor_identifier",
                (("x", "endpoint_b_x"), ("y", "endpoint_b_y"), ("z", "endpoint_b_z")),
            ),
        ),
    },
    "ConstructTemporalLink": {
        "target": "link",
        "target_class": TEMPORAL_LINK,
        "skill_code": 60,
        "roles": (
            ("output", TEMPORAL_LINK),
            ("input", TIME_ANCHOR),
            ("input", TIME_ANCHOR),
            ("input", RESOURCE),
            ("input", RESOURCE),
            ("mutate", SHIP),
        ),
        "set_fields": (
            "schema_version",
            "mechanics_version",
            "universe_version",
            "link_version",
            "endpoint_a_anchor_identifier",
            "endpoint_a_epoch",
            "endpoint_b_anchor_identifier",
            "endpoint_b_epoch",
            "uses_remaining",
        ),
        "anchors": (
            ("anchor_a", "endpoint_a_anchor_identifier", (("epoch", "endpoint_a_epoch"),)),
            ("anchor_b", "endpoint_b_anchor_identifier", (("epoch", "endpoint_b_epoch"),)),
        ),
    },
    "ComposeRendezvousCoordinate": {
        "target": "coordinate",
        "target_class": RENDEZVOUS_COORDINATE,
        "skill_code": 86,
        "roles": (
            ("output", RENDEZVOUS_COORDINATE),
            ("input", POSITION_ANCHOR),
            ("input", TIME_ANCHOR),
            ("input", RESOURCE),
            ("input", RESOURCE),
            ("mutate", SHIP),
        ),
        "set_fields": (
            "schema_version",
            "mechanics_version",
            "universe_version",
            "coordinate_version",
            "position_anchor_identifier",
            "destination_x",
            "destination_y",
            "destination_z",
            "time_anchor_identifier",
            "destination_epoch",
            "uses_remaining",
        ),
        "anchors": (
            (
                "position_anchor",
                "position_anchor_identifier",
                (("x", "destination_x"), ("y", "destination_y"), ("z", "destination_z")),
            ),
            ("time_anchor", "time_anchor_identifier", (("epoch", "destination_epoch"),)),
        ),
    },
}


def ordered_rhai_tokens(source: str, tokens: Sequence[str]) -> bool:
    """Return true when semantic token snippets occur once in required order."""
    compact = minify_rhai_source_tokens(source)
    cursor = 0
    for token in tokens:
        needle = minify_rhai_source_tokens(token).strip()
        position = compact.find(needle, cursor)
        if not needle or position < 0:
            return False
        cursor = position + len(needle)
    return True


def constructor_witness_copy_audit(
    source: str,
    spec: Mapping[str, Any],
) -> dict[str, bool]:
    """Audit the rc.43-safe placeholder-set plus witnessed-update shape."""
    target = str(spec["target"])
    target_class = str(spec["target_class"])
    skill_code = int(spec["skill_code"])
    anchors = spec["anchors"]
    copied_fields = [
        (anchor, source_field, target_field)
        for anchor, _identifier_field, numeric_fields in anchors
        for source_field, target_field in numeric_fields
    ]
    identifier_fields = [
        (anchor, identifier_field)
        for anchor, identifier_field, _numeric_fields in anchors
    ]
    set_calls = [
        arguments
        for handle, _method, arguments, _position
        in rhai_method_statement_calls(source, "set")
        if handle == target
    ]
    set_body = set_calls[0][0] if len(set_calls) == 1 and len(set_calls[0]) == 1 else ""
    update_pairs = object_update_pairs(source, target)
    expected_updates = [
        (target_field, target_field)
        for _anchor, _source_field, target_field in copied_fields
    ]
    # Identifier copies are deliberately last within each contiguous anchor
    # block, rather than collected after both anchors.
    expected_updates = []
    for _anchor, identifier_field, numeric_fields in anchors:
        expected_updates.extend((target_field, target_field) for _field, target_field in numeric_fields)
        expected_updates.append((identifier_field, identifier_field))
    expected_updates.append(("work", "work"))

    ordered_tokens: list[str] = [
        f'var {target} = action.output("{target_class}");',
        "let placeholder_identifier = action.top_limb_u256(0);",
        f"{target}.set([",
    ]
    for anchor, identifier_field, numeric_fields in anchors:
        ordered_tokens.extend(
            (
                f"var {anchor} = action.input(",
                f'prove_object_version_core(action, {anchor}, "anchor_version");',
                f"action.st_sum({anchor}.uses_remaining, 0, 1);",
            )
        )
        for source_field, target_field in numeric_fields:
            ordered_tokens.extend(
                (
                    f"var {target_field} = unsafe {{ {anchor}.{source_field} - 0 }};",
                    f"action.st_sum({anchor}.{source_field}, 0, {target_field});",
                    f'{target}.update("{target_field}", {target_field});',
                )
            )
        ordered_tokens.extend(
            (
                f"var {identifier_field} = action.random();",
                f"var_assign({identifier_field}, {anchor}.stable_identifier);",
                f'{anchor}.update("stable_identifier", {identifier_field});',
                f'{target}.update("{identifier_field}", {identifier_field});',
            )
        )
    ordered_tokens.extend(
        (
            'var material_1 = action.input("MicroverseResource");',
            "prove_resource_stack_core(action, material_1,",
            'var material_2 = action.input("MicroverseResource");',
            "prove_resource_stack_core(action, material_2,",
            f"var work = action.intro_vdf(32, {target});",
            f'{target}.update("work", work);',
            f'var ship = action.mutate("{SHIP}");',
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

    anchors_untouched_after_export = True
    for anchor, identifier_field in identifier_fields:
        final_export = minify_rhai_source_tokens(
            f'{target}.update("{identifier_field}", {identifier_field});'
        ).strip()
        compact = minify_rhai_source_tokens(source)
        position = compact.find(final_export)
        if position < 0 or f"{anchor}." in compact[position + len(final_export):]:
            anchors_untouched_after_export = False

    input_handles = [anchor for anchor, _identifier, _numeric in anchors]
    direct_input_output_values = any(
        f"{handle}." in set_body
        or any(f"{handle}." in value for _field, value in update_pairs)
        for handle in input_handles
    )
    compact = minify_rhai_source_tokens(source)
    final_identifier_field = identifier_fields[-1][1]
    final_semantic_update = minify_rhai_source_tokens(
        f'{target}.update("{final_identifier_field}", {final_identifier_field});'
    ).strip()
    vdf_call = minify_rhai_source_tokens(
        f"var work = action.intro_vdf(32, {target});"
    ).strip()
    work_update = minify_rhai_source_tokens(
        f'{target}.update("work", work);'
    ).strip()
    ship_declaration = minify_rhai_source_tokens(
        f'var ship = action.mutate("{SHIP}");'
    ).strip()
    lifecycle_positions = [
        compact.find(token)
        for token in (
            final_semantic_update,
            vdf_call,
            work_update,
            ship_declaration,
        )
    ]
    ship_updates = object_update_pairs(source, "ship")
    return {
        "action_roles_target_anchors_materials_ship_mutate": (
            source_action_object_roles(source) == list(spec["roles"])
        ),
        "single_complete_placeholder_set": (
            len(set_calls) == 1
            and object_set_fields(source, target) == list(spec["set_fields"])
            and source.count(
                "let placeholder_identifier = action.top_limb_u256(0);"
            )
            == 1
            and all(
                rhai_contains(
                    set_body,
                    f'["{identifier_field}", placeholder_identifier]',
                )
                for _anchor, identifier_field in identifier_fields
            )
            and all(
                rhai_contains(set_body, f'["{target_field}", 0]')
                for _anchor, _source_field, target_field in copied_fields
            )
        ),
        "witnessed_updates_exact": update_pairs == expected_updates,
        "anchor_blocks_contiguous_and_ordered": ordered_rhai_tokens(
            source, ordered_tokens
        ),
        "anchors_untouched_after_identifier_export": anchors_untouched_after_export,
        "vdf_after_final_semantic_update_before_ship_mutation": (
            all(position >= 0 for position in lifecycle_positions)
            and lifecycle_positions == sorted(lifecycle_positions)
            and source.count(f"action.intro_vdf(32, {target})") == 1
        ),
        "ship_mutate_lifecycle_exact": (
            source.count(f'action.mutate("{SHIP}")') == 1
            and f'action.input("{SHIP}")' not in source
            and f'action.output("{SHIP}")' not in source
            and "consume_prepared_ship_core(" not in source
            and object_set_fields(source, "ship") == []
            and ship_updates
            == [
                ("active_skill_type", "0"),
                ("action_serial", "next_action_serial"),
            ]
            and 'ship.update("stable_identifier"' not in source
            and source.count("var next_constructor_ship_key = action.random();") == 1
            and source.count("rotate_key(ship, next_constructor_ship_key);") == 1
        ),
        "no_direct_input_entries_in_output_mutation": not direct_input_output_values,
    }


def warp_v2_catalog_audit(
    plugin: str,
    actions: list[dict[str, Any]],
) -> dict[str, Any]:
    """Audit the 405 additive v2 warp actions and seven schemas."""
    by_name = {action["name"]: action for action in actions}
    expected_sources: dict[str, str] = {
        "ExtractWormholeWarpChart": extract_v2_chart_source(time_only=False),
        "ExtractWormholeEpochChart": extract_v2_chart_source(time_only=True),
        "WarpShipToPositionCoordinateReusable": v2_chart_transit_source(
            final_use=False, time_only=False
        ),
        "WarpShipToPositionCoordinateFinal": v2_chart_transit_source(
            final_use=True, time_only=False
        ),
        "WarpShipToEpochCoordinateReusable": v2_chart_transit_source(
            final_use=False, time_only=True
        ),
        "WarpShipToEpochCoordinateFinal": v2_chart_transit_source(
            final_use=True, time_only=True
        ),
        "CapturePositionAnchor": capture_anchor_source(time_only=False),
        "CaptureTimeAnchor": capture_anchor_source(time_only=True),
        "ConstructWormholeLink": construct_link_source(time_only=False),
        "ConstructTemporalLink": construct_link_source(time_only=True),
        "ComposeRendezvousCoordinate": compose_rendezvous_source(),
        "WarpToRendezvousCoordinateReusable": rendezvous_transit_source(
            final_use=False
        ),
        "WarpToRendezvousCoordinateFinal": rendezvous_transit_source(
            final_use=True
        ),
    }
    for destination in POSITION_CHART_DESTINATIONS:
        expected_sources[destination["reveal_action"]] = reveal_v2_chart_source(
            destination, time_only=False
        )
    for destination in EPOCH_CHART_DESTINATIONS:
        expected_sources[destination["reveal_action"]] = reveal_v2_chart_source(
            destination, time_only=True
        )
    for time_only, kind in ((False, "Wormhole"), (True, "Temporal")):
        for a_to_b, direction in ((True, "AToB"), (False, "BToA")):
            for final_use in (False, True):
                name = (
                    f"Traverse{kind}{direction}"
                    + ("Final" if final_use else "Reusable")
                )
                expected_sources[name] = traverse_link_source(
                    time_only=time_only,
                    a_to_b=a_to_b,
                    final_use=final_use,
                )
    v2_actions = [
        action for action in actions if action.get("warp_catalog", "").startswith("v2")
    ]
    reveal_position_names = {
        destination["reveal_action"] for destination in POSITION_CHART_DESTINATIONS
    }
    reveal_epoch_names = {
        destination["reveal_action"] for destination in EPOCH_CHART_DESTINATIONS
    }
    reveal_p_core = named_function_source(plugin, "reveal_chart_p")
    reveal_t_core = named_function_source(plugin, "reveal_chart_t")
    extract_core = named_function_source(plugin, "extract_v2_chart_core")
    bind_ship_id_core = named_function_source(plugin, "bind_ship_id")
    prepared_ship_core = named_function_source(
        plugin, "consume_prepared_ship_core"
    )
    position_anchor_capture = action_function_source(
        plugin, "CapturePositionAnchor"
    )
    time_anchor_capture = action_function_source(plugin, "CaptureTimeAnchor")
    reusable_core = named_function_source(plugin, "consume_reusable_use_core")
    final_core = named_function_source(plugin, "consume_final_use_core")
    wormhole_constructor = action_function_source(
        plugin, "ConstructWormholeLink"
    )
    temporal_constructor = action_function_source(
        plugin, "ConstructTemporalLink"
    )
    rendezvous_constructor = action_function_source(
        plugin, "ComposeRendezvousCoordinate"
    )
    position_chart_extractor = action_function_source(
        plugin, "ExtractWormholeWarpChart"
    )
    epoch_chart_extractor = action_function_source(
        plugin, "ExtractWormholeEpochChart"
    )
    constructor_copy_audits = {
        name: constructor_witness_copy_audit(
            action_function_source(plugin, name),
            spec,
        )
        for name, spec in CONSTRUCTOR_COPY_SPECS.items()
    }
    checks = {
        "action_count_exact": (
            len(v2_actions) == 405
            and len(expected_sources) == 405
            and {action["name"] for action in v2_actions} == set(expected_sources)
        ),
        "all_sources_exact": all(
            rhai_sources_equal(action_function_source(plugin, name), source)
            for name, source in expected_sources.items()
        ),
        "all_roles_exact": all(
            source_action_object_roles(
                action_function_source(plugin, action["name"])
            )
            == action_object_roles(action)
            for action in v2_actions
        ),
        "position_and_epoch_reveal_counts_exact": (
            len(reveal_position_names) == 256
            and len(reveal_epoch_names) == 128
            and reveal_position_names.isdisjoint(reveal_epoch_names)
        ),
        "shared_helpers_present_once": all(
            rhai_function_definition_count(plugin, name) == 1
            for name in (
                "prove_object_version_core",
                "consume_reusable_use_core",
                "consume_final_use_core",
                "extract_v2_chart_core",
                "reveal_chart_p",
                "reveal_chart_t",
            )
        ),
        "chart_extraction_exact": all(
            token in extract_core
            for token in (
                "action.st_sum(ship.extraction_amount, 0, extraction_amount);",
                (
                    "action.st_sum(ship.rare_extraction_amount, 0, "
                    "rare_extraction_amount);"
                ),
                "action.st_sum(body.candidate_code, 0, 22);",
                "action.st_sum(body.body_type, 0, 7);",
                f"body.energy_remaining - {WARP_ENERGY_COST}",
                f"action.st_sum(next_energy, {WARP_ENERGY_COST}, "
                "body.energy_remaining);",
            )
        ),
        "chart_capacity_witness_copies_preserved": (
            capacity_witness_copy_is_exact(extract_core)
        ),
        "chart_outputs_have_one_complete_grouped_set": (
            "chart.set(" not in extract_core
            and position_chart_extractor.count("chart.set(") == 1
            and epoch_chart_extractor.count("chart.set(") == 1
            and
            object_set_fields(position_chart_extractor, "chart")
            == [
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
            ]
            and object_set_fields(epoch_chart_extractor, "chart")
            == [
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
            ]
            and not any(
                field.startswith("destination_")
                for source in (
                    position_chart_extractor,
                    epoch_chart_extractor,
                )
                for field, _value in object_update_pairs(source, "chart")
            )
            and all(
                token in source
                for source in (
                    position_chart_extractor,
                    epoch_chart_extractor,
                )
                for token in (
                    "var source_body_identifier = action.random();",
                    "var_assign(source_body_identifier, body.stable_identifier);",
                    'body.update("stable_identifier", source_body_identifier);',
                    "var source_pool_before = unsafe { body.energy_remaining - 0 };",
                    "action.st_sum(body.energy_remaining, 0, source_pool_before);",
                    '["source_body_identifier", source_body_identifier]',
                    '["source_pool_before", source_pool_before]',
                )
            )
            and all(
                token not in extract_core
                for token in (
                    "source_body_identifier",
                    "source_pool_before",
                    'body.update("stable_identifier"',
                )
            )
        ),
        "reveal_explicit_action_identity_constraints_exact": all(
            (
                "prove_object_version_core(action, chart, \"catalog_version\");"
                in source
                and "action.intro_vdf(20, chart);" in source
                and rhai_whitespace_insensitive_contains(
                    source,
                    "action.st_gt(chart.source_pool_before, "
                    "minimum_source_pool_exclusive);",
                )
                and all(
                    token not in source
                    for token in (
                        ".stable_identifier",
                        "top_limb_u256",
                        "intro_lt_eq_u256",
                        "selector",
                    )
                )
                and source.count("action.st_gt(") == 1
                and not rhai_call_uses_indexed_field(
                    source, "action.st_sum", "source_pool_maximum"
                )
            )
            for source in (reveal_p_core, reveal_t_core)
        ),
        "reveal_action_metadata_and_catalog_rows_exact": all(
            by_name[destination["reveal_action"]].get("selection_mode")
            == EXPLICIT_SELECTION_MODE
            and by_name[destination["reveal_action"]].get("warp_catalog")
            == catalog_name
            and by_name[destination["reveal_action"]].get(
                "destination_code"
            )
            == destination["code"]
            and by_name[destination["reveal_action"]].get("uses")
            == destination["uses"]
            and by_name[destination["reveal_action"]].get(
                "minimum_source_pool_inclusive"
            )
            == destination["minimum_source_pool_inclusive"]
            and destination["minimum_source_pool_inclusive"]
            == v2_chart_pool_minimum(destination["uses"])
            and not {
                "weight_bps",
                "rarity_tier",
                "lower_top_limb",
                "upper_top_limb",
                "lower_literal",
                "upper_literal",
            }.intersection(destination)
            for catalog_name, destinations in (
                ("v2.position", POSITION_CHART_DESTINATIONS),
                ("v2.time", EPOCH_CHART_DESTINATIONS),
            )
            for destination in destinations
        ),
        "reveal_capacity_literal_is_final_and_exact": all(
            rhai_whitespace_insensitive_contains(
                action_function_source(
                    plugin, destination["reveal_action"]
                ),
                (
                    (
                        "reveal_chart_t(action, n, s, c, "
                        f"{destination['code']}, {destination['epoch']}, "
                        f"{destination['uses']}, "
                        f"{destination['minimum_source_pool_inclusive'] - 1});"
                    )
                    if catalog_name == "v2.time"
                    else (
                        "reveal_chart_p(action, n, s, c, "
                        f"{destination['code']}, {destination['x']}, "
                        f"{destination['y']}, {destination['z']}, "
                        f"{destination['uses']}, "
                        f"{destination['minimum_source_pool_inclusive'] - 1});"
                    )
                ),
            )
            for catalog_name, destinations in (
                ("v2.position", POSITION_CHART_DESTINATIONS),
                ("v2.time", EPOCH_CHART_DESTINATIONS),
            )
            for destination in destinations
        ),
        "position_reveal_updates_xyz_only": (
            object_update_pairs(reveal_p_core, "chart")
            == [
                ("revealed", "1"),
                ("destination_code", "code"),
                ("destination_x", "x"),
                ("destination_y", "y"),
                ("destination_z", "z"),
                ("uses_remaining", "uses"),
                ("work", "work"),
            ]
        ),
        "epoch_reveal_updates_epoch_only": (
            object_update_pairs(reveal_t_core, "chart")
            == [
                ("revealed", "1"),
                ("destination_code", "code"),
                ("destination_epoch", "epoch"),
                ("uses_remaining", "uses"),
                ("work", "work"),
            ]
        ),
        "reusable_and_final_use_exact": (
            "action.st_gt(object.uses_remaining, 1);" in reusable_core
            and 'object.update("uses_remaining", next_uses);' in reusable_core
            and "rotate_key(object, next_key);" in reusable_core
            and "action.st_sum(object.uses_remaining, 0, 1);" in final_core
            and "object.update" not in final_core
        ),
        "all_new_schemas_exact": all(
            class_name in SCHEMAS and len(SCHEMAS[class_name]) > 0
            for class_name in (
                WARP_CHART,
                EPOCH_CHART,
                POSITION_ANCHOR,
                TIME_ANCHOR,
                WORMHOLE_LINK,
                TEMPORAL_LINK,
                RENDEZVOUS_COORDINATE,
            )
        ),
        "all_nine_warp_schemas_exact": all(
            tuple(SCHEMAS.get(class_name, ())) == expected_schema
            for class_name, expected_schema
            in EXPECTED_WARP_OBJECT_SCHEMAS.items()
        ),
        "all_twenty_class_identifier_types_exact": (
            len(CLASS_ORDER) == 20
            and set(SCHEMAS) == set(CLASS_ORDER)
            and all(
                field_type == expected_schema_field_type(field_name)
                for class_name in CLASS_ORDER
                for field_name, field_type in SCHEMAS[class_name]
            )
        ),
        "anchor_source_ship_id_uses_raw_binding": (
            ordered_rhai_tokens(
                bind_ship_id_core,
                (
                    "var bound_ship_id = action.random();",
                    "var_assign(bound_ship_id, ship.ship_id);",
                    'ship.update("ship_id", bound_ship_id);',
                    "bound_ship_id",
                ),
            )
            and ordered_rhai_tokens(
                prepared_ship_core,
                (
                    "var ship_id = bind_ship_id(action, ship);",
                    "action.st_sum(ship.active_skill_type, 0, required_skill_type);",
                    "ship_id",
                ),
            )
            and all(
                source.count(
                    "var source_ship_id = consume_prepared_ship_core("
                ) == 1
                and source.count(
                    '["source_ship_id", source_ship_id]'
                ) == 1
                and "unsafe { source_ship_id" not in source
                and "st_sum(source_ship_id" not in source
                for source in (position_anchor_capture, time_anchor_capture)
            )
        ),
        "self_link_policy_sdk_compliant": all(
            token not in plugin for token in ("!=", "intro_or", "free_witness")
        ),
        "constructors_use_shape_j_witnessed_ship_mutation": all(
            all(audit.values()) for audit in constructor_copy_audits.values()
        ),
        "constructor_anchor_groups_contiguous": (
            object_set_fields(wormhole_constructor, "link")
            == [
                "schema_version",
                "mechanics_version",
                "universe_version",
                "link_version",
                "endpoint_a_anchor_identifier",
                "endpoint_a_x",
                "endpoint_a_y",
                "endpoint_a_z",
                "endpoint_b_anchor_identifier",
                "endpoint_b_x",
                "endpoint_b_y",
                "endpoint_b_z",
                "uses_remaining",
            ]
            and object_set_fields(temporal_constructor, "link")
            == [
                "schema_version",
                "mechanics_version",
                "universe_version",
                "link_version",
                "endpoint_a_anchor_identifier",
                "endpoint_a_epoch",
                "endpoint_b_anchor_identifier",
                "endpoint_b_epoch",
                "uses_remaining",
            ]
            and object_set_fields(rendezvous_constructor, "coordinate")
            == [
                "schema_version",
                "mechanics_version",
                "universe_version",
                "coordinate_version",
                "position_anchor_identifier",
                "destination_x",
                "destination_y",
                "destination_z",
                "time_anchor_identifier",
                "destination_epoch",
                "uses_remaining",
            ]
        ),
        "constructors_ban_direct_anchor_values_in_output_mutations": all(
            audit["no_direct_input_entries_in_output_mutation"]
            for audit in constructor_copy_audits.values()
        ),
        "warp_family_total_exact": (
            211
            + 6
            + len(v2_actions)
            == 622
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "checks": checks,
        "counts": {
            "v2_actions": len(v2_actions),
            "v2_position_reveals": len(reveal_position_names),
            "v2_epoch_reveals": len(reveal_epoch_names),
            "new_classes": 7,
        },
        "constructor_copy_audits": constructor_copy_audits,
    }


def component_catalog_audit(
    plugin: str,
    actions: list[dict[str, Any]],
) -> dict[str, Any]:
    by_name = {action["name"]: action for action in actions}
    prepared_ship_core = named_function_source(
        plugin, "consume_prepared_ship_core"
    )
    component_core = named_function_source(plugin, "fabricate_component_core")
    reusable_core = named_function_source(
        plugin, "consume_component_catalyst_reusable_core"
    )
    final_core = named_function_source(
        plugin, "consume_component_catalyst_final_core"
    )
    core_checks = {
        "helpers_present_once": all(
            rhai_function_definition_count(plugin, name) == 1
            for name in (
                "consume_prepared_ship_core",
                "fabricate_component_core",
                "consume_component_catalyst_reusable_core",
                "consume_component_catalyst_final_core",
            )
        ),
        "helpers_declare_no_action_roles": all(
            not source_action_object_roles(source)
            for source in (
                prepared_ship_core,
                component_core,
                reusable_core,
                final_core,
            )
        ),
        "replacement_ship_fields_exact": (
            object_set_fields(prepared_ship_core, "next_ship")
            == list(SHIP_SEMANTIC_FIELDS)
        ),
        "component_output_fields_exact": (
            object_set_fields(component_core, "component")
            == [
                "schema_version",
                "mechanics_version",
                "universe_version",
                "resource_type",
                "amount",
            ]
        ),
        "skill_and_recipe_gates_present": all(
            token in prepared_ship_core
            for token in (
                "action.st_sum(ship.active_skill_type, 0, required_skill_type);",
            )
        ) and all(
            token in component_core
            for token in (
                "consume_prepared_ship_core(action, next_ship, ship, skill_type);",
                "action.st_sum(material_1.resource_type, 0, material_1_type);",
                "action.st_sum(material_1.amount, 0, material_1_amount);",
                "action.st_sum(material_2.resource_type, 0, material_2_type);",
                "action.st_sum(material_2.amount, 0, material_2_amount);",
                "action.st_sum(material_3.resource_type, 0, material_3_type);",
                "action.st_sum(material_3.amount, 0, material_3_amount);",
                "action.st_sum(catalyst.resource_type, 0, catalyst_type);",
            )
        ),
        "reusable_decrements_and_rotates": all(
            token in reusable_core
            for token in (
                "action.st_gt(catalyst.amount, 1);",
                "catalyst.amount - 1",
                "action.st_sum(next_catalyst_amount, 1, catalyst.amount);",
                'catalyst.update("amount", next_catalyst_amount);',
                "rotate_key(catalyst, next_catalyst_key);",
            )
        ),
        "final_requires_exactly_one": (
            "action.st_sum(catalyst.amount, 0, 1);" in final_core
            and "catalyst.update" not in final_core
            and "rotate_key" not in final_core
        ),
    }
    details: dict[str, Any] = {}
    for component in COMPONENT_RECIPES:
        for final_use in (False, True):
            mode = "final" if final_use else "reusable"
            name = component["actions"][mode]
            source = action_function_source(plugin, name)
            semantic_source = phase5_wrapper_semantic_source(plugin, name)
            expected_roles = [
                ("output", SHIP),
                ("output", RESOURCE),
                ("input", SHIP),
                ("input", RESOURCE),
                ("input", RESOURCE),
                ("input", RESOURCE),
                (("input" if final_use else "mutate"), RESOURCE),
            ]
            action = by_name.get(name)
            checks = {
                "manifest_action_present": action is not None,
                "roles_exact": (
                    action is not None
                    and action_object_roles(action) == expected_roles
                    and source_action_object_roles(source) == expected_roles
                ),
                "source_exact": (
                    rhai_sources_equal(
                        source,
                        fabricate_component_source(
                            component, final_use=final_use
                        ),
                    )
                ),
                "metadata_exact": (
                    action is not None
                    and action.get("family") == "fabricate_component"
                    and action.get("skill_code") == component["skill_code"]
                    and action.get("resource_code") == component["code"]
                    and action.get("component_code") == component["code"]
                    and action.get("catalyst_mode") == mode
                ),
                "vdf_exact": (
                    rhai_contains(
                        semantic_source,
                        f"{component['vdf_iterations']}, "
                        f"{'component' if phase5_helper_for(name) is not None else 'c'}",
                    )
                ),
                "mode_helper_exact": (
                    rhai_contains(
                        semantic_source,
                        "consume_component_catalyst_final_core(action, "
                        f"{'catalyst' if phase5_helper_for(name) is not None else 'k'});"
                        if final_use
                        else "consume_component_catalyst_reusable_core(action, "
                        f"{'catalyst' if phase5_helper_for(name) is not None else 'k'});"
                    )
                ),
                "compact_wrapper_locals_exact": (
                    all(
                        rhai_contains(source, token)
                        for token in (
                            f'var n = action.output("{SHIP}");',
                            f'var c = action.output("{RESOURCE}");',
                            f'var s = action.input("{SHIP}");',
                            f'var a = action.input("{RESOURCE}");',
                            f'var b = action.input("{RESOURCE}");',
                            f'var d = action.input("{RESOURCE}");',
                            f'var k = action.{"input" if final_use else "mutate"}'
                            f'("{RESOURCE}");',
                        )
                    )
                    and (
                        rhai_contains(source, phase5_helper_for(name))
                        if phase5_helper_for(name) is not None
                        else all(
                            rhai_contains(source, token)
                            for token in (
                                "fabricate_component_core(",
                                "var w = action.intro_vdf(",
                                'c.update("work", w);',
                            )
                        )
                    )
                    and not any(
                        re.search(rf"\bvar\s+{re.escape(local)}\s*=", source)
                        for local in (
                            "next_ship",
                            "component",
                            "ship",
                            "material_1",
                            "material_2",
                            "material_3",
                            "catalyst",
                            "component_work",
                        )
                    )
                ),
            }
            details[name] = {
                "status": "pass" if all(checks.values()) else "fail",
                "checks": checks,
            }
    checks = {
        **core_checks,
        "component_action_count_exact": (
            sum(
                action["family"] == "fabricate_component"
                for action in actions
            )
            == 2 * len(COMPONENT_RECIPES)
        ),
        "all_component_actions_pass": all(
            detail["status"] == "pass" for detail in details.values()
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "checks": checks,
        "details": details,
    }


def skill_catalog_audit(
    plugin: str,
    actions: list[dict[str, Any]],
) -> dict[str, Any]:
    """Audit every fixed derived-skill and capability-artifact wrapper."""
    by_name = {action["name"]: action for action in actions}
    prepared_core = named_function_source(plugin, "consume_prepared_ship_core")
    stack_core = named_function_source(plugin, "prove_resource_stack_core")
    skill_core = named_function_source(plugin, "develop_derived_skill_core")
    artifact_core = named_function_source(
        plugin, "produce_capability_artifact_core"
    )
    helper_sources = (prepared_core, stack_core, skill_core, artifact_core)
    details: dict[str, Any] = {}

    def expected_stack_call(
        action_name: str,
        evidence_index: int,
        item: dict[str, Any],
    ) -> str:
        if phase5_helper_for(action_name) is not None:
            resource_type = f"evidence_{evidence_index}_type"
            amount = f"evidence_{evidence_index}_amount"
        else:
            resource_type = str(item["resource_code"])
            amount = str(item["amount"])
        return (
            f"prove_resource_stack_core(action, evidence_{evidence_index}, "
            f"{resource_type}, {amount});"
        )

    for skill in DERIVED_SKILLS:
        name = skill["action"]
        action = by_name.get(name)
        source = action_function_source(plugin, name)
        semantic_source = phase5_wrapper_semantic_source(plugin, name)
        expected_roles = [
            ("output", SHIP),
            ("output", TECHNOLOGY_SKILL),
            ("input", SHIP),
            *[("input", RESOURCE) for _item in skill["items"]],
        ]
        calls = rhai_call_arguments(
            semantic_source, "develop_derived_skill_core"
        )
        call_arguments = calls[0] if len(calls) == 1 else []
        expected_call_arguments = (
            [
                "action", "next_ship", "technology_skill", "ship",
                "parent_skill_type", "output_skill_type",
            ]
            if phase5_helper_for(name) is not None
            else [
                "action", "next_ship", "technology_skill", "ship",
                str(skill["parent_code"]), str(skill["code"]),
            ]
        )
        checks = {
            "roles_exact": (
                action is not None
                and action_object_roles(action) == expected_roles
                and source_action_object_roles(source) == expected_roles
            ),
            "source_exact": (
                rhai_sources_equal(source, develop_derived_skill_source(skill))
            ),
            "metadata_exact": (
                action is not None
                and action.get("family") == "develop_derived_skill"
                and action.get("skill_code") == skill["parent_code"]
                and action.get("output_skill_code") == skill["code"]
                and action.get("skill_tier") == skill["tier"]
                and action.get("vdf_iterations") == skill["vdf_iterations"]
            ),
            "core_literals_exact": call_arguments == expected_call_arguments,
            "evidence_exact": all(
                rhai_contains(
                    semantic_source,
                    expected_stack_call(name, item["slot"], item),
                )
                for item in skill["items"]
            ),
            "vdf_exact": (
                rhai_contains(
                    semantic_source,
                    f"{skill['vdf_iterations']}, technology_skill",
                )
            ),
        }
        details[name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
        }
    for capability in SKILL_CAPABILITIES:
        name = capability["action"]
        action = by_name.get(name)
        source = action_function_source(plugin, name)
        semantic_source = phase5_wrapper_semantic_source(plugin, name)
        expected_roles = [
            ("output", SHIP),
            ("output", RESOURCE),
            ("input", SHIP),
            *[("input", RESOURCE) for _item in capability["fixed_inputs"]],
        ]
        calls = rhai_call_arguments(
            semantic_source, "produce_capability_artifact_core"
        )
        call_arguments = calls[0] if len(calls) == 1 else []
        expected_call_arguments = (
            [
                "action", "next_ship", "artifact", "ship",
                "required_skill_type", "output_resource_type", "output_amount",
            ]
            if phase5_helper_for(name) is not None
            else [
                "action", "next_ship", "artifact", "ship",
                str(capability["skill_code"]),
                str(capability["output_resource_code"]),
                str(capability["output_amount"]),
            ]
        )
        checks = {
            "roles_exact": (
                action is not None
                and action_object_roles(action) == expected_roles
                and source_action_object_roles(source) == expected_roles
            ),
            "source_exact": (
                rhai_sources_equal(
                    source, capability_artifact_source(capability)
                )
            ),
            "metadata_exact": (
                action is not None
                and action.get("family") == capability["action_family"]
                and action.get("skill_code") == capability["skill_code"]
                and action.get("resource_code")
                == capability["output_resource_code"]
                and action.get("route_key") == capability["route_key"]
                and action.get("vdf_iterations")
                == capability["vdf_iterations"]
            ),
            "output_literals_exact": (
                call_arguments == expected_call_arguments
            ),
            "evidence_exact": all(
                rhai_contains(
                    semantic_source,
                    expected_stack_call(name, index, item),
                )
                for index, item in enumerate(
                    capability["fixed_inputs"], start=1
                )
            ),
            "vdf_exact": (
                rhai_contains(
                    semantic_source,
                    f"{capability['vdf_iterations']}, artifact",
                )
            ),
        }
        details[name] = {
            "status": "pass" if all(checks.values()) else "fail",
            "checks": checks,
        }
    checks = {
        "helpers_present_once": all(
            rhai_function_definition_count(plugin, name) == 1
            for name in (
                "consume_prepared_ship_core",
                "prove_resource_stack_core",
                "develop_derived_skill_core",
                "produce_capability_artifact_core",
            )
        ),
        "helpers_declare_no_action_roles": all(
            not source_action_object_roles(source) for source in helper_sources
        ),
        "replacement_ship_fields_exact": (
            object_set_fields(prepared_core, "next_ship")
            == list(SHIP_SEMANTIC_FIELDS)
        ),
        "prepared_skill_gate_exact": (
            "action.st_sum(ship.active_skill_type, 0, required_skill_type);"
            in prepared_core
        ),
        "resource_stack_gate_exact": all(
            token in stack_core
            for token in (
                "prove_fixed_versions(action, resource);",
                "action.st_sum(resource.resource_type, 0, resource_type);",
                "action.st_sum(resource.amount, 0, amount);",
            )
        ),
        "derived_skill_fields_exact": (
            object_set_fields(skill_core, "technology_skill")
            == [
                "schema_version",
                "mechanics_version",
                "universe_version",
                "civilization_version",
                "skill_type",
                "reusable",
            ]
        ),
        "capability_artifact_fields_exact": (
            object_set_fields(artifact_core, "artifact")
            == [
                "schema_version",
                "mechanics_version",
                "universe_version",
                "resource_type",
                "amount",
            ]
        ),
        "derived_action_count_exact": (
            sum(
                action["family"] == "develop_derived_skill"
                for action in actions
            )
            == len(DERIVED_SKILLS)
        ),
        "capability_action_names_unique": (
            len({capability["action"] for capability in SKILL_CAPABILITIES})
            == len(SKILL_CAPABILITIES)
        ),
        "all_skill_catalog_actions_pass": all(
            detail["status"] == "pass" for detail in details.values()
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "checks": checks,
        "details": details,
    }


def deterministic_hierarchy_audit(
    plugin: str,
    actions: list[dict[str, Any]],
    bank: list[dict[str, Any]],
) -> dict[str, Any]:
    """Validate the PEXE-only immutable selector hierarchy."""
    actions_by_name = {action["name"]: action for action in actions}

    def partition_exact(
        ordered_rows: list[dict[str, Any]],
        bands: dict[Any, dict[str, int | None]],
        key: str,
    ) -> bool:
        ordered = [bands[row[key]] for row in ordered_rows]
        return bool(ordered) and all(
            (
                band["lower_top_limb"] is None
                if index == 0
                else band["lower_top_limb"]
                == ordered[index - 1]["upper_top_limb"] + 1
            )
            and (
                band["upper_top_limb"] is None
                if index == len(ordered) - 1
                else isinstance(band["upper_top_limb"], int)
            )
            for index, band in enumerate(ordered)
        )

    body_partitions_exact = all(
        partition_exact(
            sorted(
                [
                    row
                    for row in bank
                    if row["body_type"] == category["body_type"]
                ],
                key=lambda row: row["code"],
            ),
            body_selector_bands(bank),
            "code",
        )
        for category in CELESTIAL_CATEGORIES
        if any(
            row["body_type"] == category["body_type"] for row in bank
        )
    )
    resource_partitions_exact = all(
        partition_exact(
            sorted(rows, key=lambda row: row["code"]),
            resource_selector_bands(),
            "action",
        )
        for rows in (
            [
                resource
                for resource in CIVILIZATION_TECH_RESOURCES
                if (
                    resource["candidate_code"],
                    resource["skill_code"],
                    resource["remaining_field"],
                )
                == group
            ]
            for group in {
                (
                    resource["candidate_code"],
                    resource["skill_code"],
                    resource["remaining_field"],
                )
                for resource in CIVILIZATION_TECH_RESOURCES
            }
        )
    )
    survey_partition_exact = partition_exact(
        SURVEY_PROFILES, survey_selector_bands(), "code"
    )
    civilization_partition_exact = partition_exact(
        CIVILIZATION_TYPES, civilization_selector_bands(), "code"
    )
    skill_partitions_exact = all(
        partition_exact(
            [
                skill
                for skill in TECHNOLOGY_SKILLS
                if skill["civilization_type"] == civilization_type
            ],
            technology_skill_selector_bands(),
            "code",
        )
        for civilization_type in (1, 2, 3)
    )

    selector_specs: dict[str, tuple[str, str, str]] = {}
    selector_specs.update(
        {
            f"SurveySector_{row['code']:02d}_{row['slug']}": (
                "sector",
                "survey_selector",
                "survey_profile",
            )
            for row in SURVEY_PROFILES
        }
    )
    selector_specs.update(
        {
            f"ScanCelestialBody_{row['code']:02d}_{row['slug']}": (
                "signal",
                "body_selector",
                "body_candidate",
            )
            for row in bank
        }
    )
    selector_specs["DetectIntelligentLife"] = (
        "body.source_signal_identifier",
        "life_selector",
        "life_presence",
    )
    selector_specs.update(
        {
            row["action"]: (
                "life_signal",
                "civilization_selector",
                "civilization_type",
            )
            for row in CIVILIZATION_TYPES
        }
    )
    selector_specs.update(
        {
            row["action"]: (
                "civilization.source_life_signal_identifier",
                "skill_selector",
                "root_skill",
            )
            for row in TECHNOLOGY_SKILLS
        }
    )
    selector_specs.update(
        {
            action["name"]: (
                "body.source_signal_identifier",
                "resource_selector",
                "advanced_resource",
            )
            for action in actions
            if action["family"] == "extract_civilization_tech_resource"
        }
    )
    route_details: dict[str, Any] = {}
    for name, (selector, prefix, hierarchy_level) in selector_specs.items():
        action = actions_by_name[name]
        source = action_function_source(plugin, name)
        band = action["selector_band"]
        expected = selector_constraints_source(
            selector, band, prefix=prefix
        )
        intro_calls = [
            call
            for call in rhai_method_statement_calls(
                source, "intro_lt_eq_u256"
            )
            if call[0] == "action"
        ]
        expected_call_count = sum(
            band[field] is not None
            for field in ("lower_top_limb", "upper_top_limb")
        )
        route_checks = {
            "mode_exact": (
                action.get("selection_mode")
                == DETERMINISTIC_SELECTOR_MODE
            ),
            "selector_subject_exact": (
                action.get("selector_subject")
                in (selector, f"{selector}.stable_identifier")
            ),
            "constraints_exact": (
                not expected or rhai_contains(source, expected)
            ),
            "comparison_count_exact": (
                len(intro_calls) == expected_call_count
            ),
            "roles_unchanged": (
                source_action_object_roles(source)
                == action_object_roles(action)
            ),
        }
        route_details[name] = {
            "status": "pass" if all(route_checks.values()) else "fail",
            "hierarchy_level": hierarchy_level,
            "checks": route_checks,
        }

    detect_details: dict[str, Any] = {}
    for candidate in bank:
        name = (
            f"DetectCelestialSignal_{candidate['code']:02d}_"
            f"{candidate['slug']}"
        )
        source = action_function_source(plugin, name)
        calls = rhai_call_arguments(source, "detect_signal_core")
        category = celestial_category(candidate)
        detect_checks = {
            "one_core_call": len(calls) == 1,
            "category_only": (
                len(calls) == 1
                and calls[0][5] == str(category["code"])
                and calls[0][6] == str(UNRESOLVED_CANDIDATE_CODE)
            ),
            "no_selector_comparison": not rhai_method_statement_calls(
                source, "intro_lt_eq_u256"
            ),
        }
        detect_details[name] = {
            "status": "pass" if all(detect_checks.values()) else "fail",
            "checks": detect_checks,
        }

    scan_core = named_function_source(plugin, "scan_body_core")
    detect_life = action_function_source(plugin, "DetectIntelligentLife")
    life_band = intelligent_life_selector_band(bank)
    planet_bands = body_selector_bands(bank)
    intersecting_planet_codes = [
        row["code"]
        for row in bank
        if row["body_type"] == 1
        and (
            planet_bands[row["code"]]["upper_top_limb"] is None
            or life_band["lower_top_limb"] is None
            or planet_bands[row["code"]]["upper_top_limb"]
            >= life_band["lower_top_limb"]
        )
        and (
            life_band["upper_top_limb"] is None
            or planet_bands[row["code"]]["lower_top_limb"] is None
            or life_band["upper_top_limb"]
            >= planet_bands[row["code"]]["lower_top_limb"]
        )
    ]
    life_updates = object_update_pairs(detect_life, "body")
    scan_life_literals_exact = all(
        len(calls) == 1 and len(calls[0]) == 13 and calls[0][7] == "0"
        for candidate in bank
        for calls in [
            rhai_call_arguments(
                action_function_source(
                    plugin,
                    f"ScanCelestialBody_{candidate['code']:02d}_"
                    f"{candidate['slug']}",
                ),
                "scan_body_core",
            )
        ]
    )
    checks = {
        "survey_partition_exact": survey_partition_exact,
        "body_partitions_exact": body_partitions_exact,
        "civilization_partition_exact": civilization_partition_exact,
        "root_skill_partitions_exact": skill_partitions_exact,
        "advanced_resource_partitions_exact": resource_partitions_exact,
        "all_selector_routes_exact": all(
            detail["status"] == "pass"
            for detail in route_details.values()
        ),
        "all_detect_aliases_emit_generic_category_signals": all(
            detail["status"] == "pass"
            for detail in detect_details.values()
        ),
        "scan_core_requires_unresolved_signal": rhai_contains(
            scan_core,
            f"action.st_sum(signal.candidate_code,0,{UNRESOLVED_CANDIDATE_CODE});",
        ),
        "scan_core_owns_no_selector": not rhai_method_statement_calls(
            scan_core, "intro_lt_eq_u256"
        ),
        "life_stat_is_boolean": all(
            row["life_stat"] in (0, 1) for row in bank
        ),
        "all_scanned_bodies_start_without_life": all(
            row["life_stat"] == 0 for row in bank
        ) and scan_life_literals_exact,
        "life_band_intersects_only_ocean_and_garden": (
            intersecting_planet_codes
            == list(INTELLIGENT_LIFE_CANDIDATE_CODES)
        ),
        "life_action_metadata_exact": (
            actions_by_name["DetectIntelligentLife"].get(
                "selection_mode"
            ) == DETERMINISTIC_SELECTOR_MODE
            and actions_by_name["DetectIntelligentLife"].get(
                "selector_subject"
            ) == "body.source_signal_identifier"
            and actions_by_name["DetectIntelligentLife"].get(
                "selector_band"
            ) == life_band
            and actions_by_name["DetectIntelligentLife"].get(
                "candidate_codes"
            ) == list(INTELLIGENT_LIFE_CANDIDATE_CODES)
        ),
        "life_action_requires_zero_then_updates_one": (
            rhai_contains(
                detect_life, "action.st_sum(body.life_stat,0,0);"
            )
            and not rhai_contains(
                detect_life, "action.st_gt(body.life_stat,0);"
            )
            and life_updates.count(("life_stat", "1")) == 1
        ),
    }
    return {
        "status": "pass" if all(checks.values()) else "fail",
        "plugin_sha256": hashlib.sha256(plugin.encode("utf-8")).hexdigest(),
        "action_count": len(actions),
        "selection_mode": DETERMINISTIC_SELECTOR_MODE,
        "boundary_policy": {
            "overlap": False,
            "excluded_values_per_split": str(2**192 - 1),
            "maximum_excluded_probability_per_split": "less than 1 / 2^64",
        },
        "checks": checks,
        "route_count": len(route_details),
        "detect_alias_count": len(detect_details),
        "routes": route_details,
        "detect_aliases": detect_details,
    }


def validate_generated(root: Path) -> dict[str, Any]:
    manifest = (root / "manifest.toml").read_text(encoding="utf-8")
    plugin = (root / "plugin.rhai").read_text(encoding="utf-8")
    contract = json.loads((root / "generated" / "action-contract.json").read_text(encoding="utf-8"))
    refactor_report_path = root / "generated" / "refactor-census.json"
    refactor_report = (
        json.loads(refactor_report_path.read_text(encoding="utf-8"))
        if refactor_report_path.is_file()
        else None
    )
    universe_contract = json.loads(
        (root / "generated" / "universe-contract.json").read_text(
            encoding="utf-8"
        )
    )
    bank = json.loads(
        (root / "generated" / "body-bank.json").read_text(
            encoding="utf-8"
        )
    )["candidates"]
    manifest_actions = re.findall(r'^name = "([^"]+)"$', manifest, flags=re.MULTILINE)
    class_count = manifest.count("[[classes]]")
    manifest_action_names = manifest_actions[class_count + 1 :]
    function_names = rhai_action_function_names(plugin)
    expected_names = [action["name"] for action in contract["actions"]]
    actions_by_name = {
        action["name"]: action for action in contract["actions"]
    }
    expected_universe_survey_profiles = [
        {
            **profile,
            "survey_profile": profile["code"],
            "action": (
                f"SurveySector_{profile['code']:02d}_{profile['slug']}"
            ),
        }
        for profile in SURVEY_PROFILES
    ]
    selection_metadata_checks = {
        "universe_survey_profiles_exact": (
            universe_contract.get("survey_profiles")
            == expected_universe_survey_profiles
        ),
        "universe_civilization_types_exact": (
            universe_contract.get("civilization_types")
            == CIVILIZATION_TYPES
        ),
        "eight_counter_gates_exact": (
            len(EXPLICIT_COUNTER_GATES) == 8
            and set(EXPLICIT_COUNTER_GATES)
            == {
                row["action"]
                for row in expected_universe_survey_profiles
            }
            | {row["action"] for row in CIVILIZATION_TYPES}
        ),
        "action_contract_counter_gates_exact": all(
            name in actions_by_name
            and actions_by_name[name].get("selection_mode")
            == gate["selection_mode"]
            and actions_by_name[name].get(
                "survey_profile"
                if gate["selection_kind"] == "survey_profile"
                else "civilization_type"
            )
            == gate["selected_code"]
            and actions_by_name[name].get(
                "minimum_claim_serial"
                if gate["counter_field"] == "claim_serial"
                else "minimum_civilization_scan_serial"
            )
            == gate["minimum_inclusive"]
            for name, gate in EXPLICIT_COUNTER_GATES.items()
        ),
    }
    deterministic_classes = {
        SECTOR,
        SIGNAL,
        BODY,
        SATELLITE,
        LIFE_SIGNAL,
        CIVILIZATION,
        WARP_COORDINATE,
        TIME_COORDINATE,
        WARP_CHART,
        EPOCH_CHART,
    }
    intro = intro_audit(plugin, contract["actions"])
    lifecycle = lifecycle_refactor_audit(
        contract["actions"],
        plugin,
        bank,
    )
    civilization_tech = civilization_tech_audit(
        contract["actions"],
        plugin,
        bank,
    )
    civilization_selection_adversarial = (
        civilization_selection_adversarial_self_check(
            contract["actions"],
            plugin,
            bank,
        )
    )
    warp_coordinate = warp_coordinate_audit(contract["actions"], plugin)
    warp_v2_catalog = warp_v2_catalog_audit(plugin, contract["actions"])
    component_catalog = component_catalog_audit(
        plugin, contract["actions"]
    )
    skill_catalog = skill_catalog_audit(plugin, contract["actions"])
    straight_line_rhai = straight_line_rhai_audit(plugin)
    flattened_witness_scope = flattened_witness_scope_audit(
        plugin,
        contract["actions"],
    )
    scan_core = named_function_source(plugin, "scan_body_core")
    raw_binding_adversarial = (
        lifecycle_raw_binding_adversarial_self_check(
            contract["actions"],
            plugin,
            bank,
        )
    )
    deterministic_actions = [
        action for action in contract["actions"]
        if any(obj["mode"] == "output" and obj["class"] in deterministic_classes for obj in action["objects"])
    ]
    deterministic_family_counts = Counter(
        action["family"] for action in deterministic_actions
    )
    expected_deterministic_family_counts = Counter(
        {
            "claim_sector": 1,
            "detect_signal": len(bank),
            "scan_body": len(bank),
            "discover_satellite": 1,
            "detect_intelligent_life": 1,
            "materialize_civilization": len(CIVILIZATION_TYPES),
            "extract_warp_coordinate": 1,
            "extract_time_coordinate": 1,
            "extract_position_chart": 1,
            "extract_epoch_chart": 1,
        }
    )
    expected_deterministic_names = {
        "ClaimSector",
        "DiscoverSatellite",
        "DetectIntelligentLife",
        "ExtractAnomalyWarpCoordinate",
        "ExtractAnomalyTimeCoordinate",
        "ExtractWormholeWarpChart",
        "ExtractWormholeEpochChart",
        *(row["action"] for row in CIVILIZATION_TYPES),
        *(
            f"DetectCelestialSignal_{candidate['code']:02d}_"
            f"{candidate['slug']}"
            for candidate in bank
        ),
        *(
            f"ScanCelestialBody_{candidate['code']:02d}_"
            f"{candidate['slug']}"
            for candidate in bank
        ),
    }
    deterministic_zero_keys = deterministic_zero_key_audit(
        plugin,
        contract["actions"],
        deterministic_classes,
    )
    checks = {
        "unique_class_names": len(CLASS_ORDER) == len(set(CLASS_ORDER)),
        "unique_action_names": len(expected_names) == len(set(expected_names)),
        "manifest_action_order_matches_contract": manifest_action_names == expected_names,
        "rhai_action_functions_match_contract": function_names == expected_names,
        "source_object_roles_match_contract": all(
            source_action_object_roles(
                action_function_source(plugin, action["name"])
            )
            == action_object_roles(action)
            for action in contract["actions"]
        ),
        "all_outputs_declared_before_mutations": all(
            not any(
                mode == "output"
                for mode, _class_name in declarations[
                    next(
                        (
                            index
                            for index, (mode, _class_name)
                            in enumerate(declarations)
                            if mode == "mutate"
                        ),
                        len(declarations),
                    ):
                ]
            )
            for action in contract["actions"]
            for declarations in [
                source_action_object_roles(
                    action_function_source(plugin, action["name"])
                )
            ]
        ),
        "plugin_below_hard_limit": (
            (root / "plugin.rhai").stat().st_size
            <= RHAI_HARD_LIMIT_BYTES
        ),
        "plugin_below_safety_limit": (
            (root / "plugin.rhai").stat().st_size
            <= RHAI_SAFETY_LIMIT_BYTES
        ),
        "manifest_below_hard_limit": (
            (root / "manifest.toml").stat().st_size
            <= RHAI_HARD_LIMIT_BYTES
        ),
        "no_forbidden_product_terms": all(token not in plugin for token in ["sensor_radius", "DockAtSector", "object.get(", ".get("]),
        "deterministic_output_action_count_exact": (
            deterministic_family_counts
            == expected_deterministic_family_counts
            and {action["name"] for action in deterministic_actions}
            == expected_deterministic_names
            and len(deterministic_actions) == 2 * len(bank) + 10
        ),
        "deterministic_outputs_have_exact_class_bound_zero_keys": (
            deterministic_zero_keys["status"] == "pass"
        ),
        "no_backward_timewarp_action": "TimeWarpNegative" not in plugin and "Backward" not in plugin,
        "largest_listed_schema_below_project_cap": max(len(fields) for fields in SCHEMAS.values()) <= 256,
        "no_custom_clock_fields": all(
            token not in plugin for token in [".clock", "resource_clock", '["clock"']
        ),
        "build_ship_has_no_pow": all(
            token not in plugin for token in ["pow_obj_grind", "pow_target"]
        ),
        "all_intro_calls_use_allowed_shapes": intro["status"] == "pass",
        "lifecycle_refactor_invariants": lifecycle["status"] == "pass",
        "civilization_tech_v3_invariants": (
            civilization_tech["status"] == "pass"
        ),
        "civilization_selection_adversarial_self_checks": (
            civilization_selection_adversarial["status"] == "pass"
        ),
        "explicit_selection_metadata_cross_bindings": all(
            selection_metadata_checks.values()
        ),
        "warp_coordinate_invariants": warp_coordinate["status"] == "pass",
        "warp_v2_catalog_invariants": (
            warp_v2_catalog["status"] == "pass"
        ),
        "component_catalog_invariants": (
            component_catalog["status"] == "pass"
        ),
        "skill_catalog_invariants": skill_catalog["status"] == "pass",
        "straight_line_supported_rhai_only": (
            straight_line_rhai["status"] == "pass"
        ),
        "flattened_witness_scope_unique": (
            flattened_witness_scope["status"] == "pass"
        ),
        "refactor_census_monotonic_budgets": (
            refactor_report is None
            or (
                refactor_report.get("status") == "pass"
                and refactor_report.get("plugin", {}).get("sha256")
                == sha256_file(root / "plugin.rhai")
            )
        ),
        "raw_binding_adversarial_self_checks": (
            raw_binding_adversarial["status"] == "pass"
        ),
        "life_signal_direct_type_actions_present": (
            "DetectIntelligentLife" in expected_names
            and all(
                civilization_type["action"] in expected_names
                for civilization_type in CIVILIZATION_TYPES
            )
            and "MaterializeCivilization" not in expected_names
            and not any(
                name.startswith("AdvanceCivilizationToType")
                for name in expected_names
            )
            and "ScanIntelligentLife" not in expected_names
        ),
    }
    result = {
        "status": "pass" if all(checks.values()) else "fail",
        "checks": checks,
        "plugin_bytes": (root / "plugin.rhai").stat().st_size,
        "rhai_hard_limit_bytes": RHAI_HARD_LIMIT_BYTES,
        "rhai_safety_limit_bytes": RHAI_SAFETY_LIMIT_BYTES,
        "rhai_safety_headroom_bytes": (
            RHAI_SAFETY_LIMIT_BYTES
            - (root / "plugin.rhai").stat().st_size
        ),
        "manifest_bytes": (root / "manifest.toml").stat().st_size,
        "action_count": len(expected_names),
        "class_count": class_count,
        "deterministic_output_action_count": len(deterministic_actions),
        "deterministic_zero_keys": deterministic_zero_keys,
        "lifecycle_refactor": lifecycle,
        "civilization_tech_v3": civilization_tech,
        "civilization_selection_adversarial_self_check": (
            civilization_selection_adversarial
        ),
        "explicit_selection_metadata": {
            "status": (
                "pass"
                if all(selection_metadata_checks.values())
                else "fail"
            ),
            "checks": selection_metadata_checks,
            "counter_gates": EXPLICIT_COUNTER_GATES,
        },
        "warp_coordinate": warp_coordinate,
        "warp_v2_catalog": warp_v2_catalog,
        "component_catalog": component_catalog,
        "skill_catalog": skill_catalog,
        "straight_line_rhai": straight_line_rhai,
        "flattened_witness_scope": flattened_witness_scope,
        "refactor_census": refactor_report,
        "raw_binding_adversarial_self_check": raw_binding_adversarial,
    }
    write_json(root / "generated" / "static-audit.json", result)
    if result["status"] != "pass":
        raise RuntimeError(f"static generation gates failed: {result}")
    return result


def readme() -> str:
    return """# Microverse Celestial Prototype

This directory contains the generated, isolated DON PEXE prototype specified by
`../microverse-spec-beta.md` and the whole-object Intro validation pass in
`../microverse-next-pass.md`, extended with the typed resources, explicit
Civilization progression milestones, reusable TechnologySkills, composite resource pools, and refinement
hierarchies in `../civilization-tech-v1.md` and `../tech-tree-v3.md`.

- `manifest.toml` and `plugin.rhai` are the only source entries packaged into
  the PEXE.
- `generated/` contains machine-readable contracts and measured evidence.
- `probes/` isolates P01 through P10b whole-object compiler/proof shapes.
- `capacity/` contains noncanonical candidate and Civilization scaling variants.
- `tools/` contains the exact commitment scanner and reachable lifecycle
  harness.
- `dist/` contains the final archive when compilation succeeds.

Regenerate deterministic source from the workspace root with:

```powershell
python .\\tools\\generate_microverse.py
```

The generator never installs a PEXE into the Driver action directory.
"""


def validation_report_skeleton() -> str:
    sections = [
        "Outcome",
        "Exact toolchain and read-only SDK verification",
        "Changes from the previous build",
        "Final classes, actions, and bridges",
        "VDF-only BuildShip calibration",
        "Compiler probes",
        "Full build and archive results",
        "Predicate and splitter results",
        "Per-action plan/prove/payload table",
        "Reachable lifecycle results",
        "Negative, collision, and atomicity results",
        "Determinism and new universe hashes",
        "Distribution scan",
        "Candidate-bank capacity sweep",
        "Civilization-specific capacity sweep",
        "Remaining room for future mechanics",
        "Bugs, blocked shapes, and PEXE-only redesign options",
        "Recommended next gameplay additions",
        "Output inventory and hashes",
    ]
    lines = [
        "# Microverse validation report",
        "",
        "> Evidence collection is in progress; this file is finalized by the validation runner.",
        "",
    ]
    for index, title in enumerate(sections, 1):
        lines.extend([f"## {index}. {title}", "", "Pending measured results.", ""])
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--workspace",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Workspace containing microverse-spec-beta.md",
    )
    parser.add_argument(
        "--source-root",
        type=Path,
        default=Path(os.environ.get("DON_SOURCE_ROOT", str(Path.cwd()))),
        help="Installed DON source tree",
    )
    parser.add_argument(
        "--candidate-count",
        type=int,
        help="Candidate count; defaults to the complete configured body bank",
    )
    parser.add_argument("--output", type=Path)
    parser.add_argument(
        "--catalog-dir",
        type=Path,
        help=(
            "Directory containing the four authoritative Microverse v2 "
            "catalog JSON files; defaults to <workspace>/catalog when present"
        ),
    )
    parser.add_argument("--skip-variants", action="store_true")
    parser.add_argument(
        "--vdf-profile",
        choices=("current", "economy"),
        default="economy",
        help=(
            "economy is canonical: staged Ship creation, tier-scaled "
            "movement, and difficulty-scaled extraction/refinement VDFs; "
            "current retains the legacy pre-economy validation profile"
        ),
    )
    args = parser.parse_args()

    workspace = args.workspace.resolve()
    output = args.output.resolve() if args.output else workspace / PACKAGE_NAME
    catalog_dir = (
        args.catalog_dir.resolve()
        if args.catalog_dir is not None
        else workspace / "catalog"
    )
    if catalog_dir.exists():
        configure_expansion_catalogs(catalog_dir)
    configure_vdf_profile(args.vdf_profile)
    candidate_count = (
        args.candidate_count
        if args.candidate_count is not None
        else len(BODY_BANK)
    )
    bank = candidate_bank(candidate_count)
    actions = build_actions(bank)
    if EXPANSION_CATALOGS:
        write_json(
            catalog_dir / CATALOG_INDEX_FILENAME,
            expansion_catalog_index(bank, actions),
        )
    generate_package(output, bank, actions, package_name=PACKAGE_NAME)
    write_json(output / "generated" / "build-baseline.json", baseline(args.source_root.resolve()))
    write_text(output / "README.md", readme())
    if not (output / "microverse-validation-report.md").exists():
        write_text(output / "microverse-validation-report.md", validation_report_skeleton())
    validate_generated(output)

    if not args.skip_variants and candidate_count == len(BODY_BANK):
        generate_probes(output, bank)
        generate_capacity_variants(output)

    summary = {
        "output": str(output),
        "candidate_count": len(bank),
        "vdf_profile": ACTIVE_VDF_PROFILE,
        "action_count": len(actions),
        "plugin_bytes": (output / "plugin.rhai").stat().st_size,
        "manifest_bytes": (output / "manifest.toml").stat().st_size,
        "plugin_sha256": sha256_file(output / "plugin.rhai"),
        "manifest_sha256": sha256_file(output / "manifest.toml"),
    }
    print(stable_json(summary), end="")


if __name__ == "__main__":
    main()
