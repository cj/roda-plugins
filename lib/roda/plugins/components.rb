class Roda
  module RodaPlugins
    module Components
      def self.configure(app, opts={})
        if app.opts[:components]
          app.opts[:components].merge!(opts)
        else
          app.opts[:components] = opts.dup
        end

        opts                        = app.opts[:components]
        opts[:cache]                = app.thread_safe_cache if opts.fetch(:cache, true)
        opts[:settings]           ||= {}
        opts[:cache][:components] ||= {}
        opts[:cache][:events]     ||= {}
      end

      module ClassMethods
        def inherited(subclass)
          super
          opts.merge! subclass.opts[:components]
        end

        def components_opts
          opts[:components]
        end

        def components
          cache[:components].keys
        end

        def load_component name
          cache[:components][name]
        end

        def component(name, events = [], &block)
          name                       = name.to_s
          cache[:components][name]   = block
          cache[:events][name]     ||= {}

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
          cache[:components]["_setup_#{name}"]
        end

        def setup_component(name, &block)
          cache[:components]["_setup_#{name}"] = block
        end

        private

        def cache
          components_opts[:cache]
        end
      end

      module InstanceMethods
        def component(name, opts = {}, &block)
          name = name.to_s

          component_request = ComponentRequest.new(self, self.class, name, opts, block)

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

        def initialize app, component_class, component_name, opts = {}, block
          @app             = app
          @component_class = component_class
          @component_name  = component_name
          @component_opts  = opts
          @cache           = Roda::RodaCache.new
          @_block          = block
        end

        def on name, &block
          name = name.to_s

          if name == component_opts[:call].to_s
            throw :halt, yield(component_opts[:locals] || {})
          end
        end

        def display &block
          on 'display', &block
        end

        def html &block
          comp_cache[:html_loaded] ||= begin
            comp_cache[:html] ||= yield
            true
          end
        end

        def setup &block
          comp_cache[:ran_setup] ||= begin
            block.call comp_dom, comp_tmpl
            true
          end
        end

        def dom
          cache[:dom] ||= comp_cache[:dom].dup
        end

        def dom_html
          dom.to_html
        end

        def tmpl name
          (cache[:tmpl] ||= {}).fetch(name){ comp_tmpl.fetch(name).dup }
        end

        def set_tmpl name, value, keep = false
          comp_tmpl[name] = value
          value.remove unless keep
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

        def block
          @_block
        end

        private

        def comp_dom
          comp_cache[:dom] ||= Nokogiri::HTML(comp_cache[:html])
        end

        def comp_tmpl
          comp_cache[:tmpl] ||= {}
        end

        def class_cache
          component_class.send(:cache)
        end

        def component_cache
          class_cache["#{component_name}_cache"] ||= {}
        end
        alias :comp_cache :component_cache
      end
    end

    register_plugin(:components, Components)
  end
end
