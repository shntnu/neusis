"""Oppy machine sample test."""

# disable ruff to remove errors
# ruff: noqa

oppy.wait_for_unit("multi-user.target")

with subtest("Log in as ank on a virtual console"):
    oppy.wait_until_tty_matches("1", "login: ")
    oppy.send_chars("ank\n")
    oppy.wait_until_tty_matches("1", "login: ank")
    oppy.wait_until_succeeds("pgrep login")
    oppy.wait_until_tty_matches("1", "Password: ")
    oppy.send_chars("changeme\n")
    oppy.wait_until_succeeds("pgrep -u ank zsh")
    oppy.send_chars("touch done\n")
    oppy.wait_for_file("/home/ank/done")
