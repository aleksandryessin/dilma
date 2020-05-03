import argparse
from pathlib import Path
from typing import List
from pprint import pprint
import json

import numpy as np
from allennlp.predictors import Predictor

from adat.utils import load_jsonlines

parser = argparse.ArgumentParser()
parser.add_argument("--adversarial-dir", type=str, required=True)
parser.add_argument("--classifier-dir", type=str, required=True)
parser.add_argument("--lm-dir", type=str, default=None)
parser.add_argument("--gamma", type=float, default=1.0)


def normalized_accuracy_drop(
        wers: List[int],
        y_true: List[int],
        y_adv: List[int],
        gamma: float = 1.0
) -> float:
    assert len(y_true) == len(y_adv)
    nads = []
    for wer, lab, alab in zip(wers, y_true, y_adv):
        if wer > 0 and lab != alab:
            nads.append(1 / wer ** gamma)
        else:
            nads.append(0.0)

    return sum(nads) / len(nads)


if __name__ == "__main__":
    args = parser.parse_args()
    adversarial_dir = Path(args.adversarial_dir)
    data = load_jsonlines(adversarial_dir / "attacked_data.json")

    if args.lm_dir is not None:
        lm_dir = Path(args.lm_dir)
        lm_predictor = Predictor.from_path(
            lm_dir / "model.tar.gz",
            # this is not a mistake
            predictor_name="text_classifier"
        )
        lm_predictor._model._tokens_masker = None
        get_perplexity = lambda text: np.exp(lm_predictor.predict_json({"sentence": text})["loss"])
        orig_perplexities = [get_perplexity(el["sequence"]) for el in data]
        adv_perplexities = [get_perplexity(el["adversarial_sequence"]) for el in data]
        perp_diff = [max(0.0, adv_perplexities[i] - orig_perplexities[i]) for i in range(len(data))]
        mean_perplexity_rise = float(np.mean(perp_diff))
    else:
        mean_perplexity_rise = None

    classifier_dir = Path(args.classifier_dir)
    predictor = Predictor.from_path(
        classifier_dir / "model.tar.gz",
        predictor_name="text_classifier"
    )
    preds = predictor.predict_batch_json([{"sentence": el["sequence"]} for el in data])
    y_true = [int(el["attacked_label"]) for el in data]
    correctly_predicted = [y == int(p["label"]) for y, p in zip(y_true, preds)]

    adv_preds = predictor.predict_batch_json([{"sentence": el["adversarial_sequence"]} for el in data])
    y_adv = [int(el["label"]) for el in adv_preds]

    prob_diffs = [p["probs"][l] - ap["probs"][l] for p, ap, l in zip(preds, adv_preds, y_true)]
    wers = [el["wer"] for el in data]

    nad = normalized_accuracy_drop(
        wers=wers,
        y_true=y_true,
        y_adv=y_adv,
        gamma=args.gamma
    )

    metrics = dict(
        mean_prob_diff=float(np.mean(prob_diffs)),
        mean_wer=float(np.mean(wers)),
        mean_perplexity_rise=mean_perplexity_rise
    )
    metrics[f"NAD_{args.gamma}"] = nad
    metrics["path_to_model"] = str(classifier_dir.absolute())

    pprint(metrics)
    with open(adversarial_dir / f"{classifier_dir.name}_metrics.json", "w") as f:
        json.dump(metrics, f, indent=4)
