#!/usr/bin/env -S uv run --script

# /// script
# dependencies = []
# ///

import argparse
import sys
from pathlib import Path
from subprocess import CalledProcessError, run


def decrypt_age_file(age_file_path: Path) -> str:
    """Decrypt an age-encrypted file using agenix."""
    cmd = ["agenix", "-d", age_file_path.name]
    try:
        out = run(cmd, capture_output=True, text=True, check=True)
        print(f"Out dec: {out}")
        return out.stdout
    except CalledProcessError as e:
        print(f"Error decrypting {age_file_path}: {e.stderr}", file=sys.stderr)
        raise


def write_to_temp(data: str, age_file_path: Path, temp_folder: Path):
    """Write decrypted data to a temporary file maintaining directory structure."""
    # Calculate relative path from the original age file
    relative_path = age_file_path.relative_to(age_file_path.parent.parent)

    # Remove .age extension to get the original file path
    target_path = temp_folder / relative_path.with_suffix("")

    # Create parent directories if they don't exist
    target_path.parent.mkdir(parents=True, exist_ok=True)

    # Write the decrypted content
    target_path.write_text(data)
    print(f"Written decrypted content to: {target_path}")


def create_root_structure(
    extra_files_folder: Path, temp_folder: Path = Path("/tmp/neusis_anywhere_temp")
):
    """Create a root file structure by decrypting age files and placing them in temp folder."""
    # Create temp folder if it doesn't exist
    temp_folder.mkdir(parents=True, exist_ok=True)

    # Find all .age files recursively
    age_files_list = [file for file in extra_files_folder.rglob("*.age")]

    if not age_files_list:
        print(f"No .age files found in {extra_files_folder}")
        return

    print(f"Found {len(age_files_list)} age files to decrypt")

    for age_file in age_files_list:
        try:
            print(f"Decrypting: {age_file}")
            decrypted_str = decrypt_age_file(age_file)
            write_to_temp(decrypted_str, age_file, temp_folder)
        except Exception as e:
            print(f"Failed to process {age_file}: {e}", file=sys.stderr)
            continue

    print(f"Root structure created in: {temp_folder}")


def main():
    """CLI interface for the anywhere script."""
    parser = argparse.ArgumentParser(
        description="Decrypt age files and create root file structure"
    )
    parser.add_argument(
        "extra_files_folder", type=Path, help="Path to folder containing .age files"
    )
    parser.add_argument(
        "--temp-folder",
        type=Path,
        default=Path("/tmp/neusis_anywhere_temp"),
        help="Temporary folder to create root structure (default: /tmp/neusis_anywhere_temp)",
    )

    args = parser.parse_args()

    # Validate input folder exists
    if not args.extra_files_folder.exists():
        print(f"Error: {args.extra_files_folder} does not exist", file=sys.stderr)
        sys.exit(1)

    if not args.extra_files_folder.is_dir():
        print(f"Error: {args.extra_files_folder} is not a directory", file=sys.stderr)
        sys.exit(1)

    try:
        create_root_structure(args.extra_files_folder, args.temp_folder)
    except Exception as e:
        print(f"Error creating root structure: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
