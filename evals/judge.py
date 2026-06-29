"""Tier-2 LLM judge: score a generated report against the approved brief (spec-as-truth).

This is harness scaffolding. The actual scoring call is delegated to the coding agent
(Copilot/Opus) at runtime; here we only assemble the rubric prompt and parse a verdict.
Truth = the brief, so this works in production (no golden file required).
"""
import argparse, json, pathlib, sys


def load_brief(path: str) -> str:
    return pathlib.Path(path).read_text(encoding="utf-8")


def build_prompt(brief: str, gate_report: dict) -> str:
    return (
        "You are grading a Power BI overview page against an approved brief.\n"
        "Score each rubric item pass/fail with one-line evidence; overall = % passed.\n\n"
        f"BRIEF:\n{brief}\n\nTIER-1 GATES:\n{json.dumps(gate_report, indent=2)}\n"
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--brief", required=True)
    ap.add_argument("--gates", required=True, help="gates.ps1 JSON output")
    ap.add_argument("--out", default="-")
    a = ap.parse_args()
    gate = json.loads(pathlib.Path(a.gates).read_text(encoding="utf-8"))
    prompt = build_prompt(load_brief(a.brief), gate)
    result = {"prompt": prompt, "tier1_pass": gate.get("pass"), "rubric": "delegated_to_agent"}
    out = json.dumps(result, indent=2)
    (sys.stdout.write(out + "\n") if a.out == "-" else pathlib.Path(a.out).write_text(out, encoding="utf-8"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
