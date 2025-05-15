#!/bin/bash

# Configuration
SMTP_SERVER="smtp.gsa.gov"
SMTP_PORT=25
FROM_ADDR="fcs_alerting.no_reply@gsa.gov"
TO_ADDR="jordan.hatchell@gsa.gov"
SUBJECT="Workspace Rebuild Report"
REPORT_FILE="workspace_report.html"

# Check if the report file exists
if [[ ! -f "$REPORT_FILE" ]]; then
  echo "Report file '$REPORT_FILE' not found!"
  exit 1
fi

# Create the email headers and body
{
  echo "To: ${TO_ADDR}"
  echo "From: ${FROM_ADDR}"
  echo "Subject: ${SUBJECT}"
  echo "MIME-Version: 1.0"
  echo "Content-Type: text/html"
  echo ""
  cat "${REPORT_FILE}"
} | /usr/sbin/sendmail -t
