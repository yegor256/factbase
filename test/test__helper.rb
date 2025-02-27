# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

$stdout.sync = true

require 'simplecov'
SimpleCov.external_at_exit = true
SimpleCov.start

require 'simplecov-cobertura'
SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

require 'minitest/autorun'

require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

require_relative '../lib/factbase'

# Default methods for all tests.
class Factbase::Test < Minitest::Test
  def fact(map = {})
    require 'factbase/fact'
    Factbase::Fact.new(Factbase.new, Mutex.new, map)
  end
end
