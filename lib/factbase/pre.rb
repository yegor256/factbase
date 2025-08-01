# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'loog'
require 'decoor'
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
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Pre
  decoor(:fb)

  def initialize(fb, &block)
    raise 'The "fb" is nil' if fb.nil?
    @fb = fb
    @block = block
  end

  def insert
    f = @fb.insert
    @block.call(f, self)
    f
  end

  def txn
    @fb.txn do |fbt|
      yield Factbase::Pre.new(fbt, &@block)
    end
  end
end
