#!/usr/bin/env python
"""Upload a local folder to the Hugging Face Hub."""

from __future__ import annotations

import argparse
import os
from pathlib import Path

from huggingface_hub import HfApi


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo-id", required=True, help="Target Hugging Face repo id, e.g. user/repo.")
    parser.add_argument("--local-dir", required=True, help="Local folder to upload.")
    parser.add_argument("--repo-type", default="model", help="Hub repo type. Defaults to model.")
    parser.add_argument("--private", action="store_true", help="Create the repo as private if it does not exist.")
    parser.add_argument(
        "--commit-message",
        default="Upload model artifacts from medical_qwen25_huatuo",
        help="Commit message used on Hugging Face Hub.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    folder = Path(args.local_dir)
    if not folder.exists() or not folder.is_dir():
        raise SystemExit(f"Local directory not found: {folder}")

    api = HfApi(token=os.getenv("HF_TOKEN") or None)
    repo_url = api.create_repo(
        repo_id=args.repo_id,
        repo_type=args.repo_type,
        private=args.private,
        exist_ok=True,
    )
    api.upload_folder(
        repo_id=args.repo_id,
        repo_type=args.repo_type,
        folder_path=str(folder),
        commit_message=args.commit_message,
        ignore_patterns=["*.pyc", "__pycache__", ".DS_Store"],
    )
    print(repo_url)


if __name__ == "__main__":
    main()
