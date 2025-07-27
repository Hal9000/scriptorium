require 'livetext'

src = "foobar.lt3"

live = Livetext.customize(mix: "liveblog", call: ".nopara", vars: {myvar: 237})
checkpoint "Calling xform_file... live = #{live.inspect}"
# log!(str: "Calling xform_file... src = #{src} pwd = #{Dir.pwd}")
out = live.xform_file(src)


puts "----- out ="
p out
