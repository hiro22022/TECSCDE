module TECSCDE
  module ChangeSetControl
    #== ChangeSet class
    # record each change (change by user's operation)
    class ChangeSet
      def initialize(number)
        @set = {}
        @number = number
      end

      def add(tm_object)
        if !@set.has_key?(tm_object)
          # flush_print "add_change_set #{tm_object.class} number=#{@number}\n"
          @set[tm_object] = tm_object.clone_for_undo
        end
      end

      def set_undo_point
        count = @set.length
        flush_print "* set_undo_point number=#{@number}, count=#{count}\n"
        return count
      end

      def apply
        # print "applying change_no=#{@number}\n"
        dbgPrint "applying change_no=#{@number}\n"
        @set.each_key{|tm_object|
          tm_object.copy_from @set[tm_object]
          dbgPrint "apply #{tm_object.class}\n"
        }
      end
    end
  end
end
