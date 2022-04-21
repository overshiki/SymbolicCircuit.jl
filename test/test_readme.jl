using SymbolicCircuit

x1 = Gate(gX(), [Loc(1), ])
cnot_1c2 = Gate(gX(), [Loc(1), cLoc(2)])
rx = Gate(rX([:theta, ]), [Loc(3), ])

x1 = Gate(gX(), [Loc(1), ])
h2 = Gate(gH(), [Loc(2), ])
y3 = Gate(gY(), [Loc(3), ])
circ = head_circuit() * x1 * x1 * h2 * y3 * x1 * x1 * h2

let circ = head_circuit()
    for _ in 1:2
        for g in [x1, h2, y3]  
            circ *= g 
        end 
    end
end

@show circ

using SymbolicCircuit: is_Z, is_commute, is_cancel
using Metatheory
using Metatheory: PassThrough, Postwalk
#commute rules
com_rule = @rule a b a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b)

#cancel rules
can_rule = @rule a b a::Gate * b::Gate => One() where is_cancel(a, b)

x1 = Gate(gX(), [Loc(1), ])
y3 = Gate(gY(), [Loc(3), ])
z2 = Gate(gZ(), [Loc(2), ])
z3 = Gate(gZ(), [Loc(3), ])

circ = head_circuit() * x1 * z2 * y3 * z3 * x1 * z3

function get_HXH(a::Gate)
    h = Gate(gH(), a.loc)
    x = Gate(gX(), a.loc)
    return :($(h) * $(x) * $(h))
end

r = @rule a a::Gate => get_HXH(a) where is_Z(a)
r = Postwalk(PassThrough(r))
@show r(circ)

using SymbolicCircuit
using Metatheory
using Metatheory.Library: @right_associative, @left_associative
v = AbstractRule[]
push!(v, @rule a b a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b))
push!(v, @rule a b a::Gate * b::Gate => One() where is_cancel(a, b))
push!(v, @rule a b b::One * a::Gate => :($(a)))
push!(v, @rule a b a::Gate * b::One => :($(a)))

ra = @right_associative (*)
la = @left_associative (*)
push!(v, ra)
push!(v, la)

function simplify(circuit)
    g = EGraph(circuit)
    params = SaturationParams(timeout=10, eclasslimit=40000)
    report = saturate!(g, v, params)
    circuit = extract!(g, astsize)
    return circuit
end 

circ = head_circuit() * x1 * x1 * h2 * y3 * x1 * x1 * h2
ncirc = simplify(circ)

areequal(v, circ, ncirc)