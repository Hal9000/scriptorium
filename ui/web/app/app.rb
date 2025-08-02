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
      puts "DEBUG: Initializing API..."
      @api = Scriptorium::API.new(testmode: true)
      puts "DEBUG: API created successfully"
      
      # Try to discover existing repo
      unless @api.instance_variable_get(:@repo)
        puts "DEBUG: No repo loaded, checking for scriptorium-TEST"
        if Dir.exist?("scriptorium-TEST")
          puts "DEBUG: Found scriptorium-TEST directory"
          begin
            @api.open_repo("scriptorium-TEST")
            puts "DEBUG: Successfully opened repo"
          rescue => e
            puts "DEBUG: Error opening repo: #{e.message}"
            @error = "Error opening repository: #{e.message}"
          end
        else
          puts "DEBUG: scriptorium-TEST directory not found"
        end
      else
        puts "DEBUG: Repo already loaded"
      end
    rescue => e
      puts "DEBUG: Error in before block: #{e.message}"
      puts "DEBUG: Backtrace: #{e.backtrace.first}"
      @api = nil
      @error = "Error initializing API: #{e.message}"
    end
  end
  
  # Main dashboard
  get '/' do
    puts "DEBUG: Root route accessed"
    @current_view = @api&.current_view
    @views = @api&.views || []
    begin
      if @api&.instance_variable_get(:@repo)
        puts "DEBUG: Repository exists"
        puts "DEBUG: Repository root: #{@api.instance_variable_get(:@repo).root}"
        
        # Only try to load posts if we have a current view
        if @current_view
          puts "DEBUG: Current view: #{@current_view.name}"
          puts "DEBUG: About to call @api.posts(#{@current_view.name})"
          puts "DEBUG: About to call @api.posts(#{@current_view.name})"
          @posts = @api.posts(@current_view.name) || []
          puts "DEBUG: Posts loaded successfully: #{@posts.length} posts"
          if @posts.length > 0
            puts "DEBUG: First post: #{@posts.first.title} (ID: #{@posts.first.id})"
          end
        else
          puts "DEBUG: No current view"
          @posts = []
        end
      else
        puts "DEBUG: No repository loaded"
        @posts = []
      end
    rescue => e
      puts "DEBUG: Error loading posts: #{e.message}"
      puts "DEBUG: Full backtrace:"
      e.backtrace.each { |line| puts "  #{line}" }
      @posts = []
    end
    @error = @error || params[:error]
    
    puts "DEBUG: Current view: #{@current_view&.name}"
    puts "DEBUG: Views count: #{@views&.length || 0}"
    puts "DEBUG: Posts count: #{@posts&.length || 0}"
    
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
    puts "DEBUG: create_view called with params: #{params.inspect}"
    begin
      validate_required_params(params, :name, :title)
      puts "DEBUG: validation passed"
      
      name = params[:name].strip
      title = params[:title].strip
      subtitle = params[:subtitle]&.strip || ""
      
      puts "DEBUG: calling @api.create_view(#{name.inspect}, #{title.inspect}, #{subtitle.inspect})"
      @api.create_view(name, title, subtitle, theme: "standard")
      puts "DEBUG: create_view succeeded"
      redirect "/?message=View '#{name}' created successfully"
    rescue => e
      puts "DEBUG: Error in create_view: #{e.class.name} - #{e.message}"
      puts "DEBUG: Backtrace: #{e.backtrace.first(3).join("\n")}"
      error_info = friendly_error_message(e)
      puts "DEBUG: Error info: #{error_info.inspect}"
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
      @api.generate_post(post_num)
      redirect "/?message=Post '#{params[:title].strip}' created successfully (##{post_num})"
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
      
      redirect "/?message=Post ##{post_id} saved successfully"
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
    config_content = params[:config_content]
    layout_content = params[:layout_content]
    
    begin
      view = @api.lookup_view(view_name)
      if view.nil?
        redirect "/?error=View not found"
        return
      end
      
      # Save config file
      config_file = @api.root/"views"/view_name/"config.txt"
      File.write(config_file, config_content) if config_content
      
      # Save layout file
      layout_file = @api.root/"views"/view_name/"config"/"layout.txt"
      FileUtils.mkdir_p(File.dirname(layout_file))
      File.write(layout_file, layout_content) if layout_content
      
      redirect "/?message=View '#{view_name}' configuration saved successfully"
    rescue => e
      redirect "/configure_view/#{view_name}?error=Failed to save configuration: #{e.message}"
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