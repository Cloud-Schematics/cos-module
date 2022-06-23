##############################################################################
# Account Variables
##############################################################################

variable "region" {
  description = "The region to which to deploy the VPC"
  type        = string
}

variable "prefix" {
  description = "The prefix that you would like to append to your resources"
  type        = string
}

variable "tags" {
  description = "List of Tags for the resource created"
  type        = list(string)
  default     = null
}

variable "use_random_suffix" {
  description = "Add a randomize suffix to the end of each resource created in this module."
  type        = bool
  default     = true
}

variable "key_management_service_guid" {
  description = "OPTIONAL - GUID of the Key Management Service to use for COS bucket encryption."
  type        = string
  default     = null
}

variable "key_management_service_name" {
  description = "OPTIONAL - Type of key management service to use for COS bucket encryption. Service authorizations will be added only if the GUID is not null."
  type        = string
  default     = null

  validation {
    error_message = "Key Management service name can be `kms`, `hs-crypto`, or `null`."
    condition     = var.key_management_service_name == null || var.key_management_service_name == "kms" || var.key_management_service_name == "hs-crypto"
  }
}

variable "service_endpoints" {
  description = "Service endpoints. Can be `public`, `private`, or `public-and-private`"
  type        = string
  default     = "private"

  validation {
    error_message = "Service endpoints can only be `public`, `private`, or `public-and-private`."
    condition     = contains(["public", "private", "public-and-private"], var.service_endpoints)
  }
}

##############################################################################

##############################################################################
# Cloud Object Storage Variables
##############################################################################

variable "cos" {
  description = "Object describing the cloud object storage instance, buckets, and keys. Set `use_data` to false to create instance"
  type = list(
    object({
      name              = string
      use_data          = optional(bool)
      resource_group_id = optional(string)
      plan              = optional(string)
      buckets = list(object({
        name                  = string
        storage_class         = string
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
      keys = optional(
        list(object({
          name        = string
          role        = string
          enable_HMAC = bool
        }))
      )

    })
  )

  default = [
    {
      buckets = [
        {
          endpoint_type = "public"
          force_delete  = true
          kms_key       = "at-test-atracker-key"
          name          = "atracker-bucket"
          storage_class = "standard"
        },
      ]
      keys = [
        {
          enable_HMAC = false
          name        = "cos-bind-key"
          role        = "Writer"
        },
      ]
      name           = "atracker-cos"
      plan           = "standard"
      random_suffix  = true
      resource_group = "at-test-service-rg"
      use_data       = false
    },
    {
      buckets = [
        {
          endpoint_type = "public"
          force_delete  = true
          kms_key       = "at-test-slz-key"
          name          = "management-bucket"
          storage_class = "standard"
        },
        {
          endpoint_type = "public"
          force_delete  = true
          kms_key       = "at-test-slz-key"
          name          = "workload-bucket"
          storage_class = "standard"
        },
        {
          endpoint_type = "public"
          force_delete  = true
          kms_key       = "at-test-slz-key"
          name          = "bastion-bucket"
          storage_class = "standard"
        },
      ]
      keys = [
        {
          enable_HMAC = true
          name        = "bastion-key"
          role        = "Writer"
        },
      ]
      name           = "cos"
      plan           = "standard"
      random_suffix  = true
      resource_group = "at-test-service-rg"
      use_data       = false
    },
  ]

  validation {
    error_message = "Each COS key must have a unique name."
    condition = length(var.cos) == 0 ? true : length(
      flatten(
        [
          for instance in var.cos :
          [
            for keys in instance.keys :
            keys.name
          ] if lookup(instance, "keys", false) != false
        ]
      )
      ) == length(
      distinct(
        flatten(
          [
            for instance in var.cos :
            [
              for keys in instance.keys :
              keys.name
            ] if lookup(instance, "keys", false) != false
          ]
        )
      )
    )
  }

  validation {
    error_message = "Plans for COS instances can only be `lite` or `standard`."
    condition = length(var.cos) == 0 ? true : length([
      for instance in var.cos :
      true if contains(["lite", "standard"], instance.plan)
    ]) == length(var.cos)
  }

  validation {
    error_message = "COS Bucket names must be unique."
    condition = length(var.cos) == 0 ? true : length(
      flatten([
        for instance in var.cos :
        instance.buckets.*.name
      ])
      ) == length(
      distinct(
        flatten([
          for instance in var.cos :
          instance.buckets.*.name
        ])
      )
    )
  }

  # https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-classes 
  validation {
    error_message = "Storage class can only be `standard`, `vault`, `cold`, or `smart`."
    condition = length(var.cos) == 0 ? true : length(
      flatten(
        [
          for instance in var.cos :
          [
            for bucket in instance.buckets :
            true if contains(["standard", "vault", "cold", "smart"], bucket.storage_class)
          ]
        ]
      )
    ) == length(flatten([for instance in var.cos : [for bucket in instance.buckets : true]]))
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#endpoint_type 
  validation {
    error_message = "Endpoint type can only be `public`, `private`, or `direct`."
    condition = length(var.cos) == 0 ? true : length(
      flatten(
        [
          for instance in var.cos :
          [
            for bucket in instance.buckets :
            true if contains(["public", "private", "direct"], bucket.endpoint_type)
          ]
        ]
      )
    ) == length(flatten([for instance in var.cos : [for bucket in instance.buckets : true]]))
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#single_site_location
  validation {
    error_message = "All single site buckets must specify `ams03`, `che01`, `hkg02`, `mel01`, `mex01`, `mil01`, `mon01`, `osl01`, `par01`, `sjc04`, `sao01`, `seo01`, `sng01`, or `tor01`."
    condition = length(var.cos) == 0 ? true : length(
      [
        for site_bucket in flatten(
          [
            for instance in var.cos :
            [
              for bucket in instance.buckets :
              bucket if lookup(bucket, "single_site_location", null) != null
            ]
          ]
        ) : site_bucket if !contains(["ams03", "che01", "hkg02", "mel01", "mex01", "mil01", "mon01", "osl01", "par01", "sjc04", "sao01", "seo01", "sng01", "tor01"], site_bucket.single_site_location)
      ]
    ) == 0
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#region_location
  validation {
    error_message = "All regional buckets must specify `au-syd`, `eu-de`, `eu-gb`, `jp-tok`, `us-east`, `us-south`, `ca-tor`, `jp-osa`, `br-sao`."
    condition = length(var.cos) == 0 ? true : length(
      [
        for site_bucket in flatten(
          [
            for instance in var.cos :
            [
              for bucket in instance.buckets :
              bucket if lookup(bucket, "region_location", null) != null
            ]
          ]
        ) : site_bucket if !contains(["au-syd", "eu-de", "eu-gb", "jp-tok", "us-east", "us-south", "ca-tor", "jp-osa", "br-sao"], site_bucket.region_location)
      ]
    ) == 0
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#cross_region_location
  validation {
    error_message = "All cross-regional buckets must specify `us`, `eu`, `ap`."
    condition = length(var.cos) == 0 ? true : length(
      [
        for site_bucket in flatten(
          [
            for instance in var.cos :
            [
              for bucket in instance.buckets :
              bucket if lookup(bucket, "cross_region_location", null) != null
            ]
          ]
        ) : site_bucket if !contains(["us", "eu", "ap"], site_bucket.cross_region_location)
      ]
    ) == 0
  }

  # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket#archive_rule
  validation {
    error_message = "Each archive rule must specify a type of `Glacier` or `Accelerated`."
    condition = length(var.cos) == 0 ? true : length(
      [
        for site_bucket in flatten(
          [
            for instance in var.cos :
            [
              for bucket in instance.buckets :
              bucket if lookup(bucket, "archive_rule", null) != null
            ]
          ]
        ) : site_bucket if !contains(["Glacier", "Accelerated"], site_bucket.archive_rule.type)
      ]
    ) == 0
  }
}

##############################################################################