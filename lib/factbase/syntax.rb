# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'backtrace'
require 'time'
require_relative '../factbase'
require_relative 'fact'
require_relative 'term'

# Syntax parser.
#
# This is an internal class, it is not supposed to be instantiated directly.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase::Syntax
  # If the syntax is broken.
  class Broken < StandardError; end

  # Ctor.
  #
  # The class provided as the +term+ argument must have a constructor that accepts
  # an operator, operands array, and a keyword argument fb. Also, it must be
  # a child of +Factbase::Term+.
  #
  # @param [String] query The query, for example "(eq id 42)"
  def initialize(query)
    @query = query
  end

  # Convert it to a term.
  # @return [Term] The term detected
  def to_term
    @to_term ||=
      begin
        t = build
        t = t.simplify if t.respond_to?(:simplify)
        t
      end
  rescue StandardError => e
    err = "#{e.message} (#{Backtrace.new(e)}) in \"#{@query}\""
    err = "#{err}, tokens: #{@tokens}" unless @tokens.nil?
    raise Broken, err
  end

  private

  # Convert it to a term.
  # @return [Term] The term detected
  def build
    @tokens ||= to_tokens
    raise 'No tokens' if @tokens.empty?
    @ast ||= to_ast(@tokens, 0)
    raise "Too many terms (#{@ast[1]} != #{@tokens.size})" if @ast[1] != @tokens.size
    t = @ast[0]
    raise 'No terms found in the AST' if t.nil?
    raise "#{t.class.name} is not an instance of Term" unless t.is_a?(Factbase::Term)
    t
  end

  # Reads the stream of tokens, starting at the +at+ position. If the
  # token at the position is not a literal (like 42 or "Hello") but a term,
  # the function recursively calls itself.
  #
  # The function returns a two-element array, where the first element
  # is the term/literal and the second one is the position where the
  # scanning should continue.
  #
  # @param [Array] tokens Array of tokens
  # @param [Integer] at Position to start parsing from
  # @return [Array<Factbase::Term,Integer>] The term detected and ending position
  def to_ast(tokens, at)
    raise "Closing too soon at ##{at}" if tokens[at] == :close
    return [tokens[at], at + 1] unless tokens[at] == :open
    at += 1
    op = tokens[at]
    raise 'No token found' if op == :close
    operands = []
    at += 1
    loop do
      raise "End of token stream at ##{at}" if tokens[at].nil?
      break if tokens[at] == :close
      (operand, at1) = to_ast(tokens, at)
      raise "Stuck at position ##{at}" if at == at1
      raise "Jump back at position ##{at}" if at1 < at
      at = at1
      operands << operand
      break if tokens[at] == :close
    end
    t = Factbase::Term.new(op, operands)
    [t, at + 1]
  end

  # Turns a query into an array of tokens.
  # @return [Array] Array of tokens
  def to_tokens
    list = []
    acc = ''
    quotes = ['\'', '"']
    spaces = [' ', ')']
    string = false
    comment = false
    @query.to_s.chars.each do |c|
      comment = true if !string && c == '#'
      comment = false if comment && c == "\n"
      next if comment
      if quotes.include?(c)
        if string && acc[acc.length - 1] == '\\'
          acc = acc[0..-2]
        else
          string = !string
        end
      end
      if string
        acc += c
        next
      end
      if !acc.empty? && spaces.include?(c)
        list << acc
        acc = ''
      end
      case c
      when '('
        list << :open
      when ')'
        list << :close
      when ' ', "\n", "\t", "\r"
        # ignore it
      else
        acc += c
      end
    end
    raise 'String not closed' if string
    list.map do |t|
      if t.is_a?(Symbol)
        t
      elsif t.start_with?('\'', '"')
        raise 'String literal can\'t be empty' if t.length <= 2
        t[1..-2]
      elsif t.match?(/^(\+|-)?[0-9]+$/)
        t.to_i
      elsif t.match?(/^(\+|-)?[0-9]+\.[0-9]+(e\+[0-9]+)?$/)
        t.to_f
      elsif t.match?(/^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$/)
        Time.parse(t)
      else
        raise "Wrong symbol format (#{t})" unless t.match?(/^([_a-z][a-zA-Z0-9_]*|\$[_a-z]+)$/)
        t.to_sym
      end
    end
  end
end
