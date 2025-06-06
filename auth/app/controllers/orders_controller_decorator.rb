OrdersController.class_eval do
  before_action :check_authorization

  private

  def check_authorization
    session[:access_token] ||= params[:token]
    order = Order.find_by(number:params[:id]) || current_order

    if order
      authorize! :edit, order, session[:access_token]
    else
      authorize! :create, Order
    end
  end

end
