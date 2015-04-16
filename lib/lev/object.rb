class Object

  def self.lev_routine(options={})
    class_eval do
      include Lev::Routine unless options[:skip_routine_include]

      # Routine configuration
      options[:transaction] ||= Lev::TransactionIsolation.mysql_default.symbol
      @transaction_isolation = Lev::TransactionIsolation.new(options[:transaction])

      @delegates_to = options[:delegates_to]
      if @delegates_to
        uses_routine @delegates_to,
                     translations: {
                       outputs: { type: :verbatim },
                       inputs: { type: :verbatim }
                     }

        @express_output ||= @delegates_to.express_output
      end

      # Set this after dealing with "delegates_to" in case it set a value
      @express_output ||= options[:express_output] || self.name.demodulize.underscore
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
