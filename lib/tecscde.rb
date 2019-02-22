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
    # p "message_box #{message}"

    # Create the dialog
    dialog = Gtk::Dialog.new("Message",
                             nil,
                             nil,
                             [Gtk::Stock::OK, Gtk::Dialog::RESPONSE_OK])

    # Ensure that the dialog box is destroyed when the user responds.
    # dialog.signal_connect('response') { dialog.destroy }

    # Add the message in a label, and show everything we've added to the dialog.
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
      [Gtk::Stock::CANCEL, Gtk::ResponseType::CANCEL])
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
    begin
      aSet = MainViewAndModel.new tecsgen
      # aSet.test_main
      Gtk.main
      # rescue Exception => evar
      #  p "exception caught"
      # ensure
    end
  end

  def self.test
    begin
      aSet = MainViewAndModel.new
      aSet.test_main
      # rescue Exception => evar
      #  p "exception caught"
      # ensure
    end
  end
end

require "tecscde/logger"
