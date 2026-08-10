# Product Requirements Document: Microverse Rhai Refactor

Status: Complete; authoritative economy release and compatibility profile validated  
Date: 2026-08-10  
Scope: `target/rhai-expansion-worktree`  
Primary source of truth: `tools/generate_microverse.py`  
Generated production artifact: `plugin.rhai`

## 1. Executive summary

Refactor the generated Microverse Rhai to reduce source size, line count, repeated
wrapper scaffolding, and a small number of proven redundant constraints without
changing gameplay, action identity, object roles, proof meaning, SDK behavior, or
the deterministic exploration model.

The implementation must remain a fully unrolled, fixed-arity, straight-line state
machine. The refactor is successful only when the same 1,650 public actions expose
the same direct roles, literals, outputs, costs, VDF work, lineage, depletion, and
state transitions and the complete existing validation campaign remains green.

This is a generator refactor. Do not hand-edit generated production Rhai as the
primary implementation technique.

## 2. Background

The deterministic-selection redesign is correct and fully tested, but it retained
the established wrapper architecture to avoid changing SDK/compiler behavior while
fixing the stable-identifier selection defect.

Approved baseline production Rhai:

- 764,380 bytes
- 28,710 nonblank code lines
- 1,677 functions
- 1,650 public action entrypoints
- 27 helpers
- 732,497 bytes and 27,770 LOC in action bodies
- 30,206 bytes and 940 LOC in helpers
- SHA-256:
  `439ff26a7c97b56544d7d5222191ee61611dde956c5a9e80e8fdc9326390f884`

Six generated families account for 633,806 bytes, or 82.9% of the plugin, and
25,203 LOC, or 87.8% of its lines:

| Family | Actions | LOC | Bytes |
|---|---:|---:|---:|
| Extraction and refinement | 687 | 14,589 | 335,594 |
| Deterministic reveal wrappers | 595 | 3,148 | 112,314 |
| Signal detection | 23 | 1,334 | 56,687 |
| Component fabrication | 90 | 3,060 | 48,103 |
| Derived skills | 72 | 1,550 | 44,162 |
| Capability artifacts | 72 | 1,522 | 36,946 |

A literal-normalized census found 34 recurring action shapes covering 1,605 of
1,650 actions. The action-specific literals are meaningful catalog data; the
repeated straight-line scaffolding around them is the refactor target.

## 3. Problem statement

The generator emits direct action roles correctly, but repeats gates, witness
plumbing, core calls, VDF tails, key-rotation temporaries, and output assembly in
hundreds of wrappers. This creates four problems:

1. Source-size pressure against the production plugin limit.
2. Review difficulty because meaningful literal changes are buried in boilerplate.
3. Audit maintenance cost because exact-source validators encode several rendering
   variants of the same semantics.
4. Avoidable runtime/proof work from a small number of duplicate constraints.

The refactor must solve these problems without replacing explicit deterministic
actions with runtime selection logic.

## 4. Product principles

1. **Explicit choice, proven eligibility, finite depletion.** Named actions select
   deterministic outcomes; authenticated state proves eligibility and pays costs.
2. **No new SDK assumptions.** Use only Rhai and ActionContext patterns already
   compiled and exercised by the existing package and test shards.
3. **Roles stay direct.** Every public action continues to declare
   `action.output`, `action.input`, and `action.mutate` directly in its wrapper and
   in the same order.
4. **Fixed arity and straight-line execution.** Helpers may accept fixed literal or
   object parameters. They may not introduce control flow or runtime lookup.
5. **Generator first.** Modify generator templates and audits, then regenerate
   `plugin.rhai`, `manifest.toml`, contracts, and the PEXE.
6. **Fail closed.** Any unexplained role, literal, transform, proof, or census drift
   blocks the phase.
7. **One writer per source file.** Parallel work may inspect or validate disposable
   copies, but concurrent agents must not edit the generator or production output.
8. **Readable generated code.** Reduce size through shared straight-line structure,
   not cryptic naming or aggressive line joining. A developer must be able to trace
   an action wrapper into its helper and understand every proof-relevant literal.

## 5. Goals

### 5.1 Required goals

- Reduce `plugin.rhai` to no more than 600,000 bytes.
- Reduce `plugin.rhai` to no more than 15,000 nonblank code lines.
- Preserve all 1,650 public action names and manifest ordering.
- Preserve exact direct object-role order for every action.
- Preserve deterministic action identity and every authored literal outcome.
- Preserve all classes, fields, action costs, reserve debits, VDF iterations,
  progression gates, capacity gates, lineage, and state transitions.
- Remove only proof constraints demonstrated to be redundant.
- Keep all four authoritative resource, component, skill, and warp catalog JSON
  inputs byte-identical unless a separate, explicitly approved catalog change is
  requested. The generator-produced aggregate index may change helper/provenance
  metadata while preserving catalog semantics and fixed literals.
- Reproduce the complete build, static-validation, and runtime-validation campaign.
- Make generated Rhai and generator templates clean and consistent for human review.
- Retain minimal comments only where they explain a non-obvious SDK constraint,
  proof invariant, security boundary, or intentional non-optimization.

### 5.2 Stretch goals

- Reach 560,000-580,000 bytes without moving roles into helpers.
- Reach 13,500-14,500 LOC while retaining one statement per line where practical.
- Add per-family byte and LOC budgets so future generation fails before source
  bloat reaches the package limit.

### 5.3 Non-goals

- Changing the SDK, Driver, or UI.
- Changing the deterministic gameplay design.
- Reducing the number of public actions.
- Collapsing reveal actions into a table, action-name resolver, or random selector.
- Changing classes, schemas, recipes, balances, destinations, milestones, or costs.
- Producing or submitting real proofs.
- Optimizing the legacy pending validation-report scaffold or README.
- Rewriting the Python generator purely to reduce Python LOC when generated Rhai is
  unchanged.
- Source minification that materially reduces readability, diagnostics, or review
  quality.

## 6. Hard technical constraints

The implementation must not introduce:

- SDK changes or patches
- loops
- conditional branching
- recursion
- action-to-action calls
- subactions
- runtime maps or tables
- modulo-based selection
- dynamic dispatch
- action-name inspection
- variable-length recipes or inputs
- movement of direct action roles into helpers
- new output, input, or mutate roles
- role reordering
- direct output assignment from unbound input fields
- removal of Raw lineage bridges
- removal of key rotation, fixed-version gates, co-location proofs, depletion guards,
  or VDF work

The SDK/compiler flattens variable names across the transitive helper graph. Every
new helper must be called at most once per action path unless its local witness names
are guaranteed unique after flattening. The flattened-witness audit is mandatory.

### 6.1 Readability and commenting standard

- Use descriptive helper names that identify the lifecycle or proof responsibility,
  such as `extract_composite_action_core`; avoid single-letter helper names.
- Keep public action wrappers visually uniform: direct roles first, then one or more
  fixed-arity helper calls, followed only by action-specific work that cannot be
  safely shared.
- Use descriptive local names inside helpers. Existing compact role aliases may
  remain in already-approved dense recipe wrappers, but new aliases must not make
  role identity ambiguous.
- Prefer one logical statement per line. Multi-line argument lists are appropriate
  when they make role or literal order easier to audit.
- Group helper parameters in role order, followed by gates, identifiers, quantities,
  and VDF literals. Do not reorder parameters solely to save bytes.
- Add comments sparingly. A comment is justified only when it records:
  - an immutable SDK/compiler behavior;
  - why an apparently redundant witness or update is security-critical;
  - why an optimization was intentionally rejected;
  - an ordering requirement that is not obvious from the code; or
  - a proof/state invariant that a future maintainer could otherwise break.
- Do not add comments that restate the next line, narrate straightforward plumbing,
  duplicate catalog data, or preserve temporary implementation history.
- Comments are authored in generator templates so regeneration is deterministic.
- Keep detailed rationale in this PRD and tests; keep generated Rhai comments
  minimal and local to the invariant they protect.
- The refactor review must include a human-readability pass over representative
  extraction, refinement, detection, Survey, component, skill, and reveal actions.

## 7. Baseline release tuple

The refactor begins from this exact approved state:

| Artifact | SHA-256 |
|---|---|
| `plugin.rhai` | `439ff26a7c97b56544d7d5222191ee61611dde956c5a9e80e8fdc9326390f884` |
| `manifest.toml` | `10785ac89122b819c77cd09c9ed3739e557e4e320f88c8d419cbdc1124cf9fab` |
| `microverse.pexe` | `5587700f32fa9716a42941b7533b6072f484682526f46d0b77cabb985d7f0564` |
| Action contract | `3da2b6df478ea0354517283476721c51c80a8d65edff956594591c2f81b6da29` |
| Universe contract | `38063ca2f5948fa4ed0a3b40a18426c89255f9e116a49e1e9089cabc88fbb0c3` |
| Schema counts | `c2a845287737c3df45eb6784d9e688898a4eaa1af4a7ec9a7d6a367526fb8a61` |
| Catalog index | `4da88f8a1c43e61c3f18507f1a909542f0f1ad7ce79a536195d423c31d094641` |
| Resource tree | `578de10b58f49c7f35310dc984bb89ce98904aaca3f276966f75cd236b564ab9` |
| Skill tree | `96bc181eb29f64b41347118e2831b711e680bf10a41fd12a24109f2be1a1e57a` |

Baseline validation:

- Strict validator: 47,068 checks, zero errors, zero warnings.
- Generator/tooling tests: 51/51 passed.
- Production build and independent installed-rc.43 `--check`: byte-identical.
- Retained runtime: 1,142/1,142 passed.
- Contract matrix: 2,027/2,027 passed.
- Combined runtime: 3,169/3,169 passed with zero incomplete rows or integrity
  failures.
- All runtime evidence was mock-only, with no network, state submission, or external
  publication.

## 8. Workstreams, frozen results, and acceptance criteria

Savings estimates are phase-local. Measure generated source after every phase;
do not add estimates. “Current” below means the profile-selected generated
package, not the approved release tuple in Section 7.

### Phase 0: Freeze measurements and budgets

#### Work

- Add a deterministic family census for bytes, LOC, action count, helper count,
  direct-role order, Intro calls, VDF calls, `var_assign` bridges, key rotations,
  output closure, and flattened witness names.
- Store phase measurements in a generated machine-readable refactor report.
- Add passing baseline/regression ceilings for the whole plugin and the six largest
  families, plus separately recorded final targets. Tighten monotonic ceilings after
  each successful phase; do not apply the final 600 KB/15K targets to the unchanged
  baseline.

#### Acceptance

- The unchanged baseline regenerates byte-exactly.
- All baseline hashes and counts match Section 7.
- Budget tooling does not mutate production source.

### Phase 1: Remove proven redundant proof work

#### Work

Remove only the repeated `parent.schema_version == 2` assertion in
`refine_resource_core` and the repeated permit schema assertion in
`authorize_large_ship_permit_core`; `prove_fixed_versions` already proves both.
Keep the exact witnessed capacity topology in all chart/coordinate paths and reject
reintroduction of the two duplicate assertions in source-shape audits.

#### Expected result

- Completed: 327 fewer logical `Sum` constraints across the affected actions.
- No unsafe copy, role, output, cost, VDF, or state-transition change.
- The capacity-literal experiment was reverted. Installed rc.43 rejects
  `ExtractAnomalyTimeCoordinate` with `TooManyTotalArgsInChainLink` (`5` public +
  `4` private arguments, maximum `8`). The witnessed-copy form is the only
  compile-proven topology and must remain.

#### Acceptance

- Normalized resolved final fields, dependency relations, gates, update order, and
  state transitions compare exactly. Source provenance hashes are regenerated
  because helper paths and expressions intentionally change.
- Physical source-site and transitive logical proof deltas are reported separately.
- Focused refinement, permit, v1 coordinate, v1 time-coordinate, v2 chart, and v2
  epoch-chart cases pass before broader generation.

### Phase 2: Simplify proof-neutral temporaries

#### Work

Canary nested literal-cost VDF updates and one-use random-value inlining only under
installed rc.43 compilation and exact source/proof audits.

#### Expected result

- Blocked with zero adoption: both nested VDF and inline random forms panic the
  installed rc.43 formatter (`fmt_podlang.rs`, missing key). Keep the named VDF
  temporary/work update and random/`rotate_key` pair.

#### Fallback

If nested evaluation exposes any compiler, borrow, attribution, or audit ambiguity,
keep the current two-statement VDF form. Do not infer new SDK behavior to obtain the
saving.

### Phase 3: Factor detection and Survey scaffolding

#### Work

- Completed: all 23 Detect wrappers route through `detect_signal_core`; all five
  Survey wrappers route through the straight-line 24-zero helper. Direct roles,
  candidate/remaining/serial literals, milestone writes, and Survey count/profile
  writes remain explicit and audited.

#### Expected result

- Completed. The source-level savings are incorporated into the Phase 4 package
  measurements; no separate Phase 3 estimate is a release budget.

#### Acceptance

- Direct roles and order remain exact.
- The shared Survey helper proves exactly `sector_type`, `survey_profile`, the 11
  configured category remaining fields (including `minor_body_field_remaining`),
  and the 11 configured category serial fields (including
  `next_minor_body_field_serial`) equal zero. The revision increment remains
  outside this helper.
- All candidate codes, counters, serial fields, remaining fields, and Survey profile
  values match the baseline action contract.
- No helper is called more than once on an action path.

### Phase 4: Add role-preserving resource adapters

#### Work

Completed: refactored `extract_source` and `refine_resource_source`. Every one of
the 687 extraction/refinement wrappers retains direct roles and calls exactly one
fixed-arity adapter for:

1. Base direct extraction
2. Body-specific direct extraction
3. Composite extraction
4. Refinement

Adapters may contain repeated candidate/skill gates, calls to existing cores, VDF
work, and final updates. They may not select behavior at runtime. Use separate
helpers where arity, role mode, VDF owner, VDF cost, or final update topology
differs. Every helper-owned `intro_vdf` uses a physical integer literal; do not pass
the VDF difficulty as a runtime helper parameter without a separately approved
compiler canary.

#### Frozen bulk result

| Profile | Source bytes | Nonblank LOC | Helpers | Physical VDF sites |
| --- | ---: | ---: | ---: | ---: |
| economy | 645,577 | 22,533 | 20 | 303 |
| current | 629,030 | 22,199 | 6 | 268 |

The active economy helper census is `Sum=652`, `Gt=98`, `unsafe=312`,
`random=78`, `var_assign=17`, `rotate_key=56`, `intro_vdf=303`, and
`intro_lt_eq_u256=1`. Current is `Sum=574`, `Gt=74`, `unsafe=288`,
`random=66`, `var_assign=17`, `rotate_key=44`, `intro_vdf=268`, and
`intro_lt_eq_u256=1`. Logical proof counts, direct roles, output closure, and
catalog literals are zero-delta from their respective profile baselines.

Installed rc.43 primary, prime, and independent `--check` builds are byte-identical
per profile: economy `67,307 B`, SHA-256
`0011b3fdf5f3557415f6a25e52e926c6c1df353e6df6303c8ba17f6e41eaac80`; current
`66,395 B`, SHA-256
`2c5d2d1d84a981ad0ef5e1915a3b7cbf17a121e72560f1fc4828dfaee2f7e5ca`.

#### Acceptance

- All 687 action entrypoints remain present and ordered.
- Exact candidate, resource, parent, child-slot, field-name, ship-tier, amount,
  split, skill, and VDF literals match the baseline contract.
- All direct role declarations remain in wrappers.
- Reserve depletion, nonnegative gates, output quantities, and replacement Ship
  closure remain exact.

#### Phase 4 completed canary architecture (authoritative)

The completed canary emitted only the inventory for its selected VDF profile, did
not emit dormant helpers from the other profile, and routed exactly one
representative wrapper through each helper before family-wide adoption.

| Profile | Fixed helper variants | Representative routes |
| --- | --- | --- |
| economy | `extract_base_vdf_{2,4,8}_core` | `ExtractGas`, `ExtractEnergy`, `ExtractMatter` |
| economy | `extract_direct_body_vdf_{2,4,12,20,32}_core` | `ExtractOceanPlanetWater`, `ExtractRedDwarfRadiantEnergy`, `ExtractRedDwarfFlareSpectrumData`, `ExtractNeutronStarGravitationalData`, `ExtractMegastructureArchiveData` |
| economy | `extract_composite_vdf_{2,4,8,12,20,32}_core` | `ExtractOceanPlanetAtmosphericGas`, `ExtractOceanPlanetSeawaterMinerals`, `ExtractRockyPlanetFerrousOre`, `ExtractRedDwarfFusionGas`, `ExtractNeutronStarRProcessEjecta`, `ExtractMegastructureStructuralSalvage` |
| economy | `refine_resource_vdf_{2,4,8,12,20,32}_core` | `RefineAtmosphericGasToNitrogen`, `RefineSeawaterMineralsToSodiumChloride`, `RefineFerrousOreToIron`, `RefineFusionGasToHydrogen`, `RefineRProcessEjectaToOsmium`, `RefineStructuralSalvageToSteel` |
| current | `extract_base_vdf_{4,8,12}_core` | `ExtractMatter`, `ExtractCrystal`, `ExtractEnergy` |
| current | `extract_direct_body_no_vdf_core`, `extract_composite_no_vdf_core`, `refine_resource_no_vdf_core` | `ExtractRedDwarfRadiantEnergy`, `ExtractRedDwarfFusionGas`, `RefineFusionGasToHydrogen` |

The exact fixed signatures are:

```text
base(action,next_ship,resource,ship,body,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount)
body(action,next_ship,resource,ship,body,candidate_code,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount)
composite(action,next_ship,composite_resource,ship,body,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount)
refine(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type)
```

VDF helpers own a literal `intro_vdf(N, body|parent)` followed by the named
two-line `work` update. No helper accepts a VDF parameter, branches, maps,
dynamic dispatch, nested builtins, or object roles. No-VDF helpers contain no
Intro or `work` update. Their wrappers retain the four direct roles in order,
all fixed literals, and exactly one adapter call.

The later economy caller distribution is base `{2:3,4:3,8:6}`; direct-body
`{2:3,4:12,12:44,20:17,32:1}`; composite
`{2:17,4:55,8:98,12:64,20:24,32:16}`; and refinement
`{2:12,4:63,8:102,12:66,20:63,32:18}`. The current distribution is base
`{4:3,8:6,12:3}`, direct-body `77`, composite `274`, and refinement `324`.

### Phase 5: Factor components, derived skills, and capability artifacts

#### Work

The frozen canary has 20 fixed helpers. All wrappers retain direct roles and make
one helper call; helpers own only their existing core/evidence/catalyst calls and a
literal-cost named VDF temporary followed by its `work` update. No helper accepts a
VDF cost parameter, branches, maps, dispatches dynamically, or owns action roles.

| Family | Helper shapes | Canary actions |
| --- | --- | --- |
| Components | reusable/final catalyst × costs `8`, `12`, `32` | `StructuralAlloyReusable`, `StructuralAlloyFinal`, `FusionCellReusable`, `FusionCellFinal`, `NeutronArmourReusable`, `NeutronArmourFinal` |
| Derived skills | 2-evidence and 3-evidence × costs `8`, `12`, `32` | `StructuralMetallurgy`, `PhotonicMaterials`, `DegenerateMatterScience`, `RadiationProtection`, `IntegratedIndustrialSystemsMastery`, `ProgrammableMatterMastery` |
| Capability artifacts | 1-evidence at `8/12/32`; 2-evidence at `8/12/32`; 3-evidence at `12/32` | `ReinforcedHullFrame`, `AdaptiveOptic`, `DegenerateContainmentCell`, `HabitatFoundation`, `PlasmaContainmentRing`, `TradeNetworkCharter`, `OrbitalFoundryCore`, `ProgrammableMatterMatrix` |

The canary must compile/check a full package before bulk routing. Bulk covers 234
actions: 90 components, 72 derived skills, and 72 capability artifacts. The frozen
logical VDF distribution is cost `8=66`, `12=78`, `32=90`, for 4,344 iterations.
Status: complete. All 234 wrappers use the frozen 20-helper inventory, and both
profiles passed source, semantic, compiler, and shard validation.

#### Result

- Economy after Phase 5 bulk: `628,323 B` and `19,801` nonblank LOC.
- Current compatibility profile after Phase 5 bulk: `611,776 B` and `19,467`
  nonblank LOC.

#### Acceptance

- Exact material codes, quantities, catalyst mode, evidence order, skill codes,
  uses, output codes, and VDF iterations match the baseline.
- Reusable/final state transitions remain distinct.
- All negative missing-input and wrong-class cases remain exact.

### Phase 6: Required conservative movement/timewarp extraction and layout cleanup

#### Work

- Extract only proven repeated movement/timewarp scaffolding into fixed-arity,
  straight-line helpers; keep roles, action-specific literals, lineage, and final
  updates in their existing authorized locations.
- Apply readable token/simple-wrapper layout cleanup: remove only redundant layout
  and repeatable wrapper plumbing, retain descriptive identifiers, statement
  boundaries, and the minimal invariant comments required by Section 6.1.
- Do not run a general minifier, join the plugin into long lines, or shorten names
  solely for bytes.

#### Expected result

- Frozen economy source target after Phases 5-6: `599,317 B` and `12,758`
  nonblank LOC. Movement/timewarp extraction supplies the remaining structural
  saving; readable token/simple-wrapper cleanup is limited to the audited
  residual saving.

#### Acceptance

- Canary each fixed helper against installed rc.43, direct-role/literal/output and
  flattened-witness audits, then run a full-package primary/prime/`--check`
  byte-equality build before bulk routing.
- Fallback: retain the existing wrapper shape for any canary that changes
  compiler argument topology, source attribution, proof census, or readability.
- Compiler diagnostics, source-to-contract extraction, and representative wrapper
  review must remain usable without consulting the Python generator.

#### Implemented source ledger

The fixed movement/timewarp canaries compiled under rc.43 in both profiles before
bulk routing. Authoritative generation, primary builds, independent primed
`--check` builds, byte comparison, strict validation, and runtime evidence now bind
the following source ledger.

| Profile | Bytes | Nonblank LOC | SHA-256 | Actions | Helpers |
|---|---:|---:|---|---:|---:|
| economy | 599,317 | 12,758 | `2e9f6416d12963273fa7bde5474bbfaad4d81e42010f3862654bd1ad2e423849` | 1,650 | 75 |
| current | 591,418 | 12,630 | `3955e24fb567ecfe9a942f61c761e2dffb8a6f7d6b049b6bf2393ecf2432f1d1` | 1,638 | 55 |

Economy routes all 18 movement wrappers through one direction helper and one
fixed `4`/`12`/`28` VDF helper, and all three TimeWarp wrappers through the
common epoch helper plus the matching fixed VDF helper. TimeWarp retains its
literal `1`/`10`/`100` epoch Sum in the wrapper. The resulting caller ledger is
`9` positive, `9` negative, `3` epoch, and `7` callers for each VDF helper.
Current emits and routes none of these six helpers.

Economy physical proof ownership is `586` Sum, `64` Gt, `278` unsafe, `60`
random, `17` var-assign, `38` rotate-key, `71` VDF, and `1` U256 threshold.
Its logical ledger remains `34,774`, `1,490`, `15,549`, `2,869`, `1,419`,
`2,888`, `1,352`, and `23` respectively. Current physical ownership remains
`574`, `74`, `288`, `66`, `17`, `44`, `54`, and `1`; its logical ledger remains
`34,714`, `1,466`, `15,525`, `2,857`, `1,419`, `2,864`, `659`, and `23`.

The layout pass is string/comment-aware and token-equivalent. It removes token
whitespace across actions and common helpers without changing statement or
string-literal order. Only the exact 687 Phase 4 and 234 Phase 5 adapter-only
wrappers receive a layout join: direct roles remain one declaration per line,
the sole adapter call is one logical line, and the structural closing brace is
attached to that call. Helpers and complex actions receive no line joining.
All generated lines are at most 278 characters and these 921 simple wrappers
are at most 144. The pre-layout ledgers are 620,127 B/19,595 LOC for economy and
611,776 B/19,467 LOC for current.

### Phase 7: Deferred experiments

The following are not part of the required refactor and require separate approval:

- Consolidating the three Materialize bodies into one helper. The Raw LifeSignal
  identity bridge is security-critical and the saving is small.
- Replacing placeholder output sets plus witnessed updates in link/rendezvous
  constructors. Existing validators intentionally bind that topology.
- Moving action roles into helpers. This could cut the plugin toward 300-330 KB but
  weakens direct-role auditing and introduces unnecessary compiler risk.
- Directly assigning output fields from input object fields.
- Combining two object-entry references into one Sum statement.
- Collapsing the 595 reveal actions or their literals.

## 9. Files in scope

Primary authored files:

- `tools/generate_microverse.py`
- `tools/validate_expansion_catalogs.py`
- `tests/test_validate_expansion_catalogs.py`
- `tests/test_expansion_test_tooling.py`
- expansion test generator/runner files when exact source-shape schemas change

Regenerated files:

- `plugin.rhai`
- `manifest.toml`
- `microverse.pexe`
- generated action, universe, schema, parity, and static-audit contracts
- fresh source and built test roots under new target directories

Protected files and paths:

- SDK
- Driver
- UI
- existing catalog JSON semantics
- prior test roots, reports, and build evidence

Never overwrite prior evidence roots. Every build, generated shard set, prepared
spec set, and execution uses a new named target directory.

## 10. Model assignment and agent topology

Official OpenAI documentation describes GPT-5.6 Sol as the flagship choice for
complex reasoning and coding, GPT-5.6 Terra as the balanced intelligence/cost
choice, and GPT-5.6 Luna as the efficient high-volume choice. GPT-5.6 supports
intentional reasoning levels from low through max. See [OpenAI model
guidance](https://developers.openai.com/api/docs/guides/latest-model) and the
[official model catalog](https://developers.openai.com/api/docs/models).

### 10.1 Roles

#### GPT-5.6 Sol

Use for architecture, proof-semantics review, high-risk generator design, failure
arbitration, and final release approval.

Recommended reasoning:

- `high` for focused semantic review
- `xhigh` for resource-adapter architecture and final release audit
- `max` only after a genuine unresolved compiler/proof blocker

Sol is the only model authorized to approve a phase containing proof-shape,
lineage, role-order, output-transform, or state-transition changes.

#### GPT-5.6 Terra

Use as the primary implementation model for bounded generator refactors, validator
updates, focused tests, and deterministic failure diagnosis.

Recommended reasoning:

- `medium` for routine rendering/test updates
- `high` for extraction, refinement, component, and skill adapters

Terra may implement a phase only after Sol has frozen its invariants and acceptance
criteria. Terra may not waive a failed semantic gate.

#### GPT-5.6 Luna

Use for high-volume, mechanical, read-only or disposable-copy work:

- family censuses
- source hashing
- action/role/literal inventories
- generated diff classification
- running deterministic test commands
- summarizing logs and reports
- checking that expected files and rows are present

Recommended reasoning:

- `low` for hashes and exact inventories
- `medium` for structured diff classification and test-log triage

Luna must not be the sole approver for semantic equivalence, proof topology,
lineage, role order, or production release.

### 10.2 Phase routing

| Phase | Primary model | Reasoning | Independent reviewer | Why |
|---|---|---|---|---|
| 0. Baseline and budgets | Luna | medium | Sol/high | High-volume census; Sol freezes invariants |
| 1. Redundant proof cleanup | Terra | high | Sol/xhigh | Small edit with proof semantics |
| 2. VDF/random temporaries | Terra | high | Sol/high | Syntax/evaluation canary needs semantic review |
| 3. Detection and Survey | Terra | high | Sol/high | Bounded fixed-arity helper extraction |
| 4. Extraction/refinement | Sol designs; Terra implements | Sol xhigh; Terra high | Separate Sol/xhigh pass | Largest and highest-risk family |
| 5. Components and skills | Terra | high | Sol/high | Repeated templates with role-order sensitivity |
| 6. Token compaction | Luna prepares; Terra applies | Luna medium; Terra medium | Sol/medium | Mechanical change with exact-token gates |
| Static validation | Luna | medium | Terra/high on failure | High-volume deterministic checking |
| Build/check diagnosis | Terra | high | Sol/high if semantic | Compiler-facing debugging |
| Runtime retained/matrix | Luna monitors | medium | Terra diagnoses; Sol arbitrates | Mechanical execution, strict failure ownership |
| Final release decision | Sol | xhigh | Independent Sol/high audit | Quality-first semantic sign-off |

### 10.3 Concurrency rules

- One Terra or Sol writer owns `tools/generate_microverse.py` at a time.
- Luna may work concurrently only on read-only inspection or disposable copies.
- A reviewer must inspect a frozen hash, never files being edited by another agent.
- Do not parallelize installed rc.43 builds that compete for memory.
- Run retained and matrix execution serially; matrix starts only after retained is
  fully green and quiescent.
- The final reviewer must not be the same agent that authored the last production
  change.

## 11. Required validation ladder

Every phase must pass the cheapest applicable gates before moving to more expensive
ones.

1. Python syntax and focused generator tests.
2. Deterministic in-memory render.
3. Source-token and function-boundary audit.
4. Action names/order and direct-role comparison.
5. Literal, output-transform, Raw relation, VDF, and flattened-witness comparison.
6. Strict expansion validator: no errors or warnings.
7. Full generator/tooling unit suite.
8. Installed rc.43 primary build.
9. Independent installed rc.43 `--check` in a separate directory.
10. Byte equality of primary/check archives.
11. Fresh four-shard source generation.
12. Source-only retained and matrix static validation.
13. Fresh four-shard primary/check builds and byte equality.
14. Canonical 29-file source/built dual-root validation.
15. Fail-fast prepare-only for retained and matrix specs.
16. Shared Rust pre-module validation of all 3,169 cases.
17. Independent prepared-artifact and hash audit.
18. Fail-fast retained runtime: 1,142/1,142 required.
19. Fail-fast matrix runtime: 2,027/2,027 required.
20. Final process-quiescence and no-network/no-state/no-submission audit.
21. Human-readability review of representative wrappers and every new helper,
    including comment necessity and naming consistency.

No phase may skip directly from source tests to full runtime execution.

## 12. Definition of done

The refactor is complete only when all of the following are true:

- `plugin.rhai` is at or below 600,000 bytes.
- `plugin.rhai` is at or below 15,000 nonblank LOC.
- Generated Rhai remains clean and readable, with consistent wrapper structure,
  descriptive helper/parameter names, and one logical statement per line where
  practical.
- Comments are minimal and necessary: every retained comment documents an SDK,
  proof, security, ordering, or intentional-design invariant.
- All 1,650 public actions exist in identical manifest order.
- Every direct role sequence is identical to the baseline.
- All catalog-driven literals and output transforms are identical.
- Logical Intro/VDF counts are identical.
- Only the 327 approved duplicate logical Sum constraints are removed. The
  capacity-copy experiment remains reverted to the compile-proven witnessed form.
- All 17 Raw `var_assign` lineage bridges and paired no-op updates remain.
- All fixed-zero key witnesses, key rotations, version gates, co-location gates,
  reserve debits, nonnegative guards, and progression/capacity gates remain.
- Strict validation, full builds, retained execution, matrix execution, and
  independent audit pass.
- Production/check archives are byte-identical to each other for the new source.
- SDK, Driver, UI, and catalog semantics are untouched.
- No proofs, submissions, external state writes, or network operations occur.
- Final hashes, byte/LOC census, action census, validation results, and any deferred
  opportunities are documented.

## 13. Stop conditions

Stop and request direction if any proposed change requires:

- an SDK or Driver edit
- moving action roles into helpers
- control flow or runtime lookup
- a class, field, action, recipe, balance, destination, milestone, or cost change
- weakening an existing negative test or semantic validator
- accepting an unexplained output/proof/census delta
- overwriting prior evidence
- real-proof generation or external submission

If a helper or source simplification fails the canary, retain the old proven shape
and continue with the remaining independent workstreams.

## 14. Agent handoff template

Every implementation or review handoff must include:

1. Phase and exact scope.
2. Frozen input hashes.
3. Files changed.
4. Functions/actions affected.
5. Byte and LOC delta, including family delta.
6. Proof/runtime census delta and why it is authorized.
7. Action/role/literal/output comparison result.
8. Tests and commands run, with exit codes.
9. New artifact hashes and paths.
10. Known caveats or deferred work.
11. Confirmation that SDK, Driver, UI, catalogs, network, proofs, and submissions
    were untouched.

An agent must read this PRD before editing and must not infer authorization beyond
the assigned phase.

## 15. Final release record

The required refactor completed on 2026-08-10 on branch
`local/rhai-refactor`. The authoritative economy source moved from `764,380 B` /
`28,710` nonblank LOC to `599,317 B` / `12,758` nonblank LOC: a reduction of
`165,063 B` (`21.6%`) and `15,952` LOC (`55.6%`). It is `683 B` below the hard
source target. The release retains all 1,650 actions in manifest order and has 75
helpers. The compatibility profile is `591,418 B` / `12,630` LOC with 1,638
profile-supported actions and 55 helpers.

### 15.1 Canonical production tuple

| Artifact | Final value |
|---|---|
| `plugin.rhai` | `599,317 B`; SHA-256 `2e9f6416d12963273fa7bde5474bbfaad4d81e42010f3862654bd1ad2e423849` |
| `manifest.toml` | SHA-256 `4ddb3c833967a8e16dddb6f39d62bc88e278a203ef1e9b21fce6280a540a06c8` |
| `microverse.pexe` | `65,959 B`; SHA-256 `d17cf84a1fb13f39cc01f7bb2b5ad54a4b8be7bee18cbe914fbda17c50ec02ad` |
| Production module | `dc9a7eeac0ce15b8e6dd0305daa3fab84c2cfda992838222924269590522c0d4` |
| Action contract | `5eebef72ddcf241638b5145d5cdd77b325aa5f60e1e74b59a8c7ea81f764e600` |
| Catalog index | `e3d4f7cd6b730a46bf2961d38b32aa4b7a4ae232a53b781e12d8903c9173d335` |
| Resource tree | `578de10b58f49c7f35310dc984bb89ce98904aaca3f276966f75cd236b564ab9` |
| Skill tree | `96bc181eb29f64b41347118e2831b711e680bf10a41fd12a24109f2be1a1e57a` |

Installed rc.43 primary, separately primed package, and independent `--check`
produced byte-identical economy archives. The compatibility profile independently
produced module `521f18205ca34b39f58723ce05ca9de6516eacc3163e5e67c32da0240efa9a07`
and a byte-identical `65,101 B` archive with SHA-256
`77c16d605caef0d067b05e7a5bc9988dcbb3e7fcf2fb9ae203e95f537bdcd21a`.

### 15.2 Validation record

- Strict canonical validator: 45,771 checks, zero errors and warnings.
- Standalone validator tests: 24/24 passed.
- Generator and expansion-tooling tests: 49/49 passed.
- Release Rust harness tests: 48/48 passed.
- Fresh shard source/built roots contain 29 files and differ only by the four
  exact manifest module-hash replacements.
- The shard gate binds all 75 production helpers and the exact 45 VDF-transformed
  helper inventory, whose sorted-name SHA-256 is
  `b9d48dbac953fce8af5f0353cc456f499792740c6920dd6e124dbae2a62aad78`.
- Shard modules: resource
  `3712589220718622b7e94deaf1660fd1ca1a13a45e62ce5cee37eb398c2b9628`,
  component `56222166d5473d959ad03c10045f28a8a95126c815b57fd12f750d75d46320eb`,
  skill `2ecc5bf7bb9d04eca4002b9b3b1ef202b2012a8d932dcc24cca248d063b87bc9`,
  and warp `a0ce31d13c89e7bb8a453c153eac3c06b260094fbb56aa2080eeba9e1c5705cb`.
- Retained runtime summary: 7/7 batches, 1,142/1,142 passed, zero failed or
  incomplete; summary SHA-256
  `c409e688cdab276f24ccba1e4cede9b9cd2c4260ba36900d735743473e7b7545`.
- Contract matrix summary: 11/11 batches, 2,027/2,027 passed, zero failed or
  incomplete; summary SHA-256
  `7abce1587b56ee30468217149e01f4b7b144d72487b43c2d917da344292f4c17`.
- Matrix inventory is 820 positives, 1,203 structured negatives, and 4 explicit
  representatives. Rejection counts are exact: Sum 796, Lt 209, missing input
  198. Evidence counts are single-field 884, compound-tier 121, class deficit 198.
- All runs were mock-only and fail-fast. Network use, external state commits,
  proof submissions, and submission attempts were zero. No target-real run was
  requested.

### 15.3 Scope and maintainability result

The final implementation changes the generator, generated production package,
validation tooling, shard tooling, and tests only. SDK, Driver, UI, and the four
authoritative catalog inputs remain untouched. No loops, conditional branches,
runtime maps, dynamic dispatch, subactions, role movement, or action-name lookup
were introduced. Public wrappers keep direct roles and fixed literal adapter calls;
helpers use descriptive lifecycle names and straight-line statements. Generated
Rhai contains no comments because the resulting structure is self-explanatory;
SDK/proof rationale and intentional fallbacks remain in this PRD and fail-closed
tests.

The current resource and skill tree deliverables are the canonical JSON files
`catalog/microverse-resource-tree-v2.json` and
`catalog/microverse-skill-tree-v2.json`.
