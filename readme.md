
# Symbolic system for Qauntum computing

### What does `SymbolicCircuit.jl` provide?

`SymbolicCircuit.jl` provides a symbolic system for representation of Quantum circuit, in which, one can manipulate Quantum circuit using term rewriting & equality saturation techniques. Using this package, one can easily define any syntactic rules of Quantum circuit(for example, mutation between two quantum gates), and apply it to term rewriting and equality saturation Modules provided by[ `Metatheory.jl` ](https://github.com/JuliaSymbolics/Metatheory.jl)(Yes, This project is highly dependent on and highly motivated by [`Metatheory.jl`](https://github.com/JuliaSymbolics/Metatheory.jl)). Doing so, tasks such as circuit simplification, equivalence detection, code generation become easily achievable.

### What is the symbolic system of `SymbolicCircuit.jl`
#### Quantum gates
In `SymbolicCircuit.jl`, Qauntum gate are expressed by the instance of `Gate` struct, for example, the Pauli X gate on 1st Qubit is defined by
```julia
using SymbolicCircuit
x1 = Gate(gX(), [Loc(1), ])
```
Where `gX()` represents the type of Pauli X, `Loc(1)` represents the gate is applied on Qubit 1.
We can also define multi-Qubit gate, for example, CNOT gate on 1st Qubit and controlled by 2nd Qubit
```julia
cnot_1c2 = Gate(gX(), [Loc(1), cLoc(2)])
```
Where `cLoc(2)` indicates the gate is controlled by 2nd Qubit

We can also define parametric gate such as rotate X, controlled by parameter `:theta`
```julia
rx = Gate(rX([:theta, ]), [Loc(3), ])
```
Since the simplifying many VQE circuits will often result in rotate gate controlled by multiple parameters(sum of multiple rotate angles), we also allow this
```julia
rx2 = Gate(rX([:theta1, :theta2, :theta3]), [Loc(3), ])
```
#### Quantum circuit
It is wellknown that, symbolically, Qauntum circuit is just a chain of quantum gate, applied from left to the right. In `SymbolicCircuit.jl`, we define Quantum circuit as expression of gates connected by `*` operator. 
```julia
using SymbolicCircuit
x1 = Gate(gX(), [Loc(1), ])
h2 = Gate(gH(), [Loc(2), ])
y3 = Gate(gY(), [Loc(3), ])
circ = head_circuit() * x1 * x1 * h2 * y3 * x1 * x1 * h2
```
This allows flexible ways of define a circuit, for example, we can also
```julia
using SymbolicCircuit
let circ = head_circuit()
    for _ in 1:2
        for g in [x1, h2, y3]  
            circ *= g 
        end 
    end
end
```
#### Syntactic rules
The core idea of `SymbolicCircuit.jl` is that Quantum circuit can be represented using symbolic expression and some rules(such as mutation rules) can be represented using syntactic rules. Then term rewriting & equality saturation system could be used to manipulate the circuit. In `SymbolicCircuit.jl`, we provide easy ways to define different type of syntactic rules one may imagined. For example, a simple commute rules and cancel rules can be defined
```julia
using SymbolicCircuit
using Metatheory

#commute rules
com_rule = @rule a b a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b)

#cancel rules
can_rule = @rule a b a::Gate * b::Gate => One() where is_cancel(a, b)

```
Where `is_commute` and `is_cancel` are functions provided in `src/gate.jl` to determine if two gates are commute and if they could be cancelled out. 
Currently, `is_commute` considers two cases:
    - gate `a` and gate `b` do not have common `Loc` or `cLoc`
    - gate `a/b` is a `Z|S|T` gate, and gate `b/a` is a `CNOT` gate, where `cLoc` of `b/a` has the same index with `Loc` of `a/b`
`is_cancel` considers two cases:
    - gate `a` and gate `b` are identical and they belong to unitary & Hermitian gate
    - gate `a/b` is the dagger version of gate `b/a`

Note that the rule defination process here is just a normal rule defination process in [`Metatheory.jl`](https://github.com/JuliaSymbolics/Metatheory.jl)(users can also define rewrite rule using `-->` and equality rule using `==`, following the document of [`Metatheory.jl`](https://github.com/JuliaSymbolics/Metatheory.jl)), what `SymbolicCircuit.jl` provides is a system of gate expression and circuit expression where[ `Metatheory.jl` ](https://github.com/JuliaSymbolics/Metatheory.jl)could be applied to. 

Addtionally, `SymbolicCircuit.jl` also provides some built-in rules for applications of circuit simplification, equivalance detection(and code generation in the next release). They are included in `src/rule.jl`. Users of `SymbolicCircuit.jl` could of course define more rules they would like to.  

#### Term rewriting & Equality saturation
The core operation of `SymbolicCircuit.jl` is to apply a variaty of syntactic rules to term rewriting & equality saturation system provided by [`Metatheory.jl`](https://github.com/JuliaSymbolics/Metatheory.jl), which allows powerful circuit manipulate functions. For example, term rewriting could be used to transform all Pauli Z gates in a circuit into `H X H` following rewriting rule `Z=HXH`. This could be easily handled using `SymbolicCircuit.jl`
```julia
using SymbolicCircuit
using SymbolicCircuit: is_Z, is_commute, is_cancel
using Metatheory
using Metatheory: PassThrough, Postwalk

x1 = Gate(gX(), [Loc(1), ])
y3 = Gate(gY(), [Loc(3), ])
z2 = Gate(gZ(), [Loc(2), ])
z3 = Gate(gZ(), [Loc(3), ])

circ = head_circuit() * x1 * z2 * y3 * z3 * x1 * z3

function get_HXH(a::Gate)
    h = Gate(gH(), a.loc)
    x = Gate(gX(), a.loc)
    return :($(h) * $(x) * $(h))
end

r = @rule a a::Gate => get_HXH(a) where is_Z(a)
r = Postwalk(PassThrough(r))
@show r(circ)
```
Of course, this is just a simple rewriting rule, and could be done using any non-symbolic systems such as direct coding in qisik|Yao.jl|mindquantum|...(for example, in mindquantum, circuits are represented as object of List class in python, such manipulation could be easily done using pop and insert operations). The full power of `SymbolicCircuit.jl` comes from the qquality saturation techniques in symbolic & compiler community. In equality saturation(Eqsat), the term rewriting are allowed to be handled without an order. For example, bidirectional rules such as gate commute rule `a*b==b*a` are allowed. The key point of Eqsat is that it allows all combination of rewriting operations to be stored in memory(usually in efficient EGraph data structure as implemented in [`Metatheory.jl`](https://github.com/JuliaSymbolics/Metatheory.jl)), and efficiently traversed. Thus one could set the search goal to search for specific expressions in all equivalent expressions resulted from the rewriting rules, which would be a complex task for non-symbolic systems without Eqsat techniques, such as qisik|Yao.jl|mindquantum|...
To demonstrate, let's consider circuit simplification operation. We consider only a combination of commute rule `a*b==b*a where a, b commute` and cancel rule `a*b->0 where a, b could be cancelled`. These simple rules already provide a strategy to simplify a circuit, i.e. for any pair of gates in a circuit, commute if possible, cancel if possible, and then try more commutation and cancellation, until no progress could be made. In a non-symbolic system without Eqsat, such strategy could only be implemented using a heuristic approach without a saturation guarantee(or it could have saturation guarantee but need a lot of codings). In `SymbolicCircuit.jl` it would be easily achiveable and has a guarantee that all possible combination are traversed.
```julia
using SymbolicCircuit
using Metatheory
using Metatheory.Library: @right_associative, @left_associative
v = AbstractRule[]
push!(v, @rule a b a::Gate * b::Gate => :($(b) * $(a)) where is_commute(a, b))
push!(v, @rule a b a::Gate * b::Gate => One() where is_cancel(a, b))
push!(v, @rule a b b::One * a::Gate => :($(a)))
push!(v, @rule a b a::Gate * b::One => :($(a)))

ra = @right_associative (*)
la = @left_associative (*)
push!(v, ra)
push!(v, la)

function simplify(circuit)
    g = EGraph(circuit)
    params = SaturationParams(timeout=10, eclasslimit=40000)
    report = saturate!(g, v, params)
    circuit = extract!(g, astsize)
    return circuit
end 

circ = head_circuit() * x1 * x1 * h2 * y3 * x1 * x1 * h2
ncirc = simplify(circ)
```
result:
```julia
Gate(gY(), Q[Loc(3)])
```

Another powerful function provided by the system is that, it allows to detect if two circuit are in equvilent in certain rules. For example, continue from the above circuit simplification task, just do
```julia
areequal(v, circ, ncirc)
```
result:
```julia
true
```
will tell if `circ` and `ncirc` are in equivalent under the rules `v`.


#### Practical usage 
For those want to use `SymbolicCircuit.jl` as openbox toolset for some practical task, `SymbolicCircuit.jl` currently provides built-in functions in: circuit simplification, equivalent detection, where a default set of syntactic rules is used. (more simplification target and code generation function are on the way)
The list of the functions are:

`egraph_simplify`: circuit simplification using default set of rules
```julia
circ = head_circuit() * x1 * x1 * h2 * y3 * x1 * x1 * h2
circ = egraph_simplify(circ, _simplify; verbose=false)
```
`areequal`: overload of `areequal` function in [`Metatheory.jl`](https://github.com/JuliaSymbolics/Metatheory.jl), using default set of rules
```julia
areequal(circ1, circ2, circ3)
```

#### More information
For more information, please refer to `test` folder. Issue and PR are welcomed.

#### Next step:
    - Some examples in example folder
    - More rewriting rules
    - T-gate reduction functions
    - Codegen for numerical simulation
    - Documentations!