require 'spec_helper'

describe User do

  context "validation" do
    it { should have_valid_factory.create(:user) }
  end

end
