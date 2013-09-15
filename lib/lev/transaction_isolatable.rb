module Lev
  module TransactionIsolatable

    def default_transaction_isolation
      TransactionIsolation.no_transaction 
    end

    def run_in_transaction(options={})
      if options[:disable_transaction_if] ||
         transaction_isolation == TransactionIsolation.no_transaction
        yield
      else
        ActiveRecord::Base.isolation_level( transaction_isolation.symbol ) do
          ActiveRecord::Base.transaction { yield }
        end
      end
    end

    def init_transaction_isolation(value=nil)
      raise IllegalArgument "Transaction isolation values must be an instance of Lev::TransactionIsolation" \
        if value && !value.is_a?(Lev::TransactionIsolation)

      self.transaction_isolation ||= default_transaction_isolation
      self.transaction_isolation = value if value
    end

    # Intended to be called from handler initializers to foretell which other 
    # algorithms or handlers will be used in this instance's handle method.
    # Currently used to figure out ahead of time what kind of isolation level
    # we should be using.
    def uses(isolatable)
      init_transaction_isolation
      self.transaction_isolation.replace_if_more_isolated(isolatable.transaction_isolation)
    end

    attr_reader :transaction_isolation

  protected

    attr_writer :transaction_isolation

  end
end