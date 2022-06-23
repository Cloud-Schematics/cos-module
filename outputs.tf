##############################################################################
# Outputs
##############################################################################

output "cos_instances" {
  description = "List of COS resource instances with shortname, name, id, and crn."
  value = [
    for instance in var.cos :
    {
      shortname = instance.name
      name      = instance.use_data == true ? data.ibm_resource_instance.cos[instance.name].name : ibm_resource_instance.cos[instance.name].name
      id        = instance.use_data == true ? data.ibm_resource_instance.cos[instance.name].id : ibm_resource_instance.cos[instance.name].id
      crn       = instance.use_data == true ? data.ibm_resource_instance.cos[instance.name].crn : ibm_resource_instance.cos[instance.name].crn
    }
  ]
}

output "cos_buckets" {
  description = "List of COS bucket instances with shortname, instance_shortname, name, id, crn, and instance id."
  value = [
    for bucket in module.cos_bucket_map.value :
    {
      instance_shortname = bucket.instance
      instance_id        = bucket.use_data == true ? data.ibm_resource_instance.cos[bucket.instance].id : ibm_resource_instance.cos[bucket.instance].id
      shortname          = bucket.name
      id                 = ibm_cos_bucket.bucket[bucket.name].id
      name               = ibm_cos_bucket.bucket[bucket.name].bucket_name
      crn                = ibm_cos_bucket.bucket[bucket.name].crn
    }
  ]
}

output "cos_keys" {
  description = "List of COS bucket instances with shortname, instance_shortname, name, id, crn, and instance id."
  value = [
    for resource_key in module.cos_key_map.value :
    {
      instance_shortname = resource_key.instance
      instance_id        = resource_key.use_data == true ? data.ibm_resource_instance.cos[resource_key.instance].id : ibm_resource_instance.cos[resource_key.instance].id
      shortname          = resource_key.name
      id                 = ibm_resource_key.key[resource_key.name].id
      name               = ibm_resource_key.key[resource_key.name].name
      crn                = ibm_resource_key.key[resource_key.name].crn
    }
  ]
}

##############################################################################