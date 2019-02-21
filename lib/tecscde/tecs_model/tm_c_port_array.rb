module TECSCDE
  class TECSModel
    class TmCPortArray < TECSCDE::TECSModel::TmPortArray
      def initialize(cell, port_def)
        # p "TmCPortArray port_def:#{port_def}"
        @port_def = port_def
        @owner = cell
        if port_def.get_array_size == "[]"
          @actual_size = 1
        else
          @actual_size = port_def.get_array_size
        end

        @ports = []
        (0..(@actual_size - 1)).each{|subscript|
          # p "TmCPortArray: length=#{@ports.length}  subscript=#{subscript}"
          @ports << TmCPort.new(self, port_def, subscript)
        }
        modified {}
      end

      def get_join(subscript)
        if subscript.nil?
          return nil
        elsif 0 <= subscript && subscript < @actual_size
          return @ports[subscript]
        else
          return nil
        end
      end

      #=== TmCPortArray#complete?
      def complete?
        @ports.each{|port|
          if !port.complete?
            return false
          end
        }
        return true
      end

      #=== TmCPortArray#is_optional?
      def is_optional?
        @port_def.is_optional?
      end

      #=== TmCPortArray#new_port
      def new_port(subscript)
        TmCPort.new(self, @port_def, subscript)
      end
    end # class TmCPortArray
  end
end
