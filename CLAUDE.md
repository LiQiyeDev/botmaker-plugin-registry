# CLAUDE.md

Guidance for working in **botmaker-plugin-registry**, the index of BotMaker plugins.

This is a **data repository**, like `botmaker-gallery`: no pom, not in the umbrella's reactor, nothing here
is compiled. Read the umbrella `../CLAUDE.md` and `../botmaker-cli/CLAUDE.md` — the gate's code lives there.

## The one structural fact: the entries are the source of truth, the index is derived

`plugins/<plugin-id>.json` is written by a human (well, by `botmaker publish`); `index.json` is written by
`.github/workflows/index.yml` and by nothing else. Two properties follow, and both were bought deliberately
from a single-array layout that did not have them:

- **Two submissions never conflict.** Two authors adding two plugins touch two files.
- **Id uniqueness is git's.** A second `plugins/com.example.discord.json` cannot exist, so the `id` check's
  "already claimed" arm is a property of the layout rather than of a check that could be forgotten. Value
  type ids are *not* filenames, so those still need the scan — that is `Registry.claimedValueTypeIds`.

`index.json` must stay at exactly its current path. Studio reads it from
`raw.githubusercontent.com/LiQiyeDev/botmaker-plugin-registry/main/index.json`, and a shipped Studio has that
URL compiled into it.

## The gate is not in this repository, and that is not an oversight

`validate.yml` resolves `com.github.LiQiyeDev:botmaker-cli`'s **main** artifact — the library, with no
picocli in it — and calls `com.botmaker.cli.registry.RegistryGate`. The rule from `botmaker-cli/CLAUDE.md`
applies from this side too: **a rule added here is a rule the plugin's author cannot run**, and a submission
that fails for a reason its author could not have seen coming is the experience the gate exists to prevent.
A new check belongs in `PluginValidator`, as a `Check`.

What this repository legitimately owns is the three facts only it holds — the ids every other entry claims,
**which host's bundled plugins these ids are reserved for**, and that `index.json` is generated — and all
three are passed to the gate rather than reimplemented.

**The bundled set is `BOTMAKER_BUNDLED_PLUGINS`, and it is coordinates, not ids.** A plugin the host itself
ships has no entry file here, so nothing claimed `com.botmaker.sdk` or the SDK's seventeen value type ids
until this existed. The gate resolves the coordinates and asks the plugins; a list of ids in this repository
would be a second answer to a question the SDK already answers, and would drift the first time a type was
added. **Both the SDK and the toolkit are named** because the SDK declares the toolkit `optional` — not
transitive — and `SdkPlugin` extends the toolkit's `AbstractStudioPlugin`, so resolving the SDK alone yields
a classpath its own plugin cannot be constructed from. The gate puts them on one classpath, which is what a
host has.

**The CLI version and the bundled coordinates are pinned** (`BOTMAKER_CLI_VERSION`,
`BOTMAKER_BUNDLED_PLUGINS` in `validate.yml`), not floating. A verdict must not change under a pull request
that is already open; bump either in a pull request of its own.

## Changed paths never reach a shell

A pull request chooses its own filenames, so a path is attacker-controlled text. `validate.yml` writes
`git diff --name-only` to `target/changed.txt` and the gate reads that file (its `@file` argument form).
Interpolating a path into a `run:` line is a command injection; it is also simply broken for a filename
containing a space.

## What this repository never claims

A plugin runs arbitrary code inside Studio's process. Every check asks whether a plugin **works**. Nothing
here is a safety review, and the README says so in its first three lines — keep it that way, and do not add a
badge or a word that implies otherwise.
