import json
from sentiment_classification_package.model_client import build_llm_client
from sentiment_classification_package.evaluator import evaluate_predictions
from sentiment_classification_package.prompts import create_prompt, zero_shot_system_message

# Load model
llm = build_llm_client()

# Gold example (Python list)
gold = json.loads('[{"text": "I loved this movie!", "label": "positive"}]')

# Build prompt
prompt = create_prompt(zero_shot_system_message)

# Run evaluation
result = evaluate_predictions(prompt, gold, llm=llm)

print(result)
