# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'minitest/autorun'

class TestRakefile < Minitest::Test
  load File.expand_path('../Rakefile', __dir__)

  def test_tail_with_arguments
    [
      { input: %w[-- --no-cov], expected: '-- --no-cov' },
      { input: %w[-- --no-cov --verbose], expected: '-- --no-cov --verbose' },
      { input: %w[test -- --no-cov --verbose], expected: '-- --no-cov --verbose' }
    ].each do |c|
      assert_equal(c[:expected], tail(c[:input]), c[:input])
    end
  end

  def test_tail_without_arguments
    [
      { input: %w[], expected: '' },
      { input: %w[--], expected: '' },
      { input: %w[no--cov], expected: '' },
      { input: %w[--no-cov], expected: '' },
      { input: %w[test --no-cov], expected: '' }
    ].each do |c|
      assert_equal(c[:expected], tail(c[:input]), c[:input])
    end
  end
end
