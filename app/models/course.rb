class Course < ApplicationRecord
  include ActionText::Attachable
  validates :title, :short_description, :language, :price, :level,  presence: true
  validates :description, presence: true, length: { :minimum => 5 }
  belongs_to :user, optional: true
  has_many :lessons, dependent: :destroy

  def to_s
    title
  end

  has_rich_text :description

  extend FriendlyId
  friendly_id :title, use: :slugged

  def should_generate_new_friendly_id?
    title_changed?
  end

  include PublicActivity::Model
  tracked owner: Proc.new{ |controller, model| controller.current_user }

  def self.languages
    ["English", "Russian", "Polish", "Spanish"]
  end

  def self.levels
    ["Beginner", "Intermediate", "Advanced"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "id", "language", "level", "price", "short_description", "slug", "title", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["rich_text_description", "user"]
  end
end