#!/bin/bash

set -e

echo "Initializing Terraform..."

cd terraform/environments/dev

terraform init

echo "Terraform initialized successfully."