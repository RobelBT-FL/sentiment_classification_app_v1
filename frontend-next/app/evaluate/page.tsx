"use client";

import { useState } from "react";

export default function EvaluatePage() {
  const [result, setResult] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function runEvaluation() {
    setLoading(true);
    setResult(null);

    try {
      const res = await fetch("http://localhost:8000/api/v1/sentiment/evaluate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({}), // your backend expects an EvaluationRequest
      });

      if (!res.ok) {
        throw new Error("Evaluation failed");
      }

      const data = await res.json();
      setResult(JSON.stringify(data, null, 2));
    } catch (err) {
      setResult("Failed to connect to backend");
    }

    setLoading(false);
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center text-white">
      <h1 className="text-3xl font-bold mb-6">Evaluation</h1>

      <button
        onClick={runEvaluation}
        className="bg-green-600 px-6 py-3 rounded hover:bg-green-700"
      >
        {loading ? "Running..." : "Run Evaluation"}
      </button>

      {result && (
        <pre className="mt-6 bg-black p-4 rounded w-2/3 text-sm whitespace-pre-wrap text-red-500 border border-red-600">
          {result}
        </pre>
      )}
    </div>
  );
}
