

struct Block 
    gates::Vector{Gate}
    indices::Vector{Int64}
end

function is_block_merge(a::Gate, b::Gate)
    indices1 = loc_indices(a)
    indices2 = loc_indices(b)

    if is_subset(indices1, indices2) || is_subset(indices2, indices1)
        return true 
    else 
        return false 
    end

end


function is_block_merge(a::Block, b::Gate)
    indices = loc_indices(b)
    if is_subset(indices, a.indices)
        return true 
    elseif length(a.indices) < 2 && length(indices)==2
        if is_subset(a.indices, indices)
            return true 
        end
    end

    return false 

end

function is_block_merge(a::Gate, b::Block)
    return is_block_merge(b, a)
end

import Base.(*)
function (*)(a::T, b::T) where {T<:Block}
    theta = copy(a.theta)
    append!(theta, b.theta)
    return T(theta)
end

function block_merge(a::Gate, b::Gate)
    indices = copy(loc_indices(a))
    indices2 = loc_indices(b)
    union!(indices, indices2)
    bk = Block([a, b], indices)
    return :($(bk))
end


function block_merge(a::Block, b::Gate)
    indices = copy(a.indices)
    indices2 = loc_indices(b)
    union!(indices, indices2)

    gates = copy(a.gates)
    push!(gates, b)

    bk = Block(gates, indices)
    return :($(bk))
end


function block_merge(a::Gate, b::Block)
    indices = copy(loc_indices(a))
    indices2 = b.indices
    union!(indices, indices2)

    gates = [a, ]
    append!(gates, b.gates)

    bk = Block(gates, indices)
    return :($(bk))
end

function block_expand(a::Block)
    gates = a.gates

    circ = head_circuit()
    for g in gates 
        circ *= g 
    end
    return circ
end