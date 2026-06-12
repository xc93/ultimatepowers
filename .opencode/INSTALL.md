# Installing Ultimatepowers for OpenCode

## Install

Add ultimatepowers to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["ultimatepowers@git+https://github.com/xc-math/ultimatepowers.git"]
}
```

Restart OpenCode. The plugin injects the using-superpowers bootstrap at session
start and registers the bundled `skills/` directory automatically.
Verify by asking: "Tell me about your ultimatepowers"

To pin a version, append `#v1.0.0` to the git spec above.

## Manual / local install

Clone this repository anywhere, then symlink
`.opencode/plugins/ultimatepowers.js` into `~/.config/opencode/plugins/`.
Restart OpenCode and verify as above.

## Do not co-install with superpowers

Ultimatepowers bundles all superpowers skills. Installing both produces duplicate
session-start bootstraps and conflicting skill names. Remove superpowers first.
