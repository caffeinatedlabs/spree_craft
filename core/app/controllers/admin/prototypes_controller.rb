class Admin::PrototypesController < Admin::ResourceController
  after_action :set_habtm_associations, :only => [:create, :update]

  helper 'admin/product_properties'

  def available
    @prototypes = Prototype.order('name asc')
    respond_to do |format|
      format.html { render :layout => !request.xhr? }
      format.js
    end
  end

  def select
    @prototype ||= Prototype.find(params[:id])
    @prototype_properties = @prototype.properties

  end

  private
  
  def set_habtm_associations
    @prototype.property_ids = params[:property][:id] if params[:property]
    @prototype.option_type_ids = params[:option_type][:id] if params[:option_type]
  end
end
