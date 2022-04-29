using Yao

function gate2yao(x::G)
    if x isa gX 
        return :X 
    elseif x isa gY 
        return :Y 
    elseif x isa gZ 
        return :Z 
    elseif x isa gH 
        return :H 
    elseif x isa gT 
        return :T
    elseif x isa gS 
        return :S
    elseif x isa rX 
        return Rx(0.1)
    elseif x isa rY 
        return Ry(0.1)
    elseif x isa rZ 
        return Rz(0.1)
    end
end

function gate2yao(x::Gate, num_qubits)
    exprs = Expr[]
    if is_CNOT(x) #|| is_CNOTd(x)
        control_index = get_CNOT_loc_index(x, Val(:cloc))
        loc_index = get_CNOT_loc_index(x, Val(:loc))
        expr = :(cnot($control_index, $loc_index))
        push!(exprs, expr)
    elseif is_no_control(x)
        g = gate2yao(x.g)
        for loc in x.loc 
            index = loc.index
            expr = :(put($num_qubits, $index=>$g))
            push!(exprs, expr)
        end
    end
    return exprs
end


function to_yao(circ::Circuit; num_qubits=0)
    if num_qubits===0
        num_qubits = max_indices(circ)
    end

    yao_expr = Expr(:call, :chain, num_qubits)
    for gate in get_gates(circ)
        if gate isa Gate
            for expr in gate2yao(gate, num_qubits)
                push!(yao_expr.args, expr)
            end
        elseif gate isa Block
            push!(yao_expr.args, merge_block2yao_expr(gate, num_qubits))
        else 
            error()
        end
    end
    # println(yao_expr)
    return yao_expr |> eval
end


# function to_yao(circ::Expr; num_qubits=0)
#     if num_qubits===0
#         for gate in get_gates(circ)
#             for index in loc_indices(gate)
#                 num_qubits = max(num_qubits, index)
#             end 
#         end 
#     end

#     # yao_expr = Expr(:call, :chain, num_qubits)
#     yao_circ = chain()
#     for gate in get_gates(circ)
#         if gate isa Gate
#             for expr in gate2yao(gate)
#                 # push!(yao_expr.args, expr)
#                 push!(yao_circ, expr |> eval)
#             end
#         # elseif gate isa Block
#             # expr = 
#         end
#     end
#     # return yao_expr |> eval
#     return yao_circ
# end

using YaoPlots
using Compose, Cairo
function to_yaoplot(save_path::String, circ::Circuit; num_qubits=0)
    # circ = circ
    circ = to_yao(circ; num_qubits=num_qubits)
    vizcircuit(circ) |> PNG(save_path)
end