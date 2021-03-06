class StateChangeLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :stateful, :polymorphic => true
  before_create :assign_user

  attr_accessible :previous_state, :next_state, :name, :user_id

  def <=>(other)
    created_at <=> other.created_at
  end

  def assign_user
    # if Session.activated? && current_user_session = Session.find
    #   self.user_id ||= current_user_session.user.id
    # end
    true   # don't stop the filters
  end
end
