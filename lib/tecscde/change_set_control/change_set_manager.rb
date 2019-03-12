module TECSCDE
  module ChangeSetControl
    #== ChangeSetMangager class
    # contain all changes & execute undo
    class ChangeSetManager
      def initialize
        @change_no = 0
        @change_set_list = []
        @change_set_next = ChangeSet.new(@change_no)
      end

      #=== ChangeSetManager#add_change_set
      # at the time modifying tm_object, record only the changed tm_object
      def add_change_set(tm_object)
        # TECSCDE.logger.info("add_change_set #{tm_object.class} change_set=#{@change_no}")
        @change_set_next.add(tm_object)
      end

      def set_undo_point
        count = @change_set_next.set_undo_point
        if count > 0
          # TECSCDE.logger.info("* set_undo_point change_no=#{@change_no}, count=#{count}")
          # p "* set_undo_point change_no=#{@change_no}, count=#{count}\n"
          @change_set_list[@change_no] = @change_set_next
          @change_no += 1
          @change_set_next = ChangeSet.new(@change_no)

          if @change_set_list.length > @change_no
            TECSCDE.logger.info("truncate undo buffer #{@change_set_list.length} to #{@change_no}")
            # print( "range: #{(@change_no)..(@change_set_list.length)-1}\n" )
            # p "length0=#{@change_set_list.length}"
            @change_set_list.slice!(@change_no..(@change_set_list.length - 1))
            # p "length1=#{@change_set_list.length}"
          end
        else
          TECSCDE.logger.info("* set_undo_point: nothing changed")
        end
      end

      # assumed undo is done just after set_undo_point (this means @change_set_next has no contents)
      def undo
        return unless modified?
        @change_no -= 1
        TECSCDE.logger.info("* undo change_no=#{@change_no}")
        @change_set_list[@change_no].apply
        # TECSCDE.logger.info("* undo1 change_no=#{@change_no}")
        @change_set_next = ChangeSet.new(@change_no)
      end

      def redo
        return if @change_set_list.length <= @change_no + 1
        @change_no += 1
        TECSCDE.logger.info("* redo change_no=#{@change_no}")
        @change_set_list[@change_no].apply
      end

      def modified?
        @change_no > 1
      end
    end
  end
end
