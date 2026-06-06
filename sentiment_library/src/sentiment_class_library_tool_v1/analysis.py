# -*- coding: utf-8 -*-
"""
ANALYSIS UTILITIES (VERY SIMPLE VERSION)

LAYMAN EXPLANATION:
    This file creates ONE big table that shows:
        - what each method predicted (zero-shot, few-shot, CoT)
        - whether each prediction was correct
        - whether few-shot or CoT FIXED mistakes
        - a summary row at the bottom that counts everything
"""

import pandas as pd


def build_combined(zero, few, cot):
    """
    PURPOSE:
        Combine the results from the 3 evaluation modes into one table.

    LAYMAN EXPLANATION:
        Think of this like stacking 3 answer sheets side-by-side:
            - zero-shot answers
            - few-shot answers
            - chain-of-thought answers

        Then we check:
            - which ones are correct
            - which ones fixed mistakes
            - how many total correct answers each method got

    INPUTS:
        zero → dictionary from evaluate_prediction()
        few  → dictionary from evaluate_prediction()
        cot  → dictionary from evaluate_prediction()

    OUTPUT:
        A pandas DataFrame (table) with:
            - predictions
            - correctness flags
            - mistake fixing
            - summary row
    """

    # --------------------------------------------------------
    # 1. BUILD THE MAIN TABLE
    # --------------------------------------------------------
    # LAYMAN:
    #   We create a table with:
    #       - the review text
    #       - the true label
    #       - the predictions from each method
    df = pd.DataFrame({
        "review": zero["full_reviews"],
        "truth": zero["ground_truths"],
        "zero": zero["model_predictions"],
        "few": few["model_predictions"],
        "cot": cot["model_predictions"]
    })

    # --------------------------------------------------------
    # 2. CHECK CORRECTNESS
    # --------------------------------------------------------
    # LAYMAN:
    #   Compare each prediction to the truth.
    #   If they match → True (correct)
    #   If not → False (wrong)
    df["zero_ok"] = df["zero"] == df["truth"]
    df["few_ok"] = df["few"] == df["truth"]
    df["cot_ok"] = df["cot"] == df["truth"]

    # --------------------------------------------------------
    # 3. MISTAKE FIXING
    # --------------------------------------------------------
    # LAYMAN:
    #   These columns check if a later method FIXED a mistake
    #   made by an earlier method.
    #
    #   Example:
    #       zero-shot wrong, few-shot correct → few_fixed_zero = True
    df["few_fixed_zero"] = (~df["zero_ok"]) & df["few_ok"]
    df["cot_fixed_zero"] = (~df["zero_ok"]) & df["cot_ok"]
    df["cot_fixed_few"] = (~df["few_ok"]) & df["cot_ok"]

    # LAYMAN:
    #   Only CoT got it right (zero and few both wrong)
    df["only_cot_correct"] = (
        (~df["zero_ok"]) &
        (~df["few_ok"]) &
        df["cot_ok"]
    )

    # LAYMAN:
    #   All 3 methods got it wrong
    df["all_wrong"] = (
        (~df["zero_ok"]) &
        (~df["few_ok"]) &
        (~df["cot_ok"])
    )

    # --------------------------------------------------------
    # 4. SUMMARY ROW
    # --------------------------------------------------------
    # LAYMAN:
    #   This row shows:
    #       - how many correct predictions each method got
    #       - accuracy (percentage correct)
    #       - how many mistakes were fixed
    summary = pd.DataFrame([{
        "review": "SUMMARY",
        "truth": "",

        # Counts of correct predictions
        "zero": int(df["zero_ok"].sum()),
        "few": int(df["few_ok"].sum()),
        "cot": int(df["cot_ok"].sum()),

        # Accuracy (correct / total)
        "zero_ok": df["zero_ok"].mean(),
        "few_ok": df["few_ok"].mean(),
        "cot_ok": df["cot_ok"].mean(),

        # Mistake fixing counts
        "few_fixed_zero": int(df["few_fixed_zero"].sum()),
        "cot_fixed_zero": int(df["cot_fixed_zero"].sum()),
        "cot_fixed_few": int(df["cot_fixed_few"].sum()),
        "only_cot_correct": int(df["only_cot_correct"].sum()),
        "all_wrong": int(df["all_wrong"].sum())
    }])

    # Add summary row to the bottom
    df = pd.concat([df, summary], ignore_index=True)

    return df
