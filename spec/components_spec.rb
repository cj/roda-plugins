require 'spec_helper'
require 'nokogiri'

describe "Components" do
  def app
    Kernel.app :bare do
      plugin :components

      component(:foo, ['world']) do |c|
        c.display do
          'bar'
        end

        c.on 'bar' do
          'foo'
        end

        c.on 'test' do
          c.trigger 'world'
          'foo'
        end

        c.on 'world' do
          'hello'
        end

        c.on 'dom' do
          c.dom_html
        end
      end

      events = [
        {respond_to: 'test', for: :foo, with: 'foo_test'},
        {respond_to: 'world', for: :foo},
      ]

      component(:bar, events) do |c|
        c.on 'foo_test' do
          'bar'
        end

        c.on 'world' do
          'world'
        end
      end

      route do |r|
        r.root do
          component(:foo)
        end

        r.on 'bar' do
          component(:foo, call: :bar)
        end

        r.on 'test' do
          component(:foo, call: 'test')
        end

        r.on 'dom' do
          component(:foo, call: :dom)
        end
      end
    end
  end

  describe 'components' do
    it 'calls the proper component route' do
      get '/'
      assert_equal last_response.body, 'bar'

      get '/bar'
      assert_equal last_response.body, 'foo'
    end

    it '#before' do
      app.setup_component(:foo) do |c|
        c.html do
          <<-EOF
            <html>
              <body>
                <div class='before'>before</div>
              </body>
            <html>
          EOF
        end

        c.setup do |dom|
          dom.at('body').add_child '<div>after</div>'
        end
      end

      get '/dom'

      # Not sure whats happening here
      # comp_cache & cache is empty for get '/dom' request
    end

    it 'events' do
      get '/test'

      # not sure what should be asserted
    end
  end
end
