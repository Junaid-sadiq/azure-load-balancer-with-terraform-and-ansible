# Ansible Configuration for Nginx Load Balancer

## Overview

This Ansible playbook configures:
- **VM-1**: Nginx as a load balancer with SSL/HTTPS support (reverse proxy)
- **VM-2, VM-3, VM-4**: Nginx web servers serving custom HTML pages

## 🔒 SSL/HTTPS Support

The playbook automatically installs free SSL certificates from Let's Encrypt!

**Quick SSL Setup:** See [QUICK_SSL_SETUP.md](QUICK_SSL_SETUP.md)  
**Detailed Guide:** See [SSL_SETUP.md](SSL_SETUP.md)

## Prerequisites

1. Terraform infrastructure must be deployed
2. SSH private key must be saved locally
3. Ansible must be installed

## Setup Steps

### 1. Deploy Terraform Infrastructure

```bash
cd ../terraform
terraform init
terraform apply
```

### 2. Save SSH Private Key

```bash
terraform output -raw ssh_private_key > ~/.ssh/azure_lb_key
chmod 600 ~/.ssh/azure_lb_key
```

### 3. Update Ansible Inventory (Automatic)

Run the update script to automatically populate inventory and nginx config:

```bash
cd ../ansible
chmod +x update_inventory.sh
./update_inventory.sh
```

This script will:
- Fetch IPs from Terraform outputs
- Update `inventory/azure.ini` with actual IPs
- Update `files/nginx_proxy.conf` with backend server IPs

### 4. Test SSH Connection

```bash
# Get the load balancer IP
LB_IP=$(cd ../terraform && terraform output -raw lb_public_ip_address)
USERNAME=$(cd ../terraform && terraform output -raw admin_username)

# Test connection to load balancer
ssh -i ~/.ssh/azure_lb_key ${USERNAME}@${LB_IP}

# Test connection to backend VM through jump host
BACKEND_IP=$(cd ../terraform && terraform output -json backend_vm_private_ips | jq -r '.[0]')
ssh -i ~/.ssh/azure_lb_key -J ${USERNAME}@${LB_IP} ${USERNAME}@${BACKEND_IP}
```

### 5. Run Ansible Playbook

```bash
ansible-playbook pb.yml
```

## Manual Setup (Alternative)

If you prefer to update manually:

### Update `inventory/azure.ini`:

```ini
[azure_proxy]
<LOAD_BALANCER_PUBLIC_IP> ansible_user=azureadmin

[azure_vms]
<BACKEND_VM_2_IP> ansible_user=azureadmin
<BACKEND_VM_3_IP> ansible_user=azureadmin
<BACKEND_VM_4_IP> ansible_user=azureadmin

[azure_vms:vars]
ansible_ssh_common_args='-o ProxyJump=azureadmin@<LOAD_BALANCER_PUBLIC_IP> -o StrictHostKeyChecking=no'

[all:vars]
ansible_ssh_private_key_file=~/.ssh/azure_lb_key
```

### Update `files/nginx_proxy.conf`:

Replace the upstream server IPs with your actual backend VM private IPs.

## Verification

After running the playbook:

1. **Check load balancer status:**
   ```bash
   curl http://<LOAD_BALANCER_PUBLIC_IP>
   ```

2. **Verify load balancing:**
   Run multiple times to see different backend servers responding:
   ```bash
   for i in {1..10}; do curl http://<LOAD_BALANCER_PUBLIC_IP>; done
   ```

3. **Check Nginx logs on load balancer:**
   ```bash
   ssh -i ~/.ssh/azure_lb_key azureadmin@<LOAD_BALANCER_PUBLIC_IP>
   sudo tail -f /var/log/nginx/access.log
   ```

## Troubleshooting

### Connection Issues

```bash
# Test Ansible connectivity
ansible all -m ping

# Verbose Ansible run
ansible-playbook pb.yml -vvv
```

### SSH Issues

```bash
# Check SSH key permissions
ls -la ~/.ssh/azure_lb_key  # Should be -rw-------

# Test SSH with verbose output
ssh -vvv -i ~/.ssh/azure_lb_key azureadmin@<LOAD_BALANCER_IP>
```

## File Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── pb.yml                   # Main playbook
├── inventory/
│   └── azure.ini           # Inventory file (update after terraform apply)
├── files/
│   ├── nginx.conf          # Backend web server nginx config
│   └── nginx_proxy.conf    # Load balancer nginx config (update IPs)
├── templates/
│   └── index.html.j2       # HTML template for backend servers
└── update_inventory.sh     # Script to auto-update from Terraform
```
