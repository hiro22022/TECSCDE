module TECSCDE
  #== TmObject: base class for TECSModel & its children
  #
  class TmObject
    # @owner::
    #  TmRegion  => TmRegion, TECSModel(for root region)
    #  TmCell    => TmRegion
    #  TmPort    => TmCell | TmCPortArray | TmEPortArray
    #  TmJoin    => TECSModel
    #  TmJoinBar => TmJoin
    #  TECSModel => Nil
    def set_owner(owner)
      @owner = owner
    end

    def get_owner
      @owner
    end

    def get_model
      if @owner
        return @owner.get_model
      else
        if self.is_a? TECSModel
          raise "get_model: self is not TECSModel: #{self.class}"
        end
        self
      end
    end

    def modified
      get_model.add_change_set self
      proc = Proc.new
      proc.call
    end

    def copy_from(tm_object)
      tm_object.instance_variables.each{|iv|
        val = tm_object.instance_variable_get(iv)
        if val.is_a?(Array) || val.is_a?(Hash)
          instance_variable_set(iv, val.dup)
        else
          instance_variable_set(iv, val)
        end
      }
    end
  end
end
