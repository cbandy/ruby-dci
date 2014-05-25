require 'dci/castable'

describe DCI::Castable do
  let(:something) { Class.new { include DCI::Castable; def greet; 'hello'; end } }
  subject(:actor) { something.new }

  context 'when the actor is not participating in the current context' do
    specify 'calling a nonexistent method raises NoMethodError' do
      expect { actor.smile }.to raise_error(NoMethodError)
    end

    specify 'calling an implemented method works' do
      expect(actor.greet).to eq 'hello'
    end
  end

  context 'when the actor is participating in the current context' do
    let(:context_participants) { { actor => [role] } }
    let(:role) { Module.new }

    before do
      allow(DCI::Context).to receive(:current).and_return(context_participants)
    end

    specify 'calling a method implemented by none of its roles raises NoMethodError' do
      expect(actor).to_not respond_to(:smile)
      expect { actor.smile }.to raise_error(NoMethodError)
    end

    context 'when one of its roles implements a public method' do
      let(:role) { Module.new { def eat; :yum; end } }

      specify 'calling that method works' do
        expect(actor).to respond_to(:eat)
        expect(actor.eat).to be :yum
      end
    end

    context 'when one of its roles implements a protected method' do
      let(:role) { Module.new { protected; def eat; :yum; end } }

      specify 'calling that method works' do
        expect(actor).to respond_to(:eat)
        expect(actor.eat).to be :yum
      end
    end

    context 'when one of its roles implements a private method' do
      let(:role) { Module.new { private; def eat; :yum; end } }

      specify 'calling that method works' do
        expect(actor).to respond_to(:eat)
        expect(actor.eat).to be :yum
      end
    end

    context 'when one of its role methods takes arguments' do
      let(:role) { Module.new { def sing(song); song; end } }

      specify 'calling that method without arguments raises ArgumentError' do
        expect { actor.sing }.to raise_error(ArgumentError)
      end

      specify 'calling that method with arguments works' do
        expect(actor.sing(:song)).to be :song
      end
    end

    context 'when one of its role methods takes a block' do
      let(:role) { Module.new { def sing(&block); block.call; end } }

      specify 'calling that method with a block works' do
        expect(actor.sing { :song }).to be :song
      end
    end
  end
end
