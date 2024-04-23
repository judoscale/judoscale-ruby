Rails.application.routes.draw do
  resource :jobs, only: [:index, :create]
  mount MissionControl::Jobs::Engine, at: "/jobs" if defined?(MissionControl)
  root "jobs#index"
end
