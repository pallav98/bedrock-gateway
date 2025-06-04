✅ Activity Plan: Workspace Rebuild and Baseline
📌 Purpose
Rebuild all Ubuntu-based AWS WorkSpaces across 3 AWS accounts (mcaas, ss-dev, and ss-prod), wait for them to become AVAILABLE, run baseline configuration using Ansible, and email the monitoring report.

1️⃣ Pre-checks (Before Triggering)
Step	Task
1.1	Ensure GitHub Runners are active for all 3 accounts (e.g., self-hosted,mcaas-github-runner, etc.)
1.2	Verify correct IAM credentials are stored in GitHub Secrets for each account:
AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
1.3	Ensure the following input files are prepared and committed:
- workspaces_mcaas.csv
- workspaces_ss_dev.csv
- workspaces_ss_prod.csv
1.4	Confirm email subscription to the SNS topic used in the send_email.sh
1.5	Ensure the baseline Ansible script is correct and SSH/private key secrets are valid.

2️⃣ Execution Steps (via GitHub Actions)
For each account, a separate GitHub Actions workflow will be triggered manually:

🟢 rebuild-mcaas.yml
Uses input: workspaces_mcaas.csv

AWS Region: e.g., us-east-1

🟢 rebuild-ss-dev.yml
Uses input: workspaces_ss_dev.csv

AWS Region: e.g., us-west-2

🟢 rebuild-ss-prod.yml
Uses input: workspaces_ss_prod.csv

AWS Region: e.g., us-east-1

Each workflow performs:

Checkout code and make scripts executable

Set AWS credentials using GitHub Secrets

Run rebuild.sh with appropriate input file

Run wait_for_all_available.sh

Configure SSH keys and vault password

Run run_baseline.sh

Run generate_report.sh

Send email via SNS with HTML report

3️⃣ Monitoring
Output logs are available in GitHub Actions per job step

Final status and logs for each workspace will be sent via email in the form of an HTML report

All result files (rebuild_status.csv, wait_status.csv, baseline_status.csv) are archived in the workflow

🛠️ Rollback Plan (If Needed)
⚠️ A rebuild is destructive, so rollback means restoring from a backup, not "undoing" a rebuild.

Step	Rollback Task
R1	Notify affected users and prepare downtime notice if needed
R2	(Optional) Redeploy baseline script using run_baseline.sh
R3	Rebuild workspace again from latest known good state manually
R4	Investigate failure cause and update script for future runs

🧾 Summary
Item	Status
Scripts reviewed and updated for dynamic input	✅
AWS account-specific GitHub runners in place	✅
Monitoring and error handling included	✅
Reports are generated and emailed	✅
Manual rollback documented	✅
