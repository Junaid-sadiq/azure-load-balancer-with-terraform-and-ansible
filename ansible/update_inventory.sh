#!/bin/bash
# Script to automatically update Ansible inventory from Terraform outputs

cd ../terraform

echo "Fetching Terraform outputs..."

LB_IP=$(terraform output -raw lb_public_ip_address)
LB_FQDN=$(terraform output -raw lb_fqdn)
BACKEND_IPS=$(terraform output -json backend_vm_private_ips | jq -r '.[]')
USERNAME=$(terraform output -raw admin_username)

# Convert backend IPs to array
IPS_ARRAY=($BACKEND_IPS)

echo "Creating Ansible inventory..."

cat > ../ansible/inventory/azure.ini <<EOF
# Auto-generated from Terraform outputs
# Generated on: $(date)

[azure_proxy]
${LB_IP} ansible_user=${USERNAME}

[azure_vms]
${IPS_ARRAY[0]} ansible_user=${USERNAME}
${IPS_ARRAY[1]} ansible_user=${USERNAME}
${IPS_ARRAY[2]} ansible_user=${USERNAME}

[azure_vms:vars]
ansible_ssh_common_args='-o ProxyJump=${USERNAME}@${LB_IP} -o StrictHostKeyChecking=no'

[all:vars]
ansible_ssh_private_key_file=~/.ssh/azure_lb_key
EOF

echo "✅ Inventory updated!"
echo ""
echo "Load Balancer: ${LB_IP} (${LB_FQDN})"
echo "Backend VMs:"
echo "  - ${IPS_ARRAY[0]}"
echo "  - ${IPS_ARRAY[1]}"
echo "  - ${IPS_ARRAY[2]}"
echo ""
echo "Now updating nginx_proxy.conf with backend IPs..."

cat > ../ansible/files/nginx_proxy.conf <<EOF
# Auto-generated from Terraform outputs
# Load ngx_stream_module
load_module /usr/lib/nginx/modules/ngx_stream_module.so;

events {
    worker_connections 8192;
}

stream {
    # Log file settings
    log_format dns '\$remote_addr - - [\$time_local] \$protocol \$status \$bytes_sent \$bytes_received \$session_time "\$upstream_addr"';
    access_log /var/log/nginx/access.log dns;
    error_log /var/log/nginx/error.log;

    upstream backend_servers {
        server ${IPS_ARRAY[0]}:80;  # VM-2
        server ${IPS_ARRAY[1]}:80;  # VM-3
        server ${IPS_ARRAY[2]}:80;  # VM-4
    }

    server {
        listen 80;                    # Nginx load balancer listen port 80
        proxy_pass backend_servers;   # The server group backend_servers
    }
}
EOF

echo "✅ nginx_proxy.conf updated!"
echo ""
echo "Next steps:"
echo "1. Save SSH private key: terraform output -raw ssh_private_key > ~/.ssh/azure_lb_key && chmod 600 ~/.ssh/azure_lb_key"
echo "2. Test connection: ssh ${USERNAME}@${LB_IP}"
echo "3. Run Ansible: cd ../ansible && ansible-playbook pb.yml"
