# 🧩 Handle Google Chrome installation and report status
CHROME_STATUS=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -i "$SSH_KEY" "$SSH_USER@$IP" bash -s << EOF
  echo "$PASSWORD" | sudo -S pkill chrome || true
  echo "$PASSWORD" | sudo -S rm -f /home/$SSH_USER/.config/google-chrome/Singleton*

  if ! command -v google-chrome > /dev/null; then
    echo "Chrome not found. Installing..."
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O chrome.deb
    echo "$PASSWORD" | sudo -S dpkg -i chrome.deb || echo "$PASSWORD" | sudo -S apt-get install -f -y
  fi

  nohup google-chrome --no-sandbox --user-data-dir=/tmp/chrome-profile > /tmp/chrome.log 2>&1 &
  sleep 5

  if pgrep -x chrome > /dev/null; then
    echo "SUCCESS,Chrome started"
  else
    echo "FAILED,Chrome failed to start"
  fi
EOF
)

echo "$WORKSPACE_ID,$USERNAME,$IP,CHROME,$CHROME_STATUS" >> "rebuild/ubuntu/$BASELINE_LOG"
