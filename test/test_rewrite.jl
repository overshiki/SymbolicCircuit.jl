using SymbolicCircuit

x1 = UGate(gX(), [Loc(1), ])
y3 = UGate(gY(), [Loc(3), ])
z2 = UGate(gZ(), [Loc(2), ])
z3 = UGate(gZ(), [Loc(3), ])
cnot_4c2 = UGate(gX(), [Loc(1), cLoc(2)])
rx1 = UGate(rX([:theta1, ]), [Loc(3), ])

circ = x1 * z2 * cnot_4c2 * z2 * y3 * z3 * x1 * rx1

z2hxh = z2hxh_rewriter()

@show z2hxh(circ.expr)

to_dagger = dagger_rewriter()
@show to_dagger(rx1)

x2hzh = x2hzh_rewriter()
show_circuit(Circuit(x2hzh(circ.expr)))