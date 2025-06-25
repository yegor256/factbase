# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# Debug terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Debug
  def traced(fact, maps, fb)
    assert_args(1)
    t = @operands[0]
    raise "A term expected, but '#{t}' provided" unless t.is_a?(Factbase::Term)
    r = t.evaluate(fact, maps, fb)
    puts "#{self} -> #{r}"
    r
  end

  def assert(fact, maps, fb)
    assert_args(2)
    message = @operands[0]
    unless message.is_a?(String)
      raise ArgumentError,
            "A string expected as first argument of 'assert', but '#{message}' provided"
    end
    t = @operands[1]
    unless t.is_a?(Factbase::Term)
      raise ArgumentError,
            "A term expected as second argument of 'assert', but '#{t}' provided"
    end
    result = t.evaluate(fact, maps, fb)
    # Convert result to boolean-like evaluation
    # Arrays are truthy if they contain at least one truthy element
    truthy =
      if result.is_a?(Array)
        result.any? { |v| v && v != 0 }
      else
        result && result != 0
      end
    raise message unless truthy
    true
  end
end
