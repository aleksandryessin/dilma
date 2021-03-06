#!/usr/bin/env bash

# usage
# bash bin/attack.sh {FILENAME} {NUM_SAMPLES} {RESULTS_DIR} {GPU_ID} {LOG_DIR} {DATA_DIR}

# test or valid
FILENAME=${1:-"test"}
default_sample_size=200
SAMPLE_SIZE=${2:-$default_sample_size}
RESULTS_DIR=${3:-"results"}
default_gpu_id=0
GPU_ID=${4:-$default_gpu_id}
LOG_DIR=${5:-"logs"}
DATA_DIR=${6:-"datasets"}

echo ">> Attacking NLP models"
# NLP attacks use shared LM and DeepLev models
NLP_LOG_DIR=${LOG_DIR}/nlp
NLP_DATA_DIR=${DATA_DIR}/nlp
NLP_RESULTS_DIR=${RESULTS_DIR}/nlp

for dir in $(ls -d ${NLP_LOG_DIR}/dataset_*); do
    dataset=$(basename ${dir} | cut -d'_' -f 2)

    echo ">>>> Attack ${dataset} by FGSM"
    PYTHONPATH=. python scripts/baseline_attack.py \
        --config-path configs/attacks/fgsm/config.json \
        --attacker fgsm \
        --classifier-dir ${dir}/substitute_clf \
        --test-path ${NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --out-dir ${NLP_RESULTS_DIR}/${dataset}/fgsm \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}

    echo ">>>> Attack ${dataset} by DeepFool"
    PYTHONPATH=. python scripts/baseline_attack.py \
        --config-path configs/attacks/deepfool/config.json \
        --attacker deepfool \
        --classifier-dir ${dir}/substitute_clf \
        --test-path ${NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --out-dir ${NLP_RESULTS_DIR}/${dataset}/deepfool \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}

    echo ">>>> Attack ${dataset} by HotFlip"
    PYTHONPATH=. python scripts/hotflip_attack.py \
        --classifier-dir ${dir}/substitute_clf \
        --test-path ${NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --out-dir ${NLP_RESULTS_DIR}/${dataset}/hotflip \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}

    conf_path=configs/attacks/cascada/config_${dataset}.json
    if [[ ! -f "$conf_path" ]]; then
        conf_path=configs/attacks/cascada/config.json
    fi
    echo "Using ${conf_path} ..."

    echo ">>>> Attack ${dataset} by CASCADA"
    PYTHONPATH=. python scripts/cascada_attack.py \
        --config-path ${conf_path} \
        --test-path ${NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --classifier-dir ${dir}/substitute_clf \
        --deep-levenshtein-dir ${NLP_LOG_DIR}/lev \
        --lm-dir ${NLP_LOG_DIR}/lm \
        --out-dir ${NLP_RESULTS_DIR}/${dataset}/cascada \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}

    conf_path=configs/attacks/cascada_sampling/config_${dataset}.json
    if [[ ! -f "$conf_path" ]]; then
        conf_path=configs/attacks/cascada_sampling/config.json
    fi
    echo "Using ${conf_path} ..."

    echo ">>>> Attack ${dataset} by CASCADA w/ sampling"
    PYTHONPATH=. python scripts/cascada_attack.py \
        --config-path ${conf_path} \
        --test-path ${NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --classifier-dir ${dir}/substitute_clf \
        --deep-levenshtein-dir ${NLP_LOG_DIR}/lev \
        --lm-dir ${NLP_LOG_DIR}/lm \
        --out-dir ${NLP_RESULTS_DIR}/${dataset}/cascada_sampling \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}

    conf_path=configs/attacks/samplingfool/config_${dataset}.json
    if [[ ! -f "$conf_path" ]]; then
        conf_path=configs/attacks/samplingfool/config.json
    fi
    echo "Using ${conf_path} ..."

    echo ">>>> Attack ${dataset} by SamplingFool"
    PYTHONPATH=. python scripts/cascada_attack.py \
        --config-path ${conf_path} \
        --test-path ${NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --classifier-dir ${dir}/substitute_clf \
        --deep-levenshtein-dir ${NLP_LOG_DIR}/lev \
        --lm-dir ${NLP_LOG_DIR}/lm \
        --out-dir ${NLP_RESULTS_DIR}/${dataset}/sampling_fool \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}
done


echo ">> Attacking non-NLP models"
# non-NLP attacks use distinct LM and DeepLev models
NON_NLP_LOG_DIR=${LOG_DIR}/non_nlp
NON_NLP_DATA_DIR=${DATA_DIR}/non_nlp
NON_NLP_RESULTS_DIR=${RESULTS_DIR}/non_nlp

for dir in $(ls -d ${NON_NLP_LOG_DIR}/dataset_*); do
    dataset=$(basename ${dir} | cut -d'_' -f 2)

    echo ">>>> Attack ${dataset} by FGSM"
    PYTHONPATH=. python scripts/baseline_attack.py \
        --config-path configs/attacks/fgsm/config.json \
        --attacker fgsm \
        --classifier-dir ${dir}/substitute_clf \
        --test-path ${NON_NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --out-dir ${NON_NLP_RESULTS_DIR}/${dataset}/fgsm \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}

    echo ">>>> Attack ${dataset} by DeepFool"
    PYTHONPATH=. python scripts/baseline_attack.py \
        --config-path configs/attacks/deepfool/config.json \
        --attacker deepfool \
        --classifier-dir ${dir}/substitute_clf \
        --test-path ${NON_NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --out-dir ${NON_NLP_RESULTS_DIR}/${dataset}/deepfool \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}

    echo ">>>> Attack ${dataset} by HotFlip"
    PYTHONPATH=. python scripts/hotflip_attack.py \
        --classifier-dir ${dir}/substitute_clf \
        --test-path ${NON_NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --out-dir ${NON_NLP_RESULTS_DIR}/${dataset}/hotflip \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}

    conf_path=configs/attacks/cascada/config_${dataset}.json
    if [[ ! -f "$conf_path" ]]; then
        conf_path=configs/attacks/cascada/config.json
    fi
    echo "Using ${conf_path} ..."

    echo ">>>> Attack ${dataset} by CASCADA"
    PYTHONPATH=. python scripts/cascada_attack.py \
        --config-path ${conf_path} \
        --test-path ${NON_NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --classifier-dir ${dir}/substitute_clf \
        --deep-levenshtein-dir ${dir}/lev \
        --lm-dir ${dir}/lm \
        --out-dir ${NON_NLP_RESULTS_DIR}/${dataset}/cascada \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}

    conf_path=configs/attacks/cascada_sampling/config_${dataset}.json
    if [[ ! -f "$conf_path" ]]; then
        conf_path=configs/attacks/cascada_sampling/config.json
    fi
    echo "Using ${conf_path} ..."

    echo ">>>> Attack ${dataset} by CASCADA w/ sampling"
    PYTHONPATH=. python scripts/cascada_attack.py \
        --config-path ${conf_path} \
        --test-path ${NON_NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --classifier-dir ${dir}/substitute_clf \
        --deep-levenshtein-dir ${dir}/lev \
        --lm-dir ${dir}/lm \
        --out-dir ${NON_NLP_RESULTS_DIR}/${dataset}/cascada_sampling \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}

    conf_path=configs/attacks/samplingfool/config_${dataset}.json
    if [[ ! -f "$conf_path" ]]; then
        conf_path=configs/attacks/samplingfool/config.json
    fi
    echo "Using ${conf_path} ..."

    echo ">>>> Attack ${dataset} by SamplingFool"
    PYTHONPATH=. python scripts/cascada_attack.py \
        --config-path ${conf_path} \
        --test-path ${NON_NLP_DATA_DIR}/${dataset}/target_clf/${FILENAME}.json \
        --classifier-dir ${dir}/substitute_clf \
        --deep-levenshtein-dir ${dir}/lev \
        --lm-dir ${dir}/lm \
        --out-dir ${NON_NLP_RESULTS_DIR}/${dataset}/sampling_fool \
        --sample-size ${SAMPLE_SIZE} \
        --not-date-dir \
        --force \
        --cuda ${GPU_ID}
done


bash bin/evaluate.sh ${RESULTS_DIR} ${LOG_DIR} ${GPU_ID}