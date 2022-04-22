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

    circuit = rebuild_circuit(circuit)
    return circuit

end

import Metatheory: EGraph, EClassId, AbstractENode, AbstractRule, addexpr!, EqualityGoal, reached

function _areequal(theory::Vector, exprs...; params=SaturationParams())
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


function areequal(::Val{:default_rule}, exprs...)
    nexprs = Expr[]
    for expr in exprs 
        if get_length(expr)==1
            expr *= One()
        end
        push!(nexprs, expr)
    end

    params = SaturationParams(timeout=100, eclasslimit=400000, scheduler=BackoffScheduler)
    return _areequal(default_rule, nexprs...; params=params)
end