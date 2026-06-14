# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'parser/current'
require_relative 'test__helper'

# Detects an antipattern that RuboCop's +Lint/UselessAssignment+ misses:
# a local variable is initialized just before an +if+/+unless+/+case+ that
# overwrites the variable in every reachable branch, never having read the
# initial value. See yegor256/factbase#485.
class TestNoUselessConditionalAssignment < Factbase::Test
  ROOT = File.expand_path('../lib', __dir__)

  def test_lib_is_free_of_useless_conditional_assignments
    offenses = []
    Dir.glob(File.join(ROOT, '**', '*.rb')).each do |path|
      ast =
        begin
          Parser::CurrentRuby.parse(File.read(path))
        rescue Parser::SyntaxError
          nil
        end
      next if ast.nil?
      walk(ast) { |seq| scan_sequence(seq.children, path, offenses) }
    end
    assert_empty(offenses, format_message(offenses))
  end

  private

  def format_message(offenses)
    [
      "Found #{offenses.size} useless pre-conditional assignment(s):",
      *offenses.map do |o|
        "  #{o[:path]}:#{o[:line]}: `#{o[:var]} = ...` is overwritten by the following conditional"
      end,
      'See https://github.com/yegor256/factbase/issues/485'
    ].join("\n")
  end

  def walk(node, &block)
    return unless node.is_a?(Parser::AST::Node)
    yield(node) if node.type == :begin
    node.children.each { |c| walk(c, &block) }
  end

  def scan_sequence(stmts, path, offenses)
    stmts.each_with_index do |stmt, i|
      next unless stmt.is_a?(Parser::AST::Node) && stmt.type == :lvasgn
      var, rhs = stmt.children
      next if rhs.nil?
      next if reads?(rhs, var)
      nxt = stmts[i + 1]
      next unless nxt.is_a?(Parser::AST::Node) && nxt.type == :if
      cond, tbranch, fbranch = nxt.children
      next if reads?(cond, var)
      next unless overwrites_without_reading?(tbranch, var)
      if fbranch.nil?
        rest = stmts[(i + 2)..] || []
        next if rest.any? { |s| reads?(s, var) }
      else
        next unless overwrites_without_reading?(fbranch, var)
      end
      offenses << { path: path, line: stmt.loc.line, var: var }
    end
  end

  # Does the subtree read +var+ as a local variable?
  def reads?(node, var)
    return false unless node.is_a?(Parser::AST::Node)
    return true if node.type == :lvar && node.children[0] == var
    node.children.any? { |c| reads?(c, var) }
  end

  # In execution order, does +branch+ assign +var+ before any read of +var+,
  # with the assignment's right-hand side itself not reading +var+? A +nil+
  # branch counts as "no assignment".
  def overwrites_without_reading?(branch, var)
    return false if branch.nil?
    stmts = branch.is_a?(Parser::AST::Node) && branch.type == :begin ? branch.children : [branch]
    stmts.each do |s|
      next unless s.is_a?(Parser::AST::Node)
      if s.type == :lvasgn && s.children[0] == var
        rhs = s.children[1]
        return false if rhs && reads?(rhs, var)
        return true
      end
      return false if reads?(s, var)
    end
    false
  end
end
