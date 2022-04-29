using SymbolicCircuit
using SymbolicCircuit: is_AAdagger

x1 = UGate(gX(), [Loc(1), ])
y3 = UGate(gY(), [Loc(3), ])
z2 = UGate(gZ(), [Loc(2), ])
z3 = UGate(gZ(), [Loc(3), ])
h2 = UGate(gH(), [Loc(2), ])
cnot_4c2 = UGate(gX(), [Loc(1), cLoc(2)])
rx1 = UGate(rX([:theta1, ]), [Loc(3), ])
rx2 = UGate(rX([:theta2, ]), [Loc(3), ])
s3 = UGate(gS(), [Loc(3), ])


to_dagger = dagger_rewriter()
rx1d = to_dagger(rx1)
@show is_AAdagger(rx1, rx1d)
rxn = UGate(rX([:theta1, :theta2]), Q[Loc(3)])
rxnd = DaggerGate(rX([:theta2, :theta1]), Q[Loc(3)])
@show is_AAdagger(rxn, rxnd)

circ = x1 * z2 * cnot_4c2 * z2 * y3 * z3 * x1 * s3 * s3 * rx1 * rx2 * h2


ncirc = egraph_simplify(circ, Val(:default_rule); verbose=true)
@show ncirc
@show SymbolicCircuit.areequal(Val(:default_rule), circ, ncirc)


circ = circ * dagger_circuit(circ)
ncirc = egraph_simplify(circ, Val(:default_rule); verbose=true)
@show ncirc
@show SymbolicCircuit.areequal(Val(:default_rule), circ, ncirc)