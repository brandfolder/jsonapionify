require 'spec_helper'
module JSONAPIonify
  describe 'Documentation' do
    include JSONAPIonify::Api::TestHelper
    let(:app) {
      Class.new(MyApi)
    }

    it "should compile" do
      get '/docs'
      expect(last_response.status).to eq 200
    end
  end
end
