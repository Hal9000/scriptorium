# Reddit Integration for Scriptorium

Scriptorium includes a Reddit autoposting feature that allows you to automatically submit blog posts to Reddit when they are published.

## Overview

The Reddit integration uses a Ruby-to-Python bridge approach:
- **Ruby side**: Handles Scriptorium integration and data preparation
- **Python side**: Uses PRAW (Python Reddit API Wrapper) for actual Reddit API calls

This approach leverages the mature and well-tested PRAW library while keeping the integration clean and maintainable.

## Setup

### 1. Install Python Dependencies

**Recommended: Use a Virtual Environment**
```bash
# Create a virtual environment for Scriptorium
python3 -m venv ~/.scriptorium-python

# Activate the virtual environment
source ~/.scriptorium-python/bin/activate

# Install PRAW
pip install praw
```

**Alternative: Install with --user flag**
```bash
pip3 install --user praw
```

**Note**: Modern Python installations on macOS may require using a virtual environment or the `--user` flag to avoid "externally-managed-environment" errors.

### 2. Create Reddit App

1. Go to [Reddit App Preferences](https://www.reddit.com/prefs/apps)
2. Click "create another app"
3. Set type to "script"
4. Note your credentials:
   - `client_id` (the string under your app name)
   - `client_secret` (the "secret" field)
   - `username` (your Reddit username)
   - `password` (your Reddit password)

### 3. Configure Credentials

Create a `reddit_credentials.json` file in your Scriptorium config directory:

```json
{
  "client_id": "YOUR_CLIENT_ID_HERE",
  "client_secret": "YOUR_CLIENT_SECRET_HERE", 
  "username": "YOUR_REDDIT_USERNAME",
  "password": "YOUR_REDDIT_PASSWORD",
  "user_agent": "scriptorium:autopost:v1.0 (by /u/YOUR_USERNAME)",
  "default_subreddit": "YOUR_DEFAULT_SUBREDDIT"
}
```

**Security Note**: Keep this file secure and never commit it to version control.

## Usage

### Basic Autoposting

```ruby
# In your Scriptorium code
post_data = {
  title: "My Blog Post Title",
  url: "https://myblog.com/posts/my-post.html",
  content: "Post content or excerpt",
  subreddit: "programming"  # Optional, uses default if not specified
}

# Autopost to Reddit
success = repo.autopost_to_reddit(post_data)
```

### Check Configuration

```ruby
# Check if Reddit integration is configured
if repo.reddit_configured?
  puts "Reddit integration is ready"
else
  puts "Reddit integration not configured"
end
```

### Get Reddit Configuration

```ruby
# Access Reddit configuration
config = repo.reddit.config
puts "Using Reddit account: #{config['username']}"
```

## API Reference

### Scriptorium::Reddit

#### `new(repo)`
Creates a new Reddit integration instance.

#### `autopost(post_data, subreddit = nil)`
Autoposts content to Reddit.

**Parameters:**
- `post_data` (Hash): Post information
  - `title` (String): Post title (required)
  - `url` (String): Post URL (required)
  - `content` (String): Post content or excerpt
  - `subreddit` (String): Target subreddit
- `subreddit` (String): Override subreddit (optional)

**Returns:** `true` on success, `false` on failure

#### `configured?`
Checks if Reddit integration is properly configured.

**Returns:** `true` if credentials and Python script exist

#### `config`
Gets the parsed Reddit configuration.

**Returns:** Hash with credentials or `nil` if not configured

### Scriptorium::Repo

#### `reddit`
Gets the Reddit integration instance (lazy-loaded).

#### `autopost_to_reddit(post_data, subreddit = nil)`
Convenience method for autoposting.

#### `reddit_configured?`
Convenience method to check Reddit configuration.

## Error Handling

The integration includes comprehensive error handling:

- **Missing credentials**: Raises `FileNotFound` exception
- **Missing Python script**: Raises `FileNotFound` exception
- **Invalid JSON**: Returns `nil` for config, logs error
- **API failures**: Returns `false`, logs error details
- **Temporary file cleanup**: Automatic cleanup in all cases

## Testing

Run the Reddit integration tests:

```bash
ruby test/unit/reddit_test.rb
```

The tests cover:
- Initialization and configuration
- Credentials management
- Error handling
- Temporary file cleanup
- Integration with Repo class

## Security Considerations

1. **Credentials Storage**: Store credentials securely and never commit to version control
2. **User Agent**: Use a descriptive user agent string as required by Reddit
3. **Rate Limiting**: PRAW handles Reddit's rate limiting automatically
4. **Permissions**: Only request necessary permissions for your app

## Troubleshooting

### Common Issues

1. **"Reddit credentials file not found"**
   - Ensure `reddit_credentials.json` exists in your config directory
   - Check file permissions

2. **"Reddit autopost Python script not found"**
   - Ensure `scripts/reddit_autopost.py` exists
   - Check that Python 3 is installed

3. **Authentication failures**
   - Verify your Reddit credentials are correct
   - Check that your Reddit app is properly configured
   - Ensure your Reddit account has the necessary permissions

4. **Subreddit posting failures**
   - Verify the subreddit exists and is accessible
   - Check subreddit posting rules and restrictions
   - Ensure your account meets subreddit posting requirements

### Debug Mode

Enable debug logging by setting the log level in your Scriptorium configuration.

## Future Enhancements

Potential improvements for the Reddit integration:

1. **Comment posting**: Support for posting comments on submissions
2. **Crossposting**: Support for crossposting to multiple subreddits
3. **Scheduling**: Delayed posting capabilities
4. **Analytics**: Track post performance and engagement
5. **Moderation**: Pre-posting content validation and filtering 