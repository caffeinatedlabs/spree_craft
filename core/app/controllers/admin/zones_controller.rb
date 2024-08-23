class Admin::ZonesController < Admin::ResourceController
  before_filter :load_data, :except => [:index]

  def new
    @zone.zone_members.build
  end

  protected

  def collection
    @search = super.ransack(params[:search])
    @search.sorts = 'name asc' if @search.sorts.empty?
    @zones = @search.result.page(params[:page]).per(Spree::Config[:orders_per_page])
  end

  def load_data
    @countries = Country.order(:name)
    @states = State.order(:name)
    @zones = Zone.order(:name)
  end
end
