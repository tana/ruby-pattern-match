require 'match'

def test
  result = match([1, 2, 3]) {
    pat([:a, 2, :b]) {
      a + b
    }
    pat([:_, :_, :_]) {
      10
    }
  }
  puts "1ok" if result == 4

  foo = Struct.new(:a, :b)
  bar = Struct.new(:a)
  result = match(foo[bar[1], 2]) {
    pat(foo[bar[1], 3]) {
      []
    }
    pat(foo[bar[:a], :b]) {
      [a, b]
    }
  }
  puts "2ok" if result == [1, 2]

  result = match(1) {
    pat([:and, :a, 2]) {
      nil
    }
    pat([:and, :a, 1]) {
      if a == 1 then "ok" else nil end
    }
  }
  puts "3ok" if result == "ok"

  result = match(1) {
    pat :a, cond {a == 1} do
      "ok"
    end
    pat :a do
      a
    end
  }
  puts "4ok" if result == "ok"

  result = match(Time.now) {
    pat([:class, Integer]) {false}
    pat([:and, [:class, Time], :a]) {
      true
    }
  }
  puts "5ok" if result == true
end
def factorial(n)
  match(n) {
    pat(1) { 1 }
    pat(:n) { n * factorial(n - 1) }
  }
end
Number = Struct.new(:number)
Plus = Struct.new(:a, :b)
Minus = Struct.new(:a, :b)
Times = Struct.new(:a, :b)
Div = Struct.new(:a, :b)
def evaluate(expr)
  match(expr) {
    pat(Number[:a]) {a}
    pat(Plus[:a, :b]) {evaluate(a) + evaluate(b)}
    pat(Minus[:a, :b]) {evaluate(a) - evaluate(b)}
    pat(Times[:a, :b]) {evaluate(a) * evaluate(b)}
    pat(Div[:a, :b]) {evaluate(a) / evaluate(b)}
  }
end

test
