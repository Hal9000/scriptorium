#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/reloader' if development?
require 'fileutils'
require 'pathname'
begin
  require 'fastimage'
rescue LoadError
  # FastImage not available, will handle gracefully
end
require_relative '../../../lib/scriptorium'
require_relative 'error_helpers'

include ErrorHelpers
include Scriptorium::Helpers

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
      # Use the test repository in the ui/web/ directory
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
          File.write("/tmp/debug.log", "DEBUG: Route reached, current_view: #{@current_view.name}\n", mode: 'a')
          @posts = @api.posts(@current_view.name, include_deleted: true) || []
          File.write("/tmp/debug.log", "DEBUG: Posts loaded: #{@posts.length}\n", mode: 'a')
          if @posts.length > 0
          end
        else
          File.write("/tmp/debug.log", "DEBUG: No current view\n", mode: 'a')
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
        @api.generate_post(post_num)
        # Check if meta.txt was created
        meta_file = @api.root/"posts"/"#{post_num.to_s.rjust(4, '0')}"/"meta.txt"
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
        @content = read_file(source_file)
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
      write_file(source_file, content)
      
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
        read_file(index_file)
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
    
    begin
      if view_name.nil? || view_name.strip.empty? || filename.nil? || filename.strip.empty?
        status 404
        return "File not found"
      end
      
      # Construct the file path
      post_file = @api.root/"views"/view_name/"output"/"posts"/filename
      
      if File.exist?(post_file)
        content_type :html
        read_file(post_file)
      else
        status 404
        "File not found: #{filename}"
      end
    rescue => e
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
        write_file(config_file, config_content)
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
        write_file(layout_file, layout_content)
      end
      
      # Step 3: Save container content files
      containers = Array(params[:containers])
      
      containers.each do |container|
        content_param = "#{container}_content"
        if params[content_param]
          content_file = @api.root/"views"/view_name/"config"/"#{container}.txt"
          FileUtils.mkdir_p(File.dirname(content_file))
          write_file(content_file, params[content_param])
          
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
              write_file(svg_file, default_svg_content)
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
          @svg_config = File.exist?(svg_file) ? read_file(svg_file) : ""
    
    # Generate current banner for display
    begin
      banner = Scriptorium::BannerSVG.new(@current_view.title, @current_view.subtitle)
      
      # Use the same approach as View class
      if @svg_config.strip.length > 0
        svg_file = @api.root/"views"/@current_view.name/"config"/"svg.txt"
        banner.parse_header_svg(svg_file)
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
              write_file(svg_file, svg_config)
      
      # Update status
      update_config_status(@current_view.name, "banner", true)
      
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
          @navbar_config = File.exist?(navbar_file) ? read_file(navbar_file).strip : ""
    
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
      current_config = File.exist?(navbar_file) ? read_file(navbar_file).strip : ""
      
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
      write_file(navbar_file, updated_config.rstrip + "\n")
      
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
      current_config = File.exist?(navbar_file) ? read_file(navbar_file).strip : ""
      
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
      write_file(navbar_file, new_lines.join.rstrip + "\n")
      
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
      write_file(navbar_file, config.rstrip + "\n")
      
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
              title = parts[0].strip
              filename = parts[1].strip
              next if filename.empty?
              
              # Add .lt3 extension if no extension
              filename += '.lt3' unless filename.include?('.')
              
              # Check if page exists
              page_file = pages_dir/filename
              unless File.exist?(page_file)
                content = ".page_title #{title}\n\n"
                write_file(page_file, content)
                pages_created << filename
              end
            end
          end
        # Check for child links (start with space)
        elsif line.start_with?(' ')
          if line.include?('  ')
            parts = line.split(/\s{2,}/, 2)
            if parts.length >= 2
              title = parts[0].strip
              filename = parts[1].strip
              next if filename.empty?
              
              # Add .lt3 extension if no extension
              filename += '.lt3' unless filename.include?('.')
              
              # Check if page exists
              page_file = pages_dir/filename
              unless File.exist?(page_file)
                content = ".page_title #{title}\n\n"
                write_file(page_file, content)
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
        content = read_file(file)
        
        # Extract page title from .page_title directive
        title = nil
        if content.lines.first&.strip&.start_with?('.page_title')
          title = content.lines.first.strip.sub('.page_title', '').strip
        end
        
        @pages << {
          filename: filename,
          title: title,
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
              write_file(page_file, content)
      
      redirect "/edit_pages?message=Page '#{filename}' saved successfully"
    rescue => e
      redirect "/edit_pages?error=Failed to save page: #{e.message}"
    end
  end

  # Per-view dashboard
  get '/view/:name' do
    view_name = params[:name]
    
    # Debug logging
    File.write('/tmp/dashboard_debug.log', "Dashboard accessed for view: #{view_name} at #{Time.now}\n", mode: 'a')
    
    begin
      # Look up the view
      @current_view = @api.lookup_view(view_name)
      if @current_view.nil?
        redirect "/?error=View '#{view_name}' not found"
        return
      end
      
      # Set as current view
      @api.view(view_name)
      # @current_view = @api.current_view # This line is now redundant as @current_view is set above
      
      # Generate banner for display
      begin
        bsvg = Scriptorium::BannerSVG.new(@current_view.title, @current_view.subtitle)
        svg_config_file = @api.root/"views"/view_name/"config"/"svg.txt"
        if File.exist?(svg_config_file)
          bsvg.parse_header_svg(svg_config_file)
        else
          bsvg.parse_header_svg
        end
        # Generate responsive SVG for web display
        svg_html = bsvg.generate_svg
        # Extract the SVG element and make it responsive
        svg_match = svg_html.match(/<svg[^>]*>(.*)<\/svg>/m)
        if svg_match
          svg_content = svg_match[1]
          # Calculate height based on aspect ratio (7.0 from config)
          width = 800
          height = (width / 7.0).to_i
          @banner_svg = <<~HTML
            <svg xmlns='http://www.w3.org/2000/svg' 
                 width='100%' height='auto' 
                 viewBox='0 0 #{width} #{height}' 
                 preserveAspectRatio='xMidYMid meet'>
              #{svg_content}
            </svg>
          HTML
        else
          @banner_svg = svg_html
        end
      rescue => e
        @banner_svg = "<p>Error generating banner: #{e.message}</p>"
      end
      
      # Get posts for pagination
      begin
        posts = @api.posts(view_name, include_deleted: true) || []
        
        # Debug: check if include_deleted is working
        File.write('/tmp/dashboard_debug.log', "Found #{posts.length} posts (including deleted)\n", mode: 'a')
        deleted_count = posts.count(&:deleted)
        File.write('/tmp/dashboard_debug.log', "Deleted posts: #{deleted_count}\n", mode: 'a')
        
        # Debug: log first few posts and their dates for ordering analysis
        posts.first(5).each_with_index do |post, i|
          File.write('/tmp/dashboard_debug.log', "Post #{i}: #{post.num} - #{post.title} - date: #{post.date}\n", mode: 'a')
        end
        
        posts.sort! { |a, b| post_compare(a, b) } # Sort by date, newest first
        
        # Get posts per page from config, default to 10
        config_file = @api.root/"views"/view_name/"config"/"post_index.txt"
        posts_per_page = 10
        if File.exist?(config_file)
          config_content = read_file(config_file)
          if config_content.strip.length > 0
            posts_per_page = config_content.lines.first.strip.split.last.to_i
          end
        end
        
        # Pagination logic
        page = (params[:page] || 1).to_i
        total_posts = posts.length
        total_pages = (total_posts.to_f / posts_per_page).ceil
        
        # Debug pagination
        File.write('/tmp/dashboard_debug.log', "Page requested: #{params[:page]}, calculated: #{page}, total_pages: #{total_pages}\n", mode: 'a')
        
        # Preserve current page if possible, otherwise reset to 1
        if page > total_pages && total_pages > 0
          page = total_pages
          File.write('/tmp/dashboard_debug.log', "Page adjusted to total_pages: #{page}\n", mode: 'a')
        elsif page < 1 || total_pages == 0
          page = 1
          File.write('/tmp/dashboard_debug.log', "Page reset to 1\n", mode: 'a')
        end
        
        start_index = (page - 1) * posts_per_page
        end_index = [start_index + posts_per_page - 1, total_posts - 1].min
        
        @posts = posts[start_index..end_index] || []
        @current_page = page
        @total_pages = total_pages
        @total_posts = total_posts
        @posts_per_page = posts_per_page
      rescue => e
        @posts = []
        @current_page = 1
        @total_pages = 1
        @total_posts = 0
        @posts_per_page = 10
      end
      
      erb :view_dashboard
    rescue => e
      redirect "/?error=Failed to load view dashboard: #{e.message}"
    end
  end

  # Advanced configuration page
  get '/advanced_config' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    # Read status from status.txt file
    config_dir = @api.root/"views"/@current_view.name/"config"
    status_file = config_dir/"status.txt"
    @configs = {}
    
    if File.exist?(status_file)
      status_config = @api.parse_commented_file(status_file)
      status_config.each do |key, value|
        @configs[key.to_sym] = value == 'y'
      end
    else
      # Default to all 'n' if status file doesn't exist
      @configs = {
        header: false,
        banner: false,
        navbar: false,
        left: false,
        right: false,
        pages: false,
        deploy: false
      }
    end
    
    # Read layout to determine which containers exist
    layout_file = config_dir/"layout.txt"
    @layout_containers = []
    if File.exist?(layout_file)
      layout_config = @api.parse_commented_file(layout_file)
      layout_config.each do |container, _|
        @layout_containers << container
      end
    end
    
    erb :advanced_config
  end

  # Header configuration page
  get '/header_config' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    # Read current header config
    header_file = @api.root/"views"/@current_view.name/"config"/"header.txt"
    @current_config = ""
    if File.exist?(header_file)
      @current_config = read_file(header_file).strip
    end
    
    # Parse current settings
    @banner_type = @current_config.include?("banner svg") ? "svg" : "image"
    @navbar_enabled = @current_config.include?("navbar")
    
    erb :header_config
  end

  # Update header configuration
  post '/header_config' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      banner_type = params[:banner_type] || "svg"
      navbar_enabled = params[:navbar_enabled] == "1"
      
      # Build header.txt content
      header_content = []
      header_content << "banner #{banner_type}"
      header_content << "navbar" if navbar_enabled
      
      # Save the header configuration
      header_file = @api.root/"views"/@current_view.name/"config"/"header.txt"
      FileUtils.mkdir_p(File.dirname(header_file))
              write_file(header_file, header_content.join("\n") + "\n")
      
      # Update status
      update_config_status(@current_view.name, "header", true)
      
      redirect "/advanced_config?message=Header configuration updated successfully"
    rescue => e
      redirect "/header_config?error=Failed to save header configuration: #{e.message}"
    end
  end

  # Deployment configuration page
  get '/deploy_config' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    # Read current deployment config
    deploy_file = @api.root/"views"/@current_view.name/"config"/"deploy.txt"
    @deploy_config = ""
    if File.exist?(deploy_file)
      @deploy_config = read_file(deploy_file).strip
    end
    
    erb :deploy_config
  end

  # Update deployment configuration
  post '/deploy_config' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      deploy_config = params[:deploy_config] || ""
      
      # Save the deployment configuration
      deploy_file = @api.root/"views"/@current_view.name/"config"/"deploy.txt"
      FileUtils.mkdir_p(File.dirname(deploy_file))
              write_file(deploy_file, deploy_config + "\n")
      
      # Update status
      update_config_status(@current_view.name, "deploy", true)
      
      redirect "/advanced_config?message=Deployment configuration updated successfully"
    rescue => e
      redirect "/deploy_config?error=Failed to save deployment configuration: #{e.message}"
    end
  end

  # Layout configuration page
  get '/layout_config' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    # Read current layout config
    layout_file = @api.root/"views"/@current_view.name/"config"/"layout.txt"
    @layout_config = ""
    if File.exist?(layout_file)
      @layout_config = read_file(layout_file).strip
    end
    
    erb :layout_config
  end

  # Update layout configuration
  post '/layout_config' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      layout_config = params[:layout_config] || ""
      
      # Save the layout configuration
      layout_file = @api.root/"views"/@current_view.name/"config"/"layout.txt"
      FileUtils.mkdir_p(File.dirname(layout_file))
              write_file(layout_file, layout_config + "\n")
      
      redirect "/advanced_config?message=Layout configuration updated successfully"
    rescue => e
      redirect "/layout_config?error=Failed to save layout configuration: #{e.message}"
    end
  end

  # Serve global assets
  get '/assets/*' do
    asset_path = params[:splat].first
    asset_file = @api.root/"assets"/asset_path
    
    if File.exist?(asset_file) && File.file?(asset_file)
      send_file asset_file
    else
      status 404
      "Asset not found"
    end
  end

  # Serve view-specific assets
  get '/views/:view_name/assets/*' do
    view_name = params[:view_name]
    asset_path = params[:splat].first
    asset_file = @api.root/"views"/view_name/"assets"/asset_path
    
    if File.exist?(asset_file) && File.file?(asset_file)
      send_file asset_file
    else
      status 404
      "Asset not found"
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

  # Asset management page
  get '/asset_management' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    # Get global assets
    global_assets_dir = @api.root/"assets"
    @global_assets = []
    @library_assets = []
    
    if Dir.exist?(global_assets_dir)
      Dir.glob(global_assets_dir/"*").each do |file|
        next unless File.file?(file)
        filename = File.basename(file)
        size = File.size(file)
        dimensions = get_image_dimensions(file)
        @global_assets << {
          filename: filename,
          size: size,
          path: file,
          dimensions: dimensions
        }
      end
      
      # Get library assets
      library_dir = global_assets_dir/"library"
      if Dir.exist?(library_dir)
        Dir.glob(library_dir/"*").each do |file|
          next unless File.file?(file)
          filename = File.basename(file)
          size = File.size(file)
          dimensions = get_image_dimensions(file)
          @library_assets << {
            filename: filename,
            size: size,
            path: file,
            dimensions: dimensions
          }
        end
      end
    end
    
    # Get view-specific assets
    view_assets_dir = @api.root/"views"/@current_view.name/"assets"
    @view_assets = []
    
    if Dir.exist?(view_assets_dir)
      Dir.glob(view_assets_dir/"*").each do |file|
        next unless File.file?(file)
        filename = File.basename(file)
        size = File.size(file)
        dimensions = get_image_dimensions(file)
        @view_assets << {
          filename: filename,
          size: size,
          path: file,
          dimensions: dimensions
        }
      end
    end
    
    # Sort all asset lists
    @global_assets.sort_by! { |asset| asset[:filename] }
    @library_assets.sort_by! { |asset| asset[:filename] }
    @view_assets.sort_by! { |asset| asset[:filename] }
    
    erb :asset_management
  end

  # Upload asset
  post '/asset_management/upload' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      target = params[:target] # 'global', 'library', or 'view'
      file = params[:file]
      
      if file.nil? || file[:tempfile].nil?
        redirect "/asset_management?error=No file selected"
        return
      end
      
      filename = file[:filename]
      tempfile = file[:tempfile]
      
      # Determine target directory
      case target
      when 'global'
        target_dir = @api.root/"assets"
      when 'library'
        target_dir = @api.root/"assets"/"library"
      when 'view'
        target_dir = @api.root/"views"/@current_view.name/"assets"
      else
        redirect "/asset_management?error=Invalid target"
        return
      end
      
      # Create directory if it doesn't exist
      FileUtils.mkdir_p(target_dir)
      
      # Save the file
      target_file = target_dir/filename
      FileUtils.cp(tempfile.path, target_file)
      
      redirect "/asset_management?message=Asset '#{filename}' uploaded successfully to #{target}"
    rescue => e
      redirect "/asset_management?error=Failed to upload asset: #{e.message}"
    end
  end

  # Copy asset from global to view
  post '/asset_management/copy' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      source = params[:source] # 'global' or 'library'
      filename = params[:filename]
      
      if filename.nil? || filename.empty?
        redirect "/asset_management?error=No filename specified"
        return
      end
      
      # Determine source file
      case source
      when 'global'
        source_file = @api.root/"assets"/filename
      when 'library'
        source_file = @api.root/"assets"/"library"/filename
      else
        redirect "/asset_management?error=Invalid source"
        return
      end
      
      unless File.exist?(source_file)
        redirect "/asset_management?error=Source file not found"
        return
      end
      
      # Copy to view assets
      target_dir = @api.root/"views"/@current_view.name/"assets"
      FileUtils.mkdir_p(target_dir)
      target_file = target_dir/filename
      FileUtils.cp(source_file, target_file)
      
      redirect "/asset_management?message=Asset '#{filename}' copied successfully to view"
    rescue => e
      redirect "/asset_management?error=Failed to copy asset: #{e.message}"
    end
  end

  # Delete asset
  post '/asset_management/delete' do
    @current_view = @api&.current_view
    if @current_view.nil?
      redirect "/?error=No view selected. Please select a view first."
      return
    end
    
    begin
      target = params[:target] # 'global', 'library', or 'view'
      filename = params[:filename]
      
      if filename.nil? || filename.empty?
        redirect "/asset_management?error=No filename specified"
        return
      end
      
      # Determine target file
      case target
      when 'global'
        target_file = @api.root/"assets"/filename
      when 'library'
        target_file = @api.root/"assets"/"library"/filename
      when 'view'
        target_file = @api.root/"views"/@current_view.name/"assets"/filename
      else
        redirect "/asset_management?error=Invalid target"
        return
      end
      
      unless File.exist?(target_file)
        redirect "/asset_management?error=File not found"
        return
      end
      
      # Delete the file
      File.delete(target_file)
      
      redirect "/asset_management?message=Asset '#{filename}' deleted successfully"
    rescue => e
      redirect "/asset_management?error=Failed to delete asset: #{e.message}"
    end
  end

  # Widget Management Routes
  
  # List widgets for current view
  get '/widgets' do
    if @api&.instance_variable_get(:@repo) && @current_view
      @available_widgets = @api.widgets_available
      @configured_widgets = []
      @widget_containers = {}
      
      @available_widgets.each do |widget|
        widget_dir = @api.root/"views"/@current_view.name/"widgets"/widget
        if Dir.exist?(widget_dir)
          @configured_widgets << widget
          # Determine which container this widget is in
          @widget_containers[widget] = determine_widget_container(@current_view)
        end
      end
      
      erb :widgets
    else
      redirect "/?error=No repository or view selected"
    end
  end

  # Add widget to current view
  post '/add_widget' do
    if @api&.instance_variable_get(:@repo) && @current_view
      widget_name = params[:widget_name]&.strip
      
      if widget_name.nil? || widget_name.empty?
        redirect "/widgets?error=Widget name required"
        return
      end
      
      # Check if widget is available
      available_widgets = @api.widgets_available
      unless available_widgets.include?(widget_name)
        redirect "/widgets?error=Widget '#{widget_name}' not available"
        return
      end
      
      # Check if widget is already configured
      widget_dir = @api.root/"views"/@current_view.name/"widgets"/widget_name
      if Dir.exist?(widget_dir)
        redirect "/widgets?error=Widget '#{widget_name}' already configured"
        return
      end
      
      # Determine container (left/right) for widget placement
      container = determine_widget_container(@current_view)
      unless container
        redirect "/widgets?error=No left or right container found in layout. Add a left or right container to your layout first."
        return
      end
      
      # Create widget directory and list.txt
      FileUtils.mkdir_p(widget_dir)
      list_file = widget_dir/"list.txt"
      File.write(list_file, "# Add #{widget_name} items here\n")
      
      # Generate the widget after creation
      begin
        @api.generate_widget(widget_name)
        redirect "/widgets?message=Widget '#{widget_name}' added successfully to #{container} container and generated"
      rescue => e
        # Widget created but generation failed
        redirect "/widgets?message=Widget '#{widget_name}' added successfully to #{container} container, but generation failed: #{e.message}"
      end
    else
      redirect "/?error=No repository or view selected"
    end
  end

  # Configure widget data
  get '/config_widget/:widget_name' do
    if @api&.instance_variable_get(:@repo) && @current_view
      @widget_name = params[:widget_name]
      widget_dir = @api.root/"views"/@current_view.name/"widgets"/@widget_name
      
      unless Dir.exist?(widget_dir)
        redirect "/widgets?error=Widget '#{@widget_name}' not configured"
        return
      end
      
      list_file = widget_dir/"list.txt"
      @widget_data = File.exist?(list_file) ? File.read(list_file) : ""
      
      erb :config_widget
    else
      redirect "/?error=No repository or view selected"
    end
  end

  # Update widget data
  post '/update_widget/:widget_name' do
    if @api&.instance_variable_get(:@repo) && @current_view
      widget_name = params[:widget_name]
      widget_data = params[:widget_data]
      
      widget_dir = @api.root/"views"/@current_view.name/"widgets"/widget_name
      list_file = widget_dir/"list.txt"
      
      File.write(list_file, widget_data)
      
      # Generate the widget after updating
      begin
        @api.generate_widget(widget_name)
        redirect "/widgets?message=Widget '#{widget_name}' updated and generated successfully"
      rescue => e
        # Widget updated but generation failed
        redirect "/widgets?error=Widget '#{widget_name}' updated successfully, but generation failed: #{e.message}"
      end
    else
      redirect "/?error=No repository or view selected"
    end
  end

  # Remove widget from current view
  post '/remove_widget' do
    if @api&.instance_variable_get(:@repo) && @current_view
      widget_name = params[:widget_name]&.strip
      
      if widget_name.nil? || widget_name.empty?
        redirect "/widgets?error=Widget name required"
        return
      end
      
      widget_dir = @api.root/"views"/@current_view.name/"widgets"/widget_name
      if Dir.exist?(widget_dir)
        FileUtils.rm_rf(widget_dir)
        redirect "/widgets?message=Widget '#{widget_name}' removed successfully"
      else
        redirect "/widgets?error=Widget '#{widget_name}' not found"
      end
    else
      redirect "/?error=No repository or view selected"
    end
  end

  # Helper method to update status
  private def update_config_status(view_name, config_name, status)
    status_file = @api.root/"views"/view_name/"config"/"status.txt"
    return unless File.exist?(status_file)
    
          content = read_file(status_file)
    lines = content.lines.map do |line|
      if line.strip.start_with?("#{config_name} ")
        "#{config_name} #{status ? 'y' : 'n'}\n"
      else
        line
      end
    end
            write_file(status_file, lines.join)
  end

  # Helper method for formatting file sizes
  def number_to_human_size(bytes)
    return '0 Bytes' if bytes == 0
    k = 1024
    sizes = ['Bytes', 'KB', 'MB', 'GB']
    i = (Math.log(bytes) / Math.log(k)).floor
    "#{(bytes / k**i.to_f).round(2)} #{sizes[i]}"
  end

  # Helper method to determine which container (left/right) widgets should be placed in
  private def determine_widget_container(view)
    layout_file = @api.root/"views"/view.name/"config"/"layout.txt"
    return nil unless File.exist?(layout_file)
    
    layout_config = @api.parse_commented_file(layout_file)
    containers = layout_config.keys
    
    # Prefer left container, fall back to right
    containers.find { |c| c == 'left' } || containers.find { |c| c == 'right' }
  end

  def get_image_dimensions(file_path)
    return nil unless File.exist?(file_path)
    
    # Check if it's an image file
    image_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp']
    return nil unless image_extensions.any? { |ext| file_path.downcase.end_with?(ext) }
    
    # Check if FastImage is available
    return nil unless defined?(FastImage)
    
    dimensions = FastImage.size(file_path)
    return dimensions ? "#{dimensions[0]}×#{dimensions[1]}" : nil
  rescue => e
    # If FastImage fails, return nil
    return nil
  end



  # Delete a post (move to _postnum directory)
  post '/delete_post/:id' do
    post_id = params[:id]
    
    begin
      # Set current view before proceeding
      @current_view = @api&.current_view
      if @current_view.nil?
        redirect "/?error=No view selected"
        return
      end
      
      post = @api.post(post_id.to_i)
      if post.nil?
        redirect "/?error=Post #{post_id} not found"
        return
      end
      
      # Mark as deleted in metadata
      post.deleted = true
      
      # Move post directory to _postnum
      post_dir = @api.root/"posts"/post.num
      deleted_dir = @api.root/"posts"/"_#{post.num}"
      
      if Dir.exist?(post_dir)
        FileUtils.mkdir_p(File.dirname(deleted_dir))
        FileUtils.mv(post_dir, deleted_dir)
      else
        redirect "/?error=Post directory #{post_dir} not found"
        return
      end
      
      # Preserve current page if available
      current_page = params[:page] || request.env['HTTP_REFERER']&.match(/[?&]page=(\d+)/)&.[](1) || 1
      redirect "/view/#{@current_view.name}?page=#{current_page}&message=Post #{post_id} deleted successfully"
    rescue => e
      redirect "/?error=Failed to delete post: #{e.message}"
    end
  end

  # Restore a deleted post
  post '/restore_post/:id' do
    post_id = params[:id]
    
    begin
      # Set current view before proceeding
      @current_view = @api&.current_view
      if @current_view.nil?
        redirect "/?error=No view selected"
        return
      end
      
      # Find the deleted post directory
      formatted_id = post_id.to_s.rjust(4, '0')  # Ensure 4-digit format (e.g., "28" -> "0028")
      deleted_dir = @api.root/"posts"/"_#{formatted_id}"
      post_dir = @api.root/"posts"/formatted_id
      
      if Dir.exist?(deleted_dir)
        # Move back to normal posts directory
        FileUtils.mv(deleted_dir, post_dir)
        
        # Update metadata to mark as not deleted
        post = @api.post(post_id.to_i)
        if post
          # Debug: log both date fields before and after
          File.write('/tmp/restore_debug.log', "Restoring post #{post_id}: pubdate before = #{post.pubdate}, created before = #{post.created}\n", mode: 'a')
          post.deleted = false
          File.write('/tmp/restore_debug.log', "Restoring post #{post_id}: pubdate after = #{post.pubdate}, created after = #{post.created}\n", mode: 'a')
        end
        
        # Preserve current page if available
        current_page = params[:page] || request.env['HTTP_REFERER']&.match(/[?&]page=(\d+)/)&.[](1) || 1
        redirect "/view/#{@current_view.name}?page=#{current_page}&message=Post #{post_id} restored successfully"
      else
        redirect "/?error=Deleted post #{post_id} not found"
      end
    rescue => e
      redirect "/?error=Failed to restore post: #{e.message}"
    end
  end

  # Toggle post published status
  post '/toggle_post_status/:id' do
    post_id = params[:id]
    
    begin
      # Set current view before proceeding
      @current_view = @api&.current_view
      if @current_view.nil?
        redirect "/?error=No view selected"
        return
      end
      
      post = @api.post(post_id.to_i)
      if post.nil?
        redirect "/?error=Post #{post_id} not found"
        return
      end
      
      # Toggle between published and unpublished
      if post.meta["post.published"] == "no" || post.meta["post.published"].nil?
        # Publish the post - only change published status, don't touch pubdate
        post.meta["post.published"] = "yes"
        post.save_metadata
        content_type :json
        { success: true, message: "Post #{post_id} published successfully", published: true }.to_json
      else
        # Unpublish the post - only change published status, don't touch pubdate
        post.meta["post.published"] = "no"
        post.save_metadata
        content_type :json
        { success: true, message: "Post #{post_id} unpublished successfully", published: false }.to_json
      end
    rescue => e
      redirect "/?error=Failed to toggle post status: #{e.message}"
    end
  end

  # Debug route to verify code is updated
  get '/debug' do
    "Server is running updated code at #{Time.now}"
  end
end

# Start the server if this file is run directly
if __FILE__ == $0
  ScriptoriumWeb.run!
end 