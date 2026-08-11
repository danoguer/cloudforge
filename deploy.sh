#!/bin/bash

set -e

echo "🚀 Starting Cloud-1 Automation Pipeline..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

mkdir -p ./bin
export PATH="$ROOT_DIR/bin:$PATH"

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
cd "$ROOT_DIR/terraform"

terraform init
terraform apply -auto-approve

SERVER_IP=$(terraform output -raw instance_public_ip)
echo "🎯 Server successfully created! Public IP: $SERVER_IP"

echo "⏳ Step 2: Waiting for SSH on $SERVER_IP to become ready..."
until nc -z -v -w5 "$SERVER_IP" 22 2>/dev/null; do
  echo "Waiting for instance SSH daemon..."
  sleep 5
done
echo "✅ SSH connection available!"

echo "📝 Step 3: Dynamically generating Ansible inventory..."
cd "$ROOT_DIR/ansible"

cat << EOF > inventory.ini
[webservers]
cloud_instance ansible_host=$SERVER_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/cloud1-key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "🐳 Step 4: Launching Ansible deployment playbook..."

ANSIBLE_CMD="ansible-playbook"
if ! command -v ansible-playbook &> /dev/null; then
    ANSIBLE_CMD="$HOME/.local/bin/ansible-playbook"
fi

VAULT_FLAG="--ask-vault-pass"
if [ -f "$HOME/.vault_pass" ]; then
    VAULT_FLAG="--vault-password-file $HOME/.vault_pass"
elif [ -f "./.vault_pass" ]; then
    VAULT_FLAG="--vault-password-file ./.vault_pass"
fi

export ANSIBLE_HOST_KEY_CHECKING=False
$ANSIBLE_CMD -i inventory.ini site.yml $VAULT_FLAG

echo "✨ Cloud-1 Stack is fully deployed and operational!"
