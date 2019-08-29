# Train scheduling with clingoDL: Benchmarks
## REQUIREMENTS

- clingo-dl >= 1.1.0, available [here](https://github.com/potassco/)
- clingo 5.4.0, available [here](https://github.com/potassco/)
- python >= 3.6
- java 11
- Please download instances.tar.gz from https://github.com/potassco/train-scheduling-with-hybrid-asp/releases
and extract them to the root folder of this git.

If you are using conda, you can install all required packages into a new environment:

- create and activate a new conda environment
- conda install -c potassco clingo-dl
- conda install -c conda-forge thriftpy2
- conda install -c conda-forge openjdk
- pip install -r requirements.txt

## CONTENT

- encodings: Folder containing all ASPmDL encodings including optimization and heuristics
- instances: from https://github.com/potassco/train-scheduling-with-hybrid-asp/releases
	- *.json: Instances in json format
	- *.lp: Instances in ASP facts
- src: Folder with solution converter and checker
- solve_and_check.sh: Script running and validating one instance
- loesung-validator-0.0.34-20190814.073719-10-cli.jar: solution validator from https://github.com/potassco/train-scheduling-with-hybrid-asp/releases
- requirements.txt: requirements file for pip

## USAGE

`solve_and_check instance.json <config> <time limit> <max delay>`

- `instance.json`: json instance
- `config`: Configuration of clingo-dl (optional)
- `time limit`: Time limit for clingo-dl (optional)
- `max delay`: Maximum delay that is allowed for each train at a node (optional)

Example call:
`./solve_and_check.sh instances/p3.json`
