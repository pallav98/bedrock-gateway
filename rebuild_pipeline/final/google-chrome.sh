# 🧩 Handle Google Chrome installation and report status
CHROME_STATUS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$IP" bash -s << 'EOF'
  set -euo pipefail

  # Kill Chrome if running
  pkill chrome || true

  # Remove lock files
  rm -f ~/.config/google-chrome/Singleton*

  # Install Chrome if not already present
  if ! command -v google-chrome > /dev/null 2>&1; then
    echo "Chrome not found. Installing..."
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/chrome.deb
    sudo apt-get update -qq
    sudo apt-get install -y /tmp/chrome.deb > /dev/null 2>&1 || {
      echo "FAILED,Chrome install failed"
      exit 1
    }
  fi

  # Start Chrome
  nohup google-chrome --no-sandbox --user-data-dir=/tmp/chrome-profile > /tmp/chrome.log 2>&1 &
  sleep 5

  if pgrep -x chrome > /dev/null; then
    echo "SUCCESS,Chrome started"
  else
    echo "FAILED,Chrome failed to start"
  fi
EOF
)

# 📄 Append Chrome result to the same baseline log
echo "$WORKSPACE_ID,$USERNAME,$IP,CHROME,$CHROME_STATUS" >> "rebuild/ubuntu/$BASELINE_LOG"
