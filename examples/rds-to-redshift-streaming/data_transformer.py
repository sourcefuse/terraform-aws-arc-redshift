import json
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Transform data during DMS replication
    """
    try:
        logger.info(f"Processing DMS event: {json.dumps(event)}")
        
        # Process DMS state change events
        if 'source' in event and event['source'] == 'aws.dms':
            return handle_dms_event(event)
        
        # Process direct transformation requests
        return handle_transformation_request(event)
        
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        raise

def handle_dms_event(event):
    """
    Handle DMS replication task state changes
    """
    detail = event.get('detail', {})
    state = detail.get('state')
    
    logger.info(f"DMS task state: {state}")
    
    if state == 'running':
        logger.info("DMS replication task is running")
    elif state == 'stopped':
        logger.info("DMS replication task has stopped")
    elif state == 'failed':
        logger.error("DMS replication task has failed")
    
    return {
        'statusCode': 200,
        'body': json.dumps(f'Processed DMS event: {state}')
    }

def handle_transformation_request(event):
    """
    Handle data transformation requests
    """
    # Add transformation logic here
    return {
        'statusCode': 200,
        'body': json.dumps('Transformation completed')
    }
