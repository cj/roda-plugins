require "tilt"

class Roda
  module RodaPlugins
    module Assets
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
        opts[:img_folder] ||= 'img'
        opts[:path]       ||= File.expand_path("assets", Dir.pwd)
        opts[:route]      ||= 'assets'
        opts[:css_engine] ||= 'scss'
        opts[:js_engine]  ||= 'coffee'
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
          opts[:layout_opts] = opts[:layout_opts].dup
          opts[:opts]        = opts[:opts].dup
          opts[:cache]       = thread_safe_cache if opts[:cache]
        end

        # Return the assets options for this class.
        def assets_opts
          opts[:assets]
        end
      end

      module InstanceMethods
        def assets_opts
          self.class.assets_opts
        end

        def assets type, options = {}
          attrs = options.map{|k,v| "#{k}=\"#{v}\""}

          tags = []

          assets_opts[:"#{type}"].each_with_index do |file, i|
            path = assets_opts[:route] + '/' + assets_opts[:"#{type}_folder"]
            ext = file[/(\.[a-z]{2,3})$/] ? '' : ".#{type}"
            file_path = "/#{path}/#{i}/#{file}#{ext}".gsub(/\.\.\//, '')
            if type.to_s == 'js'
              attrs.unshift "src=\"#{file_path}\""
            else
              attrs.unshift "href=\"#{file_path}\""
            end
            tags << send("#{type}_assets_tag", attrs.join(' '))
          end

          tags.join "\n"
        end

        private

        # <link rel="stylesheet" href="theme.css">
        def css_assets_tag attrs
          "<link rel=\"stylesheet\" type=\"text/css\" #{attrs}>"
        end

        # <script src="scriptfile.js"></script>
        def js_assets_tag attrs
          "<script #{attrs}></script>"
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

        def render_asset file, type, number
          asset_file = assets_opts[:"#{type}"][number.to_i]
          file       = asset_file if asset_file[file.gsub(/^#{number}\//, '')]
          path       = assets_opts[:path]
          folder     = assets_opts[:"#{type}_folder"]
          ext        = file[/(\.[a-z]{2,3})$/] ? '' : ".#{engine}"
          engine     = assets_opts[:"#{type}_engine"]
          file_path  = path + '/' + folder + '/' + file + ext

          if ext.length > 0
            tilt_class = ::Tilt[engine]

            cached_asset(file_path) do
              tilt_class.new(file_path, 1)
            end.render
          else
            File.read file_path
          end
        end

        private

        def cached_asset(path, &block)
          if cache = assets_opts[:cache]
            unless asset = cache[path]
              asset = cache[path] = yield
            end
            asset
          else
            yield
          end
        end
      end

      module RequestMethods
        def assets
          %w(css js).each do |type|
            on self.class.public_send "#{type}_assets_path" do |file|
              content_type = Rack::Mime.mime_type File.extname file

              response.headers.merge!({
                "Content-Type"              => content_type,
                "Cache-Control"             => 'public, max-age=2592000, no-transform',
                'Connection'                => 'keep-alive',
                'Age'                       => '25637',
                'Strict-Transport-Security' => 'max-age=31536000',
                'Content-Disposition'       => 'inline'
              })
              # this removes the extension
              self.class.render_asset file, type, file.split('/').first
            end
          end
        end
      end
    end

    register_plugin(:assets, Assets)
  end
end
