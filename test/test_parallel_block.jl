using SymbolicCircuit
using SymbolicCircuit: parallel_block_merge, is_parallel_block_merge, block_simplify, get_parallel_block_rules, block_simplify_rewriter



x1 = UGate(gX(), [Loc(1), ])
x2 = UGate(gX(), [Loc(2), ])
z1 = UGate(gZ(), [Loc(1), ])
z2 = UGate(gZ(), [Loc(2), ])
y1 = UGate(gY(), [Loc(1), ])
y2 = UGate(gY(), [Loc(2), ])

h1 = UGate(gH(), [Loc(1), ])
h2 = UGate(gH(), [Loc(2), ])


y3 = UGate(gY(), [Loc(3), ])
z3 = UGate(gZ(), [Loc(3), ])

x23 = UGate(gX(), [Loc(2), Loc(3)])

x45 = UGate(gX(), [Loc(4), Loc(5)])
s3 = UGate(gS(), [Loc(3), ])
t3 = UGate(gT(), [Loc(3), ])
cnot_1c3 = UGate(gX(), [Loc(1), cLoc(3)])

cnot_4c2 = UGate(gX(), [Loc(1), cLoc(2)])

rx1 = UGate(rX([:theta1, ]), [Loc(3), ])
rx2 = UGate(rX([:theta2, ]), [Loc(3), ])


b = parallel_block_merge(cnot_1c3, x2)
@show b
@show is_parallel_block_merge(x1, h2, [1,2,3])
@show is_parallel_block_merge(x23, h2, [1,2,3])
@show is_parallel_block_merge(b, h2, [1,2,3])
@show is_parallel_block_merge(b, rx1, [1,2,3])
@show is_parallel_block_merge(parallel_block_merge(x23, h2), y3, [1,2,3])
# @show parallel_block_merge(b, rx1)
# @show parallel_block_merge(rx1, b)

@show block_simplify(b)

circ = x1 * z2 * cnot_4c2 * z2 * y3 * z3 * x1 * z3 * s3 * s3 * rx1 * rx2 * h2

show_circuit(circ)
count_gates(circ)
println()

rules = get_parallel_block_rules([1,2,3,4])
ncirc = egraph_simplify(circ, rules; timeout=20)
show_circuit(ncirc)
count_gates(ncirc)
println()

# let head_circ = head_circuit()
#     for gate in get_gates(ncirc)
#         if gate isa Block 
#             gate = block_simplify(gate)
#         end 
#         head_circ *= gate
#         @show head_circ
#     end
#     show_circuit(head_circ)
#     count_gates(head_circ)
#     println()
# end


# v = AbstractRule[]
# r = @rule a a::Block => block_simplify2expr(a)
# push!(v, r)
# ncirc = egraph_simplify(ncirc, v; timeout=20)
# show_circuit(ncirc)
# count_gates(ncirc)
# println()

ncirc = Circuit(block_simplify_rewriter()(ncirc.expr))
show_circuit(ncirc)
count_gates(ncirc)
println()


ncirc = egraph_simplify(circ, Val(:default_rule); timeout=20)
count_gates(ncirc)
println()