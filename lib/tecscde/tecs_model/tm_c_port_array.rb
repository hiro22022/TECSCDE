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

require "tecscde/tecs_model/tm_c_port"
require "tecscde/tecs_model/tm_port_array"

module TECSCDE
  class TECSModel
    class TmCPortArray < TECSCDE::TECSModel::TmPortArray
      def initialize(cell, port_def)
        # p "TmCPortArray port_def:#{port_def}"
        @port_def = port_def
        @owner = cell
        if port_def.get_array_size == "[]"
          @actual_size = 1
        else
          @actual_size = port_def.get_array_size
        end

        @ports = []
        (0..(@actual_size - 1)).each do |subscript|
          # p "TmCPortArray: length=#{@ports.length}  subscript=#{subscript}"
          @ports << TmCPort.new(self, port_def, subscript)
        end
        modified {}
      end

      def get_join(subscript)
        if subscript.nil?
          nil
        elsif 0 <= subscript && subscript < @actual_size
          @ports[subscript]
        else
          nil
        end
      end

      #=== TmCPortArray#complete?
      def complete?
        @ports.each do |port|
          if !port.complete?
            return false
          end
        end
        true
      end

      #=== TmCPortArray#is_optional?
      def is_optional?
        @port_def.is_optional?
      end

      #=== TmCPortArray#new_port
      def new_port(subscript)
        TECSCDE::TECSModel::TmCPort.new(self, @port_def, subscript)
      end
    end
  end
end
