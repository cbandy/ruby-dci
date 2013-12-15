require 'dci/context'

describe DCI::Context do
  describe 'role implementations' do
    let(:context) { Class.new(DCI::Context) }
    let(:context_instance) { context.new }
    let(:participating_roles) { context_instance[role_player] }
    let(:role_implementation) { Module.new }
    let(:role_player) { double }

    specify 'are applied using #cast' do
      context_instance.cast(role_player, :as => role_implementation)

      expect(role_player).to be_a(DCI::Castable)
      expect(participating_roles).to be == [role_implementation]
    end

    specify 'are nil when not applied' do
      expect(participating_roles).to be_nil
    end
  end

  describe 'role identifiers are defined using ::role' do
    let(:context) do
      Class.new(DCI::Context) do
        role :One

        def initialize(one)
          self.One = one
        end
      end
    end

    context 'at runtime' do
      subject(:context_instance) { context.new(one) }
      let(:one) { double }

      specify 'role players can be assigned' do
        expect { context_instance }.to_not raise_error
      end

      specify 'role players can be accessed' do
        expect(context_instance.One).to be == one
      end
    end

    describe 'when passed a block, that block becomes the implementation' do
      let(:context) do
        Class.new(DCI::Context) do
          role :One do
            def something
              :expected
            end
          end

          def initialize
            self.One = Object.new
          end
        end
      end

      let(:context_instance) { context.new }
      let(:participating_roles) { context_instance[role_player] }
      let(:role_player) { context_instance.One }

      specify 'it is applied when the role is assigned' do
        expect(role_player).to be_a(DCI::Castable)
        expect(participating_roles).to be_an(Array)
        expect(participating_roles.first).to be_a(Module)
        expect(participating_roles.first.public_instance_methods).to include(:something)
      end
    end
  end

  describe 'use case triggers are identified using ::entry' do
    subject(:context_instance) { context.new }

    shared_examples 'correctly manages the currently executing context' do
      specify 'it assigns the executing context' do
        context_instance.something do
          expect(DCI::Context.current).to be == context_instance
        end
      end

      specify 'it restores the previously executing context' do
        expect { context_instance.something {} }.to_not change { DCI::Context.current }
      end
    end

    context 'when the method exists' do
      let(:context) do
        Class.new(DCI::Context) do
          def something(&block)
            block.call
          end

          entry :something
        end
      end

      specify 'it can be called' do
        expect(context_instance).to respond_to(:something)
        expect(context_instance.something { :expected }).to be == :expected
      end

      include_examples 'correctly manages the currently executing context'
    end

    context 'when the method does not exist' do
      let(:context) do
        Class.new(DCI::Context) do
          entry :something
        end
      end

      specify 'it cannot be called' do
        expect(context_instance).to_not respond_to(:something)
        expect { context_instance.something }.to raise_error(NoMethodError, /something/)
      end

      context 'once the method is defined' do
        before do
          context.class_exec do
            def something(&block)
              block.call
            end
          end
        end

        specify 'it can be called' do
          expect(context_instance).to respond_to(:something)
          expect(context_instance.something { :expected }).to be == :expected
        end

        include_examples 'correctly manages the currently executing context'
      end
    end

    describe 'when passed a block, that block becomes the definition' do
      let(:context) do
        Class.new(DCI::Context) do
          entry :point do
            :expected
          end
        end
      end

      specify 'that can be called' do
        expect(context_instance).to respond_to(:point)
        expect(context_instance.point).to be == :expected
      end

      context 'when the block has parameters' do
        let(:context) do
          Class.new(DCI::Context) do
            entry :parameters do |argument|
              argument
            end
          end
        end

        specify 'those parameters are required' do
          expect { context_instance.parameters }.to raise_error(ArgumentError)
        end

        specify 'and can be called with arguments' do
          expect(context_instance.parameters(:expected)).to be == :expected
        end
      end

      context 'when the block takes a block' do
        let(:context) do
          Class.new(DCI::Context) do
            entry :block do |&block|
              block.call
            end
          end
        end

        specify 'it works' do
          expect(context_instance.block { :expected }).to be == :expected
        end
      end
    end

    describe 'when passed a lambda, that lambda becomes the definition' do
      let(:context) do
        Class.new(DCI::Context) do
          entry :parameters, -> (argument) do
            argument
          end
        end
      end

      specify 'that can be called' do
        expect(context_instance).to respond_to(:parameters)
        expect { context_instance.parameters }.to raise_error(ArgumentError)
        expect(context_instance.parameters(:expected)).to be == :expected
      end
    end
  end

  context 'when capitalized roles are defined within a named context' do
    class NamedContext < DCI::Context
      role :One
      role :Two do
        def access_one
          One
        end
      end

      entry :access_one do
        One
      end

      entry :access_one_from_two do
        Two.access_one
      end

      def initialize(one)
        self.One = one
        self.Two = Object.new
      end
    end

    let(:context) { NamedContext }
    subject(:context_instance) { context.new(one) }
    let(:one) { double }

    specify 'those roles can be referenced directly by triggers' do
      expect(context_instance.access_one).to be == one
    end

    specify 'those roles can be referenced directly by other roles' do
      expect(context_instance.access_one_from_two).to be == one
    end

    specify 'those roles cannot be referenced by a later executing context' do
      class FirstContext < DCI::Context
        role :One
        entry :call do
          SecondContext.new.call
        end
      end

      class SecondContext < DCI::Context
        entry :call do
          One
        end
      end

      expect { FirstContext.new.call }.to raise_error(NameError, /One/)
    end
  end
end
