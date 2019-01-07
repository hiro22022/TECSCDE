#
#  TECS Generator
#      Generator for TOPPERS Embedded Component System
#
#   Copyright (C) 2008-2015 by TOPPERS Project
#--
#   上記著作権者は，以下の(1)〜(4)の条件を満たす場合に限り，本ソフトウェ
#   ア（本ソフトウェアを改変したものを含む．以下同じ）を使用・複製・改
#   変・再配布（以下，利用と呼ぶ）することを無償で許諾する．
#   (1) 本ソフトウェアをソースコードの形で利用する場合には，上記の著作
#       権表示，この利用条件および下記の無保証規定が，そのままの形でソー
#       スコード中に含まれていること．
#   (2) 本ソフトウェアを，ライブラリ形式など，他のソフトウェア開発に使
#       用できる形で再配布する場合には，再配布に伴うドキュメント（利用
#       者マニュアルなど）に，上記の著作権表示，この利用条件および下記
#       の無保証規定を掲載すること．
#   (3) 本ソフトウェアを，機器に組み込むなど，他のソフトウェア開発に使
#       用できない形で再配布する場合には，次のいずれかの条件を満たすこ
#       と．
#     (a) 再配布に伴うドキュメント（利用者マニュアルなど）に，上記の著
#         作権表示，この利用条件および下記の無保証規定を掲載すること．
#     (b) 再配布の形態を，別に定める方法によって，TOPPERSプロジェクトに
#         報告すること．
#   (4) 本ソフトウェアの利用により直接的または間接的に生じるいかなる損
#       害からも，上記著作権者およびTOPPERSプロジェクトを免責すること．
#       また，本ソフトウェアのユーザまたはエンドユーザからのいかなる理
#       由に基づく請求からも，上記著作権者およびTOPPERSプロジェクトを
#       免責すること．
#
#   本ソフトウェアは，無保証で提供されているものである．上記著作権者お
#   よびTOPPERSプロジェクトは，本ソフトウェアに関して，特定の使用目的
#   に対する適合性も含めて，いかなる保証も行わない．また，本ソフトウェ
#   アの利用により直接的または間接的に生じたいかなる損害に関しても，そ
#   の責任を負わない．
#
#   $Id: C2TECSBridgePlugin.rb 2952 2018-05-07 10:19:07Z okuma-top $
#++

#== C => TECS 受け口呼び出しのプラグイン
class C2TECSBridgePlugin < SignaturePlugin
# @signature:: Signature   プラグインの対象となるシグニチャ
# @option:: String   '"', '"' で囲まれた文字列

  # プラグイン引数名と Proc
  C2TECSBridgePluginArgProc = {
    "prefix" => Proc.new { |obj, rhs| obj.set_prefix rhs },
    "suffix" => Proc.new { |obj, rhs| obj.set_suffix rhs },
    "header_name" => Proc.new { |obj, rhs| obj.set_header_name rhs },
  }


  @@signature_list = { }

  # signature::     Signature        シグニチャ（インスタンス）
  def initialize(signature, option)
    super

    @signature = signature
    @header_name = "#{$gen}/C2TECS_#{@signature.get_global_name}.h"
    @prefix = ""
    @suffix = ""
    @celltype_name = :"t#{@signature.get_global_name}"
    @plugin_arg_check_proc_tab = C2TECSBridgePluginArgProc
    parse_plugin_arg
  end

  def gen_cdl_file(file)
    if @@signature_list[@signature.get_global_name]
      @@signature_list[@signature.get_global_name] << self
      cdl_warning("C2TW001 signature '$1' duplicate. ignored current one", @signature.get_namespace_path)
      return
    end

    @@signature_list[@signature.get_global_name] = [ self ]
    print_msg "  C2TECSBridgePlugin: [celltype] C2TECS::#{@celltype_name}. Create cell then join the call port 'cCall' to the target cell\n"
    file.print <<EOT
namespace nC2TECS{
  [singleton, active]    // this celltype is not active actually. 'active' is specified to prevent W1002.
  celltype #{@celltype_name} {
    call #{@signature.get_namespace_path} cCall;
  };
};
EOT
  end

  #=== 後ろのコードを生成
  # プラグインの後ろのコードを生成
  # file:: File:
  def self.gen_post_code(file)
    # 複数のプラグインの post_code が一つのファイルに含まれるため、以下のような見出しをつけること
    # file.print "/* '#{self.class.name}' post code */\n"
  end

  #===  受け口関数の本体(C言語)を生成する
  #     通常であれば、ジェネレータは受け口関数のテンプレートを生成する
  #     プラグインの場合、変更する必要のないセルタイプコードを生成する
  # file::           FILE        出力先ファイル
  # b_singleton::    bool        true if singleton
  # ct_name::        Symbol
  # global_ct_name:: string
  # sig_name::       string
  # ep_name::        string
  # func_name::      string
  # func_global_name:: string
  # func_type::      class derived from Type
  def gen_ep_func_body(file, b_singleton, ct_name, global_ct_name, sig_name, ep_name, func_name, func_global_name, func_type, params)
    # nothing to do
  end

  def gen_postamble(file, b_singleton, ct_name, global_name)
    header_file = open(@header_name, "w")

    header_comment =<<EOT
/*
 * This file was generated by C2TECSBridgePlugin and has prototype
 * decalarations of functions in signature '#{@signature.get_namespace_path}'
 */

EOT

    file.print header_comment
    header_file.print header_comment
    header_file.print <<EOT
#ifndef #{@signature.get_global_name}__h
#define #{@signature.get_global_name}__h

/*
 * function prototype declarations
 *    signature: '#{@signature.get_namespace_path}'
 *
 * These functions can be called from C sources directly.
 * If function name collides, please consider to specify 'prefix' option for C2TECSBridgePlugin.
 */
EOT

    # generate C functions calling function of call port
    @signature.get_function_head_array.each { |func_head|
      func_name = func_head.get_name
      ret_type  = func_head.get_return_type
      params    = func_head.get_paramlist.get_items

      # p "celltype_name, sig_name, func_name, func_global_name"
      # p "#{ct_name}, #{sig_name}, #{func_name}, #{func_global_name}"

      # function header
      file.print("#{ret_type.get_type_str}\n")
      header_file.printf("%-16s", ret_type.get_type_str)
      file.print("#{@prefix}#{func_name}#{@suffix}(")
      header_file.print("#{@prefix}#{func_name}#{@suffix}(")

      delim = ""
      params.each{ |param|
        file.printf("#{delim} #{param.get_type.get_type_str} #{param.get_name}#{param.get_type.get_type_str_post}")
        header_file.printf("#{delim} #{param.get_type.get_type_str} #{param.get_name}#{param.get_type.get_type_str_post}")
        delim = ","
      }
      file.print(" )\n{\n")
      header_file.print(" );\n")

      # call function in call port
      if !ret_type.is_void?
        file.print("  #{ret_type.get_type_str}  retval;\n")
        file.print("  retval = ")
      else
        file.print("  ")
      end

      file.print("cCall_#{func_name}(")

      delim = ""
      params.each{ |param|
        file.printf("#{delim} #{param.get_name}")
        delim = ","
      }
      file.print(" );\n")

      if !ret_type.is_void?
        file.print("  return retval;\n")
      end
      file.print("}\n\n")
    }

    header_file.print <<EOT

#endif /* #{@signature.get_global_name}__h */

EOT

    header_file.close
  end

  #===  set_prefix - prefix プラグインオプション
  def set_prefix(rhs)
    @prefix = rhs.to_s
  end

  #===  set_suffix - suffix プラグインオプション
  def set_suffix(rhs)
    @suffix = rhs.to_s
  end

  #===  set_header_name - header_name プラグインオプション
  def set_header_name(rhs)
    @header_name = "#{$gen}/" + rhs.to_s
    if !(@header_name =~ /\.h\Z/)
      @header_name += ".h"
    end
  end

end
