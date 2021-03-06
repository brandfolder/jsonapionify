module JSONAPIonify::Types
  class IntegerType < BaseType

    def sample(*)
      rand(1..123)
    end

    loader do |value|
      raise LoadError, 'input value was not an integer' unless value.is_a?(Fixnum)
      value
    end

    dumper do |value|
      raise DumpError, 'cannot convert value to integer' unless value.respond_to?(:to_i)
      value.to_i.tap do |int|
        raise DumpError, 'output value was not a integer' unless int.is_a? Fixnum
      end
    end

  end
end
