# 8. Advanced Features

Scriptorium includes several advanced features that extend its functionality beyond basic blogging. These features help you integrate with external platforms and enhance your site's social presence.

## Reddit Integration

Scriptorium includes built-in Reddit integration that allows you to automatically share your blog posts to Reddit. This feature helps increase your content's visibility and drive traffic to your site.

### Setting up Reddit integration

Before you can use Reddit integration, you need to create a Reddit application and configure your credentials:

1. **Create a Reddit application**:
   - Go to https://www.reddit.com/prefs/apps
   - Click "Create App" or "Create Another App"
   - Choose "script" as the application type
   - Fill in the required fields (name, description, redirect URI)
   - Note your client ID and client secret

2. **Configure Reddit credentials**:
   ```bash
   scriptorium edit config/reddit.json
   ```

3. **Add your Reddit credentials** to the configuration file:
   ```json
   {
     "client_id": "your_client_id_here",
     "client_secret": "your_client_secret_here",
     "username": "your_reddit_username",
     "password": "your_reddit_password",
     "user_agent": "scriptorium-bot/1.0"
   }
   ```

4. **Set appropriate permissions** for the configuration file:
   ```bash
   chmod 600 config/reddit.json
   ```

### Using Reddit integration

Once configured, you can automatically post to Reddit when you publish blog posts:

1. **Add Reddit metadata** to your blog posts:
   ```
   .title My Blog Post Title
   .reddit_subreddit programming
   .reddit_title My Blog Post Title
   .reddit_flair "Discussion"
   ```

2. **Available Reddit metadata**:
   - `.reddit_subreddit`: Target subreddit (e.g., "programming", "webdev")
   - `.reddit_title`: Custom title for Reddit (optional, uses post title if not specified)
   - `.reddit_flair`: Post flair (optional)
   - `.reddit_nsfw`: Mark as NSFW (true/false)
   - `.reddit_spoiler`: Mark as spoiler (true/false)

3. **Publish your post**:
   ```bash
   scriptorium publish 001
   ```

4. **The post will automatically be shared** to Reddit with the specified metadata

### Reddit integration best practices

- **Choose appropriate subreddits**: Target subreddits relevant to your content
- **Follow subreddit rules**: Ensure your content complies with each subreddit's guidelines
- **Use descriptive titles**: Make your Reddit titles compelling and accurate
- **Engage with comments**: Respond to comments on your Reddit posts
- **Don't spam**: Avoid posting too frequently to the same subreddits
- **Respect rate limits**: Reddit has API rate limits, so don't post too many times in quick succession

### Troubleshooting Reddit integration

Common issues and solutions:

- **Authentication errors**: Verify your credentials in `config/reddit.json`
- **Rate limiting**: Wait before posting again if you hit rate limits
- **Subreddit not found**: Check that the subreddit name is correct and exists
- **Permission denied**: Ensure your Reddit account has permission to post to the target subreddit

## Social Media Features

Scriptorium includes several features to enhance your social media presence and make your content more shareable.

### Social media metadata

Add social media metadata to your posts to improve how they appear when shared:

```
.title My Blog Post Title
.og_title My Blog Post Title
.og_description A compelling description of my blog post
.og_image /assets/my-featured-image.jpg
.twitter_card summary_large_image
.twitter_title My Blog Post Title
.twitter_description A compelling description for Twitter
.twitter_image /assets/my-featured-image.jpg
```

### Open Graph tags

Open Graph tags control how your content appears when shared on Facebook, LinkedIn, and other platforms:

- **`.og_title`**: Title for social media shares
- **`.og_description`**: Description for social media shares
- **`.og_image`**: Featured image for social media shares
- **`.og_type`**: Content type (article, website, etc.)
- **`.og_url`**: Canonical URL for the content

### Twitter Card tags

Twitter Card tags optimize your content for Twitter sharing:

- **`.twitter_card`**: Card type (summary, summary_large_image, app, player)
- **`.twitter_title`**: Title for Twitter shares
- **`.twitter_description`**: Description for Twitter shares
- **`.twitter_image`**: Image for Twitter shares
- **`.twitter_site`**: Your Twitter username
- **`.twitter_creator`**: Content creator's Twitter username

### Social sharing buttons

Add social sharing buttons to your posts:

1. **Configure social sharing** in your theme:
   ```bash
   scriptorium edit themes/my-theme/templates/post.lt3
   ```

2. **Add sharing buttons** to your post template:
   ```html
   <div class="social-share">
     <a href="https://twitter.com/intent/tweet?url=%{post.url}&text=%{post.title}" target="_blank">Share on Twitter</a>
     <a href="https://www.facebook.com/sharer/sharer.php?u=%{post.url}" target="_blank">Share on Facebook</a>
     <a href="https://www.linkedin.com/sharing/share-offsite/?url=%{post.url}" target="_blank">Share on LinkedIn</a>
   </div>
   ```

### RSS feeds

Scriptorium automatically generates RSS feeds for your content:

- **Main RSS feed**: `your-site.com/feed.xml`
- **Category-specific feeds**: `your-site.com/category/feed.xml`
- **Tag-specific feeds**: `your-site.com/tag/feed.xml`

### Email subscriptions

Set up email subscriptions for your blog:

1. **Configure email settings**:
   ```bash
   scriptorium edit config/email.txt
   ```

2. **Add subscription form** to your site:
   ```html
   <form action="/subscribe" method="post">
     <input type="email" name="email" placeholder="Enter your email">
     <button type="submit">Subscribe</button>
   </form>
   ```

### Analytics integration

Track your site's performance with analytics:

1. **Google Analytics**:
   ```bash
   scriptorium edit config/analytics.txt
   ```
   
   Add your Google Analytics tracking code:
   ```
   GA_TRACKING_ID: UA-XXXXXXXXX-X
   ```

2. **Other analytics services**:
   - Add tracking codes to your theme's header template
   - Configure privacy settings and cookie consent
   - Set up conversion tracking

### Social media automation

Automate your social media presence:

1. **Scheduled posting**: Set up automated posting to social platforms
2. **Cross-platform sharing**: Share content across multiple platforms simultaneously
3. **Content recycling**: Automatically reshare older content
4. **Engagement tracking**: Monitor likes, shares, and comments

### Best practices for social media

- **Consistent branding**: Use consistent colors, fonts, and imagery across platforms
- **Engage with your audience**: Respond to comments and messages
- **Post regularly**: Maintain a consistent posting schedule
- **Use hashtags strategically**: Research and use relevant hashtags
- **Monitor performance**: Track which content performs best
- **Optimize for each platform**: Tailor content for different social media platforms

### Privacy and security considerations

When using social media features:

- **Protect personal information**: Be careful with personal data in social media metadata
- **Use HTTPS**: Ensure your site uses HTTPS for secure sharing
- **Respect user privacy**: Implement appropriate privacy policies
- **Secure API keys**: Keep social media API keys and credentials secure
- **Monitor for abuse**: Watch for spam or inappropriate use of your social features

### Troubleshooting social media features

Common issues and solutions:

- **Images not appearing**: Check image paths and ensure images are publicly accessible
- **Metadata not updating**: Clear social media cache or use debugging tools
- **Sharing buttons not working**: Verify JavaScript is enabled and URLs are correct
- **Analytics not tracking**: Check tracking code installation and ad blockers

Advanced features in Scriptorium help you extend your reach beyond your blog and engage with audiences across multiple platforms. These features are designed to work seamlessly with your existing content while providing powerful tools for social media management and audience growth. 