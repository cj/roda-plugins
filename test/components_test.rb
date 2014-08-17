require_relative 'helper'
require 'nokogiri'

setup do
  app :bare do
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

scope 'components' do
  test '#routing' do
    assert body['bar']
    assert !body['foo']
    assert body('/bar')['foo']
    assert !body('/bar')['bar']
  end

  test '#before' do |app|
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
    assert body['before']
    assert body['after']
  end

  test 'events' do |app|
    assert body('/test')['helloworldfoobar']
  end
end
