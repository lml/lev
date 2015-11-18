module StubLevRoutineHelper
  def stub_lev_routine(klass_name, options = {}, nested_routines = {}, &block)
    @@block = block || Proc.new { }

    stub_const(klass_name, Class.new)

    klass_name.constantize.class_eval do
      lev_routine options

      [nested_routines[:nested]].flatten.compact.each do |routine_name|
        uses_routine routine_name
      end

      def exec
        instance_eval(&@@block)
      end
    end
  end
end
