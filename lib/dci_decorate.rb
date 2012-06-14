require 'delegate'

module DCI

  class Context
    # Intercept references to constants in the currently executing context
    def self.const_missing(name)
      context = Thread.current[:context]
      context.respond_to?(name) ? context.send(name) : super
    end

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
      data_class = args[0]
      role_class = DelegateClass(data_class)
      role_class.module_eval(&block)

      attr_reader name

      define_method("#{name}=") do |data|
        # Decorate the data object with the role class
        instance_variable_set("@#{name}", role_class.new(data))
      end

      protected "#{name}="
    end
  end
end
