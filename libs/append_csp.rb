class AppendCsp
  def initialize(app)
    @app = app
  end

  def call(env)
    res = @app.call(env)
    res[1]['Content-Security-Policy'] = 'default-src 'self' unpkg.com fonts.googleapis.com'
  end
end
