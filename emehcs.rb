# frozen_string_literal: true

# ・以下は1回だけおこなう
# rbenv で Ruby 3.3.5(じゃなくてもいい) を入れる
# $ gem install bundler
# $ cd emehcs3
# $ bundle install --path=vendor/bundle

# ・実行方法
# $ cd emehcs3
# $ RUBY_THREAD_VM_STACK_SIZE=100000000 bundle exec ruby emehcs.rb
# > [ctrl]+D か exit で終了

require './lib/const'
require './lib/parse2_core'
require './lib/repl'

# EmehcsBase クラス
class EmehcsBase
  include Const
  def initialize = (@env = { 'true' => 'true', 'false' => 'false' }; @stack = [])

  private

  # スタックから count 個の要素を取り出して、評価する(実際に値を使用する前段階)
  def common(count)
    values = init_common count
    values.map! { |y| func?(y) ? parse_run(y) : y }
    count == 1 ? values.first : values # count が 1 なら最初の要素を返す
  end

  # if と &&
  def my_if(count = 3)
    values = init_common count
    else_c = Delay.new { count == 3 ? parse_run([values[2]]) : 'false' }
    @stack.push parse_run([values[0]]) == 'true' ? parse_run([values[1]]) : else_c.force
  end
end

# Emehcs クラス 相互に呼び合っているから、継承しかないじゃん
class Emehcs < EmehcsBase
  include Parse2Core
  def run(str_code) = (@stack = []; run_after(parse_run(parse2_core(str_code)).to_s))

  # メインルーチンの改善、code は Array
  def parse_run(code)
    case code
    in [] then @stack.pop
    in [x, *xs] # each_with_index 使ったら、再帰がよけい深くなった
      case x
      in Integer then @stack.push x
      in Array   then @stack.push parse_array  x, xs.empty?
      in String  then my_ack_push parse_string x, xs.empty?
      in Symbol  then nil # do nothing
      else            raise ERROR_MESSAGES[:unexpected_type]
      end
      parse_run xs
    end
  end

  private

  # (1) Array のとき、code の最後かつ関数だったら実行する、でなければ実行せずに積む
  def parse_array(x, em) = em && func?(x) ? parse_run(x) : x

  # String のとき
  def parse_string(x, em, name = x[1..], db = [x, @env[x]], co = Const.deep_copy(@env[x]))
    db.each { |y| (em ? send(EMEHCS_FUNC_TABLE[y]) : @stack.push(y); return nil) if EMEHCS_FUNC_TABLE.key? y }
    if x[-2..] == SPECIAL_STRING_SUFFIX then x                               # 純粋文字列 :s
    elsif x[0] == FUNCTION_DEF_PREFIX   then @env[name] = pop_raise; name    # 関数束縛
    elsif x[0] == VARIABLE_DEF_PREFIX   then @env[name] = parse_array pop_raise, true; em ? name : nil
    elsif @env[x].is_a?(Array)          then              parse_array co, em # (2) code の最後かつ関数なら実行する
    elsif true                          then @env[x]                         # x が変数名
    end
  end
end

# メイン関数としたもの
if __FILE__ == $PROGRAM_NAME
  emehcs = Emehcs.new
  repl = Repl.new emehcs
  repl.prelude
  repl.repl
end
