# frozen_string_literal: true

# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Yegor Bugayenko
# SPDX-License-Identifier: MIT

require 'json'
require 'yaml'

# A factbase, which essentially is a NoSQL one-table in-memory database
# with a Lisp-ish query interface.
#
# This class is an entry point to a factbase. For example, this is how you
# add a new "fact" to a factbase, then put two properties into it, and then
# find this fact with a simple search.
#
#  fb = Factbase.new
#  f = fb.insert # new fact created
#  f.name = 'Jeff Lebowski'
#  f.age = 42
#  found = f.query('(gt 20 age)').each.to_a[0]
#  assert(found.age == 42)
#
# Every fact is a key-value hash map. Every value is a non-empty set of values.
# Consider this example of creating a factbase with a single fact inside:
#
#  fb = Factbase.new
#  f = fb.insert
#  f.name = 'Jeff'
#  f.name = 'Walter'
#  f.age = 42
#  f.age = 'unknown'
#  f.place = 'LA'
#  puts f.to_json
#
# This will print the following JSON:
#
#  {
#    'name': ['Jeff', 'Walter'],
#    'age': [42, 'unknown'],
#    'place': 'LA'
#  }
#
# Value sets, as you can see, allow data of different types. However, there
# are only four types are allowed: Integer, Float, String, and Time.
#
# A factbase may be exported to a file and then imported back:
#
#  fb1 = Factbase.new
#  File.binwrite(file, fb1.export)
#  fb2 = Factbase.new # it's empty
#  fb2.import(File.binread(file))
#
# It's impossible to delete properties of a fact. It is however possible to
# delete the entire fact, with the help of the +query()+ and then +delete!()+
# methods.
#
# It's important to use +binwrite+ and +binread+, because the content is
# a chain of bytes, not a text.
#
# Objects of this class are thread-safe.
#
# Author:: Yegor Bugayenko (yegor256@gmail.com)
# Copyright:: Copyright (c) 2024-2025 Yegor Bugayenko
# License:: MIT
class Factbase
  # Current version of the gem (changed by .rultor.yml on every release)
  VERSION = '0.0.0'

  # An exception that may be thrown in a transaction, to roll it back.
  class Rollback < StandardError; end

  # Constructor.
  # @param [Array<Hash>] maps Array of facts to start with
  def initialize(maps = [])
    @maps = maps
    @cache = {}
  end

  # Size, the total number of facts in the factbase.
  # @return [Integer] How many facts are in there
  def size
    @maps.size
  end

  # Insert a new fact and return it.
  #
  # A fact, when inserted, is empty. It doesn't contain any properties.
  #
  # The operation is thread-safe, meaning that you different threads may
  # insert facts parallel without breaking the consistency of the factbase.
  #
  # @return [Factbase::Fact] The fact just inserted
  def insert
    map = {}
    @maps << map
    require_relative 'factbase/fact'
    Factbase::Fact.new(map)
  end

  # Create a query capable of iterating.
  #
  # There is a Lisp-like syntax, for example:
  #
  #  (eq title 'Object Thinking')
  #  (gt time 2024-03-23T03:21:43Z)
  #  (gt cost 42)
  #  (exists seenBy)
  #  (and
  #    (eq foo 42.998)
  #    (or
  #      (gt bar 200)
  #      (absent zzz)))
  #
  # The full list of terms available in the query you can find in the
  # +README.md+ file of the repository.
  #
  # @param [String] query The query to use for selections
  def query(query)
    require_relative 'factbase/query'
    Factbase::Query.new(@maps, query)
  end

  # Run an ACID transaction, which will either modify the factbase
  # or rollback in case of an error.
  #
  # If necessary to terminate a transaction and roolback all changes,
  # you should raise the +Factbase::Rollback+ exception:
  #
  #  fb = Factbase.new
  #  fb.txn do |fbt|
  #    fbt.insert.bar = 42
  #    raise Factbase::Rollback
  #  end
  #
  # A the end of this script, the factbase will be empty. No facts will
  # inserted and all changes that happened in the block will be rolled back.
  #
  # @return [Factbase::Churn] How many facts have been changed (zero if rolled back)
  def txn
    pairs = {}
    before =
      @maps.map do |m|
        n = m.transform_values(&:dup)
        # rubocop:disable Lint/HashCompareByIdentity
        pairs[n.object_id] = m.object_id
        # rubocop:enable Lint/HashCompareByIdentity
        n
      end
    require_relative 'factbase/taped'
    taped = Factbase::Taped.new(before)
    begin
      require_relative 'factbase/light'
      yield Factbase::Light.new(Factbase.new(taped))
    rescue Factbase::Rollback
      return 0
    end
    require_relative 'factbase/churn'
    churn = Factbase::Churn.new
    taped.inserted.each do |oid|
      b = taped.find_by_object_id(oid)
      next if b.nil?
      @maps << b
      churn.append(1, 0, 0)
    end
    garbage = []
    taped.added.each do |oid|
      b = taped.find_by_object_id(oid)
      next if b.nil?
      garbage << pairs[oid]
      @maps << b
      churn.append(0, 0, 1)
    end
    taped.deleted.each do |oid|
      garbage << pairs[oid]
      churn.append(0, 1, 0)
    end
    @maps.delete_if { |m| garbage.include?(m.object_id) }
    churn
  end

  # Export it into a chain of bytes.
  #
  # Here is how you can export it to a file, for example:
  #
  #  fb = Factbase.new
  #  fb.insert.foo = 42
  #  File.binwrite("foo.fb", fb.export)
  #
  # The data is binary, it's not a text!
  #
  # @return [Bytes] The chain of bytes
  def export
    Marshal.dump(@maps)
  end

  # Import from a chain of bytes.
  #
  # Here is how you can read it from a file, for example:
  #
  #  fb = Factbase.new
  #  fb.import(File.binread("foo.fb"))
  #
  # The facts that existed in the factbase before importing will remain there.
  # The facts from the incoming byte stream will added to them.
  #
  # @param [Bytes] bytes Byte array to import
  def import(bytes)
    raise 'Empty input, cannot load a factbase' if bytes.empty?
    @maps += Marshal.load(bytes)
  end
end
