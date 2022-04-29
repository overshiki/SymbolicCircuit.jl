using Metatheory.Library: @right_associative, @left_associative

ra_rule = @right_associative (*)
la_rule = @left_associative (*)

commute_rule = @rule a b a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b)
cancel_rule = @rule a b a::Gate * b::Gate => One() where is_cancel(a, b)
expand_rule = @rule a a::Gate => expand(a) where is_expand(a)
merge_rule = @rule a b a::Gate * b::Gate => merge(a, b) where is_merge(a, b)



# one_rules = [
#     @rule a b b::One * a::Gate => :($(a))
#     @rule a b a::Gate * b::One => :($(a))
#     @rule a b b::One * a::Real => :($(a))
#     @rule a b a::Real * b::One => :($(a))
# ]

# one_rules = [
#     @rule a b b::One * a::Gate --> a
#     @rule a b a::Gate * b::One --> a
#     @rule a b b::One * a::Real --> a
#     @rule a b a::Real * b::One --> a
# ]


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


"""rules that are equivalent up to a globle phase, may correct it in the future"""

HYH2Y_rule = @rule a b c a::Gate * b::Gate * c::Gate => generate_Y(a) where is_HYH(a, b, c)
Y2HYH_rule = @rule a a::Gate => generate_HYH(a) where is_Y(a)

XYZ_rule = @rule a b c a::Gate * b::Gate * c::Gate => One() where is_XYZ(a, b, c)
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

    push!(v, HYH2Y_rule)
    push!(v, Y2HYH_rule)
    # push!(v, XYZ_rule)


    return v
end
# function get_simplify_rules()
#     v = AbstractRule[]
#     #commute rule
#     vi = @rule a b a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b)
#     push!(v, vi)
#     #cancel rule
#     vi = @rule a b a::Gate * b::Gate => One() where is_cancel(a, b)
#     push!(v, vi)
#     #expand rule 
#     vi = @rule a a::Gate => expand(a) where is_expand(a)
#     push!(v, vi)
#     #merge rule
#     vi = @rule a b a::Gate * b::Gate => merge(a, b) where is_merge(a, b)
#     push!(v, vi)

#     #one rule 
#     """ waiting for the bugfix in Metatheory.jl"""
#     # vi = @rule a b b::One * a::Gate --> a::Gate
#     vi = @rule a b b::One * a::Gate => :($(a))
#     push!(v, vi)
#     vi = @rule a b a::Gate * b::One => :($(a))
#     push!(v, vi)
#     vi = @rule a b b::One * a::Real => :($(a))
#     push!(v, vi)
#     vi = @rule a b a::Real * b::One => :($(a))
#     push!(v, vi)

#     """ waiting for the bugfix in Metatheory.jl"""
#     # t = @theory a b c d e f begin
#     #     # #commute rules
#     #     a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b)
#     #     a::Gate * b::Gate => One() where is_cancel(a, b)
#     #     a::Gate => expand(a) where is_expand(a)
#     #     a::Gate * b::Gate => merge(a, b) where is_merge(a, b)

#     #     # one rule
#     #     b::One * a::Gate --> a::Gate 
#     #     a::Gate * b::One --> a::Gate

#     #     b::One * a::Real --> a::Real
#     #     a::Real * b::One --> a::Real
#     # end 

#     # append!(v, t)


#     ra = @right_associative (*)
#     la = @left_associative (*)
#     push!(v, ra)
#     push!(v, la)

#     return v 

# end

# block_merge_rules_include_RG = [
#     @rule a b a::Gate * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=false)
#     @rule a b a::Block * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=false)
#     @rule a b a::Gate * b::Block => block_merge(a, b) where is_block_merge(a, b; exclude_RG=false)
# ]

block_merge_rules_include_RG = @theory a b begin 
    a::Gate * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=false)
    a::Block * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=false)
    a::Gate * b::Block => block_merge(a, b) where is_block_merge(a, b; exclude_RG=false)
end



# block_merge_rules_exclude_RG = [
#     @rule a b a::Gate * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=true)
#     @rule a b a::Block * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=true)
#     @rule a b a::Gate * b::Block => block_merge(a, b) where is_block_merge(a, b; exclude_RG=true)
# ]


block_merge_rules_exclude_RG = @theory a b begin 
    a::Gate * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=true)
    a::Block * b::Gate => block_merge(a, b) where is_block_merge(a, b; exclude_RG=true)
    a::Gate * b::Block => block_merge(a, b) where is_block_merge(a, b; exclude_RG=true)
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


# function get_block_rules()
#     v = AbstractRule[]

#     #commute rule
#     push!(v, @rule a b a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b))
#     #block merge rules 
#     push!(v, @rule a b a::Gate * b::Gate => block_merge(a, b) where is_block_merge(a, b))
#     push!(v, @rule a b a::Block * b::Gate => block_merge(a, b) where is_block_merge(a, b))
#     push!(v, @rule a b a::Gate * b::Block => block_merge(a, b) where is_block_merge(a, b))
#     #block expand rules 
#     push!(v, @rule a a::Block => block_expand(a))

#     """ waiting for the bugfix in Metatheory.jl"""
#     # t = @theory a b c d e f begin
#     #     a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b)

#     #     a::Gate * b::Gate => block_merge(a, b) where is_block_merge(a, b)
#     #     a::Block * b::Gate => block_merge(a, b) where is_block_merge(a, b)
#     #     a::Gate * b::Block => block_merge(a, b) where is_block_merge(a, b)

#     #     a::Block => block_expand(a)
#     # end 

#     # append!(v, t)


#     ra = @right_associative (*)
#     la = @left_associative (*)
#     push!(v, ra)
#     push!(v, la)

#     return v 

# end


# get_simplify_rules()
# get_block_rules()