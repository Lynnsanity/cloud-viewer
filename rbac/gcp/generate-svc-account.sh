#!/bin/bash

PROJECT_ID="<PROJECT_ID_YOU_WANT_SVC_ACCOUNT_IN>"
KEY_FILE_PATH="./service-account.json"
SERVICE_ACCOUNT_NAME="sheets-writer"

gcloud config set project $PROJECT_ID

gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --description "Service account to update Google Sheets with VM info" \
  --display-name "Sheets Writer"

gcloud iam service-accounts keys create $KEY_FILE_PATH \
  --iam-account $SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com

echo "Share the Google Sheet with the following email address:"
echo "$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"
