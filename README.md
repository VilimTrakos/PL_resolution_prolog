# **Task**
My task was to implement the resolution algorithm for propositional logic (PL) in the chosen logical programming language (e.g., Prolog, HiLog, Flora-2). The program should allow for the input of basic propositions, the input of assumptions (formulas describing the state of the world), and the conclusion to be proven (a formula). It should also output the process of normalization (CNF) and the resolution-based proof of the conclusion.
Instructions:
For data input, the Prolog format can be used, e.g.,

proposition(a).
proposition(b).
assumption(a, '=>', b).

This would represent the formula a⇒ba⇒b. Of course, other (more practical) notations using operators are also possible. Input can be manual or, for instance, loaded from a file.
After loading the problem description, it is necessary to construct a formula using the appropriate metatheorem of logical consequence for which resolution will attempt to demonstrate a contradiction. The formula must be normalized (into CNF) and a representative of the formula obtained over which the resolution process will be conducted.
For the implementation of the normalization process, pay attention to the rules provided in the lecture materials and the examples from lab exercises related to operators.


 ** My program does not support loading input from file! **

# **Algoritm i implemented is: ** 
function PL-Resolution(KB, q)
// KB, the knowledge base. a sentence in prop logic.
// q, the query, a sentence in prop logic
    clauses = contra(KB, q) // CNF representation of KB ∧ ¬q
    new = {}
    do
        for each pair of clauses Ci, Cj in clauses
            resolvents = PL-Resolve(Ci, Cj)
            if resolvents contains the empty clause
                return true
            new = new + resolvents
        if new is subset of clauses
            return false
        clauses = clauses + new

Credit for algorytham [![Francisco Iacobelli]()](https://www.youtube.com/embed/PMm5Mat0MRA?si=ePvcH01FnXt-Lze4)

# Example input is:
```
start.
propozicija(a).
propozicija(b).
propozicija(a -> b).
zakljucak(b).
end.
```
