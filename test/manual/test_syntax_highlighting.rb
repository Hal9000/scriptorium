require_relative "./environment"

manual_setup

@repo.create_view("testview", "Test View", "A test view for manual inspection")

# Ensure Highlight.js is enabled via global-head.txt
global_head_file = "test/scriptorium-TEST/views/testview/config/global-head.txt"
head_contents = File.exist?(global_head_file) ? File.read(global_head_file) : ""
add_lines = []
add_lines << "highlight      # Enable Highlight.js assets" unless head_contents.include?("\nhighlight")
add_lines << "highlight_custom # Optional Highlight.js CSS overrides" unless head_contents.include?("\nhighlight_custom")
unless add_lines.empty?
  File.open(global_head_file, "a") { |f| add_lines.each { |ln| f.puts ln } }
end

# Post with comprehensive syntax highlighting tests
draft_body = <<~'BODY'
  .blurb
  Testing Highlight.js syntax highlighting with multiple languages.
  .end
  This post tests the integrated syntax highlighters with Ruby, Elixir, JavaScript, and plain text.

  ## Ruby Code Example (Rouge)

  .code ruby
  class User
    attr_accessor :name, :email
    
    def initialize(name, email)
      @name = name
      @email = email
    end
    
    def greet
      puts "Hello, #{@name}!"
    end
    
    def valid_email?
      email.match?(/\\A[\\w+\\-.]+@[a-z\\d\\-]+(\\.[a-z\\d\\-]+)*\\.[a-z]+\\z/i)
    end
  end

  user = User.new("Alice", "alice@example.com")
  user.greet
  .end

  ## Elixir Code Example (Rouge)

  .code elixir
  defmodule Calculator do
    def add(a, b), do: a + b
    def subtract(a, b), do: a - b
    def multiply(a, b), do: a * b
    def divide(a, b) when b != 0, do: a / b
    def divide(_, 0), do: {:error, "Division by zero"}
    
    def calculate(operation, a, b) do
      case operation do
        :add -> add(a, b)
        :subtract -> subtract(a, b)
        :multiply -> multiply(a, b)
        :divide -> divide(a, b)
        _ -> {:error, "Unknown operation"}
      end
    end
  end

  # Test the calculator
  IO.puts("5 + 3 = 8")
  .end

  ## JavaScript Code Example (Highlight.js)

  .code javascript
  class TodoList {
    constructor() {
      this.todos = [];
      this.nextId = 1;
    }
    
    addTodo(text, completed = false) {
      const todo = {
        id: this.nextId++,
        text: text,
        completed: completed,
        createdAt: new Date()
      };
      
      this.todos.push(todo);
      return todo;
    }
    
    toggleTodo(id) {
      const todo = this.todos.find(t => t.id === id);
      if (todo) {
        todo.completed = !todo.completed;
      }
      return todo;
    }
  }

  // Usage example
  const todoList = new TodoList();
  todoList.addTodo("Learn syntax highlighting");
  todoList.addTodo("Test multiple languages");
  .end

  ## Simple Ruby Example

  .code ruby
  def hello_world
    puts "Hello, World!"
    @greeting = "Welcome to Scriptorium"
    return @greeting
  end
  .end

  ## Plain Text Example

  .code text
  This is just plain text
  No syntax highlighting needed
  But it should still be in a code block
  .end

  ## Test Results

  Each code block above should display with proper syntax highlighting:

  - **Ruby (Rouge)**: Keywords in red, strings in blue, variables in orange
  - **Elixir (Rouge)**: Functions in purple, atoms in green, strings in blue  
  - **JavaScript (Highlight.js)**: Keywords in red, functions in purple, strings in blue
  - **Plain text**: No highlighting, just code block formatting

  Rouge and Highlight.js highlighting should work automatically!
BODY

name = @repo.create_draft(title: "Comprehensive Syntax Highlighting Test", views: ["testview"], body: draft_body)
num = @repo.finish_draft(name)
@repo.generate_post(num)

@repo.generate_front_page("testview")

# Open the generated post directly (works under simple httpd without SPA)
unless ARGV.include?("--automated")
  post_url = "http://127.0.0.1:8000/scriptorium-TEST/views/testview/output/posts/0001-comprehensive-syntax-highlighting-test.html"
  puts "Press Enter to open the post directly to verify highlighting."
  STDIN.gets
  system("open #{post_url}")
end

instruct <<~EOS
  Front page should have one post with comprehensive syntax highlighting.
  
  Highlight.js (Ruby, Elixir, JavaScript):
  - Ruby/Elixir/JS: Token colors applied client-side
  
  Plain text: No highlighting, just code block formatting
  
  Check that Highlight.js CSS/JS are included in the generated HTML.
  All code blocks should have proper token classes and syntax highlighting.
  Then open the post directly to verify:
  http://127.0.0.1:8000/scriptorium-TEST/views/testview/output/posts/0001-comprehensive-syntax-highlighting-test.html
EOS

examine("testview")