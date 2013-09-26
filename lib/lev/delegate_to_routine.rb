# ActiveRecord::Base.delegate_to_routine
#
# Let active records delegate certain (likely non-trivial) actions to routines
# 
# Arguments:
#   method: a symbol for the instance method to delegate, e.g. :destroy
#   options: a hash of options including...
#      :routine_class => The class of the routine to delegate to; if not 
#        given, 
ActiveRecord::Base.define_singleton_method(:delegate_to_routine) do |method, options={}|
  routine_class = options[:routine_class]

  if routine_class.nil?
    routine_class_name = "#{method.to_s.capitalize}#{self.name}"
    routine_class = Kernel.const_get(routine_class_name)
  end

  self.instance_eval do
    alias_method "#{method}_original".to_sym, method
    define_method method do
      routine_class.call(self)
    end
  end

end