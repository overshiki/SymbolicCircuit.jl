using SymbolicCircuit
using SymbolicCircuit: get_simplify_rules, H_CNOT2CNOT_rule, CNOT2H_CNOT_rule, CNOTHH_rule, CNOTthree2CNOTHH_rule, CNOTHH2CNOTthree_rule, areequal

"""use CNOTHH_rule, check if H_CNOT2CNOT_rule is valid"""
x1c2 = UGate(gX(), [Loc(1), cLoc(2)])
x2c1 = UGate(gX(), [cLoc(1), Loc(2)])
h1 = UGate(gH(), [Loc(1)])
h2 = UGate(gH(), [Loc(2)])


left_circ = h1 * h2 * x2c1 * h1 * h2
right_circ = x1c2 * One()

rules = get_simplify_rules()
push!(rules, CNOTHH_rule)

result = areequal(Val(:withrule), rules, left_circ, right_circ)
@show result

ncirc = egraph_simplify(left_circ, rules; verbose=true)
@show ncirc

left_circ = h2 * x2c1 * h2
@show left_circ
@show CNOTHH_rule(left_circ.expr)

"""end"""