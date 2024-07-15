import os
import json
from datetime import datetime
import pandas as pd
from google.oauth2 import service_account
from googleapiclient.discovery import build
import gspread
import subprocess

# service account json made from readme instructions
SERVICE_ACCOUNT_FILE = './rbac/gcp/service-account.json'

SCOPES = ['https://www.googleapis.com/auth/spreadsheets']

SPREADSHEET_ID = '<YOUR_GOOGLE_SHEET_ID_HERE>'

# authenticate service account to spreadsheet scope
credentials = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE, scopes=SCOPES)
gc = gspread.authorize(credentials)
service = build('sheets', 'v4', credentials=credentials)

# ask the user to enter the date in certain format
report_date = input("Enter the date of the report (YYYY-MM-DD): ")

# validate the date format
try:
    datetime.strptime(report_date, '%Y-%m-%d')
except ValueError:
    print("Incorrect date format, should be YYYY-MM-DD")
    exit(1)

# get the reported gcp_vm_info.json file
JSON_FILE = f'./reports/gcp/gcp_vm_info_{report_date}.json'

# check if the file exists
if os.path.exists(JSON_FILE):
    with open(JSON_FILE, 'r') as f:
        vm_info = json.load(f)

    # prep data for sheets
    data = [['Name', 'MachineType', 'DiskSizeGB', 'Description', 'Tags', 'Status', 'NetworkIP']]
    for instance in vm_info:
        data.append([
            instance.get('name', ''),
            instance.get('machineType', ''),
            int(instance.get('diskSizeGb', 0)),  # Convert to integer
            instance.get('description', ''),
            '; '.join(instance.get('tags', [])) if instance.get('tags') else '',  # Handle null tags
            instance.get('status', ''),
            instance.get('networkIP', '')
        ])

    spreadsheet = gc.open_by_key(SPREADSHEET_ID)
    sheet = spreadsheet.sheet1
    sheet.update_title("GCP VMs")
    sheet.clear()
    sheet.update(values=data, range_name='A1')

    print("Google Sheet updated with VM instances info.")

    sheet_id = sheet.id

    running_color_rgb = {"red": 147/255, "green": 196/255, "blue": 125/255}  # green
    terminated_color_rgb = {"red": 224/255, "green": 102/255, "blue": 102/255}  # red

    # format the sheet
    requests = [
        {
            "addConditionalFormatRule": {
                "rule": {
                    "ranges": [{
                        "sheetId": sheet_id,
                        "startRowIndex": 1,
                        "endRowIndex": len(data) + 1,
                        "startColumnIndex": 5,
                        "endColumnIndex": 6
                    }],
                    "booleanRule": {
                        "condition": {
                            "type": "TEXT_EQ",
                            "values": [{"userEnteredValue": "RUNNING"}]
                        },
                        "format": {
                            "backgroundColor": running_color_rgb
                        }
                    }
                },
                "index": 0
            }
        },
        {
            "addConditionalFormatRule": {
                "rule": {
                    "ranges": [{
                        "sheetId": sheet_id,
                        "startRowIndex": 1,
                        "endRowIndex": len(data) + 1,
                        "startColumnIndex": 5,
                        "endColumnIndex": 6
                    }],
                    "booleanRule": {
                        "condition": {
                            "type": "TEXT_EQ",
                            "values": [{"userEnteredValue": "TERMINATED"}]
                        },
                        "format": {
                            "backgroundColor": terminated_color_rgb
                        }
                    }
                },
                "index": 1
            }
        }
    ]

    body = {"requests": requests}
    response = service.spreadsheets().batchUpdate(spreadsheetId=SPREADSHEET_ID, body=body).execute()

    print("Formatting applied to Google Sheet.")
else:
    print("No VM instances information to update. Check if the report exists for the date you've reported.")

