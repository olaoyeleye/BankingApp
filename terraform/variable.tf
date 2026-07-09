variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_name" {
  description = "Base name for VPC and EKS resources"
  type        = string
}

variable "frontend_image" {
  description = "Frontend container image"
  type        = string
  default     = "YOUR_ECR_URL/bank-frontend:latest"
}

variable "user_service_image" {
  description = "User service container image"
  type        = string
  default     = "YOUR_ECR_URL/user-service:latest"
}

variable "transaction_service_image" {
  description = "Transaction service container image"
  type        = string
  default     = "YOUR_ECR_URL/transaction-service:latest"
}

variable "activity_service_image" {
  description = "Activity service container image"
  type        = string
  default     = "YOUR_ECR_URL/activity-service:latest"
}

variable "postgres_image" {
  description = "Postgres container image"
  type        = string
  default     = "YOUR_ECR_URL/bank-app-postgres:latest"
}

variable "instance_type" {         
}