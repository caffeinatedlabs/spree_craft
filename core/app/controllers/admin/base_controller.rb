class Admin::BaseController < Spree::BaseController
  before_filter :check_alerts if Rails.env.production?

  helper :search
  helper 'admin/navigation'
  layout 'admin'

  protected
  def check_alerts
    return unless current_user and should_check_alerts?

    unless session.has_key? :alerts
      begin
        session[:alerts] = Spree::Alert.current(request.host)
        filter_dismissed_alerts
        Spree::Config.set :last_check_for_spree_alerts => DateTime.now.to_s
      rescue
        session[:alerts] = nil
      end
    end
  end

  def should_check_alerts?
    return false if not Spree::Config[:check_for_spree_alerts]

    last_check = Spree::Config[:last_check_for_spree_alerts]
    return true if last_check.blank?

    DateTime.parse(last_check) < 12.hours.ago
  end

  def filter_dismissed_alerts
    return unless session[:alerts]
    dismissed = (Spree::Config[:dismissed_spree_alerts] || '').split(',')
    session[:alerts].reject! { |a| dismissed.include? a.id.to_s }
  end

  def flash_message_for(object, event_sym)
    resource_desc  = object.class.model_name.human
    resource_desc += " \"#{object.name}\"" if object.respond_to?(:name)
    I18n.t(event_sym, :resource => resource_desc)  
  end
  
  def render_js_for_destroy
    render :partial => "/admin/shared/destroy"
  end
  
  # Index request for JSON needs to pass a CSRF token in order to prevent JSON Hijacking
  def check_json_authenticity
    return unless request.format.js? or request.format.json?
    return unless protect_against_forgery?
    auth_token = params[request_forgery_protection_token]
    unless (auth_token and form_authenticity_token == URI.unescape(auth_token))
      raise(ActionController::InvalidAuthenticityToken)
    end
  end

  # def require_object_editable_by_current_user
  #   return access_denied unless object.editable_by?(current_user)
  #   true
  # end
end
