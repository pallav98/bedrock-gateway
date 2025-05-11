#!/bin/bash
set -euo pipefail

INPUT_FILE="data/workspaces.csv"
WAIT_LOG="data/wait_status.csv"
MAX_RETRIES=60
SLEEP_INTERVAL=60

# Initialize wait log
echo "workspaceid,username,status,message" > "$WAIT_LOG"

declare -A final_states

retry=0
pending=0  # Initialize outside the loop
echo "Waiting for workspaces to become AVAILABLE..."

# First count total workspaces
total_workspaces=0
while IFS=',' read -r WORKSPACE_ID _; do
    [[ -z "$WORKSPACE_ID" || "$WORKSPACE_ID" == "workspaceid" ]] && continue
    ((total_workspaces++))
done < "$INPUT_FILE"

while [[ $retry -lt $MAX_RETRIES ]]; do
  pending=0  # Reset counter each iteration
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
      echo "Workspace $WORKSPACE_ID is now AVAILABLE"
    elif [[ "$STATE" == "UNKNOWN" ]]; then
      echo "Workspace $WORKSPACE_ID could not be queried"
      ((pending++))
    else
      echo "Workspace $WORKSPACE_ID still in state: $STATE"
      ((pending++))
    fi
  done < "$INPUT_FILE"

  if [[ $pending -eq 0 ]]; then
    echo "All $total_workspaces workspaces are now AVAILABLE."
    break
  fi

  remaining_time=$(( (MAX_RETRIES - retry) * SLEEP_INTERVAL / 60 ))
  echo "Retry $((retry+1))/$MAX_RETRIES - $pending/$total_workspaces still pending (${remaining_time}min remaining)..."
  sleep $SLEEP_INTERVAL
  ((retry++))
done

# Log any remaining as failed
while IFS=',' read -r WORKSPACE_ID USERNAME; do
  [[ "$WORKSPACE_ID" == "workspaceid" ]] && continue
  if [[ -z "${final_states[$WORKSPACE_ID]+_}" ]]; then
    echo "$WORKSPACE_ID,$USERNAME,FAILED,Timed out after $((MAX_RETRIES*SLEEP_INTERVAL/60)) min" >> "$WAIT_LOG"
    echo "Workspace $WORKSPACE_ID FAILED to become available"
  fi
done < "$INPUT_FILE"

# Final status report
success_count=$((${#final_states[@]}))
failed_count=$((total_workspaces - success_count))
echo "Final status: $success_count succeeded, $failed_count failed"