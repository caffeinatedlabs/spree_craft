require 'mail'

# Spree Configuration
SESSION_KEY = '_spree_session_id'

# TODO - Add the lib/plugins stuff maybe?

# Initialize preference system
ActiveRecord::Base.class_eval do
  include Spree::Preferences
  include Spree::Preferences::ModelHooks
end

if ActiveRecord::Base.connected? && MailMethod.table_exists?
  Spree::MailSettings.init
  Mail.register_interceptor(Spree::MailInterceptor)
end

LIKE = ActiveRecord::Base.connection_db_config.adapter == 'postgresql' ? 'ILIKE' : 'LIKE'
