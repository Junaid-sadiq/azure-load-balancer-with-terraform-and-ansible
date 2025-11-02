# Quick Start Guide

## 🚀 Deploy Infrastructure and Configure Load Balancer

### Step 1: Deploy with Terraform

```bash
cd terraform
terraform init
terraform apply
```

### Step 2: Save SSH Key

```bash
terraform output -raw ssh_private_key > ~/.ssh/azure_lb_key
chmod 600 ~/.ssh/azure_lb_key
```

### Step 3: Update Ansible Configuration

```bash
cd ../ansible
./update_inventory.sh
```

### Step 4: Run Ansible Playbook

```bash
ansible-playbook pb.yml
```

### Step 5: Test Your Load Balancer

```bash
# Get the load balancer URL
cd ../terraform
terraform output lb_fqdn

# Test it
curl http://$(terraform output -raw lb_public_ip_address)

# Test multiple times to see load balancing in action
for i in {1..10}; do 
  curl http://$(terraform output -raw lb_public_ip_address)
  echo ""
done
```

## 🎯 What You'll See

Each request will be distributed across VM-2, VM-3, and VM-4, showing:
```html
<h1>Nginx, configured by Ansible</h1>
<p>If you can see this, Ansible successfully installed nginx.</p>
<p>Running on 10.0.1.X</p>
```

The IP will change with each request, proving load balancing is working!

## 🧹 Cleanup

```bash
cd terraform
terraform destroy
```

## 📊 View Deployment Summary

```bash
cd terraform
terraform output deployment_summary
```
