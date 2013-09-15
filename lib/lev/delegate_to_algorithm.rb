# ActiveRecord::Base.delegate_to_algorithm
#
# Let active records delegate certain (likely non-trivial) actions to algoritms
# 
# Arguments:
#   method: a symbol for the instance method to delegate, e.g. :destroy
#   options: a hash of options including...
#      :algorithm_klass => The class of the algorithm to delegate to; if not 
#        given, 
ActiveRecord::Base.define_singleton_method(:delegate_to_algorithm) do |method, options={}|
  algorithm_klass = options[:algorithm_klass]

  if algorithm_klass.nil?
    algorithm_klass_name = "#{method.to_s.capitalize}#{self.name}"
    algorithm_klass = Kernel.const_get(algorithm_klass_name)
  end

  self.instance_eval do
    alias_method "#{method}_original".to_sym, method
    define_method method do
      algorithm_klass.call(self)
    end
  end

end