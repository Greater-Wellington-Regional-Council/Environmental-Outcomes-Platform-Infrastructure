include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/services/ecs-eop-pg-tileserve.hcl"
  expose = true
}

inputs = {
}
