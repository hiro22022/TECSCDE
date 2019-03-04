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
  #== AttrTreeView: show cell list
  # formerly this class is sub-class of Gtk::TreeView
  # currently this class has Gtk::TreeView
  class AttrTreeView
    # @choice_list::{name=>ListStore}
    # @cell::TmCell
    # @ct_attr_list::{ String(attr_name) => String(initializer) }
    # @view::TECSCDE::View::MainView
    # @tree_view::Gtk::TreeView

    COL_NAME = 0
    COL_TYPE = 1
    COL_VALUE = 2

    attr_reader :tree_view # Gtk::TreeView

    #=== initialize
    def initialize(tree_view)
      @tree_view = tree_view

      combo_list = Gtk::ListStore.new(String)
      iter = combo_list.append
      iter[0] = "a0"
      combo_list = Gtk::ListStore.new(String, String, String)
      # iter = combo_list.append
      # iter[0] = "a0"
      # iter[1] = "b0"
      # iter[2] = "c0"
      # iter = combo_list.append
      # iter[0] = "a1"
      # iter[1] = "b1"
      # iter[2] = "c1"

      # combo_list2 = Gtk::ListStore.new(String, String, String)
      # iter = combo_list2.append
      # iter[0] = "A0"
      # iter[1] = "B0"
      # iter[2] = "C0"
      # iter = combo_list2.append
      # iter[0] = "A1"
      # iter[1] = "B1"
      # iter[2] = "C1"

      # create data model
      liststore = Gtk::ListStore.new(String, String, String)

      # set data model to tree view(self)
      @tree_view.set_model(liststore)

      # create renderer for text
      renderer = Gtk::CellRendererText.new

      #----- set column information -----#

      # ATTRIBUTE column
      col = Gtk::TreeViewColumn.new("attribute", renderer, text: COL_NAME)
      col.set_cell_data_func(renderer) do |_col, renderer, _model, iter|
        if iter[COL_VALUE].nil? || iter[COL_VALUE] == ""
          renderer.foreground = "red"
        elsif @cell.editable?
          renderer.foreground = "black"
        else
          renderer.foreground = "blue"
        end
      end
      @tree_view.append_column(col)

      # TYPE column
      col = Gtk::TreeViewColumn.new("type", renderer, text: COL_TYPE)
      col.set_cell_data_func(renderer) do |_col, renderer, _model, _iter|
        if @cell.editable?
          renderer.foreground = "black"
        else
          renderer.foreground = "blue"
        end
      end
      @tree_view.append_column(col)

      # VALUE column
      renderer = Gtk::CellRendererCombo.new
      renderer.text_column = 0
      renderer.model = combo_list
      col = Gtk::TreeViewColumn.new("value", renderer, text: COL_VALUE)
      col.set_cell_data_func(renderer) do |_col, renderer, _model, iter|
        # p "iter[0]=#{iter[0]}"
        if @cell.get_attr_list[iter[COL_NAME].to_sym].nil?
          renderer.foreground = "orange"
        elsif @cell.editable?
          renderer.foreground = "black"
        else
          renderer.foreground = "blue"
        end

        if @cell.editable?
          renderer.editable = true
        else
          renderer.editable = false
        end

        if @choice_list[iter[0]]
          renderer.model = @choice_list[iter[0]]
          renderer.has_entry = false
          renderer.text_column = 0
        else
          renderer.model = nil
          renderer.text_column = 0
          renderer.has_entry = true
        end

        # if iter[2] && iter[2] != ""
        # if iter[1] == "ID"
        #   renderer.model = combo_list
        #   renderer.has_entry = false
        #   renderer.text_column = 0
        # elsif iter[1] == "SIZE"
        #   renderer.model = combo_list2
        #   renderer.has_entry = false
        #   renderer.text_column = 1
        # elsif iter[1] == "PRI"
        #   renderer.model = combo_list
        #   renderer.has_entry = false
        #   renderer.text_column = 2
        # else
        #   renderer.model = nil
        #   renderer.text_column = 0
        #   renderer.has_entry = true
        # end
      end
      renderer.signal_connect("edited") do |_w, path, new_text|
        # new_text can be wrong if 'text_column' is changed in each row
        # after selection is changed, before sending signal, many rows are redrawn

        # p "new_text='#{new_text}'"
        if (iter = @tree_view.model.get_iter(path))
          if new_text.nil? || new_text == ""
            if @ct_attr_list[iter[COL_NAME]]
              iter[COL_VALUE] = @ct_attr_list[iter[COL_NAME]]
            else
              iter[COL_VALUE] = new_text
            end
            if new_text == ""
              new_text = nil
            end
          else
            iter[COL_VALUE] = new_text
          end
          @cell.set_attr(iter[COL_NAME].to_sym, new_text)
          @cell.model.set_undo_point
          @view.paint_canvas
        end
      end
      @tree_view.append_column(col)
    end

    #=== AttrTreeView#set_cell
    # cell::TmCell
    def set_cell(cell)
      clear
      @cell = cell
      @choice_list = {}
      @ct_attr_list = {}
      cell_attr_list = cell.get_attr_list

      ct = @cell.get_celltype
      return unless ct
      #----- register attributes and initializer to tree view model -----#
      ct.get_attribute_list.each do |attr|
        iter = @tree_view.model.append
        name = attr.get_name.to_s
        if attr.get_initializer
          @ct_attr_list[name] = attr.get_initializer.to_CDL_str
        end

        iter[COL_NAME] = name
        iter[COL_TYPE] = "#{attr.get_type.get_type_str}#{attr.get_type.get_type_str_post}"
        if cell_attr_list[name.to_sym]
          iter[COL_VALUE] = cell_attr_list[name.to_sym]
        elsif attr.get_initializer
          iter[COL_VALUE] = attr.get_initializer.to_CDL_str
        end

        #----- choice list model -----#
        if attr.get_choice_list
          @choice_list[name] = Gtk::ListStore.new(String)
          attr.get_choice_list.each do |choice|
            iter = @choice_list[name].append
            iter[0] = CDLString.remove_dquote(choice.val)
          end
        end
      end
    end

    def clear
      @tree_view.model.clear
    end

    #=== AttrTreeView#set_view
    # view::TECSCDE::View::MainView
    def set_view(view)
      @view = view
    end
  end
end
