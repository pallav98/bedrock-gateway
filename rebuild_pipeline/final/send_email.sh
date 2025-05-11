#!/bin/bash
set -euo pipefail

TOPIC_ARN="arn:aws:sns:us-east-1:123456789012:YourTopicName"  # Replace with your ARN
REPORT_FILE="workspace_report.html"

if [[ ! -f "$REPORT_FILE" ]]; then
  echo "Report not found!"
  exit 1
fi

aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --subject "Workspace Maintenance Report" \
  --message file://"$REPORT_FILE" \
  --message-attributes '{"AWS.SNS.MAIL.MessageFormat":{"DataType":"String","StringValue":"HTML"}}'

echo "Report sent to SNS topic."