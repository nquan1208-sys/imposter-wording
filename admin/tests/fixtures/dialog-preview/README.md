# Delete dialog preview

Preview the real delete dialogs using local sample data. No API calls or data deletion are performed.

Start the admin dev server with `yarn --cwd admin dev:local`, then open:

- `/tests/fixtures/dialog-preview/index.html` — category dialog
- `/tests/fixtures/dialog-preview/index.html?word` — word dialog
- `/tests/fixtures/dialog-preview/index.html?mobile` — category dialog in a 390px viewport
- `/tests/fixtures/dialog-preview/index.html?word&mobile` — word dialog in a 390px viewport

The preview is a test fixture and is not included in the production entry point.
