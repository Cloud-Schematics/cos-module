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
# Get COS instance from data
##############################################################################

data "ibm_resource_instance" "cos" {
  for_each          = {
    for instance in var.cos:
    (instance.name) => instance if instance.use_data == true
  }
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
  for_each          = {
    for instance in var.cos:
    (instance.name) => instance if instance.use_data != true
  }
  location          = local.cos_location
  name              = "${var.prefix}-${each.value.name}${local.suffix}"
  service           = "cloud-object-storage"
  plan              = each.value.plan
  resource_group_id = each.value.resource_group_id
  tags              = var.tags
}

##############################################################################