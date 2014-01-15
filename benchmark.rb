require 'benchmark'
require 'dci'

class ExampleActor
  include DCI::Castable

  def regular; end
end

class ExampleContext
  include DCI::Context

  def regular; end
  entry :entry do; end

  entry :with do |actor, &block|
    cast(actor, :as => ExampleRole)
    block.call
  end
end

module ExampleRole
  def role; end
end

actor = ExampleActor.new
context = ExampleContext.new
number_of = 10_000

Benchmark.bm(20) do |bm|
  bm.report('Context method') { number_of.times { context.regular } }
  bm.report('Context entry point') { number_of.times { context.entry } }
end

Benchmark.bm(20) do |bm|
  context.with(actor) do
    bm.report('Actor method') { number_of.times { actor.regular } }
    bm.report('Role method') { number_of.times { actor.role } }
  end
end

Benchmark.bm(20) do |bm|
  object = Object.new
  bm.report('Method missing') { number_of.times { object.missing rescue NoMethodError } }
  bm.report('Not participating') { number_of.times { actor.missing rescue NoMethodError } }

  context.with(actor) do
    bm.report('Not implemented') { number_of.times { actor.missing rescue NoMethodError } }
  end
end

Benchmark.bm(20) do |bm|
  bm.report('Create object') { number_of.times { Object.new } }
  bm.report('Create actor') { number_of.times { ExampleActor.new } }

  bm.report('Cast object') { number_of.times { context.with(Object.new) {} } }
  bm.report('Cast actor') { number_of.times { context.with(ExampleActor.new) {} } }
end
