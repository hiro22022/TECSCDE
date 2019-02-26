$TECSCDE = true
require "tecsgen"
require "tecscde/logger"

module TECSCDE
  class Command
    def initialize
    end

    def run(argv)
      $b_tate = true     # Bool: true if vertical style
      $b_force_apply_tool_info = false # Bool: force to apply tool_info

      additional_option_parser = Proc.new do |parser|
        parser.on("--base_dir=dir", "base directory (tecscde only)") do |dir|
          $base_dir[dir] = true
        end
        parser.on("--force-apply-tool_info", "force to apply tool_info, even if validation failed. this might cause ruby exception and stop tecscde") do
          $b_force_apply_tool_info = true
        end
        parser.on("--tate", "vertical (tate) style (tecscde only)") do
          $b_tate = true
        end
        parser.on("--yoko", "horizontal (yoko) style (tecscde only)") do
          $b_tate = false
        end
      end

      TECSGEN.init(additional_option_parser)
      tecsgen = TECSGEN.new
      tecsgen.run1
      TECSCDE.main(tecsgen)
    end
  end
end
