# Nginx Load Balancer with Ansible and Terraform

This repository contains Ansible and Terraform scripts to deploy a production environment with an Nginx load balancer and multiple web servers on Azure.

## Prerequisites

1. **Azure Account**: You need an Azure account with appropriate credentials and an active subscription.
2. **Azure CLI**: Install and configure Azure CLI (`az login` to authenticate).
3. **Terraform**: Ensure Terraform is installed on your local machine.
4. **Ansible**: Ensure Ansible is installed on your local machine.

## Directory Structure

```bash
Nginx-LB-w-Ansible
├── ansible
│   ├── ansible.cfg
│   ├── files
│   │   ├── nginx.conf
│   │   └── nginx_proxy.conf
│   ├── inventory
│   │   └── csc.ini
│   ├── pb.yml
│   └── templates
│       └── index.html.j2
├── README.md
├── ssh
│   └── config
└── Terraform
    ├── main.tf
    └── providers.tf
```

## File Details

### Terraform Configuration

#### `providers.tf`

This file configures the Azure provider for Terraform. Ensure you're authenticated via Azure CLI (`az login`) before running Terraform.

#### `main.tf`

This file defines the infrastructure components such as resource group, virtual network, subnets, network security groups, load balancer, and virtual machines.

### Ansible Configuration

#### `ansible.cfg`

Ansible configuration file.

#### `pb.yml`

The Ansible playbook to configure the Nginx load balancer and web servers.

#### `files/nginx.conf`

Nginx configuration file for individual web servers.

#### `files/nginx_proxy.conf`

Nginx configuration file for the load balancer.

#### `inventory/csc.ini`

Ansible inventory file specifying the groups and hosts.

#### `templates/index.html.j2`

Jinja2 template for the default web page served by Nginx.

#### `ssh/config`

SSH configuration file specifying connection details for JumpHost and web servers.

## Setup Instructions

1. **Azure Authentication:**

   - Run `az login` to authenticate with your Azure account.
   - Set your subscription: `az account set --subscription "<SUBSCRIPTION_ID>"`.

2. **Terraform Configuration:**

   - Update the `main.tf` file with your specific Azure region and resource naming preferences.
   - Run `terraform init` to initialize the Terraform working directory.
   - Run `terraform plan` to preview the infrastructure changes.
   - Run `terraform apply` to deploy the infrastructure.

3. **Ansible Configuration:**

   - Update the `csc.ini` file in the `ansible/inventory` directory with the VM IPs from Terraform output.
   - Update the SSH configuration in the `ssh/config` file with your SSH key details.
   - Run Ansible playbook: `cd ansible && ansible-playbook pb.yml`.

4. **Accessing the Environment:**

   - The load balancer is accessible at the public IP shown in Terraform output.
   - A public domain name (FQDN) is automatically allocated and shown in the `lb_fqdn` output.
   - The load balancer accepts HTTP (port 80), HTTPS (port 443), and SSH (port 22) traffic.
   - Web servers can be accessed using SSH through the load balancer VM with the configured SSH key.
   - To get the SSH private key: `terraform output -raw ssh_private_key > ~/.ssh/azure_lb_key && chmod 600 ~/.ssh/azure_lb_key`