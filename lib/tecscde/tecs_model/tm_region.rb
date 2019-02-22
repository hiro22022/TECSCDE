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

require "tecscde/tm_object"

module TECSCDE
  class TECSModel
    class TmRegion < TECSCDE::TmObject
      # @sub_region::{name=>TmRegion}

      #=== TmRegion#initialize
      # namespace_path::NamespacePath
      # owner::TmRegion (parent) or TECSModel (root region)
      def initialize(namespace_path, owner)
        @namespace_path = namespace_path
        @owner = owner

        # region's property
        @sub_region = {}
        @cell_list = {}
        modified {}
      end

      def get_namespace_path
        @namespace_path
      end

      def get_color
      end

      def delete_cell(cell)
        @owner.delete_cell cell
      end

      def rename_cell(cell, name)
        @owner.rename_cell cell, name
      end

      def get_region(name)
        if @sub_region[name].nil?
          modified {

            parent = self
            @sub_region[name] = TmRegion.new(@namespace_path.append(name), parent)
          }
        end
        return @sub_region[name]
      end

      #=== TmRegion#clone_for_undo
      def clone_for_undo
        bu = clone
        bu.copy_from self
        return bu
      end

      def setup_clone(sub_region)
        @sub_region = sub_region.dup
      end
    end # class TmRegion
  end
end
