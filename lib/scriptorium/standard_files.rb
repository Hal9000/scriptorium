class Scriptorium::StandardFiles

  # This class generates standard file content for new posts, views, etc.

  include Scriptorium::Helpers

  def initialize   # remove?
  end

  def initial_post(mode = :filled, 
                    num:   "0", 
                    title: "ADD TITLE HERE", 
                    views: %w[BLOG1 BLOG2 BLOG3],
                    tags:  %w[sample tags])
    title ||= "standard/post_template.lt3"
    views ||= %w[BLOG1 BLOG2 BLOG3]
    tags  ||= %w[sample tags]
    
    str = 
    <<~EOS
      . Initial file created by StandardFiles#post_template(num)
      
      .id %{num}
      .created %{created}
      
      .title %{title}
      
      .views %{views}  
      .tags  %{tags}   
      
      .body
        BEGIN HERE...
      .end
    EOS

    return str if mode == :raw

    str2 = str % {num: d4(num.to_i), created: ymdhms, title: title, 
                  views: views.join(" "), tags: tags.join(", ")}
    return str2
  end

  def post_template
    str = <<~EOS
      <div style="display: flex; justify-content: space-between;">
        <span style="text-align: left; font-size: 1.2em;">%{title}</span>
        <span style="text-align: right; font-size: 0.9em;">%{pubdate}</span>
      </div>
      <hr>
      %{body}
      <hr>
      <span style="text-align: right; font-size: 0.9em;">%{tags}</span>
    EOS
  end

end