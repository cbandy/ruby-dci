require 'dci_decorate'

class Another < DCI::Context
  class NoExplicitBase
    include DCI::Role
  end

  role :mystery, NoExplicitBase
end

# role classes are named in the context
puts "* context constants:", Another.constants, ""

# role variables are accessible (though only roles should access...)
puts "* context public methods:", Another.public_instance_methods(false), ""
puts "* context protected methods:", Another.protected_instance_methods(false), ""

# roles can access the context
puts "* first role method:", Another::NoExplicitBase.instance_methods.first, ""

