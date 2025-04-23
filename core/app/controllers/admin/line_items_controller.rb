class Admin::LineItemsController < Admin::BaseController

  before_action :load_order
  before_action :load_line_item, :only => [:destroy, :update]

  def create
    variant = Variant.find(params[:line_item][:variant_id])
    @line_item = @order.add_variant(variant, params[:line_item][:quantity].to_i)

    if @order.save
      respond_to do |format| 
        format.html { render :partial => "admin/orders/form", :locals => {:order => @order.reload}, :layout => false }
      end
    else
      respond_to do |format| 
        format.js { render :action => 'create', :locals => {:order => @order.reload}, :layout => false }
      end
    end
  end

  def destroy
    if @line_item.destroy
      respond_to do |format| 
        format.html { render :partial => "admin/orders/form", :locals => {:order => @order.reload}, :layout => false }
      end
    else
      respond_to do |format| 
        format.html { render :partial => "admin/orders/form", :locals => {:order => @order.reload}, :layout => false }
      end
    end
  end

  def new
    respond_to do |format| 
      format.html { render :action => :new, :layout => false }
    end
  end

  def update
    if @line_item.update_attributes(params[:line_item])
      respond_to do |format| 
        format.html { render :partial => "admin/orders/form", :locals => {:order => @order.reload}, :layout => false}
      end
    else
      respond_to do |format| 
        format.html { render :partial => "admin/orders/form", :locals => {:order => @order.reload}, :layout => false}
      end
    end
  end


  def load_order
    @order = Order.find_by_number! params[:order_id]
  end

  def load_line_item
    @line_item = @order.line_items.find params[:id]
  end

end
