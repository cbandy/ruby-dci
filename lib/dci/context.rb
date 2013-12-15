require 'dci/castable'

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

    def self.define_entry_using_method(name)
      method = instance_method(name)
      define_method(name) do |*arguments, &block|
        begin
          # Swap out the currently executing context
          Thread.current['DCI::Context.current'], old_context = self, Thread.current['DCI::Context.current']
          method.bind(self).call(*arguments, &block)
        ensure
          # Reinstate the previously executing context
          Thread.current['DCI::Context.current'] = old_context
        end
      end
    end

    def self.define_entry_using_proc(name, definition)
      define_method(name, &definition)
      define_entry_using_method(name)
    end

    # Define a context entry point
    def self.entry(name, proc = nil, &block)
      if block_given?
        define_entry_using_proc(name, block)
      elsif proc.respond_to?(:to_proc)
        define_entry_using_proc(name, proc)
      elsif method_defined?(name)
        define_entry_using_method(name)
      else
        @entries ||= []
        @entries |= [name]
      end
    end

    def self.method_added(name)
      if @entries && @entries.delete(name)
        define_entry_using_method(name)
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
          instance_variable_set("@#{name}", cast(data, :as => role_module))
        end
      else
        attr_writer name
      end

      protected "#{name}="
    end

    def cast(actor, roles)
      actor.extend(Castable) unless actor.is_a?(Castable)

      @roles ||= {}
      @roles[actor] ||= []
      @roles[actor] |= roles.values

      actor
    end

    def [](actor)
      @roles && @roles[actor]
    end
  end
end
