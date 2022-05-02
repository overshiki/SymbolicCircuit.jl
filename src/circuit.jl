

mutable struct Circuit 
    expr::Union{Expr, One, Gate, Block, Real}
end

function dagger_circuit(circ::Circuit)
    r = dagger_rewriter()
    expr = circ.expr
    expr = r(expr)
    circuit = :((*)())
    append!(circuit.args, reverse(expr.args[2:end]))
    circuit = Circuit(circuit)
    return circuit
end

import Base.(*)
function (*)(a::Circuit, b::Circuit)
    circuit = :((*)())
    append!(circuit.args, a.expr.args[2:end])
    append!(circuit.args, b.expr.args[2:end])
    circuit = Circuit(circuit)
    return circuit
end

function (*)(a::Circuit, b::Union{Gate, Real, One, Block})
    circuit = :((*)())
    append!(circuit.args, a.expr.args[2:end])
    push!(circuit.args, b)
    circuit = Circuit(circuit)
    return circuit
end

function (*)(a::Gate, b::Union{Gate, Real, One, Block})
    circuit = :((*)())
    push!(circuit.args, a)
    push!(circuit.args, b)
    circuit = Circuit(circuit)
    return circuit
end

function head_circuit()
    return Circuit(:((*)()))
end

using MacroTools: postwalk
# function get_length(circ::Int)
#     @assert circ==0 
#     return 0
# end

# function get_length(::One)
#     return 0
# end

# function get_length(::Gate)
#     return 1
# end

# function get_length(circuit::Circuit)
#     circuit = circuit.expr
#     gates = []
#     postwalk(circuit) do x 
#         if typeof(x)==Gate
#             push!(gates, x)
#         end
#         return x 
#     end

#     return length(gates)
# end



# function get_gates(circuit::Circuit, ::Val{:withblock})
#     gates = get_gates(circuit)
#     ngates = []
#     for g in gates
#         if g isa Gate 
#             push!(ngates, g)
#         elseif g isa Block 
#             push!(ngates, g.gates)
#         else 
#             error()
#         end 
#     end 
#     return ngates
# end


function get_gates(circuit::Circuit)
    circuit = circuit.expr
    gates = []
    postwalk(circuit) do x 
        # @show x, x isa Gate || x isa One, typeof(x)
        # if x isa Expr 
        #     @show x.head, x.args
        # end
        if x isa Gate || x isa One || x isa Block
            push!(gates, x)
        end

        if x isa Expr 
            if x.head==:call && x.args[1]==:Gate 
                push!(gates, eval(x))
                # push!(gates, x)
            end 

            if x.head==:call && x.args[1]==:Block 
                push!(gates, eval(x))
            end 

        end

        return x 
    end
    return gates
end

function get_length(circuit::Circuit)
    return length(get_gates(circuit))
end

function show_length(circuit::Circuit)
    println("length of circuit: ", get_length(circuit))
end

function show_circuit(circuit::Circuit)
    gates = get_gates(circuit)
    for g in gates
        @show g
    end
    @show length(gates)
end

function rebuild_circuit(circuit::Circuit)
    gates = get_gates(circuit)
    return rebuild_circuit(gates)
end

function rebuild_circuit(gates::Vector)
    circ = head_circuit()
    for g in gates 
        circ *= g 
    end 
    return circ
end

function rebuild_circuit(g::Gate)
    circ = head_circuit()
    circ *= g 
    return circ
end

function rebuild_circuit(::One)
    circ = head_circuit()
    return circ
end


function union!(theta_set::Vector{Symbol}, theta_subset::Vector{Symbol})
    for theta in theta_subset
        if !(theta in theta_set)
            push!(theta_set, theta)
        end 
    end
end

function get_parameters(circuit::Circuit)
    gates = get_gates(circuit)
    thetas = Symbol[]
    for g in gates
        if g.g isa RG 
            union!(thetas, g.g.theta)
        end
    end
    return thetas
end


function count_gates(circuit::Circuit)
    """
    used to include the number of gates contained in blocks
    """
    gates = get_gates(circuit)
    count = []
    for g in gates 
        local _count = 0
        if g isa Gate 
            _count = 1 
        elseif g isa Block 
            _count = length(g.gates)
        else 
            error()
        end
        push!(count, _count)
    end

    println(sum(count))

end

function max_indices(gate::Gate, num_qubits)
    for index in loc_indices(gate)
        num_qubits = max(num_qubits, index)
    end 
    return num_qubits
end

function max_indices(b::Block, num_qubits)
    for gate in b.gates
        num_qubits = max_indices(gate, num_qubits)
    end 
    return num_qubits
end

function max_indices(circ::Circuit)
    num_qubits = 0
    for gate in get_gates(circ)
        num_qubits = max_indices(gate, num_qubits)
    end 
    return num_qubits
end