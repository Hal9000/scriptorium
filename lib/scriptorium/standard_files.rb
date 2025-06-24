class Scriptorium::StandardFiles

  # This class generates standard file content for new posts, views, etc.

  include Scriptorium::Helpers

  def initialize   # remove?
  end

  def post_template(mode = :filled, 
                    num:   "0", 
                    title: "ADD TITLE HERE", 
                    views: %w[BLOG1 BLOG2 BLOG3],
                    tags:  %w[sample tags])
    fname = "themes/standard/post_template.lt3"
    return fname if mode == :name
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

end
