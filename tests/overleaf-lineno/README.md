# Overleaf line-number placement regression

Oppy's pinned TeX Live contains `lineno` 5.7. With the shipped LaTeX kernel,
its `build/column/before` hook records the wrong column in the auxiliary file.
In two-column documents, review line numbers appear in the center gutter or
on top of text. The upstream 5.9 release fixes the hook and its write placement.

`machines/oppy/overleaf-lineno.nix` pins the official 5.9 source by commit and
SHA-256. `machines/oppy/overleaf.nix` adds it to **CLSI only**, through
`TEXINPUTS=.:<package>/share/texmf/tex/latex//:`. Project-local packages keep
precedence, and the final empty path element preserves all normal TeX searches.
The rest of Overleaf's compiler/runtime package set is unchanged. No conference
style or manuscript TeX patch is needed. Final/camera-ready documents that do
not load `lineno` remain unnumbered.

## Test

Use the TeX binary directory from the live `overleaf-clsi.service` PATH and a
Python environment with PyMuPDF:

```sh
texinputs=$(nix eval --raw .#nixosConfigurations.oppy.config.systemd.services.overleaf-clsi.environment.TEXINPUTS)
python tests/overleaf-lineno/check.py \
  --tex-bin /nix/store/<live-texlive-env>/bin \
  --texinputs "$texinputs" \
  --work-dir /path/to/new-test-directory
```

The package referenced by `texinputs` must have been built first. The check
intentionally reproduces the known pinned 5.7 failure, then tests fixed outer
margins, unchanged text/number sequence, body geometry within 0.02 PDF points,
incremental builds, recovery from old auxiliary files, unnumbered final mode,
and precedence of a project-local package. It fails if no line numbers are
found. Builds and failure evidence are retained.

## Deployment

The declarative module provides persistence on future NixOS rebuilds. Do not
run a broad system switch merely to deploy this fix on a shared compute host.
An administrator can deploy the exact evaluated `TEXINPUTS` as a persistent
CLSI systemd drop-in, GC-root the pinned package, reload systemd and restart
**only** `overleaf-clsi.service` during an agreed idle compile window. On NixOS,
`/etc/systemd/system` points into the immutable store. The live override is
`/etc/systemd/system.control/overleaf-clsi.service.d/50-lineno.conf`, in systemd's
supported persistent higher-priority search directory. Keep it until a normal
NixOS deployment includes the matching declarative setting; only then remove
the override after verifying that the generated unit resolves the same package. Do not
restart other Overleaf services or any compute jobs. Do not overwrite an
existing different TEXINPUTS override without inspecting it.

After activation, confirm the live service environment and package lookup as
the `overleaf` user. Recompile the affected project from scratch once using the
authenticated UI. Check `output.log` for `lineno` 5.9, the PDF's line-number
coordinates and valid output responses; obtain user confirmation of the editor
pane. Command-line tests do not prove that the browser has refreshed its PDF.

On 2026-10-28, local tests passed with 376 outer numbers across four generic
pages and 1,299 outer numbers across the actual 33-page working JUMP-lite review
PDF. Its 32-page camera-ready root contained no line numbers. The Nix expression
evaluated successfully. The owner-authorized root terminal activated the fix
at 17:51 UTC on October 28. The live CLSI service then compiled an unchanged
WACV fixture with lineno 5.9: all 352 numbers were in outer margins, PDF/log
fetches returned HTTP 200, byte-range fetch returned 206, and QPDF passed.
Only the CLSI PID changed; production-job and other Overleaf service PIDs did
not. The open user's editor still requires a fresh compile and visual
confirmation; the direct CLSI test is not proof of that browser handoff.
