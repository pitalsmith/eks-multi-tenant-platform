#!/bin/bash

# Exit instantly if any command fails
set -e

echo "🚀 Starting Internal Developer Platform Deployment..."

# Navigate to your dev environment directory
cd terraform/environments/dev

echo "📦 Initializing Terraform modules and providers..."
terraform init

echo "✨ Formatting Terraform code..."
terraform fmt -recursive

echo "🔍 Validating configuration..."
terraform validate

echo "📋 Creating infrastructure execution plan..."
terraform plan

echo "🏗️ Applying infrastructure updates..."
terraform apply -auto-approve

echo "✅ Deployment completed successfully!"