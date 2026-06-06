# -*- coding: utf-8 -*-
"""
Simple Model Loader for Local GGUF Models using llama.cpp

LAYMAN EXPLANATION:
    This file loads your local LLaMA‑2 7B model.
    No downloading. No HuggingFace. No internet.
    Just load the .gguf file from your Windows folder.
"""

import os
from llama_cpp import Llama
from sentiment_class_library_tool_v1.config import (
    MODEL_FILENAME,
    N_THREADS,
    N_BATCH,
    N_GPU_LAYERS,
    N_CTX,
)


class LlamaClient:
    """
    Wrapper around llama.cpp Llama() class.

    LAYMAN EXPLANATION:
        This class loads your GGUF model and lets you call it like:

            llm("Hello world")

        It hides all the complicated llama.cpp settings.
    """

    def __init__(self, model_path=None):
        """
        Load the GGUF model from your local /models folder.

        If model_path is not provided, we build it automatically.
        """

        # If user didn't pass a path, build it automatically
        if model_path is None:
            model_path = os.path.join(
                "C:/Robel_AI_ML_Python_Package_Development_Library",
                "sentiment_classification_project_v2",
                "models",
                MODEL_FILENAME
            )

        print(f"\nLoading model from:\n{model_path}\n")

        # Load the model using llama.cpp
        self.llm = Llama(
            model_path=model_path,
            n_threads=N_THREADS,
            n_batch=N_BATCH,
            n_gpu_layers=N_GPU_LAYERS,
            n_ctx=N_CTX,
            verbose=False
        )

    # ------------------------------------------------------------
    # CALL THE MODEL
    # ------------------------------------------------------------
    def __call__(self, prompt: str):
        """
        Run inference on the model.

        INPUT:
            prompt → the text you want the model to respond to

        OUTPUT:
            model's text response
        """

        output = self.llm(
            prompt,
            max_tokens=50,
            temperature=0.0,
            stop=["\n"]
        )

        return output["choices"][0]["text"].strip()
