# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../test__helper'
require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/sync/sync_factbase'

# Sync factbase test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class TestSyncFactbase < Factbase::Test
  def test_queries_and_inserts
    fb = Factbase::SyncFactbase.new(Factbase.new)
    fb.insert.foo = 42
    fb.query('(exists foo)').each do
      fb.insert
    end
  end
end
