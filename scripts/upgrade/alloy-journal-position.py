#!/usr/bin/env python3
"""Convert a preserved fleet Promtail checkpoint COPY, never a live state file.

Alloy 1.16's built-in converter writes labels="{}" but its journal tailer looks
up labels="". This explicit one-time converter uses the tailer's actual key.
Requires PyYAML. Input must contain only the fleet's known journal job.
"""
import argparse
import json
import os
from pathlib import Path
import re
import stat
import tempfile

import yaml


class UniqueLoader(yaml.SafeLoader):
    def construct_mapping(self, node, deep=False):
        keys = [self.construct_object(k, deep=deep) for k, _ in node.value]
        if len(set(keys)) != len(keys):
            raise ValueError("duplicate checkpoint key")
        return super().construct_mapping(node, deep=deep)


def convert(source, destination):
    source, destination = Path(source), Path(destination)
    info = source.lstat()
    if not stat.S_ISREG(info.st_mode) or info.st_size > 1048576:
        raise ValueError("expected a small preserved regular checkpoint copy")
    data = yaml.load(source.read_text(), Loader=UniqueLoader)
    if not isinstance(data, dict) or set(data) != {"positions"}:
        raise ValueError("unknown checkpoint schema")
    positions = data["positions"]
    if not isinstance(positions, dict) or set(positions) != {"cursor-journal"}:
        raise ValueError("unknown job mapping (expected journal only)")
    cursor = positions["cursor-journal"]
    if not isinstance(cursor, str) or not re.fullmatch(r"s=[0-9a-f]+;i=[0-9a-f]+;b=[0-9a-f]+;m=[0-9a-f]+;t=[0-9a-f]+;x=[0-9a-f]+", cursor):
        raise ValueError("unknown journal cursor format")
    # The parent must already exist with its intended owner and permissions.
    # Hard-link publication is atomic and NOREPLACE, unlike os.rename.
    text = ('positions:\n  ? path: cursor-loki.source.journal.journal\n'
            '    labels: ""\n  : ' + json.dumps(cursor) + '\n')
    fd, temporary = tempfile.mkstemp(prefix=".positions-", dir=destination.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.link(temporary, destination, follow_symlinks=False)
        directory = os.open(destination.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        os.unlink(temporary)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("preserved_copy")
    parser.add_argument("new_checkpoint")
    args = parser.parse_args()
    try:
        convert(args.preserved_copy, args.new_checkpoint)
    except Exception:
        parser.exit(1, "Checkpoint conversion refused; inspect schema, permissions and destination existence.\n")
    print("Offline journal checkpoint conversion: PASS")
