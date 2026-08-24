# frozen_string_literal: true

class Comment < ActiveRecord::Base
  enum :status, { unmoderated: 0, published: 1, rejected: 2 }

  belongs_to :user
  has_one :successor, class_name: :Comment, foreign_key: :predecessor_id
  belongs_to :predecessor, class_name: :Comment, foreign_key: :predecessor_id

  validates :body, presence: true
  validate { |c| !!c.thread_id ^ !!c.predecessor_id }

  before_create do |c|
    c.id = SecureRandom.uuid
  end

  around_destroy :around_destroy_handler
  def around_destroy_handler
    begin
      # Destroy last comment in thread
      Comment.transaction(requires_new: true) do
        yield
      end

      return
    rescue ActiveRecord::InvalidForeignKey
      # Not the last comment in thread
    end

    if predecessor
      Comment.transaction do
        # Destroy comment in the middle of thread
        successor.update!(predecessor: nil)
        yield
        successor.update!(predecessor: predecessor)
      end

      return # Unreachable on rollback
    end

    Comment.transaction do
      # Destroy first comment in thread
      successor.update!(predecessor: nil)
      yield
      successor.update!(thread_id: thread_id)
    end

    return # Unreachable on rollback
  end

  def self.thread(id)
    self.find_by(thread_id: id)&.thread || []
  end

  def thread
    comments = []
    curr = self
    
    while curr
      comments << curr
      curr = curr.successor
    end

    return comments
  end
end
