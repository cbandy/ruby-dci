require 'dci'

class Account
  attr_reader :balance

  def initialize(balance)
    @balance = balance
  end
end

class MoneyTransfer < DCI::Context

  module Destination
    include DCI::Role

    def deposit(amount)
      @balance += amount
    end
  end

  role :destination, Destination

  role :source do
    def withdraw(amount)
      @balance -= amount
    end

    def transfer(amount)
      puts "Source balance is: #{context.source.balance}"
      puts "Destination balance is: #{context.destination.balance}"

      context.source.withdraw(amount)
      context.destination.deposit(amount)

      puts "Source balance is now: #{context.source.balance}"
      puts "Destination balance is now: #{context.destination.balance}"
    end
  end

  entry :transfer do |amount|
    @source.transfer(amount)
  end

  def initialize(src, dest)
    self.source = src
    self.destination = dest
  end

end

# role classes are named in the context
puts "* MoneyTransfer constants:", MoneyTransfer.constants, ""

# role variables are accessible (though only roles should access...)
puts "* MoneyTransfer public methods:", MoneyTransfer.public_instance_methods(false), ""
puts "* MoneyTransfer protected methods:", MoneyTransfer.protected_instance_methods(false), ""

context = MoneyTransfer.new(Account.new(1000), Account.new(0))
context.transfer(245)

