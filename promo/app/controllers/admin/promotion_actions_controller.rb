class Admin::PromotionActionsController < Admin::BaseController
  def create
    @calculators = Promotion::Actions::CreateAdjustment.calculators
    @promotion = Promotion.find(params[:promotion_id])
    promotion_action_class = params[:promotion_action][:type]
    raise "Unexpected promotion action class: '#{promotion_action_class}'" if !promotion_action_class.starts_with?('Promotion::Actions::')
    @promotion_action = promotion_action_class.constantize.new(params[:promotion_action].to_unsafe_hash)
    @promotion_action.promotion = @promotion
    if @promotion_action.save
      flash['notice'] = I18n.t(:successfully_created, :resource => I18n.t(:promotion_action))
    end
    respond_to do |format|
      format.html { redirect_to edit_admin_promotion_path(@promotion)}
      format.js   { render :layout => false }
    end
  end

  def destroy
    @promotion = Promotion.find(params[:promotion_id])
    @promotion_action = @promotion.promotion_actions.find(params[:id])
    if @promotion_action.destroy
      flash['notice'] = I18n.t(:successfully_removed, :resource => I18n.t(:promotion_action))
    end
    respond_to do |format|
      format.html { redirect_to edit_admin_promotion_path(@promotion)}
      format.js   { render :layout => false }
    end
  end
end

