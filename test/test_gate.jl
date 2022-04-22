using SymbolicCircuit: is_CNOT_T_commute

"""test is_CNOT_T_commute"""
a = Gate(gX(), [Loc(1), cLoc(2)])
b = Gate(gT(), [Loc(2), ])
c = Gate(gT(), [Loc(1), ])
@show is_CNOT_T_commute(a, b)
@show is_CNOT_T_commute(a, c)
"""test is_CNOT_T_commute end"""