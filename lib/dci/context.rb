require 'dci/castable'

module DCI
  module Context
    # The currently executing context
    def self.current
      Thread.current[:'DCI::Context.current']
    end

    def self.included(calling_module)
      calling_module.extend(DSL)
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

    module DSL
      private

      # Replace an existing method with a wrapper that advertises the current context
      def define_entry_using_method(name)
        method = instance_method(name)
        define_method(name) do |*arguments, &block|
          begin
            # Swap out the currently executing context
            Thread.current[:'DCI::Context.current'], old_context = self, Thread.current[:'DCI::Context.current']
            method.bind(self).call(*arguments, &block)
          ensure
            # Reinstate the previously executing context
            Thread.current[:'DCI::Context.current'] = old_context
          end
        end
      end

      # Create a method that executes the provided definition while advertising the current context
      def define_entry_using_proc(name, definition)
        define_method(name, &definition)
        define_entry_using_method(name)
      end

      # Define a context entry point
      def entry(name, proc = nil, &block)
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

      # Listen for new methods that are intended to be entry points
      def method_added(name)
        if @entries && @entries.delete(name)
          define_entry_using_method(name)
        end
      end

      # Define a context role
      def role(name, *args, &block)
        attr_reader name
        public name

        if block_given?
          role_module = Module.new
          role_module.module_eval(&block)

          define_method("#{name}=") do |actor|
            instance_variable_set("@#{name}", cast(actor, :as => role_module))
          end
        else
          attr_writer name
        end

        protected "#{name}="
      end

      def trigger(name, delegate, method = name)
        entry(name) do |*arguments, &block|
          __send__(delegate).__send__(method, *arguments, &block)
        end
      end
    end
  end
end
