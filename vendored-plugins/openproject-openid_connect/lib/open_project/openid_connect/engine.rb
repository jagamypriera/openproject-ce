require 'open_project/openid_connect/lobby_boy_configuration'
require 'open_project/plugins'
require 'lobby_boy'

module OpenProject::OpenIDConnect
  class Engine < ::Rails::Engine
    engine_name :openproject_openid_connect

    include OpenProject::Plugins::ActsAsOpEngine
    extend OpenProject::Plugins::AuthPlugin

    register 'openproject-openid_connect',
             author_url: 'http://finn.de',
             requires_openproject: '>= 3.1.0pre1',
             settings: { 'default' => { 'providers' => {} } }

    assets %w(
      openid_connect/auth_provider-google.png
      openid_connect/auth_provider-heroku.png
    )

    register_auth_providers do
      require 'omniauth/openid_connect/providers'

      Providers = OmniAuth::OpenIDConnect::Providers

      # Use OpenSSL default certificate store instead of HTTPClient's.
      # It's outdated and it's unclear how it's managed.
      OpenIDConnect.http_config do |config|
        config.ssl_config.set_default_paths
      end

      def configuration
        from_settings = if Setting.plugin_openproject_openid_connect.is_a? Hash
          Hash(Setting.plugin_openproject_openid_connect["providers"])
        else
          {}
        end
        # Settings override configuration.yml
        Hash(OpenProject::Configuration["openid_connect"]).deep_merge(from_settings)
      end

      Providers.configure custom_options: [
        :display_name?, :icon?, :sso?, :issuer?,
        :check_session_iframe?, :end_session_endpoint?
      ]

      strategy :openid_connect do
        # update base redirect URI in case settings changed
        Providers.configure base_redirect_uri: "#{Setting.protocol}://#{Setting.host_name}"
        Providers.load(configuration).map(&:to_h)
      end
    end

    config.to_prepare do
      OpenProject::OpenIDConnect::LobbyBoyConfiguration.update!

      if LobbyBoy.configured?
        require 'open_project/hooks/session_iframes'

        require 'open_project/openid_connect/sso_login'
        ::Concerns::OmniauthLogin.prepend SSOLogin

        require 'open_project/openid_connect/sso_logout'
        ::AccountController.prepend SSOLogout
      end
    end

    initializer "openid_connect.middleware.lobby_boy_config" do |app|
      anchor =
        if defined? ::Multitenancy::Elevators::MappedDomainElevator
          ::Multitenancy::Elevators::MappedDomainElevator
        else
          ActionDispatch::Callbacks
        end

      app.config.middleware.insert_after anchor, OpenProject::OpenIDConnect::LobbyBoyConfiguration
    end

    config.to_prepare do
      # set a secure cookie in production
      secure_cookie = !!Rails.configuration.force_ssl

      # register an #after_login callback which sets a cookie containing the access token
      OpenProject::OmniAuth::Authorization.after_login do |_user, auth_hash, context|
        # check the configuration
        if store_access_token?
          # fetch the access token if it's present
          access_token = auth_hash.fetch(:credentials, {})[:token]
          # put it into a cookie
          if context && access_token
            context.send(:cookies)[:_open_project_session_access_token] = {
              value:  access_token,
              secure: secure_cookie
            }
          end
        end
      end

      # for changing the setting at runtime, e.g. for testing, we need to evaluate this each time
      def self.store_access_token?
        # TODO: we might want this to be configurable, for now we always enable it
        # OpenProject::Configuration['omniauth_store_access_token_in_cookie']
        true
      end
    end
  end
end
