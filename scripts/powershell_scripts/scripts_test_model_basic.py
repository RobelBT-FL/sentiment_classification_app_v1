# Test the model ALONE (no pipeline, no UI)

from sentiment_classification_package.model_client import build_llm_client
from sentiment_classification_package.prompts import create_prompt, zero_shot_system_message

# Load model
llm = build_llm_client()

# Build prompt
prompt = create_prompt(zero_shot_system_message)
final_prompt = prompt.format(input="This movie was absolutely amazing!")

# Run model
print("Model output:", llm(final_prompt))
