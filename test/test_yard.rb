# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require_relative '../lib/factbase'
require_relative '../lib/factbase/flatten'
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

  def test_names_only_existing_element_types
    Dir['lib/**/*.rb'].each { |f| require_relative("../#{f}") }
    YARD.parse(Dir['lib/**/*.rb'])
    missing = []
    YARD::Registry.all(:method).each do |obj|
      (obj.tags(:param) + obj.tags(:return)).each do |tag|
        (tag.types || []).each do |type|
          inner_names(type).each do |name|
            missing << "#{obj.file}:#{obj.line}: #{name}" unless defined_type?(name)
          end
        end
      end
    end
    assert_empty(missing)
  end

  def test_flatten_declares_hash_elements
    YARD.parse(Dir['lib/**/*.rb'])
    assert_equal(['Array<Hash>'], YARD::Registry.at('Factbase::Flatten#it').tag(:return).types)
    assert(Factbase::Flatten.new([{ 'id' => [1] }]).it.all?(Hash))
  end

  private

  # The names between the angle brackets of a YARD type, one per element.
  def inner_names(type)
    type.scan(/<([^<>]+)>/).flat_map { |m| m[0].split(',').map(&:strip) }
  end

  def defined_type?(name)
    ["Factbase::#{name}", name].any? { |c| Object.const_defined?(c) }
  rescue NameError
    false
  end
end
