class PaymentMethod < ActiveRecord::Base
  DISPLAY =  [:both, :front_end, :back_end]
  default_scope { where(:deleted_at => nil) }

  attr_accessible :type, :name, :display_on, :active, :environment, :description

  def self.providers
    Rails.application.config.spree.payment_methods
  end

  def provider_class
    raise "You must implement provider_class method for this gateway."
  end

  # The class that will process payments for this payment type, used for @payment.source
  # e.g. Creditcard in the case of a the Gateway payment type
  # nil means the payment method doesn't require a source e.g. check
  def payment_source_class
    raise "You must implement payment_source_class method for this gateway."
  end

  def self.available(display_on='both')
    PaymentMethod.all.select { |p| p.active && (p.display_on == display_on.to_s || p.display_on.blank?) &&  (p.environment == Rails.env || p.environment.blank?) }
  end

  def self.active?
    self.where(type:self.to_s, environment:Rails.env, active:true).any?
  end

  def self.current
    PaymentMethod.where(active:true, environment:Rails.env).first
  end

  def method_type
    type.demodulize.downcase
  end

  def destroy
    self.update_attribute(:deleted_at, Time.now.utc)
  end

  def self.find_with_destroyed *args
    self.with_exclusive_scope { find(*args) }
  end

  def payment_profiles_supported?
    false
  end

  def source_required?
    true
  end

end
