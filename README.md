cloud-viewer
------------

Make cloud platform csv reports of vm instances
Initialize environment -> Set up service account -> Make reports -> Update spreadsheets with report information

Pre-Reqs:
- python3 + pyenv installed
- jq installed
- google spreadsheet created and you need to know its ID

## Initialize environment

```sh
# make python environment
make env
source env/bin/activate
make requirements

# make directories to put reports in
make report-directories

# this is for GCP - edit the Makefile and put in your most powerful google project ID :)
make root-project
```

## Make Service Account in google

refer [here](./rbac/gcp/README.md)

## Generate Report Options
`make gcp-report` this should prompt you to login while script runs.
these reports go to ./reports/gcp/


## Update Google Spreadsheet

To update the google sheet specific to GCP information:
`make update-gcp-sheet`

Cool sidenote: When you update the sheet, you'll be prompted to enter date of when report was generated.
So, you don't HAVE to always replace the sheet with new information. You can go back and display old vm
information as well (all depends what date you put and if you have the json file in the right place.
