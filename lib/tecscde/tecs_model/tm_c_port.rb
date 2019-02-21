require "tecscde/tecs_model/tm_port"

module TECSCDE
  class TECSModel
    class TmCPort < TECSCDE::TECSModel::TmPort # mikan cp array
      # @join::TmJoin

      def initialize(owner, port_def, subscript = nil)
        # p "port_def::#{port_def.get_name}  #{port_def.class}"
        @port_def = port_def
        @owner = owner
        @join = nil
        @subscript = subscript
        # p "subscript=#{subscript}"

        @name = "cCport" # temporal
        @edge_side, @offs = get_cell.get_new_cport_position port_def
        modified {}
      end

      def set_join(join)
        modified {

          @join = join
        }
      end

      def moved(x_inc, y_inc)
        if @join
          @join.moved_cport(x_inc, y_inc)
        end
      end

      def get_join(subscript = nil)
        @join
      end

      #=== TmCPort#delete
      # this method is called from TmCell
      def delete
        if @join
          modified {

            @join.delete
            @join = nil
          }
        end
      end

      #=== TmCPort#delete_join
      # this method is called from TmJoin
      def delete_join
        modified {

          @join = nil
        }
      end

      #=== TmCPort#complete?
      def complete?
        @join ? true : false
      end

      #=== TmCPort#is_optional?
      def is_optional?
        @port_def.is_optional?
      end

      #=== TmCPort#clone_for_undo
      def clone_for_undo
        bu = clone
        bu.copy_from self
        return bu
      end
    end
  end
end
