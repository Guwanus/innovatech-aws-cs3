output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public_a.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private_a.id
}

output "rds_endpoint" {
  description = "RDS endpoint for the employee DB"
  value       = aws_db_instance.employee_db.address
}

output "portal_alb_dns_name" {
  description = "DNS name of the portal ALB"
  value       = aws_lb.portal_alb.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.portal.name
}

output "onboarding_lambda_arn" {
  description = "ARN of the onboarding Lambda"
  value       = aws_lambda_function.onboarding.arn
}

output "offboarding_lambda_arn" {
  description = "ARN of the offboarding Lambda"
  value       = aws_lambda_function.offboarding.arn
}
