module TECSCDE
  class TECSModel
    # class must be descendant of Node
    module TmUneditable
      # @b_editable::Bool | Nil:  objects from .cdl cannot be editable  (used by TmJoin, TmCell)

      #=== TmObject#set_editable
      # locale:: see Node in syntaxobj.rb
      def set_editable(locale)
        if locale[0] == get_model.get_file_editing
          @b_editable = true
        else
          @b_editable = false
        end
      end

      #=== TmObject#is_editable?  ***
      def is_editable?
        @b_editable
      end
    end
  end
end
