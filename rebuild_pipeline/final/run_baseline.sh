#!/bin/bash
set -euo pipefail

INPUT_FILE="data/workspaces.csv"
BASELINE_LOG="data/baseline_status.csv"

echo "workspaceid,username,ip,status,message" > "$BASELINE_LOG"

while IFS=',' read -r WORKSPACE_ID USERNAME; do
  IP=$(aws workspaces describe-workspaces --workspace-ids "$WORKSPACE_ID" \
       --query 'Workspaces[0].IpAddress' --output text 2>/dev/null)

  if [[ -z "$IP" || "$IP" == "None" ]]; then
    echo "$WORKSPACE_ID,$USERNAME,,FAILED,No IP found" >> "$BASELINE_LOG"
    continue
  fi

  echo "Running baseline on $WORKSPACE_ID ($USERNAME) - $IP"
  if OUTPUT=$(./run_user.sh -i "wsansible@$IP" -t -v fcs 2>&1); then
    echo "$WORKSPACE_ID,$USERNAME,$IP,SUCCESS,Baseline completed" >> "$BASELINE_LOG"
  else
    echo "$WORKSPACE_ID,$USERNAME,$IP,FAILED,\"$OUTPUT\"" >> "$BASELINE_LOG"
  fi
done < <(tail -n +2 "$INPUT_FILE")