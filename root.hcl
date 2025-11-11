locals {
  root_dir = get_parent_terragrunt_dir()
  
  json_files = sort(tolist(fileset(local.root_dir, "*.json")))
  
  merged_inputs = {
    for file in local.json_files : 
      replace(basename(file), ".json", "") => jsondecode(file("${local.root_dir}/${file}"))
  }
}

inputs = local.merged_inputs