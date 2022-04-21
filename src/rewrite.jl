using Metatheory: Prewalk, Postwalk, PassThrough, Chain, Fixpoint

function dagger_rewriter()
    r = @rule x x::Gate => to_dagger(x)
    r = Postwalk(PassThrough(r))
    return r
end

function get_HXH(a::Gate)
    h = Gate(gH(), a.loc)
    x = Gate(gX(), a.loc)
    return :($(h) * $(x) * $(h))
end

function z2hxh_rewriter()
    r = @rule a a::Gate => get_HXH(a) where is_Z(a)
    z2hxh = Postwalk(PassThrough(r))
    return z2hxh
end