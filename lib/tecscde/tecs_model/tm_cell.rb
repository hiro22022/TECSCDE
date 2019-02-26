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
require "tecscde/tecs_model/tm_uneditable"

module TECSCDE
  class TECSModel
    class TmCell < ::TECSCDE::TmObject
      # @x::Integer
      # @y::Integer
      # @width::Integer
      # @height::Integer
      # @name::Symbol
      # @cports::{ Symbol => CPORT }
      # @eports::{ Symbol => EPORT }
      # @n_cport::Integer
      # @n_eport::Integer
      # @celltype::  ::Celltype
      # @owner::TmRegion
      # @tecsgen_cell::Cell :  not nil if Cell from .cde/.cdl file
      # @attr_list::{Symbol(name)=>Expression}

      include TECSCDE::TECSModel::TmUneditable

      def initialize(name, celltype, x, y, region, tecsgen_cell = nil)
        TECSCDE.logger.debug("TmCell.new")
        @name = name
        @celltype = celltype
        @owner = region
        @attr_list = {}

        @x = x
        @y = y
        @width  = 25
        @height = 15

        @cports = { }
        @eports = { }
        @n_cport = 0
        @n_eport = 0

        @celltype.get_port_list.each {|port_def|
          # p "celltype:#{@celltype.get_name} port:#{port_def.get_name}"
          if port_def.get_port_type == :ENTRY
            # if ! port_def.is_reverse_required? then
            if port_def.get_array_size.nil?
              @eports[port_def.get_name] = TECSCDE::TECSModel::TmEPort.new(self, port_def)
            else
              @eports[port_def.get_name] = TECSCDE::TECSModel::TmEPortArray.new(self, port_def)
            end
            # end
          else
            if !port_def.is_require?
              if port_def.get_array_size.nil?
                @cports[port_def.get_name] = TECSCDE::TECSModel::TmCPort.new(self, port_def)
              else
                @cports[port_def.get_name] = TECSCDE::TECSModel::TmCPortArray.new(self, port_def)
              end
            end
          end
        }

        @tecsgen_cell = tecsgen_cell
        @b_editable = true
        modified {}
      end

      #=== TmCell#set_geometry
      def set_geometry(x, y, w, h)
        x_inc = x - @x
        y_inc = y - @y
        x_inc_r = x + w - (@x + @width)
        y_inc_b = y + h - (@y + @height)

        @cports.each {|name, cport|
          cport.moved_edge(x_inc, x_inc_r, y_inc, y_inc_b)
        }
        @eports.each {|name, eport|
          eport.moved_edge(x_inc, x_inc_r, y_inc, y_inc_b)
        }

        w_min, h_min = get_min_wh
        w = w_min if w < w_min
        h = h_min if h < h_min

        @x = TECSCDE::TECSModel.round_length_val x
        @y = TECSCDE::TECSModel.round_length_val y
        @width = TECSCDE::TECSModel.round_length_val w
        @height = TECSCDE::TECSModel.round_length_val h
      end

      #=== TmCell#delete ***
      def delete
        if !is_editable?
          return
        end
        modified {
          @cports.each {|name, cport|
            cport.delete
          }
          @eports.each {|name, eport|
            eport.delete
          }
          @owner.delete_cell self
        }
      end

      #=== TmCell#get_geometry ***
      def get_geometry
        [@x, @y, @width, @height]
      end

      #=== TmCell#get_name ***
      def get_name
        @name
      end

      #=== TmCell#change_name ***
      # name::Symbol : new name
      # return::Bool: true if succeed
      # if cell of new_name already exists, results false
      def change_name(name)
        if @owner.rename_cell(self, name)
          modified {
            @name = name
            return true
          }
        else
          false
        end
      end

      #=== TmCell#get_celltype ***
      def get_celltype
        @celltype
      end

      #=== TmCell#get_region
      # return::TmRegion
      def get_region
        @owner
      end

      #=== TmCell#move ***
      def move(x_inc, y_inc)
        modified {
          TECSCDE.logger.debug("cell move #{@name}")
          x0 = @x
          y0 = @y
          @x = get_model.clip_x(TECSCDE::TECSModel.round_length_val(@x + x_inc))
          @y = get_model.clip_y(TECSCDE::TECSModel.round_length_val(@y + y_inc))
          x_inc2 = @x - x0
          y_inc2 = @y - y0

          @cports.each {|name, cport|
            cport.moved(x_inc2, y_inc2)
          }
          @eports.each {|name, eport|
            eport.moved(x_inc2, y_inc2)
          }
        }
      end

      #=== TmCell::is_near?( x, y )  ***
      def is_near?(x, y)
        # p "is_near? @x=#{@x} @width=#{@width} @y=#{@y} @height=#{@height} x=#{x} y=#{y}"
        if (@x < x) && (x < (@x + @width)) && (@y < y) && (y < (@y + @height))
          true
        else
          false
        end
      end

      #=== TmCell::get_near_port ***
      def get_near_port(x, y)
        (@cports.merge @eports).each {|name, port|
          if port.is_a?(TECSCDE::TECSModel::TmPort)
            xp, yp = port.get_position
          else
            pt = port.get_near_port(x, y)
            if pt
              return pt
            end
            next
          end
          # p "get_near_port x=#{x} y=#{y} xp=#{xp} yp=#{yp}"
          if ((xp - x).abs < NEAR_DIST) && ((yp - y).abs < NEAR_DIST)
            # p "near port: found"
            return port
          end
        }
        nil
      end

      #=== TmCell#get_edge_position_in_normal_dir
      def get_edge_position_in_normal_dir(edge_side)
        case edge_side
        when  EDGE_TOP
          @y
        when  EDGE_BOTTOM
          @y + @height
        when  EDGE_LEFT
          @x
        when  EDGE_RIGHT
          @x + @width
        end
      end

      #=== TmCell#get_right_angle_edges_position
      def get_right_angle_edges_position(edge_side)
        if TECSCDE::TECSModel.is_vertical?(edge_side)
          [@y, @y + @height]
        else
          [@x, @x + @width]
         end
      end

      #=== TmCell#inc_n_cport
      # total call port count
      def inc_n_cport
        n = @n_cport
        @n_cport += 1
        n
      end

      #=== TmCell#inc_n_eport
      # total entry port count
      def inc_n_eport
        n = @n_eport
        @n_eport += 1
        n
      end

      def get_new_cport_position(port_def)
        if $b_tate
          [EDGE_BOTTOM, DIST_PORT * (inc_n_cport + 1)]
        else
          [EDGE_RIGHT, DIST_PORT * (inc_n_cport + 1)]
        end
      end

      def get_new_eport_position(port_def)
        if $b_tate
          [EDGE_TOP, DIST_PORT * (inc_n_eport + 1)]
        else
          [EDGE_LEFT, DIST_PORT * (inc_n_eport + 1)]
        end
      end

      # TmCell#adjust_port_position_to_insert
      # port::TmPort : insert after the port
      def adjust_port_position_to_insert(port)
        # p "adjust_port_position_to_insert"
        nearest_port = find_nearest_next_port port
        if nearest_port
          dist = (nearest_port.get_offset - port.get_offset)
          if dist < (DIST_PORT * 2)
            offs = (DIST_PORT * 2) - dist
            adjust_port_position_after_port port, offs
          end
        end
      end

      # TmCell#find_nearest_next_port
      # this method is part of adjust_port_position_to_insert
      def find_nearest_next_port(port)
        # p "find_nearest_next_port #{port.get_name} #{port.get_subscript}"
        edge_side = port.get_edge_side
        offs = port.get_offset
        proc_judge_near = Proc.new {|port, offs, edge_side, nearest_port|
          # p "find_nearest_next_port: comp: #{port.get_name} #{port.get_subscript} at #{port.get_offset}@#{port.get_edge_side} #{offs}@#{edge_side}"
          if port.get_edge_side == edge_side
            dist = port.get_offset - offs
            # p "dist=#{dist}"
            if dist > 0
              if nearest_port
                if (nearest_port.get_offset - offs) > dist
                  nearest_port = port
                end
              else
                nearest_port = port
              end
            end
          end
          nearest_port
        }
        nearest_port = nil
        (@eports.values + @cports.values).each {|port|
          if port.is_a?(TECSCDE::TECSModel::TmPortArray)
            port.get_ports.each {|pt|
              nearest_port = proc_judge_near.call(pt, offs, edge_side, nearest_port)
              # p "nearest=#{nearest_port}"
            }
          else
            nearest_port = proc_judge_near.call(port, offs, edge_side, nearest_port)
            # p "nearest=#{nearest_port}"
          end
        }
        # p "find_nearest=#{nearest_port}"
        nearest_port
      end

      #=== TmCell#adjust_port_position_after_port port, offs
      # this method is part of adjust_port_position_to_insert
      def adjust_port_position_after_port(port, move_offs)
        # p "adjust_port_position_after_port"
        edge_side = port.get_edge_side
        offs = port.get_offset
        proc_adjust = Proc.new {|port, offs, edge_side, move_offs|
          if port.get_edge_side == edge_side
            dist = port.get_offset - offs
            if dist > 0
              port.move(move_offs, move_offs) # move same value for x, y (only x or y applied in the method)
            end
          end
        }
        (@eports.values + @cports.values).each {|port|
          if port.is_a?(TECSCDE::TECSModel::TmPortArray)
            port.get_ports.each {|pt|
              proc_adjust.call(pt, offs, edge_side, move_offs)
            }
          else
            proc_adjust.call(port, offs, edge_side, move_offs)
          end
        }
      end

      #=== TmCell#get_cports ***
      def get_cports
        @cports
      end

      #=== TmCell#get_eports ***
      def get_eports
        @eports
      end

      #=== TmCell#get_cport_for_new_join
      def get_cport_for_new_join(cport_name, cport_subscript)
        cp = @cports[cport_name]
        if cp.nil?
          TECSCDE.logger.error("TM9999 cell #{@name} not have call port #{cport_name}")
        end

        if cport_subscript.nil?
          if !cp.is_array?
            return cp
          else
            TECSCDE.logger.error("TM9999 cell #{@name}.#{cport_name} is call port array")
            return nil
          end
        else
          if cp.is_array?
            return cp.get_port_for_new_join(cport_subscript)
          else
            TECSCDE.logger.error("TM9999 cell #{@name}.#{cport_name} is not call port array")
            return nil
          end
        end
      end

      #=== TmCell#get_eport_for_new_join
      def get_eport_for_new_join(eport_name, eport_subscript)
        ep = @eports[eport_name]
        if ep.nil?
          TECSCDE.logger.error("TM9999 cell #{@name} not have entry port #{eport_name}")
        end

        if eport_subscript.nil?
          if !ep.is_array?
            return ep
          else
            TECSCDE.logger.error("TM9999 cell #{@name}.#{eport_name} is entry port array")
            return nil
          end
        else
          if ep.is_array?
            return ep.get_port_for_new_join(eport_subscript)
          else
            TECSCDE.logger.error("TM9999 cell #{@name}.#{eport_name} is not entry port array")
            return nil
          end
        end
      end

      #=== TmCell#set_attr
      # name::Symbol
      # init::String|Nil  (from Expression)
      def set_attr(name, init)
        modified {
          if init.nil?
            @attr_list.delete name
          else
            @attr_list[name] = init
          end
        }
      end

      def get_attr_list
        @attr_list
      end

      #=== TmCell#complete?
      def complete?
        @celltype.get_attribute_list.each {|attr|
          if attr.get_initializer.nil?
            if @attr_list[attr.get_name].nil?
              return false
            end
          end
        }
        @cports.each {|name, cport|
          if !cport.complete? && !cport.is_optional?
            return false
          end
        }
        true
      end

      #=== TmCell#get_min_wh
      # minimum width & height of the cell.
      # these values are calculated from ports' offset.
      # name length is not considered.
      def get_min_wh
        h_min = 0
        w_min = 0
        (@cports.values + @eports.values).each {|port|
          if port.is_a?(TECSCDE::TECSModel::TmPortArray)
            port.get_ports.each {|pt|
              offs = pt.get_offset
              case pt.get_edge_side
              when EDGE_TOP, EDGE_BOTTOM
                w_min = offs if offs > w_min
              else
                h_min = offs if offs > h_min
              end
            }
          else
            offs = port.get_offset
            case port.get_edge_side
            when EDGE_TOP, EDGE_BOTTOM
              w_min = offs if offs > w_min
            else
              h_min = offs if offs > h_min
            end
          end
        }
        [w_min + DIST_PORT, h_min + DIST_PORT]
      end

      #=== TmCell#get_tecsgen_cell
      def get_tecsgen_cell
        @tecsgen_cell
      end

      #=== TmCell#clone_for_undo
      def clone_for_undo
        bu = clone
        bu.copy_from self
        bu
      end
    end
  end
end
