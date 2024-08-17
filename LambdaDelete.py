import json
import boto3
import logging
from botocore.exceptions import ClientError

# Initialize logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('TestDB')

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")
    
    # Check if pathParameters and key exist
    if 'pathParameters' not in event or 'key' not in event['pathParameters']:
        logger.error("Missing path parameters")
        return {
            'statusCode': 400,
            'body': json.dumps('Bad Request: Missing path parameters')
        }
    
    key = event['pathParameters']['key']
    
    try:
        response = table.delete_item(
            Key={'id': int(key)}
        )
        logger.info(f"Delete response: {json.dumps(response)}")
        return {
            'statusCode': 200,
            'body': json.dumps('Item deleted successfully')
        }
    except ClientError as e:
        logger.error(f"ClientError: {e.response['Error']['Message']}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Internal server error: {e.response['Error']['Message']}")
        }
    except Exception as e:
        logger.error(f"Exception: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Internal server error: {str(e)}")
        }