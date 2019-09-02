class AppendCsp
  def initialize(app)
    @app = app
  end

  def call(env)
    res = @app.call(env)
    res[1]['Content-Security-Policy'] = "script-src 'self' unpkg.com"
    res
  end
end
