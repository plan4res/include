# include
Thise repo contains the bash scripts which are used for running the different modules of plan4res:
- sbatch_p4r.sh is the main script used with sbatch for running plan4res in parallel with slurm
- run_p4r.sh is the main script which is called by the p4r command and by the sbatch_p4r script; this script will call the different functions from the other scripts in this repo
- main_functions.sh is used by run_p4r ; it contains the main functions for reading parameters and calling the other scripts in this repo
- create.sh launches the python script for creating a csv dataset (plan4res format) from data in IAMC format
- format.sh launches the python script for creating a netcdf dataset from a csv dataset
- ssv.sh launches the sddp for computation of bellman values
- sim.sh and simCEM.sh launch the simulation
- cem.sh launches investment_solver
- cemloopssv.sh launches the investment optimisation within a loop where bellman values are updated each N iterations of investment_solver
- runCEM.sh launches the investment optimisation, using cem.sh and cemloopssv.sh; it also manages a loop for optimising investments over different lists of scenarios
- launch the python scripts to create dataset, format dataset, pposttreat results
- launch the different sms++ modules: SSV for computation of bellman values, SIM for simulation, CEM for capacity expansion
- posttreat.sh launches the python script for post-treatment of results
- sh_utils.sh includes a list of usefull functions
- runSSVandSIM.sh runs in sequence sddp_solver and simulation
- runSSVandCEM.sh runs in sequence sddp_solver and investment_solver
