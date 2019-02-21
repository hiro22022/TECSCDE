require "tecscde/tm_object"
require "tecscde/tm_model/hbar"
require "tecscde/tm_model/vbar"

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
            if bar_prev.instance_of?(TECSCDE::TECSModel::HBar)
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
        return bu
      end
    end
  end
end
