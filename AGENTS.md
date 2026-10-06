# Working on this repo

- Tests: `for t in test/*_test.sh; do bash "$t"; done` (each prints PASS).
- Syntax check scripts: `bash -n *.sh`.
- Never let a test reach a real agent from `run-sweep.sh`; it opens PRs. Use stub
  agents on PATH with `HOME` redirected, as `test/sweep_test.sh` does.
- After changing `install.sh`, verify Devin with `devin rules list` (both
  `engineering-persona-*` rules `always-on`) and `devin skills list`. Check the
  push gate too: `/hooks` should list `require-pre-flight-review.sh`, and
  `~/.config/devin/` should hold `standards`, `domains` and `persona` symlinks.
  Without those the skills resolve `../../standards` inside the agent home and
  review against nothing while reporting success.
- Keep the `trigger: always_on` front matter on `persona/beliefs.md` and
  `persona/voice.md`; Devin loads them as manual rules without it.
