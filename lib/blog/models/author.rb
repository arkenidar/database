class Author < ActiveRecord::Base
  has_many :posts, dependent: :destroy
  has_many :comments

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  def to_h
    {
      id: id,
      name: name,
      email: email,
      bio: bio,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
