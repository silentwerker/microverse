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
next_ship,
ship,
destination_x,
destination_y,
destination_z,
destination_epoch
){
prove_fixed_versions(action,ship);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
var x=unsafe{destination_x-0};
var y=unsafe{destination_y-0};
var z=unsafe{destination_z-0};
var epoch=unsafe{destination_epoch-0};
var claim_serial=unsafe{ship.claim_serial-0};
var discovery_serial=unsafe{ship.discovery_serial-0};
var satellite_serial=unsafe{ship.satellite_serial-0};
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
action.st_sum(destination_x,0,x);
action.st_sum(destination_y,0,y);
action.st_sum(destination_z,0,z);
action.st_sum(destination_epoch,0,epoch);
action.st_sum(ship.claim_serial,0,claim_serial);
action.st_sum(ship.discovery_serial,0,discovery_serial);
action.st_sum(ship.satellite_serial,0,satellite_serial);
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
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
next_ship,
resource,
ship,
body,
remaining_field,
resource_type,
extraction_amount,
rare_extraction_amount
){
var ship_id=bind_ship_id(action,ship);
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(body.sector_x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(body.sector_y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(body.sector_z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(body.sector_epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
var discovery_serial=unsafe{ship.discovery_serial-0};
var satellite_serial=unsafe{ship.satellite_serial-0};
var civilization_scan_serial=unsafe{
ship.civilization_scan_serial-0
};
action.st_sum(ship.claim_serial,0,claim_serial);
action.st_sum(ship.discovery_serial,0,discovery_serial);
action.st_sum(ship.satellite_serial,0,satellite_serial);
action.st_sum(
ship.civilization_scan_serial,
0,
civilization_scan_serial
);
var next_action_serial=unsafe{
ship.action_serial-(0-1)
};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
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
body.update(remaining_field,next_remaining);
var next_body_key=action.random();
rotate_key(body,next_body_key);
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
child_1_amount,
child_2_amount,
child_3_amount
){
var ship_id=bind_ship_id(action,ship);
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(body.sector_x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(body.sector_y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(body.sector_z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(body.sector_epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
var discovery_serial=unsafe{ship.discovery_serial-0};
var satellite_serial=unsafe{ship.satellite_serial-0};
var civilization_scan_serial=unsafe{
ship.civilization_scan_serial-0
};
action.st_sum(ship.claim_serial,0,claim_serial);
action.st_sum(ship.discovery_serial,0,discovery_serial);
action.st_sum(ship.satellite_serial,0,satellite_serial);
action.st_sum(
ship.civilization_scan_serial,
0,
civilization_scan_serial
);
var next_action_serial=unsafe{
ship.action_serial-(0-1)
};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
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
["sector_x",x],
["sector_y",y],
["sector_z",z],
["origin_epoch",epoch],
["child_1_remaining",child_1_amount],
["child_2_remaining",child_2_amount],
["child_3_remaining",child_3_amount]
]);
body.update(remaining_field,next_remaining);
var next_body_key=action.random();
rotate_key(body,next_body_key);
}
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
){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,parent);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(parent.sector_x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(parent.sector_y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(parent.sector_z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(parent.origin_epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
action.st_sum(ship.active_skill_type,0,skill_type);
action.st_sum(parent.resource_type,0,parent_resource_type);
action.st_gt(parent[child_remaining_field],0);
var refinement_amount=unsafe{
parent[child_remaining_field]-0
};
action.st_sum(
parent[child_remaining_field],
0,
refinement_amount
);
resource.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["resource_type",output_resource_type],
["amount",refinement_amount]
]);
parent.update(child_remaining_field,0);
var next_parent_key=action.random();
rotate_key(parent,next_parent_key);
}
fn develop_technology_skill_core(
action,
next_ship,
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
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(civilization.sector_x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(civilization.sector_y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(civilization.sector_z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(civilization.origin_epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
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
next_ship,
ship,
required_skill_type
){
prove_fixed_versions(action,ship);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(ship.epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
action.st_sum(ship.active_skill_type,0,required_skill_type);
ship_id
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
next_ship,
ship,
body,
skill_type
){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(body.sector_x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(body.sector_y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(body.sector_z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(body.sector_epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
action.st_sum(ship.extraction_amount,0,250);
action.st_sum(ship.rare_extraction_amount,0,25);
action.st_sum(ship.active_skill_type,0,skill_type);
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
action,next_ship,ship,chart,code,x,y,z,uses,
minimum_source_pool_exclusive
){
consume_prepared_ship_core(action,next_ship,ship,50);
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
action,next_ship,ship,chart,code,epoch,uses,
minimum_source_pool_exclusive
){
consume_prepared_ship_core(action,next_ship,ship,58);
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
fn develop_derived_skill_core(
action,
next_ship,
technology_skill,
ship,
parent_skill_type,
output_skill_type
){
consume_prepared_ship_core(
action,
next_ship,
ship,
parent_skill_type
);
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
next_ship,
artifact,
ship,
required_skill_type,
output_resource_type,
output_amount
){
consume_prepared_ship_core(
action,
next_ship,
ship,
required_skill_type
);
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
next_ship,
ship,
permit,
skill_type,
authorization_field
){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,permit);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(permit.x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(permit.y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(permit.z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(permit.epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
action.st_sum(ship.active_skill_type,0,skill_type);
action.st_sum(permit.permit_type,0,1);
action.st_sum(permit[authorization_field],0,0);
permit.update(authorization_field,1);
var next_permit_key=action.random();
rotate_key(permit,next_permit_key);
}
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
){
consume_prepared_ship_core(action,next_ship,ship,skill_type);
prove_fixed_versions(action,material_1);
prove_fixed_versions(action,material_2);
prove_fixed_versions(action,material_3);
prove_fixed_versions(action,catalyst);
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
fn survey_replacement_ship_core(action,next_ship,ship,sector){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,sector);
action.st_sum(sector.body_bank_version,0,2);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(sector.x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(sector.y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(sector.z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(sector.epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
}
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
){
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
var next_discovery_serial=unsafe{ship.discovery_serial-(0-1)};
action.st_sum(ship.discovery_serial,1,next_discovery_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",next_discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
}
fn detect_signal_core(action,next_ship,signal,ship,sector,category_code,candidate_code,remaining_field,serial_field){
prove_fixed_versions(action,ship);
prove_fixed_versions(action,sector);
action.st_sum(sector.body_bank_version,0,2);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(sector.x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(sector.y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(sector.z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(sector.epoch,0,epoch);
finish_detect_replacement_ship_core(action,next_ship,ship,ship_id,extraction_amount,rare_extraction_amount,x,y,z,epoch);
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
["sector_x",x],
["sector_y",y],
["sector_z",z],
["sector_epoch",epoch],
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
fn extract_base_vdf_2_core(action,next_ship,resource,ship,body,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,next_ship,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(2,body);
body.update("work",work);
}
fn extract_base_vdf_4_core(action,next_ship,resource,ship,body,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,next_ship,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(4,body);
body.update("work",work);
}
fn extract_base_vdf_8_core(action,next_ship,resource,ship,body,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,next_ship,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(8,body);
body.update("work",work);
}
fn extract_direct_body_vdf_2_core(action,next_ship,resource,ship,body,candidate_code,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,next_ship,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(2,body);
body.update("work",work);
}
fn extract_direct_body_vdf_4_core(action,next_ship,resource,ship,body,candidate_code,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,next_ship,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(4,body);
body.update("work",work);
}
fn extract_direct_body_vdf_12_core(action,next_ship,resource,ship,body,candidate_code,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,next_ship,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(12,body);
body.update("work",work);
}
fn extract_direct_body_vdf_20_core(action,next_ship,resource,ship,body,candidate_code,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,next_ship,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(20,body);
body.update("work",work);
}
fn extract_direct_body_vdf_32_core(action,next_ship,resource,ship,body,candidate_code,required_skill_type,remaining_field,resource_type,extraction_amount,rare_extraction_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_direct_resource_core(action,next_ship,resource,ship,body,remaining_field,resource_type,extraction_amount,rare_extraction_amount);
var work=action.intro_vdf(32,body);
body.update("work",work);
}
fn extract_composite_vdf_2_core(action,next_ship,composite_resource,ship,body,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_composite_resource_core(action,next_ship,composite_resource,ship,body,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount);
var work=action.intro_vdf(2,body);
body.update("work",work);
}
fn extract_composite_vdf_4_core(action,next_ship,composite_resource,ship,body,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_composite_resource_core(action,next_ship,composite_resource,ship,body,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount);
var work=action.intro_vdf(4,body);
body.update("work",work);
}
fn extract_composite_vdf_8_core(action,next_ship,composite_resource,ship,body,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_composite_resource_core(action,next_ship,composite_resource,ship,body,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount);
var work=action.intro_vdf(8,body);
body.update("work",work);
}
fn extract_composite_vdf_12_core(action,next_ship,composite_resource,ship,body,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_composite_resource_core(action,next_ship,composite_resource,ship,body,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount);
var work=action.intro_vdf(12,body);
body.update("work",work);
}
fn extract_composite_vdf_20_core(action,next_ship,composite_resource,ship,body,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_composite_resource_core(action,next_ship,composite_resource,ship,body,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount);
var work=action.intro_vdf(20,body);
body.update("work",work);
}
fn extract_composite_vdf_32_core(action,next_ship,composite_resource,ship,body,candidate_code,required_skill_type,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount){
action.st_sum(body.candidate_code,0,candidate_code);
action.st_sum(ship.active_skill_type,0,required_skill_type);
extract_composite_resource_core(action,next_ship,composite_resource,ship,body,remaining_field,composite_resource_type,extraction_amount,rare_extraction_amount,child_1_amount,child_2_amount,child_3_amount);
var work=action.intro_vdf(32,body);
body.update("work",work);
}
fn refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type){
refine_resource_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type);
var work=action.intro_vdf(2,parent);
parent.update("work",work);
}
fn refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type){
refine_resource_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type);
var work=action.intro_vdf(4,parent);
parent.update("work",work);
}
fn refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type){
refine_resource_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type);
var work=action.intro_vdf(8,parent);
parent.update("work",work);
}
fn refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type){
refine_resource_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type);
var work=action.intro_vdf(12,parent);
parent.update("work",work);
}
fn refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type){
refine_resource_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type);
var work=action.intro_vdf(20,parent);
parent.update("work",work);
}
fn refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type){
refine_resource_core(action,next_ship,resource,ship,parent,required_skill_type,parent_resource_type,child_remaining_field,output_resource_type);
var work=action.intro_vdf(32,parent);
parent.update("work",work);
}
fn fabricate_component_reusable_vdf_8_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount){
fabricate_component_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount);
consume_component_catalyst_reusable_core(action,catalyst);
var work=action.intro_vdf(8,component);
component.update("work",work);
}
fn fabricate_component_final_vdf_8_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount){
fabricate_component_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount);
consume_component_catalyst_final_core(action,catalyst);
var work=action.intro_vdf(8,component);
component.update("work",work);
}
fn fabricate_component_reusable_vdf_12_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount){
fabricate_component_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount);
consume_component_catalyst_reusable_core(action,catalyst);
var work=action.intro_vdf(12,component);
component.update("work",work);
}
fn fabricate_component_final_vdf_12_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount){
fabricate_component_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount);
consume_component_catalyst_final_core(action,catalyst);
var work=action.intro_vdf(12,component);
component.update("work",work);
}
fn fabricate_component_reusable_vdf_32_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount){
fabricate_component_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount);
consume_component_catalyst_reusable_core(action,catalyst);
var work=action.intro_vdf(32,component);
component.update("work",work);
}
fn fabricate_component_final_vdf_32_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount){
fabricate_component_core(action,next_ship,component,ship,material_1,material_2,material_3,catalyst,skill_type,material_1_type,material_1_amount,material_2_type,material_2_amount,material_3_type,material_3_amount,catalyst_type,component_type,component_amount);
consume_component_catalyst_final_core(action,catalyst);
var work=action.intro_vdf(32,component);
component.update("work",work);
}
fn develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,parent_skill_type,output_skill_type,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount){
develop_derived_skill_core(action,next_ship,technology_skill,ship,parent_skill_type,output_skill_type);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
var work=action.intro_vdf(8,technology_skill);
technology_skill.update("work",work);
}
fn develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,parent_skill_type,output_skill_type,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount){
develop_derived_skill_core(action,next_ship,technology_skill,ship,parent_skill_type,output_skill_type);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
var work=action.intro_vdf(12,technology_skill);
technology_skill.update("work",work);
}
fn develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,parent_skill_type,output_skill_type,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount){
develop_derived_skill_core(action,next_ship,technology_skill,ship,parent_skill_type,output_skill_type);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
var work=action.intro_vdf(32,technology_skill);
technology_skill.update("work",work);
}
fn develop_derived_skill_3_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,parent_skill_type,output_skill_type,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount,evidence_3_type,evidence_3_amount){
develop_derived_skill_core(action,next_ship,technology_skill,ship,parent_skill_type,output_skill_type);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
prove_resource_stack_core(action,evidence_3,evidence_3_type,evidence_3_amount);
var work=action.intro_vdf(8,technology_skill);
technology_skill.update("work",work);
}
fn develop_derived_skill_3_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,parent_skill_type,output_skill_type,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount,evidence_3_type,evidence_3_amount){
develop_derived_skill_core(action,next_ship,technology_skill,ship,parent_skill_type,output_skill_type);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
prove_resource_stack_core(action,evidence_3,evidence_3_type,evidence_3_amount);
var work=action.intro_vdf(12,technology_skill);
technology_skill.update("work",work);
}
fn develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,parent_skill_type,output_skill_type,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount,evidence_3_type,evidence_3_amount){
develop_derived_skill_core(action,next_ship,technology_skill,ship,parent_skill_type,output_skill_type);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
prove_resource_stack_core(action,evidence_3,evidence_3_type,evidence_3_amount);
var work=action.intro_vdf(32,technology_skill);
technology_skill.update("work",work);
}
fn produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount){
produce_capability_artifact_core(action,next_ship,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
var work=action.intro_vdf(8,artifact);
artifact.update("work",work);
}
fn produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount){
produce_capability_artifact_core(action,next_ship,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
var work=action.intro_vdf(12,artifact);
artifact.update("work",work);
}
fn produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount){
produce_capability_artifact_core(action,next_ship,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
var work=action.intro_vdf(32,artifact);
artifact.update("work",work);
}
fn produce_capability_artifact_2_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,evidence_2,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount){
produce_capability_artifact_core(action,next_ship,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
var work=action.intro_vdf(8,artifact);
artifact.update("work",work);
}
fn produce_capability_artifact_2_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,evidence_2,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount){
produce_capability_artifact_core(action,next_ship,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
var work=action.intro_vdf(12,artifact);
artifact.update("work",work);
}
fn produce_capability_artifact_2_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount){
produce_capability_artifact_core(action,next_ship,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
var work=action.intro_vdf(32,artifact);
artifact.update("work",work);
}
fn produce_capability_artifact_3_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount,evidence_3_type,evidence_3_amount){
produce_capability_artifact_core(action,next_ship,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
prove_resource_stack_core(action,evidence_3,evidence_3_type,evidence_3_amount);
var work=action.intro_vdf(12,artifact);
artifact.update("work",work);
}
fn produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,required_skill_type,output_resource_type,output_amount,evidence_1_type,evidence_1_amount,evidence_2_type,evidence_2_amount,evidence_3_type,evidence_3_amount){
produce_capability_artifact_core(action,next_ship,artifact,ship,required_skill_type,output_resource_type,output_amount);
prove_resource_stack_core(action,evidence_1,evidence_1_type,evidence_1_amount);
prove_resource_stack_core(action,evidence_2,evidence_2_type,evidence_2_amount);
prove_resource_stack_core(action,evidence_3,evidence_3_type,evidence_3_amount);
var work=action.intro_vdf(32,artifact);
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
fn update_ship_work_vdf_4_core(action,ship){
var work=action.intro_vdf(4,ship);
ship.update("work",work);
}
fn update_ship_work_vdf_12_core(action,ship){
var work=action.intro_vdf(12,ship);
ship.update("work",work);
}
fn update_ship_work_vdf_28_core(action,ship){
var work=action.intro_vdf(28,ship);
ship.update("work",work);
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
["claim_serial",0],
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
["claim_serial",0],
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
["claim_serial",0],
["discovery_serial",0],
["satellite_serial",0],
["civilization_scan_serial",0],
["ship_id",ship_id]
]);
var work=action.intro_vdf(510,ship);
ship.update("work",work);
}
fn MovePositiveX(action){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.x,"x",1,10,1);
update_ship_work_vdf_4_core(action,ship);
}
fn MovePositiveXMedium(action){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.x,"x",10,50,5);
update_ship_work_vdf_12_core(action,ship);
}
fn MovePositiveXLarge(action){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.x,"x",100,250,25);
update_ship_work_vdf_28_core(action,ship);
}
fn MoveNegativeX(action){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.x,"x",1,10,1);
update_ship_work_vdf_4_core(action,ship);
}
fn MoveNegativeXMedium(action){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.x,"x",10,50,5);
update_ship_work_vdf_12_core(action,ship);
}
fn MoveNegativeXLarge(action){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.x,"x",100,250,25);
update_ship_work_vdf_28_core(action,ship);
}
fn MovePositiveY(action){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.y,"y",1,10,1);
update_ship_work_vdf_4_core(action,ship);
}
fn MovePositiveYMedium(action){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.y,"y",10,50,5);
update_ship_work_vdf_12_core(action,ship);
}
fn MovePositiveYLarge(action){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.y,"y",100,250,25);
update_ship_work_vdf_28_core(action,ship);
}
fn MoveNegativeY(action){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.y,"y",1,10,1);
update_ship_work_vdf_4_core(action,ship);
}
fn MoveNegativeYMedium(action){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.y,"y",10,50,5);
update_ship_work_vdf_12_core(action,ship);
}
fn MoveNegativeYLarge(action){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.y,"y",100,250,25);
update_ship_work_vdf_28_core(action,ship);
}
fn MovePositiveZ(action){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.z,"z",1,10,1);
update_ship_work_vdf_4_core(action,ship);
}
fn MovePositiveZMedium(action){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.z,"z",10,50,5);
update_ship_work_vdf_12_core(action,ship);
}
fn MovePositiveZLarge(action){
var ship=action.mutate("microverse__ship");
move_positive_core(action,ship,ship.z,"z",100,250,25);
update_ship_work_vdf_28_core(action,ship);
}
fn MoveNegativeZ(action){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.z,"z",1,10,1);
update_ship_work_vdf_4_core(action,ship);
}
fn MoveNegativeZMedium(action){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.z,"z",10,50,5);
update_ship_work_vdf_12_core(action,ship);
}
fn MoveNegativeZLarge(action){
var ship=action.mutate("microverse__ship");
move_negative_core(action,ship,ship.z,"z",100,250,25);
update_ship_work_vdf_28_core(action,ship);
}
fn TimeWarpSmall(action){
var ship=action.mutate("microverse__ship");
action.st_sum(ship.extraction_amount,0,10);
action.st_sum(ship.rare_extraction_amount,0,1);
var next_epoch=unsafe{ship.epoch-(0-1)};
action.st_sum(ship.epoch,1,next_epoch);
advance_ship_epoch_core(action,ship,next_epoch);
update_ship_work_vdf_4_core(action,ship);
}
fn TimeWarpMedium(action){
var ship=action.mutate("microverse__ship");
action.st_sum(ship.extraction_amount,0,50);
action.st_sum(ship.rare_extraction_amount,0,5);
var next_epoch=unsafe{ship.epoch-(0-10)};
action.st_sum(ship.epoch,10,next_epoch);
advance_ship_epoch_core(action,ship,next_epoch);
update_ship_work_vdf_12_core(action,ship);
}
fn TimeWarpLarge(action){
var ship=action.mutate("microverse__ship");
action.st_sum(ship.extraction_amount,0,250);
action.st_sum(ship.rare_extraction_amount,0,25);
var next_epoch=unsafe{ship.epoch-(0-100)};
action.st_sum(ship.epoch,100,next_epoch);
advance_ship_epoch_core(action,ship,next_epoch);
update_ship_work_vdf_28_core(action,ship);
}
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
var next_claim_serial=unsafe{ship.claim_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
action.st_sum(ship.claim_serial,1,next_claim_serial);
ship.update("active_skill_type",0);
ship.update("action_serial",next_action_serial);
ship.update("claim_serial",next_claim_serial);
var next_ship_key=action.random();
ship.update("key",next_ship_key);
}
fn SurveySector_01_Sparse(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
let survey_selector_upper=action.top_limb_u256(-7413177527517650715);
action.intro_lt_eq_u256(sector,survey_selector_upper);
survey_replacement_ship_core(action,next_ship,ship,sector);
action.st_gt(ship.claim_serial,3);
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
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
let survey_selector_lower=action.top_limb_u256(-7413177527517650714);
action.intro_lt_eq_u256(survey_selector_lower,sector);
let survey_selector_upper=action.top_limb_u256(-1896394254421700264);
action.intro_lt_eq_u256(sector,survey_selector_upper);
survey_replacement_ship_core(action,next_ship,ship,sector);
action.st_gt(ship.claim_serial,7);
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
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
let survey_selector_lower=action.top_limb_u256(-1896394254421700263);
action.intro_lt_eq_u256(survey_selector_lower,sector);
let survey_selector_upper=action.top_limb_u256(-517198436147712651);
action.intro_lt_eq_u256(sector,survey_selector_upper);
survey_replacement_ship_core(action,next_ship,ship,sector);
action.st_gt(ship.claim_serial,31);
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
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
let survey_selector_lower=action.top_limb_u256(-517198436147712650);
action.intro_lt_eq_u256(survey_selector_lower,sector);
let survey_selector_upper=action.top_limb_u256(-172399481579215748);
action.intro_lt_eq_u256(sector,survey_selector_upper);
survey_replacement_ship_core(action,next_ship,ship,sector);
action.st_gt(ship.claim_serial,127);
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
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
let survey_selector_lower=action.top_limb_u256(-172399481579215747);
action.intro_lt_eq_u256(survey_selector_lower,sector);
survey_replacement_ship_core(action,next_ship,ship,sector);
action.st_gt(ship.claim_serial,255);
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
fn DetectCelestialSignal_00_RedDwarf(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,2,-1,"star_remaining","next_star_serial");
}
fn DetectCelestialSignal_01_MainSequenceStar(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,2,-1,"star_remaining","next_star_serial");
}
fn DetectCelestialSignal_02_GiantStar(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,2,-1,"star_remaining","next_star_serial");
}
fn DetectCelestialSignal_03_RockyPlanet(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,1,-1,"planet_remaining","next_planet_serial");
}
fn DetectCelestialSignal_04_OceanPlanet(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,1,-1,"planet_remaining","next_planet_serial");
}
fn DetectCelestialSignal_05_GardenPlanet(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,1,-1,"planet_remaining","next_planet_serial");
}
fn DetectCelestialSignal_06_GasGiant(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,3,-1,"gas_giant_remaining","next_gas_giant_serial");
}
fn DetectCelestialSignal_07_IceGiant(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,4,-1,"ice_giant_remaining","next_ice_giant_serial");
}
fn DetectCelestialSignal_08_BarrenPlanet(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,1,-1,"planet_remaining","next_planet_serial");
}
fn DetectCelestialSignal_09_NeutronStar(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,5,-1,"neutron_star_remaining","next_neutron_star_serial");
}
fn DetectCelestialSignal_10_BlackHole(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,6,-1,"black_hole_remaining","next_black_hole_serial");
}
fn DetectCelestialSignal_11_Anomaly(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,7,-1,"anomaly_remaining","next_anomaly_serial");
}
fn DetectCelestialSignal_12_Megastructure(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,8,-1,"megastructure_remaining","next_megastructure_serial");
}
fn DetectCelestialSignal_13_GasCluster(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,9,-1,"gas_cluster_remaining","next_gas_cluster_serial");
}
fn DetectCelestialSignal_14_StellarRemnant(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,10,-1,"stellar_remnant_remaining","next_stellar_remnant_serial");
}
fn DetectCelestialSignal_15_AsteroidBelt(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,11,-1,"minor_body_field_remaining","next_minor_body_field_serial");
}
fn DetectCelestialSignal_16_VolcanicPlanet(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,1,-1,"planet_remaining","next_planet_serial");
}
fn DetectCelestialSignal_17_Nebula(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,9,-1,"gas_cluster_remaining","next_gas_cluster_serial");
}
fn DetectCelestialSignal_18_CometCluster(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,11,-1,"minor_body_field_remaining","next_minor_body_field_serial");
}
fn DetectCelestialSignal_19_BrownDwarf(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,2,-1,"star_remaining","next_star_serial");
}
fn DetectCelestialSignal_20_WhiteDwarf(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,10,-1,"stellar_remnant_remaining","next_stellar_remnant_serial");
}
fn DetectCelestialSignal_21_Magnetar(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,5,-1,"neutron_star_remaining","next_neutron_star_serial");
}
fn DetectCelestialSignal_22_WormholeMouth(action){
var next_ship=action.output("microverse__ship");
var signal=action.output("microverse__celestial_signal");
var ship=action.input("microverse__ship");
var sector=action.mutate("microverse__sector");
detect_signal_core(action,next_ship,signal,ship,sector,7,-1,"anomaly_remaining","next_anomaly_serial");
}
fn ScanCelestialBody_00_RedDwarf(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_upper=action.top_limb_u256(-4222748646691076960);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,2,0,2,0,4000,0,4000,22000,0);
}
fn ScanCelestialBody_01_MainSequenceStar(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(-4222748646691076959);
action.intro_lt_eq_u256(body_selector_lower,signal);
let body_selector_upper=action.top_limb_u256(-666749789936458296);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,2,1,2,0,3000,0,4000,27000,0);
}
fn ScanCelestialBody_02_GiantStar(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(-666749789936458295);
action.intro_lt_eq_u256(body_selector_lower,signal);
let body_selector_upper=action.top_limb_u256(-222249932842130963);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,2,2,2,0,3000,0,4000,33000,0);
}
fn ScanCelestialBody_03_RockyPlanet(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_upper=action.top_limb_u256(7976970408395495921);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,1,3,1,0,19000,5000,3000,3000,1);
}
fn ScanCelestialBody_04_OceanPlanet(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(7976970408395495922);
action.intro_lt_eq_u256(body_selector_lower,signal);
let body_selector_upper=action.top_limb_u256(-8475531063215181714);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,1,4,1,0,14000,3000,14000,3000,2);
}
fn ScanCelestialBody_05_GardenPlanet(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(-8475531063215181713);
action.intro_lt_eq_u256(body_selector_lower,signal);
let body_selector_upper=action.top_limb_u256(-7976970412690463219);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,1,5,1,0,17000,9000,6000,6000,1);
}
fn ScanCelestialBody_06_GasGiant(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
scan_body_core(action,body,signal,ship,3,6,3,0,2000,0,24000,6000,4);
}
fn ScanCelestialBody_07_IceGiant(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
scan_body_core(action,body,signal,ship,4,7,4,0,4000,9000,17000,4000,3);
}
fn ScanCelestialBody_08_BarrenPlanet(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(-7976970412690463218);
action.intro_lt_eq_u256(body_selector_lower,signal);
let body_selector_upper=action.top_limb_u256(-3988485208492715258);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,1,8,1,0,23000,9000,0,0,0);
}
fn ScanCelestialBody_09_NeutronStar(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,5,9,5,0,2000,1000,0,43000,0);
}
fn ScanCelestialBody_10_BlackHole(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
scan_body_core(action,body,signal,ship,6,10,6,0,0,0,0,50000,0);
}
fn ScanCelestialBody_11_Anomaly(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,7,11,7,0,18000,9000,9000,18000,0);
}
fn ScanCelestialBody_12_Megastructure(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
scan_body_core(action,body,signal,ship,8,12,8,0,10000,10000,0,10000,0);
}
fn ScanCelestialBody_13_GasCluster(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_upper=action.top_limb_u256(-3689348818177884161);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,9,13,9,0,5000,0,20000,5000,0);
}
fn ScanCelestialBody_14_StellarRemnant(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_upper=action.top_limb_u256(-142998020336940818);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,10,14,10,0,10000,0,0,20000,0);
}
fn ScanCelestialBody_15_AsteroidBelt(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_upper=action.top_limb_u256(-2049638234229921110);
action.intro_lt_eq_u256(signal,body_selector_upper);
scan_body_core(action,body,signal,ship,11,15,11,0,18000,8000,0,4000,0);
}
fn ScanCelestialBody_16_VolcanicPlanet(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(-3988485208492715257);
action.intro_lt_eq_u256(body_selector_lower,signal);
scan_body_core(action,body,signal,ship,1,16,1,0,16000,0,4000,12000,1);
}
fn ScanCelestialBody_17_Nebula(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(-3689348818177884160);
action.intro_lt_eq_u256(body_selector_lower,signal);
scan_body_core(action,body,signal,ship,9,17,9,0,2000,0,26000,6000,0);
}
fn ScanCelestialBody_18_CometCluster(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(-2049638234229921109);
action.intro_lt_eq_u256(body_selector_lower,signal);
scan_body_core(action,body,signal,ship,11,18,11,0,4000,14000,16000,2000,0);
}
fn ScanCelestialBody_19_BrownDwarf(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(-222249932842130962);
action.intro_lt_eq_u256(body_selector_lower,signal);
scan_body_core(action,body,signal,ship,2,19,2,0,6000,0,24000,12000,0);
}
fn ScanCelestialBody_20_WhiteDwarf(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(-142998020336940817);
action.intro_lt_eq_u256(body_selector_lower,signal);
scan_body_core(action,body,signal,ship,10,20,10,0,20000,16000,0,8000,0);
}
fn ScanCelestialBody_21_Magnetar(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(body_selector_lower,signal);
scan_body_core(action,body,signal,ship,5,21,5,0,4000,12000,0,32000,0);
}
fn ScanCelestialBody_22_WormholeMouth(action){
var body=action.output("microverse__celestial_body");
var signal=action.input("microverse__celestial_signal");
var ship=action.mutate("microverse__ship");
let body_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(body_selector_lower,signal);
scan_body_core(action,body,signal,ship,7,22,7,0,6000,6000,0,40000,0);
}
fn ExtractAnomalyWarpCoordinate(action){
var next_ship=action.output("microverse__ship");
var coordinate=action.output("microverse__warp_coordinate");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(body.sector_x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(body.sector_y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(body.sector_z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(body.sector_epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
action.st_sum(ship.extraction_amount,0,250);
action.st_sum(ship.rare_extraction_amount,0,25);
action.st_sum(ship.active_skill_type,0,14);
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
var next_ship=action.output("microverse__ship");
var coordinate=action.output("microverse__time_coordinate");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(body.sector_x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(body.sector_y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(body.sector_z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(body.sector_epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
action.st_sum(ship.extraction_amount,0,250);
action.st_sum(ship.rare_extraction_amount,0,25);
action.st_sum(ship.active_skill_type,0,14);
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
fn RevealWarpCoordinate001(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,1,793814733,968149119310,42019687806,10,17999);
}
fn RevealWarpCoordinate002(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,2,327853439873,605502947,3102,3,9000);
}
fn RevealWarpCoordinate003(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,3,105,465107091,86018776812,3,9000);
}
fn RevealWarpCoordinate004(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,4,814097886,251671466,624,3,9000);
}
fn RevealWarpCoordinate005(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,5,9816070892,17687307174,1647,1,8999);
}
fn RevealWarpCoordinate006(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,6,5411,4089311236,8166194,1,8999);
}
fn RevealWarpCoordinate007(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,7,3554,138474846290,2683096595,1,8999);
}
fn RevealWarpCoordinate008(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,8,304051388063,1555081630477,862,1,8999);
}
fn RevealWarpCoordinate009(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,9,1599211110330,835802248014,61425,1,8999);
}
fn RevealWarpCoordinate010(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,10,8800041,92923,6899663,1,8999);
}
fn RevealWarpCoordinate011(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,11,36941537,718644,90633,1,8999);
}
fn RevealWarpCoordinate012(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,12,9337934020,267915,612152605,1,8999);
}
fn RevealWarpCoordinate013(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,13,6744467,1242490000981,7902244,1,8999);
}
fn RevealWarpCoordinate014(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,14,38345967539,850429340,697145654,1,8999);
}
fn RevealWarpCoordinate015(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,15,5999015,56856983,64952,1,8999);
}
fn RevealWarpCoordinate016(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,16,74640977,831224,67427465431,1,8999);
}
fn RevealWarpCoordinate017(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,17,612742724029,1842615838159,620841,1,8999);
}
fn RevealWarpCoordinate018(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,18,79068746,3516959,57065984,1,8999);
}
fn RevealWarpCoordinate019(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,19,51382549782,5528417226,62111104,1,8999);
}
fn RevealWarpCoordinate020(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,20,76219270,80009,1703747360730,1,8999);
}
fn RevealWarpCoordinate021(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,21,1795412047697,845871,415,1,8999);
}
fn RevealWarpCoordinate022(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,22,660848117667,271400,334705,1,8999);
}
fn RevealWarpCoordinate023(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,23,316245807504,1644,428363,1,8999);
}
fn RevealWarpCoordinate024(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,24,402293889292,351046010,59250682625,1,8999);
}
fn RevealWarpCoordinate025(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,25,24491,49227,1029107766704,1,8999);
}
fn RevealWarpCoordinate026(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,26,891311451115,481989,9218437,1,8999);
}
fn RevealWarpCoordinate027(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,27,5364,979,61474,1,8999);
}
fn RevealWarpCoordinate028(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,28,7511717098,23973543873,576929938269,1,8999);
}
fn RevealWarpCoordinate029(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,29,49656048395,8956,1622146405114,1,8999);
}
fn RevealWarpCoordinate030(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,30,86575726573,951729416101,725,1,8999);
}
fn RevealWarpCoordinate031(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,31,66964245769,3641,1929443695472,1,8999);
}
fn RevealWarpCoordinate032(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,32,3328235205,8159725451,161,1,8999);
}
fn RevealWarpCoordinate033(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,33,39759057,101660631,674,1,8999);
}
fn RevealWarpCoordinate034(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,34,6685,92082552830,54238,1,8999);
}
fn RevealWarpCoordinate035(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,35,14974427,98934823,1819704510913,1,8999);
}
fn RevealWarpCoordinate036(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,36,24944230017,147614734,2500243663,1,8999);
}
fn RevealWarpCoordinate037(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,37,646052251,663494,81352378,1,8999);
}
fn RevealWarpCoordinate038(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,38,372316739,7938120392,1075364813302,1,8999);
}
fn RevealWarpCoordinate039(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,39,1166628200,10526279194,830059075497,1,8999);
}
fn RevealWarpCoordinate040(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,40,210,7442044,1316754193677,1,8999);
}
fn RevealWarpCoordinate041(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,41,38900,4723,6321753,1,8999);
}
fn RevealWarpCoordinate042(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,42,1996409208667,368553358663,1734922,1,8999);
}
fn RevealWarpCoordinate043(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,43,288,6586,19494804,1,8999);
}
fn RevealWarpCoordinate044(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,44,485,422411318214,2619205,1,8999);
}
fn RevealWarpCoordinate045(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,45,966,533868729796,590961427322,1,8999);
}
fn RevealWarpCoordinate046(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,46,52502323784,78133,454,1,8999);
}
fn RevealWarpCoordinate047(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,47,76703948680,9860,11948,1,8999);
}
fn RevealWarpCoordinate048(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,48,314,71372,270745696569,1,8999);
}
fn RevealWarpCoordinate049(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,49,68339007,806,1971315750,1,8999);
}
fn RevealWarpCoordinate050(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,50,5137455393,944693917055,3458525209,1,8999);
}
fn RevealWarpCoordinate051(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,51,1353,21802810,252999300494,1,8999);
}
fn RevealWarpCoordinate052(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,52,4680,9185,868,1,8999);
}
fn RevealWarpCoordinate053(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,53,7524306,350843987584,202765,1,8999);
}
fn RevealWarpCoordinate054(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,54,7632689,1936956092484,469012280963,1,8999);
}
fn RevealWarpCoordinate055(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,55,614439419610,827189,112195927905,1,8999);
}
fn RevealWarpCoordinate056(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,56,582061892477,20141524,8472773550,1,8999);
}
fn RevealWarpCoordinate057(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,57,1573688960761,7976,137,1,8999);
}
fn RevealWarpCoordinate058(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,58,3986,1261757673690,66936285117,1,8999);
}
fn RevealWarpCoordinate059(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,59,729009262,372761,626730552,1,8999);
}
fn RevealWarpCoordinate060(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,60,1104055358028,86077,441,1,8999);
}
fn RevealWarpCoordinate061(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,61,52596109189,3933090003,4456,1,8999);
}
fn RevealWarpCoordinate062(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,62,751694,53701,1314934400969,1,8999);
}
fn RevealWarpCoordinate063(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,63,674369454170,1293446417136,392714,1,8999);
}
fn RevealWarpCoordinate064(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,64,175503070271,6129473553,861604111960,1,8999);
}
fn RevealWarpCoordinate065(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,65,5834724,3286,524,1,8999);
}
fn RevealWarpCoordinate066(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,66,97441800,90047032,53343231,1,8999);
}
fn RevealWarpCoordinate067(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,67,138301,5743516,1938696380619,1,8999);
}
fn RevealWarpCoordinate068(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,68,858558,564867,7888191,1,8999);
}
fn RevealWarpCoordinate069(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,69,825683632839,700275972037,783698141526,1,8999);
}
fn RevealWarpCoordinate070(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,70,70325858,332752,18666153827,1,8999);
}
fn RevealWarpCoordinate071(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,71,4959023,90901641829,17537364,1,8999);
}
fn RevealWarpCoordinate072(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,72,79640,353359,48880,1,8999);
}
fn RevealWarpCoordinate073(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,73,14944048679,5098196192,412,1,8999);
}
fn RevealWarpCoordinate074(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,74,59136791,1445698873532,85863,1,8999);
}
fn RevealWarpCoordinate075(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,75,685809,1497175958752,8978,1,8999);
}
fn RevealWarpCoordinate076(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,76,5246715487,34680434180,295007845,1,8999);
}
fn RevealWarpCoordinate077(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,77,62585671,3692,649793205,1,8999);
}
fn RevealWarpCoordinate078(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,78,1072393121557,228742,26765,1,8999);
}
fn RevealWarpCoordinate079(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,79,915,1443398724083,8138707380,1,8999);
}
fn RevealWarpCoordinate080(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,80,549,5269348966,1682994349116,1,8999);
}
fn RevealWarpCoordinate081(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,81,6647239013,6275506,9077600,1,8999);
}
fn RevealWarpCoordinate082(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,82,8459930015,762,1651,1,8999);
}
fn RevealWarpCoordinate083(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,83,9934711,1258299,59728098252,1,8999);
}
fn RevealWarpCoordinate084(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,84,710,7606736,1557909202223,1,8999);
}
fn RevealWarpCoordinate085(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,85,299,66523168873,284626892275,1,8999);
}
fn RevealWarpCoordinate086(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,86,6152982,7754874715,297911415,1,8999);
}
fn RevealWarpCoordinate087(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,87,78887,1027431,8413,1,8999);
}
fn RevealWarpCoordinate088(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,88,44634,14327071,942410917,1,8999);
}
fn RevealWarpCoordinate089(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,89,149566,44461313485,602,1,8999);
}
fn RevealWarpCoordinate090(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,90,9123,915028640,90641,1,8999);
}
fn RevealWarpCoordinate091(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,91,398540000679,8784213,5356,1,8999);
}
fn RevealWarpCoordinate092(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,92,34771,84430,7861,1,8999);
}
fn RevealWarpCoordinate093(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,93,2534239576,3469374,1106468458539,1,8999);
}
fn RevealWarpCoordinate094(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,94,983822125,895056,335156,1,8999);
}
fn RevealWarpCoordinate095(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,95,3277916,15182044245,28749,1,8999);
}
fn RevealWarpCoordinate096(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,96,3405252341,601743,331027450969,1,8999);
}
fn RevealWarpCoordinate097(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,97,7642808796,1094001984094,79759561924,1,8999);
}
fn RevealWarpCoordinate098(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,98,903829411,904830290312,459,1,8999);
}
fn RevealWarpCoordinate099(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,99,4676559,114518980363,856,1,8999);
}
fn RevealWarpCoordinate100(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,100,766,26758237583,9707,1,8999);
}
fn RevealWarpCoordinate101(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,101,82778400,8860,362295963,1,8999);
}
fn RevealWarpCoordinate102(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,102,1596782367732,1267532572787,39058994718,1,8999);
}
fn RevealWarpCoordinate103(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,103,6045,5859608,1389083,1,8999);
}
fn RevealWarpCoordinate104(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,104,6949,8797833047,50774,1,8999);
}
fn RevealWarpCoordinate105(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,105,798,602,9936325343,1,8999);
}
fn RevealWarpCoordinate106(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,106,788045056049,1060,1644224548739,1,8999);
}
fn RevealWarpCoordinate107(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,107,772432026,1280668882809,1916324341020,1,8999);
}
fn RevealWarpCoordinate108(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,108,3378640,33285937,230946158499,1,8999);
}
fn RevealWarpCoordinate109(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,109,647133815143,5858,1127510,1,8999);
}
fn RevealWarpCoordinate110(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,110,658,44707717,373,1,8999);
}
fn RevealWarpCoordinate111(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,111,4960689,541034,32943629,1,8999);
}
fn RevealWarpCoordinate112(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,112,608860492110,185294125,103,1,8999);
}
fn RevealWarpCoordinate113(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,113,799422578687,1960183226040,111,1,8999);
}
fn RevealWarpCoordinate114(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,114,6945298,13302745,483914,1,8999);
}
fn RevealWarpCoordinate115(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,115,78332954177,707991091435,4786950492,1,8999);
}
fn RevealWarpCoordinate116(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,116,323464621723,860,614040324083,1,8999);
}
fn RevealWarpCoordinate117(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,117,33422934605,447154297,71851297056,1,8999);
}
fn RevealWarpCoordinate118(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,118,4643524785,8617199432,274,1,8999);
}
fn RevealWarpCoordinate119(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,119,908538877625,921,2870139,1,8999);
}
fn RevealWarpCoordinate120(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,120,5446223406,1619077126727,1703,1,8999);
}
fn RevealWarpCoordinate121(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,121,659,717811,90078,1,8999);
}
fn RevealWarpCoordinate122(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,122,19944,555485,882,1,8999);
}
fn RevealWarpCoordinate123(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,123,1385638833787,982971504292,58613,1,8999);
}
fn RevealWarpCoordinate124(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,124,1244899207058,43514054064,35564,1,8999);
}
fn RevealWarpCoordinate125(action){
var c=action.mutate("microverse__warp_coordinate");
reveal_p(action,c,125,7032978,1559777421188,362706019,1,8999);
}
fn RevealTimeCoordinate01(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,1,101,10,17999);
}
fn RevealTimeCoordinate02(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,2,19257,3,9000);
}
fn RevealTimeCoordinate03(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,3,306610,3,9000);
}
fn RevealTimeCoordinate04(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,4,1551806,3,9000);
}
fn RevealTimeCoordinate05(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,5,4904256,1,8999);
}
fn RevealTimeCoordinate06(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,6,11973137,1,8999);
}
fn RevealTimeCoordinate07(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,7,24827389,1,8999);
}
fn RevealTimeCoordinate08(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,8,45995718,1,8999);
}
fn RevealTimeCoordinate09(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,9,78466594,1,8999);
}
fn RevealTimeCoordinate10(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,10,125688251,1,8999);
}
fn RevealTimeCoordinate11(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,11,191568688,1,8999);
}
fn RevealTimeCoordinate12(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,12,280475669,1,8999);
}
fn RevealTimeCoordinate13(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,13,397236724,1,8999);
}
fn RevealTimeCoordinate14(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,14,547139143,1,8999);
}
fn RevealTimeCoordinate15(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,15,735929986,1,8999);
}
fn RevealTimeCoordinate16(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,16,969816075,1,8999);
}
fn RevealTimeCoordinate17(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,17,1255463996,1,8999);
}
fn RevealTimeCoordinate18(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,18,1600000100,1,8999);
}
fn RevealTimeCoordinate19(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,19,2011010505,1,8999);
}
fn RevealTimeCoordinate20(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,20,2496541090,1,8999);
}
fn RevealTimeCoordinate21(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,21,3065097501,1,8999);
}
fn RevealTimeCoordinate22(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,22,3725645147,1,8999);
}
fn RevealTimeCoordinate23(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,23,4487609204,1,8999);
}
fn RevealTimeCoordinate24(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,24,5360874611,1,8999);
}
fn RevealTimeCoordinate25(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,25,6355786070,1,8999);
}
fn RevealTimeCoordinate26(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,26,7483148051,1,8999);
}
fn RevealTimeCoordinate27(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,27,8754224786,1,8999);
}
fn RevealTimeCoordinate28(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,28,10180740273,1,8999);
}
fn RevealTimeCoordinate29(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,29,11774878274,1,8999);
}
fn RevealTimeCoordinate30(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,30,13549282316,1,8999);
}
fn RevealTimeCoordinate31(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,31,15517055690,1,8999);
}
fn RevealTimeCoordinate32(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,32,17691761452,1,8999);
}
fn RevealTimeCoordinate33(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,33,20087422423,1,8999);
}
fn RevealTimeCoordinate34(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,34,22718521189,1,8999);
}
fn RevealTimeCoordinate35(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,35,25600000098,1,8999);
}
fn RevealTimeCoordinate36(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,36,28747261265,1,8999);
}
fn RevealTimeCoordinate37(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,37,32176166570,1,8999);
}
fn RevealTimeCoordinate38(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,38,35903037656,1,8999);
}
fn RevealTimeCoordinate39(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,39,39944655931,1,8999);
}
fn RevealTimeCoordinate40(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,40,44318262569,1,8999);
}
fn RevealTimeCoordinate41(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,41,49041558506,1,8999);
}
fn RevealTimeCoordinate42(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,42,54132704445,1,8999);
}
fn RevealTimeCoordinate43(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,43,59610320852,1,8999);
}
fn RevealTimeCoordinate44(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,44,65493487959,1,8999);
}
fn RevealTimeCoordinate45(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,45,71801745762,1,8999);
}
fn RevealTimeCoordinate46(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,46,78555094021,1,8999);
}
fn RevealTimeCoordinate47(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,47,85773992261,1,8999);
}
fn RevealTimeCoordinate48(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,48,93479359773,1,8999);
}
fn RevealTimeCoordinate49(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,49,101692575610,1,8999);
}
fn RevealTimeCoordinate50(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,50,110435478592,1,8999);
}
fn RevealTimeCoordinate51(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,51,119730367301,1,8999);
}
fn RevealTimeCoordinate52(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,52,129600000087,1,8999);
}
fn RevealTimeCoordinate53(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,53,140067595062,1,8999);
}
fn RevealTimeCoordinate54(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,54,151156830104,1,8999);
}
fn RevealTimeCoordinate55(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,55,162891842854,1,8999);
}
fn RevealTimeCoordinate56(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,56,175297230719,1,8999);
}
fn RevealTimeCoordinate57(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,57,188398050871,1,8999);
}
fn RevealTimeCoordinate58(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,58,202219820245,1,8999);
}
fn RevealTimeCoordinate59(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,59,216788515542,1,8999);
}
fn RevealTimeCoordinate60(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,60,232130573226,1,8999);
}
fn RevealTimeCoordinate61(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,61,248272889528,1,8999);
}
fn RevealTimeCoordinate62(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,62,265242820442,1,8999);
}
fn RevealTimeCoordinate63(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,63,283068181727,1,8999);
}
fn RevealTimeCoordinate64(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,64,301777248905,1,8999);
}
fn RevealTimeCoordinate65(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,65,321398757267,1,8999);
}
fn RevealTimeCoordinate66(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,66,341961901863,1,8999);
}
fn RevealTimeCoordinate67(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,67,363496337511,1,8999);
}
fn RevealTimeCoordinate68(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,68,386032178795,1,8999);
}
fn RevealTimeCoordinate69(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,69,409600000059,1,8999);
}
fn RevealTimeCoordinate70(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,70,434230835415,1,8999);
}
fn RevealTimeCoordinate71(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,71,459956178739,1,8999);
}
fn RevealTimeCoordinate72(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,72,486807983672,1,8999);
}
fn RevealTimeCoordinate73(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,73,514818663618,1,8999);
}
fn RevealTimeCoordinate74(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,74,544021091746,1,8999);
}
fn RevealTimeCoordinate75(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,75,574448600993,1,8999);
}
fn RevealTimeCoordinate76(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,76,606134984055,1,8999);
}
fn RevealTimeCoordinate77(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,77,639114493396,1,8999);
}
fn RevealTimeCoordinate78(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,78,673421841245,1,8999);
}
fn RevealTimeCoordinate79(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,79,709092199595,1,8999);
}
fn RevealTimeCoordinate80(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,80,746161200202,1,8999);
}
fn RevealTimeCoordinate81(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,81,784664934588,1,8999);
}
fn RevealTimeCoordinate82(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,82,824639954040,1,8999);
}
fn RevealTimeCoordinate83(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,83,866123269609,1,8999);
}
fn RevealTimeCoordinate84(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,84,909152352111,1,8999);
}
fn RevealTimeCoordinate85(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,85,953765132126,1,8999);
}
fn RevealTimeCoordinate86(action){
var c=action.mutate("microverse__time_coordinate");
reveal_t(action,c,86,999999999999,1,8999);
}
fn WarpToCoordinateReusable(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
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
warp_ship_core(action,next_ship,ship,coordinate.destination_x,coordinate.destination_y,coordinate.destination_z,ship.epoch);
coordinate.update("uses_remaining",next_uses);
var next_coordinate_key=action.random();
rotate_key(coordinate,next_coordinate_key);
}
fn WarpToCoordinateFinal(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
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
warp_ship_core(action,next_ship,ship,coordinate.destination_x,coordinate.destination_y,coordinate.destination_z,ship.epoch);
}
fn TimeWarpToCoordinateReusable(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var coordinate=action.mutate("microverse__time_coordinate");
prove_fixed_versions(action,coordinate);
action.st_sum(coordinate.revealed,0,1);
action.st_gt(coordinate.uses_remaining,1);
var next_uses=unsafe{coordinate.uses_remaining-1};
action.st_sum(next_uses,1,coordinate.uses_remaining);
action.st_gt(coordinate.destination_epoch,-1);
action.st_gt(1000000000000,coordinate.destination_epoch);
warp_ship_core(action,next_ship,ship,ship.x,ship.y,ship.z,coordinate.destination_epoch);
coordinate.update("uses_remaining",next_uses);
var next_coordinate_key=action.random();
rotate_key(coordinate,next_coordinate_key);
}
fn TimeWarpToCoordinateFinal(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var coordinate=action.input("microverse__time_coordinate");
prove_fixed_versions(action,coordinate);
action.st_sum(coordinate.revealed,0,1);
action.st_sum(coordinate.uses_remaining,0,1);
action.st_gt(coordinate.destination_epoch,-1);
action.st_gt(1000000000000,coordinate.destination_epoch);
warp_ship_core(action,next_ship,ship,ship.x,ship.y,ship.z,coordinate.destination_epoch);
}
fn ExtractWormholeWarpChart(action){
var next_ship=action.output("microverse__ship");
var chart=action.output("microverse__warp_chart");
var ship=action.input("microverse__ship");
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
extract_v2_chart_core(action,next_ship,ship,body,11);
var work=action.intro_vdf(20,chart);
chart.update("work",work);
}
fn ExtractWormholeEpochChart(action){
var next_ship=action.output("microverse__ship");
var chart=action.output("microverse__epoch_chart");
var ship=action.input("microverse__ship");
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
extract_v2_chart_core(action,next_ship,ship,body,14);
var work=action.intro_vdf(20,chart);
chart.update("work",work);
}
fn RevealWarpChart001(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,1,10074,27336,51216,10,39999);
}
fn RevealWarpChart002(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,2,22972,21819,73251,3,30999);
}
fn RevealWarpChart003(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,3,72118143059,19385760590,24402608302,3,30999);
}
fn RevealWarpChart004(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,4,9251,47339,16649,3,30999);
}
fn RevealWarpChart005(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,5,206798275818,357091429978,559758623041,1,8999);
}
fn RevealWarpChart006(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,6,697832863,966128739,177061565,1,8999);
}
fn RevealWarpChart007(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,7,129484832,336090293,374648868,1,8999);
}
fn RevealWarpChart008(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,8,407956798083,255122953869,416372122780,1,8999);
}
fn RevealWarpChart009(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,9,88345,69185,87297,1,8999);
}
fn RevealWarpChart010(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,10,8901706,6451406,3019501,1,8999);
}
fn RevealWarpChart011(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,11,175780501,340325116,423347817,1,8999);
}
fn RevealWarpChart012(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,12,591736257636,143637332366,846205944460,1,8999);
}
fn RevealWarpChart013(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,13,69369,95310,87762,1,8999);
}
fn RevealWarpChart014(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,14,472438204,344741778,354298221,1,8999);
}
fn RevealWarpChart015(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,15,94840345287,89880600245,45659369001,1,8999);
}
fn RevealWarpChart016(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,16,5946323,5207367,1938946,1,8999);
}
fn RevealWarpChart017(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,17,1287758145479,1171386338485,1470168285736,1,8999);
}
fn RevealWarpChart018(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,18,43894798840,2770603724,94517650206,1,8999);
}
fn RevealWarpChart019(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,19,821281959111,818293342296,237664167479,1,8999);
}
fn RevealWarpChart020(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,20,5732599,5965324,3890012,1,8999);
}
fn RevealWarpChart021(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,21,73481133505,43098666725,79679375168,1,8999);
}
fn RevealWarpChart022(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,22,518174208,704639602,583068452,1,8999);
}
fn RevealWarpChart023(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,23,1568829907566,1633844743861,1000686091903,1,8999);
}
fn RevealWarpChart024(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,24,116456971,657441882,571786180,1,8999);
}
fn RevealWarpChart025(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,25,2632589,8258162,1962019,1,8999);
}
fn RevealWarpChart026(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,26,419671824582,903953066772,760785892021,1,8999);
}
fn RevealWarpChart027(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,27,9814145,7134937,5112582,1,8999);
}
fn RevealWarpChart028(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,28,924420380134,929850584933,472323161867,1,8999);
}
fn RevealWarpChart029(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,29,779099814,973407085,179575265,1,8999);
}
fn RevealWarpChart030(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,30,7623691,3412132,8653143,1,8999);
}
fn RevealWarpChart031(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,31,35657479123,82561883462,68859217663,1,8999);
}
fn RevealWarpChart032(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,32,97397,89248,70911,1,8999);
}
fn RevealWarpChart033(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,33,73228,55911,55313,1,8999);
}
fn RevealWarpChart034(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,34,4860363,1504063,2727096,1,8999);
}
fn RevealWarpChart035(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,35,4185659,7251031,3864918,1,8999);
}
fn RevealWarpChart036(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,36,986300365192,390772761610,267957633155,1,8999);
}
fn RevealWarpChart037(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,37,8762001,878999,5291426,1,8999);
}
fn RevealWarpChart038(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,38,3930396294,57577939222,61170847618,1,8999);
}
fn RevealWarpChart039(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,39,100539545,812641514,904812733,1,8999);
}
fn RevealWarpChart040(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,40,1008841550676,1616066770638,1182483495703,1,8999);
}
fn RevealWarpChart041(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,41,759289157552,127187844480,117808742750,1,8999);
}
fn RevealWarpChart042(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,42,1274832782972,1782293743515,1293644359364,1,8999);
}
fn RevealWarpChart043(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,43,2369750,421781,7305851,1,8999);
}
fn RevealWarpChart044(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,44,1028701687614,1172246496167,1821362932822,1,8999);
}
fn RevealWarpChart045(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,45,41891,14716,26208,1,8999);
}
fn RevealWarpChart046(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,46,33414936720,79388617127,23256941551,1,8999);
}
fn RevealWarpChart047(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,47,743183208,581502474,857786464,1,8999);
}
fn RevealWarpChart048(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,48,5582139399,7411700416,41287490225,1,8999);
}
fn RevealWarpChart049(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,49,437283591,688603927,740673088,1,8999);
}
fn RevealWarpChart050(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,50,503682,6324273,4377833,1,8999);
}
fn RevealWarpChart051(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,51,1785487448810,1968559197516,1328311510116,1,8999);
}
fn RevealWarpChart052(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,52,624707820,503471665,818913195,1,8999);
}
fn RevealWarpChart053(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,53,7537708403,37521084776,99563538503,1,8999);
}
fn RevealWarpChart054(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,54,223,723,296,1,8999);
}
fn RevealWarpChart055(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,55,4000044,2391467,9508312,1,8999);
}
fn RevealWarpChart056(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,56,225,860,371,1,8999);
}
fn RevealWarpChart057(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,57,900707900750,278589988959,219830105586,1,8999);
}
fn RevealWarpChart058(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,58,2813803,7074255,4125989,1,8999);
}
fn RevealWarpChart059(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,59,956814486358,916478176893,845919916361,1,8999);
}
fn RevealWarpChart060(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,60,44215474931,58863561127,35138164990,1,8999);
}
fn RevealWarpChart061(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,61,149847903,453934185,648050718,1,8999);
}
fn RevealWarpChart062(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,62,881,305,518,1,8999);
}
fn RevealWarpChart063(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,63,1814389357,72525172254,31551802762,1,8999);
}
fn RevealWarpChart064(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,64,75179,81084,90371,1,8999);
}
fn RevealWarpChart065(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,65,455753032,535600995,352122384,1,8999);
}
fn RevealWarpChart066(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,66,87834627982,89735847224,52413232999,1,8999);
}
fn RevealWarpChart067(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,67,647021280396,628547072517,918494627285,1,8999);
}
fn RevealWarpChart068(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,68,75267163790,18804405127,74281696123,1,8999);
}
fn RevealWarpChart069(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,69,36133,22410,68940,1,8999);
}
fn RevealWarpChart070(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,70,763768237140,592168606272,485899585145,1,8999);
}
fn RevealWarpChart071(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,71,708,555,468,1,8999);
}
fn RevealWarpChart072(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,72,46104764812,33483415363,55428358523,1,8999);
}
fn RevealWarpChart073(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,73,634609748692,900596716345,911203282001,1,8999);
}
fn RevealWarpChart074(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,74,1401060363379,1425139228247,1370100094792,1,8999);
}
fn RevealWarpChart075(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,75,726958986417,152213505081,682639687448,1,8999);
}
fn RevealWarpChart076(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,76,252,777,593,1,8999);
}
fn RevealWarpChart077(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,77,416848833490,705643221447,440089940899,1,8999);
}
fn RevealWarpChart078(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,78,871604674,792818175,888376863,1,8999);
}
fn RevealWarpChart079(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,79,23163,72227,35439,1,8999);
}
fn RevealWarpChart080(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,80,22328908111,24411973557,42631757450,1,8999);
}
fn RevealWarpChart081(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,81,1202740558102,1283152855311,1649325271410,1,8999);
}
fn RevealWarpChart082(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,82,758777919256,895362603070,401287015240,1,8999);
}
fn RevealWarpChart083(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,83,540304660,30148521,100522816,1,8999);
}
fn RevealWarpChart084(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,84,993437334553,859880626880,536494317527,1,8999);
}
fn RevealWarpChart085(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,85,2005337,9772642,3458503,1,8999);
}
fn RevealWarpChart086(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,86,3042315,791577,4010054,1,8999);
}
fn RevealWarpChart087(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,87,13855346047,96288567914,96636901450,1,8999);
}
fn RevealWarpChart088(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,88,7336391,362050,6982535,1,8999);
}
fn RevealWarpChart089(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,89,4622506,1675076,6679876,1,8999);
}
fn RevealWarpChart090(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,90,298319293,937849991,210707493,1,8999);
}
fn RevealWarpChart091(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,91,598213541,975702891,685848881,1,8999);
}
fn RevealWarpChart092(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,92,1977104175714,1573476306023,1561492130455,1,8999);
}
fn RevealWarpChart093(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,93,9062999,7864414,7924140,1,8999);
}
fn RevealWarpChart094(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,94,2589668,6514773,5391779,1,8999);
}
fn RevealWarpChart095(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,95,67550958631,42684241334,51990585131,1,8999);
}
fn RevealWarpChart096(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,96,295,699,114,1,8999);
}
fn RevealWarpChart097(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,97,370311762335,871137211426,501479487354,1,8999);
}
fn RevealWarpChart098(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,98,1903408,4254737,3835257,1,8999);
}
fn RevealWarpChart099(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,99,1703277215433,1030820697698,1256353283895,1,8999);
}
fn RevealWarpChart100(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,100,740,590,637,1,8999);
}
fn RevealWarpChart101(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,101,634672735,990942104,774868376,1,8999);
}
fn RevealWarpChart102(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,102,93840,85440,20567,1,8999);
}
fn RevealWarpChart103(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,103,957,300,218,1,8999);
}
fn RevealWarpChart104(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,104,4390390,5801879,4189254,1,8999);
}
fn RevealWarpChart105(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,105,1224356642994,1690514233487,1000070951892,1,8999);
}
fn RevealWarpChart106(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,106,281074184,332497431,360763835,1,8999);
}
fn RevealWarpChart107(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,107,38157649633,55298756329,26024298960,1,8999);
}
fn RevealWarpChart108(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,108,710491616,826185728,315592637,1,8999);
}
fn RevealWarpChart109(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,109,1246021392091,1369513950735,1526238360169,1,8999);
}
fn RevealWarpChart110(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,110,94785385616,44887904229,50034370509,1,8999);
}
fn RevealWarpChart111(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,111,991,106,936,1,8999);
}
fn RevealWarpChart112(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,112,875930465,276116087,500052154,1,8999);
}
fn RevealWarpChart113(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,113,1216187239001,1807040461777,1820199712045,1,8999);
}
fn RevealWarpChart114(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,114,956706523485,602863588036,828357347780,1,8999);
}
fn RevealWarpChart115(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,115,6388663,4379681,4489922,1,8999);
}
fn RevealWarpChart116(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,116,609807325,250801583,641325535,1,8999);
}
fn RevealWarpChart117(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,117,846447157,138988398,155961021,1,8999);
}
fn RevealWarpChart118(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,118,31794362432,16333603740,25256873821,1,8999);
}
fn RevealWarpChart119(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,119,460317881967,991814065040,151043852749,1,8999);
}
fn RevealWarpChart120(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,120,6760189,5113540,5964501,1,8999);
}
fn RevealWarpChart121(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,121,1032757414370,1254288232289,1773598556113,1,8999);
}
fn RevealWarpChart122(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,122,10968844439,56305567013,68747067050,1,8999);
}
fn RevealWarpChart123(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,123,75528700444,69780246364,34870109393,1,8999);
}
fn RevealWarpChart124(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,124,2469719,488947,815502,1,8999);
}
fn RevealWarpChart125(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,125,76039,46961,99723,1,8999);
}
fn RevealWarpChart126(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,126,191486,6729424,6254800,1,8999);
}
fn RevealWarpChart127(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,127,69036,3223,45998,1,8999);
}
fn RevealWarpChart128(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,128,35946208719,70008148457,57359493512,1,8999);
}
fn RevealWarpChart129(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,129,92140,1542,13658,1,8999);
}
fn RevealWarpChart130(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,130,97274,68349,10275,1,8999);
}
fn RevealWarpChart131(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,131,15656966542,34809779827,64088266343,1,8999);
}
fn RevealWarpChart132(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,132,61154068365,73899538816,74482556907,1,8999);
}
fn RevealWarpChart133(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,133,43587651028,51297156879,80619413171,1,8999);
}
fn RevealWarpChart134(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,134,66909742400,53519019397,48124492518,1,8999);
}
fn RevealWarpChart135(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,135,24763,62135,66695,1,8999);
}
fn RevealWarpChart136(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,136,8771323,6678346,3260027,1,8999);
}
fn RevealWarpChart137(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,137,43833,13016,36428,1,8999);
}
fn RevealWarpChart138(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,138,92047,64824,4770,1,8999);
}
fn RevealWarpChart139(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,139,89360699101,8836713211,41809933575,1,8999);
}
fn RevealWarpChart140(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,140,285738909,283044676,32121025,1,8999);
}
fn RevealWarpChart141(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,141,813722391124,932342285802,252364894238,1,8999);
}
fn RevealWarpChart142(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,142,211815218227,841433579025,768686803402,1,8999);
}
fn RevealWarpChart143(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,143,5144440285,10137782298,27951785703,1,8999);
}
fn RevealWarpChart144(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,144,308140021119,169219244416,747326497038,1,8999);
}
fn RevealWarpChart145(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,145,7592200,8934757,9559965,1,8999);
}
fn RevealWarpChart146(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,146,337777506314,786555151591,147098046668,1,8999);
}
fn RevealWarpChart147(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,147,2004327,8475812,4094826,1,8999);
}
fn RevealWarpChart148(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,148,486748812,42559444,920297189,1,8999);
}
fn RevealWarpChart149(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,149,9068518,6238914,7042090,1,8999);
}
fn RevealWarpChart150(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,150,7050602,9494154,3616727,1,8999);
}
fn RevealWarpChart151(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,151,891,512,875,1,8999);
}
fn RevealWarpChart152(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,152,216861,7141910,6516061,1,8999);
}
fn RevealWarpChart153(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,153,568574514,541451707,623131209,1,8999);
}
fn RevealWarpChart154(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,154,36648732,949004415,460255777,1,8999);
}
fn RevealWarpChart155(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,155,264727831482,653144442200,804200751788,1,8999);
}
fn RevealWarpChart156(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,156,559686446,859370879,309783580,1,8999);
}
fn RevealWarpChart157(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,157,644483968568,291933323486,189333739412,1,8999);
}
fn RevealWarpChart158(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,158,198,228,972,1,8999);
}
fn RevealWarpChart159(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,159,750571097870,807780781974,566083851319,1,8999);
}
fn RevealWarpChart160(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,160,177227,8600887,538162,1,8999);
}
fn RevealWarpChart161(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,161,3598948,8171309,601244,1,8999);
}
fn RevealWarpChart162(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,162,607006625,794401597,730621167,1,8999);
}
fn RevealWarpChart163(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,163,116394049558,269847922069,455374500243,1,8999);
}
fn RevealWarpChart164(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,164,1050004316062,1032431436990,1628959679760,1,8999);
}
fn RevealWarpChart165(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,165,2134438,7793920,7250445,1,8999);
}
fn RevealWarpChart166(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,166,277664096346,364837372855,232702721894,1,8999);
}
fn RevealWarpChart167(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,167,1412416157320,1686808021500,1110606046765,1,8999);
}
fn RevealWarpChart168(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,168,4948222,8102793,7241863,1,8999);
}
fn RevealWarpChart169(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,169,850376858,956061647,119407811,1,8999);
}
fn RevealWarpChart170(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,170,462558795,848644703,860809840,1,8999);
}
fn RevealWarpChart171(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,171,11381397669,83772452611,44231379538,1,8999);
}
fn RevealWarpChart172(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,172,6488862,7772054,1280327,1,8999);
}
fn RevealWarpChart173(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,173,883980260,760114909,884914556,1,8999);
}
fn RevealWarpChart174(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,174,33205,39835,63243,1,8999);
}
fn RevealWarpChart175(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,175,62524777214,46927575934,45948462518,1,8999);
}
fn RevealWarpChart176(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,176,1886404682367,1184450112098,1831641973445,1,8999);
}
fn RevealWarpChart177(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,177,391027502020,362776749249,767200873467,1,8999);
}
fn RevealWarpChart178(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,178,1069224030877,1256644668775,1938850096514,1,8999);
}
fn RevealWarpChart179(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,179,475479126,164980576,380333805,1,8999);
}
fn RevealWarpChart180(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,180,36521,85900,11210,1,8999);
}
fn RevealWarpChart181(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,181,1158185239345,1533346162139,1565819126316,1,8999);
}
fn RevealWarpChart182(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,182,176820931,888398133,206342741,1,8999);
}
fn RevealWarpChart183(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,183,34843390092,42701978147,17122942256,1,8999);
}
fn RevealWarpChart184(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,184,1098355928341,1472864853025,1234607979430,1,8999);
}
fn RevealWarpChart185(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,185,678429255,366306924,847872463,1,8999);
}
fn RevealWarpChart186(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,186,253,819,913,1,8999);
}
fn RevealWarpChart187(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,187,5064485,1906762,3608681,1,8999);
}
fn RevealWarpChart188(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,188,149181786,776866453,97642607,1,8999);
}
fn RevealWarpChart189(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,189,6880452,5383674,5041532,1,8999);
}
fn RevealWarpChart190(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,190,22458411203,82825728378,41711643789,1,8999);
}
fn RevealWarpChart191(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,191,1426364940374,1362885381733,1930579053543,1,8999);
}
fn RevealWarpChart192(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,192,791982659733,322885759092,861377906131,1,8999);
}
fn RevealWarpChart193(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,193,5882389,2342994,9705098,1,8999);
}
fn RevealWarpChart194(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,194,25148476706,9795830832,76402919741,1,8999);
}
fn RevealWarpChart195(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,195,476838498,319954401,868480919,1,8999);
}
fn RevealWarpChart196(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,196,97176196414,4039295600,73567133514,1,8999);
}
fn RevealWarpChart197(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,197,63225,5630,62664,1,8999);
}
fn RevealWarpChart198(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,198,697401424,186418245,243100837,1,8999);
}
fn RevealWarpChart199(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,199,96774,26842,27390,1,8999);
}
fn RevealWarpChart200(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,200,1388269225432,1106536683326,1970854923900,1,8999);
}
fn RevealWarpChart201(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,201,872187321051,460105337909,563085996558,1,8999);
}
fn RevealWarpChart202(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,202,40910601733,58947270694,25912345260,1,8999);
}
fn RevealWarpChart203(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,203,717451415,257253533,121106095,1,8999);
}
fn RevealWarpChart204(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,204,26936919774,32423658168,6526345867,1,8999);
}
fn RevealWarpChart205(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,205,32951204806,95395017765,90137771777,1,8999);
}
fn RevealWarpChart206(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,206,5821957,9182788,7196764,1,8999);
}
fn RevealWarpChart207(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,207,381573962,735272461,618415472,1,8999);
}
fn RevealWarpChart208(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,208,14970,86753,87098,1,8999);
}
fn RevealWarpChart209(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,209,66722,6465,26998,1,8999);
}
fn RevealWarpChart210(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,210,5838969,1662945,4475798,1,8999);
}
fn RevealWarpChart211(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,211,14515,53140,93194,1,8999);
}
fn RevealWarpChart212(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,212,5398698,8618941,3976412,1,8999);
}
fn RevealWarpChart213(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,213,48364965037,83892918614,71233574959,1,8999);
}
fn RevealWarpChart214(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,214,179741986404,585971173462,961915289626,1,8999);
}
fn RevealWarpChart215(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,215,894625701,842850924,849294817,1,8999);
}
fn RevealWarpChart216(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,216,43461727033,30697712933,4843718043,1,8999);
}
fn RevealWarpChart217(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,217,998696623047,128182788919,397292009706,1,8999);
}
fn RevealWarpChart218(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,218,4134157660,87766433147,48792951695,1,8999);
}
fn RevealWarpChart219(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,219,214867085,299271678,598955484,1,8999);
}
fn RevealWarpChart220(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,220,15994,15685,8429,1,8999);
}
fn RevealWarpChart221(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,221,7150139,7137215,3498353,1,8999);
}
fn RevealWarpChart222(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,222,507714764,429578850,597819405,1,8999);
}
fn RevealWarpChart223(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,223,797397975013,450353396984,353017590971,1,8999);
}
fn RevealWarpChart224(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,224,300550895092,204971595119,350311255182,1,8999);
}
fn RevealWarpChart225(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,225,597476120325,758103166257,584861536471,1,8999);
}
fn RevealWarpChart226(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,226,612,287,488,1,8999);
}
fn RevealWarpChart227(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,227,1098455879455,1669180610901,1649175683750,1,8999);
}
fn RevealWarpChart228(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,228,667697,9522165,3098915,1,8999);
}
fn RevealWarpChart229(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,229,124607174,663379634,814392545,1,8999);
}
fn RevealWarpChart230(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,230,96365592419,5239990800,99627046449,1,8999);
}
fn RevealWarpChart231(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,231,24432136925,21559399440,15139310973,1,8999);
}
fn RevealWarpChart232(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,232,564808534,262937859,33642432,1,8999);
}
fn RevealWarpChart233(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,233,84757955521,67313662506,9448691970,1,8999);
}
fn RevealWarpChart234(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,234,8482827,7679668,4614961,1,8999);
}
fn RevealWarpChart235(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,235,4594601,6804006,6499784,1,8999);
}
fn RevealWarpChart236(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,236,1785459032263,1436627809023,1136031236865,1,8999);
}
fn RevealWarpChart237(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,237,65721,53315,72626,1,8999);
}
fn RevealWarpChart238(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,238,5390113,3638968,4053143,1,8999);
}
fn RevealWarpChart239(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,239,534565545,645734759,787377921,1,8999);
}
fn RevealWarpChart240(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,240,4131,75075,49931,1,8999);
}
fn RevealWarpChart241(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,241,648,752,565,1,8999);
}
fn RevealWarpChart242(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,242,72456,71976,50076,1,8999);
}
fn RevealWarpChart243(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,243,94962612274,79437835592,23431956408,1,8999);
}
fn RevealWarpChart244(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,244,986133657691,499382533344,585937511750,1,8999);
}
fn RevealWarpChart245(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,245,96673,91493,92131,1,8999);
}
fn RevealWarpChart246(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,246,44942,57830,49717,1,8999);
}
fn RevealWarpChart247(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,247,7225291,7218369,8111364,1,8999);
}
fn RevealWarpChart248(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,248,11603836146,42888207220,11700618538,1,8999);
}
fn RevealWarpChart249(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,249,825,246,331,1,8999);
}
fn RevealWarpChart250(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,250,41995037844,4457444619,41437290410,1,8999);
}
fn RevealWarpChart251(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,251,957,155,421,1,8999);
}
fn RevealWarpChart252(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,252,405783721,96029318,537369384,1,8999);
}
fn RevealWarpChart253(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,253,45104721,704480189,712602660,1,8999);
}
fn RevealWarpChart254(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,254,247201906904,585789130388,583519608485,1,8999);
}
fn RevealWarpChart255(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,255,12990416024,40219871999,55148265409,1,8999);
}
fn RevealWarpChart256(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__warp_chart");
reveal_chart_p(action,n,s,c,256,385729605511,631900261432,396119036916,1,8999);
}
fn WarpShipToPositionCoordinateReusable(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
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
warp_ship_core(action,next_ship,ship,chart.destination_x,chart.destination_y,chart.destination_z,ship.epoch);
consume_reusable_use_core(action,chart);
var work=action.intro_vdf(12,next_ship);
next_ship.update("work",work);
}
fn WarpShipToPositionCoordinateFinal(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
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
warp_ship_core(action,next_ship,ship,chart.destination_x,chart.destination_y,chart.destination_z,ship.epoch);
consume_final_use_core(action,chart);
var work=action.intro_vdf(12,next_ship);
next_ship.update("work",work);
}
fn RevealEpochChart001(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,1,256368704,10,39999);
}
fn RevealEpochChart002(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,2,822630710647,3,30999);
}
fn RevealEpochChart003(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,3,712296361,3,30999);
}
fn RevealEpochChart004(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,4,482747484418,3,30999);
}
fn RevealEpochChart005(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,5,79684052,1,8999);
}
fn RevealEpochChart006(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,6,168714394971,1,8999);
}
fn RevealEpochChart007(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,7,852385296674,1,8999);
}
fn RevealEpochChart008(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,8,313775339588,1,8999);
}
fn RevealEpochChart009(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,9,418407602376,1,8999);
}
fn RevealEpochChart010(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,10,682910950,1,8999);
}
fn RevealEpochChart011(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,11,266629299,1,8999);
}
fn RevealEpochChart012(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,12,3286854178,1,8999);
}
fn RevealEpochChart013(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,13,617218660856,1,8999);
}
fn RevealEpochChart014(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,14,992813523404,1,8999);
}
fn RevealEpochChart015(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,15,92169980272,1,8999);
}
fn RevealEpochChart016(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,16,40732598204,1,8999);
}
fn RevealEpochChart017(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,17,592495517877,1,8999);
}
fn RevealEpochChart018(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,18,94465056208,1,8999);
}
fn RevealEpochChart019(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,19,815809172,1,8999);
}
fn RevealEpochChart020(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,20,8500482,1,8999);
}
fn RevealEpochChart021(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,21,476595662058,1,8999);
}
fn RevealEpochChart022(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,22,3553570,1,8999);
}
fn RevealEpochChart023(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,23,5289266,1,8999);
}
fn RevealEpochChart024(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,24,167461903501,1,8999);
}
fn RevealEpochChart025(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,25,34749164243,1,8999);
}
fn RevealEpochChart026(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,26,91773502718,1,8999);
}
fn RevealEpochChart027(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,27,32363,1,8999);
}
fn RevealEpochChart028(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,28,9653396,1,8999);
}
fn RevealEpochChart029(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,29,96506,1,8999);
}
fn RevealEpochChart030(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,30,2619211,1,8999);
}
fn RevealEpochChart031(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,31,639351535,1,8999);
}
fn RevealEpochChart032(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,32,69632,1,8999);
}
fn RevealEpochChart033(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,33,541686600294,1,8999);
}
fn RevealEpochChart034(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,34,28380523638,1,8999);
}
fn RevealEpochChart035(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,35,76443315,1,8999);
}
fn RevealEpochChart036(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,36,15019,1,8999);
}
fn RevealEpochChart037(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,37,727359677350,1,8999);
}
fn RevealEpochChart038(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,38,1245300838,1,8999);
}
fn RevealEpochChart039(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,39,306588059046,1,8999);
}
fn RevealEpochChart040(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,40,958328413950,1,8999);
}
fn RevealEpochChart041(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,41,81694,1,8999);
}
fn RevealEpochChart042(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,42,1952318,1,8999);
}
fn RevealEpochChart043(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,43,6268530,1,8999);
}
fn RevealEpochChart044(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,44,6339973840,1,8999);
}
fn RevealEpochChart045(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,45,8542117,1,8999);
}
fn RevealEpochChart046(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,46,14120,1,8999);
}
fn RevealEpochChart047(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,47,628890961787,1,8999);
}
fn RevealEpochChart048(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,48,7844752,1,8999);
}
fn RevealEpochChart049(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,49,177377222,1,8999);
}
fn RevealEpochChart050(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,50,5042225,1,8999);
}
fn RevealEpochChart051(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,51,50517485774,1,8999);
}
fn RevealEpochChart052(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,52,85810,1,8999);
}
fn RevealEpochChart053(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,53,52108813889,1,8999);
}
fn RevealEpochChart054(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,54,759603399336,1,8999);
}
fn RevealEpochChart055(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,55,69638397119,1,8999);
}
fn RevealEpochChart056(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,56,565557523388,1,8999);
}
fn RevealEpochChart057(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,57,614770024389,1,8999);
}
fn RevealEpochChart058(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,58,52283646,1,8999);
}
fn RevealEpochChart059(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,59,897578268837,1,8999);
}
fn RevealEpochChart060(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,60,951423868361,1,8999);
}
fn RevealEpochChart061(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,61,8857506,1,8999);
}
fn RevealEpochChart062(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,62,95675,1,8999);
}
fn RevealEpochChart063(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,63,7608403,1,8999);
}
fn RevealEpochChart064(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,64,877592330068,1,8999);
}
fn RevealEpochChart065(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,65,675381993,1,8999);
}
fn RevealEpochChart066(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,66,919803293,1,8999);
}
fn RevealEpochChart067(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,67,251056901697,1,8999);
}
fn RevealEpochChart068(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,68,25773,1,8999);
}
fn RevealEpochChart069(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,69,366992367,1,8999);
}
fn RevealEpochChart070(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,70,86993,1,8999);
}
fn RevealEpochChart071(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,71,890123102542,1,8999);
}
fn RevealEpochChart072(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,72,870385314213,1,8999);
}
fn RevealEpochChart073(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,73,143643254,1,8999);
}
fn RevealEpochChart074(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,74,934700082078,1,8999);
}
fn RevealEpochChart075(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,75,1834,1,8999);
}
fn RevealEpochChart076(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,76,8998688,1,8999);
}
fn RevealEpochChart077(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,77,307151405,1,8999);
}
fn RevealEpochChart078(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,78,125223008,1,8999);
}
fn RevealEpochChart079(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,79,17857649955,1,8999);
}
fn RevealEpochChart080(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,80,20488948932,1,8999);
}
fn RevealEpochChart081(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,81,50734985484,1,8999);
}
fn RevealEpochChart082(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,82,200515222,1,8999);
}
fn RevealEpochChart083(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,83,3793358,1,8999);
}
fn RevealEpochChart084(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,84,636494815386,1,8999);
}
fn RevealEpochChart085(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,85,54190,1,8999);
}
fn RevealEpochChart086(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,86,93756271585,1,8999);
}
fn RevealEpochChart087(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,87,2763156,1,8999);
}
fn RevealEpochChart088(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,88,136739200270,1,8999);
}
fn RevealEpochChart089(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,89,978275968016,1,8999);
}
fn RevealEpochChart090(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,90,7281675,1,8999);
}
fn RevealEpochChart091(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,91,8418622,1,8999);
}
fn RevealEpochChart092(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,92,14089036231,1,8999);
}
fn RevealEpochChart093(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,93,7601984,1,8999);
}
fn RevealEpochChart094(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,94,744130328574,1,8999);
}
fn RevealEpochChart095(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,95,7497212,1,8999);
}
fn RevealEpochChart096(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,96,40613,1,8999);
}
fn RevealEpochChart097(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,97,386340836,1,8999);
}
fn RevealEpochChart098(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,98,94885551846,1,8999);
}
fn RevealEpochChart099(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,99,8619636781,1,8999);
}
fn RevealEpochChart100(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,100,971914324668,1,8999);
}
fn RevealEpochChart101(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,101,63379,1,8999);
}
fn RevealEpochChart102(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,102,81013880119,1,8999);
}
fn RevealEpochChart103(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,103,349847167,1,8999);
}
fn RevealEpochChart104(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,104,920759038,1,8999);
}
fn RevealEpochChart105(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,105,2528759,1,8999);
}
fn RevealEpochChart106(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,106,6000,1,8999);
}
fn RevealEpochChart107(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,107,97751341420,1,8999);
}
fn RevealEpochChart108(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,108,91340,1,8999);
}
fn RevealEpochChart109(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,109,898051108737,1,8999);
}
fn RevealEpochChart110(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,110,650213715,1,8999);
}
fn RevealEpochChart111(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,111,809451332161,1,8999);
}
fn RevealEpochChart112(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,112,914795591589,1,8999);
}
fn RevealEpochChart113(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,113,55174069405,1,8999);
}
fn RevealEpochChart114(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,114,385933580,1,8999);
}
fn RevealEpochChart115(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,115,159198535677,1,8999);
}
fn RevealEpochChart116(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,116,69134248920,1,8999);
}
fn RevealEpochChart117(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,117,7784182,1,8999);
}
fn RevealEpochChart118(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,118,4649408,1,8999);
}
fn RevealEpochChart119(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,119,14635237705,1,8999);
}
fn RevealEpochChart120(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,120,732302686947,1,8999);
}
fn RevealEpochChart121(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,121,3308627,1,8999);
}
fn RevealEpochChart122(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,122,9812920,1,8999);
}
fn RevealEpochChart123(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,123,450987877403,1,8999);
}
fn RevealEpochChart124(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,124,746992898006,1,8999);
}
fn RevealEpochChart125(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,125,719878203,1,8999);
}
fn RevealEpochChart126(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,126,812740620169,1,8999);
}
fn RevealEpochChart127(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,127,685958831907,1,8999);
}
fn RevealEpochChart128(action){
var n=action.output("microverse__ship");
var s=action.input("microverse__ship");
var c=action.mutate("microverse__epoch_chart");
reveal_chart_t(action,n,s,c,128,995769685,1,8999);
}
fn WarpShipToEpochCoordinateReusable(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var chart=action.mutate("microverse__epoch_chart");
prove_object_version_core(action,chart,"catalog_version");
action.st_sum(chart.revealed,0,1);
action.st_sum(ship.active_skill_type,0,58);
action.st_gt(chart.destination_epoch,100);
action.st_gt(1000000000000,chart.destination_epoch);
warp_ship_core(action,next_ship,ship,ship.x,ship.y,ship.z,chart.destination_epoch);
consume_reusable_use_core(action,chart);
var work=action.intro_vdf(20,next_ship);
next_ship.update("work",work);
}
fn WarpShipToEpochCoordinateFinal(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var chart=action.input("microverse__epoch_chart");
prove_object_version_core(action,chart,"catalog_version");
action.st_sum(chart.revealed,0,1);
action.st_sum(ship.active_skill_type,0,58);
action.st_gt(chart.destination_epoch,100);
action.st_gt(1000000000000,chart.destination_epoch);
warp_ship_core(action,next_ship,ship,ship.x,ship.y,ship.z,chart.destination_epoch);
consume_final_use_core(action,chart);
var work=action.intro_vdf(20,next_ship);
next_ship.update("work",work);
}
fn CapturePositionAnchor(action){
var next_ship=action.output("microverse__ship");
var anchor=action.output("microverse__position_anchor");
var ship=action.input("microverse__ship");
var material_1=action.input("microverse__resource");
var material_2=action.input("microverse__resource");
var source_ship_id=consume_prepared_ship_core(
action,next_ship,ship,49
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
var next_ship=action.output("microverse__ship");
var anchor=action.output("microverse__time_anchor");
var ship=action.input("microverse__ship");
var material_1=action.input("microverse__resource");
var material_2=action.input("microverse__resource");
var source_ship_id=consume_prepared_ship_core(
action,next_ship,ship,60
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
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
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
warp_ship_core(action,next_ship,ship,link.endpoint_b_x,link.endpoint_b_y,link.endpoint_b_z,ship.epoch);
consume_reusable_use_core(action,link);
var work=action.intro_vdf(20,next_ship);
next_ship.update("work",work);
}
fn TraverseWormholeAToBFinal(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
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
warp_ship_core(action,next_ship,ship,link.endpoint_b_x,link.endpoint_b_y,link.endpoint_b_z,ship.epoch);
consume_final_use_core(action,link);
var work=action.intro_vdf(20,next_ship);
next_ship.update("work",work);
}
fn TraverseWormholeBToAReusable(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
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
warp_ship_core(action,next_ship,ship,link.endpoint_a_x,link.endpoint_a_y,link.endpoint_a_z,ship.epoch);
consume_reusable_use_core(action,link);
var work=action.intro_vdf(20,next_ship);
next_ship.update("work",work);
}
fn TraverseWormholeBToAFinal(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
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
warp_ship_core(action,next_ship,ship,link.endpoint_a_x,link.endpoint_a_y,link.endpoint_a_z,ship.epoch);
consume_final_use_core(action,link);
var work=action.intro_vdf(20,next_ship);
next_ship.update("work",work);
}
fn TraverseTemporalAToBReusable(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var link=action.mutate("microverse__temporal_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,60);
var source_epoch=unsafe{link.endpoint_a_epoch-0};
action.st_sum(link.endpoint_a_epoch,0,source_epoch);
action.st_sum(ship.epoch,0,source_epoch);
warp_ship_core(action,next_ship,ship,ship.x,ship.y,ship.z,link.endpoint_b_epoch);
consume_reusable_use_core(action,link);
var work=action.intro_vdf(20,next_ship);
next_ship.update("work",work);
}
fn TraverseTemporalAToBFinal(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var link=action.input("microverse__temporal_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,60);
var source_epoch=unsafe{link.endpoint_a_epoch-0};
action.st_sum(link.endpoint_a_epoch,0,source_epoch);
action.st_sum(ship.epoch,0,source_epoch);
warp_ship_core(action,next_ship,ship,ship.x,ship.y,ship.z,link.endpoint_b_epoch);
consume_final_use_core(action,link);
var work=action.intro_vdf(20,next_ship);
next_ship.update("work",work);
}
fn TraverseTemporalBToAReusable(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var link=action.mutate("microverse__temporal_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,60);
var source_epoch=unsafe{link.endpoint_b_epoch-0};
action.st_sum(link.endpoint_b_epoch,0,source_epoch);
action.st_sum(ship.epoch,0,source_epoch);
warp_ship_core(action,next_ship,ship,ship.x,ship.y,ship.z,link.endpoint_a_epoch);
consume_reusable_use_core(action,link);
var work=action.intro_vdf(20,next_ship);
next_ship.update("work",work);
}
fn TraverseTemporalBToAFinal(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var link=action.input("microverse__temporal_link");
prove_object_version_core(action,link,"link_version");
action.st_sum(ship.active_skill_type,0,60);
var source_epoch=unsafe{link.endpoint_b_epoch-0};
action.st_sum(link.endpoint_b_epoch,0,source_epoch);
action.st_sum(ship.epoch,0,source_epoch);
warp_ship_core(action,next_ship,ship,ship.x,ship.y,ship.z,link.endpoint_a_epoch);
consume_final_use_core(action,link);
var work=action.intro_vdf(20,next_ship);
next_ship.update("work",work);
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
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var coordinate=action.mutate("microverse__rendezvous_coordinate");
prove_object_version_core(action,coordinate,"coordinate_version");
action.st_sum(ship.active_skill_type,0,86);
warp_ship_core(
action,
next_ship,
ship,
coordinate.destination_x,
coordinate.destination_y,
coordinate.destination_z,
coordinate.destination_epoch
);
consume_reusable_use_core(action,coordinate);
var work=action.intro_vdf(32,next_ship);
next_ship.update("work",work);
}
fn WarpToRendezvousCoordinateFinal(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var coordinate=action.input("microverse__rendezvous_coordinate");
prove_object_version_core(action,coordinate,"coordinate_version");
action.st_sum(ship.active_skill_type,0,86);
warp_ship_core(
action,
next_ship,
ship,
coordinate.destination_x,
coordinate.destination_y,
coordinate.destination_z,
coordinate.destination_epoch
);
consume_final_use_core(action,coordinate);
var work=action.intro_vdf(32,next_ship);
next_ship.update("work",work);
}
fn ExtractMatter(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_8_core(action,next_ship,resource,ship,body,0,"matter_remaining",1,10,1);}
fn ExtractMatterMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_8_core(action,next_ship,resource,ship,body,0,"matter_remaining",1,50,5);}
fn ExtractMatterLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_8_core(action,next_ship,resource,ship,body,0,"matter_remaining",1,250,25);}
fn ExtractCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_8_core(action,next_ship,resource,ship,body,0,"crystal_remaining",2,10,1);}
fn ExtractCrystalMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_8_core(action,next_ship,resource,ship,body,0,"crystal_remaining",2,50,5);}
fn ExtractCrystalLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_8_core(action,next_ship,resource,ship,body,0,"crystal_remaining",2,250,25);}
fn ExtractGas(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_2_core(action,next_ship,resource,ship,body,0,"gas_remaining",3,10,1);}
fn ExtractGasMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_2_core(action,next_ship,resource,ship,body,0,"gas_remaining",3,50,5);}
fn ExtractGasLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_2_core(action,next_ship,resource,ship,body,0,"gas_remaining",3,250,25);}
fn ExtractEnergy(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_4_core(action,next_ship,resource,ship,body,0,"energy_remaining",4,10,1);}
fn ExtractEnergyMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_4_core(action,next_ship,resource,ship,body,0,"energy_remaining",4,50,5);}
fn ExtractEnergyLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_base_vdf_4_core(action,next_ship,resource,ship,body,0,"energy_remaining",4,250,25);}
fn DiscoverSatellite(action){
var next_ship=action.output("microverse__ship");
var satellite=action.output("microverse__satellite");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(body.sector_x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(body.sector_y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(body.sector_z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(body.sector_epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
var next_ship_satellite_serial=unsafe{ship.satellite_serial-(0-1)};
action.st_sum(ship.satellite_serial,1,next_ship_satellite_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",next_ship_satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
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
["sector_x",x],
["sector_y",y],
["sector_z",z],
["sector_epoch",epoch],
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
var next_ship=action.output("microverse__ship");
var life_signal=action.output("microverse__life_signal");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
prove_fixed_versions(action,ship);
prove_fixed_versions(action,body);
action.st_sum(body.body_bank_version,0,2);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(body.sector_x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(body.sector_y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(body.sector_z,0,z);
action.st_sum(ship.epoch,0,epoch);
action.st_sum(body.sector_epoch,0,epoch);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
var next_scan_serial=unsafe{ship.civilization_scan_serial-(0-1)};
action.st_sum(ship.civilization_scan_serial,1,next_scan_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",0],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",next_scan_serial],
["ship_id",ship_id]
]);
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
["sector_x",x],
["sector_y",y],
["sector_z",z],
["origin_epoch",epoch]
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
action.st_gt(
ship.civilization_scan_serial,
63
);
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
action.st_gt(
ship.civilization_scan_serial,
1023
);
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
action.st_gt(
ship.civilization_scan_serial,
16383
);
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
fn ExtractRedDwarfFusionGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
0,8,"gas_remaining",
119,50,5,30,15,5
);
}
fn ExtractRedDwarfFusionGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
0,8,"gas_remaining",
119,250,25,150,75,25
);
}
fn ExtractRedDwarfMetalRichOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
0,16,"matter_remaining",
120,50,5,45,4,1
);
}
fn ExtractRedDwarfMetalRichOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
0,16,"matter_remaining",
120,250,25,225,20,5
);
}
fn ExtractRedDwarfRadiantEnergy(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
0,8,"energy_remaining",
121,50,5
);
}
fn ExtractRedDwarfRadiantEnergyLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
0,8,"energy_remaining",
121,250,25
);
}
fn ExtractRedDwarfRedDwarfPlasma(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
0,8,"energy_remaining",
223,50,5,30,15,5
);
}
fn ExtractRedDwarfRedDwarfPlasmaLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
0,8,"energy_remaining",
223,250,25,150,75,25
);
}
fn ExtractRedDwarfMagneticStellarCondensate(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
0,7,"matter_remaining",
224,50,5,35,10,5
);
}
fn ExtractRedDwarfMagneticStellarCondensateLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
0,7,"matter_remaining",
224,250,25,175,50,25
);
}
fn ExtractRedDwarfFlareSpectrumData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
0,8,"energy_remaining",
225,50,5
);
}
fn ExtractRedDwarfFlareSpectrumDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
0,8,"energy_remaining",
225,250,25
);
}
fn ExtractRedDwarfStellarRefractoryDust(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
0,7,"matter_remaining",
336,50,5,35,10,5
);
}
fn ExtractRedDwarfStellarRefractoryDustLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
0,7,"matter_remaining",
336,250,25,175,50,25
);
}
fn ExtractMainSequenceStarFusionGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
1,8,"gas_remaining",
119,50,5,30,15,5
);
}
fn ExtractMainSequenceStarFusionGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
1,8,"gas_remaining",
119,250,25,150,75,25
);
}
fn ExtractMainSequenceStarMetalRichOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
1,16,"matter_remaining",
120,50,5,45,4,1
);
}
fn ExtractMainSequenceStarMetalRichOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
1,16,"matter_remaining",
120,250,25,225,20,5
);
}
fn ExtractMainSequenceStarRadiantEnergy(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
1,8,"energy_remaining",
121,50,5
);
}
fn ExtractMainSequenceStarRadiantEnergyLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
1,8,"energy_remaining",
121,250,25
);
}
fn ExtractMainSequenceStarPhotosphericPlasma(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
1,8,"energy_remaining",
226,50,5,30,15,5
);
}
fn ExtractMainSequenceStarPhotosphericPlasmaLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
1,8,"energy_remaining",
226,250,25,150,75,25
);
}
fn ExtractMainSequenceStarPhotosphericMineral(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
1,8,"matter_remaining",
227,50,5,35,10,5
);
}
fn ExtractMainSequenceStarPhotosphericMineralLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
1,8,"matter_remaining",
227,250,25,175,50,25
);
}
fn ExtractMainSequenceStarStellarSpectrumData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
1,8,"energy_remaining",
228,50,5
);
}
fn ExtractMainSequenceStarStellarSpectrumDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
1,8,"energy_remaining",
228,250,25
);
}
fn ExtractMainSequenceStarSolarWindCondensate(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
1,4,"matter_remaining",
337,50,5,30,15,5
);
}
fn ExtractMainSequenceStarSolarWindCondensateLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
1,4,"matter_remaining",
337,250,25,150,75,25
);
}
fn ExtractGiantStarFusionGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
2,8,"gas_remaining",
119,50,5,30,15,5
);
}
fn ExtractGiantStarFusionGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
2,8,"gas_remaining",
119,250,25,150,75,25
);
}
fn ExtractGiantStarMetalRichOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
2,16,"matter_remaining",
120,50,5,45,4,1
);
}
fn ExtractGiantStarMetalRichOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
2,16,"matter_remaining",
120,250,25,225,20,5
);
}
fn ExtractGiantStarRadiantEnergy(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
2,8,"energy_remaining",
121,50,5
);
}
fn ExtractGiantStarRadiantEnergyLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
2,8,"energy_remaining",
121,250,25
);
}
fn ExtractGiantStarHeliumCarbonEjecta(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
2,16,"gas_remaining",
229,50,5,25,15,10
);
}
fn ExtractGiantStarHeliumCarbonEjectaLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
2,16,"gas_remaining",
229,250,25,125,75,50
);
}
fn ExtractGiantStarHeavyElementCondensate(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
2,16,"matter_remaining",
230,50,5,30,15,5
);
}
fn ExtractGiantStarHeavyElementCondensateLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
2,16,"matter_remaining",
230,250,25,150,75,25
);
}
fn ExtractGiantStarNeutrinoData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
2,16,"energy_remaining",
231,50,5
);
}
fn ExtractGiantStarNeutrinoDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
2,16,"energy_remaining",
231,250,25
);
}
fn ExtractGiantStarSProcessEjecta(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
2,16,"matter_remaining",
338,50,5,30,15,5
);
}
fn ExtractGiantStarSProcessEjectaLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
2,16,"matter_remaining",
338,250,25,150,75,25
);
}
fn ExtractRockyPlanetFerrousOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(3074457344902430719);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
122,10,1,7,2,1
);
}
fn ExtractRockyPlanetFerrousOreMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(3074457344902430719);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
122,50,5,35,10,5
);
}
fn ExtractRockyPlanetFerrousOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(3074457344902430719);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
122,250,25,175,50,25
);
}
fn ExtractRockyPlanetBaseMetalOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(3074457344902430720);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
123,10,1,7,2,1
);
}
fn ExtractRockyPlanetBaseMetalOreMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(3074457344902430720);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
123,50,5,35,10,5
);
}
fn ExtractRockyPlanetBaseMetalOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(3074457344902430720);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
123,250,25,175,50,25
);
}
fn ExtractRockyPlanetSilicateMineral(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
124,10,1,7,2,1
);
}
fn ExtractRockyPlanetSilicateMineralMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
124,50,5,35,10,5
);
}
fn ExtractRockyPlanetSilicateMineralLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
124,250,25,175,50,25
);
}
fn ExtractRockyPlanetIndustrialMineral(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
125,10,1,7,2,1
);
}
fn ExtractRockyPlanetIndustrialMineralMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
125,50,5,35,10,5
);
}
fn ExtractRockyPlanetIndustrialMineralLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
125,250,25,175,50,25
);
}
fn ExtractRockyPlanetIgneousRock(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-3074457349197398017);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
232,10,1,6,3,1
);
}
fn ExtractRockyPlanetIgneousRockMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-3074457349197398017);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
232,50,5,30,15,5
);
}
fn ExtractRockyPlanetIgneousRockLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-3074457349197398017);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
232,250,25,150,75,25
);
}
fn ExtractRockyPlanetGeothermalEnergy(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
3,0,"energy_remaining",
233,10,1
);
}
fn ExtractRockyPlanetGeothermalEnergyMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
3,0,"energy_remaining",
233,50,5
);
}
fn ExtractRockyPlanetGeothermalEnergyLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
3,0,"energy_remaining",
233,250,25
);
}
fn ExtractRockyPlanetSedimentaryRock(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-3074457349197398016);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
339,10,1,7,2,1
);
}
fn ExtractRockyPlanetSedimentaryRockMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-3074457349197398016);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
339,50,5,35,10,5
);
}
fn ExtractRockyPlanetSedimentaryRockLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-3074457349197398016);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
3,0,"matter_remaining",
339,250,25,175,50,25
);
}
fn ExtractOceanPlanetWater(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_2_core(
action,next_ship,resource,ship,body,
4,0,"matter_remaining",
126,10,1
);
}
fn ExtractOceanPlanetWaterMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_2_core(
action,next_ship,resource,ship,body,
4,0,"matter_remaining",
126,50,5
);
}
fn ExtractOceanPlanetWaterLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_2_core(
action,next_ship,resource,ship,body,
4,0,"matter_remaining",
126,250,25
);
}
fn ExtractOceanPlanetSeawaterMinerals(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
4,0,"crystal_remaining",
127,10,1,7,2,1
);
}
fn ExtractOceanPlanetSeawaterMineralsMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
4,0,"crystal_remaining",
127,50,5,35,10,5
);
}
fn ExtractOceanPlanetSeawaterMineralsLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
4,0,"crystal_remaining",
127,250,25,175,50,25
);
}
fn ExtractOceanPlanetAtmosphericGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
4,0,"gas_remaining",
128,10,1,5,3,2
);
}
fn ExtractOceanPlanetAtmosphericGasMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
4,0,"gas_remaining",
128,50,5,25,15,10
);
}
fn ExtractOceanPlanetAtmosphericGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
4,0,"gas_remaining",
128,250,25,125,75,50
);
}
fn ExtractOceanPlanetSeafloorSulfideOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
4,0,"matter_remaining",
234,10,1,7,2,1
);
}
fn ExtractOceanPlanetSeafloorSulfideOreMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
4,0,"matter_remaining",
234,50,5,35,10,5
);
}
fn ExtractOceanPlanetSeafloorSulfideOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
4,0,"matter_remaining",
234,250,25,175,50,25
);
}
fn ExtractOceanPlanetMarineBiomass(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
4,0,"matter_remaining",
235,10,1,5,3,2
);
}
fn ExtractOceanPlanetMarineBiomassMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
4,0,"matter_remaining",
235,50,5,25,15,10
);
}
fn ExtractOceanPlanetMarineBiomassLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
4,0,"matter_remaining",
235,250,25,125,75,50
);
}
fn ExtractOceanPlanetTidalEnergy(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
4,0,"energy_remaining",
236,10,1
);
}
fn ExtractOceanPlanetTidalEnergyMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
4,0,"energy_remaining",
236,50,5
);
}
fn ExtractOceanPlanetTidalEnergyLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_4_core(
action,next_ship,resource,ship,body,
4,0,"energy_remaining",
236,250,25
);
}
fn ExtractOceanPlanetDissolvedTraceMinerals(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
4,0,"crystal_remaining",
340,10,1,7,2,1
);
}
fn ExtractOceanPlanetDissolvedTraceMineralsMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
4,0,"crystal_remaining",
340,50,5,35,10,5
);
}
fn ExtractOceanPlanetDissolvedTraceMineralsLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
4,0,"crystal_remaining",
340,250,25,175,50,25
);
}
fn ExtractGardenPlanetBiomass(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(4611686017353646079);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
129,10,1,5,3,2
);
}
fn ExtractGardenPlanetBiomassMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(4611686017353646079);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
129,50,5,25,15,10
);
}
fn ExtractGardenPlanetBiomassLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(4611686017353646079);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
129,250,25,125,75,50
);
}
fn ExtractGardenPlanetGeneticMaterial(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(4611686017353646080);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
130,10,1,5,3,2
);
}
fn ExtractGardenPlanetGeneticMaterialMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(4611686017353646080);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
130,50,5,25,15,10
);
}
fn ExtractGardenPlanetGeneticMaterialLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(4611686017353646080);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
130,250,25,125,75,50
);
}
fn ExtractGardenPlanetBiochemicalMixture(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
5,0,"gas_remaining",
131,10,1,5,3,2
);
}
fn ExtractGardenPlanetBiochemicalMixtureMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
5,0,"gas_remaining",
131,50,5,25,15,10
);
}
fn ExtractGardenPlanetBiochemicalMixtureLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
5,0,"gas_remaining",
131,250,25,125,75,50
);
}
fn ExtractGardenPlanetMicrobialCulture(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-4611686021648613377);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
132,10,1,5,3,2
);
}
fn ExtractGardenPlanetMicrobialCultureMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-4611686021648613377);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
132,50,5,25,15,10
);
}
fn ExtractGardenPlanetMicrobialCultureLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-4611686021648613377);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
132,250,25,125,75,50
);
}
fn ExtractGardenPlanetNaturalMaterial(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,0,"crystal_remaining",
133,10,1,5,3,2
);
}
fn ExtractGardenPlanetNaturalMaterialMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,0,"crystal_remaining",
133,50,5,25,15,10
);
}
fn ExtractGardenPlanetNaturalMaterialLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,0,"crystal_remaining",
133,250,25,125,75,50
);
}
fn ExtractGardenPlanetLivingSoil(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,17,"matter_remaining",
237,10,1,6,3,1
);
}
fn ExtractGardenPlanetLivingSoilMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,17,"matter_remaining",
237,50,5,30,15,5
);
}
fn ExtractGardenPlanetLivingSoilLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
5,17,"matter_remaining",
237,250,25,150,75,25
);
}
fn ExtractGardenPlanetPlantExtract(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-4611686021648613376);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
341,10,1,6,3,1
);
}
fn ExtractGardenPlanetPlantExtractMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-4611686021648613376);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
341,50,5,30,15,5
);
}
fn ExtractGardenPlanetPlantExtractLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-4611686021648613376);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
5,0,"matter_remaining",
341,250,25,150,75,25
);
}
fn ExtractGasGiantFusionGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(4611686017353646079);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
6,0,"gas_remaining",
119,50,5,30,15,5
);
}
fn ExtractGasGiantFusionGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(4611686017353646079);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
6,0,"gas_remaining",
119,250,25,150,75,25
);
}
fn ExtractGasGiantAtmosphericGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(4611686017353646080);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
6,0,"gas_remaining",
128,50,5,25,15,10
);
}
fn ExtractGasGiantAtmosphericGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(4611686017353646080);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
6,0,"gas_remaining",
128,250,25,125,75,50
);
}
fn ExtractGasGiantNobleGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-4611686021648613377);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
6,0,"gas_remaining",
134,50,5,35,10,5
);
}
fn ExtractGasGiantNobleGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-4611686021648613377);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
6,0,"gas_remaining",
134,250,25,175,50,25
);
}
fn ExtractGasGiantDeepAtmosphereGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
6,3,"gas_remaining",
238,50,5,30,15,5
);
}
fn ExtractGasGiantDeepAtmosphereGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
6,3,"gas_remaining",
238,250,25,150,75,25
);
}
fn ExtractGasGiantHydrocarbonCloud(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-4611686021648613376);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
6,0,"gas_remaining",
239,50,5,25,15,10
);
}
fn ExtractGasGiantHydrocarbonCloudLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-4611686021648613376);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
6,0,"gas_remaining",
239,250,25,125,75,50
);
}
fn ExtractGasGiantStormFieldData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
6,11,"energy_remaining",
240,50,5
);
}
fn ExtractGasGiantStormFieldDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
6,11,"energy_remaining",
240,250,25
);
}
fn ExtractGasGiantSulfurCloud(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
6,3,"gas_remaining",
342,50,5,35,10,5
);
}
fn ExtractGasGiantSulfurCloudLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
6,3,"gas_remaining",
342,250,25,175,50,25
);
}
fn ExtractIceGiantFusionGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
7,0,"gas_remaining",
119,50,5,30,15,5
);
}
fn ExtractIceGiantFusionGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
7,0,"gas_remaining",
119,250,25,150,75,25
);
}
fn ExtractIceGiantVolatileIce(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
7,0,"crystal_remaining",
135,50,5,45,4,1
);
}
fn ExtractIceGiantVolatileIceLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
7,0,"crystal_remaining",
135,250,25,225,20,5
);
}
fn ExtractIceGiantNobleGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
7,0,"gas_remaining",
134,50,5,35,10,5
);
}
fn ExtractIceGiantNobleGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
7,0,"gas_remaining",
134,250,25,175,50,25
);
}
fn ExtractIceGiantCryogenicVolatile(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
7,3,"gas_remaining",
241,50,5,35,10,5
);
}
fn ExtractIceGiantCryogenicVolatileLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
7,3,"gas_remaining",
241,250,25,175,50,25
);
}
fn ExtractIceGiantIceMantleMaterial(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
7,7,"crystal_remaining",
242,50,5,30,15,5
);
}
fn ExtractIceGiantIceMantleMaterialLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
7,7,"crystal_remaining",
242,250,25,150,75,25
);
}
fn ExtractIceGiantHighPressurePhaseData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
7,7,"energy_remaining",
243,50,5
);
}
fn ExtractIceGiantHighPressurePhaseDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
7,7,"energy_remaining",
243,250,25
);
}
fn ExtractIceGiantCryosphereSpectrumData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
7,7,"energy_remaining",
343,50,5
);
}
fn ExtractIceGiantCryosphereSpectrumDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
7,7,"energy_remaining",
343,250,25
);
}
fn ExtractBarrenPlanetLightMetalOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(3689348813882916863);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
136,10,1,8,1,1
);
}
fn ExtractBarrenPlanetLightMetalOreMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(3689348813882916863);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
136,50,5,40,5,5
);
}
fn ExtractBarrenPlanetLightMetalOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(3689348813882916863);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
136,250,25,200,25,25
);
}
fn ExtractBarrenPlanetPreciousMetalOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"crystal_remaining",
137,10,1,8,1,1
);
}
fn ExtractBarrenPlanetPreciousMetalOreMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"crystal_remaining",
137,50,5,40,5,5
);
}
fn ExtractBarrenPlanetPreciousMetalOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"crystal_remaining",
137,250,25,200,25,25
);
}
fn ExtractBarrenPlanetNuclearOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
8,0,"crystal_remaining",
138,50,5,45,4,1
);
}
fn ExtractBarrenPlanetNuclearOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
8,0,"crystal_remaining",
138,250,25,225,20,5
);
}
fn ExtractBarrenPlanetCarbonaceousDeposit(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(3689348813882916864);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(7378697627765833727);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
139,10,1,6,3,1
);
}
fn ExtractBarrenPlanetCarbonaceousDepositMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(3689348813882916864);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(7378697627765833727);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
139,50,5,30,15,5
);
}
fn ExtractBarrenPlanetCarbonaceousDepositLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(3689348813882916864);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(7378697627765833727);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
139,250,25,150,75,25
);
}
fn ExtractBarrenPlanetFertilizerMineral(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(7378697627765833728);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-7378697632060801025);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
140,10,1,8,1,1
);
}
fn ExtractBarrenPlanetFertilizerMineralMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(7378697627765833728);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-7378697632060801025);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
140,50,5,40,5,5
);
}
fn ExtractBarrenPlanetFertilizerMineralLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(7378697627765833728);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-7378697632060801025);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
140,250,25,200,25,25
);
}
fn ExtractBarrenPlanetDenseMetalOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-7378697632060801024);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-3689348818177884161);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
141,50,5,45,4,1
);
}
fn ExtractBarrenPlanetDenseMetalOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-7378697632060801024);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-3689348818177884161);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
141,250,25,225,20,5
);
}
fn ExtractBarrenPlanetRareEarthOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"crystal_remaining",
142,50,5,45,4,1
);
}
fn ExtractBarrenPlanetRareEarthOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"crystal_remaining",
142,250,25,225,20,5
);
}
fn ExtractBarrenPlanetAlkaliMineralOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-3689348818177884160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
344,10,1,7,2,1
);
}
fn ExtractBarrenPlanetAlkaliMineralOreMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-3689348818177884160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
344,50,5,35,10,5
);
}
fn ExtractBarrenPlanetAlkaliMineralOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-3689348818177884160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
8,0,"matter_remaining",
344,250,25,175,50,25
);
}
fn ExtractNeutronStarMetalRichOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
9,16,"matter_remaining",
120,250,25,225,20,5
);
}
fn ExtractNeutronStarHighEnergyRadiation(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
9,8,"energy_remaining",
143,250,25
);
}
fn ExtractNeutronStarGravitationalData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
9,16,"energy_remaining",
144,250,25
);
}
fn ExtractNeutronStarRProcessEjecta(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
9,13,"matter_remaining",
244,250,25,225,20,5
);
}
fn ExtractNeutronStarDegenerateCrustMaterial(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
9,13,"crystal_remaining",
245,250,25,225,20,5
);
}
fn ExtractNeutronStarPulsarEmissionData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
9,16,"energy_remaining",
246,250,25
);
}
fn ExtractNeutronStarMagnetosphericParticleFlux(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
9,13,"energy_remaining",
345,250,25,225,20,5
);
}
fn ExtractNeutronStarPulsarTimingData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
9,16,"energy_remaining",
346,250,25
);
}
fn ExtractBlackHoleHighEnergyRadiation(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
10,8,"energy_remaining",
143,250,25
);
}
fn ExtractBlackHoleGravitationalData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
10,16,"energy_remaining",
144,250,25
);
}
fn ExtractBlackHoleAccretionData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
10,16,"energy_remaining",
145,250,25
);
}
fn ExtractBlackHoleAccretionDiskMatter(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
10,13,"energy_remaining",
247,250,25,225,20,5
);
}
fn ExtractBlackHoleRelativisticPlasma(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
10,13,"energy_remaining",
248,250,25,225,20,5
);
}
fn ExtractBlackHoleLensingData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
10,14,"energy_remaining",
249,250,25
);
}
fn ExtractBlackHoleAccretionAerosol(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
10,13,"energy_remaining",
347,250,25,150,75,25
);
}
fn ExtractBlackHoleHawkingRadiationData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
10,14,"energy_remaining",
348,250,25
);
}
fn ExtractAnomalyTemporalData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(4611686017353646079);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
11,14,"energy_remaining",
146,250,25
);
}
fn ExtractAnomalyGravitationalData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
11,14,"matter_remaining",
144,250,25
);
}
fn ExtractAnomalyFieldData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
11,14,"crystal_remaining",
147,250,25
);
}
fn ExtractAnomalyPhaseShiftedMatter(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
11,13,"matter_remaining",
250,250,25,225,20,5
);
}
fn ExtractAnomalyMagneticObservation(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
11,14,"crystal_remaining",
251,250,25
);
}
fn ExtractAnomalyRadiationObservation(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(4611686017353646080);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
11,14,"energy_remaining",
252,250,25
);
}
fn ExtractAnomalyPolarizationData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-4611686021648613377);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
11,14,"energy_remaining",
349,250,25
);
}
fn ExtractAnomalyVacuumFluctuationData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-4611686021648613376);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
11,14,"energy_remaining",
350,250,25
);
}
fn ExtractMegastructureStructuralSalvage(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,6,"matter_remaining",
148,10,1,6,3,1
);
}
fn ExtractMegastructureStructuralSalvageMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,6,"matter_remaining",
148,50,5,30,15,5
);
}
fn ExtractMegastructureStructuralSalvageLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,6,"matter_remaining",
148,250,25,150,75,25
);
}
fn ExtractMegastructureElectronicSalvage(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,2,"crystal_remaining",
149,50,5,40,5,5
);
}
fn ExtractMegastructureElectronicSalvageLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,2,"crystal_remaining",
149,250,25,200,25,25
);
}
fn ExtractMegastructureCeramicSalvage(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,1,"matter_remaining",
150,50,5,40,5,5
);
}
fn ExtractMegastructureCeramicSalvageLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,1,"matter_remaining",
150,250,25,200,25,25
);
}
fn ExtractMegastructureArchiveData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_32_core(
action,next_ship,resource,ship,body,
12,18,"crystal_remaining",
151,250,25
);
}
fn ExtractMegastructurePolymerSalvage(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,10,"matter_remaining",
253,10,1,8,1,1
);
}
fn ExtractMegastructurePolymerSalvageMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,10,"matter_remaining",
253,50,5,40,5,5
);
}
fn ExtractMegastructurePolymerSalvageLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,10,"matter_remaining",
253,250,25,200,25,25
);
}
fn ExtractMegastructureOpticalSalvage(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,15,"crystal_remaining",
254,10,1,8,1,1
);
}
fn ExtractMegastructureOpticalSalvageMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,15,"crystal_remaining",
254,50,5,40,5,5
);
}
fn ExtractMegastructureOpticalSalvageLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,15,"crystal_remaining",
254,250,25,200,25,25
);
}
fn ExtractMegastructureMechanicalSalvage(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,1,"matter_remaining",
351,10,1,8,1,1
);
}
fn ExtractMegastructureMechanicalSalvageMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,1,"matter_remaining",
351,50,5,40,5,5
);
}
fn ExtractMegastructureMechanicalSalvageLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_32_core(
action,next_ship,composite_resource,ship,body,
12,1,"matter_remaining",
351,250,25,200,25,25
);
}
fn ExtractGasClusterFusionGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
13,0,"gas_remaining",
119,10,1,6,3,1
);
}
fn ExtractGasClusterFusionGasMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
13,0,"gas_remaining",
119,50,5,30,15,5
);
}
fn ExtractGasClusterFusionGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
13,0,"gas_remaining",
119,250,25,150,75,25
);
}
fn ExtractGasClusterNobleGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
13,0,"gas_remaining",
134,10,1,7,2,1
);
}
fn ExtractGasClusterNobleGasMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
13,0,"gas_remaining",
134,50,5,35,10,5
);
}
fn ExtractGasClusterNobleGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
13,0,"gas_remaining",
134,250,25,175,50,25
);
}
fn ExtractGasClusterOrganicOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
13,0,"matter_remaining",
152,10,1,5,3,2
);
}
fn ExtractGasClusterOrganicOreMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
13,0,"matter_remaining",
152,50,5,25,15,10
);
}
fn ExtractGasClusterOrganicOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
13,0,"matter_remaining",
152,250,25,125,75,50
);
}
fn ExtractGasClusterMolecularCloudGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
13,0,"gas_remaining",
255,10,1,6,3,1
);
}
fn ExtractGasClusterMolecularCloudGasMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
13,0,"gas_remaining",
255,50,5,30,15,5
);
}
fn ExtractGasClusterMolecularCloudGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_2_core(
action,next_ship,composite_resource,ship,body,
13,0,"gas_remaining",
255,250,25,150,75,25
);
}
fn ExtractGasClusterInterstellarDust(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
13,0,"matter_remaining",
256,10,1,6,3,1
);
}
fn ExtractGasClusterInterstellarDustMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
13,0,"matter_remaining",
256,50,5,30,15,5
);
}
fn ExtractGasClusterInterstellarDustLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
13,0,"matter_remaining",
256,250,25,150,75,25
);
}
fn ExtractGasClusterMolecularSpectrumData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
13,11,"energy_remaining",
257,10,1
);
}
fn ExtractGasClusterMolecularSpectrumDataMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
13,11,"energy_remaining",
257,50,5
);
}
fn ExtractGasClusterMolecularSpectrumDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
13,11,"energy_remaining",
257,250,25
);
}
fn ExtractGasClusterPrebioticMoleculeMixture(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
13,5,"matter_remaining",
352,10,1,5,3,2
);
}
fn ExtractGasClusterPrebioticMoleculeMixtureMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
13,5,"matter_remaining",
352,50,5,25,15,10
);
}
fn ExtractGasClusterPrebioticMoleculeMixtureLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
13,5,"matter_remaining",
352,250,25,125,75,50
);
}
fn ExtractStellarRemnantMetalRichOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
14,16,"matter_remaining",
120,50,5,45,4,1
);
}
fn ExtractStellarRemnantMetalRichOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
14,16,"matter_remaining",
120,250,25,225,20,5
);
}
fn ExtractStellarRemnantNuclearOre(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
14,16,"energy_remaining",
138,50,5,45,4,1
);
}
fn ExtractStellarRemnantNuclearOreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
14,16,"energy_remaining",
138,250,25,225,20,5
);
}
fn ExtractStellarRemnantCarbonaceousDeposit(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
14,16,"matter_remaining",
139,50,5,30,15,5
);
}
fn ExtractStellarRemnantCarbonaceousDepositLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
14,16,"matter_remaining",
139,250,25,150,75,25
);
}
fn ExtractStellarRemnantSupernovaEjecta(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
14,16,"matter_remaining",
258,50,5,25,15,10
);
}
fn ExtractStellarRemnantSupernovaEjectaLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
14,16,"matter_remaining",
258,250,25,125,75,50
);
}
fn ExtractStellarRemnantRadioisotopeDeposit(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
14,4,"energy_remaining",
259,50,5,30,15,5
);
}
fn ExtractStellarRemnantRadioisotopeDepositLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
14,4,"energy_remaining",
259,250,25,150,75,25
);
}
fn ExtractStellarRemnantShockwaveSpectrumData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
14,16,"energy_remaining",
260,50,5
);
}
fn ExtractStellarRemnantShockwaveSpectrumDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
let resource_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
14,16,"energy_remaining",
260,250,25
);
}
fn ExtractStellarRemnantDecaySpectrumData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
14,16,"energy_remaining",
353,50,5
);
}
fn ExtractStellarRemnantDecaySpectrumDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
14,16,"energy_remaining",
353,250,25
);
}
fn ExtractAsteroidBeltNickelIronMatrix(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,1,"matter_remaining",
435,10,1,7,2,1
);
}
fn ExtractAsteroidBeltNickelIronMatrixMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,1,"matter_remaining",
435,50,5,35,10,5
);
}
fn ExtractAsteroidBeltNickelIronMatrixLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,1,"matter_remaining",
435,250,25,175,50,25
);
}
fn ExtractAsteroidBeltCarbonaceousRegolith(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,3,"matter_remaining",
436,10,1,5,3,2
);
}
fn ExtractAsteroidBeltCarbonaceousRegolithMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,3,"matter_remaining",
436,50,5,25,15,10
);
}
fn ExtractAsteroidBeltCarbonaceousRegolithLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,3,"matter_remaining",
436,250,25,125,75,50
);
}
fn ExtractAsteroidBeltSilicateRubble(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,6,"crystal_remaining",
437,10,1,6,3,1
);
}
fn ExtractAsteroidBeltSilicateRubbleMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,6,"crystal_remaining",
437,50,5,30,15,5
);
}
fn ExtractAsteroidBeltSilicateRubbleLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,6,"crystal_remaining",
437,250,25,150,75,25
);
}
fn ExtractAsteroidBeltHydratedMineralAggregate(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,3,"crystal_remaining",
438,10,1,5,3,2
);
}
fn ExtractAsteroidBeltHydratedMineralAggregateMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,3,"crystal_remaining",
438,50,5,25,15,10
);
}
fn ExtractAsteroidBeltHydratedMineralAggregateLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,3,"crystal_remaining",
438,250,25,125,75,50
);
}
fn ExtractAsteroidBeltPlatinumGroupVein(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,1,"matter_remaining",
439,50,5,45,4,1
);
}
fn ExtractAsteroidBeltPlatinumGroupVeinLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,1,"matter_remaining",
439,250,25,225,20,5
);
}
fn ExtractAsteroidBeltImpactGlassBreccia(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,7,"crystal_remaining",
440,10,1,8,1,1
);
}
fn ExtractAsteroidBeltImpactGlassBrecciaMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,7,"crystal_remaining",
440,50,5,40,5,5
);
}
fn ExtractAsteroidBeltImpactGlassBrecciaLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
15,7,"crystal_remaining",
440,250,25,200,25,25
);
}
fn ExtractAsteroidBeltOrbitalSurveyData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
15,11,"energy_remaining",
441,10,1
);
}
fn ExtractAsteroidBeltOrbitalSurveyDataMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
15,11,"energy_remaining",
441,50,5
);
}
fn ExtractAsteroidBeltOrbitalSurveyDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
15,11,"energy_remaining",
441,250,25
);
}
fn ExtractVolcanicPlanetUltramaficMagma(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,6,"matter_remaining",
442,10,1,6,3,1
);
}
fn ExtractVolcanicPlanetUltramaficMagmaMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,6,"matter_remaining",
442,50,5,30,15,5
);
}
fn ExtractVolcanicPlanetUltramaficMagmaLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,6,"matter_remaining",
442,250,25,150,75,25
);
}
fn ExtractVolcanicPlanetSulfideMagma(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,1,"matter_remaining",
443,10,1,7,2,1
);
}
fn ExtractVolcanicPlanetSulfideMagmaMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,1,"matter_remaining",
443,50,5,35,10,5
);
}
fn ExtractVolcanicPlanetSulfideMagmaLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,1,"matter_remaining",
443,250,25,175,50,25
);
}
fn ExtractVolcanicPlanetVolcanicAshDeposit(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,6,"matter_remaining",
444,10,1,5,3,2
);
}
fn ExtractVolcanicPlanetVolcanicAshDepositMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,6,"matter_remaining",
444,50,5,25,15,10
);
}
fn ExtractVolcanicPlanetVolcanicAshDepositLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,6,"matter_remaining",
444,250,25,125,75,50
);
}
fn ExtractVolcanicPlanetFumaroleCondensate(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
16,3,"gas_remaining",
445,10,1,7,2,1
);
}
fn ExtractVolcanicPlanetFumaroleCondensateMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
16,3,"gas_remaining",
445,50,5,35,10,5
);
}
fn ExtractVolcanicPlanetFumaroleCondensateLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
16,3,"gas_remaining",
445,250,25,175,50,25
);
}
fn ExtractVolcanicPlanetGeothermalBrine(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
16,3,"gas_remaining",
446,10,1,6,3,1
);
}
fn ExtractVolcanicPlanetGeothermalBrineMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
16,3,"gas_remaining",
446,50,5,30,15,5
);
}
fn ExtractVolcanicPlanetGeothermalBrineLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
16,3,"gas_remaining",
446,250,25,150,75,25
);
}
fn ExtractVolcanicPlanetMantleXenolith(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,7,"matter_remaining",
447,10,1,8,1,1
);
}
fn ExtractVolcanicPlanetMantleXenolithMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,7,"matter_remaining",
447,50,5,40,5,5
);
}
fn ExtractVolcanicPlanetMantleXenolithLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
16,7,"matter_remaining",
447,250,25,200,25,25
);
}
fn ExtractVolcanicPlanetSeismicTomographyData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
16,9,"energy_remaining",
448,10,1
);
}
fn ExtractVolcanicPlanetSeismicTomographyDataMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
16,9,"energy_remaining",
448,50,5
);
}
fn ExtractVolcanicPlanetSeismicTomographyDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
16,9,"energy_remaining",
448,250,25
);
}
fn ExtractNebulaIonizedHydrogenCloud(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
17,8,"gas_remaining",
449,50,5,30,15,5
);
}
fn ExtractNebulaIonizedHydrogenCloudLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
17,8,"gas_remaining",
449,250,25,150,75,25
);
}
fn ExtractNebulaMolecularIceMantle(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
17,3,"gas_remaining",
450,50,5,25,15,10
);
}
fn ExtractNebulaMolecularIceMantleLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
17,3,"gas_remaining",
450,250,25,125,75,50
);
}
fn ExtractNebulaStellarNurseryDust(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
17,16,"matter_remaining",
451,50,5,40,5,5
);
}
fn ExtractNebulaStellarNurseryDustLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
17,16,"matter_remaining",
451,250,25,200,25,25
);
}
fn ExtractNebulaPolycyclicAromaticMixture(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
17,10,"gas_remaining",
452,50,5,25,15,10
);
}
fn ExtractNebulaPolycyclicAromaticMixtureLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
17,10,"gas_remaining",
452,250,25,125,75,50
);
}
fn ExtractNebulaShockedNebularGas(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
17,16,"gas_remaining",
453,50,5,35,10,5
);
}
fn ExtractNebulaShockedNebularGasLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
17,16,"gas_remaining",
453,250,25,175,50,25
);
}
fn ExtractNebulaProtostarCensusData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
17,11,"energy_remaining",
454,50,5
);
}
fn ExtractNebulaProtostarCensusDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
17,11,"energy_remaining",
454,250,25
);
}
fn ExtractNebulaEmissionLineMap(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
17,9,"energy_remaining",
455,50,5
);
}
fn ExtractNebulaEmissionLineMapLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
17,9,"energy_remaining",
455,250,25
);
}
fn ExtractCometClusterPrimitiveIceMatrix(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
18,3,"crystal_remaining",
456,10,1,6,3,1
);
}
fn ExtractCometClusterPrimitiveIceMatrixMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
18,3,"crystal_remaining",
456,50,5,30,15,5
);
}
fn ExtractCometClusterPrimitiveIceMatrixLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
18,3,"crystal_remaining",
456,250,25,150,75,25
);
}
fn ExtractCometClusterRefractoryCometDust(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
18,7,"matter_remaining",
457,10,1,7,2,1
);
}
fn ExtractCometClusterRefractoryCometDustMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
18,7,"matter_remaining",
457,50,5,35,10,5
);
}
fn ExtractCometClusterRefractoryCometDustLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
18,7,"matter_remaining",
457,250,25,175,50,25
);
}
fn ExtractCometClusterComplexOrganicMantle(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
18,10,"matter_remaining",
458,10,1,5,3,2
);
}
fn ExtractCometClusterComplexOrganicMantleMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
18,10,"matter_remaining",
458,50,5,25,15,10
);
}
fn ExtractCometClusterComplexOrganicMantleLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
18,10,"matter_remaining",
458,250,25,125,75,50
);
}
fn ExtractCometClusterCryovolcanicPlume(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
18,3,"gas_remaining",
459,10,1,6,3,1
);
}
fn ExtractCometClusterCryovolcanicPlumeMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
18,3,"gas_remaining",
459,50,5,30,15,5
);
}
fn ExtractCometClusterCryovolcanicPlumeLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
18,3,"gas_remaining",
459,250,25,150,75,25
);
}
fn ExtractCometClusterPresolarGrainAggregate(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
18,16,"crystal_remaining",
460,50,5,45,4,1
);
}
fn ExtractCometClusterPresolarGrainAggregateLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
18,16,"crystal_remaining",
460,250,25,225,20,5
);
}
fn ExtractCometClusterIrradiatedIceCrust(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
18,7,"crystal_remaining",
461,10,1,8,1,1
);
}
fn ExtractCometClusterIrradiatedIceCrustMedium(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
18,7,"crystal_remaining",
461,50,5,40,5,5
);
}
fn ExtractCometClusterIrradiatedIceCrustLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
18,7,"crystal_remaining",
461,250,25,200,25,25
);
}
fn ExtractCometClusterCometaryOrbitSolution(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
18,11,"energy_remaining",
462,10,1
);
}
fn ExtractCometClusterCometaryOrbitSolutionMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
18,11,"energy_remaining",
462,50,5
);
}
fn ExtractCometClusterCometaryOrbitSolutionLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
18,11,"energy_remaining",
462,250,25
);
}
fn ExtractBrownDwarfMetallicHydrogenLayer(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
19,8,"gas_remaining",
463,50,5,40,5,5
);
}
fn ExtractBrownDwarfMetallicHydrogenLayerLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
19,8,"gas_remaining",
463,250,25,200,25,25
);
}
fn ExtractBrownDwarfAlkaliCloudDeck(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
19,3,"gas_remaining",
464,50,5,35,10,5
);
}
fn ExtractBrownDwarfAlkaliCloudDeckLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
19,3,"gas_remaining",
464,250,25,175,50,25
);
}
fn ExtractBrownDwarfSilicateCloudLayer(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
19,7,"matter_remaining",
465,50,5,30,15,5
);
}
fn ExtractBrownDwarfSilicateCloudLayerLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_8_core(
action,next_ship,composite_resource,ship,body,
19,7,"matter_remaining",
465,250,25,150,75,25
);
}
fn ExtractBrownDwarfCarbonChemistryMixture(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
19,10,"gas_remaining",
466,50,5,25,15,10
);
}
fn ExtractBrownDwarfCarbonChemistryMixtureLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_4_core(
action,next_ship,composite_resource,ship,body,
19,10,"gas_remaining",
466,250,25,125,75,50
);
}
fn ExtractBrownDwarfDeuteriumBurnAsh(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
19,4,"matter_remaining",
467,50,5,45,4,1
);
}
fn ExtractBrownDwarfDeuteriumBurnAshLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
19,4,"matter_remaining",
467,250,25,225,20,5
);
}
fn ExtractBrownDwarfInfraredWeatherMap(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
19,9,"energy_remaining",
468,50,5
);
}
fn ExtractBrownDwarfInfraredWeatherMapLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
19,9,"energy_remaining",
468,250,25
);
}
fn ExtractBrownDwarfSubstellarRotationData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
19,11,"energy_remaining",
469,50,5
);
}
fn ExtractBrownDwarfSubstellarRotationDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
19,11,"energy_remaining",
469,250,25
);
}
fn ExtractWhiteDwarfCrystallizedCarbonOxygenCore(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
20,13,"crystal_remaining",
470,50,5,45,4,1
);
}
fn ExtractWhiteDwarfCrystallizedCarbonOxygenCoreLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
20,13,"crystal_remaining",
470,250,25,225,20,5
);
}
fn ExtractWhiteDwarfDegenerateHeliumEnvelope(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
20,16,"matter_remaining",
471,50,5,25,15,10
);
}
fn ExtractWhiteDwarfDegenerateHeliumEnvelopeLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
20,16,"matter_remaining",
471,250,25,125,75,50
);
}
fn ExtractWhiteDwarfMetalPollutedAtmosphere(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
20,16,"matter_remaining",
472,50,5,35,10,5
);
}
fn ExtractWhiteDwarfMetalPollutedAtmosphereLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
20,16,"matter_remaining",
472,250,25,175,50,25
);
}
fn ExtractWhiteDwarfTidalDebrisDisk(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
20,11,"crystal_remaining",
473,50,5,25,15,10
);
}
fn ExtractWhiteDwarfTidalDebrisDiskLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
20,11,"crystal_remaining",
473,250,25,125,75,50
);
}
fn ExtractWhiteDwarfElectronDegenerateMatter(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
20,13,"matter_remaining",
474,50,5,40,5,5
);
}
fn ExtractWhiteDwarfElectronDegenerateMatterLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
20,13,"matter_remaining",
474,250,25,200,25,25
);
}
fn ExtractWhiteDwarfNovaAshDeposit(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
20,4,"crystal_remaining",
475,50,5,30,15,5
);
}
fn ExtractWhiteDwarfNovaAshDepositLarge(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_12_core(
action,next_ship,composite_resource,ship,body,
20,4,"crystal_remaining",
475,250,25,150,75,25
);
}
fn ExtractWhiteDwarfAsteroseismicModeData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
20,9,"energy_remaining",
476,50,5
);
}
fn ExtractWhiteDwarfAsteroseismicModeDataLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
20,9,"energy_remaining",
476,250,25
);
}
fn ExtractWhiteDwarfCoolingAgeCalibration(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
20,16,"energy_remaining",
477,50,5
);
}
fn ExtractWhiteDwarfCoolingAgeCalibrationLarge(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_12_core(
action,next_ship,resource,ship,body,
20,16,"energy_remaining",
477,250,25
);
}
fn ExtractMagnetarMagnetizedCrustalLattice(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
21,13,"crystal_remaining",
478,250,25,200,25,25
);
}
fn ExtractMagnetarUltraStrongFieldCondensate(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
21,14,"energy_remaining",
479,250,25,225,20,5
);
}
fn ExtractMagnetarStarquakeEjecta(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
21,16,"matter_remaining",
480,250,25,125,75,50
);
}
fn ExtractMagnetarTwistedMagnetospherePlasma(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
21,8,"energy_remaining",
481,250,25,150,75,25
);
}
fn ExtractMagnetarQEDVacuumDeposit(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
21,14,"energy_remaining",
482,250,25,225,20,5
);
}
fn ExtractMagnetarDenseNuclearCondensate(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
21,13,"crystal_remaining",
483,250,25,175,50,25
);
}
fn ExtractMagnetarGiantFlareLightCurve(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
21,9,"energy_remaining",
484,250,25
);
}
fn ExtractMagnetarMagneticTopologyMap(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
21,15,"energy_remaining",
485,250,25
);
}
fn ExtractWormholeMouthExoticThroatMatter(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
22,13,"matter_remaining",
486,250,25,225,20,5
);
}
fn ExtractWormholeMouthTidalShearCondensate(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
22,14,"crystal_remaining",
487,250,25,200,25,25
);
}
fn ExtractWormholeMouthChronologyResidue(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(body.source_signal_identifier,resource_selector_upper);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
22,14,"energy_remaining",
488,250,25,125,75,50
);
}
fn ExtractWormholeMouthVacuumBoundaryLayer(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
22,13,"matter_remaining",
489,250,25,225,20,5
);
}
fn ExtractWormholeMouthTraversabilityFieldMatrix(action){
var next_ship=action.output("microverse__ship");
var composite_resource=action.output("microverse__composite_resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_composite_vdf_20_core(
action,next_ship,composite_resource,ship,body,
22,14,"crystal_remaining",
490,250,25,150,75,25
);
}
fn ExtractWormholeMouthThroatGeometrySolution(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
let resource_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(resource_selector_lower,body.source_signal_identifier);
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
22,14,"energy_remaining",
491,250,25
);
}
fn ExtractWormholeMouthTransitPhaseData(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
22,11,"energy_remaining",
492,250,25
);
}
fn ExtractWormholeMouthCausalConnectivityMap(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var body=action.mutate("microverse__celestial_body");
extract_direct_body_vdf_20_core(
action,next_ship,resource,ship,body,
22,18,"energy_remaining",
493,250,25
);
}
fn RefineFusionGasToHydrogen(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,119,"child_1_remaining",153);}
fn RefineFusionGasToHelium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,119,"child_2_remaining",154);}
fn RefineFusionGasToDeuterium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,119,"child_3_remaining",155);}
fn RefineMetalRichOreToIron(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,1,120,"child_1_remaining",156);}
fn RefineMetalRichOreToNickel(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,1,120,"child_2_remaining",157);}
fn RefineMetalRichOreToCobalt(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,1,120,"child_3_remaining",158);}
fn RefineFerrousOreToIron(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,122,"child_1_remaining",156);}
fn RefineFerrousOreToChromium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,122,"child_2_remaining",159);}
fn RefineFerrousOreToManganese(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,122,"child_3_remaining",160);}
fn RefineBaseMetalOreToCopper(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,123,"child_1_remaining",161);}
fn RefineBaseMetalOreToZinc(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,123,"child_2_remaining",162);}
fn RefineBaseMetalOreToTin(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,123,"child_3_remaining",163);}
fn RefineSilicateMineralToSilicon(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,124,"child_1_remaining",164);}
fn RefineSilicateMineralToMagnesium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,124,"child_2_remaining",165);}
fn RefineSilicateMineralToQuartz(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,124,"child_3_remaining",166);}
fn RefineIndustrialMineralToLimestone(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,125,"child_1_remaining",167);}
fn RefineIndustrialMineralToClay(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,125,"child_2_remaining",168);}
fn RefineIndustrialMineralToGypsum(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,125,"child_3_remaining",169);}
fn RefineSeawaterMineralsToSodiumChloride(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,127,"child_1_remaining",170);}
fn RefineSeawaterMineralsToMagnesium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,127,"child_2_remaining",165);}
fn RefineSeawaterMineralsToCalcium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,127,"child_3_remaining",171);}
fn RefineAtmosphericGasToNitrogen(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,128,"child_1_remaining",172);}
fn RefineAtmosphericGasToOxygen(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,128,"child_2_remaining",173);}
fn RefineAtmosphericGasToCarbonDioxide(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,128,"child_3_remaining",174);}
fn RefineBiomassToCellulose(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,12,129,"child_1_remaining",175);}
fn RefineBiomassToProtein(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,12,129,"child_2_remaining",176);}
fn RefineBiomassToLipid(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,12,129,"child_3_remaining",177);}
fn RefineGeneticMaterialToDNA(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,5,130,"child_1_remaining",178);}
fn RefineGeneticMaterialToRNA(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,5,130,"child_2_remaining",179);}
fn RefineGeneticMaterialToPlasmid(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,5,130,"child_3_remaining",180);}
fn RefineBiochemicalMixtureToAminoAcid(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,5,131,"child_1_remaining",181);}
fn RefineBiochemicalMixtureToEnzyme(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,5,131,"child_2_remaining",182);}
fn RefineBiochemicalMixtureToAlkaloid(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,5,131,"child_3_remaining",183);}
fn RefineMicrobialCultureToBacterialCulture(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,12,132,"child_1_remaining",184);}
fn RefineMicrobialCultureToFungalCulture(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,12,132,"child_2_remaining",185);}
fn RefineMicrobialCultureToArchaealCulture(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,12,132,"child_3_remaining",186);}
fn RefineNaturalMaterialToWoodFiber(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,12,133,"child_1_remaining",187);}
fn RefineNaturalMaterialToChitin(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,12,133,"child_2_remaining",188);}
fn RefineNaturalMaterialToNaturalRubber(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,12,133,"child_3_remaining",189);}
fn RefineNobleGasToArgon(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,134,"child_1_remaining",190);}
fn RefineNobleGasToNeon(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,134,"child_2_remaining",191);}
fn RefineNobleGasToXenon(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,134,"child_3_remaining",192);}
fn RefineVolatileIceToWaterIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,135,"child_1_remaining",193);}
fn RefineVolatileIceToMethaneIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,135,"child_2_remaining",194);}
fn RefineVolatileIceToAmmoniaIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,135,"child_3_remaining",195);}
fn RefineLightMetalOreToAluminum(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,136,"child_1_remaining",196);}
fn RefineLightMetalOreToTitanium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,136,"child_2_remaining",197);}
fn RefineLightMetalOreToLithium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,136,"child_3_remaining",198);}
fn RefinePreciousMetalOreToSilver(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,137,"child_1_remaining",199);}
fn RefinePreciousMetalOreToGold(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,137,"child_2_remaining",200);}
fn RefinePreciousMetalOreToPlatinum(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,137,"child_3_remaining",201);}
fn RefineNuclearOreToUranium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,138,"child_1_remaining",202);}
fn RefineNuclearOreToThorium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,138,"child_2_remaining",203);}
fn RefineNuclearOreToRadium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,138,"child_3_remaining",204);}
fn RefineCarbonaceousDepositToCarbon(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,139,"child_1_remaining",205);}
fn RefineCarbonaceousDepositToGraphite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,139,"child_2_remaining",206);}
fn RefineCarbonaceousDepositToDiamond(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,139,"child_3_remaining",207);}
fn RefineFertilizerMineralToPhosphate(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,140,"child_1_remaining",208);}
fn RefineFertilizerMineralToSulfur(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,140,"child_2_remaining",209);}
fn RefineFertilizerMineralToPotash(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,140,"child_3_remaining",210);}
fn RefineStructuralSalvageToSteel(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,1,148,"child_1_remaining",211);}
fn RefineStructuralSalvageToAluminum(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,1,148,"child_2_remaining",196);}
fn RefineStructuralSalvageToCarbonComposite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,1,148,"child_3_remaining",212);}
fn RefineElectronicSalvageToCopper(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,2,149,"child_1_remaining",161);}
fn RefineElectronicSalvageToSilicon(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,2,149,"child_2_remaining",164);}
fn RefineElectronicSalvageToGold(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,2,149,"child_3_remaining",200);}
fn RefineCeramicSalvageToCeramic(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,3,150,"child_1_remaining",213);}
fn RefineCeramicSalvageToGlass(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,3,150,"child_2_remaining",214);}
fn RefineCeramicSalvageToSiliconCarbide(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,3,150,"child_3_remaining",215);}
fn RefineOrganicOreToMethanol(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,152,"child_1_remaining",216);}
fn RefineOrganicOreToFormaldehyde(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,152,"child_2_remaining",217);}
fn RefineOrganicOreToBenzene(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,152,"child_3_remaining",218);}
fn RefineDenseMetalOreToLead(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,141,"child_1_remaining",219);}
fn RefineDenseMetalOreToNickel(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,141,"child_2_remaining",157);}
fn RefineDenseMetalOreToCobalt(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,141,"child_3_remaining",158);}
fn RefineRareEarthOreToCerium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,142,"child_1_remaining",220);}
fn RefineRareEarthOreToLanthanum(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,142,"child_2_remaining",221);}
fn RefineRareEarthOreToNeodymium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,142,"child_3_remaining",222);}
fn RefineRedDwarfPlasmaToIonizedHydrogen(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,223,"child_1_remaining",261);}
fn RefineRedDwarfPlasmaToIonizedHelium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,223,"child_2_remaining",262);}
fn RefineRedDwarfPlasmaToElectronPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,223,"child_3_remaining",263);}
fn RefineMagneticStellarCondensateToFerriteDust(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,7,224,"child_1_remaining",264);}
fn RefineMagneticStellarCondensateToMagnetiteGrain(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,7,224,"child_2_remaining",265);}
fn RefineMagneticStellarCondensateToCobaltFerrite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,7,224,"child_3_remaining",266);}
fn RefinePhotosphericPlasmaToProtonPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,226,"child_1_remaining",267);}
fn RefinePhotosphericPlasmaToAlphaParticlePlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,226,"child_2_remaining",268);}
fn RefinePhotosphericPlasmaToPhotosphericElectronPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,226,"child_3_remaining",269);}
fn RefinePhotosphericMineralToCalciumIonDust(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,227,"child_1_remaining",270);}
fn RefinePhotosphericMineralToSodiumIonDust(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,227,"child_2_remaining",271);}
fn RefinePhotosphericMineralToMagnesiumIonDust(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,227,"child_3_remaining",272);}
fn RefineHeliumCarbonEjectaToHelium3(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,229,"child_1_remaining",273);}
fn RefineHeliumCarbonEjectaToCarbon12(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,229,"child_2_remaining",274);}
fn RefineHeliumCarbonEjectaToOxygen16(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,229,"child_3_remaining",275);}
fn RefineHeavyElementCondensateToStrontium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,230,"child_1_remaining",276);}
fn RefineHeavyElementCondensateToBarium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,230,"child_2_remaining",277);}
fn RefineHeavyElementCondensateToEuropium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,230,"child_3_remaining",278);}
fn RefineIgneousRockToBasalt(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,232,"child_1_remaining",279);}
fn RefineIgneousRockToGranite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,232,"child_2_remaining",280);}
fn RefineIgneousRockToObsidian(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,232,"child_3_remaining",281);}
fn RefineSeafloorSulfideOreToPyrite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,234,"child_1_remaining",282);}
fn RefineSeafloorSulfideOreToChalcopyrite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,234,"child_2_remaining",283);}
fn RefineSeafloorSulfideOreToSphalerite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,234,"child_3_remaining",284);}
fn RefineMarineBiomassToAlgalFiber(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,12,235,"child_1_remaining",285);}
fn RefineMarineBiomassToMarineProtein(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,12,235,"child_2_remaining",286);}
fn RefineMarineBiomassToAlgalOil(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,12,235,"child_3_remaining",287);}
fn RefineLivingSoilToHumus(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,17,237,"child_1_remaining",288);}
fn RefineLivingSoilToMycorrhizalCulture(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,17,237,"child_2_remaining",289);}
fn RefineLivingSoilToSoilMicrobiome(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,17,237,"child_3_remaining",290);}
fn RefineDeepAtmosphereGasToAmmoniaVapor(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,238,"child_1_remaining",291);}
fn RefineDeepAtmosphereGasToMethaneVapor(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,238,"child_2_remaining",292);}
fn RefineDeepAtmosphereGasToHydrogenSulfide(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,238,"child_3_remaining",293);}
fn RefineHydrocarbonCloudToEthane(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,239,"child_1_remaining",294);}
fn RefineHydrocarbonCloudToPropane(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,239,"child_2_remaining",295);}
fn RefineHydrocarbonCloudToAcetylene(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,239,"child_3_remaining",296);}
fn RefineCryogenicVolatileToLiquidMethane(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,241,"child_1_remaining",297);}
fn RefineCryogenicVolatileToLiquidAmmonia(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,241,"child_2_remaining",298);}
fn RefineCryogenicVolatileToSuperionicWater(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,7,241,"child_3_remaining",299);}
fn RefineIceMantleMaterialToHighPressureIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,242,"child_1_remaining",300);}
fn RefineIceMantleMaterialToMethaneClathrate(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,242,"child_2_remaining",301);}
fn RefineIceMantleMaterialToAmmoniaHydrate(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,242,"child_3_remaining",302);}
fn RefineRProcessEjectaToOsmium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,244,"child_1_remaining",303);}
fn RefineRProcessEjectaToIridium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,244,"child_2_remaining",304);}
fn RefineRProcessEjectaToRhenium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,244,"child_3_remaining",305);}
fn RefineDegenerateCrustMaterialToNuclearPasta(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,245,"child_1_remaining",306);}
fn RefineDegenerateCrustMaterialToNeutronRichAlloy(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,245,"child_2_remaining",307);}
fn RefineDegenerateCrustMaterialToSuperdenseCarbon(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,245,"child_3_remaining",308);}
fn RefineAccretionDiskMatterToIonizedIron(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,247,"child_1_remaining",309);}
fn RefineAccretionDiskMatterToCarbonPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,247,"child_2_remaining",310);}
fn RefineAccretionDiskMatterToSilicatePlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,247,"child_3_remaining",311);}
fn RefineRelativisticPlasmaToPairPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,248,"child_1_remaining",312);}
fn RefineRelativisticPlasmaToSynchrotronPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,248,"child_2_remaining",313);}
fn RefineRelativisticPlasmaToRelativisticIonBeam(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,248,"child_3_remaining",314);}
fn RefinePhaseShiftedMatterToMetastableIsotope(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,250,"child_1_remaining",315);}
fn RefinePhaseShiftedMatterToPhaseLockedCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,250,"child_2_remaining",316);}
fn RefinePhaseShiftedMatterToVacuumPolarizedMatter(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,250,"child_3_remaining",317);}
fn RefinePolymerSalvageToThermoplastic(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,10,253,"child_1_remaining",318);}
fn RefinePolymerSalvageToThermosetResin(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,10,253,"child_2_remaining",319);}
fn RefinePolymerSalvageToElastomer(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,10,253,"child_3_remaining",320);}
fn RefineOpticalSalvageToOpticalGlass(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,15,254,"child_1_remaining",321);}
fn RefineOpticalSalvageToPhotonicCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,15,254,"child_2_remaining",322);}
fn RefineOpticalSalvageToLaserCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,15,254,"child_3_remaining",323);}
fn RefineMolecularCloudGasToMolecularHydrogen(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,255,"child_1_remaining",324);}
fn RefineMolecularCloudGasToCarbonMonoxide(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,255,"child_2_remaining",325);}
fn RefineMolecularCloudGasToHydrogenCyanide(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_2_core(action,next_ship,resource,ship,parent,3,255,"child_3_remaining",326);}
fn RefineInterstellarDustToSilicateDust(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,256,"child_1_remaining",327);}
fn RefineInterstellarDustToCarbonDust(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,256,"child_2_remaining",328);}
fn RefineInterstellarDustToIceGrain(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,256,"child_3_remaining",329);}
fn RefineSupernovaEjectaToCalcium44(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,258,"child_1_remaining",330);}
fn RefineSupernovaEjectaToTitanium44(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,258,"child_2_remaining",331);}
fn RefineSupernovaEjectaToNickel56(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,258,"child_3_remaining",332);}
fn RefineRadioisotopeDepositToCobalt60(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,259,"child_1_remaining",333);}
fn RefineRadioisotopeDepositToCesium137(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,259,"child_2_remaining",334);}
fn RefineRadioisotopeDepositToStrontium90(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,259,"child_3_remaining",335);}
fn RefineStellarRefractoryDustToCorundum(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,7,336,"child_1_remaining",354);}
fn RefineStellarRefractoryDustToSpinel(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,7,336,"child_2_remaining",355);}
fn RefineStellarRefractoryDustToPerovskite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,7,336,"child_3_remaining",356);}
fn RefineSolarWindCondensateToLithium7(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,337,"child_1_remaining",357);}
fn RefineSolarWindCondensateToBeryllium9(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,337,"child_2_remaining",358);}
fn RefineSolarWindCondensateToBoron11(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,337,"child_3_remaining",359);}
fn RefineSProcessEjectaToYttrium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,338,"child_1_remaining",360);}
fn RefineSProcessEjectaToZirconium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,338,"child_2_remaining",361);}
fn RefineSProcessEjectaToMolybdenum(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,338,"child_3_remaining",362);}
fn RefineSedimentaryRockToSandstone(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,339,"child_1_remaining",363);}
fn RefineSedimentaryRockToShale(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,339,"child_2_remaining",364);}
fn RefineSedimentaryRockToDolomite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,339,"child_3_remaining",365);}
fn RefineDissolvedTraceMineralsToBromine(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,340,"child_1_remaining",366);}
fn RefineDissolvedTraceMineralsToIodine(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,340,"child_2_remaining",367);}
fn RefineDissolvedTraceMineralsToBoron(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,340,"child_3_remaining",368);}
fn RefinePlantExtractToStarch(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,12,341,"child_1_remaining",369);}
fn RefinePlantExtractToSucrose(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,12,341,"child_2_remaining",370);}
fn RefinePlantExtractToLignin(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,12,341,"child_3_remaining",371);}
fn RefineSulfurCloudToSulfurDioxide(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,342,"child_1_remaining",372);}
fn RefineSulfurCloudToAmmoniumHydrosulfide(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,342,"child_2_remaining",373);}
fn RefineSulfurCloudToPolysulfurAerosol(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,342,"child_3_remaining",374);}
fn RefineAlkaliMineralOreToSodium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,344,"child_1_remaining",375);}
fn RefineAlkaliMineralOreToPotassium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,344,"child_2_remaining",376);}
fn RefineAlkaliMineralOreToRubidium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,344,"child_3_remaining",377);}
fn RefineMagnetosphericParticleFluxToPositronPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,345,"child_1_remaining",378);}
fn RefineMagnetosphericParticleFluxToMuonFlux(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,345,"child_2_remaining",379);}
fn RefineMagnetosphericParticleFluxToHeavyIonFlux(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,345,"child_3_remaining",380);}
fn RefineAccretionAerosolToIronOxideAerosol(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,347,"child_1_remaining",381);}
fn RefineAccretionAerosolToSilicateAerosol(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,347,"child_2_remaining",382);}
fn RefineAccretionAerosolToCarbonaceousAerosol(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,347,"child_3_remaining",383);}
fn RefineMechanicalSalvageToBearingSteel(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,1,351,"child_1_remaining",384);}
fn RefineMechanicalSalvageToToolSteel(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,1,351,"child_2_remaining",385);}
fn RefineMechanicalSalvageToIndustrialLubricant(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_32_core(action,next_ship,resource,ship,parent,1,351,"child_3_remaining",386);}
fn RefinePrebioticMoleculeMixtureToGlycine(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,5,352,"child_1_remaining",387);}
fn RefinePrebioticMoleculeMixtureToFormamide(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,5,352,"child_2_remaining",388);}
fn RefinePrebioticMoleculeMixtureToAcetonitrile(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,5,352,"child_3_remaining",389);}
fn RefineNickelIronMatrixToKamacite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,435,"child_1_remaining",494);}
fn RefineNickelIronMatrixToTaenite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,435,"child_2_remaining",495);}
fn RefineNickelIronMatrixToSchreibersite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,435,"child_3_remaining",496);}
fn RefineCarbonaceousRegolithToKerogenGrain(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,436,"child_1_remaining",497);}
fn RefineCarbonaceousRegolithToInsolubleOrganicMatter(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,10,436,"child_2_remaining",498);}
fn RefineCarbonaceousRegolithToNanodiamondDust(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,436,"child_3_remaining",499);}
fn RefineSilicateRubbleToOlivineAggregate(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,437,"child_1_remaining",500);}
fn RefineSilicateRubbleToPyroxeneAggregate(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,437,"child_2_remaining",501);}
fn RefineSilicateRubbleToPlagioclaseFragment(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,437,"child_3_remaining",502);}
fn RefineHydratedMineralAggregateToSerpentineFiber(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,438,"child_1_remaining",503);}
fn RefineHydratedMineralAggregateToSaponiteClay(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,438,"child_2_remaining",504);}
fn RefineHydratedMineralAggregateToBruciteNodule(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,438,"child_3_remaining",505);}
fn RefinePlatinumGroupVeinToRuthenium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,439,"child_1_remaining",506);}
fn RefinePlatinumGroupVeinToRhodium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,439,"child_2_remaining",507);}
fn RefinePlatinumGroupVeinToPalladium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,439,"child_3_remaining",508);}
fn RefineImpactGlassBrecciaToTektiteGlass(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,440,"child_1_remaining",509);}
fn RefineImpactGlassBrecciaToMaskelynite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,440,"child_2_remaining",510);}
fn RefineImpactGlassBrecciaToShockedQuartz(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,440,"child_3_remaining",511);}
fn RefineUltramaficMagmaToKomatiiteMelt(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,442,"child_1_remaining",512);}
fn RefineUltramaficMagmaToDuniteCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,442,"child_2_remaining",513);}
fn RefineUltramaficMagmaToChromiteSpinel(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,442,"child_3_remaining",514);}
fn RefineSulfideMagmaToPentlandite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,443,"child_1_remaining",515);}
fn RefineSulfideMagmaToBornite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,443,"child_2_remaining",516);}
fn RefineSulfideMagmaToMolybdenite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,2,443,"child_3_remaining",517);}
fn RefineVolcanicAshDepositToPumice(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,444,"child_1_remaining",518);}
fn RefineVolcanicAshDepositToScoria(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,444,"child_2_remaining",519);}
fn RefineVolcanicAshDepositToVolcanicTuff(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,6,444,"child_3_remaining",520);}
fn RefineFumaroleCondensateToSulfurSublimate(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,445,"child_1_remaining",521);}
fn RefineFumaroleCondensateToRealgar(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,445,"child_2_remaining",522);}
fn RefineFumaroleCondensateToOrpiment(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,445,"child_3_remaining",523);}
fn RefineGeothermalBrineToCesiumChloride(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,446,"child_1_remaining",524);}
fn RefineGeothermalBrineToLithiumChloride(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,4,446,"child_2_remaining",525);}
fn RefineGeothermalBrineToBoricAcid(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,446,"child_3_remaining",526);}
fn RefineMantleXenolithToGarnetPeridotite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,447,"child_1_remaining",527);}
fn RefineMantleXenolithToEclogite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,447,"child_2_remaining",528);}
fn RefineMantleXenolithToKimberlite(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,447,"child_3_remaining",529);}
fn RefineIonizedHydrogenCloudToBalmerAlphaPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,449,"child_1_remaining",530);}
fn RefineIonizedHydrogenCloudToRecombinationIon(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,449,"child_2_remaining",531);}
fn RefineIonizedHydrogenCloudToFreeElectronGas(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,449,"child_3_remaining",532);}
fn RefineMolecularIceMantleToMethanolIceCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,450,"child_1_remaining",533);}
fn RefineMolecularIceMantleToCarbonylSulfideIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,450,"child_2_remaining",534);}
fn RefineMolecularIceMantleToCyanoacetyleneIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,10,450,"child_3_remaining",535);}
fn RefineStellarNurseryDustToProtochondruleGrain(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,16,451,"child_1_remaining",536);}
fn RefineStellarNurseryDustToCalciumAluminumInclusion(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,16,451,"child_2_remaining",537);}
fn RefineStellarNurseryDustToAmorphousSilicate(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,451,"child_3_remaining",538);}
fn RefinePolycyclicAromaticMixtureToNaphthalene(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,10,452,"child_1_remaining",539);}
fn RefinePolycyclicAromaticMixtureToAnthracene(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,10,452,"child_2_remaining",540);}
fn RefinePolycyclicAromaticMixtureToCoronene(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,10,452,"child_3_remaining",541);}
fn RefineShockedNebularGasToRadiativeShockPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,453,"child_1_remaining",542);}
fn RefineShockedNebularGasToTurbulentIonFilament(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,453,"child_2_remaining",543);}
fn RefineShockedNebularGasToCompressedMolecularKnot(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,453,"child_3_remaining",544);}
fn RefinePrimitiveIceMatrixToCarbonDioxideIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,456,"child_1_remaining",545);}
fn RefinePrimitiveIceMatrixToCarbonMonoxideIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,456,"child_2_remaining",546);}
fn RefinePrimitiveIceMatrixToMolecularNitrogenIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,456,"child_3_remaining",547);}
fn RefineRefractoryCometDustToForsteriteCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,457,"child_1_remaining",548);}
fn RefineRefractoryCometDustToEnstatiteCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,457,"child_2_remaining",549);}
fn RefineRefractoryCometDustToEmbeddedMetalSilicateGrain(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,1,457,"child_3_remaining",550);}
fn RefineComplexOrganicMantleToTholinGranule(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,17,458,"child_1_remaining",551);}
fn RefineComplexOrganicMantleToHexamethylenetetramine(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,10,458,"child_2_remaining",552);}
fn RefineComplexOrganicMantleToPolyoxymethylene(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,10,458,"child_3_remaining",553);}
fn RefineCryovolcanicPlumeToSupercooledWaterVapor(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,459,"child_1_remaining",554);}
fn RefineCryovolcanicPlumeToCarbonDioxideJet(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,459,"child_2_remaining",555);}
fn RefineCryovolcanicPlumeToAmmoniaJet(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,459,"child_3_remaining",556);}
fn RefinePresolarGrainAggregateToPresolarSiliconCarbide(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,460,"child_1_remaining",557);}
fn RefinePresolarGrainAggregateToGraphiticSpherule(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,460,"child_2_remaining",558);}
fn RefinePresolarGrainAggregateToCorundumStardust(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,460,"child_3_remaining",559);}
fn RefineIrradiatedIceCrustToRadicalBearingIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,461,"child_1_remaining",560);}
fn RefineIrradiatedIceCrustToAmorphousWaterIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,461,"child_2_remaining",561);}
fn RefineIrradiatedIceCrustToPeroxideIce(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,3,461,"child_3_remaining",562);}
fn RefineMetallicHydrogenLayerToDegenerateHydrogenFluid(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,463,"child_1_remaining",563);}
fn RefineMetallicHydrogenLayerToProtonicConductor(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,2,463,"child_2_remaining",564);}
fn RefineMetallicHydrogenLayerToPressureIonizedHelium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,8,463,"child_3_remaining",565);}
fn RefineAlkaliCloudDeckToSodiumSulfideCloud(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,464,"child_1_remaining",566);}
fn RefineAlkaliCloudDeckToPotassiumChlorideCloud(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,464,"child_2_remaining",567);}
fn RefineAlkaliCloudDeckToZincSulfideCondensate(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,464,"child_3_remaining",568);}
fn RefineSilicateCloudLayerToEnstatiteCloudCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,465,"child_1_remaining",569);}
fn RefineSilicateCloudLayerToIronSilicateDroplet(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,465,"child_2_remaining",570);}
fn RefineSilicateCloudLayerToAluminaCloudGrain(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_8_core(action,next_ship,resource,ship,parent,7,465,"child_3_remaining",571);}
fn RefineCarbonChemistryMixtureToAcetyleneSoot(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,10,466,"child_1_remaining",572);}
fn RefineCarbonChemistryMixtureToHydrogenCyanidePolymer(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,10,466,"child_2_remaining",573);}
fn RefineCarbonChemistryMixtureToCarbonMonosulfide(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_4_core(action,next_ship,resource,ship,parent,3,466,"child_3_remaining",574);}
fn RefineDeuteriumBurnAshToDeuteriumDepletedHelium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,467,"child_1_remaining",575);}
fn RefineDeuteriumBurnAshToLithiumDepletionResidue(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,467,"child_2_remaining",576);}
fn RefineDeuteriumBurnAshToProtonCaptureAsh(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,467,"child_3_remaining",577);}
fn RefineCrystallizedCarbonOxygenCoreToCarbonOxygenLattice(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,470,"child_1_remaining",578);}
fn RefineCrystallizedCarbonOxygenCoreToNeon22Sediment(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,4,470,"child_2_remaining",579);}
fn RefineCrystallizedCarbonOxygenCoreToPhaseSeparatedOxygen(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,7,470,"child_3_remaining",580);}
fn RefineDegenerateHeliumEnvelopeToPressureBroadenedHelium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,16,471,"child_1_remaining",581);}
fn RefineDegenerateHeliumEnvelopeToTraceCarbonLayer(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,16,471,"child_2_remaining",582);}
fn RefineDegenerateHeliumEnvelopeToConvectiveHeliumCell(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,16,471,"child_3_remaining",583);}
fn RefineMetalPollutedAtmosphereToSinkingCalcium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,472,"child_1_remaining",584);}
fn RefineMetalPollutedAtmosphereToSinkingMagnesium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,472,"child_2_remaining",585);}
fn RefineMetalPollutedAtmosphereToSinkingIron(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,472,"child_3_remaining",586);}
fn RefineTidalDebrisDiskToRocheShreddedSilicate(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,11,473,"child_1_remaining",587);}
fn RefineTidalDebrisDiskToVaporizedMetalRing(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,16,473,"child_2_remaining",588);}
fn RefineTidalDebrisDiskToCompactDustArc(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,11,473,"child_3_remaining",589);}
fn RefineElectronDegenerateMatterToFermiElectronFluid(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,474,"child_1_remaining",590);}
fn RefineElectronDegenerateMatterToRelativisticElectronGas(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,474,"child_2_remaining",591);}
fn RefineElectronDegenerateMatterToCoulombCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,7,474,"child_3_remaining",592);}
fn RefineNovaAshDepositToNeonMagnesiumAsh(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,475,"child_1_remaining",593);}
fn RefineNovaAshDepositToAluminum26Deposit(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,475,"child_2_remaining",594);}
fn RefineNovaAshDepositToSodium22Deposit(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_12_core(action,next_ship,resource,ship,parent,4,475,"child_3_remaining",595);}
fn RefineMagnetizedCrustalLatticeToMagnetostrictiveIron(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,7,478,"child_1_remaining",596);}
fn RefineMagnetizedCrustalLatticeToQuantizedCrystalDomain(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,478,"child_2_remaining",597);}
fn RefineMagnetizedCrustalLatticeToNuclearImpurityLayer(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,478,"child_3_remaining",598);}
fn RefineUltraStrongFieldCondensateToLandauQuantizedPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,479,"child_1_remaining",599);}
fn RefineUltraStrongFieldCondensateToVacuumBirefringentMedium(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,479,"child_2_remaining",600);}
fn RefineUltraStrongFieldCondensateToBoundMagneticAtom(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,7,479,"child_3_remaining",601);}
fn RefineStarquakeEjectaToNeutronRichCrustShard(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,480,"child_1_remaining",602);}
fn RefineStarquakeEjectaToRelativisticPairFireball(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,16,480,"child_2_remaining",603);}
fn RefineStarquakeEjectaToHeavyNucleusFragment(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,4,480,"child_3_remaining",604);}
fn RefineTwistedMagnetospherePlasmaToResonantCyclotronPlasma(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,8,481,"child_1_remaining",605);}
fn RefineTwistedMagnetospherePlasmaToCurrentCarryingPairStream(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,8,481,"child_2_remaining",606);}
fn RefineTwistedMagnetospherePlasmaToMagnetosphericTwistFlux(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,481,"child_3_remaining",607);}
fn RefineQEDVacuumDepositToPhotonSplittingResidue(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,482,"child_1_remaining",608);}
fn RefineQEDVacuumDepositToPolarizedVacuumDomain(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,482,"child_2_remaining",609);}
fn RefineQEDVacuumDepositToMagneticPairCreationSeed(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,482,"child_3_remaining",610);}
fn RefineDenseNuclearCondensateToHyperonRichMatter(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,483,"child_1_remaining",611);}
fn RefineDenseNuclearCondensateToSuperfluidNeutronVortex(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,483,"child_2_remaining",612);}
fn RefineDenseNuclearCondensateToSuperconductingProtonPhase(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,4,483,"child_3_remaining",613);}
fn RefineExoticThroatMatterToNegativeEnergyCondensate(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,486,"child_1_remaining",614);}
fn RefineExoticThroatMatterToNullEnergyFilament(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,486,"child_2_remaining",615);}
fn RefineExoticThroatMatterToCasimirDenseFoam(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,486,"child_3_remaining",616);}
fn RefineTidalShearCondensateToGeodesicShearCrystal(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,487,"child_1_remaining",617);}
fn RefineTidalShearCondensateToRedshiftLockedLattice(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,7,487,"child_2_remaining",618);}
fn RefineTidalShearCondensateToCurvatureStressedMatter(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,487,"child_3_remaining",619);}
fn RefineChronologyResidueToClosedTimelikeFragment(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,488,"child_1_remaining",620);}
fn RefineChronologyResidueToCausalHorizonDust(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,488,"child_2_remaining",621);}
fn RefineChronologyResidueToProperTimeDifferential(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,11,488,"child_3_remaining",622);}
fn RefineVacuumBoundaryLayerToFalseVacuumMembrane(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,489,"child_1_remaining",623);}
fn RefineVacuumBoundaryLayerToTopologicalDomainWall(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,489,"child_2_remaining",624);}
fn RefineVacuumBoundaryLayerToQuantumFoamInclusion(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,13,489,"child_3_remaining",625);}
fn RefineTraversabilityFieldMatrixToMorrisThorneMetricSeed(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,490,"child_1_remaining",626);}
fn RefineTraversabilityFieldMatrixToThroatStabilizationMode(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,490,"child_2_remaining",627);}
fn RefineTraversabilityFieldMatrixToExoticStressTensor(action){
var next_ship=action.output("microverse__ship");
var resource=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var parent=action.mutate("microverse__composite_resource");
refine_resource_vdf_20_core(action,next_ship,resource,ship,parent,14,490,"child_3_remaining",628);}
fn FabricateStructuralAlloyReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,1,211,6,196,3,159,2,257,390,1);}
fn FabricateStructuralAlloyFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,1,211,6,196,3,159,2,257,390,1);}
fn FabricateCeramicPlatingReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,6,213,40,215,5,354,35,233,391,1);}
fn FabricateCeramicPlatingFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,6,213,40,215,5,354,35,233,391,1);}
fn FabricateCircuitSubstrateReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,2,164,5,161,7,354,35,147,392,1);}
fn FabricateCircuitSubstrateFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,2,164,5,161,7,354,35,147,392,1);}
fn FabricatePressureVesselReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,6,385,1,159,2,319,1,240,393,1);}
fn FabricatePressureVesselFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,6,385,1,159,2,319,1,240,393,1);}
fn FabricateFuelSlurryReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,3,216,5,218,2,386,1,257,394,1);}
fn FabricateFuelSlurryFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,3,216,5,218,2,386,1,257,394,1);}
fn FabricateAbrasiveCompoundReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,10,207,1,354,35,327,6,243,395,1);}
fn FabricateAbrasiveCompoundFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,10,207,1,354,35,327,6,243,395,1);}
fn FabricateMagneticCoreReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,2,264,35,266,5,222,5,251,396,1);}
fn FabricateMagneticCoreFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,2,264,35,266,5,222,5,251,396,1);}
fn FabricateSealantResinReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,10,318,8,189,2,371,1,257,397,1);}
fn FabricateSealantResinFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,10,318,8,189,2,371,1,257,397,1);}
fn FabricateFusionCellReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,4,155,1,273,25,357,30,228,398,1);}
fn FabricateFusionCellFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,4,155,1,273,25,357,30,228,398,1);}
fn FabricateRadiationShieldingReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,6,219,45,368,1,193,45,353,399,1);}
fn FabricateRadiationShieldingFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,6,219,45,368,1,193,45,353,399,1);}
fn FabricatePhotonicArrayReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,2,322,1,222,5,321,8,147,400,1);}
fn FabricatePhotonicArrayFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,2,322,1,222,5,321,8,147,400,1);}
fn FabricateSuperconductorReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,2,222,5,161,7,273,25,251,401,1);}
fn FabricateSuperconductorFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,2,222,5,161,7,273,25,251,401,1);}
fn FabricateLifeSupportMembraneReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,17,182,3,175,5,320,1,126,402,1);}
fn FabricateLifeSupportMembraneFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,17,182,3,175,5,320,1,126,402,1);}
fn FabricateCryogenicLineReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,10,297,35,300,30,320,1,343,403,1);}
fn FabricateCryogenicLineFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,10,297,35,300,30,320,1,343,403,1);}
fn FabricateCatalyticBedReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,10,201,1,220,45,361,15,257,404,1);}
fn FabricateCatalyticBedFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,10,201,1,220,45,361,15,257,404,1);}
fn FabricateBioreactorCultureReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,17,184,5,181,5,286,3,126,405,1);}
fn FabricateBioreactorCultureFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,17,184,5,181,5,286,3,126,405,1);}
fn FabricateLaserAssemblyReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,11,323,1,222,5,321,8,225,406,1);}
fn FabricateLaserAssemblyFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,11,323,1,222,5,321,8,225,406,1);}
fn FabricateIsotopeBatteryReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,18,335,5,334,15,219,45,353,407,1);}
fn FabricateIsotopeBatteryFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,18,335,5,334,15,219,45,353,407,1);}
fn FabricateNeutronArmourReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,18,307,20,303,225,385,1,346,408,1);}
fn FabricateNeutronArmourFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,18,307,20,303,225,385,1,346,408,1);}
fn FabricateDegenerateLatticeReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,18,306,225,304,20,316,20,246,409,1);}
fn FabricateDegenerateLatticeFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,18,306,225,304,20,316,20,246,409,1);}
fn FabricateEventHorizonCoilReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,13,308,5,310,20,305,5,348,410,1);}
fn FabricateEventHorizonCoilFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,13,308,5,310,20,305,5,348,410,1);}
fn FabricateGraviticLensReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,11,308,5,321,8,201,1,249,411,1);}
fn FabricateGraviticLensFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,11,308,5,321,8,201,1,249,411,1);}
fn FabricatePhaseStabiliserReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,11,316,20,315,225,304,20,349,412,1);}
fn FabricatePhaseStabiliserFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,11,316,20,315,225,304,20,349,412,1);}
fn FabricateWarpCoilReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,11,317,5,316,20,308,5,146,413,1);}
fn FabricateWarpCoilFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,11,317,5,316,20,308,5,146,413,1);}
fn FabricateThermalExchangerReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,6,161,7,159,2,213,40,233,414,1);}
fn FabricateThermalExchangerFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,6,161,7,159,2,213,40,233,414,1);}
fn FabricateSensorPackageReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,9,164,5,321,8,264,35,147,415,1);}
fn FabricateSensorPackageFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,9,164,5,321,8,264,35,147,415,1);}
fn FabricateServoAssemblyReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,9,384,8,158,5,386,1,251,416,1);}
fn FabricateServoAssemblyFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,9,384,8,158,5,386,1,251,416,1);}
fn FabricateDataStorageMatrixReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,9,164,5,214,5,354,35,151,417,1);}
fn FabricateDataStorageMatrixFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,9,164,5,214,5,354,35,151,417,1);}
fn FabricateAtmosphericScrubberReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,17,212,1,213,40,210,1,240,418,1);}
fn FabricateAtmosphericScrubberFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,17,212,1,213,40,210,1,240,418,1);}
fn FabricateNavigationOpticsReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,11,321,8,200,1,166,1,249,419,1);}
fn FabricateNavigationOpticsFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,11,321,8,200,1,166,1,249,419,1);}
fn FabricateCivicUtilityModuleReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_8_core(action,n,c,s,a,b,d,k,18,211,6,161,7,159,2,121,420,1);}
fn FabricateCivicUtilityModuleFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_8_core(action,n,c,s,a,b,d,k,18,211,6,161,7,159,2,121,420,1);}
fn FabricateQuantumProcessorReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,9,164,5,322,1,222,5,350,421,1);}
fn FabricateQuantumProcessorFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,9,164,5,322,1,222,5,350,421,1);}
fn FabricateAutonomousFabricatorReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,9,385,1,215,5,222,5,151,422,1);}
fn FabricateAutonomousFabricatorFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,9,385,1,215,5,222,5,151,422,1);}
fn FabricateLongRangeTransceiverReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,15,323,1,266,5,200,1,346,423,1);}
fn FabricateLongRangeTransceiverFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,15,323,1,266,5,200,1,346,423,1);}
fn FabricateEcologicalSeederReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,17,178,5,285,5,208,8,236,424,1);}
fn FabricateEcologicalSeederFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,17,178,5,285,5,208,8,236,424,1);}
fn FabricateInertialCompensatorReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_12_core(action,n,c,s,a,b,d,k,11,222,5,212,1,266,5,144,425,1);}
fn FabricateInertialCompensatorFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_12_core(action,n,c,s,a,b,d,k,11,222,5,212,1,266,5,144,425,1);}
fn FabricateCausalMapperReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,15,316,20,313,20,323,1,146,426,1);}
fn FabricateCausalMapperFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,15,316,20,313,20,323,1,146,426,1);}
fn FabricateGravitationalAnchorReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,18,308,5,303,225,316,20,143,427,1);}
fn FabricateGravitationalAnchorFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,18,308,5,303,225,316,20,143,427,1);}
fn FabricateTemporalRegulatorReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,15,315,225,305,5,322,1,252,428,1);}
fn FabricateTemporalRegulatorFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,15,315,225,305,5,322,1,252,428,1);}
fn FabricateStellarForgeCoreReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,18,309,225,306,225,316,20,260,429,1);}
fn FabricateStellarForgeCoreFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,18,309,225,306,225,316,20,260,429,1);}
fn FabricateBiosphereGenesisMatrixReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,9,178,5,286,3,317,5,151,430,1);}
fn FabricateBiosphereGenesisMatrixFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,9,178,5,286,3,317,5,151,430,1);}
fn FabricateGalacticCognitionNodeReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,9,322,1,378,225,316,20,231,431,1);}
fn FabricateGalacticCognitionNodeFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,9,322,1,378,225,316,20,231,431,1);}
fn FabricateWormholeApertureRingReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,15,317,5,308,5,311,5,145,432,1);}
fn FabricateWormholeApertureRingFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,15,317,5,308,5,311,5,145,432,1);}
fn FabricateCivilizationArchiveSeedReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,18,316,20,323,1,178,5,151,433,1);}
fn FabricateCivilizationArchiveSeedFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,18,316,20,323,1,178,5,151,433,1);}
fn FabricateVacuumEnergyTapReusable(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.mutate("microverse__resource");
fabricate_component_reusable_vdf_32_core(action,n,c,s,a,b,d,k,9,317,5,312,225,307,20,350,434,1);}
fn FabricateVacuumEnergyTapFinal(action){
var n=action.output("microverse__ship");
var c=action.output("microverse__resource");
var s=action.input("microverse__ship");
var a=action.input("microverse__resource");
var b=action.input("microverse__resource");
var d=action.input("microverse__resource");
var k=action.input("microverse__resource");
fabricate_component_final_vdf_32_core(action,n,c,s,a,b,d,k,9,317,5,312,225,307,20,350,434,1);}
fn DevelopTypeIIndustrialFabricationSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_upper=action.top_limb_u256(3074457344902430719);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
1,
1,
1
);
}
fn DevelopTypeIElectronicsSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(3074457344902430720);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
1,
2,
1
);
}
fn DevelopTypeIChemicalEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
1,
3,
1
);
}
fn DevelopTypeINuclearEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
1,
4,
1
);
}
fn DevelopTypeIGeneticEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(-3074457349197398017);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
1,
5,
1
);
}
fn DevelopTypeIPlanetaryInfrastructureSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(-3074457349197398016);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
1,
6,
1
);
}
fn DevelopTypeIIMetamaterialEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_upper=action.top_limb_u256(3074457344902430719);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
2,
7,
1
);
}
fn DevelopTypeIIStellarEnergySystemsSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(3074457344902430720);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
2,
8,
1
);
}
fn DevelopTypeIISyntheticIntelligenceSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
2,
9,
1
);
}
fn DevelopTypeIIMolecularFabricationSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
2,
10,
1
);
}
fn DevelopTypeIIInterstellarNavigationSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(-3074457349197398017);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
2,
11,
1
);
}
fn DevelopTypeIIBiosphereEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(-3074457349197398016);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
2,
12,
1
);
}
fn DevelopTypeIIIExoticMatterEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_upper=action.top_limb_u256(3074457344902430719);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
3,
13,
1
);
}
fn DevelopTypeIIISpacetimeEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(3074457344902430720);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(6148914689804861439);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
3,
14,
1
);
}
fn DevelopTypeIIIGalacticIntelligenceArchitectureSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(6148914689804861440);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(9223372034707292159);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
3,
15,
1
);
}
fn DevelopTypeIIIStellarEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(9223372034707292160);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(-6148914694099828737);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
3,
16,
1
);
}
fn DevelopTypeIIIWorldSeedingSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(-6148914694099828736);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
let skill_selector_upper=action.top_limb_u256(-3074457349197398017);
action.intro_lt_eq_u256(civilization.source_life_signal_identifier,skill_selector_upper);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
3,
17,
1
);
}
fn DevelopTypeIIICivilizationEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var civilization=action.mutate("microverse__civilization");
let skill_selector_lower=action.top_limb_u256(-3074457349197398016);
action.intro_lt_eq_u256(skill_selector_lower,civilization.source_life_signal_identifier);
develop_technology_skill_core(
action,
next_ship,
technology_skill,
ship,
civilization,
3,
18,
1
);
}
fn DevelopStructuralMetallurgySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,1,19,390,1,211,6);}
fn DevelopPrecisionToolingSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,1,20,395,1,385,1);}
fn DevelopPressureSystemsSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,1,21,393,1,233,10);}
fn DevelopCircuitArchitectureSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,2,22,392,1,161,7);}
fn DevelopElectromagneticSystemsSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,2,23,396,1,264,35);}
fn DevelopSensorInstrumentationSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,2,24,392,1,228,50);}
fn DevelopSeparationChemistrySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,3,25,257,10,201,1);}
fn DevelopPolymerChemistrySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,3,26,397,1,319,1);}
fn DevelopPropellantChemistrySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,3,27,394,1,155,1);}
fn DevelopFissionReactorEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,4,28,202,45,391,1);}
fn DevelopIsotopeEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,4,29,333,30,353,50);}
fn DevelopRadiationProtectionSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,4,30,219,45,368,1,126,10);}
fn DevelopGenomeEditingSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,5,31,178,5,180,2);}
fn DevelopMicrobialDesignSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,5,32,184,5,182,3);}
fn DevelopAdaptiveOrganismDesignSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,5,33,387,5,179,3);}
fn DevelopCivilConstructionSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,6,34,390,1,391,1);}
fn DevelopGeotechnicalEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,6,35,279,6,233,10);}
fn DevelopUtilityNetworksSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_8_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,6,36,393,1,392,1);}
fn DevelopPhotonicMaterialsSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,7,37,400,1,349,250);}
fn DevelopSuperconductingMediaSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,7,38,401,1,251,250);}
fn DevelopExtremePhaseCompositesSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,7,39,300,30,243,50);}
fn DevelopFusionPowerSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,8,40,398,1,228,50);}
fn DevelopRadiantHarvestingSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,8,41,400,1,225,50);}
fn DevelopPlasmaConfinementSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,8,42,401,1,264,35);}
fn DevelopScientificInferenceSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,9,43,392,1,147,250);}
fn DevelopAutonomousControlSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,9,44,684,1,240,50);}
fn DevelopFleetCoordinationSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,9,45,400,1,246,250);}
fn DevelopPolymerNanofabricationSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,10,46,402,1,318,8);}
fn DevelopCrystalLatticeFabricationSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,10,47,406,1,243,50);}
fn DevelopMolecularAssemblySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,10,48,404,1,257,10);}
fn DevelopStellarAstrometrySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,11,49,415,1,228,50);}
fn DevelopGravitationalCartographySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,11,50,411,1,249,250);}
fn DevelopRelativisticPilotingSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,11,51,425,1,346,250);}
fn DevelopClosedLoopEcologySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,12,52,402,1,175,5);}
fn DevelopMicrobialEcologySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,12,53,405,1,184,5);}
fn DevelopAquaticHabitatEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,12,54,126,10,286,3);}
fn DevelopDegenerateMatterScienceSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,13,55,409,1,246,250);}
fn DevelopVacuumStateMaterialsSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,13,56,412,1,350,250);}
fn DevelopRelativisticPlasmaEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,13,57,410,1,145,250);}
fn DevelopTemporalTopologySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,14,58,412,1,146,250);}
fn DevelopWormholeGeometrySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,14,59,426,1,432,1);}
fn DevelopCausalStabilizationSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,14,60,428,1,348,250);}
fn DevelopDeepArchiveSystemsSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,15,61,417,1,151,250);}
fn DevelopInterstellarCommunicationsSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,15,62,423,1,246,250);}
fn DevelopDistributedCognitionSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,15,63,431,1,316,20);}
fn DevelopPhotosphericControlSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,16,64,267,30,225,50);}
fn DevelopStarLiftingSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,16,65,401,1,264,35);}
fn DevelopRemnantEngineeringSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,16,66,409,1,260,50);}
fn DevelopAtmosphericGenesisSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,17,67,642,1,174,2);}
fn DevelopHydrosphereGenesisSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,17,68,403,1,126,10);}
fn DevelopSoilEcologyGenesisSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,17,69,405,1,290,1);}
fn DevelopCulturalContinuitySkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,18,70,417,1,151,250);}
fn DevelopGovernanceSystemsSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,18,71,691,1,151,250);}
fn DevelopInterstellarLogisticsSkill(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
develop_derived_skill_2_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,18,72,693,1,672,1);}
fn DevelopIntegratedIndustrialSystemsMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,1,73,629,1,630,1,631,1);}
fn DevelopIntegratedElectronicsMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,2,74,632,1,633,1,634,1);}
fn DevelopChemicalPlantArchitectureMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,3,75,635,1,636,1,637,1);}
fn DevelopNuclearPowerArchitectureMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,4,76,638,1,639,1,640,1);}
fn DevelopSyntheticGenomicsMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,5,77,641,1,642,1,643,1);}
fn DevelopPlanetaryWorksMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_12_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,6,78,644,1,645,1,646,1);}
fn DevelopProgrammableMatterMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,7,79,647,1,648,1,649,1);}
fn DevelopStellarPowerArchitectureMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,8,80,650,1,651,1,652,1);}
fn DevelopCognitiveInfrastructureMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,9,81,653,1,654,1,655,1);}
fn DevelopAtomicallyPreciseManufacturingMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,10,82,656,1,657,1,658,1);}
fn DevelopGalacticCartographyMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,11,83,659,1,660,1,661,1);}
fn DevelopBiosphereArchitectureMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,12,84,662,1,663,1,664,1);}
fn DevelopExoticMaterialsArchitectureMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,13,85,665,1,666,1,667,1);}
fn DevelopCausalArchitectureMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,14,86,668,1,669,1,670,1);}
fn DevelopGalacticCognitiveMeshMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,15,87,671,1,672,1,673,1);}
fn DevelopStellarArchitectureMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,16,88,674,1,675,1,676,1);}
fn DevelopTerraformingArchitectureMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,17,89,677,1,678,1,679,1);}
fn DevelopCivilizationArchitectureMastery(action){
var next_ship=action.output("microverse__ship");
var technology_skill=action.output("microverse__technology_skill");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
develop_derived_skill_3_evidence_vdf_32_core(action,next_ship,technology_skill,ship,evidence_1,evidence_2,evidence_3,18,90,680,1,681,1,682,1);}
fn ForgeReinforcedHullFrame(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,19,629,1,390,1);}
fn FabricatePrecisionToolhead(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,20,630,1,395,1);}
fn AssembleHabitatPressureShell(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,21,631,1,393,1);}
fn FabricateLogicControlBoard(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,22,632,1,392,1);}
fn FabricateFieldControlAssembly(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,23,633,1,396,1);}
fn AssembleSurveySensorArray(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,24,634,1,415,1);}
fn BuildSelectiveSeparationColumn(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,25,635,1,404,1);}
fn SynthesizePolymerMatrix(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,26,636,1,397,1);}
fn BlendHighEnergyPropellant(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,27,637,1,394,1);}
fn AssembleFissionReactorCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,28,638,1,399,1);}
fn FabricateIsotopePowerCell(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,29,639,1,407,1);}
fn AssembleRadiationVaultModule(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,30,640,1,399,1);}
fn CompileEditedGenomeArchive(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,31,641,1,417,1);}
fn CultureEngineeredMicrobe(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,32,642,1,405,1);}
fn DesignAdaptiveGermline(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,33,643,1,430,1);}
fn AssembleHabitatFoundation(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
produce_capability_artifact_2_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,evidence_2,34,644,1,390,1,391,1);}
fn ProduceGeotechnicalSurvey(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
produce_capability_artifact_2_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,evidence_2,35,645,1,415,1,414,1);}
fn AssembleUtilityGridNode(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_8_core(action,next_ship,artifact,ship,evidence_1,36,646,1,420,1);}
fn FabricateAdaptiveOptic(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,37,647,1,400,1);}
fn WindSuperconductingFieldCoil(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,38,648,1,401,1);}
fn SynthesizePhaseCompositePanel(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,39,649,1,412,1);}
fn AssembleFusionReactor(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,40,650,1,398,1);}
fn AssembleRadiantCollector(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,41,651,1,400,1);}
fn AssemblePlasmaContainmentRing(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
produce_capability_artifact_2_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,evidence_2,42,652,1,396,1,401,1);}
fn InterpretFieldData(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,43,653,1,421,1);}
fn AssembleAutonomousGuidanceCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,44,654,1,422,1);}
fn AssembleFleetCoordinationNode(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,45,655,1,423,1);}
fn FabricateSmartMembrane(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,46,656,1,402,1);}
fn FabricateTunedCrystalLattice(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,47,657,1,406,1);}
fn AssembleMolecularAssembler(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,48,658,1,404,1);}
fn CompileAstrometricAnchorSolution(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,49,659,1,419,1);}
fn CompileGravitationalChartAnalysis(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,50,660,1,411,1);}
fn CompileRelativisticTransitPlan(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,51,661,1,425,1);}
fn AssembleClosedCycleBiome(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,52,662,1,402,1);}
fn CultureManagedMicrobiome(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,53,663,1,405,1);}
fn AssembleAquaticHabitatModule(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
produce_capability_artifact_2_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,evidence_2,54,664,1,393,1,402,1);}
fn AssembleDegenerateContainmentCell(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,55,665,1,409,1);}
fn SynthesizeVacuumStateLattice(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,56,666,1,412,1);}
fn AssembleRelativisticPlasmaBottle(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,57,667,1,410,1);}
fn CompileTemporalTopologyAnalysis(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,58,668,1,428,1);}
fn CompileWormholeGeometryModel(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,59,669,1,432,1);}
fn CompileCausalStabilityModel(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,60,670,1,428,1);}
fn EncodeDeepArchiveVault(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,61,671,1,417,1);}
fn AssembleGalacticSignalRelay(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,62,672,1,423,1);}
fn AssembleGalacticCognitionNode(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,63,673,1,431,1);}
fn AssemblePhotosphericFieldInjector(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,64,674,1,396,1);}
fn AssembleStarLiftingCollector(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,65,675,1,401,1);}
fn AssembleRemnantForgeCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,66,676,1,429,1);}
fn AssembleAtmosphereSeed(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,67,677,1,418,1);}
fn AssembleHydrosphereSeed(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,68,678,1,403,1);}
fn AssembleSoilEcologySeed(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,69,679,1,405,1);}
fn EncodeCulturalContinuityArchive(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,70,680,1,433,1);}
fn CompileCivicProtocolCharter(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
produce_capability_artifact_1_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,71,681,1,420,1);}
fn CompileTradeNetworkCharter(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
produce_capability_artifact_2_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,72,682,1,423,1,419,1);}
fn AssembleOrbitalFoundryCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,73,683,1,629,1,630,1,631,1);}
fn AssembleIntegratedAvionicsCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,74,684,1,632,1,633,1,634,1);}
fn AssembleChemicalPlantCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,75,685,1,635,1,636,1,637,1);}
fn AssembleNuclearPowerNode(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,76,686,1,638,1,639,1,640,1);}
fn AssembleGenomicFoundryCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,77,687,1,641,1,642,1,643,1);}
fn AssemblePlanetaryWorksCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_12_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,78,688,1,644,1,645,1,646,1);}
fn SynthesizeProgrammableMatterMatrix(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,79,689,1,647,1,648,1,649,1);}
fn AssembleStellarPowerNode(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,80,690,1,650,1,651,1,652,1);}
fn AssembleCognitiveInfrastructureCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,81,691,1,653,1,654,1,655,1);}
fn AssembleNanoforgeCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,82,692,1,656,1,657,1,658,1);}
fn CompileGalacticPositionAtlas(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,83,693,1,659,1,660,1,661,1);}
fn AssembleBiosphereCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,84,694,1,662,1,663,1,664,1);}
fn AssembleExoticMatterMatrix(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,85,695,1,665,1,666,1,667,1);}
fn AssembleCausalTransitNode(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,86,696,1,668,1,669,1,670,1);}
fn AssembleGalacticCognitiveMeshSeed(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,87,697,1,671,1,672,1,673,1);}
fn AssembleStellarMegastructureSeed(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,88,698,1,674,1,675,1,676,1);}
fn AssembleWorldSeedPackage(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,89,699,1,677,1,678,1,679,1);}
fn AssembleCivilizationContinuityCore(action){
var next_ship=action.output("microverse__ship");
var artifact=action.output("microverse__resource");
var ship=action.input("microverse__ship");
var evidence_1=action.input("microverse__resource");
var evidence_2=action.input("microverse__resource");
var evidence_3=action.input("microverse__resource");
produce_capability_artifact_3_evidence_vdf_32_core(action,next_ship,artifact,ship,evidence_1,evidence_2,evidence_3,90,700,1,680,1,681,1,682,1);}
fn UseTechnologySkill(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var technology_skill=action.mutate("microverse__technology_skill");
prove_fixed_versions(action,ship);
prove_fixed_versions(action,technology_skill);
action.st_sum(technology_skill.civilization_version,0,2);
var ship_id=bind_ship_id(action,ship);
var extraction_amount=unsafe{ship.extraction_amount-0};
var rare_extraction_amount=unsafe{ship.rare_extraction_amount-0};
action.st_sum(ship.extraction_amount,0,extraction_amount);
action.st_sum(ship.rare_extraction_amount,0,rare_extraction_amount);
var x=unsafe{ship.x-0};
var y=unsafe{ship.y-0};
var z=unsafe{ship.z-0};
var epoch=unsafe{ship.epoch-0};
action.st_sum(ship.x,0,x);
action.st_sum(ship.y,0,y);
action.st_sum(ship.z,0,z);
action.st_sum(ship.epoch,0,epoch);
var active_skill_type=unsafe{technology_skill.skill_type-0};
action.st_sum(technology_skill.skill_type,0,active_skill_type);
var claim_serial=unsafe{ship.claim_serial-0};
action.st_sum(ship.claim_serial,0,claim_serial);
var discovery_serial=unsafe{ship.discovery_serial-0};
action.st_sum(ship.discovery_serial,0,discovery_serial);
var satellite_serial=unsafe{ship.satellite_serial-0};
action.st_sum(ship.satellite_serial,0,satellite_serial);
var civilization_scan_serial=unsafe{ship.civilization_scan_serial-0};
action.st_sum(ship.civilization_scan_serial,0,civilization_scan_serial);
var next_action_serial=unsafe{ship.action_serial-(0-1)};
action.st_sum(ship.action_serial,1,next_action_serial);
next_ship.set([
["schema_version",2],
["mechanics_version",2],
["universe_version",2],
["extraction_amount",extraction_amount],
["rare_extraction_amount",rare_extraction_amount],
["x",x],
["y",y],
["z",z],
["epoch",epoch],
["active_skill_type",active_skill_type],
["action_serial",next_action_serial],
["claim_serial",claim_serial],
["discovery_serial",discovery_serial],
["satellite_serial",satellite_serial],
["civilization_scan_serial",civilization_scan_serial],
["ship_id",ship_id]
]);
action.st_sum(technology_skill.reusable,0,1);
var next_skill_key=action.random();
rotate_key(technology_skill,next_skill_key);
}
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
fn AuthorizeLargeShipIndustrial(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var permit=action.mutate("microverse__shipyard_permit");
authorize_large_ship_permit_core(
action,
next_ship,
ship,
permit,
1,
"industrial_authorized"
);
}
fn AuthorizeLargeShipElectronics(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var permit=action.mutate("microverse__shipyard_permit");
authorize_large_ship_permit_core(
action,
next_ship,
ship,
permit,
2,
"electronics_authorized"
);
}
fn AuthorizeLargeShipMolecular(action){
var next_ship=action.output("microverse__ship");
var ship=action.input("microverse__ship");
var permit=action.mutate("microverse__shipyard_permit");
authorize_large_ship_permit_core(
action,
next_ship,
ship,
permit,
10,
"molecular_authorized"
);
}
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
["claim_serial",0],
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
["claim_serial",0],
["discovery_serial",0],
["satellite_serial",0],
["civilization_scan_serial",0],
["ship_id",ship_id]
]);
var work=action.intro_vdf(102,child_ship);
child_ship.update("work",work);
}
