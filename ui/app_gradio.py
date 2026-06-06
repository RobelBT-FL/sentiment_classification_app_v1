import gradio as gr
import requests

FASTAPI_BASE = "http://127.0.0.1:8000"

# -------------------------------------------------
# 1. HEALTH CHECK
# -------------------------------------------------
def check_health():
    try:
        r = requests.get(f"{FASTAPI_BASE}/health")
        return r.json()
    except Exception as e:
        return {"error": str(e)}

# -------------------------------------------------
# 2. SINGLE PREDICTION
# -------------------------------------------------
def predict_sentiment(review, mode):
    if review is None or review.strip() == "":
        return {"error": "Review text is empty"}

    payload = {
        "review": review,   # <-- FIXED: must match FastAPI
        "mode": mode
    }

    try:
        r = requests.post(f"{FASTAPI_BASE}/predict", json=payload)
        return r.json()
    except Exception as e:
        return {"error": str(e)}

# -------------------------------------------------
# 3. EVALUATE MODEL
# -------------------------------------------------
def evaluate_model(mode, sample_size):
    payload = {
        "mode": mode,
        "n_samples": int(sample_size)   # <-- FIXED: must match FastAPI
    }

    try:
        r = requests.post(f"{FASTAPI_BASE}/evaluate", json=payload)
        return r.json()
    except Exception as e:
        return {"error": str(e)}

# -------------------------------------------------
# BUILD GRADIO UI
# -------------------------------------------------
with gr.Blocks(title="SentimentFASTAPI - Gradio UI") as demo:

    gr.Markdown("# 💬 SentimentFASTAPI — Gradio UI")
    gr.Markdown("FastAPI backend + Gradio frontend for sentiment analysis")

    # ------------------ HEALTH CHECK TAB ------------------
    with gr.Tab("🔍 Health Check"):
        gr.Markdown("Ping the `/health` endpoint to verify backend status.")
        health_btn = gr.Button("Check /health")
        health_output = gr.JSON()
        health_btn.click(fn=check_health, outputs=health_output)

    # ------------------ PREDICT TAB ------------------
    with gr.Tab("🧠 Predict Sentiment"):
        review_input = gr.Textbox(
            label="Enter a movie review",
            placeholder="Type your review here..."
        )
        mode_input = gr.Radio(
            ["zero_shot", "few_shot", "cot"],
            label="Select mode"
        )
        predict_btn = gr.Button("Predict")
        predict_output = gr.JSON()

        predict_btn.click(
            fn=predict_sentiment,
            inputs=[review_input, mode_input],
            outputs=predict_output
        )

    # ------------------ EVALUATE TAB ------------------
    with gr.Tab("📊 Evaluate Model"):
        eval_mode = gr.Radio(
            ["zero_shot", "few_shot", "cot"],
            label="Select mode"
        )
        eval_samples = gr.Slider(
            minimum=5,
            maximum=200,
            value=20,
            step=5,
            label="Number of samples"
        )
        eval_btn = gr.Button("Run Evaluation")
        eval_output = gr.JSON()

        eval_btn.click(
            fn=evaluate_model,
            inputs=[eval_mode, eval_samples],
            outputs=eval_output
        )

demo.launch(server_name="0.0.0.0", server_port=7860)
