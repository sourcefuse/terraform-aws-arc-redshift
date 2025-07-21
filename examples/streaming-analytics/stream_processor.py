import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Process streaming data from Kinesis
    """
    try:
        logger.info(f"Processing {len(event['Records'])} records")
        
        for record in event['Records']:
            # Decode the data
            payload = json.loads(record['kinesis']['data'])
            
            # Process the record
            processed_data = process_record(payload)
            
            logger.info(f"Processed record: {processed_data}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Successfully processed records')
        }
        
    except Exception as e:
        logger.error(f"Error processing records: {str(e)}")
        raise

def process_record(data):
    """
    Process individual record
    """
    # Add processing logic here
    return {
        'processed': True,
        'timestamp': data.get('timestamp'),
        'data': data
    }
