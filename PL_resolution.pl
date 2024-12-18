:- dynamic propozicija/1.
:- dynamic pretpostavka/1.
:- dynamic zakljucak/1.

:- initialization(clear_buffer).

clear_buffer :-
    retractall(propozicija(_)),
    retractall(pretpostavka(_)),
    retractall(zakljucak(_)).

:- op(810, fy, not).
:- op(820, xfy, and).
:- op(830, xfy, or).
:- op(840, xfy, ->).
:- op(850, xfy, <->).

start :-
    retractall(propozicija(_)),
    retractall(pretpostavka(_)),
    retractall(zakljucak(_)),

    write('Unesi ulaze (zavrsava se sa "end."): '), nl,
    read_inputs,
    write('Hvala! Unos je zavrsen.'), nl, nl,

    write('Propozicije unesene:'), nl,
    list_propozicije,
    write('Zakljucak unesen:'), nl,
    list_zakljucak,

    findall(X, pretpostavka(X), Pretpostavke0),
    zakljucak(Conclusion),
    simplify_expression(not(Conclusion), SimplifiedNegatedConclusion),
    append(Pretpostavke0, [SimplifiedNegatedConclusion], AllPretpostavke),

    clauses_to_literals(AllPretpostavke, ClauseIndexMap),

    write('Pretpostavke unesene (tablicni prikaz):'), nl,
    list_pretpostavke_with_labels(AllPretpostavke, 1),

    display_logical_consequence,

    write('\nPretpostavke u formatu C1, C2, ...:'), nl,
    list_pretpostavke_with_c_labels(AllPretpostavke, 1),
    write('----------------'), nl,

    resolution_proof(ClauseIndexMap).

read_inputs :-
    read(Input),
    ( Input == end ->
        true
    ; process_input(Input),
      read_inputs
    ).

process_input(propozicija(X)) :-
    assertz(propozicija(X)).
process_input(pretpostavka(Expression)) :-
    simplify_expression(Expression, SimplifiedExpression),
    ( SimplifiedExpression =.. [Op, A, B],
      member(Op, [or, and, ->, <->]) ->
        convert_to_cnf(Op, A, B, CNF),
        simplify_expression(CNF, SimplifiedCNF),
        flatten_conjunction(SimplifiedCNF, Components),
        assert_pretpostavke_list(Components)
    ; assertz(pretpostavka(SimplifiedExpression))
    ).
process_input(zakljucak(X)) :-
    assertz(zakljucak(X)).
process_input(Input) :-
    format('Nepoznat unos: ~w~n', [Input]).

simplify_expression(not(not(X)), Simplified) :-
    simplify_expression(X, Simplified).
simplify_expression(not(X), not(SimplifiedX)) :-
    simplify_expression(X, SimplifiedX).
simplify_expression((A and B), (SimplifiedA and SimplifiedB)) :-
    simplify_expression(A, SimplifiedA),
    simplify_expression(B, SimplifiedB).
simplify_expression((A or B), (SimplifiedA or SimplifiedB)) :-
    simplify_expression(A, SimplifiedA),
    simplify_expression(B, SimplifiedB).
simplify_expression(Expression, Expression).

convert_to_cnf(->, not(A), B, (A or B)) :- !.
convert_to_cnf(->, not(A), not(B), (A or not(B))) :- !.
convert_to_cnf(->, A, not(B), (not(A) or not(B))) :- !.
convert_to_cnf(<->, not(A), B, ((A or B) and (not(B) or not(A)))) :- !.
convert_to_cnf(<->, not(A), not(B), ((A or not(B)) and (B or not(A)))) :- !.
convert_to_cnf(<->, A, not(B), ((not(A) or not(B)) and (B or A))) :- !.
convert_to_cnf(->, A, B, (not(A) or B)) :- !.
convert_to_cnf(<->, A, B, ((not(A) or B) and (not(B) or A))) :- !.
convert_to_cnf(or, A, B, (A or B)) :- !.
convert_to_cnf(and, A, B, (A and B)) :- !.

flatten_conjunction(Expression, List) :-
    ( Expression = (A and B) ->
        flatten_conjunction(A, ListA),
        flatten_conjunction(B, ListB),
        append(ListA, ListB, List)
    ; List = [Expression]
    ).

assert_pretpostavke_list([]).
assert_pretpostavke_list([H|T]) :-
    assertz(pretpostavka(H)),
    assert_pretpostavke_list(T).

list_propozicije :-
    forall(propozicija(X), (write('- '), write(X), nl)).

list_pretpostavke_with_labels([], _).
list_pretpostavke_with_labels([H|T], N) :-
    format('~d) ~w~n', [N, H]),
    N1 is N + 1,
    list_pretpostavke_with_labels(T, N1).

list_zakljucak :-
    zakljucak(X), write('- '), write(X), nl.

display_logical_consequence :-
    findall(X, pretpostavka(X), Pretpostavke),
    zakljucak(Conclusion),
    conjunction_of_list(Pretpostavke, CombinedPretpostavke),
    format('\nPrema prvom metateoremu o logičkoj posljedici trebamo dokazati:\n', []),
    format('(~w) ∧ ¬(~w) ≡ ⊥\n', [CombinedPretpostavke, Conclusion]).

conjunction_of_list([X], Formatted) :-
    format(atom(Formatted), "(~w)", [X]), !.
conjunction_of_list([H|T], Combined) :-
    conjunction_of_list(T, Rest),
    format(atom(Combined), "(~w) ∧ ~w", [H, Rest]).

list_pretpostavke_with_c_labels([], _).
list_pretpostavke_with_c_labels([H|T], N) :-
    format('C~d: ~w~n', [N, H]),
    N1 is N + 1,
    list_pretpostavke_with_c_labels(T, N1).

clauses_to_literals(Clauses, ClauseIndexMap) :-
    clauses_to_literals(Clauses, 1, ClauseIndexMap).

clauses_to_literals([], _, []).
clauses_to_literals([Clause|Rest], Index, [(Index, Literals)|ClauseIndexMapRest]) :-
    clause_to_literals(Clause, Literals),
    NextIndex is Index + 1,
    clauses_to_literals(Rest, NextIndex, ClauseIndexMapRest).

clause_to_literals(Clause, Literals) :-
    simplify_expression(Clause, SimplifiedClause),
    clause_to_literals_simplified(SimplifiedClause, Literals).

clause_to_literals_simplified(Clause, Literals) :-
    ( Clause = (A or B) ->
        clause_to_literals_simplified(A, LiteralsA),
        clause_to_literals_simplified(B, LiteralsB),
        append(LiteralsA, LiteralsB, Literals)
    ; Literals = [Clause]
    ).

resolution_proof(ClauseIndexMap) :-
    initialize_clauses(ClauseIndexMap, InitialClauseSet),
    resolve_clauses(InitialClauseSet, []).

initialize_clauses([], []).
initialize_clauses([(Index, Literals)|Rest], [clause(Index, Literals, [])|ClausesRest]) :-
    initialize_clauses(Rest, ClausesRest).

resolve_clauses(Clauses, Processed) :-
    select(clause(Index1, Lits1, Origin1), Clauses, RestClauses),
    member(clause(Index2, Lits2, Origin2), RestClauses),
    resolve(Lits1, Lits2, ResolventLits),
    \+ member(clause(_, ResolventLits, _), Clauses),
    \+ member(clause(_, ResolventLits, _), Processed),
    max_clause_index([clause(Index1, Lits1, Origin1)|Clauses], MaxIndex),
    NewIndex is MaxIndex + 1,
    format('C~d: ', [NewIndex]),
    ( ResolventLits == [] ->
        write('⊥ '),
        format('res(C~d,C~d)~n', [Index1, Index2]),
        !
    ; write_clause(ResolventLits),
      format(' res(C~d,C~d)~n', [Index1, Index2]),
      NewClause = clause(NewIndex, ResolventLits, [Index1, Index2]),
      resolve_clauses([NewClause|Clauses], [clause(Index1, Lits1, Origin1), clause(Index2, Lits2, Origin2)|Processed])
    ).
resolve_clauses(Clauses, Processed) :-
    findall(clause(Index, [Lit], Origin),
            ( member(clause(Index, [Lit], Origin), Clauses),
              \+ member(Lit, [not(_), _] ) ),
            UnitClauses),
    ( UnitClauses \= [] ->
        simplify_with_unit_clauses(UnitClauses, Clauses, SimplifiedClauses),
        resolve_clauses(SimplifiedClauses, Processed)
    ;
        write('Resoluacija završena bez pronalaženja kontradikcije.'), nl
    ).

simplify_with_unit_clauses([], Clauses, Clauses).
simplify_with_unit_clauses([clause(Index, [Lit], _)|UnitRest], Clauses, SimplifiedClauses) :-
    exclude(contains_literal(Lit), Clauses, ClausesWithoutLit),
    negate(Lit, NegLit),
    remove_literal_from_clauses(NegLit, ClausesWithoutLit, NewClauses),
    simplify_with_unit_clauses(UnitRest, NewClauses, SimplifiedClauses).

contains_literal(Lit, clause(_, Literals, _)) :-
    member(Lit, Literals).

remove_literal_from_clauses(_, [], []).
remove_literal_from_clauses(Lit, [clause(Index, Literals, Origin)|Rest], [clause(Index, NewLiterals, Origin)|SimplifiedRest]) :-
    delete(Literals, Lit, NewLiterals),
    remove_literal_from_clauses(Lit, Rest, SimplifiedRest).

negate(not(X), X).
negate(X, not(X)).

max_clause_index(Clauses, MaxIndex) :-
    findall(Index, member(clause(Index, _, _), Clauses), Indices),
    max_list(Indices, MaxIndex).

resolve(Lits1, Lits2, ResolventLits) :-
    member(Lit, Lits1),
    complementary_literal(Lit, CompLit),
    member(CompLit, Lits2),
    delete(Lits1, Lit, RestLits1),
    delete(Lits2, CompLit, RestLits2),
    append(RestLits1, RestLits2, CombinedLits0),
    simplify_literals_list(CombinedLits0, CombinedLits1),
    sort(CombinedLits1, ResolventLits).

simplify_literals_list([], []).
simplify_literals_list([L|Ls], [SimplifiedL|SimplifiedLs]) :-
    simplify_expression(L, SimplifiedL),
    simplify_literals_list(Ls, SimplifiedLs).

complementary_literal(not(X), X).
complementary_literal(X, not(X)).

write_clause([]).
write_clause([Lit]) :-
    write_literal(Lit).
write_clause([Lit|Rest]) :-
    write_literal(Lit),
    write(' or '),
    write_clause(Rest).

write_literal(not(X)) :-
    write('not '), write(X).
write_literal(X) :-
    write(X).
