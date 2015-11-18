module StubLevRoutineHelper
  def stub_lev_routine(klass_name, options = {}, &block)
    @@block = block || Proc.new { }
    nested_routines = [options.delete(:uses)].flatten.compact

    stub_const(klass_name, Class.new)

    klass_name.constantize.class_eval do
      lev_routine options

      nested_routines.each do |routine_name|
        uses_routine routine_name
      end

      def exec
        instance_eval(&@@block)
      end
    end
  end
end
