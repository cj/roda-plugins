require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

begin
  require 'tilt'
  require 'tilt/sass'
  require 'tilt/coffee'
rescue LoadError
  warn 'tilt not installed, skipping assets plugin test'
else
  describe 'assets plugin' do
    before do
      app(:bare) do
        plugin(:assets, {
          path: './spec/dummy/assets',
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

    it 'should contain proper configuration' do
      app.assets_opts[:path].should == './spec/dummy/assets'
      app.assets_opts[:css].should include('app')
    end

    it 'should serve proper assets' do
      body('/assets/css/app.css').should include('color: red')
      body('/assets/css/raw.css').should include('color: blue')
      body('/assets/js/head/app.js').should include('console.log')
    end

    it 'should contain proper assets html tags' do
      html = body '/test'
      html.should include('link')
      html.should include('script')
    end
  end
end
