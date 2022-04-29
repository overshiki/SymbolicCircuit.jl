

struct Block 
    gates::Vector{Gate}
    indices::Vector{Int64}
end

function is_block_merge(a::Gate, b::Gate; exclude_RG=true)
    indices1 = loc_indices(a)
    indices2 = loc_indices(b)

    if is_subset(indices1, indices2) || is_subset(indices2, indices1)
        if (!isa(a.g, RG) && !isa(b.g, RG)) || !exclude_RG
            return true 
        end
    end

    return false 

end


function is_block_merge(a::Block, b::Gate; exclude_RG=true)
    if !isa(b.g, RG) || !exclude_RG
        indices = loc_indices(b)
        if is_subset(indices, a.indices)
            return true 
        elseif length(a.indices) < 2 && length(indices)==2
            if is_subset(a.indices, indices)
                return true 
            end
        end
    end

    return false 

end

function is_block_merge(a::Gate, b::Block; exclude_RG=true)
    return is_block_merge(b, a; exclude_RG=exclude_RG)
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

function block_expand2expr(a::Block)
    gates = a.gates

    circ = head_circuit()
    for g in gates 
        circ *= g 
    end
    return circ.expr
end

function block_expand(a::Block, indices_mapping::Dict)
    gates = a.gates

    circ = head_circuit()
    for g in gates 
        loc = [typeof(l)(indices_mapping[l.index]) for l in g.loc]
        if g.g isa RG 
            theta = g.g.theta
            ng = typeof(g)(typeof(g.g)(theta), loc)
        else
            ng = typeof(g)(typeof(g.g)(), loc)
        end
        circ *= ng
    end
    return circ
end

using YaoToEinsum
function block2tensor(a::Block)
    indices = sort(a.indices)
    indices_mapping = Dict(indices.=>collect(1:length(indices)))

    circ = block_expand(a, indices_mapping)
    circ = to_yao(circ)
    code, tensors = YaoToEinsum.yao2einsum(circ)
    return code(tensors...)
end

function merge_block2yao(a::Block, num_qubits)
    # indices = sort(a.indices)
    # t = block2tensor(a)
    # @show size(t)
    # t = reshape(t, (4,4))
    # g = put(num_qubits, indices=>matblock(t; nlevel=2))
    g = merge_block2yao_expr(a, num_qubits) |> eval
    return g 
end

function merge_block2yao_expr(a::Block, num_qubits)
    indices = sort(a.indices)
    t = block2tensor(a)
    if length(size(t))==4
        t = reshape(t, (4,4))
    end 
    @assert length(size(t))==2
    g = :(put($num_qubits, $indices=>matblock($t; nlevel=2)))
    return g 
end