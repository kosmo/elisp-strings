# -*- coding: utf-8 -*-
require "yaml"

class String
  attr_accessor :point
  attr_accessor :match_data
  attr_accessor :inline_equation_ranges
  attr_accessor :language
  attr_accessor :ce_level

  def point
    return @point || 0
  end

  def language
    return @language
  end

  def ce_level
    return @ce_level
  end
  
  def match_data
    return @match_data || nil
  end

  def inline_equation_ranges
    return @inline_equation_ranges || nil
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
    
    c = 1
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

  def point_in_math_tex_or_lscience
    return true if self.point_in_math_tex
    return self.point_in_lscience   
  end
    

  def point_in_lscience
    return true if self.point_in_tex_command("val")
    return true if self.point_in_tex_command("percentval")
    return true if self.point_in_tex_command("degval")
    return true if self.point_in_tex_command("chem")    
    
    return true if self.point_in_tex_command("valunit")
    return true if self.point_in_tex_command_second_argument("valunit")
    
    return true if self.point_in_tex_command("valrange")
    return true if self.point_in_tex_command_second_argument("valrange")

    return true if self.point_in_tex_command("percentvalrange")
    return true if self.point_in_tex_command_second_argument("percentvalrange")

    return true if self.point_in_tex_command("valrangeunit")
    return true if self.point_in_tex_command_second_argument("valrangeunitvalrange")
    return true if self.point_in_tex_command_third_argument("valrangeunitvalrange")
  end  

  def point_in_inlineequation_tex
    set_inline_equation_ranges unless @inline_equation_ranges

    return true if @inline_equation_ranges.include?(self.point)
    return false
  end

  def set_inline_equation_ranges
    string = self.dup
    ranges = []

    string.point = 0
    string.gsub!(/(?<!\\)\\\$/, '  ')
    n = 0
    point = 0
    
    for char in string.chars do
      n += 1 if "$" == char
      ranges << point if n.odd?
      point += 1
    end

    self.inline_equation_ranges = ranges
  end

  def point_in_equation_tex
    org_point = self.point
    begin_equation = 0
    end_equation = 0
  
    substring = self.slice(0..org_point)
    while substring.search_forward_regexp(/\\begin[[:space:]]*{(equation|align(?:at)?|aligned|multline|gather|eqnarray)[*]?}/)
      begin_equation += 1
    end

    substring.point = 0

    while substring.search_forward_regexp(/\\end[[:space:]]*{(equation|align(?:at)?|aligned|multline|gather|eqnarray)[*]?}/)
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

  
  def point_in_tex_command(tex_commands, debug = false)
    org_point = self.point
    rv = false

    tex_commands = [tex_commands] unless tex_commands.is_a?(Array)

    for tex_command in tex_commands do
      self.save_excursion do
        self.save_match_data do
          if self.search_backward_regexp(/\\#{tex_command}(\[[^\]]*\])*(?=\{)/)
            tex_command_start = self.search_forward_regexp(/\{/)
            puts "|#{self.slice(self.point..self.end_of_curly_bracket)}| (#{tex_command_start} #{org_point} <= #{self.end_of_curly_bracket} #{org_point <= self.end_of_curly_bracket})" if debug
            rv = true if org_point <= self.end_of_curly_bracket
          end
        end
      end
    end
    
    self.point = org_point
    return rv
  end

  def point_in_tex_command_second_argument(tex_command, debug = false)
    org_point = self.point
    rv = false
    
    self.save_excursion do
      self.save_match_data do
        if self.search_backward_regexp(/\\#{tex_command}(\[[^\]]*\])*(?=\{)/)
          self.point += 1
          self.point = self.end_of_curly_bracket
      
          tex_command_second_argument_start = self.search_forward_regexp(/\{/)
          puts "|#{self.slice(self.point..self.end_of_curly_bracket)}| (#{ tex_command_second_argument_start} #{org_point} <= #{self.end_of_curly_bracket} #{org_point <= self.end_of_curly_bracket})" if debug
          rv = true if org_point < self.end_of_curly_bracket
        end
      end
    end
    
    return rv
  end

  def point_in_tex_command_third_argument(tex_command)
    org_point = self.point
    rv = false

    self.save_excursion do
      self.save_match_data do
        if self.search_backward_regexp(/\\#{tex_command}(\[[^\]]*\])*{[^}]*}{[^}]*}{/)
          self.point = self.match_data.end(0)
          rv = true if org_point < self.end_of_curly_bracket
        end
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

  def save_match_data(&block)
    org_match_data = self.match_data
    yield
    self.match_data = org_match_data
  end

  
  def end_of_curly_bracket
    end_point = self.point

    self.save_excursion do
      self.save_match_data do
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
    end
    
    return end_point
  end

  def end_of_quoted_curly_bracket
    end_point = self.point

    self.save_excursion do
      self.save_match_data do
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
    end
    
    return end_point
  end

  
  def end_of_parenthesis
    end_point = self.point

    self.save_excursion do
      self.save_match_data do
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
    end
    
    return end_point
  end

  def end_of_bracket
    end_point = self.point

    self.save_excursion do
      self.save_match_data do
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
    end
    
    return end_point
  end


  def jump_back_one_paragraph
    end_point = self.point
    self.search_backward_regexp(/(\n\s*\n)+/)
    
    
    
    return end_point
  end
  
end

