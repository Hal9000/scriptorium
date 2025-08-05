require 'minitest/autorun'
require_relative '../../lib/scriptorium'
require_relative '../test_helpers'

class TestContract < Minitest::Test
  include TestHelpers

  def setup
    @test_dir = "test/scriptorium-TEST-#{Time.now.to_i}-#{rand(1000)}"
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
    @repo = Scriptorium::Repo.create(@test_dir, testmode: true)
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if Dir.exist?(@test_dir)
  end

  def test_contract_disabled_in_tests
    # DBC should be disabled by default in tests
    assert Scriptorium::Contract.enabled? == false
    
    # Create a post - should not trigger contract violations
    post = @repo.create_post(title: "Test Post", body: "Test body")
    assert post.is_a?(Scriptorium::Post)
  end

  def test_contract_enabled_when_environment_set
    # Enable DBC
    ENV['DBC_DISABLED'] = nil
    
    begin
      assert Scriptorium::Contract.enabled? == true
      
      # Create a post - should work normally
      post = @repo.create_post(title: "Test Post", body: "Test body")
      assert post.is_a?(Scriptorium::Post)
      
      # Test that invariants are checked
      post.check_invariants  # Should not raise
      
    ensure
      # Restore disabled state
      ENV['DBC_DISABLED'] = 'true'
    end
  end

  def test_post_invariants
    # Enable DBC
    ENV['DBC_DISABLED'] = nil
    
    begin
      post = @repo.create_post(title: "Test Post", body: "Test body")
      
      # Test that invariants are valid
      assert post.id > 0
      assert post.repo.is_a?(Scriptorium::Repo)
      assert post.num.match?(/^\d{4}$/)
      
      # Test invariant checking
      post.check_invariants  # Should not raise
      
    ensure
      # Restore disabled state
      ENV['DBC_DISABLED'] = 'true'
    end
  end

  def test_post_contracts
    # Enable DBC
    ENV['DBC_DISABLED'] = nil
    
    begin
      post = @repo.create_post(title: "Test Post", body: "Test body")
      
      # Test save_metadata contracts
      post.meta["post.title"] = "Updated Title"
      post.save_metadata  # Should not raise
      
      # Test deleted= contracts
      post.deleted = true  # Should not raise
      assert post.deleted == true
      
      post.deleted = false  # Should not raise
      assert post.deleted == false
      
    ensure
      # Restore disabled state
      ENV['DBC_DISABLED'] = 'true'
    end
  end
end 