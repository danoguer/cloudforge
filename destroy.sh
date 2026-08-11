#!/bin/bash

set -e

echo "⚠️  Starting Cloud-1 Infrastructure Teardown..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$ROOT_DIR/bin:$PATH"

if [ -d "$ROOT_DIR/terraform" ]; then
    cd "$ROOT_DIR/terraform"

    echo "🗑️  Destroying AWS resources with Terraform..."
    terraform destroy -auto-approve

    echo "🧹 Cleaning local temporary inventory and state files..."
    rm -f "$ROOT_DIR/ansible/inventory.ini"
    rm -f "$ROOT_DIR/ansible/.vault_pass" 2>/dev/null || true

    echo "✅ Infrastructure completely removed!"
else
    echo "❌ Error: terraform directory not found."
    exit 1
fi
