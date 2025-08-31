module Scriptorium::Contract
  def self.enabled?
    !ENV['DBC_DISABLED']
  end
  
  def assume(condition = nil, message = nil, &block)
    return unless Scriptorium::Contract.enabled?
    if block_given?
      result = instance_eval(&block)
      raise "Precondition violated: #{message || 'block condition failed'}" unless result
    else
      raise "Precondition violated: #{message || condition}" unless condition
    end
  end
  
  def verify(condition = nil, message = nil, &block)
    return unless Scriptorium::Contract.enabled?
    if block_given?
      raise "Postcondition violated: #{message}" unless instance_eval(&block)
    else
      raise "Postcondition violated: #{message}" unless condition
    end
  end
  
  def invariant(&block)
    @invariants ||= []
    @invariants << block
  end
  
  def check_invariants
    return unless Scriptorium::Contract.enabled?
    @invariants&.each { |invariant| raise "Invariant violated" unless instance_eval(&invariant) }
  end
end 