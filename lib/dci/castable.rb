require 'dci/context'

module DCI
  module Castable
    def self.module_method_rebinding?
      sample_method = Enumerable.instance_method(:to_a)
      begin
        !!sample_method.bind(Object.new)
      rescue TypeError
        false
      end
    end

    private

    if module_method_rebinding?
      def delegated_method(role, method)
        role.instance_method(method)
      end
    else
      def delegated_method(role, method)
        clone.extend(role).method(method).unbind
      end
    end

    def method_missing(method, *arguments, &block)
      role = participating_role_with_method(method)
      role ? delegated_method(role, method).bind(self).call(*arguments, &block) : super
    end

    def participating_role_with_method(method)
      context = DCI::Context.current
      return unless context

      roles = context[self]
      return unless roles

      roles.find do |role|
        role.public_instance_methods.include?(method) ||
          role.protected_instance_methods.include?(method) ||
          role.private_instance_methods.include?(method)
      end
    end

    def respond_to_missing?(method, include_private)
      !!participating_role_with_method(method) || super
    end
  end
end
