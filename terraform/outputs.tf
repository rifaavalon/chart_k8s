output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = module.compute.instance_ids
}

output "instance_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = module.compute.instance_private_ips
}

output "instance_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = module.compute.instance_public_ips
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.alb.alb_zone_id
}

output "ansible_inventory" {
  description = "Ansible inventory for deployed instances"
  value = {
    hosts = {
      for idx, ip in module.compute.instance_public_ips : "host-${idx + 1}" => {
        ansible_host = ip
        environment  = var.environment
      }
    }
  }
}

output "datadog_dashboard_url" {
  description = "URL of the Datadog infrastructure dashboard"
  value       = module.datadog.dashboard_url
}

output "datadog_monitor_ids" {
  description = "IDs of created Datadog monitors"
  value       = module.datadog.monitor_ids
}

output "datadog_slo_id" {
  description = "ID of the availability SLO"
  value       = module.datadog.slo_id
}

## UNCOMMENT FOR DEMO: ECS + RDS Outputs
# # ECS Outputs
# output "ecs_cluster_name" {
#   description = "Name of the ECS cluster"
#   value       = module.ecs.cluster_name
# }
#
# output "ecs_service_name" {
#   description = "Name of the ECS service"
#   value       = module.ecs.service_name
# }
#
# # RDS Outputs
# output "rds_endpoint" {
#   description = "RDS instance endpoint"
#   value       = module.rds.db_endpoint
# }
#
# output "rds_database_name" {
#   description = "RDS database name"
#   value       = module.rds.db_name
# }
