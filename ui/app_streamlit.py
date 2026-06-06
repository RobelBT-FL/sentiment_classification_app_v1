"""
Streamlit UI for SentimentFASTAPI

LAYMAN EXPLANATION:
    This file creates a small web app (UI) that:
      - checks the health of your FastAPI server
      - sends a review to /predict and shows the sentiment
      - runs /evaluate and shows accuracy + F1

    It does NOT run the model itself.
    It only talks to your FastAPI backend over HTTP.
"""

import requests
import streamlit as st

# -----------------------------
# CONFIG & BASIC PAGE SETUP
# -----------------------------

API_BASE_URL = "http://127.0.0.1:8000"

st.set_page_config(
    page_title="SentimentFASTAPI UI",
    page_icon="🎬",
    layout="centered",
)

# A little header styling
st.markdown(
    """
    <style>
    .main-title {
        font-size: 32px;
        font-weight: 700;
        text-align: center;
        margin-bottom: 0.2rem;
    }
    .subtitle {
        text-align: center;
        color: #888888;
        margin-bottom: 1.5rem;
    }
    </style>
    """,
    unsafe_allow_html=True,
)

st.markdown('<div class="main-title">🎬 SentimentFASTAPI UI</div>', unsafe_allow_html=True)
st.markdown('<div class="subtitle">FastAPI backend + Streamlit frontend</div>', unsafe_allow_html=True)

st.write("---")

# -----------------------------
# HEALTH CHECK SECTION
# -----------------------------

st.header("1. Health Check")

col1, col2 = st.columns([1, 3])

with col1:
    if st.button("Ping /health"):
        try:
            response = requests.get(f"{API_BASE_URL}/health", timeout=5)
            if response.status_code == 200:
                data = response.json()
                st.success("✅ Server is up!")
                st.json(data)
            else:
                st.error(f"❌ Server responded with status code {response.status_code}")
        except Exception as e:
            st.error(f"❌ Could not reach server: {e}")

with col2:
    st.info(
        "This calls `GET /health` on your FastAPI server.\n\n"
        "If it works, it means:\n"
        "- FastAPI is running\n"
        "- Your model is probably loaded\n"
        "- The backend is reachable from this UI"
    )

st.write("---")

# -----------------------------
# PREDICT SECTION
# -----------------------------

st.header("2. Single Review Prediction")

st.write("Enter a movie review and choose a mode. The UI will call `POST /predict`.")

review_text = st.text_area(
    "Review text",
    height=150,
    placeholder="Type a movie review here...",
)

mode = st.selectbox(
    "Prediction mode",
    ["zero_shot", "few_shot", "cot"],
    index=0,
)

if st.button("Predict Sentiment"):
    if not review_text.strip():
        st.warning("Please enter a review before predicting.")
    else:
        payload = {
            "review": review_text,
            "mode": mode,
        }

        try:
            response = requests.post(
                f"{API_BASE_URL}/predict",
                json=payload,
                timeout=30,
            )
            if response.status_code == 200:
                data = response.json()
                st.subheader("Prediction Result")
                st.markdown(f"**Sentiment:** `{data.get('sentiment', 'unknown')}`")
                st.markdown("**Raw Model Output:**")
                st.code(data.get("raw_output", ""), language="text")
                st.markdown(f"**Mode used:** `{data.get('mode', '')}`")
            else:
                st.error(f"❌ /predict returned status code {response.status_code}")
                st.text(response.text)
        except Exception as e:
            st.error(f"❌ Error calling /predict: {e}")

st.write("---")

# -----------------------------
# EVALUATE SECTION
# -----------------------------

st.header("3. Batch Evaluation")

st.write(
    "Run the model on multiple IMDB samples via `POST /evaluate` "
    "and see accuracy + F1."
)

eval_mode = st.selectbox(
    "Evaluation mode",
    ["zero_shot", "few_shot", "cot"],
    index=0,
    key="eval_mode",
)

n_samples = st.slider(
    "Number of samples",
    min_value=10,
    max_value=200,
    value=50,
    step=10,
)

if st.button("Run Evaluation"):
    payload = {
        "mode": eval_mode,
        "n_samples": n_samples,
    }

    with st.spinner("Running evaluation... this may take a while."):
        try:
            response = requests.post(
                f"{API_BASE_URL}/evaluate",
                json=payload,
                timeout=600,
            )
            if response.status_code == 200:
                data = response.json()
                st.subheader("Evaluation Metrics")
                st.metric("Accuracy", f"{data.get('accuracy', 0):.3f}")
                st.metric("F1 Score", f"{data.get('f1', 0):.3f}")
                st.markdown(f"**Mode used:** `{data.get('mode', '')}`")
            else:
                st.error(f"❌ /evaluate returned status code {response.status_code}")
                st.text(response.text)
        except Exception as e:
            st.error(f"❌ Error calling /evaluate: {e}")

st.write("---")

st.caption("Built with ❤️ using FastAPI + Streamlit")
