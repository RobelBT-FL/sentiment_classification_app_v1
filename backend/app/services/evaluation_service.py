import pandas as pd
import logging
import os
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score

logger = logging.getLogger(__name__)

class EvaluationService:
    """
    Loads IMDB dataset, samples 25 positive + 25 negative,
    runs predictions, and computes accuracy, precision, recall, F1.
    """

    def evaluate(self, dataset_path: str, model, predict_fn):
        """
        dataset_path: FULL path to imdb.csv
        model: loaded model
        predict_fn: function(text, model) -> label
        """

        # dataset_path is the FULL path to imdb.csv
        if not os.path.exists(dataset_path):
            return {
                "error": f"Dataset not found at: {dataset_path}",
                "dataset_size": 0,
                "accuracy": 0.0
            }

        df = pd.read_csv(dataset_path)

        if "review" not in df.columns or "sentiment" not in df.columns:
            return {
                "error": "Dataset must contain 'review' and 'sentiment' columns",
                "dataset_size": 0,
                "accuracy": 0.0
            }

        # Split into positive / negative
        pos = df[df["sentiment"] == "positive"]
        neg = df[df["sentiment"] == "negative"]

        # Sample 25 each (will raise if not enough rows)
        pos_sample = pos.sample(25, random_state=42)
        neg_sample = neg.sample(25, random_state=42)

        eval_df = pd.concat([pos_sample, neg_sample]).reset_index(drop=True)

        gold_labels = []
        pred_labels = []

        for _, row in eval_df.iterrows():
            text = row["review"]
            gold = row["sentiment"]

            pred = predict_fn(text, model)

            gold_labels.append(gold)
            pred_labels.append(pred)

        # Metrics (macro handles positive/negative/unknown safely)
        accuracy = accuracy_score(gold_labels, pred_labels)
        precision = precision_score(gold_labels, pred_labels, average="macro", zero_division=0)
        recall = recall_score(gold_labels, pred_labels, average="macro", zero_division=0)
        f1 = f1_score(gold_labels, pred_labels, average="macro", zero_division=0)

        return {
            "dataset_size": len(eval_df),
            "accuracy": accuracy,
            "precision": precision,
            "recall": recall,
            "f1_score": f1,
            "samples_used": {
                "positive": 25,
                "negative": 25
            }
        }
