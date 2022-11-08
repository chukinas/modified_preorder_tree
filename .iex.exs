alias MPTree, as: T
alias MPTree.Node, as: N
alias MPTree.Seeker, as: S

build_node = fn name ->
  %{
    name: name,
    match: &(&1.name == name),
    __mptree_node__: MPTree.Node.init()
  }
end

a = build_node.("a")
b = build_node.("b")

tree = %MPTree{} = a |> MPTree.from_node() |> MPTree.insert!(b, a.match)
