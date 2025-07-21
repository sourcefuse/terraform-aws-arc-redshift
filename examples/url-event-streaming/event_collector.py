import json
import boto3
import os
import uuid
import base64
from datetime import datetime
from urllib.parse import urlparse, parse_qs
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
kinesis_client = boto3.client('kinesis')

# Environment variables
KINESIS_STREAM_NAME = os.environ['KINESIS_STREAM_NAME']
REGION = os.environ['REGION']

def lambda_handler(event, context):
    """
    Lambda function to collect URL events and stream to Kinesis
    Handles both direct API calls and ALB events
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Handle ALB event format
        if 'requestContext' in event and 'elb' in event['requestContext']:
            return handle_alb_event(event)
        
        # Handle direct API Gateway event
        elif 'httpMethod' in event:
            return handle_api_gateway_event(event)
        
        # Handle direct invocation
        else:
            return handle_direct_invocation(event)
            
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }

def handle_alb_event(event):
    """
    Handle Application Load Balancer event
    """
    try:
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/')
        query_params = event.get('queryStringParameters') or {}
        headers = event.get('headers', {})
        body = event.get('body', '')
        
        # Handle health check
        if path == '/health':
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json'
                },
                'body': json.dumps({
                    'status': 'healthy',
                    'timestamp': datetime.utcnow().isoformat(),
                    'service': 'event-collector'
                })
            }
        
        # Handle event collection endpoints
        if path.startswith('/collect') or path.startswith('/track'):
            if http_method == 'POST':
                return collect_post_event(body, headers, query_params)
            elif http_method == 'GET':
                return collect_get_event(query_params, headers)
            else:
                return method_not_allowed()
        
        # Handle pixel tracking
        elif path.startswith('/pixel.gif') or path.startswith('/track.gif'):
            return collect_pixel_event(query_params, headers)
        
        # Handle JavaScript snippet
        elif path.startswith('/js/tracker.js'):
            return serve_tracking_script()
        
        else:
            return not_found()
            
    except Exception as e:
        logger.error(f"Error handling ALB event: {str(e)}")
        raise

def handle_api_gateway_event(event):
    """
    Handle API Gateway event (similar to ALB but different structure)
    """
    # Similar logic to ALB but adapted for API Gateway event structure
    return handle_alb_event(event)

def handle_direct_invocation(event):
    """
    Handle direct Lambda invocation
    """
    try:
        # Process the event data directly
        event_data = prepare_event_data(event, {}, {})
        stream_result = stream_to_kinesis(event_data)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Event processed successfully',
                'event_id': event_data['event_id'],
                'kinesis_result': stream_result
            })
        }
        
    except Exception as e:
        logger.error(f"Error handling direct invocation: {str(e)}")
        raise

def collect_post_event(body, headers, query_params):
    """
    Collect event data from POST request
    """
    try:
        # Parse JSON body
        if body:
            if isinstance(body, str):
                event_payload = json.loads(body)
            else:
                event_payload = body
        else:
            event_payload = {}
        
        # Merge with query parameters
        event_payload.update(query_params)
        
        # Prepare and stream event
        event_data = prepare_event_data(event_payload, headers, query_params)
        stream_result = stream_to_kinesis(event_data)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': json.dumps({
                'status': 'success',
                'event_id': event_data['event_id'],
                'timestamp': event_data['timestamp']
            })
        }
        
    except Exception as e:
        logger.error(f"Error collecting POST event: {str(e)}")
        raise

def collect_get_event(query_params, headers):
    """
    Collect event data from GET request (query parameters)
    """
    try:
        # Prepare and stream event
        event_data = prepare_event_data(query_params, headers, query_params)
        stream_result = stream_to_kinesis(event_data)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'status': 'success',
                'event_id': event_data['event_id'],
                'timestamp': event_data['timestamp']
            })
        }
        
    except Exception as e:
        logger.error(f"Error collecting GET event: {str(e)}")
        raise

def collect_pixel_event(query_params, headers):
    """
    Collect event via tracking pixel (1x1 transparent GIF)
    """
    try:
        # Prepare and stream event
        event_data = prepare_event_data(query_params, headers, query_params)
        stream_result = stream_to_kinesis(event_data)
        
        # Return 1x1 transparent GIF
        gif_data = base64.b64decode('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7')
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'image/gif',
                'Cache-Control': 'no-cache, no-store, must-revalidate',
                'Pragma': 'no-cache',
                'Expires': '0',
                'Access-Control-Allow-Origin': '*'
            },
            'body': base64.b64encode(gif_data).decode('utf-8'),
            'isBase64Encoded': True
        }
        
    except Exception as e:
        logger.error(f"Error collecting pixel event: {str(e)}")
        raise

def serve_tracking_script():
    """
    Serve JavaScript tracking script
    """
    tracking_script = """
(function() {
    // URL Event Tracker
    var tracker = {
        endpoint: window.location.protocol + '//' + window.location.host + '/collect',
        
        // Track page view
        trackPageView: function() {
            this.track('page_view', {
                url: window.location.href,
                title: document.title,
                referrer: document.referrer
            });
        },
        
        // Track custom event
        track: function(eventType, data) {
            data = data || {};
            
            var eventData = {
                event_type: eventType,
                url: window.location.href,
                timestamp: new Date().toISOString(),
                user_agent: navigator.userAgent,
                screen_resolution: screen.width + 'x' + screen.height,
                viewport_size: window.innerWidth + 'x' + window.innerHeight,
                timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
                language: navigator.language,
                session_id: this.getSessionId(),
                user_id: this.getUserId()
            };
            
            // Merge custom data
            Object.assign(eventData, data);
            
            // Send via beacon API or fallback to image
            if (navigator.sendBeacon) {
                navigator.sendBeacon(this.endpoint, JSON.stringify(eventData));
            } else {
                this.sendViaImage(eventData);
            }
        },
        
        // Fallback method using image
        sendViaImage: function(data) {
            var img = new Image();
            var params = new URLSearchParams();
            
            for (var key in data) {
                if (data.hasOwnProperty(key)) {
                    params.append(key, data[key]);
                }
            }
            
            img.src = window.location.protocol + '//' + window.location.host + '/pixel.gif?' + params.toString();
        },
        
        // Get or create session ID
        getSessionId: function() {
            var sessionId = sessionStorage.getItem('tracker_session_id');
            if (!sessionId) {
                sessionId = 'sess_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
                sessionStorage.setItem('tracker_session_id', sessionId);
            }
            return sessionId;
        },
        
        // Get or create user ID
        getUserId: function() {
            var userId = localStorage.getItem('tracker_user_id');
            if (!userId) {
                userId = 'user_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
                localStorage.setItem('tracker_user_id', userId);
            }
            return userId;
        }
    };
    
    // Auto-track page view
    tracker.trackPageView();
    
    // Track clicks on links
    document.addEventListener('click', function(e) {
        if (e.target.tagName === 'A') {
            tracker.track('link_click', {
                link_url: e.target.href,
                link_text: e.target.textContent
            });
        }
    });
    
    // Track form submissions
    document.addEventListener('submit', function(e) {
        if (e.target.tagName === 'FORM') {
            tracker.track('form_submit', {
                form_id: e.target.id,
                form_action: e.target.action
            });
        }
    });
    
    // Expose tracker globally
    window.urlTracker = tracker;
})();
"""
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/javascript',
            'Cache-Control': 'public, max-age=3600',
            'Access-Control-Allow-Origin': '*'
        },
        'body': tracking_script
    }

def prepare_event_data(payload, headers, query_params):
    """
    Prepare event data for streaming to Kinesis
    """
    try:
        # Generate unique event ID
        event_id = str(uuid.uuid4())
        timestamp = datetime.utcnow().isoformat()
        
        # Extract common fields
        event_data = {
            'event_id': event_id,
            'timestamp': timestamp,
            'url': payload.get('url', ''),
            'user_id': payload.get('user_id', ''),
            'session_id': payload.get('session_id', ''),
            'event_type': payload.get('event_type', 'page_view'),
            'page_title': payload.get('title', payload.get('page_title', '')),
            'referrer': payload.get('referrer', ''),
            'user_agent': headers.get('User-Agent', headers.get('user-agent', '')),
            'ip_address': headers.get('X-Forwarded-For', headers.get('x-forwarded-for', '')),
            'country': headers.get('CloudFront-Viewer-Country', ''),
            'device_type': detect_device_type(headers.get('User-Agent', '')),
            'browser': detect_browser(headers.get('User-Agent', '')),
            'os': detect_os(headers.get('User-Agent', '')),
            'screen_resolution': payload.get('screen_resolution', ''),
            'viewport_size': payload.get('viewport_size', ''),
            'timezone': payload.get('timezone', ''),
            'language': payload.get('language', ''),
            'utm_source': payload.get('utm_source', ''),
            'utm_medium': payload.get('utm_medium', ''),
            'utm_campaign': payload.get('utm_campaign', ''),
            'utm_term': payload.get('utm_term', ''),
            'utm_content': payload.get('utm_content', ''),
            'custom_data': {k: v for k, v in payload.items() if k.startswith('custom_')},
            'processing_timestamp': timestamp
        }
        
        # Parse URL for additional insights
        if event_data['url']:
            parsed_url = urlparse(event_data['url'])
            event_data['domain'] = parsed_url.netloc
            event_data['path'] = parsed_url.path
            event_data['query_string'] = parsed_url.query
            
            # Extract UTM parameters from URL if not already present
            if parsed_url.query and not event_data['utm_source']:
                query_dict = parse_qs(parsed_url.query)
                for utm_param in ['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content']:
                    if utm_param in query_dict:
                        event_data[utm_param] = query_dict[utm_param][0]
        
        return event_data
        
    except Exception as e:
        logger.error(f"Error preparing event data: {str(e)}")
        raise

def stream_to_kinesis(event_data):
    """
    Stream event data to Kinesis
    """
    try:
        # Convert to JSON string
        data = json.dumps(event_data)
        
        # Put record to Kinesis stream
        response = kinesis_client.put_record(
            StreamName=KINESIS_STREAM_NAME,
            Data=data,
            PartitionKey=event_data.get('user_id', event_data['event_id'])
        )
        
        logger.info(f"Successfully streamed event {event_data['event_id']} to Kinesis")
        
        return {
            'success': True,
            'shard_id': response['ShardId'],
            'sequence_number': response['SequenceNumber']
        }
        
    except Exception as e:
        logger.error(f"Error streaming to Kinesis: {str(e)}")
        return {
            'success': False,
            'error': str(e)
        }

def detect_device_type(user_agent):
    """
    Detect device type from user agent
    """
    user_agent = user_agent.lower()
    
    if 'mobile' in user_agent or 'android' in user_agent or 'iphone' in user_agent:
        return 'mobile'
    elif 'tablet' in user_agent or 'ipad' in user_agent:
        return 'tablet'
    else:
        return 'desktop'

def detect_browser(user_agent):
    """
    Detect browser from user agent
    """
    user_agent = user_agent.lower()
    
    if 'chrome' in user_agent:
        return 'chrome'
    elif 'firefox' in user_agent:
        return 'firefox'
    elif 'safari' in user_agent:
        return 'safari'
    elif 'edge' in user_agent:
        return 'edge'
    elif 'opera' in user_agent:
        return 'opera'
    else:
        return 'unknown'

def detect_os(user_agent):
    """
    Detect operating system from user agent
    """
    user_agent = user_agent.lower()
    
    if 'windows' in user_agent:
        return 'windows'
    elif 'mac' in user_agent:
        return 'macos'
    elif 'linux' in user_agent:
        return 'linux'
    elif 'android' in user_agent:
        return 'android'
    elif 'ios' in user_agent:
        return 'ios'
    else:
        return 'unknown'

def method_not_allowed():
    """
    Return method not allowed response
    """
    return {
        'statusCode': 405,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'error': 'Method Not Allowed',
            'message': 'Only GET and POST methods are supported'
        })
    }

def not_found():
    """
    Return not found response
    """
    return {
        'statusCode': 404,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'error': 'Not Found',
            'message': 'Endpoint not found'
        })
    }
