# Traefik Manager Api
## Requirements
- Ruby 3.0.2
- Rails 6.1.4

## Run project
```bash
git clone git@git.zby.icdc.io:icdc/cloud/traefik-manager-api.git
cd traefik-manager-api
bundle install
rake db:create
rake db:migrate
rails s
```

## Documentation
- https://support.icdc.io/projects/networks/wiki/Traefik_Manager
- https://support.icdc.io/issues/16274

## Tips
We've a swagger documentation by route http://<host>/api-docs.
https://medium.com/@clarkjohnson_85334/adding-swagger-docs-to-a-rails-6-api-using-rswag-a3e8bc577986

