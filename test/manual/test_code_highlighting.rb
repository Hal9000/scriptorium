require_relative "./environment"

manual_setup

@repo.create_view("testview", "Test View", "A test view for manual inspection")

# Post with code highlighting
draft_body = <<~BODY
  .blurb Testing code highlighting with Prism.
  This post tests the .code function and Prism syntax highlighting.

  Here's some Ruby code:

  .code ruby
  def hello_world
    puts "Hello, World!"
    @greeting = "Welcome to Scriptorium"
    return @greeting
  end
  .end

  And some JavaScript:

  .code javascript
  function greet(name) {
    console.log("Hello, " + name);
    return "Greeting sent";
  }
  .end

  And plain text:

  .code text
  This is just plain text
  No syntax highlighting needed
  But it should still be in a code block
  .end

  And some more Ruby:

  .code ruby
  class Example
    def initialize
      @data = []
    end
    
    def add_item(item)
      @data << item
    end
  end
  .end
BODY

name = @repo.create_draft(title: "Code Highlighting Test", views: ["testview"], body: draft_body)
num = @repo.finish_draft(name)
@repo.generate_post(num)

@repo.generate_front_page("testview")

instruct <<~EOS
  Front page should have one post with code highlighting.
  Ruby code should be highlighted with Ruby syntax.
  JavaScript code should be highlighted with JS syntax.
  Plain text should be in code blocks but not highlighted.
  Check that Prism CSS and JS are included in the generated HTML.
EOS

examine("testview")
