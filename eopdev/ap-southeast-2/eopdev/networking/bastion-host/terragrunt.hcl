include "root" {
  path = find_in_parent_folders()
}

include "envcommon" {
  path   = "${dirname(find_in_parent_folders())}/_envcommon/mgmt/bastion-host.hcl"
  expose = true
}

inputs = {
}