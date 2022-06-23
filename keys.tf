##############################################################################
# Convert COS Resource Key List to Map
##############################################################################

module "cos_key_map" {
  source        = "../config_modules/nested_list_to_map_and_merge"
  list          = var.cos
  sub_list_name = "keys"
  add_parent_fields_to_child = [
    {
      parent_field = "name"
      child_key    = "instance"
    },
    {
      parent_field = "use_data"
      child_key    = "use_data"
    }
  ]
  add_lookup_child_values = [
    {
      lookup_field_key_name = "parameters"
      lookup_field          = "enable_HMAC"
      parse_json_if_true    = "{\"HMAC\" : true}"
    }
  ]
}

##############################################################################

##############################################################################
# COS Instance Keys
##############################################################################

resource "ibm_resource_key" "key" {
  for_each             = module.cos_key_map.value
  name                 = "${var.prefix}-${each.value.name}${local.suffix}"
  role                 = each.value.role
  resource_instance_id = each.value.use_data == true ? data.ibm_resource_instance.cos[each.value.instance].id : ibm_resource_instance.cos[each.value.instance].id
  parameters           = each.value.parameters
  tags                 = var.tags
}

##############################################################################