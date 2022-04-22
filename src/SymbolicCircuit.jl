module SymbolicCircuit

using Metatheory

include("set_utils.jl")
include("gate.jl")

export G, UHG, SG, RG, Hamiltonian, Pauli
export gX, gY, gZ, gS, gT, gH, rX, rY, rZ
export gXd, gYd, gZd, gSd, gTd, gHd, rXd, rYd, rZd
export Q, Loc, cLoc
export Gate, One


include("block.jl")
# export Block
# export is_block_merge, block_merge, block_expand


include("rule.jl")
export get_simplify_rules

include("rewrite.jl")
export z2hxh_rewriter, dagger_rewriter
include("circuit.jl")
export head_circuit, dagger_circuit

include("eqsat.jl")
export egraph_simplify

end # module
