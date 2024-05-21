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

require_relative '../factbase'
require_relative 'fact'

# Term.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024 Yegor Bugayenko
# License:: MIT
class Factbase::Term
  attr_reader :op, :operands

  # Ctor.
  # @param [Symbol] operator Operator
  # @param [Array] operands Operands
  def initialize(operator, operands)
    @op = operator
    @operands = operands
  end

  # Does it match the fact?
  # @param [Factbase::Fact] fact The fact
  # @return [bool] TRUE if matches
  def evaluate(fact)
    send(@op, fact)
  end

  # Put it into the context: let it see the entire array of maps.
  # @param [Array] maps The maps
  # @return [Factbase::Term] Itself
  def on(maps)
    m = "#{@op}_on"
    send(m, maps) if respond_to?(m, true)
    @operands.each do |o|
      o.on(maps) if o.is_a?(Factbase::Term)
    end
    self
  end

  # Turns it into a string.
  # @return [String] The string of it
  def to_s
    items = []
    items << @op
    items += @operands.map do |o|
      if o.is_a?(String)
        "'#{o.gsub("'", "\\\\'").gsub('"', '\\\\"')}'"
      elsif o.is_a?(Time)
        o.utc.iso8601
      else
        o.to_s
      end
    end
    "(#{items.join(' ')})"
  end

  private

  def nil(_fact)
    assert_args(0)
    true
  end

  def not(fact)
    assert_args(1)
    !only_bool(the_value(0, fact))
  end

  def or(fact)
    (0..@operands.size - 1).each do |i|
      return true if only_bool(the_value(i, fact))
    end
    false
  end

  def and(fact)
    (0..@operands.size - 1).each do |i|
      return false unless only_bool(the_value(i, fact))
    end
    true
  end

  def when(fact)
    assert_args(2)
    a = @operands[0]
    b = @operands[1]
    !a.evaluate(fact) || (a.evaluate(fact) && b.evaluate(fact))
  end

  def exists(fact)
    assert_args(1)
    !by_symbol(0, fact).nil?
  end

  def absent(fact)
    assert_args(1)
    by_symbol(0, fact).nil?
  end

  def eq(fact)
    arithmetic(:==, fact)
  end

  def lt(fact)
    arithmetic(:<, fact)
  end

  def gt(fact)
    arithmetic(:>, fact)
  end

  def size(fact)
    assert_args(1)
    v = by_symbol(0, fact)
    return 0 if v.nil?
    return 1 unless v.is_a?(Array)
    v.size
  end

  def type(fact)
    assert_args(1)
    v = by_symbol(0, fact)
    return 'nil' if v.nil?
    v.class.to_s
  end

  def matches(fact)
    assert_args(2)
    str = the_value(0, fact)
    raise 'String is nil' if str.nil?
    raise 'Exactly one string expected' unless str.size == 1
    re = the_value(1, fact)
    raise 'Regexp is nil' if re.nil?
    raise 'Exactly one regexp expected' unless re.size == 1
    str[0].to_s.match?(re[0])
  end

  def arithmetic(op, fact)
    assert_args(2)
    lefts = the_value(0, fact)
    return false if lefts.nil?
    rights = the_value(1, fact)
    return false if rights.nil?
    lefts.any? do |l|
      l = l.floor if l.is_a?(Time) && op == :==
      rights.any? do |r|
        r = r.floor if r.is_a?(Time) && op == :==
        l.send(op, r)
      end
    end
  end

  def defn(_fact)
    fn = @operands[0]
    raise 'A symbol expected as first argument of defn' unless fn.is_a?(Symbol)
    e = "class Factbase::Term\nprivate\ndef #{fn}(fact)\n#{@operands[1]}\nend\nend"
    # rubocop:disable Security/Eval
    eval(e)
    # rubocop:enable Security/Eval
    true
  end

  def max(fact)
    vv = the_value(0, fact)
    vv.any? { |v| v == @max }
  end

  def max_on(maps)
    k = @operands[0]
    raise "A symbol expected, but provided: #{k}" unless k.is_a?(Symbol)
    @max = nil
    maps.each do |m|
      vv = m[k.to_s]
      next if vv.nil?
      vv = [vv] unless vv.is_a?(Array)
      vv.each do |v|
        @max = v if @max.nil? || v > @max
      end
    end
  end

  def assert_args(num)
    c = @operands.size
    raise "Too many (#{c}) operands for '#{@op}' (#{num} expected)" if c > num
    raise "Too few (#{c}) operands for '#{@op}' (#{num} expected)" if c < num
  end

  def by_symbol(pos, fact)
    o = @operands[pos]
    raise "A symbol expected at ##{pos}, but provided: #{o}" unless o.is_a?(Symbol)
    k = o.to_s
    fact[k]
  end

  def the_value(pos, fact)
    v = @operands[pos]
    v = v.evaluate(fact) if v.is_a?(Factbase::Term)
    v = fact[v.to_s] if v.is_a?(Symbol)
    return v if v.nil?
    v = [v] unless v.is_a?(Array)
    v
  end

  def only_bool(val)
    val = val[0] if val.is_a?(Array)
    return false if val.nil?
    raise "Boolean expected, while #{val.class} received" unless val.is_a?(TrueClass) || val.is_a?(FalseClass)
    val
  end
end
