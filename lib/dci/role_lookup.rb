require 'dci/context'

module DCI
  module RoleLookup
    private

    # Forward references to constants to the currently executing context
    def const_missing(name)
      context = DCI::Context.current
      context.respond_to?(name) ? context.__send__(name) : super
    end
  end
end
