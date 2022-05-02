""" 
parallel block implementation, for example, [x1, y2, z3, x4] could be viewed as one parallel block, as they are applied on different qubits. 

each parallel block has two side: the left side and the right side

for example, [x1, y1, x2, y2, z3] could also be viewed as one parallel block, as commute rule is forbidden at each qubit and z3 could be seen at both side of this block. The left side of this block is [x1, x2, z3], the right side of this block is [y1, y2, z3]
"""



struct ParallelBlock <: Block
    gates::Vector{Gate}
    # indices::Vector{Int64}
end

# function ParallelBlock(gates::Vector{Gate})
    # return ParallelBlock(gates, Int64[])
# end

function qubit_visited_count(gates::Vector{<:Gate}, qubits_indices::Vector{Int})
    indices_count = zeros(Int32, length(qubits_indices))
    for gate in gates
        for i in loc_indices(gate)
            indices_count[i] += 1 
        end 
    end
    return indices_count
end

function nonzero_minimum(indices_count::Vector{<:Signed})
    mini = Inf 
    for count in indices_count
        if count > 0
            mini = min(mini, count)
        end 
    end 
    return mini
end

function is_parallel_block_merge(a::Gate, b::Gate, qubits_indices::Vector{Int})
    if !is_loc_intersect(a, b)
        return true 
    end

    indices_count = qubit_visited_count([a, b], qubits_indices)
    mini = nonzero_minimum(indices_count)
    mini == 1 && return true

    return false 
end


function is_parallel_block_merge(a::Block, b::Gate, qubits_indices::Vector{Int})

    if is_single_qubit(b)
        # index = loc_indices(b)[1]
        # indices_count = zeros(Int32, length(qubits_indices))
        # for gate in a.gates
        #     for i in loc_indices(gate)
        #         indices_count[i] += 1 
        #     end 
        # end
        # indices_count[index] += 1 
        gates = copy(a.gates)
        push!(gates, b)
        indices_count = qubit_visited_count(gates, qubits_indices)
        mini = nonzero_minimum(indices_count)
        
        # mini = 0 
        # for count in indices_count
        #     if count > 0
        #         mini = min(mini, count)
        #     end 
        # end 

        # if mini==1
        #     return true 
        # end 
        mini == 1 && return true
    end
    return false

end

function is_parallel_block_merge(a::Gate, b::Block, qubits_indices::Vector{Int})
    return is_parallel_block_merge(b, a, qubits_indices)
end

# import Base.(*)
# function (*)(a::T, b::T) where {T<:ParallelBlock}
#     theta = copy(a.theta)
#     append!(theta, b.theta)
#     return T(theta)
# end

function parallel_block_merge(a::Gate, b::Gate)
    bk = ParallelBlock([a, b])
    return :($(bk))
end


function parallel_block_merge(a::Block, b::Gate)
    gates = copy(a.gates)
    push!(gates, b)

    bk = ParallelBlock(gates)
    return :($(bk))
end


function parallel_block_merge(a::Gate, b::Block)
    gates = [a, ]
    append!(gates, b.gates)

    bk = ParallelBlock(gates)
    return :($(bk))
end

# function parallel_block_expand2expr(a::Block)
#     gates = a.gates

#     circ = head_circuit()
#     for g in gates 
#         circ *= g 
#     end
#     return circ.expr
# end

