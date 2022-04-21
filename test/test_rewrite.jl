using Metatheory
using SymbolicCircuit

x1 = Gate(gX(), [Loc(1), ])
y3 = Gate(gY(), [Loc(3), ])
z2 = Gate(gZ(), [Loc(2), ])
z3 = Gate(gZ(), [Loc(3), ])
cnot_4c2 = Gate(gX(), [Loc(1), cLoc(2)])
rx1 = Gate(rX([:theta1, ]), [Loc(3), ])

circ = head_circuit() * x1 * z2 * cnot_4c2 * z2 * y3 * z3 * x1 * rx1

z2hxh = z2hxh_rewriter()

@show z2hxh(circ)

to_dagger = dagger_rewriter()
@show to_dagger(rx1)