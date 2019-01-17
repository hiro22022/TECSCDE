require "gtk2"
require "tecscde/tmodel"

module TECSCDE
  class Preferences

    attr_accessor :selected_paper

    def initialize(control)
      @control = control
      @builder = Gtk::Builder.new
      @builder.add_from_file(File.join(__dir__, "preferences.glade"))
      @selected_paper = nil
      @changed = false
      setup
    end

    def setup
      setup_combo_box
    end

    def setup_combo_box
      combo = @builder["paper-size"]
      combo.signal_connect("changed") do
        @selected_paper = combo.active_text
        @changed = true
      end
      combo.active = @control.preferences[:paper].index
    end

    def run
      dialog = @builder["preferences"]
      response = dialog.run
      if response == Gtk::ResponseType::APPLY
        apply
      end
      dialog.destroy
    end

    def apply
      @control.change_preferences(paper: @selected_paper)
    end
  end
end
