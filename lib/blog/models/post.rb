class Post < ActiveRecord::Base
  belongs_to :author
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true
  validates :author, presence: true

  scope :published, -> { where.not(published_at: nil) }
  scope :drafts, -> { where(published_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def published?
    published_at.present?
  end

  def publish!
    update!(published_at: Time.now)
  end

  def unpublish!
    update!(published_at: nil)
  end

  def to_h
    {
      id: id,
      author_id: author_id,
      author_name: author&.name,
      title: title,
      body: body,
      published_at: published_at,
      created_at: created_at,
      updated_at: updated_at
    }
  end
end
