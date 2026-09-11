module Config
  Limit = 10
end
Config::Limit = 20
def f
  a = Config::Limit
  nil
end
