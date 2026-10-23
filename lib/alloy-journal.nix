# Shared by the live configuration and the journal ingestion regression test.
{
  lib,
  hostName,
  lokiPort,
  journalPath ? null,
  # Regression-only: Alloy 1.16's legacy import uses the wrong labels key.
  # Production cutovers use scripts/upgrade/alloy-journal-position.py instead.
  legacyPosition ? null,
}:
''
  loki.relabel "journal" {
    forward_to = []
    rule {
      source_labels = ["__journal__systemd_unit"]
      target_label = "unit"
    }
  }

  loki.source.journal "journal" {
    ${lib.optionalString (journalPath != null) "path = ${builtins.toJSON journalPath}"}
    ${lib.optionalString (legacyPosition != null) ''
      legacy_position {
        file = ${builtins.toJSON legacyPosition.file}
        name = ${builtins.toJSON legacyPosition.name}
      }
    ''}
    max_age = "12h"
    labels = {
      job = "systemd-journal",
      host = ${builtins.toJSON hostName},
    }
    relabel_rules = loki.relabel.journal.rules
    forward_to = [loki.write.local.receiver]
  }

  loki.write "local" {
    endpoint {
      url = "http://127.0.0.1:${toString lokiPort}/loki/api/v1/push"
    }
  }
''
