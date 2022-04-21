using Metatheory
using SymbolicCircuit

@rule a b a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b)

t = @theory a b begin
    #commute rules
    a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b)
end

@rule a b b::One * a::Gate --> a::Gate

t = @theory a b begin
    #commute rules
    b::One * a::Gate --> a::Gate
end