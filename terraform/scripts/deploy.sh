#!/bin/bash

set -e

echo "Starting Terraform deployment..."

cd terraform/environments/dev

echo "Formatting code..."
terraform fmt -recursive

echo "Validating configuration..."
terraform validate

echo "Creating execution plan..."
terraform plan

echo "Applying infrastructure..."
terraform apply -auto-approve

echo "Deployment completed successfully."