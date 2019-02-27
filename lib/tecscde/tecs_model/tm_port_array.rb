#
# TECSCDE - TECS Component Diagram Editor
#
# Copyright (C) 2014-2019 by TOPPERS Project
#
#  The above copyright holders grant permission gratis to use,
#  duplicate, modify, or redistribute (hereafter called use) this
#  software (including the one made by modifying this software),
#  provided that the following four conditions (1) through (4) are
#  satisfied.
#
#  (1) When this software is used in the form of source code, the above
#      copyright notice, this use conditions, and the disclaimer shown
#      below must be retained in the source code without modification.
#
#  (2) When this software is redistributed in the forms usable for the
#      development of other software, such as in library form, the above
#      copyright notice, this use conditions, and the disclaimer shown
#      below must be shown without modification in the document provided
#      with the redistributed software, such as the user manual.
#
#  (3) When this software is redistributed in the forms unusable for the
#      development of other software, such as the case when the software
#      is embedded in a piece of equipment, either of the following two
#      conditions must be satisfied:
#
#    (a) The above copyright notice, this use conditions, and the
#        disclaimer shown below must be shown without modification in
#        the document provided with the redistributed software, such as
#        the user manual.
#
#    (b) How the software is to be redistributed must be reported to the
#        TOPPERS Project according to the procedure described
#        separately.
#
#  (4) The above copyright holders and the TOPPERS Project are exempt
#      from responsibility for any type of damage directly or indirectly
#      caused from the use of this software and are indemnified by any
#      users or end users of this software from any and all causes of
#      action whatsoever.
#
#  THIS SOFTWARE IS PROVIDED "AS IS." THE ABOVE COPYRIGHT HOLDERS AND
#  THE TOPPERS PROJECT DISCLAIM ANY EXPRESS OR IMPLIED WARRANTIES,
#  INCLUDING, BUT NOT LIMITED TO, ITS APPLICABILITY TO A PARTICULAR
#  PURPOSE. IN NO EVENT SHALL THE ABOVE COPYRIGHT HOLDERS AND THE
#  TOPPERS PROJECT BE LIABLE FOR ANY TYPE OF DAMAGE DIRECTLY OR
#  INDIRECTLY CAUSED FROM THE USE OF THIS SOFTWARE.
#

require "tecscde/tecs_model/tm_port_array"

module TECSCDE
  class TECSModel
    class TmPortArray < TECSCDE::TmObject
      # @ports::[TmPort]
      # @port_def::Port
      # @actual_size::Integer
      # @subscript1::subscript value of 1st element. to check consistency of subscript

      def get_actual_size
        @actual_size
      end

      # TmPortArray#get_port_for_new_join
      # this method is for load
      def get_port_for_new_join(subscript)
        if @subscript1.nil?
          # 1st element of this entry array
          @subscript1 = subscript
        elsif (@subscript1 >= 0 && subscript < 0) || (@subscript1 < 0 && subscript >= 0)
          TECSCDE.logger.error("TM9999 array subscript inconsistent (similar error to S1128)")
          return nil
        end

        modified do
          # p "new_join: for name:#{@port_def.get_name}[ #{subscript} ] owner:#{@owner.get_name}, len=#{@ports.length}"
          if subscript >= 0
            if subscript >= @actual_size

              # in case of unsized array, extend array
              if @port_def.get_array_size == "[]"
                # extend array size
                (0..subscript).each do |subsc|
                  if @ports[subsc].nil?
                    port = new_port subsc
                    @ports[subsc] = port
                  end
                end
                @actual_size = @ports.length
                # p "new_join: 1 for name:#{@port_def.get_name}[ #{subscript} ] owner:#{@owner.get_name}, len=#{@ports.length}"
                return @ports[subscript]
              end

              TECSCDE.logger.error("#{@owner.get_name}.#{@port_def.get_name}[#{subscript}]: subscript=#{subscript} out of range(0..(#{@actual_size - 1})")
              return nil
            else
              port = @ports[subscript]
              # p "new_join: 2 for name:#{@port_def.get_name}[ #{subscript} ] owner:#{@owner.get_name}, len=#{@ports.length}"
              if self.instance_of?(TECSCDE::TECSModel::TmCPortArray) # CPort cannot have multiple join
                if port.get_join
                  TECSCDE.logger.error("#{@owner.get_name}.#{@port_def.get_name}[#{subscript}]: duplicate join")
                  return nil
                end
              end
              return port
            end
          else # no index
            found = false
            found_port = nil
            @ports.each do |port|
              if port.get_join.nil?
                found = true
                found_port = port
                break
              end
            end
            if found
              return found_port
            end

            # in case of unsized array, extend array
            if @port_def.get_array_size == "[]"
              port = new_port @ports.length
              @ports << port
              @actual_size = @ports.length
              return port
            end
          end
          return nil
        end
      end

      #=== TmPortArray#get_ports
      def get_ports
        @ports
      end

      #=== TmPortArray#get_near_port
      def get_near_port(x, y)
        @ports.each do |port|
          xp, yp = port.get_position
          # p "get_near_port x=#{x} y=#{y} xp=#{xp} yp=#{yp}"
          if ((xp - x).abs < NEAR_DIST) && ((yp - y).abs < NEAR_DIST)
            # p "near port: found"
            return port
          end
        end
        nil
      end

      #=== TmPortArray#array?
      def array?
        true
      end

      def moved_edge(x_inc_l, x_inc_r, y_inc_t, y_inc_b)
        @ports.each do |port|
          port.moved_edge(x_inc_l, x_inc_r, y_inc_t, y_inc_b)
        end
      end

      def moved(x_inc, y_inc)
        @ports.each do |port|
          port.moved(x_inc, y_inc)
        end
      end

      def get_member(subscript)
        if subscript < 0 || subscript >= @actual_size
          nil
        else
          @ports[subscript]
        end
      end

      #=== TmPortArray#delete
      # this method is called from TmCell
      def delete
        @ports.each(&:delete)
      end

      #=== TmPortArray#delete_hilited
      # this method is called from Control
      def delete_hilited(port)
        if @port_def.get_array_size != "[]"
          TECSCDE.message_box(<<~MESSAGE, :OK)
            Array size is fixed (#{@port_def.get_array_size}).
            Cannot delete array member.
          MESSAGE
          return
        end
        index = @ports.index port
        if index != 0
          modified do
            TECSCDE.logger.info("delete #### subscript=#{port.get_subscript}")
            port.delete
            if @ports.delete(port).nil?
              TECSCDE.logger.info("delete: not found")
            end
            index = 0
            @ports.each do |port|
              port.set_subscript index
              index += 1
            end
          end
        else
          TECSCDE.message_box(<<~MESSAGE, :OK)
            cannot delete array member with subscript==0
          MESSAGE
        end
      end

      #=== TmPortArray#insert
      # this method is called from Control
      def insert(port, before_after)
        if @port_def.get_array_size != "[]"
          TECSCDE.message_box(<<~MESSAGE, :OK)
            Array size is fixed (#{@port_def.get_array_size}).
            Cannot insert array member.
          MESSAGE
          return
        end
        modified do
          @owner.adjust_port_position_to_insert port
          subsc = port.get_subscript
          i = @ports.length - 1
          while i > subsc
            @ports[i].set_subscript(@ports[i].get_subscript + 1)
            @ports[i + 1] = @ports[i]
            i -= 1
          end
          new_port = new_port(subsc + 1)
          new_port.set_position(port.get_edge_side, port.get_offset + DIST_PORT)
          @ports[subsc + 1] = new_port

          TECSCDE.logger.info("insert ####")
        end
      end

      def complete?
        @ports.all?(&:complete?)
      end

      #=== TmPortArray#editable?
      def editable?
        @owner.editable?
      end

      #=== TmPortArray#is_unsubscripted_array?
      def is_unsubscripted_array?
        if @port_def.get_array_size == "[]"
          true
        else
          false
        end
      end

      #=== TmPortArray#clone_for_undo
      def clone_for_undo
        bu = clone
        bu.copy_from self
        bu
      end

      def setup_clone(ports)
        @ports = ports.dup
      end
    end
  end
end
