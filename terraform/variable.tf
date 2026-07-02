variable "region" {}
variable "ami" {}
variable "instance_type" {}
variable "key_name" {
    default = "tai-key-2"
}
variable "instance-name-nginx" {} 
variable "vpc_name" {}

variable "eks_admin_principal_arn" {
  description = "IAM principal ARN that should have EKS cluster admin access"
  type        = string
}