class Enrollment < ApplicationRecord
  belongs_to :course, counter_cache: true
  belongs_to :user, counter_cache: true

  validates :user, :course, presence: true

  validates_presence_of :rating, if: :review?
  validates_presence_of :review, if: :rating?

  validates_uniqueness_of :user_id, scope: :course_id  #user cant be subscribed to the same course twice
  validates_uniqueness_of :course_id, scope: :user_id  #user cant be subscribed to the same course twice

  validate :cant_subscribe_to_own_course  #user can't create a subscription if course.user == current_user.id

  scope :pending_review, -> { where(rating: [0, nil, ""], review: [0, nil, ""]) }
  scope :reviewed, -> { where.not(review: [0, nil, ""]) }
  
  extend FriendlyId
  friendly_id :to_s, use: :slugged

  def to_s
    user.to_s + " " + course.to_s
  end


  def self.ransackable_attributes(auth_object = nil)
    ["course_id", "created_at", "id", "price", "rating", "review", "slug", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["course", "user"]
  end

  after_save do
    unless rating.nil? || rating.zero?
      course.update_rating
    end
  end

  after_destroy do
    course.update_rating
  end

  protected
  def cant_subscribe_to_own_course
    if self.new_record?
      if self.user_id.present?
        if self.user_id == course.user_id
          errors.add(:base, "You can not subscribe to your own course")
        end
      end
    end
  end
end