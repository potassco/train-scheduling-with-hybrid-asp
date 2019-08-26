from enum import Enum, auto
from typing import Optional

import attr
import clingo


class BeType(Enum):
    RELATIVE = auto()
    ABSOLUTE = auto()


@attr.s(auto_attribs=True, frozen=True)
class BasicExpression:
    id: int
    type: BeType
    duration_in_millis: Optional[int]
    time_after_reference_in_millis: Optional[int]
    fa1: clingo.Symbol
    coordination_id_1: clingo.Symbol
    node_fa1: clingo.Symbol
    fa2: clingo.Symbol
    coordination_id_2: clingo.Symbol
    node_fa2: clingo.Symbol

    @classmethod
    def from_symbol(cls, symbol: clingo.Symbol):
        type_symbol, fa1, coordination_id_1, fa2, coordination_id_2, duration_or_time_millis, node_fa1, node_fa2 = symbol.arguments
        be_id = cls.create_id(fa1, node_fa1, fa2, node_fa2, duration_or_time_millis)
        if type_symbol.name == 'relative':
            be_type = BeType.RELATIVE
            duration_in_millis = duration_or_time_millis.number
            time_after_reference_in_millis = None
        else:
            be_type = BeType.ABSOLUTE
            duration_in_millis = None
            time_after_reference_in_millis = duration_or_time_millis.number
        return cls(id=be_id,
                   type=be_type,
                   duration_in_millis=duration_in_millis,
                   time_after_reference_in_millis=time_after_reference_in_millis,
                   fa1=fa1,
                   coordination_id_1=coordination_id_1,
                   node_fa1=node_fa1,
                   fa2=fa2,
                   coordination_id_2=coordination_id_2,
                   node_fa2=node_fa2)

    @classmethod
    def from_edge(cls, start_node, start_attribs, end_node, end_attribs, length, soll_arrival, soll_dep):
        be_id = cls.create_id(start_node.fa_id, start_node.node_id, end_node.fa_id, end_node.node_id, length)
        be_type = BeType.RELATIVE if start_attribs["type"].name == "master" and end_attribs[
            "type"].name == "master" else BeType.ABSOLUTE
        time_after_reference_in_millis = None
        if start_attribs["type"].name == "vp":
            time_after_reference_in_millis = soll_dep + length
            length = time_after_reference_in_millis
        elif end_attribs["type"].name == "vp":
            time_after_reference_in_millis = soll_arrival - length
            length = time_after_reference_in_millis
        duration_in_millis = length if be_type == BeType.RELATIVE else None
        return cls(
            id=be_id,
            type=be_type,
            duration_in_millis=duration_in_millis,
            time_after_reference_in_millis=time_after_reference_in_millis,
            fa1=start_node.fa_id,
            coordination_id_1=start_attribs["koord_id"],
            node_fa1=start_node.node_id,
            fa2=end_node.fa_id,
            coordination_id_2=end_attribs["koord_id"],
            node_fa2=end_node.node_id
        )

    @classmethod
    def create_id(cls, fa1, node_fa1, fa2, node_fa2, duration_or_time_millis):
        return hash(repr([fa1, node_fa1, fa2, node_fa2, duration_or_time_millis]))
