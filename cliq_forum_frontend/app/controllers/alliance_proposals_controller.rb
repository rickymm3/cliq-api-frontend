class AllianceProposalsController < ApplicationController
  def vote
    proposal_id = params[:id]
    value = params[:value] # true or false

    response = api_post("alliance_proposals/#{proposal_id}/vote", { value: value })
    
    render json: response
  end
end
