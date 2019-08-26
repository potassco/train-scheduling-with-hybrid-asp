import logging
from typing import FrozenSet

import attr

from model.dekompo.basic_expression import BasicExpression, BeType

LOGGER = logging.getLogger(__name__)

@attr.s(auto_attribs=True, frozen=True)
class PossibleChoice:
    basic_expressions: FrozenSet[BasicExpression]

    def possible_choice_is_not_dominated(self, possible_choices):
        if len(self.basic_expressions) == 0:
            LOGGER.info(f'PC is dominated because it does not contain any BasicExpressions')
            return False
        if self in possible_choices:
            LOGGER.info(f'PC is dominated because it was already contained in the accumulated PCs')
            return False
        for other_possible_choice in possible_choices:
            if other_possible_choice.choice_dominates_other(self):
                LOGGER.warning(f'ATTENTION!---- I, {self}, am "dominated" by {other_possible_choice} by element-wise comparison. Please inspect me and the other PC in detail if you ever see this log message')
                return False
        return True

    def choice_dominates_other(self, other_choice):
        if len(self.basic_expressions) != len(other_choice.basic_expressions):
            return False
        sorted1 = sorted(self.basic_expressions)
        sorted2 = sorted(other_choice.basic_expressions)
        for i, basic_expression in enumerate(sorted1):
            other_expression = sorted2[i]
            if basic_expression.type != other_expression.type \
                    or basic_expression.fa1 != other_expression.fa1 \
                    or basic_expression.node_fa1 != other_expression.node_fa1 \
                    or basic_expression.fa2 != other_expression.fa2 \
                    or basic_expression.node_fa2 != other_expression.node_fa2:
                return False
            if basic_expression.type is BeType.RELATIVE:
                if basic_expression.duration_in_millis > other_expression.duration_in_millis:
                    return False
            elif basic_expression.node_fa1 is None:
                if basic_expression.time_after_reference_in_millis > other_expression.time_after_reference_in_millis:
                    return False
            elif basic_expression.time_after_reference_in_millis < other_expression.time_after_reference_in_millis:
                return False

        return True
