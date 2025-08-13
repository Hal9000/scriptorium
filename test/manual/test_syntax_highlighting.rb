require_relative "./environment"

manual_setup

@repo.create_view("testview", "Test View", "A test view for manual inspection")

# Enable syntax highlighting for this test by adding it to global-head.txt
global_head_file = "test/scriptorium-TEST/views/testview/config/global-head.txt"
File.open(global_head_file, "a") { |f| f.puts "syntax     # Enable Rouge syntax highlighting" }

# Post with Rouge syntax highlighting for multiple languages
draft_body = <<~'BODY'
  .blurb Testing Rouge syntax highlighting for Ruby, Elixir, and JavaScript.
  This post tests the integrated Rouge syntax highlighter with three different programming languages.

  ## Ruby Code Example

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

  ## Elixir Code Example

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

  ## JavaScript Code Example

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
    
    removeTodo(id) {
      const index = this.todos.findIndex(t => t.id === id);
      if (index > -1) {
        return this.todos.splice(index, 1)[0];
      }
      return null;
    }
    
    getCompletedTodos() {
      return this.todos.filter(t => t.completed);
    }
    
    getPendingTodos() {
      return this.todos.filter(t => !t.completed);
    }
  }

  // Usage example
  const todoList = new TodoList();
  todoList.addTodo("Learn Rouge syntax highlighting");
  todoList.addTodo("Test multiple languages");
  todoList.addTodo("Write documentation", true);

  console.log("Pending todos:", todoList.getPendingTodos().length);
  console.log("Completed todos:", todoList.getCompletedTodos().length);
  .end

  ## Test Results

  Each code block above should display with proper syntax highlighting:

  - **Ruby**: Keywords in red, strings in blue, variables in orange
  - **Elixir**: Functions in purple, atoms in green, strings in blue  
  - **JavaScript**: Keywords in red, functions in purple, strings in blue

  The highlighting should work automatically thanks to our Rouge integration!
BODY

name = @repo.create_draft(title: "Rouge Syntax Highlighting Test", views: ["testview"], body: draft_body)
num = @repo.finish_draft(name)
@repo.generate_post(num)

@repo.generate_front_page("testview")

instruct <<~EOS
  Front page should have one post with Rouge syntax highlighting.
  Ruby code should be highlighted with Ruby syntax (keywords red, strings blue, variables orange).
  Elixir code should be highlighted with Elixir syntax (functions purple, atoms green, strings blue).
  JavaScript code should be highlighted with JS syntax (keywords red, functions purple, strings blue).
  Check that Rouge CSS is included in the generated HTML.
  All code blocks should have proper token classes and syntax highlighting.
EOS

examine("testview")
