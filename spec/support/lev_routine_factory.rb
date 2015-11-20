module LevRoutineFactory
  def lev_routine_factory(klass_name, options = {}, &block)
    nested_routines = [options.delete(:uses)].flatten.compact

    stub_const(klass_name, Class.new)

    klass_name.constantize.class_eval do
      lev_routine options

      nested_routines.each do |routine_name|
        uses_routine routine_name
      end

      define_method(:exec, &block)
    end
  end
end
