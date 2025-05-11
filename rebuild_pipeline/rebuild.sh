#!/bin/bash
set -euo pipefail

INPUT_FILE="data/workspaces.csv"
REBUILD_LOG="data/rebuild_status.csv"

echo "workspaceid,username,rebuild,status,message" > "$REBUILD_LOG"

while IFS=',' read -r WORKSPACE_ID USERNAME; do
  echo "Rebuilding $WORKSPACE_ID ($USERNAME)..."
  if OUTPUT=$(aws workspaces rebuild-workspace --workspace-id "$WORKSPACE_ID" 2>&1); then
    echo "$WORKSPACE_ID,$USERNAME,yes,SUCCESS,Rebuild started" >> "$REBUILD_LOG"
  else
    echo "$WORKSPACE_ID,$USERNAME,yes,FAILED,\"$OUTPUT\"" >> "$REBUILD_LOG"
  fi
done < <(tail -n +2 "$INPUT_FILE")
