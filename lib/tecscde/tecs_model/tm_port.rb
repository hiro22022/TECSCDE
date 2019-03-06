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
    class TmPort < TECSCDE::TmObject
      # @edge_side::Integer()
      # @offset::Integer(mm)  # distance from top or left side
      # @owner::TmCell | TmXPortArray  (Reverse Reference)
      # @port_def:: ::Port
      # @subscript::Integer | Nil

      attr_reader :offset

      #=== TmPort#move
      def move(x_inc, y_inc)
        modified do
          # p "move x=#{x_inc} y=#{y_inc}"
          _x, _y, w, h = owner_cell.get_geometry
          case @edge_side
          when EDGE_LEFT, EDGE_RIGHT
            offs = TECSModel.round_length_val(@offset + y_inc)
            if offs < 0 || offs > h
              return
            end
            x_inc = 0
          when EDGE_TOP, EDGE_BOTTOM
            offs = TECSCDE::TECSModel.round_length_val(@offset + x_inc)
            # p "offs=#{offs} x=#{x} w=#{w}"
            if offs < 0 || offs > w
              return
            end
            y_inc = 0
          end
          @offset = offs
          moved_edge(x_inc, x_inc, y_inc, y_inc)
        end
      end

      #=== TmPort#moved_edge
      # moved cell's edge
      # x_inc_l::Float : left edge moved,   value is incremental
      # x_inc_r::Float : right edge moved,  value is incremental
      # y_inc_t::Float : top edge moved,    value is incremental
      # y_inc_b::Float : bottom edge moved, value is incremental
      def moved_edge(x_inc_l, x_inc_r, y_inc_t, y_inc_b)
        case @edge_side
        when EDGE_TOP, EDGE_LEFT
          moved(x_inc_l, y_inc_t)
        when EDGE_BOTTOM
          moved(x_inc_l, y_inc_b)
        when EDGE_RIGHT
          moved(x_inc_r, y_inc_t)
        end
      end

      #=== tmport#get_normal_bar_of_edge
      # (1)  (6) bar from call port. this indicate A position.
      # join::TmJoin
      def get_normal_bar_of_edge(join)
        pos = get_cell.get_edge_position_in_normal_dir(@edge_side) + CPGAP * TECSModel.get_sign_of_normal(@edge_side)
        if TECSCDE::TECSModel.vertical?(@edge_side)
          TECSCDE::TECSModel::HBar.new(pos, join)
        else
          TECSCDE::TECSModel::VBar.new(pos, join)
        end
      end

      #=== TmPort#get_position_in_tangential_dir
      def get_position_in_tangential_dir
        x, y, _width, _height = get_cell.get_geometry
        TECSCDE::TECSModel.vertical?(@edge_side) ? y + @offset : x + @offset
      end

      def get_position_in_normal_dir
        get_cell.get_edge_position_in_normal_dir(@edge_side)
      end

      def get_sign_of_normal
        TECSCDE::TECSModel.get_sign_of_normal @edge_side
      end

      def get_edge_side
        @edge_side
      end

      def get_edge_side_name
        case @edge_side
        when EDGE_TOP
          :EDGE_TOP
        when EDGE_BOTTOM
          :EDGE_BOTTOM
        when EDGE_LEFT
          :EDGE_LEFT
        when EDGE_RIGHT
          :EDGE_RIGHT
        end
      end

      def get_cell
        if @owner.is_a?(TECSCDE::TECSModel::TmCell)
          @owner
        else
          @owner.owner
        end
      end

      def get_position
        x, y, w, h = get_cell.get_geometry
        case @edge_side
        when EDGE_TOP
          [x + @offset, y]
        when EDGE_BOTTOM
          [x + @offset, y + h]
        when EDGE_LEFT
          [x, y + @offset]
        when EDGE_RIGHT
          [x + w, y + @offset]
        end
      end

      def get_name
        @port_def.get_name
      end

      #=== TmPort# get_signature
      # RETURN::Signature
      def get_signature
        @port_def.get_signature
      end

      def get_subscript
        @subscript
      end

      def set_subscript(subscript)
        modified do
          @subscript = subscript
        end
      end

      #=== TmPort#array?
      def array?
        false
      end

      #=== TmPort#set_position
      def set_position(edge_side, offset)
        modified do
          @edge_side = edge_side
          @offset = TECSCDE::TECSModel.round_length_val offset
        end
      end

      #=== TmPort#delete_highlighted
      # delete_highlighted if this port is a member of unsubscripted array.
      def delete_highlighted
        return unless @owner.editable?
        return unless @owner.is_a?(TECSCDE::TECSModel::TmPortArray)
        @owner.delete_highlighted(self)
      end

      #=== TmPort#insert
      # before_after::Symbol: :before, :after
      # insert if this port is a member of unsubscripted array.
      def insert(before_after)
        return unless @owner.is_a?(TECSCDE::TECSModel::TmPortArray)
        @owner.insert(self, before_after)
      end

      #=== TmPort#editable?
      def editable?
        @owner.editable?
      end

      #=== TmPort#owner_cell
      def owner_cell
        if @owner.is_a?(TECSCDE::TECSModel::TmCell)
          @owner
        elsif @owner.is_a?(TECSCDE::TECSModel::TmPortArray)
          @owner.owner
        else
          raise "unknown cell"
        end
      end
    end
  end
end
