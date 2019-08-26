from typing import FrozenSet

import attr

from model.dekompo.possible_choice import PossibleChoice


@attr.s(auto_attribs=True, frozen=True)
class AdditionalCondition:
    possible_choices: FrozenSet[PossibleChoice]
