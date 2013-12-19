require 'dci/role_lookup'

describe DCI::RoleLookup do
  context 'when roles are lowercase' do
    class LowercaseContext
      include DCI::Context
      extend DCI::RoleLookup

      role :one
      role :two do
        def access_one
          one
        end
      end

      entry :access_one_from_two do
        two.access_one
      end

      def initialize
        self.one = Object.new
        self.two = Object.new
      end
    end

    let(:context_instance) { LowercaseContext.new }

    specify 'role lookup does not work' do
      expect { context_instance.access_one_from_two }.to raise_error(NameError, /undefined.*one/)
    end
  end

  context 'when roles are capitalized' do
    context 'in an anonymous module' do
      let(:context) do
        Class.new do
          include DCI::Context
          extend DCI::RoleLookup

          role :One

          entry :access_one do
            One
          end
        end
      end

      let(:context_instance) { context.new }

      specify 'role lookup does not work' do
        expect { context_instance.access_one }.to raise_error(NameError, /One/)
      end
    end

    context 'in a named module' do
      class NamedContext
        include DCI::Context
        extend DCI::RoleLookup

        role :One
        role :Two
        role :Three do
          def access_one
            One
          end
        end

        module TwoMethods
          extend DCI::RoleLookup

          def access_one
            One
          end
        end

        entry :access_one_from_two do
          Two.access_one
        end

        entry :access_one_from_three do
          Three.access_one
        end

        def initialize(one)
          self.One = one
          self.Two = cast(Object.new, :as => TwoMethods)
          self.Three = Object.new
        end
      end

      let(:context_instance) { NamedContext.new(one) }
      let(:one) { double }

      specify 'role lookup works' do
        expect(context_instance.access_one_from_two).to be == one
        expect(context_instance.access_one_from_three).to be == one
      end

      specify 'those roles cannot be referenced by a later executing context' do
        class FirstContext
          include DCI::Context
          role :One
          entry :call do
            SecondContext.new.call
          end
        end

        class SecondContext
          include DCI::Context
          entry :call do
            One
          end
        end

        expect { FirstContext.new.call }.to raise_error(NameError, /One/)
      end
    end
  end
end
