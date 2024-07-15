#!/bin/bash

CURRENT_DATE=$(date +"%Y-%m-%d")

authenticate() {
    gcloud auth application-default login
}


set_project() {
    local PROJECT=$1
    gcloud config set project "$PROJECT"
}

# use gcloud command to fetch instance data of vms
fetch_instance_data() {
    local INSTANCES=$(gcloud compute instances list --format=json 2>/dev/null)

    if [ -n "$INSTANCES" ] && [ "$INSTANCES" != "[]" ]; then
        echo "$INSTANCES" | jq -r '.[] | { name: .name, machineType: .machineType, diskSizeGb: .disks[].diskSizeGb, status: .status, networkIP: .networkInterfaces[].networkIP, description: .description, tags: .tags.items }'
    fi
}

update_gcp_info_sheet() {
    local INSTANCE_DATA=$1
    # make the gcp_vm_info.json file
    echo $INSTANCE_DATA >> ./reports/gcp/gcp_vm_info_$CURRENT_DATE.json
}

main() {
    authenticate
    # get current project user is in - should be most powerful
    INITIAL_PROJECT=$(gcloud config get-value project)

    # fetch projects user has access to
    PROJECTS=$(gcloud projects list --format="value(projectId)")

    declare -a ALL_INSTANCES=()
    declare -a SUCCESSFUL_PROJECTS=()

    for PROJECT in $PROJECTS; do
        echo "Processing project: $PROJECT"

        # check if compute.googleapis.com API is enabled
        SERVICES=$(gcloud services list --project "$PROJECT" --format="value(NAME)" --filter="NAME:compute.googleapis.com" 2>/dev/null)

        if [[ -n "$SERVICES" ]]; then
            set_project "$PROJECT"
            CURRENT_PROJECT=$(gcloud config get-value project)
            echo "Current project set to: $CURRENT_PROJECT"

            INSTANCES=$(fetch_instance_data)

            if [ -n "$INSTANCES" ]; then
                ALL_INSTANCES+=("$INSTANCES")
                SUCCESSFUL_PROJECTS+=("$PROJECT")
            fi
        else
            echo "Skipping project $PROJECT (compute.googleapis.com API is either not enabled or you do not have permission)."
        fi
    done

    # format instances into a single JSON array
    COMBINED_INSTANCES=$(printf "%s\n" "${ALL_INSTANCES[@]}" | jq -s .)

    # insert the data into a json file
    update_gcp_info_sheet "$COMBINED_INSTANCES"

    # print successful projects
    echo "Successfully fetched and inserted GCP instance information for the following projects:"
    for project in "${SUCCESSFUL_PROJECTS[@]}"; do
        echo "- $project"
    done

    # put user back into their initial project they were in
    gcloud config set project "$INITIAL_PROJECT"
    CURRENT_PROJECT=$(gcloud config get-value project)
    echo "Current project is set back to: $CURRENT_PROJECT"
}

# run the thang
main

