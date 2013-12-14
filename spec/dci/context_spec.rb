require 'dci/context'

describe DCI::Context do
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
      let(:role_player) { context_instance.One }

      specify 'it is applied when the role is assigned' do
        expect(role_player).to respond_to(:something)
      end
    end
  end

  describe 'use case triggers are identified using ::entry' do
    describe 'when passed a block, that block becomes the definition' do
      let(:context) do
        Class.new(DCI::Context) do
          entry :point do
            :expected
          end
        end
      end

      subject(:context_instance) { context.new }

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

        specify 'those parameters are not required' do
          expect { context_instance.parameters }.to_not raise_error
        end

        specify 'those parameters default to nil' do
          expect(context_instance.parameters).to be_nil
        end

        specify 'but can be called with arguments' do
          argument = double
          expect(context_instance.parameters(argument)).to be == argument
        end
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
