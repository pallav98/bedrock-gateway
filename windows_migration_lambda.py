import boto3
import time

ssm = boto3.client('ssm')

INSTANCE_ID = 'i-xxxxxxxxxxxxxxxxx'  # Replace with your instance ID
S3_BUCKET = 'your-bucket-name'       # Replace with your bucket
ZIP_FILE = 'UserBackup.zip'
DEST_PATH = 'D:\\UserBackup'

def lambda_handler(event, context):
    # PowerShell commands
    commands = [
    f"aws s3 cp s3://{S3_BUCKET}/{ZIP_FILE} D:\\{ZIP_FILE}",
    f"Expand-Archive -Path D:\\{ZIP_FILE} -DestinationPath {DEST_PATH} -Force",
    f"Get-Content {DEST_PATH}\\sample.txt"
    ]


    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunPowerShellScript",
        Parameters={"commands": commands},
        Comment="Download ZIP, unzip and list sample.txt",
    )

    command_id = response['Command']['CommandId']
    print(f"Command sent with ID: {command_id}")

    # Wait for the command to complete
    time.sleep(5)  # Optional: Add retries + exponential backoff for better reliability

    output = ssm.get_command_invocation(
        CommandId=command_id,
        InstanceId=INSTANCE_ID
    )

    return {
        "status": output['Status'],
        "output": output['StandardOutputContent']
    }
