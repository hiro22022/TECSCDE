module TECSCDE
  #== CelltypeTreeView: show celltype list
  # formerly this class is sub-class of Gtk::TreeView
  # currently this class has Gtk::TreeView
  class CelltypeTreeView
    COL_NAME   = 0
    COL_NSPATH = 1

    #=== initialize
    def initialize(treeView)
      @treeView = treeView

      # create data model
      liststore = Gtk::ListStore.new(String, String)

      # set data model to tree view(self)
      @treeView.set_model(liststore)

      # create renderer for text
      renderer = Gtk::CellRendererText.new

      # set column information
      col = Gtk::TreeViewColumn.new("name", renderer, :text => COL_NAME)
      @treeView.append_column(col)

      col = Gtk::TreeViewColumn.new("namespace", renderer, :text => COL_NSPATH)
      @treeView.append_column(col)

      liststore.set_sort_column_id(COL_NAME)
    end

    def add(celltype)
      iter = @treeView.model.append
      iter[COL_NAME] = celltype.get_name
      iter[COL_NSPATH] = celltype.get_owner.get_namespace_path.to_s
    end

    def selected
      iter = @treeView.selection.selected
      if iter
        [iter[COL_NAME], iter[COL_NSPATH]]
      else
        [nil, nil]
      end
    end

    def delete(item)
    end

    def clear
      @treeView.model.clear
    end

    #=== CelltypeTreeView#get_treeView
    # RETURN::Gtk::TreeView
    def get_treeView
      @treeView
    end
  end
end
