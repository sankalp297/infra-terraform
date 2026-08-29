output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint URL"
  value       = module.eks.cluster_endpoint
}

output "ecr_order_service" {
  description = "ECR repo URL for order-service"
  value       = aws_ecr_repository.order_service.repository_url
}

output "ecr_inventory_service" {
  description = "ECR repo URL for inventory-service"
  value       = aws_ecr_repository.inventory_service.repository_url
}