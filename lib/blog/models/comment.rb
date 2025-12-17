class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :author, optional: true

  validates :body, presence: true
  validates :post, presence: true
  validates :commenter_name, presence: true, unless: :author

  def display_name
    author&.name || commenter_name
  end

  def to_h
    {
      id: id,
      post_id: post_id,
      post_title: post&.title,
      author_id: author_id,
      commenter_name: display_name,
      body: body,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
