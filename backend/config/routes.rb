Rails.application.routes.draw do
  namespace :api do
    resources :quizzes, only: [:create, :show] do
      member do
        post :regenerate
      end
    end
  end
end
