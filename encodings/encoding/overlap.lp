
seq(T,T',R,C,C') :- decided(T,T',R,C,C').

%%% resource_chunk_overlap(T,R,C,R',C') - the resource_chunk (R,C) of train T shares an edge with resource_chunk (R',C')
resource_chunk_overlap(T,R,C,R',C') :- resource_chunk(T,R,C,ID), resource_chunk(T,R',C',ID), R != R'.
:- seq(T,T',R,C,C'),
   resource_chunk_overlap(T,R,C,R',D),
   resource_chunk_overlap(T',R,C',R',D'),
   1 #sum {1 : route(T,ID), resource_chunk(T,R,C,ID),    resource_chunk(T,R',D,ID),
               route(T',ID'), resource_chunk(T',R,C',ID'), resource_chunk(T',R',D',ID')},
   not seq(T,T',R',D,D'), 1 #sum{1 : shared(T,T',R',D,D'); 1 : decided(T,T',R',D,D'); 1 : decided(T',T,R',D',D)}.


