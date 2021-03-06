require 'spec_helper'

describe Address do
  context "validations" do
    it { should belong_to(:country) }
    it { should belong_to(:state) }
    it { should have_many(:shipments) }
    it { should validate_presence_of(:firstname) }
    it { should validate_presence_of(:lastname) }
    it { should validate_presence_of(:address1) }
    it { should validate_presence_of(:city) }
    it { should validate_presence_of(:country) }
    it { should validate_presence_of(:phone) }
    it { should have_valid_factory(:address) }
  end

  context "factory" do
    let(:address) { FactoryGirl.create(:address) }
    specify { address.state.country.should == address.country }
  end


  context 'country usa already exists' do
    let!(:country) { FactoryGirl.create(:country,  :iso_name => 'UNITED STATES',
                                        :iso => 'US',
                                        :name => 'United States',
                                        :numcode => 840) }
    let(:address) { FactoryGirl.create(:address) }
    it 'should have country belonging to usa' do
      address.country == country
    end
  end

  context "validation" do
    let(:state) { FactoryGirl.create(:state, :name => 'maryland', :abbr => 'md') }
    before { Spree::Config.set :address_requires_state => true }

    context "state_name is not nil and country does not have any states" do
      let(:address) { FactoryGirl.create(:address, :state => nil, :state_name => 'alabama')}
      specify { address.new_record?.should be_false }
    end

    context "state_name is nil" do
      let(:address) { FactoryGirl.build(:address, :state => nil, :state_name => nil, :country => state.country)}
      before { address.save }
      specify { address.errors.full_messages.first.should == "State can't be blank" }
    end

    context "full state name is in state_name and country does contain that state" do
      let(:address) { FactoryGirl.create(:address, :state => nil, :state_name => 'maryland', :country => state.country)}
      before do
        State.delete_all
        Country.delete_all
        @state = FactoryGirl.create(:state)
        @address = FactoryGirl.create(:address, :state => nil, :state_name => @state.name, :country => @state.country)
      end
      specify do
        address.should be_valid
      end
    end

    context "state abbr is in state_name and country does contain that state" do
        before do
          State.delete_all
          Country.delete_all
          @state = FactoryGirl.create(:state)
          @address = FactoryGirl.create(:address, :state => nil, :state_name => @state.abbr, :country => @state.country)
        end
      specify do
        @address.should be_valid
      end
    end

    context "address_requires_state preference is false" do
      before { Spree::Config.set :address_requires_state => false }

      let(:address) { FactoryGirl.create(:address, :state => nil, :state_name => nil) }
      specify { address.should be_valid }
    end

  end

  context '#full_name' do
    let(:address) { FactoryGirl.create(:address, :firstname => 'Michael', :lastname => 'Jackson') }
    specify { address.full_name.should == 'Michael Jackson' }
  end

  context '#state_text' do
    context 'state is blank' do
      let(:address) { FactoryGirl.create(:address, :state => nil, :state_name => 'virginia') }
      specify { address.state_text.should == 'virginia' }
    end

    context 'both name and abbr is present' do
      let(:state) { FactoryGirl.create(:state, :name => 'virginia', :abbr => 'va') }
      let(:address) { FactoryGirl.create(:address, :state => state) }
      specify { address.state_text.should == 'va' }
    end

    context 'only name is present' do
      let(:state) { FactoryGirl.create(:state, :name => 'virginia', :abbr => nil) }
      let(:address) { FactoryGirl.create(:address, :state => state) }
      specify { address.state_text.should == 'virginia' }
    end

  end
end