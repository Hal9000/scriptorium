#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/reloader' if development?
require 'fileutils'
require_relative '../../../lib/scriptorium'
require_relative 'error_helpers'

include ErrorHelpers

class ScriptoriumWeb < Sinatra::Base
  set :port, 4567
  set :bind, '0.0.0.0'
  set :views, File.join(__dir__, 'views')
  set :show_exceptions, false  # Disable Sinatra's default error display
  
  # Enable reloading in development
  configure :development do
    register Sinatra::Reloader
  end
  
  # Global error handler
  error do
    error_info = friendly_error_message(env['sinatra.error'])
    @error = error_info[:message]
    @suggestion = error_info[:suggestion]
    erb :error_page
  end

  # Initialize API instance
  before do
    begin
      @api = Scriptorium::API.new
      # Use absolute path to the test repository
      test_repo_path = File.join(__dir__, "..", "scriptorium-TEST")
      @api.open_repo(test_repo_path) if Dir.exist?(test_repo_path)
    rescue => e
      @api = nil
    end
  end
  
  # Main dashboard
  get '/' do
    @current_view = @api&.current_view
    @views = @api&.views || []
    begin
      if @api&.instance_variable_get(:@repo)
        
        # Only try to load posts if we have a current view
        if @current_view
          @posts = @api.posts(@current_view.name) || []
          if @posts.length > 0
          end
        else
          @posts = []
        end
      else
        @posts = []
      end
    rescue => e
      @posts = []
    end
    @error = @error || params[:error]
    @message = params[:message]
    
    erb :dashboard
  end
  
  # Change view
  post '/change_view' do
    view_name = params[:view_name]
    
    if view_name.nil? || view_name.strip.empty?
      redirect "/?error=No view selected"
      return
    end
    
    begin
      view = @api.lookup_view(view_name)
      @api.view(view_name)
      redirect '/?message=View changed successfully'
    rescue => e
      redirect "/?error=Failed to change view: #{e.message}"
    end
  end
  
  # Create new repository
  post '/create_repo' do
    begin
      @api.create_repo("scriptorium-TEST")
      # After creating, open the repo
      @api.open_repo("scriptorium-TEST")
      redirect '/?message=Repository created successfully'
    rescue => e
      redirect "/?error=Failed to create repository: #{e.message}"
    end
  end

  # Create new view
  post '/create_view' do
    begin
      validate_required_params(params, :name, :title)
      
      name = params[:name].strip
      title = params[:title].strip
      subtitle = params[:subtitle]&.strip || ""
      
      @api.create_view(name, title, subtitle, theme: "standard")
      redirect "/?message=View '#{name}' created successfully"
    rescue => e
      error_info = friendly_error_message(e)
      redirect "/?error=#{error_info[:message]}&suggestion=#{error_info[:suggestion]}"
    end
  end

  # Create new post
  post '/create_post' do
    begin
      validate_required_params(params, :title)
      
      current_view = @api&.current_view
      if current_view.nil?
        redirect "/?error=No view selected. Please select a view first."
        return
      end
      
      # Create a draft first
      draft_path = @api.create_draft(
        title: params[:title].strip,
        body: "",  # Empty body to start
        views: current_view.name,
        tags: nil,
        blurb: nil
      )
      
      # Convert draft to post immediately
      post_num = @api.finish_draft(draft_path)
      # Generate the post to create meta.txt and other files
      begin
        STDERR.puts "DEBUG: About to call generate_post for post #{post_num}"
        STDERR.puts "DEBUG: Current working directory: #{Dir.pwd}"
        STDERR.puts "DEBUG: API root: #{@api.root}"
        @api.generate_post(post_num)
        STDERR.puts "DEBUG: generate_post completed successfully"
        # Check if meta.txt was created
        meta_file = @api.root/"posts"/"#{post_num.to_s.rjust(4, '0')}"/"meta.txt"
        STDERR.puts "DEBUG: Meta file path: #{meta_file}"
        STDERR.puts "DEBUG: Meta file exists: #{File.exist?(meta_file)}"
        redirect "/?message=Post '#{params[:title].strip}' created successfully (##{post_num})"
              rescue => e
          # Log the actual error for debugging
          STDERR.puts "ERROR in generate_post: #{e.class}: #{e.message}"
          STDERR.puts e.backtrace.join("\n")
          error_info = friendly_error_message(e)
          redirect "/?error=#{error_info[:message]}&suggestion=#{error_info[:suggestion]}"
      end
    rescue => e
      error_info = friendly_error_message(e)
      redirect "/?error=#{error_info[:message]}&suggestion=#{error_info[:suggestion]}"
    end
  end

  # Edit post (redirects to file editing)
  post '/edit_post' do
    begin
      validate_required_params(params, :post_id)
      
      unless validate_post_id(params[:post_id])
        redirect "/?error=Invalid post ID&suggestion=Please provide a valid post number."
        return
      end
      
      post = @api.post(params[:post_id].to_i)
      if post.nil?
        redirect "/?error=Post not found&suggestion=The post may have been deleted or moved."
        return
      end
      
      # Redirect to the edit page
      redirect "/edit_post/#{params[:post_id]}"
    rescue => e
      error_info = friendly_error_message(e)
      redirect "/?error=#{error_info[:message]}&suggestion=#{error_info[:suggestion]}"
    end
  end

  # Show edit post page
  get '/edit_post/:id' do
    post_id = params[:id]&.to_i
    
    if post_id.nil? || post_id <= 0
      redirect "/?error=Invalid post ID"
      return
    end
    
    begin
      @post = @api.post(post_id)
      if @post.nil?
        redirect "/?error=Post not found"
        return
      end
      
      # Read the source file content
      source_file = @api.root/"posts"/@post.num/"source.lt3"
      if File.exist?(source_file)
        @content = File.read(source_file)
      else
        @content = "# #{@post.title}\n\n"
      end
      
      erb :edit_post
    rescue => e
      redirect "/?error=Failed to load post: #{e.message}"
    end
  end

  # Save edited post
  post '/save_post/:id' do
    post_id = params[:id]&.to_i
    content = params[:content]
    
    if post_id.nil? || post_id <= 0
      redirect "/?error=Invalid post ID"
      return
    end
    
    if content.nil?
      redirect "/edit_post/#{post_id}?error=No content provided"
      return
    end
    
    begin
      post = @api.post(post_id)
      if post.nil?
        redirect "/?error=Post not found"
        return
      end
      
      # Write the content to the source file
      source_file = @api.root/"posts"/post.num/"source.lt3"
      File.write(source_file, content)
      
      # Generate the post after saving
      @api.generate_post(post_id)
      
      redirect "/?message=Post ##{post_id} saved and generated successfully"
    rescue => e
      redirect "/edit_post/#{post_id}?error=Failed to save post: #{e.message}"
    end
    end

  # Generate post
  post '/generate_post' do
    post_id = params[:post_id]&.to_i
    
    if post_id.nil? || post_id <= 0
      redirect "/?error=Invalid post ID"
      return
    end
    
    begin
      post = @api.post(post_id)
      if post.nil?
        redirect "/?error=Post not found"
        return
      end
      
      # Generate the post
      @api.generate_post(post_id)
      redirect "/?message=Post ##{post_id} generated successfully"
    rescue => e
      redirect "/?error=Failed to generate post: #{e.message}"
    end
  end

  # Generate view
  post '/generate_view' do
    view_name = params[:view_name]
    
    begin
      if view_name.nil? || view_name.strip.empty?
        redirect "/?error=No view specified"
        return
      end
      
      # Generate the view
      @api.generate_view(view_name)
      redirect "/?message=View '#{view_name}' generated successfully"
    rescue => e
      redirect "/?error=Failed to generate view: #{e.message}"
    end
  end

  # Preview view
  post '/preview_view' do
    view_name = params[:view_name]
    
    begin
      if view_name.nil? || view_name.strip.empty?
        redirect "/?error=No view specified"
        return
      end
      
      # Generate the view first to ensure it's up to date
      @api.generate_view(view_name)
      
      # Redirect to the generated index.html file
      view_dir = @api.root/"views"/view_name
      index_file = view_dir/"output"/"index.html"
      
      if File.exist?(index_file)
        # Return the HTML content directly for preview
        content_type :html
        File.read(index_file)
      else
        redirect "/?error=Preview file not found - view may not have been generated properly"
      end
    rescue => e
      redirect "/?error=Failed to preview view: #{e.message}"
    end
  end

  # Serve post files for preview
  get '/preview/:view_name/posts/:filename' do
    view_name = params[:view_name]
    filename = params[:filename]
    
    STDERR.puts "DEBUG: Preview request - view_name: #{view_name}, filename: #{filename}"
    
    begin
      if view_name.nil? || view_name.strip.empty? || filename.nil? || filename.strip.empty?
        STDERR.puts "DEBUG: Missing parameters"
        status 404
        return "File not found"
      end
      
      # Construct the file path
      post_file = @api.root/"views"/view_name/"output"/"posts"/filename
      STDERR.puts "DEBUG: Looking for file: #{post_file}"
      STDERR.puts "DEBUG: File exists: #{File.exist?(post_file)}"
      
      if File.exist?(post_file)
        content_type :html
        File.read(post_file)
      else
        STDERR.puts "DEBUG: File not found"
        status 404
        "File not found: #{filename}"
      end
    rescue => e
      STDERR.puts "DEBUG: Error: #{e.message}"
      status 500
      "Error loading file: #{e.message}"
    end
  end

  # Show view configuration page
  get '/configure_view/:name' do
    begin
      validate_required_params(params, :name)
      
      unless validate_view_name(params[:name])
        redirect "/?error=Invalid view name&suggestion=View names must contain only letters, numbers, hyphens, and underscores."
        return
      end
      
      view = @api.lookup_view(params[:name])
      if view.nil?
        redirect "/?error=View not found&suggestion=The view '#{params[:name]}' does not exist. Check the view name or create it first."
        return
      end
      
      @view = view
      
      # Load view configuration safely
      config_file = @api.root/"views"/params[:name]/"config.txt"
      @config_content = safe_read_file(config_file, "# View configuration for #{params[:name]}\n")
      
      # Load layout file safely
      layout_file = @api.root/"views"/params[:name]/"config"/"layout.txt"
      @layout_content = safe_read_file(layout_file, "# Layout configuration for #{params[:name]}\n")
      
      erb :configure_view
    rescue => e
      error_info = friendly_error_message(e)
      redirect "/?error=#{error_info[:message]}&suggestion=#{error_info[:suggestion]}"
    end
  end

  # Save view configuration
  post '/save_view_config/:name' do
    view_name = params[:name]
    
    begin
      view = @api.lookup_view(view_name)
      if view.nil?
        redirect "/?error=View not found"
        return
      end
      
      # Step 1: Save basic view information
      if params[:view_title] && params[:view_subtitle] && params[:view_theme]
        config_content = "title    #{params[:view_title]}\n"
        config_content += "subtitle #{params[:view_subtitle]}\n"
        config_content += "theme    #{params[:view_theme]}\n"
        
        config_file = @api.root/"views"/view_name/"config.txt"
        File.write(config_file, config_content)
      end
      
      # Step 2: Save layout configuration
      if params[:containers]
        layout_content = ""
        containers = Array(params[:containers])
        
        containers.each do |container|
          case container
          when 'header'
            layout_content += "header      # Top (banner? title? navbar? etc.)\n"
          when 'left'
            width = params[:left_width] || "15%"
            layout_content += "left   #{width}  # Left sidebar, #{width} width\n"
          when 'main'
            layout_content += "main        # Main (center) container - posts/etc.\n"
          when 'right'
            width = params[:right_width] || "15%"
            layout_content += "right   #{width}  # Right sidebar, #{width} width\n"
          when 'footer'
            layout_content += "footer      # Footer (copyright? mail? social media? etc.)\n"
          end
        end
        
        layout_file = @api.root/"views"/view_name/"config"/"layout.txt"
        FileUtils.mkdir_p(File.dirname(layout_file))
        File.write(layout_file, layout_content)
      end
      
      # Step 3: Save container content files
      containers = Array(params[:containers])
      
      containers.each do |container|
        content_param = "#{container}_content"
        if params[content_param]
          content_file = @api.root/"views"/view_name/"config"/"#{container}.txt"
          FileUtils.mkdir_p(File.dirname(content_file))
          File.write(content_file, params[content_param])
          
          # If this is header with "banner svg", create default svg.txt
          if container == 'header' && params[content_param].strip == 'banner svg'
            svg_file = @api.root/"views"/view_name/"config"/"svg.txt"
            unless File.exist?(svg_file)
              # Create default SVG configuration
              default_svg_content = "# SVG Banner Configuration\n"
              default_svg_content += "# Light gradient background with dark text\n"
              default_svg_content += "back.linear #f8f9fa #e9ecef lr\n"
              default_svg_content += "text.color #374151\n"
              default_svg_content += "title.style bold\n"
              File.write(svg_file, default_svg_content)
            end
          end
        end
      end
      
      redirect "/?message=View '#{view_name}' configuration saved successfully"
    rescue => e
      redirect "/configure_view/#{view_name}?error=Failed to save configuration: #{e.message}"
    end
  end

  # Banner configuration page
  get '/banner_config' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    # Get current SVG config
    svg_file = @api.root/"views"/@current_view.name/"config"/"svg.txt"
    @svg_config = File.exist?(svg_file) ? File.read(svg_file) : ""
    
    # Generate current banner for display
    begin
      banner = Scriptorium::BannerSVG.new(@current_view.title, @current_view.subtitle)
      
      # Use the same approach as View class
      if @svg_config.strip.length > 0
        # Temporarily change to the config directory
        config_dir = @api.root/"views"/@current_view.name/"config"
        Dir.chdir(config_dir) do
          # Temporarily rename svg.txt to config.txt for BannerSVG compatibility
          if File.exist?("config.txt")
            File.rename("config.txt", "config.txt.backup")
          end
          File.rename("svg.txt", "config.txt")
          
          begin
            banner.parse_header_svg
          ensure
            # Restore original files
            File.rename("config.txt", "svg.txt")
            if File.exist?("config.txt.backup")
              File.rename("config.txt.backup", "config.txt")
            end
          end
        end
      else
        # No config, use defaults
        banner.parse_header_svg
      end
      
      @banner_svg = banner.generate_svg
    rescue => e
      @banner_svg = "<p>Error generating banner: #{e.message}</p>"
    end
    
    erb :banner_config
  end

  # Update banner configuration
  post '/banner_config' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      svg_config = params[:svg_config] || ""
      
      # Save the SVG configuration
      svg_file = @api.root/"views"/@current_view.name/"config"/"svg.txt"
      FileUtils.mkdir_p(File.dirname(svg_file))
      File.write(svg_file, svg_config)
      
      redirect "/banner_config?message=Banner configuration updated successfully"
    rescue => e
      redirect "/banner_config?error=Failed to save banner configuration: #{e.message}"
    end
  end

  # Navbar configuration page
  get '/navbar_config' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    # Get current navbar config
    navbar_file = @api.root/"views"/@current_view.name/"config"/"navbar.txt"
    @navbar_config = File.exist?(navbar_file) ? File.read(navbar_file).strip : ""
    
    # Generate current navbar preview
    begin
      view = @api.lookup_view(@current_view.name)
      @navbar_preview = view.build_nav(nil) # nil = use default navbar.txt
    rescue => e
      @navbar_preview = "<p>Error generating navbar: #{e.message}</p>"
    end
    
    erb :navbar_config
  end

  # Add item (top-level link or parent)
  post '/navbar_config/add_item' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      label = params[:label]&.strip
      filename = params[:filename]&.strip
      action = params[:action]
      
      if label.nil? || label.empty?
        redirect "/navbar_config?error=Label is required"
        return
      end
      
      # Read current navbar config
      navbar_file = @api.root/"views"/@current_view.name/"config"/"navbar.txt"
      current_config = File.exist?(navbar_file) ? File.read(navbar_file).strip : ""
      
      # Add new item based on action
      if action == "link"
        if filename.nil? || filename.empty?
          redirect "/navbar_config?error=Filename is required for top-level links"
          return
        end
        new_line = "-#{label}  #{filename}"
        message = "Added #{label} as top-level link"
      else
        new_line = "=#{label}"
        message = "Added #{label} as parent"
      end
      
      # Append to config
      updated_config = current_config.empty? ? new_line : "#{current_config.rstrip}\n#{new_line}"
      
      # Save the updated configuration
      FileUtils.mkdir_p(File.dirname(navbar_file))
      File.write(navbar_file, updated_config.rstrip + "\n")
      
      redirect "/navbar_config?message=#{message}"
    rescue => e
      redirect "/navbar_config?error=Failed to add item: #{e.message}"
    end
  end

  # Add child to parent
  post '/navbar_config/add_child' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      parent = params[:parent]&.strip
      label = params[:label]&.strip
      filename = params[:filename]&.strip
      
      if parent.nil? || parent.empty?
        redirect "/navbar_config?error=Parent is required"
        return
      end
      
      if label.nil? || label.empty?
        redirect "/navbar_config?error=Label is required"
        return
      end
      
      if filename.nil? || filename.empty?
        redirect "/navbar_config?error=Filename is required"
        return
      end
      
      # Read current navbar config
      navbar_file = @api.root/"views"/@current_view.name/"config"/"navbar.txt"
      current_config = File.exist?(navbar_file) ? File.read(navbar_file).strip : ""
      
      # Find the parent and add child after it
      lines = current_config.lines
      new_lines = []
      parent_found = false
      
      lines.each do |line|
        new_lines << line
        if line.strip == "=#{parent}"
          parent_found = true
          # Add child on next line
          new_lines << " #{label}  #{filename}\n"
        end
      end
      
      if !parent_found
        redirect "/navbar_config?error=Parent '#{parent}' not found"
        return
      end
      
      # Save the updated configuration
      FileUtils.mkdir_p(File.dirname(navbar_file))
      File.write(navbar_file, new_lines.join.rstrip + "\n")
      
      redirect "/navbar_config?message=Added #{label} as child of #{parent}"
    rescue => e
      redirect "/navbar_config?error=Failed to add child: #{e.message}"
    end
  end

  # Save direct edit of navbar config
  post '/navbar_config/save_direct' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      config = params[:config]&.strip
      if config.nil?
        redirect "/navbar_config?error=Configuration is required"
        return
      end
      
      # Save the configuration
      navbar_file = @api.root/"views"/@current_view.name/"config"/"navbar.txt"
      FileUtils.mkdir_p(File.dirname(navbar_file))
      File.write(navbar_file, config.rstrip + "\n")
      
      # Check for missing pages and create them
      pages_created = []
      pages_dir = @api.root/"views"/@current_view.name/"pages"
      FileUtils.mkdir_p(pages_dir) unless Dir.exist?(pages_dir)
      
      # Parse navbar config to find page filenames
      config.lines.each do |line|
        line = line.rstrip
        next if line.empty? || line.start_with?('#')
        
        # Check for top-level links (start with -)
        if line.start_with?('-')
          if line.include?('  ')
            parts = line.split(/\s{2,}/, 2)
            if parts.length >= 2
              filename = parts[1].strip
              next if filename.empty?
              
              # Add .lt3 extension if no extension
              filename += '.lt3' unless filename.include?('.')
              
              # Check if page exists
              page_file = pages_dir/filename
              unless File.exist?(page_file)
                FileUtils.touch(page_file)
                pages_created << filename
              end
            end
          end
        # Check for child links (start with space)
        elsif line.start_with?(' ')
          if line.include?('  ')
            parts = line.split(/\s{2,}/, 2)
            if parts.length >= 2
              filename = parts[1].strip
              next if filename.empty?
              
              # Add .lt3 extension if no extension
              filename += '.lt3' unless filename.include?('.')
              
              # Check if page exists
              page_file = pages_dir/filename
              unless File.exist?(page_file)
                FileUtils.touch(page_file)
                pages_created << filename
              end
            end
          end
        end
      end
      
      # Build success message
      message = "Configuration saved successfully"
      if pages_created.any?
        message += ". Created missing pages: #{pages_created.join(', ')}"
      end
      
      redirect "/navbar_config?message=#{message}"
    rescue => e
      redirect "/navbar_config?error=Failed to save configuration: #{e.message}"
    end
  end

  # Edit pages page
  get '/edit_pages' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    # Get all pages in the current view
    pages_dir = @api.root/"views"/@current_view.name/"pages"
    @pages = []
    
    if Dir.exist?(pages_dir)
      Dir.glob(pages_dir/"*").each do |file|
        next unless File.file?(file)
        filename = File.basename(file)
        content = File.read(file)
        @pages << {
          filename: filename,
          content: content,
          empty: content.strip.empty?
        }
      end
    end
    
    # Sort pages alphabetically
    @pages.sort_by! { |page| page[:filename] }
    
    erb :edit_pages
  end

  # Save page content
  post '/edit_pages/save' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      filename = params[:filename]&.strip
      content = params[:content]&.strip || ""
      
      if filename.nil? || filename.empty?
        redirect "/edit_pages?error=Filename is required"
        return
      end
      
      # Save the page
      pages_dir = @api.root/"views"/@current_view.name/"pages"
      FileUtils.mkdir_p(pages_dir)
      page_file = pages_dir/filename
      File.write(page_file, content)
      
      redirect "/edit_pages?message=Page '#{filename}' saved successfully"
    rescue => e
      redirect "/edit_pages?error=Failed to save page: #{e.message}"
    end
  end

  # Server status endpoint
  get '/status' do
    content_type :json
    {
      status: 'running',
      port: settings.port,
      current_view: @api.current_view&.name,
      repo_loaded: !@api.instance_variable_get(:@repo).nil?
    }.to_json
  end
end

# Start the server if this file is run directly
if __FILE__ == $0
  ScriptoriumWeb.run!
end 