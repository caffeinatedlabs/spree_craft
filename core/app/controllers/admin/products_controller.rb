class Admin::ProductsController < Admin::ResourceController
  before_action :check_json_authenticity, :only => :index
  before_action :load_data, :except => :index
  update.before :update_before

  def index
    respond_to do |format|
      format.html
      format.json { render :json => json_data }
    end
  end

  # override the destory method to set deleted_at value
  # instead of actually deleting the product.
  def destroy
    @product = Product.find_by_permalink(params[:id])
    @product.deleted_at = Time.now()

    @product.variants.each do |v|
      v.deleted_at = Time.now()
      v.save
    end

    if @product.save
      flash.notice = I18n.t("notice_messages.product_deleted")
    else
      flash.notice = I18n.t("notice_messages.product_not_deleted")
    end

    respond_to do |format|
      format.html { redirect_to collection_url }
      format.js  { render_js_for_destroy }
    end
  end

  def clone
    @new = @product.duplicate

    if @new.save
      flash.notice = I18n.t("notice_messages.product_cloned")
    else
      flash.notice = I18n.t("notice_messages.product_not_cloned")
    end

    respond_to { |format| format.html { redirect_to edit_admin_product_url(@new) } }
  end

  protected

  def find_resource
    Product.find_by_permalink!(params[:id])
  end

  def location_after_save
    edit_admin_product_url(@product)
  end

  # Allow different formats of json data to suit different ajax calls
  def json_data
    json_format = params[:json_format] or 'default'
    case json_format
    when 'basic'
      collection.map {|p| {'id' => p.id, 'name' => p.name}}.to_json
    else
      collection.to_json(:include => {:variants => {:include => {:option_values => {:include => :option_type}, 
                                                    :images => {:only => [:id], :methods => :mini_url}}}, 
                                                    :images => {:only => [:id], :methods => :mini_url}, :master => {}})
    end
  end

  def load_data
    @tax_categories = TaxCategory.order(:name)
    @shipping_categories = ShippingCategory.order(:name)
  end

  def collection
    return @collection if @collection.present?

    unless request.xhr?
      params[:search] ||= {}
      # Note: the scopes are on/off switches, so we need to select "not_deleted" explicitly if the switch is off
      if params[:search][:deleted_at_null].nil?
        params[:search][:deleted_at_null] = "1"
      end

      @search = super.ransack(params[:search], search_key: :search)
      @search.sorts = 'name asc' if @search.sorts.empty?

      @collection = @search.result.group_by_products_id.includes({:variants => [:images, :option_values]}).page(params[:page]).per(Spree::Config[:admin_products_per_page])
    else
      includes = [{:variants => [:images,  {:option_values => :option_type}]}, :master, :images]

      @collection = super.where(["name #{LIKE} ?", "%#{params[:q]}%"])
      @collection = @collection.includes(includes).limit(params[:limit] || 10)

      tmp = super.where(["variants.sku #{LIKE} ?", "%#{params[:q]}%"])
      tmp = tmp.includes(:variants_including_master).limit(params[:limit] || 10)
      @collection.concat(tmp)

      @collection.uniq
    end

  end

  def update_before
    # note: we only reset the product properties if we're receiving a post from the form on that tab
    return unless params[:clear_product_properties]
    params[:product] ||= {}
  end

end
