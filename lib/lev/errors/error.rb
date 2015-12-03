module Lev
  class Error
    ATTRS = [:code, :data, :kind, :message, :offending_inputs]

    ATTRS.each { |a| attr_accessor a }

    attr_accessor :appended

    def initialize(args = {})
      args.stringify_keys!

      if args['code'].blank?
        raise ArgumentError, "must supply a :code to Lev::Error"
      else
        apply_attrs(args)
      end
    end

    def to_s
      [kind_str, code_str, data_str, message_str, appended_str].compact.join(' - ')
    end

    private
    def apply_attrs(args)
      args['kind'] ||= :lev

      ATTRS.each do |a|
        self.send("#{a}=", args.delete(a.to_s))
      end

      self.appended = args.map { |k, v| ["#{k}: ", v] }
    end

    ATTRS.each do |attr|
      define_method("#{attr}_str") do
        "#{attr}: #{send(attr)}" unless send(attr).blank?
      end
    end

    def appended_str
      if appended.any?
        appended.map { |a| a.join('') }
      end
    end
  end
end
