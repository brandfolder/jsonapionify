require 'enumerable_observer'
require 'active_support/core_ext/module/delegation'
require 'concurrent'

module JSONAPIonify::Structure
  module Collections
    class Base < Array
      include Helpers::InheritsOrigin
      attr_reader :parent

      delegate :cache_store, to: JSONAPIonify

      def self.value_is(type_class)
        define_method(:type_class) do
          type_class
        end
      end

      value_is Objects::Base

      def initialize(array = [])
        array.each do |instance|
          self << instance
        end
      end

      def original_method(method)
        Array.instance_method(method).bind(self)
      end

      def validate
        each do |member|
          member.validate if member.respond_to? :validate
        end
      end

      def signature
        "#{self.class.name}:#{Digest::SHA2.hexdigest map(&:signature).join}"
      end

      def collect_hashes
        map do |member|
          case member
          when Objects::Base, Hash
            member.to_h
          else
            member
          end
        end
      end

      def compile
        collect_hashes
      end

      def new(**attributes)
        self << attributes
      end

      alias_method :append, :new

      def <<(instance)
        new_instance =
          case instance
          when Hash
            type_class.new(**instance)
          when type_class
            instance
          else
            if type_class < instance.class
              type_class.from_hash instance.to_h
            else
              raise(
                ValidationError,
                "Can't initialize collection `#{self.class.name}` with a type of `#{instance.class.name}`"
              )
            end
          end
        self[length] = new_instance
      end

      def [] k
        v = super
        v.nil? || v.instance_variable_get(:@parent) == self ? v : self[k] = v
      end

      def []= k, v
        unless v.nil? || v.instance_variable_get(:@parent) == self
          v = v.dup.tap { |obj| obj.instance_variable_set :@parent, self}
        end
        super(k, v)
      end

      def each
        length.times do |i|
          yield self[i]
        end
      end

      def errors
        map.each_with_index.each_with_object({}) do |(value, key), errors|
          next unless value.respond_to? :errors
          value.errors.each do |error_key, message|
            errors[[key, error_key].join('/')] = message
          end
        end
      end

      def warnings
        map.each_with_index.each_with_object({}) do |(value, key), warnings|
          next unless value.respond_to? :all_warnings
          value.all_warnings.each do |warning_key, message|
            warnings[[key, warning_key].join('. ')] = message
          end
        end
      end

      alias_method :all_warnings, :warnings

      private

    end
  end
end
