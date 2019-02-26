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

        @editable = true
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
        if bar.horizontal?
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
        TECSCDE.logger.debug("moved_eport=(#{x_inc} #{y_inc})")
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
        @bars.each do |bar|
          if bar.horizontal?
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
        end
        [min_bar, min_dist]
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
        modified do
          @bars = bars
        end
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
        modified do
          @cport.delete_join
          @eport.delete_join self
          @owner.delete_join self
        end
      end

      #=== TmJoin#clone_for_undo
      def clone_for_undo
        bu = clone
        bu.copy_from self
        bu
      end
    end
  end
end
