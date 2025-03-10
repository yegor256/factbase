# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../../factbase'

# System-level terms.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
module Factbase::Term::System
  def env(fact, maps, fb)
    assert_args(2)
    n = _values(0, fact, maps, fb)[0]
    ENV.fetch(n.upcase) { _values(1, fact, maps, fb)[0] }
  end
end
