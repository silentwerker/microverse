# Microverse release

Microverse is a proof-powered universe where you pilot a ship across space and time, survey unknown sectors, harvest distant worlds, and turn each discovery into technology, artifacts, and civilization, one branch at a time.

Explore. Discover. Build.

## Current PEXE compatibility

| Component | Compatible version |
| --- | --- |
| Digital Objects Network source | [`856894131b5a3fb0d34951362934ec83e4305ebf`](https://github.com/dobjlabs/digital-objects-network/commit/856894131b5a3fb0d34951362934ec83e4305ebf) (`v0.1.0-rc.43-4-g8568941`) |
| Driver / `dobjd` | crate `0.1.0`; local build reports `dobjd dev`; binary SHA-256 `3BF9BBC23AA102781FDD563B17F062DF5E17D5362BEC0BFE7111095BEFB49F0A` |
| Relayer | crate `0.1.0` from the source commit above |
| Synchronizer | crate `0.1.0` from the source commit above |
| PEXE compiler | local build reports `pexe dev`; binary SHA-256 `59A96B2233A066E68BAEDE15B1DDECD03BCAEB410158BBA0CB6F4735E393980C` |

The shared source commit is the authoritative compatibility pin. The individual
crate versions are not sufficient on their own because these development builds
still report `0.1.0`/`dev` while carrying the RC43 backports.
