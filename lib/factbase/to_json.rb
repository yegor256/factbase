# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require_relative '../factbase'
require_relative '../factbase/flatten'

# Factbase to JSON converter.
#
# This class helps converting an entire Factbase to YAML format, for example:
#
#  require 'factbase/to_json'
#  fb = Factbase.new
#  puts Factbase::ToJSON.new(fb).json
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class Factbase::ToJSON
  # Constructor.
  def initialize(fb, sorter = '_id')
    @fb = fb
    @sorter = sorter
  end

  # Convert the entire factbase into JSON.
  # @return [String] The factbase in JSON format
  def json
    Factbase::Flatten.new(Marshal.load(@fb.export), @sorter).it.to_json
  end
end
