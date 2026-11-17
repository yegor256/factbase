# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../../lib/factbase'
require_relative '../../../lib/factbase/indexed/keyed'
require_relative '../../../lib/factbase/lazy_taped'

require_relative '../../test__helper'

# Test for Keyed.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestKeyed < Factbase::Test
  class Reporter
    include Factbase::Keyed

    def report(maps)
      the_key(maps)
    end
  end

  def test_keys_a_plain_array_by_its_own_object
    maps = [{ 'a' => 1 }]
    assert_equal(maps.object_id, Reporter.new.report(maps))
  end

  def test_takes_the_key_a_decorator_reports
    maps = Factbase::LazyTaped.new([{ 'a' => 1 }])
    assert_equal(maps.the_key, Reporter.new.report(maps))
  end
end
