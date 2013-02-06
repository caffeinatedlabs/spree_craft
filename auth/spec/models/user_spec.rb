require 'spec_helper'

describe User do
  before(:all) { Role.create :name => "admin" }

  it "should generate the reset password token" do
    user = FactoryGirl.build(:user)
    UserMailer.should_receive(:reset_password_instructions).with(user).and_return(double(:deliver => true))
    user.send_reset_password_instructions
    user.reset_password_token.should_not be_nil
  end

  context "#create" do
    let(:user) { FactoryGirl.build(:user) }

    it "should not be anonymous" do
      user.should_not be_anonymous
    end
  end

  context "anonymous!" do
    let(:user) { User.anonymous! }

    it "should create a new user" do
      user.new_record?.should be_false
    end

    it "should create a user with an example.net email" do
      user.email.should =~ /@example.net$/
    end

    it "should be anonymous" do
      user.should be_anonymous
    end
  end

  context "#save" do
    let(:user) { FactoryGirl.build(:user) }

    context "when there are no admin users" do
      it "should assign the user an admin role" do
        user.save
        user.has_role?("admin").should be_true
      end
    end
    context "when there are existing admin users" do
      before { FactoryGirl.create(:admin_user) }
      it "should not assign the user an admin role" do
        user.save
        user.has_role?('anonymous?').should be_false
      end
    end
  end
end
