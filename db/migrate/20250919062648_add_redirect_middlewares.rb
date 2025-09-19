class AddRedirectMiddlewares < ActiveRecord::Migration[8.0]
  def up
    execute(
      "INSERT INTO middlewares (
           route_id,
           type,
           options,
           created_at,
           updated_at
       )
       SELECT
           routes.id AS route_id,
           'Middleware::Http::RedirectScheme' AS type,
           '{\"scheme\":\"https\",\"permanent\":true}' AS options,
           TIMEZONE('utc', NOW()) AS created_at,
           TIMEZONE('utc', NOW()) AS updated_at
       FROM
           routes
       LEFT OUTER JOIN
           middlewares ON (
               middlewares.route_id = routes.id
               AND middlewares.type = 'Middleware::Http::RedirectScheme'
           )
       WHERE
           routes.type = 'Route::Http'
           AND routes.insecure = 'redirect'
           AND middlewares.id IS NULL;"
    )
  end
end
