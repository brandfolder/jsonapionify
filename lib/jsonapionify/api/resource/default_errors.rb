module JSONAPIonify::Api
  module Resource::DefaultErrors
    extend ActiveSupport::Concern
    included do
      rescue_from JSONAPIonify::Structure::ValidationError, error: :jsonapi_validation_error
      rescue_from Oj::ParseError, error: :json_parse_error

      Rack::Utils::SYMBOL_TO_STATUS_CODE.each do |symbol, code|
        message = Rack::Utils::HTTP_STATUS_CODES[code]
        error symbol do
          title message
          status code.to_s
        end
      end

      error :missing_data do
        pointer ''
        title 'Missing Member'
        detail 'missing data member'
        status '422'
      end

      error :json_parse_error do
        title 'Parse Error'
        detail 'Could not parse JSON object'
        status '422'
      end

      error :invalid_field_param do |type, field|
        parameter "fields[#{type}]"
        title 'Invalid Field'
        detail "type: `#{type}`, does not have field: `#{field}`"
        status '400'
      end

      error :missing_required_attributes do |attributes|
        pointer 'data/attributes'
        title 'Missing Required Attributes'
        detail "Missing attributes: #{attributes.to_sentence}"
        status '422'
      end

      error :unpermitted_attribute do |attribute|
        pointer "data/attributes/#{attribute}"
        title 'Attribute not permitted'
        detail "Attribute not permitted: #{attribute}"
      end

      error :wrong_type do
        title 'Wrong type for request'
        status '400'
      end

      error :missing_attributes do
        title 'Missing Member'
        detail 'missing attributes member'
      end

      error :invalid_request_object do |context|
        context.errors.set context.request_object.errors.as_collection
      end

      error :invalid_resource do
        title 'Invalid Resource'
        status '404'
      end
    end
  end
end
