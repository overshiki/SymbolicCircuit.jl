using SymbolicCircuit


x1 = Gate(gX(), [Loc(1), ])
y3 = Gate(gY(), [Loc(3), ])
z2 = Gate(gZ(), [Loc(2), ])
z3 = Gate(gZ(), [Loc(3), ])
cnot1c2 = Gate(gX(), [Loc(1), cLoc(2)])

circ = x1 * z2 * y3 * z3 * x1 * z3 * cnot1c2
show(circ)

_circ = to_yao(circ; num_qubits=3)
println(_circ)

_circ = to_yao(circ)
println(_circ)

to_yaoplot("./test/plot.png", circ)

ncirc = egraph_simplify(circ, Val(:default_rule))

to_yaoplot("./test/sim_plot.png", ncirc)