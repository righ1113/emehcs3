# frozen_string_literal: true

# ＜以下は1回だけおこなう＞
# rbenv で Ruby 3.3.5(じゃなくてもいい) を入れる
# $ gem install bundler
# $ cd emehcs3
# $ bundle install --path=vendor/bundle
# ＜実行方法＞
# $ cd emehcs3
# $ RUBY_THREAD_VM_STACK_SIZE=100000000 bundle exec ruby emehcs.rb
# > [Ctrl+D] か exit で終了
require './lib/const'
require './lib/parse2_core'
require './lib/repl'

# EmehcsBase クラス
class EmehcsBase
  include Const
  private def initialize = (@env = {}; @stack = [])
  private def common(count, values = init_common(count))
    values.map! { |y| func?(y) ? parse_run(y) : y } # スタックから count 個の要素を取り出して評価する(実際に値を使用する前段階)
    count == 1 ? values.first : values              # count が 1 なら最初の要素を返す
  end
  private def my_if_and(count = 3, values = init_common(count))
    else_c = Delay.new { count == 3 ? parse_run([values[2]]) : false }
    parse_run([values[0]]) ? parse_run([values[1]]) : else_c.force
  end
end

# Emehcs クラス 相互に呼び合っているから、継承
class Emehcs < EmehcsBase
  include Parse2Core
  public def run(str_code, _dmy = @stack.clear) = (run_after parse_run parse2_core str_code)
  public def parse_run(code)
    case code   # メインルーチンの改善、code は Array
    in [] then @stack.pop
    in [x, *xs] # each_with_index 使ったら、再帰がよけい深くなった
      case x
      in Integer | TrueClass | FalseClass then @stack.push x
      in Array                            then @stack.push parse_array  x, xs.empty?
      in String                           then my_ack_push parse_string x, xs.empty?
      in Symbol                           then nil # do nothing
      else                                raise ERROR_MESSAGES[:unexpected_type]
      end; parse_run xs
    end
  end
  private def parse_array(x, em) = em && func?(x) ? parse_run(x) : x
  private def parse_string(x, em, name = x[1..], db = [x, @env[x]], co = Const.deep_copy(@env[x]))
    db.each { |y| return em ? send(EMEHCS_FUNC_TABLE[y]) : y if EMEHCS_FUNC_TABLE.key? y }
    if x[-2..] == SPECIAL_STRING_SUFFIX then x                      # 純粋文字列 :s
    elsif [FUNCTION_DEF_PREFIX, VARIABLE_DEF_PREFIX].include?(x[0]) # 関数束縛と変数束縛
      @env[name] = parse_array(pop_raise, PREFIX_TABLE[x[0]])
      em_n_nil(em, name)
    elsif @env[x].is_a?(Array)          then parse_array co, em     # code の最後かつ関数なら実行する
    elsif true                          then @env[x]                # x が変数名
    end
  end
end
Repl.new(Emehcs.new).prelude.repl if __FILE__ == $PROGRAM_NAME # メイン関数としたもの
