require 'spec_helper'
require 'nokogiri'

describe 'components plugin' do
  before do
    app(:bare) do
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

  it 'routing' do
    body.should include('bar')
    body.should_not include('foo')
    body('/bar').should include('foo')
    body('/bar').should_not include('bar')
  end

  it 'before' do
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

    body = body('/dom')
    body.should include('before')
    body.should include('after')
  end

  it 'events' do
    body('/test').should include('helloworldfoobar')
  end
end
