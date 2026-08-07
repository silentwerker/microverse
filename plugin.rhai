fn prove_fixed_versions(action, object) {
  action.st_sum(object.schema_version, 0, 1);
  action.st_sum(object.mechanics_version, 0, 1);
  action.st_sum(object.universe_version, 0, 1);
}
fn bind_ship_id(action, ship) {
  var bound_ship_id = action.random();
  var_assign(bound_ship_id, ship.ship_id);
  ship.update("ship_id", bound_ship_id);
  bound_ship_id
}
fn warp_ship_core(
  action,
  next_ship,
  ship,
  destination_x,
  destination_y,
  destination_z,
  destination_epoch
) {
  prove_fixed_versions(action, ship);
  var ship_id = bind_ship_id(action, ship);
  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  var x = unsafe { destination_x - 0 };
  var y = unsafe { destination_y - 0 };
  var z = unsafe { destination_z - 0 };
  var epoch = unsafe { destination_epoch - 0 };
  var claim_serial = unsafe { ship.claim_serial - 0 };
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
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
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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
}
fn prove_ship_at_sector(action, ship, sector) {
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var sector_equal_x = unsafe { ship.x - 0 };
  var sector_equal_y = unsafe { ship.y - 0 };
  var sector_equal_z = unsafe { ship.z - 0 };
  var sector_equal_epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, sector_equal_x);
  action.st_sum(sector.x, 0, sector_equal_x);
  action.st_sum(ship.y, 0, sector_equal_y);
  action.st_sum(sector.y, 0, sector_equal_y);
  action.st_sum(ship.z, 0, sector_equal_z);
  action.st_sum(sector.z, 0, sector_equal_z);
  action.st_sum(ship.epoch, 0, sector_equal_epoch);
  action.st_sum(sector.epoch, 0, sector_equal_epoch);
}
fn prove_ship_at_body(action, ship, body) {
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, body);
  action.st_sum(body.body_bank_version, 0, 1);
  var body_equal_x = unsafe { ship.x - 0 };
  var body_equal_y = unsafe { ship.y - 0 };
  var body_equal_z = unsafe { ship.z - 0 };
  var body_equal_epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, body_equal_x);
  action.st_sum(body.sector_x, 0, body_equal_x);
  action.st_sum(ship.y, 0, body_equal_y);
  action.st_sum(body.sector_y, 0, body_equal_y);
  action.st_sum(ship.z, 0, body_equal_z);
  action.st_sum(body.sector_z, 0, body_equal_z);
  action.st_sum(ship.epoch, 0, body_equal_epoch);
  action.st_sum(body.sector_epoch, 0, body_equal_epoch);
}
fn rotate_key(object, next_key) {
  object.update("key", next_key);
}
fn reveal_p(
  action,
  coordinate,
  destination_code,
  destination_x,
  destination_y,
  destination_z,
  uses,
  lower_limb,
  upper_limb
) {
  prove_fixed_versions(action, coordinate);
  action.st_sum(coordinate.revealed, 0, 0);
  action.st_gt(coordinate.source_pool_before, -1);
  var selector = action.random();
  var_assign(selector, coordinate.stable_identifier);
  coordinate.update("stable_identifier", selector);
  let lower = action.top_limb_u256(lower_limb);
  let upper = action.top_limb_u256(upper_limb);
  action.intro_lt_eq_u256(lower, selector);
  action.intro_lt_eq_u256(selector, upper);
  coordinate.update("revealed", 1);
  coordinate.update("destination_code", destination_code);
  coordinate.update("destination_x", destination_x);
  coordinate.update("destination_y", destination_y);
  coordinate.update("destination_z", destination_z);
  coordinate.update("uses_remaining", uses);
  var next_key = action.random();
  rotate_key(coordinate, next_key);
}
fn reveal_t(
  action,
  coordinate,
  destination_code,
  destination_epoch,
  uses,
  lower_limb,
  upper_limb
) {
  prove_fixed_versions(action, coordinate);
  action.st_sum(coordinate.revealed, 0, 0);
  action.st_gt(coordinate.source_pool_before, -1);
  var selector = action.random();
  var_assign(selector, coordinate.stable_identifier);
  coordinate.update("stable_identifier", selector);
  let lower = action.top_limb_u256(lower_limb);
  let upper = action.top_limb_u256(upper_limb);
  action.intro_lt_eq_u256(lower, selector);
  action.intro_lt_eq_u256(selector, upper);
  coordinate.update("revealed", 1);
  coordinate.update("destination_code", destination_code);
  coordinate.update("destination_epoch", destination_epoch);
  coordinate.update("uses_remaining", uses);
  var next_key = action.random();
  rotate_key(coordinate, next_key);
}
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
) {
  var ship_id = bind_ship_id(action, ship);
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, body);
  action.st_sum(body.body_bank_version, 0, 1);
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(body.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(body.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(body.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(body.sector_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  var civilization_scan_serial = unsafe {
    ship.civilization_scan_serial - 0
  };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  action.st_sum(
    ship.civilization_scan_serial,
    0,
    civilization_scan_serial
  );
  var next_action_serial = unsafe {
    ship.action_serial - (0 - 1)
  };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  var next_remaining = unsafe {
    body[remaining_field] - extraction_amount
  };
  action.st_sum(
    next_remaining,
    extraction_amount,
    body[remaining_field]
  );
  action.st_gt(next_remaining, -1);

  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", resource_type],
    ["amount", extraction_amount]
  ]);
  body.update(remaining_field, next_remaining);
  var next_body_key = action.random();
  rotate_key(body, next_body_key);
}
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
  common_amount,
  uncommon_amount
) {
  var ship_id = bind_ship_id(action, ship);
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, body);
  action.st_sum(body.body_bank_version, 0, 1);
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(body.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(body.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(body.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(body.sector_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  var civilization_scan_serial = unsafe {
    ship.civilization_scan_serial - 0
  };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  action.st_sum(
    ship.civilization_scan_serial,
    0,
    civilization_scan_serial
  );
  var next_action_serial = unsafe {
    ship.action_serial - (0 - 1)
  };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  var next_remaining = unsafe {
    body[remaining_field] - extraction_amount
  };
  action.st_sum(
    next_remaining,
    extraction_amount,
    body[remaining_field]
  );
  action.st_gt(next_remaining, -1);
  composite_resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", resource_type],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["origin_epoch", epoch],
    ["child_1_remaining", common_amount],
    ["child_2_remaining", uncommon_amount],
    ["child_3_remaining", rare_extraction_amount]
  ]);
  body.update(remaining_field, next_remaining);
  var next_body_key = action.random();
  rotate_key(body, next_body_key);
}
fn BuildShipSmall(action) {
  var ship = action.output("MicroverseShip");
  var ship_id = action.random();
  ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", 10],
    ["rare_extraction_amount", 1],
    ["x", 1000000000000],
    ["y", 1000000000000],
    ["z", 1000000000000],
    ["epoch", 0],
    ["active_skill_type", 0],
    ["action_serial", 0],
    ["claim_serial", 0],
    ["discovery_serial", 0],
    ["satellite_serial", 0],
    ["civilization_scan_serial", 0],
    ["ship_id", ship_id]
  ]);
  var work = action.intro_vdf(17, ship);
  ship.update("work", work);
}
fn BuildShipMedium(action) {
  var ship = action.output("MicroverseShip");
  var ingredient_1_matter = action.input("MicroverseResource");
  var ingredient_2_crystal = action.input("MicroverseResource");
  var ingredient_3_energy = action.input("MicroverseResource");
  var ingredient_4_iron = action.input("MicroverseResource");
  var ingredient_5_aluminum = action.input("MicroverseResource");
  var ingredient_6_copper = action.input("MicroverseResource");
  var ingredient_7_silicon = action.input("MicroverseResource");
  var ingredient_8_carbon = action.input("MicroverseResource");
  action.st_sum(ingredient_1_matter.resource_type, 0, 1);
  action.st_sum(ingredient_1_matter.amount, 0, 10);
  action.st_sum(ingredient_2_crystal.resource_type, 0, 2);
  action.st_sum(ingredient_2_crystal.amount, 0, 10);
  action.st_sum(ingredient_3_energy.resource_type, 0, 4);
  action.st_sum(ingredient_3_energy.amount, 0, 10);
  action.st_sum(ingredient_4_iron.resource_type, 0, 156);
  action.st_sum(ingredient_4_iron.amount, 0, 6);
  action.st_sum(ingredient_5_aluminum.resource_type, 0, 196);
  action.st_sum(ingredient_5_aluminum.amount, 0, 6);
  action.st_sum(ingredient_6_copper.resource_type, 0, 161);
  action.st_sum(ingredient_6_copper.amount, 0, 6);
  action.st_sum(ingredient_7_silicon.resource_type, 0, 164);
  action.st_sum(ingredient_7_silicon.amount, 0, 6);
  action.st_sum(ingredient_8_carbon.resource_type, 0, 205);
  action.st_sum(ingredient_8_carbon.amount, 0, 6);
  var ship_id = action.random();
  ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", 50],
    ["rare_extraction_amount", 5],
    ["x", 1000000000000],
    ["y", 1000000000000],
    ["z", 1000000000000],
    ["epoch", 0],
    ["active_skill_type", 0],
    ["action_serial", 0],
    ["claim_serial", 0],
    ["discovery_serial", 0],
    ["satellite_serial", 0],
    ["civilization_scan_serial", 0],
    ["ship_id", ship_id]
  ]);
  var work = action.intro_vdf(51, ship);
  ship.update("work", work);
}
fn BuildShipLarge(action) {
  var ship = action.output("MicroverseShip");
  var permit = action.input("MicroverseShipyardPermit");
  var ingredient_1_matter = action.input("MicroverseResource");
  var ingredient_2_crystal = action.input("MicroverseResource");
  var ingredient_3_energy = action.input("MicroverseResource");
  var ingredient_4_steel = action.input("MicroverseResource");
  var ingredient_5_aluminum = action.input("MicroverseResource");
  var ingredient_6_titanium = action.input("MicroverseResource");
  var ingredient_7_copper = action.input("MicroverseResource");
  var ingredient_8_silicon = action.input("MicroverseResource");
  var ingredient_9_gold = action.input("MicroverseResource");
  var ingredient_10_carboncomposite = action.input("MicroverseResource");
  prove_fixed_versions(action, permit);
  action.st_sum(permit.permit_type, 0, 1);
  action.st_sum(permit.industrial_authorized, 0, 1);
  action.st_sum(permit.electronics_authorized, 0, 1);
  action.st_sum(permit.molecular_authorized, 0, 1);
  var build_x = unsafe { permit.x - 0 };
  var build_y = unsafe { permit.y - 0 };
  var build_z = unsafe { permit.z - 0 };
  var build_epoch = unsafe { permit.epoch - 0 };
  action.st_sum(permit.x, 0, build_x);
  action.st_sum(permit.y, 0, build_y);
  action.st_sum(permit.z, 0, build_z);
  action.st_sum(permit.epoch, 0, build_epoch);
  action.st_sum(ingredient_1_matter.resource_type, 0, 1);
  action.st_sum(ingredient_1_matter.amount, 0, 50);
  action.st_sum(ingredient_2_crystal.resource_type, 0, 2);
  action.st_sum(ingredient_2_crystal.amount, 0, 50);
  action.st_sum(ingredient_3_energy.resource_type, 0, 4);
  action.st_sum(ingredient_3_energy.amount, 0, 50);
  action.st_sum(ingredient_4_steel.resource_type, 0, 211);
  action.st_sum(ingredient_4_steel.amount, 0, 30);
  action.st_sum(ingredient_5_aluminum.resource_type, 0, 196);
  action.st_sum(ingredient_5_aluminum.amount, 0, 30);
  action.st_sum(ingredient_6_titanium.resource_type, 0, 197);
  action.st_sum(ingredient_6_titanium.amount, 0, 15);
  action.st_sum(ingredient_7_copper.resource_type, 0, 161);
  action.st_sum(ingredient_7_copper.amount, 0, 30);
  action.st_sum(ingredient_8_silicon.resource_type, 0, 164);
  action.st_sum(ingredient_8_silicon.amount, 0, 30);
  action.st_sum(ingredient_9_gold.resource_type, 0, 200);
  action.st_sum(ingredient_9_gold.amount, 0, 15);
  action.st_sum(ingredient_10_carboncomposite.resource_type, 0, 212);
  action.st_sum(ingredient_10_carboncomposite.amount, 0, 5);
  var ship_id = action.random();
  ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", 250],
    ["rare_extraction_amount", 25],
    ["x", build_x],
    ["y", build_y],
    ["z", build_z],
    ["epoch", build_epoch],
    ["active_skill_type", 0],
    ["action_serial", 0],
    ["claim_serial", 0],
    ["discovery_serial", 0],
    ["satellite_serial", 0],
    ["civilization_scan_serial", 0],
    ["ship_id", ship_id]
  ]);
  var work = action.intro_vdf(510, ship);
  ship.update("work", work);
}
fn MovePositiveX(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 10);
  action.st_sum(ship.rare_extraction_amount, 0, 1);
  var next_coordinate = unsafe { ship.x - (0 - 1) };
  action.st_sum(ship.x, 1, next_coordinate);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("x", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(4, ship);
  ship.update("work", next_work);
}
fn MovePositiveXMedium(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 50);
  action.st_sum(ship.rare_extraction_amount, 0, 5);
  var next_coordinate = unsafe { ship.x - (0 - 10) };
  action.st_sum(ship.x, 10, next_coordinate);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("x", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(12, ship);
  ship.update("work", next_work);
}
fn MovePositiveXLarge(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 250);
  action.st_sum(ship.rare_extraction_amount, 0, 25);
  var next_coordinate = unsafe { ship.x - (0 - 100) };
  action.st_sum(ship.x, 100, next_coordinate);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("x", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(28, ship);
  ship.update("work", next_work);
}
fn MoveNegativeX(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 10);
  action.st_sum(ship.rare_extraction_amount, 0, 1);
  var next_coordinate = unsafe { ship.x - 1 };
  action.st_sum(next_coordinate, 1, ship.x);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("x", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(4, ship);
  ship.update("work", next_work);
}
fn MoveNegativeXMedium(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 50);
  action.st_sum(ship.rare_extraction_amount, 0, 5);
  var next_coordinate = unsafe { ship.x - 10 };
  action.st_sum(next_coordinate, 10, ship.x);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("x", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(12, ship);
  ship.update("work", next_work);
}
fn MoveNegativeXLarge(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 250);
  action.st_sum(ship.rare_extraction_amount, 0, 25);
  var next_coordinate = unsafe { ship.x - 100 };
  action.st_sum(next_coordinate, 100, ship.x);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("x", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(28, ship);
  ship.update("work", next_work);
}
fn MovePositiveY(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 10);
  action.st_sum(ship.rare_extraction_amount, 0, 1);
  var next_coordinate = unsafe { ship.y - (0 - 1) };
  action.st_sum(ship.y, 1, next_coordinate);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("y", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(4, ship);
  ship.update("work", next_work);
}
fn MovePositiveYMedium(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 50);
  action.st_sum(ship.rare_extraction_amount, 0, 5);
  var next_coordinate = unsafe { ship.y - (0 - 10) };
  action.st_sum(ship.y, 10, next_coordinate);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("y", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(12, ship);
  ship.update("work", next_work);
}
fn MovePositiveYLarge(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 250);
  action.st_sum(ship.rare_extraction_amount, 0, 25);
  var next_coordinate = unsafe { ship.y - (0 - 100) };
  action.st_sum(ship.y, 100, next_coordinate);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("y", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(28, ship);
  ship.update("work", next_work);
}
fn MoveNegativeY(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 10);
  action.st_sum(ship.rare_extraction_amount, 0, 1);
  var next_coordinate = unsafe { ship.y - 1 };
  action.st_sum(next_coordinate, 1, ship.y);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("y", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(4, ship);
  ship.update("work", next_work);
}
fn MoveNegativeYMedium(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 50);
  action.st_sum(ship.rare_extraction_amount, 0, 5);
  var next_coordinate = unsafe { ship.y - 10 };
  action.st_sum(next_coordinate, 10, ship.y);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("y", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(12, ship);
  ship.update("work", next_work);
}
fn MoveNegativeYLarge(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 250);
  action.st_sum(ship.rare_extraction_amount, 0, 25);
  var next_coordinate = unsafe { ship.y - 100 };
  action.st_sum(next_coordinate, 100, ship.y);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("y", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(28, ship);
  ship.update("work", next_work);
}
fn MovePositiveZ(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 10);
  action.st_sum(ship.rare_extraction_amount, 0, 1);
  var next_coordinate = unsafe { ship.z - (0 - 1) };
  action.st_sum(ship.z, 1, next_coordinate);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("z", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(4, ship);
  ship.update("work", next_work);
}
fn MovePositiveZMedium(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 50);
  action.st_sum(ship.rare_extraction_amount, 0, 5);
  var next_coordinate = unsafe { ship.z - (0 - 10) };
  action.st_sum(ship.z, 10, next_coordinate);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("z", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(12, ship);
  ship.update("work", next_work);
}
fn MovePositiveZLarge(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 250);
  action.st_sum(ship.rare_extraction_amount, 0, 25);
  var next_coordinate = unsafe { ship.z - (0 - 100) };
  action.st_sum(ship.z, 100, next_coordinate);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("z", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(28, ship);
  ship.update("work", next_work);
}
fn MoveNegativeZ(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 10);
  action.st_sum(ship.rare_extraction_amount, 0, 1);
  var next_coordinate = unsafe { ship.z - 1 };
  action.st_sum(next_coordinate, 1, ship.z);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("z", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(4, ship);
  ship.update("work", next_work);
}
fn MoveNegativeZMedium(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 50);
  action.st_sum(ship.rare_extraction_amount, 0, 5);
  var next_coordinate = unsafe { ship.z - 10 };
  action.st_sum(next_coordinate, 10, ship.z);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("z", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(12, ship);
  ship.update("work", next_work);
}
fn MoveNegativeZLarge(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 250);
  action.st_sum(ship.rare_extraction_amount, 0, 25);
  var next_coordinate = unsafe { ship.z - 100 };
  action.st_sum(next_coordinate, 100, ship.z);
  action.st_gt(next_coordinate, 0);
  action.st_gt(2000000000000, next_coordinate);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("z", next_coordinate);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(28, ship);
  ship.update("work", next_work);
}
fn TimeWarpSmall(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 10);
  action.st_sum(ship.rare_extraction_amount, 0, 1);
  var next_epoch = unsafe { ship.epoch - (0 - 1) };
  action.st_sum(ship.epoch, 1, next_epoch);
  action.st_gt(1000000000000, next_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("epoch", next_epoch);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(4, ship);
  ship.update("work", next_work);
}
fn TimeWarpMedium(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 50);
  action.st_sum(ship.rare_extraction_amount, 0, 5);
  var next_epoch = unsafe { ship.epoch - (0 - 10) };
  action.st_sum(ship.epoch, 10, next_epoch);
  action.st_gt(1000000000000, next_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("epoch", next_epoch);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(12, ship);
  ship.update("work", next_work);
}
fn TimeWarpLarge(action) {
  var ship = action.mutate("MicroverseShip");
  action.st_sum(ship.extraction_amount, 0, 250);
  action.st_sum(ship.rare_extraction_amount, 0, 25);
  var next_epoch = unsafe { ship.epoch - (0 - 100) };
  action.st_sum(ship.epoch, 100, next_epoch);
  action.st_gt(1000000000000, next_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("epoch", next_epoch);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
  var next_work = action.intro_vdf(28, ship);
  ship.update("work", next_work);
}
fn ClaimSector(action) {
  var sector = action.output("MicroverseSector");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, ship);
  var sector_x = unsafe { ship.x - 0 };
  var sector_y = unsafe { ship.y - 0 };
  var sector_z = unsafe { ship.z - 0 };
  var sector_epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  sector.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["x", sector_x],
    ["y", sector_y],
    ["z", sector_z],
    ["epoch", sector_epoch],
    ["sector_type", 0],
    ["survey_profile", 0],
    ["planet_remaining", 0],
    ["star_remaining", 0],
    ["gas_giant_remaining", 0],
    ["ice_giant_remaining", 0],
    ["neutron_star_remaining", 0],
    ["black_hole_remaining", 0],
    ["anomaly_remaining", 0],
    ["megastructure_remaining", 0],
    ["gas_cluster_remaining", 0],
    ["stellar_remnant_remaining", 0],
    ["next_planet_serial", 0],
    ["next_star_serial", 0],
    ["next_gas_giant_serial", 0],
    ["next_ice_giant_serial", 0],
    ["next_neutron_star_serial", 0],
    ["next_black_hole_serial", 0],
    ["next_anomaly_serial", 0],
    ["next_megastructure_serial", 0],
    ["next_gas_cluster_serial", 0],
    ["next_stellar_remnant_serial", 0],
    ["revision", 0]
  ]);
  let zero = action.top_limb_u256(0);
  sector.update("key", zero);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  var next_claim_serial = unsafe { ship.claim_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  action.st_sum(ship.claim_serial, 1, next_claim_serial);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  ship.update("claim_serial", next_claim_serial);
  var next_ship_key = action.random();
  ship.update("key", next_ship_key);
}
fn SurveySector_01_Sparse(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(sector.sector_type, 0, 0);
  action.st_sum(sector.survey_profile, 0, 0);
  action.st_sum(sector.planet_remaining, 0, 0);
  action.st_sum(sector.star_remaining, 0, 0);
  action.st_sum(sector.gas_giant_remaining, 0, 0);
  action.st_sum(sector.ice_giant_remaining, 0, 0);
  action.st_sum(sector.neutron_star_remaining, 0, 0);
  action.st_sum(sector.black_hole_remaining, 0, 0);
  action.st_sum(sector.anomaly_remaining, 0, 0);
  action.st_sum(sector.megastructure_remaining, 0, 0);
  action.st_sum(sector.gas_cluster_remaining, 0, 0);
  action.st_sum(sector.stellar_remnant_remaining, 0, 0);
  action.st_sum(sector.next_planet_serial, 0, 0);
  action.st_sum(sector.next_star_serial, 0, 0);
  action.st_sum(sector.next_gas_giant_serial, 0, 0);
  action.st_sum(sector.next_ice_giant_serial, 0, 0);
  action.st_sum(sector.next_neutron_star_serial, 0, 0);
  action.st_sum(sector.next_black_hole_serial, 0, 0);
  action.st_sum(sector.next_anomaly_serial, 0, 0);
  action.st_sum(sector.next_megastructure_serial, 0, 0);
  action.st_sum(sector.next_gas_cluster_serial, 0, 0);
  action.st_sum(sector.next_stellar_remnant_serial, 0, 0);
  var sector_selector = action.random();
  var_assign(sector_selector, sector.stable_identifier);
  sector.update("stable_identifier", sector_selector);
  let profile_lower = action.top_limb_u256(4611686018427387905);
  let profile_upper = action.top_limb_u256(9223372036854775807);
  action.intro_lt_eq_u256(profile_lower, sector_selector);
  action.intro_lt_eq_u256(sector_selector, profile_upper);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);

  sector.update("sector_type", 1);
  sector.update("survey_profile", 1);
  sector.update("planet_remaining", 1);
  sector.update("star_remaining", 1);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn SurveySector_02_Standard(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(sector.sector_type, 0, 0);
  action.st_sum(sector.survey_profile, 0, 0);
  action.st_sum(sector.planet_remaining, 0, 0);
  action.st_sum(sector.star_remaining, 0, 0);
  action.st_sum(sector.gas_giant_remaining, 0, 0);
  action.st_sum(sector.ice_giant_remaining, 0, 0);
  action.st_sum(sector.neutron_star_remaining, 0, 0);
  action.st_sum(sector.black_hole_remaining, 0, 0);
  action.st_sum(sector.anomaly_remaining, 0, 0);
  action.st_sum(sector.megastructure_remaining, 0, 0);
  action.st_sum(sector.gas_cluster_remaining, 0, 0);
  action.st_sum(sector.stellar_remnant_remaining, 0, 0);
  action.st_sum(sector.next_planet_serial, 0, 0);
  action.st_sum(sector.next_star_serial, 0, 0);
  action.st_sum(sector.next_gas_giant_serial, 0, 0);
  action.st_sum(sector.next_ice_giant_serial, 0, 0);
  action.st_sum(sector.next_neutron_star_serial, 0, 0);
  action.st_sum(sector.next_black_hole_serial, 0, 0);
  action.st_sum(sector.next_anomaly_serial, 0, 0);
  action.st_sum(sector.next_megastructure_serial, 0, 0);
  action.st_sum(sector.next_gas_cluster_serial, 0, 0);
  action.st_sum(sector.next_stellar_remnant_serial, 0, 0);
  var sector_selector = action.random();
  var_assign(sector_selector, sector.stable_identifier);
  sector.update("stable_identifier", sector_selector);
  let profile_lower = action.top_limb_u256(1152921504606846977);
  let profile_upper = action.top_limb_u256(4611686018427387904);
  action.intro_lt_eq_u256(profile_lower, sector_selector);
  action.intro_lt_eq_u256(sector_selector, profile_upper);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);

  sector.update("sector_type", 1);
  sector.update("survey_profile", 2);
  sector.update("planet_remaining", 3);
  sector.update("star_remaining", 1);
  sector.update("gas_giant_remaining", 1);
  sector.update("ice_giant_remaining", 1);
  sector.update("gas_cluster_remaining", 2);
  sector.update("stellar_remnant_remaining", 1);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn SurveySector_03_Rich(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(sector.sector_type, 0, 0);
  action.st_sum(sector.survey_profile, 0, 0);
  action.st_sum(sector.planet_remaining, 0, 0);
  action.st_sum(sector.star_remaining, 0, 0);
  action.st_sum(sector.gas_giant_remaining, 0, 0);
  action.st_sum(sector.ice_giant_remaining, 0, 0);
  action.st_sum(sector.neutron_star_remaining, 0, 0);
  action.st_sum(sector.black_hole_remaining, 0, 0);
  action.st_sum(sector.anomaly_remaining, 0, 0);
  action.st_sum(sector.megastructure_remaining, 0, 0);
  action.st_sum(sector.gas_cluster_remaining, 0, 0);
  action.st_sum(sector.stellar_remnant_remaining, 0, 0);
  action.st_sum(sector.next_planet_serial, 0, 0);
  action.st_sum(sector.next_star_serial, 0, 0);
  action.st_sum(sector.next_gas_giant_serial, 0, 0);
  action.st_sum(sector.next_ice_giant_serial, 0, 0);
  action.st_sum(sector.next_neutron_star_serial, 0, 0);
  action.st_sum(sector.next_black_hole_serial, 0, 0);
  action.st_sum(sector.next_anomaly_serial, 0, 0);
  action.st_sum(sector.next_megastructure_serial, 0, 0);
  action.st_sum(sector.next_gas_cluster_serial, 0, 0);
  action.st_sum(sector.next_stellar_remnant_serial, 0, 0);
  var sector_selector = action.random();
  var_assign(sector_selector, sector.stable_identifier);
  sector.update("stable_identifier", sector_selector);
  let profile_lower = action.top_limb_u256(288230376151711745);
  let profile_upper = action.top_limb_u256(1152921504606846976);
  action.intro_lt_eq_u256(profile_lower, sector_selector);
  action.intro_lt_eq_u256(sector_selector, profile_upper);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);

  sector.update("sector_type", 1);
  sector.update("survey_profile", 3);
  sector.update("planet_remaining", 6);
  sector.update("star_remaining", 2);
  sector.update("gas_giant_remaining", 2);
  sector.update("ice_giant_remaining", 2);
  sector.update("neutron_star_remaining", 1);
  sector.update("megastructure_remaining", 2);
  sector.update("gas_cluster_remaining", 4);
  sector.update("stellar_remnant_remaining", 2);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn SurveySector_04_Ancient(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(sector.sector_type, 0, 0);
  action.st_sum(sector.survey_profile, 0, 0);
  action.st_sum(sector.planet_remaining, 0, 0);
  action.st_sum(sector.star_remaining, 0, 0);
  action.st_sum(sector.gas_giant_remaining, 0, 0);
  action.st_sum(sector.ice_giant_remaining, 0, 0);
  action.st_sum(sector.neutron_star_remaining, 0, 0);
  action.st_sum(sector.black_hole_remaining, 0, 0);
  action.st_sum(sector.anomaly_remaining, 0, 0);
  action.st_sum(sector.megastructure_remaining, 0, 0);
  action.st_sum(sector.gas_cluster_remaining, 0, 0);
  action.st_sum(sector.stellar_remnant_remaining, 0, 0);
  action.st_sum(sector.next_planet_serial, 0, 0);
  action.st_sum(sector.next_star_serial, 0, 0);
  action.st_sum(sector.next_gas_giant_serial, 0, 0);
  action.st_sum(sector.next_ice_giant_serial, 0, 0);
  action.st_sum(sector.next_neutron_star_serial, 0, 0);
  action.st_sum(sector.next_black_hole_serial, 0, 0);
  action.st_sum(sector.next_anomaly_serial, 0, 0);
  action.st_sum(sector.next_megastructure_serial, 0, 0);
  action.st_sum(sector.next_gas_cluster_serial, 0, 0);
  action.st_sum(sector.next_stellar_remnant_serial, 0, 0);
  var sector_selector = action.random();
  var_assign(sector_selector, sector.stable_identifier);
  sector.update("stable_identifier", sector_selector);
  let profile_lower = action.top_limb_u256(72057594037927937);
  let profile_upper = action.top_limb_u256(288230376151711744);
  action.intro_lt_eq_u256(profile_lower, sector_selector);
  action.intro_lt_eq_u256(sector_selector, profile_upper);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);

  sector.update("sector_type", 1);
  sector.update("survey_profile", 4);
  sector.update("planet_remaining", 3);
  sector.update("star_remaining", 2);
  sector.update("gas_giant_remaining", 1);
  sector.update("ice_giant_remaining", 1);
  sector.update("neutron_star_remaining", 1);
  sector.update("megastructure_remaining", 9);
  sector.update("gas_cluster_remaining", 2);
  sector.update("stellar_remnant_remaining", 2);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn SurveySector_05_Anomalous(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(sector.sector_type, 0, 0);
  action.st_sum(sector.survey_profile, 0, 0);
  action.st_sum(sector.planet_remaining, 0, 0);
  action.st_sum(sector.star_remaining, 0, 0);
  action.st_sum(sector.gas_giant_remaining, 0, 0);
  action.st_sum(sector.ice_giant_remaining, 0, 0);
  action.st_sum(sector.neutron_star_remaining, 0, 0);
  action.st_sum(sector.black_hole_remaining, 0, 0);
  action.st_sum(sector.anomaly_remaining, 0, 0);
  action.st_sum(sector.megastructure_remaining, 0, 0);
  action.st_sum(sector.gas_cluster_remaining, 0, 0);
  action.st_sum(sector.stellar_remnant_remaining, 0, 0);
  action.st_sum(sector.next_planet_serial, 0, 0);
  action.st_sum(sector.next_star_serial, 0, 0);
  action.st_sum(sector.next_gas_giant_serial, 0, 0);
  action.st_sum(sector.next_ice_giant_serial, 0, 0);
  action.st_sum(sector.next_neutron_star_serial, 0, 0);
  action.st_sum(sector.next_black_hole_serial, 0, 0);
  action.st_sum(sector.next_anomaly_serial, 0, 0);
  action.st_sum(sector.next_megastructure_serial, 0, 0);
  action.st_sum(sector.next_gas_cluster_serial, 0, 0);
  action.st_sum(sector.next_stellar_remnant_serial, 0, 0);
  var sector_selector = action.random();
  var_assign(sector_selector, sector.stable_identifier);
  sector.update("stable_identifier", sector_selector);
  let profile_lower = action.top_limb_u256(0);
  let profile_upper = action.top_limb_u256(72057594037927936);
  action.intro_lt_eq_u256(profile_lower, sector_selector);
  action.intro_lt_eq_u256(sector_selector, profile_upper);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);

  sector.update("sector_type", 1);
  sector.update("survey_profile", 5);
  sector.update("planet_remaining", 3);
  sector.update("star_remaining", 2);
  sector.update("gas_giant_remaining", 1);
  sector.update("ice_giant_remaining", 1);
  sector.update("neutron_star_remaining", 1);
  sector.update("black_hole_remaining", 1);
  sector.update("anomaly_remaining", 1);
  sector.update("megastructure_remaining", 9);
  sector.update("gas_cluster_remaining", 2);
  sector.update("stellar_remnant_remaining", 2);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_00_RedDwarf(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.star_remaining, 0);
  var slot_serial = unsafe { sector.next_star_serial - 0 };
  action.st_sum(sector.next_star_serial, 0, slot_serial);
  var next_star_remaining = unsafe { sector.star_remaining - 1 };
  action.st_sum(next_star_remaining, 1, sector.star_remaining);
  var next_next_star_serial = unsafe { sector.next_star_serial - (0 - 1) };
  action.st_sum(sector.next_star_serial, 1, next_next_star_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 2],
    ["candidate_code", 0],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("star_remaining", next_star_remaining);
  sector.update("next_star_serial", next_next_star_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_01_MainSequenceStar(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.star_remaining, 0);
  var slot_serial = unsafe { sector.next_star_serial - 0 };
  action.st_sum(sector.next_star_serial, 0, slot_serial);
  var next_star_remaining = unsafe { sector.star_remaining - 1 };
  action.st_sum(next_star_remaining, 1, sector.star_remaining);
  var next_next_star_serial = unsafe { sector.next_star_serial - (0 - 1) };
  action.st_sum(sector.next_star_serial, 1, next_next_star_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 2],
    ["candidate_code", 1],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("star_remaining", next_star_remaining);
  sector.update("next_star_serial", next_next_star_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_02_GiantStar(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.star_remaining, 0);
  var slot_serial = unsafe { sector.next_star_serial - 0 };
  action.st_sum(sector.next_star_serial, 0, slot_serial);
  var next_star_remaining = unsafe { sector.star_remaining - 1 };
  action.st_sum(next_star_remaining, 1, sector.star_remaining);
  var next_next_star_serial = unsafe { sector.next_star_serial - (0 - 1) };
  action.st_sum(sector.next_star_serial, 1, next_next_star_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 2],
    ["candidate_code", 2],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("star_remaining", next_star_remaining);
  sector.update("next_star_serial", next_next_star_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_03_RockyPlanet(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.planet_remaining, 0);
  var slot_serial = unsafe { sector.next_planet_serial - 0 };
  action.st_sum(sector.next_planet_serial, 0, slot_serial);
  var next_planet_remaining = unsafe { sector.planet_remaining - 1 };
  action.st_sum(next_planet_remaining, 1, sector.planet_remaining);
  var next_next_planet_serial = unsafe { sector.next_planet_serial - (0 - 1) };
  action.st_sum(sector.next_planet_serial, 1, next_next_planet_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 1],
    ["candidate_code", 3],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("planet_remaining", next_planet_remaining);
  sector.update("next_planet_serial", next_next_planet_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_04_OceanPlanet(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.planet_remaining, 0);
  var slot_serial = unsafe { sector.next_planet_serial - 0 };
  action.st_sum(sector.next_planet_serial, 0, slot_serial);
  var next_planet_remaining = unsafe { sector.planet_remaining - 1 };
  action.st_sum(next_planet_remaining, 1, sector.planet_remaining);
  var next_next_planet_serial = unsafe { sector.next_planet_serial - (0 - 1) };
  action.st_sum(sector.next_planet_serial, 1, next_next_planet_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 1],
    ["candidate_code", 4],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("planet_remaining", next_planet_remaining);
  sector.update("next_planet_serial", next_next_planet_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_05_GardenPlanet(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.planet_remaining, 0);
  var slot_serial = unsafe { sector.next_planet_serial - 0 };
  action.st_sum(sector.next_planet_serial, 0, slot_serial);
  var next_planet_remaining = unsafe { sector.planet_remaining - 1 };
  action.st_sum(next_planet_remaining, 1, sector.planet_remaining);
  var next_next_planet_serial = unsafe { sector.next_planet_serial - (0 - 1) };
  action.st_sum(sector.next_planet_serial, 1, next_next_planet_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 1],
    ["candidate_code", 5],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("planet_remaining", next_planet_remaining);
  sector.update("next_planet_serial", next_next_planet_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_06_GasGiant(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.gas_giant_remaining, 0);
  var slot_serial = unsafe { sector.next_gas_giant_serial - 0 };
  action.st_sum(sector.next_gas_giant_serial, 0, slot_serial);
  var next_gas_giant_remaining = unsafe { sector.gas_giant_remaining - 1 };
  action.st_sum(next_gas_giant_remaining, 1, sector.gas_giant_remaining);
  var next_next_gas_giant_serial = unsafe { sector.next_gas_giant_serial - (0 - 1) };
  action.st_sum(sector.next_gas_giant_serial, 1, next_next_gas_giant_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 3],
    ["candidate_code", 6],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("gas_giant_remaining", next_gas_giant_remaining);
  sector.update("next_gas_giant_serial", next_next_gas_giant_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_07_IceGiant(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.ice_giant_remaining, 0);
  var slot_serial = unsafe { sector.next_ice_giant_serial - 0 };
  action.st_sum(sector.next_ice_giant_serial, 0, slot_serial);
  var next_ice_giant_remaining = unsafe { sector.ice_giant_remaining - 1 };
  action.st_sum(next_ice_giant_remaining, 1, sector.ice_giant_remaining);
  var next_next_ice_giant_serial = unsafe { sector.next_ice_giant_serial - (0 - 1) };
  action.st_sum(sector.next_ice_giant_serial, 1, next_next_ice_giant_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 4],
    ["candidate_code", 7],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("ice_giant_remaining", next_ice_giant_remaining);
  sector.update("next_ice_giant_serial", next_next_ice_giant_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_08_BarrenPlanet(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.planet_remaining, 0);
  var slot_serial = unsafe { sector.next_planet_serial - 0 };
  action.st_sum(sector.next_planet_serial, 0, slot_serial);
  var next_planet_remaining = unsafe { sector.planet_remaining - 1 };
  action.st_sum(next_planet_remaining, 1, sector.planet_remaining);
  var next_next_planet_serial = unsafe { sector.next_planet_serial - (0 - 1) };
  action.st_sum(sector.next_planet_serial, 1, next_next_planet_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 1],
    ["candidate_code", 8],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("planet_remaining", next_planet_remaining);
  sector.update("next_planet_serial", next_next_planet_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_09_NeutronStar(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.neutron_star_remaining, 0);
  var slot_serial = unsafe { sector.next_neutron_star_serial - 0 };
  action.st_sum(sector.next_neutron_star_serial, 0, slot_serial);
  var next_neutron_star_remaining = unsafe { sector.neutron_star_remaining - 1 };
  action.st_sum(next_neutron_star_remaining, 1, sector.neutron_star_remaining);
  var next_next_neutron_star_serial = unsafe { sector.next_neutron_star_serial - (0 - 1) };
  action.st_sum(sector.next_neutron_star_serial, 1, next_next_neutron_star_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 5],
    ["candidate_code", 9],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("neutron_star_remaining", next_neutron_star_remaining);
  sector.update("next_neutron_star_serial", next_next_neutron_star_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_10_BlackHole(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.black_hole_remaining, 0);
  var slot_serial = unsafe { sector.next_black_hole_serial - 0 };
  action.st_sum(sector.next_black_hole_serial, 0, slot_serial);
  var next_black_hole_remaining = unsafe { sector.black_hole_remaining - 1 };
  action.st_sum(next_black_hole_remaining, 1, sector.black_hole_remaining);
  var next_next_black_hole_serial = unsafe { sector.next_black_hole_serial - (0 - 1) };
  action.st_sum(sector.next_black_hole_serial, 1, next_next_black_hole_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 6],
    ["candidate_code", 10],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("black_hole_remaining", next_black_hole_remaining);
  sector.update("next_black_hole_serial", next_next_black_hole_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_11_Anomaly(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.anomaly_remaining, 0);
  var slot_serial = unsafe { sector.next_anomaly_serial - 0 };
  action.st_sum(sector.next_anomaly_serial, 0, slot_serial);
  var next_anomaly_remaining = unsafe { sector.anomaly_remaining - 1 };
  action.st_sum(next_anomaly_remaining, 1, sector.anomaly_remaining);
  var next_next_anomaly_serial = unsafe { sector.next_anomaly_serial - (0 - 1) };
  action.st_sum(sector.next_anomaly_serial, 1, next_next_anomaly_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 7],
    ["candidate_code", 11],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("anomaly_remaining", next_anomaly_remaining);
  sector.update("next_anomaly_serial", next_next_anomaly_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_12_Megastructure(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.megastructure_remaining, 0);
  var slot_serial = unsafe { sector.next_megastructure_serial - 0 };
  action.st_sum(sector.next_megastructure_serial, 0, slot_serial);
  var next_megastructure_remaining = unsafe { sector.megastructure_remaining - 1 };
  action.st_sum(next_megastructure_remaining, 1, sector.megastructure_remaining);
  var next_next_megastructure_serial = unsafe { sector.next_megastructure_serial - (0 - 1) };
  action.st_sum(sector.next_megastructure_serial, 1, next_next_megastructure_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 8],
    ["candidate_code", 12],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("megastructure_remaining", next_megastructure_remaining);
  sector.update("next_megastructure_serial", next_next_megastructure_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_13_GasCluster(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.gas_cluster_remaining, 0);
  var slot_serial = unsafe { sector.next_gas_cluster_serial - 0 };
  action.st_sum(sector.next_gas_cluster_serial, 0, slot_serial);
  var next_gas_cluster_remaining = unsafe { sector.gas_cluster_remaining - 1 };
  action.st_sum(next_gas_cluster_remaining, 1, sector.gas_cluster_remaining);
  var next_next_gas_cluster_serial = unsafe { sector.next_gas_cluster_serial - (0 - 1) };
  action.st_sum(sector.next_gas_cluster_serial, 1, next_next_gas_cluster_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 9],
    ["candidate_code", 13],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("gas_cluster_remaining", next_gas_cluster_remaining);
  sector.update("next_gas_cluster_serial", next_next_gas_cluster_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn DetectCelestialSignal_14_StellarRemnant(action) {
  var next_ship = action.output("MicroverseShip");
  var signal = action.output("MicroverseCelestialSignal");
  var ship = action.input("MicroverseShip");
  var sector = action.mutate("MicroverseSector");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, sector);
  action.st_sum(sector.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(sector.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(sector.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(sector.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(sector.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_discovery_serial = unsafe { ship.discovery_serial - (0 - 1) };
  action.st_sum(ship.discovery_serial, 1, next_discovery_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", 0],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", next_discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(sector.sector_type, 0, 1);
  action.st_gt(sector.survey_profile, 0);
  action.st_gt(sector.stellar_remnant_remaining, 0);
  var slot_serial = unsafe { sector.next_stellar_remnant_serial - 0 };
  action.st_sum(sector.next_stellar_remnant_serial, 0, slot_serial);
  var next_stellar_remnant_remaining = unsafe { sector.stellar_remnant_remaining - 1 };
  action.st_sum(next_stellar_remnant_remaining, 1, sector.stellar_remnant_remaining);
  var next_next_stellar_remnant_serial = unsafe { sector.next_stellar_remnant_serial - (0 - 1) };
  action.st_sum(sector.next_stellar_remnant_serial, 1, next_next_stellar_remnant_serial);
  signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["sector_epoch", epoch],
    ["category_code", 10],
    ["candidate_code", 14],
    ["slot_serial", slot_serial]
  ]);
  let zero = action.top_limb_u256(0);
  signal.update("key", zero);
  var next_sector_revision = unsafe { sector.revision - (0 - 1) };
  action.st_sum(sector.revision, 1, next_sector_revision);
  sector.update("stellar_remnant_remaining", next_stellar_remnant_remaining);
  sector.update("next_stellar_remnant_serial", next_next_stellar_remnant_serial);
  sector.update("revision", next_sector_revision);
  var next_sector_key = action.random();
  rotate_key(sector, next_sector_key);
}
fn ScanCelestialBody_00_RedDwarf(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 2);
  action.st_sum(signal.candidate_code, 0, 0);
  let target = action.top_limb_u256(2305843009213693952);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 0],
    ["body_type", 2],
    ["life_stat", 0],
    ["matter_remaining", 4000],
    ["crystal_remaining", 0],
    ["gas_remaining", 4000],
    ["energy_remaining", 22000],
    ["satellites_remaining", 0],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_01_MainSequenceStar(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 2);
  action.st_sum(signal.candidate_code, 0, 1);
  let target = action.top_limb_u256(576460752303423488);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 1],
    ["body_type", 2],
    ["life_stat", 0],
    ["matter_remaining", 3000],
    ["crystal_remaining", 0],
    ["gas_remaining", 4000],
    ["energy_remaining", 27000],
    ["satellites_remaining", 0],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_02_GiantStar(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 2);
  action.st_sum(signal.candidate_code, 0, 2);
  let target = action.top_limb_u256(72057594037927936);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 2],
    ["body_type", 2],
    ["life_stat", 0],
    ["matter_remaining", 3000],
    ["crystal_remaining", 0],
    ["gas_remaining", 4000],
    ["energy_remaining", 33000],
    ["satellites_remaining", 0],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_03_RockyPlanet(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 1);
  action.st_sum(signal.candidate_code, 0, 3);
  let target = action.top_limb_u256(2305843009213693952);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 3],
    ["body_type", 1],
    ["life_stat", 0],
    ["matter_remaining", 19000],
    ["crystal_remaining", 5000],
    ["gas_remaining", 3000],
    ["energy_remaining", 3000],
    ["satellites_remaining", 1],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_04_OceanPlanet(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 1);
  action.st_sum(signal.candidate_code, 0, 4);
  let target = action.top_limb_u256(576460752303423488);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 4],
    ["body_type", 1],
    ["life_stat", 2],
    ["matter_remaining", 14000],
    ["crystal_remaining", 3000],
    ["gas_remaining", 14000],
    ["energy_remaining", 3000],
    ["satellites_remaining", 2],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_05_GardenPlanet(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 1);
  action.st_sum(signal.candidate_code, 0, 5);
  let target = action.top_limb_u256(144115188075855872);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 5],
    ["body_type", 1],
    ["life_stat", 4],
    ["matter_remaining", 17000],
    ["crystal_remaining", 9000],
    ["gas_remaining", 6000],
    ["energy_remaining", 6000],
    ["satellites_remaining", 1],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_06_GasGiant(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 3);
  action.st_sum(signal.candidate_code, 0, 6);
  let target = action.top_limb_u256(1152921504606846976);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 6],
    ["body_type", 3],
    ["life_stat", 0],
    ["matter_remaining", 2000],
    ["crystal_remaining", 0],
    ["gas_remaining", 24000],
    ["energy_remaining", 6000],
    ["satellites_remaining", 4],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_07_IceGiant(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 4);
  action.st_sum(signal.candidate_code, 0, 7);
  let target = action.top_limb_u256(576460752303423488);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 7],
    ["body_type", 4],
    ["life_stat", 0],
    ["matter_remaining", 4000],
    ["crystal_remaining", 9000],
    ["gas_remaining", 17000],
    ["energy_remaining", 4000],
    ["satellites_remaining", 3],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_08_BarrenPlanet(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 1);
  action.st_sum(signal.candidate_code, 0, 8);
  let target = action.top_limb_u256(1152921504606846976);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 8],
    ["body_type", 1],
    ["life_stat", 0],
    ["matter_remaining", 23000],
    ["crystal_remaining", 9000],
    ["gas_remaining", 0],
    ["energy_remaining", 0],
    ["satellites_remaining", 0],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_09_NeutronStar(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 5);
  action.st_sum(signal.candidate_code, 0, 9);
  let target = action.top_limb_u256(9007199254740992);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 9],
    ["body_type", 5],
    ["life_stat", 0],
    ["matter_remaining", 2000],
    ["crystal_remaining", 1000],
    ["gas_remaining", 0],
    ["energy_remaining", 43000],
    ["satellites_remaining", 0],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_10_BlackHole(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 6);
  action.st_sum(signal.candidate_code, 0, 10);
  let target = action.top_limb_u256(2251799813685248);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 10],
    ["body_type", 6],
    ["life_stat", 0],
    ["matter_remaining", 0],
    ["crystal_remaining", 0],
    ["gas_remaining", 0],
    ["energy_remaining", 50000],
    ["satellites_remaining", 0],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_11_Anomaly(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 7);
  action.st_sum(signal.candidate_code, 0, 11);
  let target = action.top_limb_u256(562949953421312);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 11],
    ["body_type", 7],
    ["life_stat", 0],
    ["matter_remaining", 18000],
    ["crystal_remaining", 9000],
    ["gas_remaining", 9000],
    ["energy_remaining", 18000],
    ["satellites_remaining", 0],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_12_Megastructure(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 8);
  action.st_sum(signal.candidate_code, 0, 12);
  let target = action.top_limb_u256(2305843009213693952);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 12],
    ["body_type", 8],
    ["life_stat", 0],
    ["matter_remaining", 10000],
    ["crystal_remaining", 10000],
    ["gas_remaining", 0],
    ["energy_remaining", 10000],
    ["satellites_remaining", 0],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_13_GasCluster(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 9);
  action.st_sum(signal.candidate_code, 0, 13);
  let target = action.top_limb_u256(2305843009213693952);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 13],
    ["body_type", 9],
    ["life_stat", 0],
    ["matter_remaining", 5000],
    ["crystal_remaining", 0],
    ["gas_remaining", 20000],
    ["energy_remaining", 5000],
    ["satellites_remaining", 0],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ScanCelestialBody_14_StellarRemnant(action) {
  var body = action.output("MicroverseCelestialBody");
  var signal = action.input("MicroverseCelestialSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, signal);
  prove_fixed_versions(action, ship);
  action.st_sum(signal.body_bank_version, 0, 1);
  action.st_sum(signal.category_code, 0, 10);
  action.st_sum(signal.candidate_code, 0, 14);
  let target = action.top_limb_u256(2305843009213693952);

  action.st_gt(signal.slot_serial, -1);

  var source_signal_identifier = action.random();
  var_assign(source_signal_identifier, signal.stable_identifier);
  signal.update("stable_identifier", source_signal_identifier);

  var sector_x = unsafe { signal.sector_x - 0 };
  var sector_y = unsafe { signal.sector_y - 0 };
  var sector_z = unsafe { signal.sector_z - 0 };
  var sector_epoch = unsafe { signal.sector_epoch - 0 };
  action.st_sum(signal.sector_x, 0, sector_x);
  action.st_sum(signal.sector_y, 0, sector_y);
  action.st_sum(signal.sector_z, 0, sector_z);
  action.st_sum(signal.sector_epoch, 0, sector_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, sector_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  action.intro_lt_eq_u256(signal, target);
  body.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["body_bank_version", 1],
    ["source_signal_identifier", source_signal_identifier],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["sector_epoch", sector_epoch],
    ["candidate_code", 14],
    ["body_type", 10],
    ["life_stat", 0],
    ["matter_remaining", 10000],
    ["crystal_remaining", 0],
    ["gas_remaining", 0],
    ["energy_remaining", 20000],
    ["satellites_remaining", 0],
    ["next_satellite_serial", 0],
    ["civilization_discovered", 0]
  ]);
  let zero = action.top_limb_u256(0);
  body.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ExtractAnomalyWarpCoordinate(action) {
  var next_ship = action.output("MicroverseShip");
  var coordinate = action.output("MicroverseWarpCoordinate");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, body);
  action.st_sum(body.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(body.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(body.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(body.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(body.sector_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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
  action.st_sum(ship.extraction_amount, 0, 250);
  action.st_sum(ship.rare_extraction_amount, 0, 25);
  action.st_sum(ship.active_skill_type, 0, 14);
  action.st_sum(body.candidate_code, 0, 11);
  action.st_sum(body.body_type, 0, 7);

  var source_body_identifier = action.random();
  var_assign(source_body_identifier, body.stable_identifier);
  body.update("stable_identifier", source_body_identifier);
  var source_pool_before = unsafe { body.energy_remaining - 0 };
  action.st_sum(body.energy_remaining, 0, source_pool_before);
  var next_energy = unsafe { source_pool_before - 9000 };
  action.st_sum(next_energy, 9000, source_pool_before);
  action.st_gt(next_energy, -1);

  coordinate.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["source_body_identifier", source_body_identifier],
    ["source_pool_before", source_pool_before],
    ["revealed", 0],
    ["destination_code", 0],
    ["destination_x", 0],
    ["destination_y", 0],
    ["destination_z", 0],
    ["uses_remaining", 0]
  ]);
  let zero = action.top_limb_u256(0);
  coordinate.update("key", zero);
  body.update("energy_remaining", next_energy);
  var next_body_key = action.random();
  rotate_key(body, next_body_key);
}
fn ExtractAnomalyTimeCoordinate(action) {
  var next_ship = action.output("MicroverseShip");
  var coordinate = action.output("MicroverseTimeCoordinate");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, body);
  action.st_sum(body.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(body.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(body.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(body.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(body.sector_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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
  action.st_sum(ship.extraction_amount, 0, 250);
  action.st_sum(ship.rare_extraction_amount, 0, 25);
  action.st_sum(ship.active_skill_type, 0, 14);
  action.st_sum(body.candidate_code, 0, 11);
  action.st_sum(body.body_type, 0, 7);

  var source_body_identifier = action.random();
  var_assign(source_body_identifier, body.stable_identifier);
  body.update("stable_identifier", source_body_identifier);
  var source_pool_before = unsafe { body.energy_remaining - 0 };
  action.st_sum(body.energy_remaining, 0, source_pool_before);
  var next_energy = unsafe { source_pool_before - 9000 };
  action.st_sum(next_energy, 9000, source_pool_before);
  action.st_gt(next_energy, -1);

  coordinate.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["source_body_identifier", source_body_identifier],
    ["source_pool_before", source_pool_before],
    ["revealed", 0],
    ["destination_code", 0],
    ["destination_epoch", 0],
    ["uses_remaining", 0]
  ]);
  let zero = action.top_limb_u256(0);
  coordinate.update("key", zero);
  body.update("energy_remaining", next_energy);
  var next_body_key = action.random();
  rotate_key(body, next_body_key);
}
fn RevealWarpCoordinate001(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 1, 793814733, 968149119310, 42019687806, 10, 0, 184467440694145842);
}
fn RevealWarpCoordinate002(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 2, 327853439873, 605502947, 3102, 3, 184467440694145843, 737869762776583371);
}
fn RevealWarpCoordinate003(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 3, 105, 465107091, 86018776812, 3, 737869762776583372, 1291272084859020901);
}
fn RevealWarpCoordinate004(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 4, 814097886, 251671466, 624, 3, 1291272084859020902, 1844674406941458431);
}
fn RevealWarpCoordinate005(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 5, 9816070892, 17687307174, 1647, 1, 1844674406941458432, 1983024987462067813);
}
fn RevealWarpCoordinate006(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 6, 5411, 4089311236, 8166194, 1, 1983024987462067814, 2121375567982677195);
}
fn RevealWarpCoordinate007(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 7, 3554, 138474846290, 2683096595, 1, 2121375567982677196, 2259726148503286578);
}
fn RevealWarpCoordinate008(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 8, 304051388063, 1555081630477, 862, 1, 2259726148503286579, 2398076729023895960);
}
fn RevealWarpCoordinate009(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 9, 1599211110330, 835802248014, 61425, 1, 2398076729023895961, 2536427309544505343);
}
fn RevealWarpCoordinate010(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 10, 8800041, 92923, 6899663, 1, 2536427309544505344, 2674777890065114725);
}
fn RevealWarpCoordinate011(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 11, 36941537, 718644, 90633, 1, 2674777890065114726, 2813128470585724107);
}
fn RevealWarpCoordinate012(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 12, 9337934020, 267915, 612152605, 1, 2813128470585724108, 2951479051106333490);
}
fn RevealWarpCoordinate013(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 13, 6744467, 1242490000981, 7902244, 1, 2951479051106333491, 3089829631626942872);
}
fn RevealWarpCoordinate014(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 14, 38345967539, 850429340, 697145654, 1, 3089829631626942873, 3228180212147552255);
}
fn RevealWarpCoordinate015(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 15, 5999015, 56856983, 64952, 1, 3228180212147552256, 3366530792668161637);
}
fn RevealWarpCoordinate016(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 16, 74640977, 831224, 67427465431, 1, 3366530792668161638, 3504881373188771019);
}
fn RevealWarpCoordinate017(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 17, 612742724029, 1842615838159, 620841, 1, 3504881373188771020, 3643231953709380402);
}
fn RevealWarpCoordinate018(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 18, 79068746, 3516959, 57065984, 1, 3643231953709380403, 3781582534229989784);
}
fn RevealWarpCoordinate019(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 19, 51382549782, 5528417226, 62111104, 1, 3781582534229989785, 3919933114750599167);
}
fn RevealWarpCoordinate020(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 20, 76219270, 80009, 1703747360730, 1, 3919933114750599168, 4058283695271208549);
}
fn RevealWarpCoordinate021(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 21, 1795412047697, 845871, 415, 1, 4058283695271208550, 4196634275791817932);
}
fn RevealWarpCoordinate022(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 22, 660848117667, 271400, 334705, 1, 4196634275791817933, 4334984856312427314);
}
fn RevealWarpCoordinate023(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 23, 316245807504, 1644, 428363, 1, 4334984856312427315, 4473335436833036696);
}
fn RevealWarpCoordinate024(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 24, 402293889292, 351046010, 59250682625, 1, 4473335436833036697, 4611686017353646079);
}
fn RevealWarpCoordinate025(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 25, 24491, 49227, 1029107766704, 1, 4611686017353646080, 4750036597874255461);
}
fn RevealWarpCoordinate026(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 26, 891311451115, 481989, 9218437, 1, 4750036597874255462, 4888387178394864844);
}
fn RevealWarpCoordinate027(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 27, 5364, 979, 61474, 1, 4888387178394864845, 5026737758915474226);
}
fn RevealWarpCoordinate028(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 28, 7511717098, 23973543873, 576929938269, 1, 5026737758915474227, 5165088339436083608);
}
fn RevealWarpCoordinate029(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 29, 49656048395, 8956, 1622146405114, 1, 5165088339436083609, 5303438919956692991);
}
fn RevealWarpCoordinate030(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 30, 86575726573, 951729416101, 725, 1, 5303438919956692992, 5441789500477302373);
}
fn RevealWarpCoordinate031(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 31, 66964245769, 3641, 1929443695472, 1, 5441789500477302374, 5580140080997911756);
}
fn RevealWarpCoordinate032(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 32, 3328235205, 8159725451, 161, 1, 5580140080997911757, 5718490661518521138);
}
fn RevealWarpCoordinate033(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 33, 39759057, 101660631, 674, 1, 5718490661518521139, 5856841242039130520);
}
fn RevealWarpCoordinate034(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 34, 6685, 92082552830, 54238, 1, 5856841242039130521, 5995191822559739903);
}
fn RevealWarpCoordinate035(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 35, 14974427, 98934823, 1819704510913, 1, 5995191822559739904, 6133542403080349285);
}
fn RevealWarpCoordinate036(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 36, 24944230017, 147614734, 2500243663, 1, 6133542403080349286, 6271892983600958668);
}
fn RevealWarpCoordinate037(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 37, 646052251, 663494, 81352378, 1, 6271892983600958669, 6410243564121568050);
}
fn RevealWarpCoordinate038(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 38, 372316739, 7938120392, 1075364813302, 1, 6410243564121568051, 6548594144642177432);
}
fn RevealWarpCoordinate039(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 39, 1166628200, 10526279194, 830059075497, 1, 6548594144642177433, 6686944725162786815);
}
fn RevealWarpCoordinate040(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 40, 210, 7442044, 1316754193677, 1, 6686944725162786816, 6825295305683396197);
}
fn RevealWarpCoordinate041(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 41, 38900, 4723, 6321753, 1, 6825295305683396198, 6963645886204005580);
}
fn RevealWarpCoordinate042(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 42, 1996409208667, 368553358663, 1734922, 1, 6963645886204005581, 7101996466724614962);
}
fn RevealWarpCoordinate043(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 43, 288, 6586, 19494804, 1, 7101996466724614963, 7240347047245224344);
}
fn RevealWarpCoordinate044(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 44, 485, 422411318214, 2619205, 1, 7240347047245224345, 7378697627765833727);
}
fn RevealWarpCoordinate045(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 45, 966, 533868729796, 590961427322, 1, 7378697627765833728, 7517048208286443109);
}
fn RevealWarpCoordinate046(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 46, 52502323784, 78133, 454, 1, 7517048208286443110, 7655398788807052492);
}
fn RevealWarpCoordinate047(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 47, 76703948680, 9860, 11948, 1, 7655398788807052493, 7793749369327661874);
}
fn RevealWarpCoordinate048(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 48, 314, 71372, 270745696569, 1, 7793749369327661875, 7932099949848271257);
}
fn RevealWarpCoordinate049(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 49, 68339007, 806, 1971315750, 1, 7932099949848271258, 8070450530368880639);
}
fn RevealWarpCoordinate050(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 50, 5137455393, 944693917055, 3458525209, 1, 8070450530368880640, 8208801110889490021);
}
fn RevealWarpCoordinate051(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 51, 1353, 21802810, 252999300494, 1, 8208801110889490022, 8345307017003157945);
}
fn RevealWarpCoordinate052(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 52, 4680, 9185, 868, 1, 8345307017003157946, 8481812923116825869);
}
fn RevealWarpCoordinate053(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 53, 7524306, 350843987584, 202765, 1, 8481812923116825870, 8618318829230493793);
}
fn RevealWarpCoordinate054(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 54, 7632689, 1936956092484, 469012280963, 1, 8618318829230493794, 8754824735344161717);
}
fn RevealWarpCoordinate055(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 55, 614439419610, 827189, 112195927905, 1, 8754824735344161718, 8891330641457829641);
}
fn RevealWarpCoordinate056(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 56, 582061892477, 20141524, 8472773550, 1, 8891330641457829642, 9027836547571497565);
}
fn RevealWarpCoordinate057(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 57, 1573688960761, 7976, 137, 1, 9027836547571497566, 9164342453685165489);
}
fn RevealWarpCoordinate058(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 58, 3986, 1261757673690, 66936285117, 1, 9164342453685165490, -9145895713910718203);
}
fn RevealWarpCoordinate059(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 59, 729009262, 372761, 626730552, 1, -9145895713910718202, -9009389807797050279);
}
fn RevealWarpCoordinate060(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 60, 1104055358028, 86077, 441, 1, -9009389807797050278, -8872883901683382355);
}
fn RevealWarpCoordinate061(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 61, 52596109189, 3933090003, 4456, 1, -8872883901683382354, -8736377995569714431);
}
fn RevealWarpCoordinate062(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 62, 751694, 53701, 1314934400969, 1, -8736377995569714430, -8599872089456046507);
}
fn RevealWarpCoordinate063(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 63, 674369454170, 1293446417136, 392714, 1, -8599872089456046506, -8463366183342378583);
}
fn RevealWarpCoordinate064(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 64, 175503070271, 6129473553, 861604111960, 1, -8463366183342378582, -8326860277228710659);
}
fn RevealWarpCoordinate065(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 65, 5834724, 3286, 524, 1, -8326860277228710658, -8190354371115042735);
}
fn RevealWarpCoordinate066(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 66, 97441800, 90047032, 53343231, 1, -8190354371115042734, -8053848465001374811);
}
fn RevealWarpCoordinate067(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 67, 138301, 5743516, 1938696380619, 1, -8053848465001374810, -7917342558887706887);
}
fn RevealWarpCoordinate068(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 68, 858558, 564867, 7888191, 1, -7917342558887706886, -7780836652774038963);
}
fn RevealWarpCoordinate069(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 69, 825683632839, 700275972037, 783698141526, 1, -7780836652774038962, -7644330746660371039);
}
fn RevealWarpCoordinate070(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 70, 70325858, 332752, 18666153827, 1, -7644330746660371038, -7507824840546703115);
}
fn RevealWarpCoordinate071(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 71, 4959023, 90901641829, 17537364, 1, -7507824840546703114, -7371318934433035191);
}
fn RevealWarpCoordinate072(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 72, 79640, 353359, 48880, 1, -7371318934433035190, -7234813028319367267);
}
fn RevealWarpCoordinate073(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 73, 14944048679, 5098196192, 412, 1, -7234813028319367266, -7098307122205699343);
}
fn RevealWarpCoordinate074(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 74, 59136791, 1445698873532, 85863, 1, -7098307122205699342, -6961801216092031419);
}
fn RevealWarpCoordinate075(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 75, 685809, 1497175958752, 8978, 1, -6961801216092031418, -6825295309978363495);
}
fn RevealWarpCoordinate076(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 76, 5246715487, 34680434180, 295007845, 1, -6825295309978363494, -6688789403864695571);
}
fn RevealWarpCoordinate077(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 77, 62585671, 3692, 649793205, 1, -6688789403864695570, -6552283497751027647);
}
fn RevealWarpCoordinate078(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 78, 1072393121557, 228742, 26765, 1, -6552283497751027646, -6415777591637359723);
}
fn RevealWarpCoordinate079(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 79, 915, 1443398724083, 8138707380, 1, -6415777591637359722, -6279271685523691799);
}
fn RevealWarpCoordinate080(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 80, 549, 5269348966, 1682994349116, 1, -6279271685523691798, -6142765779410023875);
}
fn RevealWarpCoordinate081(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 81, 6647239013, 6275506, 9077600, 1, -6142765779410023874, -6006259873296355951);
}
fn RevealWarpCoordinate082(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 82, 8459930015, 762, 1651, 1, -6006259873296355950, -5869753967182688027);
}
fn RevealWarpCoordinate083(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 83, 9934711, 1258299, 59728098252, 1, -5869753967182688026, -5733248061069020103);
}
fn RevealWarpCoordinate084(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 84, 710, 7606736, 1557909202223, 1, -5733248061069020102, -5596742154955352179);
}
fn RevealWarpCoordinate085(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 85, 299, 66523168873, 284626892275, 1, -5596742154955352178, -5460236248841684256);
}
fn RevealWarpCoordinate086(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 86, 6152982, 7754874715, 297911415, 1, -5460236248841684255, -5323730342728016332);
}
fn RevealWarpCoordinate087(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 87, 78887, 1027431, 8413, 1, -5323730342728016331, -5187224436614348408);
}
fn RevealWarpCoordinate088(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 88, 44634, 14327071, 942410917, 1, -5187224436614348407, -5050718530500680484);
}
fn RevealWarpCoordinate089(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 89, 149566, 44461313485, 602, 1, -5050718530500680483, -4914212624387012560);
}
fn RevealWarpCoordinate090(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 90, 9123, 915028640, 90641, 1, -4914212624387012559, -4777706718273344636);
}
fn RevealWarpCoordinate091(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 91, 398540000679, 8784213, 5356, 1, -4777706718273344635, -4641200812159676712);
}
fn RevealWarpCoordinate092(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 92, 34771, 84430, 7861, 1, -4641200812159676711, -4504694906046008788);
}
fn RevealWarpCoordinate093(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 93, 2534239576, 3469374, 1106468458539, 1, -4504694906046008787, -4368188999932340864);
}
fn RevealWarpCoordinate094(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 94, 983822125, 895056, 335156, 1, -4368188999932340863, -4231683093818672940);
}
fn RevealWarpCoordinate095(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 95, 3277916, 15182044245, 28749, 1, -4231683093818672939, -4095177187705005016);
}
fn RevealWarpCoordinate096(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 96, 3405252341, 601743, 331027450969, 1, -4095177187705005015, -3958671281591337092);
}
fn RevealWarpCoordinate097(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 97, 7642808796, 1094001984094, 79759561924, 1, -3958671281591337091, -3822165375477669168);
}
fn RevealWarpCoordinate098(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 98, 903829411, 904830290312, 459, 1, -3822165375477669167, -3685659469364001244);
}
fn RevealWarpCoordinate099(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 99, 4676559, 114518980363, 856, 1, -3685659469364001243, -3549153563250333320);
}
fn RevealWarpCoordinate100(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 100, 766, 26758237583, 9707, 1, -3549153563250333319, -3412647657136665396);
}
fn RevealWarpCoordinate101(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 101, 82778400, 8860, 362295963, 1, -3412647657136665395, -3276141751022997472);
}
fn RevealWarpCoordinate102(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 102, 1596782367732, 1267532572787, 39058994718, 1, -3276141751022997471, -3139635844909329548);
}
fn RevealWarpCoordinate103(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 103, 6045, 5859608, 1389083, 1, -3139635844909329547, -3003129938795661624);
}
fn RevealWarpCoordinate104(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 104, 6949, 8797833047, 50774, 1, -3003129938795661623, -2866624032681993700);
}
fn RevealWarpCoordinate105(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 105, 798, 602, 9936325343, 1, -2866624032681993699, -2730118126568325776);
}
fn RevealWarpCoordinate106(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 106, 788045056049, 1060, 1644224548739, 1, -2730118126568325775, -2593612220454657852);
}
fn RevealWarpCoordinate107(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 107, 772432026, 1280668882809, 1916324341020, 1, -2593612220454657851, -2457106314340989928);
}
fn RevealWarpCoordinate108(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 108, 3378640, 33285937, 230946158499, 1, -2457106314340989927, -2320600408227322004);
}
fn RevealWarpCoordinate109(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 109, 647133815143, 5858, 1127510, 1, -2320600408227322003, -2184094502113654080);
}
fn RevealWarpCoordinate110(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 110, 658, 44707717, 373, 1, -2184094502113654079, -2047588595999986156);
}
fn RevealWarpCoordinate111(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 111, 4960689, 541034, 32943629, 1, -2047588595999986155, -1911082689886318232);
}
fn RevealWarpCoordinate112(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 112, 608860492110, 185294125, 103, 1, -1911082689886318231, -1774576783772650308);
}
fn RevealWarpCoordinate113(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 113, 799422578687, 1960183226040, 111, 1, -1774576783772650307, -1638070877658982384);
}
fn RevealWarpCoordinate114(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 114, 6945298, 13302745, 483914, 1, -1638070877658982383, -1501564971545314460);
}
fn RevealWarpCoordinate115(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 115, 78332954177, 707991091435, 4786950492, 1, -1501564971545314459, -1365059065431646536);
}
fn RevealWarpCoordinate116(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 116, 323464621723, 860, 614040324083, 1, -1365059065431646535, -1228553159317978612);
}
fn RevealWarpCoordinate117(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 117, 33422934605, 447154297, 71851297056, 1, -1228553159317978611, -1092047253204310688);
}
fn RevealWarpCoordinate118(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 118, 4643524785, 8617199432, 274, 1, -1092047253204310687, -955541347090642764);
}
fn RevealWarpCoordinate119(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 119, 908538877625, 921, 2870139, 1, -955541347090642763, -819035440976974840);
}
fn RevealWarpCoordinate120(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 120, 5446223406, 1619077126727, 1703, 1, -819035440976974839, -682529534863306916);
}
fn RevealWarpCoordinate121(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 121, 659, 717811, 90078, 1, -682529534863306915, -546023628749638992);
}
fn RevealWarpCoordinate122(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 122, 19944, 555485, 882, 1, -546023628749638991, -409517722635971068);
}
fn RevealWarpCoordinate123(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 123, 1385638833787, 982971504292, 58613, 1, -409517722635971067, -273011816522303144);
}
fn RevealWarpCoordinate124(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 124, 1244899207058, 43514054064, 35564, 1, -273011816522303143, -136505910408635220);
}
fn RevealWarpCoordinate125(action) {
  var c = action.mutate("MicroverseWarpCoordinate");
  reveal_p(action, c, 125, 7032978, 1559777421188, 362706019, 1, -136505910408635219, -4294967296);
}
fn RevealTimeCoordinate01(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 1, 101, 10, 0, 184467440694145842);
}
fn RevealTimeCoordinate02(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 2, 19257, 3, 184467440694145843, 737869762776583371);
}
fn RevealTimeCoordinate03(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 3, 306610, 3, 737869762776583372, 1291272084859020901);
}
fn RevealTimeCoordinate04(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 4, 1551806, 3, 1291272084859020902, 1844674406941458431);
}
fn RevealTimeCoordinate05(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 5, 4904256, 1, 1844674406941458432, 2047588591705018858);
}
fn RevealTimeCoordinate06(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 6, 11973137, 1, 2047588591705018859, 2250502776468579286);
}
fn RevealTimeCoordinate07(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 7, 24827389, 1, 2250502776468579287, 2453416961232139713);
}
fn RevealTimeCoordinate08(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 8, 45995718, 1, 2453416961232139714, 2656331145995700141);
}
fn RevealTimeCoordinate09(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 9, 78466594, 1, 2656331145995700142, 2859245330759260568);
}
fn RevealTimeCoordinate10(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 10, 125688251, 1, 2859245330759260569, 3062159515522820996);
}
fn RevealTimeCoordinate11(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 11, 191568688, 1, 3062159515522820997, 3265073700286381423);
}
fn RevealTimeCoordinate12(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 12, 280475669, 1, 3265073700286381424, 3467987885049941851);
}
fn RevealTimeCoordinate13(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 13, 397236724, 1, 3467987885049941852, 3670902069813502278);
}
fn RevealTimeCoordinate14(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 14, 547139143, 1, 3670902069813502279, 3873816254577062706);
}
fn RevealTimeCoordinate15(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 15, 735929986, 1, 3873816254577062707, 4076730439340623133);
}
fn RevealTimeCoordinate16(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 16, 969816075, 1, 4076730439340623134, 4279644624104183561);
}
fn RevealTimeCoordinate17(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 17, 1255463996, 1, 4279644624104183562, 4482558808867743989);
}
fn RevealTimeCoordinate18(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 18, 1600000100, 1, 4482558808867743990, 4685472993631304416);
}
fn RevealTimeCoordinate19(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 19, 2011010505, 1, 4685472993631304417, 4888387178394864844);
}
fn RevealTimeCoordinate20(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 20, 2496541090, 1, 4888387178394864845, 5091301363158425271);
}
fn RevealTimeCoordinate21(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 21, 3065097501, 1, 5091301363158425272, 5294215547921985699);
}
fn RevealTimeCoordinate22(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 22, 3725645147, 1, 5294215547921985700, 5497129732685546126);
}
fn RevealTimeCoordinate23(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 23, 4487609204, 1, 5497129732685546127, 5700043917449106554);
}
fn RevealTimeCoordinate24(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 24, 5360874611, 1, 5700043917449106555, 5902958102212666981);
}
fn RevealTimeCoordinate25(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 25, 6355786070, 1, 5902958102212666982, 6105872286976227409);
}
fn RevealTimeCoordinate26(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 26, 7483148051, 1, 6105872286976227410, 6308786471739787836);
}
fn RevealTimeCoordinate27(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 27, 8754224786, 1, 6308786471739787837, 6511700656503348264);
}
fn RevealTimeCoordinate28(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 28, 10180740273, 1, 6511700656503348265, 6714614841266908691);
}
fn RevealTimeCoordinate29(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 29, 11774878274, 1, 6714614841266908692, 6917529026030469119);
}
fn RevealTimeCoordinate30(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 30, 13549282316, 1, 6917529026030469120, 7120443210794029546);
}
fn RevealTimeCoordinate31(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 31, 15517055690, 1, 7120443210794029547, 7323357395557589974);
}
fn RevealTimeCoordinate32(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 32, 17691761452, 1, 7323357395557589975, 7526271580321150401);
}
fn RevealTimeCoordinate33(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 33, 20087422423, 1, 7526271580321150402, 7729185765084710829);
}
fn RevealTimeCoordinate34(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 34, 22718521189, 1, 7729185765084710830, 7932099949848271257);
}
fn RevealTimeCoordinate35(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 35, 25600000098, 1, 7932099949848271258, 8135014134611831684);
}
fn RevealTimeCoordinate36(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 36, 28747261265, 1, 8135014134611831685, 8337928319375392112);
}
fn RevealTimeCoordinate37(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 37, 32176166570, 1, 8337928319375392113, 8540842504138952539);
}
fn RevealTimeCoordinate38(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 38, 35903037656, 1, 8540842504138952540, 8743756688902512967);
}
fn RevealTimeCoordinate39(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 39, 39944655931, 1, 8743756688902512968, 8946670873666073394);
}
fn RevealTimeCoordinate40(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 40, 44318262569, 1, 8946670873666073395, 9149585058429633822);
}
fn RevealTimeCoordinate41(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 41, 49041558506, 1, 9149585058429633823, -9094244830516357367);
}
fn RevealTimeCoordinate42(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 42, 54132704445, 1, -9094244830516357366, -8891330645752796939);
}
fn RevealTimeCoordinate43(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 43, 59610320852, 1, -8891330645752796938, -8688416460989236512);
}
fn RevealTimeCoordinate44(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 44, 65493487959, 1, -8688416460989236511, -8485502276225676084);
}
fn RevealTimeCoordinate45(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 45, 71801745762, 1, -8485502276225676083, -8282588091462115657);
}
fn RevealTimeCoordinate46(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 46, 78555094021, 1, -8282588091462115656, -8079673906698555229);
}
fn RevealTimeCoordinate47(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 47, 85773992261, 1, -8079673906698555228, -7876759721934994802);
}
fn RevealTimeCoordinate48(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 48, 93479359773, 1, -7876759721934994801, -7673845537171434374);
}
fn RevealTimeCoordinate49(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 49, 101692575610, 1, -7673845537171434373, -7470931352407873947);
}
fn RevealTimeCoordinate50(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 50, 110435478592, 1, -7470931352407873946, -7268017167644313519);
}
fn RevealTimeCoordinate51(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 51, 119730367301, 1, -7268017167644313518, -7065102982880753091);
}
fn RevealTimeCoordinate52(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 52, 129600000087, 1, -7065102982880753090, -6862188798117192664);
}
fn RevealTimeCoordinate53(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 53, 140067595062, 1, -6862188798117192663, -6659274613353632236);
}
fn RevealTimeCoordinate54(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 54, 151156830104, 1, -6659274613353632235, -6456360428590071809);
}
fn RevealTimeCoordinate55(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 55, 162891842854, 1, -6456360428590071808, -6253446243826511381);
}
fn RevealTimeCoordinate56(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 56, 175297230719, 1, -6253446243826511380, -6050532059062950954);
}
fn RevealTimeCoordinate57(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 57, 188398050871, 1, -6050532059062950953, -5847617874299390526);
}
fn RevealTimeCoordinate58(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 58, 202219820245, 1, -5847617874299390525, -5644703689535830099);
}
fn RevealTimeCoordinate59(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 59, 216788515542, 1, -5644703689535830098, -5441789504772269671);
}
fn RevealTimeCoordinate60(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 60, 232130573226, 1, -5441789504772269670, -5238875320008709244);
}
fn RevealTimeCoordinate61(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 61, 248272889528, 1, -5238875320008709243, -5035961135245148816);
}
fn RevealTimeCoordinate62(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 62, 265242820442, 1, -5035961135245148815, -4833046950481588389);
}
fn RevealTimeCoordinate63(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 63, 283068181727, 1, -4833046950481588388, -4630132765718027961);
}
fn RevealTimeCoordinate64(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 64, 301777248905, 1, -4630132765718027960, -4427218580954467534);
}
fn RevealTimeCoordinate65(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 65, 321398757267, 1, -4427218580954467533, -4224304396190907106);
}
fn RevealTimeCoordinate66(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 66, 341961901863, 1, -4224304396190907105, -4021390211427346678);
}
fn RevealTimeCoordinate67(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 67, 363496337511, 1, -4021390211427346677, -3820320701070727709);
}
fn RevealTimeCoordinate68(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 68, 386032178795, 1, -3820320701070727708, -3619251190714108740);
}
fn RevealTimeCoordinate69(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 69, 409600000059, 1, -3619251190714108739, -3418181680357489771);
}
fn RevealTimeCoordinate70(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 70, 434230835415, 1, -3418181680357489770, -3217112170000870802);
}
fn RevealTimeCoordinate71(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 71, 459956178739, 1, -3217112170000870801, -3016042659644251833);
}
fn RevealTimeCoordinate72(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 72, 486807983672, 1, -3016042659644251832, -2814973149287632864);
}
fn RevealTimeCoordinate73(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 73, 514818663618, 1, -2814973149287632863, -2613903638931013895);
}
fn RevealTimeCoordinate74(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 74, 544021091746, 1, -2613903638931013894, -2412834128574394926);
}
fn RevealTimeCoordinate75(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 75, 574448600993, 1, -2412834128574394925, -2211764618217775957);
}
fn RevealTimeCoordinate76(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 76, 606134984055, 1, -2211764618217775956, -2010695107861156987);
}
fn RevealTimeCoordinate77(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 77, 639114493396, 1, -2010695107861156986, -1809625597504538018);
}
fn RevealTimeCoordinate78(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 78, 673421841245, 1, -1809625597504538017, -1608556087147919049);
}
fn RevealTimeCoordinate79(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 79, 709092199595, 1, -1608556087147919048, -1407486576791300080);
}
fn RevealTimeCoordinate80(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 80, 746161200202, 1, -1407486576791300079, -1206417066434681111);
}
fn RevealTimeCoordinate81(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 81, 784664934588, 1, -1206417066434681110, -1005347556078062142);
}
fn RevealTimeCoordinate82(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 82, 824639954040, 1, -1005347556078062141, -804278045721443173);
}
fn RevealTimeCoordinate83(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 83, 866123269609, 1, -804278045721443172, -603208535364824204);
}
fn RevealTimeCoordinate84(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 84, 909152352111, 1, -603208535364824203, -402139025008205235);
}
fn RevealTimeCoordinate85(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 85, 953765132126, 1, -402139025008205234, -201069514651586266);
}
fn RevealTimeCoordinate86(action) {
  var c = action.mutate("MicroverseTimeCoordinate");
  reveal_t(action, c, 86, 999999999999, 1, -201069514651586265, -4294967296);
}
fn WarpToCoordinateReusable(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var coordinate = action.mutate("MicroverseWarpCoordinate");
  prove_fixed_versions(action, coordinate);
  action.st_sum(coordinate.revealed, 0, 1);
  action.st_gt(coordinate.uses_remaining, 1);
  var next_uses = unsafe { coordinate.uses_remaining - 1 };
  action.st_sum(next_uses, 1, coordinate.uses_remaining);
  action.st_gt(coordinate.destination_x, 0);
  action.st_gt(2000000000000, coordinate.destination_x);
  action.st_gt(coordinate.destination_y, 0);
  action.st_gt(2000000000000, coordinate.destination_y);
  action.st_gt(coordinate.destination_z, 0);
  action.st_gt(2000000000000, coordinate.destination_z);
  warp_ship_core(action, next_ship, ship, coordinate.destination_x, coordinate.destination_y, coordinate.destination_z, ship.epoch);
  coordinate.update("uses_remaining", next_uses);
  var next_coordinate_key = action.random();
  rotate_key(coordinate, next_coordinate_key);
}
fn WarpToCoordinateFinal(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var coordinate = action.input("MicroverseWarpCoordinate");
  prove_fixed_versions(action, coordinate);
  action.st_sum(coordinate.revealed, 0, 1);
  action.st_sum(coordinate.uses_remaining, 0, 1);
  action.st_gt(coordinate.destination_x, 0);
  action.st_gt(2000000000000, coordinate.destination_x);
  action.st_gt(coordinate.destination_y, 0);
  action.st_gt(2000000000000, coordinate.destination_y);
  action.st_gt(coordinate.destination_z, 0);
  action.st_gt(2000000000000, coordinate.destination_z);
  warp_ship_core(action, next_ship, ship, coordinate.destination_x, coordinate.destination_y, coordinate.destination_z, ship.epoch);

}
fn TimeWarpToCoordinateReusable(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var coordinate = action.mutate("MicroverseTimeCoordinate");
  prove_fixed_versions(action, coordinate);
  action.st_sum(coordinate.revealed, 0, 1);
  action.st_gt(coordinate.uses_remaining, 1);
  var next_uses = unsafe { coordinate.uses_remaining - 1 };
  action.st_sum(next_uses, 1, coordinate.uses_remaining);
  action.st_gt(coordinate.destination_epoch, -1);
  action.st_gt(1000000000000, coordinate.destination_epoch);
  warp_ship_core(action, next_ship, ship, ship.x, ship.y, ship.z, coordinate.destination_epoch);
  coordinate.update("uses_remaining", next_uses);
  var next_coordinate_key = action.random();
  rotate_key(coordinate, next_coordinate_key);
}
fn TimeWarpToCoordinateFinal(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var coordinate = action.input("MicroverseTimeCoordinate");
  prove_fixed_versions(action, coordinate);
  action.st_sum(coordinate.revealed, 0, 1);
  action.st_sum(coordinate.uses_remaining, 0, 1);
  action.st_gt(coordinate.destination_epoch, -1);
  action.st_gt(1000000000000, coordinate.destination_epoch);
  warp_ship_core(action, next_ship, ship, ship.x, ship.y, ship.z, coordinate.destination_epoch);

}
fn ExtractMatter(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"matter_remaining",
1,
10,
1
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractMatterMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"matter_remaining",
1,
50,
5
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractMatterLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"matter_remaining",
1,
250,
25
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractCrystal(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"crystal_remaining",
2,
10,
1
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractCrystalMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"crystal_remaining",
2,
50,
5
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractCrystalLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"crystal_remaining",
2,
250,
25
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGas(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"gas_remaining",
3,
10,
1
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"gas_remaining",
3,
50,
5
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"gas_remaining",
3,
250,
25
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractEnergy(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
4,
10,
1
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractEnergyMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
4,
50,
5
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractEnergyLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
4,
250,
25
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn DiscoverSatellite(action) {
  var next_ship = action.output("MicroverseShip");
  var satellite = action.output("MicroverseSatellite");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, body);
  action.st_sum(body.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(body.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(body.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(body.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(body.sector_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_ship_satellite_serial = unsafe { ship.satellite_serial - (0 - 1) };
  action.st_sum(ship.satellite_serial, 1, next_ship_satellite_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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
    ["satellite_serial", next_ship_satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_gt(body.satellites_remaining, 0);
  var next_remaining = unsafe { body.satellites_remaining - 1 };
  action.st_sum(next_remaining, 1, body.satellites_remaining);
  var next_satellite_serial = unsafe { body.next_satellite_serial - (0 - 1) };
  action.st_sum(body.next_satellite_serial, 1, next_satellite_serial);
  var parent_body_identifier = action.random();
  var_assign(parent_body_identifier, body.stable_identifier);
  body.update("stable_identifier", parent_body_identifier);
  satellite.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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
}
fn DetectIntelligentLife(action) {
  var next_ship = action.output("MicroverseShip");
  var life_signal = action.output("MicroverseLifeSignal");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, body);
  action.st_sum(body.body_bank_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(body.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(body.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(body.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(body.sector_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  var next_scan_serial = unsafe { ship.civilization_scan_serial - (0 - 1) };
  action.st_sum(ship.civilization_scan_serial, 1, next_scan_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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
    ["civilization_scan_serial", next_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(body.body_type, 0, 1);
  action.st_gt(body.life_stat, 0);
  action.st_sum(body.civilization_discovered, 0, 0);
  var source_body_identifier = action.random();
  var_assign(source_body_identifier, body.stable_identifier);
  body.update("stable_identifier", source_body_identifier);
  life_signal.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["source_body_identifier", source_body_identifier],
    ["sector_x", x],
    ["sector_y", y],
    ["sector_z", z],
    ["origin_epoch", epoch]
  ]);
  let zero = action.top_limb_u256(0);
  life_signal.update("key", zero);
  body.update("civilization_discovered", 1);
  var next_body_key = action.random();
  rotate_key(body, next_body_key);
}
fn MaterializeCivilizationTypeI(action) {
  var civilization = action.output("MicroverseCivilization");
  var life_signal = action.input("MicroverseLifeSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, life_signal);
  prove_fixed_versions(action, ship);
  action.st_sum(life_signal.civilization_version, 0, 1);

  var sector_x = unsafe { life_signal.sector_x - 0 };
  var sector_y = unsafe { life_signal.sector_y - 0 };
  var sector_z = unsafe { life_signal.sector_z - 0 };
  var origin_epoch = unsafe { life_signal.origin_epoch - 0 };
  action.st_sum(life_signal.sector_x, 0, sector_x);
  action.st_sum(life_signal.sector_y, 0, sector_y);
  action.st_sum(life_signal.sector_z, 0, sector_z);
  action.st_sum(life_signal.origin_epoch, 0, origin_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, origin_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  var civilization_selector = action.random();
  var_assign(civilization_selector, life_signal.stable_identifier);
  let type_lower = action.top_limb_u256(18014398509481985);
  let type_upper = action.top_limb_u256(288230376151711744);
  action.intro_lt_eq_u256(type_lower, civilization_selector);
  action.intro_lt_eq_u256(civilization_selector, type_upper);
  civilization.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["source_life_signal_identifier", civilization_selector],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["origin_epoch", origin_epoch],
    ["civilization_type", 1]
  ]);
  let zero = action.top_limb_u256(0);
  civilization.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn MaterializeCivilizationTypeII(action) {
  var civilization = action.output("MicroverseCivilization");
  var life_signal = action.input("MicroverseLifeSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, life_signal);
  prove_fixed_versions(action, ship);
  action.st_sum(life_signal.civilization_version, 0, 1);

  var sector_x = unsafe { life_signal.sector_x - 0 };
  var sector_y = unsafe { life_signal.sector_y - 0 };
  var sector_z = unsafe { life_signal.sector_z - 0 };
  var origin_epoch = unsafe { life_signal.origin_epoch - 0 };
  action.st_sum(life_signal.sector_x, 0, sector_x);
  action.st_sum(life_signal.sector_y, 0, sector_y);
  action.st_sum(life_signal.sector_z, 0, sector_z);
  action.st_sum(life_signal.origin_epoch, 0, origin_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, origin_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  var civilization_selector = action.random();
  var_assign(civilization_selector, life_signal.stable_identifier);
  let type_lower = action.top_limb_u256(1125899906842625);
  let type_upper = action.top_limb_u256(18014398509481984);
  action.intro_lt_eq_u256(type_lower, civilization_selector);
  action.intro_lt_eq_u256(civilization_selector, type_upper);
  civilization.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["source_life_signal_identifier", civilization_selector],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["origin_epoch", origin_epoch],
    ["civilization_type", 2]
  ]);
  let zero = action.top_limb_u256(0);
  civilization.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn MaterializeCivilizationTypeIII(action) {
  var civilization = action.output("MicroverseCivilization");
  var life_signal = action.input("MicroverseLifeSignal");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, life_signal);
  prove_fixed_versions(action, ship);
  action.st_sum(life_signal.civilization_version, 0, 1);

  var sector_x = unsafe { life_signal.sector_x - 0 };
  var sector_y = unsafe { life_signal.sector_y - 0 };
  var sector_z = unsafe { life_signal.sector_z - 0 };
  var origin_epoch = unsafe { life_signal.origin_epoch - 0 };
  action.st_sum(life_signal.sector_x, 0, sector_x);
  action.st_sum(life_signal.sector_y, 0, sector_y);
  action.st_sum(life_signal.sector_z, 0, sector_z);
  action.st_sum(life_signal.origin_epoch, 0, origin_epoch);
  action.st_sum(ship.x, 0, sector_x);
  action.st_sum(ship.y, 0, sector_y);
  action.st_sum(ship.z, 0, sector_z);
  action.st_sum(ship.epoch, 0, origin_epoch);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  var civilization_selector = action.random();
  var_assign(civilization_selector, life_signal.stable_identifier);
  let type_lower = action.top_limb_u256(0);
  let type_upper = action.top_limb_u256(1125899906842624);
  action.intro_lt_eq_u256(type_lower, civilization_selector);
  action.intro_lt_eq_u256(civilization_selector, type_upper);
  civilization.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["source_life_signal_identifier", civilization_selector],
    ["sector_x", sector_x],
    ["sector_y", sector_y],
    ["sector_z", sector_z],
    ["origin_epoch", origin_epoch],
    ["civilization_type", 3]
  ]);
  let zero = action.top_limb_u256(0);
  civilization.update("key", zero);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn ExtractRedDwarfFusionGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfFusionGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfMetalRichOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
120,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfMetalRichOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
120,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfRadiantEnergy(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
121,
50,
5
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfRadiantEnergyLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
121,
250,
25
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfRedDwarfPlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
223,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfRedDwarfPlasmaLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
223,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfMagneticStellarCondensate(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,7);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
224,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfMagneticStellarCondensateLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,7);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
224,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfFlareSpectrumData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
225,
50,
5
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfFlareSpectrumDataLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
225,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfStellarRefractoryDust(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,7);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
336,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRedDwarfStellarRefractoryDustLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 0);
  action.st_sum(ship.active_skill_type,0,7);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
336,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarFusionGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarFusionGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarMetalRichOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
120,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarMetalRichOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
120,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarRadiantEnergy(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
121,
50,
5
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarRadiantEnergyLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
121,
250,
25
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarPhotosphericPlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
226,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarPhotosphericPlasmaLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
226,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarPhotosphericMineral(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
227,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarPhotosphericMineralLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
227,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarStellarSpectrumData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
228,
50,
5
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarStellarSpectrumDataLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
228,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarSolarWindCondensate(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,4);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
337,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractMainSequenceStarSolarWindCondensateLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 1);
  action.st_sum(ship.active_skill_type,0,4);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
337,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarFusionGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarFusionGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,8);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarMetalRichOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
120,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarMetalRichOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
120,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarRadiantEnergy(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
121,
50,
5
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGiantStarRadiantEnergyLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
121,
250,
25
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGiantStarHeliumCarbonEjecta(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
229,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarHeliumCarbonEjectaLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
229,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarHeavyElementCondensate(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
230,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarHeavyElementCondensateLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
230,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarNeutrinoData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
231,
50,
5
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarNeutrinoDataLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
231,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarSProcessEjecta(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
338,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGiantStarSProcessEjectaLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 2);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
338,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetFerrousOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
122,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetFerrousOreMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
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
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetFerrousOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
122,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetBaseMetalOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
123,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetBaseMetalOreMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
123,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetBaseMetalOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
123,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetSilicateMineral(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
124,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetSilicateMineralMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
124,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetSilicateMineralLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
124,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetIndustrialMineral(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
125,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetIndustrialMineralMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
125,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetIndustrialMineralLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
125,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetIgneousRock(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
232,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetIgneousRockMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
232,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetIgneousRockLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
232,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetGeothermalEnergy(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
233,
10,
1
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetGeothermalEnergyMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
233,
50,
5
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetGeothermalEnergyLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
233,
250,
25
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetSedimentaryRock(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
339,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetSedimentaryRockMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
339,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractRockyPlanetSedimentaryRockLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 3);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
339,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetWater(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"matter_remaining",
126,
10,
1
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetWaterMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"matter_remaining",
126,
50,
5
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetWaterLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"matter_remaining",
126,
250,
25
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetSeawaterMinerals(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
127,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetSeawaterMineralsMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
127,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetSeawaterMineralsLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
127,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetAtmosphericGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
128,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetAtmosphericGasMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
128,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetAtmosphericGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
128,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetSeafloorSulfideOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
234,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetSeafloorSulfideOreMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
234,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetSeafloorSulfideOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
234,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetMarineBiomass(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
235,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetMarineBiomassMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
235,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetMarineBiomassLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
235,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetTidalEnergy(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
236,
10,
1
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetTidalEnergyMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
236,
50,
5
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetTidalEnergyLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
236,
250,
25
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetDissolvedTraceMinerals(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
340,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetDissolvedTraceMineralsMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
340,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractOceanPlanetDissolvedTraceMineralsLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 4);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
340,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetBiomass(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
129,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetBiomassMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
129,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetBiomassLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
129,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetGeneticMaterial(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
130,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetGeneticMaterialMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
130,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetGeneticMaterialLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
130,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetBiochemicalMixture(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
131,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetBiochemicalMixtureMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
131,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetBiochemicalMixtureLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
131,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetMicrobialCulture(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
132,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetMicrobialCultureMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
132,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetMicrobialCultureLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
132,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetNaturalMaterial(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
133,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetNaturalMaterialMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
133,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetNaturalMaterialLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
133,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetLivingSoil(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,17);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
237,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetLivingSoilMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,17);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
237,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetLivingSoilLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,17);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
237,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetPlantExtract(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
341,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetPlantExtractMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
341,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGardenPlanetPlantExtractLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 5);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
341,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGasGiantFusionGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGasGiantFusionGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGasGiantAtmosphericGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
128,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasGiantAtmosphericGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
128,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasGiantNobleGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
134,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasGiantNobleGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
134,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasGiantDeepAtmosphereGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,3);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
238,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasGiantDeepAtmosphereGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,3);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
238,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasGiantHydrocarbonCloud(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
239,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGasGiantHydrocarbonCloudLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
239,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGasGiantStormFieldData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,11);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
240,
50,
5
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGasGiantStormFieldDataLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,11);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
240,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGasGiantSulfurCloud(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,3);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
342,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGasGiantSulfurCloudLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 6);
  action.st_sum(ship.active_skill_type,0,3);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
342,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractIceGiantFusionGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractIceGiantFusionGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractIceGiantVolatileIce(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
135,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractIceGiantVolatileIceLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
135,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractIceGiantNobleGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
134,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractIceGiantNobleGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
134,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractIceGiantCryogenicVolatile(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,3);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
241,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractIceGiantCryogenicVolatileLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,3);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
241,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractIceGiantIceMantleMaterial(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,7);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
242,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractIceGiantIceMantleMaterialLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,7);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
242,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractIceGiantHighPressurePhaseData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,7);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
243,
50,
5
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractIceGiantHighPressurePhaseDataLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,7);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
243,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractIceGiantCryosphereSpectrumData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,7);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
343,
50,
5
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractIceGiantCryosphereSpectrumDataLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 7);
  action.st_sum(ship.active_skill_type,0,7);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
343,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetLightMetalOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
136,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetLightMetalOreMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
136,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetLightMetalOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
136,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetPreciousMetalOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
137,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetPreciousMetalOreMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
137,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetPreciousMetalOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
137,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetNuclearOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
138,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetNuclearOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
138,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetCarbonaceousDeposit(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
139,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetCarbonaceousDepositMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
139,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetCarbonaceousDepositLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
139,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetFertilizerMineral(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
140,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetFertilizerMineralMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
140,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetFertilizerMineralLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
140,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetDenseMetalOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
141,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetDenseMetalOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
141,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetRareEarthOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
142,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetRareEarthOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
142,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetAlkaliMineralOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
344,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetAlkaliMineralOreMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
344,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractBarrenPlanetAlkaliMineralOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 8);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
344,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractNeutronStarMetalRichOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 9);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
120,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractNeutronStarHighEnergyRadiation(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 9);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
143,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractNeutronStarGravitationalData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 9);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
144,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractNeutronStarRProcessEjecta(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 9);
  action.st_sum(ship.active_skill_type,0,13);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
244,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractNeutronStarDegenerateCrustMaterial(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 9);
  action.st_sum(ship.active_skill_type,0,13);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
245,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractNeutronStarPulsarEmissionData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 9);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
246,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractNeutronStarMagnetosphericParticleFlux(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 9);
  action.st_sum(ship.active_skill_type,0,13);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
345,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractNeutronStarPulsarTimingData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 9);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
346,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractBlackHoleHighEnergyRadiation(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 10);
  action.st_sum(ship.active_skill_type,0,8);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
143,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractBlackHoleGravitationalData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 10);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
144,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractBlackHoleAccretionData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 10);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
145,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractBlackHoleAccretionDiskMatter(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 10);
  action.st_sum(ship.active_skill_type,0,13);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
247,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractBlackHoleRelativisticPlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 10);
  action.st_sum(ship.active_skill_type,0,13);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
248,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractBlackHoleLensingData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 10);
  action.st_sum(ship.active_skill_type,0,14);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
249,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractBlackHoleAccretionAerosol(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 10);
  action.st_sum(ship.active_skill_type,0,13);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
347,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractBlackHoleHawkingRadiationData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 10);
  action.st_sum(ship.active_skill_type,0,14);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
348,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractAnomalyTemporalData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 11);
  action.st_sum(ship.active_skill_type,0,14);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
146,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractAnomalyGravitationalData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 11);
  action.st_sum(ship.active_skill_type,0,14);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"matter_remaining",
144,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractAnomalyFieldData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 11);
  action.st_sum(ship.active_skill_type,0,14);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"crystal_remaining",
147,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractAnomalyPhaseShiftedMatter(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 11);
  action.st_sum(ship.active_skill_type,0,13);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
250,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractAnomalyMagneticObservation(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 11);
  action.st_sum(ship.active_skill_type,0,14);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"crystal_remaining",
251,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractAnomalyRadiationObservation(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 11);
  action.st_sum(ship.active_skill_type,0,14);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
252,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractAnomalyPolarizationData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 11);
  action.st_sum(ship.active_skill_type,0,14);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
349,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractAnomalyVacuumFluctuationData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 11);
  action.st_sum(ship.active_skill_type,0,14);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
350,
250,
25
  );
  var next_work = action.intro_vdf(20, body);
  body.update("work", next_work);
}
fn ExtractMegastructureStructuralSalvage(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,6);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
148,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureStructuralSalvageMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,6);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
148,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureStructuralSalvageLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,6);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
148,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureElectronicSalvage(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,2);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
149,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureElectronicSalvageLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,2);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
149,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureCeramicSalvage(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,1);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
150,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureCeramicSalvageLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,1);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
150,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureArchiveData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,18);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"crystal_remaining",
151,
250,
25
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructurePolymerSalvage(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,10);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
253,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructurePolymerSalvageMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,10);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
253,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructurePolymerSalvageLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,10);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
253,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureOpticalSalvage(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,15);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
254,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureOpticalSalvageMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,15);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
254,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureOpticalSalvageLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,15);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"crystal_remaining",
254,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureMechanicalSalvage(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,1);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
351,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureMechanicalSalvageMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,1);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
351,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractMegastructureMechanicalSalvageLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 12);
  action.st_sum(ship.active_skill_type,0,1);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
351,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(32, body);
  body.update("work", next_work);
}
fn ExtractGasClusterFusionGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGasClusterFusionGasMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGasClusterFusionGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
119,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGasClusterNobleGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
134,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasClusterNobleGasMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
134,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasClusterNobleGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
134,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasClusterOrganicOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
152,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGasClusterOrganicOreMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
152,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGasClusterOrganicOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
152,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGasClusterMolecularCloudGas(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
255,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasClusterMolecularCloudGasMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
255,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasClusterMolecularCloudGasLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"gas_remaining",
255,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(2, body);
  body.update("work", next_work);
}
fn ExtractGasClusterInterstellarDust(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
256,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGasClusterInterstellarDustMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
256,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGasClusterInterstellarDustLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,0);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
256,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractGasClusterMolecularSpectrumData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,11);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
257,
10,
1
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGasClusterMolecularSpectrumDataMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,11);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
257,
50,
5
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGasClusterMolecularSpectrumDataLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,11);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
257,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractGasClusterPrebioticMoleculeMixture(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,5);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
352,
10,
1,
6,
3
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGasClusterPrebioticMoleculeMixtureMedium(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,5);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
352,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractGasClusterPrebioticMoleculeMixtureLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 13);
  action.st_sum(ship.active_skill_type,0,5);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
352,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(4, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantMetalRichOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
120,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantMetalRichOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
120,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantNuclearOre(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
138,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantNuclearOreLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
138,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantCarbonaceousDeposit(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
139,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantCarbonaceousDepositLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
139,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(8, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantSupernovaEjecta(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
258,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantSupernovaEjectaLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"matter_remaining",
258,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantRadioisotopeDeposit(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,4);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
259,
50,
5,
30,
15
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantRadioisotopeDepositLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var composite_resource = action.output("MicroverseCompositeResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,4);
  extract_composite_resource_core(
action,
next_ship,
composite_resource,
ship,
body,
"energy_remaining",
259,
250,
25,
150,
75
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantShockwaveSpectrumData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
260,
50,
5
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantShockwaveSpectrumDataLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
260,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantDecaySpectrumData(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
353,
50,
5
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn ExtractStellarRemnantDecaySpectrumDataLarge(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var body = action.mutate("MicroverseCelestialBody");
  action.st_sum(body.candidate_code, 0, 14);
  action.st_sum(ship.active_skill_type,0,16);
  extract_direct_resource_core(
action,
next_ship,
resource,
ship,
body,
"energy_remaining",
353,
250,
25
  );
  var next_work = action.intro_vdf(12, body);
  body.update("work", next_work);
}
fn RefineFusionGasToHydrogen(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 119);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 153],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineFusionGasToHelium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 119);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 154],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineFusionGasToDeuterium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 119);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 155],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineMetalRichOreToIron(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 120);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 156],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineMetalRichOreToNickel(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 120);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 157],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineMetalRichOreToCobalt(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 120);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 158],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineFerrousOreToIron(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 122);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 156],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineFerrousOreToChromium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 122);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 159],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineFerrousOreToManganese(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 122);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 160],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineBaseMetalOreToCopper(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 123);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 161],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineBaseMetalOreToZinc(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 123);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 162],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineBaseMetalOreToTin(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 123);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 163],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineSilicateMineralToSilicon(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 124);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 164],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineSilicateMineralToMagnesium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 124);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 165],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineSilicateMineralToQuartz(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 124);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 166],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineIndustrialMineralToLimestone(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 125);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 167],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineIndustrialMineralToClay(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 125);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 168],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineIndustrialMineralToGypsum(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 125);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 169],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineSeawaterMineralsToSodiumChloride(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 127);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 170],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineSeawaterMineralsToMagnesium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 127);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 165],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineSeawaterMineralsToCalcium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 127);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 171],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineAtmosphericGasToNitrogen(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 128);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 172],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineAtmosphericGasToOxygen(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 128);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 173],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineAtmosphericGasToCarbonDioxide(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 128);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 174],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineBiomassToCellulose(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 129);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 175],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineBiomassToProtein(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 129);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 176],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineBiomassToLipid(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 129);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 177],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineGeneticMaterialToDNA(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 5);
  action.st_sum(parent.resource_type, 0, 130);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 178],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineGeneticMaterialToRNA(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 5);
  action.st_sum(parent.resource_type, 0, 130);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 179],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineGeneticMaterialToPlasmid(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 5);
  action.st_sum(parent.resource_type, 0, 130);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 180],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineBiochemicalMixtureToAminoAcid(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 5);
  action.st_sum(parent.resource_type, 0, 131);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 181],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineBiochemicalMixtureToEnzyme(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 5);
  action.st_sum(parent.resource_type, 0, 131);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 182],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineBiochemicalMixtureToAlkaloid(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 5);
  action.st_sum(parent.resource_type, 0, 131);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 183],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineMicrobialCultureToBacterialCulture(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 132);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 184],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineMicrobialCultureToFungalCulture(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 132);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 185],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineMicrobialCultureToArchaealCulture(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 132);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 186],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineNaturalMaterialToWoodFiber(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 133);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 187],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineNaturalMaterialToChitin(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 133);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 188],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineNaturalMaterialToNaturalRubber(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 133);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 189],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineNobleGasToArgon(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 134);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 190],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineNobleGasToNeon(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 134);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 191],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineNobleGasToXenon(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 134);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 192],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineVolatileIceToWaterIce(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 135);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 193],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineVolatileIceToMethaneIce(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 135);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 194],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineVolatileIceToAmmoniaIce(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 135);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 195],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineLightMetalOreToAluminum(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 136);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 196],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineLightMetalOreToTitanium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 136);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 197],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineLightMetalOreToLithium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 136);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 198],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefinePreciousMetalOreToSilver(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 137);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 199],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefinePreciousMetalOreToGold(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 137);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 200],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefinePreciousMetalOreToPlatinum(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 137);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 201],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineNuclearOreToUranium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 138);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 202],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineNuclearOreToThorium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 138);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 203],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineNuclearOreToRadium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 138);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 204],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineCarbonaceousDepositToCarbon(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 139);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 205],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineCarbonaceousDepositToGraphite(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 139);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 206],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineCarbonaceousDepositToDiamond(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 139);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 207],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineFertilizerMineralToPhosphate(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 140);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 208],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineFertilizerMineralToSulfur(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 140);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 209],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineFertilizerMineralToPotash(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 140);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 210],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineStructuralSalvageToSteel(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 148);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 211],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineStructuralSalvageToAluminum(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 148);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 196],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineStructuralSalvageToCarbonComposite(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 148);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 212],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineElectronicSalvageToCopper(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 2);
  action.st_sum(parent.resource_type, 0, 149);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 161],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineElectronicSalvageToSilicon(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 2);
  action.st_sum(parent.resource_type, 0, 149);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 164],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineElectronicSalvageToGold(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 2);
  action.st_sum(parent.resource_type, 0, 149);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 200],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineCeramicSalvageToCeramic(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 150);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 213],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineCeramicSalvageToGlass(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 150);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 214],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineCeramicSalvageToSiliconCarbide(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 150);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 215],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineOrganicOreToMethanol(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 152);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 216],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineOrganicOreToFormaldehyde(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 152);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 217],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineOrganicOreToBenzene(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 152);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 218],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineDenseMetalOreToLead(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 141);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 219],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineDenseMetalOreToNickel(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 141);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 157],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineDenseMetalOreToCobalt(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 141);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 158],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineRareEarthOreToCerium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 142);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 220],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineRareEarthOreToLanthanum(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 142);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 221],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineRareEarthOreToNeodymium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 142);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 222],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineRedDwarfPlasmaToIonizedHydrogen(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 8);
  action.st_sum(parent.resource_type, 0, 223);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 261],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineRedDwarfPlasmaToIonizedHelium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 8);
  action.st_sum(parent.resource_type, 0, 223);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 262],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineRedDwarfPlasmaToElectronPlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 8);
  action.st_sum(parent.resource_type, 0, 223);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 263],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineMagneticStellarCondensateToFerriteDust(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 7);
  action.st_sum(parent.resource_type, 0, 224);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 264],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineMagneticStellarCondensateToMagnetiteGrain(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 7);
  action.st_sum(parent.resource_type, 0, 224);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 265],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineMagneticStellarCondensateToCobaltFerrite(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 7);
  action.st_sum(parent.resource_type, 0, 224);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 266],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefinePhotosphericPlasmaToProtonPlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 8);
  action.st_sum(parent.resource_type, 0, 226);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 267],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefinePhotosphericPlasmaToAlphaParticlePlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 8);
  action.st_sum(parent.resource_type, 0, 226);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 268],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefinePhotosphericPlasmaToPhotosphericElectronPlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 8);
  action.st_sum(parent.resource_type, 0, 226);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 269],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefinePhotosphericMineralToCalciumIonDust(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 8);
  action.st_sum(parent.resource_type, 0, 227);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 270],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefinePhotosphericMineralToSodiumIonDust(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 8);
  action.st_sum(parent.resource_type, 0, 227);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 271],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefinePhotosphericMineralToMagnesiumIonDust(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 8);
  action.st_sum(parent.resource_type, 0, 227);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 272],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineHeliumCarbonEjectaToHelium3(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 229);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 273],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineHeliumCarbonEjectaToCarbon12(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 229);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 274],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineHeliumCarbonEjectaToOxygen16(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 229);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 275],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineHeavyElementCondensateToStrontium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 230);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 276],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineHeavyElementCondensateToBarium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 230);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 277],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineHeavyElementCondensateToEuropium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 230);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 278],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineIgneousRockToBasalt(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 6);
  action.st_sum(parent.resource_type, 0, 232);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 279],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineIgneousRockToGranite(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 6);
  action.st_sum(parent.resource_type, 0, 232);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 280],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineIgneousRockToObsidian(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 6);
  action.st_sum(parent.resource_type, 0, 232);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 281],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineSeafloorSulfideOreToPyrite(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 234);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 282],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineSeafloorSulfideOreToChalcopyrite(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 234);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 283],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineSeafloorSulfideOreToSphalerite(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 234);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 284],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineMarineBiomassToAlgalFiber(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 235);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 285],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineMarineBiomassToMarineProtein(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 235);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 286],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineMarineBiomassToAlgalOil(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 235);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 287],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineLivingSoilToHumus(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 17);
  action.st_sum(parent.resource_type, 0, 237);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 288],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineLivingSoilToMycorrhizalCulture(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 17);
  action.st_sum(parent.resource_type, 0, 237);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 289],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineLivingSoilToSoilMicrobiome(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 17);
  action.st_sum(parent.resource_type, 0, 237);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 290],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineDeepAtmosphereGasToAmmoniaVapor(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 238);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 291],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineDeepAtmosphereGasToMethaneVapor(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 238);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 292],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineDeepAtmosphereGasToHydrogenSulfide(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 238);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 293],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineHydrocarbonCloudToEthane(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 239);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 294],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineHydrocarbonCloudToPropane(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 239);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 295],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineHydrocarbonCloudToAcetylene(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 239);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 296],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineCryogenicVolatileToLiquidMethane(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 241);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 297],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineCryogenicVolatileToLiquidAmmonia(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 241);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 298],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineCryogenicVolatileToSuperionicWater(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 7);
  action.st_sum(parent.resource_type, 0, 241);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 299],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineIceMantleMaterialToHighPressureIce(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 7);
  action.st_sum(parent.resource_type, 0, 242);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 300],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineIceMantleMaterialToMethaneClathrate(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 7);
  action.st_sum(parent.resource_type, 0, 242);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 301],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineIceMantleMaterialToAmmoniaHydrate(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 7);
  action.st_sum(parent.resource_type, 0, 242);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 302],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineRProcessEjectaToOsmium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 244);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 303],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineRProcessEjectaToIridium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 244);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 304],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineRProcessEjectaToRhenium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 244);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 305],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineDegenerateCrustMaterialToNuclearPasta(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 245);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 306],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineDegenerateCrustMaterialToNeutronRichAlloy(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 245);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 307],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineDegenerateCrustMaterialToSuperdenseCarbon(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 245);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 308],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineAccretionDiskMatterToIonizedIron(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 247);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 309],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineAccretionDiskMatterToCarbonPlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 247);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 310],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineAccretionDiskMatterToSilicatePlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 247);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 311],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineRelativisticPlasmaToPairPlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 248);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 312],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineRelativisticPlasmaToSynchrotronPlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 248);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 313],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineRelativisticPlasmaToRelativisticIonBeam(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 248);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 314],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefinePhaseShiftedMatterToMetastableIsotope(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 250);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 315],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefinePhaseShiftedMatterToPhaseLockedCrystal(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 14);
  action.st_sum(parent.resource_type, 0, 250);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 316],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefinePhaseShiftedMatterToVacuumPolarizedMatter(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 14);
  action.st_sum(parent.resource_type, 0, 250);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 317],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefinePolymerSalvageToThermoplastic(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 10);
  action.st_sum(parent.resource_type, 0, 253);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 318],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefinePolymerSalvageToThermosetResin(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 10);
  action.st_sum(parent.resource_type, 0, 253);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 319],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefinePolymerSalvageToElastomer(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 10);
  action.st_sum(parent.resource_type, 0, 253);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 320],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineOpticalSalvageToOpticalGlass(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 15);
  action.st_sum(parent.resource_type, 0, 254);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 321],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineOpticalSalvageToPhotonicCrystal(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 15);
  action.st_sum(parent.resource_type, 0, 254);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 322],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineOpticalSalvageToLaserCrystal(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 15);
  action.st_sum(parent.resource_type, 0, 254);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 323],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineMolecularCloudGasToMolecularHydrogen(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 255);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 324],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineMolecularCloudGasToCarbonMonoxide(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 255);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 325],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineMolecularCloudGasToHydrogenCyanide(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 255);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 326],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(2, parent);
  parent.update("work", next_work);
}
fn RefineInterstellarDustToSilicateDust(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 256);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 327],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineInterstellarDustToCarbonDust(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 256);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 328],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineInterstellarDustToIceGrain(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 256);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 329],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineSupernovaEjectaToCalcium44(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 258);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 330],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineSupernovaEjectaToTitanium44(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 258);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 331],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineSupernovaEjectaToNickel56(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 258);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 332],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineRadioisotopeDepositToCobalt60(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 259);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 333],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineRadioisotopeDepositToCesium137(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 259);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 334],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineRadioisotopeDepositToStrontium90(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 259);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 335],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineStellarRefractoryDustToCorundum(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 7);
  action.st_sum(parent.resource_type, 0, 336);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 354],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineStellarRefractoryDustToSpinel(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 7);
  action.st_sum(parent.resource_type, 0, 336);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 355],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineStellarRefractoryDustToPerovskite(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 7);
  action.st_sum(parent.resource_type, 0, 336);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 356],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineSolarWindCondensateToLithium7(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 337);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 357],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineSolarWindCondensateToBeryllium9(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 337);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 358],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineSolarWindCondensateToBoron11(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 4);
  action.st_sum(parent.resource_type, 0, 337);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 359],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineSProcessEjectaToYttrium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 338);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 360],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineSProcessEjectaToZirconium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 338);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 361],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineSProcessEjectaToMolybdenum(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 16);
  action.st_sum(parent.resource_type, 0, 338);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 362],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(12, parent);
  parent.update("work", next_work);
}
fn RefineSedimentaryRockToSandstone(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 339);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 363],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineSedimentaryRockToShale(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 339);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 364],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineSedimentaryRockToDolomite(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 339);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 365],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineDissolvedTraceMineralsToBromine(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 340);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 366],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineDissolvedTraceMineralsToIodine(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 340);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 367],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineDissolvedTraceMineralsToBoron(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 340);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 368],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefinePlantExtractToStarch(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 341);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 369],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefinePlantExtractToSucrose(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 341);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 370],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefinePlantExtractToLignin(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 12);
  action.st_sum(parent.resource_type, 0, 341);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 371],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineSulfurCloudToSulfurDioxide(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 342);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 372],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineSulfurCloudToAmmoniumHydrosulfide(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 342);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 373],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineSulfurCloudToPolysulfurAerosol(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 342);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 374],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefineAlkaliMineralOreToSodium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 344);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 375],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineAlkaliMineralOreToPotassium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 344);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 376],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineAlkaliMineralOreToRubidium(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 3);
  action.st_sum(parent.resource_type, 0, 344);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 377],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(8, parent);
  parent.update("work", next_work);
}
fn RefineMagnetosphericParticleFluxToPositronPlasma(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 345);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 378],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineMagnetosphericParticleFluxToMuonFlux(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 345);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 379],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineMagnetosphericParticleFluxToHeavyIonFlux(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 345);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 380],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineAccretionAerosolToIronOxideAerosol(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 347);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 381],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineAccretionAerosolToSilicateAerosol(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 347);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 382],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineAccretionAerosolToCarbonaceousAerosol(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 13);
  action.st_sum(parent.resource_type, 0, 347);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 383],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(20, parent);
  parent.update("work", next_work);
}
fn RefineMechanicalSalvageToBearingSteel(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 351);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 384],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineMechanicalSalvageToToolSteel(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 351);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 385],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefineMechanicalSalvageToIndustrialLubricant(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(parent.resource_type, 0, 351);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 386],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(32, parent);
  parent.update("work", next_work);
}
fn RefinePrebioticMoleculeMixtureToGlycine(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 5);
  action.st_sum(parent.resource_type, 0, 352);
  action.st_gt(parent.child_1_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_1_remaining - 0
  };
  action.st_sum(
    parent.child_1_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 387],
    ["amount", refinement_amount]
  ]);
  parent.update("child_1_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefinePrebioticMoleculeMixtureToFormamide(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 5);
  action.st_sum(parent.resource_type, 0, 352);
  action.st_gt(parent.child_2_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_2_remaining - 0
  };
  action.st_sum(
    parent.child_2_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 388],
    ["amount", refinement_amount]
  ]);
  parent.update("child_2_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn RefinePrebioticMoleculeMixtureToAcetonitrile(action) {
  var next_ship = action.output("MicroverseShip");
  var resource = action.output("MicroverseResource");
  var ship = action.input("MicroverseShip");
  var parent = action.mutate("MicroverseCompositeResource");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, parent);
  action.st_sum(parent.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(parent.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(parent.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(parent.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(parent.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(ship.active_skill_type, 0, 5);
  action.st_sum(parent.resource_type, 0, 352);
  action.st_gt(parent.child_3_remaining, 0);
  var refinement_amount = unsafe {
    parent.child_3_remaining - 0
  };
  action.st_sum(
    parent.child_3_remaining,
    0,
    refinement_amount
  );
  resource.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["resource_type", 389],
    ["amount", refinement_amount]
  ]);
  parent.update("child_3_remaining", 0);
  var next_parent_key = action.random();
  rotate_key(parent, next_parent_key);
  var next_work = action.intro_vdf(4, parent);
  parent.update("work", next_work);
}
fn DevelopTypeIIndustrialFabricationSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    1
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 1],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIElectronicsSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    1
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 2],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIChemicalEngineeringSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    1
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 3],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeINuclearEngineeringSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    1
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 4],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIGeneticEngineeringSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    1
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 5],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIPlanetaryInfrastructureSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    1
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 6],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIMetamaterialEngineeringSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    2
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 7],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIStellarEnergySystemsSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    2
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 8],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIISyntheticIntelligenceSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    2
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 9],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIMolecularFabricationSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    2
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 10],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIInterstellarNavigationSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    2
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 11],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIBiosphereEngineeringSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    2
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 12],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIIExoticMatterEngineeringSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    3
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 13],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIISpacetimeEngineeringSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    3
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 14],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIIGalacticIntelligenceArchitectureSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    3
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 15],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIIStellarEngineeringSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    3
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 16],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIIWorldSeedingSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    3
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 17],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn DevelopTypeIIICivilizationEngineeringSkill(action) {
  var next_ship = action.output("MicroverseShip");
  var technology_skill = action.output("MicroverseTechnologySkill");
  var ship = action.input("MicroverseShip");
  var civilization = action.mutate("MicroverseCivilization");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, civilization);
  action.st_sum(civilization.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(civilization.sector_x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(civilization.sector_y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(civilization.sector_z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(civilization.origin_epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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

  action.st_sum(
    civilization.civilization_type,
    0,
    3
  );
  technology_skill.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["civilization_version", 1],
    ["skill_type", 18],
    ["reusable", 1]
  ]);
  var next_civilization_key = action.random();
  rotate_key(civilization, next_civilization_key);
}
fn UseTechnologySkill(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var technology_skill = action.mutate("MicroverseTechnologySkill");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, technology_skill);
  action.st_sum(technology_skill.civilization_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);

  var active_skill_type = unsafe { technology_skill.skill_type - 0 };
  action.st_sum(technology_skill.skill_type, 0, active_skill_type);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", extraction_amount],
    ["rare_extraction_amount", rare_extraction_amount],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["active_skill_type", active_skill_type],
    ["action_serial", next_action_serial],
    ["claim_serial", claim_serial],
    ["discovery_serial", discovery_serial],
    ["satellite_serial", satellite_serial],
    ["civilization_scan_serial", civilization_scan_serial],
    ["ship_id", ship_id]
  ]);

  action.st_sum(technology_skill.reusable, 0, 1);
  var next_skill_key = action.random();
  rotate_key(technology_skill, next_skill_key);
}
fn CreateLargeShipConstructionPermit(action) {
  var permit = action.output("MicroverseShipyardPermit");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, ship);
  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  permit.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["permit_type", 1],
    ["x", x],
    ["y", y],
    ["z", z],
    ["epoch", epoch],
    ["industrial_authorized", 0],
    ["electronics_authorized", 0],
    ["molecular_authorized", 0]
  ]);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn AuthorizeLargeShipIndustrial(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var permit = action.mutate("MicroverseShipyardPermit");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, permit);
  action.st_sum(permit.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(permit.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(permit.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(permit.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(permit.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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
  action.st_sum(ship.active_skill_type, 0, 1);
  action.st_sum(permit.permit_type, 0, 1);
  action.st_sum(permit.industrial_authorized, 0, 0);
  permit.update("industrial_authorized", 1);
  var next_permit_key = action.random();
  rotate_key(permit, next_permit_key);
}
fn AuthorizeLargeShipElectronics(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var permit = action.mutate("MicroverseShipyardPermit");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, permit);
  action.st_sum(permit.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(permit.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(permit.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(permit.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(permit.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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
  action.st_sum(ship.active_skill_type, 0, 2);
  action.st_sum(permit.permit_type, 0, 1);
  action.st_sum(permit.electronics_authorized, 0, 0);
  permit.update("electronics_authorized", 1);
  var next_permit_key = action.random();
  rotate_key(permit, next_permit_key);
}
fn AuthorizeLargeShipMolecular(action) {
  var next_ship = action.output("MicroverseShip");
  var ship = action.input("MicroverseShip");
  var permit = action.mutate("MicroverseShipyardPermit");
  prove_fixed_versions(action, ship);
  prove_fixed_versions(action, permit);
  action.st_sum(permit.schema_version, 0, 1);
  var ship_id = bind_ship_id(action, ship);

  var extraction_amount = unsafe { ship.extraction_amount - 0 };
  var rare_extraction_amount = unsafe { ship.rare_extraction_amount - 0 };
  action.st_sum(ship.extraction_amount, 0, extraction_amount);
  action.st_sum(ship.rare_extraction_amount, 0, rare_extraction_amount);

  var x = unsafe { ship.x - 0 };
  var y = unsafe { ship.y - 0 };
  var z = unsafe { ship.z - 0 };
  var epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, x);
  action.st_sum(permit.x, 0, x);
  action.st_sum(ship.y, 0, y);
  action.st_sum(permit.y, 0, y);
  action.st_sum(ship.z, 0, z);
  action.st_sum(permit.z, 0, z);
  action.st_sum(ship.epoch, 0, epoch);
  action.st_sum(permit.epoch, 0, epoch);

  var claim_serial = unsafe { ship.claim_serial - 0 };
  action.st_sum(ship.claim_serial, 0, claim_serial);
  var discovery_serial = unsafe { ship.discovery_serial - 0 };
  action.st_sum(ship.discovery_serial, 0, discovery_serial);
  var satellite_serial = unsafe { ship.satellite_serial - 0 };
  action.st_sum(ship.satellite_serial, 0, satellite_serial);
  var civilization_scan_serial = unsafe { ship.civilization_scan_serial - 0 };
  action.st_sum(ship.civilization_scan_serial, 0, civilization_scan_serial);

  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);

  next_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
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
  action.st_sum(ship.active_skill_type, 0, 10);
  action.st_sum(permit.permit_type, 0, 1);
  action.st_sum(permit.molecular_authorized, 0, 0);
  permit.update("molecular_authorized", 1);
  var next_permit_key = action.random();
  rotate_key(permit, next_permit_key);
}
fn IssueAuxiliaryShipPermit(action) {
  var permit = action.output("MicroverseShipyardPermit");
  var ship = action.mutate("MicroverseShip");
  prove_fixed_versions(action, ship);
  action.st_sum(ship.extraction_amount, 0, 250);
  action.st_sum(ship.rare_extraction_amount, 0, 25);
  var permit_x = unsafe { ship.x - 0 };
  var permit_y = unsafe { ship.y - 0 };
  var permit_z = unsafe { ship.z - 0 };
  var permit_epoch = unsafe { ship.epoch - 0 };
  action.st_sum(ship.x, 0, permit_x);
  action.st_sum(ship.y, 0, permit_y);
  action.st_sum(ship.z, 0, permit_z);
  action.st_sum(ship.epoch, 0, permit_epoch);
  permit.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["permit_type", 2],
    ["x", permit_x],
    ["y", permit_y],
    ["z", permit_z],
    ["epoch", permit_epoch],
    ["industrial_authorized", 0],
    ["electronics_authorized", 0],
    ["molecular_authorized", 0]
  ]);
  var next_action_serial = unsafe { ship.action_serial - (0 - 1) };
  action.st_sum(ship.action_serial, 1, next_action_serial);
  ship.update("active_skill_type", 0);
  ship.update("action_serial", next_action_serial);
  var next_ship_key = action.random();
  rotate_key(ship, next_ship_key);
}
fn BuildAuxiliaryShipSmall(action) {
  var permit = action.input("MicroverseShipyardPermit");
  var ingredient_1_matter = action.input("MicroverseResource");
  var ingredient_2_iron = action.input("MicroverseResource");
  var ingredient_3_aluminum = action.input("MicroverseResource");
  var ingredient_4_copper = action.input("MicroverseResource");
  var ingredient_5_silicon = action.input("MicroverseResource");
  prove_fixed_versions(action, permit);
  action.st_sum(permit.permit_type, 0, 2);
  action.st_sum(ingredient_1_matter.resource_type, 0, 1);
  action.st_sum(ingredient_1_matter.amount, 0, 10);
  action.st_sum(ingredient_2_iron.resource_type, 0, 156);
  action.st_sum(ingredient_2_iron.amount, 0, 6);
  action.st_sum(ingredient_3_aluminum.resource_type, 0, 196);
  action.st_sum(ingredient_3_aluminum.amount, 0, 6);
  action.st_sum(ingredient_4_copper.resource_type, 0, 161);
  action.st_sum(ingredient_4_copper.amount, 0, 6);
  action.st_sum(ingredient_5_silicon.resource_type, 0, 164);
  action.st_sum(ingredient_5_silicon.amount, 0, 6);
  var build_x = unsafe { permit.x - 0 };
  var build_y = unsafe { permit.y - 0 };
  var build_z = unsafe { permit.z - 0 };
  var build_epoch = unsafe { permit.epoch - 0 };
  action.st_sum(permit.x, 0, build_x);
  action.st_sum(permit.y, 0, build_y);
  action.st_sum(permit.z, 0, build_z);
  action.st_sum(permit.epoch, 0, build_epoch);
  var child_ship = action.output("MicroverseShip");
  var ship_id = action.random();
  child_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", 10],
    ["rare_extraction_amount", 1],
    ["x", build_x],
    ["y", build_y],
    ["z", build_z],
    ["epoch", build_epoch],
    ["active_skill_type", 0],
    ["action_serial", 0],
    ["claim_serial", 0],
    ["discovery_serial", 0],
    ["satellite_serial", 0],
    ["civilization_scan_serial", 0],
    ["ship_id", ship_id]
  ]);
  var work = action.intro_vdf(34, child_ship);
  child_ship.update("work", work);
}
fn BuildAuxiliaryShipMedium(action) {
  var permit = action.input("MicroverseShipyardPermit");
  var ingredient_1_matter = action.input("MicroverseResource");
  var ingredient_2_crystal = action.input("MicroverseResource");
  var ingredient_3_energy = action.input("MicroverseResource");
  var ingredient_4_iron = action.input("MicroverseResource");
  var ingredient_5_aluminum = action.input("MicroverseResource");
  var ingredient_6_copper = action.input("MicroverseResource");
  var ingredient_7_silicon = action.input("MicroverseResource");
  var ingredient_8_carbon = action.input("MicroverseResource");
  prove_fixed_versions(action, permit);
  action.st_sum(permit.permit_type, 0, 2);
  action.st_sum(ingredient_1_matter.resource_type, 0, 1);
  action.st_sum(ingredient_1_matter.amount, 0, 10);
  action.st_sum(ingredient_2_crystal.resource_type, 0, 2);
  action.st_sum(ingredient_2_crystal.amount, 0, 10);
  action.st_sum(ingredient_3_energy.resource_type, 0, 4);
  action.st_sum(ingredient_3_energy.amount, 0, 10);
  action.st_sum(ingredient_4_iron.resource_type, 0, 156);
  action.st_sum(ingredient_4_iron.amount, 0, 6);
  action.st_sum(ingredient_5_aluminum.resource_type, 0, 196);
  action.st_sum(ingredient_5_aluminum.amount, 0, 6);
  action.st_sum(ingredient_6_copper.resource_type, 0, 161);
  action.st_sum(ingredient_6_copper.amount, 0, 6);
  action.st_sum(ingredient_7_silicon.resource_type, 0, 164);
  action.st_sum(ingredient_7_silicon.amount, 0, 6);
  action.st_sum(ingredient_8_carbon.resource_type, 0, 205);
  action.st_sum(ingredient_8_carbon.amount, 0, 6);
  var build_x = unsafe { permit.x - 0 };
  var build_y = unsafe { permit.y - 0 };
  var build_z = unsafe { permit.z - 0 };
  var build_epoch = unsafe { permit.epoch - 0 };
  action.st_sum(permit.x, 0, build_x);
  action.st_sum(permit.y, 0, build_y);
  action.st_sum(permit.z, 0, build_z);
  action.st_sum(permit.epoch, 0, build_epoch);
  var child_ship = action.output("MicroverseShip");
  var ship_id = action.random();
  child_ship.set([
    ["schema_version", 1],
    ["mechanics_version", 1],
    ["universe_version", 1],
    ["extraction_amount", 50],
    ["rare_extraction_amount", 5],
    ["x", build_x],
    ["y", build_y],
    ["z", build_z],
    ["epoch", build_epoch],
    ["active_skill_type", 0],
    ["action_serial", 0],
    ["claim_serial", 0],
    ["discovery_serial", 0],
    ["satellite_serial", 0],
    ["civilization_scan_serial", 0],
    ["ship_id", ship_id]
  ]);
  var work = action.intro_vdf(102, child_ship);
  child_ship.update("work", work);
}
