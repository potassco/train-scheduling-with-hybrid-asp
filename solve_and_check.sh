#!/bin/bash
DEFAULT_TIME_LIMIT=300
TIME_LIMIT=${2:-$DEFAULT_TIME_LIMIT} 	# If variable not set, use default.
DEFAULT_MBW=1800
MBW=${3:-$DEFAULT_MBW}  				# If variable not set, use default.
DEFAULT_THREADS=2
THREADS=${4:-$DEFAULT_THREADS}  		# If variable not set, use default.
LEXI=${5:-$DEFAULT_LEXI}

echo "starting solver with a Time-Limit of $TIME_LIMIT s and a MBW of $MBW s with ${THREADS} threads"

if [[ "$(uname -s)" == "windows32" ]]; then pytonCmd=python; else pytonCmd=python3; fi

export PYTHONPATH=./src
export STAGE=shell

json=${1}
filename=$(basename -- "$json")
dir=$(dirname -- "$json")
extension="${filename##*.}"
asp=${dir}/"${filename%.*}".lp
echo "Reason from ${json} and ${asp}"
clingo-dl encodings/version_hs_ol1_ac.lp --time-limit=${TIME_LIMIT} -c mbw=${MBW} -t${THREADS} ${asp} -q1,0 --stats --heuristic=Domain --propagate=partial --lookahead=no > sol
eval ${pytonCmd} ./src/converter/asp2json.py ${json} sol > sol.json
java -jar loesung-validator-0.0.34-20190814.073719-10-cli.jar -problem_instance ${json} -solution sol.json
