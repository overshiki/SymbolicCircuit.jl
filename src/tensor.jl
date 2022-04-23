
zero_c = 0.0+0.0im 
one_c = 1.0+0.0im


function real2complex(r)
    return r+0.0im
end

function get_tensor(::gX)
    [zero_c one_c; 
    one_c zero_c]
end

function get_tensor(::gXd)
    m = get_tensor(gX())
    return collect(m')
end

function get_tensor(::gY)
    [zero_c -1.0im; 
    1.0im zero_c]
end

function get_tensor(::gZ)
    [one_c zero_c; 
    zero_c -one_c]
end

function get_tensor(::gS)
    [one_c zero_c; 
    zero_c 1.0im]
end

function get_tensor(::gT)
    [one_c zero_c; 
    zero_c exp(im*pi/4)]
end

function get_tensor(::gH)
    1/sqrt(2) .* [one_c one_c; 
                one_c -one_c]
end


function get_theta(g::RG, param::Dict)
    theta = 0
    coeff = 1.0
    for sym in g.theta
        if sym isa Positive
            coeff *= 1
        elseif sym isa Negative
            coeff *= (-1)
        elseif sym isa Symbol
            theta += param[sym]
        else 
            error()
        end
    end
    theta *= coeff
    return theta
end

function get_tensor(g::rZ, param::Dict)
    theta = get_theta(g, param)

    [exp(im*theta/2) zero_c;
    zero_c exp(im*(-1)*theta/2)]
end

function get_tensor(g::rY, param::Dict)
    theta = get_theta(g, param)

    [real2complex(cos(theta/2)) real2complex(sin(theta/2));
    real2complex(-sin(theta/2)) real2complex(cos(theta/2))]

end

function get_tensor(g::rX, param::Dict)
    theta = get_theta(g, param)

    [real2complex(cos(theta/2)) im*sin(theta/2);
    im*sin(theta/2) real2complex(cos(theta/2))]

end


function get_cnot_tensor()
    tensor = [one_c zero_c zero_c zero_c;
    zero_c one_c zero_c zero_c;
    zero_c zero_c zero_c one_c;
    zero_c zero_c one_c zero_c]
    tensor = reshape(tensor, (2,2,2,2))
    return tensor
end

function get_tensor(g::Gate, ::Val{:cnot})
    t = get_cnot_tensor()
    loc_out, cloc_out, loc_in, cloc_in = nothing, nothing, nothing, nothing
    for loc in g.loc 
        index = loc.index
        if loc isa Loc 
            loc_in, loc_out = loc_mapping[index]
        elseif loc isa cLoc 
            cloc_in, cloc_out = loc_mapping[index]
        else 
            error()
        end
    end
    @assert all([loc_out, cloc_out, loc_in, cloc_in] .!== nothing)
    lm = (loc_out, cloc_out, loc_in, cloc_in)
    return t, lm
end


function has_cloc(g::Gate)
    for loc in g.loc 
        if loc isa cLoc
            return true 
        end 
    end 
    return false
end

function get_tensor(g::Gate, param::Dict, loc_mapping::Dict)
    if length(g.loc)==1
        index = g.loc[1].index
        if g.g isa RG 
            return [get_tensor(g.g, param), ], [loc_mapping[index], ]
        else
            return [get_tensor(g.g), ], [loc_mapping[index], ]
        end
    elseif is_CNOT(g) || is_CNOTd(g)
        t, lm = get_tensor(g, Val(:cnot))
        return [t, ], [lm, ]

    else 
        @assert !has_cloc(g)
        lm = [loc_mapping[x] for x in loc_indices(g)]
        t = [get_tensor(g.g) for _ in 1:length(lm)]
        return t, lm
    end
end

using OMEinsum
function get_tensor(gs::Vector{Gate}, param::Dict, loc_mapping::Dict)
    tensors, indices = [], []
    for g in gs
        t, lm = get_tensor(g, param, loc_mapping)
        append!(tensors, t)
        append!(indices, lm)
    end

    out_indices = String[]
    for ind in indices
        union!(out_indices, Vector{String}([ind...]))
    end
    out_indices = tuple(out_indices...)

    # @show tuple(indices...), out_indices

    tensor_out = einsum(EinCode(tuple(indices...), out_indices), tuple(tensors...))
    return [tensor_out, ], [out_indices, ]
end