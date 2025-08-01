# Scriptorium Dependencies & Requirements

This document lists the external dependencies and configuration requirements for different Scriptorium features.

## Core Dependencies

### Required for All Features
- **Ruby** (2.7+) - Core runtime
- **Git** - Version control (for repository management)

## Feature-Specific Dependencies & Requirements

### Reddit Integration
**Features**: Reddit autoposting, Reddit button generation

**Software Dependencies**:
- **Python 3** (3.7+) - Runtime for Reddit API scripts
- **PRAW** - Python Reddit API Wrapper
  ```bash
  pip3 install praw
  ```

**Configuration Requirements**:
- **Reddit App** - Create app at https://www.reddit.com/prefs/apps
- **API Credentials** - client_id, client_secret, username, password
- **Credentials File** - `config/reddit_credentials.json` with proper format
- **User Agent** - Descriptive user agent string (required by Reddit)

**Installation Notes**:
- On macOS: `brew install python3` (recommended)
- On Ubuntu/Debian: `sudo apt install python3 python3-pip`
- On Windows: Download from python.org or use Chocolatey

### LiveText Integration
**Features**: LiveText plugin support, file statistics

**Dependencies**:
- **LiveText** - LiveText gem and runtime
  ```bash
  gem install livetext
  ```

### Web Development Features
**Features**: Web server, JavaScript serving, browser integration

**Dependencies**:
- **Webrick** - Ruby web server (usually included with Ruby)
- **Default browser** - System default web browser

### File Operations
**Features**: File editing, directory operations

**Dependencies**:
- **Text editor** - One of:
  - `ed` (Unix/Linux/macOS) - Minimal editor for automation
  - `nano` - Simple text editor
  - `vim` - Advanced text editor
  - `emacs` - Advanced text editor
  - System default editor

### Image Processing
**Features**: Image optimization, thumbnail generation

**Dependencies**:
- **ImageMagick** - Image processing library
  ```bash
  # macOS
  brew install imagemagick
  
  # Ubuntu/Debian
  sudo apt install imagemagick
  
  # Windows
  # Download from imagemagick.org
  ```

### Markdown Processing
**Features**: Markdown rendering, syntax highlighting

**Dependencies**:
- **Pygments** - Syntax highlighting (optional)
  ```bash
  pip3 install pygments
  ```

### RSS/Atom Feeds
**Features**: RSS feed generation, feed validation

**Software Dependencies**:
- **Feed validator** (optional) - For feed validation
  ```bash
  pip3 install feedvalidator
  ```

### Deployment
**Features**: Deploy blog to web server

**Software Dependencies**:
- **SSH client** - For server access (usually included with OS)
- **rsync** - For file synchronization (usually included with OS)

**Configuration Requirements**:
- **SSH Keys** - Set up SSH key authentication for server access
- **Server Access** - Valid server credentials and permissions
- **Deployment Config** - Server details in `config/deploy.txt`
- **Domain/DNS** - Domain name pointing to server (optional)
- **SSL Certificate** - HTTPS certificate for secure access (optional)

**Setup Steps**:
1. Generate SSH key pair: `ssh-keygen -t rsa -b 4096`
2. Add public key to server: `ssh-copy-id user@server`
3. Test connection: `ssh user@server`
4. Configure deployment settings in Scriptorium

## Platform-Specific Dependencies

### macOS
- **Homebrew** (recommended) - Package manager
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
- **Xcode Command Line Tools** - For compilation
  ```bash
  xcode-select --install
  ```

### Linux (Ubuntu/Debian)
- **Build essentials** - For compilation
  ```bash
  sudo apt update
  sudo apt install build-essential
  ```

### Windows
- **RubyInstaller** - Ruby for Windows
- **Git for Windows** - Git integration
- **WSL** (optional) - Windows Subsystem for Linux

## Installation Scripts

### Quick Setup Scripts

#### macOS (with Homebrew)
```bash
#!/bin/bash
# Install core dependencies
brew install ruby git python3

# Install Python packages
pip3 install praw pygments feedvalidator

# Install Ruby gems
gem install livetext

# Install ImageMagick (if needed)
brew install imagemagick
```

#### Ubuntu/Debian
```bash
#!/bin/bash
# Update package list
sudo apt update

# Install core dependencies
sudo apt install ruby ruby-dev git python3 python3-pip build-essential

# Install Python packages
pip3 install praw pygments feedvalidator

# Install Ruby gems
gem install livetext

# Install ImageMagick (if needed)
sudo apt install imagemagick
```

## Feature Dependency Matrix

### Software Dependencies
| Feature | Ruby | Git | Python3 | PRAW | LiveText | ImageMagick | Editor |
|---------|------|-----|---------|------|----------|-------------|---------|
| Core Blogging | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Reddit Button | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Reddit Autopost | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| LiveText Plugins | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| File Statistics | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Web Server | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Image Processing | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Markdown + Syntax | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| RSS Feeds | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| File Editing | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Deployment | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

### Configuration Requirements
| Feature | Reddit Credentials | SSH Keys | Server Access | Domain/DNS | SSL Cert |
|---------|-------------------|----------|---------------|------------|----------|
| Core Blogging | ❌ | ❌ | ❌ | ❌ | ❌ |
| Reddit Button | ❌ | ❌ | ❌ | ❌ | ❌ |
| Reddit Autopost | ✅ | ❌ | ❌ | ❌ | ❌ |
| LiveText Plugins | ❌ | ❌ | ❌ | ❌ | ❌ |
| File Statistics | ❌ | ❌ | ❌ | ❌ | ❌ |
| Web Server | ❌ | ❌ | ❌ | ❌ | ❌ |
| Image Processing | ❌ | ❌ | ❌ | ❌ | ❌ |
| Markdown + Syntax | ❌ | ❌ | ❌ | ❌ | ❌ |
| RSS Feeds | ❌ | ❌ | ❌ | ❌ | ❌ |
| File Editing | ❌ | ❌ | ❌ | ❌ | ❌ |
| Deployment | ❌ | ✅ | ✅ | ⚠️ | ⚠️ |

## Verification Commands

### Check Core Dependencies
```bash
# Check Ruby
ruby --version

# Check Git
git --version

# Check Python 3
python3 --version
```

### Check Feature Dependencies
```bash
# Check PRAW (Reddit integration)
python3 -c "import praw; print('PRAW available')"

# Check LiveText
livetext --version

# Check ImageMagick
convert --version

# Check Pygments
python3 -c "import pygments; print('Pygments available')"
```

### Check Configuration Requirements
```bash
# Check Reddit credentials
ls -la config/reddit_credentials.json

# Check SSH key setup
ls -la ~/.ssh/id_rsa.pub

# Test SSH connection (replace with your server)
ssh -T user@your-server.com

# Check deployment configuration
ls -la config/deploy.txt

# Check domain resolution (replace with your domain)
nslookup your-domain.com
```

## Troubleshooting

### Common Issues

1. **Python not found**
   - Ensure Python 3 is installed and in PATH
   - On macOS, use `brew install python3`

2. **PRAW installation fails**
   - Upgrade pip: `pip3 install --upgrade pip`
   - Install with user flag: `pip3 install --user praw`

3. **LiveText not found**
   - Install via gem: `gem install livetext`
   - Check Ruby version compatibility

4. **ImageMagick not working**
   - Verify installation: `convert --version`
   - Check PATH and permissions

### Getting Help

- Check the specific feature documentation
- Run the verification commands above
- Check system logs for error messages
- Ensure all dependencies are properly installed and in PATH 