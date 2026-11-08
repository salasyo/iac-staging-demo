#!/usr/bin/env bash
set -euo pipefail

ACTION=${1:-"apply"}
VAR_FILE="staging.tfvars"

# Dynamically set ephemeral DB password if not already provided in environment
export TF_VAR_db_password="${TF_VAR_db_password:-$(openssl rand -hex 12)}"

# Auto-detect macOS Docker Desktop or Colima socket if /var/run/docker.sock is missing
if [ ! -S /var/run/docker.sock ]; then
    if [ -S "${HOME}/.docker/run/docker.sock" ]; then
        export DOCKER_HOST="unix://${HOME}/.docker/run/docker.sock"
    elif [ -S "${HOME}/.colima/default/docker.sock" ]; then
        export DOCKER_HOST="unix://${HOME}/.colima/default/docker.sock"
    fi
fi

echo "===================================================="
echo "🚀 Starting Automated IaC Provisioning (${ACTION})"
echo "===================================================="

echo "-> [1/4] Initializing Terraform plugins..."
terraform init -input=false

echo "-> [2/4] Validating Terraform formatting & syntax..."
terraform fmt -check
terraform validate

if [ "$ACTION" == "destroy" ]; then
    echo "-> [3/4] Destroying Staging Environment..."
    terraform destroy -var-file="$VAR_FILE" -auto-approve
    echo "✅ Staging environment completely torn down."
elif [ "$ACTION" == "recreate" ]; then
    echo "-> [3/4] Destroying existing Staging Environment..."
    terraform destroy -var-file="$VAR_FILE" -auto-approve
    echo "-> [4/4] Recreating Staging Environment from scratch..."
    terraform apply -var-file="$VAR_FILE" -auto-approve
    echo "✅ Staging environment successfully recreated!"
else
    echo "-> [3/4] Generating Execution Plan..."
    terraform plan -var-file="$VAR_FILE" -out=tfplan
    echo "-> [4/4] Applying Infrastructure Plan..."
    terraform apply -input=false tfplan
    echo "✅ Staging environment provisioned successfully!"
fi
