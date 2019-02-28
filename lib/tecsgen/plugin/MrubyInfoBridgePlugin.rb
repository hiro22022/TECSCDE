#== MrubyBridgePlugin クラス
class MrubyInfoBridgePlugin < CelltypePlugin

  # TECSInfo の生成
  # すべてのシグニチャについて、ブリッジセルを生成
  #   動的結合可能とする
  # TECSInfo から RawDescriptor を得て mruby オブジェクトに記憶
  # 呼出し時
    class MrubyInfoBridge
      def factory cell_entry
        find_cell
      end
    end
end
