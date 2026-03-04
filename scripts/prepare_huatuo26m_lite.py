#!/usr/bin/env python
"""Download and convert Huatuo26M-Lite into a LLaMA-Factory local dataset."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Dict

from datasets import load_dataset


DEFAULT_DATASET_ID = "FreedomIntelligence/Huatuo26M-Lite"
DEFAULT_SPLIT = "train"


def normalize_record(sample: Dict[str, Any]) -> Dict[str, str] | None:
    instruction = str(sample.get("instruction", "") or "").strip()
    input_text = str(sample.get("input", "") or "").strip()
    output_text = str(sample.get("output", "") or "").strip()

    if not instruction or not output_text:
        return None

    return {
        "instruction": instruction,
        "input": input_text,
        "output": output_text,
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dataset-id",
        default=DEFAULT_DATASET_ID,
        help="Hugging Face dataset id.",
    )
    parser.add_argument(
        "--split",
        default=DEFAULT_SPLIT,
        help="Dataset split to download.",
    )
    parser.add_argument(
        "--output",
        default="medical_qwen25_huatuo/dataset/huatuo26m_lite_sft.jsonl",
        help="Output jsonl path for LLaMA-Factory.",
    )
    parser.add_argument(
        "--report",
        default="medical_qwen25_huatuo/dataset/prepare_report.json",
        help="Where to write preparation statistics.",
    )
    parser.add_argument(
        "--max-samples",
        type=int,
        default=None,
        help="Optional cap for quick smoke tests.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_path = Path(args.output)
    report_path = Path(args.report)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    dataset = load_dataset(args.dataset_id, split=args.split)
    kept = 0
    skipped = 0

    with output_path.open("w", encoding="utf-8") as fout:
        for index, sample in enumerate(dataset):
            if args.max_samples is not None and index >= args.max_samples:
                break

            normalized = normalize_record(sample)
            if normalized is None:
                skipped += 1
                continue

            fout.write(json.dumps(normalized, ensure_ascii=False) + "\n")
            kept += 1

    report = {
        "dataset_id": args.dataset_id,
        "split": args.split,
        "output": str(output_path).replace("\\", "/"),
        "kept_samples": kept,
        "skipped_samples": skipped,
        "max_samples": args.max_samples,
    }
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
