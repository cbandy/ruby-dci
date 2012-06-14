require 'dci/context'
require 'delegate'

module DCI
  class DelegateContext < Context
    # Define a context role using a delegate class
    def self.role(name, *args, &block)
      data_class = args[0]
      role_class = DelegateClass(data_class)
      role_class.module_eval(&block)

      attr_reader name

      define_method("#{name}=") do |data|
        # Wrap the data object with the role class
        instance_variable_set("@#{name}", role_class.new(data))
      end

      protected "#{name}="
    end
  end
end
