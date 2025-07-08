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
  
      def pubdate
        lines = File.readlines(meta_file, chomp: true)
        lines.each do |line|
          key, value = line.strip.split(/\s+/, 2)
          return value if key == "pubdate"
        end
        nil
      end
  
      def title
        lines = File.readlines(meta_file, chomp: true)
        lines.each do |line|
          key, value = line.strip.split(/\s+/, 2)
          return value if key == "title"
        end
        nil
      end
  
      def slug
        lines = File.readlines(meta_file, chomp: true)
        lines.each do |line|
          key, value = line.strip.split(/\s+/, 2)
          return value if key == "slug"
        end
        nil
      end
  
      # Add other accessors as needed (e.g., views, tags)
    end
  end
  