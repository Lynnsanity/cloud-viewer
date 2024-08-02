import os
import json
from datetime import datetime
import pandas as pd
from google.oauth2 import service_account
from googleapiclient.discovery import build
import gspread

SERVICE_ACCOUNT_FILE = './rbac/gcp/service-account.json'

SCOPES = ['https://www.googleapis.com/auth/spreadsheets']
SPREADSHEET_ID = '<SHEET_ID_HERE>'

credentials = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE, scopes=SCOPES)
gc = gspread.authorize(credentials)
service = build('sheets', 'v4', credentials=credentials)

report_date = input("Enter the date of the report (YYYY-MM-DD): ")

try:
    datetime.strptime(report_date, '%Y-%m-%d')
except ValueError:
    print("Incorrect date format, should be YYYY-MM-DD")
    exit(1)

JSON_FILE = f'./reports/azr/azure_vm_info_{report_date}.json'

if os.path.exists(JSON_FILE):
    with open(JSON_FILE, 'r') as f:
        vm_info = json.load(f)

    data = [['Name', 'Location', 'ResourceGroup', 'DiskSizeGb', 'Priority', 'ProvisioningState', 'Tags']]

    for instance in vm_info:
        if isinstance(instance, dict):
            tags = instance.get('tags', {})
            if tags is None:
                tags_str = ''
            else:
                tags_str = ', '.join(f"{k}: {v}" for k, v in tags.items())
            
            data.append([
                instance.get('name', ''),
                instance.get('location', ''),
                instance.get('resourceGroup', ''),
                instance.get('osDiskSizeGb', ''),
                instance.get('priority', ''),
                instance.get('provisioningState', ''),
                tags_str
            ])
        else:
            print("Skipping non-dictionary instance: ", instance)

    spreadsheet = gc.open_by_key(SPREADSHEET_ID)
    sheet = spreadsheet.worksheet("Azure VMs")
    sheet.clear()
    sheet.update(values=data, range_name='A1')

    print("Google Sheet updated with Azure VM instances info.")
else:
    print("No VM instances information to update. Check if the report exists for the date you've reported.")
