# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require_relative '../factbase'
require_relative '../factbase/flatten'

# Factbase to YAML converter.
#
# This class helps converting an entire Factbase to YAML format, for example:
#
#  require 'factbase/to_yaml'
#  fb = Factbase.new
#  puts Factbase::ToYAML.new(fb).yaml
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::ToYAML
  # Constructor.
  def initialize(fb, sorter = '_id')
    @fb = fb
    @sorter = sorter
  end

  # Convert the entire factbase into YAML.
  # @return [String] The factbase in YAML format
  def yaml
    YAML.dump(Factbase::Flatten.new(Marshal.load(@fb.export), @sorter).it)
  end
end
