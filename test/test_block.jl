using Metatheory
using SymbolicCircuit
using SymbolicCircuit: merge_block2yao, block_merge, is_block_merge



x1 = Gate(gX(), [Loc(1), ])
x2 = Gate(gX(), [Loc(2), ])
z1 = Gate(gZ(), [Loc(1), ])
z2 = Gate(gZ(), [Loc(2), ])
y1 = Gate(gY(), [Loc(1), ])
y2 = Gate(gY(), [Loc(2), ])

h1 = Gate(gH(), [Loc(1), ])
h2 = Gate(gH(), [Loc(2), ])


y3 = Gate(gY(), [Loc(3), ])

x23 = Gate(gX(), [Loc(2), Loc(3)])

x45 = Gate(gX(), [Loc(4), Loc(5)])
s3 = Gate(gS(), [Loc(3), ])
t3 = Gate(gT(), [Loc(3), ])
cnot_1c3 = Gate(gX(), [Loc(1), cLoc(3)])

rx1 = Gate(rX([:theta1, ]), [Loc(3), ])
rx2 = Gate(rX([:theta2, ]), [Loc(3), ])


b = block_merge(cnot_1c3, x1)
@show b
@show is_block_merge(x1, h2)
@show is_block_merge(x23, h2)
@show is_block_merge(b, h2)
@show is_block_merge(b, rx1)
@show block_merge(b, rx1)
@show block_merge(rx1, b)


using Yao
function test(block, circ, n_qubits)
    yao_gate = merge_block2yao(block, n_qubits)
    @show yao_gate

    yao_circ = to_yao(circ)

    a = zero_state(n_qubits) |> yao_gate
    b = zero_state(n_qubits) |> yao_circ

    @show a.state 
    @show b.state
    println()
end


block = Block([x1, z2], [1,2])
circ = x1 * z2
test(block, circ, 2)

block = Block([x1, h2], [1,2])
circ = x1 * h2
test(block, circ, 2)

block = Block([y1, x2, z1, h2], [1,2])
circ = y1 * x2 * z1 * h2
test(block, circ, 2)

block = Block([x1, y3, cnot_1c3], [1,3])
circ = x1 * y3 * cnot_1c3
test(block, circ, 3)