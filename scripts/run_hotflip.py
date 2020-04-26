import argparse
from pathlib import Path
import csv
import json
from tqdm import tqdm
from datetime import datetime

import pandas as pd
from allennlp.data.vocabulary import Vocabulary
from allennlp.common.util import dump_metrics
from allennlp.predictors import TextClassifierPredictor

from adat.datasets.classifier import ClassificationReader
from adat.attackers import HotFlipFixed, AttackerOutput
from adat.models import get_classification_model
from adat.utils import load_weights

parser = argparse.ArgumentParser()
parser.add_argument('--csv_path', type=str, default='data/test.csv')
parser.add_argument('--results_path', type=str, default='results')
parser.add_argument('--classifier_path', type=str, default='experiments/classification')
parser.add_argument('--max_tokens', type=int, default=None)
parser.add_argument('--sample', type=int, default=None)


def _get_classifier_from_args(vocab: Vocabulary, path: str):
    with open(path) as file:
        args = json.load(file)
    num_classes = args['num_classes']
    return get_classification_model(vocab, int(num_classes))


if __name__ == '__main__':
    args = parser.parse_args()

    class_reader = ClassificationReader(skip_start_end=True)
    class_vocab = Vocabulary.from_files(Path(args.classifier_path) / 'vocab')
    class_model = _get_classifier_from_args(class_vocab, Path(args.classifier_path) / 'args.json')
    load_weights(class_model, Path(args.classifier_path) / 'best.th')

    predictor = TextClassifierPredictor(class_model, class_reader)
    max_tokens = args.max_tokens or class_vocab.get_vocab_size('tokens')
    attacker = HotFlipFixed(predictor, max_tokens=max_tokens)
    attacker.initialize()

    data = pd.read_csv(args.csv_path)
    sequences = data['sequences'].tolist()[:args.sample]
    labels = data['labels'].tolist()[:args.sample]

    results_path = Path(args.results_path) / datetime.now().strftime('%Y%m%d_%H%M%S')
    results_path.mkdir(exist_ok=True, parents=True)
    path_to_results_file = results_path / 'results.csv'
    dump_metrics(results_path / 'args.json', args.__dict__)
    with open(path_to_results_file, 'w', newline='') as csv_write:
        fieldnames = list(AttackerOutput.__annotations__.keys())
        writer = csv.DictWriter(csv_write, fieldnames=fieldnames)
        writer.writeheader()
        for seq, lab in tqdm(zip(sequences, labels)):
            inputs = {
                'sentence': seq,
                # 'label': lab
            }

            attack = attacker.attack_from_json(inputs)
            generated_seq = ' '.join(attack['final'][0])

            output = AttackerOutput(
                sequence=seq,
                label=lab,
                adversarial_sequence=generated_seq
            )

            writer.writerow(output.__dict__)
            csv_write.flush()