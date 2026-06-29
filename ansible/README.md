# Ansible deployment for Nginx and Kubernetes

This folder contains an Ansible playbook and roles to configure the Nginx EC2 instance and deploy Kubernetes resources to EKS.

## Structure

- `ansible.cfg` - local Ansible configuration
- `hosts.ini` - inventory file for the Nginx instance
- `playbook.yml` - playbook that applies `nginx` and `k8s` roles
- `roles/nginx` - installs and starts Nginx
- `roles/k8s` - installs AWS CLI and kubectl, configures EKS access, and deploys `k8s/deploy.yml` and `k8s/service.yml`

## Usage

1. Update `ansible/hosts.ini`:
   - set `ansible_host` to the `nginx_public_ip` output from Terraform
   - set `ansible_ssh_private_key_file` to your private key path
   - set `aws_region`
   - set `eks_cluster_name`

2. Run the playbook from the repository root:

```bash
cd fast-app-repo
ansible-playbook ansible/playbook.yml
```

## Notes

- The target host must allow SSH from the control machine.
- The instance IAM role must allow `eks:UpdateKubeconfig` / EKS access so `aws eks update-kubeconfig` succeeds.
- Kubernetes manifest copies use the local `k8s/deploy.yml` and `k8s/service.yml` files.
