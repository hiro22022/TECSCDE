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

require "tecscde/tm_object"

module TECSCDE
  class TECSModel
    class TmJoinBar < TECSCDE::TmObject
      # @position::Integer(mm)     # horizontal(x) or vertical(y) position
      # @owner::TmJoin (Reverse Reference)
      def initialize(position, owner_join)
        @position = position
        @owner = owner_join
        modified {}
      end

      #=== TmJoinBar#get_position ***
      def get_position
        @position
      end

      def set_position(position)
        modified {

          @position = TECSCDE::TECSModel.round_length_val position
        }
      end

      def moved(inc)
        set_position(@position + inc)
      end

      # def set_join join
      #  @owner = join
      # end

      #=== TmJoinBar#get_join ***
      def get_join
        @owner
      end

      #=== TmJoinBar#move ***
      # actually moving previous next bar
      # 1st bar and last bar can not be moved (necessary cport, eport move)
      def move(x_inc, y_inc)
        modified {

          bar_prev = nil
          bars = @owner.get_bars

          if bars.length >= 1 && bars[bars.length - 1] == self
            @owner.get_eport.move(x_inc, y_inc)
            return # last bar
          end

          bars.each{|bar|
            if bar.equal? self
              break
            end
            bar_prev = bar
          }

          if bar_prev # prev_bar is nil if self is 1st bar
            # p "bar_prev exist"
            if bar_prev.horizontal?
              xm = bar_prev.get_position + x_inc
              bar_prev.set_position(get_model.clip_x xm)
            else
              ym = bar_prev.get_position + y_inc
              bar_prev.set_position(get_model.clip_y ym)
            end
          else
            # 1st bar
            @owner.get_cport.move(x_inc, y_inc)
          end
        }
      end

      #=== TmJoinBar#clone_for_undo
      def clone_for_undo
        bu = clone
        bu.copy_from self
        bu
      end

      def horizontal?
        raise NotImplementedError
      end

      def vertical?
        raise NotImplementedError
      end

      def type
        raise NotImplementedError
      end
    end
  end
end

require "tecscde/tecs_model/hbar"
require "tecscde/tecs_model/vbar"
