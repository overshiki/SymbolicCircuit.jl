using SymbolicCircuit
using SymbolicCircuit: get_tensor


param = Dict(:theta1=>10.0, :theta2=>0.5)
loc_mapping = Dict(1=>('i','j'), 2=>('k','l'), 3=>('p','q'))


display(get_tensor(gX()))
display(get_tensor(gY()))
display(get_tensor(gZ()))
display(get_tensor(gS()))
display(get_tensor(gT()))
display(get_tensor(gH()))
display(get_tensor(rZ([:theta1, :theta2]), param))
display(get_tensor(rY([:theta1, :theta2]), param))
display(get_tensor(rX([:theta1, :theta2]), param))


x1 = Gate(gX(), [Loc(1), ])
h2 = Gate(gH(), [Loc(2), ])
y3 = Gate(gY(), [Loc(3), ])
s3 = Gate(gS(), [Loc(3), ])
t3 = Gate(gT(), [Loc(3), ])
rx1 = Gate(rX([:theta1, Positive()]), [Loc(3), ])
rx2 = Gate(rX([:theta2, Negative()]), [Loc(3), ])


for g in [x1, h2, y3, s3, t3, rx1, rx2]
    local t, l = get_tensor(g, param, loc_mapping)
    display(t)
    println(l)
end


x23 = Gate(gX(), [Loc(2), Loc(3)])

ts, ls = get_tensor(x23, param, loc_mapping)
@show length(ts), ls

ts, ls = get_tensor([x1, h2, y3, x23], param, loc_mapping)
@show length(ts), ls, size(ts[1])

cnot_1c3 = Gate(gX(), [Loc(1), cLoc(3)])

ts, ls = get_tensor([x1, h2, y3, x23, cnot_1c3], param, loc_mapping)
@show length(ts), ls, size(ts[1])