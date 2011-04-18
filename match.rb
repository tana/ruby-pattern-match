# Rubyでパターンマッチ

# match: パターンマッチの最初に呼ぶ。引数は対象の値
#   内部の変数を初期化する。
# pat: パターンと実行する内容。引数はパターン, ブロックは実行内容
#   シンボルの名前はパターンの中だけ。出現した順番に並べてブロックに渡す
# endmatch: パターンマッチの最後に呼ぶ。値を返すのはこれ。

class PatternMatch
  # @result: 戻り値
  # @val: 対象の値
  # @end: 終わったか


  # この二つのクラスはmatch_の中で使う
  class Failed
    # 失敗したらFailedのインスタンスを返す
  end
  class FailedException < Exception
    # 失敗した時に出す例外
  end
  # パターンマッチ
  def match_(pat, val)
    begin
      vars = []
      if (pat == :_)
        []
      elsif (pat.is_a? Symbol)
        vars << [pat, val]
      elsif (pat == val)
        []
      elsif (pat.is_a?(Array) && pat[0] == :and)
        arr = []
        pat[1..pat.length].each {|pattern|
          result = match_(pattern, val)
          raise FailedException if result.is_a? Failed
          arr << result
        }
        vars.concat(arr.inject([]) {|a, b| a + b})
      elsif (pat.is_a?(Array) && pat[0] == :class)
        raise FailedException unless val.is_a? pat[1]
      elsif (pat.is_a?(Array) && val.is_a?(Array) && pat.length == val.length)
        vars.concat(pat.zip(val).map {|arr|
          result = match_(arr[0], arr[1])
          if result.is_a?(Failed)
            raise FailedException
          end
          result
        }.inject([]) {|a, b| a + b})
      elsif (pat.is_a?(Struct) && val.is_a?(Struct) && pat.class==val.class &&
             pat.length == val.length)
        arr = []
        pat.each_pair {|name, value|
          result = match_(value, val[name])
          if result.is_a? Failed
            raise FailedException
          end
          arr << result
        }
        vars.concat(arr.inject([]) {|a, b| a + b})
      else
        raise FailedException
      end
      return vars
    rescue FailedException
      return Failed.new
    end
  end
  def hash2obj(hash)
    c = Class.new
    c.class_eval {|c2|
      hash.each_pair {|key, value|
        define_method(key, lambda { value })
      }
    }
    return c.new
  end
  #def match(val)
  #  @val = nil
  #  @end = false 
  #  @result = nil
  #  @val = val
  #end
  def initialize(value)
    @val = value
  end
  def cond(&block)
    return block
  end
  def pat(pattern, condition=nil, &block)
    return if @end
    result = match_(pattern, @val)
    if not result.is_a?(Failed)
      vars = {}
      result.each {|arr|
        vars[arr[0]] = arr[1]
      }
      obj = hash2obj(vars)
      return if condition != nil && !obj.instance_eval(&condition)
      @end = true
      @result = obj.instance_eval(&block)
    end
  end
  def endmatch
    return @result
  end
end

def match(value, &block)
  obj = PatternMatch.new(value)
  obj.instance_eval(&block)
  return obj.endmatch
end
