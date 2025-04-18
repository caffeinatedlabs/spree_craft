require 'spec_helper'

describe Product do

  context "shoulda validations" do
    it { should belong_to(:tax_category) }
    it { should belong_to(:shipping_category) }
    it { should have_many(:product_option_types) }
    it { should have_many(:option_types) }
    it { should have_many(:product_properties) }
    it { should have_many(:properties) }
    it { should have_many(:images) }
    it { should have_and_belong_to_many(:product_groups) }
    it { should have_and_belong_to_many(:taxons) }
    it { should validate_presence_of(:price) }
    it { should validate_presence_of(:permalink) }
    it { should have_valid_factory(:product) }
  end

  context "factory_girl" do
    let(:product) { FactoryGirl.create(:product) }
    it 'should have a saved product record' do
      product.new_record?.should be_false
    end
    it 'should have zero properties record' do
      product.product_properties.size.should == 0
    end
    it 'should have a master variant' do
      product.master.should be_true
    end
  end

  context "scopes" do
    context ".master_price_lte" do
      it 'produces correct sql' do
        sql = %Q{SELECT "products".* FROM "products" INNER JOIN "variants" ON "variants"."product_id" = "products"."id" AND variants.is_master = 't' AND variants.deleted_at IS NULL WHERE (variants.price <= 10)}
        Product.master_price_lte(10).to_sql.gsub('`', '"').sub(/1\b/, "'t'").should == sql.gsub('`', '"').sub(/1\b/, "'t'")
      end
    end

    context ".master_price_gte" do
      it 'produces correct sql' do
        sql = %Q{SELECT "products".* FROM "products" INNER JOIN "variants" ON "variants"."product_id" = "products"."id" AND variants.is_master = 't' AND variants.deleted_at IS NULL WHERE (variants.price >= 10)}
        Product.master_price_gte(10).to_sql.gsub('`', '"').sub(/1\b/, "'t'").should == sql.gsub('"', '"').sub(/1\b/, "'t'")
      end
    end

    context ".group_by_products_id.count" do
      let(:product) { FactoryGirl.create(:product) }
      it 'produces a properly formed ordered-hash key' do
        expected_key = (ActiveRecord::Base.connection.adapter_name == 'PostgreSQL') ?
          Product.column_names.map{|col_name| product.send(col_name)} :
          product.id
        count_key = Product.group_by_products_id.count.keys.first
        [expected_key, count_key].each{|val| val.map!{|e| e.is_a?(Time) ? e.strftime("%Y-%m-%d %H:%M:%S") : e} if val.respond_to?(:map!)}
        count_key.should == expected_key
      end
    end

  end

  context '#add_properties_and_option_types_from_prototype' do
    let!(:prototype) { FactoryGirl.create(:prototype) }
    let(:product) { FactoryGirl.create(:product, :prototype_id => prototype.id) }
    it 'should have one property' do
      product.product_properties.size.should == 1
    end
  end

  context '#has_stock?' do
    let(:product) { FactoryGirl.create(:product) }
    context 'nothing in stock' do
      before do
        Spree::Config.set :track_inventory_levels => true
        product.master.update_attribute(:on_hand, 0)
      end
      specify { product.has_stock?.should be_false }
    end
    context 'master variant has items in stock' do
      before do
        product.master.on_hand = 100
      end
      specify { product.has_stock?.should be_true }
    end
    context 'variant has items in stock' do
      before do
        Spree::Config.set :track_inventory_levels => true
        product.master.update_attribute(:on_hand, 0)
        FactoryGirl.create(:variant, :product => product, :on_hand => 100, :is_master => false, :deleted_at => nil)
        product.reload
      end
      specify { product.has_stock?.should be_true }
    end
  end

  context '#effective_tax_rate' do
    let(:product) { FactoryGirl.create(:product) }

    it 'should check tax category for applicable rates' do
      TaxCategory.any_instance.should_receive(:effective_amount)
      product.effective_tax_rate
    end

    it 'should return default tax rate when no tax category is defined' do
      product.update_attribute(:tax_category, nil)
      product.effective_tax_rate.should == TaxRate.default
    end

  end

end
