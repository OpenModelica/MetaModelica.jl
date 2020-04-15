function isLineNumberNode(a, file::String, lines::LineNumberNode)
  if typeof(a) <: LineNumberNode
    a.file == Symbol(file)
  else
    false
  end
end

function replaceLineNum(a::Expr, file::String, lines::LineNumberNode)
  replace!(arg -> isLineNumberNode(arg, file, lines) ? lines : arg, a.args)
  for n in a.args
    replaceLineNum(n, file, lines)
  end
end
function replaceLineNum(a::Any, file::String, lines::LineNumberNode) end
