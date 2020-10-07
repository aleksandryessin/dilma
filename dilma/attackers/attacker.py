from typing import List, Optional, Dict, Any
from abc import ABC, abstractmethod

from dataclasses import dataclass
from dataclasses_json import dataclass_json
from allennlp.common.registrable import Registrable
from allennlp.models import Model
import torch

from dilma.common import SequenceData, ModelsInput
from dilma.reader import BasicDatasetReader
from dilma.utils.metrics import word_error_rate
from dilma.utils.data import data_to_tensors


@dataclass_json
@dataclass
class AttackerOutput:
    data: SequenceData
    adversarial_data: SequenceData  # target clf
    probability: float  # original probability
    adversarial_probability: float  # target clf
    prob_diff: float
    wer: int
    history: Optional[List[Dict[str, Any]]] = None  # substitute clf

    @classmethod
    def from_data(
            cls,
            data_to_attack: SequenceData,
            adversarial_data: SequenceData,
            probability: float,
            adversarial_probability: float,
    ) -> "AttackerOutput":
        return cls(
            data=data_to_attack.to_dict(),
            adversarial_data=adversarial_data.to_dict(),
            probability=probability,
            adversarial_probability=adversarial_probability,
            prob_diff=(probability - adversarial_probability),
            wer=word_error_rate(data_to_attack.sequence, adversarial_data.sequence),
        )


class Attacker(ABC, Registrable):
    def __init__(
            self,
            substitute_classifier: Model,
            target_classifier: Model,
            reader: BasicDatasetReader,
            device: int = -1,
    ) -> None:
        self.substitute_classifier = substitute_classifier
        self.target_classifier = target_classifier
        subst_vocab = self.substitute_classifier.vocab
        target_vocab = self.target_classifier.vocab
        assert subst_vocab == target_vocab
        self.vocab = target_vocab
        self.reader = reader

        self.device = device
        if self.device >= 0 and torch.cuda.is_available():
            self.substitute_classifier.cuda(self.device)
            self.target_classifier.cuda(self.device)

    @abstractmethod
    def attack(self, data_to_attack: SequenceData) -> AttackerOutput:
        pass

    def get_target_clf_probs(self, inputs: ModelsInput) -> torch.Tensor:
        probs = self.target_classifier(**inputs)["probs"][0]
        return probs

    def get_substitute_clf_probs(self, inputs: ModelsInput) -> torch.Tensor:
        probs = self.substitute_classifier(**inputs)["probs"][0]
        return probs

    def probs_to_label(self, probs: torch.Tensor) -> int:
        label_idx = probs.argmax().item()
        label = self.index_to_label(label_idx)
        return label

    def index_to_label(self, label_idx: int) -> int:
        label = self.vocab.get_index_to_token_vocabulary("labels").get(label_idx, str(label_idx))
        return int(label)

    def label_to_index(self, label: int) -> int:
        label_idx = self.vocab.get_token_to_index_vocabulary("labels").get(str(label), label)
        return label_idx

    @staticmethod
    def find_best_attack(outputs: List[AttackerOutput]) -> AttackerOutput:
        if len(outputs) == 1:
            return outputs[0]

        changed_label_outputs = []
        for output in outputs:
            if output.data["label"] != output.adversarial_data["label"] and output.wer > 0:
                changed_label_outputs.append(output)

        if changed_label_outputs:
            sorted_outputs = sorted(changed_label_outputs, key=lambda x: x.prob_diff, reverse=True)
            best_output = min(sorted_outputs, key=lambda x: x.wer)
        else:
            best_output = max(outputs, key=lambda x: x.prob_diff)

        return best_output

    def recalculate_prob_and_label_for_target_clf(self, output: AttackerOutput) -> AttackerOutput:

        adv_inputs = data_to_tensors(output.adversarial_data, self.reader, self.vocab, self.device)
        adv_probs = self.get_target_clf_probs(adv_inputs)
        output.adversarial_data.label = self.probs_to_label(adv_probs)
        output.adversarial_probability = adv_probs[self.label_to_index(output.data_to_attack.label)].item()
        return output