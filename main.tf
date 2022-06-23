##############################################################################
# Random Suffix
##############################################################################

resource "random_string" "random_cos_suffix" {
  length  = 8
  special = false
  upper   = false
}

locals {
  suffix       = var.use_random_suffix == true ? "-${random_string.random_cos_suffix.result}" : ""
  cos_location = "global" # Currently the only supported locatation for COS
}

##############################################################################

##############################################################################
# Create map of COS instance to be retrieved from data
##############################################################################

module "cos_data_map" {
  source             = "../config_modules/list_to_map"
  list               = var.cos
  lookup_field       = "use_data"
  lookup_value_regex = "^true$"
}

##############################################################################

##############################################################################
# Create map of COS instance to create
##############################################################################

module "cos_map" {
  source             = "../config_modules/list_to_map"
  list               = var.cos
  lookup_field       = "use_data"
  lookup_value_regex = "false|null"
}

##############################################################################

##############################################################################
# Get COS instance from data
##############################################################################

data "ibm_resource_instance" "cos" {
  for_each          = module.cos_data_map.value
  location          = local.cos_location
  name              = each.value.name
  resource_group_id = each.value.resource_group_id
  service           = "cloud-object-storage"
}

##############################################################################

##############################################################################
# Create new COS instances
##############################################################################

resource "ibm_resource_instance" "cos" {
  for_each          = module.cos_map.value
  location          = local.cos_location
  name              = "${var.prefix}-${each.value.name}${local.suffix}"
  service           = "cloud-object-storage"
  plan              = each.value.plan
  resource_group_id = each.value.resource_group_id
  tags              = var.tags
}

##############################################################################