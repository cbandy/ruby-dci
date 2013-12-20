### A lightweight DSL for DCI in Ruby

- Role Identifiers
- Methodful Roles
- Role behavior applies only within the current Context

Roles are identified within a Context using the `role` keyword.

```ruby
class MoneyTransfer
  include DCI::Context

  role :Source
  role :Sink

  def initialize(source, target)
    self.Source = source
    self.Sink = target
  end
end
```

Objects can be cast as role players using the `cast` method.

```ruby
class MoneyTransfer
  include DCI::Context

  role :Source
  role :Sink

  module SomeSourceBehavior
    def withdraw(amount)
      @balance -= amount
    end
  end

  module AnyModule
    def deposit(amount)
      @balance += amount
    end
  end

  def initialize(source, target)
    self.Source = cast(source, :as => SomeSourceBehavior)
    self.Sink = cast(target, :as => AnyModule)
  end
end
```

`role` supports a shorthand that defines an identifier and its behavior.

```ruby
class MoneyTransfer
  include DCI::Context

  role :Source do
    def withdraw(amount)
      @balance -= amount
    end
  end

  role :Sink do
    def deposit(amount)
      @balance += amount
    end
  end

  def initialize(source, target)
    self.Source = source
    self.Sink = target
  end
end
```

Context entry points are identified using the `entry` keyword. This allows
role players to refer each other during the execution of the Context.

```ruby
class MoneyTransfer
  include DCI::Context

  role :Source do
    def withdraw(amount)
      @balance -= amount
    end

    def transfer(amount)
      withdraw(amount)
      DCI::Context.current.Sink.deposit(amount)
    end
  end

  role :Sink do
    def deposit(amount)
      @balance += amount
    end
  end

  entry :transfer

  def initialize(source, target)
    self.Source = source
    self.Sink = target
  end

  def transfer(amount)
    self.Source.transfer(amount)
  end
end
```

`entry` also supports a shorthand to define the behavior at once.

```ruby
class MoneyTransfer
  include DCI::Context

  role :Source do
    def withdraw(amount)
      @balance -= amount
    end

    def transfer(amount)
      withdraw(amount)
      DCI::Context.current.Sink.deposit(amount)
    end
  end

  role :Sink do
    def deposit(amount)
      @balance += amount
    end
  end

  entry :transfer do |amount|
    self.Source.transfer(amount)
  end

  def initialize(source, target)
    self.Source = source
    self.Sink = target
  end
end
```

Lambdas can also be used with `entry`.

```ruby
entry :transfer, -> (amount) { self.Source.transfer(amount) }
```

When the Context class is not anonymous, referring to the current role players
can be done with bare constants.

```ruby
class MoneyTransfer
  include DCI::Context
  extend DCI::RoleLookup

  role :Source do
    def withdraw(amount)
      @balance -= amount
    end

    def transfer(amount)
      withdraw(amount)
      Sink.deposit(amount)
    end
  end

  role :Sink do
    def deposit(amount)
      @balance += amount
    end
  end

  entry :transfer, -> (amount) do
    Source.transfer(amount)
  end

  def initialize(source, target)
    self.Source = source
    self.Sink = target
  end
end
```
