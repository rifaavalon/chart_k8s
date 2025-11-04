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
