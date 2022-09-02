Rails.application.routes.draw do
  resource :jobs, only: [:index, :create]
  root "jobs#index"
end
