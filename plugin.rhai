// Shared proof and state helpers
fn prove_fixed_versions(action,object){
action.st_sum(object.schema_version,0,2);
action.st_sum(object.mechanics_version,0,2);
action.st_sum(object.universe_version,0,2);
}
fn bind_ship_id(action,ship){
var bound_ship_id=action.random();
var_assign(bound_ship_id,ship.ship_id);
ship.update("ship_id",bound_ship_id);
bound_ship_id
}
fn warp_ship_core(
action,
ship,
destination_x,
destination_y,
destination_z,
destination_epoch
){
prove_fixed_versions(action,ship);
var x=unsafe{destination_x-0};
var y=unsafe{destination_y-0};
var z=unsafe{destination_z-0};
var epoch=unsafe{destination_epoch-0};
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(destination_x,0,x);
action.st_sum(destination_y,0,y);
action.st_sum(destination_z,0,z);
action.st_sum(destination_epoch,0,epoch);
action.st_sum(ship.action_serial,1,next_action_serial);
ship.update("x",x);
ship.update("y",y);
ship.update("z",z);
ship.update("epoch",epoch);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn rotate_key(object,next_key){
object.update("key",next_key);
}
fn reveal_p(
action,
coordinate,
destination_code,
destination_x,
destination_y,
destination_z,
uses,
minimum_source_pool_exclusive
){
prove_fixed_versions(action,coordinate);
action.st_sum(coordinate.revealed,0,0);
action.st_gt(
coordinate.source_pool_before,
minimum_source_pool_exclusive
);
coordinate.update("revealed",1);
coordinate.update("destination_code",destination_code);
coordinate.update("destination_x",destination_x);
coordinate.update("destination_y",destination_y);
coordinate.update("destination_z",destination_z);
coordinate.update("uses_remaining",uses);
var next_key=action.random();
rotate_key(coordinate,next_key);
}
fn reveal_t(
action,
coordinate,
destination_code,
destination_epoch,
uses,
minimum_source_pool_exclusive
){
prove_fixed_versions(action,coordinate);
action.st_sum(coordinate.revealed,0,0);
action.st_gt(
coordinate.source_pool_before,
minimum_source_pool_exclusive
);
coordinate.update("revealed",1);
coordinate.update("destination_code",destination_code);
coordinate.update("destination_epoch",destination_epoch);
coordinate.update("uses_remaining",uses);
var next_key=action.random();
rotate_key(coordinate,next_key);
}
fn extract_direct_resource_core(
action,
resource,
ship,
body,
remaining_field,
resource_type,
extraction_amount,
rare_extraction_amount
){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
action.st_sum(ship.x,0,body.sector_x);
action.st_sum(ship.y,0,body.sector_y);
action.st_sum(ship.z,0,body.sector_z);
action.st_sum(ship.epoch,0,body.sector_epoch);
var next_remaining=unsafe{
body[remaining_field]-extraction_amount
};
action.st_sum(
next_remaining,
extraction_amount,
body[remaining_field]
);
action.st_gt(next_remaining,-1);
resource.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["resource_type",resource_type],
["amount",extraction_amount]
]);
var next_action_serial=unsafe{
ship.action_serial-(0-1)
};
action.st_sum(ship.action_serial,1,next_action_serial);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
body.update(remaining_field,next_remaining);
var next_body_key=action.random();
rotate_key(body,next_body_key);
}
fn extract_composite_resource_core(
action,
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
){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
action.st_sum(ship.x,0,body.sector_x);
action.st_sum(ship.y,0,body.sector_y);
action.st_sum(ship.z,0,body.sector_z);
action.st_sum(ship.epoch,0,body.sector_epoch);
var next_remaining=unsafe{
body[remaining_field]-extraction_amount
};
action.st_sum(
next_remaining,
extraction_amount,
body[remaining_field]
);
action.st_gt(next_remaining,-1);
composite_resource.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["resource_type",resource_type],
["sector_x",ship.x],
["sector_y",ship.y],
["sector_z",ship.z],
["origin_epoch",ship.epoch],
["child_1_remaining",child_1_amount],
["child_2_remaining",child_2_amount],
["child_3_remaining",child_3_amount]
]);
var next_action_serial=unsafe{
ship.action_serial-(0-1)
};
action.st_sum(ship.action_serial,1,next_action_serial);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
body.update(remaining_field,next_remaining);
var next_body_key=action.random();
rotate_key(body,next_body_key);
}
fn refine_resource_core(
action,
resource,
ship,
parent,
skill_type,
parent_resource_type,
child_remaining_field,
output_resource_type
){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,parent);
action.st_sum(ship.x,0,parent.sector_x);
action.st_sum(ship.y,0,parent.sector_y);
action.st_sum(ship.z,0,parent.sector_z);
action.st_sum(ship.epoch,0,parent.origin_epoch);
action.st_sum(ship.active_skill_type,0,skill_type);
action.st_sum(parent.resource_type,0,parent_resource_type);
action.st_gt(parent[child_remaining_field],0);
resource.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["resource_type",output_resource_type],
["amount",parent[child_remaining_field]]
]);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
parent.update(child_remaining_field,0);
var next_parent_key=action.random();
rotate_key(parent,next_parent_key);
}
fn develop_technology_skill_core(
action,
technology_skill,
ship,
civilization,
civilization_type,
skill_type,
reusable
){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,civilization);
action.st_sum(civilization.civilization_version,0,2);
action.st_sum(ship.x,0,civilization.sector_x);
action.st_sum(ship.y,0,civilization.sector_y);
action.st_sum(ship.z,0,civilization.sector_z);
action.st_sum(ship.epoch,0,civilization.origin_epoch);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
action.st_sum(
civilization.civilization_type,
0,
civilization_type
);
technology_skill.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["civilization_version",2],
["skill_type",skill_type],
["reusable",reusable]
]);
var next_civilization_key=action.random();
rotate_key(civilization,next_civilization_key);
}
fn consume_prepared_ship_core(
action,
ship,
required_skill_type
){
prove_fixed_versions(action,ship);
var ship_id=bind_ship_id(action,ship);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
action.st_sum(ship.active_skill_type,0,required_skill_type);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
ship_id
}
fn consume_prepared_ship_mutation_core(action,ship,required_skill_type){
prove_fixed_versions(action,ship);
action.st_sum(ship.active_skill_type,0,required_skill_type);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn prove_resource_stack_core(action,resource,resource_type,amount){
prove_fixed_versions(action,resource);
action.st_sum(resource.resource_type,0,resource_type);
action.st_sum(resource.amount,0,amount);
}
fn prove_object_version_core(action,object,version_field){
prove_fixed_versions(action,object);
action.st_sum(object[version_field],0,2);
}
fn consume_reusable_use_core(action,object){
action.st_gt(object.uses_remaining,1);
var next_uses=unsafe{object.uses_remaining-1};
action.st_sum(next_uses,1,object.uses_remaining);
object.update("uses_remaining",next_uses);
var next_key=action.random();
rotate_key(object,next_key);
}
fn consume_final_use_core(action,object){
action.st_sum(object.uses_remaining,0,1);
}
fn extract_v2_chart_core(
action,
ship,
body,
skill_type
){
consume_prepared_ship_mutation_core(action,ship,skill_type);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
action.st_sum(ship.extraction_amount,0,250);
action.st_sum(ship.rare_extraction_amount,0,25);
action.st_sum(ship.x,0,body.sector_x);
action.st_sum(ship.y,0,body.sector_y);
action.st_sum(ship.z,0,body.sector_z);
action.st_sum(ship.epoch,0,body.sector_epoch);
action.st_sum(body.candidate_code,0,22);
action.st_sum(body.body_type,0,7);
var next_energy=unsafe{body.energy_remaining-9000};
action.st_sum(next_energy,9000,body.energy_remaining);
action.st_gt(next_energy,-1);
body.update("energy_remaining",next_energy);
var next_body_key=action.random();
rotate_key(body,next_body_key);
}
fn reveal_chart_p(
action,ship,chart,code,x,y,z,uses,
minimum_source_pool_exclusive
){
consume_prepared_ship_mutation_core(action,ship,50);
prove_object_version_core(action,chart,"catalog_version");
action.st_sum(chart.revealed,0,0);
action.st_gt(chart.source_pool_before,minimum_source_pool_exclusive);
chart.update("revealed",1);
chart.update("destination_code",code);
chart.update("destination_x",x);
chart.update("destination_y",y);
chart.update("destination_z",z);
chart.update("uses_remaining",uses);
var next_key=action.random();
rotate_key(chart,next_key);
var work=action.intro_vdf(20,chart);
chart.update("work",work);
}
fn reveal_chart_t(
action,ship,chart,code,epoch,uses,
minimum_source_pool_exclusive
){
consume_prepared_ship_mutation_core(action,ship,58);
prove_object_version_core(action,chart,"catalog_version");
action.st_sum(chart.revealed,0,0);
action.st_gt(chart.source_pool_before,minimum_source_pool_exclusive);
chart.update("revealed",1);
chart.update("destination_code",code);
chart.update("destination_epoch",epoch);
chart.update("uses_remaining",uses);
var next_key=action.random();
rotate_key(chart,next_key);
var work=action.intro_vdf(20,chart);
chart.update("work",work);
}
fn reveal_warp_coordinate_action(action,code,x,y,z,uses,minimum_source_pool_exclusive){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,code,x,y,z,uses,minimum_source_pool_exclusive);
}
fn reveal_time_coordinate_action(action,code,epoch,uses,minimum_source_pool_exclusive){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,code,epoch,uses,minimum_source_pool_exclusive);
}
fn reveal_warp_chart_action(action,code,x,y,z,uses,minimum_source_pool_exclusive){
var s=action.mutate("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,s,c,code,x,y,z,uses,minimum_source_pool_exclusive);
}
fn reveal_epoch_chart_action(action,code,epoch,uses,minimum_source_pool_exclusive){
var s=action.mutate("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,s,c,code,epoch,uses,minimum_source_pool_exclusive);
}
fn develop_derived_skill_core(
action,
technology_skill,
ship,
parent_skill_type,
output_skill_type
){
consume_prepared_ship_mutation_core(action,ship,parent_skill_type);
technology_skill.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["civilization_version",2],
["skill_type",output_skill_type],
["reusable",1]
]);
}
fn produce_capability_artifact_core(
action,
artifact,
ship,
required_skill_type,
output_resource_type,
output_amount
){
consume_prepared_ship_mutation_core(action,ship,required_skill_type);
artifact.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["resource_type",output_resource_type],
["amount",output_amount]
]);
}
fn authorize_large_ship_permit_core(
action,
ship,
permit,
skill_type,
authorization_field
){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,permit);
action.st_sum(ship.x,0,permit.x);
action.st_sum(ship.y,0,permit.y);
action.st_sum(ship.z,0,permit.z);
action.st_sum(ship.epoch,0,permit.epoch);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
action.st_sum(ship.active_skill_type,0,skill_type);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
action.st_sum(permit.permit_type,0,1);
action.st_sum(permit[authorization_field],0,0);
permit.update(authorization_field,1);
var next_permit_key=action.random();
rotate_key(permit,next_permit_key);
}
fn fabricate_component_core(
action,
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
){
prove_fixed_versions(action,material_1);
prove_fixed_versions(action,material_2);
prove_fixed_versions(action,material_3);
prove_fixed_versions(action,catalyst);
consume_prepared_ship_mutation_core(action,ship,skill_type);
action.st_sum(material_1.resource_type,0,material_1_type);
action.st_sum(material_1.amount,0,material_1_amount);
action.st_sum(material_2.resource_type,0,material_2_type);
action.st_sum(material_2.amount,0,material_2_amount);
action.st_sum(material_3.resource_type,0,material_3_type);
action.st_sum(material_3.amount,0,material_3_amount);
action.st_sum(catalyst.resource_type,0,catalyst_type);
component.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["resource_type",component_type],
["amount",component_amount]
]);
}
fn consume_component_catalyst_reusable_core(action,catalyst){
action.st_gt(catalyst.amount,1);
var next_catalyst_amount=unsafe{catalyst.amount-1};
action.st_sum(next_catalyst_amount,1,catalyst.amount);
catalyst.update("amount",next_catalyst_amount);
var next_catalyst_key=action.random();
rotate_key(catalyst,next_catalyst_key);
}
fn consume_component_catalyst_final_core(action,catalyst){
action.st_sum(catalyst.amount,0,1);
}
fn scan_celestial_body_ungated_action(action,category_code,candidate_code,body_type,life_stat,matter_remaining,crystal_remaining,gas_remaining,energy_remaining,satellites_remaining){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
scan_body_core(action,body,signal,ship,category_code,candidate_code,body_type,life_stat,matter_remaining,crystal_remaining,gas_remaining,energy_remaining,satellites_remaining);
}
fn scan_celestial_body_upper_action(action,upper_limb,category_code,candidate_code,body_type,life_stat,matter_remaining,crystal_remaining,gas_remaining,energy_remaining,satellites_remaining){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_upper=action.top_limb_u256(upper_limb);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,category_code,candidate_code,body_type,life_stat,matter_remaining,crystal_remaining,gas_remaining,energy_remaining,satellites_remaining);
}
fn scan_celestial_body_lower_action(action,lower_limb,category_code,candidate_code,body_type,life_stat,matter_remaining,crystal_remaining,gas_remaining,energy_remaining,satellites_remaining){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(lower_limb);
action.intro_lt_eq_u256(body_selector_lower,signal);
scan_body_core(action,body,signal,ship,category_code,candidate_code,body_type,life_stat,matter_remaining,crystal_remaining,gas_remaining,energy_remaining,satellites_remaining);
}
fn scan_celestial_body_range_action(action,lower_limb,upper_limb,category_code,candidate_code,body_type,life_stat,matter_remaining,crystal_remaining,gas_remaining,energy_remaining,satellites_remaining){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(lower_limb);
action.intro_lt_eq_u256(body_selector_lower,signal);
let body_selector_upper=action.top_limb_u256(upper_limb);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,category_code,candidate_code,body_type,life_stat,matter_remaining,crystal_remaining,gas_remaining,energy_remaining,satellites_remaining);
}
fn develop_initial_skill_upper_action(action,upper_limb,civilization_type,skill_type,reusable){
var ship=action.mutate("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var civilization=action.mutate("microverse__civilization");
let skill_selector_upper=action.top_limb_u256(upper_limb);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(action,technology_skill,ship,civilization,civilization_type,skill_type,reusable);
}
fn develop_initial_skill_lower_action(action,lower_limb,civilization_type,skill_type,reusable){
var ship=action.mutate("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(lower_limb);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
develop_technology_skill_core(action,technology_skill,ship,civilization,civilization_type,skill_type,reusable);
}
fn develop_initial_skill_range_action(action,lower_limb,upper_limb,civilization_type,skill_type,reusable){
var ship=action.mutate("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(lower_limb);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(upper_limb);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(action,technology_skill,ship,civilization,civilization_type,skill_type,reusable);
}
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
){
prove_fixed_versions(action,signal);
prove_fixed_versions(action,ship);
action.st_sum(signal.body_bank_version,0,2);
action.st_sum(signal.category_code,0,category_code);
action.st_sum(signal.candidate_code,0,-1);
action.st_gt(signal.slot_serial,-1);
var source_signal_identifier=action.random();
var_assign(source_signal_identifier,signal.stable_identifier);
signal.update("stable_identifier",source_signal_identifier);
var sector_x=unsafe{signal.sector_x-0};
var sector_y=unsafe{signal.sector_y-0};
var sector_z=unsafe{signal.sector_z-0};
var sector_epoch=unsafe{signal.sector_epoch-0};
action.st_sum(signal.sector_x,0,sector_x);
action.st_sum(signal.sector_y,0,sector_y);
action.st_sum(signal.sector_z,0,sector_z);
action.st_sum(signal.sector_epoch,0,sector_epoch);
action.st_sum(ship.x,0,sector_x);
action.st_sum(ship.y,0,sector_y);
action.st_sum(ship.z,0,sector_z);
action.st_sum(ship.epoch,0,sector_epoch);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
body.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["body_bank_version",2],
["source_signal_identifier",source_signal_identifier],
["sector_x",sector_x],
["sector_y",sector_y],
["sector_z",sector_z],
["sector_epoch",sector_epoch],
["candidate_code",candidate_code],
["body_type",body_type],
["life_stat",life_stat],
["matter_remaining",matter_remaining],
["crystal_remaining",crystal_remaining],
["gas_remaining",gas_remaining],
["energy_remaining",energy_remaining],
["satellites_remaining",satellites_remaining],
["next_satellite_serial",0],
["civilization_discovered",0]
]);
let zero=action.top_limb_u256(0);
body.update("key",zero);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn survey_replacement_ship_core(action,ship,sector){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,sector);
action.st_sum(sector.body_bank_version,0,2);
action.st_sum(ship.x,0,sector.x);
action.st_sum(ship.y,0,sector.y);
action.st_sum(ship.z,0,sector.z);
action.st_sum(ship.epoch,0,sector.epoch);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn finish_detect_replacement_ship_core(action,ship){
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
var next_discovery_serial=unsafe{ship.discovery_serial-(0-1)};
action.st_sum(ship.discovery_serial,1,next_discovery_serial);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
ship.update("discovery_serial",next_discovery_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn detect_signal_core(action,signal,ship,sector,category_code,candidate_code,remaining_field,serial_field){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,sector);
action.st_sum(sector.body_bank_version,0,2);
action.st_sum(ship.x,0,sector.x);
action.st_sum(ship.y,0,sector.y);
action.st_sum(ship.z,0,sector.z);
action.st_sum(ship.epoch,0,sector.epoch);
finish_detect_replacement_ship_core(action,ship);
action.st_sum(sector.sector_type,0,1);
action.st_gt(sector.survey_profile,0);
action.st_gt(sector[remaining_field],0);
var slot_serial=unsafe{sector[serial_field]-0};
action.st_sum(sector[serial_field],0,slot_serial);
var next_remaining=unsafe{sector[remaining_field]-1};action.st_sum(next_remaining,1,sector[remaining_field]);
var next_serial=unsafe{sector[serial_field]-(0-1)};action.st_sum(sector[serial_field],1,next_serial);
signal.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["body_bank_version",2],
["sector_x",ship.x],
["sector_y",ship.y],
["sector_z",ship.z],
["sector_epoch",ship.epoch],
["category_code",category_code],
["candidate_code",candidate_code],
["slot_serial",slot_serial]
]);
let zero=action.top_limb_u256(0);signal.update("key",zero);
var next_sector_revision=unsafe{sector.revision-(0-1)};
action.st_sum(sector.revision,1,next_sector_revision);
sector.update(remaining_field,next_remaining);
sector.update(serial_field,next_serial);
sector.update("revision",next_sector_revision);
var next_sector_key=action.random();rotate_key(sector,next_sector_key);
}
fn prove_empty_survey_sector_core(action,sector){
action.st_sum(sector.sector_type,0,0);
action.st_sum(sector.survey_profile,0,0);
action.st_sum(sector.planet_remaining,0,0);
action.st_sum(sector.star_remaining,0,0);
action.st_sum(sector.gas_giant_remaining,0,0);
action.st_sum(sector.ice_giant_remaining,0,0);
action.st_sum(sector.neutron_star_remaining,0,0);
action.st_sum(sector.black_hole_remaining,0,0);
action.st_sum(sector.anomaly_remaining,0,0);
action.st_sum(sector.megastructure_remaining,0,0);
action.st_sum(sector.gas_cluster_remaining,0,0);
action.st_sum(sector.stellar_remnant_remaining,0,0);
action.st_sum(sector.minor_body_field_remaining,0,0);
action.st_sum(sector.next_planet_serial,0,0);
action.st_sum(sector.next_star_serial,0,0);
action.st_sum(sector.next_gas_giant_serial,0,0);
action.st_sum(sector.next_ice_giant_serial,0,0);
action.st_sum(sector.next_neutron_star_serial,0,0);
action.st_sum(sector.next_black_hole_serial,0,0);
action.st_sum(sector.next_anomaly_serial,0,0);
action.st_sum(sector.next_megastructure_serial,0,0);
action.st_sum(sector.next_gas_cluster_serial,0,0);
action.st_sum(sector.next_stellar_remnant_serial,0,0);
action.st_sum(sector.next_minor_body_field_serial,0,0);
}
fn extract_base_action(action,vdf_iterations,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
var ship=action.mutate("microverse__ship");
var resource=action.output("microverse__resource");
var body=action.mutate("microverse__celestial_body");
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,body);
body.update("work",work);
}
fn extract_direct_ungated_action(action,vdf_iterations,candidate_code,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
var ship=action.mutate("microverse__ship");
var resource=action.output("microverse__resource");
var body=action.mutate("microverse__celestial_body");
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,body);
body.update("work",work);
}
fn extract_direct_upper_action(action,upper_limb,vdf_iterations,candidate_code,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
var ship=action.mutate("microverse__ship");
var resource=action.output("microverse__resource");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(upper_limb);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,body);
body.update("work",work);
}
fn extract_direct_lower_action(action,lower_limb,vdf_iterations,candidate_code,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
var ship=action.mutate("microverse__ship");
var resource=action.output("microverse__resource");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(lower_limb);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,body);
body.update("work",work);
}
fn extract_direct_range_action(action,lower_limb,upper_limb,vdf_iterations,candidate_code,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
var ship=action.mutate("microverse__ship");
var resource=action.output("microverse__resource");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(lower_limb);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(upper_limb);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,body);
body.update("work",work);
}
fn extract_composite_ungated_action(action,vdf_iterations,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount){
var ship=action.mutate("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var body=action.mutate("microverse__celestial_body");
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_composite_resource_core(action,composite_resource,ship,body,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount);
var work=action.intro_vdf(vdf_iterations,body);
body.update("work",work);
}
fn extract_composite_upper_action(action,upper_limb,vdf_iterations,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount){
var ship=action.mutate("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(upper_limb);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_composite_resource_core(action,composite_resource,ship,body,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount);
var work=action.intro_vdf(vdf_iterations,body);
body.update("work",work);
}
fn extract_composite_lower_action(action,lower_limb,vdf_iterations,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount){
var ship=action.mutate("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(lower_limb);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_composite_resource_core(action,composite_resource,ship,body,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount);
var work=action.intro_vdf(vdf_iterations,body);
body.update("work",work);
}
fn extract_composite_range_action(action,lower_limb,upper_limb,vdf_iterations,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount){
var ship=action.mutate("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(lower_limb);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(upper_limb);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_composite_resource_core(action,composite_resource,ship,body,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount);
var work=action.intro_vdf(vdf_iterations,body);
body.update("work",work);
}
fn refine_resource_action(action,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type,vdf_iterations){
var ship=action.mutate("microverse__ship");
var resource=action.output("microverse__resource");
var parent=action.mutate("microverse__composite_resource");
refine_resource_core(action,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type);
var work=action.intro_vdf(vdf_iterations,parent);
parent.update("work",work);
}
fn fabricate_component_reusable_action(action,vdf_iterations,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount){
var s=action.mutate("microverse__ship");
var c=action.output("microverse__resource");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_core(action,c,s,a,b,d,k,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount);
consume_component_catalyst_reusable_core(action,k);
var work=action.intro_vdf(vdf_iterations,c);
c.update("work",work);
}
fn fabricate_component_final_action(action,vdf_iterations,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount){
var s=action.mutate("microverse__ship");
var c=action.output("microverse__resource");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_core(action,c,s,a,b,d,k,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount);
consume_component_catalyst_final_core(action,k);
var work=action.intro_vdf(vdf_iterations,c);
c.update("work",work);
}
fn develop_derived_skill_2_evidence_action(action,vdf_iterations,parent_skill_type,output_skill_type,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount){
var ship=action.mutate("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_core(action,technology_skill,ship,parent_skill_type,output_skill_type);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
var work=action.intro_vdf(vdf_iterations,technology_skill);
technology_skill.update("work",work);
}
fn develop_derived_skill_3_evidence_action(action,vdf_iterations,parent_skill_type,output_skill_type,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount,evidence_3_type,evidence_3_amount){
var ship=action.mutate("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_core(action,technology_skill,ship,parent_skill_type,output_skill_type);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
prove_resource_stack_core(action,evidence_3,evidence_3_type,evidence_3_amount);
var work=action.intro_vdf(vdf_iterations,technology_skill);
technology_skill.update("work",work);
}
fn produce_capability_artifact_1_evidence_action(action,vdf_iterations,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount){
var ship=action.mutate("microverse__ship");
var artifact=action.output("microverse__resource");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_core(action,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
var work=action.intro_vdf(vdf_iterations,artifact);
artifact.update("work",work);
}
fn produce_capability_artifact_2_evidence_action(action,vdf_iterations,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount){
var ship=action.mutate("microverse__ship");
var artifact=action.output("microverse__resource");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
produce_capability_artifact_core(action,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
var work=action.intro_vdf(vdf_iterations,artifact);
artifact.update("work",work);
}
fn produce_capability_artifact_3_evidence_action(action,vdf_iterations,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount,evidence_3_type,evidence_3_amount){
var ship=action.mutate("microverse__ship");
var artifact=action.output("microverse__resource");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_core(action,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
prove_resource_stack_core(action,evidence_3,evidence_3_type,evidence_3_amount);
var work=action.intro_vdf(vdf_iterations,artifact);
artifact.update("work",work);
}
fn move_positive_core(action,ship,current_coordinate,coordinate_field,step,extraction_amount,rare_extraction_amount){
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var next_coordinate=unsafe{current_coordinate-(0-step)};
action.st_sum(current_coordinate,step,next_coordinate);
action.st_gt(next_coordinate,0);
action.st_gt(2000000000000,next_coordinate);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
ship.update(coordinate_field,next_coordinate);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn move_negative_core(action,ship,current_coordinate,coordinate_field,step,extraction_amount,rare_extraction_amount){
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var next_coordinate=unsafe{current_coordinate-step};
action.st_sum(next_coordinate,step,current_coordinate);
action.st_gt(next_coordinate,0);
action.st_gt(2000000000000,next_coordinate);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
ship.update(coordinate_field,next_coordinate);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn advance_ship_epoch_core(action,ship,next_epoch){
action.st_gt(1000000000000,next_epoch);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
ship.update("epoch",next_epoch);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn detect_celestial_signal_action(action,category_code,candidate_code,remaining_field,serial_field){
var ship=action.mutate("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,signal,ship,sector,category_code,candidate_code,remaining_field,serial_field);
}
fn move_positive_x_action(action,step,extraction_amount,rare_extraction_amount,vdf_iterations){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.x,"x",step,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,ship);
ship.update("work",work);
}
fn move_negative_x_action(action,step,extraction_amount,rare_extraction_amount,vdf_iterations){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.x,"x",step,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,ship);
ship.update("work",work);
}
fn move_positive_y_action(action,step,extraction_amount,rare_extraction_amount,vdf_iterations){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.y,"y",step,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,ship);
ship.update("work",work);
}
fn move_negative_y_action(action,step,extraction_amount,rare_extraction_amount,vdf_iterations){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.y,"y",step,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,ship);
ship.update("work",work);
}
fn move_positive_z_action(action,step,extraction_amount,rare_extraction_amount,vdf_iterations){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.z,"z",step,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,ship);
ship.update("work",work);
}
fn move_negative_z_action(action,step,extraction_amount,rare_extraction_amount,vdf_iterations){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.z,"z",step,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(vdf_iterations,ship);
ship.update("work",work);
}
fn time_warp_action(action,step,extraction_amount,rare_extraction_amount,vdf_iterations){
var ship=action.mutate("microverse__ship");
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var next_epoch=unsafe{ship.epoch-(0-step)};
action.st_sum(ship.epoch,step,next_epoch);
advance_ship_epoch_core(action,ship,next_epoch);
var work=action.intro_vdf(vdf_iterations,ship);
ship.update("work",work);
}
fn authorize_large_ship_action(action,skill_type,authorization_field){
var ship=action.mutate("microverse__ship");
var permit=action.mutate("microverse__shipyard_permit");
authorize_large_ship_permit_core(action,ship,permit,skill_type,authorization_field);
}
// Ships and navigation
fn BuildShipSmall(action){
var ship=action.output("microverse__ship");
var ship_id=action.random();
ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",10],
["rare_extraction_amount",1],
["x",1000000000000],
["y",1000000000000],
["z",1000000000000],
["epoch",0],
["active_skill_type",0],
["action_serial",0],
["discovery_serial",0],
["satellite_serial",0],
["civilization_scan_serial",0],
["ship_id",ship_id]
]);
var work=action.intro_vdf(17,ship);
ship.update("work",work);
}
fn BuildShipMedium(action){
var ship=action.output("microverse__ship");
var ingredient_1_matter=action.input("microverse__resource");
var ingredient_2_crystal=action.input("microverse__resource");
var ingredient_3_energy=action.input("microverse__resource");
var ingredient_4_iron=action.input("microverse__resource");
var ingredient_5_aluminum=action.input("microverse__resource");
var ingredient_6_copper=action.input("microverse__resource");
var ingredient_7_silicon=action.input("microverse__resource");
var ingredient_8_carbon=action.input("microverse__resource");
action.st_sum(ingredient_1_matter.resource_type,0,1);
action.st_sum(ingredient_1_matter.amount,0,10);
action.st_sum(ingredient_2_crystal.resource_type,0,2);
action.st_sum(ingredient_2_crystal.amount,0,10);
action.st_sum(ingredient_3_energy.resource_type,0,4);
action.st_sum(ingredient_3_energy.amount,0,10);
action.st_sum(ingredient_4_iron.resource_type,0,156);
action.st_sum(ingredient_4_iron.amount,0,6);
action.st_sum(ingredient_5_aluminum.resource_type,0,196);
action.st_sum(ingredient_5_aluminum.amount,0,6);
action.st_sum(ingredient_6_copper.resource_type,0,161);
action.st_sum(ingredient_6_copper.amount,0,6);
action.st_sum(ingredient_7_silicon.resource_type,0,164);
action.st_sum(ingredient_7_silicon.amount,0,6);
action.st_sum(ingredient_8_carbon.resource_type,0,205);
action.st_sum(ingredient_8_carbon.amount,0,6);
var ship_id=action.random();
ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",50],
["rare_extraction_amount",5],
["x",1000000000000],
["y",1000000000000],
["z",1000000000000],
["epoch",0],
["active_skill_type",0],
["action_serial",0],
["discovery_serial",0],
["satellite_serial",0],
["civilization_scan_serial",0],
["ship_id",ship_id]
]);
var work=action.intro_vdf(51,ship);
ship.update("work",work);
}
fn BuildShipLarge(action){
var ship=action.output("microverse__ship");
var permit=action.input("microverse__shipyard_permit");
var ingredient_1_matter=action.input("microverse__resource");
var ingredient_2_crystal=action.input("microverse__resource");
var ingredient_3_energy=action.input("microverse__resource");
var ingredient_4_steel=action.input("microverse__resource");
var ingredient_5_aluminum=action.input("microverse__resource");
var ingredient_6_titanium=action.input("microverse__resource");
var ingredient_7_copper=action.input("microverse__resource");
var ingredient_8_silicon=action.input("microverse__resource");
var ingredient_9_gold=action.input("microverse__resource");
var ingredient_10_carboncomposite=action.input("microverse__resource");
prove_fixed_versions(action,permit);
action.st_sum(permit.permit_type,0,1);
action.st_sum(permit.industrial_authorized,0,1);
action.st_sum(permit.electronics_authorized,0,1);
action.st_sum(permit.molecular_authorized,0,1);
var build_x=unsafe{permit.x-0};
var build_y=unsafe{permit.y-0};
var build_z=unsafe{permit.z-0};
var build_epoch=unsafe{permit.epoch-0};
action.st_sum(permit.x,0,build_x);
action.st_sum(permit.y,0,build_y);
action.st_sum(permit.z,0,build_z);
action.st_sum(permit.epoch,0,build_epoch);
action.st_sum(ingredient_1_matter.resource_type,0,1);
action.st_sum(ingredient_1_matter.amount,0,50);
action.st_sum(ingredient_2_crystal.resource_type,0,2);
action.st_sum(ingredient_2_crystal.amount,0,50);
action.st_sum(ingredient_3_energy.resource_type,0,4);
action.st_sum(ingredient_3_energy.amount,0,50);
action.st_sum(ingredient_4_steel.resource_type,0,211);
action.st_sum(ingredient_4_steel.amount,0,30);
action.st_sum(ingredient_5_aluminum.resource_type,0,196);
action.st_sum(ingredient_5_aluminum.amount,0,30);
action.st_sum(ingredient_6_titanium.resource_type,0,197);
action.st_sum(ingredient_6_titanium.amount,0,15);
action.st_sum(ingredient_7_copper.resource_type,0,161);
action.st_sum(ingredient_7_copper.amount,0,30);
action.st_sum(ingredient_8_silicon.resource_type,0,164);
action.st_sum(ingredient_8_silicon.amount,0,30);
action.st_sum(ingredient_9_gold.resource_type,0,200);
action.st_sum(ingredient_9_gold.amount,0,15);
action.st_sum(ingredient_10_carboncomposite.resource_type,0,212);
action.st_sum(ingredient_10_carboncomposite.amount,0,5);
var ship_id=action.random();
ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",250],
["rare_extraction_amount",25],
["x",build_x],
["y",build_y],
["z",build_z],
["epoch",build_epoch],
["active_skill_type",0],
["action_serial",0],
["discovery_serial",0],
["satellite_serial",0],
["civilization_scan_serial",0],
["ship_id",ship_id]
]);
var work=action.intro_vdf(510,ship);
ship.update("work",work);
}
fn MovePositiveX(action){move_positive_x_action(action,1,10,1,4);}
fn MovePositiveXMedium(action){move_positive_x_action(action,10,50,5,12);}
fn MovePositiveXLarge(action){move_positive_x_action(action,100,250,25,28);}
fn MoveNegativeX(action){move_negative_x_action(action,1,10,1,4);}
fn MoveNegativeXMedium(action){move_negative_x_action(action,10,50,5,12);}
fn MoveNegativeXLarge(action){move_negative_x_action(action,100,250,25,28);}
fn MovePositiveY(action){move_positive_y_action(action,1,10,1,4);}
fn MovePositiveYMedium(action){move_positive_y_action(action,10,50,5,12);}
fn MovePositiveYLarge(action){move_positive_y_action(action,100,250,25,28);}
fn MoveNegativeY(action){move_negative_y_action(action,1,10,1,4);}
fn MoveNegativeYMedium(action){move_negative_y_action(action,10,50,5,12);}
fn MoveNegativeYLarge(action){move_negative_y_action(action,100,250,25,28);}
fn MovePositiveZ(action){move_positive_z_action(action,1,10,1,4);}
fn MovePositiveZMedium(action){move_positive_z_action(action,10,50,5,12);}
fn MovePositiveZLarge(action){move_positive_z_action(action,100,250,25,28);}
fn MoveNegativeZ(action){move_negative_z_action(action,1,10,1,4);}
fn MoveNegativeZMedium(action){move_negative_z_action(action,10,50,5,12);}
fn MoveNegativeZLarge(action){move_negative_z_action(action,100,250,25,28);}
fn TimeWarpSmall(action){time_warp_action(action,1,10,1,4);}
fn TimeWarpMedium(action){time_warp_action(action,10,50,5,12);}
fn TimeWarpLarge(action){time_warp_action(action,100,250,25,28);}
// Sectors and survey profiles
fn ClaimSector(action){
var sector=action.output("microverse__sector");
var ship=action.mutate("microverse__ship");
prove_fixed_versions(action,ship);
var sector_x=unsafe{ship.x-0};
var sector_y=unsafe{ship.y-0};
var sector_z=unsafe{ship.z-0};
var sector_epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,sector_x);
action.st_sum(ship.y,0,sector_y);
action.st_sum(ship.z,0,sector_z);
action.st_sum(ship.epoch,0,sector_epoch);
sector.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["body_bank_version",2],
["x",sector_x],
["y",sector_y],
["z",sector_z],
["epoch",sector_epoch],
["sector_type",0],
["survey_profile",0],
["planet_remaining",0],
["star_remaining",0],
["gas_giant_remaining",0],
["ice_giant_remaining",0],
["neutron_star_remaining",0],
["black_hole_remaining",0],
["anomaly_remaining",0],
["megastructure_remaining",0],
["gas_cluster_remaining",0],
["stellar_remnant_remaining",0],
["minor_body_field_remaining",0],
["next_planet_serial",0],
["next_star_serial",0],
["next_gas_giant_serial",0],
["next_ice_giant_serial",0],
["next_neutron_star_serial",0],
["next_black_hole_serial",0],
["next_anomaly_serial",0],
["next_megastructure_serial",0],
["next_gas_cluster_serial",0],
["next_stellar_remnant_serial",0],
["next_minor_body_field_serial",0],
["revision",0]
]);
let zero=action.top_limb_u256(0);
sector.update("key",zero);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
ship.update("key",next_ship_key);
}
fn SurveySector_01_Sparse(action){
var ship=action.mutate("microverse__ship");
var sector=action.mutate("microverse__sector");
var sector_selector=action.random();
var_assign(sector_selector,sector.stable_identifier);
sector.update("stable_identifier",sector_selector);
let survey_selector_upper=action.top_limb_u256(7723496582334330630);
action.intro_lt_eq_u256(sector_selector,survey_selector_upper);
survey_replacement_ship_core(action,ship,sector);
prove_empty_survey_sector_core(action,sector);
var next_sector_revision=unsafe{sector.revision-(0-1)};
action.st_sum(sector.revision,1,next_sector_revision);
sector.update("sector_type",1);
sector.update("survey_profile",1);
sector.update("planet_remaining",1);
sector.update("star_remaining",1);
sector.update("minor_body_field_remaining",1);
sector.update("revision",next_sector_revision);
var next_sector_key=action.random();
rotate_key(sector,next_sector_key);
}
fn SurveySector_02_Standard(action){
var ship=action.mutate("microverse__ship");
var sector=action.mutate("microverse__sector");
var sector_selector=action.random();
var_assign(sector_selector,sector.stable_identifier);
sector.update("stable_identifier",sector_selector);
let survey_selector_lower=action.top_limb_u256(7723496582334330631);
action.intro_lt_eq_u256(survey_selector_lower,sector_selector);
let survey_selector_upper=action.top_limb_u256(-6861499200208055670);
action.intro_lt_eq_u256(sector_selector,survey_selector_upper);
survey_replacement_ship_core(action,ship,sector);
prove_empty_survey_sector_core(action,sector);
var next_sector_revision=unsafe{sector.revision-(0-1)};
action.st_sum(sector.revision,1,next_sector_revision);
sector.update("sector_type",1);
sector.update("survey_profile",2);
sector.update("planet_remaining",3);
sector.update("star_remaining",1);
sector.update("gas_giant_remaining",1);
sector.update("ice_giant_remaining",1);
sector.update("gas_cluster_remaining",2);
sector.update("stellar_remnant_remaining",1);
sector.update("minor_body_field_remaining",2);
sector.update("revision",next_sector_revision);
var next_sector_key=action.random();
rotate_key(sector,next_sector_key);
}
fn SurveySector_03_Rich(action){
var ship=action.mutate("microverse__ship");
var sector=action.mutate("microverse__sector");
var sector_selector=action.random();
var_assign(sector_selector,sector.stable_identifier);
sector.update("stable_identifier",sector_selector);
let survey_selector_lower=action.top_limb_u256(-6861499200208055669);
action.intro_lt_eq_u256(survey_selector_lower,sector_selector);
let survey_selector_upper=action.top_limb_u256(-5896062127416264341);
action.intro_lt_eq_u256(sector_selector,survey_selector_upper);
survey_replacement_ship_core(action,ship,sector);
prove_empty_survey_sector_core(action,sector);
var next_sector_revision=unsafe{sector.revision-(0-1)};
action.st_sum(sector.revision,1,next_sector_revision);
sector.update("sector_type",1);
sector.update("survey_profile",3);
sector.update("planet_remaining",6);
sector.update("star_remaining",2);
sector.update("gas_giant_remaining",2);
sector.update("ice_giant_remaining",2);
sector.update("neutron_star_remaining",1);
sector.update("megastructure_remaining",2);
sector.update("gas_cluster_remaining",4);
sector.update("stellar_remnant_remaining",2);
sector.update("minor_body_field_remaining",4);
sector.update("revision",next_sector_revision);
var next_sector_key=action.random();
rotate_key(sector,next_sector_key);
}
fn SurveySector_04_Ancient(action){
var ship=action.mutate("microverse__ship");
var sector=action.mutate("microverse__sector");
var sector_selector=action.random();
var_assign(sector_selector,sector.stable_identifier);
sector.update("stable_identifier",sector_selector);
let survey_selector_lower=action.top_limb_u256(-5896062127416264340);
action.intro_lt_eq_u256(survey_selector_lower,sector_selector);
let survey_selector_upper=action.top_limb_u256(-5654702859218316509);
action.intro_lt_eq_u256(sector_selector,survey_selector_upper);
survey_replacement_ship_core(action,ship,sector);
prove_empty_survey_sector_core(action,sector);
var next_sector_revision=unsafe{sector.revision-(0-1)};
action.st_sum(sector.revision,1,next_sector_revision);
sector.update("sector_type",1);
sector.update("survey_profile",4);
sector.update("planet_remaining",3);
sector.update("star_remaining",2);
sector.update("gas_giant_remaining",1);
sector.update("ice_giant_remaining",1);
sector.update("neutron_star_remaining",1);
sector.update("megastructure_remaining",9);
sector.update("gas_cluster_remaining",2);
sector.update("stellar_remnant_remaining",2);
sector.update("minor_body_field_remaining",2);
sector.update("revision",next_sector_revision);
var next_sector_key=action.random();
rotate_key(sector,next_sector_key);
}
fn SurveySector_05_Anomalous(action){
var ship=action.mutate("microverse__ship");
var sector=action.mutate("microverse__sector");
var sector_selector=action.random();
var_assign(sector_selector,sector.stable_identifier);
sector.update("stable_identifier",sector_selector);
let survey_selector_lower=action.top_limb_u256(-5654702859218316508);
action.intro_lt_eq_u256(survey_selector_lower,sector_selector);
let survey_selector_upper=action.top_limb_u256(-5534023225119342593);
action.intro_lt_eq_u256(sector_selector,survey_selector_upper);
survey_replacement_ship_core(action,ship,sector);
prove_empty_survey_sector_core(action,sector);
var next_sector_revision=unsafe{sector.revision-(0-1)};
action.st_sum(sector.revision,1,next_sector_revision);
sector.update("sector_type",1);
sector.update("survey_profile",5);
sector.update("planet_remaining",3);
sector.update("star_remaining",2);
sector.update("gas_giant_remaining",1);
sector.update("ice_giant_remaining",1);
sector.update("neutron_star_remaining",1);
sector.update("black_hole_remaining",1);
sector.update("anomaly_remaining",1);
sector.update("megastructure_remaining",9);
sector.update("gas_cluster_remaining",2);
sector.update("stellar_remnant_remaining",2);
sector.update("minor_body_field_remaining",2);
sector.update("revision",next_sector_revision);
var next_sector_key=action.random();
rotate_key(sector,next_sector_key);
}
// Signals and celestial bodies
fn DetectCelestialSignal_00_RedDwarf(action){detect_celestial_signal_action(action,2,-1,"star_remaining","next_star_serial");}
fn DetectCelestialSignal_01_MainSequenceStar(action){detect_celestial_signal_action(action,2,-1,"star_remaining","next_star_serial");}
fn DetectCelestialSignal_02_GiantStar(action){detect_celestial_signal_action(action,2,-1,"star_remaining","next_star_serial");}
fn DetectCelestialSignal_03_RockyPlanet(action){detect_celestial_signal_action(action,1,-1,"planet_remaining","next_planet_serial");}
fn DetectCelestialSignal_04_OceanPlanet(action){detect_celestial_signal_action(action,1,-1,"planet_remaining","next_planet_serial");}
fn DetectCelestialSignal_05_GardenPlanet(action){detect_celestial_signal_action(action,1,-1,"planet_remaining","next_planet_serial");}
fn DetectCelestialSignal_06_GasGiant(action){detect_celestial_signal_action(action,3,-1,"gas_giant_remaining","next_gas_giant_serial");}
fn DetectCelestialSignal_07_IceGiant(action){detect_celestial_signal_action(action,4,-1,"ice_giant_remaining","next_ice_giant_serial");}
fn DetectCelestialSignal_08_BarrenPlanet(action){detect_celestial_signal_action(action,1,-1,"planet_remaining","next_planet_serial");}
fn DetectCelestialSignal_09_NeutronStar(action){detect_celestial_signal_action(action,5,-1,"neutron_star_remaining","next_neutron_star_serial");}
fn DetectCelestialSignal_10_BlackHole(action){detect_celestial_signal_action(action,6,-1,"black_hole_remaining","next_black_hole_serial");}
fn DetectCelestialSignal_11_Anomaly(action){detect_celestial_signal_action(action,7,-1,"anomaly_remaining","next_anomaly_serial");}
fn DetectCelestialSignal_12_Megastructure(action){detect_celestial_signal_action(action,8,-1,"megastructure_remaining","next_megastructure_serial");}
fn DetectCelestialSignal_13_GasCluster(action){detect_celestial_signal_action(action,9,-1,"gas_cluster_remaining","next_gas_cluster_serial");}
fn DetectCelestialSignal_14_StellarRemnant(action){detect_celestial_signal_action(action,10,-1,"stellar_remnant_remaining","next_stellar_remnant_serial");}
fn DetectCelestialSignal_15_AsteroidBelt(action){detect_celestial_signal_action(action,11,-1,"minor_body_field_remaining","next_minor_body_field_serial");}
fn DetectCelestialSignal_16_VolcanicPlanet(action){detect_celestial_signal_action(action,1,-1,"planet_remaining","next_planet_serial");}
fn DetectCelestialSignal_17_Nebula(action){detect_celestial_signal_action(action,9,-1,"gas_cluster_remaining","next_gas_cluster_serial");}
fn DetectCelestialSignal_18_CometCluster(action){detect_celestial_signal_action(action,11,-1,"minor_body_field_remaining","next_minor_body_field_serial");}
fn DetectCelestialSignal_19_BrownDwarf(action){detect_celestial_signal_action(action,2,-1,"star_remaining","next_star_serial");}
fn DetectCelestialSignal_20_WhiteDwarf(action){detect_celestial_signal_action(action,10,-1,"stellar_remnant_remaining","next_stellar_remnant_serial");}
fn DetectCelestialSignal_21_Magnetar(action){detect_celestial_signal_action(action,5,-1,"neutron_star_remaining","next_neutron_star_serial");}
fn DetectCelestialSignal_22_WormholeMouth(action){detect_celestial_signal_action(action,7,-1,"anomaly_remaining","next_anomaly_serial");}
fn ScanCelestialBody_00_RedDwarf(action){scan_celestial_body_upper_action(action,-4222748646691076960,2,0,2,0,4000,0,4000,22000,0);}
fn ScanCelestialBody_01_MainSequenceStar(action){scan_celestial_body_range_action(action,-4222748646691076959,-666749789936458296,2,1,2,0,3000,0,4000,27000,0);}
fn ScanCelestialBody_02_GiantStar(action){scan_celestial_body_range_action(action,-666749789936458295,-222249932842130963,2,2,2,0,3000,0,4000,33000,0);}
fn ScanCelestialBody_03_RockyPlanet(action){scan_celestial_body_upper_action(action,7976970408395495921,1,3,1,0,19000,5000,3000,3000,1);}
fn ScanCelestialBody_04_OceanPlanet(action){scan_celestial_body_range_action(action,7976970408395495922,-8475531063215181714,1,4,1,0,14000,3000,14000,3000,2);}
fn ScanCelestialBody_05_GardenPlanet(action){scan_celestial_body_range_action(action,-8475531063215181713,-7976970412690463219,1,5,1,0,17000,9000,6000,6000,1);}
fn ScanCelestialBody_06_GasGiant(action){scan_celestial_body_ungated_action(action,3,6,3,0,2000,0,24000,6000,4);}
fn ScanCelestialBody_07_IceGiant(action){scan_celestial_body_ungated_action(action,4,7,4,0,4000,9000,17000,4000,3);}
fn ScanCelestialBody_08_BarrenPlanet(action){scan_celestial_body_range_action(action,-7976970412690463218,-3988485208492715258,1,8,1,0,23000,9000,0,0,0);}
fn ScanCelestialBody_09_NeutronStar(action){scan_celestial_body_upper_action(action,-6148914694099828737,5,9,5,0,2000,1000,0,43000,0);}
fn ScanCelestialBody_10_BlackHole(action){scan_celestial_body_ungated_action(action,6,10,6,0,0,0,0,50000,0);}
fn ScanCelestialBody_11_Anomaly(action){scan_celestial_body_upper_action(action,6148914689804861439,7,11,7,0,18000,9000,9000,18000,0);}
fn ScanCelestialBody_12_Megastructure(action){scan_celestial_body_ungated_action(action,8,12,8,0,10000,10000,0,10000,0);}
fn ScanCelestialBody_13_GasCluster(action){scan_celestial_body_upper_action(action,-3689348818177884161,9,13,9,0,5000,0,20000,5000,0);}
fn ScanCelestialBody_14_StellarRemnant(action){scan_celestial_body_upper_action(action,-142998020336940818,10,14,10,0,10000,0,0,20000,0);}
fn ScanCelestialBody_15_AsteroidBelt(action){scan_celestial_body_upper_action(action,-2049638234229921110,11,15,11,0,18000,8000,0,4000,0);}
fn ScanCelestialBody_16_VolcanicPlanet(action){scan_celestial_body_lower_action(action,-3988485208492715257,1,16,1,0,16000,0,4000,12000,1);}
fn ScanCelestialBody_17_Nebula(action){scan_celestial_body_lower_action(action,-3689348818177884160,9,17,9,0,2000,0,26000,6000,0);}
fn ScanCelestialBody_18_CometCluster(action){scan_celestial_body_lower_action(action,-2049638234229921109,11,18,11,0,4000,14000,16000,2000,0);}
fn ScanCelestialBody_19_BrownDwarf(action){scan_celestial_body_lower_action(action,-222249932842130962,2,19,2,0,6000,0,24000,12000,0);}
fn ScanCelestialBody_20_WhiteDwarf(action){scan_celestial_body_lower_action(action,-142998020336940817,10,20,10,0,20000,16000,0,8000,0);}
fn ScanCelestialBody_21_Magnetar(action){scan_celestial_body_lower_action(action,-6148914694099828736,5,21,5,0,4000,12000,0,32000,0);}
fn ScanCelestialBody_22_WormholeMouth(action){scan_celestial_body_lower_action(action,6148914689804861440,7,22,7,0,6000,6000,0,40000,0);}
// Coordinates, charts, and traversal
fn ExtractAnomalyWarpCoordinate(action){
var ship=action.mutate("microverse__ship");
var coordinate=action.output("microverse__warp_coordinate");
var body=action.mutate("microverse__celestial_body");
consume_prepared_ship_mutation_core(action,ship,14);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
action.st_sum(ship.extraction_amount,0,250);
action.st_sum(ship.rare_extraction_amount,0,25);
action.st_sum(ship.x,0,body.sector_x);
action.st_sum(ship.y,0,body.sector_y);
action.st_sum(ship.z,0,body.sector_z);
action.st_sum(ship.epoch,0,body.sector_epoch);
action.st_sum(body.candidate_code,0,11);
action.st_sum(body.body_type,0,7);
var source_body_identifier=action.random();
var_assign(source_body_identifier,body.stable_identifier);
body.update("stable_identifier",source_body_identifier);
var source_pool_before=unsafe{body.energy_remaining-0};
action.st_sum(body.energy_remaining,0,source_pool_before);
var next_energy=unsafe{source_pool_before-9000};
action.st_sum(next_energy,9000,source_pool_before);
action.st_gt(next_energy,-1);
coordinate.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["source_body_identifier",source_body_identifier],
["source_pool_before",source_pool_before],
["revealed",0],
["destination_code",0],
["destination_x",0],
["destination_y",0],
["destination_z",0],
["uses_remaining",0]
]);
let zero=action.top_limb_u256(0);
coordinate.update("key",zero);
body.update("energy_remaining",next_energy);
var next_body_key=action.random();
rotate_key(body,next_body_key);
}
fn ExtractAnomalyTimeCoordinate(action){
var ship=action.mutate("microverse__ship");
var coordinate=action.output("microverse__time_coordinate");
var body=action.mutate("microverse__celestial_body");
consume_prepared_ship_mutation_core(action,ship,14);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
action.st_sum(ship.extraction_amount,0,250);
action.st_sum(ship.rare_extraction_amount,0,25);
action.st_sum(ship.x,0,body.sector_x);
action.st_sum(ship.y,0,body.sector_y);
action.st_sum(ship.z,0,body.sector_z);
action.st_sum(ship.epoch,0,body.sector_epoch);
action.st_sum(body.candidate_code,0,11);
action.st_sum(body.body_type,0,7);
var source_body_identifier=action.random();
var_assign(source_body_identifier,body.stable_identifier);
body.update("stable_identifier",source_body_identifier);
var source_pool_before=unsafe{body.energy_remaining-0};
action.st_sum(body.energy_remaining,0,source_pool_before);
var next_energy=unsafe{source_pool_before-9000};
action.st_sum(next_energy,9000,source_pool_before);
action.st_gt(next_energy,-1);
coordinate.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["source_body_identifier",source_body_identifier],
["source_pool_before",source_pool_before],
["revealed",0],
["destination_code",0],
["destination_epoch",0],
["uses_remaining",0]
]);
let zero=action.top_limb_u256(0);
coordinate.update("key",zero);
body.update("energy_remaining",next_energy);
var next_body_key=action.random();
rotate_key(body,next_body_key);
}
fn RevealWarpCoordinate001(action){reveal_warp_coordinate_action(action,1,793814733,968149119310,42019687806,10,17999);}
fn RevealWarpCoordinate002(action){reveal_warp_coordinate_action(action,2,327853439873,605502947,3102,3,9000);}
fn RevealWarpCoordinate003(action){reveal_warp_coordinate_action(action,3,105,465107091,86018776812,3,9000);}
fn RevealWarpCoordinate004(action){reveal_warp_coordinate_action(action,4,814097886,251671466,624,3,9000);}
fn RevealWarpCoordinate005(action){reveal_warp_coordinate_action(action,5,9816070892,17687307174,1647,1,8999);}
fn RevealWarpCoordinate006(action){reveal_warp_coordinate_action(action,6,5411,4089311236,8166194,1,8999);}
fn RevealWarpCoordinate007(action){reveal_warp_coordinate_action(action,7,3554,138474846290,2683096595,1,8999);}
fn RevealWarpCoordinate008(action){reveal_warp_coordinate_action(action,8,304051388063,1555081630477,862,1,8999);}
fn RevealWarpCoordinate009(action){reveal_warp_coordinate_action(action,9,1599211110330,835802248014,61425,1,8999);}
fn RevealWarpCoordinate010(action){reveal_warp_coordinate_action(action,10,8800041,92923,6899663,1,8999);}
fn RevealWarpCoordinate011(action){reveal_warp_coordinate_action(action,11,36941537,718644,90633,1,8999);}
fn RevealWarpCoordinate012(action){reveal_warp_coordinate_action(action,12,9337934020,267915,612152605,1,8999);}
fn RevealWarpCoordinate013(action){reveal_warp_coordinate_action(action,13,6744467,1242490000981,7902244,1,8999);}
fn RevealWarpCoordinate014(action){reveal_warp_coordinate_action(action,14,38345967539,850429340,697145654,1,8999);}
fn RevealWarpCoordinate015(action){reveal_warp_coordinate_action(action,15,5999015,56856983,64952,1,8999);}
fn RevealWarpCoordinate016(action){reveal_warp_coordinate_action(action,16,74640977,831224,67427465431,1,8999);}
fn RevealWarpCoordinate017(action){reveal_warp_coordinate_action(action,17,612742724029,1842615838159,620841,1,8999);}
fn RevealWarpCoordinate018(action){reveal_warp_coordinate_action(action,18,79068746,3516959,57065984,1,8999);}
fn RevealWarpCoordinate019(action){reveal_warp_coordinate_action(action,19,51382549782,5528417226,62111104,1,8999);}
fn RevealWarpCoordinate020(action){reveal_warp_coordinate_action(action,20,76219270,80009,1703747360730,1,8999);}
fn RevealWarpCoordinate021(action){reveal_warp_coordinate_action(action,21,1795412047697,845871,415,1,8999);}
fn RevealWarpCoordinate022(action){reveal_warp_coordinate_action(action,22,660848117667,271400,334705,1,8999);}
fn RevealWarpCoordinate023(action){reveal_warp_coordinate_action(action,23,316245807504,1644,428363,1,8999);}
fn RevealWarpCoordinate024(action){reveal_warp_coordinate_action(action,24,402293889292,351046010,59250682625,1,8999);}
fn RevealWarpCoordinate025(action){reveal_warp_coordinate_action(action,25,24491,49227,1029107766704,1,8999);}
fn RevealWarpCoordinate026(action){reveal_warp_coordinate_action(action,26,891311451115,481989,9218437,1,8999);}
fn RevealWarpCoordinate027(action){reveal_warp_coordinate_action(action,27,5364,979,61474,1,8999);}
fn RevealWarpCoordinate028(action){reveal_warp_coordinate_action(action,28,7511717098,23973543873,576929938269,1,8999);}
fn RevealWarpCoordinate029(action){reveal_warp_coordinate_action(action,29,49656048395,8956,1622146405114,1,8999);}
fn RevealWarpCoordinate030(action){reveal_warp_coordinate_action(action,30,86575726573,951729416101,725,1,8999);}
fn RevealWarpCoordinate031(action){reveal_warp_coordinate_action(action,31,66964245769,3641,1929443695472,1,8999);}
fn RevealWarpCoordinate032(action){reveal_warp_coordinate_action(action,32,3328235205,8159725451,161,1,8999);}
fn RevealWarpCoordinate033(action){reveal_warp_coordinate_action(action,33,39759057,101660631,674,1,8999);}
fn RevealWarpCoordinate034(action){reveal_warp_coordinate_action(action,34,6685,92082552830,54238,1,8999);}
fn RevealWarpCoordinate035(action){reveal_warp_coordinate_action(action,35,14974427,98934823,1819704510913,1,8999);}
fn RevealWarpCoordinate036(action){reveal_warp_coordinate_action(action,36,24944230017,147614734,2500243663,1,8999);}
fn RevealWarpCoordinate037(action){reveal_warp_coordinate_action(action,37,646052251,663494,81352378,1,8999);}
fn RevealWarpCoordinate038(action){reveal_warp_coordinate_action(action,38,372316739,7938120392,1075364813302,1,8999);}
fn RevealWarpCoordinate039(action){reveal_warp_coordinate_action(action,39,1166628200,10526279194,830059075497,1,8999);}
fn RevealWarpCoordinate040(action){reveal_warp_coordinate_action(action,40,210,7442044,1316754193677,1,8999);}
fn RevealWarpCoordinate041(action){reveal_warp_coordinate_action(action,41,38900,4723,6321753,1,8999);}
fn RevealWarpCoordinate042(action){reveal_warp_coordinate_action(action,42,1996409208667,368553358663,1734922,1,8999);}
fn RevealWarpCoordinate043(action){reveal_warp_coordinate_action(action,43,288,6586,19494804,1,8999);}
fn RevealWarpCoordinate044(action){reveal_warp_coordinate_action(action,44,485,422411318214,2619205,1,8999);}
fn RevealWarpCoordinate045(action){reveal_warp_coordinate_action(action,45,966,533868729796,590961427322,1,8999);}
fn RevealWarpCoordinate046(action){reveal_warp_coordinate_action(action,46,52502323784,78133,454,1,8999);}
fn RevealWarpCoordinate047(action){reveal_warp_coordinate_action(action,47,76703948680,9860,11948,1,8999);}
fn RevealWarpCoordinate048(action){reveal_warp_coordinate_action(action,48,314,71372,270745696569,1,8999);}
fn RevealWarpCoordinate049(action){reveal_warp_coordinate_action(action,49,68339007,806,1971315750,1,8999);}
fn RevealWarpCoordinate050(action){reveal_warp_coordinate_action(action,50,5137455393,944693917055,3458525209,1,8999);}
fn RevealWarpCoordinate051(action){reveal_warp_coordinate_action(action,51,1353,21802810,252999300494,1,8999);}
fn RevealWarpCoordinate052(action){reveal_warp_coordinate_action(action,52,4680,9185,868,1,8999);}
fn RevealWarpCoordinate053(action){reveal_warp_coordinate_action(action,53,7524306,350843987584,202765,1,8999);}
fn RevealWarpCoordinate054(action){reveal_warp_coordinate_action(action,54,7632689,1936956092484,469012280963,1,8999);}
fn RevealWarpCoordinate055(action){reveal_warp_coordinate_action(action,55,614439419610,827189,112195927905,1,8999);}
fn RevealWarpCoordinate056(action){reveal_warp_coordinate_action(action,56,582061892477,20141524,8472773550,1,8999);}
fn RevealWarpCoordinate057(action){reveal_warp_coordinate_action(action,57,1573688960761,7976,137,1,8999);}
fn RevealWarpCoordinate058(action){reveal_warp_coordinate_action(action,58,3986,1261757673690,66936285117,1,8999);}
fn RevealWarpCoordinate059(action){reveal_warp_coordinate_action(action,59,729009262,372761,626730552,1,8999);}
fn RevealWarpCoordinate060(action){reveal_warp_coordinate_action(action,60,1104055358028,86077,441,1,8999);}
fn RevealWarpCoordinate061(action){reveal_warp_coordinate_action(action,61,52596109189,3933090003,4456,1,8999);}
fn RevealWarpCoordinate062(action){reveal_warp_coordinate_action(action,62,751694,53701,1314934400969,1,8999);}
fn RevealWarpCoordinate063(action){reveal_warp_coordinate_action(action,63,674369454170,1293446417136,392714,1,8999);}
fn RevealWarpCoordinate064(action){reveal_warp_coordinate_action(action,64,175503070271,6129473553,861604111960,1,8999);}
fn RevealWarpCoordinate065(action){reveal_warp_coordinate_action(action,65,5834724,3286,524,1,8999);}
fn RevealWarpCoordinate066(action){reveal_warp_coordinate_action(action,66,97441800,90047032,53343231,1,8999);}
fn RevealWarpCoordinate067(action){reveal_warp_coordinate_action(action,67,138301,5743516,1938696380619,1,8999);}
fn RevealWarpCoordinate068(action){reveal_warp_coordinate_action(action,68,858558,564867,7888191,1,8999);}
fn RevealWarpCoordinate069(action){reveal_warp_coordinate_action(action,69,825683632839,700275972037,783698141526,1,8999);}
fn RevealWarpCoordinate070(action){reveal_warp_coordinate_action(action,70,70325858,332752,18666153827,1,8999);}
fn RevealWarpCoordinate071(action){reveal_warp_coordinate_action(action,71,4959023,90901641829,17537364,1,8999);}
fn RevealWarpCoordinate072(action){reveal_warp_coordinate_action(action,72,79640,353359,48880,1,8999);}
fn RevealWarpCoordinate073(action){reveal_warp_coordinate_action(action,73,14944048679,5098196192,412,1,8999);}
fn RevealWarpCoordinate074(action){reveal_warp_coordinate_action(action,74,59136791,1445698873532,85863,1,8999);}
fn RevealWarpCoordinate075(action){reveal_warp_coordinate_action(action,75,685809,1497175958752,8978,1,8999);}
fn RevealWarpCoordinate076(action){reveal_warp_coordinate_action(action,76,5246715487,34680434180,295007845,1,8999);}
fn RevealWarpCoordinate077(action){reveal_warp_coordinate_action(action,77,62585671,3692,649793205,1,8999);}
fn RevealWarpCoordinate078(action){reveal_warp_coordinate_action(action,78,1072393121557,228742,26765,1,8999);}
fn RevealWarpCoordinate079(action){reveal_warp_coordinate_action(action,79,915,1443398724083,8138707380,1,8999);}
fn RevealWarpCoordinate080(action){reveal_warp_coordinate_action(action,80,549,5269348966,1682994349116,1,8999);}
fn RevealWarpCoordinate081(action){reveal_warp_coordinate_action(action,81,6647239013,6275506,9077600,1,8999);}
fn RevealWarpCoordinate082(action){reveal_warp_coordinate_action(action,82,8459930015,762,1651,1,8999);}
fn RevealWarpCoordinate083(action){reveal_warp_coordinate_action(action,83,9934711,1258299,59728098252,1,8999);}
fn RevealWarpCoordinate084(action){reveal_warp_coordinate_action(action,84,710,7606736,1557909202223,1,8999);}
fn RevealWarpCoordinate085(action){reveal_warp_coordinate_action(action,85,299,66523168873,284626892275,1,8999);}
fn RevealWarpCoordinate086(action){reveal_warp_coordinate_action(action,86,6152982,7754874715,297911415,1,8999);}
fn RevealWarpCoordinate087(action){reveal_warp_coordinate_action(action,87,78887,1027431,8413,1,8999);}
fn RevealWarpCoordinate088(action){reveal_warp_coordinate_action(action,88,44634,14327071,942410917,1,8999);}
fn RevealWarpCoordinate089(action){reveal_warp_coordinate_action(action,89,149566,44461313485,602,1,8999);}
fn RevealWarpCoordinate090(action){reveal_warp_coordinate_action(action,90,9123,915028640,90641,1,8999);}
fn RevealWarpCoordinate091(action){reveal_warp_coordinate_action(action,91,398540000679,8784213,5356,1,8999);}
fn RevealWarpCoordinate092(action){reveal_warp_coordinate_action(action,92,34771,84430,7861,1,8999);}
fn RevealWarpCoordinate093(action){reveal_warp_coordinate_action(action,93,2534239576,3469374,1106468458539,1,8999);}
fn RevealWarpCoordinate094(action){reveal_warp_coordinate_action(action,94,983822125,895056,335156,1,8999);}
fn RevealWarpCoordinate095(action){reveal_warp_coordinate_action(action,95,3277916,15182044245,28749,1,8999);}
fn RevealWarpCoordinate096(action){reveal_warp_coordinate_action(action,96,3405252341,601743,331027450969,1,8999);}
fn RevealWarpCoordinate097(action){reveal_warp_coordinate_action(action,97,7642808796,1094001984094,79759561924,1,8999);}
fn RevealWarpCoordinate098(action){reveal_warp_coordinate_action(action,98,903829411,904830290312,459,1,8999);}
fn RevealWarpCoordinate099(action){reveal_warp_coordinate_action(action,99,4676559,114518980363,856,1,8999);}
fn RevealWarpCoordinate100(action){reveal_warp_coordinate_action(action,100,766,26758237583,9707,1,8999);}
fn RevealWarpCoordinate101(action){reveal_warp_coordinate_action(action,101,82778400,8860,362295963,1,8999);}
fn RevealWarpCoordinate102(action){reveal_warp_coordinate_action(action,102,1596782367732,1267532572787,39058994718,1,8999);}
fn RevealWarpCoordinate103(action){reveal_warp_coordinate_action(action,103,6045,5859608,1389083,1,8999);}
fn RevealWarpCoordinate104(action){reveal_warp_coordinate_action(action,104,6949,8797833047,50774,1,8999);}
fn RevealWarpCoordinate105(action){reveal_warp_coordinate_action(action,105,798,602,9936325343,1,8999);}
fn RevealWarpCoordinate106(action){reveal_warp_coordinate_action(action,106,788045056049,1060,1644224548739,1,8999);}
fn RevealWarpCoordinate107(action){reveal_warp_coordinate_action(action,107,772432026,1280668882809,1916324341020,1,8999);}
fn RevealWarpCoordinate108(action){reveal_warp_coordinate_action(action,108,3378640,33285937,230946158499,1,8999);}
fn RevealWarpCoordinate109(action){reveal_warp_coordinate_action(action,109,647133815143,5858,1127510,1,8999);}
fn RevealWarpCoordinate110(action){reveal_warp_coordinate_action(action,110,658,44707717,373,1,8999);}
fn RevealWarpCoordinate111(action){reveal_warp_coordinate_action(action,111,4960689,541034,32943629,1,8999);}
fn RevealWarpCoordinate112(action){reveal_warp_coordinate_action(action,112,608860492110,185294125,103,1,8999);}
fn RevealWarpCoordinate113(action){reveal_warp_coordinate_action(action,113,799422578687,1960183226040,111,1,8999);}
fn RevealWarpCoordinate114(action){reveal_warp_coordinate_action(action,114,6945298,13302745,483914,1,8999);}
fn RevealWarpCoordinate115(action){reveal_warp_coordinate_action(action,115,78332954177,707991091435,4786950492,1,8999);}
fn RevealWarpCoordinate116(action){reveal_warp_coordinate_action(action,116,323464621723,860,614040324083,1,8999);}
fn RevealWarpCoordinate117(action){reveal_warp_coordinate_action(action,117,33422934605,447154297,71851297056,1,8999);}
fn RevealWarpCoordinate118(action){reveal_warp_coordinate_action(action,118,4643524785,8617199432,274,1,8999);}
fn RevealWarpCoordinate119(action){reveal_warp_coordinate_action(action,119,908538877625,921,2870139,1,8999);}
fn RevealWarpCoordinate120(action){reveal_warp_coordinate_action(action,120,5446223406,1619077126727,1703,1,8999);}
fn RevealWarpCoordinate121(action){reveal_warp_coordinate_action(action,121,659,717811,90078,1,8999);}
fn RevealWarpCoordinate122(action){reveal_warp_coordinate_action(action,122,19944,555485,882,1,8999);}
fn RevealWarpCoordinate123(action){reveal_warp_coordinate_action(action,123,1385638833787,982971504292,58613,1,8999);}
fn RevealWarpCoordinate124(action){reveal_warp_coordinate_action(action,124,1244899207058,43514054064,35564,1,8999);}
fn RevealWarpCoordinate125(action){reveal_warp_coordinate_action(action,125,7032978,1559777421188,362706019,1,8999);}
fn RevealTimeCoordinate01(action){reveal_time_coordinate_action(action,1,101,10,17999);}
fn RevealTimeCoordinate02(action){reveal_time_coordinate_action(action,2,19257,3,9000);}
fn RevealTimeCoordinate03(action){reveal_time_coordinate_action(action,3,306610,3,9000);}
fn RevealTimeCoordinate04(action){reveal_time_coordinate_action(action,4,1551806,3,9000);}
fn RevealTimeCoordinate05(action){reveal_time_coordinate_action(action,5,4904256,1,8999);}
fn RevealTimeCoordinate06(action){reveal_time_coordinate_action(action,6,11973137,1,8999);}
fn RevealTimeCoordinate07(action){reveal_time_coordinate_action(action,7,24827389,1,8999);}
fn RevealTimeCoordinate08(action){reveal_time_coordinate_action(action,8,45995718,1,8999);}
fn RevealTimeCoordinate09(action){reveal_time_coordinate_action(action,9,78466594,1,8999);}
fn RevealTimeCoordinate10(action){reveal_time_coordinate_action(action,10,125688251,1,8999);}
fn RevealTimeCoordinate11(action){reveal_time_coordinate_action(action,11,191568688,1,8999);}
fn RevealTimeCoordinate12(action){reveal_time_coordinate_action(action,12,280475669,1,8999);}
fn RevealTimeCoordinate13(action){reveal_time_coordinate_action(action,13,397236724,1,8999);}
fn RevealTimeCoordinate14(action){reveal_time_coordinate_action(action,14,547139143,1,8999);}
fn RevealTimeCoordinate15(action){reveal_time_coordinate_action(action,15,735929986,1,8999);}
fn RevealTimeCoordinate16(action){reveal_time_coordinate_action(action,16,969816075,1,8999);}
fn RevealTimeCoordinate17(action){reveal_time_coordinate_action(action,17,1255463996,1,8999);}
fn RevealTimeCoordinate18(action){reveal_time_coordinate_action(action,18,1600000100,1,8999);}
fn RevealTimeCoordinate19(action){reveal_time_coordinate_action(action,19,2011010505,1,8999);}
fn RevealTimeCoordinate20(action){reveal_time_coordinate_action(action,20,2496541090,1,8999);}
fn RevealTimeCoordinate21(action){reveal_time_coordinate_action(action,21,3065097501,1,8999);}
fn RevealTimeCoordinate22(action){reveal_time_coordinate_action(action,22,3725645147,1,8999);}
fn RevealTimeCoordinate23(action){reveal_time_coordinate_action(action,23,4487609204,1,8999);}
fn RevealTimeCoordinate24(action){reveal_time_coordinate_action(action,24,5360874611,1,8999);}
fn RevealTimeCoordinate25(action){reveal_time_coordinate_action(action,25,6355786070,1,8999);}
fn RevealTimeCoordinate26(action){reveal_time_coordinate_action(action,26,7483148051,1,8999);}
fn RevealTimeCoordinate27(action){reveal_time_coordinate_action(action,27,8754224786,1,8999);}
fn RevealTimeCoordinate28(action){reveal_time_coordinate_action(action,28,10180740273,1,8999);}
fn RevealTimeCoordinate29(action){reveal_time_coordinate_action(action,29,11774878274,1,8999);}
fn RevealTimeCoordinate30(action){reveal_time_coordinate_action(action,30,13549282316,1,8999);}
fn RevealTimeCoordinate31(action){reveal_time_coordinate_action(action,31,15517055690,1,8999);}
fn RevealTimeCoordinate32(action){reveal_time_coordinate_action(action,32,17691761452,1,8999);}
fn RevealTimeCoordinate33(action){reveal_time_coordinate_action(action,33,20087422423,1,8999);}
fn RevealTimeCoordinate34(action){reveal_time_coordinate_action(action,34,22718521189,1,8999);}
fn RevealTimeCoordinate35(action){reveal_time_coordinate_action(action,35,25600000098,1,8999);}
fn RevealTimeCoordinate36(action){reveal_time_coordinate_action(action,36,28747261265,1,8999);}
fn RevealTimeCoordinate37(action){reveal_time_coordinate_action(action,37,32176166570,1,8999);}
fn RevealTimeCoordinate38(action){reveal_time_coordinate_action(action,38,35903037656,1,8999);}
fn RevealTimeCoordinate39(action){reveal_time_coordinate_action(action,39,39944655931,1,8999);}
fn RevealTimeCoordinate40(action){reveal_time_coordinate_action(action,40,44318262569,1,8999);}
fn RevealTimeCoordinate41(action){reveal_time_coordinate_action(action,41,49041558506,1,8999);}
fn RevealTimeCoordinate42(action){reveal_time_coordinate_action(action,42,54132704445,1,8999);}
fn RevealTimeCoordinate43(action){reveal_time_coordinate_action(action,43,59610320852,1,8999);}
fn RevealTimeCoordinate44(action){reveal_time_coordinate_action(action,44,65493487959,1,8999);}
fn RevealTimeCoordinate45(action){reveal_time_coordinate_action(action,45,71801745762,1,8999);}
fn RevealTimeCoordinate46(action){reveal_time_coordinate_action(action,46,78555094021,1,8999);}
fn RevealTimeCoordinate47(action){reveal_time_coordinate_action(action,47,85773992261,1,8999);}
fn RevealTimeCoordinate48(action){reveal_time_coordinate_action(action,48,93479359773,1,8999);}
fn RevealTimeCoordinate49(action){reveal_time_coordinate_action(action,49,101692575610,1,8999);}
fn RevealTimeCoordinate50(action){reveal_time_coordinate_action(action,50,110435478592,1,8999);}
fn RevealTimeCoordinate51(action){reveal_time_coordinate_action(action,51,119730367301,1,8999);}
fn RevealTimeCoordinate52(action){reveal_time_coordinate_action(action,52,129600000087,1,8999);}
fn RevealTimeCoordinate53(action){reveal_time_coordinate_action(action,53,140067595062,1,8999);}
fn RevealTimeCoordinate54(action){reveal_time_coordinate_action(action,54,151156830104,1,8999);}
fn RevealTimeCoordinate55(action){reveal_time_coordinate_action(action,55,162891842854,1,8999);}
fn RevealTimeCoordinate56(action){reveal_time_coordinate_action(action,56,175297230719,1,8999);}
fn RevealTimeCoordinate57(action){reveal_time_coordinate_action(action,57,188398050871,1,8999);}
fn RevealTimeCoordinate58(action){reveal_time_coordinate_action(action,58,202219820245,1,8999);}
fn RevealTimeCoordinate59(action){reveal_time_coordinate_action(action,59,216788515542,1,8999);}
fn RevealTimeCoordinate60(action){reveal_time_coordinate_action(action,60,232130573226,1,8999);}
fn RevealTimeCoordinate61(action){reveal_time_coordinate_action(action,61,248272889528,1,8999);}
fn RevealTimeCoordinate62(action){reveal_time_coordinate_action(action,62,265242820442,1,8999);}
fn RevealTimeCoordinate63(action){reveal_time_coordinate_action(action,63,283068181727,1,8999);}
fn RevealTimeCoordinate64(action){reveal_time_coordinate_action(action,64,301777248905,1,8999);}
fn RevealTimeCoordinate65(action){reveal_time_coordinate_action(action,65,321398757267,1,8999);}
fn RevealTimeCoordinate66(action){reveal_time_coordinate_action(action,66,341961901863,1,8999);}
fn RevealTimeCoordinate67(action){reveal_time_coordinate_action(action,67,363496337511,1,8999);}
fn RevealTimeCoordinate68(action){reveal_time_coordinate_action(action,68,386032178795,1,8999);}
fn RevealTimeCoordinate69(action){reveal_time_coordinate_action(action,69,409600000059,1,8999);}
fn RevealTimeCoordinate70(action){reveal_time_coordinate_action(action,70,434230835415,1,8999);}
fn RevealTimeCoordinate71(action){reveal_time_coordinate_action(action,71,459956178739,1,8999);}
fn RevealTimeCoordinate72(action){reveal_time_coordinate_action(action,72,486807983672,1,8999);}
fn RevealTimeCoordinate73(action){reveal_time_coordinate_action(action,73,514818663618,1,8999);}
fn RevealTimeCoordinate74(action){reveal_time_coordinate_action(action,74,544021091746,1,8999);}
fn RevealTimeCoordinate75(action){reveal_time_coordinate_action(action,75,574448600993,1,8999);}
fn RevealTimeCoordinate76(action){reveal_time_coordinate_action(action,76,606134984055,1,8999);}
fn RevealTimeCoordinate77(action){reveal_time_coordinate_action(action,77,639114493396,1,8999);}
fn RevealTimeCoordinate78(action){reveal_time_coordinate_action(action,78,673421841245,1,8999);}
fn RevealTimeCoordinate79(action){reveal_time_coordinate_action(action,79,709092199595,1,8999);}
fn RevealTimeCoordinate80(action){reveal_time_coordinate_action(action,80,746161200202,1,8999);}
fn RevealTimeCoordinate81(action){reveal_time_coordinate_action(action,81,784664934588,1,8999);}
fn RevealTimeCoordinate82(action){reveal_time_coordinate_action(action,82,824639954040,1,8999);}
fn RevealTimeCoordinate83(action){reveal_time_coordinate_action(action,83,866123269609,1,8999);}
fn RevealTimeCoordinate84(action){reveal_time_coordinate_action(action,84,909152352111,1,8999);}
fn RevealTimeCoordinate85(action){reveal_time_coordinate_action(action,85,953765132126,1,8999);}
fn RevealTimeCoordinate86(action){reveal_time_coordinate_action(action,86,999999999999,1,8999);}
fn WarpToCoordinateReusable(action){
var ship=action.mutate("microverse__ship");
var coordinate=action.mutate("microverse__warp_coordinate");
prove_fixed_versions(action,coordinate);
action.st_sum(coordinate.revealed,0,1);
action.st_gt(coordinate.uses_remaining,1);
var next_uses=unsafe{coordinate.uses_remaining-1};
action.st_sum(next_uses,1,coordinate.uses_remaining);
action.st_gt(coordinate.destination_x,0);
action.st_gt(2000000000000,coordinate.destination_x);
action.st_gt(coordinate.destination_y,0);
action.st_gt(2000000000000,coordinate.destination_y);
action.st_gt(coordinate.destination_z,0);
action.st_gt(2000000000000,coordinate.destination_z);
warp_ship_core(action,ship,coordinate.destination_x,coordinate.destination_y,coordinate.destination_z,ship.epoch);
coordinate.update("uses_remaining",next_uses);
var next_coordinate_key=action.random();
rotate_key(coordinate,next_coordinate_key);
}
fn WarpToCoordinateFinal(action){
var ship=action.mutate("microverse__ship");
var coordinate=action.input("microverse__warp_coordinate");
prove_fixed_versions(action,coordinate);
action.st_sum(coordinate.revealed,0,1);
action.st_sum(coordinate.uses_remaining,0,1);
action.st_gt(coordinate.destination_x,0);
action.st_gt(2000000000000,coordinate.destination_x);
action.st_gt(coordinate.destination_y,0);
action.st_gt(2000000000000,coordinate.destination_y);
action.st_gt(coordinate.destination_z,0);
action.st_gt(2000000000000,coordinate.destination_z);
warp_ship_core(action,ship,coordinate.destination_x,coordinate.destination_y,coordinate.destination_z,ship.epoch);
}
fn TimeWarpToCoordinateReusable(action){
var ship=action.mutate("microverse__ship");
var coordinate=action.mutate("microverse__time_coordinate");
prove_fixed_versions(action,coordinate);
action.st_sum(coordinate.revealed,0,1);
action.st_gt(coordinate.uses_remaining,1);
var next_uses=unsafe{coordinate.uses_remaining-1};
action.st_sum(next_uses,1,coordinate.uses_remaining);
action.st_gt(coordinate.destination_epoch,-1);
action.st_gt(1000000000000,coordinate.destination_epoch);
warp_ship_core(action,ship,ship.x,ship.y,ship.z,coordinate.destination_epoch);
coordinate.update("uses_remaining",next_uses);
var next_coordinate_key=action.random();
rotate_key(coordinate,next_coordinate_key);
}
fn TimeWarpToCoordinateFinal(action){
var ship=action.mutate("microverse__ship");
var coordinate=action.input("microverse__time_coordinate");
prove_fixed_versions(action,coordinate);
action.st_sum(coordinate.revealed,0,1);
action.st_sum(coordinate.uses_remaining,0,1);
action.st_gt(coordinate.destination_epoch,-1);
action.st_gt(1000000000000,coordinate.destination_epoch);
warp_ship_core(action,ship,ship.x,ship.y,ship.z,coordinate.destination_epoch);
}
fn ExtractWormholeWarpChart(action){
var ship=action.mutate("microverse__ship");
var chart=action.output("microverse__warp_chart");
var body=action.mutate("microverse__celestial_body");
var source_body_identifier=action.random();
var_assign(source_body_identifier,body.stable_identifier);
body.update("stable_identifier",source_body_identifier);
var source_pool_before=unsafe{body.energy_remaining-0};
action.st_sum(body.energy_remaining,0,source_pool_before);
chart.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["catalog_version",2],
["source_body_identifier",source_body_identifier],
["source_pool_before",source_pool_before],
["revealed",0],
["destination_code",0],
["destination_x",0],
["destination_y",0],
["destination_z",0],
["uses_remaining",0]
]);
let chart_zero=action.top_limb_u256(0);
chart.update("key",chart_zero);
extract_v2_chart_core(action,ship,body,11);
var work=action.intro_vdf(20,chart);
chart.update("work",work);
}
fn ExtractWormholeEpochChart(action){
var ship=action.mutate("microverse__ship");
var chart=action.output("microverse__epoch_chart");
var body=action.mutate("microverse__celestial_body");
var source_body_identifier=action.random();
var_assign(source_body_identifier,body.stable_identifier);
body.update("stable_identifier",source_body_identifier);
var source_pool_before=unsafe{body.energy_remaining-0};
action.st_sum(body.energy_remaining,0,source_pool_before);
chart.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["catalog_version",2],
["source_body_identifier",source_body_identifier],
["source_pool_before",source_pool_before],
["revealed",0],
["destination_code",0],
["destination_epoch",0],
["uses_remaining",0]
]);
let chart_zero=action.top_limb_u256(0);
chart.update("key",chart_zero);
extract_v2_chart_core(action,ship,body,14);
var work=action.intro_vdf(20,chart);
chart.update("work",work);
}
fn RevealWarpChart001(action){reveal_warp_chart_action(action,1,10074,27336,51216,10,39999);}
fn RevealWarpChart002(action){reveal_warp_chart_action(action,2,22972,21819,73251,3,30999);}
fn RevealWarpChart003(action){reveal_warp_chart_action(action,3,72118143059,19385760590,24402608302,3,30999);}
fn RevealWarpChart004(action){reveal_warp_chart_action(action,4,9251,47339,16649,3,30999);}
fn RevealWarpChart005(action){reveal_warp_chart_action(action,5,206798275818,357091429978,559758623041,1,8999);}
fn RevealWarpChart006(action){reveal_warp_chart_action(action,6,697832863,966128739,177061565,1,8999);}
fn RevealWarpChart007(action){reveal_warp_chart_action(action,7,129484832,336090293,374648868,1,8999);}
fn RevealWarpChart008(action){reveal_warp_chart_action(action,8,407956798083,255122953869,416372122780,1,8999);}
fn RevealWarpChart009(action){reveal_warp_chart_action(action,9,88345,69185,87297,1,8999);}
fn RevealWarpChart010(action){reveal_warp_chart_action(action,10,8901706,6451406,3019501,1,8999);}
fn RevealWarpChart011(action){reveal_warp_chart_action(action,11,175780501,340325116,423347817,1,8999);}
fn RevealWarpChart012(action){reveal_warp_chart_action(action,12,591736257636,143637332366,846205944460,1,8999);}
fn RevealWarpChart013(action){reveal_warp_chart_action(action,13,69369,95310,87762,1,8999);}
fn RevealWarpChart014(action){reveal_warp_chart_action(action,14,472438204,344741778,354298221,1,8999);}
fn RevealWarpChart015(action){reveal_warp_chart_action(action,15,94840345287,89880600245,45659369001,1,8999);}
fn RevealWarpChart016(action){reveal_warp_chart_action(action,16,5946323,5207367,1938946,1,8999);}
fn RevealWarpChart017(action){reveal_warp_chart_action(action,17,1287758145479,1171386338485,1470168285736,1,8999);}
fn RevealWarpChart018(action){reveal_warp_chart_action(action,18,43894798840,2770603724,94517650206,1,8999);}
fn RevealWarpChart019(action){reveal_warp_chart_action(action,19,821281959111,818293342296,237664167479,1,8999);}
fn RevealWarpChart020(action){reveal_warp_chart_action(action,20,5732599,5965324,3890012,1,8999);}
fn RevealWarpChart021(action){reveal_warp_chart_action(action,21,73481133505,43098666725,79679375168,1,8999);}
fn RevealWarpChart022(action){reveal_warp_chart_action(action,22,518174208,704639602,583068452,1,8999);}
fn RevealWarpChart023(action){reveal_warp_chart_action(action,23,1568829907566,1633844743861,1000686091903,1,8999);}
fn RevealWarpChart024(action){reveal_warp_chart_action(action,24,116456971,657441882,571786180,1,8999);}
fn RevealWarpChart025(action){reveal_warp_chart_action(action,25,2632589,8258162,1962019,1,8999);}
fn RevealWarpChart026(action){reveal_warp_chart_action(action,26,419671824582,903953066772,760785892021,1,8999);}
fn RevealWarpChart027(action){reveal_warp_chart_action(action,27,9814145,7134937,5112582,1,8999);}
fn RevealWarpChart028(action){reveal_warp_chart_action(action,28,924420380134,929850584933,472323161867,1,8999);}
fn RevealWarpChart029(action){reveal_warp_chart_action(action,29,779099814,973407085,179575265,1,8999);}
fn RevealWarpChart030(action){reveal_warp_chart_action(action,30,7623691,3412132,8653143,1,8999);}
fn RevealWarpChart031(action){reveal_warp_chart_action(action,31,35657479123,82561883462,68859217663,1,8999);}
fn RevealWarpChart032(action){reveal_warp_chart_action(action,32,97397,89248,70911,1,8999);}
fn RevealWarpChart033(action){reveal_warp_chart_action(action,33,73228,55911,55313,1,8999);}
fn RevealWarpChart034(action){reveal_warp_chart_action(action,34,4860363,1504063,2727096,1,8999);}
fn RevealWarpChart035(action){reveal_warp_chart_action(action,35,4185659,7251031,3864918,1,8999);}
fn RevealWarpChart036(action){reveal_warp_chart_action(action,36,986300365192,390772761610,267957633155,1,8999);}
fn RevealWarpChart037(action){reveal_warp_chart_action(action,37,8762001,878999,5291426,1,8999);}
fn RevealWarpChart038(action){reveal_warp_chart_action(action,38,3930396294,57577939222,61170847618,1,8999);}
fn RevealWarpChart039(action){reveal_warp_chart_action(action,39,100539545,812641514,904812733,1,8999);}
fn RevealWarpChart040(action){reveal_warp_chart_action(action,40,1008841550676,1616066770638,1182483495703,1,8999);}
fn RevealWarpChart041(action){reveal_warp_chart_action(action,41,759289157552,127187844480,117808742750,1,8999);}
fn RevealWarpChart042(action){reveal_warp_chart_action(action,42,1274832782972,1782293743515,1293644359364,1,8999);}
fn RevealWarpChart043(action){reveal_warp_chart_action(action,43,2369750,421781,7305851,1,8999);}
fn RevealWarpChart044(action){reveal_warp_chart_action(action,44,1028701687614,1172246496167,1821362932822,1,8999);}
fn RevealWarpChart045(action){reveal_warp_chart_action(action,45,41891,14716,26208,1,8999);}
fn RevealWarpChart046(action){reveal_warp_chart_action(action,46,33414936720,79388617127,23256941551,1,8999);}
fn RevealWarpChart047(action){reveal_warp_chart_action(action,47,743183208,581502474,857786464,1,8999);}
fn RevealWarpChart048(action){reveal_warp_chart_action(action,48,5582139399,7411700416,41287490225,1,8999);}
fn RevealWarpChart049(action){reveal_warp_chart_action(action,49,437283591,688603927,740673088,1,8999);}
fn RevealWarpChart050(action){reveal_warp_chart_action(action,50,503682,6324273,4377833,1,8999);}
fn RevealWarpChart051(action){reveal_warp_chart_action(action,51,1785487448810,1968559197516,1328311510116,1,8999);}
fn RevealWarpChart052(action){reveal_warp_chart_action(action,52,624707820,503471665,818913195,1,8999);}
fn RevealWarpChart053(action){reveal_warp_chart_action(action,53,7537708403,37521084776,99563538503,1,8999);}
fn RevealWarpChart054(action){reveal_warp_chart_action(action,54,223,723,296,1,8999);}
fn RevealWarpChart055(action){reveal_warp_chart_action(action,55,4000044,2391467,9508312,1,8999);}
fn RevealWarpChart056(action){reveal_warp_chart_action(action,56,225,860,371,1,8999);}
fn RevealWarpChart057(action){reveal_warp_chart_action(action,57,900707900750,278589988959,219830105586,1,8999);}
fn RevealWarpChart058(action){reveal_warp_chart_action(action,58,2813803,7074255,4125989,1,8999);}
fn RevealWarpChart059(action){reveal_warp_chart_action(action,59,956814486358,916478176893,845919916361,1,8999);}
fn RevealWarpChart060(action){reveal_warp_chart_action(action,60,44215474931,58863561127,35138164990,1,8999);}
fn RevealWarpChart061(action){reveal_warp_chart_action(action,61,149847903,453934185,648050718,1,8999);}
fn RevealWarpChart062(action){reveal_warp_chart_action(action,62,881,305,518,1,8999);}
fn RevealWarpChart063(action){reveal_warp_chart_action(action,63,1814389357,72525172254,31551802762,1,8999);}
fn RevealWarpChart064(action){reveal_warp_chart_action(action,64,75179,81084,90371,1,8999);}
fn RevealWarpChart065(action){reveal_warp_chart_action(action,65,455753032,535600995,352122384,1,8999);}
fn RevealWarpChart066(action){reveal_warp_chart_action(action,66,87834627982,89735847224,52413232999,1,8999);}
fn RevealWarpChart067(action){reveal_warp_chart_action(action,67,647021280396,628547072517,918494627285,1,8999);}
fn RevealWarpChart068(action){reveal_warp_chart_action(action,68,75267163790,18804405127,74281696123,1,8999);}
fn RevealWarpChart069(action){reveal_warp_chart_action(action,69,36133,22410,68940,1,8999);}
fn RevealWarpChart070(action){reveal_warp_chart_action(action,70,763768237140,592168606272,485899585145,1,8999);}
fn RevealWarpChart071(action){reveal_warp_chart_action(action,71,708,555,468,1,8999);}
fn RevealWarpChart072(action){reveal_warp_chart_action(action,72,46104764812,33483415363,55428358523,1,8999);}
fn RevealWarpChart073(action){reveal_warp_chart_action(action,73,634609748692,900596716345,911203282001,1,8999);}
fn RevealWarpChart074(action){reveal_warp_chart_action(action,74,1401060363379,1425139228247,1370100094792,1,8999);}
fn RevealWarpChart075(action){reveal_warp_chart_action(action,75,726958986417,152213505081,682639687448,1,8999);}
fn RevealWarpChart076(action){reveal_warp_chart_action(action,76,252,777,593,1,8999);}
fn RevealWarpChart077(action){reveal_warp_chart_action(action,77,416848833490,705643221447,440089940899,1,8999);}
fn RevealWarpChart078(action){reveal_warp_chart_action(action,78,871604674,792818175,888376863,1,8999);}
fn RevealWarpChart079(action){reveal_warp_chart_action(action,79,23163,72227,35439,1,8999);}
fn RevealWarpChart080(action){reveal_warp_chart_action(action,80,22328908111,24411973557,42631757450,1,8999);}
fn RevealWarpChart081(action){reveal_warp_chart_action(action,81,1202740558102,1283152855311,1649325271410,1,8999);}
fn RevealWarpChart082(action){reveal_warp_chart_action(action,82,758777919256,895362603070,401287015240,1,8999);}
fn RevealWarpChart083(action){reveal_warp_chart_action(action,83,540304660,30148521,100522816,1,8999);}
fn RevealWarpChart084(action){reveal_warp_chart_action(action,84,993437334553,859880626880,536494317527,1,8999);}
fn RevealWarpChart085(action){reveal_warp_chart_action(action,85,2005337,9772642,3458503,1,8999);}
fn RevealWarpChart086(action){reveal_warp_chart_action(action,86,3042315,791577,4010054,1,8999);}
fn RevealWarpChart087(action){reveal_warp_chart_action(action,87,13855346047,96288567914,96636901450,1,8999);}
fn RevealWarpChart088(action){reveal_warp_chart_action(action,88,7336391,362050,6982535,1,8999);}
fn RevealWarpChart089(action){reveal_warp_chart_action(action,89,4622506,1675076,6679876,1,8999);}
fn RevealWarpChart090(action){reveal_warp_chart_action(action,90,298319293,937849991,210707493,1,8999);}
fn RevealWarpChart091(action){reveal_warp_chart_action(action,91,598213541,975702891,685848881,1,8999);}
fn RevealWarpChart092(action){reveal_warp_chart_action(action,92,1977104175714,1573476306023,1561492130455,1,8999);}
fn RevealWarpChart093(action){reveal_warp_chart_action(action,93,9062999,7864414,7924140,1,8999);}
fn RevealWarpChart094(action){reveal_warp_chart_action(action,94,2589668,6514773,5391779,1,8999);}
fn RevealWarpChart095(action){reveal_warp_chart_action(action,95,67550958631,42684241334,51990585131,1,8999);}
fn RevealWarpChart096(action){reveal_warp_chart_action(action,96,295,699,114,1,8999);}
fn RevealWarpChart097(action){reveal_warp_chart_action(action,97,370311762335,871137211426,501479487354,1,8999);}
fn RevealWarpChart098(action){reveal_warp_chart_action(action,98,1903408,4254737,3835257,1,8999);}
fn RevealWarpChart099(action){reveal_warp_chart_action(action,99,1703277215433,1030820697698,1256353283895,1,8999);}
fn RevealWarpChart100(action){reveal_warp_chart_action(action,100,740,590,637,1,8999);}
fn RevealWarpChart101(action){reveal_warp_chart_action(action,101,634672735,990942104,774868376,1,8999);}
fn RevealWarpChart102(action){reveal_warp_chart_action(action,102,93840,85440,20567,1,8999);}
fn RevealWarpChart103(action){reveal_warp_chart_action(action,103,957,300,218,1,8999);}
fn RevealWarpChart104(action){reveal_warp_chart_action(action,104,4390390,5801879,4189254,1,8999);}
fn RevealWarpChart105(action){reveal_warp_chart_action(action,105,1224356642994,1690514233487,1000070951892,1,8999);}
fn RevealWarpChart106(action){reveal_warp_chart_action(action,106,281074184,332497431,360763835,1,8999);}
fn RevealWarpChart107(action){reveal_warp_chart_action(action,107,38157649633,55298756329,26024298960,1,8999);}
fn RevealWarpChart108(action){reveal_warp_chart_action(action,108,710491616,826185728,315592637,1,8999);}
fn RevealWarpChart109(action){reveal_warp_chart_action(action,109,1246021392091,1369513950735,1526238360169,1,8999);}
fn RevealWarpChart110(action){reveal_warp_chart_action(action,110,94785385616,44887904229,50034370509,1,8999);}
fn RevealWarpChart111(action){reveal_warp_chart_action(action,111,991,106,936,1,8999);}
fn RevealWarpChart112(action){reveal_warp_chart_action(action,112,875930465,276116087,500052154,1,8999);}
fn RevealWarpChart113(action){reveal_warp_chart_action(action,113,1216187239001,1807040461777,1820199712045,1,8999);}
fn RevealWarpChart114(action){reveal_warp_chart_action(action,114,956706523485,602863588036,828357347780,1,8999);}
fn RevealWarpChart115(action){reveal_warp_chart_action(action,115,6388663,4379681,4489922,1,8999);}
fn RevealWarpChart116(action){reveal_warp_chart_action(action,116,609807325,250801583,641325535,1,8999);}
fn RevealWarpChart117(action){reveal_warp_chart_action(action,117,846447157,138988398,155961021,1,8999);}
fn RevealWarpChart118(action){reveal_warp_chart_action(action,118,31794362432,16333603740,25256873821,1,8999);}
fn RevealWarpChart119(action){reveal_warp_chart_action(action,119,460317881967,991814065040,151043852749,1,8999);}
fn RevealWarpChart120(action){reveal_warp_chart_action(action,120,6760189,5113540,5964501,1,8999);}
fn RevealWarpChart121(action){reveal_warp_chart_action(action,121,1032757414370,1254288232289,1773598556113,1,8999);}
fn RevealWarpChart122(action){reveal_warp_chart_action(action,122,10968844439,56305567013,68747067050,1,8999);}
fn RevealWarpChart123(action){reveal_warp_chart_action(action,123,75528700444,69780246364,34870109393,1,8999);}
fn RevealWarpChart124(action){reveal_warp_chart_action(action,124,2469719,488947,815502,1,8999);}
fn RevealWarpChart125(action){reveal_warp_chart_action(action,125,76039,46961,99723,1,8999);}
fn RevealWarpChart126(action){reveal_warp_chart_action(action,126,191486,6729424,6254800,1,8999);}
fn RevealWarpChart127(action){reveal_warp_chart_action(action,127,69036,3223,45998,1,8999);}
fn RevealWarpChart128(action){reveal_warp_chart_action(action,128,35946208719,70008148457,57359493512,1,8999);}
fn RevealWarpChart129(action){reveal_warp_chart_action(action,129,92140,1542,13658,1,8999);}
fn RevealWarpChart130(action){reveal_warp_chart_action(action,130,97274,68349,10275,1,8999);}
fn RevealWarpChart131(action){reveal_warp_chart_action(action,131,15656966542,34809779827,64088266343,1,8999);}
fn RevealWarpChart132(action){reveal_warp_chart_action(action,132,61154068365,73899538816,74482556907,1,8999);}
fn RevealWarpChart133(action){reveal_warp_chart_action(action,133,43587651028,51297156879,80619413171,1,8999);}
fn RevealWarpChart134(action){reveal_warp_chart_action(action,134,66909742400,53519019397,48124492518,1,8999);}
fn RevealWarpChart135(action){reveal_warp_chart_action(action,135,24763,62135,66695,1,8999);}
fn RevealWarpChart136(action){reveal_warp_chart_action(action,136,8771323,6678346,3260027,1,8999);}
fn RevealWarpChart137(action){reveal_warp_chart_action(action,137,43833,13016,36428,1,8999);}
fn RevealWarpChart138(action){reveal_warp_chart_action(action,138,92047,64824,4770,1,8999);}
fn RevealWarpChart139(action){reveal_warp_chart_action(action,139,89360699101,8836713211,41809933575,1,8999);}
fn RevealWarpChart140(action){reveal_warp_chart_action(action,140,285738909,283044676,32121025,1,8999);}
fn RevealWarpChart141(action){reveal_warp_chart_action(action,141,813722391124,932342285802,252364894238,1,8999);}
fn RevealWarpChart142(action){reveal_warp_chart_action(action,142,211815218227,841433579025,768686803402,1,8999);}
fn RevealWarpChart143(action){reveal_warp_chart_action(action,143,5144440285,10137782298,27951785703,1,8999);}
fn RevealWarpChart144(action){reveal_warp_chart_action(action,144,308140021119,169219244416,747326497038,1,8999);}
fn RevealWarpChart145(action){reveal_warp_chart_action(action,145,7592200,8934757,9559965,1,8999);}
fn RevealWarpChart146(action){reveal_warp_chart_action(action,146,337777506314,786555151591,147098046668,1,8999);}
fn RevealWarpChart147(action){reveal_warp_chart_action(action,147,2004327,8475812,4094826,1,8999);}
fn RevealWarpChart148(action){reveal_warp_chart_action(action,148,486748812,42559444,920297189,1,8999);}
fn RevealWarpChart149(action){reveal_warp_chart_action(action,149,9068518,6238914,7042090,1,8999);}
fn RevealWarpChart150(action){reveal_warp_chart_action(action,150,7050602,9494154,3616727,1,8999);}
fn RevealWarpChart151(action){reveal_warp_chart_action(action,151,891,512,875,1,8999);}
fn RevealWarpChart152(action){reveal_warp_chart_action(action,152,216861,7141910,6516061,1,8999);}
fn RevealWarpChart153(action){reveal_warp_chart_action(action,153,568574514,541451707,623131209,1,8999);}
fn RevealWarpChart154(action){reveal_warp_chart_action(action,154,36648732,949004415,460255777,1,8999);}
fn RevealWarpChart155(action){reveal_warp_chart_action(action,155,264727831482,653144442200,804200751788,1,8999);}
fn RevealWarpChart156(action){reveal_warp_chart_action(action,156,559686446,859370879,309783580,1,8999);}
fn RevealWarpChart157(action){reveal_warp_chart_action(action,157,644483968568,291933323486,189333739412,1,8999);}
fn RevealWarpChart158(action){reveal_warp_chart_action(action,158,198,228,972,1,8999);}
fn RevealWarpChart159(action){reveal_warp_chart_action(action,159,750571097870,807780781974,566083851319,1,8999);}
fn RevealWarpChart160(action){reveal_warp_chart_action(action,160,177227,8600887,538162,1,8999);}
fn RevealWarpChart161(action){reveal_warp_chart_action(action,161,3598948,8171309,601244,1,8999);}
fn RevealWarpChart162(action){reveal_warp_chart_action(action,162,607006625,794401597,730621167,1,8999);}
fn RevealWarpChart163(action){reveal_warp_chart_action(action,163,116394049558,269847922069,455374500243,1,8999);}
fn RevealWarpChart164(action){reveal_warp_chart_action(action,164,1050004316062,1032431436990,1628959679760,1,8999);}
fn RevealWarpChart165(action){reveal_warp_chart_action(action,165,2134438,7793920,7250445,1,8999);}
fn RevealWarpChart166(action){reveal_warp_chart_action(action,166,277664096346,364837372855,232702721894,1,8999);}
fn RevealWarpChart167(action){reveal_warp_chart_action(action,167,1412416157320,1686808021500,1110606046765,1,8999);}
fn RevealWarpChart168(action){reveal_warp_chart_action(action,168,4948222,8102793,7241863,1,8999);}
fn RevealWarpChart169(action){reveal_warp_chart_action(action,169,850376858,956061647,119407811,1,8999);}
fn RevealWarpChart170(action){reveal_warp_chart_action(action,170,462558795,848644703,860809840,1,8999);}
fn RevealWarpChart171(action){reveal_warp_chart_action(action,171,11381397669,83772452611,44231379538,1,8999);}
fn RevealWarpChart172(action){reveal_warp_chart_action(action,172,6488862,7772054,1280327,1,8999);}
fn RevealWarpChart173(action){reveal_warp_chart_action(action,173,883980260,760114909,884914556,1,8999);}
fn RevealWarpChart174(action){reveal_warp_chart_action(action,174,33205,39835,63243,1,8999);}
fn RevealWarpChart175(action){reveal_warp_chart_action(action,175,62524777214,46927575934,45948462518,1,8999);}
fn RevealWarpChart176(action){reveal_warp_chart_action(action,176,1886404682367,1184450112098,1831641973445,1,8999);}
fn RevealWarpChart177(action){reveal_warp_chart_action(action,177,391027502020,362776749249,767200873467,1,8999);}
fn RevealWarpChart178(action){reveal_warp_chart_action(action,178,1069224030877,1256644668775,1938850096514,1,8999);}
fn RevealWarpChart179(action){reveal_warp_chart_action(action,179,475479126,164980576,380333805,1,8999);}
fn RevealWarpChart180(action){reveal_warp_chart_action(action,180,36521,85900,11210,1,8999);}
fn RevealWarpChart181(action){reveal_warp_chart_action(action,181,1158185239345,1533346162139,1565819126316,1,8999);}
fn RevealWarpChart182(action){reveal_warp_chart_action(action,182,176820931,888398133,206342741,1,8999);}
fn RevealWarpChart183(action){reveal_warp_chart_action(action,183,34843390092,42701978147,17122942256,1,8999);}
fn RevealWarpChart184(action){reveal_warp_chart_action(action,184,1098355928341,1472864853025,1234607979430,1,8999);}
fn RevealWarpChart185(action){reveal_warp_chart_action(action,185,678429255,366306924,847872463,1,8999);}
fn RevealWarpChart186(action){reveal_warp_chart_action(action,186,253,819,913,1,8999);}
fn RevealWarpChart187(action){reveal_warp_chart_action(action,187,5064485,1906762,3608681,1,8999);}
fn RevealWarpChart188(action){reveal_warp_chart_action(action,188,149181786,776866453,97642607,1,8999);}
fn RevealWarpChart189(action){reveal_warp_chart_action(action,189,6880452,5383674,5041532,1,8999);}
fn RevealWarpChart190(action){reveal_warp_chart_action(action,190,22458411203,82825728378,41711643789,1,8999);}
fn RevealWarpChart191(action){reveal_warp_chart_action(action,191,1426364940374,1362885381733,1930579053543,1,8999);}
fn RevealWarpChart192(action){reveal_warp_chart_action(action,192,791982659733,322885759092,861377906131,1,8999);}
fn RevealWarpChart193(action){reveal_warp_chart_action(action,193,5882389,2342994,9705098,1,8999);}
fn RevealWarpChart194(action){reveal_warp_chart_action(action,194,25148476706,9795830832,76402919741,1,8999);}
fn RevealWarpChart195(action){reveal_warp_chart_action(action,195,476838498,319954401,868480919,1,8999);}
fn RevealWarpChart196(action){reveal_warp_chart_action(action,196,97176196414,4039295600,73567133514,1,8999);}
fn RevealWarpChart197(action){reveal_warp_chart_action(action,197,63225,5630,62664,1,8999);}
fn RevealWarpChart198(action){reveal_warp_chart_action(action,198,697401424,186418245,243100837,1,8999);}
fn RevealWarpChart199(action){reveal_warp_chart_action(action,199,96774,26842,27390,1,8999);}
fn RevealWarpChart200(action){reveal_warp_chart_action(action,200,1388269225432,1106536683326,1970854923900,1,8999);}
fn RevealWarpChart201(action){reveal_warp_chart_action(action,201,872187321051,460105337909,563085996558,1,8999);}
fn RevealWarpChart202(action){reveal_warp_chart_action(action,202,40910601733,58947270694,25912345260,1,8999);}
fn RevealWarpChart203(action){reveal_warp_chart_action(action,203,717451415,257253533,121106095,1,8999);}
fn RevealWarpChart204(action){reveal_warp_chart_action(action,204,26936919774,32423658168,6526345867,1,8999);}
fn RevealWarpChart205(action){reveal_warp_chart_action(action,205,32951204806,95395017765,90137771777,1,8999);}
fn RevealWarpChart206(action){reveal_warp_chart_action(action,206,5821957,9182788,7196764,1,8999);}
fn RevealWarpChart207(action){reveal_warp_chart_action(action,207,381573962,735272461,618415472,1,8999);}
fn RevealWarpChart208(action){reveal_warp_chart_action(action,208,14970,86753,87098,1,8999);}
fn RevealWarpChart209(action){reveal_warp_chart_action(action,209,66722,6465,26998,1,8999);}
fn RevealWarpChart210(action){reveal_warp_chart_action(action,210,5838969,1662945,4475798,1,8999);}
fn RevealWarpChart211(action){reveal_warp_chart_action(action,211,14515,53140,93194,1,8999);}
fn RevealWarpChart212(action){reveal_warp_chart_action(action,212,5398698,8618941,3976412,1,8999);}
fn RevealWarpChart213(action){reveal_warp_chart_action(action,213,48364965037,83892918614,71233574959,1,8999);}
fn RevealWarpChart214(action){reveal_warp_chart_action(action,214,179741986404,585971173462,961915289626,1,8999);}
fn RevealWarpChart215(action){reveal_warp_chart_action(action,215,894625701,842850924,849294817,1,8999);}
fn RevealWarpChart216(action){reveal_warp_chart_action(action,216,43461727033,30697712933,4843718043,1,8999);}
fn RevealWarpChart217(action){reveal_warp_chart_action(action,217,998696623047,128182788919,397292009706,1,8999);}
fn RevealWarpChart218(action){reveal_warp_chart_action(action,218,4134157660,87766433147,48792951695,1,8999);}
fn RevealWarpChart219(action){reveal_warp_chart_action(action,219,214867085,299271678,598955484,1,8999);}
fn RevealWarpChart220(action){reveal_warp_chart_action(action,220,15994,15685,8429,1,8999);}
fn RevealWarpChart221(action){reveal_warp_chart_action(action,221,7150139,7137215,3498353,1,8999);}
fn RevealWarpChart222(action){reveal_warp_chart_action(action,222,507714764,429578850,597819405,1,8999);}
fn RevealWarpChart223(action){reveal_warp_chart_action(action,223,797397975013,450353396984,353017590971,1,8999);}
fn RevealWarpChart224(action){reveal_warp_chart_action(action,224,300550895092,204971595119,350311255182,1,8999);}
fn RevealWarpChart225(action){reveal_warp_chart_action(action,225,597476120325,758103166257,584861536471,1,8999);}
fn RevealWarpChart226(action){reveal_warp_chart_action(action,226,612,287,488,1,8999);}
fn RevealWarpChart227(action){reveal_warp_chart_action(action,227,1098455879455,1669180610901,1649175683750,1,8999);}
fn RevealWarpChart228(action){reveal_warp_chart_action(action,228,667697,9522165,3098915,1,8999);}
fn RevealWarpChart229(action){reveal_warp_chart_action(action,229,124607174,663379634,814392545,1,8999);}
fn RevealWarpChart230(action){reveal_warp_chart_action(action,230,96365592419,5239990800,99627046449,1,8999);}
fn RevealWarpChart231(action){reveal_warp_chart_action(action,231,24432136925,21559399440,15139310973,1,8999);}
fn RevealWarpChart232(action){reveal_warp_chart_action(action,232,564808534,262937859,33642432,1,8999);}
fn RevealWarpChart233(action){reveal_warp_chart_action(action,233,84757955521,67313662506,9448691970,1,8999);}
fn RevealWarpChart234(action){reveal_warp_chart_action(action,234,8482827,7679668,4614961,1,8999);}
fn RevealWarpChart235(action){reveal_warp_chart_action(action,235,4594601,6804006,6499784,1,8999);}
fn RevealWarpChart236(action){reveal_warp_chart_action(action,236,1785459032263,1436627809023,1136031236865,1,8999);}
fn RevealWarpChart237(action){reveal_warp_chart_action(action,237,65721,53315,72626,1,8999);}
fn RevealWarpChart238(action){reveal_warp_chart_action(action,238,5390113,3638968,4053143,1,8999);}
fn RevealWarpChart239(action){reveal_warp_chart_action(action,239,534565545,645734759,787377921,1,8999);}
fn RevealWarpChart240(action){reveal_warp_chart_action(action,240,4131,75075,49931,1,8999);}
fn RevealWarpChart241(action){reveal_warp_chart_action(action,241,648,752,565,1,8999);}
fn RevealWarpChart242(action){reveal_warp_chart_action(action,242,72456,71976,50076,1,8999);}
fn RevealWarpChart243(action){reveal_warp_chart_action(action,243,94962612274,79437835592,23431956408,1,8999);}
fn RevealWarpChart244(action){reveal_warp_chart_action(action,244,986133657691,499382533344,585937511750,1,8999);}
fn RevealWarpChart245(action){reveal_warp_chart_action(action,245,96673,91493,92131,1,8999);}
fn RevealWarpChart246(action){reveal_warp_chart_action(action,246,44942,57830,49717,1,8999);}
fn RevealWarpChart247(action){reveal_warp_chart_action(action,247,7225291,7218369,8111364,1,8999);}
fn RevealWarpChart248(action){reveal_warp_chart_action(action,248,11603836146,42888207220,11700618538,1,8999);}
fn RevealWarpChart249(action){reveal_warp_chart_action(action,249,825,246,331,1,8999);}
fn RevealWarpChart250(action){reveal_warp_chart_action(action,250,41995037844,4457444619,41437290410,1,8999);}
fn RevealWarpChart251(action){reveal_warp_chart_action(action,251,957,155,421,1,8999);}
fn RevealWarpChart252(action){reveal_warp_chart_action(action,252,405783721,96029318,537369384,1,8999);}
fn RevealWarpChart253(action){reveal_warp_chart_action(action,253,45104721,704480189,712602660,1,8999);}
fn RevealWarpChart254(action){reveal_warp_chart_action(action,254,247201906904,585789130388,583519608485,1,8999);}
fn RevealWarpChart255(action){reveal_warp_chart_action(action,255,12990416024,40219871999,55148265409,1,8999);}
fn RevealWarpChart256(action){reveal_warp_chart_action(action,256,385729605511,631900261432,396119036916,1,8999);}
fn WarpShipToPositionCoordinateReusable(action){
var ship=action.mutate("microverse__ship");
var chart=action.mutate("microverse__warp_chart");
prove_object_version_core(action,chart,"catalog_version");
action.st_sum(chart.revealed,0,1);
action.st_sum(ship.active_skill_type,0,51);
action.st_gt(chart.destination_x,99);
action.st_gt(2000000000000,chart.destination_x);
action.st_gt(chart.destination_y,99);
action.st_gt(2000000000000,chart.destination_y);
action.st_gt(chart.destination_z,99);
action.st_gt(2000000000000,chart.destination_z);
warp_ship_core(action,ship,chart.destination_x,chart.destination_y,chart.destination_z,ship.epoch);
consume_reusable_use_core(action,chart);
var work=action.intro_vdf(12,ship);
ship.update("work",work);
}
fn WarpShipToPositionCoordinateFinal(action){
var ship=action.mutate("microverse__ship");
var chart=action.input("microverse__warp_chart");
prove_object_version_core(action,chart,"catalog_version");
action.st_sum(chart.revealed,0,1);
action.st_sum(ship.active_skill_type,0,51);
action.st_gt(chart.destination_x,99);
action.st_gt(2000000000000,chart.destination_x);
action.st_gt(chart.destination_y,99);
action.st_gt(2000000000000,chart.destination_y);
action.st_gt(chart.destination_z,99);
action.st_gt(2000000000000,chart.destination_z);
warp_ship_core(action,ship,chart.destination_x,chart.destination_y,chart.destination_z,ship.epoch);
consume_final_use_core(action,chart);
var work=action.intro_vdf(12,ship);
ship.update("work",work);
}
fn RevealEpochChart001(action){reveal_epoch_chart_action(action,1,256368704,10,39999);}
fn RevealEpochChart002(action){reveal_epoch_chart_action(action,2,822630710647,3,30999);}
fn RevealEpochChart003(action){reveal_epoch_chart_action(action,3,712296361,3,30999);}
fn RevealEpochChart004(action){reveal_epoch_chart_action(action,4,482747484418,3,30999);}
fn RevealEpochChart005(action){reveal_epoch_chart_action(action,5,79684052,1,8999);}
fn RevealEpochChart006(action){reveal_epoch_chart_action(action,6,168714394971,1,8999);}
fn RevealEpochChart007(action){reveal_epoch_chart_action(action,7,852385296674,1,8999);}
fn RevealEpochChart008(action){reveal_epoch_chart_action(action,8,313775339588,1,8999);}
fn RevealEpochChart009(action){reveal_epoch_chart_action(action,9,418407602376,1,8999);}
fn RevealEpochChart010(action){reveal_epoch_chart_action(action,10,682910950,1,8999);}
fn RevealEpochChart011(action){reveal_epoch_chart_action(action,11,266629299,1,8999);}
fn RevealEpochChart012(action){reveal_epoch_chart_action(action,12,3286854178,1,8999);}
fn RevealEpochChart013(action){reveal_epoch_chart_action(action,13,617218660856,1,8999);}
fn RevealEpochChart014(action){reveal_epoch_chart_action(action,14,992813523404,1,8999);}
fn RevealEpochChart015(action){reveal_epoch_chart_action(action,15,92169980272,1,8999);}
fn RevealEpochChart016(action){reveal_epoch_chart_action(action,16,40732598204,1,8999);}
fn RevealEpochChart017(action){reveal_epoch_chart_action(action,17,592495517877,1,8999);}
fn RevealEpochChart018(action){reveal_epoch_chart_action(action,18,94465056208,1,8999);}
fn RevealEpochChart019(action){reveal_epoch_chart_action(action,19,815809172,1,8999);}
fn RevealEpochChart020(action){reveal_epoch_chart_action(action,20,8500482,1,8999);}
fn RevealEpochChart021(action){reveal_epoch_chart_action(action,21,476595662058,1,8999);}
fn RevealEpochChart022(action){reveal_epoch_chart_action(action,22,3553570,1,8999);}
fn RevealEpochChart023(action){reveal_epoch_chart_action(action,23,5289266,1,8999);}
fn RevealEpochChart024(action){reveal_epoch_chart_action(action,24,167461903501,1,8999);}
fn RevealEpochChart025(action){reveal_epoch_chart_action(action,25,34749164243,1,8999);}
fn RevealEpochChart026(action){reveal_epoch_chart_action(action,26,91773502718,1,8999);}
fn RevealEpochChart027(action){reveal_epoch_chart_action(action,27,32363,1,8999);}
fn RevealEpochChart028(action){reveal_epoch_chart_action(action,28,9653396,1,8999);}
fn RevealEpochChart029(action){reveal_epoch_chart_action(action,29,96506,1,8999);}
fn RevealEpochChart030(action){reveal_epoch_chart_action(action,30,2619211,1,8999);}
fn RevealEpochChart031(action){reveal_epoch_chart_action(action,31,639351535,1,8999);}
fn RevealEpochChart032(action){reveal_epoch_chart_action(action,32,69632,1,8999);}
fn RevealEpochChart033(action){reveal_epoch_chart_action(action,33,541686600294,1,8999);}
fn RevealEpochChart034(action){reveal_epoch_chart_action(action,34,28380523638,1,8999);}
fn RevealEpochChart035(action){reveal_epoch_chart_action(action,35,76443315,1,8999);}
fn RevealEpochChart036(action){reveal_epoch_chart_action(action,36,15019,1,8999);}
fn RevealEpochChart037(action){reveal_epoch_chart_action(action,37,727359677350,1,8999);}
fn RevealEpochChart038(action){reveal_epoch_chart_action(action,38,1245300838,1,8999);}
fn RevealEpochChart039(action){reveal_epoch_chart_action(action,39,306588059046,1,8999);}
fn RevealEpochChart040(action){reveal_epoch_chart_action(action,40,958328413950,1,8999);}
fn RevealEpochChart041(action){reveal_epoch_chart_action(action,41,81694,1,8999);}
fn RevealEpochChart042(action){reveal_epoch_chart_action(action,42,1952318,1,8999);}
fn RevealEpochChart043(action){reveal_epoch_chart_action(action,43,6268530,1,8999);}
fn RevealEpochChart044(action){reveal_epoch_chart_action(action,44,6339973840,1,8999);}
fn RevealEpochChart045(action){reveal_epoch_chart_action(action,45,8542117,1,8999);}
fn RevealEpochChart046(action){reveal_epoch_chart_action(action,46,14120,1,8999);}
fn RevealEpochChart047(action){reveal_epoch_chart_action(action,47,628890961787,1,8999);}
fn RevealEpochChart048(action){reveal_epoch_chart_action(action,48,7844752,1,8999);}
fn RevealEpochChart049(action){reveal_epoch_chart_action(action,49,177377222,1,8999);}
fn RevealEpochChart050(action){reveal_epoch_chart_action(action,50,5042225,1,8999);}
fn RevealEpochChart051(action){reveal_epoch_chart_action(action,51,50517485774,1,8999);}
fn RevealEpochChart052(action){reveal_epoch_chart_action(action,52,85810,1,8999);}
fn RevealEpochChart053(action){reveal_epoch_chart_action(action,53,52108813889,1,8999);}
fn RevealEpochChart054(action){reveal_epoch_chart_action(action,54,759603399336,1,8999);}
fn RevealEpochChart055(action){reveal_epoch_chart_action(action,55,69638397119,1,8999);}
fn RevealEpochChart056(action){reveal_epoch_chart_action(action,56,565557523388,1,8999);}
fn RevealEpochChart057(action){reveal_epoch_chart_action(action,57,614770024389,1,8999);}
fn RevealEpochChart058(action){reveal_epoch_chart_action(action,58,52283646,1,8999);}
fn RevealEpochChart059(action){reveal_epoch_chart_action(action,59,897578268837,1,8999);}
fn RevealEpochChart060(action){reveal_epoch_chart_action(action,60,951423868361,1,8999);}
fn RevealEpochChart061(action){reveal_epoch_chart_action(action,61,8857506,1,8999);}
fn RevealEpochChart062(action){reveal_epoch_chart_action(action,62,95675,1,8999);}
fn RevealEpochChart063(action){reveal_epoch_chart_action(action,63,7608403,1,8999);}
fn RevealEpochChart064(action){reveal_epoch_chart_action(action,64,877592330068,1,8999);}
fn RevealEpochChart065(action){reveal_epoch_chart_action(action,65,675381993,1,8999);}
fn RevealEpochChart066(action){reveal_epoch_chart_action(action,66,919803293,1,8999);}
fn RevealEpochChart067(action){reveal_epoch_chart_action(action,67,251056901697,1,8999);}
fn RevealEpochChart068(action){reveal_epoch_chart_action(action,68,25773,1,8999);}
fn RevealEpochChart069(action){reveal_epoch_chart_action(action,69,366992367,1,8999);}
fn RevealEpochChart070(action){reveal_epoch_chart_action(action,70,86993,1,8999);}
fn RevealEpochChart071(action){reveal_epoch_chart_action(action,71,890123102542,1,8999);}
fn RevealEpochChart072(action){reveal_epoch_chart_action(action,72,870385314213,1,8999);}
fn RevealEpochChart073(action){reveal_epoch_chart_action(action,73,143643254,1,8999);}
fn RevealEpochChart074(action){reveal_epoch_chart_action(action,74,934700082078,1,8999);}
fn RevealEpochChart075(action){reveal_epoch_chart_action(action,75,1834,1,8999);}
fn RevealEpochChart076(action){reveal_epoch_chart_action(action,76,8998688,1,8999);}
fn RevealEpochChart077(action){reveal_epoch_chart_action(action,77,307151405,1,8999);}
fn RevealEpochChart078(action){reveal_epoch_chart_action(action,78,125223008,1,8999);}
fn RevealEpochChart079(action){reveal_epoch_chart_action(action,79,17857649955,1,8999);}
fn RevealEpochChart080(action){reveal_epoch_chart_action(action,80,20488948932,1,8999);}
fn RevealEpochChart081(action){reveal_epoch_chart_action(action,81,50734985484,1,8999);}
fn RevealEpochChart082(action){reveal_epoch_chart_action(action,82,200515222,1,8999);}
fn RevealEpochChart083(action){reveal_epoch_chart_action(action,83,3793358,1,8999);}
fn RevealEpochChart084(action){reveal_epoch_chart_action(action,84,636494815386,1,8999);}
fn RevealEpochChart085(action){reveal_epoch_chart_action(action,85,54190,1,8999);}
fn RevealEpochChart086(action){reveal_epoch_chart_action(action,86,93756271585,1,8999);}
fn RevealEpochChart087(action){reveal_epoch_chart_action(action,87,2763156,1,8999);}
fn RevealEpochChart088(action){reveal_epoch_chart_action(action,88,136739200270,1,8999);}
fn RevealEpochChart089(action){reveal_epoch_chart_action(action,89,978275968016,1,8999);}
fn RevealEpochChart090(action){reveal_epoch_chart_action(action,90,7281675,1,8999);}
fn RevealEpochChart091(action){reveal_epoch_chart_action(action,91,8418622,1,8999);}
fn RevealEpochChart092(action){reveal_epoch_chart_action(action,92,14089036231,1,8999);}
fn RevealEpochChart093(action){reveal_epoch_chart_action(action,93,7601984,1,8999);}
fn RevealEpochChart094(action){reveal_epoch_chart_action(action,94,744130328574,1,8999);}
fn RevealEpochChart095(action){reveal_epoch_chart_action(action,95,7497212,1,8999);}
fn RevealEpochChart096(action){reveal_epoch_chart_action(action,96,40613,1,8999);}
fn RevealEpochChart097(action){reveal_epoch_chart_action(action,97,386340836,1,8999);}
fn RevealEpochChart098(action){reveal_epoch_chart_action(action,98,94885551846,1,8999);}
fn RevealEpochChart099(action){reveal_epoch_chart_action(action,99,8619636781,1,8999);}
fn RevealEpochChart100(action){reveal_epoch_chart_action(action,100,971914324668,1,8999);}
fn RevealEpochChart101(action){reveal_epoch_chart_action(action,101,63379,1,8999);}
fn RevealEpochChart102(action){reveal_epoch_chart_action(action,102,81013880119,1,8999);}
fn RevealEpochChart103(action){reveal_epoch_chart_action(action,103,349847167,1,8999);}
fn RevealEpochChart104(action){reveal_epoch_chart_action(action,104,920759038,1,8999);}
fn RevealEpochChart105(action){reveal_epoch_chart_action(action,105,2528759,1,8999);}
fn RevealEpochChart106(action){reveal_epoch_chart_action(action,106,6000,1,8999);}
fn RevealEpochChart107(action){reveal_epoch_chart_action(action,107,97751341420,1,8999);}
fn RevealEpochChart108(action){reveal_epoch_chart_action(action,108,91340,1,8999);}
fn RevealEpochChart109(action){reveal_epoch_chart_action(action,109,898051108737,1,8999);}
fn RevealEpochChart110(action){reveal_epoch_chart_action(action,110,650213715,1,8999);}
fn RevealEpochChart111(action){reveal_epoch_chart_action(action,111,809451332161,1,8999);}
fn RevealEpochChart112(action){reveal_epoch_chart_action(action,112,914795591589,1,8999);}
fn RevealEpochChart113(action){reveal_epoch_chart_action(action,113,55174069405,1,8999);}
fn RevealEpochChart114(action){reveal_epoch_chart_action(action,114,385933580,1,8999);}
fn RevealEpochChart115(action){reveal_epoch_chart_action(action,115,159198535677,1,8999);}
fn RevealEpochChart116(action){reveal_epoch_chart_action(action,116,69134248920,1,8999);}
fn RevealEpochChart117(action){reveal_epoch_chart_action(action,117,7784182,1,8999);}
fn RevealEpochChart118(action){reveal_epoch_chart_action(action,118,4649408,1,8999);}
fn RevealEpochChart119(action){reveal_epoch_chart_action(action,119,14635237705,1,8999);}
fn RevealEpochChart120(action){reveal_epoch_chart_action(action,120,732302686947,1,8999);}
fn RevealEpochChart121(action){reveal_epoch_chart_action(action,121,3308627,1,8999);}
fn RevealEpochChart122(action){reveal_epoch_chart_action(action,122,9812920,1,8999);}
fn RevealEpochChart123(action){reveal_epoch_chart_action(action,123,450987877403,1,8999);}
fn RevealEpochChart124(action){reveal_epoch_chart_action(action,124,746992898006,1,8999);}
fn RevealEpochChart125(action){reveal_epoch_chart_action(action,125,719878203,1,8999);}
fn RevealEpochChart126(action){reveal_epoch_chart_action(action,126,812740620169,1,8999);}
fn RevealEpochChart127(action){reveal_epoch_chart_action(action,127,685958831907,1,8999);}
fn RevealEpochChart128(action){reveal_epoch_chart_action(action,128,995769685,1,8999);}
fn WarpShipToEpochCoordinateReusable(action){
var ship=action.mutate("microverse__ship");
var chart=action.mutate("microverse__epoch_chart");
prove_object_version_core(action,chart,"catalog_version");
action.st_sum(chart.revealed,0,1);
action.st_sum(ship.active_skill_type,0,58);
action.st_gt(chart.destination_epoch,100);
action.st_gt(1000000000000,chart.destination_epoch);
warp_ship_core(action,ship,ship.x,ship.y,ship.z,chart.destination_epoch);
consume_reusable_use_core(action,chart);
var work=action.intro_vdf(20,ship);
ship.update("work",work);
}
fn WarpShipToEpochCoordinateFinal(action){
var ship=action.mutate("microverse__ship");
var chart=action.input("microverse__epoch_chart");
prove_object_version_core(action,chart,"catalog_version");
action.st_sum(chart.revealed,0,1);
action.st_sum(ship.active_skill_type,0,58);
action.st_gt(chart.destination_epoch,100);
action.st_gt(1000000000000,chart.destination_epoch);
warp_ship_core(action,ship,ship.x,ship.y,ship.z,chart.destination_epoch);
consume_final_use_core(action,chart);
var work=action.intro_vdf(20,ship);
ship.update("work",work);
}
fn CapturePositionAnchor(action){
var ship=action.mutate("microverse__ship");
var anchor=action.output("microverse__position_anchor");
var material_1=action.input("microverse__resource");
var material_2=action.input("microverse__resource");
var source_ship_id=consume_prepared_ship_core(
action,ship,49
);
prove_resource_stack_core(action,material_1,415,1);
prove_resource_stack_core(action,material_2,419,1);
var ax=unsafe{ship.x-0};
var ay=unsafe{ship.y-0};
var az=unsafe{ship.z-0};
action.st_sum(ship.x,0,ax);
action.st_sum(ship.y,0,ay);
action.st_sum(ship.z,0,az);
anchor.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["anchor_version",2],
["source_ship_id",source_ship_id],
["x",ax],
["y",ay],
["z",az],
["uses_remaining",1]
]);
var work=action.intro_vdf(12,anchor);
anchor.update("work",work);
}
fn CaptureTimeAnchor(action){
var ship=action.mutate("microverse__ship");
var anchor=action.output("microverse__time_anchor");
var material_1=action.input("microverse__resource");
var material_2=action.input("microverse__resource");
var source_ship_id=consume_prepared_ship_core(
action,ship,60
);
prove_resource_stack_core(action,material_1,428,1);
prove_resource_stack_core(action,material_2,412,1);
var ae=unsafe{ship.epoch-0};
action.st_sum(ship.epoch,0,ae);
anchor.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["anchor_version",2],
["source_ship_id",source_ship_id],
["epoch",ae],
["uses_remaining",1]
]);
var work=action.intro_vdf(20,anchor);
anchor.update("work",work);
}
fn ConstructWormholeLink(action){
var link=action.output("microverse__wormhole_link");
let placeholder_identifier=action.top_limb_u256(0);
link.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["link_version",2],
["endpoint_a_anchor_identifier",placeholder_identifier],
["endpoint_a_x",0],
["endpoint_a_y",0],
["endpoint_a_z",0],
["endpoint_b_anchor_identifier",placeholder_identifier],
["endpoint_b_x",0],
["endpoint_b_y",0],
["endpoint_b_z",0],
["uses_remaining",3]
]);
var anchor_a=action.input("microverse__position_anchor");
prove_object_version_core(action,anchor_a,"anchor_version");
action.st_sum(anchor_a.uses_remaining,0,1);
var endpoint_a_x=unsafe{anchor_a.x-0};
action.st_sum(anchor_a.x,0,endpoint_a_x);
link.update("endpoint_a_x",endpoint_a_x);
var endpoint_a_y=unsafe{anchor_a.y-0};
action.st_sum(anchor_a.y,0,endpoint_a_y);
link.update("endpoint_a_y",endpoint_a_y);
var endpoint_a_z=unsafe{anchor_a.z-0};
action.st_sum(anchor_a.z,0,endpoint_a_z);
link.update("endpoint_a_z",endpoint_a_z);
var endpoint_a_anchor_identifier=action.random();
var_assign(endpoint_a_anchor_identifier,anchor_a.stable_identifier);
anchor_a.update("stable_identifier",endpoint_a_anchor_identifier);
link.update("endpoint_a_anchor_identifier",endpoint_a_anchor_identifier);
var anchor_b=action.input("microverse__position_anchor");
prove_object_version_core(action,anchor_b,"anchor_version");
action.st_sum(anchor_b.uses_remaining,0,1);
var endpoint_b_x=unsafe{anchor_b.x-0};
action.st_sum(anchor_b.x,0,endpoint_b_x);
link.update("endpoint_b_x",endpoint_b_x);
var endpoint_b_y=unsafe{anchor_b.y-0};
action.st_sum(anchor_b.y,0,endpoint_b_y);
link.update("endpoint_b_y",endpoint_b_y);
var endpoint_b_z=unsafe{anchor_b.z-0};
action.st_sum(anchor_b.z,0,endpoint_b_z);
link.update("endpoint_b_z",endpoint_b_z);
var endpoint_b_anchor_identifier=action.random();
var_assign(endpoint_b_anchor_identifier,anchor_b.stable_identifier);
anchor_b.update("stable_identifier",endpoint_b_anchor_identifier);
link.update("endpoint_b_anchor_identifier",endpoint_b_anchor_identifier);
var material_1=action.input("microverse__resource");
prove_resource_stack_core(action,material_1,432,1);
var material_2=action.input("microverse__resource");
prove_resource_stack_core(action,material_2,410,1);
var work=action.intro_vdf(32,link);
link.update("work",work);
var ship=action.mutate("microverse__ship");
prove_fixed_versions(action,ship);
action.st_sum(ship.active_skill_type,0,59);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_constructor_ship_key=action.random();
rotate_key(ship,next_constructor_ship_key);
}
fn ConstructTemporalLink(action){
var link=action.output("microverse__temporal_link");
let placeholder_identifier=action.top_limb_u256(0);
link.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["link_version",2],
["endpoint_a_anchor_identifier",placeholder_identifier],
["endpoint_a_epoch",0],
["endpoint_b_anchor_identifier",placeholder_identifier],
["endpoint_b_epoch",0],
["uses_remaining",3]
]);
var anchor_a=action.input("microverse__time_anchor");
prove_object_version_core(action,anchor_a,"anchor_version");
action.st_sum(anchor_a.uses_remaining,0,1);
var endpoint_a_epoch=unsafe{anchor_a.epoch-0};
action.st_sum(anchor_a.epoch,0,endpoint_a_epoch);
link.update("endpoint_a_epoch",endpoint_a_epoch);
var endpoint_a_anchor_identifier=action.random();
var_assign(endpoint_a_anchor_identifier,anchor_a.stable_identifier);
anchor_a.update("stable_identifier",endpoint_a_anchor_identifier);
link.update("endpoint_a_anchor_identifier",endpoint_a_anchor_identifier);
var anchor_b=action.input("microverse__time_anchor");
prove_object_version_core(action,anchor_b,"anchor_version");
action.st_sum(anchor_b.uses_remaining,0,1);
var endpoint_b_epoch=unsafe{anchor_b.epoch-0};
action.st_sum(anchor_b.epoch,0,endpoint_b_epoch);
link.update("endpoint_b_epoch",endpoint_b_epoch);
var endpoint_b_anchor_identifier=action.random();
var_assign(endpoint_b_anchor_identifier,anchor_b.stable_identifier);
anchor_b.update("stable_identifier",endpoint_b_anchor_identifier);
link.update("endpoint_b_anchor_identifier",endpoint_b_anchor_identifier);
var material_1=action.input("microverse__resource");
prove_resource_stack_core(action,material_1,412,1);
var material_2=action.input("microverse__resource");
prove_resource_stack_core(action,material_2,428,1);
var work=action.intro_vdf(32,link);
link.update("work",work);
var ship=action.mutate("microverse__ship");
prove_fixed_versions(action,ship);
action.st_sum(ship.active_skill_type,0,60);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_constructor_ship_key=action.random();
rotate_key(ship,next_constructor_ship_key);
}
fn TraverseWormholeAToBReusable(action){
var ship=action.mutate("microverse__ship");
var link=action.mutate("microverse__wormhole_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,59);
var source_x=unsafe{link.endpoint_a_x-0};
action.st_sum(link.endpoint_a_x,0,source_x);
action.st_sum(ship.x,0,source_x);
var source_y=unsafe{link.endpoint_a_y-0};
action.st_sum(link.endpoint_a_y,0,source_y);
action.st_sum(ship.y,0,source_y);
var source_z=unsafe{link.endpoint_a_z-0};
action.st_sum(link.endpoint_a_z,0,source_z);
action.st_sum(ship.z,0,source_z);
warp_ship_core(action,ship,link.endpoint_b_x,link.endpoint_b_y,link.endpoint_b_z,ship.epoch);
consume_reusable_use_core(action,link);
var work=action.intro_vdf(20,ship);
ship.update("work",work);
}
fn TraverseWormholeAToBFinal(action){
var ship=action.mutate("microverse__ship");
var link=action.input("microverse__wormhole_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,59);
var source_x=unsafe{link.endpoint_a_x-0};
action.st_sum(link.endpoint_a_x,0,source_x);
action.st_sum(ship.x,0,source_x);
var source_y=unsafe{link.endpoint_a_y-0};
action.st_sum(link.endpoint_a_y,0,source_y);
action.st_sum(ship.y,0,source_y);
var source_z=unsafe{link.endpoint_a_z-0};
action.st_sum(link.endpoint_a_z,0,source_z);
action.st_sum(ship.z,0,source_z);
warp_ship_core(action,ship,link.endpoint_b_x,link.endpoint_b_y,link.endpoint_b_z,ship.epoch);
consume_final_use_core(action,link);
var work=action.intro_vdf(20,ship);
ship.update("work",work);
}
fn TraverseWormholeBToAReusable(action){
var ship=action.mutate("microverse__ship");
var link=action.mutate("microverse__wormhole_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,59);
var source_x=unsafe{link.endpoint_b_x-0};
action.st_sum(link.endpoint_b_x,0,source_x);
action.st_sum(ship.x,0,source_x);
var source_y=unsafe{link.endpoint_b_y-0};
action.st_sum(link.endpoint_b_y,0,source_y);
action.st_sum(ship.y,0,source_y);
var source_z=unsafe{link.endpoint_b_z-0};
action.st_sum(link.endpoint_b_z,0,source_z);
action.st_sum(ship.z,0,source_z);
warp_ship_core(action,ship,link.endpoint_a_x,link.endpoint_a_y,link.endpoint_a_z,ship.epoch);
consume_reusable_use_core(action,link);
var work=action.intro_vdf(20,ship);
ship.update("work",work);
}
fn TraverseWormholeBToAFinal(action){
var ship=action.mutate("microverse__ship");
var link=action.input("microverse__wormhole_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,59);
var source_x=unsafe{link.endpoint_b_x-0};
action.st_sum(link.endpoint_b_x,0,source_x);
action.st_sum(ship.x,0,source_x);
var source_y=unsafe{link.endpoint_b_y-0};
action.st_sum(link.endpoint_b_y,0,source_y);
action.st_sum(ship.y,0,source_y);
var source_z=unsafe{link.endpoint_b_z-0};
action.st_sum(link.endpoint_b_z,0,source_z);
action.st_sum(ship.z,0,source_z);
warp_ship_core(action,ship,link.endpoint_a_x,link.endpoint_a_y,link.endpoint_a_z,ship.epoch);
consume_final_use_core(action,link);
var work=action.intro_vdf(20,ship);
ship.update("work",work);
}
fn TraverseTemporalAToBReusable(action){
var ship=action.mutate("microverse__ship");
var link=action.mutate("microverse__temporal_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,60);
var source_epoch=unsafe{link.endpoint_a_epoch-0};
action.st_sum(link.endpoint_a_epoch,0,source_epoch);
action.st_sum(ship.epoch,0,source_epoch);
warp_ship_core(action,ship,ship.x,ship.y,ship.z,link.endpoint_b_epoch);
consume_reusable_use_core(action,link);
var work=action.intro_vdf(20,ship);
ship.update("work",work);
}
fn TraverseTemporalAToBFinal(action){
var ship=action.mutate("microverse__ship");
var link=action.input("microverse__temporal_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,60);
var source_epoch=unsafe{link.endpoint_a_epoch-0};
action.st_sum(link.endpoint_a_epoch,0,source_epoch);
action.st_sum(ship.epoch,0,source_epoch);
warp_ship_core(action,ship,ship.x,ship.y,ship.z,link.endpoint_b_epoch);
consume_final_use_core(action,link);
var work=action.intro_vdf(20,ship);
ship.update("work",work);
}
fn TraverseTemporalBToAReusable(action){
var ship=action.mutate("microverse__ship");
var link=action.mutate("microverse__temporal_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,60);
var source_epoch=unsafe{link.endpoint_b_epoch-0};
action.st_sum(link.endpoint_b_epoch,0,source_epoch);
action.st_sum(ship.epoch,0,source_epoch);
warp_ship_core(action,ship,ship.x,ship.y,ship.z,link.endpoint_a_epoch);
consume_reusable_use_core(action,link);
var work=action.intro_vdf(20,ship);
ship.update("work",work);
}
fn TraverseTemporalBToAFinal(action){
var ship=action.mutate("microverse__ship");
var link=action.input("microverse__temporal_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,60);
var source_epoch=unsafe{link.endpoint_b_epoch-0};
action.st_sum(link.endpoint_b_epoch,0,source_epoch);
action.st_sum(ship.epoch,0,source_epoch);
warp_ship_core(action,ship,ship.x,ship.y,ship.z,link.endpoint_a_epoch);
consume_final_use_core(action,link);
var work=action.intro_vdf(20,ship);
ship.update("work",work);
}
fn ComposeRendezvousCoordinate(action){
var coordinate=action.output("microverse__rendezvous_coordinate");
let placeholder_identifier=action.top_limb_u256(0);
coordinate.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["coordinate_version",2],
["position_anchor_identifier",placeholder_identifier],
["destination_x",0],
["destination_y",0],
["destination_z",0],
["time_anchor_identifier",placeholder_identifier],
["destination_epoch",0],
["uses_remaining",3]
]);
var position_anchor=action.input("microverse__position_anchor");
prove_object_version_core(action,position_anchor,"anchor_version");
action.st_sum(position_anchor.uses_remaining,0,1);
var destination_x=unsafe{position_anchor.x-0};
action.st_sum(position_anchor.x,0,destination_x);
coordinate.update("destination_x",destination_x);
var destination_y=unsafe{position_anchor.y-0};
action.st_sum(position_anchor.y,0,destination_y);
coordinate.update("destination_y",destination_y);
var destination_z=unsafe{position_anchor.z-0};
action.st_sum(position_anchor.z,0,destination_z);
coordinate.update("destination_z",destination_z);
var position_anchor_identifier=action.random();
var_assign(position_anchor_identifier,position_anchor.stable_identifier);
position_anchor.update("stable_identifier",position_anchor_identifier);
coordinate.update("position_anchor_identifier",position_anchor_identifier);
var time_anchor=action.input("microverse__time_anchor");
prove_object_version_core(action,time_anchor,"anchor_version");
action.st_sum(time_anchor.uses_remaining,0,1);
var destination_epoch=unsafe{time_anchor.epoch-0};
action.st_sum(time_anchor.epoch,0,destination_epoch);
coordinate.update("destination_epoch",destination_epoch);
var time_anchor_identifier=action.random();
var_assign(time_anchor_identifier,time_anchor.stable_identifier);
time_anchor.update("stable_identifier",time_anchor_identifier);
coordinate.update("time_anchor_identifier",time_anchor_identifier);
var material_1=action.input("microverse__resource");
prove_resource_stack_core(action,material_1,426,1);
var material_2=action.input("microverse__resource");
prove_resource_stack_core(action,material_2,413,1);
var work=action.intro_vdf(32,coordinate);
coordinate.update("work",work);
var ship=action.mutate("microverse__ship");
prove_fixed_versions(action,ship);
action.st_sum(ship.active_skill_type,0,86);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_constructor_ship_key=action.random();
rotate_key(ship,next_constructor_ship_key);
}
fn WarpToRendezvousCoordinateReusable(action){
var ship=action.mutate("microverse__ship");
var coordinate=action.mutate("microverse__rendezvous_coordinate");
prove_object_version_core(action,coordinate,"coordinate_version");
action.st_sum(ship.active_skill_type,0,86);
warp_ship_core(
action,
ship,
coordinate.destination_x,
coordinate.destination_y,
coordinate.destination_z,
coordinate.destination_epoch
);
consume_reusable_use_core(action,coordinate);
var work=action.intro_vdf(32,ship);
ship.update("work",work);
}
fn WarpToRendezvousCoordinateFinal(action){
var ship=action.mutate("microverse__ship");
var coordinate=action.input("microverse__rendezvous_coordinate");
prove_object_version_core(action,coordinate,"coordinate_version");
action.st_sum(ship.active_skill_type,0,86);
warp_ship_core(
action,
ship,
coordinate.destination_x,
coordinate.destination_y,
coordinate.destination_z,
coordinate.destination_epoch
);
consume_final_use_core(action,coordinate);
var work=action.intro_vdf(32,ship);
ship.update("work",work);
}
// Basic resource extraction
fn ExtractMatter(action){extract_base_action(action,8,0,"matter_remaining",1,10,1);}
fn ExtractMatterMedium(action){extract_base_action(action,8,0,"matter_remaining",1,50,5);}
fn ExtractMatterLarge(action){extract_base_action(action,8,0,"matter_remaining",1,250,25);}
fn ExtractCrystal(action){extract_base_action(action,8,0,"crystal_remaining",2,10,1);}
fn ExtractCrystalMedium(action){extract_base_action(action,8,0,"crystal_remaining",2,50,5);}
fn ExtractCrystalLarge(action){extract_base_action(action,8,0,"crystal_remaining",2,250,25);}
fn ExtractGas(action){extract_base_action(action,2,0,"gas_remaining",3,10,1);}
fn ExtractGasMedium(action){extract_base_action(action,2,0,"gas_remaining",3,50,5);}
fn ExtractGasLarge(action){extract_base_action(action,2,0,"gas_remaining",3,250,25);}
fn ExtractEnergy(action){extract_base_action(action,4,0,"energy_remaining",4,10,1);}
fn ExtractEnergyMedium(action){extract_base_action(action,4,0,"energy_remaining",4,50,5);}
fn ExtractEnergyLarge(action){extract_base_action(action,4,0,"energy_remaining",4,250,25);}
// Satellites, life, and civilizations
fn DiscoverSatellite(action){
var ship=action.mutate("microverse__ship");
var satellite=action.output("microverse__satellite");
var body=action.mutate("microverse__celestial_body");
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
action.st_sum(ship.x,0,body.sector_x);
action.st_sum(ship.y,0,body.sector_y);
action.st_sum(ship.z,0,body.sector_z);
action.st_sum(ship.epoch,0,body.sector_epoch);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
var next_ship_satellite_serial=unsafe{ship.satellite_serial-(0-1)};
action.st_sum(ship.satellite_serial,1,next_ship_satellite_serial);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
ship.update("satellite_serial",next_ship_satellite_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
action.st_gt(body.satellites_remaining,0);
var next_remaining=unsafe{body.satellites_remaining-1};
action.st_sum(next_remaining,1,body.satellites_remaining);
var next_satellite_serial=unsafe{body.next_satellite_serial-(0-1)};
action.st_sum(body.next_satellite_serial,1,next_satellite_serial);
var parent_body_identifier=action.random();
var_assign(parent_body_identifier,body.stable_identifier);
body.update("stable_identifier",parent_body_identifier);
satellite.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["parent_body_identifier",parent_body_identifier],
["sector_x",ship.x],
["sector_y",ship.y],
["sector_z",ship.z],
["sector_epoch",ship.epoch],
["satellite_serial",next_satellite_serial]
]);
let zero=action.top_limb_u256(0);
satellite.update("key",zero);
body.update("satellites_remaining",next_remaining);
body.update("next_satellite_serial",next_satellite_serial);
var next_body_key=action.random();
rotate_key(body,next_body_key);
}
fn DetectIntelligentLife(action){
var ship=action.mutate("microverse__ship");
var life_signal=action.output("microverse__life_signal");
var body=action.mutate("microverse__celestial_body");
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
action.st_sum(ship.x,0,body.sector_x);
action.st_sum(ship.y,0,body.sector_y);
action.st_sum(ship.z,0,body.sector_z);
action.st_sum(ship.epoch,0,body.sector_epoch);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
var next_scan_serial=unsafe{ship.civilization_scan_serial-(0-1)};
action.st_sum(ship.civilization_scan_serial,1,next_scan_serial);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
ship.update("civilization_scan_serial",next_scan_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
let life_selector_lower=action.top_limb_u256(8974091709444932912);
action.intro_lt_eq_u256(life_selector_lower,body.source_signal_identifier);
let life_selector_upper=action.top_limb_u256(-8226250737952822467);
action.intro_lt_eq_u256(body.source_signal_identifier,life_selector_upper);
action.st_sum(body.body_type,0,1);
action.st_sum(body.life_stat,0,0);
action.st_sum(body.civilization_discovered,0,0);
var source_body_identifier=action.random();
var_assign(source_body_identifier,body.stable_identifier);
body.update("stable_identifier",source_body_identifier);
life_signal.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["civilization_version",2],
["source_body_identifier",source_body_identifier],
["sector_x",ship.x],
["sector_y",ship.y],
["sector_z",ship.z],
["origin_epoch",ship.epoch]
]);
let zero=action.top_limb_u256(0);
life_signal.update("key",zero);
body.update("life_stat",1);
body.update("civilization_discovered",1);
var next_body_key=action.random();
rotate_key(body,next_body_key);
}
fn MaterializeCivilizationTypeI(action){
var civilization=action.output("microverse__civilization");
var life_signal=action.input("microverse__life_signal");
var ship=action.mutate("microverse__ship");
let civilization_selector_upper=action.top_limb_u256(-1148698352939831522);
action.intro_lt_eq_u256(life_signal,civilization_selector_upper);
prove_fixed_versions(action,life_signal);
prove_fixed_versions(action,ship);
action.st_sum(life_signal.civilization_version,0,2);
var sector_x=unsafe{life_signal.sector_x-0};
var sector_y=unsafe{life_signal.sector_y-0};
var sector_z=unsafe{life_signal.sector_z-0};
var origin_epoch=unsafe{life_signal.origin_epoch-0};
action.st_sum(life_signal.sector_x,0,sector_x);
action.st_sum(life_signal.sector_y,0,sector_y);
action.st_sum(life_signal.sector_z,0,sector_z);
action.st_sum(life_signal.origin_epoch,0,origin_epoch);
action.st_sum(ship.x,0,sector_x);
action.st_sum(ship.y,0,sector_y);
action.st_sum(ship.z,0,sector_z);
action.st_sum(ship.epoch,0,origin_epoch);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
var source_life_signal_identifier=action.random();
var_assign(
source_life_signal_identifier,
life_signal.stable_identifier
);
life_signal.update(
"stable_identifier",
source_life_signal_identifier
);
civilization.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["civilization_version",2],
["source_life_signal_identifier",source_life_signal_identifier],
["sector_x",sector_x],
["sector_y",sector_y],
["sector_z",sector_z],
["origin_epoch",origin_epoch],
["civilization_type",1]
]);
let zero=action.top_limb_u256(0);
civilization.update("key",zero);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn MaterializeCivilizationTypeII(action){
var civilization=action.output("microverse__civilization");
var life_signal=action.input("microverse__life_signal");
var ship=action.mutate("microverse__ship");
let civilization_selector_lower=action.top_limb_u256(-1148698352939831521);
action.intro_lt_eq_u256(civilization_selector_lower,life_signal);
let civilization_selector_upper=action.top_limb_u256(-67570495391724016);
action.intro_lt_eq_u256(life_signal,civilization_selector_upper);
prove_fixed_versions(action,life_signal);
prove_fixed_versions(action,ship);
action.st_sum(life_signal.civilization_version,0,2);
var sector_x=unsafe{life_signal.sector_x-0};
var sector_y=unsafe{life_signal.sector_y-0};
var sector_z=unsafe{life_signal.sector_z-0};
var origin_epoch=unsafe{life_signal.origin_epoch-0};
action.st_sum(life_signal.sector_x,0,sector_x);
action.st_sum(life_signal.sector_y,0,sector_y);
action.st_sum(life_signal.sector_z,0,sector_z);
action.st_sum(life_signal.origin_epoch,0,origin_epoch);
action.st_sum(ship.x,0,sector_x);
action.st_sum(ship.y,0,sector_y);
action.st_sum(ship.z,0,sector_z);
action.st_sum(ship.epoch,0,origin_epoch);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
var source_life_signal_identifier=action.random();
var_assign(
source_life_signal_identifier,
life_signal.stable_identifier
);
life_signal.update(
"stable_identifier",
source_life_signal_identifier
);
civilization.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["civilization_version",2],
["source_life_signal_identifier",source_life_signal_identifier],
["sector_x",sector_x],
["sector_y",sector_y],
["sector_z",sector_z],
["origin_epoch",origin_epoch],
["civilization_type",2]
]);
let zero=action.top_limb_u256(0);
civilization.update("key",zero);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn MaterializeCivilizationTypeIII(action){
var civilization=action.output("microverse__civilization");
var life_signal=action.input("microverse__life_signal");
var ship=action.mutate("microverse__ship");
let civilization_selector_lower=action.top_limb_u256(-67570495391724015);
action.intro_lt_eq_u256(civilization_selector_lower,life_signal);
prove_fixed_versions(action,life_signal);
prove_fixed_versions(action,ship);
action.st_sum(life_signal.civilization_version,0,2);
var sector_x=unsafe{life_signal.sector_x-0};
var sector_y=unsafe{life_signal.sector_y-0};
var sector_z=unsafe{life_signal.sector_z-0};
var origin_epoch=unsafe{life_signal.origin_epoch-0};
action.st_sum(life_signal.sector_x,0,sector_x);
action.st_sum(life_signal.sector_y,0,sector_y);
action.st_sum(life_signal.sector_z,0,sector_z);
action.st_sum(life_signal.origin_epoch,0,origin_epoch);
action.st_sum(ship.x,0,sector_x);
action.st_sum(ship.y,0,sector_y);
action.st_sum(ship.z,0,sector_z);
action.st_sum(ship.epoch,0,origin_epoch);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
var source_life_signal_identifier=action.random();
var_assign(
source_life_signal_identifier,
life_signal.stable_identifier
);
life_signal.update(
"stable_identifier",
source_life_signal_identifier
);
civilization.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["civilization_version",2],
["source_life_signal_identifier",source_life_signal_identifier],
["sector_x",sector_x],
["sector_y",sector_y],
["sector_z",sector_z],
["origin_epoch",origin_epoch],
["civilization_type",3]
]);
let zero=action.top_limb_u256(0);
civilization.update("key",zero);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
// Resource extraction and refinement
fn ExtractRedDwarfFusionGas(action){extract_composite_ungated_action(action,12,0,8,"gas_remaining",119,50,5,30,15,5);}
fn ExtractRedDwarfFusionGasLarge(action){extract_composite_ungated_action(action,12,0,8,"gas_remaining",119,250,25,150,75,25);}
fn ExtractRedDwarfMetalRichOre(action){extract_composite_ungated_action(action,12,0,16,"matter_remaining",120,50,5,45,4,1);}
fn ExtractRedDwarfMetalRichOreLarge(action){extract_composite_ungated_action(action,12,0,16,"matter_remaining",120,250,25,225,20,5);}
fn ExtractRedDwarfRadiantEnergy(action){extract_direct_upper_action(action,6148914689804861439,4,0,8,"energy_remaining",121,50,5);}
fn ExtractRedDwarfRadiantEnergyLarge(action){extract_direct_upper_action(action,6148914689804861439,4,0,8,"energy_remaining",121,250,25);}
fn ExtractRedDwarfRedDwarfPlasma(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,12,0,8,"energy_remaining",223,50,5,30,15,5);}
fn ExtractRedDwarfRedDwarfPlasmaLarge(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,12,0,8,"energy_remaining",223,250,25,150,75,25);}
fn ExtractRedDwarfMagneticStellarCondensate(action){extract_composite_upper_action(action,9223372034707292159,12,0,7,"matter_remaining",224,50,5,35,10,5);}
fn ExtractRedDwarfMagneticStellarCondensateLarge(action){extract_composite_upper_action(action,9223372034707292159,12,0,7,"matter_remaining",224,250,25,175,50,25);}
fn ExtractRedDwarfFlareSpectrumData(action){extract_direct_lower_action(action,-6148914694099828736,12,0,8,"energy_remaining",225,50,5);}
fn ExtractRedDwarfFlareSpectrumDataLarge(action){extract_direct_lower_action(action,-6148914694099828736,12,0,8,"energy_remaining",225,250,25);}
fn ExtractRedDwarfStellarRefractoryDust(action){extract_composite_lower_action(action,9223372034707292160,12,0,7,"matter_remaining",336,50,5,35,10,5);}
fn ExtractRedDwarfStellarRefractoryDustLarge(action){extract_composite_lower_action(action,9223372034707292160,12,0,7,"matter_remaining",336,250,25,175,50,25);}
fn ExtractMainSequenceStarFusionGas(action){extract_composite_ungated_action(action,12,1,8,"gas_remaining",119,50,5,30,15,5);}
fn ExtractMainSequenceStarFusionGasLarge(action){extract_composite_ungated_action(action,12,1,8,"gas_remaining",119,250,25,150,75,25);}
fn ExtractMainSequenceStarMetalRichOre(action){extract_composite_ungated_action(action,12,1,16,"matter_remaining",120,50,5,45,4,1);}
fn ExtractMainSequenceStarMetalRichOreLarge(action){extract_composite_ungated_action(action,12,1,16,"matter_remaining",120,250,25,225,20,5);}
fn ExtractMainSequenceStarRadiantEnergy(action){extract_direct_upper_action(action,6148914689804861439,4,1,8,"energy_remaining",121,50,5);}
fn ExtractMainSequenceStarRadiantEnergyLarge(action){extract_direct_upper_action(action,6148914689804861439,4,1,8,"energy_remaining",121,250,25);}
fn ExtractMainSequenceStarPhotosphericPlasma(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,12,1,8,"energy_remaining",226,50,5,30,15,5);}
fn ExtractMainSequenceStarPhotosphericPlasmaLarge(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,12,1,8,"energy_remaining",226,250,25,150,75,25);}
fn ExtractMainSequenceStarPhotosphericMineral(action){extract_composite_ungated_action(action,12,1,8,"matter_remaining",227,50,5,35,10,5);}
fn ExtractMainSequenceStarPhotosphericMineralLarge(action){extract_composite_ungated_action(action,12,1,8,"matter_remaining",227,250,25,175,50,25);}
fn ExtractMainSequenceStarStellarSpectrumData(action){extract_direct_lower_action(action,-6148914694099828736,12,1,8,"energy_remaining",228,50,5);}
fn ExtractMainSequenceStarStellarSpectrumDataLarge(action){extract_direct_lower_action(action,-6148914694099828736,12,1,8,"energy_remaining",228,250,25);}
fn ExtractMainSequenceStarSolarWindCondensate(action){extract_composite_ungated_action(action,12,1,4,"matter_remaining",337,50,5,30,15,5);}
fn ExtractMainSequenceStarSolarWindCondensateLarge(action){extract_composite_ungated_action(action,12,1,4,"matter_remaining",337,250,25,150,75,25);}
fn ExtractGiantStarFusionGas(action){extract_composite_ungated_action(action,12,2,8,"gas_remaining",119,50,5,30,15,5);}
fn ExtractGiantStarFusionGasLarge(action){extract_composite_ungated_action(action,12,2,8,"gas_remaining",119,250,25,150,75,25);}
fn ExtractGiantStarMetalRichOre(action){extract_composite_upper_action(action,6148914689804861439,12,2,16,"matter_remaining",120,50,5,45,4,1);}
fn ExtractGiantStarMetalRichOreLarge(action){extract_composite_upper_action(action,6148914689804861439,12,2,16,"matter_remaining",120,250,25,225,20,5);}
fn ExtractGiantStarRadiantEnergy(action){extract_direct_ungated_action(action,4,2,8,"energy_remaining",121,50,5);}
fn ExtractGiantStarRadiantEnergyLarge(action){extract_direct_ungated_action(action,4,2,8,"energy_remaining",121,250,25);}
fn ExtractGiantStarHeliumCarbonEjecta(action){extract_composite_ungated_action(action,12,2,16,"gas_remaining",229,50,5,25,15,10);}
fn ExtractGiantStarHeliumCarbonEjectaLarge(action){extract_composite_ungated_action(action,12,2,16,"gas_remaining",229,250,25,125,75,50);}
fn ExtractGiantStarHeavyElementCondensate(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,12,2,16,"matter_remaining",230,50,5,30,15,5);}
fn ExtractGiantStarHeavyElementCondensateLarge(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,12,2,16,"matter_remaining",230,250,25,150,75,25);}
fn ExtractGiantStarNeutrinoData(action){extract_direct_ungated_action(action,12,2,16,"energy_remaining",231,50,5);}
fn ExtractGiantStarNeutrinoDataLarge(action){extract_direct_ungated_action(action,12,2,16,"energy_remaining",231,250,25);}
fn ExtractGiantStarSProcessEjecta(action){extract_composite_lower_action(action,-6148914694099828736,12,2,16,"matter_remaining",338,50,5,30,15,5);}
fn ExtractGiantStarSProcessEjectaLarge(action){extract_composite_lower_action(action,-6148914694099828736,12,2,16,"matter_remaining",338,250,25,150,75,25);}
fn ExtractRockyPlanetFerrousOre(action){extract_composite_upper_action(action,3074457344902430719,8,3,0,"matter_remaining",122,10,1,7,2,1);}
fn ExtractRockyPlanetFerrousOreMedium(action){extract_composite_upper_action(action,3074457344902430719,8,3,0,"matter_remaining",122,50,5,35,10,5);}
fn ExtractRockyPlanetFerrousOreLarge(action){extract_composite_upper_action(action,3074457344902430719,8,3,0,"matter_remaining",122,250,25,175,50,25);}
fn ExtractRockyPlanetBaseMetalOre(action){extract_composite_range_action(action,3074457344902430720,6148914689804861439,8,3,0,"matter_remaining",123,10,1,7,2,1);}
fn ExtractRockyPlanetBaseMetalOreMedium(action){extract_composite_range_action(action,3074457344902430720,6148914689804861439,8,3,0,"matter_remaining",123,50,5,35,10,5);}
fn ExtractRockyPlanetBaseMetalOreLarge(action){extract_composite_range_action(action,3074457344902430720,6148914689804861439,8,3,0,"matter_remaining",123,250,25,175,50,25);}
fn ExtractRockyPlanetSilicateMineral(action){extract_composite_range_action(action,6148914689804861440,9223372034707292159,8,3,0,"matter_remaining",124,10,1,7,2,1);}
fn ExtractRockyPlanetSilicateMineralMedium(action){extract_composite_range_action(action,6148914689804861440,9223372034707292159,8,3,0,"matter_remaining",124,50,5,35,10,5);}
fn ExtractRockyPlanetSilicateMineralLarge(action){extract_composite_range_action(action,6148914689804861440,9223372034707292159,8,3,0,"matter_remaining",124,250,25,175,50,25);}
fn ExtractRockyPlanetIndustrialMineral(action){extract_composite_range_action(action,9223372034707292160,-6148914694099828737,8,3,0,"matter_remaining",125,10,1,7,2,1);}
fn ExtractRockyPlanetIndustrialMineralMedium(action){extract_composite_range_action(action,9223372034707292160,-6148914694099828737,8,3,0,"matter_remaining",125,50,5,35,10,5);}
fn ExtractRockyPlanetIndustrialMineralLarge(action){extract_composite_range_action(action,9223372034707292160,-6148914694099828737,8,3,0,"matter_remaining",125,250,25,175,50,25);}
fn ExtractRockyPlanetIgneousRock(action){extract_composite_range_action(action,-6148914694099828736,-3074457349197398017,8,3,0,"matter_remaining",232,10,1,6,3,1);}
fn ExtractRockyPlanetIgneousRockMedium(action){extract_composite_range_action(action,-6148914694099828736,-3074457349197398017,8,3,0,"matter_remaining",232,50,5,30,15,5);}
fn ExtractRockyPlanetIgneousRockLarge(action){extract_composite_range_action(action,-6148914694099828736,-3074457349197398017,8,3,0,"matter_remaining",232,250,25,150,75,25);}
fn ExtractRockyPlanetGeothermalEnergy(action){extract_direct_ungated_action(action,4,3,0,"energy_remaining",233,10,1);}
fn ExtractRockyPlanetGeothermalEnergyMedium(action){extract_direct_ungated_action(action,4,3,0,"energy_remaining",233,50,5);}
fn ExtractRockyPlanetGeothermalEnergyLarge(action){extract_direct_ungated_action(action,4,3,0,"energy_remaining",233,250,25);}
fn ExtractRockyPlanetSedimentaryRock(action){extract_composite_lower_action(action,-3074457349197398016,8,3,0,"matter_remaining",339,10,1,7,2,1);}
fn ExtractRockyPlanetSedimentaryRockMedium(action){extract_composite_lower_action(action,-3074457349197398016,8,3,0,"matter_remaining",339,50,5,35,10,5);}
fn ExtractRockyPlanetSedimentaryRockLarge(action){extract_composite_lower_action(action,-3074457349197398016,8,3,0,"matter_remaining",339,250,25,175,50,25);}
fn ExtractOceanPlanetWater(action){extract_direct_upper_action(action,6148914689804861439,2,4,0,"matter_remaining",126,10,1);}
fn ExtractOceanPlanetWaterMedium(action){extract_direct_upper_action(action,6148914689804861439,2,4,0,"matter_remaining",126,50,5);}
fn ExtractOceanPlanetWaterLarge(action){extract_direct_upper_action(action,6148914689804861439,2,4,0,"matter_remaining",126,250,25);}
fn ExtractOceanPlanetSeawaterMinerals(action){extract_composite_upper_action(action,9223372034707292159,4,4,0,"crystal_remaining",127,10,1,7,2,1);}
fn ExtractOceanPlanetSeawaterMineralsMedium(action){extract_composite_upper_action(action,9223372034707292159,4,4,0,"crystal_remaining",127,50,5,35,10,5);}
fn ExtractOceanPlanetSeawaterMineralsLarge(action){extract_composite_upper_action(action,9223372034707292159,4,4,0,"crystal_remaining",127,250,25,175,50,25);}
fn ExtractOceanPlanetAtmosphericGas(action){extract_composite_ungated_action(action,2,4,0,"gas_remaining",128,10,1,5,3,2);}
fn ExtractOceanPlanetAtmosphericGasMedium(action){extract_composite_ungated_action(action,2,4,0,"gas_remaining",128,50,5,25,15,10);}
fn ExtractOceanPlanetAtmosphericGasLarge(action){extract_composite_ungated_action(action,2,4,0,"gas_remaining",128,250,25,125,75,50);}
fn ExtractOceanPlanetSeafloorSulfideOre(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,8,4,0,"matter_remaining",234,10,1,7,2,1);}
fn ExtractOceanPlanetSeafloorSulfideOreMedium(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,8,4,0,"matter_remaining",234,50,5,35,10,5);}
fn ExtractOceanPlanetSeafloorSulfideOreLarge(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,8,4,0,"matter_remaining",234,250,25,175,50,25);}
fn ExtractOceanPlanetMarineBiomass(action){extract_composite_lower_action(action,-6148914694099828736,4,4,0,"matter_remaining",235,10,1,5,3,2);}
fn ExtractOceanPlanetMarineBiomassMedium(action){extract_composite_lower_action(action,-6148914694099828736,4,4,0,"matter_remaining",235,50,5,25,15,10);}
fn ExtractOceanPlanetMarineBiomassLarge(action){extract_composite_lower_action(action,-6148914694099828736,4,4,0,"matter_remaining",235,250,25,125,75,50);}
fn ExtractOceanPlanetTidalEnergy(action){extract_direct_ungated_action(action,4,4,0,"energy_remaining",236,10,1);}
fn ExtractOceanPlanetTidalEnergyMedium(action){extract_direct_ungated_action(action,4,4,0,"energy_remaining",236,50,5);}
fn ExtractOceanPlanetTidalEnergyLarge(action){extract_direct_ungated_action(action,4,4,0,"energy_remaining",236,250,25);}
fn ExtractOceanPlanetDissolvedTraceMinerals(action){extract_composite_lower_action(action,9223372034707292160,4,4,0,"crystal_remaining",340,10,1,7,2,1);}
fn ExtractOceanPlanetDissolvedTraceMineralsMedium(action){extract_composite_lower_action(action,9223372034707292160,4,4,0,"crystal_remaining",340,50,5,35,10,5);}
fn ExtractOceanPlanetDissolvedTraceMineralsLarge(action){extract_composite_lower_action(action,9223372034707292160,4,4,0,"crystal_remaining",340,250,25,175,50,25);}
fn ExtractGardenPlanetBiomass(action){extract_composite_upper_action(action,4611686017353646079,4,5,0,"matter_remaining",129,10,1,5,3,2);}
fn ExtractGardenPlanetBiomassMedium(action){extract_composite_upper_action(action,4611686017353646079,4,5,0,"matter_remaining",129,50,5,25,15,10);}
fn ExtractGardenPlanetBiomassLarge(action){extract_composite_upper_action(action,4611686017353646079,4,5,0,"matter_remaining",129,250,25,125,75,50);}
fn ExtractGardenPlanetGeneticMaterial(action){extract_composite_range_action(action,4611686017353646080,9223372034707292159,8,5,0,"matter_remaining",130,10,1,5,3,2);}
fn ExtractGardenPlanetGeneticMaterialMedium(action){extract_composite_range_action(action,4611686017353646080,9223372034707292159,8,5,0,"matter_remaining",130,50,5,25,15,10);}
fn ExtractGardenPlanetGeneticMaterialLarge(action){extract_composite_range_action(action,4611686017353646080,9223372034707292159,8,5,0,"matter_remaining",130,250,25,125,75,50);}
fn ExtractGardenPlanetBiochemicalMixture(action){extract_composite_ungated_action(action,4,5,0,"gas_remaining",131,10,1,5,3,2);}
fn ExtractGardenPlanetBiochemicalMixtureMedium(action){extract_composite_ungated_action(action,4,5,0,"gas_remaining",131,50,5,25,15,10);}
fn ExtractGardenPlanetBiochemicalMixtureLarge(action){extract_composite_ungated_action(action,4,5,0,"gas_remaining",131,250,25,125,75,50);}
fn ExtractGardenPlanetMicrobialCulture(action){extract_composite_range_action(action,9223372034707292160,-4611686021648613377,8,5,0,"matter_remaining",132,10,1,5,3,2);}
fn ExtractGardenPlanetMicrobialCultureMedium(action){extract_composite_range_action(action,9223372034707292160,-4611686021648613377,8,5,0,"matter_remaining",132,50,5,25,15,10);}
fn ExtractGardenPlanetMicrobialCultureLarge(action){extract_composite_range_action(action,9223372034707292160,-4611686021648613377,8,5,0,"matter_remaining",132,250,25,125,75,50);}
fn ExtractGardenPlanetNaturalMaterial(action){extract_composite_ungated_action(action,8,5,0,"crystal_remaining",133,10,1,5,3,2);}
fn ExtractGardenPlanetNaturalMaterialMedium(action){extract_composite_ungated_action(action,8,5,0,"crystal_remaining",133,50,5,25,15,10);}
fn ExtractGardenPlanetNaturalMaterialLarge(action){extract_composite_ungated_action(action,8,5,0,"crystal_remaining",133,250,25,125,75,50);}
fn ExtractGardenPlanetLivingSoil(action){extract_composite_ungated_action(action,8,5,17,"matter_remaining",237,10,1,6,3,1);}
fn ExtractGardenPlanetLivingSoilMedium(action){extract_composite_ungated_action(action,8,5,17,"matter_remaining",237,50,5,30,15,5);}
fn ExtractGardenPlanetLivingSoilLarge(action){extract_composite_ungated_action(action,8,5,17,"matter_remaining",237,250,25,150,75,25);}
fn ExtractGardenPlanetPlantExtract(action){extract_composite_lower_action(action,-4611686021648613376,4,5,0,"matter_remaining",341,10,1,6,3,1);}
fn ExtractGardenPlanetPlantExtractMedium(action){extract_composite_lower_action(action,-4611686021648613376,4,5,0,"matter_remaining",341,50,5,30,15,5);}
fn ExtractGardenPlanetPlantExtractLarge(action){extract_composite_lower_action(action,-4611686021648613376,4,5,0,"matter_remaining",341,250,25,150,75,25);}
fn ExtractGasGiantFusionGas(action){extract_composite_upper_action(action,4611686017353646079,12,6,0,"gas_remaining",119,50,5,30,15,5);}
fn ExtractGasGiantFusionGasLarge(action){extract_composite_upper_action(action,4611686017353646079,12,6,0,"gas_remaining",119,250,25,150,75,25);}
fn ExtractGasGiantAtmosphericGas(action){extract_composite_range_action(action,4611686017353646080,9223372034707292159,2,6,0,"gas_remaining",128,50,5,25,15,10);}
fn ExtractGasGiantAtmosphericGasLarge(action){extract_composite_range_action(action,4611686017353646080,9223372034707292159,2,6,0,"gas_remaining",128,250,25,125,75,50);}
fn ExtractGasGiantNobleGas(action){extract_composite_range_action(action,9223372034707292160,-4611686021648613377,2,6,0,"gas_remaining",134,50,5,35,10,5);}
fn ExtractGasGiantNobleGasLarge(action){extract_composite_range_action(action,9223372034707292160,-4611686021648613377,2,6,0,"gas_remaining",134,250,25,175,50,25);}
fn ExtractGasGiantDeepAtmosphereGas(action){extract_composite_upper_action(action,9223372034707292159,2,6,3,"gas_remaining",238,50,5,30,15,5);}
fn ExtractGasGiantDeepAtmosphereGasLarge(action){extract_composite_upper_action(action,9223372034707292159,2,6,3,"gas_remaining",238,250,25,150,75,25);}
fn ExtractGasGiantHydrocarbonCloud(action){extract_composite_lower_action(action,-4611686021648613376,4,6,0,"gas_remaining",239,50,5,25,15,10);}
fn ExtractGasGiantHydrocarbonCloudLarge(action){extract_composite_lower_action(action,-4611686021648613376,4,6,0,"gas_remaining",239,250,25,125,75,50);}
fn ExtractGasGiantStormFieldData(action){extract_direct_ungated_action(action,12,6,11,"energy_remaining",240,50,5);}
fn ExtractGasGiantStormFieldDataLarge(action){extract_direct_ungated_action(action,12,6,11,"energy_remaining",240,250,25);}
fn ExtractGasGiantSulfurCloud(action){extract_composite_lower_action(action,9223372034707292160,4,6,3,"gas_remaining",342,50,5,35,10,5);}
fn ExtractGasGiantSulfurCloudLarge(action){extract_composite_lower_action(action,9223372034707292160,4,6,3,"gas_remaining",342,250,25,175,50,25);}
fn ExtractIceGiantFusionGas(action){extract_composite_upper_action(action,9223372034707292159,12,7,0,"gas_remaining",119,50,5,30,15,5);}
fn ExtractIceGiantFusionGasLarge(action){extract_composite_upper_action(action,9223372034707292159,12,7,0,"gas_remaining",119,250,25,150,75,25);}
fn ExtractIceGiantVolatileIce(action){extract_composite_ungated_action(action,4,7,0,"crystal_remaining",135,50,5,45,4,1);}
fn ExtractIceGiantVolatileIceLarge(action){extract_composite_ungated_action(action,4,7,0,"crystal_remaining",135,250,25,225,20,5);}
fn ExtractIceGiantNobleGas(action){extract_composite_lower_action(action,9223372034707292160,2,7,0,"gas_remaining",134,50,5,35,10,5);}
fn ExtractIceGiantNobleGasLarge(action){extract_composite_lower_action(action,9223372034707292160,2,7,0,"gas_remaining",134,250,25,175,50,25);}
fn ExtractIceGiantCryogenicVolatile(action){extract_composite_ungated_action(action,4,7,3,"gas_remaining",241,50,5,35,10,5);}
fn ExtractIceGiantCryogenicVolatileLarge(action){extract_composite_ungated_action(action,4,7,3,"gas_remaining",241,250,25,175,50,25);}
fn ExtractIceGiantIceMantleMaterial(action){extract_composite_ungated_action(action,8,7,7,"crystal_remaining",242,50,5,30,15,5);}
fn ExtractIceGiantIceMantleMaterialLarge(action){extract_composite_ungated_action(action,8,7,7,"crystal_remaining",242,250,25,150,75,25);}
fn ExtractIceGiantHighPressurePhaseData(action){extract_direct_upper_action(action,9223372034707292159,12,7,7,"energy_remaining",243,50,5);}
fn ExtractIceGiantHighPressurePhaseDataLarge(action){extract_direct_upper_action(action,9223372034707292159,12,7,7,"energy_remaining",243,250,25);}
fn ExtractIceGiantCryosphereSpectrumData(action){extract_direct_lower_action(action,9223372034707292160,12,7,7,"energy_remaining",343,50,5);}
fn ExtractIceGiantCryosphereSpectrumDataLarge(action){extract_direct_lower_action(action,9223372034707292160,12,7,7,"energy_remaining",343,250,25);}
fn ExtractBarrenPlanetLightMetalOre(action){extract_composite_upper_action(action,3689348813882916863,8,8,0,"matter_remaining",136,10,1,8,1,1);}
fn ExtractBarrenPlanetLightMetalOreMedium(action){extract_composite_upper_action(action,3689348813882916863,8,8,0,"matter_remaining",136,50,5,40,5,5);}
fn ExtractBarrenPlanetLightMetalOreLarge(action){extract_composite_upper_action(action,3689348813882916863,8,8,0,"matter_remaining",136,250,25,200,25,25);}
fn ExtractBarrenPlanetPreciousMetalOre(action){extract_composite_upper_action(action,6148914689804861439,8,8,0,"crystal_remaining",137,10,1,8,1,1);}
fn ExtractBarrenPlanetPreciousMetalOreMedium(action){extract_composite_upper_action(action,6148914689804861439,8,8,0,"crystal_remaining",137,50,5,40,5,5);}
fn ExtractBarrenPlanetPreciousMetalOreLarge(action){extract_composite_upper_action(action,6148914689804861439,8,8,0,"crystal_remaining",137,250,25,200,25,25);}
fn ExtractBarrenPlanetNuclearOre(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,12,8,0,"crystal_remaining",138,50,5,45,4,1);}
fn ExtractBarrenPlanetNuclearOreLarge(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,12,8,0,"crystal_remaining",138,250,25,225,20,5);}
fn ExtractBarrenPlanetCarbonaceousDeposit(action){extract_composite_range_action(action,3689348813882916864,7378697627765833727,8,8,0,"matter_remaining",139,10,1,6,3,1);}
fn ExtractBarrenPlanetCarbonaceousDepositMedium(action){extract_composite_range_action(action,3689348813882916864,7378697627765833727,8,8,0,"matter_remaining",139,50,5,30,15,5);}
fn ExtractBarrenPlanetCarbonaceousDepositLarge(action){extract_composite_range_action(action,3689348813882916864,7378697627765833727,8,8,0,"matter_remaining",139,250,25,150,75,25);}
fn ExtractBarrenPlanetFertilizerMineral(action){extract_composite_range_action(action,7378697627765833728,-7378697632060801025,8,8,0,"matter_remaining",140,10,1,8,1,1);}
fn ExtractBarrenPlanetFertilizerMineralMedium(action){extract_composite_range_action(action,7378697627765833728,-7378697632060801025,8,8,0,"matter_remaining",140,50,5,40,5,5);}
fn ExtractBarrenPlanetFertilizerMineralLarge(action){extract_composite_range_action(action,7378697627765833728,-7378697632060801025,8,8,0,"matter_remaining",140,250,25,200,25,25);}
fn ExtractBarrenPlanetDenseMetalOre(action){extract_composite_range_action(action,-7378697632060801024,-3689348818177884161,8,8,0,"matter_remaining",141,50,5,45,4,1);}
fn ExtractBarrenPlanetDenseMetalOreLarge(action){extract_composite_range_action(action,-7378697632060801024,-3689348818177884161,8,8,0,"matter_remaining",141,250,25,225,20,5);}
fn ExtractBarrenPlanetRareEarthOre(action){extract_composite_lower_action(action,-6148914694099828736,8,8,0,"crystal_remaining",142,50,5,45,4,1);}
fn ExtractBarrenPlanetRareEarthOreLarge(action){extract_composite_lower_action(action,-6148914694099828736,8,8,0,"crystal_remaining",142,250,25,225,20,5);}
fn ExtractBarrenPlanetAlkaliMineralOre(action){extract_composite_lower_action(action,-3689348818177884160,8,8,0,"matter_remaining",344,10,1,7,2,1);}
fn ExtractBarrenPlanetAlkaliMineralOreMedium(action){extract_composite_lower_action(action,-3689348818177884160,8,8,0,"matter_remaining",344,50,5,35,10,5);}
fn ExtractBarrenPlanetAlkaliMineralOreLarge(action){extract_composite_lower_action(action,-3689348818177884160,8,8,0,"matter_remaining",344,250,25,175,50,25);}
fn ExtractNeutronStarMetalRichOre(action){extract_composite_ungated_action(action,12,9,16,"matter_remaining",120,250,25,225,20,5);}
fn ExtractNeutronStarHighEnergyRadiation(action){extract_direct_ungated_action(action,12,9,8,"energy_remaining",143,250,25);}
fn ExtractNeutronStarGravitationalData(action){extract_direct_upper_action(action,6148914689804861439,20,9,16,"energy_remaining",144,250,25);}
fn ExtractNeutronStarRProcessEjecta(action){extract_composite_ungated_action(action,20,9,13,"matter_remaining",244,250,25,225,20,5);}
fn ExtractNeutronStarDegenerateCrustMaterial(action){extract_composite_ungated_action(action,20,9,13,"crystal_remaining",245,250,25,225,20,5);}
fn ExtractNeutronStarPulsarEmissionData(action){extract_direct_range_action(action,6148914689804861440,-6148914694099828737,12,9,16,"energy_remaining",246,250,25);}
fn ExtractNeutronStarMagnetosphericParticleFlux(action){extract_composite_ungated_action(action,20,9,13,"energy_remaining",345,250,25,225,20,5);}
fn ExtractNeutronStarPulsarTimingData(action){extract_direct_lower_action(action,-6148914694099828736,12,9,16,"energy_remaining",346,250,25);}
fn ExtractBlackHoleHighEnergyRadiation(action){extract_direct_ungated_action(action,12,10,8,"energy_remaining",143,250,25);}
fn ExtractBlackHoleGravitationalData(action){extract_direct_upper_action(action,9223372034707292159,20,10,16,"energy_remaining",144,250,25);}
fn ExtractBlackHoleAccretionData(action){extract_direct_lower_action(action,9223372034707292160,20,10,16,"energy_remaining",145,250,25);}
fn ExtractBlackHoleAccretionDiskMatter(action){extract_composite_upper_action(action,6148914689804861439,20,10,13,"energy_remaining",247,250,25,225,20,5);}
fn ExtractBlackHoleRelativisticPlasma(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,20,10,13,"energy_remaining",248,250,25,225,20,5);}
fn ExtractBlackHoleLensingData(action){extract_direct_upper_action(action,9223372034707292159,20,10,14,"energy_remaining",249,250,25);}
fn ExtractBlackHoleAccretionAerosol(action){extract_composite_lower_action(action,-6148914694099828736,20,10,13,"energy_remaining",347,250,25,150,75,25);}
fn ExtractBlackHoleHawkingRadiationData(action){extract_direct_lower_action(action,9223372034707292160,20,10,14,"energy_remaining",348,250,25);}
fn ExtractAnomalyTemporalData(action){extract_direct_upper_action(action,4611686017353646079,20,11,14,"energy_remaining",146,250,25);}
fn ExtractAnomalyGravitationalData(action){extract_direct_ungated_action(action,20,11,14,"matter_remaining",144,250,25);}
fn ExtractAnomalyFieldData(action){extract_direct_upper_action(action,9223372034707292159,20,11,14,"crystal_remaining",147,250,25);}
fn ExtractAnomalyPhaseShiftedMatter(action){extract_composite_ungated_action(action,20,11,13,"matter_remaining",250,250,25,225,20,5);}
fn ExtractAnomalyMagneticObservation(action){extract_direct_lower_action(action,9223372034707292160,20,11,14,"crystal_remaining",251,250,25);}
fn ExtractAnomalyRadiationObservation(action){extract_direct_range_action(action,4611686017353646080,9223372034707292159,20,11,14,"energy_remaining",252,250,25);}
fn ExtractAnomalyPolarizationData(action){extract_direct_range_action(action,9223372034707292160,-4611686021648613377,20,11,14,"energy_remaining",349,250,25);}
fn ExtractAnomalyVacuumFluctuationData(action){extract_direct_lower_action(action,-4611686021648613376,20,11,14,"energy_remaining",350,250,25);}
fn ExtractMegastructureStructuralSalvage(action){extract_composite_ungated_action(action,32,12,6,"matter_remaining",148,10,1,6,3,1);}
fn ExtractMegastructureStructuralSalvageMedium(action){extract_composite_ungated_action(action,32,12,6,"matter_remaining",148,50,5,30,15,5);}
fn ExtractMegastructureStructuralSalvageLarge(action){extract_composite_ungated_action(action,32,12,6,"matter_remaining",148,250,25,150,75,25);}
fn ExtractMegastructureElectronicSalvage(action){extract_composite_ungated_action(action,32,12,2,"crystal_remaining",149,50,5,40,5,5);}
fn ExtractMegastructureElectronicSalvageLarge(action){extract_composite_ungated_action(action,32,12,2,"crystal_remaining",149,250,25,200,25,25);}
fn ExtractMegastructureCeramicSalvage(action){extract_composite_upper_action(action,9223372034707292159,32,12,1,"matter_remaining",150,50,5,40,5,5);}
fn ExtractMegastructureCeramicSalvageLarge(action){extract_composite_upper_action(action,9223372034707292159,32,12,1,"matter_remaining",150,250,25,200,25,25);}
fn ExtractMegastructureArchiveData(action){extract_direct_ungated_action(action,32,12,18,"crystal_remaining",151,250,25);}
fn ExtractMegastructurePolymerSalvage(action){extract_composite_ungated_action(action,32,12,10,"matter_remaining",253,10,1,8,1,1);}
fn ExtractMegastructurePolymerSalvageMedium(action){extract_composite_ungated_action(action,32,12,10,"matter_remaining",253,50,5,40,5,5);}
fn ExtractMegastructurePolymerSalvageLarge(action){extract_composite_ungated_action(action,32,12,10,"matter_remaining",253,250,25,200,25,25);}
fn ExtractMegastructureOpticalSalvage(action){extract_composite_ungated_action(action,32,12,15,"crystal_remaining",254,10,1,8,1,1);}
fn ExtractMegastructureOpticalSalvageMedium(action){extract_composite_ungated_action(action,32,12,15,"crystal_remaining",254,50,5,40,5,5);}
fn ExtractMegastructureOpticalSalvageLarge(action){extract_composite_ungated_action(action,32,12,15,"crystal_remaining",254,250,25,200,25,25);}
fn ExtractMegastructureMechanicalSalvage(action){extract_composite_lower_action(action,9223372034707292160,32,12,1,"matter_remaining",351,10,1,8,1,1);}
fn ExtractMegastructureMechanicalSalvageMedium(action){extract_composite_lower_action(action,9223372034707292160,32,12,1,"matter_remaining",351,50,5,40,5,5);}
fn ExtractMegastructureMechanicalSalvageLarge(action){extract_composite_lower_action(action,9223372034707292160,32,12,1,"matter_remaining",351,250,25,200,25,25);}
fn ExtractGasClusterFusionGas(action){extract_composite_upper_action(action,6148914689804861439,12,13,0,"gas_remaining",119,10,1,6,3,1);}
fn ExtractGasClusterFusionGasMedium(action){extract_composite_upper_action(action,6148914689804861439,12,13,0,"gas_remaining",119,50,5,30,15,5);}
fn ExtractGasClusterFusionGasLarge(action){extract_composite_upper_action(action,6148914689804861439,12,13,0,"gas_remaining",119,250,25,150,75,25);}
fn ExtractGasClusterNobleGas(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,2,13,0,"gas_remaining",134,10,1,7,2,1);}
fn ExtractGasClusterNobleGasMedium(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,2,13,0,"gas_remaining",134,50,5,35,10,5);}
fn ExtractGasClusterNobleGasLarge(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,2,13,0,"gas_remaining",134,250,25,175,50,25);}
fn ExtractGasClusterOrganicOre(action){extract_composite_upper_action(action,9223372034707292159,4,13,0,"matter_remaining",152,10,1,5,3,2);}
fn ExtractGasClusterOrganicOreMedium(action){extract_composite_upper_action(action,9223372034707292159,4,13,0,"matter_remaining",152,50,5,25,15,10);}
fn ExtractGasClusterOrganicOreLarge(action){extract_composite_upper_action(action,9223372034707292159,4,13,0,"matter_remaining",152,250,25,125,75,50);}
fn ExtractGasClusterMolecularCloudGas(action){extract_composite_lower_action(action,-6148914694099828736,2,13,0,"gas_remaining",255,10,1,6,3,1);}
fn ExtractGasClusterMolecularCloudGasMedium(action){extract_composite_lower_action(action,-6148914694099828736,2,13,0,"gas_remaining",255,50,5,30,15,5);}
fn ExtractGasClusterMolecularCloudGasLarge(action){extract_composite_lower_action(action,-6148914694099828736,2,13,0,"gas_remaining",255,250,25,150,75,25);}
fn ExtractGasClusterInterstellarDust(action){extract_composite_lower_action(action,9223372034707292160,8,13,0,"matter_remaining",256,10,1,6,3,1);}
fn ExtractGasClusterInterstellarDustMedium(action){extract_composite_lower_action(action,9223372034707292160,8,13,0,"matter_remaining",256,50,5,30,15,5);}
fn ExtractGasClusterInterstellarDustLarge(action){extract_composite_lower_action(action,9223372034707292160,8,13,0,"matter_remaining",256,250,25,150,75,25);}
fn ExtractGasClusterMolecularSpectrumData(action){extract_direct_ungated_action(action,12,13,11,"energy_remaining",257,10,1);}
fn ExtractGasClusterMolecularSpectrumDataMedium(action){extract_direct_ungated_action(action,12,13,11,"energy_remaining",257,50,5);}
fn ExtractGasClusterMolecularSpectrumDataLarge(action){extract_direct_ungated_action(action,12,13,11,"energy_remaining",257,250,25);}
fn ExtractGasClusterPrebioticMoleculeMixture(action){extract_composite_ungated_action(action,4,13,5,"matter_remaining",352,10,1,5,3,2);}
fn ExtractGasClusterPrebioticMoleculeMixtureMedium(action){extract_composite_ungated_action(action,4,13,5,"matter_remaining",352,50,5,25,15,10);}
fn ExtractGasClusterPrebioticMoleculeMixtureLarge(action){extract_composite_ungated_action(action,4,13,5,"matter_remaining",352,250,25,125,75,50);}
fn ExtractStellarRemnantMetalRichOre(action){extract_composite_upper_action(action,6148914689804861439,12,14,16,"matter_remaining",120,50,5,45,4,1);}
fn ExtractStellarRemnantMetalRichOreLarge(action){extract_composite_upper_action(action,6148914689804861439,12,14,16,"matter_remaining",120,250,25,225,20,5);}
fn ExtractStellarRemnantNuclearOre(action){extract_composite_upper_action(action,6148914689804861439,12,14,16,"energy_remaining",138,50,5,45,4,1);}
fn ExtractStellarRemnantNuclearOreLarge(action){extract_composite_upper_action(action,6148914689804861439,12,14,16,"energy_remaining",138,250,25,225,20,5);}
fn ExtractStellarRemnantCarbonaceousDeposit(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,8,14,16,"matter_remaining",139,50,5,30,15,5);}
fn ExtractStellarRemnantCarbonaceousDepositLarge(action){extract_composite_range_action(action,6148914689804861440,-6148914694099828737,8,14,16,"matter_remaining",139,250,25,150,75,25);}
fn ExtractStellarRemnantSupernovaEjecta(action){extract_composite_lower_action(action,-6148914694099828736,12,14,16,"matter_remaining",258,50,5,25,15,10);}
fn ExtractStellarRemnantSupernovaEjectaLarge(action){extract_composite_lower_action(action,-6148914694099828736,12,14,16,"matter_remaining",258,250,25,125,75,50);}
fn ExtractStellarRemnantRadioisotopeDeposit(action){extract_composite_ungated_action(action,12,14,4,"energy_remaining",259,50,5,30,15,5);}
fn ExtractStellarRemnantRadioisotopeDepositLarge(action){extract_composite_ungated_action(action,12,14,4,"energy_remaining",259,250,25,150,75,25);}
fn ExtractStellarRemnantShockwaveSpectrumData(action){extract_direct_range_action(action,6148914689804861440,-6148914694099828737,12,14,16,"energy_remaining",260,50,5);}
fn ExtractStellarRemnantShockwaveSpectrumDataLarge(action){extract_direct_range_action(action,6148914689804861440,-6148914694099828737,12,14,16,"energy_remaining",260,250,25);}
fn ExtractStellarRemnantDecaySpectrumData(action){extract_direct_lower_action(action,-6148914694099828736,12,14,16,"energy_remaining",353,50,5);}
fn ExtractStellarRemnantDecaySpectrumDataLarge(action){extract_direct_lower_action(action,-6148914694099828736,12,14,16,"energy_remaining",353,250,25);}
fn ExtractAsteroidBeltNickelIronMatrix(action){extract_composite_upper_action(action,9223372034707292159,8,15,1,"matter_remaining",435,10,1,7,2,1);}
fn ExtractAsteroidBeltNickelIronMatrixMedium(action){extract_composite_upper_action(action,9223372034707292159,8,15,1,"matter_remaining",435,50,5,35,10,5);}
fn ExtractAsteroidBeltNickelIronMatrixLarge(action){extract_composite_upper_action(action,9223372034707292159,8,15,1,"matter_remaining",435,250,25,175,50,25);}
fn ExtractAsteroidBeltCarbonaceousRegolith(action){extract_composite_ungated_action(action,8,15,3,"matter_remaining",436,10,1,5,3,2);}
fn ExtractAsteroidBeltCarbonaceousRegolithMedium(action){extract_composite_ungated_action(action,8,15,3,"matter_remaining",436,50,5,25,15,10);}
fn ExtractAsteroidBeltCarbonaceousRegolithLarge(action){extract_composite_ungated_action(action,8,15,3,"matter_remaining",436,250,25,125,75,50);}
fn ExtractAsteroidBeltSilicateRubble(action){extract_composite_ungated_action(action,8,15,6,"crystal_remaining",437,10,1,6,3,1);}
fn ExtractAsteroidBeltSilicateRubbleMedium(action){extract_composite_ungated_action(action,8,15,6,"crystal_remaining",437,50,5,30,15,5);}
fn ExtractAsteroidBeltSilicateRubbleLarge(action){extract_composite_ungated_action(action,8,15,6,"crystal_remaining",437,250,25,150,75,25);}
fn ExtractAsteroidBeltHydratedMineralAggregate(action){extract_composite_ungated_action(action,8,15,3,"crystal_remaining",438,10,1,5,3,2);}
fn ExtractAsteroidBeltHydratedMineralAggregateMedium(action){extract_composite_ungated_action(action,8,15,3,"crystal_remaining",438,50,5,25,15,10);}
fn ExtractAsteroidBeltHydratedMineralAggregateLarge(action){extract_composite_ungated_action(action,8,15,3,"crystal_remaining",438,250,25,125,75,50);}
fn ExtractAsteroidBeltPlatinumGroupVein(action){extract_composite_lower_action(action,9223372034707292160,8,15,1,"matter_remaining",439,50,5,45,4,1);}
fn ExtractAsteroidBeltPlatinumGroupVeinLarge(action){extract_composite_lower_action(action,9223372034707292160,8,15,1,"matter_remaining",439,250,25,225,20,5);}
fn ExtractAsteroidBeltImpactGlassBreccia(action){extract_composite_ungated_action(action,8,15,7,"crystal_remaining",440,10,1,8,1,1);}
fn ExtractAsteroidBeltImpactGlassBrecciaMedium(action){extract_composite_ungated_action(action,8,15,7,"crystal_remaining",440,50,5,40,5,5);}
fn ExtractAsteroidBeltImpactGlassBrecciaLarge(action){extract_composite_ungated_action(action,8,15,7,"crystal_remaining",440,250,25,200,25,25);}
fn ExtractAsteroidBeltOrbitalSurveyData(action){extract_direct_ungated_action(action,12,15,11,"energy_remaining",441,10,1);}
fn ExtractAsteroidBeltOrbitalSurveyDataMedium(action){extract_direct_ungated_action(action,12,15,11,"energy_remaining",441,50,5);}
fn ExtractAsteroidBeltOrbitalSurveyDataLarge(action){extract_direct_ungated_action(action,12,15,11,"energy_remaining",441,250,25);}
fn ExtractVolcanicPlanetUltramaficMagma(action){extract_composite_upper_action(action,9223372034707292159,8,16,6,"matter_remaining",442,10,1,6,3,1);}
fn ExtractVolcanicPlanetUltramaficMagmaMedium(action){extract_composite_upper_action(action,9223372034707292159,8,16,6,"matter_remaining",442,50,5,30,15,5);}
fn ExtractVolcanicPlanetUltramaficMagmaLarge(action){extract_composite_upper_action(action,9223372034707292159,8,16,6,"matter_remaining",442,250,25,150,75,25);}
fn ExtractVolcanicPlanetSulfideMagma(action){extract_composite_ungated_action(action,8,16,1,"matter_remaining",443,10,1,7,2,1);}
fn ExtractVolcanicPlanetSulfideMagmaMedium(action){extract_composite_ungated_action(action,8,16,1,"matter_remaining",443,50,5,35,10,5);}
fn ExtractVolcanicPlanetSulfideMagmaLarge(action){extract_composite_ungated_action(action,8,16,1,"matter_remaining",443,250,25,175,50,25);}
fn ExtractVolcanicPlanetVolcanicAshDeposit(action){extract_composite_lower_action(action,9223372034707292160,8,16,6,"matter_remaining",444,10,1,5,3,2);}
fn ExtractVolcanicPlanetVolcanicAshDepositMedium(action){extract_composite_lower_action(action,9223372034707292160,8,16,6,"matter_remaining",444,50,5,25,15,10);}
fn ExtractVolcanicPlanetVolcanicAshDepositLarge(action){extract_composite_lower_action(action,9223372034707292160,8,16,6,"matter_remaining",444,250,25,125,75,50);}
fn ExtractVolcanicPlanetFumaroleCondensate(action){extract_composite_upper_action(action,9223372034707292159,4,16,3,"gas_remaining",445,10,1,7,2,1);}
fn ExtractVolcanicPlanetFumaroleCondensateMedium(action){extract_composite_upper_action(action,9223372034707292159,4,16,3,"gas_remaining",445,50,5,35,10,5);}
fn ExtractVolcanicPlanetFumaroleCondensateLarge(action){extract_composite_upper_action(action,9223372034707292159,4,16,3,"gas_remaining",445,250,25,175,50,25);}
fn ExtractVolcanicPlanetGeothermalBrine(action){extract_composite_lower_action(action,9223372034707292160,4,16,3,"gas_remaining",446,10,1,6,3,1);}
fn ExtractVolcanicPlanetGeothermalBrineMedium(action){extract_composite_lower_action(action,9223372034707292160,4,16,3,"gas_remaining",446,50,5,30,15,5);}
fn ExtractVolcanicPlanetGeothermalBrineLarge(action){extract_composite_lower_action(action,9223372034707292160,4,16,3,"gas_remaining",446,250,25,150,75,25);}
fn ExtractVolcanicPlanetMantleXenolith(action){extract_composite_ungated_action(action,8,16,7,"matter_remaining",447,10,1,8,1,1);}
fn ExtractVolcanicPlanetMantleXenolithMedium(action){extract_composite_ungated_action(action,8,16,7,"matter_remaining",447,50,5,40,5,5);}
fn ExtractVolcanicPlanetMantleXenolithLarge(action){extract_composite_ungated_action(action,8,16,7,"matter_remaining",447,250,25,200,25,25);}
fn ExtractVolcanicPlanetSeismicTomographyData(action){extract_direct_ungated_action(action,12,16,9,"energy_remaining",448,10,1);}
fn ExtractVolcanicPlanetSeismicTomographyDataMedium(action){extract_direct_ungated_action(action,12,16,9,"energy_remaining",448,50,5);}
fn ExtractVolcanicPlanetSeismicTomographyDataLarge(action){extract_direct_ungated_action(action,12,16,9,"energy_remaining",448,250,25);}
fn ExtractNebulaIonizedHydrogenCloud(action){extract_composite_ungated_action(action,12,17,8,"gas_remaining",449,50,5,30,15,5);}
fn ExtractNebulaIonizedHydrogenCloudLarge(action){extract_composite_ungated_action(action,12,17,8,"gas_remaining",449,250,25,150,75,25);}
fn ExtractNebulaMolecularIceMantle(action){extract_composite_ungated_action(action,4,17,3,"gas_remaining",450,50,5,25,15,10);}
fn ExtractNebulaMolecularIceMantleLarge(action){extract_composite_ungated_action(action,4,17,3,"gas_remaining",450,250,25,125,75,50);}
fn ExtractNebulaStellarNurseryDust(action){extract_composite_ungated_action(action,8,17,16,"matter_remaining",451,50,5,40,5,5);}
fn ExtractNebulaStellarNurseryDustLarge(action){extract_composite_ungated_action(action,8,17,16,"matter_remaining",451,250,25,200,25,25);}
fn ExtractNebulaPolycyclicAromaticMixture(action){extract_composite_ungated_action(action,4,17,10,"gas_remaining",452,50,5,25,15,10);}
fn ExtractNebulaPolycyclicAromaticMixtureLarge(action){extract_composite_ungated_action(action,4,17,10,"gas_remaining",452,250,25,125,75,50);}
fn ExtractNebulaShockedNebularGas(action){extract_composite_ungated_action(action,12,17,16,"gas_remaining",453,50,5,35,10,5);}
fn ExtractNebulaShockedNebularGasLarge(action){extract_composite_ungated_action(action,12,17,16,"gas_remaining",453,250,25,175,50,25);}
fn ExtractNebulaProtostarCensusData(action){extract_direct_ungated_action(action,12,17,11,"energy_remaining",454,50,5);}
fn ExtractNebulaProtostarCensusDataLarge(action){extract_direct_ungated_action(action,12,17,11,"energy_remaining",454,250,25);}
fn ExtractNebulaEmissionLineMap(action){extract_direct_ungated_action(action,12,17,9,"energy_remaining",455,50,5);}
fn ExtractNebulaEmissionLineMapLarge(action){extract_direct_ungated_action(action,12,17,9,"energy_remaining",455,250,25);}
fn ExtractCometClusterPrimitiveIceMatrix(action){extract_composite_ungated_action(action,4,18,3,"crystal_remaining",456,10,1,6,3,1);}
fn ExtractCometClusterPrimitiveIceMatrixMedium(action){extract_composite_ungated_action(action,4,18,3,"crystal_remaining",456,50,5,30,15,5);}
fn ExtractCometClusterPrimitiveIceMatrixLarge(action){extract_composite_ungated_action(action,4,18,3,"crystal_remaining",456,250,25,150,75,25);}
fn ExtractCometClusterRefractoryCometDust(action){extract_composite_ungated_action(action,8,18,7,"matter_remaining",457,10,1,7,2,1);}
fn ExtractCometClusterRefractoryCometDustMedium(action){extract_composite_ungated_action(action,8,18,7,"matter_remaining",457,50,5,35,10,5);}
fn ExtractCometClusterRefractoryCometDustLarge(action){extract_composite_ungated_action(action,8,18,7,"matter_remaining",457,250,25,175,50,25);}
fn ExtractCometClusterComplexOrganicMantle(action){extract_composite_ungated_action(action,4,18,10,"matter_remaining",458,10,1,5,3,2);}
fn ExtractCometClusterComplexOrganicMantleMedium(action){extract_composite_ungated_action(action,4,18,10,"matter_remaining",458,50,5,25,15,10);}
fn ExtractCometClusterComplexOrganicMantleLarge(action){extract_composite_ungated_action(action,4,18,10,"matter_remaining",458,250,25,125,75,50);}
fn ExtractCometClusterCryovolcanicPlume(action){extract_composite_ungated_action(action,4,18,3,"gas_remaining",459,10,1,6,3,1);}
fn ExtractCometClusterCryovolcanicPlumeMedium(action){extract_composite_ungated_action(action,4,18,3,"gas_remaining",459,50,5,30,15,5);}
fn ExtractCometClusterCryovolcanicPlumeLarge(action){extract_composite_ungated_action(action,4,18,3,"gas_remaining",459,250,25,150,75,25);}
fn ExtractCometClusterPresolarGrainAggregate(action){extract_composite_ungated_action(action,12,18,16,"crystal_remaining",460,50,5,45,4,1);}
fn ExtractCometClusterPresolarGrainAggregateLarge(action){extract_composite_ungated_action(action,12,18,16,"crystal_remaining",460,250,25,225,20,5);}
fn ExtractCometClusterIrradiatedIceCrust(action){extract_composite_ungated_action(action,8,18,7,"crystal_remaining",461,10,1,8,1,1);}
fn ExtractCometClusterIrradiatedIceCrustMedium(action){extract_composite_ungated_action(action,8,18,7,"crystal_remaining",461,50,5,40,5,5);}
fn ExtractCometClusterIrradiatedIceCrustLarge(action){extract_composite_ungated_action(action,8,18,7,"crystal_remaining",461,250,25,200,25,25);}
fn ExtractCometClusterCometaryOrbitSolution(action){extract_direct_ungated_action(action,12,18,11,"energy_remaining",462,10,1);}
fn ExtractCometClusterCometaryOrbitSolutionMedium(action){extract_direct_ungated_action(action,12,18,11,"energy_remaining",462,50,5);}
fn ExtractCometClusterCometaryOrbitSolutionLarge(action){extract_direct_ungated_action(action,12,18,11,"energy_remaining",462,250,25);}
fn ExtractBrownDwarfMetallicHydrogenLayer(action){extract_composite_ungated_action(action,12,19,8,"gas_remaining",463,50,5,40,5,5);}
fn ExtractBrownDwarfMetallicHydrogenLayerLarge(action){extract_composite_ungated_action(action,12,19,8,"gas_remaining",463,250,25,200,25,25);}
fn ExtractBrownDwarfAlkaliCloudDeck(action){extract_composite_ungated_action(action,4,19,3,"gas_remaining",464,50,5,35,10,5);}
fn ExtractBrownDwarfAlkaliCloudDeckLarge(action){extract_composite_ungated_action(action,4,19,3,"gas_remaining",464,250,25,175,50,25);}
fn ExtractBrownDwarfSilicateCloudLayer(action){extract_composite_ungated_action(action,8,19,7,"matter_remaining",465,50,5,30,15,5);}
fn ExtractBrownDwarfSilicateCloudLayerLarge(action){extract_composite_ungated_action(action,8,19,7,"matter_remaining",465,250,25,150,75,25);}
fn ExtractBrownDwarfCarbonChemistryMixture(action){extract_composite_ungated_action(action,4,19,10,"gas_remaining",466,50,5,25,15,10);}
fn ExtractBrownDwarfCarbonChemistryMixtureLarge(action){extract_composite_ungated_action(action,4,19,10,"gas_remaining",466,250,25,125,75,50);}
fn ExtractBrownDwarfDeuteriumBurnAsh(action){extract_composite_ungated_action(action,12,19,4,"matter_remaining",467,50,5,45,4,1);}
fn ExtractBrownDwarfDeuteriumBurnAshLarge(action){extract_composite_ungated_action(action,12,19,4,"matter_remaining",467,250,25,225,20,5);}
fn ExtractBrownDwarfInfraredWeatherMap(action){extract_direct_ungated_action(action,12,19,9,"energy_remaining",468,50,5);}
fn ExtractBrownDwarfInfraredWeatherMapLarge(action){extract_direct_ungated_action(action,12,19,9,"energy_remaining",468,250,25);}
fn ExtractBrownDwarfSubstellarRotationData(action){extract_direct_ungated_action(action,12,19,11,"energy_remaining",469,50,5);}
fn ExtractBrownDwarfSubstellarRotationDataLarge(action){extract_direct_ungated_action(action,12,19,11,"energy_remaining",469,250,25);}
fn ExtractWhiteDwarfCrystallizedCarbonOxygenCore(action){extract_composite_ungated_action(action,20,20,13,"crystal_remaining",470,50,5,45,4,1);}
fn ExtractWhiteDwarfCrystallizedCarbonOxygenCoreLarge(action){extract_composite_ungated_action(action,20,20,13,"crystal_remaining",470,250,25,225,20,5);}
fn ExtractWhiteDwarfDegenerateHeliumEnvelope(action){extract_composite_upper_action(action,9223372034707292159,20,20,16,"matter_remaining",471,50,5,25,15,10);}
fn ExtractWhiteDwarfDegenerateHeliumEnvelopeLarge(action){extract_composite_upper_action(action,9223372034707292159,20,20,16,"matter_remaining",471,250,25,125,75,50);}
fn ExtractWhiteDwarfMetalPollutedAtmosphere(action){extract_composite_lower_action(action,9223372034707292160,12,20,16,"matter_remaining",472,50,5,35,10,5);}
fn ExtractWhiteDwarfMetalPollutedAtmosphereLarge(action){extract_composite_lower_action(action,9223372034707292160,12,20,16,"matter_remaining",472,250,25,175,50,25);}
fn ExtractWhiteDwarfTidalDebrisDisk(action){extract_composite_ungated_action(action,12,20,11,"crystal_remaining",473,50,5,25,15,10);}
fn ExtractWhiteDwarfTidalDebrisDiskLarge(action){extract_composite_ungated_action(action,12,20,11,"crystal_remaining",473,250,25,125,75,50);}
fn ExtractWhiteDwarfElectronDegenerateMatter(action){extract_composite_ungated_action(action,20,20,13,"matter_remaining",474,50,5,40,5,5);}
fn ExtractWhiteDwarfElectronDegenerateMatterLarge(action){extract_composite_ungated_action(action,20,20,13,"matter_remaining",474,250,25,200,25,25);}
fn ExtractWhiteDwarfNovaAshDeposit(action){extract_composite_ungated_action(action,12,20,4,"crystal_remaining",475,50,5,30,15,5);}
fn ExtractWhiteDwarfNovaAshDepositLarge(action){extract_composite_ungated_action(action,12,20,4,"crystal_remaining",475,250,25,150,75,25);}
fn ExtractWhiteDwarfAsteroseismicModeData(action){extract_direct_ungated_action(action,12,20,9,"energy_remaining",476,50,5);}
fn ExtractWhiteDwarfAsteroseismicModeDataLarge(action){extract_direct_ungated_action(action,12,20,9,"energy_remaining",476,250,25);}
fn ExtractWhiteDwarfCoolingAgeCalibration(action){extract_direct_ungated_action(action,12,20,16,"energy_remaining",477,50,5);}
fn ExtractWhiteDwarfCoolingAgeCalibrationLarge(action){extract_direct_ungated_action(action,12,20,16,"energy_remaining",477,250,25);}
fn ExtractMagnetarMagnetizedCrustalLattice(action){extract_composite_upper_action(action,9223372034707292159,20,21,13,"crystal_remaining",478,250,25,200,25,25);}
fn ExtractMagnetarUltraStrongFieldCondensate(action){extract_composite_upper_action(action,9223372034707292159,20,21,14,"energy_remaining",479,250,25,225,20,5);}
fn ExtractMagnetarStarquakeEjecta(action){extract_composite_ungated_action(action,20,21,16,"matter_remaining",480,250,25,125,75,50);}
fn ExtractMagnetarTwistedMagnetospherePlasma(action){extract_composite_ungated_action(action,20,21,8,"energy_remaining",481,250,25,150,75,25);}
fn ExtractMagnetarQEDVacuumDeposit(action){extract_composite_lower_action(action,9223372034707292160,20,21,14,"energy_remaining",482,250,25,225,20,5);}
fn ExtractMagnetarDenseNuclearCondensate(action){extract_composite_lower_action(action,9223372034707292160,20,21,13,"crystal_remaining",483,250,25,175,50,25);}
fn ExtractMagnetarGiantFlareLightCurve(action){extract_direct_ungated_action(action,20,21,9,"energy_remaining",484,250,25);}
fn ExtractMagnetarMagneticTopologyMap(action){extract_direct_ungated_action(action,20,21,15,"energy_remaining",485,250,25);}
fn ExtractWormholeMouthExoticThroatMatter(action){extract_composite_upper_action(action,9223372034707292159,20,22,13,"matter_remaining",486,250,25,225,20,5);}
fn ExtractWormholeMouthTidalShearCondensate(action){extract_composite_upper_action(action,9223372034707292159,20,22,14,"crystal_remaining",487,250,25,200,25,25);}
fn ExtractWormholeMouthChronologyResidue(action){extract_composite_upper_action(action,9223372034707292159,20,22,14,"energy_remaining",488,250,25,125,75,50);}
fn ExtractWormholeMouthVacuumBoundaryLayer(action){extract_composite_lower_action(action,9223372034707292160,20,22,13,"matter_remaining",489,250,25,225,20,5);}
fn ExtractWormholeMouthTraversabilityFieldMatrix(action){extract_composite_lower_action(action,9223372034707292160,20,22,14,"crystal_remaining",490,250,25,150,75,25);}
fn ExtractWormholeMouthThroatGeometrySolution(action){extract_direct_lower_action(action,9223372034707292160,20,22,14,"energy_remaining",491,250,25);}
fn ExtractWormholeMouthTransitPhaseData(action){extract_direct_ungated_action(action,20,22,11,"energy_remaining",492,250,25);}
fn ExtractWormholeMouthCausalConnectivityMap(action){extract_direct_ungated_action(action,20,22,18,"energy_remaining",493,250,25);}
fn RefineFusionGasToHydrogen(action){refine_resource_action(action,4,119,"child_1_remaining",153,12);}
fn RefineFusionGasToHelium(action){refine_resource_action(action,4,119,"child_2_remaining",154,12);}
fn RefineFusionGasToDeuterium(action){refine_resource_action(action,4,119,"child_3_remaining",155,12);}
fn RefineMetalRichOreToIron(action){refine_resource_action(action,1,120,"child_1_remaining",156,12);}
fn RefineMetalRichOreToNickel(action){refine_resource_action(action,1,120,"child_2_remaining",157,12);}
fn RefineMetalRichOreToCobalt(action){refine_resource_action(action,1,120,"child_3_remaining",158,12);}
fn RefineFerrousOreToIron(action){refine_resource_action(action,1,122,"child_1_remaining",156,8);}
fn RefineFerrousOreToChromium(action){refine_resource_action(action,1,122,"child_2_remaining",159,8);}
fn RefineFerrousOreToManganese(action){refine_resource_action(action,1,122,"child_3_remaining",160,8);}
fn RefineBaseMetalOreToCopper(action){refine_resource_action(action,1,123,"child_1_remaining",161,8);}
fn RefineBaseMetalOreToZinc(action){refine_resource_action(action,1,123,"child_2_remaining",162,8);}
fn RefineBaseMetalOreToTin(action){refine_resource_action(action,1,123,"child_3_remaining",163,8);}
fn RefineSilicateMineralToSilicon(action){refine_resource_action(action,3,124,"child_1_remaining",164,8);}
fn RefineSilicateMineralToMagnesium(action){refine_resource_action(action,3,124,"child_2_remaining",165,8);}
fn RefineSilicateMineralToQuartz(action){refine_resource_action(action,3,124,"child_3_remaining",166,8);}
fn RefineIndustrialMineralToLimestone(action){refine_resource_action(action,3,125,"child_1_remaining",167,8);}
fn RefineIndustrialMineralToClay(action){refine_resource_action(action,3,125,"child_2_remaining",168,8);}
fn RefineIndustrialMineralToGypsum(action){refine_resource_action(action,3,125,"child_3_remaining",169,8);}
fn RefineSeawaterMineralsToSodiumChloride(action){refine_resource_action(action,3,127,"child_1_remaining",170,4);}
fn RefineSeawaterMineralsToMagnesium(action){refine_resource_action(action,3,127,"child_2_remaining",165,4);}
fn RefineSeawaterMineralsToCalcium(action){refine_resource_action(action,3,127,"child_3_remaining",171,4);}
fn RefineAtmosphericGasToNitrogen(action){refine_resource_action(action,3,128,"child_1_remaining",172,2);}
fn RefineAtmosphericGasToOxygen(action){refine_resource_action(action,3,128,"child_2_remaining",173,2);}
fn RefineAtmosphericGasToCarbonDioxide(action){refine_resource_action(action,3,128,"child_3_remaining",174,2);}
fn RefineBiomassToCellulose(action){refine_resource_action(action,12,129,"child_1_remaining",175,4);}
fn RefineBiomassToProtein(action){refine_resource_action(action,12,129,"child_2_remaining",176,4);}
fn RefineBiomassToLipid(action){refine_resource_action(action,12,129,"child_3_remaining",177,4);}
fn RefineGeneticMaterialToDNA(action){refine_resource_action(action,5,130,"child_1_remaining",178,8);}
fn RefineGeneticMaterialToRNA(action){refine_resource_action(action,5,130,"child_2_remaining",179,8);}
fn RefineGeneticMaterialToPlasmid(action){refine_resource_action(action,5,130,"child_3_remaining",180,8);}
fn RefineBiochemicalMixtureToAminoAcid(action){refine_resource_action(action,5,131,"child_1_remaining",181,4);}
fn RefineBiochemicalMixtureToEnzyme(action){refine_resource_action(action,5,131,"child_2_remaining",182,4);}
fn RefineBiochemicalMixtureToAlkaloid(action){refine_resource_action(action,5,131,"child_3_remaining",183,4);}
fn RefineMicrobialCultureToBacterialCulture(action){refine_resource_action(action,12,132,"child_1_remaining",184,8);}
fn RefineMicrobialCultureToFungalCulture(action){refine_resource_action(action,12,132,"child_2_remaining",185,8);}
fn RefineMicrobialCultureToArchaealCulture(action){refine_resource_action(action,12,132,"child_3_remaining",186,8);}
fn RefineNaturalMaterialToWoodFiber(action){refine_resource_action(action,12,133,"child_1_remaining",187,8);}
fn RefineNaturalMaterialToChitin(action){refine_resource_action(action,12,133,"child_2_remaining",188,8);}
fn RefineNaturalMaterialToNaturalRubber(action){refine_resource_action(action,12,133,"child_3_remaining",189,8);}
fn RefineNobleGasToArgon(action){refine_resource_action(action,3,134,"child_1_remaining",190,2);}
fn RefineNobleGasToNeon(action){refine_resource_action(action,3,134,"child_2_remaining",191,2);}
fn RefineNobleGasToXenon(action){refine_resource_action(action,3,134,"child_3_remaining",192,2);}
fn RefineVolatileIceToWaterIce(action){refine_resource_action(action,3,135,"child_1_remaining",193,4);}
fn RefineVolatileIceToMethaneIce(action){refine_resource_action(action,3,135,"child_2_remaining",194,4);}
fn RefineVolatileIceToAmmoniaIce(action){refine_resource_action(action,3,135,"child_3_remaining",195,4);}
fn RefineLightMetalOreToAluminum(action){refine_resource_action(action,1,136,"child_1_remaining",196,8);}
fn RefineLightMetalOreToTitanium(action){refine_resource_action(action,1,136,"child_2_remaining",197,8);}
fn RefineLightMetalOreToLithium(action){refine_resource_action(action,1,136,"child_3_remaining",198,8);}
fn RefinePreciousMetalOreToSilver(action){refine_resource_action(action,1,137,"child_1_remaining",199,8);}
fn RefinePreciousMetalOreToGold(action){refine_resource_action(action,1,137,"child_2_remaining",200,8);}
fn RefinePreciousMetalOreToPlatinum(action){refine_resource_action(action,1,137,"child_3_remaining",201,8);}
fn RefineNuclearOreToUranium(action){refine_resource_action(action,4,138,"child_1_remaining",202,12);}
fn RefineNuclearOreToThorium(action){refine_resource_action(action,4,138,"child_2_remaining",203,12);}
fn RefineNuclearOreToRadium(action){refine_resource_action(action,4,138,"child_3_remaining",204,12);}
fn RefineCarbonaceousDepositToCarbon(action){refine_resource_action(action,3,139,"child_1_remaining",205,8);}
fn RefineCarbonaceousDepositToGraphite(action){refine_resource_action(action,3,139,"child_2_remaining",206,8);}
fn RefineCarbonaceousDepositToDiamond(action){refine_resource_action(action,3,139,"child_3_remaining",207,8);}
fn RefineFertilizerMineralToPhosphate(action){refine_resource_action(action,3,140,"child_1_remaining",208,8);}
fn RefineFertilizerMineralToSulfur(action){refine_resource_action(action,3,140,"child_2_remaining",209,8);}
fn RefineFertilizerMineralToPotash(action){refine_resource_action(action,3,140,"child_3_remaining",210,8);}
fn RefineStructuralSalvageToSteel(action){refine_resource_action(action,1,148,"child_1_remaining",211,32);}
fn RefineStructuralSalvageToAluminum(action){refine_resource_action(action,1,148,"child_2_remaining",196,32);}
fn RefineStructuralSalvageToCarbonComposite(action){refine_resource_action(action,1,148,"child_3_remaining",212,32);}
fn RefineElectronicSalvageToCopper(action){refine_resource_action(action,2,149,"child_1_remaining",161,32);}
fn RefineElectronicSalvageToSilicon(action){refine_resource_action(action,2,149,"child_2_remaining",164,32);}
fn RefineElectronicSalvageToGold(action){refine_resource_action(action,2,149,"child_3_remaining",200,32);}
fn RefineCeramicSalvageToCeramic(action){refine_resource_action(action,3,150,"child_1_remaining",213,32);}
fn RefineCeramicSalvageToGlass(action){refine_resource_action(action,3,150,"child_2_remaining",214,32);}
fn RefineCeramicSalvageToSiliconCarbide(action){refine_resource_action(action,3,150,"child_3_remaining",215,32);}
fn RefineOrganicOreToMethanol(action){refine_resource_action(action,3,152,"child_1_remaining",216,4);}
fn RefineOrganicOreToFormaldehyde(action){refine_resource_action(action,3,152,"child_2_remaining",217,4);}
fn RefineOrganicOreToBenzene(action){refine_resource_action(action,3,152,"child_3_remaining",218,4);}
fn RefineDenseMetalOreToLead(action){refine_resource_action(action,1,141,"child_1_remaining",219,8);}
fn RefineDenseMetalOreToNickel(action){refine_resource_action(action,1,141,"child_2_remaining",157,8);}
fn RefineDenseMetalOreToCobalt(action){refine_resource_action(action,1,141,"child_3_remaining",158,8);}
fn RefineRareEarthOreToCerium(action){refine_resource_action(action,1,142,"child_1_remaining",220,8);}
fn RefineRareEarthOreToLanthanum(action){refine_resource_action(action,1,142,"child_2_remaining",221,8);}
fn RefineRareEarthOreToNeodymium(action){refine_resource_action(action,1,142,"child_3_remaining",222,8);}
fn RefineRedDwarfPlasmaToIonizedHydrogen(action){refine_resource_action(action,8,223,"child_1_remaining",261,12);}
fn RefineRedDwarfPlasmaToIonizedHelium(action){refine_resource_action(action,8,223,"child_2_remaining",262,12);}
fn RefineRedDwarfPlasmaToElectronPlasma(action){refine_resource_action(action,8,223,"child_3_remaining",263,12);}
fn RefineMagneticStellarCondensateToFerriteDust(action){refine_resource_action(action,7,224,"child_1_remaining",264,12);}
fn RefineMagneticStellarCondensateToMagnetiteGrain(action){refine_resource_action(action,7,224,"child_2_remaining",265,12);}
fn RefineMagneticStellarCondensateToCobaltFerrite(action){refine_resource_action(action,7,224,"child_3_remaining",266,12);}
fn RefinePhotosphericPlasmaToProtonPlasma(action){refine_resource_action(action,8,226,"child_1_remaining",267,12);}
fn RefinePhotosphericPlasmaToAlphaParticlePlasma(action){refine_resource_action(action,8,226,"child_2_remaining",268,12);}
fn RefinePhotosphericPlasmaToPhotosphericElectronPlasma(action){refine_resource_action(action,8,226,"child_3_remaining",269,12);}
fn RefinePhotosphericMineralToCalciumIonDust(action){refine_resource_action(action,8,227,"child_1_remaining",270,12);}
fn RefinePhotosphericMineralToSodiumIonDust(action){refine_resource_action(action,8,227,"child_2_remaining",271,12);}
fn RefinePhotosphericMineralToMagnesiumIonDust(action){refine_resource_action(action,8,227,"child_3_remaining",272,12);}
fn RefineHeliumCarbonEjectaToHelium3(action){refine_resource_action(action,16,229,"child_1_remaining",273,12);}
fn RefineHeliumCarbonEjectaToCarbon12(action){refine_resource_action(action,16,229,"child_2_remaining",274,12);}
fn RefineHeliumCarbonEjectaToOxygen16(action){refine_resource_action(action,16,229,"child_3_remaining",275,12);}
fn RefineHeavyElementCondensateToStrontium(action){refine_resource_action(action,16,230,"child_1_remaining",276,12);}
fn RefineHeavyElementCondensateToBarium(action){refine_resource_action(action,16,230,"child_2_remaining",277,12);}
fn RefineHeavyElementCondensateToEuropium(action){refine_resource_action(action,16,230,"child_3_remaining",278,12);}
fn RefineIgneousRockToBasalt(action){refine_resource_action(action,6,232,"child_1_remaining",279,8);}
fn RefineIgneousRockToGranite(action){refine_resource_action(action,6,232,"child_2_remaining",280,8);}
fn RefineIgneousRockToObsidian(action){refine_resource_action(action,6,232,"child_3_remaining",281,8);}
fn RefineSeafloorSulfideOreToPyrite(action){refine_resource_action(action,1,234,"child_1_remaining",282,8);}
fn RefineSeafloorSulfideOreToChalcopyrite(action){refine_resource_action(action,1,234,"child_2_remaining",283,8);}
fn RefineSeafloorSulfideOreToSphalerite(action){refine_resource_action(action,1,234,"child_3_remaining",284,8);}
fn RefineMarineBiomassToAlgalFiber(action){refine_resource_action(action,12,235,"child_1_remaining",285,4);}
fn RefineMarineBiomassToMarineProtein(action){refine_resource_action(action,12,235,"child_2_remaining",286,4);}
fn RefineMarineBiomassToAlgalOil(action){refine_resource_action(action,12,235,"child_3_remaining",287,4);}
fn RefineLivingSoilToHumus(action){refine_resource_action(action,17,237,"child_1_remaining",288,8);}
fn RefineLivingSoilToMycorrhizalCulture(action){refine_resource_action(action,17,237,"child_2_remaining",289,8);}
fn RefineLivingSoilToSoilMicrobiome(action){refine_resource_action(action,17,237,"child_3_remaining",290,8);}
fn RefineDeepAtmosphereGasToAmmoniaVapor(action){refine_resource_action(action,3,238,"child_1_remaining",291,2);}
fn RefineDeepAtmosphereGasToMethaneVapor(action){refine_resource_action(action,3,238,"child_2_remaining",292,2);}
fn RefineDeepAtmosphereGasToHydrogenSulfide(action){refine_resource_action(action,3,238,"child_3_remaining",293,2);}
fn RefineHydrocarbonCloudToEthane(action){refine_resource_action(action,3,239,"child_1_remaining",294,4);}
fn RefineHydrocarbonCloudToPropane(action){refine_resource_action(action,3,239,"child_2_remaining",295,4);}
fn RefineHydrocarbonCloudToAcetylene(action){refine_resource_action(action,3,239,"child_3_remaining",296,4);}
fn RefineCryogenicVolatileToLiquidMethane(action){refine_resource_action(action,3,241,"child_1_remaining",297,4);}
fn RefineCryogenicVolatileToLiquidAmmonia(action){refine_resource_action(action,3,241,"child_2_remaining",298,4);}
fn RefineCryogenicVolatileToSuperionicWater(action){refine_resource_action(action,7,241,"child_3_remaining",299,4);}
fn RefineIceMantleMaterialToHighPressureIce(action){refine_resource_action(action,7,242,"child_1_remaining",300,8);}
fn RefineIceMantleMaterialToMethaneClathrate(action){refine_resource_action(action,7,242,"child_2_remaining",301,8);}
fn RefineIceMantleMaterialToAmmoniaHydrate(action){refine_resource_action(action,7,242,"child_3_remaining",302,8);}
fn RefineRProcessEjectaToOsmium(action){refine_resource_action(action,13,244,"child_1_remaining",303,20);}
fn RefineRProcessEjectaToIridium(action){refine_resource_action(action,13,244,"child_2_remaining",304,20);}
fn RefineRProcessEjectaToRhenium(action){refine_resource_action(action,13,244,"child_3_remaining",305,20);}
fn RefineDegenerateCrustMaterialToNuclearPasta(action){refine_resource_action(action,13,245,"child_1_remaining",306,20);}
fn RefineDegenerateCrustMaterialToNeutronRichAlloy(action){refine_resource_action(action,13,245,"child_2_remaining",307,20);}
fn RefineDegenerateCrustMaterialToSuperdenseCarbon(action){refine_resource_action(action,13,245,"child_3_remaining",308,20);}
fn RefineAccretionDiskMatterToIonizedIron(action){refine_resource_action(action,13,247,"child_1_remaining",309,20);}
fn RefineAccretionDiskMatterToCarbonPlasma(action){refine_resource_action(action,13,247,"child_2_remaining",310,20);}
fn RefineAccretionDiskMatterToSilicatePlasma(action){refine_resource_action(action,13,247,"child_3_remaining",311,20);}
fn RefineRelativisticPlasmaToPairPlasma(action){refine_resource_action(action,13,248,"child_1_remaining",312,20);}
fn RefineRelativisticPlasmaToSynchrotronPlasma(action){refine_resource_action(action,13,248,"child_2_remaining",313,20);}
fn RefineRelativisticPlasmaToRelativisticIonBeam(action){refine_resource_action(action,13,248,"child_3_remaining",314,20);}
fn RefinePhaseShiftedMatterToMetastableIsotope(action){refine_resource_action(action,13,250,"child_1_remaining",315,20);}
fn RefinePhaseShiftedMatterToPhaseLockedCrystal(action){refine_resource_action(action,14,250,"child_2_remaining",316,20);}
fn RefinePhaseShiftedMatterToVacuumPolarizedMatter(action){refine_resource_action(action,14,250,"child_3_remaining",317,20);}
fn RefinePolymerSalvageToThermoplastic(action){refine_resource_action(action,10,253,"child_1_remaining",318,32);}
fn RefinePolymerSalvageToThermosetResin(action){refine_resource_action(action,10,253,"child_2_remaining",319,32);}
fn RefinePolymerSalvageToElastomer(action){refine_resource_action(action,10,253,"child_3_remaining",320,32);}
fn RefineOpticalSalvageToOpticalGlass(action){refine_resource_action(action,15,254,"child_1_remaining",321,32);}
fn RefineOpticalSalvageToPhotonicCrystal(action){refine_resource_action(action,15,254,"child_2_remaining",322,32);}
fn RefineOpticalSalvageToLaserCrystal(action){refine_resource_action(action,15,254,"child_3_remaining",323,32);}
fn RefineMolecularCloudGasToMolecularHydrogen(action){refine_resource_action(action,3,255,"child_1_remaining",324,2);}
fn RefineMolecularCloudGasToCarbonMonoxide(action){refine_resource_action(action,3,255,"child_2_remaining",325,2);}
fn RefineMolecularCloudGasToHydrogenCyanide(action){refine_resource_action(action,3,255,"child_3_remaining",326,2);}
fn RefineInterstellarDustToSilicateDust(action){refine_resource_action(action,3,256,"child_1_remaining",327,8);}
fn RefineInterstellarDustToCarbonDust(action){refine_resource_action(action,3,256,"child_2_remaining",328,8);}
fn RefineInterstellarDustToIceGrain(action){refine_resource_action(action,3,256,"child_3_remaining",329,8);}
fn RefineSupernovaEjectaToCalcium44(action){refine_resource_action(action,16,258,"child_1_remaining",330,12);}
fn RefineSupernovaEjectaToTitanium44(action){refine_resource_action(action,16,258,"child_2_remaining",331,12);}
fn RefineSupernovaEjectaToNickel56(action){refine_resource_action(action,16,258,"child_3_remaining",332,12);}
fn RefineRadioisotopeDepositToCobalt60(action){refine_resource_action(action,4,259,"child_1_remaining",333,12);}
fn RefineRadioisotopeDepositToCesium137(action){refine_resource_action(action,4,259,"child_2_remaining",334,12);}
fn RefineRadioisotopeDepositToStrontium90(action){refine_resource_action(action,4,259,"child_3_remaining",335,12);}
fn RefineStellarRefractoryDustToCorundum(action){refine_resource_action(action,7,336,"child_1_remaining",354,12);}
fn RefineStellarRefractoryDustToSpinel(action){refine_resource_action(action,7,336,"child_2_remaining",355,12);}
fn RefineStellarRefractoryDustToPerovskite(action){refine_resource_action(action,7,336,"child_3_remaining",356,12);}
fn RefineSolarWindCondensateToLithium7(action){refine_resource_action(action,4,337,"child_1_remaining",357,12);}
fn RefineSolarWindCondensateToBeryllium9(action){refine_resource_action(action,4,337,"child_2_remaining",358,12);}
fn RefineSolarWindCondensateToBoron11(action){refine_resource_action(action,4,337,"child_3_remaining",359,12);}
fn RefineSProcessEjectaToYttrium(action){refine_resource_action(action,16,338,"child_1_remaining",360,12);}
fn RefineSProcessEjectaToZirconium(action){refine_resource_action(action,16,338,"child_2_remaining",361,12);}
fn RefineSProcessEjectaToMolybdenum(action){refine_resource_action(action,16,338,"child_3_remaining",362,12);}
fn RefineSedimentaryRockToSandstone(action){refine_resource_action(action,3,339,"child_1_remaining",363,8);}
fn RefineSedimentaryRockToShale(action){refine_resource_action(action,3,339,"child_2_remaining",364,8);}
fn RefineSedimentaryRockToDolomite(action){refine_resource_action(action,3,339,"child_3_remaining",365,8);}
fn RefineDissolvedTraceMineralsToBromine(action){refine_resource_action(action,3,340,"child_1_remaining",366,4);}
fn RefineDissolvedTraceMineralsToIodine(action){refine_resource_action(action,3,340,"child_2_remaining",367,4);}
fn RefineDissolvedTraceMineralsToBoron(action){refine_resource_action(action,3,340,"child_3_remaining",368,4);}
fn RefinePlantExtractToStarch(action){refine_resource_action(action,12,341,"child_1_remaining",369,4);}
fn RefinePlantExtractToSucrose(action){refine_resource_action(action,12,341,"child_2_remaining",370,4);}
fn RefinePlantExtractToLignin(action){refine_resource_action(action,12,341,"child_3_remaining",371,4);}
fn RefineSulfurCloudToSulfurDioxide(action){refine_resource_action(action,3,342,"child_1_remaining",372,4);}
fn RefineSulfurCloudToAmmoniumHydrosulfide(action){refine_resource_action(action,3,342,"child_2_remaining",373,4);}
fn RefineSulfurCloudToPolysulfurAerosol(action){refine_resource_action(action,3,342,"child_3_remaining",374,4);}
fn RefineAlkaliMineralOreToSodium(action){refine_resource_action(action,3,344,"child_1_remaining",375,8);}
fn RefineAlkaliMineralOreToPotassium(action){refine_resource_action(action,3,344,"child_2_remaining",376,8);}
fn RefineAlkaliMineralOreToRubidium(action){refine_resource_action(action,3,344,"child_3_remaining",377,8);}
fn RefineMagnetosphericParticleFluxToPositronPlasma(action){refine_resource_action(action,13,345,"child_1_remaining",378,20);}
fn RefineMagnetosphericParticleFluxToMuonFlux(action){refine_resource_action(action,13,345,"child_2_remaining",379,20);}
fn RefineMagnetosphericParticleFluxToHeavyIonFlux(action){refine_resource_action(action,13,345,"child_3_remaining",380,20);}
fn RefineAccretionAerosolToIronOxideAerosol(action){refine_resource_action(action,13,347,"child_1_remaining",381,20);}
fn RefineAccretionAerosolToSilicateAerosol(action){refine_resource_action(action,13,347,"child_2_remaining",382,20);}
fn RefineAccretionAerosolToCarbonaceousAerosol(action){refine_resource_action(action,13,347,"child_3_remaining",383,20);}
fn RefineMechanicalSalvageToBearingSteel(action){refine_resource_action(action,1,351,"child_1_remaining",384,32);}
fn RefineMechanicalSalvageToToolSteel(action){refine_resource_action(action,1,351,"child_2_remaining",385,32);}
fn RefineMechanicalSalvageToIndustrialLubricant(action){refine_resource_action(action,1,351,"child_3_remaining",386,32);}
fn RefinePrebioticMoleculeMixtureToGlycine(action){refine_resource_action(action,5,352,"child_1_remaining",387,4);}
fn RefinePrebioticMoleculeMixtureToFormamide(action){refine_resource_action(action,5,352,"child_2_remaining",388,4);}
fn RefinePrebioticMoleculeMixtureToAcetonitrile(action){refine_resource_action(action,5,352,"child_3_remaining",389,4);}
fn RefineNickelIronMatrixToKamacite(action){refine_resource_action(action,1,435,"child_1_remaining",494,8);}
fn RefineNickelIronMatrixToTaenite(action){refine_resource_action(action,1,435,"child_2_remaining",495,8);}
fn RefineNickelIronMatrixToSchreibersite(action){refine_resource_action(action,1,435,"child_3_remaining",496,8);}
fn RefineCarbonaceousRegolithToKerogenGrain(action){refine_resource_action(action,3,436,"child_1_remaining",497,8);}
fn RefineCarbonaceousRegolithToInsolubleOrganicMatter(action){refine_resource_action(action,10,436,"child_2_remaining",498,8);}
fn RefineCarbonaceousRegolithToNanodiamondDust(action){refine_resource_action(action,7,436,"child_3_remaining",499,8);}
fn RefineSilicateRubbleToOlivineAggregate(action){refine_resource_action(action,6,437,"child_1_remaining",500,8);}
fn RefineSilicateRubbleToPyroxeneAggregate(action){refine_resource_action(action,6,437,"child_2_remaining",501,8);}
fn RefineSilicateRubbleToPlagioclaseFragment(action){refine_resource_action(action,6,437,"child_3_remaining",502,8);}
fn RefineHydratedMineralAggregateToSerpentineFiber(action){refine_resource_action(action,3,438,"child_1_remaining",503,8);}
fn RefineHydratedMineralAggregateToSaponiteClay(action){refine_resource_action(action,3,438,"child_2_remaining",504,8);}
fn RefineHydratedMineralAggregateToBruciteNodule(action){refine_resource_action(action,3,438,"child_3_remaining",505,8);}
fn RefinePlatinumGroupVeinToRuthenium(action){refine_resource_action(action,1,439,"child_1_remaining",506,8);}
fn RefinePlatinumGroupVeinToRhodium(action){refine_resource_action(action,1,439,"child_2_remaining",507,8);}
fn RefinePlatinumGroupVeinToPalladium(action){refine_resource_action(action,1,439,"child_3_remaining",508,8);}
fn RefineImpactGlassBrecciaToTektiteGlass(action){refine_resource_action(action,7,440,"child_1_remaining",509,8);}
fn RefineImpactGlassBrecciaToMaskelynite(action){refine_resource_action(action,7,440,"child_2_remaining",510,8);}
fn RefineImpactGlassBrecciaToShockedQuartz(action){refine_resource_action(action,7,440,"child_3_remaining",511,8);}
fn RefineUltramaficMagmaToKomatiiteMelt(action){refine_resource_action(action,6,442,"child_1_remaining",512,8);}
fn RefineUltramaficMagmaToDuniteCrystal(action){refine_resource_action(action,6,442,"child_2_remaining",513,8);}
fn RefineUltramaficMagmaToChromiteSpinel(action){refine_resource_action(action,1,442,"child_3_remaining",514,8);}
fn RefineSulfideMagmaToPentlandite(action){refine_resource_action(action,1,443,"child_1_remaining",515,8);}
fn RefineSulfideMagmaToBornite(action){refine_resource_action(action,1,443,"child_2_remaining",516,8);}
fn RefineSulfideMagmaToMolybdenite(action){refine_resource_action(action,2,443,"child_3_remaining",517,8);}
fn RefineVolcanicAshDepositToPumice(action){refine_resource_action(action,6,444,"child_1_remaining",518,8);}
fn RefineVolcanicAshDepositToScoria(action){refine_resource_action(action,6,444,"child_2_remaining",519,8);}
fn RefineVolcanicAshDepositToVolcanicTuff(action){refine_resource_action(action,6,444,"child_3_remaining",520,8);}
fn RefineFumaroleCondensateToSulfurSublimate(action){refine_resource_action(action,3,445,"child_1_remaining",521,4);}
fn RefineFumaroleCondensateToRealgar(action){refine_resource_action(action,3,445,"child_2_remaining",522,4);}
fn RefineFumaroleCondensateToOrpiment(action){refine_resource_action(action,3,445,"child_3_remaining",523,4);}
fn RefineGeothermalBrineToCesiumChloride(action){refine_resource_action(action,3,446,"child_1_remaining",524,4);}
fn RefineGeothermalBrineToLithiumChloride(action){refine_resource_action(action,4,446,"child_2_remaining",525,4);}
fn RefineGeothermalBrineToBoricAcid(action){refine_resource_action(action,3,446,"child_3_remaining",526,4);}
fn RefineMantleXenolithToGarnetPeridotite(action){refine_resource_action(action,7,447,"child_1_remaining",527,8);}
fn RefineMantleXenolithToEclogite(action){refine_resource_action(action,7,447,"child_2_remaining",528,8);}
fn RefineMantleXenolithToKimberlite(action){refine_resource_action(action,1,447,"child_3_remaining",529,8);}
fn RefineIonizedHydrogenCloudToBalmerAlphaPlasma(action){refine_resource_action(action,8,449,"child_1_remaining",530,12);}
fn RefineIonizedHydrogenCloudToRecombinationIon(action){refine_resource_action(action,8,449,"child_2_remaining",531,12);}
fn RefineIonizedHydrogenCloudToFreeElectronGas(action){refine_resource_action(action,8,449,"child_3_remaining",532,12);}
fn RefineMolecularIceMantleToMethanolIceCrystal(action){refine_resource_action(action,3,450,"child_1_remaining",533,4);}
fn RefineMolecularIceMantleToCarbonylSulfideIce(action){refine_resource_action(action,3,450,"child_2_remaining",534,4);}
fn RefineMolecularIceMantleToCyanoacetyleneIce(action){refine_resource_action(action,10,450,"child_3_remaining",535,4);}
fn RefineStellarNurseryDustToProtochondruleGrain(action){refine_resource_action(action,16,451,"child_1_remaining",536,8);}
fn RefineStellarNurseryDustToCalciumAluminumInclusion(action){refine_resource_action(action,16,451,"child_2_remaining",537,8);}
fn RefineStellarNurseryDustToAmorphousSilicate(action){refine_resource_action(action,7,451,"child_3_remaining",538,8);}
fn RefinePolycyclicAromaticMixtureToNaphthalene(action){refine_resource_action(action,10,452,"child_1_remaining",539,4);}
fn RefinePolycyclicAromaticMixtureToAnthracene(action){refine_resource_action(action,10,452,"child_2_remaining",540,4);}
fn RefinePolycyclicAromaticMixtureToCoronene(action){refine_resource_action(action,10,452,"child_3_remaining",541,4);}
fn RefineShockedNebularGasToRadiativeShockPlasma(action){refine_resource_action(action,16,453,"child_1_remaining",542,12);}
fn RefineShockedNebularGasToTurbulentIonFilament(action){refine_resource_action(action,8,453,"child_2_remaining",543,12);}
fn RefineShockedNebularGasToCompressedMolecularKnot(action){refine_resource_action(action,16,453,"child_3_remaining",544,12);}
fn RefinePrimitiveIceMatrixToCarbonDioxideIce(action){refine_resource_action(action,3,456,"child_1_remaining",545,4);}
fn RefinePrimitiveIceMatrixToCarbonMonoxideIce(action){refine_resource_action(action,3,456,"child_2_remaining",546,4);}
fn RefinePrimitiveIceMatrixToMolecularNitrogenIce(action){refine_resource_action(action,3,456,"child_3_remaining",547,4);}
fn RefineRefractoryCometDustToForsteriteCrystal(action){refine_resource_action(action,7,457,"child_1_remaining",548,8);}
fn RefineRefractoryCometDustToEnstatiteCrystal(action){refine_resource_action(action,7,457,"child_2_remaining",549,8);}
fn RefineRefractoryCometDustToEmbeddedMetalSilicateGrain(action){refine_resource_action(action,1,457,"child_3_remaining",550,8);}
fn RefineComplexOrganicMantleToTholinGranule(action){refine_resource_action(action,17,458,"child_1_remaining",551,4);}
fn RefineComplexOrganicMantleToHexamethylenetetramine(action){refine_resource_action(action,10,458,"child_2_remaining",552,4);}
fn RefineComplexOrganicMantleToPolyoxymethylene(action){refine_resource_action(action,10,458,"child_3_remaining",553,4);}
fn RefineCryovolcanicPlumeToSupercooledWaterVapor(action){refine_resource_action(action,3,459,"child_1_remaining",554,4);}
fn RefineCryovolcanicPlumeToCarbonDioxideJet(action){refine_resource_action(action,3,459,"child_2_remaining",555,4);}
fn RefineCryovolcanicPlumeToAmmoniaJet(action){refine_resource_action(action,3,459,"child_3_remaining",556,4);}
fn RefinePresolarGrainAggregateToPresolarSiliconCarbide(action){refine_resource_action(action,16,460,"child_1_remaining",557,12);}
fn RefinePresolarGrainAggregateToGraphiticSpherule(action){refine_resource_action(action,16,460,"child_2_remaining",558,12);}
fn RefinePresolarGrainAggregateToCorundumStardust(action){refine_resource_action(action,16,460,"child_3_remaining",559,12);}
fn RefineIrradiatedIceCrustToRadicalBearingIce(action){refine_resource_action(action,7,461,"child_1_remaining",560,8);}
fn RefineIrradiatedIceCrustToAmorphousWaterIce(action){refine_resource_action(action,7,461,"child_2_remaining",561,8);}
fn RefineIrradiatedIceCrustToPeroxideIce(action){refine_resource_action(action,3,461,"child_3_remaining",562,8);}
fn RefineMetallicHydrogenLayerToDegenerateHydrogenFluid(action){refine_resource_action(action,8,463,"child_1_remaining",563,12);}
fn RefineMetallicHydrogenLayerToProtonicConductor(action){refine_resource_action(action,2,463,"child_2_remaining",564,12);}
fn RefineMetallicHydrogenLayerToPressureIonizedHelium(action){refine_resource_action(action,8,463,"child_3_remaining",565,12);}
fn RefineAlkaliCloudDeckToSodiumSulfideCloud(action){refine_resource_action(action,3,464,"child_1_remaining",566,4);}
fn RefineAlkaliCloudDeckToPotassiumChlorideCloud(action){refine_resource_action(action,3,464,"child_2_remaining",567,4);}
fn RefineAlkaliCloudDeckToZincSulfideCondensate(action){refine_resource_action(action,3,464,"child_3_remaining",568,4);}
fn RefineSilicateCloudLayerToEnstatiteCloudCrystal(action){refine_resource_action(action,7,465,"child_1_remaining",569,8);}
fn RefineSilicateCloudLayerToIronSilicateDroplet(action){refine_resource_action(action,7,465,"child_2_remaining",570,8);}
fn RefineSilicateCloudLayerToAluminaCloudGrain(action){refine_resource_action(action,7,465,"child_3_remaining",571,8);}
fn RefineCarbonChemistryMixtureToAcetyleneSoot(action){refine_resource_action(action,10,466,"child_1_remaining",572,4);}
fn RefineCarbonChemistryMixtureToHydrogenCyanidePolymer(action){refine_resource_action(action,10,466,"child_2_remaining",573,4);}
fn RefineCarbonChemistryMixtureToCarbonMonosulfide(action){refine_resource_action(action,3,466,"child_3_remaining",574,4);}
fn RefineDeuteriumBurnAshToDeuteriumDepletedHelium(action){refine_resource_action(action,4,467,"child_1_remaining",575,12);}
fn RefineDeuteriumBurnAshToLithiumDepletionResidue(action){refine_resource_action(action,4,467,"child_2_remaining",576,12);}
fn RefineDeuteriumBurnAshToProtonCaptureAsh(action){refine_resource_action(action,4,467,"child_3_remaining",577,12);}
fn RefineCrystallizedCarbonOxygenCoreToCarbonOxygenLattice(action){refine_resource_action(action,13,470,"child_1_remaining",578,20);}
fn RefineCrystallizedCarbonOxygenCoreToNeon22Sediment(action){refine_resource_action(action,4,470,"child_2_remaining",579,20);}
fn RefineCrystallizedCarbonOxygenCoreToPhaseSeparatedOxygen(action){refine_resource_action(action,7,470,"child_3_remaining",580,20);}
fn RefineDegenerateHeliumEnvelopeToPressureBroadenedHelium(action){refine_resource_action(action,16,471,"child_1_remaining",581,20);}
fn RefineDegenerateHeliumEnvelopeToTraceCarbonLayer(action){refine_resource_action(action,16,471,"child_2_remaining",582,20);}
fn RefineDegenerateHeliumEnvelopeToConvectiveHeliumCell(action){refine_resource_action(action,16,471,"child_3_remaining",583,20);}
fn RefineMetalPollutedAtmosphereToSinkingCalcium(action){refine_resource_action(action,16,472,"child_1_remaining",584,12);}
fn RefineMetalPollutedAtmosphereToSinkingMagnesium(action){refine_resource_action(action,16,472,"child_2_remaining",585,12);}
fn RefineMetalPollutedAtmosphereToSinkingIron(action){refine_resource_action(action,16,472,"child_3_remaining",586,12);}
fn RefineTidalDebrisDiskToRocheShreddedSilicate(action){refine_resource_action(action,11,473,"child_1_remaining",587,12);}
fn RefineTidalDebrisDiskToVaporizedMetalRing(action){refine_resource_action(action,16,473,"child_2_remaining",588,12);}
fn RefineTidalDebrisDiskToCompactDustArc(action){refine_resource_action(action,11,473,"child_3_remaining",589,12);}
fn RefineElectronDegenerateMatterToFermiElectronFluid(action){refine_resource_action(action,13,474,"child_1_remaining",590,20);}
fn RefineElectronDegenerateMatterToRelativisticElectronGas(action){refine_resource_action(action,13,474,"child_2_remaining",591,20);}
fn RefineElectronDegenerateMatterToCoulombCrystal(action){refine_resource_action(action,7,474,"child_3_remaining",592,20);}
fn RefineNovaAshDepositToNeonMagnesiumAsh(action){refine_resource_action(action,4,475,"child_1_remaining",593,12);}
fn RefineNovaAshDepositToAluminum26Deposit(action){refine_resource_action(action,4,475,"child_2_remaining",594,12);}
fn RefineNovaAshDepositToSodium22Deposit(action){refine_resource_action(action,4,475,"child_3_remaining",595,12);}
fn RefineMagnetizedCrustalLatticeToMagnetostrictiveIron(action){refine_resource_action(action,7,478,"child_1_remaining",596,20);}
fn RefineMagnetizedCrustalLatticeToQuantizedCrystalDomain(action){refine_resource_action(action,14,478,"child_2_remaining",597,20);}
fn RefineMagnetizedCrustalLatticeToNuclearImpurityLayer(action){refine_resource_action(action,13,478,"child_3_remaining",598,20);}
fn RefineUltraStrongFieldCondensateToLandauQuantizedPlasma(action){refine_resource_action(action,14,479,"child_1_remaining",599,20);}
fn RefineUltraStrongFieldCondensateToVacuumBirefringentMedium(action){refine_resource_action(action,14,479,"child_2_remaining",600,20);}
fn RefineUltraStrongFieldCondensateToBoundMagneticAtom(action){refine_resource_action(action,7,479,"child_3_remaining",601,20);}
fn RefineStarquakeEjectaToNeutronRichCrustShard(action){refine_resource_action(action,13,480,"child_1_remaining",602,20);}
fn RefineStarquakeEjectaToRelativisticPairFireball(action){refine_resource_action(action,16,480,"child_2_remaining",603,20);}
fn RefineStarquakeEjectaToHeavyNucleusFragment(action){refine_resource_action(action,4,480,"child_3_remaining",604,20);}
fn RefineTwistedMagnetospherePlasmaToResonantCyclotronPlasma(action){refine_resource_action(action,8,481,"child_1_remaining",605,20);}
fn RefineTwistedMagnetospherePlasmaToCurrentCarryingPairStream(action){refine_resource_action(action,8,481,"child_2_remaining",606,20);}
fn RefineTwistedMagnetospherePlasmaToMagnetosphericTwistFlux(action){refine_resource_action(action,14,481,"child_3_remaining",607,20);}
fn RefineQEDVacuumDepositToPhotonSplittingResidue(action){refine_resource_action(action,14,482,"child_1_remaining",608,20);}
fn RefineQEDVacuumDepositToPolarizedVacuumDomain(action){refine_resource_action(action,14,482,"child_2_remaining",609,20);}
fn RefineQEDVacuumDepositToMagneticPairCreationSeed(action){refine_resource_action(action,13,482,"child_3_remaining",610,20);}
fn RefineDenseNuclearCondensateToHyperonRichMatter(action){refine_resource_action(action,13,483,"child_1_remaining",611,20);}
fn RefineDenseNuclearCondensateToSuperfluidNeutronVortex(action){refine_resource_action(action,13,483,"child_2_remaining",612,20);}
fn RefineDenseNuclearCondensateToSuperconductingProtonPhase(action){refine_resource_action(action,4,483,"child_3_remaining",613,20);}
fn RefineExoticThroatMatterToNegativeEnergyCondensate(action){refine_resource_action(action,13,486,"child_1_remaining",614,20);}
fn RefineExoticThroatMatterToNullEnergyFilament(action){refine_resource_action(action,14,486,"child_2_remaining",615,20);}
fn RefineExoticThroatMatterToCasimirDenseFoam(action){refine_resource_action(action,13,486,"child_3_remaining",616,20);}
fn RefineTidalShearCondensateToGeodesicShearCrystal(action){refine_resource_action(action,14,487,"child_1_remaining",617,20);}
fn RefineTidalShearCondensateToRedshiftLockedLattice(action){refine_resource_action(action,7,487,"child_2_remaining",618,20);}
fn RefineTidalShearCondensateToCurvatureStressedMatter(action){refine_resource_action(action,13,487,"child_3_remaining",619,20);}
fn RefineChronologyResidueToClosedTimelikeFragment(action){refine_resource_action(action,14,488,"child_1_remaining",620,20);}
fn RefineChronologyResidueToCausalHorizonDust(action){refine_resource_action(action,14,488,"child_2_remaining",621,20);}
fn RefineChronologyResidueToProperTimeDifferential(action){refine_resource_action(action,11,488,"child_3_remaining",622,20);}
fn RefineVacuumBoundaryLayerToFalseVacuumMembrane(action){refine_resource_action(action,13,489,"child_1_remaining",623,20);}
fn RefineVacuumBoundaryLayerToTopologicalDomainWall(action){refine_resource_action(action,14,489,"child_2_remaining",624,20);}
fn RefineVacuumBoundaryLayerToQuantumFoamInclusion(action){refine_resource_action(action,13,489,"child_3_remaining",625,20);}
fn RefineTraversabilityFieldMatrixToMorrisThorneMetricSeed(action){refine_resource_action(action,14,490,"child_1_remaining",626,20);}
fn RefineTraversabilityFieldMatrixToThroatStabilizationMode(action){refine_resource_action(action,14,490,"child_2_remaining",627,20);}
fn RefineTraversabilityFieldMatrixToExoticStressTensor(action){refine_resource_action(action,14,490,"child_3_remaining",628,20);}
// Components
fn FabricateStructuralAlloyReusable(action){fabricate_component_reusable_action(action,8,1,211,6,196,3,159,2,257,390,1);}
fn FabricateStructuralAlloyFinal(action){fabricate_component_final_action(action,8,1,211,6,196,3,159,2,257,390,1);}
fn FabricateCeramicPlatingReusable(action){fabricate_component_reusable_action(action,8,6,213,40,215,5,354,35,233,391,1);}
fn FabricateCeramicPlatingFinal(action){fabricate_component_final_action(action,8,6,213,40,215,5,354,35,233,391,1);}
fn FabricateCircuitSubstrateReusable(action){fabricate_component_reusable_action(action,8,2,164,5,161,7,354,35,147,392,1);}
fn FabricateCircuitSubstrateFinal(action){fabricate_component_final_action(action,8,2,164,5,161,7,354,35,147,392,1);}
fn FabricatePressureVesselReusable(action){fabricate_component_reusable_action(action,8,6,385,1,159,2,319,1,240,393,1);}
fn FabricatePressureVesselFinal(action){fabricate_component_final_action(action,8,6,385,1,159,2,319,1,240,393,1);}
fn FabricateFuelSlurryReusable(action){fabricate_component_reusable_action(action,8,3,216,5,218,2,386,1,257,394,1);}
fn FabricateFuelSlurryFinal(action){fabricate_component_final_action(action,8,3,216,5,218,2,386,1,257,394,1);}
fn FabricateAbrasiveCompoundReusable(action){fabricate_component_reusable_action(action,8,10,207,1,354,35,327,6,243,395,1);}
fn FabricateAbrasiveCompoundFinal(action){fabricate_component_final_action(action,8,10,207,1,354,35,327,6,243,395,1);}
fn FabricateMagneticCoreReusable(action){fabricate_component_reusable_action(action,8,2,264,35,266,5,222,5,251,396,1);}
fn FabricateMagneticCoreFinal(action){fabricate_component_final_action(action,8,2,264,35,266,5,222,5,251,396,1);}
fn FabricateSealantResinReusable(action){fabricate_component_reusable_action(action,8,10,318,8,189,2,371,1,257,397,1);}
fn FabricateSealantResinFinal(action){fabricate_component_final_action(action,8,10,318,8,189,2,371,1,257,397,1);}
fn FabricateFusionCellReusable(action){fabricate_component_reusable_action(action,12,4,155,1,273,25,357,30,228,398,1);}
fn FabricateFusionCellFinal(action){fabricate_component_final_action(action,12,4,155,1,273,25,357,30,228,398,1);}
fn FabricateRadiationShieldingReusable(action){fabricate_component_reusable_action(action,12,6,219,45,368,1,193,45,353,399,1);}
fn FabricateRadiationShieldingFinal(action){fabricate_component_final_action(action,12,6,219,45,368,1,193,45,353,399,1);}
fn FabricatePhotonicArrayReusable(action){fabricate_component_reusable_action(action,12,2,322,1,222,5,321,8,147,400,1);}
fn FabricatePhotonicArrayFinal(action){fabricate_component_final_action(action,12,2,322,1,222,5,321,8,147,400,1);}
fn FabricateSuperconductorReusable(action){fabricate_component_reusable_action(action,12,2,222,5,161,7,273,25,251,401,1);}
fn FabricateSuperconductorFinal(action){fabricate_component_final_action(action,12,2,222,5,161,7,273,25,251,401,1);}
fn FabricateLifeSupportMembraneReusable(action){fabricate_component_reusable_action(action,12,17,182,3,175,5,320,1,126,402,1);}
fn FabricateLifeSupportMembraneFinal(action){fabricate_component_final_action(action,12,17,182,3,175,5,320,1,126,402,1);}
fn FabricateCryogenicLineReusable(action){fabricate_component_reusable_action(action,12,10,297,35,300,30,320,1,343,403,1);}
fn FabricateCryogenicLineFinal(action){fabricate_component_final_action(action,12,10,297,35,300,30,320,1,343,403,1);}
fn FabricateCatalyticBedReusable(action){fabricate_component_reusable_action(action,12,10,201,1,220,45,361,15,257,404,1);}
fn FabricateCatalyticBedFinal(action){fabricate_component_final_action(action,12,10,201,1,220,45,361,15,257,404,1);}
fn FabricateBioreactorCultureReusable(action){fabricate_component_reusable_action(action,12,17,184,5,181,5,286,3,126,405,1);}
fn FabricateBioreactorCultureFinal(action){fabricate_component_final_action(action,12,17,184,5,181,5,286,3,126,405,1);}
fn FabricateLaserAssemblyReusable(action){fabricate_component_reusable_action(action,12,11,323,1,222,5,321,8,225,406,1);}
fn FabricateLaserAssemblyFinal(action){fabricate_component_final_action(action,12,11,323,1,222,5,321,8,225,406,1);}
fn FabricateIsotopeBatteryReusable(action){fabricate_component_reusable_action(action,12,18,335,5,334,15,219,45,353,407,1);}
fn FabricateIsotopeBatteryFinal(action){fabricate_component_final_action(action,12,18,335,5,334,15,219,45,353,407,1);}
fn FabricateNeutronArmourReusable(action){fabricate_component_reusable_action(action,32,18,307,20,303,225,385,1,346,408,1);}
fn FabricateNeutronArmourFinal(action){fabricate_component_final_action(action,32,18,307,20,303,225,385,1,346,408,1);}
fn FabricateDegenerateLatticeReusable(action){fabricate_component_reusable_action(action,32,18,306,225,304,20,316,20,246,409,1);}
fn FabricateDegenerateLatticeFinal(action){fabricate_component_final_action(action,32,18,306,225,304,20,316,20,246,409,1);}
fn FabricateEventHorizonCoilReusable(action){fabricate_component_reusable_action(action,32,13,308,5,310,20,305,5,348,410,1);}
fn FabricateEventHorizonCoilFinal(action){fabricate_component_final_action(action,32,13,308,5,310,20,305,5,348,410,1);}
fn FabricateGraviticLensReusable(action){fabricate_component_reusable_action(action,32,11,308,5,321,8,201,1,249,411,1);}
fn FabricateGraviticLensFinal(action){fabricate_component_final_action(action,32,11,308,5,321,8,201,1,249,411,1);}
fn FabricatePhaseStabiliserReusable(action){fabricate_component_reusable_action(action,32,11,316,20,315,225,304,20,349,412,1);}
fn FabricatePhaseStabiliserFinal(action){fabricate_component_final_action(action,32,11,316,20,315,225,304,20,349,412,1);}
fn FabricateWarpCoilReusable(action){fabricate_component_reusable_action(action,32,11,317,5,316,20,308,5,146,413,1);}
fn FabricateWarpCoilFinal(action){fabricate_component_final_action(action,32,11,317,5,316,20,308,5,146,413,1);}
fn FabricateThermalExchangerReusable(action){fabricate_component_reusable_action(action,8,6,161,7,159,2,213,40,233,414,1);}
fn FabricateThermalExchangerFinal(action){fabricate_component_final_action(action,8,6,161,7,159,2,213,40,233,414,1);}
fn FabricateSensorPackageReusable(action){fabricate_component_reusable_action(action,8,9,164,5,321,8,264,35,147,415,1);}
fn FabricateSensorPackageFinal(action){fabricate_component_final_action(action,8,9,164,5,321,8,264,35,147,415,1);}
fn FabricateServoAssemblyReusable(action){fabricate_component_reusable_action(action,8,9,384,8,158,5,386,1,251,416,1);}
fn FabricateServoAssemblyFinal(action){fabricate_component_final_action(action,8,9,384,8,158,5,386,1,251,416,1);}
fn FabricateDataStorageMatrixReusable(action){fabricate_component_reusable_action(action,8,9,164,5,214,5,354,35,151,417,1);}
fn FabricateDataStorageMatrixFinal(action){fabricate_component_final_action(action,8,9,164,5,214,5,354,35,151,417,1);}
fn FabricateAtmosphericScrubberReusable(action){fabricate_component_reusable_action(action,8,17,212,1,213,40,210,1,240,418,1);}
fn FabricateAtmosphericScrubberFinal(action){fabricate_component_final_action(action,8,17,212,1,213,40,210,1,240,418,1);}
fn FabricateNavigationOpticsReusable(action){fabricate_component_reusable_action(action,8,11,321,8,200,1,166,1,249,419,1);}
fn FabricateNavigationOpticsFinal(action){fabricate_component_final_action(action,8,11,321,8,200,1,166,1,249,419,1);}
fn FabricateCivicUtilityModuleReusable(action){fabricate_component_reusable_action(action,8,18,211,6,161,7,159,2,121,420,1);}
fn FabricateCivicUtilityModuleFinal(action){fabricate_component_final_action(action,8,18,211,6,161,7,159,2,121,420,1);}
fn FabricateQuantumProcessorReusable(action){fabricate_component_reusable_action(action,12,9,164,5,322,1,222,5,350,421,1);}
fn FabricateQuantumProcessorFinal(action){fabricate_component_final_action(action,12,9,164,5,322,1,222,5,350,421,1);}
fn FabricateAutonomousFabricatorReusable(action){fabricate_component_reusable_action(action,12,9,385,1,215,5,222,5,151,422,1);}
fn FabricateAutonomousFabricatorFinal(action){fabricate_component_final_action(action,12,9,385,1,215,5,222,5,151,422,1);}
fn FabricateLongRangeTransceiverReusable(action){fabricate_component_reusable_action(action,12,15,323,1,266,5,200,1,346,423,1);}
fn FabricateLongRangeTransceiverFinal(action){fabricate_component_final_action(action,12,15,323,1,266,5,200,1,346,423,1);}
fn FabricateEcologicalSeederReusable(action){fabricate_component_reusable_action(action,12,17,178,5,285,5,208,8,236,424,1);}
fn FabricateEcologicalSeederFinal(action){fabricate_component_final_action(action,12,17,178,5,285,5,208,8,236,424,1);}
fn FabricateInertialCompensatorReusable(action){fabricate_component_reusable_action(action,12,11,222,5,212,1,266,5,144,425,1);}
fn FabricateInertialCompensatorFinal(action){fabricate_component_final_action(action,12,11,222,5,212,1,266,5,144,425,1);}
fn FabricateCausalMapperReusable(action){fabricate_component_reusable_action(action,32,15,316,20,313,20,323,1,146,426,1);}
fn FabricateCausalMapperFinal(action){fabricate_component_final_action(action,32,15,316,20,313,20,323,1,146,426,1);}
fn FabricateGravitationalAnchorReusable(action){fabricate_component_reusable_action(action,32,18,308,5,303,225,316,20,143,427,1);}
fn FabricateGravitationalAnchorFinal(action){fabricate_component_final_action(action,32,18,308,5,303,225,316,20,143,427,1);}
fn FabricateTemporalRegulatorReusable(action){fabricate_component_reusable_action(action,32,15,315,225,305,5,322,1,252,428,1);}
fn FabricateTemporalRegulatorFinal(action){fabricate_component_final_action(action,32,15,315,225,305,5,322,1,252,428,1);}
fn FabricateStellarForgeCoreReusable(action){fabricate_component_reusable_action(action,32,18,309,225,306,225,316,20,260,429,1);}
fn FabricateStellarForgeCoreFinal(action){fabricate_component_final_action(action,32,18,309,225,306,225,316,20,260,429,1);}
fn FabricateBiosphereGenesisMatrixReusable(action){fabricate_component_reusable_action(action,32,9,178,5,286,3,317,5,151,430,1);}
fn FabricateBiosphereGenesisMatrixFinal(action){fabricate_component_final_action(action,32,9,178,5,286,3,317,5,151,430,1);}
fn FabricateGalacticCognitionNodeReusable(action){fabricate_component_reusable_action(action,32,9,322,1,378,225,316,20,231,431,1);}
fn FabricateGalacticCognitionNodeFinal(action){fabricate_component_final_action(action,32,9,322,1,378,225,316,20,231,431,1);}
fn FabricateWormholeApertureRingReusable(action){fabricate_component_reusable_action(action,32,15,317,5,308,5,311,5,145,432,1);}
fn FabricateWormholeApertureRingFinal(action){fabricate_component_final_action(action,32,15,317,5,308,5,311,5,145,432,1);}
fn FabricateCivilizationArchiveSeedReusable(action){fabricate_component_reusable_action(action,32,18,316,20,323,1,178,5,151,433,1);}
fn FabricateCivilizationArchiveSeedFinal(action){fabricate_component_final_action(action,32,18,316,20,323,1,178,5,151,433,1);}
fn FabricateVacuumEnergyTapReusable(action){fabricate_component_reusable_action(action,32,9,317,5,312,225,307,20,350,434,1);}
fn FabricateVacuumEnergyTapFinal(action){fabricate_component_final_action(action,32,9,317,5,312,225,307,20,350,434,1);}
// Initial civilization skills
fn DevelopTypeIIndustrialFabricationSkill(action){develop_initial_skill_upper_action(action,3074457344902430719,1,1,1);}
fn DevelopTypeIElectronicsSkill(action){develop_initial_skill_range_action(action,3074457344902430720,6148914689804861439,1,2,1);}
fn DevelopTypeIChemicalEngineeringSkill(action){develop_initial_skill_range_action(action,6148914689804861440,9223372034707292159,1,3,1);}
fn DevelopTypeINuclearEngineeringSkill(action){develop_initial_skill_range_action(action,9223372034707292160,-6148914694099828737,1,4,1);}
fn DevelopTypeIGeneticEngineeringSkill(action){develop_initial_skill_range_action(action,-6148914694099828736,-3074457349197398017,1,5,1);}
fn DevelopTypeIPlanetaryInfrastructureSkill(action){develop_initial_skill_lower_action(action,-3074457349197398016,1,6,1);}
fn DevelopTypeIIMetamaterialEngineeringSkill(action){develop_initial_skill_upper_action(action,3074457344902430719,2,7,1);}
fn DevelopTypeIIStellarEnergySystemsSkill(action){develop_initial_skill_range_action(action,3074457344902430720,6148914689804861439,2,8,1);}
fn DevelopTypeIISyntheticIntelligenceSkill(action){develop_initial_skill_range_action(action,6148914689804861440,9223372034707292159,2,9,1);}
fn DevelopTypeIIMolecularFabricationSkill(action){develop_initial_skill_range_action(action,9223372034707292160,-6148914694099828737,2,10,1);}
fn DevelopTypeIIInterstellarNavigationSkill(action){develop_initial_skill_range_action(action,-6148914694099828736,-3074457349197398017,2,11,1);}
fn DevelopTypeIIBiosphereEngineeringSkill(action){develop_initial_skill_lower_action(action,-3074457349197398016,2,12,1);}
fn DevelopTypeIIIExoticMatterEngineeringSkill(action){develop_initial_skill_upper_action(action,3074457344902430719,3,13,1);}
fn DevelopTypeIIISpacetimeEngineeringSkill(action){develop_initial_skill_range_action(action,3074457344902430720,6148914689804861439,3,14,1);}
fn DevelopTypeIIIGalacticIntelligenceArchitectureSkill(action){develop_initial_skill_range_action(action,6148914689804861440,9223372034707292159,3,15,1);}
fn DevelopTypeIIIStellarEngineeringSkill(action){develop_initial_skill_range_action(action,9223372034707292160,-6148914694099828737,3,16,1);}
fn DevelopTypeIIIWorldSeedingSkill(action){develop_initial_skill_range_action(action,-6148914694099828736,-3074457349197398017,3,17,1);}
fn DevelopTypeIIICivilizationEngineeringSkill(action){develop_initial_skill_lower_action(action,-3074457349197398016,3,18,1);}
// Derived skills
fn DevelopStructuralMetallurgySkill(action){develop_derived_skill_2_evidence_action(action,8,1,19,390,1,211,6);}
fn DevelopPrecisionToolingSkill(action){develop_derived_skill_2_evidence_action(action,8,1,20,395,1,385,1);}
fn DevelopPressureSystemsSkill(action){develop_derived_skill_2_evidence_action(action,8,1,21,393,1,233,10);}
fn DevelopCircuitArchitectureSkill(action){develop_derived_skill_2_evidence_action(action,8,2,22,392,1,161,7);}
fn DevelopElectromagneticSystemsSkill(action){develop_derived_skill_2_evidence_action(action,8,2,23,396,1,264,35);}
fn DevelopSensorInstrumentationSkill(action){develop_derived_skill_2_evidence_action(action,8,2,24,392,1,228,50);}
fn DevelopSeparationChemistrySkill(action){develop_derived_skill_2_evidence_action(action,8,3,25,257,10,201,1);}
fn DevelopPolymerChemistrySkill(action){develop_derived_skill_2_evidence_action(action,8,3,26,397,1,319,1);}
fn DevelopPropellantChemistrySkill(action){develop_derived_skill_2_evidence_action(action,8,3,27,394,1,155,1);}
fn DevelopFissionReactorEngineeringSkill(action){develop_derived_skill_2_evidence_action(action,8,4,28,202,45,391,1);}
fn DevelopIsotopeEngineeringSkill(action){develop_derived_skill_2_evidence_action(action,8,4,29,333,30,353,50);}
fn DevelopRadiationProtectionSkill(action){develop_derived_skill_3_evidence_action(action,8,4,30,219,45,368,1,126,10);}
fn DevelopGenomeEditingSkill(action){develop_derived_skill_2_evidence_action(action,8,5,31,178,5,180,2);}
fn DevelopMicrobialDesignSkill(action){develop_derived_skill_2_evidence_action(action,8,5,32,184,5,182,3);}
fn DevelopAdaptiveOrganismDesignSkill(action){develop_derived_skill_2_evidence_action(action,8,5,33,387,5,179,3);}
fn DevelopCivilConstructionSkill(action){develop_derived_skill_2_evidence_action(action,8,6,34,390,1,391,1);}
fn DevelopGeotechnicalEngineeringSkill(action){develop_derived_skill_2_evidence_action(action,8,6,35,279,6,233,10);}
fn DevelopUtilityNetworksSkill(action){develop_derived_skill_2_evidence_action(action,8,6,36,393,1,392,1);}
fn DevelopPhotonicMaterialsSkill(action){develop_derived_skill_2_evidence_action(action,12,7,37,400,1,349,250);}
fn DevelopSuperconductingMediaSkill(action){develop_derived_skill_2_evidence_action(action,12,7,38,401,1,251,250);}
fn DevelopExtremePhaseCompositesSkill(action){develop_derived_skill_2_evidence_action(action,12,7,39,300,30,243,50);}
fn DevelopFusionPowerSkill(action){develop_derived_skill_2_evidence_action(action,12,8,40,398,1,228,50);}
fn DevelopRadiantHarvestingSkill(action){develop_derived_skill_2_evidence_action(action,12,8,41,400,1,225,50);}
fn DevelopPlasmaConfinementSkill(action){develop_derived_skill_2_evidence_action(action,12,8,42,401,1,264,35);}
fn DevelopScientificInferenceSkill(action){develop_derived_skill_2_evidence_action(action,12,9,43,392,1,147,250);}
fn DevelopAutonomousControlSkill(action){develop_derived_skill_2_evidence_action(action,12,9,44,684,1,240,50);}
fn DevelopFleetCoordinationSkill(action){develop_derived_skill_2_evidence_action(action,12,9,45,400,1,246,250);}
fn DevelopPolymerNanofabricationSkill(action){develop_derived_skill_2_evidence_action(action,12,10,46,402,1,318,8);}
fn DevelopCrystalLatticeFabricationSkill(action){develop_derived_skill_2_evidence_action(action,12,10,47,406,1,243,50);}
fn DevelopMolecularAssemblySkill(action){develop_derived_skill_2_evidence_action(action,12,10,48,404,1,257,10);}
fn DevelopStellarAstrometrySkill(action){develop_derived_skill_2_evidence_action(action,12,11,49,415,1,228,50);}
fn DevelopGravitationalCartographySkill(action){develop_derived_skill_2_evidence_action(action,12,11,50,411,1,249,250);}
fn DevelopRelativisticPilotingSkill(action){develop_derived_skill_2_evidence_action(action,12,11,51,425,1,346,250);}
fn DevelopClosedLoopEcologySkill(action){develop_derived_skill_2_evidence_action(action,12,12,52,402,1,175,5);}
fn DevelopMicrobialEcologySkill(action){develop_derived_skill_2_evidence_action(action,12,12,53,405,1,184,5);}
fn DevelopAquaticHabitatEngineeringSkill(action){develop_derived_skill_2_evidence_action(action,12,12,54,126,10,286,3);}
fn DevelopDegenerateMatterScienceSkill(action){develop_derived_skill_2_evidence_action(action,32,13,55,409,1,246,250);}
fn DevelopVacuumStateMaterialsSkill(action){develop_derived_skill_2_evidence_action(action,32,13,56,412,1,350,250);}
fn DevelopRelativisticPlasmaEngineeringSkill(action){develop_derived_skill_2_evidence_action(action,32,13,57,410,1,145,250);}
fn DevelopTemporalTopologySkill(action){develop_derived_skill_2_evidence_action(action,32,14,58,412,1,146,250);}
fn DevelopWormholeGeometrySkill(action){develop_derived_skill_2_evidence_action(action,32,14,59,426,1,432,1);}
fn DevelopCausalStabilizationSkill(action){develop_derived_skill_2_evidence_action(action,32,14,60,428,1,348,250);}
fn DevelopDeepArchiveSystemsSkill(action){develop_derived_skill_2_evidence_action(action,32,15,61,417,1,151,250);}
fn DevelopInterstellarCommunicationsSkill(action){develop_derived_skill_2_evidence_action(action,32,15,62,423,1,246,250);}
fn DevelopDistributedCognitionSkill(action){develop_derived_skill_2_evidence_action(action,32,15,63,431,1,316,20);}
fn DevelopPhotosphericControlSkill(action){develop_derived_skill_2_evidence_action(action,32,16,64,267,30,225,50);}
fn DevelopStarLiftingSkill(action){develop_derived_skill_2_evidence_action(action,32,16,65,401,1,264,35);}
fn DevelopRemnantEngineeringSkill(action){develop_derived_skill_2_evidence_action(action,32,16,66,409,1,260,50);}
fn DevelopAtmosphericGenesisSkill(action){develop_derived_skill_2_evidence_action(action,32,17,67,642,1,174,2);}
fn DevelopHydrosphereGenesisSkill(action){develop_derived_skill_2_evidence_action(action,32,17,68,403,1,126,10);}
fn DevelopSoilEcologyGenesisSkill(action){develop_derived_skill_2_evidence_action(action,32,17,69,405,1,290,1);}
fn DevelopCulturalContinuitySkill(action){develop_derived_skill_2_evidence_action(action,32,18,70,417,1,151,250);}
fn DevelopGovernanceSystemsSkill(action){develop_derived_skill_2_evidence_action(action,32,18,71,691,1,151,250);}
fn DevelopInterstellarLogisticsSkill(action){develop_derived_skill_2_evidence_action(action,32,18,72,693,1,672,1);}
fn DevelopIntegratedIndustrialSystemsMastery(action){develop_derived_skill_3_evidence_action(action,12,1,73,629,1,630,1,631,1);}
fn DevelopIntegratedElectronicsMastery(action){develop_derived_skill_3_evidence_action(action,12,2,74,632,1,633,1,634,1);}
fn DevelopChemicalPlantArchitectureMastery(action){develop_derived_skill_3_evidence_action(action,12,3,75,635,1,636,1,637,1);}
fn DevelopNuclearPowerArchitectureMastery(action){develop_derived_skill_3_evidence_action(action,12,4,76,638,1,639,1,640,1);}
fn DevelopSyntheticGenomicsMastery(action){develop_derived_skill_3_evidence_action(action,12,5,77,641,1,642,1,643,1);}
fn DevelopPlanetaryWorksMastery(action){develop_derived_skill_3_evidence_action(action,12,6,78,644,1,645,1,646,1);}
fn DevelopProgrammableMatterMastery(action){develop_derived_skill_3_evidence_action(action,32,7,79,647,1,648,1,649,1);}
fn DevelopStellarPowerArchitectureMastery(action){develop_derived_skill_3_evidence_action(action,32,8,80,650,1,651,1,652,1);}
fn DevelopCognitiveInfrastructureMastery(action){develop_derived_skill_3_evidence_action(action,32,9,81,653,1,654,1,655,1);}
fn DevelopAtomicallyPreciseManufacturingMastery(action){develop_derived_skill_3_evidence_action(action,32,10,82,656,1,657,1,658,1);}
fn DevelopGalacticCartographyMastery(action){develop_derived_skill_3_evidence_action(action,32,11,83,659,1,660,1,661,1);}
fn DevelopBiosphereArchitectureMastery(action){develop_derived_skill_3_evidence_action(action,32,12,84,662,1,663,1,664,1);}
fn DevelopExoticMaterialsArchitectureMastery(action){develop_derived_skill_3_evidence_action(action,32,13,85,665,1,666,1,667,1);}
fn DevelopCausalArchitectureMastery(action){develop_derived_skill_3_evidence_action(action,32,14,86,668,1,669,1,670,1);}
fn DevelopGalacticCognitiveMeshMastery(action){develop_derived_skill_3_evidence_action(action,32,15,87,671,1,672,1,673,1);}
fn DevelopStellarArchitectureMastery(action){develop_derived_skill_3_evidence_action(action,32,16,88,674,1,675,1,676,1);}
fn DevelopTerraformingArchitectureMastery(action){develop_derived_skill_3_evidence_action(action,32,17,89,677,1,678,1,679,1);}
fn DevelopCivilizationArchitectureMastery(action){develop_derived_skill_3_evidence_action(action,32,18,90,680,1,681,1,682,1);}
// Capability artifacts
fn ForgeReinforcedHullFrame(action){produce_capability_artifact_1_evidence_action(action,8,19,629,1,390,1);}
fn FabricatePrecisionToolhead(action){produce_capability_artifact_1_evidence_action(action,8,20,630,1,395,1);}
fn AssembleHabitatPressureShell(action){produce_capability_artifact_1_evidence_action(action,8,21,631,1,393,1);}
fn FabricateLogicControlBoard(action){produce_capability_artifact_1_evidence_action(action,8,22,632,1,392,1);}
fn FabricateFieldControlAssembly(action){produce_capability_artifact_1_evidence_action(action,8,23,633,1,396,1);}
fn AssembleSurveySensorArray(action){produce_capability_artifact_1_evidence_action(action,8,24,634,1,415,1);}
fn BuildSelectiveSeparationColumn(action){produce_capability_artifact_1_evidence_action(action,8,25,635,1,404,1);}
fn SynthesizePolymerMatrix(action){produce_capability_artifact_1_evidence_action(action,8,26,636,1,397,1);}
fn BlendHighEnergyPropellant(action){produce_capability_artifact_1_evidence_action(action,8,27,637,1,394,1);}
fn AssembleFissionReactorCore(action){produce_capability_artifact_1_evidence_action(action,8,28,638,1,399,1);}
fn FabricateIsotopePowerCell(action){produce_capability_artifact_1_evidence_action(action,8,29,639,1,407,1);}
fn AssembleRadiationVaultModule(action){produce_capability_artifact_1_evidence_action(action,8,30,640,1,399,1);}
fn CompileEditedGenomeArchive(action){produce_capability_artifact_1_evidence_action(action,8,31,641,1,417,1);}
fn CultureEngineeredMicrobe(action){produce_capability_artifact_1_evidence_action(action,8,32,642,1,405,1);}
fn DesignAdaptiveGermline(action){produce_capability_artifact_1_evidence_action(action,8,33,643,1,430,1);}
fn AssembleHabitatFoundation(action){produce_capability_artifact_2_evidence_action(action,8,34,644,1,390,1,391,1);}
fn ProduceGeotechnicalSurvey(action){produce_capability_artifact_2_evidence_action(action,8,35,645,1,415,1,414,1);}
fn AssembleUtilityGridNode(action){produce_capability_artifact_1_evidence_action(action,8,36,646,1,420,1);}
fn FabricateAdaptiveOptic(action){produce_capability_artifact_1_evidence_action(action,12,37,647,1,400,1);}
fn WindSuperconductingFieldCoil(action){produce_capability_artifact_1_evidence_action(action,12,38,648,1,401,1);}
fn SynthesizePhaseCompositePanel(action){produce_capability_artifact_1_evidence_action(action,12,39,649,1,412,1);}
fn AssembleFusionReactor(action){produce_capability_artifact_1_evidence_action(action,12,40,650,1,398,1);}
fn AssembleRadiantCollector(action){produce_capability_artifact_1_evidence_action(action,12,41,651,1,400,1);}
fn AssemblePlasmaContainmentRing(action){produce_capability_artifact_2_evidence_action(action,12,42,652,1,396,1,401,1);}
fn InterpretFieldData(action){produce_capability_artifact_1_evidence_action(action,12,43,653,1,421,1);}
fn AssembleAutonomousGuidanceCore(action){produce_capability_artifact_1_evidence_action(action,12,44,654,1,422,1);}
fn AssembleFleetCoordinationNode(action){produce_capability_artifact_1_evidence_action(action,12,45,655,1,423,1);}
fn FabricateSmartMembrane(action){produce_capability_artifact_1_evidence_action(action,12,46,656,1,402,1);}
fn FabricateTunedCrystalLattice(action){produce_capability_artifact_1_evidence_action(action,12,47,657,1,406,1);}
fn AssembleMolecularAssembler(action){produce_capability_artifact_1_evidence_action(action,12,48,658,1,404,1);}
fn CompileAstrometricAnchorSolution(action){produce_capability_artifact_1_evidence_action(action,12,49,659,1,419,1);}
fn CompileGravitationalChartAnalysis(action){produce_capability_artifact_1_evidence_action(action,12,50,660,1,411,1);}
fn CompileRelativisticTransitPlan(action){produce_capability_artifact_1_evidence_action(action,12,51,661,1,425,1);}
fn AssembleClosedCycleBiome(action){produce_capability_artifact_1_evidence_action(action,12,52,662,1,402,1);}
fn CultureManagedMicrobiome(action){produce_capability_artifact_1_evidence_action(action,12,53,663,1,405,1);}
fn AssembleAquaticHabitatModule(action){produce_capability_artifact_2_evidence_action(action,12,54,664,1,393,1,402,1);}
fn AssembleDegenerateContainmentCell(action){produce_capability_artifact_1_evidence_action(action,32,55,665,1,409,1);}
fn SynthesizeVacuumStateLattice(action){produce_capability_artifact_1_evidence_action(action,32,56,666,1,412,1);}
fn AssembleRelativisticPlasmaBottle(action){produce_capability_artifact_1_evidence_action(action,32,57,667,1,410,1);}
fn CompileTemporalTopologyAnalysis(action){produce_capability_artifact_1_evidence_action(action,32,58,668,1,428,1);}
fn CompileWormholeGeometryModel(action){produce_capability_artifact_1_evidence_action(action,32,59,669,1,432,1);}
fn CompileCausalStabilityModel(action){produce_capability_artifact_1_evidence_action(action,32,60,670,1,428,1);}
fn EncodeDeepArchiveVault(action){produce_capability_artifact_1_evidence_action(action,32,61,671,1,417,1);}
fn AssembleGalacticSignalRelay(action){produce_capability_artifact_1_evidence_action(action,32,62,672,1,423,1);}
fn AssembleGalacticCognitionNode(action){produce_capability_artifact_1_evidence_action(action,32,63,673,1,431,1);}
fn AssemblePhotosphericFieldInjector(action){produce_capability_artifact_1_evidence_action(action,32,64,674,1,396,1);}
fn AssembleStarLiftingCollector(action){produce_capability_artifact_1_evidence_action(action,32,65,675,1,401,1);}
fn AssembleRemnantForgeCore(action){produce_capability_artifact_1_evidence_action(action,32,66,676,1,429,1);}
fn AssembleAtmosphereSeed(action){produce_capability_artifact_1_evidence_action(action,32,67,677,1,418,1);}
fn AssembleHydrosphereSeed(action){produce_capability_artifact_1_evidence_action(action,32,68,678,1,403,1);}
fn AssembleSoilEcologySeed(action){produce_capability_artifact_1_evidence_action(action,32,69,679,1,405,1);}
fn EncodeCulturalContinuityArchive(action){produce_capability_artifact_1_evidence_action(action,32,70,680,1,433,1);}
fn CompileCivicProtocolCharter(action){produce_capability_artifact_1_evidence_action(action,32,71,681,1,420,1);}
fn CompileTradeNetworkCharter(action){produce_capability_artifact_2_evidence_action(action,32,72,682,1,423,1,419,1);}
fn AssembleOrbitalFoundryCore(action){produce_capability_artifact_3_evidence_action(action,12,73,683,1,629,1,630,1,631,1);}
fn AssembleIntegratedAvionicsCore(action){produce_capability_artifact_3_evidence_action(action,12,74,684,1,632,1,633,1,634,1);}
fn AssembleChemicalPlantCore(action){produce_capability_artifact_3_evidence_action(action,12,75,685,1,635,1,636,1,637,1);}
fn AssembleNuclearPowerNode(action){produce_capability_artifact_3_evidence_action(action,12,76,686,1,638,1,639,1,640,1);}
fn AssembleGenomicFoundryCore(action){produce_capability_artifact_3_evidence_action(action,12,77,687,1,641,1,642,1,643,1);}
fn AssemblePlanetaryWorksCore(action){produce_capability_artifact_3_evidence_action(action,12,78,688,1,644,1,645,1,646,1);}
fn SynthesizeProgrammableMatterMatrix(action){produce_capability_artifact_3_evidence_action(action,32,79,689,1,647,1,648,1,649,1);}
fn AssembleStellarPowerNode(action){produce_capability_artifact_3_evidence_action(action,32,80,690,1,650,1,651,1,652,1);}
fn AssembleCognitiveInfrastructureCore(action){produce_capability_artifact_3_evidence_action(action,32,81,691,1,653,1,654,1,655,1);}
fn AssembleNanoforgeCore(action){produce_capability_artifact_3_evidence_action(action,32,82,692,1,656,1,657,1,658,1);}
fn CompileGalacticPositionAtlas(action){produce_capability_artifact_3_evidence_action(action,32,83,693,1,659,1,660,1,661,1);}
fn AssembleBiosphereCore(action){produce_capability_artifact_3_evidence_action(action,32,84,694,1,662,1,663,1,664,1);}
fn AssembleExoticMatterMatrix(action){produce_capability_artifact_3_evidence_action(action,32,85,695,1,665,1,666,1,667,1);}
fn AssembleCausalTransitNode(action){produce_capability_artifact_3_evidence_action(action,32,86,696,1,668,1,669,1,670,1);}
fn AssembleGalacticCognitiveMeshSeed(action){produce_capability_artifact_3_evidence_action(action,32,87,697,1,671,1,672,1,673,1);}
fn AssembleStellarMegastructureSeed(action){produce_capability_artifact_3_evidence_action(action,32,88,698,1,674,1,675,1,676,1);}
fn AssembleWorldSeedPackage(action){produce_capability_artifact_3_evidence_action(action,32,89,699,1,677,1,678,1,679,1);}
fn AssembleCivilizationContinuityCore(action){produce_capability_artifact_3_evidence_action(action,32,90,700,1,680,1,681,1,682,1);}
fn UseTechnologySkill(action){
var ship=action.mutate("microverse__ship");
var technology_skill=action.mutate("microverse__technology_skill");
prove_fixed_versions(action,ship);
prove_fixed_versions(action,technology_skill);
action.st_sum(technology_skill.civilization_version,0,2);
var active_skill_type=unsafe{technology_skill.skill_type-0};
action.st_sum(technology_skill.skill_type,0,active_skill_type);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
let zero_work=action.top_limb_u256(0);
ship.update("work",zero_work);
ship.update("active_skill_type",active_skill_type);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
action.st_sum(technology_skill.reusable,0,1);
var next_skill_key=action.random();
rotate_key(technology_skill,next_skill_key);
}
// Permits and auxiliary ships
fn CreateLargeShipConstructionPermit(action){
var permit=action.output("microverse__shipyard_permit");
var ship=action.mutate("microverse__ship");
prove_fixed_versions(action,ship);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(ship.epoch,0,epoch);
permit.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["permit_type",1],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["industrial_authorized",0],
["electronics_authorized",0],
["molecular_authorized",0]
]);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn AuthorizeLargeShipIndustrial(action){authorize_large_ship_action(action,1,"industrial_authorized");}
fn AuthorizeLargeShipElectronics(action){authorize_large_ship_action(action,2,"electronics_authorized");}
fn AuthorizeLargeShipMolecular(action){authorize_large_ship_action(action,10,"molecular_authorized");}
fn IssueAuxiliaryShipPermit(action){
var permit=action.output("microverse__shipyard_permit");
var ship=action.mutate("microverse__ship");
prove_fixed_versions(action,ship);
action.st_sum(ship.extraction_amount,0,250);
action.st_sum(ship.rare_extraction_amount,0,25);
var permit_x=unsafe{ship.x-0};
var permit_y=unsafe{ship.y-0};
var permit_z=unsafe{ship.z-0};
var permit_epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,permit_x);
action.st_sum(ship.y,0,permit_y);
action.st_sum(ship.z,0,permit_z);
action.st_sum(ship.epoch,0,permit_epoch);
permit.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["permit_type",2],
["x",permit_x],
["y",permit_y],
["z",permit_z],
["epoch",permit_epoch],
["industrial_authorized",0],
["electronics_authorized",0],
["molecular_authorized",0]
]);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
var next_ship_key=action.random();
rotate_key(ship,next_ship_key);
}
fn BuildAuxiliaryShipSmall(action){
var child_ship=action.output("microverse__ship");
var permit=action.input("microverse__shipyard_permit");
var ingredient_1_matter=action.input("microverse__resource");
var ingredient_2_iron=action.input("microverse__resource");
var ingredient_3_aluminum=action.input("microverse__resource");
var ingredient_4_copper=action.input("microverse__resource");
var ingredient_5_silicon=action.input("microverse__resource");
prove_fixed_versions(action,permit);
action.st_sum(permit.permit_type,0,2);
action.st_sum(ingredient_1_matter.resource_type,0,1);
action.st_sum(ingredient_1_matter.amount,0,10);
action.st_sum(ingredient_2_iron.resource_type,0,156);
action.st_sum(ingredient_2_iron.amount,0,6);
action.st_sum(ingredient_3_aluminum.resource_type,0,196);
action.st_sum(ingredient_3_aluminum.amount,0,6);
action.st_sum(ingredient_4_copper.resource_type,0,161);
action.st_sum(ingredient_4_copper.amount,0,6);
action.st_sum(ingredient_5_silicon.resource_type,0,164);
action.st_sum(ingredient_5_silicon.amount,0,6);
var build_x=unsafe{permit.x-0};
var build_y=unsafe{permit.y-0};
var build_z=unsafe{permit.z-0};
var build_epoch=unsafe{permit.epoch-0};
action.st_sum(permit.x,0,build_x);
action.st_sum(permit.y,0,build_y);
action.st_sum(permit.z,0,build_z);
action.st_sum(permit.epoch,0,build_epoch);
var ship_id=action.random();
child_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",10],
["rare_extraction_amount",1],
["x",build_x],
["y",build_y],
["z",build_z],
["epoch",build_epoch],
["active_skill_type",0],
["action_serial",0],
["discovery_serial",0],
["satellite_serial",0],
["civilization_scan_serial",0],
["ship_id",ship_id]
]);
var work=action.intro_vdf(34,child_ship);
child_ship.update("work",work);
}
fn BuildAuxiliaryShipMedium(action){
var child_ship=action.output("microverse__ship");
var permit=action.input("microverse__shipyard_permit");
var ingredient_1_matter=action.input("microverse__resource");
var ingredient_2_crystal=action.input("microverse__resource");
var ingredient_3_energy=action.input("microverse__resource");
var ingredient_4_iron=action.input("microverse__resource");
var ingredient_5_aluminum=action.input("microverse__resource");
var ingredient_6_copper=action.input("microverse__resource");
var ingredient_7_silicon=action.input("microverse__resource");
var ingredient_8_carbon=action.input("microverse__resource");
prove_fixed_versions(action,permit);
action.st_sum(permit.permit_type,0,2);
action.st_sum(ingredient_1_matter.resource_type,0,1);
action.st_sum(ingredient_1_matter.amount,0,10);
action.st_sum(ingredient_2_crystal.resource_type,0,2);
action.st_sum(ingredient_2_crystal.amount,0,10);
action.st_sum(ingredient_3_energy.resource_type,0,4);
action.st_sum(ingredient_3_energy.amount,0,10);
action.st_sum(ingredient_4_iron.resource_type,0,156);
action.st_sum(ingredient_4_iron.amount,0,6);
action.st_sum(ingredient_5_aluminum.resource_type,0,196);
action.st_sum(ingredient_5_aluminum.amount,0,6);
action.st_sum(ingredient_6_copper.resource_type,0,161);
action.st_sum(ingredient_6_copper.amount,0,6);
action.st_sum(ingredient_7_silicon.resource_type,0,164);
action.st_sum(ingredient_7_silicon.amount,0,6);
action.st_sum(ingredient_8_carbon.resource_type,0,205);
action.st_sum(ingredient_8_carbon.amount,0,6);
var build_x=unsafe{permit.x-0};
var build_y=unsafe{permit.y-0};
var build_z=unsafe{permit.z-0};
var build_epoch=unsafe{permit.epoch-0};
action.st_sum(permit.x,0,build_x);
action.st_sum(permit.y,0,build_y);
action.st_sum(permit.z,0,build_z);
action.st_sum(permit.epoch,0,build_epoch);
var ship_id=action.random();
child_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",50],
["rare_extraction_amount",5],
["x",build_x],
["y",build_y],
["z",build_z],
["epoch",build_epoch],
["active_skill_type",0],
["action_serial",0],
["discovery_serial",0],
["satellite_serial",0],
["civilization_scan_serial",0],
["ship_id",ship_id]
]);
var work=action.intro_vdf(102,child_ship);
child_ship.update("work",work);
}
