require "gtk2"

module TECSCDE
  module View
    #== CairoMatrix
    # this class is necessary for draw_text_v_cairo & totally shift when writing PDF
    class CairoMatrix < Cairo::Matrix
      def initialize
        @base_x = 0
        @base_y = 0
        super(1, 0, 0, 1, 0, 0)
      end

      def set(xx, yx, xy, yy, x0, y0)
        x0 += @base_x
        y0 += @base_y
        super
      end

      #=== CairoMatrix#set_rotate0
      # no rotate, then shift (x, y)
      def set_rotate0(x = 0, y = 0)
        set(1, 0, 0, 1, x, y)
        self
      end

      #=== CairoMatrix#set_rotate90
      # rotate 90 around (0, 0) then shift (x, y)
      def set_rotate90(x, y)
        set(0, -1, 1, 0, x, y)
        self
      end

      def set_base_shift(x, y)
        @base_x = x
        @base_y = y
        set_rotate0
      end
    end
  end
end
