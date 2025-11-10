# Skip remote state for init/bootstrap since it creates the state bucket
# This will use local state for the bootstrap process
# No remote_state block means Terragrunt won't configure remote state

terraform {
    source = "."
}

# Dynamically load all inputs from kuberly.json
inputs = jsondecode(file("${dirname(get_terragrunt_dir())}/kuberly.json"))