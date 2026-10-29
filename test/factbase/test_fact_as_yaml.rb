# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'yaml'
require_relative '../../lib/factbase'
require_relative '../../lib/factbase/fact_as_yaml'
require_relative '../test__helper'

# Test.
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2026 Yegor Bugayenko
# License:: MIT
class TestFactAsYaml < Factbase::Test
  def test_preserves_nanoseconds_in_time_values
    fact = Factbase.new.insert
    times = [123_456_001, 123_456_999].map { |ns| Time.at(1_700_000_000, ns, :nanosecond).utc }
    times.each { |time| fact.when = time }
    fact.single = times.first
    yaml = YAML.safe_load(Factbase::FactAsYaml.new(fact).to_s, permitted_classes: [Time])
    assert_equal(times, yaml['when'])
    assert_equal(times.first, yaml['single'])
    refute_equal(yaml['when'][0], yaml['when'][1])
  end

  def test_prints_exactly
    f = Factbase.new.insert
    f._id = 1
    f.foo = 42
    f.foo = 33
    f.foo = 42
    f.bar = 'hello, world! how are you?'
    assert_equal(
      "_id: 1\n" \
      "bar: \"hello, world! how are you?\"\n" \
      'foo: [42, 33, 42]',
      Factbase::FactAsYaml.new(f).to_s
    )
  end

  def test_prints_false_values
    f = Factbase.new.insert
    f.flag = true
    f.flag = false
    f.solo = false
    assert_equal(
      "flag: [true, false]\n" \
      'solo: false',
      Factbase::FactAsYaml.new(f).to_s
    )
  end

  def test_simple_rendering
    f = Factbase.new.insert
    f._id = 1
    f.foo = 42
    f.bar = 'hello'
    yaml = YAML.load(Factbase::FactAsYaml.new(f).to_s)
    assert_equal(1, yaml['_id'])
    assert_equal('hello', yaml['bar'])
    assert_equal(42, yaml['foo'])
  end

  def test_multiple_values
    f = Factbase.new.insert
    f.foo = 42
    f.foo = 256
    f.foo = 512
    assert_equal([42, 256, 512], YAML.load(Factbase::FactAsYaml.new(f).to_s)['foo'])
  end

  def test_sorted_keys
    f = Factbase.new.insert
    f.c = 3
    f.a = 1
    f.b = 2
    yaml_str = Factbase::FactAsYaml.new(f).to_s
    assert_operator(yaml_str.index('a:'), :<, yaml_str.index('b:'))
    assert_operator(yaml_str.index('b:'), :<, yaml_str.index('c:'))
  end

  def test_usage_example_from_issue
    fb = Factbase.new
    f = fb.insert
    f._id = 1
    f.name = 'test'
    f = fb.query('(eq _id 1)').each.to_a.first
    yaml_str = Factbase::FactAsYaml.new(f).to_s
    assert(yaml_str)
    assert_includes(yaml_str, '_id')
    assert_includes(yaml_str, 'name')
  end

  def test_keeps_reserved_property_names_as_string_keys
    fb = Factbase.new
    f = fb.insert
    f.yes = 1
    f.null = 2
    f.name = 3
    assert_equal(
      { 'name' => 3, 'null' => 2, 'yes' => 1 },
      YAML.safe_load(Factbase::FactAsYaml.new(fb.query('(always)').each.to_a.first).to_s)
    )
  end

  def test_keeps_zone_of_printed_time
    seed = Random.new_seed
    rnd = Random.new(seed)
    zone = format('%+03d:00', [-1, 1].sample(random: rnd) * rnd.rand(1..11))
    fb = Factbase.new
    fb.insert.id = rnd.rand(1..1000)
    f = fb.query("(as t (to_time '2026-01-01T12:00:00#{zone}'))").each.first
    Factbase::FactAsYaml.new(f).to_s
    assert_equal(zone, f.t.strftime('%:z'), "printing changed the zone of the time, seed #{seed}")
  end

  def test_keeps_zones_of_printed_times
    seed = Random.new_seed
    rnd = Random.new(seed)
    zones = Array.new(2) { format('%+03d:00', [-1, 1].sample(random: rnd) * rnd.rand(1..11)) }
    fb = Factbase.new
    fb.insert.id = rnd.rand(1..1000)
    f = fb.query(
      "(and (as t (to_time '2026-01-01T12:00:00#{zones[0]}')) (as t (to_time '2026-02-01T12:00:00#{zones[1]}')))"
    ).each.first
    Factbase::FactAsYaml.new(f).to_s
    assert_equal(zones, f['t'].map { |t| t.strftime('%:z') }, "printing changed the zones of the times, seed #{seed}")
  end

  def test_prints_time_in_utc
    seed = Random.new_seed
    rnd = Random.new(seed)
    zone = format('%+03d:00', [-1, 1].sample(random: rnd) * rnd.rand(1..11))
    fb = Factbase.new
    fb.insert.id = rnd.rand(1..1000)
    assert_includes(
      Factbase::FactAsYaml.new(fb.query("(as t (to_time '2026-01-01T12:00:00.25#{zone}'))").each.first).to_s,
      "t: #{Time.parse("2026-01-01T12:00:00.25#{zone}").utc.iso8601(9)}",
      "printed time is not in UTC, seed #{seed}"
    )
  end

  def test_keeps_a_newline_escape_whole_in_a_long_string
    f = Factbase.new.insert
    f.message = "#{'a' * 29}\n#{'b' * 100}"
    assert_kind_of(
      String, YAML.safe_load(Factbase::FactAsYaml.new(f).to_s)['message'],
      'a long string with a newline is not printed as valid YAML'
    )
  end

  def test_keeps_a_control_character_escape_whole_in_a_long_string
    f = Factbase.new.insert
    f.message = "#{'a' * 25}\u0001#{'b' * 100}"
    assert_kind_of(
      String, YAML.safe_load(Factbase::FactAsYaml.new(f).to_s)['message'],
      'a long string with a control character is not printed as valid YAML'
    )
  end

  def test_keeps_quote_and_backslash_escapes_whole_in_a_long_string
    f = Factbase.new.insert
    f.message = "#{'a' * 29}\"\\#{'b' * 100}"
    assert_kind_of(
      String, YAML.safe_load(Factbase::FactAsYaml.new(f).to_s)['message'],
      'a long string with a quote and a backslash is not printed as valid YAML'
    )
  end

  def test_prints_valid_yaml_for_long_strings_full_of_escapes
    seed = Random.new_seed
    rnd = Random.new(seed)
    f = Factbase.new.insert
    f.message = Array.new(rnd.rand(80..300)) { ["\n", "\t", '"', '\\', "\u0002", 'ж', 'z'].sample(random: rnd) }.join
    assert_kind_of(
      String, YAML.safe_load(Factbase::FactAsYaml.new(f).to_s)['message'],
      "a long string full of escapes is not printed as valid YAML, seed #{seed}"
    )
  end

  def test_ruby_interpolation_syntax
    f = Factbase.new.insert
    f.msg = "\#{name}"
    f.ivar = "\#@name"
    f.gvar = "\#$name"
    yaml_str = Factbase::FactAsYaml.new(f).to_s
    assert_includes(yaml_str, 'msg:')
    assert_equal("\#{name}", YAML.safe_load(yaml_str)['msg'])
    assert_equal("\#@name", YAML.safe_load(yaml_str)['ivar'])
    assert_equal("\#$name", YAML.safe_load(yaml_str)['gvar'])
  end

  def test_interpolation_syntax_in_array
    f = Factbase.new.insert
    f.items = "\#{first}"
    f.items = "\#@second"
    f.items = "\#$third"
    yaml_str = Factbase::FactAsYaml.new(f).to_s
    assert_includes(yaml_str, 'items: [')
    assert_equal(["\#{first}", "\#@second", "\#$third"], YAML.safe_load(yaml_str)['items'])
  end

  def test_literal_backslash_followed_by_hash
    f = Factbase.new.insert
    f.raw = '\#abc'
    f.mid = 'foo\#bar'
    yaml_str = Factbase::FactAsYaml.new(f).to_s
    assert_equal('\#abc', YAML.safe_load(yaml_str)['raw'])
    assert_equal('foo\#bar', YAML.safe_load(yaml_str)['mid'])
  end

  def test_long_string_with_newline_does_not_break_yaml_syntax
    f = Factbase.new.insert
    f.message = "#{'a' * 29}\n#{'b' * 100}"
    parsed = YAML.safe_load(Factbase::FactAsYaml.new(f).to_s)
    assert_includes(parsed['message'], '...')
    assert_includes(parsed['message'], "\n")
  end

  def test_long_string_with_quotes_and_backslashes
    f = Factbase.new.insert
    f.text = "#{'x' * 20}\"quoted\"\\backslash\t#{'y' * 80}"
    assert_includes(YAML.safe_load(Factbase::FactAsYaml.new(f).to_s)['text'], '...')
  end
end
