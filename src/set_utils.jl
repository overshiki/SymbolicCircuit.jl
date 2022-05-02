

function unique_elements(ind1::Vector{T}) where {T}
    ind2 = []
    union!(ind2, ind1)
    return ind2
end

function union!(ind1::Vector{T}, ind2::Vector{T}) where {T}
    for ind in ind2
        union!(ind1, ind)
    end
end

function union!(v::Vector{T}, a::T) where {T}
    if !(a in v)
        push!(v, a)
    end 
end

function is_set_identity(a::Vector{T}, b::Vector{T}) where {T}
    if is_subset(a, b) && is_subset(b, a) && length(a)==length(b)
        return true 
    else 
        return false 
    end
end

function is_subset(atom::T, larger_atom_vec::Vector{T}) where {T}
    return atom in larger_atom_vec
end

function is_subset(atom_vec::Vector{T}, larger_atom_vec::Vector{T}) where {T}
    check = true 
    for atom in atom_vec
        check = check && is_subset(atom, larger_atom_vec)
    end 
    return check

end

function is_intersect(indices1::Vector{T}, indices2::Vector{T}) where {T}
    # return length(get_intersect(vec1, vec2))>0
    check = false
    for index in indices1
        if index in indices2
            check = true 
        end 
    end 
    return check
end

function get_intersect(vec1::Vector{T}, vec2::Vector{T}) where {T}
    rvec = T[]
    for v1 in vec1
        if v1 in vec2
            push!(rvec, v1)
        end 
    end 
    return rvec
end 

function get_complement(inner_vec::Vector{T}, outer_vec::Vector{T}) where {T}
    com = T[]
    for symbol in outer_vec 
        if !(symbol in inner_vec)
            push!(com, symbol)
        end 
    end
    return com
end