# -*- coding: utf-8 -*-
"""
PROMPT TEMPLATES (SUPER SIMPLE VERSION)

LAYMAN EXPLANATION:
    This file builds the text prompts that we send to the model.

    It supports three modes:
        • Zero-shot        → no examples, only instructions
        • Few-shot         → show a few labeled examples
        • Chain-of-thought → ask the model to "think" internally

    The goal:
        - keep prompts short
        - keep them clear
        - make them easy to read and modify
"""

import json  # (not strictly needed here, but harmless if you keep it)


# ------------------------------------------------------------
# ZERO-SHOT PROMPT
# ------------------------------------------------------------
def build_zero_shot_prompt():
    """
    Build a zero-shot prompt.

    LAYMAN EXPLANATION:
        Zero-shot means:
            "We give the model only instructions, no examples."

        We tell the model:
            - You are a sentiment classifier
            - Read the review
            - Output exactly one word: positive or negative
            - Do NOT explain
    """

    prompt = (
        "You are a sentiment classifier.\n"
        "Read the review and output exactly one word:\n"
        "positive or negative.\n"
        "Do not explain.\n"
        "Do not add extra words.\n"
    )

    return prompt


# ------------------------------------------------------------
# FEW-SHOT PROMPT
# ------------------------------------------------------------
def build_few_shot_prompt(examples):
    """
    Build a few-shot prompt.

    INPUT:
        examples → list of dictionaries, like:
            [
                {"text": "I loved this movie!", "label": "positive"},
                {"text": "This was terrible.", "label": "negative"}
            ]

    LAYMAN EXPLANATION:
        Few-shot means:
            "Show the model some labeled examples first,
             then ask it to classify a new review."

        We:
            - Start with instructions
            - Add each example as:
                  Review:
                  <text>
                  Sentiment: <label>
            - End with instructions for the next review
    """

    # Start with general instructions
    prompt = (
        "You are a sentiment classifier.\n"
        "Here are some examples:\n\n"
    )

    # Add each example to the prompt
    for ex in examples:
        prompt += (
            f"Review:\n{ex['text']}\n"
            f"Sentiment: {ex['label']}\n\n"
        )

    # Final instruction for the model
    prompt += (
        "Now classify the next review.\n"
        "Output exactly one word: positive or negative.\n"
        "Do not explain.\n"
    )

    return prompt


# ------------------------------------------------------------
# CHAIN-OF-THOUGHT PROMPT
# ------------------------------------------------------------
def build_cot_prompt(examples):
    """
    Build a Chain-of-Thought (CoT) prompt.

    INPUT:
        examples → list of dictionaries (same format as few-shot)

    LAYMAN EXPLANATION:
        Chain-of-thought (CoT) means:
            "Ask the model to think step-by-step internally,
             but only show the final answer."

        We:
            - Tell the model to think step-by-step in its "head"
            - Show labeled examples
            - Ask it to output only one word: positive or negative
    """

    # Start with CoT-specific instructions
    prompt = (
        "You are a sentiment classifier.\n"
        "Think step-by-step internally.\n"
        "But ONLY output the final answer:\n"
        "positive or negative.\n\n"
        "Here are some examples:\n\n"
    )

    # Add examples
    for ex in examples:
        prompt += (
            f"Review:\n{ex['text']}\n"
            f"Sentiment: {ex['label']}\n\n"
        )

    # Final instruction
    prompt += (
        "Now classify the next review.\n"
        "Remember: think internally, but output only one word.\n"
    )

    return prompt

