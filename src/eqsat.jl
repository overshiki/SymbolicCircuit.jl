using Metatheory.Schedulers

default_rule = get_simplify_rules()
block_rule = get_block_rules()


function _simplify(circuit, ::Val{:default_rule})
    return _simplify(circuit, default_rule)
end 

function _simplify(circuit, ::Val{:block_rule})
    return _simplify(circuit, block_rule)
end 

function _simplify(circuit, v::Vector{<:AbstractRule})

    g = EGraph(circuit)
    params = SaturationParams(timeout=10, eclasslimit=40000, scheduler=BackoffScheduler)
    report = saturate!(g, v, params)
    circuit = extract!(g, astsize)
    # println(report.reason)
    return circuit, report.reason
end 

function egraph_simplify(circuit, rule; verbose=false)
    return egraph_simplify(circuit, _simplify, rule; verbose=verbose)
end

function egraph_simplify(circuit, f::Function, rule; verbose=false)

    function _simp(circuit)
        circuit, reason = f(circuit, rule)
        if rule==Val(:default_rule)
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
    return areequal(default_rule, exprs...)
end