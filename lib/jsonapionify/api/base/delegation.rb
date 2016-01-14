module JSONAPIonify::Api
  module Base::Delegation

    def self.extended(klass)
      klass.class_eval do
        class << self
          delegate :context, :response_header, :helper, :rescue_from, :error,
                   :pagination, :before, :param, :request_header, :sorting,
                   :sticky_params, :authentication, :on_exception,
                   to: :resource_class
        end
      end
    end

  end
end
