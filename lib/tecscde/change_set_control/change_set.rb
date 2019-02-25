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
          # TECSCDE.logger.info("add_change_set #{tm_object.class} number=#{@number}")
          @set[tm_object] = tm_object.clone_for_undo
        end
      end

      def set_undo_point
        count = @set.length
        TECSCDE.logger.info("* set_undo_point number=#{@number}, count=#{count}")
        count
      end

      def apply
        TECSCDE.logger.debug("applying change_no=#{@number}")
        @set.each_key{|tm_object|
          tm_object.copy_from(@set[tm_object])
          TECSCDE.logger.debug("apply #{tm_object.class}")
        }
      end
    end
  end
end
