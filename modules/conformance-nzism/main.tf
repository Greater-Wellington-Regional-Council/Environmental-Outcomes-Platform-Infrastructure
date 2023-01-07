resource "aws_config_conformance_pack" "nzism" {
  name = "NZISM"

  input_parameter {
    parameter_name  = "DeployEdgeRules"
    parameter_value = "false"
  }

  template_body = file("./Operational-Best-Practices-for-NZISM.yaml")

}