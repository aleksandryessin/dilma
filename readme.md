# Adversarial Attacks (ADAT)

## Dependencies

Install [Poetry](https://python-poetry.org/)

```bash
pip install poetry
```

Run `poetry config settings.virtualenvs.create false` if you don't want to use virtual environment.


Install all project dependencies

```bash
poetry install
```

And active a virtual environment (or don't)

```bash
poetry shell
```


## Datasets

**How every dataset should look like:**
1. .csv format (train.csv and test.csv)
2. Two columns `[sequences, labels]` (order is important!)
3. `sequences` is a `string`, where each event is separated by a space.
4. `labels` is an `int`.

### [Prediction of client gender on card transactions](https://www.kaggle.com/c/python-and-analyze-data-final-project/data)

Predict a gender of a client based on his/her transactions.

Check [this](https://github.com/fursovia/adversarial_attacks/blob/master/notebooks/kaggle_dataset_preparation.ipynb)
notebook to see how the dataset was collected.

### [Ai Academy Competition](https://onti.ai-academy.ru/competition)

Predict an age of a client based on his/her transactions.

### Insurance dataset by Martin

TODO



## Usage

### CopyNet Training

```bash
python train.py \
    --task nonmasked_copynet_with_attention \
    --model_dir experiments/sample/nonmasked_copynet_with_attention \
    --data_dir data/sample \
    --use_mask \
    --cuda 3
```


### Classifier Training

```bash
python train.py \
    --task classification \
    --model_dir experiments/sample/classification \
    --data_dir data/sample \
    --cuda 3
```


### MCMC/Random sampler

```bash
python run_mcmc.py \
    --csv_path data/sample/test.csv \
    --results_path results/sample/mcmc \
    --classifier_path experiments/sample/classification \
    --copynet_path experiments/sample/nonmasked_copynet_with_attention \
    --beam_size 3 \
    --cuda 3
```