#!/bin/bash

# Exit instantly if any command fails
set -e

echo "⚠️  WARNING: Starting full infrastructure destruction..."
echo "This will permanently terminate your EKS cluster, worker nodes, and VPC network."

# Navigate to your dev environment directory
cd terraform/environments/dev

echo "📋 Generating destruction plan for review..."
terraform plan -destroy

# Optional safety check: If you want an interactive prompt before it nukes everything,
# remove the "-auto-approve" flag from the line below.
echo "💥 Nuking all deployed infrastructure..."
terraform destroy -auto-approve

echo "✅ All platform infrastructure has been cleanly destroyed. Costs successfully mitigated!"