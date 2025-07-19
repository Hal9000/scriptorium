class Scriptorium::Post
    include Scriptorium::Helpers

    attr_reader :repo, :num
  
    def initialize(repo, num)
      @repo = repo
      @num = num.to_s.rjust(4, "0")
    end
  
    def dir
      repo.root/:posts/@num
    end
  
    def meta_file
      @repo.root/:posts/@num/"meta.txt"
    end
  
    def id
      num
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

    def set_pubdate(ymd)
      raise TestModeOnly unless Scriptorium::Repo.testing
      yyyy, mm, dd = ymd.split("-")
      t = Time.new(yyyy.to_i, mm.to_i, dd.to_i)
      meta["post.pubdate"] = t.strftime("%Y-%m-%d %H:%M:%S") 
      meta["post.pubdate.month"] = t.strftime("%B") 
      meta["post.pubdate.day"] = t.strftime("%e") 
      meta["post.pubdate.year"] = t.strftime("%Y") 
      save_metadata   # Because it changed
    end

    def pubdate_month_day_year
      [meta["post.pubdate.month"], meta["post.pubdate.day"], meta["post.pubdate.year"]]
    end

    def views
      meta["post.views"]
    end

    def tags
      meta["post.tags"]
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
      return @meta if defined?(@meta)
      return @meta = {} unless File.exist?(meta_file)
      @meta = load_metadata
    end


    def vars
      return @vars if defined?(@vars)
      @vars = Hash.new("")
      meta.each_pair {|k,v| @vars[k.to_sym] = v }
      @vars
    end

    # Additional method to load metadata explicitly, so it’s only called once
    def load_metadata
      @meta = {}
      @repo.tree("/tmp/tree.txt")
      File.readlines(meta_file, chomp: true).each do |line|
        key, value = line.strip.split(/\s+/, 2)
        next if key.nil? || key.empty?
        @meta[key] = value
      end 
      @meta
    end

    def save_metadata
      File.open(meta_file, "w") do |f|
        @meta.each_pair {|k,v| f.printf "%-18s  %s\n", k, v }
      end
    end
  end
  