class UserPasswordsController < Devise::PasswordsController
  include SpreeBase
  helper :users, 'spree/base'
  
  after_action :associate_user, :only => :update

  def new
    super
  end

  # Temporary Override until next Devise release (i.e after v1.3.4)
  # line:
  #   respond_with resource, :location => new_session_path(resource_name)
  # is generating bad url /session/new.user
  #
  # overridden to:
  #   respond_with resource, :location => login_path
  #
  def create
    self.resource = resource_class.send_reset_password_instructions(params[resource_name])

    if resource.errors.empty?
      set_flash_message(:notice, :send_instructions) if is_navigational_format?
      redirect_to root_url
    else
      render :new 
    end
  end

  def edit
    super
  end

  def update
    super
  end
  
  private
  
  def associate_user
    return unless current_user and current_order
    current_order.associate_user!(current_user)
    session[:guest_token] = nil
  end
  
end
