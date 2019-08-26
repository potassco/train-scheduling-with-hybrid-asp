%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All preprocessing takes place here.
% We do compute bgroups, aka "Belegungsgruppen",
% subsumed resources (resources that are not
% needed), and
% collision_free-points where we can ensure that two
% trains will never actually meet in time.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% topographically sort nodes
node(T,(V;V'))   :- edge(T,ID,V,V').

node_count(T,V,0) :- start(T,V).
node_count(T,V',N+1) :- node_count(T,V,N), edge(T,ID,V,V').
node_pos(T,V,M) :- node(T,V), M = #max {N : node_count(T,V,N)}.

last_node(T,M)   :- train(T), M = #max{ P : node_pos(T,V,P), end(T,V) },
                    M!=#inf.

%%% bgroups aka "Belegungsgruppen"
%%% bresource(X,R) - bgroup X contains resource R
%%% bgroup(X,T,ID) - bgroup X affects train T on edge ID
bresource((T,ID,T',ID'),R)   :- collision_free_connection(T,ID,T',ID',R).
bgroup((T,ID,T',ID'),T,ID)   :- collision_free_connection(T,ID,T',ID',_).
bgroup((T,ID,T',ID'),T',ID') :- collision_free_connection(T,ID,T',ID',_).

bgroup(X,T,(V',V'')) :- bgroup(X,T,(V,V')), edge(T,V',V''), bresource(X,R),
                        resource(R,(V',V'')).
bgroup(X,T,(V'',V))  :- bgroup(X,T,(V,V')), edge(T,V'',V), bresource(X,R),
                        resource(R,(V'',V)).

bgroup(X,T',ID') :- bgroup(X,T,ID),   bresource((T,ID,T',ID'),R), bresource(X,R).
bgroup(X,T,ID)   :- bgroup(X,T',ID'), bresource((T,ID,T',ID'),R), bresource(X,R).

% collision_free meeting point for shared connections
collision_free(T,T',R,C,C') :- bgroup(I,T,ID), bgroup(I,T',ID'), bresource(I,R), resource_chunk(T,R,C,ID), resource_chunk(T',R,C',ID'), T != T'.

%%% subsumed resources
%%% redundant_resource(T,R)  - resource R is redundant for train T and does not need to be considered
%%% resource_chunk(T,R,C,ID) - resource chunk (R,C) includes edge ID
%%% resource_chunk_entry(T,R,C,E) - train T can enter resource_chunk (R,C) earliest at time E
%%% resource_chunk_exit(T,R,C,L)  - train T can leave resource_chunk (R,C) latest at time L
% resource R is not subsumed by R'
nsubsumed(R,R') :- resource(R',ID), not resource(R,ID), resource(R,_), R != R', b(R,B), b(R',B'), B>=B'.
% R subsumes R'
subsumed(R,R') :- not nsubsumed(R,R'), resource(R,_), resource(R',_), R != R', nsubsumed(R',R), b(R,B), b(R',B'), B>=B'.
subsumed(R,R') :- not nsubsumed(R,R'), resource(R,_), resource(R',_), R < R',  not nsubsumed(R',R), b(R,B), b(R',B'), B=B'.
subsumed(R,R') :- not nsubsumed(R,R'), resource(R,_), resource(R',_), R != R', not nsubsumed(R',R), b(R,B), b(R',B'), B>B'.
removed_resource(T,R) :- bresource(X,R), bgroup(X,T,_).
redundant_resource(T,R') :- subsumed(R,R'), train(T), not removed_resource(T,R).

resource_chunk(T,R,C,(V,V')) :- json_resource_chunk(T,R,C,ID), edge(T,(F,ID),V,V'), not redundant_resource(T,R).
resource_chunk_entry(T,R,C,M) :- resource_chunk(T,R,C,_), M = #min{E : resource_chunk(T,R,C,(V,V')), e(T,V,E)}.

resource_chunk_exit(T,R,C,M) :- resource_chunk(T,R,C,_), M = #max{L   : resource_chunk(T,R,C,(V,V')), l(T,V',L);
                                                                  E+D : resource_chunk(T,R,C,(V,V')), e(T,V',E), end(T,V')},
                                delta(T,D).

%%% shared(T,T',R,C,C')           - trains T,T' are sharing resource R,
%%%                                 i.e. the time that train T potentially visits resource_chunk (R,C)
%%%                                 overlaps with the time that train T' potentially visits resource_chunk (R,C')
shared(T,T',R,C,C') :- train(T), train(T'), T<T', not collision_free(T,T',R,C,C'),
                       resource_chunk_entry(T,R,C,E), resource_chunk_entry(T',R,C',E'),
                       resource_chunk_exit(T,R,C,L),
                       b(R,B),
                       E <= E', E' < L+B.

shared(T,T',R,C,C') :- train(T), train(T'), T<T', not collision_free(T,T',R,C,C'),
                       resource_chunk_entry(T,R,C,E), resource_chunk_entry(T',R,C',E'),
                       resource_chunk_exit(T',R,C',L'),
                       b(R,B),
                       E' <= E, E < L'+B.

