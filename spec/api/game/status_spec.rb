# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GameAPI, type: :api, module: :game do
  describe 'GET /status' do
    before do
      get '/status'
    end

    let(:data) { JSON.parse(last_response.body) }

    it { expect(last_response.status).to eq(200) }
    it { expect(data).to a_hash_including({ 'status' => 'ok' }) }
  end
end
