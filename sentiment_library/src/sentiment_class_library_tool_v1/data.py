"""
DATA LOADING + PREPROCESSING (SUPER SIMPLE VERSION)

This file loads your local IMDb CSV file and prepares it for the model.

LAYMAN EXPLANATION:
    Imagine you have a big Excel file of movie reviews.
    This file does 3 things:

    1. Loads the CSV into Python
    2. Cleans it (rename columns, lowercase labels)
    3. Creates helper functions for:
         - shortening long reviews
         - picking few-shot examples
         - picking gold evaluation examples
"""

import pandas as pd
import json


# ------------------------------------------------------------
# 1. LOAD LOCAL IMDB CSV
# ------------------------------------------------------------
def load_dataset(path: str):
    """
    Load the IMDb CSV file from your computer.

    INPUT:
        path → full path to imdb.csv
               Example:
               "C:/Robel/sentiment_project/data/imdb.csv"

    OUTPUT:
        A clean DataFrame with:
            text  → the review text
            label → "positive" or "negative"
    """

    # Read the CSV file into a DataFrame (like an Excel table)
    df = pd.read_csv(path)

    # Make all column names lowercase (just to be safe)
    df.columns = [c.lower() for c in df.columns]

    # Check that the CSV has the columns we expect
    if "review" not in df.columns or "sentiment" not in df.columns:
        raise ValueError(
            f"Expected columns 'review' and 'sentiment'. Found: {df.columns.tolist()}"
        )

    # Keep only the two important columns
    df = df[["review", "sentiment"]].dropna()

    # Rename them to what the rest of the code expects
    df.columns = ["text", "label"]

    # Make labels lowercase ("Positive" → "positive")
    df["label"] = df["label"].str.lower()

    return df


# ------------------------------------------------------------
# 2. TRUNCATE LONG REVIEWS
# ------------------------------------------------------------
def truncate(text: str, max_len: int):
    """
    Shorten long reviews.

    LAYMAN EXPLANATION:
        If a review is too long, we cut it down so the model
        doesn't run out of memory.

    INPUT:
        text     → the review
        max_len  → maximum characters allowed

    OUTPUT:
        shortened text
    """
    return text[:max_len]


# ------------------------------------------------------------
# 3. CREATE FEW-SHOT EXAMPLES
# ------------------------------------------------------------
def create_examples(df, num_per_class: int = 1):
    """
    Create few-shot examples for prompting.

    LAYMAN EXPLANATION:
        Few-shot = "show the model a couple of examples first."

        We pick:
            - num_per_class positive reviews
            - num_per_class negative reviews

        Then we shuffle them so the order is random.

    OUTPUT:
        A list of dictionaries:
            [
                {"text": "...", "label": "positive"},
                {"text": "...", "label": "negative"}
            ]
    """

    # Pick random positive examples
    pos = df[df["label"] == "positive"].sample(num_per_class)

    # Pick random negative examples
    neg = df[df["label"] == "negative"].sample(num_per_class)

    # Combine and shuffle
    examples = pd.concat([pos, neg]).sample(frac=1)

    # Convert DataFrame → list of dicts
    return examples.to_dict(orient="records")


# ------------------------------------------------------------
# 4. CREATE GOLD EVALUATION SET
# ------------------------------------------------------------
def load_gold(df, num_gold: int = 50):
    """
    Pick a fixed number of gold evaluation examples.

    LAYMAN EXPLANATION:
        Gold examples = "test questions" used to measure accuracy.

        We randomly pick num_gold reviews.

    OUTPUT:
        JSON string containing the selected examples.
    """

    # Pick random rows (same every time because random_state=42)
    gold = df[["text", "label"]].sample(num_gold, random_state=42)

    # Convert to JSON string
    return gold.to_json(orient="records")


# ------------------------------------------------------------
# 5. JSON → PYTHON LIST
# ------------------------------------------------------------
def json_to_list(json_str):
    """
    Convert JSON string → Python list.

    LAYMAN EXPLANATION:
        The evaluator needs a Python list, not JSON text.
        This function converts between the two.
    """
    return json.loads(json_str)
