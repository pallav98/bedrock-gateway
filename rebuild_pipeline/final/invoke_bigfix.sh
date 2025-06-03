#!/bin/bash

# ========= CONFIGURE =========
RESOURCE_GROUP_NAME="$2"
DOCUMENT_NAME="AWS-RunPowerShellScript"
PS_SCRIPT_FILE="$1"  # Your PowerShell script filename
# =============================

# Check if script file exists
if [ ! -f "$PS_SCRIPT_FILE" ]; then
  echo "PowerShell script not found: $PS_SCRIPT_FILE"
  exit 1
fi

# Escape PowerShell script for JSON
PS_SCRIPT=$(awk '{gsub("\"", "\\\""); printf "\"%s\",\n", $0}' "$PS_SCRIPT_FILE" | sed '$s/,$//')

# Call SSM send-command
COMMAND_ID=$(aws ssm send-command \
  --document-name "$DOCUMENT_NAME" \
  --targets "Key=resource-groups:Name,Values=$RESOURCE_GROUP_NAME" \
  --parameters "{\"commands\": [ $PS_SCRIPT ]}" \
  --comment "Invoke BigFix installation via PowerShell" \
  --region "$REGION" \
  --query "Command.CommandId" \
  --output text)

if [ -z "$COMMAND_ID" ]; then
  echo "Failed to invoke command via SSM."
  exit 2
fi

echo "✅ SSM command sent. Command ID: $COMMAND_ID"

# Optional: Wait and get command result
echo "⌛ Waiting for command to complete..."
sleep 10  # Wait a bit before polling

aws ssm list-command-invocations \
  --command-id "$COMMAND_ID" \
  --details \
  --region "$REGION" \
  --output table
