GCP VM Listing Steps
--------------------

## Pre-reqs

- Access to gcp project ID
- For other projects you want vm info on
    - you need Google API enabled on the project
    - access to view and list vm's there with gcloud cli
    - you need to be able to view the list of all projects with gcloud cli

On the main project ID I enabled Google Spreadsheets API as well.

Make env variable modifications in `./generate-svc-account.sh` and run it.

This service account made is what pushes vm information you obtain to the spreadsheet.

Add the service account to Google Spreadsheets API too.

Don't share the service account with anyone!

Make sure to add the service account email as Editor to the spreadsheet you'd like it to update.

Now you can go back to readme and generate reports/update spreadsheets pertaining to GCP.

