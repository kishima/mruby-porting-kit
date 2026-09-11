# Pure-Ruby stand-in for mrbgems/mruby-test/driver.c, so the reference `mruby` command can run
# assert.rb + a test file without the mrbtest binary:  mruby <(cat reference_runner.rb assert.rb t/x.rb; echo report)
def t_print(*args)
  args.each { |a| print a.to_s }
  nil
end
module Mrbtest
  FLOAT_TOLERANCE = 1e-10
  def self.nofree_cstr?; true; end
end
def __glob_bracket(pat, p, c)
  return nil if p >= pat.size
  negated = false
  if pat[p] == "!" || pat[p] == "^" then negated = true; p += 1 end
  ok = false
  while true
    return nil if p >= pat.size
    break if pat[p] == "]"
    t1 = (pat[p] == "\\") ? p + 1 : p
    return nil if t1 >= pat.size
    p = t1 + 1
    return nil if p >= pat.size
    if pat[p] == "-" && p + 1 < pat.size && pat[p + 1] != "]"
      t2 = (pat[p + 1] == "\\") ? p + 2 : p + 1
      return nil if t2 >= pat.size
      p = t2 + 1
      ok = true if !ok && pat[t1] <= c && c <= pat[t2]
    else
      ok = true if !ok && pat[t1] == c
    end
  end
  ok == negated ? nil : p + 1
end
def __glob_nb(pat, s)
  p = 0; i = 0; ptmp = nil; stmp = nil
  while true
    return i == s.size if p == pat.size
    failed = false
    c = pat[p]
    if c == "*"
      p += 1 while p < pat.size && pat[p] == "*"
      return true if ((p < pat.size && pat[p] == "\\") ? p + 1 : p) >= pat.size
      return false if i == s.size
      ptmp = p; stmp = i
      next
    elsif c == "?"
      return false if i == s.size
      p += 1; i += 1
      next
    elsif c == "["
      return false if i == s.size
      t = __glob_bracket(pat, p + 1, s[i])
      if t then p = t; i += 1; next else failed = true end
    end
    unless failed
      p += 1 if pat[p] == "\\"
      return p == pat.size if i == s.size
      if p < pat.size && pat[p] == s[i] then p += 1; i += 1; next end
    end
    return false unless ptmp
    p = ptmp; stmp += 1; i = stmp
  end
end
def __glob(pat, s, depth)
  return false if depth > 100
  l = nil; r = nil; nest = 0; i = 0
  while i < pat.size
    c = pat[i]
    if c == "{"
      l = i if nest == 0
      nest += 1
    elsif c == "}" && l
      nest -= 1
      if nest == 0 then r = i; break end
    elsif c == "\\"
      i += 1
    end
    i += 1
  end
  if l && r
    p = l
    while p < r
      t = p + 1; q = t; n = 0
      while q < r && !(pat[q] == "," && n == 0)
        if pat[q] == "{" then n += 1
        elsif pat[q] == "}" then n -= 1
        elsif pat[q] == "\\" then q += 1; break if q >= r
        end
        q += 1
      end
      ex = pat[0, l] + pat[t, q - t] + pat[r + 1, pat.size - r - 1]
      return true if __glob(ex, s, depth + 1)
      p = q
    end
    false
  elsif !l && !r
    __glob_nb(pat, s)
  else
    false
  end
end
def _str_match?(pat, s)
  __glob(pat, s, 0)
end
