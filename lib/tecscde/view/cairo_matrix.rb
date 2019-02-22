#
# TECSCDE - TECS Component Diagram Editor
#
# Copyright (C) 2014-2019 by TOPPERS Project
#
#  The above copyright holders grant permission gratis to use,
#  duplicate, modify, or redistribute (hereafter called use) this
#  software (including the one made by modifying this software),
#  provided that the following four conditions (1) through (4) are
#  satisfied.
#
#  (1) When this software is used in the form of source code, the above
#      copyright notice, this use conditions, and the disclaimer shown
#      below must be retained in the source code without modification.
#
#  (2) When this software is redistributed in the forms usable for the
#      development of other software, such as in library form, the above
#      copyright notice, this use conditions, and the disclaimer shown
#      below must be shown without modification in the document provided
#      with the redistributed software, such as the user manual.
#
#  (3) When this software is redistributed in the forms unusable for the
#      development of other software, such as the case when the software
#      is embedded in a piece of equipment, either of the following two
#      conditions must be satisfied:
#
#    (a) The above copyright notice, this use conditions, and the
#        disclaimer shown below must be shown without modification in
#        the document provided with the redistributed software, such as
#        the user manual.
#
#    (b) How the software is to be redistributed must be reported to the
#        TOPPERS Project according to the procedure described
#        separately.
#
#  (4) The above copyright holders and the TOPPERS Project are exempt
#      from responsibility for any type of damage directly or indirectly
#      caused from the use of this software and are indemnified by any
#      users or end users of this software from any and all causes of
#      action whatsoever.
#
#  THIS SOFTWARE IS PROVIDED "AS IS." THE ABOVE COPYRIGHT HOLDERS AND
#  THE TOPPERS PROJECT DISCLAIM ANY EXPRESS OR IMPLIED WARRANTIES,
#  INCLUDING, BUT NOT LIMITED TO, ITS APPLICABILITY TO A PARTICULAR
#  PURPOSE. IN NO EVENT SHALL THE ABOVE COPYRIGHT HOLDERS AND THE
#  TOPPERS PROJECT BE LIABLE FOR ANY TYPE OF DAMAGE DIRECTLY OR
#  INDIRECTLY CAUSED FROM THE USE OF THIS SOFTWARE.
#

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
