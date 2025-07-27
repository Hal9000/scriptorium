
def makehead(title, subtitle)
  @vbx, @vby = 440, 44
  @heavy = %w[bold 24 sans-serif #aa8800]
  @small = %w[italic 9 sans-serif #ff1100]
  @wrect, @hrect, @fillrect = 240, 40, "rust"
  @txy = 5, 22
  @sxy = 110, 36
  #---
  @h1, @h2, @h3, @h4 = *@heavy
  @s1, @s2, @s3, @s4 = *@small
  @tx, @ty = *@txy
  @sx, @sy = *@sxy
  code = <<~HTML
  <svg viewBox="0 0 #@vbx #@vby">
    <style>
      .heavy { font: #@h1 #{@h2}px #@h3; fill: @h4 }
      .small { font: #@s1 #{@s2}px #@s3; fill: @s4 }
    </style>
  <rect x="0" y="0" rx="3" ry="3" width="#@wrect" height="#@hrect" 
        fill="#@rectfill"/>
  <text x="#@tx" y="#@ty" class=heavy>#{title}</text>
  <text x="#@sx" y="#@sy" class=small>#{subtitle}</text>
  </svg>
  HTML
end

puts makehead("A Place for My Stuff", "with apologies to george carlin")
