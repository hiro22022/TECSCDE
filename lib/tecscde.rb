require "gtk2"

require "tecscde/version"
require "tecscde/main_view_and_model"

module TECSCDE
  class Error < StandardError; end

  #=== TECSCDE.message_box
  # Function to open a dialog box displaying the message provided.
  # ok_yn_okcan::
  # RETURN
  def self.message_box(message, ok_yn_okcan)
    dialog = Gtk::Dialog.new("Message",
                             nil,
                             nil,
                             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK])

    dialog.vbox.add(Gtk::Label.new(message))
    dialog.show_all

    res = nil
    dialog.run do |response|
      res = response
    end
    dialog.destroy
    res
  end

  def self.confirm?(message, parent = nil)
    dialog = Gtk::Dialog.new(
      "Confirm",
      parent,
      Gtk::Dialog::Flags::MODAL | Gtk::Dialog::Flags::DESTROY_WITH_PARENT,
      [Gtk::Stock::OK, Gtk::ResponseType::OK],
      [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL]
    )
    dialog.vbox.add(Gtk::Label.new(message))
    dialog.show_all
    response = dialog.run
    dialog.destroy
    response == Gtk::ResponseType::OK
  end

  def self.quit(model, parent = nil)
    if model.modified?
      if TECSCDE.confirm?("変更を保存せずに終了しますか？")
        Gtk.main_quit
      end
    else
      Gtk.main_quit
    end
  end

  def self.main(tecsgen)
    MainViewAndModel.new(tecsgen)
    Gtk.main
  end

  def self.test
    MainViewAndModel.new.test_main
  end
end

require "tecscde/logger"
