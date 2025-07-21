import json
import base64
import boto3
import os
import logging
from datetime import datetime
from urllib.parse import urlparse, parse_qs
import geoip2.database
import geoip2.errors

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
REGION = os.environ['REGION']

def lambda_handler(event, context):
    """
    Lambda function to enrich events before loading into Redshift
    This function is called by Kinesis Data Firehose
    """
    try:
        logger.info(f"Processing {len(event['records'])} records")
        
        output_records = []
        
        for record in event['records']:
            # Decode the data
            payload = base64.b64decode(record['data']).decode('utf-8')
            data = json.loads(payload)
            
            # Enrich the event data
            enriched_data = enrich_event(data)
            
            # Encode back to base64
            enriched_payload = json.dumps(enriched_data)
            encoded_data = base64.b64encode(enriched_payload.encode('utf-8')).decode('utf-8')
            
            output_record = {
                'recordId': record['recordId'],
                'result': 'Ok',
                'data': encoded_data
            }
            
            output_records.append(output_record)
        
        logger.info(f"Successfully processed {len(output_records)} records")
        
        return {
            'records': output_records
        }
        
    except Exception as e:
        logger.error(f"Error processing records: {str(e)}")
        
        # Return failed records
        output_records = []
        for record in event['records']:
            output_record = {
                'recordId': record['recordId'],
                'result': 'ProcessingFailed'
            }
            output_records.append(output_record)
        
        return {
            'records': output_records
        }

def enrich_event(data):
    """
    Enrich event data with additional information
    """
    try:
        enriched_data = data.copy()
        
        # Add processing timestamp
        enriched_data['enrichment_timestamp'] = datetime.utcnow().isoformat()
        
        # Enrich URL information
        if enriched_data.get('url'):
            url_info = analyze_url(enriched_data['url'])
            enriched_data.update(url_info)
        
        # Enrich user agent information
        if enriched_data.get('user_agent'):
            ua_info = analyze_user_agent(enriched_data['user_agent'])
            enriched_data.update(ua_info)
        
        # Enrich IP address information (geolocation)
        if enriched_data.get('ip_address'):
            geo_info = get_geolocation(enriched_data['ip_address'])
            enriched_data.update(geo_info)
        
        # Add session information
        session_info = analyze_session(enriched_data)
        enriched_data.update(session_info)
        
        # Add marketing attribution
        attribution_info = analyze_attribution(enriched_data)
        enriched_data.update(attribution_info)
        
        # Add content categorization
        content_info = categorize_content(enriched_data)
        enriched_data.update(content_info)
        
        # Add engagement metrics
        engagement_info = calculate_engagement_metrics(enriched_data)
        enriched_data.update(engagement_info)
        
        # Clean and validate data
        enriched_data = clean_and_validate(enriched_data)
        
        return enriched_data
        
    except Exception as e:
        logger.error(f"Error enriching event: {str(e)}")
        # Return original data if enrichment fails
        return data

def analyze_url(url):
    """
    Analyze URL and extract meaningful information
    """
    try:
        parsed = urlparse(url)
        
        url_info = {
            'url_scheme': parsed.scheme,
            'url_domain': parsed.netloc,
            'url_path': parsed.path,
            'url_query': parsed.query,
            'url_fragment': parsed.fragment,
            'url_port': parsed.port,
            'is_secure': parsed.scheme == 'https',
            'path_depth': len([p for p in parsed.path.split('/') if p]),
            'has_query_params': bool(parsed.query),
            'subdomain': extract_subdomain(parsed.netloc),
            'domain_extension': extract_domain_extension(parsed.netloc)
        }
        
        # Extract query parameters
        if parsed.query:
            query_params = parse_qs(parsed.query)
            url_info['query_param_count'] = len(query_params)
            
            # Check for common tracking parameters
            tracking_params = ['utm_source', 'utm_medium', 'utm_campaign', 'gclid', 'fbclid']
            url_info['has_tracking_params'] = any(param in query_params for param in tracking_params)
        
        # Categorize page type based on path
        url_info['page_category'] = categorize_page_type(parsed.path)
        
        return url_info
        
    except Exception as e:
        logger.error(f"Error analyzing URL: {str(e)}")
        return {}

def analyze_user_agent(user_agent):
    """
    Analyze user agent string for detailed device/browser information
    """
    try:
        ua_lower = user_agent.lower()
        
        ua_info = {
            'browser_name': detect_browser_detailed(ua_lower),
            'browser_version': extract_browser_version(user_agent),
            'os_name': detect_os_detailed(ua_lower),
            'os_version': extract_os_version(user_agent),
            'device_type': detect_device_type_detailed(ua_lower),
            'device_brand': detect_device_brand(ua_lower),
            'is_mobile': is_mobile_device(ua_lower),
            'is_tablet': is_tablet_device(ua_lower),
            'is_bot': is_bot_user_agent(ua_lower),
            'supports_javascript': not is_bot_user_agent(ua_lower),
            'user_agent_length': len(user_agent)
        }
        
        return ua_info
        
    except Exception as e:
        logger.error(f"Error analyzing user agent: {str(e)}")
        return {}

def get_geolocation(ip_address):
    """
    Get geolocation information from IP address
    Note: This is a simplified version. In production, you'd use a proper GeoIP database
    """
    try:
        # Remove common proxy headers
        ip = ip_address.split(',')[0].strip()
        
        # Skip private/local IPs
        if is_private_ip(ip):
            return {
                'country': 'Unknown',
                'country_code': 'XX',
                'region': 'Unknown',
                'city': 'Unknown',
                'latitude': None,
                'longitude': None,
                'timezone': 'Unknown',
                'isp': 'Unknown',
                'is_private_ip': True
            }
        
        # In a real implementation, you would use a GeoIP database like MaxMind
        # For now, return placeholder data
        geo_info = {
            'country': 'United States',  # Placeholder
            'country_code': 'US',
            'region': 'California',
            'city': 'San Francisco',
            'latitude': 37.7749,
            'longitude': -122.4194,
            'timezone': 'America/Los_Angeles',
            'isp': 'Unknown',
            'is_private_ip': False
        }
        
        return geo_info
        
    except Exception as e:
        logger.error(f"Error getting geolocation: {str(e)}")
        return {}

def analyze_session(data):
    """
    Analyze session-related information
    """
    try:
        session_info = {
            'has_session_id': bool(data.get('session_id')),
            'has_user_id': bool(data.get('user_id')),
            'is_new_session': data.get('session_id', '').startswith('sess_'),
            'is_new_user': data.get('user_id', '').startswith('user_'),
            'session_duration_estimate': estimate_session_duration(data),
            'is_bounce_candidate': is_potential_bounce(data)
        }
        
        return session_info
        
    except Exception as e:
        logger.error(f"Error analyzing session: {str(e)}")
        return {}

def analyze_attribution(data):
    """
    Analyze marketing attribution
    """
    try:
        attribution_info = {
            'has_utm_params': any(data.get(f'utm_{param}') for param in ['source', 'medium', 'campaign']),
            'traffic_source': determine_traffic_source(data),
            'campaign_type': determine_campaign_type(data),
            'is_direct_traffic': not data.get('referrer') and not any(data.get(f'utm_{param}') for param in ['source', 'medium']),
            'is_organic_search': is_organic_search_traffic(data),
            'is_paid_search': is_paid_search_traffic(data),
            'is_social_traffic': is_social_traffic(data),
            'is_email_traffic': is_email_traffic(data),
            'referrer_domain': extract_domain_from_referrer(data.get('referrer', ''))
        }
        
        return attribution_info
        
    except Exception as e:
        logger.error(f"Error analyzing attribution: {str(e)}")
        return {}

def categorize_content(data):
    """
    Categorize content based on URL and page information
    """
    try:
        url = data.get('url', '')
        path = data.get('url_path', '')
        title = data.get('page_title', '')
        
        content_info = {
            'content_category': categorize_page_type(path),
            'content_subcategory': get_content_subcategory(path, title),
            'is_homepage': path in ['/', ''],
            'is_product_page': '/product' in path.lower() or '/item' in path.lower(),
            'is_category_page': '/category' in path.lower() or '/collection' in path.lower(),
            'is_search_page': '/search' in path.lower() or 'q=' in data.get('url_query', ''),
            'is_checkout_page': any(keyword in path.lower() for keyword in ['/checkout', '/cart', '/payment']),
            'is_account_page': any(keyword in path.lower() for keyword in ['/account', '/profile', '/dashboard']),
            'page_depth': data.get('path_depth', 0),
            'has_page_title': bool(title)
        }
        
        return content_info
        
    except Exception as e:
        logger.error(f"Error categorizing content: {str(e)}")
        return {}

def calculate_engagement_metrics(data):
    """
    Calculate engagement-related metrics
    """
    try:
        engagement_info = {
            'event_value': calculate_event_value(data),
            'engagement_score': calculate_engagement_score(data),
            'conversion_potential': assess_conversion_potential(data),
            'user_intent': determine_user_intent(data),
            'interaction_type': classify_interaction_type(data.get('event_type', 'page_view'))
        }
        
        return engagement_info
        
    except Exception as e:
        logger.error(f"Error calculating engagement metrics: {str(e)}")
        return {}

def clean_and_validate(data):
    """
    Clean and validate the enriched data
    """
    try:
        # Remove None values
        cleaned_data = {k: v for k, v in data.items() if v is not None}
        
        # Ensure required fields have default values
        required_fields = {
            'event_id': 'unknown',
            'timestamp': datetime.utcnow().isoformat(),
            'event_type': 'page_view',
            'url': '',
            'user_id': '',
            'session_id': ''
        }
        
        for field, default_value in required_fields.items():
            if not cleaned_data.get(field):
                cleaned_data[field] = default_value
        
        # Truncate long strings to prevent Redshift issues
        string_limits = {
            'url': 2048,
            'page_title': 500,
            'user_agent': 1000,
            'referrer': 2048
        }
        
        for field, limit in string_limits.items():
            if cleaned_data.get(field) and len(str(cleaned_data[field])) > limit:
                cleaned_data[field] = str(cleaned_data[field])[:limit]
        
        return cleaned_data
        
    except Exception as e:
        logger.error(f"Error cleaning data: {str(e)}")
        return data

# Helper functions (simplified implementations)

def extract_subdomain(netloc):
    parts = netloc.split('.')
    return parts[0] if len(parts) > 2 else ''

def extract_domain_extension(netloc):
    parts = netloc.split('.')
    return parts[-1] if parts else ''

def categorize_page_type(path):
    path_lower = path.lower()
    if path in ['/', '']:
        return 'homepage'
    elif '/product' in path_lower:
        return 'product'
    elif '/category' in path_lower:
        return 'category'
    elif '/blog' in path_lower:
        return 'blog'
    elif '/about' in path_lower:
        return 'about'
    elif '/contact' in path_lower:
        return 'contact'
    else:
        return 'other'

def detect_browser_detailed(ua_lower):
    if 'chrome' in ua_lower and 'edge' not in ua_lower:
        return 'Chrome'
    elif 'firefox' in ua_lower:
        return 'Firefox'
    elif 'safari' in ua_lower and 'chrome' not in ua_lower:
        return 'Safari'
    elif 'edge' in ua_lower:
        return 'Edge'
    elif 'opera' in ua_lower:
        return 'Opera'
    else:
        return 'Other'

def detect_os_detailed(ua_lower):
    if 'windows' in ua_lower:
        return 'Windows'
    elif 'mac' in ua_lower and 'iphone' not in ua_lower and 'ipad' not in ua_lower:
        return 'macOS'
    elif 'linux' in ua_lower:
        return 'Linux'
    elif 'android' in ua_lower:
        return 'Android'
    elif 'iphone' in ua_lower or 'ipad' in ua_lower:
        return 'iOS'
    else:
        return 'Other'

def detect_device_type_detailed(ua_lower):
    if 'mobile' in ua_lower or 'android' in ua_lower or 'iphone' in ua_lower:
        return 'Mobile'
    elif 'tablet' in ua_lower or 'ipad' in ua_lower:
        return 'Tablet'
    else:
        return 'Desktop'

def detect_device_brand(ua_lower):
    if 'iphone' in ua_lower or 'ipad' in ua_lower or 'mac' in ua_lower:
        return 'Apple'
    elif 'samsung' in ua_lower:
        return 'Samsung'
    elif 'google' in ua_lower:
        return 'Google'
    else:
        return 'Other'

def is_mobile_device(ua_lower):
    return any(keyword in ua_lower for keyword in ['mobile', 'android', 'iphone'])

def is_tablet_device(ua_lower):
    return any(keyword in ua_lower for keyword in ['tablet', 'ipad'])

def is_bot_user_agent(ua_lower):
    bot_keywords = ['bot', 'crawler', 'spider', 'scraper', 'curl', 'wget']
    return any(keyword in ua_lower for keyword in bot_keywords)

def is_private_ip(ip):
    # Simplified check for private IP ranges
    return ip.startswith(('10.', '172.', '192.168.', '127.'))

def extract_browser_version(user_agent):
    # Simplified version extraction
    return 'Unknown'

def extract_os_version(user_agent):
    # Simplified version extraction
    return 'Unknown'

def estimate_session_duration(data):
    # Placeholder for session duration estimation
    return 0

def is_potential_bounce(data):
    # Simplified bounce detection
    return data.get('event_type') == 'page_view'

def determine_traffic_source(data):
    if data.get('utm_source'):
        return data['utm_source']
    elif data.get('referrer'):
        return 'referral'
    else:
        return 'direct'

def determine_campaign_type(data):
    utm_medium = data.get('utm_medium', '').lower()
    if 'cpc' in utm_medium or 'ppc' in utm_medium:
        return 'paid_search'
    elif 'email' in utm_medium:
        return 'email'
    elif 'social' in utm_medium:
        return 'social'
    else:
        return 'other'

def is_organic_search_traffic(data):
    referrer = data.get('referrer', '').lower()
    search_engines = ['google.com', 'bing.com', 'yahoo.com', 'duckduckgo.com']
    return any(engine in referrer for engine in search_engines) and not data.get('utm_source')

def is_paid_search_traffic(data):
    return data.get('utm_medium', '').lower() in ['cpc', 'ppc'] or 'gclid' in data.get('url_query', '')

def is_social_traffic(data):
    referrer = data.get('referrer', '').lower()
    social_domains = ['facebook.com', 'twitter.com', 'linkedin.com', 'instagram.com']
    return any(domain in referrer for domain in social_domains)

def is_email_traffic(data):
    return data.get('utm_medium', '').lower() == 'email'

def extract_domain_from_referrer(referrer):
    if referrer:
        try:
            return urlparse(referrer).netloc
        except:
            return ''
    return ''

def get_content_subcategory(path, title):
    # Simplified subcategory detection
    return 'general'

def calculate_event_value(data):
    # Assign values based on event type
    event_values = {
        'page_view': 1,
        'link_click': 2,
        'form_submit': 5,
        'purchase': 10,
        'signup': 8
    }
    return event_values.get(data.get('event_type', 'page_view'), 1)

def calculate_engagement_score(data):
    # Simple engagement scoring
    score = 0
    if data.get('has_session_id'):
        score += 1
    if data.get('event_type') != 'page_view':
        score += 2
    if data.get('has_utm_params'):
        score += 1
    return score

def assess_conversion_potential(data):
    # Simple conversion potential assessment
    high_intent_pages = ['/checkout', '/cart', '/signup', '/contact']
    path = data.get('url_path', '').lower()
    return 'high' if any(page in path for page in high_intent_pages) else 'low'

def determine_user_intent(data):
    path = data.get('url_path', '').lower()
    if '/search' in path:
        return 'search'
    elif '/product' in path:
        return 'browse'
    elif '/checkout' in path:
        return 'purchase'
    else:
        return 'general'

def classify_interaction_type(event_type):
    interaction_types = {
        'page_view': 'passive',
        'link_click': 'navigation',
        'form_submit': 'conversion',
        'scroll': 'engagement',
        'download': 'conversion'
    }
    return interaction_types.get(event_type, 'other')
