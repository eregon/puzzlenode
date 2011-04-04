
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

PM = lambda { |subject| subject }

module Forward
  def method_missing(meth, *args, &blk)
    lambda { |recv| self.call(recv).send(meth, *args, &block) }.extend(Forward)
  end
end

PM.extend Forward

p [2,-3].map(&PM.abs)
p [2,-3].map(&PM.abs.succ)
p [2,-3].map(&PM.abs.succ * 2)
