local TOKEN_INDEXER = {
    "tokens": {
        "type": "single_id",
        "start_tokens": [
          "<START>"
        ],
        "end_tokens": [
          "<END>"
        ],
        // should be set to the maximum value of `ngram_filter_sizes`
        "token_min_padding_length": 5
      }
};

{
  "dataset_reader": {
    // this is not a mistake
    "type": "text_classification_json",
    // DO NOT CHANGE token_indexers
    "token_indexers": TOKEN_INDEXER,
    // DO NOT CHANGE tokenizer
    "tokenizer": {
      "type": "just_spaces"
    },
    // must be lower than positional_embedding_size
    "max_sequence_length": 150,
    "lazy": false
  },
  "train_data_path": std.extVar("LM_TRAIN_DATA_PATH"),
  "validation_data_path": std.extVar("LM_VALID_DATA_PATH"),
  "vocabulary": {
//    "max_vocab_size": {
//      "tokens": 50000
//    },
    "tokens_to_add": {
      "tokens": [
        "@@MASK@@",
        "<START>",
        "<END>"
      ]
    },
  },
  "model": {
    "type": "masked_lm",
    "text_field_embedder": {
      "token_embedders": {
        "tokens": {
          "type": "embedding",
          "embedding_dim": 64,
          "trainable": true
        }
      }
    },
    "seq2seq_encoder": {
      "type": "pytorch_transformer",
      "input_dim": 64,
      "num_layers": 3,
      "num_attention_heads": 4,
      "positional_encoding": "embedding"
    },
    "tokens_masker": {
      "type": "tokens_masker",
      "mask_probability": 0.5,
      "replace_probability": 0.1
    }
  },
  "distributed": {
    "master_port": 29501,
    "cuda_devices": [
      2,
      3
    ]
  },
  "data_loader": {
    "batch_size": 64
  },
  "trainer": {
    "num_epochs": 50,
    "patience": 2
  }
}
