# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'loog'
require_relative '../factbase'
require_relative 'enumerated'

# A decorator of a +Factbase+, that runs a provided block on every +insert+.
#
# For example, you can use this decorator if you want to put some properties
# into every fact that gets into the factbase:
#
#  fb = Factbase::Pre.new(Factbase.new) do |f, fbt|
#    f.when = Time.now
#  end
#
# The second argument passed to the block is the factbase, while the first
# one is the fact just inserted.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::Pre
  decoor(:fb)
  include Factbase::Enumerated

  def initialize(fb, &block)
    raise(ArgumentError, 'The "fb" is nil') if fb.nil?
    @fb = fb
    @block = block
  end

  def insert
    f = @fb.insert
    @block.call(f, self)
    f
  end

  def import(bytes)
    probe = Factbase.new
    probe.import(bytes)
    @fb.txn do |fbt|
      context = Factbase::Pre.new(fbt, &@block)
      probe.query('(always)').each do |source|
        fact = fbt.insert
        source.all_properties.each do |property|
          source[property].each { |value| fact.public_send(:"#{property}=", value) }
        end
        @block.call(fact, context)
      end
    end
  end

  def txn
    @fb.txn do |fbt|
      yield(Factbase::Pre.new(fbt, &@block))
    end
  end
end
