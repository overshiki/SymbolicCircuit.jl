using SymbolicCircuit
using SymbolicCircuit: get_parallel_block_rules, block_simplify_rewriter

H0 = UGate(gH(), [Loc(4)])
H1 = UGate(gH(), [Loc(1)])
H2 = UGate(gH(), [Loc(2)])
H3 = UGate(gH(), [Loc(3)])

Z0 = UGate(gZ(), [Loc(4)])
Z1 = UGate(gZ(), [Loc(1)])
Z2 = UGate(gZ(), [Loc(2)])
Z3 = UGate(gZ(), [Loc(3)])

Y0 = UGate(gY(), [Loc(4)])
Y1 = UGate(gY(), [Loc(1)])
Y2 = UGate(gY(), [Loc(2)])
Y3 = UGate(gY(), [Loc(3)])

X0 = UGate(gX(), [Loc(4)])
X1 = UGate(gX(), [Loc(1)])
X2 = UGate(gX(), [Loc(2)])
X3 = UGate(gX(), [Loc(3)])

circ = H3 * H1 * Z2 * Y3 * Y3 * Z0 
circ *= H2 * H2 * X2 * X0 * Z0 * Y2 
circ *= X3 * Y1 * Y1 * Y1 * Z2 * H0
circ *= Z0 * Z2 * X3 * Y3 * X1 * X3
circ *= Y0 * Z3 * Y1 * H2 * Z1 * X0 


answer = H3 * H1 * Z2 * Z0 * X2 * X0 * Z0 * Y2 * Y1 * H0 
answer *= Z0 * Y3 * X1 * X3 * Y0 * Z3 * Y1 * H2 * Z1 * X0

count_gates(answer)
count_gates(circ)

rules = get_parallel_block_rules([1,2,3,4])
ncirc = egraph_simplify(circ, rules; timeout=20)

ncirc = Circuit(block_simplify_rewriter()(ncirc.expr))
# show_circuit(ncirc)
count_gates(ncirc)
println()

ncirc = egraph_simplify(circ, Val(:default_rule); timeout=20)
count_gates(ncirc)
println()