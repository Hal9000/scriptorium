class Scriptorium::Post
    include Scriptorium::Exceptions
    include Scriptorium::Helpers

    attr_reader :repo, :num, :id
  
    def initialize(repo, num)
      validate_initialization(repo, num)
      
      @repo = repo
      @num = d4(num.to_i)  # num is zero-padded string
      @id = num.to_i       # id is integer
      @meta = nil  # Explicitly initialize for clarity
    end

    private def validate_initialization(repo, num)
      raise CannotCreatePostRepoNil if repo.nil?
      raise CannotCreatePostNumNil if num.nil?
      raise CannotCreatePostNumEmpty if num.to_s.strip.empty?
      raise CannotCreatePostNumInvalid(num) unless num.to_s.match?(/^\d+$/)
    end
  
    def dir
      repo.root/:posts/@num
    end
  
    def meta_file
      # Check if post is in deleted directory (with underscore prefix)
      deleted_meta = @repo.root/:posts/"_#{@num}"/"meta.txt"
      return deleted_meta if File.exist?(deleted_meta)
      
      # Otherwise use normal directory
      @repo.root/:posts/@num/"meta.txt"
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

    def set_pubdate(ymd, seconds: 0)
      raise TestModeOnly unless Scriptorium::Repo.testing
      
      validate_date_format(ymd)
      
      yyyy, mm, dd = ymd.split("-")
      t = Time.new(yyyy.to_i, mm.to_i, dd.to_i, 0, 0, seconds)
      
      update_pubdate_metadata(t)
      save_metadata
    end

    private def validate_date_format(date)
      raise CannotSetPubdateYmdNil if date.nil?
      raise CannotSetPubdateYmdEmpty if date.to_s.strip.empty?
      raise CannotSetPubdateInvalidFormat(date) unless date.to_s.match?(/^\d{4}-\d{2}-\d{2}$/)
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
      meta["post.deleted"] == "true"
    end

    def deleted=(value)
      meta["post.deleted"] = value ? "true" : "false"
      save_metadata
    end

    # New method to access multiple attributes at once
    def attrs(*keys)
        keys.map { |key| send(key) }
    end

    # New class method to read metadata and initialize the Post
    def self.read(repo, num)
      post = new(repo, num)
      post.load_metadata
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
      @meta = {}
      @repo.tree("/tmp/tree.txt")
      read_file(meta_file, lines: true, chomp: true).each do |line|
        key, value = line.strip.split(/\s+/, 2)
        next if key.nil? || key.empty?
        @meta[key] = value
      end 
      @meta
    end

    def save_metadata
      lines = @meta.map { |k, v| sprintf("%-18s  %s", k, v) }
      write_file(meta_file, lines.join("\n"))
    end
  end
  