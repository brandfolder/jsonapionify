module JSONAPIonify::Api
  module Base::Delegation

    def self.extended(klass)
      klass.class_eval do
        class << self
          delegate :context,
                   :response_header,
                   :helper,
                   :rescue_from,
                   :register_exception,
                   :error,
                   :enable_pagination,
                   :before,
                   :param,
                   :request_header,
                   :define_pagination_strategy,
                   :define_sorting_strategy,
                   :sticky_params,
                   :authentication,
                   :on_exception,
                   :example_id_generator,
                   :after,
                   :builder,
                   :types,
                   :attribute,

                   to: :resource_class
        end
      end
    end

  end
end
