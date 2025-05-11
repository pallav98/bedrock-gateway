#!/bin/bash
set -euo pipefail

INPUT_FILE="data/workspaces.csv"
WAIT_LOG="data/wait_status.csv"
MAX_RETRIES=60
SLEEP_INTERVAL=60

echo "workspaceid,username,status,message" > "$WAIT_LOG"

declare -A final_states

retry=0
echo "Waiting for workspaces to become AVAILABLE..."

while [[ $retry -lt $MAX_RETRIES ]]; do
  pending=0
  while IFS=',' read -r WORKSPACE_ID USERNAME; do
    [[ "$WORKSPACE_ID" == "workspaceid" ]] && continue

    if [[ -n "${final_states[$WORKSPACE_ID]+_}" ]]; then
      continue  # already marked success
    fi

    STATE=$(aws workspaces describe-workspaces --workspace-ids "$WORKSPACE_ID" \
            --query 'Workspaces[0].State' --output text 2>/dev/null || echo "UNKNOWN")

    if [[ "$STATE" == "AVAILABLE" ]]; then
      final_states["$WORKSPACE_ID"]="$USERNAME"
      echo "$WORKSPACE_ID,$USERNAME,SUCCESS,Available after $((retry*SLEEP_INTERVAL/60)) min" >> "$WAIT_LOG"
    else
      ((pending++))
    fi
  done < "$INPUT_FILE"

  if [[ $pending -eq 0 ]]; then
    echo "All workspaces are AVAILABLE."
    break
  fi

  echo "Retry $((retry+1))/$MAX_RETRIES - $pending still pending..."
  sleep $SLEEP_INTERVAL
  ((retry++))
done

# Log any remaining as failed
while IFS=',' read -r WORKSPACE_ID USERNAME; do
  [[ "$WORKSPACE_ID" == "workspaceid" ]] && continue
  if [[ -z "${final_states[$WORKSPACE_ID]+_}" ]]; then
    echo "$WORKSPACE_ID,$USERNAME,FAILED,Timed out after $((MAX_RETRIES*SLEEP_INTERVAL/60)) min" >> "$WAIT_LOG"
  fi
done < "$INPUT_FILE"
