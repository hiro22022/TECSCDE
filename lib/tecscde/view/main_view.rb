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
#  (1) structure of MainWindow
#
#    +- @main_window::Window--------------------+
#    |+-@vbox::VBox(1/2)-----------------------+|
#    ||+-- @scrolled_window::ScrolledWindow--+ ||
#    ||| +---------------------------------+ | ||
#    ||| | @canvas::Canvas                 | | ||
#    ||| |                                 | | ||
#    ||| |                                 | | ||
#    ||| |                                 | | ||
#    ||| |                                 | | ||
#    ||| |                                 | | ||
#    ||| |                                 | | ||
#    ||| |                                 | | ||
#    ||| +---------------------------------+ | ||
#    ||+-------------------------------------+ ||
#    |+-@vbox::VBox(2/2)-----------------------+|
#    ||                        <--HScale-->    ||
#    |+----------------------------------------+|
#    +------------------------------------------+
#
#  @canvas::Canvas (<DrawingArea)
#    紙の大きさを持つ、描画エリア
#    大きさ (dots) = PaperHeight(mm) * dpi / 25.4 * Scale
#      A4L=270*180  (Papersize=297*197)
#
#  (2) canvasPixmap
#
#    +---------------------------------+
#    | @canvas_pixmap::Pixmap          |
#    |                                 |
#    |                                 |
#    |                                 |
#    |                                 |
#    |                                 |
#    |                                 |
#    |                                 |
#    +---------------------------------+
#
#  @canvas_pixmap is invisible.
#  draw contents on @canvas_pixmap then copy on @canvas, to avoid flickers and to redraw fast on expose.
#

require "gtk2"

module TECSCDE
  module View
    #== MainView class
    class MainView
      # @main_window::Gtk::Window
      # @main_window_height::Integer
      # @main_window_width::Integer
      # @vbox::VBox
      # @canvas_height::Integer
      # @canvas_width::Integer
      # @canvas::Canvas
      # @canvas_pixmap::Gtk::Pixmap
      # @gdk_window::Gdk::Window  GDK window of @canvas
      # @draw_target::Gtk::Pixmap | Gdk::Window : @canvas_pixmap or @gdk_window
      # @canvas_gc::Gdk::GC
      # @model::Model
      # @hscale::HScale
      # @scale_val::Integer
      # @control::Control
      # @pango_context::Gdk::Pango.context
      # @pango_layout::Pango::Layout
      # @pango_matrix::Pango::Matrix

      include TECSCDE::View::Constants

      # colors
      @@colors = nil
      @@colormap = nil

      def initialize(model, control)
        @model = model
        @control = control
        @paper = :A3L
        @b_emphasize_cell_name = false
        @b_color_by_region = false
        MainView.setup_colormap

        @main_window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
        @main_window_width = width = 900
        @main_window_height = height = 600
        @main_window.title = "TECSCDE - TECS Component Diagram Editor"
        @main_window.set_default_size(width, height)
        @main_window.sensitive = true
        @main_window.signal_connect("delete-event") do |_window, *_args|
          TECSCDE.quit(@model, @main_window)
          true
        end
        # KEY-PRESS event action
        @main_window.signal_connect("key-press-event") do |_win, event|
          if @entry_win.visible?
            # while cell name editing, send forward to Entry window
            event.set_window(@entry_win.window)
            event.put
          else
            @control.key_pressed(event.keyval & 0xff, event.state)
          end
        end
        @main_window.signal_connect("focus-in-event") do |win, event|
          # p "event:#{event.class} in"
        end
        @main_window.signal_connect("focus-out-event") do |win, event|
          # p "event:#{event.class} out"
        end
        @main_window.signal_connect("grab-broken-event") do |win, event|
          # p "event:#{event.class}"
        end
        @main_window.signal_connect("grab-focus") do |win|
          # p "event:grab-focus"
        end
        @main_window.signal_connect("grab-notify") do |win, arg1|
          # p "event:grab-notify"
        end

        create_hscale
        create_hbox

        @vbox = Gtk::VBox.new
        # @vbox.set_resize_mode Gtk::RESIZE_IMMEDIATE
        # p @vbox.resize_mode
        @main_window.add(@vbox)

        @scrolled_window = Gtk::ScrolledWindow.new
        # @scrolled_window.signal_connect("expose_event") { |win, evt|
        #   gdkWin = @scrolled_window.window
        #   gc = Gdk::GC.new gdkWin
        #   gdkWin.draw_rectangle( gc, true, 0, 0, 10000, 10000 )
        # }

        @vbox.pack_start(@scrolled_window)
        @vbox.pack_end(@hbox, false) # expand = false

        create_canvas
        @scrolled_window.set_size_request(width, height - SCALE_HEIGHT)

        @main_window.show_all

        create_edit_window
      end

      def get_window
        @main_window
      end

      #------ CANVAS  ------#

      #=== create canvas
      def create_canvas
        @canvas = Canvas.new
        resize_canvas
        TECSCDE.logger.debug("canvas width=#{@canvas_width}, height=#{@canvas_height}")

        # BUTTON PRESS event action
        @canvas.signal_connect("button-press-event") do |_canvas, event| # canvas = @canvas
          TECSCDE.logger.debug("pressed #{event}")
          xd, yd = event.coords
          xm = dot2mm(xd)
          ym = dot2mm(yd)

          case event.event_type
          when Gdk::Event::BUTTON_PRESS   # single click or before ddouble, triple click
            click_count = 1
          when Gdk::Event::BUTTON2_PRESS  # double click
            click_count = 2
          when Gdk::Event::BUTTON3_PRESS  # triple click
            click_count = 3
          else
            click_count = 1
          end
          @control.pressed_on_canvas(xm, ym, event.state, event.button, event.time, click_count)
        end
        # BUTTON RELEASE event action
        @canvas.signal_connect("button-release-event") do |_canvas, event|
          TECSCDE.logger.debug("released #{event}")
          xd, yd = event.coords
          xm = dot2mm(xd)
          ym = dot2mm(yd)
          @control.released_on_canvas(xm, ym, event.state, event.button)
        end
        # MOTION event action
        @canvas.signal_connect("motion-notify-event") do |_canvas, event|
          TECSCDE.logger.debug("motion #{event}")
          xd, yd = event.coords
          xm = dot2mm(xd)
          ym = dot2mm(yd)
          @control.motion_on_canvas(xm, ym, event.state)
        end
        # EXPOSE event action
        @canvas.signal_connect("expose_event") do |_win, _evt|
          refresh_canvas
        end

        # add events to receive
        @canvas.add_events(Gdk::Event::POINTER_MOTION_MASK |
                            Gdk::Event::BUTTON_PRESS_MASK  |
                            Gdk::Event::BUTTON_RELEASE_MASK |
                            Gdk::Event::PROPERTY_CHANGE_MASK |
                            Gdk::Event::KEY_PRESS_MASK)

        @scrolled_window.add_with_viewport(@canvas)
        # it seems that gdkWindow is nil before window.show or realize
        @canvas.realize
        @gdk_window = @canvas.window
        @canvas_gc = Gdk::GC.new(@gdk_window)

        # prepare pixmap (buffer for canvas)
        #  pixmap cannot be resized, so we have the largest one at initial.
        @canvas_pixmap = Gdk::Pixmap.new(@gdk_window,
                                         @canvas_width  * SCALE_VAL_MAX / SCALE_VAL_INI,
                                         @canvas_height * SCALE_VAL_MAX / SCALE_VAL_INI,
                                         @gdk_window.depth)
        # @draw_target = @canvas_pixmap
        @cairo_context_pixmap = @canvas_pixmap.create_cairo_context
        @cairo_context_pixmap.save
        # @cairo_context_win = @gdk_window.create_cairo_context
        # @cairo_context_win.save
        @cairo_context_target = @cairo_context_pixmap
        @cairo_matrix = TECSCDE::View::CairoMatrix.new

        # prepare text renderer
        @pango_context = Gdk::Pango.context
        @pango_layout = Pango::Layout.new(@pango_context)
        @pango_matrix = Pango::Matrix.new.rotate!(90)
      end

      def paint_canvas
        clear_canvas_pixmap

        #----- draw cells -----#
        @model.get_cell_list.each do |cell|
          draw_cell(cell)
        end

        #----- draw joins -----#
        # draw linew before draw texts (if other colors are used, it is better to lay texts upper side)
        @model.get_join_list.each do |join|
          draw_join(join)
        end

        refresh_canvas
      end

      def refresh_canvas
        @gdk_window.draw_drawable(@canvas_gc, @canvas_pixmap, 0, 0, 0, 0, @canvas_width, @canvas_height)
        draw_hilite_objects(@control.highlighted_objects)
      end

      def resize_canvas
        @canvas_height = Integer(mm2dot(@model.paper.height))
        @canvas_width  = Integer(mm2dot(@model.paper.width))
        @canvas.set_size_request(@canvas_width, @canvas_height)
        # @scrolled_window.queue_draw
      end

      def clear_canvas_pixmap
        @canvas_gc.function = Gdk::GC::SET
        @canvas_gc.fill = Gdk::GC::SOLID
        @canvas_gc.foreground = Gdk::Color.new(255, 255, 255)
        @canvas_pixmap.draw_rectangle(@canvas_gc, true, 0, 0, @canvas_width, @canvas_height)
        canvas_gc_reset
        # p "color = #{@canvas_gc.foreground.red}, #{@canvas_gc.foreground.green}, #{@canvas_gc.foreground.blue}"
      end

      def set_cursor(cursor)
        @canvas.window.cursor = cursor
      end

      #=== TmView#draw_target_direct
      # change draw target to Window
      def draw_target_direct
        # @draw_target = @gdk_window
        # @cairo_context_target = @cairo_context_win
      end

      #=== TmView#draw_target_reset
      # reset draw target to canvasPixmap
      def draw_target_reset
        # @draw_target = @canvas_pixmap
        # @cairo_context_target = @cairo_context_pixmap
      end

      #------ HBox  ------#
      def create_hbox
        @hbox = Gtk::HBox.new
        #----- emphasize_cell_name button -----#
        @emphasize_cell_name_button = Gtk::ToggleButton.new("Emphasize Cell Name")
        @emphasize_cell_name_button.signal_connect("toggled") do |button|
          @b_emphasize_cell_name = button.active?
          paint_canvas
        end
        @hbox.pack_start(@emphasize_cell_name_button)

        #----- color by region button -----#
        # @color_by_region_button = Gtk::ToggleButton.new( "Color by Region" )
        @color_by_region_button = Gtk::CheckButton.new("Color by Region")
        @color_by_region_button.signal_connect("toggled") do |button|
          @b_color_by_region = button.active?
          # @color_by_region_button.label =  button.active? ? "Color by File" : "Color by Region"
          paint_canvas
        end
        @hbox.pack_start(@color_by_region_button)
        @hbox.pack_end(@hscale)
      end

      #------ HScale  ------#
      def create_hscale
        @scale_val = SCALE_VAL_INI
        @hscale = Gtk::HScale.new(SCALE_VAL_MIN, SCALE_VAL_MAX, 1)
        @hscale.set_digits(0) # 小数点以下
        @hscale.set_value(@scale_val)
        @hscale.set_size_request(@main_window_width, SCALE_HEIGHT)
        @hscale.signal_connect("value-changed") do |scale_self, _scroll_type|
          # set scale_val in the range [SCALE_VAL_MIN..SCALE_VAL_MAX]
          scale_val = scale_self.value
          if scale_val > SCALE_VAL_MAX
            scale_val = SCALE_VAL_MAX
          elsif scale_val < SCALE_VAL_MIN
            scale_val = SCALE_VAL_MIN
          end
          @scale_val = scale_val
          TECSCDE.logger.debug("scale_val=#{@scale_val}")

          resize_canvas
          paint_canvas
        end
      end

      #------ Draw Contents on CANVAS  ------#

      def draw_cell(cell)
        #----- calc position in dot -----#
        x, y, w, h = cell.get_geometry
        x1 = mm2dot(x)
        y1 = mm2dot(y)
        x2 = mm2dot(x + w)
        y2 = mm2dot(y + h)
        w1 = mm2dot(w)
        h1 = mm2dot(h)

        #----- paint cell -----#
        color = get_cell_paint_color(cell)
        # @canvas_gc.set_foreground color
        # @draw_target.draw_rectangle( @canvas_gc, true, x1, y1, w1, h1 )

        @cairo_context_target.rectangle(x1, y1, w1, h1)
        @cairo_context_target.set_source_color(color)
        @cairo_context_target.fill

        #----- setup color -----#
        if !cell.editable?
          # @canvas_gc.set_foreground @@colors[ Color_uneditable ]
          @cairo_context_target.set_source_color(@@colors[Color_uneditable])
        else
          # @canvas_gc.set_foreground @@colors[ Color_editable ]
          @cairo_context_target.set_source_color(@@colors[Color_editable])
        end

        #----- draw cell rect -----#
        # @draw_target.draw_rectangle( @canvas_gc, false, x1, y1, w1, h1 )
        # @cairo_context_target.rectangle(x1, y1, w1, h1)
        @cairo_context_target.rectangle(x1 + 0.5, y1 + 0.5, w1, h1)
        @cairo_context_target.set_line_width(1)
        @cairo_context_target.stroke

        gap = mm2dot(GAP_ACTIVE)
        gap = 2 if gap < 2 # if less than 2 dots, let gap 2 dots
        if cell.get_celltype&.is_active?
          # @draw_target.draw_rectangle( @canvas_gc, false, x1 + gap, y1 + gap, w1 - 2 * gap, h1 - 2 * gap )
          @cairo_context_target.rectangle(x1 + gap + 0.5, y1 + gap + 0.5, w1 - 2 * gap, h1 - 2 * gap)
          @cairo_context_target.set_line_width(1)
          @cairo_context_target.stroke
        end

        #----- draw entry ports triangle -----#
        cell.get_eports.each do |_name, eport|
          if !eport.array?
            draw_entry_port_triangle(eport)
          else
            if cell.editable? && eport.is_unsubscripted_array?
              # @canvas_gc.set_foreground @@colors[ :brown ]
              @cairo_context_target.set_source_color(@@colors[:brown])
            end
            # EPortArray
            eport.get_ports.each do |ep|
              draw_entry_port_triangle(ep)
            end
            if cell.editable? && eport.is_unsubscripted_array?
              # @canvas_gc.set_foreground @@colors[ Color_editable ]
              @cairo_context_target.set_source_color(@@colors[Color_editable])
            end
          end
        end

        #----- draw cell name & celltype name -----#
        cell_name = cell.get_name
        ct_name = cell.get_celltype.get_name
        label = cell_name.to_s + "\n" + ct_name.to_s
        unless cell.complete?
          # @canvas_gc.set_foreground @@colors[ Color_incomplete ]
          @cairo_context_target.set_source_color(@@colors[Color_incomplete])
        end
        # draw_text( x1 + w1/2, y1+h1/2, label, CELL_NAME, ALIGN_CENTER, TEXT_HORIZONTAL )

        if @b_emphasize_cell_name
          wmn, hmn = get_text_extent(cell_name.to_s, CELL_NAME_L, ALIGN_CENTER, TEXT_HORIZONTAL)
          if wmn > w
            s1, s2 = div_string(cell_name.to_s)
            draw_text(x1 + w1 / 2, y1 + h1 / 2 - mm2dot(hmn) / 2, s1, CELL_NAME_L, ALIGN_CENTER, TEXT_HORIZONTAL)
            draw_text(x1 + w1 / 2, y1 + h1 / 2 + mm2dot(hmn) / 2, s2, CELL_NAME_L, ALIGN_CENTER, TEXT_HORIZONTAL)
          else
            draw_text(x1 + w1 / 2, y1 + h1 / 2, cell_name.to_s, CELL_NAME_L, ALIGN_CENTER, TEXT_HORIZONTAL)
          end
        else
          wmn, hmn = get_text_extent(cell_name.to_s, CELL_NAME, ALIGN_CENTER, TEXT_HORIZONTAL)
          draw_text(x1 + w1 / 2, y1 + h1 / 2 + mm2dot(hmn) / 2, cell_name.to_s, CELL_NAME, ALIGN_CENTER, TEXT_HORIZONTAL)
          draw_text(x1 + w1 / 2, y1 + h1 / 2 - mm2dot(hmn) / 2, ct_name.to_s,   CELLTYPE_NAME, ALIGN_CENTER, TEXT_HORIZONTAL)
        end

        #----- draw port name -----#
        cell.get_cports.merge(cell.get_eports).each do |_name, port|
          if !port.array?
            set_port_color(port, cell)
            draw_port_name(port)
          else
            #--- prot array ---#
            port.get_ports.each do |pt|
              set_port_color pt, cell
              draw_port_name(pt)
            end
          end
        end

        canvas_gc_reset
      end

      #=== set_port_color
      def set_port_color(port, cell)
        if port.complete?
          if cell.editable?
            color_name = Color_editable
          else
            color_name = Color_uneditable
          end
        else
          if port.is_a?(TECSModel::TmCPort) && !port.is_optional?
            color_name = Color_incomplete
          else
            color_name = Color_unjoin
          end
        end
        # @canvas_gc.set_foreground @@colors[ color_name ]
        @cairo_context_target.set_source_color(@@colors[color_name])
      end

      def draw_entry_port_triangle(eport)
        triangle_1_2 = mm2dot(TRIANGLE_LEN / 2)
        triangle_hi  = mm2dot(TRIANGLE_HEIGHT)
        x1, y1 = eport.get_position
        xe = mm2dot(x1)
        ye = mm2dot(y1)
        case eport.get_edge_side
        when TECSModel::EDGE_TOP
          points = [[xe - triangle_1_2, ye], [xe + triangle_1_2, ye], [xe, ye + triangle_hi]]
        when TECSModel::EDGE_BOTTOM
          points = [[xe - triangle_1_2, ye], [xe + triangle_1_2, ye], [xe, ye - triangle_hi]]
        when TECSModel::EDGE_LEFT
          points = [[xe, ye - triangle_1_2], [xe, ye + triangle_1_2], [xe + triangle_hi, ye]]
        when TECSModel::EDGE_RIGHT
          points = [[xe, ye - triangle_1_2], [xe, ye + triangle_1_2], [xe - triangle_hi, ye]]
        end
        # fill = true
        # @draw_target.draw_polygon( @canvas_gc, fill, points )
        @cairo_context_target.triangle(*points[0], *points[1], *points[2])
        @cairo_context_target.fill
      end

      def draw_port_name(port)
        x1, y1 = port.get_position
        xp = mm2dot(x1)
        yp = mm2dot(y1)
        case port.get_edge_side
        when TECSModel::EDGE_TOP
          alignment = ALIGN_LEFT
          direction = TEXT_VERTICAL
        when TECSModel::EDGE_BOTTOM
          alignment = ALIGN_RIGHT
          direction = TEXT_VERTICAL
        when TECSModel::EDGE_LEFT
          alignment = ALIGN_RIGHT
          direction = TEXT_HORIZONTAL
        when TECSModel::EDGE_RIGHT
          xp += 2
          alignment = ALIGN_LEFT
          direction = TEXT_HORIZONTAL
        end
        name = port.get_name.to_s
        if port.get_subscript
          name += "[#{port.get_subscript}]"
        end
        name = port.get_name.to_s
        subscript = port.get_subscript
        if subscript
          if subscript >= 0
            name += "[#{subscript}]"
          end
        end
        draw_text(xp, yp, name, PORT_NAME, alignment, direction)
      end

      #=== TView#draw_hilite_objects
      def draw_hilite_objects(obj_list)
        obj_list.each do |obj|
          if obj.is_a?(TECSModel::TmCell)
            draw_cell_rect_direct(obj)
            # draw_target_direct
            # draw_cell(obj)
            # draw_target_reset
          elsif obj.is_a?(TECSModel::TmPort)
            draw_port_direct(obj)
          elsif obj.is_a?(TECSModel::TmJoinBar)
            draw_bar_direct(obj)
          end
        end
      end

      #=== TView#draw_cell_rect_direct
      # directly draw on Window hilited cell rect
      def draw_cell_rect_direct(cell)
        draw_target_direct

        #----- set line width -----#
        canvas_gc_set_line_width(2)
        # @cairo_context_target.set_line_width(2)

        #----- if uneditable change color ------#
        unless cell.editable?
          @canvas_gc.set_foreground(@@colors[Color_uneditable])
          # @cairo_context_target.set_source_color( @@colors[ Color_uneditable ] )
        end

        #----- calc position in dot -----#
        x, y, w, h = cell.get_geometry
        x1 = mm2dot(x)
        y1 = mm2dot(y)
        w1 = mm2dot(w)
        h1 = mm2dot(h)

        #----- draw cell rect -----#
        @gdk_window.draw_rectangle(@canvas_gc, false, x1, y1, w1, h1)
        # @cairo_context_target.rectangle(x1, y1, w1, h1)
        # @cairo_context_target.stroke

        #----- reset GC, line width -----#
        canvas_gc_reset
        canvas_gc_set_line_width(1)
        draw_target_reset
      end

      def draw_port_direct(port)
        draw_target_direct

        #----- set line width -----#
        @canvas_gc.set_foreground(@@colors[Color_highlight])
        # @cairo_context_target.set_source_color( @@colors[ Color_highlight ] )
        draw_port_name(port)

        if port.is_a?(TECSModel::TmEPort)
          draw_entry_port_triangle(port)
        end

        canvas_gc_set_line_width(2)
        x, y = port.get_position
        x1 = x2 = mm2dot(x)
        y1 = y2 = mm2dot(y)
        case port.get_edge_side
        when TECSModel::EDGE_TOP
          y1 -= 20
        when TECSModel::EDGE_BOTTOM
          y2 += 20
        when TECSModel::EDGE_LEFT
          x1 -= 20
        when TECSModel::EDGE_RIGHT
          x2 += 20
        end
        @gdk_window.draw_line(@canvas_gc, x1, y1, x2, y2)
        # @cairo_context_target.move_to( x1, y1 )
        # @cairo_context_target.line_to( x2, y2 )

        #----- reset GC, line width -----#
        canvas_gc_reset
        canvas_gc_set_line_width(1)

        draw_target_reset
      end

      def draw_join(join)
        cport, eport, bars = join.get_ports_bars
        x, y = cport.get_position
        xm = mm2dot(x) + 0.5
        ym = mm2dot(y) + 0.5

        #----- setup color -----#
        unless join.editable?
          # @canvas_gc.set_foreground @@colors[ Color_uneditable ]
          @cairo_context_target.set_source_color(@@colors[Color_uneditable])
        end

        @cairo_context_target.move_to(xm, ym)
        #----- draw bars -----#
        bars.each do |bar|
          if bar.horizontal?
            xm2 = mm2dot(bar.get_position) + 0.5
            # @draw_target.draw_line( @canvas_gc, xm, ym, xm2, ym )
            @cairo_context_target.line_to(xm2, ym)
            xm = xm2
          else # VBar
            ym2 = mm2dot(bar.get_position) + 0.5
            # @draw_target.draw_line( @canvas_gc, xm, ym, xm, ym2 )
            @cairo_context_target.line_to(xm, ym2)
            ym = ym2
          end
        end
        @cairo_context_target.set_line_width(1)
        @cairo_context_target.stroke

        #----- draw signature name -----#
        if eport.get_joins[0] == join
          # draw only 1st entry port join

          if (eport.get_subscript.nil? || eport.get_subscript == 0) &&
              (join.get_cport.get_subscript.nil? || join.get_cport.get_subscript == 0)

            if bars[2].vertical?
              xm = mm2dot((bars[1].get_position + bars[3].get_position) / 2)
              ym = mm2dot(bars[2].get_position + 2)
            else
              xm = mm2dot((bars[0].get_position + bars[2].get_position) / 2)
              ym = mm2dot(bars[1].get_position + 2)
            end
            draw_text(xm, ym, join.get_signature.get_name.to_s, SIGNATURE_NAME, ALIGN_CENTER, TEXT_HORIZONTAL)
          end
        end

        canvas_gc_reset
      end

      #=== TView#draw_bar_direct
      # directly draw on Window
      def draw_bar_direct(bar)
        draw_target_direct

        join = bar.get_join
        cport, eport, bars = join.get_ports_bars
        x, y = cport.get_position
        xm = mm2dot(x)
        ym = mm2dot(y)

        canvas_gc_set_line_width(2)

        bars.each do |bar2|
          if @control.highlighted_objects.include?(bar2)
            color = @@colors[Color_highlight]
          elsif join.editable?
            color = @@colors[Color_editable]
          else
            color = @@colors[Color_uneditable]
          end
          @canvas_gc.foreground = color
          @cairo_context_target.set_source_color(color)

          if bar2.horizontal?
            xm2 = mm2dot(bar2.get_position)
            @gdk_window.draw_line(@canvas_gc, xm, ym, xm2, ym)
            xm = xm2
          else # VBar
            ym2 = mm2dot(bar2.get_position)
            @gdk_window.draw_line(@canvas_gc, xm, ym, xm, ym2)
            ym = ym2
          end
        end

        canvas_gc_set_line_width(1)
        canvas_gc_reset

        draw_target_reset
      end

      #----- draw and utility for text  -----#

      def get_text_extent(text, obj_type, alignment, direction)
        pc = @pango_context
        plo = @pango_layout
        if direction != TEXT_VERTICAL
          pc.matrix = nil
          plo.text = text.to_s
          pfd = pc.font_description
          pfd.absolute_size = font_size(obj_type)
          plo.font_description = pfd
          plo.alignment = alignment
          # plo.context_changed          # ??
          # rect2 = plo.get_pixel_extents[1]
          # return [ dot2mm(rect2.rbearing), dot2mm(rect2.descent) ]
          rect2 = plo.pixel_extents[1]
          [dot2mm(rect2.x + rect2.width), dot2mm(rect2.y + rect2.height)]
        else
          pm = @pango_matrix
          pc.matrix = pm
          plo.text = text.to_s
          pfd = pc.font_description
          pfd.absolute_size = font_size(obj_type)
          plo.font_description = pfd
          plo.alignment = alignment
          # plo.context_changed
          rect2 = plo.get_pixel_extents[1]
          [dot2mm(rect2.descent), dot2mm(rect2.rbearing)]
        end
      end

      # x::Integer(dot)
      # y::Integer(dot)
      # obj_type::CELL_NAME, SIGNATURE_NAME, PORT_NAME
      # alignment::ALIGN_CENTER, ALIGN_LEFT
      def draw_text(x, y, text, obj_type, alignment, direction)
        if direction == TEXT_VERTICAL
          draw_text_v(x, y, text, obj_type, alignment)
        else
          draw_text_h(x, y, text, obj_type, alignment)
        end
      end

      def draw_text_h(x, y, text, obj_type, alignment)
        # draw_text_h_gdk( x, y, text, obj_type, alignment )
        draw_text_h_cairo(x, y, text, obj_type, alignment)
        # draw_text_h_cairo_pango( x, y, text, obj_type, alignment )
      end

      def draw_text_h_gdk(x, y, text, obj_type, alignment)
        #----- Gdk Pango version -----#
        pc = @pango_context
        plo = @pango_layout
        pc.matrix = nil
        plo.text = text
        pfd = pc.font_description
        pfd.absolute_size = font_size(obj_type)
        plo.font_description = pfd
        plo.alignment = alignment
        # plo.context_changed          # ??
        rect2 = plo.get_pixel_extents[1]

        case alignment
        when ALIGN_CENTER
          # calc text draww postion
          x2 = x - rect2.rbearing / 2
          y2 = y - rect2.descent / 2
        when ALIGN_RIGHT
          x2 = x - rect2.rbearing - mm2dot(GAP_PORT)
          y2 = y - rect2.descent
        when ALIGN_LEFT
          x2 = x + mm2dot(GAP_PORT)
          y2 = y - rect2.descent
        end

        # pfd =  Pango::FontDescription.new
        # p pfd.size, pfd.variant, pfd.family
        # rect = plo.get_pixel_extents[0]
        # p rect.ascent, rect.descent, rect.lbearing, rect.rbearing
        # p rect2.ascent, rect2.descent, rect2.lbearing, rect2.rbearing

        @draw_target.draw_layout(@canvas_gc, x2, y2, plo)
      end

      #----- Cairo version -----#
      def draw_text_h_cairo(x, y, text, obj_type, alignment)
        cr = @cairo_context_target
        cr.select_font_face(font_family = nil, # "courier", # font_family = "Times New Roman",
                            font_slant  = Cairo::FONT_SLANT_NORMAL,
                            font_weight = Cairo::FONT_WEIGHT_NORMAL)
        cr.set_font_size(font_size(obj_type) / 1000)
        cr_te = cr.text_extents(text)
        # p "width=#{cr_te.width} x_bearing=#{cr_te.x_bearing} height=#{cr_te.height} y_bearing=#{cr_te.y_bearing}"
        case alignment
        when ALIGN_CENTER
          # calc text draww postion
          x2 = x - (cr_te.width + cr_te.x_bearing) / 2
          y2 = y - cr_te.y_bearing / 2
        when ALIGN_RIGHT
          x2 = x - cr_te.width - cr_te.x_bearing - mm2dot(GAP_PORT)
          y2 = y - cr_te.height - cr_te.y_bearing - 2
        when ALIGN_LEFT
          x2 = x + mm2dot(GAP_PORT)
          y2 = y - cr_te.height - cr_te.y_bearing - 2
        end
        cr.move_to(x2, y2)
        cr.show_text(text)
      end

      #----- Cairo Pango version -----#
      def draw_text_h_cairo_pango(x, y, text, obj_type, alignment)
        cr = @cairo_context_target
        # pfd = Pango::FontDescription.new( "Times" )
        pfd = Pango::FontDescription.new
        pfd.absolute_size = font_size(obj_type)
        plo = cr.create_pango_layout
        plo.font_description = pfd
        plo.alignment = alignment
        plo.set_text(text)
        rect2 = plo.get_pixel_extents[1]

        case alignment
        when ALIGN_CENTER
          # calc text draww postion
          x2 = x - rect2.rbearing / 2
          y2 = y - rect2.descent / 2
        when ALIGN_RIGHT
          x2 = x - rect2.rbearing - mm2dot(GAP_PORT)
          y2 = y - rect2.descent
        when ALIGN_LEFT
          x2 = x + mm2dot(GAP_PORT)
          y2 = y - rect2.descent
        end
        cr.move_to(x2, y2)
        cr.show_pango_layout(plo)
      end

      # x::Integer(dot)
      # y::Integer(dot)
      # obj_type::CELL_NAME, SIGNATURE_NAME, PORT_NAME
      # alignment::ALIGN_CENTER, ALIGN_LEFT
      def draw_text_v(x, y, text, obj_type, alignment)
        # draw_text_v_gdk( x, y, text, obj_type, alignment )
        draw_text_v_cairo(x, y, text, obj_type, alignment)
        # draw_text_v_cairo_pango( x, y, text, obj_type, alignment )
      end

      #----- Gdk Pango version -----#
      def draw_text_v_gdk(x, y, text, obj_type, alignment)
        pc = @pango_context
        plo = @pango_layout
        pm = @pango_matrix
        pc.matrix = pm
        plo.text = text
        pfd = pc.font_description
        pfd.absolute_size = font_size(obj_type)
        plo.font_description = pfd
        plo.alignment = alignment
        # plo.context_changed
        rect2 = plo.get_pixel_extents[1]

        case alignment
        when ALIGN_CENTER
          # calc text draww postion
          x2 = x - rect2.descent / 2
          y2 = y - rect2.rbearing / 2
        when ALIGN_RIGHT
          x2 = x - rect2.descent
          y2 = y + mm2dot(GAP_PORT)
        when ALIGN_LEFT
          x2 = x - rect2.descent
          y2 = y - rect2.rbearing - mm2dot(GAP_PORT)
        end

        @draw_target.draw_layout(@canvas_gc, x2, y2, plo)
      end

      #----- Cairo version -----#
      def draw_text_v_cairo(x, y, text, obj_type, alignment)
        cr = @cairo_context_target
        cr.select_font_face(font_family = nil, # "courier", # font_family = "Times New Roman",
                            font_slant  = Cairo::FONT_SLANT_NORMAL,
                            font_weight = Cairo::FONT_WEIGHT_NORMAL)
        cr.set_font_size(font_size(obj_type) / 1000)
        cr_te = cr.text_extents(text)
        # p "width=#{cr_te.width} x_bearing=#{cr_te.x_bearing} height=#{cr_te.height} y_bearing=#{cr_te.y_bearing}"
        case alignment
        when ALIGN_CENTER # this case is not used & not checked
          # calc text draww postion
          x2 = x - 2
          y2 = y - (cr_te.width + cr_te.x_bearing) / 2
        when ALIGN_RIGHT
          x2 = x - 2
          y2 = y + cr_te.width + cr_te.x_bearing + mm2dot(GAP_PORT)
        when ALIGN_LEFT
          x2 = x - 2
          y2 = y - mm2dot(GAP_PORT)
        end
        @cairo_matrix.set_rotate90(x2, y2) # rotate around (0, 0) then shift (x2, y2)
        cr.matrix = @cairo_matrix
        cr.move_to(0, 0) # this assumes that (0, 0) is left bottom of strings
        cr.show_text(text)
        @cairo_matrix.set_rotate0
        cr.matrix = @cairo_matrix
      end

      #----- Cairo Pango version -----#
      def draw_text_v_cairo_pango(x, y, text, obj_type, alignment)
        cr = @cairo_context_target
        # pfd = Pango::FontDescription.new( "Times" )
        pfd = Pango::FontDescription.new
        pfd.absolute_size = font_size(obj_type)
        # p "font_size=#{font_size( obj_type )}"
        plo = cr.create_pango_layout
        plo.font_description = pfd
        plo.alignment = alignment
        plo.set_text(text)
        rect2 = plo.get_pixel_extents[1]
        # p "descent=#{rect2.descent}, rbearing=#{rect2.rbearing}"

        case alignment
        when ALIGN_CENTER
          # calc text draww postion
          x2 = x - rect2.descent / 2
          y2 = y - rect2.rbearing / 2
        when ALIGN_RIGHT
          x2 = x
          y2 = y + rect2.rbearing + mm2dot(GAP_PORT)
        when ALIGN_LEFT
          x2 = x
          y2 = y - mm2dot(GAP_PORT)
        end

        matrix = Cairo::Matrix.new(0, -1, 1, 0, x2, y2)
        cr.matrix = matrix
        cr.move_to(0, 0) # this assumes that (0, 0) is left bottom of strings
        cr.show_text(text)
        cr.matrix = Cairo::Matrix.new(1, 0, 0, 1, 0, 0)
      end

      #---------- Cell name editor ---------#
      def create_edit_window
        @entry = Gtk::Entry.new
        @entry.set_has_frame(true)

        @entry_win = Gtk::Window.new(Gtk::Window::TOPLEVEL)
        @entry_win.add(@entry)
        @entry_win.realize
        @entry_win.window.reparent(@canvas.window, 0, 0) # Gdk level operation

        # these steps are to avoid to move ( 0, 0 ) at 1st appear
        @entry_win.show_all
        @entry_win.hide
      end

      def begin_edit_name(cell, time)
        @entry.set_text(cell.get_name)

        x, y, w, h = get_cell_name_edit_area(cell)
        # p "x=#{x} y=#{y} w=#{w} h=#{h}"
        @entry_win.window.move(x - 3, y - 6)    # Gdk level operation
        @entry_win.window.resize(w + 6, h + 8)  # Gdk level operation
        @entry_win.show_all
      end

      def end_edit_name
        name = @entry.text
        @entry_win.hide
        name
      end

      def get_cell_name_edit_area(cell)
        name = cell.get_name
        obj_type = CELL_NAME
        alignment = ALIGN_CENTER
        direction = TEXT_HORIZONTAL
        wmn, hmn = get_text_extent(name, obj_type, alignment, direction)
        xm, ym, wm, hm = cell.get_geometry
        x = mm2dot(xm + (wm - wmn) / 2)
        y = mm2dot(ym + hm / 2 + 1)
        # y = mm2dot( ym + hm / 2 - hmn )
        w = mm2dot(wmn)
        h = mm2dot(hmn)

        [x, y, w, h]
      end

      #------ Convert Unit  ------#

      #=== convert mm to dot
      def mm2dot(mm)
        (@scale_val * mm * DPI / 25.4 / 100).to_i
      end

      #=== convert dot to mm
      def dot2mm(dot)
        dot * 100 * 25.4 / DPI / @scale_val
      end

      #=== font_size
      # obj_type::Integer CELL_NAME, SIGNATURE_NAME, PORT_NAME
      def font_size(obj_type)
        case obj_type
        when CELL_NAME
          base_size = 10500
        when CELLTYPE_NAME
          base_size = 10500
        when CELL_NAME_L
          base_size = 16000
        when SIGNATURE_NAME
          base_size = 9000
        when PORT_NAME
          base_size = 9000
        when PAPER_COMMENT
          base_size = 10500
        end
        base_size * @scale_val / 100.0 * DPI / 96.0
      end

      #------ handle CanvasGC  ------#
      def canvas_gc_reset
        @canvas_gc.function = Gdk::GC::COPY
        @canvas_gc.fill = Gdk::GC::SOLID
        @canvas_gc.foreground = @@colors[Color_editable]

        @cairo_context_target.restore
        @cairo_context_target.save # prepare for next time
        @cairo_context_target.matrix = @cairo_matrix
      end

      def canvas_gc_set_line_width(width)
        line_attr = @canvas_gc.line_attributes
        line_width = line_attr[0]
        line_attr[0] = width
        @canvas_gc.set_line_attributes(*line_attr)
      end

      def self.setup_colormap
        if !@@colors.nil?
          return
        end

        @@colors = {}
        @@colormap = Gdk::Colormap.system

        [
          :black, :white, :gray, :yellow, :orange, :skyblue, :magenta, :red, :blue, :green,
          :cyan, :brown, :violet, :lavender, :MistyRose, :lightyellow, :LightCyan, :Beige,
          :PapayaWhip, :Violet, :pink
        ].each do |color_name|
          setup_colormap_1 color_name
        end
        setup_colormap_2(:ultraLightGreen, Gdk::Color.new(0xE000, 0xFF00, 0xE000))
        setup_colormap_1(Color_editable_cell)

        @@cell_paint_colors = [
          :MistyRose, :lightyellow, :LightCyan, :ultraLightGreen, :lavender, :Beige,
          :PapayaWhip, :Violet, :pink
        ]
        # plum: light purble (pastel)
        # pink: light magenta (pastel)
        # lavender: light blue (pastel)
        # lightyellow: light yellow (pastel)
        @@cell_paint_color_index = 0
        @@cell_file_to_color = {}
      end

      def self.setup_colormap_1(name)
        color = Gdk::Color.parse(name.to_s)
        setup_colormap_2(name, color)
      end

      def self.setup_colormap_2(name, color)
        @@colors[name] = color
        @@colormap.alloc_color(color, false, true)
      end

      #----- cell paint colors -----#

      def get_cell_paint_color(cell)
        if @b_color_by_region
          region = cell.get_region
          color = @@cell_file_to_color[region]
          if color
            return color
          end
          obj = region
        else
          tecsgen_cell = cell.get_tecsgen_cell
          if tecsgen_cell.nil? || cell.editable?
            return @@colors[Color_editable_cell]
          end
          file = tecsgen_cell.get_locale[0]
          color = @@cell_file_to_color[file]
          if color
            return color
          end
          obj = file
        end
        if @@cell_paint_color_index >= @@cell_paint_colors.length
          @@cell_paint_color_index = 0
        end
        col_name = @@cell_paint_colors[@@cell_paint_color_index]
        @@cell_file_to_color[obj] = @@colors[col_name]
        @@cell_paint_color_index += 1
        # p "col_name:#{col_name} index:#{@@cell_paint_color_index}"
        @@colors[col_name]
      end

      #------ export ------#
      def export(fname)
        begin
          if File.exist?(fname)
            File.unlink(fname)
          end
        rescue => evar
          TECSCDE.message_box("fail to remove #{fname}\n#{evar}", :OK)
          return
        end

        scale_val_bak = @scale_val
        @scale_val = 72.0 / TECSCDE::DPI * 100 # PDF surface = 72 DPI,  mm2dot assume 100 DPI by default
        target_bak = @cairo_context_target

        paper = @model.paper.cairo_paper_class
        paper_width = paper.width("pt") - mm2dot(PAPER_MARGIN * 2)
        paper_height = paper.height("pt") - mm2dot(PAPER_MARGIN * 2)
        begin
          surface = Cairo::PDFSurface.new(fname, paper.width("pt"), paper.height("pt"))
          @cairo_context_target = Cairo::Context.new(surface)

          #----- set paper margin -----#
          @cairo_matrix.set_base_shift(mm2dot(PAPER_MARGIN), mm2dot(PAPER_MARGIN))
          @cairo_context_target.matrix = @cairo_matrix

          #----- clip in rectangle frame -----#
          @cairo_context_target.rectangle(0, 0, paper_width, paper_height)
          @cairo_context_target.clip(false) # preserve = false
          @cairo_context_target.save # (* pair *)   # must be saved initially

          #----- draw contents of PDF -----#
          paint_canvas

          #----- draw model name -----#
          draw_text(paper_width, paper_height, @model.get_file_editing, PAPER_COMMENT, ALIGN_RIGHT, TEXT_HORIZONTAL)

          #----- draw rectangle frame around paper -----#
          @cairo_context_target.rectangle(0, 0, paper_width, paper_height)
          @cairo_context_target.stroke

          #----- complete PDF file -----#
          surface.finish

          #----- reset context -----#
          # cairo_context_target: unnecessary because the context is abandoned after this
          # @cairo_matrix.set_base_shift( 0, 0 )
          # @cairo_context_target.matrix = @cairo_matrix
          # @cairo_context_target.restore   # (* pair *)
        rescue => evar
          TECSCDE.logger.error(evar)
          TECSCDE.message_box("fail to writ to #{fname}\n#{evar}", :OK)
        ensure
          @cairo_context_target = target_bak
          @cairo_matrix.set_base_shift(0, 0)
          @scale_val = scale_val_bak
          surface&.finish
        end

        paint_canvas
      end

      #=== MainView#div_string
      # divide string near center at A-Z or '_'
      def div_string(str)
        len = str.length
        if len <= 4
          return [str, ""]
        end

        center = len / 2
        i = 0
        n = 0
        while (center / 2 > i) && (i < center) && (str[center + i] != nil)
          char_i = str[center - i]
          char_j = str[center + i]
          if char_j == CHAR__ || (CHAR_A <= char_j && char_j <= CHAR_Z)
            n = center + i
            break
          elsif CHAR_A <= char_i && char_i <= CHAR_Z
            n = center - i
            break
          elsif char_i == CHAR__
            n = center - i + 1
            break
          end
          i += 1
        end
        if n > 0
          return [str[0, n], str[n, len]]
        else
          return [str[0, len / 2], str[len / 2, len]]
        end
      end
    end
  end
end
