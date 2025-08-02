# 10. Troubleshooting

Even with the best setup, you may encounter issues while using Scriptorium. This section covers common problems and their solutions, helping you quickly resolve issues and get back to creating content.

## Common Issues

### Site generation problems

#### Site won't generate

**Symptoms**: Running `scriptorium generate` fails or produces errors.

**Possible causes and solutions**:

1. **Missing dependencies**:
   ```bash
   # Check if Ruby and required gems are installed
   ruby --version
   gem list
   
   # Reinstall Scriptorium if needed
   gem uninstall scriptorium
   gem install scriptorium
   ```

2. **Corrupted repository**:
   ```bash
   # Check repository integrity
   scriptorium status
   
   # If corrupted, restore from backup or recreate
   cp -r .scriptorium .scriptorium.backup
   scriptorium init
   ```

3. **Permission issues**:
   ```bash
   # Check file permissions
   ls -la
   
   # Fix permissions if needed
   chmod 755 .
   chmod 644 *.txt *.md *.lt3
   ```

#### Posts not appearing

**Symptoms**: Posts exist but don't show up on the site.

**Solutions**:

1. **Check post status**:
   ```bash
   scriptorium list posts
   ```

2. **Verify post is linked to current view**:
   ```bash
   scriptorium post 001
   # Check the "views" field
   ```

3. **Link post to view if needed**:
   ```bash
   scriptorium link 001
   ```

4. **Regenerate the site**:
   ```bash
   scriptorium generate
   ```

#### Images not displaying

**Symptoms**: Images appear broken or don't load.

**Solutions**:

1. **Check image paths**:
   ```bash
   # Verify image exists
   ls -la assets/images/
   
   # Check path in post
   scriptorium edit posts/001.lt3
   ```

2. **Correct image references**:
   ```
   # Use relative paths from the post
   ![Alt text](assets/images/my-image.jpg)
   
   # Or absolute paths from site root
   ![Alt text](/assets/images/my-image.jpg)
   ```

3. **Ensure images are in the correct directory**:
   ```bash
   # Move images to assets directory
   mv my-image.jpg assets/images/
   ```

### Widget issues

#### Widget not appearing

**Symptoms**: Widget is configured but doesn't show on the site.

**Solutions**:

1. **Check widget configuration**:
   ```bash
   scriptorium edit widgets/links/list.txt
   # Verify the file exists and has content
   ```

2. **Generate the widget**:
   ```bash
   scriptorium generate widget links
   ```

3. **Check layout configuration**:
   ```bash
   scriptorium edit config/layout.txt
   # Ensure sidebar containers are defined
   
   scriptorium edit config/left.txt
   # Ensure widget is referenced
   ```

4. **Regenerate the entire site**:
   ```bash
   scriptorium generate
   ```

#### Widget content not updating

**Symptoms**: Changes to widget configuration don't appear on the site.

**Solutions**:

1. **Regenerate the specific widget**:
   ```bash
   scriptorium generate widget widget-name
   ```

2. **Clear any caching**:
   ```bash
   # Remove generated files
   rm -rf output/
   scriptorium generate
   ```

### Theme and styling issues

#### Theme not applying

**Symptoms**: Site doesn't use the expected theme.

**Solutions**:

1. **Check theme configuration**:
   ```bash
   scriptorium edit config.txt
   # Verify theme: theme-name is set correctly
   ```

2. **Verify theme exists**:
   ```bash
   ls -la themes/
   # Ensure the theme directory exists
   ```

3. **Apply theme explicitly**:
   ```bash
   scriptorium theme theme-name
   ```

#### CSS not loading

**Symptoms**: Site appears unstyled or with broken styling.

**Solutions**:

1. **Check CSS file paths**:
   ```bash
   ls -la themes/standard/layout/gen/
   # Verify CSS files exist
   ```

2. **Regenerate theme**:
   ```bash
   scriptorium generate
   # This should regenerate CSS files
   ```

3. **Check browser cache**:
   - Hard refresh (Ctrl+F5 or Cmd+Shift+R)
   - Clear browser cache
   - Try incognito/private browsing mode

## Dependency Management

### Ruby version issues

**Symptoms**: Scriptorium fails to run or has compatibility issues.

**Solutions**:

1. **Check Ruby version**:
   ```bash
   ruby --version
   # Scriptorium requires Ruby 2.7 or higher
   ```

2. **Update Ruby if needed**:
   ```bash
   # Using rbenv
   rbenv install 3.2.0
   rbenv global 3.2.0
   
   # Using rvm
   rvm install 3.2.0
   rvm use 3.2.0 --default
   ```

3. **Reinstall gems**:
   ```bash
   gem update
   gem install scriptorium
   ```

### Gem conflicts

**Symptoms**: Scriptorium conflicts with other Ruby gems.

**Solutions**:

1. **Use bundler**:
   ```bash
   # Create Gemfile
   echo 'gem "scriptorium"' > Gemfile
   
   # Install with bundler
   bundle install
   bundle exec scriptorium
   ```

2. **Use gem isolation**:
   ```bash
   # Install in user directory
   gem install --user-install scriptorium
   ```

3. **Check gem environment**:
   ```bash
   gem env
   # Verify gem paths and versions
   ```

### System dependencies

**Symptoms**: Scriptorium fails due to missing system libraries.

**Solutions**:

1. **Install development tools**:
   ```bash
   # Ubuntu/Debian
   sudo apt install build-essential
   
   # macOS
   xcode-select --install
   
   # CentOS/RHEL
   sudo yum groupinstall "Development Tools"
   ```

2. **Install specific libraries**:
   ```bash
   # Ubuntu/Debian
   sudo apt install libssl-dev libreadline-dev zlib1g-dev
   
   # CentOS/RHEL
   sudo yum install openssl-devel readline-devel zlib-devel
   ```

## Error Messages

### Common error messages and solutions

#### "Cannot read file: file not found"

**Cause**: Scriptorium can't find a required file.

**Solution**:
```bash
# Check if file exists
ls -la path/to/file

# Create missing file if needed
touch path/to/file

# Check file permissions
chmod 644 path/to/file
```

#### "Cannot build widget: name invalid"

**Cause**: Widget name contains invalid characters.

**Solution**:
```bash
# Use only lowercase letters, numbers, and hyphens
# Good: my-widget, links, pages
# Bad: My_Widget, links!, pages@
```

#### "Layout has unknown tag"

**Cause**: Layout file contains unrecognized container names.

**Solution**:
```bash
# Check layout file
scriptorium edit config/layout.txt

# Valid containers: header, main, left, right, footer
# Remove or correct invalid container names
```

#### "Theme doesn't exist"

**Cause**: Referenced theme is not found.

**Solution**:
```bash
# List available themes
ls -la themes/

# Check theme configuration
scriptorium edit config.txt

# Use existing theme or create new one
scriptorium theme standard
```

#### "Post not found"

**Cause**: Referenced post ID doesn't exist.

**Solution**:
```bash
# List all posts
scriptorium list posts

# Check post ID format
# Posts should be numbered: 001, 002, etc.

# Create post if needed
scriptorium new post "Post Title"
```

### Debugging techniques

#### Enable verbose output

```bash
# Run commands with verbose output
scriptorium generate --verbose

# Check for detailed error messages
scriptorium status --verbose
```

#### Check log files

```bash
# Look for error logs
find . -name "*.log" -exec cat {} \;

# Check system logs
tail -f /var/log/syslog  # Linux
tail -f /var/log/system.log  # macOS
```

#### Test individual components

```bash
# Test post generation
scriptorium generate post 001

# Test widget generation
scriptorium generate widget links

# Test theme application
scriptorium theme standard
```

## Getting Help

### Self-help resources

1. **Check the documentation**:
   - Review relevant sections of this user guide
   - Check the README file in your Scriptorium installation
   - Look for examples in the test directory

2. **Use built-in help**:
   ```bash
   scriptorium --help
   scriptorium help command-name
   ```

3. **Check the source code**:
   ```bash
   # Find Scriptorium installation
   gem which scriptorium
   
   # Explore the source
   ls -la $(gem which scriptorium | sed 's/lib\/scriptorium.rb//')
   ```

### Community resources

1. **GitHub repository**:
   - Check issues for similar problems
   - Review recent commits for fixes
   - Submit new issues for bugs

2. **Documentation**:
   - Check the project wiki
   - Review example configurations
   - Look for community-contributed guides

3. **Forums and discussions**:
   - Search for Scriptorium discussions
   - Ask questions in relevant communities
   - Share solutions with others

### Reporting bugs

When reporting bugs, include:

1. **System information**:
   ```bash
   ruby --version
   gem list scriptorium
   uname -a
   ```

2. **Steps to reproduce**:
   - Exact commands run
   - Expected vs. actual behavior
   - Any error messages

3. **Configuration details**:
   - Relevant configuration files
   - Post content (if relevant)
   - Theme and widget setup

4. **Error logs**:
   - Full error messages
   - Stack traces
   - Debug output

### Getting support

1. **Before asking for help**:
   - Try the solutions in this section
   - Search for similar issues
   - Check if the problem is user error

2. **When asking for help**:
   - Be specific about the problem
   - Include relevant error messages
   - Provide system and configuration details
   - Explain what you've already tried

3. **Follow up**:
   - Let people know if their suggestions worked
   - Share solutions that worked for you
   - Help others with similar problems

### Prevention tips

1. **Regular backups**:
   ```bash
   # Backup your Scriptorium repository
   tar -czf scriptorium-backup-$(date +%Y%m%d).tar.gz .
   ```

2. **Version control**:
   ```bash
   # Use git for version control
   git init
   git add .
   git commit -m "Initial commit"
   ```

3. **Test changes**:
   ```bash
   # Test changes before applying
   scriptorium generate --dry-run
   
   # Keep a test environment
   cp -r . test-environment
   ```

4. **Document your setup**:
   - Keep notes on your configuration
   - Document customizations
   - Record solutions to problems

By following these troubleshooting steps and best practices, you can quickly resolve most issues and maintain a stable Scriptorium installation. 