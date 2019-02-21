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
