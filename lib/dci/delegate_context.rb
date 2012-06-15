require 'dci/context'
require 'delegate'

module DCI
  class DelegateContext < Context
    # Define a context role using a delegate class
    def self.role(name, data_class, &block)
      role_module = Module.new
      role_module.module_eval(&block)

      (role_module.instance_methods & data_class.instance_methods).each do |method|
        raise "RoleMethod conflict: #{name}.#{method}"
      end

      role_class = DelegateClass(data_class).send(:include, role_module)

      attr_reader name

      define_method("#{name}=") do |data|
        # Wrap the data object with the role class
        instance_variable_set("@#{name}", role_class.new(data))
      end

      protected "#{name}="
    end
  end
end
