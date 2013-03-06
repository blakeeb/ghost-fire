GhostFire::Application.routes.draw do
  root :to => 'welcome#index'
  match '/:id' => 'rooms#show'
  match '/gopro.html', :to => redirect('/gopro.html')
end
