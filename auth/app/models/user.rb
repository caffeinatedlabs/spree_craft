class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :encryptable, :encryptor => "authlogic_sha512"

  has_many :orders
  has_and_belongs_to_many :roles
  belongs_to :ship_address, :foreign_key => "ship_address_id", :class_name => "Address"
  belongs_to :bill_address, :foreign_key => "bill_address_id", :class_name => "Address"

  # before_save :check_admin
  before_validation :set_login

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :email, :password, :password_confirmation, :remember_me, :persistence_token

  scope :admin, lambda { includes(:roles).where("roles.name" => "admin") }
  scope :registered, -> { where("users.email NOT LIKE ?", "%@example.net") }

  # has_role? simply needs to return true or false whether a user has a role or not.
  def has_role?(role_in_question)
    roles.any? { |role| role.name == role_in_question.to_s }
  end

  # Creates an anonymous user.  An anonymous user is basically an auto-generated +User+ account that is created for the customer
  # behind the scenes and its completely transparently to the customer.  All +Orders+ must have a +User+ so this is necessary
  # when adding to the "cart" (which is really an order) and before the customer has a chance to provide an email or to register.
  def self.anonymous!
    token = User.generate_token(:persistence_token)
    User.create(:email => "#{token}@example.net", :password => token, :password_confirmation => token, :persistence_token => token)
  end

  def self.admin_created?
    User.admin.count > 0
  end

  def anonymous?
    email =~ /@example.net$/
  end

  def send_reset_password_instructions
    raw_token = set_reset_password_token
    UserMailer.reset_password_instructions(self.id, raw_token).deliver_now
  end

  protected
  def password_required?
    !persisted? || password.present? || password_confirmation.present?
  end

  private

  def check_admin
    return if self.class.admin_created?
    admin_role = Role.find_or_create_by(name:"admin")
    self.roles << admin_role
  end

  def set_login
    # for now force login to be same as email, eventually we will make this configurable, etc.
    self.login ||= self.email if self.email
  end

  # Generate a friendly string randomically to be used as token.
  def self.friendly_token
    SecureRandom.base64(15).tr('+/=', '-_ ').strip.delete("\n")
  end

  # Generate a token by looping and ensuring does not already exist.
  def self.generate_token(column)
    loop do
      token = friendly_token
      break token unless where(column => token).any?
    end
  end

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end

end
