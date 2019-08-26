%%% purely optional transitive closure of seq atoms
%%% there is a nice way to do it
%myseq(T,T',R,C,C') :- seq(T,T',R,C,C').
%myseq(T',T,R,C',C) :- shared(T,T',R,C,C'), not seq(T,T',R,C,C').
%:- myseq(T,T',R,C,C'), myseq(T',T'',R,C',C''), shared(T,T'',R,C,C''), not myseq(T,T'',R,C,C'').
%:- myseq(T,T',R,C,C'), myseq(T',T'',R,C',C''), shared(T'',T,R,C'',C), myseq(T'',T,R,C'',C).
%%% and a not so nice way that avoids additional variables
:- seq(T,T',R,C,C'), shared(T,T',R,C,C'), seq(T',T'',R,C',C''), shared(T',T'',R,C',C''), shared(T,T'',R,C,C''), not seq(T,T'',R,C,C'').

:- shared(T,T',R,C,C'), not seq(T,T',R,C,C'), seq(T,T'',R,C,C''), shared(T,T'',R,C,C''), shared(T',T'',R,C',C''), not seq(T',T'',R,C',C'').
:- shared(T,T',R,C,C'), not seq(T,T',R,C,C'), seq(T,T'',R,C,C''), shared(T,T'',R,C,C''), shared(T'',T',R,C'',C'), seq(T'',T',R,C'',C').

:- shared(T,T',R,C,C'), not seq(T,T',R,C,C'), shared(T'',T,R,C'',C), not seq(T'',T,R,C'',C), shared(T',T'',R,C',C''), not seq(T',T'',R,C',C'').
:- shared(T,T',R,C,C'), not seq(T,T',R,C,C'), shared(T'',T,R,C'',C), not seq(T'',T,R,C'',C), shared(T'',T',R,C'',C'), seq(T'',T',R,C'',C').

:- seq(T,T',R,C,C'), shared(T,T',R,C,C'), shared(T'',T',R,C'',C'), not seq(T'',T',R,C'',C'), shared(T,T'',R,C,C''), not seq(T,T'',R,C,C'').
:- seq(T,T',R,C,C'), shared(T,T',R,C,C'), shared(T'',T',R,C'',C'), not seq(T'',T',R,C'',C'), shared(T'',T,R,C'',C), seq(T'',T,R,C'',C).

