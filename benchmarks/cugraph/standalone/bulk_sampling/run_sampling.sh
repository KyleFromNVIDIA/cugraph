#!/bin/bash

conda init
source ~/.bashrc
conda activate rapids

BATCH_SIZE=$1
FANOUT=$2
REPLICATION_FACTOR=$3
SCRIPTS_DIR=$4
NUM_EPOCHS=$5

SAMPLES_DIR=/samples
DATASET_DIR=/datasets
LOGS_DIR=/logs

MG_UTILS_DIR=${SCRIPTS_DIR}/mg_utils
SCHEDULER_FILE=${MG_UTILS_DIR}/dask_scheduler.json

export WORKER_RMM_POOL_SIZE=28G
export UCX_MAX_RNDV_RAILS=1
export RAPIDS_NO_INITIALIZE=1
export CUDF_SPILL=1
export LIBCUDF_CUFILE_POLICY="OFF"
export GPUS_PER_NODE=8

PATCH_CUGRAPH=1

export SCHEDULER_FILE=$SCHEDULER_FILE
export LOGS_DIR=$LOGS_DIR

function handleTimeout {
    seconds=$1
    eval "timeout --signal=2 --kill-after=60 $*"
    LAST_EXITCODE=$?
    if (( $LAST_EXITCODE == 124 )); then
        logger "ERROR: command timed out after ${seconds} seconds"
    elif (( $LAST_EXITCODE == 137 )); then
        logger "ERROR: command timed out after ${seconds} seconds, and had to be killed with signal 9"
    fi
    ERRORCODE=$((ERRORCODE | ${LAST_EXITCODE}))
}

DASK_STARTUP_ERRORCODE=0
if [[ $SLURM_NODEID == 0 ]]; then
    ${MG_UTILS_DIR}/run-dask-process.sh scheduler workers &
else
    ${MG_UTILS_DIR}/run-dask-process.sh workers &
fi

if [[ $PATCH_CUGRAPH == 1 ]]; then
    mkdir /opt/cugraph-patch
    git clone https://github.com/alexbarghi-nv/cugraph -b dlfw-patch-24.01 /opt/cugraph-patch
    
    rm /opt/rapids/cugraph/python/cugraph/cugraph/structure/graph_implementation/simpleDistributedGraph.py
    cp /opt/cugraph-patch/python/cugraph/cugraph/structure/graph_implementation/simpleDistributedGraph.py /opt/rapids/cugraph/python/cugraph/cugraph/structure/graph_implementation/simpleDistributedGraph.py
    rm /usr/local/lib/python3.10/dist-packages/cugraph/structure/graph_implementation/simpleDistributedGraph.py
    cp /opt/cugraph-patch/python/cugraph/cugraph/structure/graph_implementation/simpleDistributedGraph.py /usr/local/lib/python3.10/dist-packages/cugraph/structure/graph_implementation/simpleDistributedGraph.py

fi

echo "properly waiting for workers to connect"
NUM_GPUS=$(python -c "import os; print(int(os.environ['SLURM_JOB_NUM_NODES'])*int(os.environ['GPUS_PER_NODE']))")
handleTimeout 120 python ${MG_UTILS_DIR}/wait_for_workers.py \
                    --num-expected-workers ${NUM_GPUS} \
                    --scheduler-file-path ${SCHEDULER_FILE}


DASK_STARTUP_ERRORCODE=$LAST_EXITCODE

echo $SLURM_NODEID 
if [[ $SLURM_NODEID == 0 ]]; then
    echo "Launching Python Script"
    python ${SCRIPTS_DIR}/cugraph_bulk_sampling.py \
        --output_root ${SAMPLES_DIR} \
        --dataset_root ${DATASET_DIR} \
        --datasets "ogbn_papers100M["$REPLICATION_FACTOR"]" \
        --fanouts $FANOUT \
        --batch_sizes $BATCH_SIZE \
        --seeds_per_call_opts "524288" \
        --num_epochs $NUM_EPOCHS \
        --random_seed 42 

    echo "DONE" > ${SAMPLES_DIR}/status.txt
fi

while [ ! -f "${SAMPLES_DIR}"/status.txt ]
do
    sleep 1
done

sleep 3

# At this stage there should be no running processes except /usr/lpp/mmfs/bin/mmsysmon.py
dask_processes=$(pgrep -la dask)
python_processes=$(pgrep -la python)
echo "$dask_processes"
echo "$python_processes"

if [[ ${#python_processes[@]} -gt 1 || $dask_processes ]]; then
    logger "The client was not shutdown properly, killing dask/python processes for Node $SLURM_NODEID"
    # This can be caused by a job timeout
    pkill python
    pkill dask
    pgrep -la python
    pgrep -la dask
fi
sleep 2

if [[ $SLURM_NODEID == 0 ]]; then
    rm ${SAMPLES_DIR}/status.txt
fi