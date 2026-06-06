"use client";

import Link from "next/link";

export default function Home() {
  return (
    <div className="flex flex-col items-center justify-center h-screen gap-6">
      <h1 className="text-3xl font-bold">Welcome to the Sentiment App</h1>

      <div className="flex gap-4">
        <Link
          href="/predict"
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Go to Prediction
        </Link>

        <Link
          href="/evaluate"
          className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
        >
          Run Evaluation
        </Link>
      </div>
    </div>
  );
}
