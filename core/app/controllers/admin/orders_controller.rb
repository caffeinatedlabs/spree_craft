class Admin::OrdersController < Admin::BaseController
  require 'spree/gateway_error'
  before_filter :initialize_txn_partials
  before_filter :initialize_order_events
  before_filter :load_order, :only => [:fire, :resend, :history, :user]

  def index
    params[:search] ||= {}
    params[:search][:completed_at_not_null] ||= '1' if Spree::Config[:show_only_complete_orders_by_default]
    @show_only_completed = params[:search][:completed_at_not_null].present?

    if !params[:search][:created_at_gt].blank?
      params[:search][:created_at_gt] = Time.zone.parse(params[:search][:created_at_gt]).beginning_of_day rescue ""
    end

    if !params[:search][:created_at_lt].blank?
      params[:search][:created_at_lt] = Time.zone.parse(params[:search][:created_at_lt]).end_of_day rescue ""
    end

    if @show_only_completed
      params[:search][:completed_at_gt] = params[:search].delete(:created_at_gt)
      params[:search][:completed_at_lt] = params[:search].delete(:created_at_lt)
    end

    @search = Order.ransack(params[:search], search_key: :search)
    @search.sorts = @show_only_completed ? 'completed_ata desc' : 'created_at desc' if @search.sorts.empty?
    @orders = @search.result.includes([:user, :shipments, :payments]).page(params[:page]).per(Spree::Config[:orders_per_page])
  end

  def show
    load_order
  end

  def new
    @order = Order.create
  end

  def edit
    load_order

  end

  def update
    return_path = nil
    load_order
    if @order.update_attributes(params[:order]) && @order.line_items.present?
      unless @order.complete?
        if params[:order].key?(:email)
          shipping_method = @order.available_shipping_methods(:front_end).first
          if shipping_method
            @order.shipping_method = shipping_method

            if params[:guest_checkout] == 'false' && params[:user_id].present?
              @order.user_id = params[:user_id]
              @order.user true
            end
            @order.save
            @order.create_shipment!
            return_path = edit_admin_order_shipment_path(@order, @order.shipment)
          else
            flash['error'] = t('errors.messages.no_shipping_methods_available')
            return_path = user_admin_order_path(@order)
          end
        else
          return_path = user_admin_order_path(@order)
        end

      else
        return_path = admin_order_path(@order)
      end
    else
      @order.errors.add(:line_items, t('errors.messages.blank'))
    end

    respond_to do |format|
      format.html do
        if return_path
          redirect_to return_path
        else
          render :action => :edit
        end
      end
    end
  end


  def fire
    # TODO - possible security check here but right now any admin can before any transition (and the state machine
    # itself will make sure transitions are not applied in the wrong state)
    event = params[:e]
    if @order.send("#{event}")
      flash.notice = t('order_updated')
    else
      flash['error'] = t('cannot_perform_operation')
    end
  rescue Spree::GatewayError => ge
    flash['error'] = "#{ge.message}"
  ensure
    respond_to { |format| format.html { redirect_to :back } }
  end

  def resend
    OrderMailer.confirm_email(@order, true).deliver
    flash.notice = t('order_email_resent')

    respond_to { |format| format.html { redirect_to :back } }
  end

  def user
    @order.build_bill_address(:country_id => Spree::Config[:default_country_id]) if @order.bill_address.nil?
    @order.build_ship_address(:country_id => Spree::Config[:default_country_id]) if @order.ship_address.nil?
  end

  private

  def load_order
    @order ||= Order.find_by_number(params[:id]) if params[:id]
    @order
  end

  # Allows extensions to add new forms of payment to provide their own display of transactions
  def initialize_txn_partials
    @txn_partials = []
  end

  # Used for extensions which need to provide their own custom event links on the order details view.
  def initialize_order_events
    @order_events = %w{cancel resume}
  end

end
