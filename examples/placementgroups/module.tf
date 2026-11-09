
module "placement_group_1" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/PlacementGroup?ref=main"

  name     = "${var.prefixo_projeto}-highperformance-pg"
  strategy = "cluster"

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }

}

module "placement_group_2" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/PlacementGroup?ref=main"

  name     = "${var.prefixo_projeto}-critical-pg"
  strategy = "spread"

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }

}

module "placement_group_3" {
  source = "git::https://github.com/mgsantos89/Terraform-Modules.git//modules/PlacementGroup?ref=main"

  name     = "${var.prefixo_projeto}-distributed-pg"
  strategy = "partition"

  tags = {
    Environment = var.environment
    Project     = var.prefixo_projeto
    ManagedBy   = "Terraform"
  }

}

