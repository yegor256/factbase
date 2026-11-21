# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'open3'
require 'rbconfig'
require_relative 'test__helper'

# Tests that requiring the library doesn't pull in heavyweight stdlib.
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestRequireLight < Factbase::Test
  LIB = File.expand_path('../lib', __dir__)
  SCRIPT = 'require "factbase"; puts $LOADED_FEATURES.grep(%r{/(json|yaml|psych)(\.rb|/)}).size'

  def test_does_not_load_json_and_yaml
    out, status = Open3.capture2(RbConfig.ruby, '-I', LIB, '-e', SCRIPT)
    assert_predicate(status, :success?, 'the subprocess must exit with zero')
    assert_equal('0', out.strip)
  end
end
