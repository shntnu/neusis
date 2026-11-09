"""Render lineno regression tests with the actual pinned CLSI TeX binaries.

Requires Python with PyMuPDF. All compile directories are fresh and retained.
"""

import argparse
import collections
import json
import os
from pathlib import Path
import shutil
import subprocess

import pymupdf


SOURCE = r"""\documentclass[10pt,twocolumn,letterpaper]{article}
\usepackage[margin=0.8in]{geometry}
\usepackage{amsmath}
\usepackage{xcolor}
\usepackage{lipsum}
\ifdefined\FinalMode\else
\usepackage[switch,mathlines]{lineno}
\renewcommand\linenumberfont{\normalfont\ttfamily\scriptsize\color{blue}}
\setlength{\linenumbersep}{12pt}
\linenumbers
\fi
\begin{document}
\section{Column and page transitions}
\lipsum[1-16]
\section{Equations}
\begin{equation} a+b=c \end{equation}
\lipsum[17-32]
\end{document}
"""


def run(command, cwd, env):
    result = subprocess.run(
        command, cwd=cwd, env=env, capture_output=True, text=True, timeout=120
    )
    (cwd / "last-command.stdout.log").write_text(result.stdout)
    (cwd / "last-command.stderr.log").write_text(result.stderr)
    if result.returncode:
        raise RuntimeError(f"Command failed in {cwd}: {command}: {result.returncode}")
    return result.stdout


def compile_doc(directory, env, final=False):
    directory.mkdir(exist_ok=True)
    (directory / "test.tex").write_text(
        (r"\def\FinalMode{1}" + "\n" if final else "") + SOURCE
    )
    run(
        ["latexmk", "-pdf", "-interaction=nonstopmode", "-halt-on-error", "test.tex"],
        directory,
        env,
    )
    with pymupdf.open(directory / "test.pdf") as pdf:
        numbers, body = [], []
        for page_index, page in enumerate(pdf):
            for block in page.get_text("dict")["blocks"]:
                for line in block.get("lines", []):
                    for span in line["spans"]:
                        item = (
                            page_index,
                            span["text"],
                            tuple(round(v, 2) for v in span["bbox"]),
                        )
                        if span["text"].isdigit() and span["color"] == 255:
                            numbers.append(item)
                        else:
                            body.append(item)
        return {"pages": len(pdf), "numbers": numbers, "body": body}


def assert_outer(result):
    assert len(result["numbers"]) > 200, (
        "Vacuous check: expected hundreds of line numbers"
    )
    assert all(bbox[2] < 57.6 or bbox[0] > 554.4 for _, _, bbox in result["numbers"]), (
        "Number inside text/column gutter"
    )
    assert any(bbox[2] < 57.6 for _, _, bbox in result["numbers"])
    assert any(bbox[0] > 554.4 for _, _, bbox in result["numbers"])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--tex-bin", type=Path, required=True)
    parser.add_argument("--texinputs", required=True)
    parser.add_argument("--work-dir", type=Path, required=True)
    args = parser.parse_args()
    root = args.work_dir.resolve()
    root.mkdir(exist_ok=False, parents=True)
    env = os.environ.copy()
    env["PATH"] = str(args.tex_bin.resolve()) + os.pathsep + env.get("PATH", "")
    env.pop("TEXINPUTS", None)
    baseline = compile_doc(root / "baseline", env)
    assert any(250 < bbox[0] < 350 for _, _, bbox in baseline["numbers"]), (
        "Expected pinned 5.7 regression was not reproduced"
    )

    fixed_env = env | {"TEXINPUTS": args.texinputs}
    fixed = compile_doc(root / "fixed", fixed_env)
    assert_outer(fixed)
    assert [(p, text) for p, text, _ in fixed["body"]] == [
        (p, text) for p, text, _ in baseline["body"]
    ], "Fix changed body text or page placement"
    # Moving the number changes PDF text-state/kerning serialization by <0.01 pt.
    # Require matching text and allow only 0.02 pt in the extracted coordinates.
    assert all(
        abs(a - b) <= 0.02
        for fixed_span, old_span in zip(fixed["body"], baseline["body"])
        for a, b in zip(fixed_span[2], old_span[2])
    ), "Fix changed body layout"
    assert collections.Counter(
        (p, n) for p, n, _ in fixed["numbers"]
    ) == collections.Counter((p, n) for p, n, _ in baseline["numbers"])
    assert "v5.9" in (root / "fixed" / "test.log").read_text()

    repeat = compile_doc(root / "fixed", fixed_env)
    assert repeat == fixed, "Incremental rebuild changed placement/content"
    shutil.copytree(root / "baseline", root / "stale-aux")
    run(
        [
            "latexmk",
            "-g",
            "-pdf",
            "-interaction=nonstopmode",
            "-halt-on-error",
            "test.tex",
        ],
        root / "stale-aux",
        fixed_env,
    )
    stale = compile_doc(root / "stale-aux", fixed_env)
    assert stale == fixed, "Old auxiliary files were not corrected"

    final = compile_doc(root / "final", fixed_env, final=True)
    assert not final["numbers"], "Camera-ready mode contains line numbers"
    assert "Package: lineno" not in (root / "final" / "test.log").read_text()

    override = root / "project-local"
    override.mkdir()
    (override / "lineno.sty").write_text("% project-local lookup sentinel\n")
    chosen = run(["kpsewhich", "lineno.sty"], override, fixed_env).strip()
    assert (override / chosen).resolve() == (override / "lineno.sty").resolve(), (
        "Project-local packages lost precedence"
    )

    summary = {
        "status": "PASS",
        "baseline_gutter_numbers": sum(
            250 < bbox[0] < 350 for _, _, bbox in baseline["numbers"]
        ),
        "fixed_outer_numbers": len(fixed["numbers"]),
        "pages": fixed["pages"],
        "checks": [
            "known regression",
            "outer margins",
            "body geometry within 0.02 pt",
            "number sequence unchanged",
            "incremental repeat",
            "stale aux recovery",
            "unnumbered final",
            "project-local precedence",
        ],
    }
    (root / "RESULT.json").write_text(json.dumps(summary, indent=2) + "\n")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
