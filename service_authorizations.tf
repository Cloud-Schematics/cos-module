##############################################################################
# Create Authorizations to Allow COS to read from Key Management
##############################################################################

module "cos_to_key_management" {
  source = "./config_modules/list_to_map"
  list = [
    for instance in(var.key_management_service_guid == null ? [] : var.cos) :
    {
      name                        = "cos-${instance.name}-to-key-management"
      source_service_name         = "cloud-object-storage"
      description                 = "Allow COS instance to read from KMS instance"
      roles                       = ["Reader"]
      target_service_name         = var.key_management_service_name
      target_resource_instance_id = var.key_management_service_guid
      source_resource_instance_id = split(":",
        instance.use_data == true                          # if use data
        ? data.ibm_resource_instance.cos[instance.name].id # get from data
        : ibm_resource_instance.cos[instance.name].id      # otherwise get from resource
      )[7]
    }
  ]
}

##############################################################################

##############################################################################
# Authorization Policies
##############################################################################

resource "ibm_iam_authorization_policy" "policy" {
  for_each                    = module.cos_to_key_management.value
  source_service_name         = each.value.source_service_name
  source_resource_type        = lookup(each.value, "source_resource_type", null)
  source_resource_instance_id = lookup(each.value, "source_resource_instance_id", null)
  source_resource_group_id    = lookup(each.value, "source_resource_group_id", null)
  target_service_name         = each.value.target_service_name
  target_resource_instance_id = lookup(each.value, "target_resource_instance_id", null)
  target_resource_group_id    = lookup(each.value, "target_resource_group", null)
  roles                       = each.value.roles
  description                 = each.value.description
}

##############################################################################