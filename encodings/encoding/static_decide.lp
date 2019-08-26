%%% some combination of resource_chunks can already statically be decided
%%% decided(T,T',R,C,C') - T uses resource chunk (R,C) before T' uses resource chunk (R,C')
decided(T,T',R,C,C') :- resource_chunk_exit(T,R,C,L), T != T', not removed_resource(T,R),
                        not removed_resource(T',R), resource_chunk_entry(T',R,C',E), L < E.
decided(T,T',R,C,C') :- resource_chunk(T,R,C,(V,V')), bridge(T,(V,V')), l(T,V',L), T != T',
                        not removed_resource(T,R), not removed_resource(T',R),  
                        resource_chunk(T',R,C',(U,U')), bridge(T',(U,U')), e(T',U,E), L < E.
                        %%%find a way to better (pre?) compute this lines above


