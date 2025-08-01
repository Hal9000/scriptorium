#!/usr/bin/env ruby
# Scriptorium Dependency Checker
# Run this script to check what dependencies are available for different features

require 'open3'

class DependencyChecker
  def initialize
    @results = {}
    @features = {
      'Core Blogging' => ['ruby', 'git'],
      'Reddit Button' => ['ruby', 'git'],
      'Reddit Autopost' => ['ruby', 'git', 'python3', 'praw', 'reddit_creds'],
      'LiveText Plugins' => ['ruby', 'git', 'livetext'],
      'File Statistics' => ['ruby', 'git', 'livetext'],
      'Web Server' => ['ruby', 'git'],
      'Image Processing' => ['ruby', 'git', 'imagemagick'],
      'Markdown + Syntax' => ['ruby', 'git', 'python3', 'pygments'],
      'RSS Feeds' => ['ruby', 'git', 'python3', 'feedvalidator'],
      'File Editing' => ['ruby', 'git', 'editor'],
      'Deployment' => ['ruby', 'git', 'ssh_keys', 'server_access']
    }
  end

  def check_all
    puts "🔍 Scriptorium Dependency Checker"
    puts "=" * 50
    puts

    check_core_dependencies
    check_feature_dependencies
    print_results
  end

  private

  def check_core_dependencies
    puts "Checking core dependencies..."
    
    @results['ruby'] = check_command('ruby --version')
    @results['git'] = check_command('git --version')
    @results['python3'] = check_command('python3 --version')
    
    puts
  end

  def check_feature_dependencies
    puts "Checking feature-specific dependencies..."
    
    # Check Python packages
    @results['praw'] = check_python_package('praw')
    @results['pygments'] = check_python_package('pygments')
    @results['feedvalidator'] = check_python_package('feedvalidator')
    
    # Check Ruby gems
    @results['livetext'] = check_ruby_gem('livetext')
    
    # Check system tools
    @results['imagemagick'] = check_command('convert --version')
    @results['editor'] = check_editor
    
    # Check configuration requirements
    @results['reddit_creds'] = check_reddit_credentials
    @results['ssh_keys'] = check_ssh_keys
    @results['server_access'] = check_server_access
    
    puts
  end

  def check_command(command)
    stdout, stderr, status = Open3.capture3(command)
    status.success?
  end

  def check_python_package(package)
    # Try system python3 first
    command = "python3 -c \"import #{package}; print('#{package} available')\""
    stdout, stderr, status = Open3.capture3(command)
    return true if status.success?
    
    # Try Scriptorium virtual environment
    venv_python = File.expand_path("~/.scriptorium-python/bin/python")
    if File.exist?(venv_python)
      command = "#{venv_python} -c \"import #{package}; print('#{package} available')\""
      stdout, stderr, status = Open3.capture3(command)
      return true if status.success?
    end
    
    # Try other common virtual environments
    common_venvs = [
      File.expand_path("~/.virtualenvs/scriptorium/bin/python"),
      File.expand_path("~/venv/scriptorium/bin/python"),
      File.expand_path("~/env/scriptorium/bin/python")
    ]
    
    common_venvs.each do |venv|
      if File.exist?(venv)
        command = "#{venv} -c \"import #{package}; print('#{package} available')\""
        stdout, stderr, status = Open3.capture3(command)
        return true if status.success?
      end
    end
    
    false
  end

  def check_ruby_gem(gem_name)
    command = "#{gem_name} --version"
    stdout, stderr, status = Open3.capture3(command)
    status.success?
  end

  def check_editor
    editors = ['ed', 'nano', 'vim', 'emacs']
    editors.any? { |editor| check_command("#{editor} --version") }
  end

  def check_reddit_credentials
    # Check if reddit credentials file exists and is valid JSON
    creds_file = 'config/reddit_credentials.json'
    return false unless File.exist?(creds_file)
    
    begin
      require 'json'
      JSON.parse(File.read(creds_file))
      true
    rescue JSON::ParserError
      false
    end
  end

  def check_ssh_keys
    # Check if SSH key pair exists
    private_key = File.expand_path('~/.ssh/id_rsa')
    public_key = File.expand_path('~/.ssh/id_rsa.pub')
    File.exist?(private_key) && File.exist?(public_key)
  end

  def check_server_access
    # This is a basic check - user needs to configure their server details
    deploy_file = 'config/deploy.txt'
    File.exist?(deploy_file)
  end

  def print_results
    puts "📊 Dependency Status"
    puts "=" * 50
    puts

    # Print individual dependency status
    puts "Individual Dependencies:"
    puts "-" * 30
    
    dependencies = [
      ['Ruby', 'ruby'],
      ['Git', 'git'],
      ['Python 3', 'python3'],
      ['PRAW (Reddit API)', 'praw'],
      ['Pygments (Syntax Highlighting)', 'pygments'],
      ['Feed Validator', 'feedvalidator'],
      ['LiveText', 'livetext'],
      ['ImageMagick', 'imagemagick'],
      ['Text Editor', 'editor'],
      ['Reddit Credentials', 'reddit_creds'],
      ['SSH Keys', 'ssh_keys'],
      ['Server Access Config', 'server_access']
    ]

    dependencies.each do |name, key|
      status = @results[key] ? "✅ Available" : "❌ Missing"
      puts "#{name.ljust(25)} #{status}"
    end

    puts
    puts "Feature Availability:"
    puts "-" * 30

    @features.each do |feature, deps|
      available = deps.all? { |dep| @results[dep] }
      status = available ? "✅ Ready" : "❌ Missing Dependencies"
      puts "#{feature.ljust(20)} #{status}"
      
      unless available
        missing = deps.reject { |dep| @results[dep] }
        puts "   Missing: #{missing.join(', ')}"
      end
    end

    puts
    print_installation_guide
  end

  def print_installation_guide
    puts "📋 Installation Guide"
    puts "=" * 50
    puts

    missing = @results.reject { |k, v| v }.keys

    if missing.empty?
      puts "🎉 All dependencies are available! You can use all Scriptorium features."
      return
    end

    puts "Missing dependencies: #{missing.join(', ')}"
    puts

    if missing.include?('python3')
      puts "📦 Install Python 3:"
      puts "   macOS: brew install python3"
      puts "   Ubuntu/Debian: sudo apt install python3 python3-pip"
      puts "   Windows: Download from python.org"
      puts
    end

    if missing.include?('praw')
      puts "🐍 Install PRAW:"
      puts "   # Create virtual environment (recommended):"
      puts "   python3 -m venv ~/.scriptorium-python"
      puts "   source ~/.scriptorium-python/bin/activate"
      puts "   pip install praw"
      puts "   # OR use --user flag:"
      puts "   pip3 install --user praw"
      puts
    end

    if missing.include?('pygments')
      puts "🎨 Install Pygments:"
      puts "   pip3 install pygments"
      puts
    end

    if missing.include?('feedvalidator')
      puts "📰 Install Feed Validator:"
      puts "   pip3 install feedvalidator"
      puts
    end

    if missing.include?('livetext')
      puts "📝 Install LiveText:"
      puts "   gem install livetext"
      puts
    end

    if missing.include?('imagemagick')
      puts "🖼️  Install ImageMagick:"
      puts "   macOS: brew install imagemagick"
      puts "   Ubuntu/Debian: sudo apt install imagemagick"
      puts "   Windows: Download from imagemagick.org"
      puts
    end

    if missing.include?('editor')
      puts "✏️  Install a text editor:"
      puts "   macOS/Linux: ed, nano, vim, or emacs"
      puts "   Windows: Notepad, VS Code, or similar"
      puts
    end

    if missing.include?('reddit_creds')
      puts "🔑 Configure Reddit credentials:"
      puts "   1. Create Reddit app at https://www.reddit.com/prefs/apps"
      puts "   2. Create config/reddit_credentials.json"
      puts "   3. Add your API credentials"
      puts
    end

    if missing.include?('ssh_keys')
      puts "🔐 Set up SSH keys:"
      puts "   ssh-keygen -t rsa -b 4096"
      puts "   ssh-copy-id user@your-server.com"
      puts
    end

    if missing.include?('server_access')
      puts "🌐 Configure server access:"
      puts "   1. Create config/deploy.txt"
      puts "   2. Add server details and deployment settings"
      puts
    end

    puts "For more details, see: doc/dependencies.md"
  end
end

if __FILE__ == $0
  checker = DependencyChecker.new
  checker.check_all
end 