module Lev
  class TransactionIsolation

    def replace_if_more_isolated(other_transaction_isolation)
      if other_transaction_isolation.isolation_level > self.isolation_level
        self.symbol = other_transaction_isolation.symbol
      end
      self
    end

    def initialize(symbol)
      raise IllegalArgument, "Invalid isolation symbol" if !@@symbols_to_isolation_levels.has_key?(symbol)
      @symbol = symbol
    end

    def self.no_transaction;   new(:no_transaction);   end
    def self.read_uncommitted; new(:read_uncommitted); end
    def self.read_committed;   new(:read_committed);   end
    def self.repeatable_read;  new(:repeatable_read);  end
    def self.serializable;     new(:serializable);     end

    def self.mysql_default
      # MySQL default per https://blog.engineyard.com/2010/a-gentle-introduction-to-isolation-levels
      repeatable_read
    end

    def ==(other)
      self.symbol == other.symbol
    end

    def eql?(other)
      self == other
    end
    
    attr_reader :symbol

  protected

    def isolation_level
      @@symbols_to_isolation_levels[symbol]
    end

    @@symbols_to_isolation_levels = {
      no_transaction:   0,
      read_uncommitted: 1,
      read_committed:   2,
      repeatable_read:  3,
      serializable:     4
    }

    attr_writer :symbol

  end
end