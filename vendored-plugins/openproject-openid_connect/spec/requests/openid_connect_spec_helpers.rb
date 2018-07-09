module OpenIDConnectSpecHelpers
  def redirect_from_provider(name = 'heroku')
    # Emulate the provider's redirect with a nonsense code.
    get "/auth/#{name}/callback",
      :code => 'foobar',
      :redirect_uri => "http://localhost:3000/auth/#{name}/callack"
  end

  def click_on_signin(pro_name = 'heroku')
    # Emulate click on sign-in for that particular provider
    get "/auth/#{pro_name}"
  end
end
