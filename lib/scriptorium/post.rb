class Scriptorium::Post
    attr_reader :repo, :num
  
    def initialize(repo, num)
      @repo = repo
      @num = num.to_s.rjust(4, "0")
      @metadata = load_metadata
    end
  
    def dir
      repo.root / :posts / @num
    end
  
    def meta_file
      dir / "meta.txt"
    end
  
    def load_metadata
      return {} unless File.exist?(meta_file)
      lines = File.readlines(meta_file, chomp: true)
      lines.each_with_object({}) do |line, hash|
        key, value = line.strip.split(/\s+/, 2)
        hash[key] = value
      end
    end
  
    def pubdate
      @metadata["post.pubdate"]
    end
  
    def title
      @metadata["post.title"]
    end
  
    def slug
      @metadata["post.slug"]
    end
  
    # Add other accessors as needed
  end
  