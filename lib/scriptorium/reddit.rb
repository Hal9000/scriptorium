require 'json'
require 'tempfile'
require_relative 'exceptions'
require_relative 'helpers'

module Scriptorium
  class Reddit
    include Scriptorium::Exceptions
    include Scriptorium::Helpers

    def initialize(repo)
      @repo = repo
      @credentials_file = @repo.dir/:config/"reddit_credentials.json"
      @python_script = File.join(File.dirname(__FILE__), '..', '..', 'scripts', 'reddit_autopost.py')
      @python_env = find_python_environment
    end

    # Autopost a post to Reddit
    def autopost(post_data, subreddit = nil)
      need(:file, @credentials_file, "Reddit credentials file not found")
      need(:file, @python_script, "Reddit autopost Python script not found")

      # Prepare post data for Python script
      temp_file = write_temp_post_data(post_data)
      
      begin
        # Call Python script with PRAW using the appropriate Python environment
        python_cmd = @python_env ? [@python_env, @python_script] : ["python3", @python_script]
        result = system(*python_cmd, temp_file, subreddit.to_s, @credentials_file)
        
        if result
          @repo.log.info("Successfully autoposted to Reddit: #{post_data[:title]}")
          return true
        else
          @repo.log.error("Failed to autopost to Reddit: #{post_data[:title]}")
          return false
        end
      ensure
        # Clean up temporary file
        File.delete(temp_file) if File.exist?(temp_file)
      end
    end

    # Check if Reddit autoposting is configured
    def configured?
      File.exist?(@credentials_file) && File.exist?(@python_script)
    end

    # Get Reddit configuration
    def config
      return nil unless configured?
      
      begin
        JSON.parse(read_file(@credentials_file))
      rescue => e
        @repo.log.error("Failed to parse Reddit credentials: #{e.message}")
        nil
      end
    end

    private

    def find_python_environment
      # Check for Scriptorium virtual environment first
      venv_path = File.expand_path("~/.scriptorium-python/bin/python")
      return venv_path if File.exist?(venv_path)
      
      # Check for other common virtual environment locations
      common_venvs = [
        File.expand_path("~/.virtualenvs/scriptorium/bin/python"),
        File.expand_path("~/venv/scriptorium/bin/python"),
        File.expand_path("~/env/scriptorium/bin/python")
      ]
      
      common_venvs.each do |venv|
        return venv if File.exist?(venv)
      end
      
      # Fall back to system python3
      nil
    end

    def write_temp_post_data(post_data)
      temp_file = Tempfile.new(['reddit_post', '.json'])
      temp_file.write(JSON.generate({
        title: post_data[:title],
        url: post_data[:url],
        content: post_data[:content],
        subreddit: post_data[:subreddit]
      }))
      temp_file.close
      temp_file.path
    end
  end
end 