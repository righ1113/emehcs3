# frozen_string_literal: true

# Const モジュール
module Const
  READLINE_HIST_FILE = './data/.readline_history'
  PRELUDE_FILE       = './data/prelude.eme'
  EMEHCS_VERSION     = 'emehcs version 0.2.5'
  EMEHCS_FUNC_TABLE  = {
    '+'        => :plus,
    '-'        => :minus,
    '*'        => :mul,
    '/'        => :div,
    'mod'      => :mod,
    '<'        => :lt,
    '=='       => :eq,
    '!='       => :ne,
    '&&'       => :my_and,
    'cons'     => :cons,
    's.++'     => :s_append,
    'sample'   => :my_sample,
    'error'    => :error,
    'car'      => :car,
    'cdr'      => :cdr,
    'cmd'      => :cmd,
    'eval'     => :eval,
    'eq2'      => :eq2,
    '!!'       => :index,
    'length'   => :length,
    'chr'      => :chr,
    'up_p'     => :up_p,
    '?'        => :my_if_and,
    'S'        => :un_s,
    'K'        => :un_k,
    'I'        => :un_i,
    'INC'      => :un_inc,
    'R'        => :un_r
  }.freeze

  ERROR_MESSAGES = {
    insufficient_args: '引数が不足しています',
    unexpected_type:   '予期しない型'
  }.freeze

  SPECIAL_STRING_SUFFIX = ':s'
  FUNCTION_DEF_PREFIX   = '>'
  VARIABLE_DEF_PREFIX   = '='

  PREFIX_TABLE = {
    FUNCTION_DEF_PREFIX => false,
    VARIABLE_DEF_PREFIX => true
  }.freeze

  private

  # スタック操作のためのインターフェースを定義
  def stack_pop         = @stack.pop
  def stack_push(value) = @stack.push(value)
  def stack_clear       = @stack.clear

  def init_common(count)
    values = Array.new(count) { stack_pop }
    raise ERROR_MESSAGES[:insufficient_args] if values.any?(&:nil?)

    values
  end

  def common(count, values = init_common(count))
    values.map! { |y| func?(y) ? parse_run(y) : y } # count 個の要素を map して評価する(実際に値を使用する前段階)
    count == 1 ? values.first : values              # count が 1 なら最初の要素を返す
  end

  # primitive functions
  def plus      = common(2).reduce(:+)
  def mul       = common(2).reduce(:*)
  def minus     = (y1, y2 = common(2); y2 -  y1)
  def div       = (y1, y2 = common(2); y2 /  y1)
  def mod       = (y1, y2 = common(2); y2 %  y1)
  def lt        = (y1, y2 = common(2); y2 <  y1)
  def eq        = (y1, y2 = common(2); y2 == y1)
  def ne        = (y1, y2 = common(2); y2 != y1)
  def s_append  = (y1, y2 = common(2); y1[0..-3] + y2)
  def my_sample = common(1)[..-2].sample
  def error     = raise common(1).to_s[..-3]
  def car       = common(1)[0]
  def cdr       = common(1)[1..]
  def cons      = (y1, y2 = common(2); [y1] + y2)
  def cmd       = (y1 = common(1); system(y1[..-3].gsub('%', ' ')); $?)
  def eval      = (y1 = common(1); parse_run(y1[..-2]))
  def eq2       = (y1, y2 = common(2); run_after(y2.to_s) == run_after(y1.to_s))
  def length    = (common(1).length - 2)
  def chr       = common(1).chr
  def up_p      = (y1, y2, y3 = common(3); y3[y2] += y1; y3)
  def index     = (y1, y2 = common(2); y2.is_a?(Array) ? y2[y1] : "#{y2[y1]}#{SPECIAL_STRING_SUFFIX}")
  def my_and    = my_if_and 2
  def un_s      = ->(f) { ->(g) { ->(x) { f[x][g[x]] } } }
  def un_k      = ->(x) { ->(_y) { x } }
  def un_i      = ->(x) { x }
  def un_inc    = ->(x) { x + 1 }
  def un_dot(c) = ->(x) { print c; x }
  def un_r      = ->(x) { puts; x }

  # utility
  def pop_raise          = (pr = stack_pop; raise ERROR_MESSAGES[:insufficient_args] if pr.nil?; pr)
  def func?(x)           = x.is_a?(Array) && x.last != :q
  def my_ck_push(x)      = x.nil? ? nil : stack_push(x)
  def em_n_nil(em, name) = em ? name : nil

  # Const クラス
  class Const
    def self.deep_copy(arr)
      Marshal.load(Marshal.dump(arr))
    end

    # このようにして assert を使うことができます
    def self.assert(cond1, cond2, message = 'Assertion failed')
      raise "#{cond1} #{cond2} <#{message}>" unless cond1 == cond2
    end
  end

  # 遅延評価
  class Delay
    def initialize(&func)
      @func  = func
      @flag  = false
      @value = false
    end

    def force
      unless @flag
        @value = @func.call
        @flag  = true
      end
      @value
    end
  end
end
