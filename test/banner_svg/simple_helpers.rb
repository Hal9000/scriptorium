module SimpleTestHelpers
  def assert_present(str, *targets)
    result = true
    missing = []
    targets.each do |t|
      if ! str.include?(t)
        result = false
        missing << t
      end
    end
    assert result, "Targets missing: #{missing.join(", ").inspect}"
  end
end 