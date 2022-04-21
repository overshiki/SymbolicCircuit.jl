using Metatheory.Schedulers

default_rule = get_simplify_rules()
block_rule = get_block_rules()



function _simplify(circuit; rule=:default_rule)
    if rule==:default_rule
        v = default_rule
    elseif rule==:block_rule 
        v = block_rule 
    else 
        error()
    end 

    g = EGraph(circuit)
    # s = SimpleScheduler()
    params = SaturationParams(timeout=10, eclasslimit=40000, scheduler=BackoffScheduler)
    report = saturate!(g, v, params)
    circuit = extract!(g, astsize)
    # print(cansaturate(s))
    # println(report.reason)
    return circuit, report.reason
end 




#FIXME
using MacroTools: postwalk
function subbatch_simplify(circuit; batch_size=15, stride=5)
    for i in 0:stride:batch_size-1
        gates_expr = circuit.args[2:end]
        final_expr  = head_circuit()
        # for epoch in 0:Int(floor(length(gates_expr)/batch_size))
        for epoch in 1:batch_size:length(gates_expr)
            # @show epoch
            e_start = epoch + i
            e_end = min(e_start+batch_size-1, length(gates_expr))
            # if i==1
            @show e_start, e_end, length(gates_expr)
            # end
            
            if e_end > e_start

                if epoch==1
                    append!(final_expr.args, gates_expr[1:e_start-1])
                end

                if e_end - e_start + 1 == batch_size
                    expr_head  = head_circuit()
                    append!(expr_head.args, gates_expr[e_start:e_end])
                    expr, _ = _simplify(expr_head)
                    if isa(expr, Expr)
                        append!(final_expr.args, expr.args[2:end])
                    elseif expr isa Gate || expr isa One 
                        push!(final_expr.args, expr)
                    else
                        @show epoch, expr
                    end
                else 
                    append!(final_expr.args, gates_expr[e_start:e_end])
                end
            end
        end 

        circuit = rebuild_circuit(final_expr)
        if get_length(circuit) < batch_size
            break
        end
    end
    # println(circuit)
    circuit, reason = _simplify(circuit)

    return circuit, reason
end


function egraph_simplify(circuit, f::Function; verbose=false, rule=:default_rule)

    function _simp(circuit)
        circuit, reason = f(circuit; rule=rule)
        if rule==:default_rule
            circuit = rebuild_circuit(circuit)
        end
        return circuit, reason
    end

    i = 1
    count = 1
    while true
        len = get_length(circuit)
        circuit, reason = _simp(circuit)
        
        if verbose
            print(i, " ", reason, " ", len, " ")
            show_length(circuit)
            # println(circuit)
            println()
        end

        if reason==:saturated
            break 
        end

        if len<=get_length(circuit) 
            count += 1
        else 
            count = 1
        end
        
        if count > 10
            # println("early stop")
            break 
        end 

        i += 1
    end

    return circuit

end

function areequal(exprs...)
    return areequal(vrule, exprs...)
end