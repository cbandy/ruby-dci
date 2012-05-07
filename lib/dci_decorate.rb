require 'delegate'

module DCI

  class Context
    # Define a context entry point
    def self.entry(name, &block)
      define_method(name) do |*args|
        begin
          # Swap out the currently executing context
          Thread.current[:context], old_context = self, Thread.current[:context]
          instance_exec(*args, &block)
        ensure
          # Reinstate the previously executing context
          Thread.current[:context] = old_context
        end
      end
    end

    # Define a context role
    def self.role(name, *args, &block)
      if block_given?
        data_class = args[0]
        role_class = DCI::Role(data_class)
        role_class.module_eval(&block)

        # Camelize
        role_class_name = name.to_s.split(/_/).map{ |w| w.capitalize }.join('')
        const_set(role_class_name, role_class)
      else
        role_class = args[0]
      end

      attr_reader name

      define_method("#{name}=") do |data|
        # Decorate the data object with the role class
        instance_variable_set("@#{name}", role_class.new(data))
      end

      protected "#{name}="
    end
  end

  module Role
    # The currently executing context
    def context
      Thread.current[:context]
    end
  end

  # Create a decorator class that includes the Role module
  def self.Role(data_class)
    role_class = DelegateClass(data_class)
    role_class.send(:include, Role)
  end
end
