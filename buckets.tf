##############################################################################
# COS Bucket Map
##############################################################################

module "cos_bucket_map" {
  source        = "../config_modules/nested_list_to_map_and_merge"
  list          = var.cos
  sub_list_name = "buckets"
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
}

##############################################################################

##############################################################################
# Map Keys
##############################################################################

module "encryption_key_map" {
  source         = "../config_modules/list_to_map"
  list           = var.key_management_keys
  key_name_field = "shortname"
}

##############################################################################

##############################################################################
# COS Buckets
##############################################################################

resource "ibm_cos_bucket" "bucket" {
  for_each              = module.cos_bucket_map.value
  bucket_name           = "${var.prefix}-${each.value.name}${local.suffix}"
  resource_instance_id  = each.value.use_data == true ? data.ibm_resource_instance.cos[each.value.instance].id : ibm_resource_instance.cos[each.value.instance].id
  storage_class         = each.value.storage_class
  endpoint_type         = each.value.endpoint_type
  force_delete          = each.value.force_delete
  single_site_location  = each.value.single_site_location
  region_location       = (each.value.region_location == null && each.value.single_site_location == null && each.value.cross_region_location == null) ? var.region : each.value.region_location
  cross_region_location = each.value.cross_region_location
  allowed_ip            = each.value.allowed_ip
  hard_quota            = each.value.hard_quota
  key_protect           = lookup(module.encryption_key_map.value, each.value.kms_key, null)

  dynamic "archive_rule" {
    for_each = (
      each.value.archive_rule == null
      ? []
      : [each.value.archive_rule]
    )

    content {
      days    = archive_rule.value.days
      enable  = archive_rule.value.enable
      rule_id = archive_rule.value.rule_id
      type    = archive_rule.value.type
    }
  }

  dynamic "activity_tracking" {
    for_each = (
      each.value.activity_tracking == null
      ? []
      : [each.value.activity_tracking]
    )

    content {
      activity_tracker_crn = activity_tracking.value.activity_tracker_crn
      read_data_events     = activity_tracking.value.read_data_events
      write_data_events    = activity_tracking.value.write_data_events
    }
  }

  dynamic "metrics_monitoring" {
    for_each = (
      each.value.metrics_monitoring == null
      ? []
      : [each.value.metrics_monitoring]
    )

    content {
      metrics_monitoring_crn  = metrics_monitoring.value.metrics_monitoring_crn
      request_metrics_enabled = metrics_monitoring.value.request_metrics_enabled
      usage_metrics_enabled   = metrics_monitoring.value.usage_metrics_enabled
    }
  }

  depends_on = [ibm_iam_authorization_policy.policy]
}

##############################################################################