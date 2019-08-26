%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This part of the encoding translates the facts
% created from a json file to a format that can
% be used by our encoding.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% translate edges from ids to actual node connections of a multi-graph
%%% train(T)        - a service intention/train T is used
%%% edge(T,(F,ID),V,V') - train T can use a directed edge (F,ID) that goes from node V to node V'
%%% start(T,V)      - train T can start at node V
%%% end(T,V)        - train T can end at node V
%%% merge(T,V)      - train T can reach node V directly via several different edges
%%% split(T,V)      - train T has several edges as option to leave node V
%%% bridge(T,(F,ID))    - train T definetely uses edge ID

trans(SI,ID'',(F,ID,alt)) :- json_edge(SI,ID,ID''), 2{ json_edge(SI,ID,ID') }, json_si(fahrweg,SI,F).
trans(SI,ID'',(F,ID''))   :- json_edge(SI,ID,ID''), { json_edge(SI,ID,ID') }1, json_si(fahrweg,SI,F).
trans(SI,ID,(F,ID))       :- json_edge(SI,ID,ID'), not json_edge(SI,_,ID), json_si(fahrweg,SI,F).
trans(SI,ID,(F,ID))       :- json_start(SI,ID), not json_edge(SI,_,_), json_si(fahrweg,SI,F).
train(T) :- json_si(T).

edge(SI,(F,ID),(F,ID),(F,ID'))        :- json_edge(SI,ID,ID'), { json_edge(SI,ID,ID'') }1, trans(SI,ID,(F,ID)), json_si(fahrweg,SI,F).
edge(SI,(F,ID),(F,ID),(F,ID,alt))     :- json_edge(SI,ID,_), 2{ json_edge(SI,ID,ID') }, json_si(fahrweg,SI,F).
edge(SI,(F,ID'),(F,ID,alt),TID)       :- edge(SI,_,_,(F,ID,alt)), json_edge(SI,ID,ID'), json_edge(SI,ID',ID''), trans(SI,ID'',TID), json_si(fahrweg,SI,F). 
edge(SI,(F,ID),TID,(F,ID,end))        :- json_end(SI,ID), trans(SI,ID,TID), json_si(fahrweg,SI,F).

edge(SI,V,V') :- edge(SI,_,V,V').

start(T,V) :- edge(T,_,V,V'), not edge(T,_,_,V).
end(T,V')  :- edge(T,_,V,V'), not edge(T,_,V',_).

merge(T,V') :- edge(T,ID,_,V'), edge(T,ID',_,V'), ID != ID'.
split(T,V)  :- edge(T,ID,V,_),  edge(T,ID',V,_),  ID != ID'.

bridge(SI,(V,V')) :- json_bridge(SI,ID,"True"), edge(SI,(F,ID),V,V').

%%% general predicate for all kinds of "verknuepfung"
%%% connection(T,ID,T',ID,Min,Max,A,From,To) - train T has a connection on edge ID with train T' on ID'
%%%                                            From is a node on edge ID
%%%                                            To is a node on edge ID'
%%%                                            T has to be at node From via ID at least Min seconds before
%%%                                            T' enters node To via ID' if it is a timed_connection
%%%                                            T' has to be at node To via ID' at most Max seconds after
%%%                                            T enters node From via ID if it is a timed_connection
%%%                                            A is a string, describing the type of the connection
%%% collision_free_connection(T,ID,T',ID)     - trains T, T' can share any resource on their edges ID, ID'
%%% collision_free_connection(T,ID,T',ID,R)   - trains T, T' can share resource R on their edges ID, ID'
%%% timed_connection(T,ID,T',ID',Min,Max,From,To) - see connection

connection(SI,(V,V'),SI',(V'',V'''),Min,Max,A,From,To) :- json_verknuepfung(aufFaId,SI,K,N,SI'),
                                               json_verknuepfung(typ,SI,K,N,A),
                                               json_verknuepfung(aufAbschnittskennzeichen,SI,K,N,K'),
                                               Min = #max{0; T : json_verknuepfung(mindestdauer,SI,K,N,T), A != "umlauf", A != "umlauf_gleisbelegend"},
                                               Max = #max{T : json_verknuepfung(maxdauer,SI,K,N,T)}, % this can be #inf
                                               json_verknuepfung(vonEvent,SI,K,N,From'),
                                               json_verknuepfung(aufEvent,SI,K,N,To'),
                                               edge(SI,(F,ID),V,V'), edge(SI',(F',ID'),V'',V'''),
                                               From = #max{V' : From'="austritt"; V : From'="eintritt"},
                                               To = #max{V''' : To'="austritt"; V'' : To'="eintritt"},
                                               json_si(fahrweg,SI,F), json_abschnitt(abschnittskennzeichen,F,ID,K),
                                               json_si(fahrweg,SI',F'), json_abschnitt(abschnittskennzeichen,F',ID',K').
connection(SI',ID',SI,ID,0,M,"umlauf",To,From)               :- connection(SI,ID,SI',ID',0,M,"umlauf",From,To).
connection(SI',ID',SI,ID,0,M,"umlauf_gleisbelegend",To,From) :- connection(SI,ID,SI',ID',0,M,"umlauf_gleisbelegend",From,To).

% a connection where a resource can actually be shared
collision_free_connection(SI,ID,SI',ID')   :- connection(SI,ID,SI',ID',Min,Max,A,From,To),
                                              1 #sum {1 : A="umlauf_gleisbelegend";
                                                      1 : A="besetzte_einfahrt"}.

collision_free_connection(SI,ID,SI',ID',R) :- collision_free_connection(SI,ID,SI',ID'),
                                              resource(R,ID), resource(R,ID').

% a connection that has to meet in time
timed_connection(SI,ID,SI',ID',Min,Max,From,To) :- connection(SI,ID,SI',ID',Min,Max,A,From,To), A !="besetzte_einfahrt".


%%% minimal/maximal arrival/travel times
%%% relevant(e,T,V) - it is relevant to check the entering time of node V for train T
%%% relevant(l,T,V) - it is relevant to check the leaving time of node V for train T
%%% e(T,V,E)  - E is the earliest time that train T can reach node V
%%% l(T,V,L)  - L is the latest time that train T can reach node V
%%% m(T,ID,M) - M is the minimum travel time for train T on edge ID
%%% w(T,ID,W) - W is the minimum waiting time for train T on edge ID
delta(B)   :- json_maxBandabweichung(B).
delta(mbw) :- not json_maxBandabweichung(_). 
delta(T,B) :- train(T), delta(B), not json_maxBandabweichung(T,_).
delta(T,B) :- json_maxBandabweichung(T,B).
ausMax'(SI,(V,V'),Max+MBW) :- json_ausMax(SI,ID,Max), delta(SI,MBW), edge(SI,(F,ID),V,V').
einMax'(SI,(V,V'),Max+MBW) :- json_einMax(SI,ID,Max), delta(SI,MBW), edge(SI,(F,ID),V,V').

relevant(e,SI,V)  :-  json_start(SI,ID), trans(SI,ID,V).
relevant(e,SI,V)  :-  json_end(SI,ID), trans(SI,ID,V).
relevant(e,SI,V)  :-  json_abschnittVorgabe(einMin,SI,K,_), 
                      json_si(fahrweg,SI,F), 
                      json_abschnitt(abschnittskennzeichen,F,ID,K),
                      trans(SI,ID,V).
relevant(l,SI,V') :-  json_abschnittVorgabe(ausMax,SI,K,_),
                      json_si(fahrweg,SI,F),
                      json_abschnitt(abschnittskennzeichen,F,ID,K),
                      edge(SI,(F,ID),V,V').
relevant(l,SI,V)  :-  json_si(fahrweg,SI,F), trans(SI,ID,V),
                      json_abschnittVorgabe(einMax,SI,K,_),
                      json_abschnitt(abschnittskennzeichen,F,ID,K).
relevant(e,SI,V') :-  edge(SI,(F,ID),V,V'), json_si(fahrweg,SI,F),
                      json_abschnitt(abschnittskennzeichen,F,ID,K),
                      json_abschnittVorgabe(ausMin,SI,K,_).

aux_e(SI,V,E)      :- json_einMin(SI,ID,E), trans(SI,ID,V).
aux_e(SI,V',E)     :- json_ausMin(SI,ID,E), edge(SI,(F,ID),V,V').
e(SI,V,M)          :- aux_e(SI,V,_), M = #max {E : aux_e(SI,V,E)}.
aux_l(SI,V,L)      :- einMax'(SI,(V,V'),L), edge(SI,(F,ID),V,V'), trans(SI,ID,V).
aux_l(SI,V',L)     :- ausMax'(SI,(V,V'),L), edge(SI,(F,ID),V,V').
l(SI,V,M)          :- aux_l(SI,V,_), M = #min {L : aux_l(SI,V,L)}.

m(SI,(V,V'),FZ)        :- json_si(fahrweg,SI,F), json_abschnitt(minimaleFahrzeit,F,ID,FZ), edge(SI,(F,ID),V,V').
w(SI,(V,V'),HZ)        :- json_si(fahrweg,SI,F), edge(SI,(F,ID),V,V'),
                      json_abschnittVorgabe(minHaltezeit,SI,K,HZ),
                      json_abschnitt(abschnittskennzeichen,F,ID,K).
                               
%%% resources
%%% resource(R,ID) - resource R is used by train T on edge ID
%%% b(R,B)         - the block time for resource R is B
resource(R,(V,V')) :- json_ressourcenbelegung(ressource,F,ID,R),
                      edge(SI,(F,ID),V,V'),
                      json_si(fahrweg,SI,F).
b(R,B) :- json_ressource(freigabezeit,R,B).

%%% penalties for using routes or being late
%%% potlate(T,V,M,P) - if train T arrives at node V later than time M this solution gets penalized by P points
penalty((V,V'),P) :- json_abschnitt(penalty,F,ID,P), json_si(fahrweg,SI,F), edge(SI,(F,ID),V,V').
potlate(SI,V,M+T,W*U) :- json_abschnittVorgabe(einVerspaetungsfaktor,SI,K,W), json_si(fahrweg,SI,F),
                         json_abschnitt(abschnittskennzeichen,F,ID,K), json_abschnittVorgabe(einMax,SI,K,M), dpenalty(SI,T,U),
                         edge(SI,(F,ID),V,V').
potlate(SI,V',M+T,W*U) :- json_abschnittVorgabe(ausVerspaetungsfaktor,SI,K,W), json_si(fahrweg,SI,F),
                          json_abschnitt(abschnittskennzeichen,F,ID,K), json_abschnittVorgabe(ausMax,SI,K,M), dpenalty(SI,T,U),
                          edge(SI,(F,ID),V,V').

