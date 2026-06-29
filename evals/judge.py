"""
judge.py — LLM rubric evaluator for agentic-bi-workforce.

Reads an eval brief and a set of artifact paths, then scores the artifact against
the rubric defined in the brief using an LLM judge. Outputs a JSON result suitable
for ingestion by eval.ps1.

Usage:
    python evals/judge.py --brief evals/briefs/overview-page.md \\
                          --artifact path/to/report.json \\
                          --client volvo

Requirements:
    pip install openai>=1.0 rich
    Set OPENAI_API_KEY or AZURE_OPENAI_* env vars.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path


def load_brief(brief_path: str) -> str:
    path = Path(brief_path)
    if not path.exists():
        raise FileNotFoundError(f"Brief not found: {brief_path}")
    return path.read_text(encoding="utf-8")


def load_artifact(artifact_path: str) -> str:
    path = Path(artifact_path)
    if not path.exists():
        raise FileNotFoundError(f"Artifact not found: {artifact_path}")
    content = path.read_text(encoding="utf-8")
    # Truncate very large artifacts to avoid exceeding token limits
    max_chars = 12_000
    if len(content) > max_chars:
        content = content[:max_chars] + "\n... [TRUNCATED]"
    return content


def load_brand(client: str) -> dict:
    brand_path = Path(__file__).parent.parent / "clients" / client / "brand.json"
    if not brand_path.exists():
        return {}
    return json.loads(brand_path.read_text(encoding="utf-8"))


def build_prompt(brief: str, artifact: str, brand: dict) -> str:
    brand_snippet = json.dumps(brand, indent=2) if brand else "{}"
    return f"""You are an expert Power BI quality evaluator for WPP.

## Evaluation Brief
{brief}

## Brand Tokens
```json
{brand_snippet}
```

## Artifact Under Review
```json
{artifact}
```

## Task
Score the artifact against every criterion in the brief.
Return ONLY a valid JSON object with this exact schema — no markdown fences, no extra text:
{{
  "overallScore": <0-100 integer>,
  "criteriaScores": {{
    "<criterion-name>": {{
      "score":  <0-100 integer>,
      "weight": <0.0-1.0 float>,
      "rationale": "<one sentence>"
    }}
  }},
  "passThreshold": 70,
  "pass": <true|false>,
  "summary": "<two sentences max>"
}}
"""


def call_llm(prompt: str) -> str:
    """Call the LLM judge. Supports OpenAI and Azure OpenAI."""
    try:
        import openai  # noqa: PLC0415
    except ImportError:
        raise RuntimeError(
            "openai package not installed. Run: pip install openai>=1.0"
        )

    azure_endpoint = os.environ.get("AZURE_OPENAI_ENDPOINT")
    if azure_endpoint:
        client = openai.AzureOpenAI(
            azure_endpoint=azure_endpoint,
            api_key=os.environ.get("AZURE_OPENAI_API_KEY", ""),
            api_version=os.environ.get("AZURE_OPENAI_API_VERSION", "2024-02-01"),
        )
        model = os.environ.get("AZURE_OPENAI_DEPLOYMENT", "gpt-4o")
    else:
        client = openai.OpenAI(
            api_key=os.environ.get("OPENAI_API_KEY", ""),
        )
        model = os.environ.get("JUDGE_MODEL", "gpt-4o")

    response = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        temperature=0,
        max_tokens=1024,
    )
    return response.choices[0].message.content or ""


def parse_llm_response(raw: str) -> dict:
    """Extract and validate JSON from LLM response."""
    # Strip markdown fences if present
    text = raw.strip()
    if text.startswith("```"):
        lines = text.split("\n")
        text = "\n".join(lines[1:-1]) if lines[-1] == "```" else "\n".join(lines[1:])

    result = json.loads(text)

    required_keys = {"overallScore", "criteriaScores", "passThreshold", "pass", "summary"}
    missing = required_keys - set(result.keys())
    if missing:
        raise ValueError(f"LLM response missing keys: {missing}")

    return result


def main() -> None:
    parser = argparse.ArgumentParser(description="LLM rubric evaluator")
    parser.add_argument("--brief",    required=True, help="Path to eval brief markdown")
    parser.add_argument("--artifact", required=True, help="Path to artifact file")
    parser.add_argument("--client",   default="volvo", help="Client slug for brand tokens")
    parser.add_argument("--dry-run",  action="store_true",
                        help="Print prompt only; do not call LLM")
    args = parser.parse_args()

    run_id    = str(uuid.uuid4())
    timestamp = datetime.now(tz=timezone.utc).isoformat()

    brief    = load_brief(args.brief)
    artifact = load_artifact(args.artifact)
    brand    = load_brand(args.client)
    prompt   = build_prompt(brief, artifact, brand)

    if args.dry_run:
        print(prompt)
        return

    try:
        raw    = call_llm(prompt)
        scored = parse_llm_response(raw)
    except Exception as exc:  # noqa: BLE001
        result = {
            "runId":     run_id,
            "timestamp": timestamp,
            "brief":     args.brief,
            "artifact":  args.artifact,
            "client":    args.client,
            "error":     str(exc),
            "pass":      False,
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)

    result = {
        "runId":     run_id,
        "timestamp": timestamp,
        "brief":     args.brief,
        "artifact":  args.artifact,
        "client":    args.client,
        **scored,
    }

    print(json.dumps(result, indent=2))

    # Persist to logs/ for skill-improve ingestion
    logs_dir = Path(__file__).parent.parent / "logs"
    logs_dir.mkdir(exist_ok=True)
    log_file = logs_dir / f"eval-{run_id}.json"
    log_file.write_text(json.dumps(result, indent=2), encoding="utf-8")

    sys.exit(0 if scored.get("pass") else 1)


if __name__ == "__main__":
    main()
