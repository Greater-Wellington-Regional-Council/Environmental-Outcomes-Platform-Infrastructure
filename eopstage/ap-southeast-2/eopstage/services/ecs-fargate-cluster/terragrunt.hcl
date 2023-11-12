include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/services/ecs-fargate-cluster.hcl"
  expose = true
}

locals {
}

inputs = {

}
