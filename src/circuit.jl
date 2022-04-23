

function dagger_circuit(expr)
    r = dagger_rewriter()
    expr = r(expr)
    circuit = :((*)())
    append!(circuit.args, reverse(expr.args[2:end]))
    return circuit
end

import Base.(*)
function (*)(a::Expr, b::Expr)
    circuit = :((*)())
    append!(circuit.args, a.args[2:end])
    append!(circuit.args, b.args[2:end])
    return circuit
end

function (*)(a::Expr, b::Union{Gate, Real, One})
    circuit = :((*)())
    append!(circuit.args, a.args[2:end])
    push!(circuit.args, b)
    return circuit
end

function (*)(a::Gate, b::Gate)
    circuit = :((*)())
    push!(circuit.args, a)
    push!(circuit.args, b)
    return circuit
end

function head_circuit()
    return :((*)())
end

using MacroTools: postwalk
function get_length(circ::Int)
    @assert circ==0 
    return 0
end

function get_length(::One)
    return 0
end

function get_length(::Gate)
    return 1
end

function get_length(circuit::Expr)
    gates = []
    postwalk(circuit) do x 
        if typeof(x)==Gate
            push!(gates, x)
        end
        return x 
    end

    return length(gates)
end

function show_length(circuit)
    println("length of circuit: ", get_length(circuit))
end

function get_gates(circuit, ::Val{:withblock})
    gates = get_gates(circuit)
    ngates = []
    for g in gates
        if g isa Gate 
            push!(ngates, g)
        elseif g isa Block 
            push!(ngates, g.gates)
        else 
            error()
        end 
    end 
    return ngates
end


function get_gates(circuit)
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

function show_circuit(circuit)
    gates = get_gates(circuit)
    for g in gates
        @show g
    end
    @show length(gates)
end

function rebuild_circuit(circuit::Expr)
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

function get_parameters(circuit)
    gates = get_gates(circuit)
    thetas = Symbol[]
    for g in gates
        if g.g isa RG 
            union!(thetas, g.g.theta)
        end
    end
    return thetas
end
