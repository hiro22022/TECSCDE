module TECSCDE
  class TECSModel
    class TmEPort < TmPort # mikan ep array
      # @joins::[TmJoin]

      def initialize(owner, port_def, subscript = nil)
        @owner = owner
        @port_def = port_def
        @subscript = subscript

        @joins = []
        @edge_side, @offs = get_cell.get_new_eport_position port_def
        modified {}
      end

      def moved(x_inc, y_inc)
        @joins.each{|join|
          join.moved_eport(x_inc, y_inc)
        }
      end

      def add_join(join)
        modified {

          @joins << join
        }
      end

      #=== TmEPort#include?
      # TmEPort can have plural of joins.
      # test if TmEPort has specified join.
      def include?(join)
        @joins.include? join
      end

      #=== TmEPort#get_joins
      def get_joins
        @joins
      end

      #=== TmEPort#delete
      # this method is called from TmCell
      def delete
        modified {

          joins = @joins.dup # in join.edelete delete_join is called and change @joins
          joins.each{|join|
            join.delete
          }
        }
      end

      #=== TmEPort#delete_join
      # this method is called from TmJoin
      def delete_join(join)
        modified {
          @joins.delete join
        }
      end

      #=== TmEPort#complete?
      def complete?
        (@joins.length > 0) ? true : false
      end

      #=== TmEPort#clone_for_undo
      def clone_for_undo
        bu = clone
        bu.copy_from self
        return bu
      end

      def setup_clone(joins)
        @joins = joins.dup
      end
    end
  end
end
