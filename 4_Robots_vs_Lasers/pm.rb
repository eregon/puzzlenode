
P = Object.new

def P.method_missing(meth, *args, &block)
  l = lambda { |recv| recv.send(meth, *args, &block) }
  def l.method_missing(meth, *args, &block)
    lambda { |recv| self.call(recv).send(meth, *args, &block) }
  end
  l
end

p [2,-3].map(&P.abs)

p [2,-3].map(&P.abs.succ)

module Forward
  def method_missing(meth, *args, &blk)
    lambda { |recv| self.call(recv).send(meth, *args, &block) }.extend Forward
  end

  def self.extended(by)
    class << by
      undef_method :to_s
      undef_method :==
      undef_method :!
    end
  end
end

PM = lambda { |subject| subject }.extend Forward

p [2,-3].map(&PM.abs)
p [2,-3].map(&PM.abs.succ)
p [2,-3].map(&PM.abs.succ * 2)

p [1,2].map(&PM == 2)
p [1,2].map(&PM == 2).map(&!PM)
p [1,2].map(&!(PM == 2))
p [1,2].map(&PM * 2 - 1 + 5)

p [2,-3].map(&PM.abs.succ.to_s(3))

exit

class Blank < BasicObject
  undef_method :==
  def method_missing(meth, *args, &block)
    @meth, @args, @block = meth, args, block
    self
  end
  def call(*args)
    send(@meth, *@args, &@block)
  end
  def to_proc
    self
  end
end

B = Blank.new
p [2,-3].map(&B.abs)
#p [1,2].map(&B == 2)
