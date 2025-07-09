module Scriptorium
    class Post
      attr_reader :repo, :num
  
      def initialize(repo, num)
        @repo = repo
        @num = num.to_s.rjust(4, "0")
      end
  
      def dir
        repo.root/:posts/@num
      end
  
      def meta_file
        dir/"meta.txt"
      end
  
      def meta
        return @meta if defined?(@meta)
        return @meta = {} unless File.exist?(meta_file)
        @meta = {}
        File.readlines(meta_file, chomp: true).each do |line|
          key, value = line.strip.split(/\s+/, 2)
          @meta[key] = value
        end
        @meta
      end
  
      def pubdate
        meta["post.pubdate"]
      end
  
      def title
        meta["post.title"]
      end
  
      def slug
        meta["post.slug"]
      end
    end
  end
  