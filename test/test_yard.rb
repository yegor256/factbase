# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative 'test__helper'
require 'yard'

class TestYard < Factbase::Test
  def test_params_match_method_signatures
    YARD.parse(Dir['lib/**/*.rb'])
    YARD::Registry.all(:method).each do |obj|
      next if obj.tags(:param).empty?
      next if obj.parameters.nil? || obj.parameters.empty?
      param_names = obj.parameters.map { |p| p[0].sub(/^\**/, '').sub(/:$/, '') }
      obj.tags(:param).each do |tag|
        assert_includes(
          param_names, tag.name,
          "In #{obj.file}:#{obj.line}: " \
          "@param #{tag.name} not found in " \
          "#{obj.namespace}##{obj.name}(#{param_names.join(', ')})"
        )
      end
    end
  end
end
