class Gateway < PaymentMethod
  belongs_to :provider
  %w{authorize purchase capture void credit}.each do |attr|
    delegate attr, :to => :provider
    delegate "#{attr}=", :to => :provider
  end

  validates :name, :type, :presence => true

  preference :server, :string, :default => 'test'
  preference :test_mode, :boolean, :default => true

  attr_protected #none

  def payment_source_class
    Creditcard
  end

  # instantiates the selected gateway and configures with the options stored in the database
  def self.current
    super
	end

  def provider
    gateway_options = options
    gateway_options.delete :login if gateway_options.has_key?(:login) and gateway_options[:login].nil?
    ActiveMerchant::Billing::Base.gateway_mode = gateway_options[:server].to_sym
    @provider ||= provider_class.new(gateway_options)
  end

	def options
    options_hash = {}
    self.preferences.each do |key,value|
      options_hash[key.to_sym] = value
    end
    options_hash
	end

	def method_missing(method, *args)
	 	if @provider.nil? || !@provider.respond_to?(method)
			super
		else
      provider.send(method)
		end
	end

	def payment_profiles_supported?
	  false
  end

  def method_type
    "gateway"
  end

end
