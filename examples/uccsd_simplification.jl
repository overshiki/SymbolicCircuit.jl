using PyCall

py"""
from mindquantum.algorithm.nisq.chem import HardwareEfficientAnsatz
from mindquantum import RY, RZ, Z

from openfermion.chem import MolecularData
from openfermionpyscf import run_pyscf
from mindquantum import Hamiltonian
from mindquantum.simulator import Simulator

from mindquantum.core.operators import InteractionOperator
from mindquantum.core.operators.utils import get_fermion_operator
from mindquantum.algorithm.nisq.chem import Transform

def get_qubit_hamiltonian(mol, transform_type='JW'):
    m_ham = mol.get_molecular_hamiltonian()
    int_ham = InteractionOperator(*(m_ham.n_body_tensors.values()))
    f_ham = get_fermion_operator(int_ham)
    if transform_type=='BK':
        q_ham = Transform(f_ham).bravyi_kitaev()
    elif transform_type=='JW':
        q_ham = Transform(f_ham).jordan_wigner()
    else:
        raise ValueError()
    return q_ham



from mindquantum import Circuit, X, RX, Hamiltonian, Simulator, generate_uccsd

def get_uccsd_ansatz(molecule_of):
    hf_state_circuit = Circuit([X.on(i) for i in range(molecule_of.n_electrons)])
    upccsd_circuit,_,_,_,_,_ = generate_uccsd(molecule_of, th=-1)
    total_circuit = hf_state_circuit + upccsd_circuit
    # total_circuit.summary()
    return total_circuit

def get_circuit(molecule_of):
    circ = get_uccsd_ansatz(molecule_of)
    circ.summary()

    gates_name, gates_q, gates_cq = [], [], []
    gates_coeff = []
    barrier_count = 0
    for gate in circ:
        if gate.name != "BARRIER":
            # print(gate, gate.name, gate.obj_qubits, gate.ctrl_qubits, gate.coeff)
            gates_name.append(gate.name)
            gates_q.append(gate.obj_qubits)
            gates_cq.append(gate.ctrl_qubits)
            gates_coeff.append(gate.coeff)
        else:
            barrier_count += 1
    
    print("barrier_count: {}".format(barrier_count))

    return gates_name, gates_q, gates_cq, gates_coeff


def get_Ham(molecule_of, femion_mapping='JW'):
    hamiltonian_QubitOp = get_qubit_hamiltonian(molecule_of, transform_type=femion_mapping).compress()
    # return molecule_of, Hamiltonian(hamiltonian_QubitOp)
    # print(hamiltonian_QubitOp)
    # print(type(hamiltonian_QubitOp))

    # print(hamiltonian_QubitOp.coefficient)
    terms, coeffs = [], []
    for term, coeff in sorted(hamiltonian_QubitOp.terms.items()):
        # print(term, coeff)
        terms.append(term)
        coeffs.append(coeff)

    return terms, coeffs

def get_system(dist=1.5, ):
    
    geometry = [
        ["H", [0.0, 0.0, 0.0 * dist]],
        ["H", [0.0, 0.0, 1.0 * dist]],
    ]


    basis = "sto3g"
    spin = 0
    # print("Geometry: \n", geometry)

    molecule_of = MolecularData(
        geometry,
        basis,
        multiplicity=2 * spin + 1
    )
    molecule_of = run_pyscf(
        molecule_of,
        run_scf=1,
        run_ccsd=1,
        run_fci=1
    )
    return molecule_of

    # for ham in hamiltonian_QubitOp:
        # print(ham)

def get_all():
    molecule_of = get_system()
    gates_name, gates_q, gates_cq, gates_coeff = get_circuit(molecule_of)
    terms, coeffs = get_Ham(molecule_of)
    return gates_name, gates_q, gates_cq, gates_coeff, terms, coeffs

"""

using Metatheory

include("../src/gate.jl")
include("../src/rule.jl")
include("../src/rewrite.jl")
include("../src/circuit.jl")
include("../src/eqsat.jl")


function generate_circuit(gates_name, gates_q, gates_cq, gates_coeff)
    name_dict = Dict("X"=>gX, "Y"=>gY, "Z"=>gZ, "H"=>gH, "T"=>gT, "S"=>gS, 
    "RX"=>rX, "RY"=>rY, "RZ"=>rZ)

    # circuit = :((+)())
    circuit = head_circuit()
    for (name, q, cq, coeff) in zip(gates_name, gates_q, gates_cq, gates_coeff)
        # if isa(name_dict[name], typeof(UHG))
        gtype = name_dict[name]
        if gtype<:UHG || gtype<:SG
            @assert length(cq) <= 1
            @assert coeff==nothing

            if length(cq)==1
                g = Gate(gtype(), [Loc(q), cLoc(cq[1])])
            else
                g = Gate(gtype(), [Loc(q), ])
            end
            # circuit *= :($(g))
            circuit *= g
        elseif gtype<:RG
            @assert length(cq) == 0 
            coeff = Vector{Symbol}([Symbol(x) for x in keys(coeff)])
            g = Gate(gtype(coeff), [Loc(q), ])
            # circuit *= :($(g))
            circuit *= g
        else 
            error()
        end
    end
    return circuit
end