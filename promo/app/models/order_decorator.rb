Order.class_eval do

  def promotion_credit_exists?(promotion)
    !! adjustments.promotion.reload.detect { |credit| credit.originator.promotion.id == promotion.id }
  end

  def products
    line_items.map {|li| li.variant.product}
  end

  unless self.method_defined?("update_adjustments_with_promotion_limiting")
    def update_adjustments_with_promotion_limiting
      update_adjustments_without_promotion_limiting
      return if adjustments.promotion.eligible.none?
      most_valuable_adjustment = adjustments.promotion.eligible.max{|a,b| a.amount.abs <=> b.amount.abs}
      ( adjustments.promotion.eligible - [most_valuable_adjustment] ).each{|adjustment| adjustment.update_attribute_without_callbacks(:eligible, false)}
    end
    # Update below for Rails 5.1
    # alias_method_chain :update_adjustments, :promotion_limiting
    alias_method :update_adjustments_without_promotion_limiting, :update_adjustments
    alias_method :update_adjustments, :update_adjustments_with_promotion_limiting
  end

end
