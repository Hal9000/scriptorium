#!/usr/bin/env python3
"""
Reddit Autopost Script for Scriptorium
Uses PRAW to submit posts to Reddit
"""

import sys
import json
import praw
import logging
from pathlib import Path

def setup_logging():
    """Setup basic logging"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(__name__)

def load_credentials(credentials_file):
    """Load Reddit API credentials from JSON file"""
    try:
        with open(credentials_file, 'r') as f:
            creds = json.load(f)
        
        required_fields = ['client_id', 'client_secret', 'username', 'password', 'user_agent']
        for field in required_fields:
            if field not in creds:
                raise ValueError(f"Missing required field: {field}")
        
        return creds
    except Exception as e:
        print(f"Error loading credentials: {e}", file=sys.stderr)
        sys.exit(1)

def load_post_data(post_data_file):
    """Load post data from JSON file"""
    try:
        with open(post_data_file, 'r') as f:
            data = json.load(f)
        
        required_fields = ['title', 'url']
        for field in required_fields:
            if field not in data:
                raise ValueError(f"Missing required field: {field}")
        
        return data
    except Exception as e:
        print(f"Error loading post data: {e}", file=sys.stderr)
        sys.exit(1)

def submit_to_reddit(creds, post_data, subreddit=None):
    """Submit post to Reddit using PRAW"""
    try:
        # Initialize Reddit instance
        reddit = praw.Reddit(
            client_id=creds['client_id'],
            client_secret=creds['client_secret'],
            username=creds['username'],
            password=creds['password'],
            user_agent=creds['user_agent']
        )
        
        # Verify credentials
        reddit.user.me()
        
        # Determine subreddit
        target_subreddit = subreddit or post_data.get('subreddit') or creds.get('default_subreddit')
        if not target_subreddit:
            raise ValueError("No subreddit specified")
        
        # Submit the post
        subreddit_instance = reddit.subreddit(target_subreddit)
        
        # Submit as link post
        submission = subreddit_instance.submit(
            title=post_data['title'],
            url=post_data['url'],
            resubmit=False  # Don't resubmit if URL already exists
        )
        
        print(f"Successfully posted to r/{target_subreddit}: {submission.shortlink}")
        return True
        
    except Exception as e:
        print(f"Error submitting to Reddit: {e}", file=sys.stderr)
        return False

def main():
    """Main function"""
    if len(sys.argv) < 3:
        print("Usage: python3 reddit_autopost.py <post_data_file> <subreddit> [credentials_file]", file=sys.stderr)
        sys.exit(1)
    
    logger = setup_logging()
    
    post_data_file = sys.argv[1]
    subreddit = sys.argv[2] if sys.argv[2] != 'None' else None
    credentials_file = sys.argv[3] if len(sys.argv) > 3 else 'reddit_credentials.json'
    
    # Load credentials and post data
    creds = load_credentials(credentials_file)
    post_data = load_post_data(post_data_file)
    
    logger.info(f"Submitting post: {post_data['title']}")
    
    # Submit to Reddit
    success = submit_to_reddit(creds, post_data, subreddit)
    
    if success:
        logger.info("Post submitted successfully")
        sys.exit(0)
    else:
        logger.error("Failed to submit post")
        sys.exit(1)

if __name__ == "__main__":
    main() 