class Admin::ProductPropertiesController < Admin::ResourceController
  belongs_to :product, :find_by => :permalink
  before_action :find_properties

  private

  def find_properties
    @properties = Property.all.map(&:name)
  end
end
