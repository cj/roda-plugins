class Roda
  module RodaPlugins
    module Components
      def self.configure(app, opts={})
        app.instance_exec{@components ||= {}}
      end

      module ClassMethods
        def components
          @components.keys
        end

        def load_component name
          @components[name]
        end

        def component(name, events = [], &block)
          name = name.to_s

          @components[name] = block

          cache[:events][name] ||= {}

          events.each do |event|
            if event.is_a? String
              event_array = cache[:events][name][event] ||= []
              event_array << { component: name, call: event }
            elsif event.is_a? Hash
              for_component = event[:for].to_s
              response_to   = event[:respond_to].to_s
              call_with     = event[:with]

              event_array = cache[:events][for_component || name][response_to] ||= []
              event_array << { component: name, call: call_with || response_to }
            end
          end
        end

        def load_setup_component name
          @components["_setup_#{name}"]
        end

        def setup_component(name, &block)
          @components["_setup_#{name}"] = block
        end

        def cache
          @cache ||= begin
            c = Roda::RodaCache.new
            c[:events] = {}
            c
          end
        end
      end

      module InstanceMethods
        def component(name, opts = {})
          name = name.to_s

          component_request = ComponentRequest.new(self, self.class, name, opts)

          content = catch :halt do
            if setup_component = self.class.load_setup_component(name)
              instance_exec(component_request, &setup_component)
            end

            opts[:call] ||= 'display'

            instance_exec(component_request, &self.class.load_component(name))

            raise "Couldn't find on method `#{opts[:call]}`, for the `#{name}` component."
          end

          response.write content if content.is_a? String

          component_request.trigger_events
        end
      end

      class ComponentRequest
        attr_reader :app, :component_class, :component_name, :component_opts, :cache

        def initialize app, component_class, component_name, opts = {}
          @app             = app
          @component_class = component_class
          @component_name  = component_name
          @component_opts  = opts
          @cache           = Roda::RodaCache.new
        end

        def on name, &block
          name = name.to_s

          if name == component_opts[:call].to_s
            throw :halt, yield
          end
        end

        def display &block
          on 'display', &block
        end

        def html &block
          class_cache[:html_loaded] ||= begin
            class_cache[:html] ||= yield
            true
          end
        end

        def setup &block
          class_cache[:ran_setup] ||= begin
            block.call class_dom, class_tmpl
            true
          end
        end

        def dom
          cache[:dom] ||= class_cache[:dom].dup
        end

        def dom_html
          dom.to_html
        end

        def tmpl name
          (cache[:tmpl] ||= {}).fetch(name){ class_cache[:tmpl].fetch(name).dup }
        end

        def trigger_events
          trigger component_opts.dup.delete(:call), component_opts
        end

        def trigger event, opts = {}
          event = event.to_s

          if opts.key?(:for)
            name = opts.delete(:for).to_s
          else
            name = component_name
          end

          if events = class_cache[:events][name]
            (events[event] || []).each do |e|
              if component_opts[:call] != e[:call]
                e_opts = opts.dup.merge({call: e[:call]})
                app.component e[:component], e_opts
              end
            end
          end
        end

        private

        def class_dom
          class_cache[:dom] ||= Nokogiri::HTML(class_cache[:html])
        end

        def class_tmpl
          class_cache[:tmpl] ||= {}
        end

        def class_cache
          component_class.cache
        end
      end
    end

    register_plugin(:components, Components)
  end
end
