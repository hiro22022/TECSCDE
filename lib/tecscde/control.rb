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

require "tecscde/highlighted_objects"
require "tecscde/palette"

module TECSCDE
  #
  # Structure of Palette Window
  #
  #  +-- @window -----------------------------+
  #  |+-- @box ------------------------------+|
  #  ||+- mode (@mode_frame) ---------------+||
  #  |||+-@mode_vbox-----------------------+|||
  #  ||||  Pointer  (@pointer_button)      ||||
  #  |||+----------------------------------+|||
  #  ||||  New Cell (@new_button)          ||||
  #  |||+----------------------------------+|||
  #  ||+- celltypes (@celltype_frame)-------+||
  #  |||+- ClltypeTreeView&ScrolledWindow--+|||
  #  |||| name    | region                 ||||
  #  |||+---------+------------------------+|||
  #  ||||         |                        ||||
  #  ||||         |                        ||||
  #  |||+---------+------------------------+|||
  #  ||+- cell properties (@mode_celltype) -+||
  #  |||+- AttrTreeView&ScrolledWindow-----+|||
  #  |||| name    | type    | value        ||||
  #  |||+---------+---------+--------------+|||
  #  ||||         |         |              ||||
  #  ||||         |         |              ||||
  #  |||+---------+---------+--------------+|||
  #  |+--------------------------------------+|
  #  +----------------------------------------+
  #

  UNSELECTED_STR = "(unselected)"

  class Control
    # @window:: Gtk::Window
    # @model::Model
    # @view::View
    # @mode::Symbol: :NEW_CELL, :POINTER
    # @cport_joining::TmCPort   # :SM_JOINING starting cell
    # @celltype_tree_view::CelltypeTreeView
    # @attr_tree_view::AttrTreeView
    # @prev_time::Integer: event time (milli second)

    MODE_LIST    = [:MODE_NONE, :MODE_NEW_CELL, :MODE_POINTER]
    SUBMODE_LIST = [
      :SM_NONE,
      :SM_JOINING,
      :SM_SURROUNDING_CELLS,
      :SM_MOVING_CELL_BAR,
      :SM_MOVING_CPORT,
      :SM_MOVING_EPORT,
      :SM_MOVING_CELL_EDGE,
      :SM_EDIT_CELL_NAME
    ]

    attr_reader :highlighted_objects

    def initialize(model)
      @nest = -1
      @model = model
      @highlighted_objects = TECSCDE::HighlightedObjects.new
      @mode = :MODE_NONE
      @sub_mode = :SM_NONE
      @cport_joining = nil
      @prev_time = 0

      create_new_operation_window
      add_celltype_list

      @highlighted_objects.set_attr_tree_view(@attr_tree_view, @cell_name_entry, @cell_region_entry, @cell_frame)
      @highlighted_objects.update_attr_tree_view

      @last_xm = @last_ym = 0
    end

    #----- operations for palette -----#
    def on_save
      TECSCDE.logger.info("save")
      @model.save(@model.get_file_editing)
    end

    def on_export
      fname = @model.get_file_editing.sub(/\.[Cc][Dd][Ee]\Z/, ".pdf")
      if !(fname =~ /\.pdf\Z/)
        fname += ".pdf"
      end
      TECSCDE.logger.info("export to #{fname}")
      @view.export(fname)
    end

    def on_pointer
      TECSCDE.logger.info("mode: pointer")
      @mode = :MODE_POINTER
    end

    def on_new_cell
      @mode = :MODE_NEW_CELL
      TECSCDE.logger.info("mode: new")
    end

    def on_undo
      @model.undo
      @highlighted_objects.reset
      update
    end

    def on_redo
      @model.redo
      @highlighted_objects.reset
      update
    end

    def on_quit
      TECSCDE.quit(@model)
    end

    def on_cell_name_entry_active(entry)
      @b_cell_renaming = true
      @highlighted_objects.change_cell_name entry.text
      @b_cell_renaming = false
      update
    end

    def on_cell_name_entry_focus_out(entry)
      # to avoid nested message box dialog in error case
      if !@b_cell_renaming
        @highlighted_objects.change_cell_name entry.text
        update
      end
    end

    def on_cell_region_entry_active(entry)
      # @b_cell_renaming = true
      # @highlighted_objects.change_cell_name entry.text
      # @b_cell_renaming = false
      # update
    end

    def on_cell_region_entry_focus_out(entry)
      # to avoid nested message box dialog in error case
      # if ! @b_cell_renaming
      #   @highlighted_objects.change_cell_name entry.text
      #   update
      # end
    end

    def set_attr_operation_widgets(window, celltype_tree_view, attr_tree_view, cell_name_entry, cell_region_entry, cell_frame)
      @window = window
      @celltype_tree_view = celltype_tree_view
      @attr_tree_view = attr_tree_view
      @cell_name_entry = cell_name_entry
      @cell_region_entry = cell_region_entry
      @cell_frame = cell_frame
      @highlighted_objects.set_attr_tree_view(@attr_tree_view, @cell_name_entry, @cell_region_etnry, @cell_frame)
    end

    def preferences
      {
        paper: @model.paper
      }
    end

    def change_preferences(paper: nil)
      @model.paper = paper.to_sym
    end

    #----- palette -----#
    def create_new_operation_window
      @palette = TECSCDE::Palette.new self
      # @palette.get_entry_cell_name
      # @palette.get_attrTreeView
    end

    #----- end of palette operations -----#

    def set_view(view)
      @view = view
      @attr_tree_view.set_view view

      # keep controlWindow above mainWindow
      @window.set_transient_for(@view.get_window)
      @window.window.set_group @view.get_window.window
      @window.window.raise

      @palette.set_view view
    end

    #----- canvas events action -----#

    #=== mouse pressed on canvas
    # button::Integer: mouse button number
    # state::GdkModifierType: modifier key state
    # time::Integer: milli second
    # click_count::Integer: 1=single click, 2=double click
    def pressed_on_canvas(xm, ym, state, button, time, click_count)
      # p "button=#{button} state=#{state} time=#{time} sub_mode=#{@sub_mode}"
      if @sub_mode == :SM_EDIT_CELL_NAME
        name = @view.end_edit_name
        # p "end_edit_name name=#{name}"
        @highlighted_objects.change_cell_name name
        @sub_mode = :SM_NONE
      end

      if button == 1
        object = find_near xm, ym
        if object.is_a?(TECSModel::TmCell) && click_count == 2
          if object.editable?
            # p "begin_edit_name"
            @view.begin_edit_name object, time
            @highlighted_objects.reset(object)
            @sub_mode = :SM_EDIT_CELL_NAME
          end
        elsif object.is_a?(TECSModel::TmCell) || object.is_a?(TECSModel::TmJoinBar)
          @sub_mode = :SM_MOVING_CELL_BAR
          # p "FOUND Cell or Bar"
          if state.shift_mask?
            @highlighted_objects.add(object)
          elsif state.control_mask?
            @highlighted_objects.add_del(object)
          elsif !@highlighted_objects.include? object
            @highlighted_objects.reset(object)
          end
          @view.draw_hilite_objects @highlighted_objects
        elsif object.is_a? TECSModel::TmCPort
          # p "FOUND TmCPort"
          if state.shift_mask?
            @sub_mode = :SM_MOVING_CPORT
            @highlighted_objects.add object
          elsif state.control_mask?
            @sub_mode = :SM_MOVING_CPORT
            @highlighted_objects.reset(object)
          elsif object.get_join.nil?
            @sub_mode = :SM_JOINING
            @highlighted_objects.reset
            @cport_joining = object
            @view.set_cursor TECSCDE::CURSOR_JOINING
          else
            TECSCDE.message_box(<<~MESSAGE, :OK)
              Call port has already been joined.
              Delete existing join before creating new join.
              If you want to hilited port, click with pressing shift key.
            MESSAGE
          end
        elsif object.is_a? TECSModel::TmEPort
          @sub_mode = :SM_MOVING_EPORT
          if state.shift_mask?
            @highlighted_objects.add object
          elsif state.control_mask?
            @highlighted_objects.add_del(object)
          else
            # p "FOUND TmEPort"
            @highlighted_objects.reset object
          end
        else
          # p "NOT FOUND"
          if @mode == :MODE_NEW_CELL
            ctn, nsp = @celltype_tree_view.selected
            if ctn
              cell = @model.new_cell(xm, ym, ctn, nsp)
              @model.set_undo_point
            end
            @highlighted_objects.reset cell
          else
            @highlighted_objects.reset
          end
        end
        @last_xm = xm
        @last_ym = ym
      end
      @prev_time = time
    end

    #=== mouse moved on canvas
    def motion_on_canvas(xm, ym, state)
      x_inc = xm - @last_xm
      y_inc = ym - @last_ym

      q, r = x_inc.divmod TECSModel.get_alignment
      x_inc2 = TECSModel.get_alignment * q
      @last_xm = xm - r

      q, r = y_inc.divmod TECSModel.get_alignment
      y_inc2 = TECSModel.get_alignment * q
      @last_ym = ym - r

      case @sub_mode
      when :SM_MOVING_CELL_BAR
        # p "move hilite obj"
        @highlighted_objects.each do |cell_bar|
          cell_bar.move(x_inc2, y_inc2)
        end
        @view.refresh_canvas
        @view.draw_hilite_objects @highlighted_objects
      when :SM_MOVING_CPORT, :SM_MOVING_EPORT
        @highlighted_objects.each do |port|
          port.move(x_inc2, y_inc2)
        end
        update
        @view.refresh_canvas
        @view.draw_hilite_objects @highlighted_objects
      when :SM_JOINING
        object = find_near xm, ym
        if object.is_a? TECSModel::TmEPort
          if object.get_signature == @cport_joining.get_signature
            @view.set_cursor TECSCDE::CURSOR_JOIN_OK
          end
          # update
        end

      when :SM_NONE
        object = find_near xm, ym
        if object.is_a? TECSModel::TmCPort
          @view.set_cursor TECSCDE::CURSOR_PORT
        else
          @view.set_cursor TECSCDE::CURSOR_NORMAL
        end
      end
    end

    #=== mouse released on canvas
    def released_on_canvas(xm, ym, state, button)
      case @sub_mode
      when :SM_MOVING_CELL_BAR
        # update
        @model.set_undo_point
      when :SM_MOVING_CPORT, :SM_MOVING_EPORT
        # update
        @model.set_undo_point
      when :SM_JOINING
        object = find_near xm, ym
        if object.is_a? TECSModel::TmEPort
          if object.get_signature == @cport_joining.get_signature
            join = @model.new_join(@cport_joining, object)
            @model.set_undo_point
          end
          # update
        end
      end
      @view.set_cursor TECSCDE::CURSOR_NORMAL
      if @sub_mode != :SM_EDIT_CELL_NAME
        update
        @sub_mode = :SM_NONE
      end
    end

    def key_pressed(keyval, state)
      if @sub_mode == :SM_EDIT_CELL_NAME

        return
      end

      case keyval
      when 0xff     # delete key
        @highlighted_objects.each do |object|
          if object.is_a? TECSModel::TmJoinBar
            object.get_join.delete
          elsif object.is_a? TECSModel::TmCell
            object.delete
          elsif object.is_a? TECSModel::TmPort
            object.delete_hilited
          end
        end
        @highlighted_objects.reset
      when 0x63     # Insert
        @highlighted_objects.each do |object|
          if object.is_a? TECSModel::TmPort
            object.insert(state.shift_mask? ? :before : :after)
          end
        end
      when 0x51, 0x52, 0x53, 0x54
        case keyval
        when 0x51     # left arrow
          x_inc = - TECSModel.get_alignment
          y_inc = 0
        when 0x52     # up arrow
          x_inc = 0.0
          y_inc = - TECSModel.get_alignment
        when 0x53     # right arrow
          x_inc = TECSModel.get_alignment
          y_inc = 0
        when 0x54     # down arrow
          x_inc = 0.0
          y_inc = TECSModel.get_alignment
        end
        @highlighted_objects.each do |obj|
          obj.move(x_inc, y_inc)
        end
      when 0x50     # home
      when 0x57     # end
      when 0x55     # PageUp
      when 0x56     # PageDown
      else
        message = "key_pressed: keyval=%02x" % [keyval]
        TECSCDE.logger.info(message)
      end
      if @sub_mode != :SM_EDIT_CELL_NAME
        update
      end
      @model.set_undo_point
    end

    #=== find_near object
    # RETURN::TmCell, TmPort, TmJoin
    def find_near(xm, ym)
      @model.get_cell_list.each do |cell|
        port = cell.get_near_port(xm, ym)
        if !port.nil?
          # p "found port"
          return port
        end

        if cell.near?(xm, ym)
          # p "found cell"
          return cell
        end
      end

      # find nearest bar
      min_dist = 999999999
      min_bar = nil
      @model.get_join_list.each do |join|
        bar, dist = join.get_near_bar(xm, ym)
        if dist < min_dist
          min_dist = dist
          min_bar = bar
        end
      end
      min_bar
    end

    def add_celltype_list
      ctl = @model.get_celltype_list
      if ctl
        ctl.each do |ct|
          @celltype_tree_view.add ct
        end
      end
    end

    # Control#update
    def update
      @highlighted_objects.update_attr_tree_view
      @view.paint_canvas
    end
  end
end
