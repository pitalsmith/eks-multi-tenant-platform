#!/bin/bash

set -e

echo "WARNING: Destroying all infrastructure in dev environment..."

cd terraform/environments/dev

terraform destroy -auto-approve

echo "Infrastructure destroyed successfully."