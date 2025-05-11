#!/bin/bash
set -euo pipefail

INPUT_FILE="data/workspaces.csv"
WAIT_LOG="data/wait_status.csv"
MAX_RETRIES=60
SLEEP_INTERVAL=60

# Initialize wait log
echo "workspaceid,username,status,message" > "$WAIT_LOG"

declare -A final_states

# First count total workspaces (skip header)
total_workspaces=$(tail -n +2 "$INPUT_FILE" | wc -l | awk '{print $1}')
echo "Total workspaces to check: $total_workspaces"

retry=0
echo "Waiting for workspaces to become AVAILABLE..."

while [[ $retry -lt $MAX_RETRIES ]]; do
  pending=0
  processed=0
  
  # Skip header row with tail -n +2
  while IFS=',' read -r WORKSPACE_ID USERNAME || [[ -n "$WORKSPACE_ID" ]]; do
    # Skip empty lines
    [[ -z "$WORKSPACE_ID" ]] && continue
    
    if [[ -n "${final_states[$WORKSPACE_ID]+_}" ]]; then
      ((processed++))
      continue  # already marked success
    fi

    STATE=$(aws workspaces describe-workspaces --workspace-ids "$WORKSPACE_ID" \
            --query 'Workspaces[0].State' --output text 2>/dev/null || echo "UNKNOWN")

    if [[ "$STATE" == "AVAILABLE" ]]; then
      final_states["$WORKSPACE_ID"]="$USERNAME"
      echo "$WORKSPACE_ID,$USERNAME,SUCCESS,Available after $((retry*SLEEP_INTERVAL/60)) min" >> "$WAIT_LOG"
      echo "Workspace $WORKSPACE_ID is now AVAILABLE"
      ((processed++))
    elif [[ "$STATE" == "UNKNOWN" ]]; then
      echo "Workspace $WORKSPACE_ID could not be queried"
      ((pending++))
      ((processed++))
    else
      echo "Workspace $WORKSPACE_ID still in state: $STATE"
      ((pending++))
      ((processed++))
    fi
  done < <(tail -n +2 "$INPUT_FILE")

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
while IFS=',' read -r WORKSPACE_ID USERNAME || [[ -n "$WORKSPACE_ID" ]]; do
  [[ -z "$WORKSPACE_ID" ]] && continue
  if [[ -z "${final_states[$WORKSPACE_ID]+_}" ]]; then
    echo "$WORKSPACE_ID,$USERNAME,FAILED,Timed out after $((MAX_RETRIES*SLEEP_INTERVAL/60)) min" >> "$WAIT_LOG"
    echo "Workspace $WORKSPACE_ID FAILED to become available"
  fi
done < <(tail -n +2 "$INPUT_FILE")

# Final status report
success_count=$((${#final_states[@]}))
failed_count=$((total_workspaces - success_count))
echo "Final status: $success_count succeeded, $failed_count failed"