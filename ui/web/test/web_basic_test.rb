require 'minitest/autorun'
require_relative '../../../lib/scriptorium'

class WebBasicTest < Minitest::Test
  def test_web_structure
    # Test that the web app file exists
    app_file = File.join(__dir__, '..', 'app', 'app.rb')
    assert File.exist?(app_file), "Web app should exist at #{app_file}"
    
    # Test that the dashboard template exists
    template_file = File.join(__dir__, '..', 'app', 'views', 'dashboard.erb')
    assert File.exist?(template_file), "Dashboard template should exist at #{template_file}"
    
    # Test that the server management script exists
    server_script = File.join(__dir__, '..', 'bin', 'scriptorium-web')
    assert File.exist?(server_script), "Server script should exist at #{server_script}"
    assert File.executable?(server_script), "Server script should be executable"
  end
  
  def test_api_integration
    # Test that the web app can create an API instance
    api = Scriptorium::API.new(testmode: true)
    assert api, "Should be able to create API instance"
    
    # Test that we can check for repository
    assert_respond_to api, :views, "API should respond to views method"
  end
  
  def test_server_script_requires
    # Test that the server script has the necessary requires
    server_script = File.join(__dir__, '..', 'bin', 'scriptorium-web')
    content = File.read(server_script)
    
    assert content.include?('require \'optparse\''), "Should require optparse"
    assert content.include?('require \'json\''), "Should require json"
    assert content.include?('require \'net/http\''), "Should require net/http"
  end
end 