Rails.application.routes.draw do
  namespace :api do
    resources :quizzes, only: [:create, :show, :update] do
      member do
        post :regenerate
      end
    end
  end
end
