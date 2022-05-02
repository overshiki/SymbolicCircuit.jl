

simplify_rules = get_simplify_rules()

function block_simplify(b::Block)
    circ = rebuild_circuit(b.gates)
    ncirc = egraph_simplify(circ, simplify_rules; timeout=20)
    block = ParallelBlock(get_gates(ncirc))
    return block
end

function block_simplify2expr(b::Block)
    block = block_simplify(b)
    return :($block)
end