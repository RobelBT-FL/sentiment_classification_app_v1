import json
from tqdm import tqdm

def evaluate_prediction(prompt, gold_examples, llm, use_tqdm=False):
    """
    Evaluate model on gold examples.
    """

    full_reviews = []
    truncated_reviews = []
    model_predictions = []
    ground_truths = []

    gold_list = json.loads(gold_examples)

    iterator = tqdm(gold_list, desc="Evaluating", ncols=80) if use_tqdm else gold_list

    for example in iterator:
        full_text = example["text"]
        full_reviews.append(full_text)

        truncated = full_text[:300]
        truncated_reviews.append(truncated)

        final_prompt = prompt + f"\nReview:\n{truncated}\nSentiment:"

        try:
            raw_output = llm(final_prompt)
            pred = raw_output.lower().strip()

            if "positive" in pred:
                clean_pred = "positive"
            elif "negative" in pred:
                clean_pred = "negative"
            else:
                clean_pred = "negative"

            model_predictions.append(clean_pred)
            ground_truths.append(example["label"].lower().strip())

        except Exception as e:
            print("Error:", e)
            model_predictions.append("error")
            ground_truths.append(example["label"])

    return {
        "full_reviews": full_reviews,
        "truncated_reviews": truncated_reviews,
        "model_predictions": model_predictions,
        "ground_truths": ground_truths
    }
