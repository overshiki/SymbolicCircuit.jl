using Metatheory
using SymbolicCircuit
using SymbolicCircuit: is_AAdagger

x1 = Gate(gX(), [Loc(1), ])
y3 = Gate(gY(), [Loc(3), ])
z2 = Gate(gZ(), [Loc(2), ])
z3 = Gate(gZ(), [Loc(3), ])
h2 = Gate(gH(), [Loc(2), ])
cnot_4c2 = Gate(gX(), [Loc(1), cLoc(2)])
rx1 = Gate(rX([:theta1, ]), [Loc(3), ])
rx2 = Gate(rX([:theta2, ]), [Loc(3), ])
s3 = Gate(gS(), [Loc(3), ])


to_dagger = dagger_rewriter()
rx1d = to_dagger(rx1)
@show is_AAdagger(rx1, rx1d)
rxn = Gate(rX([:theta1, :theta2]), Q[Loc(3)])
rxnd = Gate(rXd([:theta2, :theta1]), Q[Loc(3)])
@show is_AAdagger(rxn, rxnd)

circ = head_circuit() * x1 * z2 * cnot_4c2 * z2 * y3 * z3 * x1 * s3 * s3 * rx1 * rx2 * h2

ncirc = egraph_simplify(circ, _simplify)
@show ncirc

circ = circ * dagger_circuit(circ)
ncirc = egraph_simplify(circ, _simplify)
@show ncirc