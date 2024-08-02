#!/bin/bash

CURRENT_DATE=$(date +"%Y-%m-%d")
REPORT_DIR="./reports/azr"
JSON_FILE="$REPORT_DIR/azure_vm_info_$CURRENT_DATE.json"

# Authenticate Azure CLI
az login

# Fetch all subscription IDs
SUBSCRIPTIONS=$(az account list --query "[].id" -o tsv)

# Initialize an empty array to hold VM info
ALL_VMS=()

# Loop through each subscription
for SUBSCRIPTION in $SUBSCRIPTIONS; do
    az account set --subscription "$SUBSCRIPTION"

    # Fetch all resource groups
    RESOURCE_GROUPS=$(az group list --query "[].name" -o tsv)

    # Loop through each resource group
    for RESOURCE_GROUP in $RESOURCE_GROUPS; do
        # Fetch VMs in the current resource group
        VM_NAMES=$(az vm list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv)

        for VM_NAME in $VM_NAMES; do
            # Fetch detailed VM information
            VM_DATA=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --query '{
                name: name,
                location: location,
                vmSize: hardwareProfile.vmSize,
                resourceGroup: resourceGroup,
                provisioningState: provisioningState,
                priority: priority,
                networkInterfaces: networkProfile.networkInterfaces[*].id,
                osDiskSizeGb: storageProfile.osDisk.diskSizeGb,
                tags: tags
            }' --output json)

            # Append the VM data to the array
            ALL_VMS+=("$VM_DATA")
        done
    done
done

# Combine all VM data into a single JSON array
COMBINED_VMS=$(printf "%s\n" "${ALL_VMS[@]}" | jq -s .)

# Create reports directory if it doesn't exist
mkdir -p "$REPORT_DIR"

# Save the combined VM info to a JSON file
echo "$COMBINED_VMS" > "$JSON_FILE"

echo "Azure VM information saved to $JSON_FILE."

