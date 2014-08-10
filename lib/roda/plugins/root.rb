class Roda
  module RodaPlugins
    module Root
      module RequestMethods
        def root(*args, &block)
          args << ["", true]
          is(*args, &block)
        end
      end
    end

    register_plugin(:root, Root)
  end
end
