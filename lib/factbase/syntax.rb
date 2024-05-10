# frozen_string_literal: true

# Copyright (c) 2024 Yegor Bugayenko
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the 'Software'), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'cgi'
require_relative 'fact'
require_relative 'term'

# Syntax.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Syntax
  def initialize(query)
    @query = query
  end

  # Convert it to a term.
  # @return [Term] The term detected
  def to_term
    @tokens ||= to_tokens
    @ast ||= to_ast(@tokens, 0)
    @ast[0]
  end

  private

  # Reads the stream of tokens, starting at the +at+ position. If the
  # token at the position is not a literal (like 42 or "Hello") but a term,
  # the function recursively calls itself.
  #
  # The function returns an two-elements array, where the first element
  # is the term/literal and the second one is the position where the
  # scanning should continue.
  def to_ast(tokens, at)
    return [tokens[at], at + 1] unless tokens[at] == :open
    at += 1
    op = tokens[at]
    return [Factbase::Term.new(:nil, []), at + 1] if op == :close
    operands = []
    at += 1
    loop do
      break if tokens[at] == :close
      (operand, at1) = to_ast(tokens, at)
      at = at1
      operands << operand
      break if tokens[at] == :close
    end
    [Factbase::Term.new(op, operands), at + 1]
  end

  def to_tokens
    list = []
    acc = ''
    @query.to_s.chars.each do |c|
      if !acc.empty? && [' ', ')'].include?(c)
        list << acc
        acc = ''
      end
      case c
      when '('
        list << :open
      when ')'
        list << :close
      when ' '
        # ignore it
      else
        acc += c
      end
    end
    list.map do |t|
      if t.is_a?(Symbol)
        t
      elsif t.start_with?('\'')
        CGI.unescapeHTML(t[1..-2])
      elsif t.match?(/^[0-9]+$/)
        t.to_i
      else
        t.to_sym
      end
    end
  end
end
