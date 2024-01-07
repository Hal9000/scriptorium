require 'date'
require 'find'

$LOAD_PATH << "lib"

require "scriptorium/version"

Gem.post_install do |spec|
  Dir.chdir(Scriptorium::Path)
  # system("livetext -i liveblog.rb")
  system("livetext -i code_rouge.rb")
end

spec = Gem::Specification.new do |s|
  system("rm -f *.gem")
  s.name        = 'runeblog'
  s.version     = Scriptorium::VERSION
  s.date        = Date.today.strftime("%Y-%m-%d")
  s.summary     = "A command-line blogging system"
  s.description = "A blog system based on Ruby and Livetext"
  s.authors     = ["Hal Fulton"]
  s.email       = 'rubyhacker@gmail.com'
  s.executables << "blog"

  s.add_runtime_dependency 'livetext', '~> 0.9',  '>= 0.9.41'
  s.add_runtime_dependency 'rubytext', '~> 0.1',  '>= 0.1.26'
  s.add_runtime_dependency 'rouge',    '~> 3.25', '>= 3.25.0'

  s.add_development_dependency 'minitest', '~> 5.10', '>= 5.10.0'

  # Files...

  main = Find.find("bin").to_a + 
         Find.find("lib").to_a + 
         Find.find("readme").to_a
  test = Find.find("test").to_a

  misc = %w[./README.lt3 ./README.md ./runeblog.gemspec]

  s.files       =  main + misc + test
  s.homepage    = 'https://github.com/Hal9000/scriptorium'
  s.license     = "Ruby"
  s.post_install_message = 
                  "\n  Success! Run 'sblog' command and type h for help.\n "
end

spec

