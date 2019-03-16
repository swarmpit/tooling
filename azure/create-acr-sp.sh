#!/bin/bash

display_usage() {
  echo "This script creates swarmpit service principal to access azure container registry"
  echo -e "\nUsage:\n create-acr-sp.sh [registry-name]"
  echo -e "\n example: create-acr-sp.sh registry712"
}

if [  $# -le 1 ]
then
  display_usage
  exit 1
fi

# Modify for your environment.
# ACR_NAME: The name of your Azure Container Registry
# SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant, default to swarmpit-acr
ACR_NAME=$1
SERVICE_PRINCIPAL_NAME=swarmpit-acr

# Populate the ACR login server and resource id to obtain full registry ID
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)

# Create a READER role assignment with a scope of the ACR resource.
SP_PASSWD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --role Reader --scopes $ACR_REGISTRY_ID --query password --output tsv)
SP_APP_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)

# Output the service principal's credentials; use these in
# Swarmpit to authenticate to the container registry.
echo "Service principal name: $SERVICE_PRINCIPAL_NAME"
echo "Service principal ID: $SP_APP_ID"
echo "Service principal password: $SP_PASSWD"
