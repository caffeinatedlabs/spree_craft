require 'spec_helper'

describe Zone do

  let(:zone) { FactoryGirl.create :zone }

  context 'factory' do
    #let(:zone){ FactoryGirl.create :zone }

    it "should set zone members correctly" do
      zone.zone_members.count.should == 1
    end
  end

  context "#destroy" do
    before { zone.destroy }
    it "should destroy all zone members" do
      zone.zone_members.count.should == 0
    end
  end

end
