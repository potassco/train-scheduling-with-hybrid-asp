%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This part optimizes the delay of each train.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

{ late(T,V,D,W) : visit(T,V) } :- potlate(T,V,D,W). 

next(T,V,D,D') :- potlate(T,V,D,_), potlate(T,V,D',_), D<D',
                  not potlate(T,V,D'',_) : potlate(T,V,D'',_), D''>D, D''<D'. 
:- not late(T,V,D,_), late(T,V,D',_), next(T,V,D,D').

topo_late(T,N,D,W) :- late(T,V,D,W), node_pos(T,V,N).

&diff{ 0-(T,N) } <= -D  :- topo_late(T,N,D,W).
&diff{ (T,M)-0 } <=  N  :- not topo_late(T,M,D,W), potlate(T,V,D,W), 
                           N=D-1, visit(T,V), node_pos(T,V,M).

#minimize{ W@1,T,N,D : topo_late(T,N,D,W) }.

