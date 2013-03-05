GhostFire::Application.routes.draw do
  root :to => 'welcome#index'
  match '/:id' => 'rooms#show'
end
