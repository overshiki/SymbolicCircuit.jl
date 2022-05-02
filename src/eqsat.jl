using Metatheory.Schedulers

default_rule = get_simplify_rules()
block_rule = get_block_rules()


function _simplify(circuit::Circuit, ::Val{:default_rule}, timeout)
    return _simplify(circuit, default_rule, timeout)
end 

function _simplify(circuit::Circuit, ::Val{:block_rule}, timeout)
    return _simplify(circuit, block_rule, timeout)
end 

function _simplify(circuit::Circuit, v::Vector{<:AbstractRule}, timeout)
    circuit = circuit.expr
    g = EGraph(circuit)
    params = SaturationParams(timeout=timeout, eclasslimit=400000, scheduler=BackoffScheduler)
    report = saturate!(g, v, params)
    circuit = extract!(g, astsize)
    circuit = Circuit(circuit)
    # println(report.reason)
    return circuit, report
end 

function egraph_simplify(circuit::Circuit, rule; verbose=false, timeout=100, repeat=3)
    return egraph_simplify(circuit, _simplify, rule; verbose=verbose, timeout=timeout, repeat=repeat)
end

function egraph_simplify(circuit::Circuit, f::Function, rule; verbose=false, timeout=100, repeat=3)

    function _simp(circuit)
        circuit, report = f(circuit, rule, timeout)
        # if rule==Val(:default_rule)
        circuit = rebuild_circuit(circuit)
        # end
        return circuit, report
    end

    i = 1
    count = 1
    while true
        len = get_length(circuit)
        circuit, report = _simp(circuit)
        reason = report.reason
        
        if verbose
            print(i, " ", reason, " ")
            show_length(circuit)
            # println(circuit)
            println()
        end

        if reason==:saturated
            if verbose
                println("saturated")
            end
            break 
        end

        if len<=get_length(circuit) 
            count += 1
        else 
            count = 1
        end
        
        if count > repeat
            if verbose
                println(report)
                println("early stop")
            end
            break 
        end 

        i += 1
    end

    circuit = rebuild_circuit(circuit)
    return circuit

end

import Metatheory: EGraph, EClassId, AbstractENode, AbstractRule, addexpr!, EqualityGoal, reached

function _areequal(theory::Vector, exprs...)
    params = SaturationParams(timeout=100, eclasslimit=400000, scheduler=BackoffScheduler)
    g = EGraph(exprs[1])
    _areequal(g, theory, exprs...; params=params)
end

function _areequal(g::EGraph, t::Vector{<:AbstractRule}, exprs...; params=SaturationParams())
    # @log "Checking equality for " exprs
    if length(exprs) == 1; return true end
    # rebuild!(G)

    # @log "starting saturation"

    n = length(exprs)
    ids = Vector{EClassId}(undef, n)
    nodes = Vector{AbstractENode}(undef, n)
    for i ∈ 1:n
        ec, node = addexpr!(g, exprs[i])
        ids[i] = ec.id
        nodes[i] = node
    end

    goal = EqualityGoal(collect(exprs), ids)
    
    # alleq = () -> (all(x -> in_same_set(G.uf, ids[1], x), ids[2:end]))

    params.goal = goal
    # params.stopwhen = alleq

    report = saturate!(g, t, params)

    if report.reason in [:goalreached, :saturated]
        return reached(g, goal)
    else
        return report.reason 
    end

    # # display(g.classes); println()
    # if !(report.reason === :saturated) && !reached(g, goal)
    #     @show report.reason
    #     return missing # failed to prove
    # end
    # @show report.reason
    # return reached(g, goal)
end


function areequal(::Val{:default_rule}, circs...)
    # exprs = [x.expr for x in circs]
    # ncirc = Circuit[]
    # for circ in circs 
    #     if get_length(circ)==1
    #         circ *= One()
    #     end
    #     push!(ncirc, circ)
    # end

    # nexprs = [x.expr for x in ncirc]
    
    # return _areequal(default_rule, nexprs...)

    return areequal(Val(:withrule), default_rule, circs...)
end


function areequal(::Val{:withrule}, rules, circs...)
    # exprs = [x.expr for x in circs]
    ncirc = Circuit[]
    for circ in circs 
        if get_length(circ)==1
            circ *= One()
        end
        push!(ncirc, circ)
    end

    nexprs = [x.expr for x in ncirc]
    
    return _areequal(rules, nexprs...)
end