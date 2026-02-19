require 'rails_helper'

RSpec.describe "Api::CliqAliasProposals", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/api/cliq_alias_proposals/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/api/cliq_alias_proposals/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/api/cliq_alias_proposals/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /vote" do
    it "returns http success" do
      get "/api/cliq_alias_proposals/vote"
      expect(response).to have_http_status(:success)
    end
  end

end
