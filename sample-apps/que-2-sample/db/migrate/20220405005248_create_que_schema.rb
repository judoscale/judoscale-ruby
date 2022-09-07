class CreateQueSchema < ActiveRecord::Migration[7.0]
  def up
    Que.migrate!(version: 6)
  end

  def down
    Que.migrate!(version: 0)
  end
end
