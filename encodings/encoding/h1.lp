%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This part encodes a heuristic for the sequence
% of entering a resource.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#heuristic seq(T,T',R,C,C') : shared(T,T',R,C,C'),
                         resource_chunk_entry(T,R,C,E),  resource_chunk_entry(T',R,C',E'),
                         resource_chunk_exit(T,R,C,L),   resource_chunk_exit(T',R,C',L'). [E'-E - (L-L'),sign] 

