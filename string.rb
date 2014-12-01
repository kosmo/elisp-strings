# -*- coding: utf-8 -*-
class String
  attr_accessor :point

  def point
    return @point || 0
  end

  def match_data
    return @match_data || nil
  end

  def search_forward_regexp(regex, limit = nil)
    if limit
      _string_to_search = self.dup.slice(0, limit)
    else
      _string_to_search = self.dup
    end

    if _m = _string_to_search.match(regex, self.point)
      @match_data = _m
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

  def match_string(group)
    return @match_data[group]
  end


  def point_in_math_tex
    return true if self.point_in_equation_tex
    return true if self.point_in_inlineequation_tex
    return false
  end

  def point_in_inlineequation_tex
    org_point = self.point
    self.search_backward_regexp(/\n\s*\n/)
    substring = self.slice(point..org_point)
    substring.gsub!(/\\\$/, '')

    n = 0
    while substring.search_forward_regexp(/\$/)
      n += 1
    end

    self.point = org_point

    return true if n.odd?
    return false
  end

  def point_in_equation_tex
    org_point = self.point
    begin_equation = 0
    end_equation = 0
  
    substring = self.slice(0..org_point)
    while substring.search_forward_regexp(/\\begin{(equation|align(?:at)?|multline|gather|eqnarray)[*]?}/)
      begin_equation += 1
    end

    substring.point = 0

    while substring.search_forward_regexp(/\\end{(equation|align(?:at)?|multline|gather|eqnarray)[*]?}/)
      end_equation += 1
    end

    return true if begin_equation > end_equation
    return false

    self.point = org_point
  end

  def point_in_tex_command(tex_command)
    org_point = self.point
    
    if self.search_backward_regexp(/\\#{tex_command}(\\[[^]]*\\])*{/)
	  (goto-char (match-end 0))
	  (if (< stelle (end-of-curly-bracket))


	      (setq back t)
	    (setq back nil)
	    )
	  )
      (setq back nil)
      )
    ))
)
    self.point = org_point
  end



  def end_of_curly_bracket
    org_point = self.point
    
    curly_bracket_stack = 1

    while (curly_bracket_stack != 0)
      self.search_forward_regexp(/({|})/)
      if self.match_string(1) == "{"
        curly_bracket_stack += 1
      else
	curly_bracket_stack -= 1
      end
    end
    self.point = org_point

    
  end
  
end
