class Department < ActiveRecord::Base
  tracked(except: [:create])
  activist
end

class Category < ActiveRecord::Base
  tracked(only: [:create, :update, :destroy])
  validates_presence_of :name
end

class Note < ActiveRecord::Base
  tracked(only: [:update])
  belongs_to :category
end
