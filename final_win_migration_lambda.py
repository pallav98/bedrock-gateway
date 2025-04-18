import boto3
import os
import time

workspace_client = boto3.client('workspaces')
ssm_client = boto3.client('ssm')
s3_client = boto3.client('s3')

# Env variables
SOURCE_DIRECTORY_ID = os.environ['SOURCE_DIRECTORY_ID']
DEST_DIRECTORY_ID = os.environ['DEST_DIRECTORY_ID']
TARGET_USER = os.environ.get('TARGET_USER', 'ALL').strip().lower()
S3_BUCKET = os.environ['S3_BUCKET']

def get_workspaces_by_directory(directory_id):
    workspaces = []
    next_token = None
    while True:
        kwargs = {'DirectoryId': directory_id}
        if next_token:
            kwargs['NextToken'] = next_token
        response = workspace_client.describe_workspaces(**kwargs)
        workspaces.extend(response['Workspaces'])
        next_token = response.get('NextToken')
        if not next_token:
            break
    return [
        {
            'UserName': ws['UserName'],
            'WorkspaceId': ws['WorkspaceId'],
            'ComputerName': ws['ComputerName'],
            'State': ws['State']
        }
        for ws in workspaces if ws['State'] == 'AVAILABLE'
    ]

def get_ssm_node_id(computer_name):
    inventory = ssm_client.get_inventory(
        Filters=[{
            'Key': 'AWS:InstanceInformation.ComputerName',
            'Values': [computer_name],
            'Type': 'Equal'
        }],
        ResultAttributes=[{'TypeName': 'AWS:InstanceInformation'}]
    )
    entities = inventory['Entities']
    if entities and 'Id' in entities[0]:
        return entities[0]['Id']
    return None

def send_ssm_command(node_id, commands, comment):
    response = ssm_client.send_command(
        InstanceIds=[node_id],
        DocumentName="AWS-RunPowerShellScript",
        Parameters={"commands": commands},
        Comment=comment
    )
    command_id = response['Command']['CommandId']
    for _ in range(20):
        time.sleep(10)
        result = ssm_client.get_command_invocation(
            CommandId=command_id,
            InstanceId=node_id
        )
        if result['Status'] in ['Success', 'Failed', 'TimedOut', 'Cancelled']:
            return result
    return {'Status': 'TimedOut', 'StandardOutputContent': '', 'StandardErrorContent': 'Command timeout'}

def lambda_handler(event, context):
    source_workspaces = get_workspaces_by_directory(SOURCE_DIRECTORY_ID)
    dest_workspaces = get_workspaces_by_directory(DEST_DIRECTORY_ID)

    if TARGET_USER != 'all':
        source_workspaces = [ws for ws in source_workspaces if ws['UserName'].lower() == TARGET_USER]

    dest_usernames = {ws['UserName'].lower(): ws for ws in dest_workspaces}

    for source_ws in source_workspaces:
        username = source_ws['UserName'].lower()

        if username not in dest_usernames:
            print(f"Destination workspace not found for {username}, skipping.")
            continue

        print(f"Processing user: {username}")
        s3_prefix = username

        # Get source node ID
        source_node_id = get_ssm_node_id(source_ws['ComputerName'])
        if not source_node_id:
            print(f"Could not find source SSM node for {username}")
            continue

        # Zip Users folder and upload to S3
        zip_path = f"D:\\{username}_backup.zip"
        commands = [
            f"Compress-Archive -Path 'D:\\Users\\*' -DestinationPath '{zip_path}' -Force",
            f"aws s3 cp '{zip_path}' 's3://{S3_BUCKET}/{s3_prefix}/{username}_backup.zip'"
        ]
        zip_result = send_ssm_command(source_node_id, commands, f"Zipping and uploading user folder for {username}")
        print(f"Zip result: {zip_result['Status']}")

        if zip_result['Status'] != 'Success':
            print(f"Failed to zip/upload for {username}")
            continue

        # Get destination node ID
        dest_ws = dest_usernames[username]
        dest_node_id = get_ssm_node_id(dest_ws['ComputerName'])
        if not dest_node_id:
            print(f"Could not find destination SSM node for {username}")
            continue

        # Download from S3 and unzip
        commands = [
            f"aws s3 cp 's3://{S3_BUCKET}/{s3_prefix}/{username}_backup.zip' 'D:\\{username}_backup.zip'",
            f"Expand-Archive -Path 'D:\\{username}_backup.zip' -DestinationPath 'D:\\Users' -Force"
        ]
        unzip_result = send_ssm_command(dest_node_id, commands, f"Download and unzip home for {username}")
        print(f"Unzip result: {unzip_result['Status']}")

    return {
        "status": "completed",
        "message": f"Migration run for {'all users' if TARGET_USER == 'all' else TARGET_USER}"
    }
