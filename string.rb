class String
  attr_accessor :point

  def point
    return @point || 0
  end

  def search_forward_regexp(regex, limit = nil)
    if limit
      _string_to_search = self.dup.slice(0, limit)
    else
      _string_to_search = self.dup
    end

    if _m = _string_to_search.match(regex, self.point)
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

  def line_number
    _point = @point
    @point = 0

    c = 0
    while self.search_forward_regexp(/\n/, _point) do
      c += 1
    end

    @point = _point
    return c
  end


end
