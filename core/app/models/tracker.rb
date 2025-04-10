class Tracker < ActiveRecord::Base
  def self.current
    Tracker.where(active:true, environment:Rails.env).first
  end
end
