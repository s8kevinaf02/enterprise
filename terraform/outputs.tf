output "cluster_name" {
  value = module.eks.cluster_name
}

output "region" {
  value = var.aws_region
}
