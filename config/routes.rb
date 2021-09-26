Router.config do
  get "", controller: GetController, action: :root
  post "", controller: PostController, action: :root
  get "/time", controller: GetController # TODO: remove /
end
