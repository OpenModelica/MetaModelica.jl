module myMod

function getClientField(__module__::Module)
  println(names(__module__))
  getfield(__module__, :foo)
end

macro client()
  a = getClientField(__module__)
end

end


