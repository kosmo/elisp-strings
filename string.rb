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

    #puts regex

    if _m = _string_to_search.match(regex, self.point)
      @match_data = _m
      self.point = _m.end(0)
      return self.point
    end
    return nil
  end

  def search_backward_regexp(regex)
    # if _m = self.to_enum(:scan, regex).map{Regexp.last_match}.last
    #   @match_data = _m
    #   self.point = _m.end(0)
    #   return self.point
    # end
    # return nil

    if _r = self.rindex(regex, self.point-1)
      if _m = self.match(regex, _r - 1)
        @match_data = _m
        self.point = _m.end(0)
        return self.point
      end
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
    rv = false
    self.save_excursion do
      substring = self.slice(0..point - 1)
      substring.gsub!(/\\\$/, '')

      n = 0
      while substring.search_forward_regexp(/\$/)
        n += 1
      end
      
      if n.odd?
        rv = true 
      else
        rv = false
      end
    end
    
    return rv
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

  def point_in_superscript(debug = false)
    org_point = self.point
    rv = false
    
    self.save_excursion do
      if tex_command_start = self.search_backward_regexp(/\^{/)
        self.point = tex_command_start
        puts "|#{self.slice(self.point..self.end_of_curly_bracket)}| (#{tex_command_start} #{org_point} <= #{self.end_of_curly_bracket} #{org_point <= self.end_of_curly_bracket}) " if debug
        rv = true if org_point <= self.end_of_curly_bracket
      end
    end
    self.point = org_point
    return rv
  end

  def point_in_subscript(debug = false)
    org_point = self.point
    rv = false
    
    self.save_excursion do
      if tex_command_start = self.search_backward_regexp(/_{/)
        self.point = tex_command_start
        puts "|#{self.slice(self.point..self.end_of_curly_bracket)}| (#{tex_command_start} #{org_point} <= #{self.end_of_curly_bracket} #{org_point <= self.end_of_curly_bracket}) " if debug
        rv = true if org_point <= self.end_of_curly_bracket
      end
    end
    self.point = org_point
    return rv
  end

  
  def point_in_tex_command(tex_command, debug = false)
    org_point = self.point
    rv = false
    
    self.save_excursion do
      if self.search_backward_regexp(/\\#{tex_command}(\[[^\]]*\])*/)
        tex_command_start = self.search_forward_regexp(/\{/)
        puts "|#{self.slice(self.point..self.end_of_curly_bracket)}| (#{tex_command_start} #{org_point} <= #{self.end_of_curly_bracket} #{org_point <= self.end_of_curly_bracket})" if debug
        rv = true if org_point <= self.end_of_curly_bracket
      end
    end

    self.point = org_point
    return rv
  end

  def point_in_tex_command_second_argument(tex_command, debug = false)
    org_point = self.point
    rv = false
    
    self.save_excursion do
      # if self.search_backward_regexp(/\\#{tex_command}(\[[^\]]*\])*{[^}]*}{/)    
      if self.search_backward_regexp(/\\#{tex_command}(\[[^\]]*\])*({[^}]*}+)/)
        tex_command_second_argument_start = self.search_forward_regexp(/\{/)
        puts "|#{self.slice(self.point..self.end_of_curly_bracket)}| (#{ tex_command_second_argument_start} #{org_point} <= #{self.end_of_curly_bracket} #{org_point <= self.end_of_curly_bracket})" if debug
        rv = true if org_point < self.end_of_curly_bracket
      end
    end
    return rv
  end

  def point_in_tex_command_third_argument(tex_command)
    org_point = self.point
    rv = false

    self.save_excursion do
      if self.search_backward_regexp(/\\#{tex_command}(\[[^\]]*\])*{[^}]*}{[^}]*}{/)
        self.point = self.match_data.end(0)
        rv = true if org_point < self.end_of_curly_bracket
      end
    end

    return rv
  end

  def point_in_tex_environment(environment)
    current_point = self.point
    begin_env = 0
    end_env = 0
    back = false

    self.save_excursion do
      self.point = 0
      self.save_excursion do
        while self.search_forward_regexp(/\\begin{#{environment}}/, current_point)
          begin_env += 1
        end
      end

      self.save_excursion do 
        while self.search_forward_regexp(/\\end{#{environment}}/, current_point)
          end_env += 1
        end
      end
      
      if begin_env > end_env
        back = true
      end
    end

    return back
  end

  def save_excursion(&block)
    org_point = self.point
    yield
    self.point = org_point
  end

  def end_of_curly_bracket
    end_point = self.point

    self.save_excursion do
      curly_bracket_stack = 1
      
      while (curly_bracket_stack != 0)
        self.search_forward_regexp(/({|})/)
        if self.match_string(1) == "{"
          curly_bracket_stack += 1
        else
          curly_bracket_stack -= 1
        end
      end
      
      end_point = self.point
    end
    
    return end_point
  end

  def end_of_quoted_curly_bracket
    end_point = self.point

    self.save_excursion do
      curly_bracket_stack = 1
      
      while (curly_bracket_stack != 0)
        self.search_forward_regexp(/(\\\{|\\\})/)
        if self.match_string(1) == "\\{"
          curly_bracket_stack += 1
        else
          curly_bracket_stack -= 1
        end
      end
      
      end_point = self.point
    end
    
    return end_point
  end

  
  def end_of_parenthesis
    end_point = self.point

    self.save_excursion do
      curly_bracket_stack = 1
      
      while (curly_bracket_stack != 0)
        self.search_forward_regexp(/(\(|\))/)
        if self.match_string(1) == "("
          curly_bracket_stack += 1
        else
          curly_bracket_stack -= 1
        end
      end
      
      end_point = self.point
    end
    
    return end_point
  end

  def end_of_bracket
    end_point = self.point

    self.save_excursion do
      curly_bracket_stack = 1
      
      while (curly_bracket_stack != 0)
        self.search_forward_regexp(/(\[|\])/)
        if self.match_string(1) == "["
          curly_bracket_stack += 1
        else
          curly_bracket_stack -= 1
        end
      end
      
      end_point = self.point
    end
    
    return end_point
  end

  
end

