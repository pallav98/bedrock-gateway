#!/bin/bash
set -euo pipefail

INPUT_FILE="data/workspaces.csv"
MAX_RETRIES=60
SLEEP_INTERVAL=60

retry=0
echo "Waiting for workspaces to become AVAILABLE..."

while [[ $retry -lt $MAX_RETRIES ]]; do
  pending=0
  while IFS=',' read -r WORKSPACE_ID USERNAME; do
    STATE=$(aws workspaces describe-workspaces --workspace-ids "$WORKSPACE_ID" --query 'Workspaces[0].State' --output text 2>/dev/null || echo "UNKNOWN")
    if [[ "$STATE" != "AVAILABLE" ]]; then
      echo "$WORKSPACE_ID ($USERNAME) is $STATE"
      ((pending++))
    fi
  done < <(tail -n +2 "$INPUT_FILE")

  if [[ $pending -eq 0 ]]; then
    echo "All workspaces are AVAILABLE."
    exit 0
  fi

  echo "Retry $((retry+1))/$MAX_RETRIES - Waiting..."
  sleep $SLEEP_INTERVAL
  ((retry++))
done

echo "Timeout: Some workspaces are still not AVAILABLE."
exit 1