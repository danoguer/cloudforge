#!/bin/bash

set -e

echo "🚀 Starting Cloud-1 Automation Pipeline..."

mkdir -p ./bin
export PATH="$PWD/bin:$PATH"


if ! command -v terraform &> /dev/null; then
    echo "⚠️ Terraform not found globally. Downloading portable binary into ./bin..."

    OS_TYPE=$(uname | tr '[:upper:]' '[:lower:]')

    curl -sSL "https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_${OS_TYPE}_amd64.zip" -o terraform.zip

    unzip -q terraform.zip -d ./bin
    rm terraform.zip
    chmod +x ./bin/terraform
    echo "✅ Portable Terraform ready!"
fi


echo "🏗️ Step 1: Provisioning AWS Infrastructure..."
cd terraform

terraform init
terraform apply -auto-approve

SERVER_IP=$(terraform output -raw instance_public_ip)
echo "🎯 Server successfully created! Public IP: $SERVER_IP"


echo "📝 Step 2: Dynamically generating Ansible inventory..."
cd ../ansible


cat << EOF > inventory.ini
[webservers]
cloud_instance ansible_host=$SERVER_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/cloud1-key.pem
EOF


echo "🐳 Step 3: Launching Ansible deployment playbook..."


ANSIBLE_CMD="ansible-playbook"
if ! command -v ansible-playbook &> /dev/null; then
    ANSIBLE_CMD="$HOME/.local/bin/ansible-playbook"
fi

$ANSIBLE_CMD -i inventory.ini site.yml --ask-vault-pass

echo "✨ Cloud-1 Stack is fully deployed and operational!"
