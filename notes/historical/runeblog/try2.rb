require 'livetext'

Log = File.new("/tmp/mylog", "w")

def log(str)
  Log.puts ("Logged: #{str}")
end


log "line 1"

live = Livetext.customize(mix: "liveblog")

src = "mytext.lt3"

live.xform_file(src)


log "line 3"
