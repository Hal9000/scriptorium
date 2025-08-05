class Scriptorium::BannerSVG
  include Scriptorium::Helpers
  include Scriptorium::Exceptions
  include Scriptorium::Contract
  
  # Invariants
  def define_invariants
    invariant { @title.is_a?(String) }
    invariant { @subtitle.is_a?(String) }
    invariant { @title_scale.is_a?(Numeric) && @title_scale > 0 }
    invariant { @subtitle_scale.is_a?(Numeric) && @subtitle_scale > 0 }
    invariant { @aspect.is_a?(Numeric) && @aspect > 0 }
    invariant { @font.is_a?(String) && !@font.empty? }
    invariant { @text_color.is_a?(String) && !@text_color.empty? }
    invariant { @background.is_a?(String) && !@background.empty? }
  end
  
  def initialize(title, subtitle)
    assume { title.is_a?(String) }
    assume { subtitle.is_a?(String) }
    
    @title, @subtitle = title, subtitle
    @title_scale = 0.8
    @subtitle_scale = 0.4
    @title_style = "normal"
    @subtitle_style = "normal"
    @title_weight = "normal"
    @subtitle_weight = "normal"
    @text_color = "#374151"
    @text_anchor = "start"
    @aspect = 8.0
    @font = "Verdana"
    # Remove default @title_xy and @subtitle_xy
    @background = "#fff"
    @gradient_start_color = nil
    @gradient_end_color = nil
    @gradient_direction = nil
    @radial_start_color = nil
    @radial_end_color = nil
    @image_background = nil
    @title_xy_set = false
    @subtitle_xy_set = false
    
    define_invariants
    verify { @title == title }
    verify { @subtitle == subtitle }
    check_invariants
  end
  

  
    def handle_background(*args)
      check_invariants
      assume { args.is_a?(Array) }
      
      validate_background_args(args)
      @background = args.first
      
      verify { @background.is_a?(String) && !@background.empty? }
      check_invariants
    end

    private def validate_background_args(args)
      raise CannotHandleBackgroundNoArgs if args.nil? || args.empty?
      
      raise CannotHandleBackgroundFirstArgNil if args.first.nil?
      
      raise CannotHandleBackgroundFirstArgEmpty if args.first.to_s.strip.empty?
    end

    def handle_linear_gradient(*args)
      validate_linear_gradient_args(args)
      @gradient_start_color = args[0]
      @gradient_end_color = args[1]
      @gradient_direction = args[2] || "lr"
    end

    private def validate_linear_gradient_args(args)
      raise CannotHandleLinearGradientNoArgs if args.nil? || args.empty?
      
      raise CannotHandleLinearGradientStartColorNil if args[0].nil? || args[0].to_s.strip.empty?
      
      # Validate all provided arguments (up to 3: start_color, end_color, direction)
      args.each_with_index do |arg, index|
        next if arg.nil? # Allow nil for optional arguments
        raise CannotHandleLinearGradientArgEmpty(index + 1) if arg.to_s.strip.empty?
      end
    end
  
    def handle_radial_gradient(*args)
      validate_radial_gradient_args(args)
      @radial_start_color = args[0]
      @radial_end_color = args[1]
      # Optional: cx, cy, r
      @radial_cx = args[2] || '50%'
      @radial_cy = args[3] || '50%'
      @radial_r  = args[4] || '50%'
      # 6th param: aspect ratio compensation for gradientTransform
      @radial_ar = args[5] ? args[5].to_f : nil
    end

    private def validate_radial_gradient_args(args)
      raise CannotHandleRadialGradientNoArgs if args.nil? || args.empty?
      
      raise CannotHandleRadialGradientStartColorNil if args[0].nil? || args[0].to_s.strip.empty?
      
      # Validate all provided arguments (up to 6: start_color, end_color, cx, cy, r, aspect_ratio)
      args.each_with_index do |arg, index|
        next if arg.nil? # Allow nil for optional arguments
        raise CannotHandleRadialGradientArgEmpty(index + 1) if arg.to_s.strip.empty?
      end
    end

    # Image backgrounds: Users should provide images matching the banner's aspect ratio.
    # SVG will crop/stretch if aspect ratios don't match (use preserveAspectRatio="xMidYMid slice" for cropping).
    def handle_image_background(*args)
      validate_image_background_args(args)
      @image_background = args[0]
    end

    private def validate_image_background_args(args)
      raise CannotHandleImageBackgroundNoArgs if args.nil? || args.empty?
      
      raise CannotHandleImageBackgroundFirstArgNil if args[0].nil?
      
      raise CannotHandleImageBackgroundFirstArgEmpty if args[0].to_s.strip.empty?
    end
    
    def handle_aspect(*args)
      check_invariants
      assume { args.is_a?(Array) }
      
      validate_aspect_args(args)
      @aspect = args.first.to_f
      
      verify { @aspect.is_a?(Numeric) && @aspect > 0 }
      check_invariants
    end

    private def validate_aspect_args(args)
      raise CannotHandleAspectNoArgs if args.nil? || args.empty?
      
      raise CannotHandleAspectFirstArgNil if args.first.nil?
      
      raise CannotHandleAspectFirstArgEmpty if args.first.to_s.strip.empty?
      
      unless args.first.to_s.match?(/^\d+(\.\d+)?$/)
        raise CannotHandleAspectInvalidValue(args.first)
      end
    end

    def handle_preserve_aspect(*args)
      @preserve_aspect = args.first
    end

    def handle_font(*args)
      validate_font_args(args)
      @font = args.join(" ")
    end

    private def validate_font_args(args)
      raise CannotHandleFontArgsNil if args.nil?
      
      # Font arguments are optional - empty args array is allowed
      # But if any arguments are provided, they must be valid
      args.each_with_index do |arg, index|
        raise CannotHandleFontArgNil(index + 1) if arg.nil?
        
        raise CannotHandleFontArgEmpty(index + 1) if arg.to_s.strip.empty?
      end
    end
    
    def handle_text_color(*args)
      validate_text_color_args(args)
      @text_color = args.first
    end

    private def validate_text_color_args(args)
      raise CannotHandleTextColorNoArgs if args.nil? || args.empty?
      
      raise CannotHandleTextColorFirstArgNil if args.first.nil?
      
      raise CannotHandleTextColorFirstArgEmpty if args.first.to_s.strip.empty?
    end
    
    def handle_text_align(*args)
      direction = args[0]
      # Apply to both title and subtitle
      handle_title_align(*args)
      handle_subtitle_align(*args)
    end
    
    def handle_scale(which, *args)
      check_invariants
      assume { which.is_a?(String) && !which.empty? }
      assume { args.is_a?(Array) }
      
      if which == "title"
        @title_scale = args.first.to_f
        verify { @title_scale.is_a?(Numeric) && @title_scale > 0 }
      elsif which == "subtitle"
        @subtitle_scale = args.first.to_f
        verify { @subtitle_scale.is_a?(Numeric) && @subtitle_scale > 0 }
      end
      
      check_invariants
    end
    
    def handle_style(which, *args)
      args.each do |arg|
        case
        when which == "title" && arg =~ /bold/i
          @title_weight = "bold"
        when which == "title" && arg =~ /italic/i
          @title_style = "italic"
        when which == "subtitle" && arg =~ /bold/i
          @subtitle_weight = "bold"
        when which == "subtitle" && arg =~ /italic/i
          @subtitle_style = "italic"
        else
          @title_style = arg
          @subtitle_style = arg
        end
      end
    end
    
    def handle_xy(which, *args)
      validate_xy_which(which)
      
      if which == "title"
        @title_xy = args
        @title_xy_set = true
      elsif which == "subtitle"
        @subtitle_xy = args
        @subtitle_xy_set = true
      end
    end

    private def validate_xy_which(which)
      raise CannotHandleXYWhichNil if which.nil?
      
      raise CannotHandleXYWhichEmpty if which.to_s.strip.empty?
      
      unless ["title", "subtitle"].include?(which)
        raise CannotHandleXYInvalidWhich(which)
      end
    end

      private def validate_align_args(args)
    raise CannotHandleAlignNoArgs if args.nil? || args.empty?
    
    raise CannotHandleAlignDirectionNil if args[0].nil? || args[0].to_s.strip.empty?
      
      unless ["left", "center", "right"].include?(args[0])
        raise CannotHandleAlignInvalidDirection(args[0])
      end
      
      # Validate optional x and y arguments if provided
      args.each_with_index do |arg, index|
        next if index == 0 # Skip direction (already validated)
        next if arg.nil? # Allow nil for optional arguments
        raise CannotHandleAlignArgEmpty(index + 1) if arg.to_s.strip.empty?
      end
    end

  def handle_title_align(*args)
    validate_align_args(args)
    direction = args[0]
    x = args[1]
    y = args[2]
    @title_align = direction
    @title_align_x = x
    @title_align_y = y
    # Smart default for x if 'auto'
    if x == 'auto' || x.nil?
      @title_align_x = case direction
        when 'left' then '5%'
        when 'center' then '50%'
        when 'right' then '95%'
        else '5%'
      end
    end
    # Warn if direction and x seem incompatible
    if direction == 'center' && @title_align_x !~ /^50%$/
      warn "[BannerSVG] Warning: title.align center with x=#{@title_align_x} may not be visually centered."
    elsif direction == 'left' && @title_align_x !~ /^5%$/
      warn "[BannerSVG] Warning: title.align left with x=#{@title_align_x} may not be visually left-aligned."
    elsif direction == 'right' && @title_align_x !~ /^95%$/
      warn "[BannerSVG] Warning: title.align right with x=#{@title_align_x} may not be visually right-aligned."
    end
    # Set anchor
    @title_text_anchor = case direction
      when 'left' then 'start'
      when 'center' then 'middle'
      when 'right' then 'end'
      else 'start'
    end
    # Set y if provided
    @title_align_y = y if y
  end

  def handle_subtitle_align(*args)
    validate_align_args(args)
    direction = args[0]
    x = args[1]
    y = args[2]
    @subtitle_align = direction
    @subtitle_align_x = x
    @subtitle_align_y = y
    if x == 'auto' || x.nil?
      @subtitle_align_x = case direction
        when 'left' then '5%'
        when 'center' then '50%'
        when 'right' then '95%'
        else '5%'
      end
    end
    if direction == 'center' && @subtitle_align_x !~ /^50%$/
      warn "[BannerSVG] Warning: subtitle.align center with x=#{@subtitle_align_x} may not be visually centered."
    elsif direction == 'left' && @subtitle_align_x !~ /^5%$/
      warn "[BannerSVG] Warning: subtitle.align left with x=#{@subtitle_align_x} may not be visually left-aligned."
    elsif direction == 'right' && @subtitle_align_x !~ /^95%$/
      warn "[BannerSVG] Warning: subtitle.align right with x=#{@subtitle_align_x} may not be visually right-aligned."
    end
    @subtitle_text_anchor = case direction
      when 'left' then 'start'
      when 'center' then 'middle'
      when 'right' then 'end'
      else 'start'
    end
    @subtitle_align_y = y if y
  end

  def handle_title_color(*args)
    validate_color_args(args)
    @title_color = args.first
  end

  def handle_subtitle_color(*args)
    validate_color_args(args)
    @subtitle_color = args.first
  end



  private def validate_color_args(args)
    raise CannotHandleColorNoArgs if args.nil? || args.empty?
    
    raise CannotHandleColorFirstArgNil if args.first.nil?
    
    raise CannotHandleColorFirstArgEmpty if args.first.to_s.strip.empty?
  end
  
    def parse_header_svg(config_file = "config.txt")
      check_invariants
      assume { config_file.is_a?(String) && !config_file.empty? }
      
      lines = read_commented_file(config_file)
  
      # Parse config into a hash
      cfg = {}
      lines.each do |line|
        key, *values = line.split(/\s+/)
        cfg[key.strip] = Array(values) if key && values
      end
    
      # Use instance variables instead of local variables
      handlers = {
        "back.color"     => ->(args) { handle_background(*args) },
        "back.linear"    => ->(args) { handle_linear_gradient(*args) },
        "back.radial"    => ->(args) { handle_radial_gradient(*args) },
        "back.image"     => ->(args) { handle_image_background(*args) },
        "aspect"         => ->(args) { handle_aspect(*args) },
        "preserve_aspect" => ->(args) { handle_preserve_aspect(*args) },
        "text.font"      => ->(args) { handle_font(*args) },
        "text.color"     => ->(args) { handle_text_color(*args) },
        "title.color"    => ->(args) { handle_title_color(*args) },
        "subtitle.color" => ->(args) { handle_subtitle_color(*args) },

        "title.align"    => ->(args) { handle_title_align(*args) },
        "subtitle.align" => ->(args) { handle_subtitle_align(*args) },
        "title.scale"    => ->(args) { handle_scale("title", *args) },
        "subtitle.scale" => ->(args) { handle_scale("subtitle", *args) },
        "title.style"    => ->(args) { handle_style("title", *args) },
        "subtitle.style" => ->(args) { handle_style("subtitle", *args) },
        "title.xy"       => ->(args) { handle_xy("title", *args) },   
        "subtitle.xy"    => ->(args) { handle_xy("subtitle", *args) },
        "text.align"     => ->(args) { handle_text_align(*args) }
      }

      cfg.each_pair do |key, args|
        handler = handlers[key]
        if handler
          # Skip malformed lines (empty args) to avoid validation errors
          next if args.nil? || args.empty?
          handler.call(args)
        end
      end
      
      # Check for align/xy conflicts and warn
      # Note: xy coordinates take precedence over align coordinates when both are set
      if @title_align && @title_xy && @title_align_x && @title_xy[0] && @title_align_x != @title_xy[0]
        warn "[BannerSVG] Warning: title.align x=#{@title_align_x} conflicts with title.xy x=#{@title_xy[0]} (xy will override)"
      end
      if @subtitle_align && @subtitle_xy && @subtitle_align_x && @subtitle_xy[0] && @subtitle_align_x != @subtitle_xy[0]
        warn "[BannerSVG] Warning: subtitle.align x=#{@subtitle_align_x} conflicts with subtitle.xy x=#{@subtitle_xy[0]} (xy will override)"
      end

      # Set base font size
      base_font_size = 60
      title_font_size = (base_font_size * @title_scale).to_i
      subtitle_font_size = (base_font_size * @subtitle_scale).to_i

      width = 800     # Arbitrary starting point for calculations
      height = (width / @aspect).to_i  # height calculated based on aspect ratio
  
      # Handle background (image, radial gradient, linear gradient, or solid color)
      background_svg = ""
      if @image_background
        # Generate image background
        background_svg = <<~IMAGE
          <defs>
            <pattern id="bg-pattern" x="0" y="0" width="100%" height="100%" patternUnits="objectBoundingBox">
              <image href="#{@image_background}" x="0" y="0" width="100%" height="100%" 
                     preserveAspectRatio="xMidYMid slice" />
            </pattern>
          </defs>
          <rect x='0' y='0' width='100%' height='100%' fill='url(#bg-pattern)' />
        IMAGE
      elsif @radial_start_color && @radial_end_color
        # Generate radial gradient
        background_svg = <<~RADIAL
          <defs>
            <radialGradient id="radial1" cx="50%" cy="50%" r="50%">
              <stop offset="0%" style="stop-color:#{@radial_start_color};stop-opacity:1" />
              <stop offset="100%" style="stop-color:#{@radial_end_color};stop-opacity:1" />
            </radialGradient>
          </defs>
          <rect x='0' y='0' width='100%' height='100%' fill='url(#radial1)' />
        RADIAL
      elsif @gradient_start_color && @gradient_end_color
        # Generate linear gradient
        directions = {
          "lr" => ["0%", "0%", "100%", "0%"],
          "tb" => ["0%", "0%", "0%", "100%"],
          "ul-lr" => ["0%", "0%", "100%", "100%"],
          "ll-ur" => ["0%", "100%", "100%", "0%"]
        }
        
        direction_coords = directions[@gradient_direction] || directions["lr"]
        x1, y1, x2, y2 = direction_coords
        
        background_svg = <<~GRADIENT
          <defs>
            <linearGradient id="grad1" x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}">
              <stop offset="0%" style="stop-color:#{@gradient_start_color};stop-opacity:1" />
              <stop offset="100%" style="stop-color:#{@gradient_end_color};stop-opacity:1" />
            </linearGradient>
          </defs>
          <rect x='0' y='0' width='100%' height='100%' fill='url(#grad1)' />
        GRADIENT
      else
        # Solid color background
        background_svg = "<rect x='0' y='0' width='100%' height='100%' fill='#{@background}' />"
      end
      
      # Build style strings
      title_style =  "font-family: #{@font}; "
      title_style << "font-size: #{title_font_size}px; "
      title_style << "font-weight: #{@title_weight}; "
      title_style << "font-style: #{@title_style}"
      
      subtitle_style =  "font-family: #{@font}; "
      subtitle_style << "font-size: #{subtitle_font_size}px; "
      subtitle_style << "font-weight: #{@subtitle_weight}; "
      subtitle_style << "font-style: #{@subtitle_style}"
      
      # Get xy coordinates if set, otherwise use alignment fallbacks
      if @title_xy_set && @title_xy
        title_x = @title_xy[0]
        title_y = @title_xy[1]
      else
        title_x = @title_align_x || '5%'
        title_y = @title_align_y || '52%'
      end
      if @subtitle_xy_set && @subtitle_xy
        subtitle_x = @subtitle_xy[0]
        subtitle_y = @subtitle_xy[1]
      else
        subtitle_x = @subtitle_align_x || '5%'
        subtitle_y = @subtitle_align_y || '82%'
      end
      
      title_svg = <<~EOS
        <text x='#{title_x}' 
              y='#{title_y}' 
              text-anchor='#{@text_anchor}'
              style='#{title_style}' 
              fill='#{@text_color}'>#@title</text>
      EOS
      
      # Call generate_svg to return the complete SVG
      generate_svg
    end
    
    def generate_svg
      check_invariants
      
      # Set base font size
      base_font_size = 60
      title_font_size = (base_font_size * @title_scale).to_i
      subtitle_font_size = (base_font_size * @subtitle_scale).to_i

      width = 800     # Arbitrary starting point for calculations
      height = (width / @aspect).to_i  # height calculated based on aspect ratio
  
      # Handle background (image, radial gradient, linear gradient, or solid color)
      background_svg = ""
      if @image_background
        # Generate image background
        background_svg = <<~IMAGE
          <defs>
            <pattern id="bg-pattern" x="0" y="0" width="100%" height="100%" patternUnits="objectBoundingBox">
              <image href="#{@image_background}" x="0" y="0" width="100%" height="100%" 
                     preserveAspectRatio="xMidYMid slice" />
            </pattern>
          </defs>
          <rect x='0' y='0' width='100%' height='100%' fill='url(#bg-pattern)' />
        IMAGE
      elsif @radial_start_color && @radial_end_color
        # Calculate aspect ratio compensation for gradientTransform
        ar = @radial_ar || (1.0 / @aspect)
        # Compensate cx for X scaling so that cx visually matches the intended center
        cx_val = @radial_cx
        if cx_val.is_a?(String) && cx_val.strip.end_with?('%')
          cx_num = cx_val.strip.chomp('%').to_f
          cx_val = (cx_num / ar).to_s + '%'
        end
        gradient_transform = "gradientTransform=\"scale(#{ar},1)\"" if ar
        background_svg = <<~RADIAL
          <defs>
            <radialGradient id="radial1" cx="#{cx_val}" cy="#{@radial_cy}" r="#{@radial_r}" #{gradient_transform}>
              <stop offset="0%" style="stop-color:#{@radial_start_color};stop-opacity:1" />
              <stop offset="100%" style="stop-color:#{@radial_end_color};stop-opacity:1" />
            </radialGradient>
          </defs>
          <rect x='0' y='0' width='100%' height='100%' fill='url(#radial1)' />
        RADIAL
      elsif @gradient_start_color && @gradient_end_color
        # Generate linear gradient
        directions = {
          "lr" => ["0%", "0%", "100%", "0%"],
          "tb" => ["0%", "0%", "0%", "100%"],
          "ul-lr" => ["0%", "0%", "100%", "100%"],
          "ll-ur" => ["0%", "100%", "100%", "0%"]
        }
        
        direction_coords = directions[@gradient_direction] || directions["lr"]
        x1, y1, x2, y2 = direction_coords
        
        background_svg = <<~GRADIENT
          <defs>
            <linearGradient id="grad1" x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}">
              <stop offset="0%" style="stop-color:#{@gradient_start_color};stop-opacity:1" />
              <stop offset="100%" style="stop-color:#{@gradient_end_color};stop-opacity:1" />
            </linearGradient>
          </defs>
          <rect x='0' y='0' width='100%' height='100%' fill='url(#grad1)' />
        GRADIENT
      else
        # Solid color background
        background_svg = "<rect x='0' y='0' width='100%' height='100%' fill='#{@background}' />"
      end
      
      # Build style strings
      title_style =  "font-family: #{@font}; "
      title_style << "font-size: #{title_font_size}px; "
      title_style << "font-weight: #{@title_weight}; "
      title_style << "font-style: #{@title_style}"
      
      subtitle_style =  "font-family: #{@font}; "
      subtitle_style << "font-size: #{subtitle_font_size}px; "
      subtitle_style << "font-weight: #{@subtitle_weight}; "
      subtitle_style << "font-style: #{@subtitle_style}"
      
      title_color = @title_color || @text_color
      subtitle_color = @subtitle_color || @text_color
      
      # Get xy coordinates if set, otherwise use alignment fallbacks
      if @title_xy_set && @title_xy
        title_x = @title_xy[0]
        title_y = @title_xy[1]
      else
        title_x = @title_align_x || '5%'
        title_y = @title_align_y || '52%'
      end
      
      if @subtitle_xy_set && @subtitle_xy
        subtitle_x = @subtitle_xy[0]
        subtitle_y = @subtitle_xy[1]
      else
        subtitle_x = @subtitle_align_x || '5%'
        subtitle_y = @subtitle_align_y || '82%'
      end
      
      title_anchor = @title_text_anchor || @text_anchor
      subtitle_anchor = @subtitle_text_anchor || @text_anchor
      
      title_svg = <<~EOS
        <text x='#{title_x}' 
              y='#{title_y}' 
              text-anchor='#{title_anchor}'
              style='#{title_style}' 
              fill='#{title_color}'>#@title</text>
      EOS
      subtitle_svg = <<~EOS
        <text x='#{subtitle_x}' 
              y='#{subtitle_y}' 
              text-anchor='#{subtitle_anchor}'
              style='#{subtitle_style}' 
              fill='#{subtitle_color}'>#@subtitle</text>
      EOS
      
      # Define the SVG output
      # Use different preserveAspectRatio for radial gradients to maintain circular shape
      preserve_aspect = if @radial_start_color && @radial_end_color && @preserve_aspect
        @preserve_aspect
      elsif @radial_start_color && @radial_end_color
        'xMidYMid slice'  # Default for radial gradients: crop to maintain aspect ratio
      else
        'xMidYMid meet'   # Default for other backgrounds: fit within bounds
      end
      
      svg = <<~SVG
        <svg xmlns='http://www.w3.org/2000/svg' 
             width='100%' height='#{height}' 
             viewBox='0 0 #{width} #{height}' 
             preserveAspectRatio='#{preserve_aspect}'>
          #{background_svg}
          #{title_svg}
          #{subtitle_svg}
        </svg>
      SVG
  
      svg
    end
  
    def get_svg
      check_invariants
      
      # Generate SVG without re-parsing config (use current instance variables)
      svg_code = generate_svg
      svg_lines = svg_code.split("\n").map {|line| " "*6 + line }
      svg_code  = svg_lines.join("\n")
  
      # Calculate coordinates safely
      title_x = @title_xy_set && @title_xy ? @title_xy[0] : (@title_align_x || '5%')
      title_y = @title_xy_set && @title_xy ? @title_xy[1] : (@title_align_y || '52%')
      subtitle_x = @subtitle_xy_set && @subtitle_xy ? @subtitle_xy[0] : (@subtitle_align_x || '5%')
      subtitle_y = @subtitle_xy_set && @subtitle_xy ? @subtitle_xy[1] : (@subtitle_align_y || '82%')
      
      code = <<~EOS
        <script>
          function insert_svg_header(container) {
            const svg_text = `#{svg_code}`;
            const svgElement = document.createElement('div');
            svgElement.innerHTML = svg_text;
            const svg = svgElement.firstElementChild;
        
            const svgWidth = window.innerWidth;
            const aspectRatio = #{@aspect};
            const svgHeight = svgWidth / aspectRatio;
        
            svg.setAttribute('viewBox', `0 0 ${svgWidth} ${svgHeight}`);
            svg.setAttribute('width', svgWidth);
            svg.setAttribute('height', svgHeight);
        
            const titleScale = #{@title_scale};
            const subtitleScale = #{@subtitle_scale};
        
            const base_font_size = 60;
            const titleFontSize = titleScale * base_font_size;
            const subtitleFontSize = subtitleScale * base_font_size;
        
            const te1 = svg.querySelector('text:nth-of-type(1)')
            const te2 = svg.querySelector('text:nth-of-type(2)')
            
            // Don't override the styles - they're already set correctly in the SVG
            // Just update the positioning and text-anchor
            
            const titleXpct = "#{title_x}";
            const titleYpct = "#{title_y}";
            const subtitleXpct = "#{subtitle_x}";
            const subtitleYpct = "#{subtitle_y}";
        
            const tX = svgWidth  * (parseFloat(titleXpct) / 100);
            const tY = svgHeight * (parseFloat(titleYpct) / 100);
            const sX = svgWidth  * (parseFloat(subtitleXpct) / 100);
            const sY = svgHeight * (parseFloat(subtitleYpct) / 100);
        
            te1.setAttribute('x', tX);
            te1.setAttribute('y', tY);
            te2.setAttribute('x', sX);
            te2.setAttribute('y', sY);
            
            // Set text-anchor for proper positioning (use individual anchors if set)
            te1.setAttribute('text-anchor', '#{@title_text_anchor || @text_anchor}');
            te2.setAttribute('text-anchor', '#{@subtitle_text_anchor || @text_anchor}');
        
            const containerElement = document.getElementById(container);
          if (containerElement) {
            console.log('Container found, inserting SVG...');
            containerElement.innerHTML = svg.outerHTML;
            console.log('SVG inserted successfully');
          } else {
            console.error('Container not found:', container);
          }
          }
        
                  console.log('SVG script loaded');
        console.log('Header element exists:', !!document.querySelector('header'));
        
        window.onload = function() {
          console.log('SVG insertion starting...');
          insert_svg_header('header');
          console.log('SVG insertion complete');
        }
        
        // Also try immediate execution
        document.addEventListener('DOMContentLoaded', function() {
          console.log('DOM ready, trying SVG insertion...');
          insert_svg_header('header');
        });
        </script>
      EOS
      code
    end
  
    # How to call??  bsvg = BannerSVG.new(...); bsvg.parse_svg_header; code = bsvg.get_svg  # Simplify?
    # Doesn't output, just returns string...
  
  end