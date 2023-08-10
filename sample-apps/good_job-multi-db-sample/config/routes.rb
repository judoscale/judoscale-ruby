Rails.application.routes.draw do
  resource :jobs, only: [:index, :create]
  mount GoodJob::Engine => "good_job"
  root "jobs#index"
end
