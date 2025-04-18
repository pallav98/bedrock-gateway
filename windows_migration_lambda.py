import boto3
import time

ssm = boto3.client('ssm')

INSTANCE_ID = 'i-xxxxxxxxxxxxxxxxx'  # Replace with your actual instance ID
S3_BUCKET = 'your-bucket-name'       # Replace with your S3 bucket name
ZIP_FILE = 'UserBackup.zip'
ZIP_LOCAL_PATH = f'D:\\{ZIP_FILE}'
DEST_PATH = 'D:\\Users'  # Overwriting Users folder
SAMPLE_FILE = f'{DEST_PATH}\\fdjapi\\sample.txt'  # Adjust subfolder if needed

def lambda_handler(event, context):
    # PowerShell commands
    commands = [
        f"aws s3 cp s3://{S3_BUCKET}/{ZIP_FILE} {ZIP_LOCAL_PATH}",
        f"Expand-Archive -Path {ZIP_LOCAL_PATH} -DestinationPath {DEST_PATH} -Force",
        f"Get-Content -Path {SAMPLE_FILE}"
    ]

    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName="AWS-RunPowerShellScript",
        Parameters={"commands": commands},
        Comment="Restore Users folder from ZIP and print sample.txt",
    )

    command_id = response['Command']['CommandId']
    print(f"Command sent with ID: {command_id}")

    time.sleep(10)  # Tune this if zip size is large

    output = ssm.get_command_invocation(
        CommandId=command_id,
        InstanceId=INSTANCE_ID
    )

    return {
        "status": output['Status'],
        "output": output['StandardOutputContent'],
        "stderr": output['StandardErrorContent']
    }
