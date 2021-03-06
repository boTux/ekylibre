class Backend::Cells::LastEntitiesCellsController < Backend::CellsController

  list(model: :entities, conditions: {active: true}, order: {created_at: :desc}, per_page: 5) do |t|
    t.column :full_name, url: {controller: "/backend/entities"}
    t.column :client
    t.column :prospect
    t.column :nature
    t.column :created_at
  end

  def show
  end

end
