module JSONAPIonify::Api
  module Base::AppBuilder

    def self.extended(klass)
      klass.class_eval do
        extend JSONAPIonify::InheritedAttributes
        inherited_array_attribute :middleware
      end
    end

    def use(*args, &block)
      middleware << [args, block]
    end

    def call(env)
      app.call(env)
    end

    private

    def app
      api = self
      Rack::Builder.new do
        use Rack::ShowExceptions
        use Rack::CommonLogger
        use Base::Reloader unless ENV['RACK_ENV'] == 'production'
        map "/docs" do
          run ->(env) {
            request = JSONAPIonify::Api::Server::Request.new env
            if request.path_info.present?
              return [301, { 'location' => request.path.chomp(request.path_info) }, []]
            end
            response = Rack::Response.new
            response.write api.documentation_output(request)
            response.finish
          }
        end
        map "/" do
          use Rack::MethodOverride
          api.middleware.each do |args, block|
            use(*args, &block)
          end
          run JSONAPIonify::Api::Server.new(api)
        end
      end
    end
  end
end
