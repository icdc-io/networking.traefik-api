class AddNotNullForRouteColumns < ActiveRecord::Migration[6.1]
  def change
    Route.where(insecure: nil).update_all(insecure: "")
    Route.where(tls_termination: nil).update_all(tls_termination: "")

    change_table :routes, bulk: true do |t|
      t.change_null :insecure, false
      t.change_null :tls_termination, false
    end
  end
end
