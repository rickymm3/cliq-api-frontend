module Api
  class BaseController < ApplicationController
    include ApiAuthenticatable
  end
end
