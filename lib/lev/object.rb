class Object

  def self.lev_routine(options={})
    class_eval do
      include Lev::Routine unless options[:skip_routine_include]

      # Routine configuration
      options[:transaction] ||= Lev::TransactionIsolation.mysql_default.symbol
      @transaction_isolation = Lev::TransactionIsolation.new(options[:transaction])
      @express_output = options[:express_output] || self.name.demodulize.underscore
    end
  end

  def self.lev_handler(options={})
    class_eval do
      include Lev::Handler
    end
    
    # Do routine configuration
    options[:skip_routine_include] = true
    lev_routine(options)

    # Do handler configuration (none currently)
  end

end