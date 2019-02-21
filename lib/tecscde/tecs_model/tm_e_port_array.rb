module TECSCDE
  class TECSModel
    class TmEPortArray < TmPortArray
      def initialize(cell, port_def)
        # p "TmEPortArray port_def:#{port_def}"
        @port_def = port_def
        @owner = cell
        if port_def.get_array_size == "[]"
          @actual_size = 1
        else
          @actual_size = port_def.get_array_size
        end

        @ports = []
        (0..(@actual_size - 1)).each{|subscript|
          @ports << TmEPort.new(self, port_def, subscript)
        }
        modified {}
      end

      #=== TmEPortArray#new_port
      def new_port(subscript)
        TmEPort.new(self, @port_def, subscript)
      end
    end
  end
end
