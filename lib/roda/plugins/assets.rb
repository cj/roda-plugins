require "tilt"

class Roda
  module RodaPlugins
    module Assets
      def self.load_dependencies(app, opts={})
        app.plugin :render
      end

      def self.configure(app, opts={}, &block)
        if app.opts[:assets]
          app.opts[:assets].merge!(opts)
        else
          app.opts[:assets] = opts.dup
        end

        opts                = app.opts[:assets]
        opts[:css]        ||= []
        opts[:js]         ||= []
        opts[:js_folder]  ||= 'js'
        opts[:css_folder] ||= 'css'
        opts[:path]       ||= File.expand_path("assets", Dir.pwd)
        opts[:route]      ||= 'assets'
        opts[:css_engine] ||= 'scss'
        opts[:js_engine]  ||= 'coffee'
        opts[:headers]    ||= {}
        opts[:cache]        = app.thread_safe_cache if opts.fetch(:cache, true)

        yield opts if block
      end

      module ClassMethods
        # Copy the assets options into the subclass, duping
        # them as necessary to prevent changes in the subclass
        # affecting the parent class.
        def inherited(subclass)
          super
          opts               = subclass.opts[:assets] = assets_opts.dup
          opts[:opts]        = opts[:opts].dup
          opts[:cache]       = thread_safe_cache if opts[:cache]
        end

        # Return the assets options for this class.
        def assets_opts
          opts[:assets]
        end

        def cache
          assets_opts[:cache]
        end

        def cached_path file, type
          cache.fetch(:path){{}}[file] ||= begin
            path   = assets_opts[:route] + '/' + assets_opts[:"#{type}_folder"]
            ext    = file[/(\.[a-z]{2,3})$/] ? '' : ".#{type[0]}"
            folder = assets_opts[:"#{type}_folder"]

            [
              "/#{path}/#{file}#{ext}".gsub(/\.\.\//, ''),
              assets_opts[:path] + '/' + folder + '/' + file
            ]
          end
        end
      end

      module InstanceMethods
        def assets_opts
          self.class.assets_opts
        end

        def assets type, options = {}
          attrs = options.map{|k,v| "#{k}=\"#{v}\""}
          tags  = []
          type  = [type] unless type.is_a? Array
          files = type.length == 1 \
                ? assets_opts[:"#{type[0]}"] \
                : assets_opts[:"#{type[0]}"][:"#{type[1]}"]

          files.each do |file|
            file_path, file = cached_path file, type[0]
            attr            = type[0].to_s == 'js' ? 'src' : 'href'

            attrs.unshift "#{attr}=\"#{file_path}\""
            tags << send("#{type[0]}_assets_tag", attrs.join(' '))
          end

          tags.join "\n"
        end

        private

        # <link rel="stylesheet" href="theme.css">
        def css_assets_tag attrs
          "<link type=\"text/css\" #{attrs} />"
        end

        # <script src="scriptfile.js"></script>
        def js_assets_tag attrs
          "<script type=\"text/javascript\" #{attrs}></script>"
        end

        def cached_path *args
          self.class.cached_path(*args)
        end
      end

      module RequestClassMethods
        def assets_opts
          roda_class.assets_opts
        end

        %w(css js).each do |type|
          define_method "#{type}_assets_path" do
            Regexp.new(
              assets_opts[:route] + '/' + assets_opts[:"#{type}_folder"] + '/(.*)'
            )
          end
        end
      end

      module RequestMethods
        def assets
          %w(css js).each do |type|
            on self.class.public_send "#{type}_assets_path" do |file|
              file.gsub!(/\.#{type}$/, '')

              content_type = type == 'css' ? 'text/css' : 'text/javascript'

              response.headers.merge!({
                "Content-Type"              => content_type + '; charset=UTF-8',
              }.merge(scope.assets_opts[:headers]))

              file, file_path = self.class.roda_class.cached_path file, type
              engine          = scope.assets_opts[:"#{type}_engine"]

              if !file[/\.#{type}$/]
                scope.render path: "#{file_path}.#{engine}"
              else
                File.read file_path
              end
            end
          end
        end
      end
    end

    register_plugin(:assets, Assets)
  end
end
