require "tecscde/tm_object"
require "tecscde/tecs_model/hbar"
require "tecscde/tecs_model/vbar"

module TECSCDE
  class TECSModel
    class TmJoin < TECSCDE::TmObject
      # @cport::TmCPort
      # @eport::TmEPort
      # @bars::[TECSCDE::TECSModel::HBar|TECSCDE::TECSModel::VBar]
      # @owner::TECSModel

      include TECSCDE::TECSModel::TmUneditable

      def initialize(cport, eport, tmodel)
        @cport = cport
        @eport = eport
        @owner = tmodel

        cport.set_join self
        eport.add_join self

        create_bars
        # @bars.each{ |bar| bar.set_join self }

        @b_editable = true
        modified {}
      end

      #=== TmJoin#create_bars_to dest_port
      def create_bars
        if TECSCDE::TECSModel.is_parallel?(@cport.get_edge_side, @eport.get_edge_side)
          if TECSCDE::TECSModel.is_opposite?(@cport.get_edge_side, @eport.get_edge_side)
            create_bars_a
          else
            create_bars_e
          end
        else
          create_bars_c
        end
      end

      def create_bar(bar, position)
        if bar.instance_of?(TECSCDE::TECSModel::HBar)
          TECSCDE::TECSModel::VBar.new(position, self)
        else
          TECSCDE::TECSModel::HBar.new(position, self)
        end
      end

      #=== TmJoin#create_bars_a
      # (a) parallel opposite side generic
      def create_bars_a
        @bars = []

        @bars[0] = @cport.get_normal_bar_of_edge self

        posa = @cport.get_position_in_tangential_dir
        e1, e2 = @eport.get_cell.get_right_angle_edges_position(@cport.get_edge_side)
        # p "posa=#{posa} e1=#{e1}, e2=#{e2}"
        pos1 = ((posa - e1).abs > (posa - e2).abs) ? (e2 + Gap) : (e1 - Gap)
        @bars[1] = create_bar(@bars[0], pos1)

        pos2 = @eport.get_position_in_normal_dir + EPGap * @eport.get_sign_of_normal
        @bars[2] = create_bar(@bars[1], pos2)

        pos3 = @eport.get_position_in_tangential_dir
        @bars[3] = create_bar(@bars[2], pos3)

        pos4 = @eport.get_position_in_normal_dir
        @bars[4] = create_bar(@bars[3], pos4)
      end

      #=== TmJoin#create_bars_c
      # (c) right angle generic
      def create_bars_c
        @bars = []

        @bars[0] = @cport.get_normal_bar_of_edge self

        pos1 = @eport.get_position_in_normal_dir + EPGap * @eport.get_sign_of_normal
        @bars[1] = create_bar(@bars[0], pos1)

        pos2 = @eport.get_position_in_tangential_dir
        @bars[2] = create_bar(@bars[1], pos2)

        pos3 = @eport.get_position_in_normal_dir
        @bars[3] = create_bar(@bars[2], pos3)
      end

      #=== TmJoin#create_bars_e
      # (e) parallel same side generic
      def create_bars_e
        @bars = []

        @bars[0] = @cport.get_normal_bar_of_edge self

        posa = @cport.get_position_in_tangential_dir
        e1, e2 = @eport.get_cell.get_right_angle_edges_position(@cport.get_edge_side)
        pos1 = ((posa - e1).abs > (posa - e2).abs) ? (e2 + Gap) : (e1 - Gap)
        @bars[1] = create_bar(@bars[0], pos1)

        pos2 = @eport.get_position_in_normal_dir + EPGap * @eport.get_sign_of_normal
        @bars[2] = create_bar(@bars[1], pos2)

        pos3 = @eport.get_position_in_tangential_dir
        @bars[3] = create_bar(@bars[2], pos3)

        pos4 = @eport.get_position_in_normal_dir
        @bars[4] = create_bar(@bars[3], pos4)
      end

      #=== TmJoin#get_ports_bars ***
      def get_ports_bars
        [@cport, @eport, @bars]
      end

      def get_bars
        @bars
      end

      def get_cport
        @cport
      end

      def get_eport
        @eport
      end

      def moved_cport(x_inc, y_inc)
        if @bars[0].instance_of?(TECSCDE::TECSModel::VBar)
          @bars[0].moved y_inc
        else
          @bars[0].moved x_inc
        end
      end

      def moved_eport(x_inc, y_inc)
        dbgPrint "moved_eport=(#{x_inc} #{y_inc})\n"
        len = @bars.length

        if len >= 5
          if @bars[len - 4].instance_of?(TECSCDE::TECSModel::VBar)
            @bars[len - 4].moved y_inc
          else
            @bars[len - 4].moved x_inc
          end
        end

        if len >= 4
          if @bars[len - 3].instance_of?(TECSCDE::TECSModel::VBar)
            @bars[len - 3].moved y_inc
          else
            @bars[len - 3].moved x_inc
          end
        end

        if len >= 3
          if @bars[len - 2].instance_of?(TECSCDE::TECSModel::VBar)
            @bars[len - 2].moved y_inc
          else
            @bars[len - 2].moved x_inc
          end
        end

        if @bars[len - 1].instance_of?(TECSCDE::TECSModel::VBar)
          @bars[len - 1].moved y_inc
        else
          @bars[len - 1].moved x_inc
        end
      end

      #=== TmJoin#get_near_bar ***
      def get_near_bar(xm, ym)
        xs, ys = @cport.get_position
        xe = xs
        ye = ys
        min_dist = 999999999
        min_bar = nil
        @bars.each{|bar|
          if bar.instance_of?(TECSCDE::TECSModel::HBar)
            xe = bar.get_position
            if is_between?(xm, xs, xe) && is_near?(ym, ys)
              dist = (ym - ys).abs
              if dist < min_dist
                min_dist = dist
                min_bar = bar
              end
            end
          else # VBar
            ye = bar.get_position
            if is_between?(ym, ys, ye) && is_near?(xm, xs)
              dist = (xm - xs).abs
              if dist < min_dist
                min_dist = dist
                min_bar = bar
              end
            end
          end
          xs = xe
          ys = ye
        }
        return [min_bar, min_dist]
      end

      #=== TmJoin#is_between?
      # RETURN:: true if x is between a & b
      def is_between?(x, a, b)
        if a >= b
          if b <= x && x <= a
            true
          else
            false
          end
        else
          if a <= x && x <= b
            true
          else
            false
          end
        end
      end

      #=== TmJoin#is_near
      def is_near?(x, a)
        (x - a).abs < NEAR_DIST
      end

      #=== TmJoin#change_bars bars
      def change_bars(bars)
        modified {
          @bars = bars
        }
      end

      #=== TmJoin#get_signature ***
      def get_signature
        @cport.get_signature
      end

      #=== TmJoin#delete ***
      def delete
        if !is_editable?
          return
        end
        modified {

          @cport.delete_join
          @eport.delete_join self
          @owner.delete_join self
        }
      end

      #=== TmJoin#clone_for_undo
      def clone_for_undo
        bu = clone
        bu.copy_from self
        return bu
      end
    end
  end
end
