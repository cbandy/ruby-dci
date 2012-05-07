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
        role_module = Module.new
        role_module.send(:include, DCI::Role)
        role_module.module_eval(&block)

        # Camelize
        role_module_name = name.to_s.split(/_/).map{ |w| w.capitalize }.join('')
        const_set(role_module_name, role_module)
      else
        role_module = args[0]
      end

      attr_reader name

      define_method("#{name}=") do |data|
        # Extend the data object with the role module
        instance_variable_set("@#{name}", data).extend(role_module)
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

end
