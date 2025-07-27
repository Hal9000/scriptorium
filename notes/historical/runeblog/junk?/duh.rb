require 'runeblog'
require 'livetext'
require 'liveblog'
require 'pathmagic'

@blog = RuneBlog.new

Dir.chdir(".blogs/views/around_austin/themes/standard")

tag = "pinned"
wtag = :widgets/tag

    code = _load_local(tag)
    if code 
      Dir.chdir(wtag) do 
        widget = code.new(@blog)
        widget.build
      end
    end

