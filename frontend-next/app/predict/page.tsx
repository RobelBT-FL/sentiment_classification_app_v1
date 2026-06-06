"use client";

import { useState } from "react";

export default function PredictPage() {
  const [text, setText] = useState("");
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handlePredict() {
    if (!text.trim()) {
      setError("Please enter some text.");
      return;
    }

    setLoading(true);
    setError("");
    setResult(null);

    try {
      const res = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/api/v1/sentiment/predict`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ text }),
        }
      );

      const data = await res.json();
      setResult(data);
    } catch (err) {
      setError("Failed to connect to backend.");
    }

    setLoading(false);
  }

  return (
    <div className="p-10 max-w-2xl mx-auto">
      <h1 className="text-3xl font-bold mb-6">Sentiment Prediction</h1>

      <textarea
        className="w-full border p-3 rounded mb-4"
        rows={5}
        placeholder="Enter text to analyze..."
        value={text}
        onChange={(e) => setText(e.target.value)}
      />

      {error && <p className="text-red-600 mb-3">{error}</p>}

      <button
        onClick={handlePredict}
        disabled={loading}
        className="bg-blue-600 text-white px-4 py-2 rounded disabled:bg-blue-300"
      >
        {loading ? "Predicting..." : "Predict"}
      </button>

      {result && (
        <div className="mt-6 p-4 border rounded bg-gray-50">
          <h2 className="text-xl font-semibold mb-2">Result</h2>

          {/* ⭐ RED TEXT FOR LABEL */}
          <p className="text-red-600">
            <strong>Label:</strong> {result.label}
          </p>

          <p className="mt-1">
            <strong>Score:</strong> {result.score}
          </p>
        </div>
      )}
    </div>
  );
}
