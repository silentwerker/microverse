# Manifest order proof benchmark

This isolates one variable for `RefineFerrousOreToIron`: the order of complete
`[[actions]]` blocks in `manifest.toml`. Both configurations use the same Rhai
source, fixture, and proof harness, run against the PR212 stack.

| Configuration | Exact source | Operations | PODs | Real proof |
|---|---|---:|---:|---:|
| Original order | [`25d6e4e7517c24eedf932b2b303f03fc10fc4a6e`](https://github.com/silentwerker/microverse/commit/25d6e4e7517c24eedf932b2b303f03fc10fc4a6e) | 481 | 37 | 1,062.54 s |
| Latency order | [`8e1583ac51c798dfb0f191e68f1fbec060d9a3ab`](https://github.com/silentwerker/microverse/commit/8e1583ac51c798dfb0f191e68f1fbec060d9a3ab) | 171 | 6 | 325.74 s |

The reordered manifest reduced real proof time by 69.34% on the benchmark
machine. Generated `Is<Class>` branch positions follow manifest action/object
role order, so the selected continuation paths became shorter.

## Run

Requirements: Python 3, Rust nightly `2026-01-25`, and the source checkout used
by a [local Driver running the PR 212 commit](https://github.com/dobjlabs/digital-objects-network/commit/02bee560249616d101ec68490696d9b34d6b4121).
Pass the checkout root containing `libs/payload`, `libs/pexe`, `libs/pod2utils`,
`libs/sdk`, and `libs/txlib` to `--stack`.

From the Microverse repository root:

```sh
python proof-latency-benchmark/run.py --stack /path/to/digital-objects-network
```

That single command verifies the fixtures, builds the release harness against
the supplied stack, runs both mock plans, checks the action outputs, and prints
the comparison. Add `--real` to build both recursive proofs:

```sh
python proof-latency-benchmark/run.py --stack /path/to/digital-objects-network --real
```

To reuse an already-built harness, replace `--stack` with
`--harness /path/to/microverse-reachable-harness`.

`expected.json` is the compact record of the fixture seeds, module hashes, plan
sizes, and observed real-proof times. Absolute timing varies by machine; the
operation and POD counts should reproduce exactly.
