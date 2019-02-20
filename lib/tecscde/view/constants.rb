require "gtk2"

module TECSCDE
  module View
    module Constants
      DPI = 96.0                                  # Dot per Inch
      # DPI = 72.0                                # Dot per Inch

      ScaleHeight = 50                            # Height of HScale widget

      Scale = 1.0                                 # Scale initial value
      ScaleValIni = Scale * 100                   # 100%
      ScaleValMax = ScaleValIni * 2.00            # 200%
      ScaleValMin = ScaleValIni * 0.05            #   5%

      Triangle_Len     = 3                        # edge length(mm)
      Triangle_Height  = 2.598                    # height (mm)

      #----- draw text argment value -----#
      # object
      CELL_NAME         = 1
      CELLTYPE_NAME     = 2
      CELL_NAME_L       = 3
      SIGNATURE_NAME    = 4
      PORT_NAME         = 5
      PAPER_COMMENT     = 6

      # text alignment
      ALIGN_CENTER      = Pango::Layout::ALIGN_CENTER
      ALIGN_LEFT        = Pango::Layout::ALIGN_LEFT
      ALIGN_RIGHT       = Pango::Layout::ALIGN_RIGHT

      # text direction
      TEXT_HORIZONTAL   = 1   # left to right
      TEXT_VERTICAL     = 2   # bottom to top

      #----- Cursor for mouse pointer -----#
      CURSOR_PORT       = Gdk::Cursor.new Gdk::Cursor::SB_LEFT_ARROW
      CURSOR_JOINING    = Gdk::Cursor.new Gdk::Cursor::DOT
      CURSOR_JOIN_OK    = Gdk::Cursor.new Gdk::Cursor::CIRCLE
      CURSOR_NORMAL     = Gdk::Cursor.new Gdk::Cursor::TOP_LEFT_ARROW

      GapActive         = 1   # (mm)  gap of active cell between inner rectangle and outer one
      GapPort           = 0.8 # (mm)  gap between port name & edge

      #----- Paper -----#
      PAPER_MARGIN = 10 # (mm)

      #----- constnts for div_string -----#
      Char_A = "A"[0]
      Char_Z = "Z"[0]
      Char__ = "_"[0]

      #----- Color -----#
      Color_editable_cell = :gray97
      Color_uneditable    = :blue
      Color_editable      = :black
      Color_hilite        = :magenta
      Color_incomplete    = :red
      Color_unjoin        = :magenta
      # color names are found in setup_colormap
    end
  end

  include TECSCDE::View::Constants
end
