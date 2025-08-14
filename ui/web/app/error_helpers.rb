module ErrorHelpers
  # Error message mapping for common errors
  ERROR_MESSAGES = {
    'ReadFileNotFound' => {
      message: 'File not found',
      suggestion: 'The file may have been moved or deleted. Try refreshing the page or recreating the content.'
    },
    'PostRepoNil' => {
      message: 'Repository not initialized',
      suggestion: 'Please create or open a repository first.'
    },
    'PostNumNil' => {
      message: 'Invalid post ID',
      suggestion: 'Please provide a valid post number.'
    },
    'PostNumEmpty' => {
      message: 'Post ID is empty',
      suggestion: 'Please provide a valid post number.'
    },
    'PostNumInvalid' => {
      message: 'Invalid post ID format',
      suggestion: 'Post ID must be a number.'
    },
    'GetPostIdNil' => {
      message: 'Post ID not provided',
      suggestion: 'Please specify a post ID.'
    },
    'GetPostIdEmpty' => {
      message: 'Post ID is empty',
      suggestion: 'Please provide a valid post ID.'
    },
    'GetPostIdInvalid' => {
      message: 'Invalid post ID format',
      suggestion: 'Post ID must be a number.'
    },
    'EditFilePathNil' => {
      message: 'File path not specified',
      suggestion: 'Please provide a valid file path.'
    },
    'EditFilePathEmpty' => {
      message: 'File path is empty',
      suggestion: 'Please provide a valid file path.'
    },
    'RepoDirAlreadyExists' => {
      message: 'Repository already exists',
      suggestion: 'The repository directory already exists. You can open it instead.'
    },
    'LookupViewTargetNil' => {
      message: 'View not specified',
      suggestion: 'Please provide a valid view name.'
    },
    'ViewNameNil' => {
      message: 'View name not provided',
      suggestion: 'Please provide a view name.'
    },
    'ViewNameEmpty' => {
      message: 'View name is empty',
      suggestion: 'Please provide a view name.'
    },
    'ViewTitleNil' => {
      message: 'View title not provided',
      suggestion: 'Please provide a view title.'
    },
    'ViewTitleEmpty' => {
      message: 'View title is empty',
      suggestion: 'Please provide a view title.'
    },
    'ViewNameInvalid' => {
      message: 'Invalid view name',
      suggestion: 'View names can only contain letters, numbers, hyphens (-), and underscores (_).'
    }
  }

  # Get a user-friendly error message
  def friendly_error_message(error)
    error_class = error.class.name
    error_message = error.message
    
    if ERROR_MESSAGES[error_class]
      {
        message: ERROR_MESSAGES[error_class][:message],
        suggestion: ERROR_MESSAGES[error_class][:suggestion],
        details: error_message
      }
    else
      {
        message: 'An unexpected error occurred',
        suggestion: 'Please try again or contact support if the problem persists.',
        details: error_message
      }
    end
  end

  # Validate required parameters
  def validate_required_params(params, *required_keys)
    missing = required_keys.select { |key| params[key].nil? || params[key].to_s.strip.empty? }
    
    if missing.any?
      raise ArgumentError.new("Missing required parameters: #{missing.join(', ')}")
    end
  end

  # Validate post ID
  def validate_post_id(post_id)
    return false if post_id.nil?
    return false unless post_id.to_s.match?(/^\d+$/)
    return false if post_id.to_i <= 0
    true
  end

  # Validate view name
  def validate_view_name(name)
    return false if name.nil?
    return false if name.to_s.strip.empty?
    return false unless name.to_s.match?(/^[a-zA-Z0-9_-]+$/)
    true
  end

  # Safe file operations
  def safe_read_file(path, default_content = "")
    return default_content unless File.exist?(path)
    File.read(path)
  rescue => e
    puts "Error reading file #{path}: #{e.message}" if $DEBUG
    default_content
  end

  def safe_write_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    true
  rescue => e
    puts "Error writing file #{path}: #{e.message}" if $DEBUG
    false
  end

  # Format error for display
  def format_error_display(error_info)
    html = "<div class='error-details'>"
    html += "<strong>#{error_info[:message]}</strong><br>"
    html += "<em>#{error_info[:suggestion]}</em>"
    
    if error_info[:details] && error_info[:details] != error_info[:message]
      html += "<br><small>Technical details: #{error_info[:details]}</small>"
    end
    
    html += "</div>"
    html
  end
end 