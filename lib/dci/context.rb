module DCI
  class Context
    # Intercept references to constants in the currently executing context
    def self.const_missing(name)
      context = current
      context.respond_to?(name) ? context.send(name) : super
    end

    # The currently executing context
    def self.current
      Thread.current['DCI::Context.current']
    end

    # Define a context entry point
    def self.entry(name, &block)
      define_method(name) do |*args|
        begin
          # Swap out the currently executing context
          Thread.current['DCI::Context.current'], old_context = self, Thread.current['DCI::Context.current']
          instance_exec(*args, &block)
        ensure
          # Reinstate the previously executing context
          Thread.current['DCI::Context.current'] = old_context
        end
      end
    end

    # Define a context role
    def self.role(name, *args, &block)
      attr_reader name
      public name

      if block_given?
        role_module = Module.new
        role_module.module_eval(&block)

        define_method("#{name}=") do |data|
          instance_variable_set("@#{name}", data).extend(role_module)
        end
      else
        attr_writer name
      end

      protected "#{name}="
    end
  end
end
