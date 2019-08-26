%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This part purely formats output for the
% asp2json converter.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#show.
#show fahrweg(SI,F) : json_si(fahrweg,SI,F).
%#show visit(SI,ID) : visit(SI,X), trans(SI,ID,X).
#show visit/2.
#show route(T,ID) : route(T,(V,V')), edge(T,(F,ID),V,V'). 
#show hash(X) : json_hash(X).
#show topologischeReihenfolge(SI,ID,N) : json_topologischeReihenfolge(SI,ID,N).
#show abschnittskennzeichen(SI,ID,K) : json_si(abschnittVorgabe,SI,K), json_si(fahrweg,SI,F), json_abschnitt(abschnittskennzeichen,F,ID,K).
#show abschnitt(folgenid,SI,ID,Name) : json_abschnitt(folgenid,F,ID,Name), json_si(fahrweg,SI,F).
#show convert_topo(T,N,V) : node_pos(T,V,N), visit(T,V).
%%% for the positive cycles of the subproblem
%#show edge/4.
#show edge(T,ID,V,V') : edge(T,(F,ID),V,V'). 
#show late/4.
#show transition/5.
#show timed_connection/8.
#show m/3.
#show w/3.
#show relevant/3.
#show json_abschnittVorgabe/4.
#show json_si/3.
#show json_abschnitt/4.
#show trans/3.
#show merge/2.
#show split/2.
#show e/3.
#show l/3.
