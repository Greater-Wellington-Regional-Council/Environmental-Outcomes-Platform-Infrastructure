include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/networking/alb-eop-manager.hcl"
  expose = true
}

inputs = {
  alb_name = "eop-manager-prod"
}
