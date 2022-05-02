using Metatheory.Library: @right_associative, @left_associative

ra_rule = @right_associative (*)
la_rule = @left_associative (*)

commute_rule = @rule a b a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b)
cancel_rule = @rule a b a::Gate * b::Gate => One() where is_cancel(a, b)
expand_rule = @rule a a::Gate => expand(a) where is_expand(a)
merge_rule = @rule a b a::Gate * b::Gate => merge(a, b) where is_merge(a, b)


"""could be used, but does not work well"""
# commute_rule = @rule a b a::Gate * b::Gate --> b * a where is_commute(a, b)
# cancel_rule = @rule a b a::Gate * b::Gate --> One() where is_cancel(a, b)
"""end"""


one_rules = @theory a b begin 
    b::One * a::Gate --> a
    a::Gate * b::One --> a
    b::One * a::Real --> a
    a::Real * b::One --> a
end



"""some rewrite rules"""
to_dagger_rule = @rule x x::Gate => to_dagger(x)
Z2HXH_rule = @rule a a::Gate => generate_HXH(a) where is_Z(a)
HXH2Z_rule = @rule a b c a::Gate * b::Gate * c::Gate => generate_Z(a) where is_HXH(a, b, c)

X2HZH_rule = @rule a a::Gate => generate_HZH(a) where is_X(a)
HZH2X_rule = @rule a b c a::Gate * b::Gate * c::Gate => generate_X(a) where is_HZH(a, b, c)
"""some rewrite rules end"""

"""cnot rules"""

function check_H_CNOT(a::Gate, b::Gate, c::Gate, d::Gate, e::Gate)
    check = true 
    check = check && is_H(a) && is_H(b) && is_CNOT(c) && is_H(d) && is_H(e)
    check = check && (!is_gate_type_inverse(a, b) && !is_gate_type_inverse(a, c) && !is_gate_type_inverse(a, d) && !is_gate_type_inverse(a, e))

    index_a = loc_indices(a)[1]
    index_b = loc_indices(b)[1]
    index_d = loc_indices(d)[1]
    index_e = loc_indices(e)[1]

    check = check && (index_a!==index_b) && (index_d!==index_e)
    check = check && (((index_a==index_d) && (index_b==index_e)) || ((index_a==index_e) && (index_b==index_d)))

    index_i, index_j = loc_indices(c)
    check = check && (((index_i==index_a) && (index_j==index_b)) || ((index_j==index_a) && (index_i==index_b)))
    return check
end

function invert_CNOT_indices(c::Gate)
    index, c_index = nothing, nothing
    for l in c.loc
        if l isa Loc 
            index = l.index
        elseif l isa cLoc 
            c_index = l.index 
        else 
            error()
        end 
    end 

    g = typeof(c)(gX(), [Loc(index), cLoc(c_index)])
    # return :($g)
    return g
end

function invert_CNOT_indices2expr(c::Gate)
    g = invert_CNOT_indices(c)
    return :($g)
end

H_CNOT2CNOT_rule = @rule a b c d e a::Gate * b::Gate * c::Gate * d::Gate * e::Gate => invert_CNOT_indices2expr(c) where check_H_CNOT(a, b, c, d, e)

function get_H_CNOT(c::Gate)
    index_i, index_j = loc_indices(c)
    a = typeof(c)(gH(), [Loc(index_i)])
    b = typeof(c)(gH(), [Loc(index_j)])
    return :($a * $b * $c * $a * $b)
end

CNOT2H_CNOT_rule = @rule a a::Gate => get_H_CNOT(a) where is_CNOT(a)

function get_CNOT_normalindex(a::Gate)
    index = nothing 
    for l in a.loc 
        if l isa Loc 
            index = l.index 
        end 
    end 
    return index
end

function get_CNOT_controlindex(a::Gate)
    index = nothing 
    for l in a.loc 
        if l isa cLoc 
            index = l.index 
        end 
    end 
    return index
end


function is_CNOT_HH(a::Gate, b::Gate, c::Gate)
    check = true 
    check = check && is_H(a) && is_CNOT(b) && is_H(c)
    check = check && !is_gate_type_inverse(a, b) && !is_gate_type_inverse(a, c)

    index = get_CNOT_normalindex(b)

    a_index = loc_indices(a)[1]
    c_index = loc_indices(c)[1]
    check = check && a_index==index && c_index==index
    return check

end

function invert_CNOT_HH(a::Gate, b::Gate, c::Gate)
    bd = invert_CNOT_indices(b)
    index = get_CNOT_controlindex(b)

    h = typeof(a)(gH(), [Loc(index)])

    return :($h * $bd * $h)
end

CNOTHH_rule = @rule a b c a::Gate * b::Gate * c::Gate => invert_CNOT_HH(a, b, c) where is_CNOT_HH(a, b, c)

function is_CNOTthree(a::Gate, b::Gate, c::Gate)
    check = !is_gate_type_inverse(a, b) && !is_gate_type_inverse(a, c)
    check = check && is_CNOT(a) && is_CNOT(b) && is_CNOT(c)
    check = check && is_loc_identity(a, b) && is_loc_identity(a, c)

    a_index = get_CNOT_normalindex(a)
    c_index = get_CNOT_normalindex(c)
    check = check && a_index==get_CNOT_controlindex(b) && a_index==c_index
    return check
end

function get_CNOT_HH(b::Gate)
    index = get_CNOT_normalindex(b)
    h = typeof(b)(gH(), [Loc(index)])
    return :($h * $b * $h)
end

CNOTthree2CNOTHH_rule = @rule a b c a::Gate * b::Gate * c::Gate => get_CNOT_HH(b) where is_CNOTthree(a, b, c)


function get_CNOTthree(b::Gate)
    cindex = get_CNOT_normalindex(b)
    index = get_CNOT_controlindex(b)
    cnot = typeof(b)(gX(), [Loc(index), cLoc(cindex)])
    return :($cnot * $b * $cnot)
end

CNOTHH2CNOTthree_rule = @rule a b c a::Gate * b::Gate * c::Gate => get_CNOTthree(b) where is_CNOT_HH(a, b, c)

"""end"""




"""rules that are equivalent up to a globle phase, may correct it in the future"""

HYH2Y_rule = @rule a b c a::Gate * b::Gate * c::Gate => generate_Y(a) where is_HYH(a, b, c) #HYH = -Y
Y2HYH_rule = @rule a a::Gate => generate_HYH(a) where is_Y(a)

XYZ_rule = @rule a b c a::Gate * b::Gate * c::Gate => One() where is_XYZ(a, b, c) #XYZ = iI
"""end"""



function get_simplify_rules()
    v = AbstractRule[]
    push!(v, ra_rule)
    push!(v, la_rule)
    push!(v, commute_rule)
    push!(v, cancel_rule)
    push!(v, expand_rule)
    push!(v, merge_rule)
    append!(v, one_rules)
    return v
end


function get_full_simplify_rules()
    v = get_simplify_rules()
    push!(v, Z2HXH_rule)
    push!(v, X2HZH_rule)
    push!(v, HXH2Z_rule)
    push!(v, HZH2X_rule)

    push!(v, H_CNOT2CNOT_rule)
    push!(v, CNOT2H_CNOT_rule)
    return v
end

function get_special_CNOT_rules()
    v = AbstractRule[]
    push!(v, ra_rule)
    push!(v, la_rule)
    push!(v, commute_rule)
    push!(v, cancel_rule)
    append!(v, one_rules)

    push!(v, H_CNOT2CNOT_rule)
    push!(v, CNOT2H_CNOT_rule)
    push!(v, CNOTHH_rule)
    push!(v, CNOTthree2CNOTHH_rule)
    push!(v, CNOTHH2CNOTthree_rule)
    return v
end

function get_equivalent_simplify_rules()
    v = get_full_simplify_rules()
    push!(v, HYH2Y_rule)
    push!(v, Y2HYH_rule)
    push!(v, XYZ_rule)

end

block_merge_rules_include_RG = @theory a b begin 
    a::Gate * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=false)
    a::Block * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=false)
    a::Gate * b::Block => block_merge(a, b) where is_block_merge(a, b; exclude_RG=false)
end



block_merge_rules_exclude_RG = @theory a b begin 
    a::Gate * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=true)
    a::Block * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=true)
    a::Gate * b::Block => block_merge(a, b) where is_block_merge(a, b; exclude_RG=true)
end


function get_parallel_block_merge_rules(qubits_indices::Vector{Int})
    parallel_block_merge_rules = @theory a b begin 
        a::Gate * b::Gate => parallel_block_merge(a, b) where is_parallel_block_merge(a, b, qubits_indices)
        a::Block * b::Gate => parallel_block_merge(a, b) where is_parallel_block_merge(a, b, qubits_indices)
        a::Gate * b::Block => parallel_block_merge(a, b) where is_parallel_block_merge(a, b, qubits_indices)
    end
    return parallel_block_merge_rules
end


block_expand_rule = @rule a a::Block => block_expand2expr(a)

function get_block_rules(;exclude_RG=true)
    v = AbstractRule[]
    push!(v, la_rule)
    push!(v, ra_rule)
    push!(v, commute_rule)
    push!(v, block_expand_rule)
    if exclude_RG
        append!(v, block_merge_rules_exclude_RG)
    else 
        append!(v, block_merge_rules_include_RG)
    end
    return v
end


function get_parallel_block_rules(qubits_indices::Vector{Int})
    v = AbstractRule[]
    push!(v, la_rule)
    push!(v, ra_rule)
    push!(v, commute_rule)
    push!(v, block_expand_rule)

    parallel_block_merge_rules = get_parallel_block_merge_rules(qubits_indices)
    append!(v, parallel_block_merge_rules)

    return v
end

