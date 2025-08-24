class Scriptorium::Post
    include Scriptorium::Exceptions
    include Scriptorium::Helpers
    include Scriptorium::Contract

    attr_reader :repo, :num, :id
  
    def initialize(repo, num)
      assume { repo.is_a?(Scriptorium::Repo) }
      assume { num.is_a?(Integer) || num.is_a?(String) }
      validate_initialization(repo, num)
      
      @repo = repo
      @num = d4(num.to_i)  # num is zero-padded string
      @id = num.to_i       # id is integer
      @meta = nil  # Explicitly initialize for clarity
      
      # Define invariants
      invariant { @id > 0 }
      invariant { @repo.is_a?(Scriptorium::Repo) }
      invariant { @num.match?(/^\d{4}$/) }
    end

    private def validate_initialization(repo, num)
      raise PostRepoNil if repo.nil?
      raise PostNumNil if num.nil?
      raise PostNumEmpty if num.to_s.strip.empty?
      raise PostNumInvalid(num) unless num.to_s.match?(/^\d+$/)
    end
  
    def dir
      repo.root/:posts/@num
    end
  
    def meta_file
      # Check what directory actually exists
      normal_dir = @repo.root/:posts/@num
      deleted_dir = @repo.root/:posts/"_#{@num}"
      
      if Dir.exist?(normal_dir)
        # Normal post directory exists
        normal_dir/"meta.txt"
      elsif Dir.exist?(deleted_dir)
        # Deleted post directory exists
        deleted_dir/"meta.txt"
      else
        # Neither exists - post never existed
        raise "Post directory for #{@num} not found"
      end
    end

    def validate_metadata_consistency
      return unless File.exist?(meta_file)
      
      normal_dir = @repo.root/:posts/@num
      deleted_dir = @repo.root/:posts/"_#{@num}"
      metadata_deleted = meta["post.deleted"] == "true"
      
      if Dir.exist?(normal_dir) && metadata_deleted
        raise "Inconsistency: Post #{@num} has normal directory but metadata shows deleted=true"
      elsif Dir.exist?(deleted_dir) && !metadata_deleted
        raise "Inconsistency: Post #{@num} has deleted directory but metadata shows deleted=false"
      end
    end
  


    def blurb
      meta["post.blurb"]
    end
  
    def title
      meta["post.title"]
    end
  
    def slug
      meta["post.slug"]
    end

    def pubdate
      meta["post.pubdate"]
    end
    
    def created
      meta["post.created"]
    end
    
    def date
      pubdate || created
    end

    def set_pubdate(ymd, seconds: 0)
      check_invariants
      assume { Scriptorium::Repo.testing }
      assume { ymd.is_a?(String) }
      assume { seconds.is_a?(Integer) && seconds >= 0 }
      
      raise TestModeOnly unless Scriptorium::Repo.testing
      
      validate_date_format(ymd)
      
      yyyy, mm, dd = ymd.split("-")
      t = Time.new(yyyy.to_i, mm.to_i, dd.to_i, 0, 0, seconds)
      
      update_pubdate_metadata(t)
      save_metadata
      
      verify { meta["post.pubdate"].is_a?(String) }
      check_invariants
    end

    private def validate_date_format(date)
      raise PubdateYmdNil if date.nil?
      raise PubdateYmdEmpty if date.to_s.strip.empty?
      raise PubdateInvalidFormat(date) unless date.to_s.match?(/^\d{4}-\d{2}-\d{2}$/)
    end

    private def update_pubdate_metadata(time)
      meta["post.pubdate"] = time.strftime("%Y-%m-%d %H:%M:%S") 
      meta["post.pubdate.month"] = time.strftime("%B") 
      meta["post.pubdate.day"] = time.strftime("%e") 
      meta["post.pubdate.year"] = time.strftime("%Y") 
    end

    # Legacy method for backward compatibility - preserves 12:00 base time
    def set_pubdate_with_seconds(ymd, seconds)
      raise TestModeOnly unless Scriptorium::Repo.testing
      
      validate_date_format(ymd)
      
      yyyy, mm, dd = ymd.split("-")
      t = Time.new(yyyy.to_i, mm.to_i, dd.to_i, 12, 0, seconds)  # 12:00:XX for ordering
      
      update_pubdate_metadata(t)
      save_metadata
    end

    def pubdate_month_day_year
      [meta["post.pubdate.month"], meta["post.pubdate.day"], meta["post.pubdate.year"]]
    end

    def views
      meta["post.views"]
    end

    def views_array
      views_str = meta["post.views"]
      return [] if views_str.nil? || views_str.strip.empty?
      views_str.strip.split(/\s+/)
    end

    def tags
      meta["post.tags"]
    end

    def deleted
      # Check what directory actually exists
      normal_dir = @repo.root/:posts/@num
      deleted_dir = @repo.root/:posts/"_#{@num}"
      
      if Dir.exist?(deleted_dir)
        true
      elsif Dir.exist?(normal_dir)
        false
      else
        # Neither exists - post never existed
        raise "Post directory for #{@num} not found"
      end
    end

    def deleted=(value)
      check_invariants
      assume { [true, false].include?(value) }
      
      meta["post.deleted"] = value ? "true" : "false"
      save_metadata
      
      verify { meta["post.deleted"] == (value ? "true" : "false") }
      check_invariants
    end

    # New method to access multiple attributes at once
    def attrs(*keys)
        keys.map { |key| send(key) }
    end

    # New class method to read metadata and initialize the Post
    def self.read(repo, num, deleted: false)
      post = new(repo, num)
      post.load_metadata
      post.validate_metadata_consistency
      post
    end
  
    def meta
      return @meta if @meta
      @meta = File.exist?(meta_file) ? load_metadata : {}
    end

    def vars
      return @vars if defined?(@vars)
      @vars = Hash.new("")
      meta.each_pair {|k,v| @vars[k.to_sym] = v }
      @vars
    end

    # Additional method to load metadata explicitly, so it's only called once
    def load_metadata
      check_invariants
      assume { File.exist?(meta_file) }
      
      @meta = {}
      @repo.tree("/tmp/tree.txt")
      read_file(meta_file, lines: true, chomp: true).each do |line|
        key, value = line.strip.split(/\s+/, 2)
        next if key.nil? || key.empty?
        @meta[key] = value
      end 
      
      verify { @meta.is_a?(Hash) }
      check_invariants
      @meta
    end

    def save_metadata
      check_invariants
      assume { @meta.is_a?(Hash) }
      assume { !@meta.empty? }
      
      lines = @meta.map { |k, v| sprintf("%-18s  %s", k, v) }
      write_file(meta_file, lines.join("\n"))
      
      verify { File.exist?(meta_file) }
      check_invariants
    end
  end
  