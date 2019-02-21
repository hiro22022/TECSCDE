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

module TECSCDE
  #== CelltypeTreeView: show celltype list
  # formerly this class is sub-class of Gtk::TreeView
  # currently this class has Gtk::TreeView
  class CelltypeTreeView
    COL_NAME   = 0
    COL_NSPATH = 1

    #=== initialize
    def initialize(tree_view)
      @tree_view = tree_view

      # create data model
      liststore = Gtk::ListStore.new(String, String)

      # set data model to tree view(self)
      @tree_view.set_model(liststore)

      # create renderer for text
      renderer = Gtk::CellRendererText.new

      # set column information
      col = Gtk::TreeViewColumn.new("name", renderer, :text => COL_NAME)
      @tree_view.append_column(col)

      col = Gtk::TreeViewColumn.new("namespace", renderer, :text => COL_NSPATH)
      @tree_view.append_column(col)

      liststore.set_sort_column_id(COL_NAME)
    end

    def add(celltype)
      iter = @tree_view.model.append
      iter[COL_NAME] = celltype.get_name
      iter[COL_NSPATH] = celltype.get_owner.get_namespace_path.to_s
    end

    def selected
      iter = @tree_view.selection.selected
      if iter
        [iter[COL_NAME], iter[COL_NSPATH]]
      else
        [nil, nil]
      end
    end

    def delete(item)
    end

    def clear
      @tree_view.model.clear
    end

    #=== CelltypeTreeView#get_treeView
    # RETURN::Gtk::TreeView
    def get_treeView
      @tree_view
    end
  end
end
