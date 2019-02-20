module TECSCDE
  #== manage highlighted objects
  class HighlightedObjects
    # @objects::[TmCell|TmJoinBar]
    def initialize
      @objects = []
    end

    def add(obj)
      reset_if_ncessary obj
      @objects << obj
      @objects.uniq!
      update_attrTreeView
    end

    #=== objects#add_del
    # add if not include, delete if include
    def add_del(obj)
      reset_if_ncessary obj
      if @objects.include? obj
        @objects.delete obj
      else
        @objects << obj
      end
      update_attrTreeView
    end

    def reset(obj = nil)
      @objects = []
      if obj
        @objects << obj
      end
      update_attrTreeView
    end

    #=== objects#reset_if_ncessary
    # Port and ( Cell or Bar ) cannot be hilited simultaneously.
    # Ports belonging to diferent Cell cannot be hilited simultaneously.
    # obj::TmCell | TmBar | TmPort: new object to be hilited
    def reset_if_ncessary(obj)
      if @objects.length > 0
        if @objects[0].is_a? TECSModel::TmPort
          if obj.is_a? TECSModel::TmPort
            if obj.get_owner_cell != @objects[0].get_owner_cell
              reset
            end
          else
            reset
          end
        else
          if obj.is_a? TECSModel::TmPort
            reset
          end
        end
      end
    end

    def each # proc
      proc = Proc.new
      @objects.each{|obj|
        proc.call obj
      }
    end

    def empty?
      @objects.empty?
    end

    def include?(object)
      @objects.include? object
    end

    def set_attrTreeView(treeview, name_entry, region_entry, frame)
      @cell_property_frame = frame
      @cell_name_entry = name_entry
      @cell_region_entry = region_entry
      @attrTreeView = treeview
    end

    def change_cell_name(name)
      if @objects.length == 1 && @objects[0].is_a?(TECSModel::TmCell)
        @objects[0].change_name name.to_sym
        @objects[0].get_model.set_undo_point
      end
    end

    def cell_plugin_dialog
      if @objects.length == 1 && @objects[0].is_a?(TECSModel::TmCell)
        dialog = CellPluginDialog.new @objects[0]
        dialog.run
      end
    end

    def update_attrTreeView
      cell = nil
      n_cell = 0
      each{|obj|
        if obj.is_a? TECSModel::TmCell
          cell = obj
          n_cell += 1
        end
      }
      if n_cell == 1
        @cell_name_entry.text = cell.get_name.to_s
        @cell_region_entry.text = cell.get_region.get_namespace_path.to_s

        # this doesn't work!  I don't know how to change the color of Entry text
        if cell.is_editable?
          @cell_name_entry.modify_fg Gtk::STATE_NORMAL, Gdk::Color.parse("black")
          @cell_region_entry.modify_fg Gtk::STATE_NORMAL, Gdk::Color.parse("black")
          @cell_property_frame.set_label "cell property"
        else
          @cell_name_entry.modify_fg Gtk::STATE_NORMAL, Gdk::Color.parse("blue")
          @cell_region_entry.modify_fg Gtk::STATE_NORMAL, Gdk::Color.parse("blue")
          @cell_property_frame.set_label "cell property (read only)"
        end

        @cell_name_entry.set_editable cell.is_editable?
        @cell_region_entry.set_editable cell.is_editable?

        @attrTreeView.set_cell cell
      else
        @cell_name_entry.text = "(unselected)"
        @cell_name_entry.set_editable false
        @cell_name_entry.text = "(unselected)"
        @cell_name_entry.set_editable false
        @cell_property_frame.set_label "cell property (unselected)"

        @attrTreeView.clear
      end
    end
  end
end
