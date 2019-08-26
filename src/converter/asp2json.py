#!/usr/bin/env python3

import argparse
import json
import operator
import re
import sys
import traceback
from typing import Dict, Any, List, Set

from converter import json2asp as json2asp
from model.business import TimeReference
from model.dekompo.additional_condition import AdditionalCondition
from model.dekompo.basic_expression import BasicExpression, BeType


def error(msg):
    sys.stderr.write(msg)
    sys.exit()

def millisec2dur(millisecs: int) -> str:
    secs = float(millisecs) / 1000.0
    return f'PT{secs}S'


def asp_to_loesung(solution_as_string: str, time_reference: TimeReference, feedbacks=None, infeasible=False) -> Dict[str, Any]:

    out = {}
    out["hash"] = 1  # no way to precompute this
    out["zugfahrten"] = []

    if feedbacks is None:
        feedbacks = []
    if infeasible:
        return out
    if len(solution_as_string) == 0 and len(feedbacks) == 0:
        raise ValueError('error - solution is empty\n')

    answer = ""
    if 'error' in solution_as_string or 'ERROR' in solution_as_string:
        raise ValueError("error found in solution")
    if "dl" in solution_as_string:
        answer = solution_as_string

    answer = [line for line in answer.splitlines()]

    atom = re.compile(r'^[a-zA-Z_]+\(.*\)$')

    answer = [p + ")" for line in answer for p in (line + " ").split(') ') if len(p) > 1]
    answer = [item for item in answer if atom.match(item)]

    reghash = re.compile(r'hash\((-?\d+)\)')
    regroute = re.compile(r'route\("(.*)",(\d+)\)')
    regstart = re.compile(r'dl\(\("(.*)",(.*)\),"(\d+)"\)$')
    regstart2 = re.compile(r'dl\(\("(.*)",(.*)\),(\d+)\)$')
    regfahrweg = re.compile(r'fahrweg\("(.*)","(.*)"\)')
    regtop = re.compile(r'topologischeReihenfolge\("(.*)",(\d+),(\d+)\)')
    regkenn = re.compile(r'abschnittskennzeichen\("(.*)",(\d+),"(.*)"\)')
    regfolge = re.compile(r'abschnitt\(folgenid,"(.*)",(\d+),"(.*)"\)')
    regmin = re.compile(r'minTime\("(.*)",(\d+),(\d+)\)')
    edge = re.compile(r'edge\("(.*)",(\d+),(\(.*\)),(\(.*\))\)$')
    rvisit = re.compile(r'visit\("(.*)",(\(.*\))\)$')
    convertt = re.compile('convert_topo\("(.*)",(\d+),(\(.*\))\)$')
    route = {}
    visit = {}
    times = {}
    result = {}
    sifw = {}
    topology = {}
    kenn = {}
    folge = {}
    ingoing = {}
    outgoing = {}
    convert_topo = {}

    for i in answer:
        x = convertt.match(i)
        if x != None:
            convert_topo.setdefault(x.group(1), {})[int(x.group(2))] = str(x.group(3))
        x = regstart.match(i)
        if x != None:
            times.setdefault(x.group(1), {})[str(x.group(2))] = int(x.group(3))
        x = regstart2.match(i)  # newest clingo-wip
        if x != None:
            times.setdefault(x.group(1), {})[str(x.group(2))] = int(x.group(3))
        x = reghash.match(i)
        if x != None:
            out["verkehrsplanHash"] = x.group(1)
        x = regroute.match(i)
        if x != None:
            route.setdefault(x.group(1), []).extend([x.group(2)])
        x = regfahrweg.match(i)
        if x != None:
            sifw[x.group(1)] = x.group(2)
        x = regtop.match(i)
        if x != None:
            if x.group(1) not in topology:
                topology[x.group(1)] = {}
            topology[x.group(1)][x.group(2)] = int(x.group(3))
        x = regkenn.match(i)
        if x != None:
            if x.group(1) not in kenn:
                kenn[x.group(1)] = {}
            kenn[x.group(1)][x.group(2)] = x.group(3)
        x = regfolge.match(i)
        if x != None:
            if x.group(1) not in folge:
                folge[x.group(1)] = {}
            folge[x.group(1)][x.group(2)] = x.group(3)
        x = edge.match(i)
        if x != None:
            ingoing.setdefault(x.group(1), {}).setdefault(x.group(3), []).append(x.group(2))
            outgoing.setdefault(x.group(1), {}).setdefault(x.group(4), []).append(x.group(2))
        x = rvisit.match(i)
        if x != None:
            visit.setdefault(x.group(1), []).append(x.group(2))
    #    print(visit)

    for si in times:
        for n, t in times[si].items():
            if int(n) not in convert_topo[si]:
                continue

            v = convert_topo[si][int(n)]
            if v in ingoing[si]:
                for i in ingoing[si][v]:
                    if i in route[si] and v in visit[si]:
                        result.setdefault(si, {}).setdefault(i, {})["ein"] = time_reference.restore_from_milliseconds(
                            t).to_iso8601_string()
            if v in outgoing[si]:
                for i in outgoing[si][v]:
                    if i in route[si] and v in visit[si]:
                        result.setdefault(si, {}).setdefault(i, {})["aus"] = time_reference.restore_from_milliseconds(
                            t).to_iso8601_string()

    ins = out["zugfahrten"]
    if len(feedbacks) == 0:
        write_timetable_of_feasible_solution(folge, ins, kenn, result, sifw, topology)
    else:
        write_timetable_of_feasible_solution(folge, ins, kenn, result, sifw, topology)
        write_subproblem_feedback(feedbacks, out, time_reference)

    return out


def write_subproblem_feedback(feedbacks: Set[AdditionalCondition], out: Dict[str, Any], time_reference: TimeReference) -> None: #ToDo: Return the subproblem-feedback instead of side-effect
    out["subproblemFeedback"] = {}
    feeedback = out["subproblemFeedback"]
    feeedback["basicExpressions"] = []
    bes = feeedback["basicExpressions"]
    feeedback["additionalConditions"] = []
    for additional_condition in feedbacks:
        ac = {}
        ac["possibleChoices"] = [dict(basicExpressionIds=[be.id for be in possible_choice.basic_expressions]) for possible_choice in additional_condition.possible_choices]

        feeedback["additionalConditions"].append(ac)

    basic_expression_set: Set[BasicExpression] = {be for additional_condition in feedbacks for possible_choice in additional_condition.possible_choices for be in possible_choice.basic_expressions}

    for be in basic_expression_set: #ToDo: use cattrs destructure to write as dict instead of manually writing
        basicExpression = dict()
        basicExpression['id'] = be.id
        basicExpression["type"] = be.type.name.lower()
        fa1 = str(be.fa1.string).replace('"', '')
        if (fa1 != 'null'):
            basicExpression["fa1"] = fa1
        cId1 = str(be.coordination_id_1).replace('"', '')
        if (cId1 != 'null'):
            basicExpression["coordinationId1"] = cId1
        fa2 = str(be.fa2).replace('"', '')
        if (fa2 != 'null'):
            basicExpression["fa2"] = fa2
        cId2 = str(be.coordination_id_2).replace('"', '')
        if (cId2 != 'null'):
            basicExpression["coordinationId2"] = cId2
        if be.type is BeType.RELATIVE:
            basicExpression["duration"] = millisec2dur(int(str(be.duration_in_millis)))
        elif be.type is BeType.ABSOLUTE:
            basicExpression["time"] = time_reference.restore_from_milliseconds(
                int(str(be.time_after_reference_in_millis))).to_iso8601_string()
        bes.append(basicExpression)



def write_timetable_of_feasible_solution(folge, ins, kenn, result, sifw, topology):
    for i in result:
        si = {}
        si["funktionaleAngebotsbeschreibungId"] = i
        si["zugfahrtabschnitte"] = []
        zfa = si["zugfahrtabschnitte"]
        for k in result[i]:
            abschnitt = {}
            abschnitt["fahrwegabschnittId"] = sifw[i] + "#" + str(str(k))
            abschnitt["fahrweg"] = sifw[i]
            abschnitt["ein"] = result[i][k]["ein"]
            abschnitt["aus"] = result[i][k]["aus"]
            abschnitt["abschnittsfolge"] = folge[i][k]
            abschnitt["reihenfolge"] = topology[i][k]
            if i in kenn and k in kenn[i]:
                abschnitt["abschnittsvorgabe"] = kenn[i][k]
            zfa.append(abschnitt)
        si['zugfahrtabschnitte'] = sorted(si['zugfahrtabschnitte'], key=operator.itemgetter('reihenfolge'))

        ins.append(si)


def main():
    try:
        parser = argparse.ArgumentParser(description="Converts a clingoDL answer set into a challenge solution ")
        parser.add_argument('vp', metavar='<vp>', type=argparse.FileType('r'), help='Read from %(metavar)s')
        parser.add_argument('asp_solution', metavar='<asp_solution>', type=argparse.FileType('r'),
                            help='Read from %(metavar)s')

        args = parser.parse_args()
        with open(args.vp.name, 'r') as f:
            vp = json2asp.convert_strings_to_datetimes(json.load(f))
            time_reference = TimeReference.from_verkehrsplan(vp)

        with open(args.asp_solution.name, 'r') as f:
            print(json.dumps(asp_to_loesung(f.read(), time_reference)))
    except Exception as e:
        traceback.print_exception(*sys.exc_info())
        return 1


if __name__ == '__main__':
    sys.exit(main())
