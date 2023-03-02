terraform {
  source = "${include.envcommon.locals.source_base_url}?ref=v0.96.9"
}

include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/services/static-site-eop-plan-limits.hcl"
  expose = true
}

inputs = {
}