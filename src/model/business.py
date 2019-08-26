from typing import Any, Dict

import attr
import pendulum
from pendulum import DateTime


@attr.s(auto_attribs=True)
class TimeReference:

    reference: DateTime

    def to_milliseconds(self, datetime: DateTime) -> int:
        return round((datetime - self.reference).total_seconds()*1000.0)

    def to_milliseconds_from_string(self, datetime_string: str) -> int:
        return self.to_milliseconds(TimeReference.safe_parse_timestamp(datetime_string))

    def restore_from_milliseconds(self, milliseconds: int) -> DateTime:
        seconds = float(milliseconds) / 1000.0
        return self.reference.add(seconds=seconds)

    @staticmethod
    def safe_parse_timestamp(timestamp_string) -> DateTime:
        try:
            ts = pendulum.parse(timestamp_string)
            return ts
        except (TypeError, ValueError):  # einMin = None or einMin = ""
            return None

    @classmethod
    def from_verkehrsplan(cls, vp_dict: Dict[str, Any]):
        _reference = min(av['einMin'] for fa in vp_dict['funktionaleAngebotsbeschreibungen']
                   for av in fa['abschnittsvorgaben'] if av['einMin'] is not None)
        return cls(reference=_reference)

