# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'

# Test for the GitHub workflows.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestWorkflows < Factbase::Test
  def test_pins_every_action_to_a_release_or_a_commit
    assert_empty(
      Dir[File.expand_path('../.github/workflows/*.yml', __dir__)]
        .flat_map { |f| File.read(f).scan(/uses:\s*(\S+)/).flatten }
        .grep_v(/@(v?\d+(\.\d+)*|\h{40})\z/),
      'some workflow runs an action that is not pinned to a release or a commit'
    )
  end
end
