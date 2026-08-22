# Microverse

Microverse is a proof-powered universe where you pilot a ship across space and time, survey unknown sectors, harvest distant worlds, and turn each discovery into technology, artifacts, and civilization, one branch at a time.

Explore. Discover. Build.

## Current PEXE compatibility

| Component | Compatible version |
| --- | --- |
| Digital Objects Network source | [`355e9f849526b5f115b4e168af7a356debfca8eb`](https://github.com/dobjlabs/digital-objects-network/commit/355e9f849526b5f115b4e168af7a356debfca8eb) (`v0.1.0-rc.43-13-g355e9f8`, PR #221) |
| Driver / `dobjd` | crate `0.1.0`; local build reports `dobjd main-355e9f8`; binary SHA-256 `8CDFFC617FDC5990629F3266851275A24F8D64EA58FB393BCEEA5C9C53EB8431` |
| Relayer | crate `0.1.0` from the source commit above |
| Synchronizer | crate `0.1.0` from the source commit above |
| PEXE compiler | local build reports `pexe main-355e9f8`; binary SHA-256 `1E35BD1FAA5C8DBE8ADC5B25E06CE466EAB8AEA7F7C739E181F6165BA24B714A` |

The shared source commit is the authoritative compatibility pin. The individual
crate versions are not sufficient on their own because these development builds
still use crate version `0.1.0` while carrying later protocol and SDK changes.
