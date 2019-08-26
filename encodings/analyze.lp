%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This encoding gives some general stats about
% the problem. Needs the convert.lp and the
% preprocessing.lp.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

numSI(X) :- X = #sum {1,SI : train(SI)}.
%%% this is more like the size of all subgraphs, we can not have an edge shared with another train ?
numEdges(X) :- X = #sum {1,SI,ID,V,V' : edge(SI,ID,V,V')}.
numSplits(X) :- X = #sum {1,SI,ID,ID',V,V',V'' : edge(SI,ID,V,V'), edge(SI,ID',V,V''), V' != V''}.
numMerges(X) :- X = #sum {1,SI,ID,ID',V,V',V'' : edge(SI,ID,V',V), edge(SI,ID',V'',V), V' != V''}.
numBridges(X) :- X = #sum {1,SI,ID : bridge(SI,ID)}.
numResources(X) :- X = #sum {1,R : resource(R,(_,_))}.
numResourceOcc(X) :- X = #sum{1,T,R,ID : resource(R,(V,V')), edge(T,ID,V,V')}.
numResourceChunks(X) :- X = #sum {1,T,R,C : resource_chunk(T,R,C,_)}.
numSubsumedResources(X) :- X = #sum {1,R : subsumed(R,_)}.
numMultiEdges(X) :- X = #sum {1,SI,ID,V,V' : edge(SI,ID,V,V'), edge(SI,ID',V,V'), ID < ID'}.
numSharedChunks(X) :- X = #sum {1,T,T',R,C,C' : shared(T,T',R,C,C')}.

sharedEdge(T,(V,V'),T',(U,U')) :- edge(T,V,V'), edge(T',U,U'), T!=T', not redundant_resource(T,R), not redundant_resource(T',R),
                              resource(R,(V,V')), resource(R,(U,U')), b(R,B),
                              e(T,V,E), l(T,V',L), e(T',U,E'),
                              E <= E', E' < L+B.

numSharedEdges(X) :- X = #sum {1,T,E,T',E' : sharedEdge(T,E,T',E')}.
numNodeVariables(X) :- X = #sum {1,T,V : edge(T,V,_); 1,T,V' : edge(T,_,V')}.
numTopoVariables(X) :- X = #sum {1,T,M : node_pos(T,_,M)}.

#show numSI/1.
#show numEdges/1.
#show numSplits/1.
#show numMerges/1.
#show numBridges/1.
#show numResources/1.
#show numResourceOcc/1.
#show numResourceChunks/1.
#show numSubsumedResources/1.
#show numMultiEdges/1.
#show numSharedChunks/1.
#show numSharedEdges/1.
#show numNodeVariables/1.
#show numTopoVariables/1.
