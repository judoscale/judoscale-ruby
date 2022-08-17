Rails.application.routes.draw do
  resource :jobs, only: [:index, :create]
  match "/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]
  root "jobs#index"
end
