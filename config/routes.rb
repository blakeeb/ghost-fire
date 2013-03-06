GhostFire::Application.routes.draw do
  get "admin/parse"

  root :to => redirect('/welcome')
  match 'home' => 'welcome#index'
  match '/:id' => 'rooms#show'
  match '/gopro.html', :to => redirect('/gopro.html')
end
