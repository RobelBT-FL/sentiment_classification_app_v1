# -*- coding: utf-8 -*-
"""
METRICS (SUPER SIMPLE VERSION)

LAYMAN EXPLANATION:
    This file calculates how good your model is.

    It computes:
        • Accuracy  → how many predictions were correct
        • F1 score  → balance of precision + recall
        • Precision → how many predicted positives were actually positive
        • Recall    → how many real positives the model found
        • ROC-AUC   → how well the model separates positive vs negative
        • PR-AUC    → area under precision-recall curve
        • Confusion matrix → table of correct/wrong predictions

    Everything here uses scikit-learn (industry standard).
"""

from sklearn.metrics import (
    accuracy_score,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
    average_precision_score,
    confusion_matrix
)


# ------------------------------------------------------------
# LABEL ENCODING HELPER
# ------------------------------------------------------------
def encode_labels(preds, truths):
    """
    Convert text labels → numbers for AUC metrics.

    LAYMAN EXPLANATION:
        AUC metrics need numbers, not words.
        So we convert:
            "positive" → 1
            "negative" → 0

        INPUT:
            preds  → list of model predictions
            truths → list of true labels

        OUTPUT:
            y_true → list of 0/1 true labels
            y_pred → list of 0/1 predicted labels
    """

    mapping = {"positive": 1, "negative": 0}

    y_true = [mapping[t] for t in truths]
    y_pred = [mapping[p] for p in preds]

    return y_true, y_pred


# ------------------------------------------------------------
# MAIN METRICS FUNCTION
# ------------------------------------------------------------
def compute_metrics(result):
    """
    Compute all evaluation metrics.

    INPUT:
        result → dictionary returned by evaluate_prediction()
                 {
                     "model_predictions": [...],
                     "ground_truths": [...]
                 }

    OUTPUT:
        Dictionary of metrics:
            {
                "accuracy": ...,
                "f1_micro": ...,
                "f1_macro": ...,
                "precision_micro": ...,
                "precision_macro": ...,
                "recall_micro": ...,
                "recall_macro": ...,
                "roc_auc": ...,
                "pr_auc": ...,
                "confusion_matrix": [...]
            }
    """

    # Extract predictions + true labels
    preds = result["model_predictions"]
    truths = result["ground_truths"]

    # Convert labels to numbers for AUC
    y_true, y_pred = encode_labels(preds, truths)

    # Build metrics dictionary
    metrics = {

        # ----------------------------------------------------
        # BASIC METRICS
        # ----------------------------------------------------
        # LAYMAN:
        #   Accuracy = % of correct predictions
        "accuracy": accuracy_score(truths, preds),

        # LAYMAN:
        #   Micro F1 = treats all examples equally
        "f1_micro": f1_score(truths, preds, average="micro"),

        # LAYMAN:
        #   Macro F1 = treats each class equally
        "f1_macro": f1_score(truths, preds, average="macro"),

        # ----------------------------------------------------
        # PRECISION
        # ----------------------------------------------------
        # LAYMAN:
        #   Precision = "When the model says positive, how often is it right?"
        "precision_micro": precision_score(truths, preds, average="micro"),
        "precision_macro": precision_score(truths, preds, average="macro"),

        # ----------------------------------------------------
        # RECALL
        # ----------------------------------------------------
        # LAYMAN:
        #   Recall = "How many real positives did the model find?"
        "recall_micro": recall_score(truths, preds, average="micro"),
        "recall_macro": recall_score(truths, preds, average="macro"),

        # ----------------------------------------------------
        # AUC METRICS (binary)
        # ----------------------------------------------------
        # LAYMAN:
        #   ROC-AUC = how well the model separates positive vs negative
        "roc_auc": roc_auc_score(y_true, y_pred),

        # LAYMAN:
        #   PR-AUC = area under precision-recall curve
        "pr_auc": average_precision_score(y_true, y_pred),

        # ----------------------------------------------------
        # CONFUSION MATRIX
        # ----------------------------------------------------
        # LAYMAN:
        #   Shows:
        #       - true positives
        #       - true negatives
        #       - false positives
        #       - false negatives
        "confusion_matrix": confusion_matrix(truths, preds).tolist()
    }

    return metrics
