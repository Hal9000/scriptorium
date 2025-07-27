
def image   # primitive so far
  fname = _args.first
  path = "assets/#{fname}"
  _out "<img src=#{path}></img>"
  _optional_blank_line
end

def image!
  fname, w, h, factor, alt = _data.split(" ", 5)
  path = "assets/#{fname}"
  alt.gsub!("'", "&apos;")
  alt.gsub!("\"", "&quot;")
  _out <<-HTML
    <a href=#{path} target=_blank
       title='#{alt} (click to open)'>
      <img src=#{path} width=#{w.to_i/factor.to_i} 
        height=#{h.to_i/factor.to_i}
        alt='#{alt}'>
      </img>
    </a>
  HTML
  _optional_blank_line
end

