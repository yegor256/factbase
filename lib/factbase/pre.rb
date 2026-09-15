# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'decoor'
require 'loog'
require_relative '../factbase'

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

  def initialize(fb, inside: false, &block)
    raise(ArgumentError, 'The "fb" is nil') if fb.nil?
    @fb = fb
    @inside = inside
    @block = block
  end

  def insert
    f = nil
    if @inside
      f = @fb.insert
      @block.call(f, self)
    else
      @fb.txn do |fbt|
        f = fbt.insert
        @block.call(f, self)
      end
    end
    f
  end

  def txn
    @fb.txn do |fbt|
      yield(Factbase::Pre.new(fbt, inside: true, &@block))
    end
  end
end
