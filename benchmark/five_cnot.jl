using SymbolicCircuit
using SymbolicCircuit: get_full_simplify_rules, get_gates, get_special_CNOT_rules

cnot2c1 = UGate(gX(), [Loc(2), cLoc(1)])
cnot3c2 = UGate(gX(), [Loc(3), cLoc(2)])
cnot3c1 = UGate(gX(), [Loc(3), cLoc(1)])

circ = cnot3c2 * cnot2c1 * cnot3c2 * cnot2c1 * cnot3c1

@show get_gates(circ)
show_length(circ)

# # to_yaoplot("./benchmark/five_cnot_circ.png", circ)
# rules = get_full_simplify_rules()
rules = get_special_CNOT_rules()
ncirc = egraph_simplify(circ, rules; verbose=true, timeout=500)
@show ncirc
show_length(ncirc)