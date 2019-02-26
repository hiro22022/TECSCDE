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

#
# methods marked *** can be called externally.
# don't call unmarked methods other than TECSModel.
#

require "tecscde/view/constants"
require "tecscde/tm_object"
require "tecscde/change_set_control"

module TECSCDE
  class TECSModel < TmObject
    include TECSCDE::ChangeSetControl
    include TECSCDE::View::Constants

    # tool_info schema for tecscde
    TECSCDE_SCHEMA = {
      tecscde: {
        cell_list: [:cell_location],    # array
        join_list: [:join_location]     # array
      },
      __tecscde: {
        paper: :paper                   # paper
      },
      paper: {
        type: "paper",                  # fixed string (type name)
        size: :string,                  # "A4", "A3", "A2"
        orientation: :string,           # "LANDSCAPE", "PORTRAIT"
      },
      cell_location: {
        type: "cell_location",          # fixed string (type name)
        region: :string,                # "rRegion::rReg"
        name: :string,                  # "CellName"
        location: [:number],            # [ x, y, w, h ]
        port_location: [:port_location] # array
      },
      port_location: {
        type: "port_location",          # fixed string (type name)
        port_name: :string,
        edge: :string,                  # "EDGE_TOP" | "EDGE_BOTTOM" | "EDGE_LEFT" | "EDGE_RIGHT"
        offset: :number                 # real number (mm) (>=0)
      },
      __port_location: {                # port_location optional
        subscript: :integer
      },
      join_location: {
        type: "join_location",          # fixed string (type name)
        call_region: :string,           # "rRegionParent::rRegionChild",
        call_cell: :string,             # "CellName",
        call_port: :string,             # "cPort",
        entry_region: :string,          # "rERegionParent::rERegionChild",
        entry_cell: :string,            # "ECellName",
        entry_port: :string,            # "ePort",
        bar_list: [:HBar, :VBar]        # mixed (HBar&VBar) array type
      },
      __join_location: {                # join_location optional
        call_port_subscript: :integer,  # >= 0
        entry_port_subscript: :integer, # >= 0
      },
      HBar: {
        type: "HBar",                   # fixed string (type name)
        position: :number,              # real number (mm), location in X-axis
      },
      VBar: {
        type: "VBar",                   # fixed string (type name)
        position: :number,              # real number (mm), location in Y-axis
      }
    }

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
        TECSCDE.logger.error("TM9999 celltype #{ct_nsp}: not found for cell #{@name}")
        return
      end

      if tecsgen_cell
        region = get_region_from_tecsgen_region(tecsgen_cell.get_region)
      else
        region = get_region_by_location(xm, ym)
      end
      new_cell2(xm, ym, ct, region, tecsgen_cell)
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
      get_region_from_namespace_path nsp
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
      region
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
      x
    end

    def clip_y(y)
      max = @paper.height - 2
      if y < 2
        y = 2
      elsif y > max
        y = max
      end
      y
    end

    #=== TECSModel.clone_for_undo
    def clone_for_undo
      bu = clone
      bu.copy_from self
      bu
    end

    #=== TECSModel.setup_clone
    def copy_from(model)
      model.instance_variables.each {|iv|
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

    #=== TECSModel#add_cell_list_from_tecsgen
    def add_cell_list_from_tecsgen
      #----- set @file_editing -----#
      argv = TECSGEN.get_argv
      if argv.length > 0
        last_arg = argv[-1]
        if last_arg =~ /\.cde\Z/
          @file_editing = last_arg
        else
          if last_arg =~ /\.cdl\Z/
            @file_editing = last_arg.gsub(/\.cdl\Z/, ".cde")
          else
            @file_editing = last_arg + ".cde"
          end
        end
      else
        @file_editing = ""
      end

      print "file_editing: #{@file_editing}\n"

      tecsgen_cell_list = @tecsgen.get_cell_list
      tecsgen_cell_list2 = []
      x = 10
      y = 10
      # x = @paper[ :width ] - 60
      # y = @paper[ :height ] -30

      cell_list = { } # ::Cell => TmCell
      if tecsgen_cell_list
        TECSCDE.logger.info("=== create cell ===")
        tecsgen_cell_list.each {|cell|
          # p cell.get_owner.get_namespace
          # p cell.get_owner.get_namespace_path
          if @cell_hash[cell.get_name] # duplicate cell in cdl file
            next
          end
          if cell.get_celltype.nil? # celltype not found error in cdl (tecsgen)
            TECSCDE.logger.info("add_cell: celltype not found: #{cell.get_name} #{cell.get_owner.get_namespace_path}")
            next
          end

          TECSCDE.logger.info("add_cell #{cell.get_name} #{cell.get_owner.get_namespace_path} #{cell.get_locale}")
          new_cell_ = create_cell_from_tecsgen(cell, x, y)
          tecsgen_cell_list2 << cell
          cell_list[cell] = new_cell_

          new_cell_.set_editable(cell.get_locale)

          x += 55
          if x >= @paper[:width] - 30
            x = 10
            y += 30
            if y >= @paper[:height] - 15
              y = 10
            end
          end
          # x -= 55
          # if x <= 10
          #   x =   @paper[ :width ] - 60
          #   y -= 30
          #   if y <= 50
          #     y = @paper[ :height ] -30
          #   end
          # end
        }

        set_location_from_tecsgen_old
        #------ validate and set location info from __tool_info( "tecscde" ) ------#
        # begin
        if validate || $b_force_apply_tool_info
          TECSCDE.logger.info("=== set_paper ===")
          set_paper_from_tecsgen

          TECSCDE.logger.info("=== set_cell_location ===")
          set_cell_location_from_tecsgen
        else
          TECSCDE.logger.error("validate error in __tool_info__( \"tecscde\" )")
        end

        TECSCDE.logger.info("=== create join ===")
        tecsgen_cell_list2.each {|cell|
          cell.get_join_list.get_items.each {|join|
            if join.get_array_member2.nil?
              create_join_from_tecsgen(cell, join, cell_list)
            else
              join.get_array_member2.each {|j|
                if !j.nil?
                  create_join_from_tecsgen(cell, j, cell_list)
                end
              }
            end
          }
        }

        if validate || $b_force_apply_tool_info
          TECSCDE.logger.info("=== set_join_location ===")
          set_join_location_from_tecsgen
        end
      end
    end

    #=== TECSModel#create_cell_from_tecsgen
    def create_cell_from_tecsgen(cell, x, y)
      new_cell_ = new_cell(x, y, cell.get_celltype.get_name, cell.get_celltype.get_owner.get_namespace_path.to_s, cell)
      new_name = cell.get_name # automatically given name
      new_cell_.change_name(new_name)

      # decide cell box size from text width
      w, h = @view.get_text_extent(new_name, CELL_NAME, ALIGN_CENTER, TEXT_HORIZONTAL)
      w2, h = @view.get_text_extent(cell.get_celltype.get_name, CELLTYPE_NAME, ALIGN_CENTER, TEXT_HORIZONTAL)
      w = w2 if w2 > w
      w += 2
      h += 2
      w = 25 if w < 25
      h = 15 if h < 15
      new_cell_.set_geometry(x, y, w, h)
      new_cell_
    end

    #=== TECSModel#create_join_from_tecsgen
    def create_join_from_tecsgen(cell, join, cell_list)
      # p join.get_name
      object = cell.get_celltype.find join.get_name
      # p "OBJECT CLASS #{object.class}"
      if object.instance_of?(::Port)
        if object.get_port_type == :CALL
          if !object.is_require?
            lhs_cell = cell_list[cell]
            cport = lhs_cell.get_cport_for_new_join(join.get_name, join.get_subscript)
            if cport.nil?
              TECSCDE.logger.error("#{@name}.#{join.get_name} not found")
              return
            end
            rhs_cell = cell_list[join.get_cell]
            if rhs_cell.nil? # not joined in cdl (tecsgen)
              return
            end
            # eport = rhs_cell.get_eports[ join.get_port_name ]
            eport = rhs_cell.get_eport_for_new_join(join.get_port_name, join.get_rhs_subscript1)
            # p "new_join #{lhs_cell.get_name}.#{cport.get_name} => #{rhs_cell.get_name}.#{eport.get_name}"
            new_join_ = new_join cport, eport
            new_join_.set_editable(join.get_locale)
          end
        end
      else
        cell_list[cell].set_attr(join.get_name, join.get_rhs.to_CDL_str)
      end
    end

    def set_paper_from_tecsgen
      info = TOOL_INFO.get_tool_info(:tecscde)
      if info.nil? || info[:paper].nil?
        return
      end

      #----- paper -----#
      paper_info = info[:paper]
      if paper_info
        size = paper_info[:size]
        orientation = paper_info[:orientation]
        paper = nil
        PAPERS.each {|name, spec|
          if spec.size == size && spec.orientation == orientation
            TECSCDE.logger.info("paper found #{spec.name}")
            paper = spec
          end
        }
        @paper = paper if paper
      end
    end

    def set_cell_location_from_tecsgen
      info = TOOL_INFO.get_tool_info(:tecscde)
      if info.nil? || info[:cell_list].nil?
        return
      end

      #----- cell location -----#
      info[:cell_list].each {|cell_location|
        # region = cell_location[ :region ].to_sym
        name = cell_location[:name].to_sym
        loc = cell_location[:location]
        if loc.length != 4
          TECSCDE.logger.error("#{name}: cell_location.location: array length is not inconsistent, #{loc.length} for 4")
          next
        end
        cell = @cell_hash[name]
        if cell
          # p "apply location: #{cell.get_name}"
          cell.set_geometry(*loc)

          #------ port location -----#
          cell_location[:port_location].each {|port_location|
            # mikan offset not set yet
            port_name = port_location[:port_name].to_sym
            edge = get_edge_side_val(port_location[:edge])
            offset = port_location[:offset]
            subscript = port_location[:subscript]
            port = cell.get_cports[port_name]
            if port.nil?
              port = cell.get_eports[port_name]
            end
            if port.nil?
              TECSCDE.logger.info("port '#{port_name}' not found")
              next
            end
            if subscript
              if !port.is_array?
                TECSCDE.logger.info("port '#{port_name}' : 'subscript' specified but not array")
                next
              end
              if subscript < 0
                TECSCDE.logger.info("port '#{port_name}' : 'subscript' negative valude specified")
                next
              end
              p0 = port
              port = port.get_ports[subscript] # array
              if port.nil?
                TECSCDE.logger.info("port '#{port_name}' : 'subscript=#{subscript}' out of range")
                next
              end
            else
              if port.is_array?
                TECSCDE.logger.info("port '#{port_name}' : array but no 'subscript' specified")
                next
              end
            end
            port.set_position edge, offset
          }
        else
          @cell_hash.each do |a, b|
            TECSCDE.logger.info(a)
          end
          TECSCDE.logger.info("not apply location: #{name}")
          next
        end
      }
    end

    def set_join_location_from_tecsgen
      info = TOOL_INFO.get_tool_info(:tecscde)
      if info.nil?
        return
      end

      #----- join location -----#
      info[:join_list].each {|jl|
        # jl[ :call_region ]
        cp_cell_nspath = jl[:call_cell].to_sym
        cp_name = jl[:call_port].to_sym
        cp_subscript = jl[:call_port_subscript]
        # jl[ :entry_region ]
        ep_cell_nspath = jl[:entry_cell].to_sym
        ep_name = jl[:entry_port].to_sym
        ep_subscript = jl[:entry_port_subscript]

        bl = jl[:bar_list]
        bar_list = []
        bl.each {|bar|
          bar_list << [bar[:type], bar[:position]]
        }

        # cp_cell_nspath, cp_name, ep_cell_nspath, ep_name, bar_list = jl.get_location
        # p "set_location_from_tecsgen, #{cp_cell_nspath}, #{cp_name}, #{ep_cell_nspath}, #{ep_name}, #{bar_list}"
        cp_cell = @cell_hash[cp_cell_nspath]
        ep_cell = @cell_hash[ep_cell_nspath]
        # check existance of cells
        if !cp_cell.nil? && !ep_cell.nil?
          cport = cp_cell.get_cports[cp_name]
          if cport.is_a? TmCPortArray
            if cp_subscript.nil?
              TECSCDE.logger.error("TM9999 location information ignored #{cp_name} is array but not specified subscript")
              next
            end
            cport = cport.get_member cp_subscript
          else
            if !cp_subscript.nil?
              TECSCDE.logger.error("TM9999 #{cp_name} is not array but specified subscript")
            end
          end
          eport = ep_cell.get_eports[ep_name]
          if eport.is_a? TmEPortArray
            if ep_subscript.nil?
              TECSCDE.logger.error("TM9999 location information ignored #{ep_name} is array but not specified subscript")
              next
            end
            eport = eport.get_member ep_subscript
          else
            if !ep_subscript.nil?
              TECSCDE.logger.error("TM9999 #{ep_name} is not array but specified subscript")
            end
          end
          # p "1 #{cp_name} #{cp_subscript} #{ep_name} #{ep_subscript} #{cport} #{eport}"

          # check existance of cport & eport and direction of bar & edge (must be in right angle)
          # mikan necessary more than 2 bars
          if !cport.nil? && !eport.nil? && eport.include?(cport.get_join(cp_subscript)) && bar_list.length >= 2
            # p "2"
            b_vertical = TECSModel.is_vertical?(cport.get_edge_side)
            bar_type = bar_list[0][0].to_sym
            if (b_vertical && bar_type == :HBar) || (!b_vertical && bar_type == :VBar)
              # p "3"
              len = bar_list.length

              normal_pos = bar_list[len - 1][1]
              tan_pos = bar_list[len - 2][1]
              # p "normal_pos=#{normal_pos}, eport_normal=#{eport.get_position_in_normal_dir}"
              # p "tan_pos=#{tan_pos}, eport_tan=#{eport.get_position_in_tangential_dir}"
              # check if normal_pos & tan_pos can be evaluated and the position of bars goal
              if !normal_pos.nil? && !tan_pos.nil? &&
                  ((normal_pos - eport.get_position_in_normal_dir).abs <= MAX_ERROR_IN_NOR) &&
                  ((tan_pos - eport.get_position_in_tangential_dir).abs <= MAX_ERROR_IN_TAN)
                # p "4"
                bars = []
                bar_list.each {|bar_info|
                  # bar_list: array of [ IDENTIFER, position ] => bars ( array of HBar or VBar )
                  pos = bar_info[1]
                  if !pos.nil? && bar_info[0].to_sym == :HBar
                    bar = HBar.new(pos, cport.get_join)
                    bars << bar
                  elsif !pos.nil? && bar_info[0].to_sym == :VBar
                    bar = VBar.new(pos, cport.get_join)
                    bars << bar
                  else
                    bars = []
                    break
                  end
                }
                # mikan length more than 2
                len = bars.length
                if len >= 0.1
                  bars[len - 1].set_position eport.get_position_in_normal_dir
                  bars[len - 2].set_position eport.get_position_in_tangential_dir
                  # p "bar changed for #{cp_cell_nspath}.#{cport.get_name}"
                  cport.get_join.change_bars bars
                end
              end
            end
          end
        end
      }
    end

    #=== TECSModel#validate
    # validate JSON format data in __tool_info__( "tecscde" )
    def validate
      validator = TOOL_INFO::VALIDATOR.new(:tecscde, TECSCDE_SCHEMA)
      validator.validate
    end

    #=== save data ***
    def save(filename)
      begin
        Dir.chdir($run_dir) do
          File.open(filename, "w") do |file|
            save_tecsgen(file)
            save_cells(file)
            save_info(file)
          end
        end
      rescue => evar
        TECSCDE.message_box("fail to save #{filename}\n#{evar}", :OK)
      end
    end

    #=== TECSModel#save_tecsgen
    # output __tool_info__ ("tecsgen")
    def save_tecsgen(f)
      f.print "__tool_info__ (\"tecsgen\") {\n"

      f.print "    \"tecscde_version\"     : \"#{$tecscde_version}\",\n"
      f.print "    \"cde_format_version\"  : \"#{$cde_format_version}\",\n"
      f.print "    \"save_date\"           : \"#{DateTime.now}\",\n"

      f.print "    \"base_dir\" : [\n"
      delim = "        "
      $base_dir.each {|bd, b_necessity|
        if b_necessity
          f.print "#{delim}\"#{bd}\""
          delim = ",\n        "
        end
      }
      f.print "\n    ],\n"

      f.print "    \"define_macro\" : [\n"
      delim = ""
      $define.each {|define|
        f.print "#{delim}        \"#{define}\""
        delim = ",\n"
      }
      f.print "\n    ],\n"

      f.print "   \"import_path\" : [\n"
      delim = ""
      $import_path.each {|path|
        tecspath = $tecspath.gsub(/\\/, '\\\\\\\\')
        # p tecspath
        # p path, Regexp.new( "^A#{tecspath}" ), path =~ Regexp.new( "\\A#{tecspath}" )
        next if path =~ Regexp.new("\\A#{tecspath}")
        f.print "#{delim}        \"#{path}\""
        delim = ",\n"
      }
      f.print "\n    ],\n"

      f.print "    \"direct_import\" : [\n"
      delim = ""
      Import.get_list.each {|path, import|
        if (import.is_imported? == false) && (import.get_cdl_name != @file_editing)
          f.print "#{delim}        \"#{import.get_cdl_name}\""
          delim = ",\n"
        end
      }
      f.print "\n    ]"

      # optionaly set
      if $b_cpp_specified
        f.print ",\n    \"cpp\"    : \"#{$cpp}\"\n"
      else
        f.print "\n"
      end

      f.print "}\n\n"
    end

    #=== TECSModel#save_cells
    # output cell definition
    def save_cells(f)
      @cell_list.each {|cell| # mikan region
        if !cell.is_editable?
          next
        end

        f.print("cell #{cell.get_celltype.get_namespace_path} #{cell.get_name} {\n")

        if cell.get_cports.length > 0
          f.print "\n    /*** call ports ***/\n"
        end
        cell.get_cports.each {|name, cport|
          if cport.is_array?
            cport.get_ports.each {|cport|
              join = cport.get_join
              if join
                eport = join.get_eport
                if eport.get_subscript
                  subscript = "[ #{eport.get_subscript} ]"
                else
                  subscript = ""
                end
                f.print "    #{cport.get_name}[ #{cport.get_subscript} ] = #{eport.get_cell.get_name}.#{eport.get_name}#{subscript};\n"
              end
            }
          else
            join = cport.get_join
            if join
              eport = join.get_eport
              if eport.get_subscript
                subscript = "[ #{eport.get_subscript} ]"
              else
                subscript = ""
              end
              f.print "    #{cport.get_name} = #{eport.get_cell.get_name}.#{eport.get_name}#{subscript};\n"
            end
          end
        }

        attr_list = cell.get_attr_list
        if attr_list.length > 0
          f.print "\n    /*** attributes ***/\n"
        end
        attr_list.keys.sort.each {|attr|
          f.print "    #{attr} = #{attr_list[attr]};\n"
        }

        f.print("};\n")
      }
    end

    #=== TECSModel#save_info
    # output location information
    def save_info(f)
      f.print "\n"
      f.print "/*************************************************\n"
      f.print " *         TOOL INFORMATION FOR TECSCDE          *\n"
      f.print " *     This  information is used by tecscde      *\n"
      f.print " *  please don't touch if you are not familiar   *\n"
      f.print " ************************************************/\n"
      f.print "__tool_info__ (\"tecscde\") {\n"

      save_paper_info f
      save_cell_info f
      save_join_info f

      f.print "}\n"
    end

    #=== TECSModel#save_cell_info
    # output cell location information
    def save_paper_info(f)
      f.print <<PAPER_INFO
    "paper" : {
       "type" : "paper",
       "size" :  "#{@paper[:size]}",
       "orientation" :  "#{@paper[:orientation]}"
    },
PAPER_INFO
    end

    #=== TECSModel#save_cell_info
    # output cell location information
    def save_cell_info(f)
      f.print "    \"cell_list\" : [\n"
      delim_1 = ""
      index = 0
      @cell_list.each {|cell|
        x, y, w, h = cell.get_geometry
        f.print <<CELL_INFO
#{delim_1}        {       /** cell_list[ #{index} ] **/
            "type"     : "cell_location",
            "name"     : "#{cell.get_name}",
            "location" : [ #{x}, #{y}, #{w}, #{h} ],
            "region"   : "#{cell.get_region.get_namespace_path}",
            "port_location" : [
CELL_INFO
        delim_2 = ""
        (cell.get_cports.merge cell.get_eports).each {|name, cport|
          if cport.is_array?
            cport.get_ports.each {|cp|
              f.print <<PORT_INFO
#{delim_2}                {
                    "type"      : "port_location",
                    "port_name" : "#{cp.get_name}",
                    "subscript" : #{cp.get_subscript},
                    "edge"      : "#{cp.get_edge_side_name}",
                    "offset"    : #{cp.get_offset}
PORT_INFO
              f.print "                }"
              delim_2 = ",\n"
            }
          else
            f.print <<PORT_INFO
#{delim_2}                {
                    "type"      : "port_location",
                    "port_name" : "#{cport.get_name}",
                    "edge"      : "#{cport.get_edge_side_name}",
                    "offset"    : #{cport.get_offset}
PORT_INFO
            f.print "                }"
          end
          delim_2 = ",\n"
        }
        f.print "\n            ]\n        }"
        index += 1
        delim_1 = ",\n"
      }
      f.print "\n    ],\n"
    end

    #=== TECSModel#save_join_info
    # output join location information
    def save_join_info(f)
      f.print "    \"join_list\" : [\n"
      delim_1 = ""
      index = 0
      @join_list.each {|join|
        cport, eport, bars = join.get_ports_bars
        if cport.get_subscript
          cp_subsc = "            \"call_port_subscript\" : #{cport.get_subscript},\n"
        else
          cp_subsc = ""
        end
        if eport.get_subscript
          ep_subsc = "            \"entry_port_subscript\" : #{eport.get_subscript},\n"
        else
          ep_subsc = ""
        end
        # :call_region :
        # :entry_region :

        f.print <<JOIN_INFO
#{delim_1}        {       /** join_list[ #{index} ] **/
            "type"        : "join_location",
            "call_cell"   : "#{cport.get_cell.get_name}",
            "call_region" : "#{cport.get_cell.get_region.get_namespace_path}",
            "call_port"   : "#{cport.get_name}",
#{cp_subsc}            "entry_cell"  : "#{eport.get_cell.get_name}",
            "entry_region": "#{eport.get_cell.get_region.get_namespace_path}",
            "entry_port"  : "#{eport.get_name}",
#{ep_subsc}            "bar_list"    : [
JOIN_INFO
        delim_2 = ""
        bars.each {|bar|
          f.print <<BAR_INFO
#{delim_2}                {
                     "type"     : "#{bar.type}",
                     "position" : #{bar.get_position}
BAR_INFO
          f.print "                }"
          delim_2 = ","
        }
        f.print "\n            ]\n"
        f.print "        }"
        delim_1 = ",\n"
        index += 1
      }
      f.print "\n    ]\n"
    end

    #----- old syntax for location information -----#
    # load code is still used for old data.

    #=== TECSModel#set_location_from_tecsgen
    # get location information from cde file and apply it to TmCell & TmJoin
    def set_location_from_tecsgen_old
      # set cell location
      @tecsgen.get_cell_location_list.each {|cl|
        cell_nspath, x, y, w, h, port_location_list = cl.get_location
        # p "set_location_from_tecsgen", cell_nspath, x, y, w, h, port_location_list
        cell = @cell_hash[cell_nspath.to_s.to_sym]
        if cell
          # p "apply location: #{cell.get_name}"
          cell.set_geometry(x, y, w, h)
        end
      }

      # set join location
      @tecsgen.get_join_location_list.each {|jl|
        cp_cell_nspath, cp_name, ep_cell_nspath, ep_name, bar_list = jl.get_location
        cp_subscript = nil # kari
        ep_subscript = nil
        # p "set_location_from_tecsgen, #{cp_cell_nspath}, #{cp_name}, #{ep_cell_nspath}, #{ep_name}, #{bar_list}"
        cp_cell = @cell_hash[cp_cell_nspath.to_s.to_sym]
        ep_cell = @cell_hash[ep_cell_nspath.to_s.to_sym]
        # check existance of cells
        if !cp_cell.nil? && !ep_cell.nil?
          cport = cp_cell.get_cports[cp_name.to_sym]
          eport = ep_cell.get_eports[ep_name.to_sym]
          # p "1 #{cp_name} #{ep_name} #{cport} #{eport}"

          # check existance of cport & eport and direction of bar & edge (must be in right angle)
          # mikan necessary more than 2 bars
          if !cport.nil? && !eport.nil? && eport.include?(cport.get_join(cp_subscript)) && bar_list.length >= 2
            # p "2"
            b_vertical = TECSModel.is_vertical?(cport.get_edge_side)
            bar_type = bar_list[0][0]
            if (b_vertical && bar_type == :HBar) || (!b_vertical && bar_type == :VBar)
              # p "3"
              len = bar_list.length
              # bar_list: [ [:HBar, pos]
              normal_pos = bar_list[len - 1][1].eval_const(nil)
              tan_pos = bar_list[len - 2][1].eval_const(nil)
              # p "normal_pos=#{normal_pos}, eport_normal=#{eport.get_position_in_normal_dir}"
              # p "tan_pos=#{tan_pos}, eport_tan=#{eport.get_position_in_tangential_dir}"
              # check if normal_pos & tan_pos can be evaluated and the position of bars goal
              if !normal_pos.nil? && !tan_pos.nil? &&
                  ((normal_pos - eport.get_position_in_normal_dir).abs <= MAX_ERROR_IN_NOR) &&
                  ((tan_pos - eport.get_position_in_tangential_dir).abs <= MAX_ERROR_IN_TAN)
                # p "4"
                bars = []
                bar_list.each {|bar_info|
                  # bar_list: array of [ IDENTIFER, position ] => bars ( array of HBar or VBar )
                  pos = bar_info[1].eval_const nil
                  if !pos.nil? && bar_info[0] == :HBar
                    bar = HBar.new(pos, cport.get_join)
                    bars << bar
                  elsif !pos.nil? && bar_info[0] == :VBar
                    bar = VBar.new(pos, cport.get_join)
                    bars << bar
                  else
                    bars = []
                    break
                  end
                }
                # mikan length more than 2
                len = bars.length
                if len >= 2
                  bars[len - 1].set_position eport.get_position_in_normal_dir
                  bars[len - 2].set_position eport.get_position_in_tangential_dir
                  # p "bar changed for #{cp_cell_nspath}.#{cport.get_name}"
                  cport.get_join.change_bars bars
                end
              end
            end
          end
        end
      }
    end

    def save_old_info(f)
      f.print "//////////  TECSCDE  ///////////\n"
      f.print "\n"
      f.print "/*************************************************\n"
      f.print " *             LOCATION INFORMATION              *\n"
      f.print " *   location information is used by tecscde     *\n"
      f.print " *  please don't touch if you are not familiar   *\n"
      f.print " ************************************************/\n"
      f.print "__location_information__ {\n"

      @cell_list.each {|cell|
        x, y, w, h = cell.get_geometry
        f.print("    __cell__  #{cell.get_name}( #{x}, #{y}, #{w}, #{h} ) {\n")
        cell.get_cports.each {|name, cport|
          if cport.is_array?
            cport.get_ports.each {|cp|
              f.print "        #{cp.get_name}( #{cp.get_subscript}, #{cp.get_edge_side_name}, #{cp.get_offset} )\n"
            }
          else
            f.print "        #{cport.get_name}( #{cport.get_edge_side_name}, #{cport.get_offset} )\n"
          end
        }
        cell.get_eports.each {|name, eport|
          if eport.is_array?
            eport.get_ports.each {|ep|
              f.print "        #{ep.get_name}( #{ep.get_subscript}, #{ep.get_edge_side_name}, #{ep.get_offset} )\n"
            }
          else
            f.print "        #{eport.get_name}( #{eport.get_edge_side_name}, #{eport.get_offset} )\n"
          end
        }
        f.print("    }\n")
      }
      @join_list.each {|join|
        cport, eport, bars = join.get_ports_bars
        if cport.get_subscript
          cp_subsc = "[ #{cport.get_subscript} ]"
        else
          cp_subsc = ""
        end
        if eport.get_subscript
          ep_subsc = "[ #{eport.get_subscript} ]"
        else
          ep_subsc = ""
        end

        f.print("    __join__( #{cport.get_cell.get_name}.#{cport.get_name}#{cp_subsc} => #{eport.get_cell.get_name}.#{eport.get_name}#{ep_subsc} ){\n")
        bars.each {|bar|
          f.print("        #{bar.type}( #{bar.get_position} )\n")
        }
        f.print("    }\n")
      }
      f.print("} //__location_information\n")
    end

    #=== TECSModel#get_edge_side_val
    def get_edge_side_val(edge_side_name)
      case edge_side_name
      when "EDGE_TOP"
        EDGE_TOP
      when "EDGE_BOTTOM"
        EDGE_BOTTOM
      when "EDGE_LEFT"
        EDGE_LEFT
      when "EDGE_RIGHT"
        EDGE_RIGHT
      else
        0 # same as EDGE_TOP
      end
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

#
# Software Design Memo
#
# pattern of lines between cells
#
# (a) parallel opposite side generic
# (b) parallel opposite side abbreviated
# (c) right angle generic
# (d) right angle  abbreviated
# (e) parallel same side generic
# (f) parallel same side abbreviated
#
# applying abbrviated patterns, there is conditions.
#
#    +-------------+
#    |          (f)|---------------------------1+
#    |          (d)|-------------------1+       |
#    |          (e)|----1+              |       |
#    |          (c)|---1+|              |       |
#    |          (a)|--1+||              |       |
#    |          (b)|-1+|||              |       |
#    |         (c)'|-+||||              |       |
#    +-------------+ |||||              |       |
#                    ||||+2-------------------3+|
#                    |||+2---------3+   |      ||
#                    ||+2---3+      |   |      ||
#                    ||      | +-------------+ ||
#                    ||      4 |    V   V    | 4|
#                    ||      +-|>           <|-+|
#                    |+2-------|>           <|-2+
#                    |         |    ^        |
#                    |         +-------------+
#                    |              |
#                    +--------------+
#
#  edge_side
#    horizontal
#      EDGE_TOP    = 0b00
#      EDGE_BOTTOM = 0b01
#    vertical
#      EDGE_LEFT   = 0b10
#      EDGE_RIGHT  = 0b11
#
#
#   bit0: 1 if normal direction is positive, 0 negative
#   bit1: 1 if vertical, 0 if horizontal
#
#   TECSModel class method
#     get_sign_of_normal( edge_side ) = (edge_side & 0b01) ? 1 : -1
#     is_vertical?( edge_side )   = (edge_side & 0b10) ? true : false
#     is_parallel?( edge_side1, edge_side2 ) = ( edge_side1 ^ edge_side2 ) < 0b10
#     is_opposite?( edge_side1, edge_side2 ) = ( ( edge_side1 ^ edge_side2 ) & 0b01 ) ? true : false
#         this function can be applicable only when edge_side1, edge_side2 are parallel
#
#   TmCell#get_edge_position_in_normal_dir( edge_side )
#       case edge_side
#       when  EDGE_TOP     y
#       when  EDGE_BOTTOM  y+height
#       when  EDGE_LEFT    x
#       when  EDGE_RIGHT   x+width
#
#   #=== (1)  (6) bar from call port. this indicate A position.
#   TmCPort#get_normal_bar_of_edge
#       pos = @cell.get_edge_position_in_normal_dir( @edge_side ) + Gap * TECSModel.get_sign_of_normal( @edge_side )
#       TECSModel.is_vertical?( @edge_side ) ? HBar.new( pos ) : VBar.new( pos )
#
#   TmCPort#tangential_position
#       ( TECSModel.is_vertical? @edge_side ) ? @cell.get_y + @offs : @cell.get_x + @offs
#
#   TmJoin#create_bars
#       if TECSModel.is_parallel?( @edge_side, dest_port.get_edge_side )
#           if TECSModel.is_opposite?( @edge_side, dest_port.get_edge_side )
#               create_bars_a
#           else
#               create_bars_e
#       else
#           create_bars_c
#
#   TmJoin#create_bars_a
#        @bars = []
#
#        @bars[0] = @cport.get_normal_bar_of_edge
#
#        posa = @cport.get_position_in_tangential_dir
#        e1, e2 = @eport.get_cell.get_right_angle_edges_position( @cport.get_edge_side )
#        pos2 = ( posa - e1 ).abs > ( posa - e2 ).abs ? e2 : e1
#        @bars[2] = (bar[1].instance_of? HBar) ? VBar.new( pos2 ) : HBar.new( pos2 )
#
#        pos3 = @eport.get_position_in_normal_dir + Gap * @eport.get_sign_of_normal
#        @bars[2] = (@bars[1].instance_of? HBar) ? VBar.new( pos3 ) : HBar.new( pos3 )
#
#        pos4 = @eport.get_position_in_normal_dir + Gap * @eport.get_sign_of_normal
#        @bars[3] = (@bars[2].instance_of? HBar) ? VBar.new( pos4 ) : HBar.new( pos4 )
#
#        pos5 = @eport.get_position_in_tangential_dir
#        @bars[4] = (@bars[3].instance_of? HBar) ? VBar.new( pos5 ) : HBar.new( pos5 )
#
#        pos6 = @eport.get_position_in_normal_dir
#        @bars[5] = (@bars[4].instance_of? HBar) ? VBar.new( pos6 ) : HBar.new( pos6 )
#
#   TmJoin#create_bars_c
#        @bars = []
#
#        @bars[0] = @cport.get_normal_bar_of_edge
#
#        pos1 = @eport.get_position_in_normal_dir + Gap * @eport.get_sign_of_normal
#        @bars[1] = (bar[0].instance_of? HBar) ? VBar.new( pos1 ) : HBar.new( pos1 )
#
#        pos2 = @eport.get_position_in_tangential_dir
#        @bars[2] = (bar[1].instance_of? HBar) ? VBar.new( pos2 ) : HBar.new( pos2 )
#
#        pos3 = @eport.get_position_in_normal_dir
#        @bars[3] = (bar[2].instance_of? HBar) ? VBar.new( pos3 ) : HBar.new( pos3 )
#
#   TmJoin#create_bars_e
#        @bars = []
#
#        @bars[0] = @cport.get_normal_bar_of_edge
#
#        pos1 = @eport.get_position_in_normal_dir + Gap * @eport.get_sign_of_normal
#        @bars[1] = (bar[0].instance_of? HBar) ? VBar.new( pos1 ) : HBar.new( pos1 )
#
#        posa = @cport.get_position_in_tangential_dir
#        e1, e2 = @eport.get_cell.get_right_angle_edges_position( @cport.get_edge_side )
#        pos2 = ( posa - e1 ).abs > ( posa - e2 ).abs ? e2 : e1
#        @bars[2] = (bar[1].instance_of? HBar) ? VBar.new( pos2 ) : HBar.new( pos2 )
#
#        pos3 = @eport.get_position_in_normal_dir + Gap * @eport.get_sign_of_normal
#        @bars[3] = (bar[2].instance_of? HBar) ? VBar.new( pos3 ) : HBar.new( pos3 )
#
#        pos4 = @eport.get_position_in_normal_dir
#        @bars[4] = (bar[3].instance_of? HBar) ? VBar.new( pos4 ) : HBar.new( pos4 )
#
#
#
#----- JSON schema (likely) -----#
#
