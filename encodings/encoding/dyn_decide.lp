
decided(T,T',R,C,C') :- resource_chunk(T,R,C,(V,V')), route(T,(V,V')),
                        l(T,V',L), T != T', not removed_resource(T,R), not removed_resource(T',R),  
                        resource_chunk(T',R,C',(U,U')), route(T',(U,U')),
                        e(T',U,E), L < E.
