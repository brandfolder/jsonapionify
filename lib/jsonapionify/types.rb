require 'oj'

module JSONAPIonify::Types
  extend JSONAPIonify::Autoload
  autoload_all

  DumpError     = Class.new(StandardError)
  LoadError     = Class.new(StandardError)
  RequiredError = Class.new(StandardError)

  def types
    DefinitionFinder
  end

  module DefinitionFinder
    def self.method_missing(m, *args)
      JSONAPIonify::Types.const_get("#{m}Type", false).new(*args)
    rescue NameError
      raise TypeError, "#{m} is not a valid JSON type."
    end
  end

  class BaseType
    include JSONAPIonify::Callbacks
    define_callbacks :initialize

    def self.dumper(&block)
      define_method(:dump) do |value|
        return nil if value.nil? && !required?
        raise RequiredError if value.nil? && required?
        instance_exec(value, &block)
      end
    end

    def self.loader(&block)
      define_method(:load) do |value|
        return nil if value.nil? && !required?
        raise RequiredError if value.nil? && required?
        instance_exec(value, &block)
      end
    end

    loader do |value|
      value
    end

    dumper do |value|
      JSON.load JSON.dump value
    end

    def name
      self.class.name.split('::').last.chomp('Type')
    end

    attr_reader :options

    def initialize(**options)
      run_callbacks :initialize do
        @options = options
      end
    end

    def required!
      @required = true
      self
    end

    private

    def required?
      !!@required
    end

    def verify(non_ruby)
      dump(load(non_ruby)) == non_ruby
    end

  end
end
