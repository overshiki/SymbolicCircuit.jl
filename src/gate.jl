# module GateModule

# export G, UHG, SG, RG, Hamiltonian, Pauli
# export gX, gY, gZ, gS, gT, gH, rX, rY, rZ
# export gXd, gYd, gZd, gSd, gTd, gHd, rXd, rYd, rZd
# export Q, Loc, cLoc
# export Gate
# export is_commute, is_cancel, is_expand, is_merge
# export expand, merge


abstract type G end

abstract type UHG <: G end
abstract type SG <: G end
abstract type RG <: G end

abstract type Hamiltonian <: G end

struct Pauli <:Hamiltonian 
    mapping::Dict
end

# abstract type CliffordG <: G end

struct gX <:UHG end
struct gY <:UHG end
struct gZ <:UHG end
struct gH <:UHG end

struct gT <:SG end
struct gS <:SG end


struct rX <:RG 
    theta::Vector{Any}
end

struct rY <:RG 
    theta::Vector{Any}
end

struct rZ <:RG 
    theta::Vector{Any}
end


struct A <: Hamiltonian end 
struct Ad <: Hamiltonian end



"""dagger gate"""
struct gXd <:UHG end
struct gYd <:UHG end
struct gZd <:UHG end
struct gHd <:UHG end

struct gTd <:SG end
struct gSd <:SG end







struct One end
struct Positive end
struct Negative end


struct rXd <:RG 
    theta::Vector{Any}
end

struct rYd <:RG 
    theta::Vector{Any}
end

struct rZd <:RG 
    theta::Vector{Any}
end




import Base.(*)
function (*)(a::T, b::T) where {T<:RG}
    theta = copy(a.theta)
    append!(theta, b.theta)
    return T(theta)
end

abstract type Q end

struct Loc <: Q
    index::Int64
end

struct cLoc <: Q
    index::Int64
end

struct Gate 
    g::G
    loc::Vector{Q}
end

# struct CommuteClause
#     gate1::Gate
#     gate2::Gate
# end

# struct Clause
#     gate1::Gate
#     gate2::Gate
# end

# struct Circuit 
#     gates::Tuple{Gate}
#     Circuit(gates...) = new(gates)
# end

dagger_dict = Dict(gX=>gXd, gY=>gYd, gZ=>gZd, gH=>gHd, gT=>gTd, gS=>gSd, rX=>rXd, rY=>rYd, rZ=>rZd)
rev_dagger_dict = Dict(values(dagger_dict).=> keys(dagger_dict))
merge!(dagger_dict, rev_dagger_dict)

function gate2string(g::Gate)
    type_dict = Dict(gX=>"X", gY=>"Y", gZ=>"Z", 
                    gH=>"H", gT=>"T", gS=>"S", 
                    rX=>"RX", rY=>"RY", rZ=>"RZ", 
                    gXd=>"X_dagger", gYd=>"Y_dagger", 
                    gZd=>"Z_dagger", gHd=>"H_dagger", 
                    gTd=>"T_dagger", gSd=>"S_dagger", 
                    rXd=>"RX_dagger", rYd=>"RY_dagger", rZd=>"RZ_dagger")

    g_str = type_dict[typeof(g.g)]
    for loc in g.loc 
        if isa(loc, Loc)
            g_str = g_str * " " * string(loc.index)
        elseif isa(loc, cLoc)
            g_str = g_str * " " * "c"*string(loc.index)
        end 
    end 
    return g_str
end


function loc_indices(a::Gate)
    indices = [x.index for x in a.loc]
    return indices
end


function is_loc_intersect(a::Gate, b::Gate)
    indices1 = loc_indices(a)
    indices2 = loc_indices(b)
    check = false
    for index in indices1
        if index in indices2
            check = true 
        end 
    end 
    return check
end

function is_loc_identity(a::Gate, b::Gate)
    indices1 = loc_indices(a)
    indices2 = loc_indices(b)
    check = is_set_identity(indices1, indices2)

    return check
end

function is_loc_type_identity(a::Gate, b::Gate)
    check = true
    for loca in a.loc 
        for locb in b.loc 
            if loca.index==locb.index 
                if isa(loca, Loc)
                    check = check && isa(locb, Loc)
                elseif isa(loca, cLoc)
                    check = check && isa(locb, cLoc)
                end 
            end 
        end 
    end 
    return check
end

function is_gate_type_identity(a::Gate, b::Gate)
    return typeof(a.g)==typeof(b.g)
end

function is_cancel(a::Gate, b::Gate)
    if is_loc_identity(a, b) && is_loc_type_identity(a, b) && is_gate_type_identity(a, b) && isa(a.g, UHG)
        return true 
    end 

    if is_AAdagger(a, b)
        return true 
    end

    return false
end

function is_gate_type_inverse(a::Gate, b::Gate)
    if isa(a.g, Hamiltonian) || isa(b.g, Hamiltonian)
        return false
    else
        return typeof(a.g)==dagger_dict[typeof(b.g)]
    end
end

function is_AAdagger(a::Gate, b::Gate)
    if is_loc_identity(a, b) && is_loc_type_identity(a, b) && is_gate_type_inverse(a, b)
        if isa(a.g, Union{UHG, SG})
            return true
        elseif isa(a.g, RG)
            if is_set_identity(a.g.theta, b.g.theta)
                return true 
            end
        else 
            error()
        end
    end

    return false
end


function is_no_control(a::Gate)
    for loc in a.loc 
        if loc isa cLoc 
            return false 
        end 
    end 
    return true
end

function is_single_qubit(a::Gate)
    return length(a.loc)==1
end

function is_Z(a::Gate)
    check = isa(a.g, gZ)
    check = check && is_single_qubit(a)
    return check
end

function is_X(a::Gate)
    check = isa(a.g, gX)
    check = check && is_single_qubit(a)
    return check
end


function is_Y(a::Gate)
    check = isa(a.g, gY)
    check = check && is_single_qubit(a)
    return check
end

function is_H(a::Gate)
    check = isa(a.g, gH)
    check = check && is_single_qubit(a)
    return check
end

function is_T(a::Gate)
    check = isa(a.g, gT)
    check = check && is_single_qubit(a)
    return check
end

function is_S(a::Gate)
    check = isa(a.g, gS)
    check = check && is_single_qubit(a)
    return check
end

function get_CNOT_loc_index(a::Gate, ::Val{:loc})
    for loc in a.loc 
        if loc isa Loc 
            return loc.index 
        end 
    end
end

function get_CNOT_loc_index(a::Gate, ::Val{:cloc})
    for loc in a.loc 
        if loc isa cLoc 
            return loc.index 
        end 
    end
end

function is_CNOT(a::Gate)
    if isa(a.g, gX)
        if length(a.loc)==2
            if isa(a.loc[1], Loc) || isa(a.loc[2], Loc)
                if isa(a.loc[1], cLoc) || isa(a.loc[2], cLoc)
                    return true 
                end 
            end 
        end 
    end
    return false 
end


function is_CNOT_T_commute(a::Gate, b::Gate)
    if is_CNOT(a) && (is_T(b) || is_S(b) || is_Z(b))
        for loc in a.loc 
            if isa(loc, cLoc)
                index = loc.index 
                if index == b.loc[1].index 
                    return true 
                end 
            end 
        end 
    end 
    return false 
end





"""some dagger rule"""

function is_Zd(a::Gate)
    check = isa(a.g, gZd)
    check = check && is_single_qubit(a)
    return check
end

function is_Xd(a::Gate)
    check = isa(a.g, gXd)
    check = check && is_single_qubit(a)
    return check
end

function is_Yd(a::Gate)
    check = isa(a.g, gYd)
    check = check && is_single_qubit(a)
    return check
end


function is_Hd(a::Gate)
    check = isa(a.g, gHd)
    check = check && is_single_qubit(a)
    return check
end


function is_Td(a::Gate)
    check = isa(a.g, gTd)
    check = check && is_single_qubit(a)
    return check
end

function is_Sd(a::Gate)
    check = isa(a.g, gSd)
    check = check && is_single_qubit(a)
    return check
end

function is_CNOTd(a::Gate)
    if isa(a.g, gXd)
        if length(a.loc)==2
            if isa(a.loc[1], Loc) || isa(a.loc[2], Loc)
                if isa(a.loc[1], cLoc) || isa(a.loc[2], cLoc)
                    return true 
                end 
            end 
        end 
    end
    return false 
end


function is_CNOTd_Td_commute(a::Gate, b::Gate)
    if is_CNOTd(a) && (is_Td(b) || is_Sd(b) || is_Zd(b))
        for loc in a.loc 
            if isa(loc, cLoc)
                index = loc.index 
                if index == b.loc[1].index 
                    return true 
                end 
            end 
        end 
    end 
    return false 
end






















function is_commute(a::Gate, b::Gate)
    if !is_loc_intersect(a, b)
        return true 
    end 

    if is_CNOT_T_commute(a, b) || is_CNOT_T_commute(b, a)
        return true 
    end 

    if is_CNOTd_Td_commute(a, b) || is_CNOTd_Td_commute(b, a)
        return true 
    end 


    return false

end

function is_r_merge(a::Gate, b::Gate)
    if is_single_qubit(a) && is_single_qubit(b)
        if is_loc_identity(a, b) && is_gate_type_identity(a, b) && is_loc_type_identity(a, b)
            if isa(a.g, RG)
                return true 
            end 
        end 
    end
    return false
end


function is_expand(a::Gate)
    if is_S(a) 
        return true 
    elseif is_Sd(a) 
        return true 
    elseif is_Z(a) 
        return true
    elseif is_Zd(a) 
        return true 
    end 
    return false
end



function expand(a::Gate)
    if is_S(a)
        index = a.loc[1].index
        g = Gate(gT(), [Loc(index), ])
        return :($(g) * $(g))

    elseif is_Sd(a)
        index = a.loc[1].index
        g = Gate(gTd(), [Loc(index), ])
        return :($(g) * $(g))

    elseif is_Z(a)
        index = a.loc[1].index
        g = Gate(gS(), [Loc(index), ])
        return :($(g) * $(g))

    elseif is_Zd(a)
        index = a.loc[1].index
        g = Gate(gSd(), [Loc(index), ])
        return :($(g) * $(g))
    end 
    error()
end







function is_merge(a::Gate, b::Gate)
    if is_loc_identity(a, b)
        if is_S(a) && is_S(b)
            return true 
        elseif is_Sd(a) && is_Sd(b)
            return true 
        elseif is_T(a) && is_T(b)
            return true
        elseif is_Td(a) && is_Td(b)
            return true 
        elseif is_r_merge(a, b)
            return true
        end 
    end 
    return false
end

function merge(a::Gate, b::Gate)
    if is_S(a)
        g = Gate(gZ(), a.loc)
        return :($(g))

    elseif is_Sd(a)
        g = Gate(gZd(), a.loc)
        return :($(g))

    elseif is_T(a)
        g = Gate(gS(), a.loc)
        return :($(g))

    elseif is_Td(a)
        g = Gate(gSd(), a.loc)
        return :($(g))

    elseif is_r_merge(a, b)
        g = Gate(a.g*b.g, a.loc)
        return :($(g))
    end 
    error()
end


function to_cancel(a::Gate, b::Gate)
    if is_cancel(a, b)
        return :(One())
    else 
        return :($a * $b)
    end
end


function to_dagger(a::Gate)
    if isa(a.g, Union{UHG, SG})
        g = Gate(dagger_dict[typeof(a.g)](), a.loc)
    elseif isa(a.g, RG)
        theta = a.g.theta
        g = Gate(dagger_dict[typeof(a.g)](theta), a.loc)
    else 
        error()
    end

    return :($(g))
end


"""generate from vacumm"""
function generate_HXH(a::Gate)
    h = Gate(gH(), a.loc)
    x = Gate(gX(), a.loc)
    return :($(h) * $(x) * $(h))
end

function generate_HZH(a::Gate)
    h = Gate(gH(), a.loc)
    z = Gate(gZ(), a.loc)
    return :($(h) * $(z) * $(h))
end

function generate_HYH(a::Gate)
    h = Gate(gH(), a.loc)
    y = Gate(gY(), a.loc)
    return :($(h) * $(y) * $(h))
end

function is_HXH(a::Gate, b::Gate, c::Gate)
    return is_H(a)&&is_X(b)&&is_H(c)&&is_loc_identity(a, b)&&is_loc_identity(a, c)
end

function is_HZH(a::Gate, b::Gate, c::Gate)
    return is_H(a)&&is_Z(b)&&is_H(c)&&is_loc_identity(a, b)&&is_loc_identity(a, c)
end
function is_HYH(a::Gate, b::Gate, c::Gate)
    return is_H(a)&&is_Y(b)&&is_H(c)&&is_loc_identity(a, b)&&is_loc_identity(a, c)
end

function is_XYZ(a::Gate, b::Gate, c::Gate)
    return is_X(a)&&is_Y(b)&&is_Z(c)&&is_loc_identity(a, b)&&is_loc_identity(a, c)
end


function generate_Z(a::Gate)
    z = Gate(gZ(), a.loc)
    return :($z)
end


function generate_X(a::Gate)
    x = Gate(gX(), a.loc)
    return :($x)
end

function generate_Y(a::Gate)
    x = Gate(gY(), a.loc)
    return :($x)
end

"""generate from vacumm end"""

# end