module SpreeBase
  module InstanceMethods
    def access_forbidden
      render :text => 'Access Forbidden', :layout => true, :status => 401
    end

    # can be used in views as well as controllers.
    # e.g. <% title = 'This is a custom title for this view' %>
    attr_writer :title

    def title
      title_string = @title.present? ? @title : accurate_title
      if title_string.present?
        if Spree::Config[:always_put_site_name_in_title]
          [default_title, title_string].join(' - ')
        else
          title_string
        end
      else
        default_title
      end
    end

    protected

    def default_title
      Spree::Config[:site_name]
    end

    # this is a hook for subclasses to provide title
    def accurate_title
      Spree::Config[:default_seo_title]
    end

    # def reject_unknown_object
    #   # workaround to catch problems with loading errors for permalink ids (reconsider RC permalink hack elsewhere?)
    #   begin
    #     load_object
    #   rescue Exception => e
    #     @object = nil
    #   end
    #   the_object = instance_variable_get "@#{object_name}"
    #   the_object = nil if (the_object.respond_to?(:deleted?) && the_object.deleted?)
    #   unless params[:id].blank? || the_object
    #     if self.respond_to? :object_missing
    #       self.object_missing(params[:id])
    #     else
    #       render_404(Exception.new("missing object in #{self.class.to_s}"))
    #     end
    #   end
    #   true
    # end

    def render_404(exception = nil)
      respond_to do |type|
        type.html { render :status => :not_found, :file    => "#{Rails.root}/public/404.html", :layout => nil}
        type.all  { render :status => :not_found, :nothing => true }
      end
    end

    # Convenience method for firing instrumentation events with the default payload hash
    def fire_event(name, extra_payload = {})
      ActiveSupport::Notifications.instrument(name, default_notification_payload.merge(extra_payload))
    end

    # Creates the hash that is sent as the payload for all notifications. Specific notifications will
    # add additional keys as appropriate. Override this method if you need additional data when
    # responding to a notification
    def default_notification_payload
      {:user => (respond_to?(:current_user) && current_user), :order => current_order}
    end

    private

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    def instantiate_controller_and_action_names
      @current_action = action_name
      @current_controller = controller_name
    end

    def get_taxonomies
      @taxonomies ||= Taxonomy.includes(:root => :children).joins(:root)
    end

    def current_gateway
      @current_gateway ||= Gateway.current
    end

    #RAILS 3 TODO
    # # Load all models using STI to fix associations such as @order.credits giving no results and resulting in incorrect order totals
    # def touch_sti_subclasses
    #   if Rails.env == 'development'
    #     load(File.join(SPREE_ROOT,'config/initializers/touch.rb'))
    #   end
    # end

    def set_user_language
      locale = session[:locale] || Spree::Config[:default_locale]
      locale = I18n.default_locale unless locale && I18n.available_locales.include?(locale.to_sym)
      I18n.locale = locale.to_sym
    end
  end

  def self.included(receiver)
    #receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
    receiver.send :layout, 'spree_application'
    receiver.send :helper, :hook
    receiver.send :before_action, :instantiate_controller_and_action_names
    #  #RAILS 3 TODO
    #  #before_action :touch_sti_subclasses
    receiver.send :before_action, :set_user_language

    receiver.send :helper_method, :title
    receiver.send :helper_method, :title=
    receiver.send :helper_method, :accurate_title
    receiver.send :helper_method, :get_taxonomies
    receiver.send :helper_method, :current_gateway
    receiver.send :helper_method, :current_order
    receiver.send :include, Spree::CurrentOrder
  end
end
