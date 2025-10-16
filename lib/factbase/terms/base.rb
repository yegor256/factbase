# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

# Test for unique term.
# Author:: Volodya Lombrozo (volodya.lombrozo@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT

# Base class for all terms.
class Factbase::TermBase
  require_relative 'shared'
  include Factbase::TermShared

  protected :assert_args, :_by_symbol, :_values, :to_s
end
