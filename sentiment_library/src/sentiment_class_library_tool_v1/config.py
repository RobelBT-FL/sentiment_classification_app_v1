# -*- coding: utf-8 -*-
"""
CONFIGURATION FILE FOR SENTIMENT ANALYSIS LIBRARY

LAYMAN EXPLANATION:
    Think of this file as a "control panel" for your library.
    These values tell your model:
        - which GGUF file to load
        - how many CPU/GPU resources to use
        - how long each review can be
        - how many few‑shot examples to include
        - how many test samples to evaluate

    Nothing here is complicated — these are just simple numbers
    that your code reads when it starts running.
"""

# ------------------------------------------------------------
# MODEL SETTINGS (FOR LLAMA‑2 7B GGUF)
# ------------------------------------------------------------

# LAYMAN:
#   This is the name of your model file inside the /models folder.
#   Your code will do: load("models/" + MODEL_FILENAME)
MODEL_FILENAME = "llama-2-7b-chat-hf-q4_k_m.gguf"

# LAYMAN:
#   These settings control how llama.cpp runs the model.
#   You can think of them like "performance knobs".

# Number of CPU threads to use.
# More threads = faster, but uses more CPU.
N_THREADS = 4

# How many tokens to process at once.
# Smaller = safer for 7B models, avoids memory issues.
N_BATCH = 256

# How many layers to offload to the GPU.
# 7B models usually support 20–30 layers on mid‑range GPUs.
N_GPU_LAYERS = 20

# Maximum context window (how much text the model can "see").
# 4096 is safe and fast for 7B.
N_CTX = 4096


# ------------------------------------------------------------
# DATA SETTINGS
# ------------------------------------------------------------

# LAYMAN:
#   Reviews can be very long. We cut them to a maximum length
#   so the model doesn't get overwhelmed.
MAX_REVIEW_CHARS = 300


# ------------------------------------------------------------
# FEW-SHOT SETTINGS
# ------------------------------------------------------------

# LAYMAN:
#   Few‑shot means: "show the model some examples before asking it to classify."
#   Here we show:
#       1 positive example
#       1 negative example
FEW_SHOT_EXAMPLES_PER_CLASS = 1

# LAYMAN:
#   We also limit how long each example can be.
FEW_SHOT_MAX_CHARS = 800


# ------------------------------------------------------------
# EVALUATION SETTINGS
# ------------------------------------------------------------

# LAYMAN:
#   How many test samples to evaluate.
#   Example: if GOLD_SAMPLE_SIZE = 50, we test on 50 reviews.
GOLD_SAMPLE_SIZE = 50

# LAYMAN:
#   How many times to repeat the evaluation.
#   Usually 1 is enough.
NUM_EVAL_RUNS = 1
