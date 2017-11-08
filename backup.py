import boto3
import os
ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    response = ec2.get_console_output(
        InstanceIds=[
                os.environ['LAMBDA_EC2_ID']
        ],
        DryRun=False
    )
    print(response.output)

    response = ec2.start_instances(
        InstanceIds=[
            os.environ['LAMBDA_EC2_ID']
        ],
        DryRun=False
    )

    print(response)