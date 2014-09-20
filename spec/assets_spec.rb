require 'spec_helper'

require 'tilt'
require 'tilt/sass'
require 'tilt/coffee'

describe 'assets' do
  before do
    @app = Kernel.app :bare do
      plugin(:assets, {
        path: './dummy/assets',
        css_engine: 'scss',
        js_engine: 'coffee',
        headers: {
          "Cache-Control"             => 'public, max-age=2592000, no-transform',
          'Connection'                => 'keep-alive',
          'Age'                       => '25637',
          'Strict-Transport-Security' => 'max-age=31536000',
          'Content-Disposition'       => 'inline'
        }
      })

      assets_opts[:css] = ['app', '../raw.css']
      assets_opts[:js]  = { head: ['app'] }

      route do |r|
        r.assets

        r.is 'test' do
          response.write assets :css
          response.write assets [:js, :head]
        end
      end
    end
  end

  def app
    @app
  end

  it 'config' do
    assert_equal './dummy/assets', @app.assets_opts[:path]
    assert_includes @app.assets_opts[:css], 'app'
  end

  it 'middleware/render' do
    get '/test'
    p last_response.body

    get '/assets/css/app.css'
    p last_response.body

    get '/assets/css/raw.css'
    p last_response.body

    get '/assets/js/head/app.js'
    p last_response.body
  end
end
