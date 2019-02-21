=begin

TECSCDE - TECS Component Diagram Editor

Copyright (C) 2014-2019 by TOPPERS Project

 The above copyright holders grant permission gratis to use,
 duplicate, modify, or redistribute (hereafter called use) this
 software (including the one made by modifying this software),
 provided that the following four conditions (1) through (4) are
 satisfied.

 (1) When this software is used in the form of source code, the above
     copyright notice, this use conditions, and the disclaimer shown
     below must be retained in the source code without modification.

 (2) When this software is redistributed in the forms usable for the
     development of other software, such as in library form, the above
     copyright notice, this use conditions, and the disclaimer shown
     below must be shown without modification in the document provided
     with the redistributed software, such as the user manual.

 (3) When this software is redistributed in the forms unusable for the
     development of other software, such as the case when the software
     is embedded in a piece of equipment, either of the following two
     conditions must be satisfied:

   (a) The above copyright notice, this use conditions, and the
       disclaimer shown below must be shown without modification in
       the document provided with the redistributed software, such as
       the user manual.

   (b) How the software is to be redistributed must be reported to the
       TOPPERS Project according to the procedure described
       separately.

 (4) The above copyright holders and the TOPPERS Project are exempt
     from responsibility for any type of damage directly or indirectly
     caused from the use of this software and are indemnified by any
     users or end users of this software from any and all causes of
     action whatsoever.

 THIS SOFTWARE IS PROVIDED "AS IS." THE ABOVE COPYRIGHT HOLDERS AND
 THE TOPPERS PROJECT DISCLAIM ANY EXPRESS OR IMPLIED WARRANTIES,
 INCLUDING, BUT NOT LIMITED TO, ITS APPLICABILITY TO A PARTICULAR
 PURPOSE. IN NO EVENT SHALL THE ABOVE COPYRIGHT HOLDERS AND THE
 TOPPERS PROJECT BE LIABLE FOR ANY TYPE OF DAMAGE DIRECTLY OR
 INDIRECTLY CAUSED FROM THE USE OF THIS SOFTWARE.

=end

#
# methods marked *** can be called externally.
# don't call unmarked methods other than TECSModel.
#

require "tecscde/view/constants"
require "tecscde/tm_object"
require "tecscde/change_set_control"

module TECSCDE

  def self.error(msg)
    puts(msg)
  end

  class TECSModel < TmObject
    include TECSCDE::ChangeSetControl
    include TECSCDE::View::Constants

    # edges for join (connected by Bars from TmCPort to TmEPort)
    EDGE_TOP    = 0b00
    EDGE_BOTTOM = 0b01
    EDGE_LEFT   = 0b10
    EDGE_RIGHT  = 0b11

    # gap is length between parallel bars.
    CPGap = 10  # (mm)
    EPGap = 10  # (mm)
    Gap   = 5   # (mm)
    ALIGN = 1.0 # (mm)    # grid size

    # acceptable error of position information in .cde file
    MAX_ERROR_IN_NOR = 0.5
    MAX_ERROR_IN_TAN = 2

    # minmal distance to next port (minimal interval)
    DIST_PORT = 4 # (mm)

    # Paper Size w/o margin (10 mm each side)
    PaperSpec = Struct.new(:index, :size, :key, :orientation, :name, :height, :width) do
      def cairo_paper_class
        Cairo::Paper.const_get(@name)
      end
    end
    PAPERS = {
      A4L: PaperSpec.new(0, "A4", :A4L, "LANDSCAPE", "A4_LANDSCAPE", 190, 277),
      A3L: PaperSpec.new(1, "A3", :A3L, "LANDSCAPE", "A3_LANDSCAPE", 277, 400),
      A2L: PaperSpec.new(2, "A2", :A2L, "LANDSCAPE", "A2_LANDSCAPE", 400, 574),
    }
    # name must be found in Cairo::Paper.constants

    NEAR_DIST = 2 # (mm)

    IDENTIFIER_RE = /[A-Za-z_][0-9A-Za-z_]*/

    attr_reader :paper

    # @paper::PaperSpec : See PaperSpec
    # @cell_list::[TmCell]
    # @cell_hash::{ Symbole(namespace_path) => TmCell }
    # @join_list::[TmJoin]
    # @view::TView
    # @root_region::TmRegion
    # @file_editing::String

    def initialize(tecsgen)
      @cell_list = []
      @cell_hash = {}
      @join_list = []
      @tecsgen = tecsgen
      @paper = PAPERS[:A3L]

      # __tool_info__( "tecsgen" )
      @direct_import = []
      @import_path_opt = []
      @define    = []
      @cpp       = ""
      @file_editing = "untitled"
      @owner = nil
      init_change_set

      create_root_region
    end

    #=== TECSModel#new_cell ***
    # namespace_path::String : namespace path string of celltype
    def new_cell(xm, ym, celltype_name, ct_namespace_path, tecsgen_cell = nil)
      ct_nsp = NamespacePath.analyze(ct_namespace_path)
      ct_nsp.append! celltype_name.to_sym
      ct = Namespace.find ct_nsp
      if ct.nil?
        TECSCDE.error("TM9999 celltype #{ct_nsp}: not found for cell #{@name}")
        return
      end

      if tecsgen_cell
        region = get_region_from_tecsgen_region(tecsgen_cell.get_region)
      else
        region = get_region_by_location(xm, ym)
      end
      return new_cell2(xm, ym, ct, region, tecsgen_cell)
    end

    # celltype::Celltype : in tecsgen (should be changed to TmCelltype)
    # region:TmRegion    :
    # tecsgen_cell:Cell  : in tecsgen
    def new_cell2(xm, ym, celltype, region, tecsgen_cell)
      modified {

        name = celltype.get_name.to_s.gsub(/t(.*)/, '\\1').to_sym
        if @cell_hash[name]
          count = 0
          while @cell_hash[(name.to_s + count.to_s).to_sym]
            count += 1
          end
          name = (name.to_s + count.to_s).to_sym
        end

        cell = TmCell.new(name, celltype, xm, ym, region, tecsgen_cell)
        @cell_list << cell
        @cell_hash[name] = cell

        w, h = @view.get_text_extent(name, CELL_NAME, ALIGN_CENTER, TEXT_HORIZONTAL)
        w2, h = @view.get_text_extent(celltype.get_name, CELL_NAME, ALIGN_CENTER, TEXT_HORIZONTAL)
        w += 2
        w = w2 if w2 > w
        w = 20 if w < 20
        h = 13 if h < 13
        cell.set_geometry(xm, ym, w, h)

        return cell
      }
    end

    #=== TECSModel#delete_cell
    # don't call externally, use TmCell#delete instead
    def delete_cell(cell)
      modified {

        @cell_list.delete cell
        @cell_hash.delete cell.get_name # mikan region
      }
    end

    #=== TECSModel#rename_cell
    # old_name::Symbol
    # cell:: TmCell
    # don't call externally, use TmCell#change_name instead
    def rename_cell(cell, new_name)
      modified {

        if !new_name.is_a? Symbol
          raise "cell name not Symbol"
        end
        if cell.get_name == new_name
          return true
        end

        if !(new_name =~ IDENTIFIER_RE)
          TECSCDE.message_box("'#{new_name}' has unsuitable character for identifier", nil)
          return false
        end
        if @cell_hash[new_name]
          TECSCDE.message_box("'#{new_name}' already exists", nil)
          return false
        end
        @cell_hash.delete cell.get_name
        @cell_hash[new_name] = cell
        return true
      }
    end

    #=== TECSModel#new_join ***
    def new_join(cport, eport)
      modified {

        join = TmJoin.new(cport, eport, self)
        @join_list << join
        return join
      }
    end

    #=== TECSModel#delete_join
    # don't call externally. call TmJoin#delete instead
    def delete_join(join)
      modified {

        @join_list.delete join
      }
    end

    #=== TECSModel.normal direction of edge
    # RETURN:: 1: if direction is positive, -1: negative
    def self.get_sign_of_normal(edge_side)
      ((edge_side & 0b01)) != 0 ? 1 : -1
    end

    #=== TECSModel.is_vertical?
    # RETURN:: true if vertical, false if horizontal
    def self.is_vertical?(edge_side)
      ((edge_side & 0b10) != 0) ? true : false
    end

    #=== TECSModel.is_parallel?
    # RETURN:: true if parallel, false if right anble
    def self.is_parallel?(edge_side1, edge_side2)
      # p "edge val", edge_side1, edge_side2, edge_side1 ^ edge_side2
      (edge_side1 ^ edge_side2) < 0b10
    end

    #=== TECSModel.is_opposite?
    # this function can be applicable only when edge_side1, edge_side2 are parallel
    def self.is_opposite?(edge_side1, edge_side2)
      (((edge_side1 ^ edge_side2) & 0b01) != 0) ? true : false
    end

    #=== TECSModel.round_length_val
    def self.round_length_val(val)
      round_unit = TECSModel.get_alignment
      # round_unit = 0.25
      # (val / round_unit).round * round_unit
      (val / round_unit).round * round_unit
      # val
    end

    #=== TECSModel#get_cell_list ***
    def get_cell_list
      @cell_list
    end

    #=== TECSModel#get_join_list ***
    def get_join_list
      @join_list
    end

    def get_paper
      @paper
    end

    def paper=(name)
      @paper = PAPERS[name]
    end

    #=== TECSModel#set_view ***
    def set_view(view)
      @view = view
    end

    #=== TECSModel#get_celltype_list ***
    def get_celltype_list
      if @tecsgen
        @tecsgen.get_celltype_list
      end
    end

    #=== TECSModel#get_region_from_tecsgen_region
    def get_region_from_tecsgen_region(tecsgen_region)
      nsp = tecsgen_region.get_namespace_path
      return get_region_from_namespace_path nsp
    end

    #=== TECSModel#get_region_from_namespace_path
    def get_region_from_namespace_path(nsp)
      path_array = nsp.get_path
      region = @root_region
      i = 0
      while i < path_array.length
        region = region.get_region path_array[i]
        i += 1
      end
      return region
    end

    #=== TECSModel#get_region_by_location
    def get_region_by_location(x, y)
      @root_region # mikan
    end

    #=== TECSModel#create_root_region
    def create_root_region
      nsp = NamespacePath.new("::", true)
      @root_region = TmRegion.new(nsp, self)
    end

    #=== TECSModel#get_file_editing
    # return::String : file name editing
    def get_file_editing
      @file_editing
    end

    #=== TECSModel.get_alignment
    # return::String : file name editing
    def self.get_alignment
      ALIGN
    end

    def clip_x(x)
      max = @paper.width - 2
      if x < 2
        x = 2
      elsif x > max
        x = max
      end
      return x
    end

    def clip_y(y)
      max = @paper.height - 2
      if y < 2
        y = 2
      elsif y > max
        y = max
      end
      return y
    end

    #=== TECSModel.clone_for_undo
    def clone_for_undo
      bu = clone
      bu.copy_from self
      return bu
    end

    #=== TECSModel.setup_clone
    def copy_from(model)
      model.instance_variables.each{|iv|
        val = model.instance_variable_get(iv)
        instance_variable_set(iv, val)
      }
      @cell_list = (model.instance_variable_get :@cell_list).dup
      @cell_hash = (model.instance_variable_get :@cell_hash).dup
      @join_list = (model.instance_variable_get :@join_list).dup
    end

    def get_model
      self
    end
  end
end

require "tecscde/tecs_model/tm_c_port"
require "tecscde/tecs_model/tm_c_port_array"
require "tecscde/tecs_model/tm_cell"
require "tecscde/tecs_model/tm_e_port"
require "tecscde/tecs_model/tm_e_port_array"
require "tecscde/tecs_model/tm_join"
require "tecscde/tecs_model/tm_join_bar"
require "tecscde/tecs_model/tm_port"
require "tecscde/tecs_model/tm_port_array"
require "tecscde/tecs_model/tm_region"
require "tecscde/tecs_model/tm_uneditable"
require "tecscde/tecs_model/hbar"
require "tecscde/tecs_model/vbar"

=begin

Software Design Memo

pattern of lines between cells

(a) parallel opposite side generic
(b) parallel opposite side abbreviated
(c) right angle generic
(d) right angle  abbreviated
(e) parallel same side generic
(f) parallel same side abbreviated

applying abbrviated patterns, there is conditions.

   +-------------+
   |          (f)|---------------------------1+
   |          (d)|-------------------1+       |
   |          (e)|----1+              |       |
   |          (c)|---1+|              |       |
   |          (a)|--1+||              |       |
   |          (b)|-1+|||              |       |
   |         (c)'|-+||||              |       |
   +-------------+ |||||              |       |
                   ||||+2-------------------3+|
                   |||+2---------3+   |      ||
                   ||+2---3+      |   |      ||
                   ||      | +-------------+ ||
                   ||      4 |    V   V    | 4|
                   ||      +-|>           <|-+|
                   |+2-------|>           <|-2+
                   |         |    ^        |
                   |         +-------------+
                   |              |
                   +--------------+

 edge_side
   horizontal
     EDGE_TOP    = 0b00
     EDGE_BOTTOM = 0b01
   vertical
     EDGE_LEFT   = 0b10
     EDGE_RIGHT  = 0b11


  bit0: 1 if normal direction is positive, 0 negative
  bit1: 1 if vertical, 0 if horizontal

  TECSModel class method
    get_sign_of_normal( edge_side ) = (edge_side & 0b01) ? 1 : -1
    is_vertical?( edge_side )   = (edge_side & 0b10) ? true : false
    is_parallel?( edge_side1, edge_side2 ) = ( edge_side1 ^ edge_side2 ) < 0b10
    is_opposite?( edge_side1, edge_side2 ) = ( ( edge_side1 ^ edge_side2 ) & 0b01 ) ? true : false
        this function can be applicable only when edge_side1, edge_side2 are parallel

  TmCell#get_edge_position_in_normal_dir( edge_side )
      case edge_side
      when  EDGE_TOP     y
      when  EDGE_BOTTOM  y+height
      when  EDGE_LEFT    x
      when  EDGE_RIGHT   x+width

  #=== (1)  (6) bar from call port. this indicate A position.
  TmCPort#get_normal_bar_of_edge
      pos = @cell.get_edge_position_in_normal_dir( @edge_side ) + Gap * TECSModel.get_sign_of_normal( @edge_side )
      TECSModel.is_vertical?( @edge_side ) ? HBar.new( pos ) : VBar.new( pos )

  TmCPort#tangential_position
      ( TECSModel.is_vertical? @edge_side ) ? @cell.get_y + @offs : @cell.get_x + @offs

  TmJoin#create_bars
      if TECSModel.is_parallel?( @edge_side, dest_port.get_edge_side )
          if TECSModel.is_opposite?( @edge_side, dest_port.get_edge_side )
              create_bars_a
          else
              create_bars_e
      else
          create_bars_c

  TmJoin#create_bars_a
       @bars = []

       @bars[0] = @cport.get_normal_bar_of_edge

       posa = @cport.get_position_in_tangential_dir
       e1, e2 = @eport.get_cell.get_right_angle_edges_position( @cport.get_edge_side )
       pos2 = ( posa - e1 ).abs > ( posa - e2 ).abs ? e2 : e1
       @bars[2] = (bar[1].instance_of? HBar) ? VBar.new( pos2 ) : HBar.new( pos2 )

       pos3 = @eport.get_position_in_normal_dir + Gap * @eport.get_sign_of_normal
       @bars[2] = (@bars[1].instance_of? HBar) ? VBar.new( pos3 ) : HBar.new( pos3 )

       pos4 = @eport.get_position_in_normal_dir + Gap * @eport.get_sign_of_normal
       @bars[3] = (@bars[2].instance_of? HBar) ? VBar.new( pos4 ) : HBar.new( pos4 )

       pos5 = @eport.get_position_in_tangential_dir
       @bars[4] = (@bars[3].instance_of? HBar) ? VBar.new( pos5 ) : HBar.new( pos5 )

       pos6 = @eport.get_position_in_normal_dir
       @bars[5] = (@bars[4].instance_of? HBar) ? VBar.new( pos6 ) : HBar.new( pos6 )

  TmJoin#create_bars_c
       @bars = []

       @bars[0] = @cport.get_normal_bar_of_edge

       pos1 = @eport.get_position_in_normal_dir + Gap * @eport.get_sign_of_normal
       @bars[1] = (bar[0].instance_of? HBar) ? VBar.new( pos1 ) : HBar.new( pos1 )

       pos2 = @eport.get_position_in_tangential_dir
       @bars[2] = (bar[1].instance_of? HBar) ? VBar.new( pos2 ) : HBar.new( pos2 )

       pos3 = @eport.get_position_in_normal_dir
       @bars[3] = (bar[2].instance_of? HBar) ? VBar.new( pos3 ) : HBar.new( pos3 )

  TmJoin#create_bars_e
       @bars = []

       @bars[0] = @cport.get_normal_bar_of_edge

       pos1 = @eport.get_position_in_normal_dir + Gap * @eport.get_sign_of_normal
       @bars[1] = (bar[0].instance_of? HBar) ? VBar.new( pos1 ) : HBar.new( pos1 )

       posa = @cport.get_position_in_tangential_dir
       e1, e2 = @eport.get_cell.get_right_angle_edges_position( @cport.get_edge_side )
       pos2 = ( posa - e1 ).abs > ( posa - e2 ).abs ? e2 : e1
       @bars[2] = (bar[1].instance_of? HBar) ? VBar.new( pos2 ) : HBar.new( pos2 )

       pos3 = @eport.get_position_in_normal_dir + Gap * @eport.get_sign_of_normal
       @bars[3] = (bar[2].instance_of? HBar) ? VBar.new( pos3 ) : HBar.new( pos3 )

       pos4 = @eport.get_position_in_normal_dir
       @bars[4] = (bar[3].instance_of? HBar) ? VBar.new( pos4 ) : HBar.new( pos4 )



#----- JSON schema (likely) -----#

=end
