require_relative "./environment"

manual_setup

@repo.create_view("testview", "Test View", "A test view for manual inspection")

# Enable syntax highlighting for this test by adding it to global-head.txt
global_head_file = "test/scriptorium-TEST/views/testview/config/global-head.txt"
File.open(global_head_file, "a") { |f| f.puts "syntax     # Enable Rouge syntax highlighting" }

# Post with comprehensive syntax highlighting tests
draft_body = <<~'BODY'
  .blurb Testing both Prism and Rouge syntax highlighting with multiple languages.
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

  ## JavaScript Code Example (Prism)

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

  ## Simple Ruby Example (Prism)

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
  - **JavaScript (Prism)**: Keywords in red, functions in purple, strings in blue
  - **Plain text**: No highlighting, just code block formatting

  Both Rouge and Prism highlighting should work automatically!
BODY

name = @repo.create_draft(title: "Comprehensive Syntax Highlighting Test", views: ["testview"], body: draft_body)
num = @repo.finish_draft(name)
@repo.generate_post(num)

@repo.generate_front_page("testview")

instruct <<~EOS
  Front page should have one post with comprehensive syntax highlighting.
  
  Rouge highlighting (Ruby, Elixir):
  - Ruby: Keywords red, strings blue, variables orange
  - Elixir: Functions purple, atoms green, strings blue
  
  Prism highlighting (JavaScript, Ruby):
  - JavaScript: Keywords red, functions purple, strings blue
  - Ruby: Standard Prism Ruby highlighting
  
  Plain text: No highlighting, just code block formatting
  
  Check that both Rouge CSS and Prism CSS/JS are included in the generated HTML.
  All code blocks should have proper token classes and syntax highlighting.
EOS

examine("testview")