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
#
# This is an internal class, it is not supposed to be instantiated directly.
#
# It is possible to use for testing directly, for example to make a
# term with two arguments:
#
#  require 'factbase/fact'
#  require 'factbase/term'
#  f = Factbase::Fact.new(Mutex.new, { 'foo' => [42, 256, 'Hello, world!'] })
#  t = Factbase::Term.new(:lt, [:foo, 50])
#  assert(t.evaluate(f))
#
# The design of this class may look ugly, since it has a large number of
# methods, each of which corresponds to a different type of a +Term+. A much
# better design would definitely involve many classes, one per each type
# of a term. It's not done this way because of an experimental nature of
# the project. Most probably we should keep current design intact, since it
# works well and is rather simple to extend (by adding new term types).
# Moreover, it looks like the number of possible term types is rather limited
# and currently we implement most of them.
#
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
  # @param [Array<Factbase::Fact>] maps All maps available
  # @return [bool] TRUE if matches
  def evaluate(fact, maps)
    send(@op, fact, maps)
  rescue NoMethodError => e
    raise "Term '#{@op}' is not defined: #{e.message}"
  end

  # Simplify it if possible.
  # @return [Factbase::Term] New term or itself
  def simplify
    m = "#{@op}_simplify"
    if respond_to?(m, true)
      send(m)
    else
      self
    end
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

  def always(_fact, _maps)
    assert_args(0)
    true
  end

  def never(_fact, _maps)
    assert_args(0)
    false
  end

  def not(fact, maps)
    assert_args(1)
    !only_bool(the_values(0, fact, maps))
  end

  def or(fact, maps)
    (0..@operands.size - 1).each do |i|
      return true if only_bool(the_values(i, fact, maps))
    end
    false
  end

  def and(fact, maps)
    (0..@operands.size - 1).each do |i|
      return false unless only_bool(the_values(i, fact, maps))
    end
    true
  end

  def and_or_simplify
    strs = []
    ops = []
    @operands.each do |o|
      o = o.simplify
      s = o.to_s
      next if strs.include?(s)
      strs << s
      ops << o
    end
    return ops[0] if ops.size == 1
    Factbase::Term.new(@op, ops)
  end

  def and_simplify
    and_or_simplify
  end

  def or_simplify
    and_or_simplify
  end

  def when(fact, maps)
    assert_args(2)
    a = @operands[0]
    b = @operands[1]
    !a.evaluate(fact, maps) || (a.evaluate(fact, maps) && b.evaluate(fact, maps))
  end

  def exists(fact, _maps)
    assert_args(1)
    !by_symbol(0, fact).nil?
  end

  def absent(fact, _maps)
    assert_args(1)
    by_symbol(0, fact).nil?
  end

  def either(fact, maps)
    assert_args(2)
    v = the_values(0, fact, maps)
    return v unless v.nil?
    the_values(1, fact, maps)
  end

  def at(fact, maps)
    assert_args(2)
    i = the_values(0, fact, maps)
    raise 'Too many values at first position, one expected' unless i.size == 1
    i = i[0]
    return nil if i.nil?
    v = the_values(1, fact, maps)
    return nil if v.nil?
    v[i]
  end

  def prev(fact, maps)
    assert_args(1)
    before = @prev
    v = the_values(0, fact, maps)
    @prev = v
    before
  end

  def unique(fact, _maps)
    @uniques = [] if @uniques.nil?
    assert_args(1)
    vv = by_symbol(0, fact)
    return false if vv.nil?
    vv = [vv] unless vv.is_a?(Array)
    vv.each do |v|
      return false if @uniques.include?(v)
      @uniques << v
    end
    true
  end

  def many(fact, maps)
    assert_args(1)
    v = the_values(0, fact, maps)
    !v.nil? && v.size > 1
  end

  def one(fact, maps)
    assert_args(1)
    v = the_values(0, fact, maps)
    !v.nil? && v.size == 1
  end

  def plus(fact, maps)
    arithmetic(:+, fact, maps)
  end

  def minus(fact, maps)
    arithmetic(:-, fact, maps)
  end

  def times(fact, maps)
    arithmetic(:*, fact, maps)
  end

  def div(fact, maps)
    arithmetic(:/, fact, maps)
  end

  def eq(fact, maps)
    cmp(:==, fact, maps)
  end

  def lt(fact, maps)
    cmp(:<, fact, maps)
  end

  def gt(fact, maps)
    cmp(:>, fact, maps)
  end

  def size(fact, _maps)
    assert_args(1)
    v = by_symbol(0, fact)
    return 0 if v.nil?
    return 1 unless v.is_a?(Array)
    v.size
  end

  def type(fact, _maps)
    assert_args(1)
    v = by_symbol(0, fact)
    return 'nil' if v.nil?
    v.class.to_s
  end

  def matches(fact, maps)
    assert_args(2)
    str = the_values(0, fact, maps)
    return false if str.nil?
    raise 'Exactly one string expected' unless str.size == 1
    re = the_values(1, fact, maps)
    raise 'Regexp is nil' if re.nil?
    raise 'Exactly one regexp expected' unless re.size == 1
    str[0].to_s.match?(re[0])
  end

  def cmp(op, fact, maps)
    assert_args(2)
    lefts = the_values(0, fact, maps)
    return false if lefts.nil?
    rights = the_values(1, fact, maps)
    return false if rights.nil?
    lefts.any? do |l|
      l = l.floor if l.is_a?(Time) && op == :==
      rights.any? do |r|
        r = r.floor if r.is_a?(Time) && op == :==
        l.send(op, r)
      end
    end
  end

  def arithmetic(op, fact, maps)
    assert_args(2)
    lefts = the_values(0, fact, maps)
    raise 'The first argument is NIL, while literal expected' if lefts.nil?
    raise 'Too many values at first position, one expected' unless lefts.size == 1
    rights = the_values(1, fact, maps)
    raise 'The second argument is NIL, while literal expected' if rights.nil?
    raise 'Too many values at second position, one expected' unless rights.size == 1
    lefts[0].send(op, rights[0])
  end

  def defn(_fact, _maps)
    fn = @operands[0]
    raise 'A symbol expected as first argument of defn' unless fn.is_a?(Symbol)
    e = "class Factbase::Term\nprivate\ndef #{fn}(fact, maps)\n#{@operands[1]}\nend\nend"
    # rubocop:disable Security/Eval
    eval(e)
    # rubocop:enable Security/Eval
    true
  end

  def min(_fact, maps)
    @min ||= best(maps) { |v, b| v < b }
  end

  def max(_fact, maps)
    @max ||= best(maps) { |v, b| v > b }
  end

  def count(_fact, maps)
    @count ||= maps.size
  end

  def sum(_fact, maps)
    @sum ||=
      begin
        k = @operands[0]
        raise "A symbol expected, but provided: #{k}" unless k.is_a?(Symbol)
        sum = 0
        maps.each do |m|
          vv = m[k.to_s]
          next if vv.nil?
          vv = [vv] unless vv.is_a?(Array)
          vv.each do |v|
            sum += v
          end
        end
        sum
      end
  end

  def agg(_fact, maps)
    selector = @operands[0]
    raise "A term expected, but #{selector} provided" unless selector.is_a?(Factbase::Term)
    term = @operands[1]
    raise "A term expected, but #{term} provided" unless term.is_a?(Factbase::Term)
    subset = maps.select { |m| selector.evaluate(m, maps) }
    @agg ||=
      if subset.empty?
        term.evaluate(Factbase::Fact.new(Mutex.new, {}), subset)
      else
        term.evaluate(subset.first, subset)
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

  def the_values(pos, fact, maps)
    v = @operands[pos]
    v = v.evaluate(fact, maps) if v.is_a?(Factbase::Term)
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

  def best(maps)
    k = @operands[0]
    raise "A symbol expected, but provided: #{k}" unless k.is_a?(Symbol)
    best = nil
    maps.each do |m|
      vv = m[k.to_s]
      next if vv.nil?
      vv = [vv] unless vv.is_a?(Array)
      vv.each do |v|
        best = v if best.nil? || yield(v, best)
      end
    end
    best
  end
end
