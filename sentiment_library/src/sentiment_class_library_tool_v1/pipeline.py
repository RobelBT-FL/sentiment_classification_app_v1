# -*- coding: utf-8 -*-
"""
PIPELINE (SUPER SIMPLE + METRICS VERSION + TIMING + CSV EXPORT + PROGRESS BAR)
"""

import pandas as pd
import time
from tqdm import tqdm

# Data loading + preprocessing
from sentiment_class_library_tool_v1.data import (
    load_dataset,
    create_examples,
    load_gold
)

# Prompt builders
from sentiment_class_library_tool_v1.prompts import (
    build_zero_shot_prompt,
    build_few_shot_prompt,
    build_cot_prompt
)

# Evaluator
from sentiment_class_library_tool_v1.evaluator import (
    evaluate_prediction
)

# Model loader
from sentiment_class_library_tool_v1.model_client import (
    LlamaClient
)

# Metrics
from sentiment_class_library_tool_v1.metrics import (
    compute_metrics
)

# Config
from sentiment_class_library_tool_v1.config import (
    FEW_SHOT_EXAMPLES_PER_CLASS,
    GOLD_SAMPLE_SIZE
)


# ------------------------------------------------------------
# PREPARE IMDB DATA
# ------------------------------------------------------------
def prepare_imdb_data(path, n=50):
    df = load_dataset(path)
    gold_json = load_gold(df, num_gold=n)
    return gold_json, df


# ------------------------------------------------------------
# MAIN PIPELINE
# ------------------------------------------------------------
def run_full_pipeline(
    data_path,
    model_path=None,
    gold_size=GOLD_SAMPLE_SIZE
):
    print("\n=== LOADING DATA ===")
    gold_json, df = prepare_imdb_data(data_path, n=gold_size)

    print("\n=== LOADING MODEL ===")
    llm = LlamaClient(model_path=model_path)

    # --------------------------------------------------------
    # ZERO-SHOT
    # --------------------------------------------------------
    print("\n=== ZERO-SHOT ===")
    zero_prompt = build_zero_shot_prompt()

    start = time.time()
    zero_result = evaluate_prediction(zero_prompt, gold_json, llm, use_tqdm=True)
    zero_time = time.time() - start

    zero_metrics = compute_metrics(zero_result)

    print("\nZERO-SHOT METRICS")
    for k, v in zero_metrics.items():
        print(f"{k:20s}: {v}")
    print(f"inference_time_sec    : {zero_time:.2f}")

    # --------------------------------------------------------
    # FEW-SHOT
    # --------------------------------------------------------
    print("\n=== FEW-SHOT ===")
    few_examples = create_examples(df, num_per_class=FEW_SHOT_EXAMPLES_PER_CLASS)
    few_prompt = build_few_shot_prompt(few_examples)

    start = time.time()
    few_result = evaluate_prediction(few_prompt, gold_json, llm, use_tqdm=True)
    few_time = time.time() - start

    few_metrics = compute_metrics(few_result)

    print("\nFEW-SHOT METRICS")
    for k, v in few_metrics.items():
        print(f"{k:20s}: {v}")
    print(f"inference_time_sec    : {few_time:.2f}")

    # --------------------------------------------------------
    # CHAIN-OF-THOUGHT
    # --------------------------------------------------------
    print("\n=== CHAIN-OF-THOUGHT ===")
    cot_examples = create_examples(df, num_per_class=FEW_SHOT_EXAMPLES_PER_CLASS)
    cot_prompt = build_cot_prompt(cot_examples)

    start = time.time()
    cot_result = evaluate_prediction(cot_prompt, gold_json, llm, use_tqdm=True)
    cot_time = time.time() - start

    cot_metrics = compute_metrics(cot_result)

    print("\nCHAIN-OF-THOUGHT METRICS")
    for k, v in cot_metrics.items():
        print(f"{k:20s}: {v}")
    print(f"inference_time_sec    : {cot_time:.2f}")

    # --------------------------------------------------------
    # SUMMARY COMPARISON TABLE
    # --------------------------------------------------------
    print("\n=== SUMMARY COMPARISON TABLE ===")

    summary_df = pd.DataFrame({
        "mode": ["zero_shot", "few_shot", "cot"],
        "accuracy": [
            zero_metrics["accuracy"],
            few_metrics["accuracy"],
            cot_metrics["accuracy"]
        ],
        "f1_micro": [
            zero_metrics["f1_micro"],
            few_metrics["f1_micro"],
            cot_metrics["f1_micro"]
        ],
        "roc_auc": [
            zero_metrics["roc_auc"],
            few_metrics["roc_auc"],
            cot_metrics["roc_auc"]
        ],
        "pr_auc": [
            zero_metrics["pr_auc"],
            few_metrics["pr_auc"],
            cot_metrics["pr_auc"]
        ],
        "time_sec": [zero_time, few_time, cot_time]
    })

    print(summary_df)

    # Save summary CSV
    summary_df.to_csv("summary_metrics.csv", index=False)
    print("\nSaved: summary_metrics.csv")

    # --------------------------------------------------------
    # COMBINED RESULTS TABLE
    # --------------------------------------------------------
    combined_df = pd.DataFrame({
        "review": zero_result["full_reviews"],
        "truth": zero_result["ground_truths"],
        "zero_shot": zero_result["model_predictions"],
        "few_shot": few_result["model_predictions"],
        "cot": cot_result["model_predictions"]
    })

    combined_df["zero_correct"] = combined_df["zero_shot"] == combined_df["truth"]
    combined_df["few_correct"] = combined_df["few_shot"] == combined_df["truth"]
    combined_df["cot_correct"] = combined_df["cot"] == combined_df["truth"]

    # Save combined CSV
    combined_df.to_csv("combined_predictions.csv", index=False)
    print("Saved: combined_predictions.csv")

    print("\n=== PIPELINE COMPLETE ===")
    return combined_df
