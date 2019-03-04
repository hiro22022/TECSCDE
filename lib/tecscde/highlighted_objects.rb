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

module TECSCDE
  #== manage highlighted objects
  class HighlightedObjects
    # @objects::[TmCell|TmJoinBar]
    def initialize
      @objects = []
    end

    def add(obj)
      reset_if_ncessary(obj)
      @objects << obj
      @objects.uniq!
      update_attr_tree_view
    end

    #=== objects#add_del
    # add if not include, delete if include
    def add_del(obj)
      reset_if_ncessary(obj)
      if @objects.include?(obj)
        @objects.delete(obj)
      else
        @objects << obj
      end
      update_attr_tree_view
    end

    def reset(obj = nil)
      @objects = []
      if obj
        @objects << obj
      end
      update_attr_tree_view
    end

    #=== objects#reset_if_ncessary
    # Port and ( Cell or Bar ) cannot be highlighted simultaneously.
    # Ports belonging to diferent Cell cannot be highlighted simultaneously.
    # obj::TmCell | TmBar | TmPort: new object to be highlighted
    def reset_if_ncessary(obj)
      return if @objects.empty?
      if @objects[0].is_a?(TECSModel::TmPort)
        if obj.is_a?(TECSModel::TmPort)
          if obj.get_owner_cell != @objects[0].get_owner_cell
            reset
          end
        else
          reset
        end
      else
        if obj.is_a?(TECSModel::TmPort)
          reset
        end
      end
    end

    def each
      @objects.each do |obj|
        yield obj
      end
    end

    def empty?
      @objects.empty?
    end

    def include?(object)
      @objects.include?(object)
    end

    def set_attr_tree_view(tree_view, name_entry, region_entry, frame)
      @cell_property_frame = frame
      @cell_name_entry = name_entry
      @cell_region_entry = region_entry
      @attr_tree_view = tree_view
    end

    def change_cell_name(name)
      if @objects.length == 1 && @objects[0].is_a?(TECSModel::TmCell)
        @objects[0].change_name(name.to_sym)
        @objects[0].get_model.set_undo_point
      end
    end

    def cell_plugin_dialog
      if @objects.length == 1 && @objects[0].is_a?(TECSModel::TmCell)
        dialog = CellPluginDialog.new(@objects[0])
        dialog.run
      end
    end

    def update_attr_tree_view
      cell = nil
      n_cell = 0
      each do |obj|
        if obj.is_a?(TECSModel::TmCell)
          cell = obj
          n_cell += 1
        end
      end
      if n_cell == 1
        @cell_name_entry.text = cell.get_name.to_s
        @cell_region_entry.text = cell.get_region.get_namespace_path.to_s

        # this doesn't work!  I don't know how to change the color of Entry text
        if cell.editable?
          @cell_name_entry.modify_fg(Gtk::STATE_NORMAL, Gdk::Color.parse("black"))
          @cell_region_entry.modify_fg(Gtk::STATE_NORMAL, Gdk::Color.parse("black"))
          @cell_property_frame.set_label("cell property")
        else
          @cell_name_entry.modify_fg(Gtk::STATE_NORMAL, Gdk::Color.parse("blue"))
          @cell_region_entry.modify_fg(Gtk::STATE_NORMAL, Gdk::Color.parse("blue"))
          @cell_property_frame.set_label("cell property (read only)")
        end

        @cell_name_entry.set_editable(cell.editable?)
        @cell_region_entry.set_editable(cell.editable?)

        @attr_tree_view.set_cell(cell)
      else
        @cell_name_entry.text = "(unselected)"
        @cell_name_entry.set_editable(false)
        @cell_name_entry.text = "(unselected)"
        @cell_name_entry.set_editable(false)
        @cell_property_frame.set_label("cell property (unselected)")

        @attr_tree_view.clear
      end
    end
  end
end
