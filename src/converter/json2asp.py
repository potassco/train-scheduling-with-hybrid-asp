#!/usr/bin/env python3
from typing import List, Any, Dict, Tuple, Optional
from model.business import TimeReference


def convert_string_to_datetime(datetime_string: Optional[str]):
    return TimeReference.safe_parse_timestamp(datetime_string)


def convert_strings_to_datetimes(vp_dict: Dict[str, Any]) -> Dict[str, Any]:
    for fa in vp_dict['funktionaleAngebotsbeschreibungen']:
        for av in fa['abschnittsvorgaben']:
            for key in ('einMin', 'einMax', 'ausMin', 'ausMax'):
                av[key] = convert_string_to_datetime(av.get(key, None))

    return vp_dict

