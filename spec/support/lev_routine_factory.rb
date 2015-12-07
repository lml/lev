module LevRoutineFactory
  def routine(klass_name, options = {}, &block)
    stub_const(klass_name, Class.new)

    klass_name.constantize.class_eval do
      lev_routine options

      define_method(:exec, &(block || Proc.new { }))
    end
  end

  def handler(klass_name, options = {}, &block)
    stub_const(klass_name, Class.new)

    klass_name.constantize.class_eval do
      lev_handler options

      define_method(:handle, &(block || Proc.new { }))
    end
  end
end
