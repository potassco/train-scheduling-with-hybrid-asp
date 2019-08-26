%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This encoding creates points in time where
% a train can be late. The points are spread
% in a linear fashion.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#const pen_init = 180000. % currently maximum of 900000
#const pen_steps = 5.

dpenalty_aux(1,1).
dpenalty_aux(pen_init,pen_init-1).
dpenalty_aux(pen_init*X,(pen_init*X-pen_init*(X-1))) :- X=2..pen_steps.

%%% dpenalty(T,P) - beeing late by at least T seconds adds P amount of penalty to the solution
dpenalty(T,X,Y) :- dpenalty_aux(X,Y), X <= D, delta(T,D).
dpenalty(T,D,D-High) :- delta(T,D),
                        Max = #max{0; Z : dpenalty_aux(Z,_)},
                        Max > D,
                        High = #max{0; Z : dpenalty_aux(Z,_), Z < D}.

                 
