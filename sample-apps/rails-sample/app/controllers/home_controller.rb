class HomeController < ApplicationController
  def index
    if (sleep_seconds = params[:sleep].to_f) > 0
      sleep(sleep_seconds)
    end
  end
end
