#!/usr/bin/env python3
"""Refresh the self-contained UI from the canonical Microverse package artifacts."""

from __future__ import annotations

import argparse
import base64
import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path

import tomli


ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / "microverse.html"
CATALOG = ROOT / "catalog"
GENERATED = ROOT / "generated"
WASM = (
    ROOT
    / "target"
    / "commitment-wasm"
    / "wasm32-unknown-unknown"
    / "release"
    / "microverse_commitment_wasm.wasm"
)


def load_json(path: Path):
    return json.loads(path.read_bytes().decode("utf-8"))


def compact_json(value) -> str:
    return json.dumps(value, ensure_ascii=True, separators=(",", ":")).replace("</", "<\\/")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def find_balanced(source: str, start: int) -> int:
    opening = source[start]
    closing = {"{": "}", "[": "]", "(": ")"}[opening]
    depth = 0
    quote = None
    escaped = False
    line_comment = False
    block_comment = False
    index = start
    while index < len(source):
        char = source[index]
        next_char = source[index + 1] if index + 1 < len(source) else ""
        if line_comment:
            if char in "\r\n":
                line_comment = False
        elif block_comment:
            if char == "*" and next_char == "/":
                block_comment = False
                index += 1
        elif quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in "\"'`":
            quote = char
        elif char == "/" and next_char == "/":
            line_comment = True
            index += 1
        elif char == "/" and next_char == "*":
            block_comment = True
            index += 1
        elif char == opening:
            depth += 1
        elif char == closing:
            depth -= 1
            if depth == 0:
                return index + 1
        index += 1
    raise ValueError(f"unterminated {opening} expression")


def replace_balanced_assignment(source: str, prefix: str, expression: str) -> str:
    position = source.find(prefix)
    if position < 0:
        raise ValueError(f"missing assignment {prefix}")
    start = position + len(prefix)
    if source[start] not in "{[":
        raise ValueError(f"assignment {prefix} is not a data expression")
    end = find_balanced(source, start)
    return source[:start] + expression + source[end:]


def js_string_span(source: str, prefix: str) -> tuple[int, int, str]:
    position = source.find(prefix)
    if position < 0:
        raise ValueError(f"missing string assignment {prefix}")
    start = position + len(prefix)
    quote = source[start]
    if quote not in "\"'":
        raise ValueError(f"assignment {prefix} is not a string")
    escaped = False
    for index in range(start + 1, len(source)):
        char = source[index]
        if escaped:
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == quote:
            literal = source[start : index + 1]
            if quote != '"':
                raise ValueError(f"unsupported quote for {prefix}")
            return start, index + 1, json.loads(literal.replace("<\\/", "</"))
    raise ValueError(f"unterminated string assignment {prefix}")


def replace_js_string(source: str, prefix: str, value: str) -> str:
    start, end, _ = js_string_span(source, prefix)
    literal = json.dumps(value, ensure_ascii=True).replace("</", "<\\/")
    return source[:start] + literal + source[end:]


def replace_between(source: str, start_marker: str, end_marker: str, value: str) -> str:
    start = source.find(start_marker)
    end = source.find(end_marker, start)
    if start < 0 or end < 0:
        raise ValueError(f"missing replacement block {start_marker!r} ... {end_marker!r}")
    return source[:start] + value + source[end:]


def replace_once_regex(source: str, pattern: str, replacement: str) -> str:
    updated, count = re.subn(pattern, replacement, source, count=1)
    if count != 1:
        raise ValueError(f"expected one match for {pattern!r}, found {count}")
    return updated


def replace_exact_once(source: str, old: str, new: str) -> str:
    count = source.count(old)
    if count != 1:
        raise ValueError(f"expected one exact match, found {count}: {old[:96]!r}")
    return source.replace(old, new, 1)


def replace_exact_or_current(source: str, old: str, new: str) -> str:
    if source.count(new) == 1 and source.count(old) == 0:
        return source
    return replace_exact_once(source, old, new)


def skill_rows(skill_catalog: dict) -> list[dict]:
    rows = []
    for root in skill_catalog["roots"]:
        rows.append(
            {
                "code": root["code"],
                "name": root["name"],
                "display_name": root["name"],
                "tier": "root",
                "civilization_type": root["civilization_type"],
                "parent_code": None,
                "develop_action": root["develop_action"],
                "description": root["route_policy"],
            }
        )
        for specialization in root["specializations"]:
            rows.append(
                {
                    "code": specialization["code"],
                    "name": specialization["name"],
                    "display_name": specialization["name"],
                    "tier": "specialization",
                    "civilization_type": specialization["civilization_type"],
                    "parent_code": specialization["parent_code"],
                    "develop_action": specialization["develop_action"],
                    "description": specialization["description"],
                }
            )
        mastery = root["mastery"]
        rows.append(
            {
                "code": mastery["code"],
                "name": mastery["name"],
                "display_name": mastery["name"],
                "tier": "mastery",
                "civilization_type": mastery["civilization_type"],
                "parent_code": mastery["parent_code"],
                "develop_action": mastery["develop_action"],
                "description": mastery["description"],
            }
        )
    rows.sort(key=lambda row: row["code"])
    if [row["code"] for row in rows] != list(range(1, 91)):
        raise ValueError("skill catalog must contain the exact contiguous codes 1 through 90")
    return rows


def class_contract(manifest: dict) -> dict:
    display = {
        "MicroverseShip": ("Microverse Ship", "world_object"),
        "MicroverseSector": ("Microverse Sector", "world_object"),
        "MicroverseCelestialSignal": ("Microverse Celestial Signal", "world_object"),
        "MicroverseCelestialBody": ("Microverse Celestial Body", "world_object"),
        "MicroverseCompositeResource": ("Composite Resource", "composite_resource"),
        "MicroverseResource": ("Resource", "resource"),
        "MicroverseSatellite": ("Microverse Satellite", "world_object"),
        "MicroverseLifeSignal": ("Microverse Life Signal", "world_object"),
        "MicroverseCivilization": ("Microverse Civilization", "world_object"),
        "MicroverseTechnologySkill": ("Technology Skill", "technology_skill"),
        "MicroverseShipyardPermit": ("Microverse Shipyard Permit", "world_object"),
        "MicroverseWarpCoordinate": ("Warp Coordinate", "warp_coordinate"),
        "MicroverseTimeCoordinate": ("Time Coordinate", "time_coordinate"),
        "MicroverseWarpChart": ("Warp Chart", "warp_chart"),
        "MicroverseEpochChart": ("Epoch Chart", "epoch_chart"),
        "MicroversePositionAnchor": ("Position Anchor", "position_anchor"),
        "MicroverseTimeAnchor": ("Time Anchor", "time_anchor"),
        "MicroverseWormholeLink": ("Wormhole Link", "wormhole_link"),
        "MicroverseTemporalLink": ("Temporal Link", "temporal_link"),
        "MicroverseRendezvousCoordinate": ("Rendezvous Coordinate", "rendezvous_coordinate"),
    }
    classes = []
    for item in manifest["classes"]:
        name = item["name"]
        if name not in display:
            raise ValueError(f"no UI class presentation for {name}")
        label, kind = display[name]
        classes.append({"class": name, "display_name": label, "kind": kind})
    return {"class_count": len(classes), "classes": classes}


def updated_tree_viewer(
    viewer: str,
    resource_catalog: dict,
    skills: list[dict],
    universe: dict,
    components: dict,
    skill_catalog: dict,
) -> tuple[str, dict]:
    match = re.search(
        r'<script id="data" type="application/json">(.*?)</script>', viewer, re.S
    )
    if not match:
        raise ValueError("embedded resource tree data was not found")
    data = json.loads(match.group(1))

    new_body_names = {body["name"] for body in resource_catalog["bodies"]}
    data["bodies"] = {
        name: body for name, body in data["bodies"].items() if name not in new_body_names
    }
    for body in resource_catalog["bodies"]:
        caps = {
            pool.title(): amount
            for pool, amount in body["reserves"].items()
            if amount
        }
        data["bodies"][body["name"]] = {
            "odds": body["nominal_denominator"],
            "caps": caps,
            "bits": body["occurrence_exponent"],
        }

    skill_name = {row["code"]: row["name"] for row in skills}
    body_name = {body["body_id"]: body["name"] for body in resource_catalog["bodies"]}
    pool_name = {pool["pool_id"]: pool["name"] for pool in resource_catalog["pools"]}
    source_codes = {resource["resource_id"] for resource in resource_catalog["source_resources"]}
    data["prim"] = [item for item in data["prim"] if item["c"] not in source_codes]
    ship_tier = {0: "Small+", 1: "Medium+", 2: "Large+"}
    for resource in resource_catalog["source_resources"]:
        data["prim"].append(
            {
                "c": resource["resource_id"],
                "n": resource["name"],
                "comp": resource["role"] == "composite",
                "r": [
                    {
                        "b": body_name[resource["body_id"]],
                        "pool": pool_name[resource["pool_id"]],
                        "ship": ship_tier[resource["min_capacity_tier"]],
                        "skill": skill_name.get(resource["extraction_skill_id"], "No skill"),
                    }
                ],
            }
        )
    data["prim"].sort(key=lambda item: item["c"])

    refined_codes = {resource["resource_id"] for resource in resource_catalog["refined_resources"]}
    data["ref"] = [item for item in data["ref"] if item["c"] not in refined_codes]
    tier_name = {1: "Primary", 2: "Secondary", 3: "Tertiary"}
    for resource in resource_catalog["refined_resources"]:
        parent = next(
            item
            for item in resource_catalog["refinement_parents"]
            if item["resource_id"] == resource["parent_resource_id"]
        )
        data["ref"].append(
            {
                "c": resource["resource_id"],
                "n": resource["name"],
                "r": [
                    {
                        "p": parent["parent_name"],
                        "t": tier_name[resource["slot"]],
                        "pct": resource["allocation_per_1000"] / 10,
                        "skill": skill_name[resource["refinement_skill_id"]],
                    }
                ],
            }
        )
    data["ref"].sort(key=lambda item: item["c"])

    data["skills"] = skills
    civ_by_code = {item["code"]: item for item in universe["civilization_types"]}
    data["civilizations"] = [
        {
            "code": code,
            "name": civ_by_code[code]["name"],
            "short": f"Type {'I' * code}",
            "odds": f"serial >= {civ_by_code[code]['minimum_civilization_scan_serial']:,}",
        }
        for code in (1, 2, 3)
    ]
    data["components"] = [
        {
            "code": item["code"],
            "name": item["name"],
            "skill_code": item["skill_code"],
            "skill_name": item["skill_name"],
            "description": item["description"],
            "tier": item["tier"],
            "vdf_iterations": item["vdf_iterations"],
            "materials": [
                {
                    "code": material["resource_code"],
                    "name": material["name"],
                    "amount": material["amount"],
                }
                for material in item["materials"]
            ],
            "catalyst": {
                "code": item["catalyst"]["resource_code"],
                "name": item["catalyst"]["name"],
                "amount": item["catalyst"]["units_per_craft"],
                "modes": item["catalyst"]["modes"],
            },
            "actions": item["actions"],
        }
        for item in components["components"]
    ]
    capability_descriptions = {}
    for root in skill_catalog["roots"]:
        for skill in [*root["specializations"], root["mastery"]]:
            for capability in skill.get("gated_capabilities", []):
                capability_descriptions[capability["output_resource_code"]] = capability[
                    "description"
                ]
    resource_names = {
        1: "Matter",
        2: "Crystal",
        3: "Gas",
        4: "Energy",
        **{
            item["resource_id"]: item["name"]
            for item in [
                *resource_catalog["source_resources"],
                *resource_catalog["refined_resources"],
            ]
        },
        **{item["code"]: item["name"] for item in components["components"]},
        **{
            item["fallback_resource"]["code"]: item["fallback_resource"]["name"]
            for item in skill_catalog["capability_artifacts"]
        },
    }
    data["artifacts"] = [
        {
            "code": item["fallback_resource"]["code"],
            "name": item["fallback_resource"]["name"],
            "skill_code": item["skill_code"],
            "skill_name": skill_name[item["skill_code"]],
            "description": capability_descriptions.get(
                item["fallback_resource"]["code"],
                "Capability artifact produced by this technology skill.",
            ),
            "action": item["action"],
            "vdf_iterations": item["vdf_iterations"],
            "inputs": [
                {
                    "code": material["resource_code"],
                    "name": resource_names[material["resource_code"]],
                    "amount": material["amount"],
                }
                for material in item["fixed_inputs"]
            ],
        }
        for item in skill_catalog["capability_artifacts"]
    ]

    data_literal = json.dumps(data, ensure_ascii=True, separators=(",", ":"))
    viewer = viewer[: match.start(1)] + data_literal + viewer[match.end(1) :]

    constants_start = viewer.find("const CIVILIZATIONS = ")
    constants_end = viewer.find("const ROOTC", constants_start)
    if constants_start < 0 or constants_end < 0:
        raise ValueError("resource tree skill constants were not found")
    constants = """const CIVILIZATIONS = D.civilizations.map(civ => ({
  ...civ, skills:D.skills.filter(skill => skill.civilization_type === civ.code).map(skill => skill.name)
}));
const CIV_BY_SKILL = Object.fromEntries(CIVILIZATIONS.flatMap(civ => civ.skills.map(skill => [skill, civ])));
const SKILLS = D.skills.slice().sort((a,b) => a.code - b.code).map(skill => skill.name);
const SKILL_BY_CODE = Object.fromEntries(D.skills.map(skill => [skill.code, skill]));
const SKILL_BY_NAME = Object.fromEntries(D.skills.map(skill => [skill.name, skill]));
"""
    viewer = viewer[:constants_start] + constants + viewer[constants_end:]

    rarity_start = viewer.find("const RAR = {")
    rarity_end = viewer.find("const POOLC", rarity_start)
    if rarity_start < 0 or rarity_end < 0:
        raise ValueError("resource tree rarity palette was not found")
    rarity = """const RAR = {
  8:{c:'#5FBF87',t:'Abundant'},16:{c:'#86C56B',t:'Common'},32:{c:'#B4C75A',t:'Uncommon'},
  64:{c:'#D9C24E',t:'Notable'},128:{c:'#EBA047',t:'Scarce'},256:{c:'#E87C45',t:'Rare'},
  512:{c:'#E56A49',t:'Rare+'},1024:{c:'#E15650',t:'Very rare'},2048:{c:'#DC4A69',t:'Exceptional'},
  4096:{c:'#D63E86',t:'Exotic'},8192:{c:'#BC46B8',t:'Exotic+'},
  16384:{c:'#A052D4',t:'Anomalous'},32768:{c:'#9B5DE8',t:'Singular'}
};
"""
    viewer = viewer[:rarity_start] + rarity + viewer[rarity_end:]

    palette = """const ROOTC = '#7FD1E0';
const LIFEC = '#79D99C', CIVC = '#D68BE8';
const COMPONENTC = '#F6B26B', ARTIFACTC = '#D68BE8', PROGRESSIONC = '#8FB3FF';
let MODE = 'bodies';
"""
    viewer = replace_between(viewer, "const ROOTC", "const LAST", palette)

    skill_model = r"""function buildSkillModel(skillName){
  const skill = SKILL_BY_NAME[skillName];
  const root = { kind:'skill', name:skillName, skill, children:[] };
  const groups = Object.fromEntries(POOLS.map(pool => [pool, new Map()]));
  const ensurePrimary = (pool, p) => {
    let node = groups[pool].get(p.n);
    if (!node){
      node = { kind:'prim', name:p.n, pool, comp:p.comp, extractRoutes:[], children:[] };
      groups[pool].set(p.n, node);
    }
    return node;
  };
  D.prim.forEach(p => p.r.filter(r => r.skill === skillName).forEach(r => {
    const node = ensurePrimary(r.pool, p);
    if (!node.extractRoutes.some(x => x.b === r.b && x.ship === r.ship)) node.extractRoutes.push(r);
  }));
  D.ref.forEach(x => x.r.filter(r => r.skill === skillName).forEach(recipe => {
    const p = primBy[recipe.p];
    if (!p) return;
    [...new Set(p.r.map(r => r.pool))].forEach(pool => {
      const node = ensurePrimary(pool, p);
      if (!node.children.some(child => child.name === x.n)){
        node.children.push({ kind:'ref', name:x.n, pool, pct:recipe.pct,
          skill:skillName, parentName:p.n, children:[] });
      }
    });
  }));
  const civilization = CIV_BY_SKILL[skillName];
  if (civilization) root.children.push({
    kind:'origin', name:civilization.name, civilization, children:[]
  });
  const relatedSkills = [];
  if (skill.parent_code){
    const parentSkill = SKILL_BY_CODE[skill.parent_code];
    relatedSkills.push({ kind:'skilllink', name:parentSkill.name, skill:parentSkill,
      relationship:'Prerequisite', pool:'Crystal', children:[] });
  }
  D.skills.filter(item => item.parent_code === skill.code)
    .sort((a,b) => a.code - b.code)
    .forEach(child => relatedSkills.push({ kind:'skilllink', name:child.name, skill:child,
      relationship:'Unlock', pool:'Crystal', children:[] }));
  if (relatedSkills.length) root.children.push({ kind:'pool', name:'Skill progression',
    branch:'progression', pool:'Crystal', cap:relatedSkills.length, children:relatedSkills });
  POOLS.forEach(pool => {
    const children = [...groups[pool].values()].sort((a,b) => a.name.localeCompare(b.name));
    children.forEach(n => n.children.sort((a,b) => b.pct - a.pct || a.name.localeCompare(b.name)));
    if (children.length) root.children.push({ kind:'pool', name:pool, branch:'resources',
      pool, cap:children.length, children });
  });
  const componentNodes = D.components.filter(item => item.skill_code === skill.code)
    .sort((a,b) => a.code - b.code)
    .map(component => ({ kind:'component', name:component.name, component,
      pool:'Energy', children:[] }));
  if (componentNodes.length) root.children.push({ kind:'pool', name:'Components',
    branch:'components', pool:'Energy', cap:componentNodes.length, children:componentNodes });
  const artifactNodes = D.artifacts.filter(item => item.skill_code === skill.code)
    .sort((a,b) => a.code - b.code)
    .map(artifact => ({ kind:'artifact', name:artifact.name, artifact,
      pool:'Gas', children:[] }));
  if (artifactNodes.length) root.children.push({ kind:'pool', name:'Capability artifacts',
    branch:'artifacts', pool:'Gas', cap:artifactNodes.length, children:artifactNodes });
  let leaves = 0;
  (function count(n){ n.children.length ? n.children.forEach(count) : leaves++; })(root);
  let slot = 0;
  (function assign(n){
    if (!n.children.length){ n.a = FAN0 - FAN/2 + (slot + .5) / leaves * FAN; slot++; return n.a; }
    const as = n.children.map(assign); n.a = (Math.min(...as) + Math.max(...as)) / 2; return n.a;
  })(root);
  const flat = [];
  (function placeNode(n, depth, parent){
    const t = TIERS[depth];
    n.pos = new THREE.Vector3(Math.cos(n.a) * t.r, t.y, Math.sin(n.a) * t.r);
    n.depth = depth; n.parent = parent; flat.push(n);
    n.children.forEach(c => placeNode(c, depth + 1, n));
  })(root, 0, null);
  return flat;
}

"""
    viewer = replace_between(viewer, "function buildSkillModel(", "function buildModel(", skill_model)

    size_model = r"""const sizeOf = n =>
  (n.kind === 'body' || n.kind === 'skill') ? 1.2 :
  n.kind === 'unlock' ? .68 :
  n.kind === 'component' ? .52 :
  n.kind === 'artifact' ? .56 :
  n.kind === 'skilllink' ? .46 :
  n.kind === 'civskill' ? .34 :
  n.kind === 'life' ? .78 :
  n.kind === 'signal' ? .58 :
  (n.kind === 'civ' || n.kind === 'origin') ? .58 :
  n.kind === 'pool' ? (MODE === 'skills' ? .48 + Math.min(.55, n.children.length * .035) : .40 + (n.cap / MAXCAP) * .70) :
  n.kind === 'prim' ? (n.comp ? .50 : .36) :
  .085 * Math.sqrt(n.pct);

"""
    viewer = replace_between(
        viewer,
        "const sizeOf =",
        "/* ============ build ============ */",
        size_model,
    )

    render_model = r"""const hex = n.kind === 'body' ? RAR[BODY[bodyName].odds].c
              : n.kind === 'component' ? COMPONENTC
              : n.kind === 'artifact' ? ARTIFACTC
              : n.kind === 'skilllink' ? PROGRESSIONC
              : (n.kind === 'skill' || n.kind === 'unlock' || n.kind === 'civskill') ? ROOTC
              : (n.kind === 'life' || n.kind === 'signal') ? LIFEC
              : (n.kind === 'civ' || n.kind === 'origin') ? CIVC : POOLC[n.pool];
    const col = new THREE.Color(hex);
    const geo = (n.kind === 'skill' || n.kind === 'unlock' || n.kind === 'civskill' || n.kind === 'skilllink')
      ? new THREE.TetrahedronGeometry(sizeOf(n) * 1.32, 0)
      : n.kind === 'artifact'
      ? new THREE.BoxGeometry(sizeOf(n) * 1.35, sizeOf(n) * 1.35, sizeOf(n) * 1.35)
      : n.kind === 'component'
      ? new THREE.IcosahedronGeometry(sizeOf(n), 1)
      : n.kind === 'life'
      ? new THREE.DodecahedronGeometry(sizeOf(n), 0)
      : n.kind === 'signal'
      ? new THREE.OctahedronGeometry(sizeOf(n), 0)
      : (n.kind === 'civ' || n.kind === 'origin')
      ? new THREE.BoxGeometry(sizeOf(n) * 1.45, sizeOf(n) * 1.45, sizeOf(n) * 1.45)
      : (n.kind === 'prim' && !n.comp)
      ? new THREE.OctahedronGeometry(sizeOf(n) * 1.18, 0)
      : new THREE.IcosahedronGeometry(sizeOf(n), n.kind === 'ref' ? 0 : 1);
    """
    viewer = replace_between(viewer, "const hex =", "n.mesh = new THREE.Mesh", render_model)

    labels = r"""el.innerHTML = (n.kind === 'unlock' || n.kind === 'civskill')
      ? `<span class="txt"><b>Skill</b>${esc(n.name)}</span>`
      : n.kind === 'skilllink'
      ? `<span class="txt"><b>${esc(n.relationship)}</b>${esc(n.name)}</span>`
      : n.kind === 'component'
      ? `<span class="txt"><b>Component #${n.component.code}</b>${esc(n.name)}</span>`
      : n.kind === 'artifact'
      ? `<span class="txt"><b>Artifact #${n.artifact.code}</b>${esc(n.name)}</span>`
      : n.kind === 'life'
      ? `<span class="txt"><b>Life ${n.life}</b>${esc(n.name)}</span>`
      : n.kind === 'civ'
      ? `<span class="txt">${esc(n.civilization.short)}</span>`
      : n.kind === 'ref'
      ? `<span class="txt"><b>${n.pct}%</b>${esc(n.name)}</span>`
      : `<span class="txt">${esc(n.name)}</span>`;
    """
    viewer = replace_between(viewer, "el.innerHTML =", "el.style.visibility", labels)

    skill_details = r"""function selectSkillNode(n){
  const chain = [];
  let cur = n; while (cur){ chain.unshift(`<b>${esc(cur.name)}</b>`); cur = cur.parent; }
  let note = '', gates = '', also = '';
  if (n.kind === 'origin'){
    note = `${esc(focused)} is developed by this civilization type and remains reusable once earned.`;
    gates = `<span class="gate">Overall frequency ${esc(n.civilization.odds)}</span><span class="gate">Civilization source</span>`;
  } else if (n.kind === 'pool'){
    const branchLabel = n.branch === 'components' ? 'fabricated component'
      : n.branch === 'artifacts' ? 'capability artifact'
      : n.branch === 'progression' ? 'related skill' : 'resource path';
    note = `${n.children.length} ${branchLabel}${n.children.length === 1 ? '' : 's'} connected to this skill.`;
    gates = `<span class="gate">${esc(focused)}</span><span class="gate">${esc(n.name)}</span>`;
  } else if (n.kind === 'component'){
    const item = n.component;
    note = esc(item.description);
    gates = `<span class="gate">Component #${item.code}</span><span class="gate">Tier ${item.tier}</span><span class="gate">VDF ${item.vdf_iterations}</span>`;
    also = `<p class="also">Materials: ${item.materials.map(material => `${material.amount} ${esc(material.name)}`).join(', ')}. Catalyst: ${item.catalyst.amount} ${esc(item.catalyst.name)} (${item.catalyst.modes.map(esc).join(' / ')}).</p>`;
  } else if (n.kind === 'artifact'){
    const item = n.artifact;
    note = esc(item.description);
    gates = `<span class="gate">Artifact #${item.code}</span><span class="gate">VDF ${item.vdf_iterations}</span><span class="gate">${esc(item.action)}</span>`;
    also = `<p class="also">Inputs: ${item.inputs.map(material => `${material.amount} ${esc(material.name)}`).join(', ')}.</p>`;
  } else if (n.kind === 'skilllink'){
    note = n.relationship === 'Prerequisite'
      ? `${esc(n.name)} is the parent skill required to develop ${esc(focused)}.`
      : `${esc(n.name)} develops from ${esc(focused)}.`;
    gates = `<span class="gate">${esc(n.relationship)}</span><span class="gate">${esc(n.skill.tier)}</span><span class="gate">${esc(n.skill.develop_action)}</span>`;
  } else if (n.kind === 'prim'){
    const routes = n.extractRoutes || [];
    const bodies = [...new Set(routes.map(r => r.b))].sort((a,b) => BODY[a].odds - BODY[b].odds);
    const roles = [];
    if (routes.length) roles.push(`Unlocks extraction from ${bodies.length} bod${bodies.length === 1 ? 'y' : 'ies'}.`);
    if (n.children.length) roles.push(`Unlocks ${n.children.length} refined product${n.children.length === 1 ? '' : 's'} from this primary.`);
    note = roles.join(' ');
    const ships = [...new Set(routes.map(r => r.ship))];
    gates = `<span class="gate">${esc(focused)}</span>` + ships.map(ship => `<span class="gate">${esc(ship)} ship</span>`).join('');
    if (bodies.length) also = `<p class="also">Extraction sources: ${bodies.map(b => `${esc(b)} 1:${fmt(BODY[b].odds)}`).join(', ')}</p>`;
  } else {
    note = `${n.pct}% of every ${esc(n.parent.name)} refinement yield.`;
    gates = `<span class="gate">${esc(focused)}</span><span class="gate">Refinement</span>`;
  }
  detail.innerHTML = `<div class="crumb">${chain.join('<i>›</i>')}</div>
    <h3>${esc(n.name)}</h3><p class="note">${note}</p>
    <div class="gates">${gates}</div>${also}`;
  detail.classList.add('on'); measureHud(); fitCamera();
}

"""
    viewer = replace_between(viewer, "function selectSkillNode(", "function select(n)", skill_details)

    skill_focus = r"""function focusSkill(name){
  LAST.skills = name;
  buildTree(name); applyEmphasis(); fitCamera();
  const extract = D.prim.filter(p => p.r.some(r => r.skill === name)).length;
  const refine = D.ref.filter(x => x.r.some(r => r.skill === name)).length;
  const skill = SKILL_BY_NAME[name];
  const componentCount = D.components.filter(item => item.skill_code === skill.code).length;
  const artifactCount = D.artifacts.filter(item => item.skill_code === skill.code).length;
  const unlocks = extract + refine + componentCount + artifactCount;
  const civilization = CIV_BY_SKILL[name];
  document.getElementById('bodycard').innerHTML =
    `<p class="eyebrow">Skill tree</p><h1>${esc(name)}</h1>
     <div class="sub" style="--r:${ROOTC}"><span class="tier">${esc(skill.tier)}</span>
       <span class="rar">${unlocks} production paths</span></div>
     <div class="caps">
       <span class="cap pool Matter" style="--fill:${Math.min(100, extract / 15 * 100)}%">Extract<b>${extract}</b></span>
       <span class="cap pool Crystal" style="--fill:${Math.min(100, refine / 55 * 100)}%">Refine<b>${refine}</b></span>
       <span class="cap pool Energy" style="--fill:${Math.min(100, componentCount / 4 * 100)}%">Components<b>${componentCount}</b></span>
       <span class="cap pool Gas" style="--fill:${Math.min(100, artifactCount * 100)}%">Artifacts<b>${artifactCount}</b></span>
     </div>
     ${civilization ? `<div class="life-readout civilization"><span>Origin</span><b>${esc(civilization.name)}</b><small>${esc(civilization.odds)}</small></div>` : ''}`;
  document.querySelectorAll('.bb').forEach(x => x.setAttribute('aria-pressed', String(x.dataset.name === name)));
  detail.classList.remove('on'); measureHud();
}

"""
    viewer = replace_between(viewer, "function focusSkill(", "function renderPicker(", skill_focus)

    mode_switch = r"""function setMode(mode){
  const next = mode === 'skills' ? 'skills' : 'bodies';
  if (next === MODE && nodes.length) return;
  MODE = next; selected = null; searchEl.value = ''; results.classList.remove('on');
  detail.classList.remove('on'); detail.replaceChildren();
  tierEls[0].el.querySelector('.txt').textContent = MODE === 'skills' ? 'Origin / Branch' : 'Pool';
  tierEls[1].el.querySelector('.txt').textContent = MODE === 'skills' ? 'Resource / Item' : 'Primary';
  tierEls[2].el.querySelector('.txt').textContent = 'Refined';
  tierEls[tierEls.length - 1].el.style.display = MODE === 'skills' ? 'none' : '';
  renderPicker(); focus(LAST[MODE]);
}

"""
    viewer = replace_between(viewer, "function setMode(", "function focus(name)", mode_switch)

    skill_index = r"""const skillItems = new Map();
const addSkillItem = (name, skill, role) => {
  if (!skill || skill === 'No skill') return;
  const item = skillItems.get(name) || { n:name, skills:new Set(), roles:new Set() };
  item.skills.add(skill); item.roles.add(role); skillItems.set(name, item);
};
D.prim.forEach(p => p.r.forEach(r => addSkillItem(p.n, r.skill, 'extract')));
D.ref.forEach(x => x.r.forEach(r => addSkillItem(x.n, r.skill, 'refine')));
D.components.forEach(item => addSkillItem(item.name, item.skill_name, 'fabricate'));
D.artifacts.forEach(item => addSkillItem(item.name, item.skill_name, 'capability'));
const SKILL_INDEX = [...skillItems.values()].map(i => ({...i, skills:[...i.skills].sort(), roles:[...i.roles].sort()}))
  .sort((a,b) => a.n.localeCompare(b.n));
"""
    viewer = replace_between(
        viewer,
        "const skillItems = new Map();",
        "const results = document.getElementById('results')",
        skill_index,
    )

    ready_start = viewer.find("window.__microverseTreeCensus")
    if ready_start >= 0:
        ready_end = viewer.find("window.__ready = true;", ready_start)
        if ready_end < 0:
            raise ValueError("resource tree readiness marker was not found")
        viewer = viewer[:ready_start] + viewer[ready_end:]
    census = """window.__microverseTreeCensus = {
  bodies:Object.keys(BODY).length,
  skills:D.skills.length,
  source_resources:D.prim.length,
  refined_resources:D.ref.length,
  components:D.components.length,
  artifacts:D.artifacts.length
};
window.__ready = true;"""
    viewer = viewer.replace("window.__ready = true;", census, 1)

    counts = {
        "bodies": len(data["bodies"]),
        "base_resources": len(data["base"]),
        "source_resources": len(data["prim"]),
        "refined_resources": len(data["ref"]),
        "skills": len(data["skills"]),
        "components": len(data["components"]),
        "artifacts": len(data["artifacts"]),
        "rarity_tiers": len({body["odds"] for body in data["bodies"].values()}),
    }
    expected = {
        "bodies": 23,
        "base_resources": 4,
        "source_resources": 149,
        "refined_resources": 316,
        "skills": 90,
        "components": 45,
        "artifacts": 72,
        "rarity_tiers": 13,
    }
    if counts != expected:
        raise ValueError(f"resource tree census drift: {counts!r} != {expected!r}")
    return viewer, counts


def catalog_records(
    index: dict,
    components: dict,
    skill_catalog: dict,
    skills: list[dict],
    universe: dict,
) -> dict:
    civilization_tech = universe["civilization_tech"]
    source_rows = defaultdict(list)
    for row in civilization_tech["resources"]:
        source_rows[row["code"]].append(row)
    refined_rows = {
        row["code"]: row for row in civilization_tech["refined_resources"]
    }
    production = defaultdict(list)
    for row in index["production"]:
        production[row["resource_code"]].append(row)
    action_skills = defaultdict(set)
    for gate in index["skill_gates"]:
        for action in gate["actions"]:
            action_skills[action].add(gate["skill_code"])

    component_by_code = {item["code"]: item for item in components["components"]}
    artifact_by_code = {
        item["fallback_resource"]["code"]: item
        for item in skill_catalog["capability_artifacts"]
    }
    skill_by_code = {row["code"]: row for row in skills}
    records = []
    kind_counts = defaultdict(int)
    for code_row in sorted(index["resource_code_rows"], key=lambda row: row["code"]):
        code = code_row["code"]
        rows = production[code]
        actions = sorted({action for row in rows for action in row.get("actions", [row["action"]])})
        source_bodies = sorted(
            {row["source_body_name"] for row in rows if row.get("source_body_name")}
        )
        parents = sorted(
            {row["parent_resource_name"] for row in rows if row.get("parent_resource_name")}
        )
        ship_tiers = sorted({row["ship_tier"] for row in rows if row.get("ship_tier")})
        if code in source_rows:
            actions = sorted(set(actions) | {row["action"] for row in source_rows[code]})
            source_bodies = sorted(
                set(source_bodies) | {row["category"] for row in source_rows[code]}
            )
        if code in refined_rows:
            actions = sorted(set(actions) | set(refined_rows[code]["source_routes"]))
        skill_codes = sorted(
            {code for action in actions for code in action_skills.get(action, set())}
        )
        description = ""
        if code in component_by_code:
            item = component_by_code[code]
            kind = "Component"
            skill_codes = sorted(set(skill_codes) | {item["skill_code"]})
            materials = ", ".join(
                f"{part['amount']} {part['name']}" for part in item["materials"]
            )
            description = f"{item['description']} Materials: {materials}. Catalyst: {item['catalyst']['name']}."
        elif code in artifact_by_code:
            item = artifact_by_code[code]
            kind = "Capability artifact"
            skill_codes = sorted(set(skill_codes) | {item["skill_code"]})
            description = "Fixed inputs: " + ", ".join(
                f"{part['amount']} x resource {part['resource_code']}" for part in item["fixed_inputs"]
            )
        elif code <= 4:
            kind = "Base resource"
            description = "Foundational ship or celestial reserve pool."
        elif code in source_rows:
            kind = "Source resource"
            description = "Extracted from " + (", ".join(source_bodies) or "a celestial reserve") + "."
        elif code in refined_rows:
            kind = "Refined resource"
            description = "Refined from " + (", ".join(parents) or "a composite resource") + "."
        else:
            raise ValueError(f"resource code {code} has no catalog classification")
        kind_counts[kind] += 1
        records.append(
            {
                "kind": kind,
                "code": code,
                "name": code_row["name"],
                "description": description,
                "actions": actions,
                "skills": [skill_by_code[skill]["name"] for skill in skill_codes],
                "sources": source_bodies,
                "tiers": ship_tiers,
            }
        )

    for row in skills:
        gated_actions = sorted(
            {
                action
                for gate in index["skill_gates"]
                if gate["skill_code"] == row["code"]
                for action in gate["actions"]
            }
        )
        records.append(
            {
                "kind": "Skill",
                "code": row["code"],
                "name": row["name"],
                "description": row["description"],
                "actions": [row["develop_action"]] + gated_actions,
                "skills": [],
                "sources": [f"Type {'I' * row['civilization_type']} civilization"],
                "tiers": [row["tier"]],
            }
        )

    for body in universe["body_bank"]:
        records.append(
            {
                "kind": "Body",
                "code": body["code"],
                "name": body["name"],
                "description": (
                    f"Occurrence 1:{body['nominal_denominator']:,}; reserves "
                    f"Matter {body['matter']:,}, Crystal {body['crystal']:,}, "
                    f"Gas {body['gas']:,}, Energy {body['energy']:,}."
                ),
                "actions": [
                    f"DetectCelestialSignal_{body['code']:02d}_{body['slug']}",
                    f"ScanCelestialBody_{body['code']:02d}_{body['slug']}",
                ],
                "skills": [],
                "sources": [],
                "tiers": [],
            }
        )

    expected_kinds = {
        "Base resource": 4,
        "Source resource": 149,
        "Refined resource": 316,
        "Component": 45,
        "Capability artifact": 72,
    }
    if dict(kind_counts) != expected_kinds:
        raise ValueError(f"catalog item census drift: {dict(kind_counts)!r}")
    return {
        "summary": {
            "items": len(index["resource_code_rows"]),
            "bodies": len(universe["body_bank"]),
            "components": len(components["components"]),
            "skills": len(skills),
            "artifacts": len(skill_catalog["capability_artifacts"]),
        },
        "records": records,
    }


def catalog_shell(catalog: dict) -> str:
    payload = json.dumps(catalog, ensure_ascii=True, separators=(",", ":")).replace(
        "<", "\\u003c"
    )
    summary = catalog["summary"]
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Microverse Resource Catalog</title><style>
:root{{color-scheme:dark;--void:#0a0d14;--panel:#111722;--panel2:#161d2a;--rule:#263146;--ink:#e8edf5;--dim:#8a99af;--cyan:#7fd1e0;--amber:#c79a4e;--mono:"IBM Plex Mono",ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}}*{{box-sizing:border-box}}html,body{{height:100%;margin:0;overflow:hidden;background:var(--void);color:var(--ink);font:13px/1.45 var(--mono)}}.wrap{{height:100%;display:grid;grid-template-rows:auto minmax(0,1fr)}}.toolbar{{display:flex;align-items:center;gap:10px;padding:8px 12px;border-bottom:1px solid var(--rule);background:#0b111b}}.tabs{{display:flex;gap:3px}}button,select,input{{font:inherit}}.tab{{min-height:34px;padding:8px 15px;border:1px solid var(--rule);border-radius:3px;background:var(--panel);color:var(--dim);cursor:pointer}}.tab[aria-selected=true]{{background:var(--cyan);border-color:var(--cyan);color:#071015}}.totals{{margin-left:auto;display:flex;gap:14px;color:var(--dim);white-space:nowrap}}.totals b{{color:var(--ink)}}#resourceTreeFrame{{width:100%;height:100%;border:0;background:var(--void)}}#catalogPane{{min-height:0;display:grid;grid-template-rows:auto minmax(0,1fr);overflow:hidden}}#catalogPane[hidden],#resourceTreeFrame[hidden]{{display:none}}.filters{{display:grid;grid-template-columns:minmax(180px,1fr) 210px auto;gap:8px;padding:11px;border-bottom:1px solid var(--rule);background:var(--panel)}}.filters input,.filters select{{min-width:0;padding:9px 10px;border:1px solid var(--rule);border-radius:3px;background:var(--void);color:var(--ink)}}#matchCount{{align-self:center;color:var(--dim)}}.rows{{overflow:auto;padding:0 11px 30px}}.row{{display:grid;grid-template-columns:64px minmax(190px,.7fr) minmax(280px,1.5fr);gap:12px;padding:12px 4px;border-bottom:1px solid var(--rule)}}.code{{color:var(--dim)}}.name b{{display:block;font-size:14px}}.kind{{display:inline-block;margin-top:5px;padding:2px 6px;border:1px solid var(--rule);border-radius:2px;color:var(--cyan);font-size:10px;text-transform:uppercase;letter-spacing:.08em}}.detail{{color:var(--dim)}}.meta{{margin-top:5px;font-size:11px;color:#b7c3d3}}.empty{{padding:30px 4px;color:var(--dim)}}@media(max-width:820px){{.totals{{display:none}}.filters{{grid-template-columns:1fr 150px}}#matchCount{{grid-column:1/-1}}.row{{grid-template-columns:48px 1fr}}.detail{{grid-column:2}}}}
</style></head><body><div class="wrap"><header class="toolbar"><nav class="tabs" aria-label="Catalog views"><button class="tab" data-mode="bodies" aria-selected="true">Bodies</button><button class="tab" data-mode="skills" aria-selected="false">Skills</button><button class="tab" data-mode="catalog" aria-selected="false">All items</button></nav><div class="totals"><span><b>{summary['items']}</b> items</span><span><b>{summary['bodies']}</b> bodies</span><span><b>{summary['components']}</b> components</span><span><b>{summary['skills']}</b> skills</span><span><b>{summary['artifacts']}</b> artifacts</span></div></header><iframe id="resourceTreeFrame" src="about:blank" title="Interactive Microverse resource and skill tree"></iframe><section id="catalogPane" hidden><div class="filters"><input id="query" type="search" placeholder="Search names, codes, actions, skills, or sources"><select id="kind"><option value="">All catalog entries</option></select><span id="matchCount"></span></div><div class="rows" id="rows"></div></section></div><script id="catalog-data" type="application/json">{payload}</script><script>
const data=JSON.parse(document.getElementById('catalog-data').textContent),frame=document.getElementById('resourceTreeFrame'),pane=document.getElementById('catalogPane'),query=document.getElementById('query'),kind=document.getElementById('kind'),rows=document.getElementById('rows'),matchCount=document.getElementById('matchCount');
const esc=s=>String(s).replace(/[&<>\"]/g,c=>({{'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'}}[c]));
const kinds=[...new Set(data.records.map(row=>row.kind))].sort();for(const value of kinds)kind.insertAdjacentHTML('beforeend',`<option>${{esc(value)}}</option>`);
function sendMode(mode){{frame.contentWindow?.postMessage({{type:'microverse-tree-mode',mode}},'*')}}
function render(){{const q=query.value.trim().toLowerCase(),wanted=kind.value;const visible=data.records.filter(row=>(!wanted||row.kind===wanted)&&(!q||JSON.stringify(row).toLowerCase().includes(q)));matchCount.textContent=`${{visible.length.toLocaleString()}} entries`;rows.innerHTML=visible.length?visible.map(row=>`<article class="row"><span class="code">#${{row.code}}</span><div class="name"><b>${{esc(row.name)}}</b><span class="kind">${{esc(row.kind)}}</span></div><div class="detail">${{esc(row.description)}}${{row.skills.length?`<div class="meta">Skills: ${{row.skills.map(esc).join(', ')}}</div>`:''}}${{row.sources.length?`<div class="meta">Sources: ${{row.sources.map(esc).join(', ')}}</div>`:''}}${{row.actions.length?`<div class="meta">Actions: ${{row.actions.map(esc).join(', ')}}</div>`:''}}</div></article>`).join(''):'<div class="empty">No matching catalog entries.</div>'}}
for(const tab of document.querySelectorAll('.tab'))tab.addEventListener('click',()=>{{const mode=tab.dataset.mode;for(const item of document.querySelectorAll('.tab'))item.setAttribute('aria-selected',String(item===tab));const all=mode==='catalog';frame.hidden=all;pane.hidden=!all;if(all){{render();query.focus()}}else sendMode(mode)}});query.addEventListener('input',render);kind.addEventListener('change',render);frame.addEventListener('load',()=>sendMode(document.querySelector('.tab[aria-selected=true]').dataset.mode));render();
</script></body></html>'''


def update_deterministic_runtime(
    source: str,
    action_contract: dict,
    resource_catalog: dict,
    universe: dict,
) -> str:
    """Bind browser-side eligibility and previews to the PEXE selector contract."""

    actions = action_contract["actions"]
    detect_rows = [row for row in actions if row["family"] == "detect_signal"]
    scan_rows = [row for row in actions if row["family"] == "scan_body"]
    survey_rows = [row for row in actions if row["family"] == "survey_sector"]
    base_categories = [
        (1, "Planet", "planet"),
        (2, "Star", "star"),
        (3, "Gas Giant", "gas_giant"),
        (4, "Ice Giant", "ice_giant"),
        (5, "Neutron Star", "neutron_star"),
        (6, "Black Hole", "black_hole"),
        (7, "Anomaly", "anomaly"),
        (8, "Megastructure", "megastructure"),
        (9, "Gas Cluster", "gas_cluster"),
        (10, "Stellar Remnant", "stellar_remnant"),
    ]
    categories = {
        code: {
            "category_code": code,
            "name": name,
            "runtime_name": name,
            "remaining_field": f"{stem}_remaining",
            "serial_field": f"next_{stem}_serial",
        }
        for code, name, stem in base_categories
    }
    categories.update(
        {
            int(row["category_code"]): row
            for row in resource_catalog["celestial_categories"]
        }
    )
    if sorted(categories) != list(range(1, 12)):
        raise ValueError("celestial categories must be exactly 1..11")
    if len(detect_rows) != 23 or len(scan_rows) != 23 or len(survey_rows) != 5:
        raise ValueError("deterministic discovery action census drift")
    if sorted(row["candidate_code"] for row in detect_rows) != list(range(23)):
        raise ValueError("detect candidate codes must be exactly 0..22")
    if any(row.get("output_candidate_code") != -1 for row in detect_rows):
        raise ValueError("all detected Signals must remain untyped at candidate_code -1")

    candidate_fields = {}
    for row in detect_rows:
        category = categories[int(row["signal_category_code"])]
        candidate_fields[f"{int(row['candidate_code']):02d}"] = category[
            "remaining_field"
        ]
    category_codes = {
        row["remaining_field"]: int(row["category_code"])
        for row in categories.values()
    }
    category_labels = {
        row["remaining_field"]: row.get("runtime_name", row["name"]).lower()
        for row in categories.values()
    }
    survey_counts = {
        str(int(row["survey_profile"])): row["counts"]
        for row in universe["survey_profiles"]
    }
    runtime_maps = (
        "var Uc="
        + compact_json(candidate_fields)
        + ",Sn="
        + compact_json(category_codes)
        + ",vn="
        + compact_json(category_labels)
        + ",Jn="
        + compact_json(survey_counts)
        + ";"
    )
    source = replace_between(source, "var Uc=", "function zn", runtime_maps)

    selector_runtime = r'''function mvStableBandMatch(A,e){if(!A||!e)return!1;let l=oo(A),c=e.lower_top_limb==null?0n:BigInt(e.lower_top_limb),a=e.upper_top_limb==null?18446744073709551615n:BigInt(e.upper_top_limb);return l>=c&&l<=a}function mvSelectedAction(A,e,l=null){return xl.actions.find(c=>c.family===A&&(!l||l(c))&&mvStableBandMatch(e,c.selector_band))||null}function Wl(A){return A?.stable_identifier?mvSelectedAction("survey_sector",A.stable_identifier)?.name||null:null}function ns(A,e=null){let l=A.predicateSource||"",c=$i(),a=c?N(c,"extraction_amount",10):10,o=l.match(/(?:ship\w*\.)?extraction_amount\s*,\s*0\s*,\s*(\d+)/);if(o&&Number(o[1])!==a)return!1;let d=tA(A);if(e&&d?.selection_mode==="stable_identifier_band_v1"){let t=e.driverObject||e,m=String(d.selector_subject||"").split(".").pop(),n=ae(t,m);if(!mvStableBandMatch(n,d.selector_band))return!1}if(e){let t=N(e.driverObject,"candidate_code"),m=l.match(/(?:body\w*\.)?candidate_code\s*,\s*0\s*,\s*(\d+)/);if(m&&Number(m[1])!==t)return!1}return!0}'''
    selector_start = (
        "function mvStableBandMatch("
        if "function mvStableBandMatch(" in source
        else "function Wl("
    )
    source = replace_between(source, selector_start, "function Po(", selector_runtime)

    life_runtime = r'''function Po(A,e){let l=tA(A),c=e&&e.driverObject;if(!c)return"";if(l?.family==="detect_intelligent_life"){let a=N(c,"candidate_code",-1);if(!l.candidate_codes.includes(a))return"only Ocean and Garden planets can carry intelligent life";if(N(c,"life_stat")!==Number(l.initial_life_stat))return"intelligent life has already been detected";if(!mvStableBandMatch(ae(c,"source_signal_identifier"),l.selector_band))return"this planet's stable-ID band has no intelligent-life signal";if(N(c,"civilization_discovered")>0)return"life has already been scanned"}return l?.family==="discover_satellite"&&N(c,"satellites_remaining")<=0?"no satellites remain to discover":""}'''
    source = replace_between(source, "function Po(", "function Yn(", life_runtime)

    action_router = r'''function Yn(A,e=null){if(g.actionByName.has(A))return A;let l=i.mv.sectors.get(bA(i.focus.x,i.focus.y,i.focus.z,i.focus.t));if(A==="RevealSector")return Wl(l);if(A.startsWith("MaterializeCelestialBody_")){let c=A.slice(25);return[...g.actionByName.keys()].find(a=>a.startsWith(`ScanCelestialBody_${c.slice(0,2)}_`))||null}if(A==="MaterializeCivilization"){let c=e?.driverObject||e,a=c?.class?.name===H.lifeSignal?c:null;if(!a&&c){let o=ae(c,"stable_identifier");a=jA(H.lifeSignal).find(d=>ae(d,"source_body_identifier")===o)||null}a||=jA(H.lifeSignal)[0];return a?mvSelectedAction("materialize_civilization",ae(a,"stable_identifier"))?.name||null:null}let c=A.replace(/[^a-z0-9]/gi,"").toLowerCase();return[...g.actionByName.keys()].find(a=>a.replace(/[^a-z0-9]/gi,"").toLowerCase()===c)||null}'''
    source = replace_between(source, "function Yn(", "Rc=function(e)", action_router)
    source = replace_exact_or_current(
        source,
        "Rc=function(e){let l=Yn(e.action);",
        "Rc=function(e){let l=Yn(e.action,e.driverObject);",
    )

    scan_runtime = r'''function gs(A){let e=String(A).padStart(2,"0");return[...g.actionByName.keys()].find(l=>l.startsWith(`ScanCelestialBody_${e}_`))}function mvSignalStable(A){let e=A?.driverObject||A;return ae(e,"stable_identifier")||T(A?.stable||A?.id||"")}function mvSignalCategory(A){let e=A?.driverObject||A;return Number(A?.category??A?.category_code??N(e,"category_code",-1))}function mvScanContract(A){let e=mvSignalStable(A),l=mvSignalCategory(A);return mvSelectedAction("scan_body",e,c=>Sn[Uc[String(c.candidate_code).padStart(2,"0")]]===l)}function us(A){return A?mvScanContract(A)?.name||null:null}function Ln(A){let e=Na(A);return e.known?e.eligible:null}function Na(A,e=null){let l=A?.driverObject||A;if(!l)return{known:!1,eligible:!1,reason:"The selected Signal object is unavailable."};if(N(l,"candidate_code",-1)!==-1)return{known:!0,eligible:!1,reason:"The selected Signal is already typed and is incompatible with deterministic Scan actions."};let c=mvScanContract(A);if(!c)return{known:!1,eligible:!1,reason:"No deterministic Scan band matches this Signal's stable identifier and category."};let a=String(c.candidate_code).padStart(2,"0"),o=GA(a),d=e==null||Number(e)===Number(c.candidate_code),t=mvSignalStable(A);return{known:!0,eligible:d,candidate:o,commitment:t,target:c.selector_band,reason:d?"":`${o?.name||"This Signal"} is selected by a different stable-ID band.`}}function Cs(A,e){if(tA(A)?.family!=="scan_body")return null;let l=ne(A).findIndex(a=>WA(a)===H.signal);if(l<0)return{known:!1,eligible:!1,reason:"The Scan action has no Signal input."};let c=Ao(e[l]);return Na(c,tA(A).candidate_code)}'''
    source = replace_between(source, "function gs(", "function Dn(", scan_runtime)

    prediction_runtime = r'''function Hn(A,e){let l=new Map,c=A?.driverObject,a=g.classByName.get(H.signal);if(!c||!a||!e.length)return l;let o=[T(c.contentHash),T(a.hash),...e.map(t=>T(t.hash))].join(":"),d=g.signalPredictions.get(o);if(d)return d;try{let t=["x","y","z","epoch"].map(r=>{let I=c._fields?.[r];if(I==null)throw new Error(`Sector is missing ${r}`);return BigInt(I)}),m=[...new Map(e.map(r=>[Number(tA(r)?.signal_category_code),r])).values()].map(r=>{let I=tA(r),G=Number(I.signal_category_code),b=Object.keys(Sn).find(p=>Sn[p]===G),p=`next_${b.replace(/_remaining$/,'')}_serial`;return{action:r,category:G,poolField:b,row:[...t,BigInt(G),BigInt(I.output_candidate_code),BigInt(N(c,p))]}}),n=Dn("signal_commitments",m.flatMap(r=>r.row),7,a.hash),r=new Map;m.forEach((I,G)=>{let b=n[G],p={category:I.category,stable:b.stable,object:b.object},C=Na(p);r.set(I.category,{known:C.known,eligible:C.eligible,candidate:C.candidate,stable:b.stable,object:b.object,reason:C.reason})});for(let I of e){let G=Number(tA(I)?.signal_category_code),b=r.get(G)||{known:!1,eligible:!1,reason:"No deterministic Signal prediction is available for this category."};l.set(I.action.name,b)}}catch(t){for(let m of e)l.set(m.action.name,{known:!1,eligible:!1,reason:`Signal prediction unavailable: ${t.message}`})}return g.signalPredictions.set(o,l),g.signalPredictions.size>32&&g.signalPredictions.delete(g.signalPredictions.keys().next().value),l}'''
    source = replace_between(source, "function Hn(", "Ti=function", prediction_runtime)

    detect_routes = r''',C=[...new Map(g.actions.filter(Q=>{let R=Number(tA(Q)?.signal_category_code),E=Object.keys(Sn).find(X=>Sn[X]===R);return/^DetectCelestialSignal_/.test(Q.action.name)&&$d(Q,H.sector)&&ns(Q)&&G.has(E)}).map(Q=>[Number(tA(Q)?.signal_category_code),Q])).values()]'''
    detect_route_start = (
        ",C=g.actions.filter"
        if ",C=g.actions.filter" in source
        else ",C=[...new Map(g.actions.filter"
    )
    source = replace_between(
        source,
        detect_route_start,
        ',Z=$("Survey contacts"',
        detect_routes,
    )
    detect_panel = r''',Z=$("Survey contacts",`${p} undetected \xB7 ${b-p} detected`),B=Hn(l,C);Z.appendChild(h("div","grp-empty",`${b} category contact${b===1?"":"s"} found. Each untyped Signal and its stable-ID-selected body are calculated locally before a proof begins.`));for(let Q of C){let R=Number(tA(Q)?.signal_category_code),E=Object.keys(Sn).find(y=>Sn[y]===R),X=G.get(E),y=!!X&&X.remaining>0,f=B.get(Q.action.name),S=y&&f?.known&&f.eligible,TA=X?.label||vn[E]||"celestial";if(!y)continue;Z.appendChild(j({label:`Detect ${TA} signal`,action:Q.action.name,ico:"scan",disabled:!S,cls:S?"go":"",sub:f?.known?f.eligible?`${f.candidate?.name||"Body type"} selected by stable ID \xB7 ${gA(Q)}`:"no deterministic body band":`${TA} contact \xB7 eligibility unavailable`,title:f?.reason||`Prospective untyped Signal ${Ze(f?.stable)} deterministically scans as ${f?.candidate?.name||"one body type"}.`}))}e.appendChild(Z)'''
    source = replace_between(
        source,
        ',Z=$("Survey contacts"',
        "}if(l.signals.length)",
        detect_panel,
    )

    signal_inventory = r'''for(let C of jA(H.signal)){let Z=bl(C),B=i.mv.sectors.get(bA(Z.x,Z.y,Z.z,Z.t));if(!B)continue;let V={id:ae(C,"stable_identifier")||C.contentHash,code:"-1",category:N(C,"category_code",-1),driverObject:C,driverFile:C.fileName},Q=Na(V);Q.known&&Q.eligible&&Q.candidate&&(V.code=String(Q.candidate.code).padStart(2,"0"),B.signals.push(V))}'''
    source = replace_between(
        source,
        "for(let C of jA(H.signal)){",
        "i.charts.clear();",
        signal_inventory,
    )

    source = replace_exact_or_current(
        source,
        "life:l.life,lifeScanned:!1",
        'life:A.driverObject?N(A.driverObject,"life_stat",l.life):l.life,lifeScanned:!1',
    )
    source = replace_exact_or_current(
        source,
        "let t=to(a.class.name);",
        "let t=to(a.class.name,{driverObject:a});",
    )

    visual_by_slug = {
        "RedDwarf": "star",
        "MainSequenceStar": "star",
        "GiantStar": "star",
        "RockyPlanet": "rocky",
        "OceanPlanet": "rocky",
        "GardenPlanet": "rocky",
        "GasGiant": "giant",
        "IceGiant": "ice",
        "BarrenPlanet": "rocky",
        "NeutronStar": "pulsar",
        "BlackHole": "well",
        "Anomaly": "anomaly",
        "Megastructure": "derelict",
        "GasCluster": "nebula",
        "StellarRemnant": "pulsar",
        "AsteroidBelt": "belt",
        "VolcanicPlanet": "rocky",
        "Nebula": "nebula",
        "CometCluster": "ice",
        "BrownDwarf": "star",
        "WhiteDwarf": "pulsar",
        "Magnetar": "pulsar",
        "WormholeMouth": "anomaly",
    }
    body_visuals = {
        f"{int(row['code']):02d}": visual_by_slug[row["slug"]]
        for row in universe["body_bank"]
    }
    source = replace_between(
        source,
        "var cs=",
        "function $m(",
        "var cs=" + compact_json(body_visuals) + ";",
    )
    return source


def build_updated_html(source: str) -> tuple[str, dict]:
    action_contract = load_json(GENERATED / "action-contract.json")
    body_bank = load_json(GENERATED / "body-bank.json")
    warp_contract = load_json(GENERATED / "warp-coordinate-contract.json")
    time_contract = load_json(GENERATED / "time-coordinate-contract.json")
    universe = load_json(GENERATED / "universe-contract.json")
    index = load_json(CATALOG / "microverse-catalog-index-v2.json")
    resource_catalog = load_json(CATALOG / "microverse-resource-tree-v2.json")
    component_catalog = load_json(CATALOG / "microverse-component-tree-v2.json")
    skill_catalog = load_json(CATALOG / "microverse-skill-tree-v2.json")
    manifest = tomli.loads((ROOT / "manifest.toml").read_bytes().decode("utf-8"))
    skills = skill_rows(skill_catalog)
    classes = class_contract(manifest)

    if len(action_contract["actions"]) != len(manifest["actions"]):
        raise ValueError("action contract and manifest action counts differ")
    if [row["name"] for row in action_contract["actions"]] != [
        row["name"] for row in manifest["actions"]
    ]:
        raise ValueError("action contract and manifest action order differ")

    resource_rows = sorted(index["resource_code_rows"], key=lambda row: row["code"])
    if len(resource_rows) != 586:
        raise ValueError("resource index must contain 586 unique item codes")
    composite_codes = {
        row["code"]
        for row in universe["civilization_tech"]["resources"]
        if row.get("composite")
    }
    resource_pairs = [
        [
            row["code"],
            {
                "code": row["code"],
                "display_name": row["name"],
                "composite": row["code"] in composite_codes,
            },
        ]
        for row in resource_rows
    ]

    _, _, viewer_b64 = js_string_span(source, "var ResourceTreeViewerB64=")
    viewer = base64.b64decode(viewer_b64).decode("utf-8")
    viewer, tree_counts = updated_tree_viewer(
        viewer, resource_catalog, skills, universe, component_catalog, skill_catalog
    )
    catalog = catalog_records(index, component_catalog, skill_catalog, skills, universe)
    shell = catalog_shell(catalog)

    updated = source
    for prefix, value in (
        ("var Xo=", action_contract),
        ("var Qo=", body_bank),
        ("var ho=", warp_contract),
        ("var Eo=", time_contract),
        ("var Vo=", universe),
        (",ta=", classes),
    ):
        updated = replace_balanced_assignment(updated, prefix, compact_json(value))

    ma_start = updated.find("ma=")
    ma_end = updated.find(",Ec=", ma_start)
    if ma_start < 0 or ma_end < 0:
        raise ValueError("runtime skill map assignment was not found")
    updated = updated[:ma_start] + "ma=" + compact_json(skills) + updated[ma_end:]
    ec_start = updated.find("Ec=new Map(")
    ec_end = updated.find("function FA", ec_start)
    if ec_start < 0 or ec_end < 0:
        raise ValueError("runtime resource map assignment was not found")
    updated = (
        updated[:ec_start]
        + "Ec=new Map("
        + compact_json(resource_pairs)
        + ");"
        + updated[ec_end:]
    )
    updated = update_deterministic_runtime(
        updated,
        action_contract,
        resource_catalog,
        universe,
    )

    module_hash = manifest["plugin"]["module_hash"]
    pexe_hash = sha256((ROOT / "microverse.pexe").read_bytes())
    updated = replace_once_regex(
        updated, r'var Ml="microverse\.[0-9a-f]{64}"', f'var Ml="microverse.{module_hash}"'
    )
    updated = replace_once_regex(updated, r'\bec="[0-9a-f]{64}"', f'ec="{module_hash}"')
    updated = replace_once_regex(updated, r'\bsa="[0-9a-f]{64}"', f'sa="{pexe_hash}"')
    updated = replace_once_regex(
        updated,
        r'var _A=Nl,jd=1e12,aa=\d+,Rm=\d+;',
        f'var _A=Nl,jd=1e12,aa={len(action_contract["actions"])},Rm={classes["class_count"]};',
    )
    updated = replace_once_regex(
        updated,
        r'FA\(xl\.actions\.length===\d+,"action count"\)',
        f'FA(xl.actions.length==={len(action_contract["actions"])},"action count")',
    )
    updated = replace_once_regex(
        updated,
        r'FA\(ta\.classes\.length===\d+,"class count"\)',
        f'FA(ta.classes.length==={classes["class_count"]},"class count")',
    )
    updated = replace_once_regex(
        updated,
        r'FA\(Ec\.size===\d+,"resource count"\)',
        f'FA(Ec.size==={len(resource_rows)},"resource count")',
    )
    updated = replace_once_regex(
        updated,
        r'FA\(ma\.length===\d+,"technology skill count"\)',
        f'FA(ma.length==={len(skills)},"technology skill count")',
    )

    warp_uses = sum(row["uses"] for row in warp_contract["destinations"])
    time_uses = sum(row["uses"] for row in time_contract["destinations"])
    updated = replace_once_regex(
        updated,
        r"var cd=A=>A\.destinations\.reduce\(\(e,l\)=>e\+Number\(l\.(?:weight_bps|uses)\),0\);",
        "var cd=A=>A.destinations.reduce((e,l)=>e+Number(l.uses),0);",
    )
    updated = replace_once_regex(
        updated,
        r'FA\(cd\(Qc\)===[0-9e]+,"warp (?:weight|use) total"\)',
        f'FA(cd(Qc)==={warp_uses},"warp use total")',
    )
    updated = replace_once_regex(
        updated,
        r'FA\(cd\(hc\)===[0-9e]+,"time (?:weight|use) total"\)',
        f'FA(cd(hc)==={time_uses},"time use total")',
    )
    selector_start = updated.find("function Vn(")
    selector_end = updated.find("function Wn(", selector_start)
    if selector_start < 0 or selector_end < 0:
        raise ValueError("coordinate reveal action selector was not found")
    explicit_selector = (
        'function Vn(A,e){let l=N(A,"source_pool"),c=(e.destinations||[])'
        ".filter(a=>Number(a.minimum_source_pool_inclusive)<=l)"
        ".sort((a,o)=>Number(o.minimum_source_pool_inclusive)-"
        "Number(a.minimum_source_pool_inclusive)||Number(a.code)-Number(o.code));"
        "return c[0]||null}"
    )
    updated = updated[:selector_start] + explicit_selector + updated[selector_end:]

    updated = replace_js_string(
        updated,
        "var ResourceTreeViewerB64=",
        base64.b64encode(viewer.encode("utf-8")).decode("ascii"),
    )
    updated = replace_js_string(updated, "var Wo=", shell)
    if not WASM.exists():
        raise ValueError(f"compiled commitment WASM is missing: {WASM}")
    wasm = WASM.read_bytes()
    if wasm[:4] != b"\x00asm":
        raise ValueError("compiled commitment payload is not a WASM module")
    throw_imports = {
        item.decode("ascii")
        for item in re.findall(
            rb"__wbg___wbindgen_throw_[0-9a-f]{16}",
            wasm,
        )
    }
    if len(throw_imports) != 1:
        raise ValueError(
            f"compiled commitment WASM has unexpected throw imports: {throw_imports!r}"
        )
    throw_import = throw_imports.pop()
    updated, throw_import_count = re.subn(
        r"__wbg___wbindgen_throw_[0-9a-f]{16}",
        throw_import,
        updated,
    )
    if throw_import_count < 1:
        raise ValueError("commitment WASM throw import was not found in the UI loaders")
    updated = replace_js_string(
        updated, "var ym=", base64.b64encode(wasm).decode("ascii")
    )

    report = {
        "actions": len(action_contract["actions"]),
        "classes": classes["class_count"],
        "resource_items": len(resource_rows),
        "skills": len(skills),
        "components": len(component_catalog["components"]),
        "capability_artifacts": len(skill_catalog["capability_artifacts"]),
        "bodies": len(universe["body_bank"]),
        "module_hash": module_hash,
        "pexe_sha256": pexe_hash,
        "warp_destination_uses": warp_uses,
        "time_destination_uses": time_uses,
        "commitment_wasm_bytes": len(wasm),
        "commitment_wasm_sha256": sha256(wasm),
        "commitment_wasm_throw_import": throw_import,
        "tree": tree_counts,
    }
    return updated, report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail if microverse.html is stale")
    args = parser.parse_args()
    source = HTML.read_bytes().decode("utf-8")
    updated, report = build_updated_html(source)
    if args.check:
        if updated != source:
            raise SystemExit("microverse.html is stale; run tools/update_microverse_html.py")
    elif updated != source:
        HTML.write_bytes(updated.encode("utf-8"))
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
