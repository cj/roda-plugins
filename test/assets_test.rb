require_relative 'helper'

require 'tilt'
require 'tilt/sass'
require 'tilt/coffee'

setup do
  app :bare do
    plugin(:assets, {
      path: './test/dummy/assets',
      css_engine: 'scss',
      js_engine: 'coffee'
    })

    assets_opts[:css] = ['app']
    assets_opts[:js]  = ['app']

    route do |r|
      r.assets

      r.is 'test' do
        response.write assets :css
        response.write assets :js
      end
    end
  end
end

scope 'assets' do
  test 'config' do |app|
    assert app.assets_opts[:path] == './test/dummy/assets'
    assert app.assets_opts[:css].include? 'app'
  end

  test 'middleware/render' do |app|
    assert body('/assets/css/app.css')['color: red']
    assert body('/assets/js/app.js')['console.log']
  end

  test 'instance_methods' do |app|
    html = body '/test'
    assert html['link']
    assert html['script']
  end
end
