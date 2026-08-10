use std::{collections::HashMap, mem, slice};

use pod2::middleware::{containers::Dictionary, F, Hash, StrKey, Value, EMPTY_VALUE};

const HASH_LIMBS: usize = 4;
const OUTPUT_LIMBS: usize = 8;
const SECTOR_INPUTS: usize = 4;
const SIGNAL_INPUTS: usize = 7;

#[no_mangle]
pub extern "C" fn alloc(size: usize) -> *mut u8 {
    let mut bytes = Vec::<u8>::with_capacity(size);
    let pointer = bytes.as_mut_ptr();
    mem::forget(bytes);
    pointer
}

#[no_mangle]
pub unsafe extern "C" fn dealloc(pointer: *mut u8, size: usize) {
    if !pointer.is_null() {
        drop(Vec::from_raw_parts(pointer, 0, size));
    }
}

fn class_hash(limbs: &[u64]) -> Hash {
    Hash([F(limbs[0]), F(limbs[1]), F(limbs[2]), F(limbs[3])])
}

fn base_object(class: Hash) -> HashMap<StrKey, Value> {
    HashMap::from([
        (StrKey::from("key"), Value::from(EMPTY_VALUE)),
        (StrKey::from("work"), Value::from(EMPTY_VALUE)),
        (StrKey::from("type"), Value::from(class)),
    ])
}

fn add_int(entries: &mut HashMap<StrKey, Value>, key: &str, value: i64) {
    entries.insert(StrKey::from(key), Value::from(value));
}

fn materialize(entries: HashMap<StrKey, Value>) -> (Hash, Hash) {
    let initial = Dictionary::new(entries);
    let stable_identifier = initial.commitment();
    let mut object = initial;
    object
        .insert(
            &StrKey::from("stable_identifier"),
            &Value::from(stable_identifier),
        )
        .expect("stable identifier insertion");
    (stable_identifier, object.commitment())
}

unsafe fn write_pair(output: *mut u64, index: usize, stable: Hash, object: Hash) {
    let target = output.add(index * OUTPUT_LIMBS);
    for limb in 0..HASH_LIMBS {
        *target.add(limb) = stable.0[limb].0;
        *target.add(HASH_LIMBS + limb) = object.0[limb].0;
    }
}

#[no_mangle]
pub unsafe extern "C" fn sector_commitments(
    inputs: *const i64,
    count: usize,
    class_hash_input: *const u64,
    output: *mut u64,
) -> u32 {
    if inputs.is_null() || class_hash_input.is_null() || output.is_null() || count > 1_000_000 {
        return 0;
    }
    let values = slice::from_raw_parts(inputs, count * SECTOR_INPUTS);
    let class = class_hash(slice::from_raw_parts(class_hash_input, HASH_LIMBS));

    for index in 0..count {
        let row = &values[index * SECTOR_INPUTS..(index + 1) * SECTOR_INPUTS];
        let mut entries = base_object(class);
        for (key, value) in [
            ("schema_version", 2),
            ("mechanics_version", 2),
            ("universe_version", 2),
            ("body_bank_version", 2),
            ("x", row[0]),
            ("y", row[1]),
            ("z", row[2]),
            ("epoch", row[3]),
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
            add_int(&mut entries, key, value);
        }
        let (stable, object) = materialize(entries);
        write_pair(output, index, stable, object);
    }
    1
}

#[no_mangle]
pub unsafe extern "C" fn signal_commitments(
    inputs: *const i64,
    count: usize,
    class_hash_input: *const u64,
    output: *mut u64,
) -> u32 {
    if inputs.is_null() || class_hash_input.is_null() || output.is_null() || count > 1_000_000 {
        return 0;
    }
    let values = slice::from_raw_parts(inputs, count * SIGNAL_INPUTS);
    let class = class_hash(slice::from_raw_parts(class_hash_input, HASH_LIMBS));

    for index in 0..count {
        let row = &values[index * SIGNAL_INPUTS..(index + 1) * SIGNAL_INPUTS];
        let mut entries = base_object(class);
        for (key, value) in [
            ("schema_version", 2),
            ("mechanics_version", 2),
            ("universe_version", 2),
            ("body_bank_version", 2),
            ("sector_x", row[0]),
            ("sector_y", row[1]),
            ("sector_z", row[2]),
            ("sector_epoch", row[3]),
            ("category_code", row[4]),
            ("candidate_code", row[5]),
            ("slot_serial", row[6]),
        ] {
            add_int(&mut entries, key, value);
        }
        let (stable, object) = materialize(entries);
        write_pair(output, index, stable, object);
    }
    1
}
