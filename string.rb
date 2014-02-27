class String
  attr_accessor :point

  def point
    return @point || 0
  end

  def search_forward_regexp(regex)
    if _m = self.match(regex, self.point)
      self.point = _m.end(0)
      return self.point
    end
    return nil
  end

  def search_backward_regexp(regex)
    if _r = self.rindex(regex, self.point - 1)
      self.point = _r
      return self.point
    end
    return nil
  end
  


end
