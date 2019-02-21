require "tecscde/tecs_model/tm_e_port"

module TECSCDE
  class TECSModel
    class TmEPortArray < TECSCDE::TECSModel::TmPortArray
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
          @ports << TECSCDE::TECSModel::TmEPort.new(self, port_def, subscript)
        }
        modified {}
      end

      #=== TmEPortArray#new_port
      def new_port(subscript)
        TECSCDE::TECSModel::TmEPort.new(self, @port_def, subscript)
      end
    end
  end
end
