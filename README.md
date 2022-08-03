# Cloud Object Storage Module

This module is used to create any numer of Cloud Object Storage Instances, Buckets, and Resource Keys. It also allows users to dynamically create service-to-service authorizations to allow the Object Storage instances to be encrypted by IBM Key Protect or Hyper Protect Crypto Services.

---

## Table of Contents

1. [Template Level Variables](#template-level-variables)
2. [COS Variable](#cos-variable)
3. [Module Outputs](#module-outputs)
    - [COS Instances](#cos-instances)
    - [COS Buckets](#cos-buckets)
    - [COS Keys](#cos-keys)

---

## Template Level Variables

Name                        | Type         | Description                                                                                                                                    | Sensitive | Default
--------------------------- | ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- | --------- | -------
region                      | string       | The region to which to deploy the VPC                                                                                                          |           | 
prefix                      | string       | The prefix that you would like to append to your resources                                                                                     |           | 
tags                        | list(string) | List of Tags for the resource created                                                                                                          |           | null
use_random_suffix           | bool         | Add a randomize suffix to the end of each resource created in this module.                                                                     |           | true
service_endpoints           | string       | Service endpoints. Can be `public`, `private`, or `public-and-private`                                                                         |           | private
key_management_service_guid | string       | OPTIONAL - GUID of the Key Management Service to use for COS bucket encryption.                                                                |           | null
key_management_service_name | string       | OPTIONAL - Type of key management service to use for COS bucket encryption. Service authorizations will be added only if the GUID is not null. |           | null

---

## COS Variable

COS instances, buckets, and key deployments are created and managed using the [cos variable](./variables.tf#L67)

```terraform
variable "cos" {
  description = "Object describing the cloud object storage instance, buckets, and keys. Set `use_data` to false to create instance"
  type = list(
    object({
      name              = string           # Name of the COS instance
      use_data          = optional(bool)   # Optional - Get existing COS instance from data
      resource_group_id = optional(string) # ID of resource group where COS should be provisioned
      plan              = optional(string) # Can be `lite` or `standard`
      ##############################################################################
      # For more information on bucket creation, see the Terraform Documentation
      # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket
      ##############################################################################
      buckets = list(object({
        name                  = string           # Name of the bucket
        storage_class         = string           # Storage class for the bucket
        endpoint_type         = string
        force_delete          = bool
        single_site_location  = optional(string)
        region_location       = optional(string)
        cross_region_location = optional(string)
        encryption_key_id     = optional(string)
        allowed_ip            = optional(list(string))
        hard_quota            = optional(number)
        archive_rule = optional(object({
          days    = number
          enable  = bool
          rule_id = optional(string)
          type    = string
        }))
        activity_tracking = optional(object({
          activity_tracker_crn = string
          read_data_events     = bool
          write_data_events    = bool
        }))
        metrics_monitoring = optional(object({
          metrics_monitoring_crn  = string
          request_metrics_enabled = optional(bool)
          usage_metrics_enabled   = optional(bool)
        }))
      }))
      ##############################################################################
      # Create Any number of keys 
      ##############################################################################
      keys = optional(
        list(object({
          name        = string
          role        = string
          enable_HMAC = bool
        }))
      )

    })
  )
```

---

## Module Outputs

This module has three complex variable outputs to simplify the use of these resources as part of a larger architecture. Outputs can be found in [outputs.tf](./outputs.tf). The random suffix used for COS resource is referenced by the output `cos_suffix`.

### COS Instances

```terraform
output "cos_instances" {
  description = "List of COS resource instances with shortname, name, id, and crn."
  value = [
    for instance in var.cos :
    {
      # Name of the instance without the random suffix
      shortname = instance.name
      # Composed name with prefix and suffix
      name      = instance.use_data == true ? data.ibm_resource_instance.cos[instance.name].name : ibm_resource_instance.cos[instance.name].name
      # ID of intantce
      id        = instance.use_data == true ? data.ibm_resource_instance.cos[instance.name].id : ibm_resource_instance.cos[instance.name].id
      # CRN of instance
      crn       = instance.use_data == true ? data.ibm_resource_instance.cos[instance.name].crn : ibm_resource_instance.cos[instance.name].crn
    }
  ]
}
```

### COS Buckets

```terraform
output "cos_buckets" {
  description = "List of COS bucket instances with shortname, instance_shortname, name, id, crn, and instance id."
  value = [
    for bucket in module.cos_bucket_map.value :
    {
      # Name of the instance without the random suffix
      instance_shortname = bucket.instance
      # Bucket Instance ID
      instance_id        = bucket.use_data == true ? data.ibm_resource_instance.cos[bucket.instance].id : ibm_resource_instance.cos[bucket.instance].id
      # Bucket name without random suffix
      shortname          = bucket.name
      # ID of bucket
      id                 = ibm_cos_bucket.bucket[bucket.name].id
      # Composed name with prefix and suffix
      name               = ibm_cos_bucket.bucket[bucket.name].bucket_name
      crn                = ibm_cos_bucket.bucket[bucket.name].crn
    }
  ]
}
```

### COS Keys

```terraform
output "cos_keys" {
  description = "List of COS bucket instances with shortname, instance_shortname, name, id, crn, and instance id."
  value = [
    for resource_key in module.cos_key_map.value :
    {
      # Name of the instance without the random suffix
      instance_shortname = resource_key.instance
      # Instance IDs
      instance_id        = resource_key.use_data == true ? data.ibm_resource_instance.cos[resource_key.instance].id : ibm_resource_instance.cos[resource_key.instance].id
      # Key name without prefix and suffix
      shortname          = resource_key.name
      # Resource Key ID
      id                 = ibm_resource_key.key[resource_key.name].id
      # Composed name with prefix and suffix
      name               = ibm_resource_key.key[resource_key.name].name
      # Resource Key CRN
      crn                = ibm_resource_key.key[resource_key.name].crn
    }
  ]
}

```