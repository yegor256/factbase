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

  def test_return_types_match_returned_values
    YARD.parse(Dir['lib/**/*.rb'])
    fb = Factbase.new
    fb.insert.price = 1.25
    fb.insert.qty = 7
    {
      '(sum price)' => 'Factbase::Sum',
      '(sum qty)' => 'Factbase::Sum',
      '(to_integer missing)' => 'Factbase::ToInteger',
      '(to_float missing)' => 'Factbase::ToFloat',
      '(to_string missing)' => 'Factbase::ToString',
      '(to_time missing)' => 'Factbase::ToTime'
    }.each do |query, name|
      value = fb.query(query).one
      declared = YARD::Registry.at("#{name}#evaluate").tag(:return).types
      declared = declared.map { |t| t == 'NilClass' ? 'nil' : t }
      assert_includes(
        declared,
        value.nil? ? 'nil' : value.class.name,
        "#{name}#evaluate returns #{value.inspect} (#{value.class}) for #{query}, " \
        "but @return declares #{declared.join(', ')}"
      )
    end
  end
end
