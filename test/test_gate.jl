using SymbolicCircuit
using SymbolicCircuit: is_CNOT_T_commute, is_cancel, is_merge, is_r_merge, is_single_qubit, is_loc_identity, is_gate_type_identity, is_loc_type_identity

"""test is_CNOT_T_commute"""
a = UGate(gX(), [Loc(1), cLoc(2)])
b = UGate(gT(), [Loc(2), ])
c = UGate(gT(), [Loc(1), ])
@show is_CNOT_T_commute(a, b)
@show is_CNOT_T_commute(a, c)
"""test is_CNOT_T_commute end"""

"""test RG"""
a = UGate(rX([:theta, Positive(), Negative()]), [Loc(1), cLoc(2)])
b = UGate(rX([:theta, Positive(), Negative()]), [Loc(1), cLoc(2)])
circ = a*b
@show circ
@show rX([:theta, Positive(), Negative()])*rX([:theta, Positive(), Negative()])
"""test RG end"""

"""test is_cancel"""
x = gX()
h = gH()
y = gY()
t = gT()
s = gS()

@show UGate(gX(), [Loc(1), ])
@show is_cancel(UGate(gX(), [Loc(1), ]), UGate(gX(), [Loc(1), ]))
@show is_cancel(UGate(gH(), [Loc(2), ]), UGate(gH(), [Loc(2), ]))
@show is_cancel(UGate(gT(), [Loc(2), ]), UGate(gT(), [Loc(2), ]))
@show is_cancel(UGate(gS(), [Loc(2), ]), UGate(gS(), [Loc(2), ]))

a = UGate(gX(), [Loc(1), cLoc(2)])
b = UGate(gT(), [Loc(2), ])
c = UGate(gT(), [Loc(1), ])
@show is_cancel(a, a)
@show is_cancel(a, UGate(gX(), [Loc(2), cLoc(1)]))
"""test is_cancel end"""


"""test is_merge is_r_merge is_single_qubit is_loc_identity is_gate_type_identity is_loc_type_identity"""
x1 = UGate(gX(), [Loc(1), ])
h2 = UGate(gH(), [Loc(2), ])
y3 = UGate(gY(), [Loc(3), ])

x45 = UGate(gX(), [Loc(4), Loc(5)])
s3 = UGate(gS(), [Loc(3), ])
t3 = UGate(gT(), [Loc(3), ])
cnot_1c3 = UGate(gX(), [Loc(1), cLoc(3)])

rx1 = UGate(rX([:theta1, ]), [Loc(3), ])
rx2 = UGate(rX([:theta2, ]), [Loc(3), ])

@show is_merge(rx1, rx1)
@show is_merge(rx1, rx2)
@show is_r_merge(rx1, rx2)
@show is_single_qubit(rx1)
@show is_loc_identity(rx1, rx2)
@show is_gate_type_identity(rx1, rx2)
@show is_loc_type_identity(rx1, rx2)
@show isa(rx1.g, RG)

"""test is_merge is_r_merge is_single_qubit is_loc_identity is_gate_type_identity is_loc_type_identity end"""