module TECSCDE
  #==ChangeSetControl: provide methods for controling ChangeSet
  module ChangeSetControl
    #----- ChangeSetControl methods -----#
    def init_change_set
      @change_set_manager = TECSCDE::ChangeSetControl::ChangeSetManager.new
    end

    #=== ChangeSetControl#add_change_set
    # at the time modifying tm_object, record only the changed tm_object
    def add_change_set(tm_object)
      # flush_print "add_change_set #{tm_object.class} change_set=#{@change_no}\n"
      @change_set_manager.add_change_set tm_object
    end

    def set_undo_point
      @change_set_manager.set_undo_point
    end

    def undo
      @change_set_manager.undo
    end

    def redo
      @change_set_manager.redo
    end

    def modified?
      @change_set_manager.modified?
    end
  end
end

require "tecscde/change_set_control/change_set"
require "tecscde/change_set_control/change_set_manager"
