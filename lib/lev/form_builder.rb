module Lev
  class FormBuilder < ActionView::Helpers::FormBuilder

    (field_helpers - %w(label check_box radio_button fields_for file_field)).each do |selector|
      class_eval <<-RUBY_EVAL, __FILE__, __LINE__ + 1
        def #{selector}(method, options = {})                       # def text_field(method, options = {})
          set_value_if_available(method, options)                   #   ... verbatim ...
          mark_error_if_present(method, options)                    #   ... verbatim ...
          super(method, options)                                    #   ... verbatim ...
        end                                                         # end
      RUBY_EVAL
    end

    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      options[:checked] = true if get_form_params_entry(method).to_i > 0
      mark_error_if_present(method, options)
      super(method, options, checked_value, unchecked_value)
    end

    def radio_button(method, tag_value, options = {})
      options[:checked] = true if get_form_params_entry(method) == tag_value
      mark_error_if_present(method, options)
      super(method, tag_value, options)
    end

    def fields_for(record_name, record_object = nil, fields_options = {}, &block)
      raise "Didn't put fields_for into LevitateFormBuilder yet"
    end

  protected

    def get_form_params_entry(name)
      @options[:params].present? ? 
        (@options[:params][@object_name].present? ?
          @options[:params][@object_name][name] :
          nil) :
        nil
    end

    def has_error?(name)
      @options[:errors].present? ? @options[:errors].has_offending_param?([@object_name, name]) : false
    end

    def set_value_if_available(method, options)
      value = get_form_params_entry(method)
      options[:value] ||= value if !value.nil?
    end

    def mark_error_if_present(method, options)
      (options[:class] ||= '') << ' error' if has_error?(method) # TODO make the error class configurable
    end

  end
end

def lev_form_for(record_or_name_or_array, *args, &proc)
  options = args.extract_options!
  options[:params] = params
  options[:errors] = @errors || []
  form_for(record_or_name_or_array, *(args << options.merge(:builder => Lev::FormBuilder)), &proc)
end