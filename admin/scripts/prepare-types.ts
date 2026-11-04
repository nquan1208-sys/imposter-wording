import { readdir } from 'node:fs/promises'
import { createServer } from 'vite'

const server = await createServer({ mode: 'localdev', server: { middlewareMode: true, hmr: false, ws: false } })
try {
  // The component plugin discovers Nuxt UI types while transforming templates.
  // Merely resolving Vite config only generates declarations for local components.
  for (const directory of ['src', 'tests/fixtures']) {
    const files = await readdir(directory, { recursive: true })
    for (const file of files.filter(file => file.endsWith('.vue'))) {
      await server.transformRequest(`/${directory}/${file}`, { ssr: true })
    }
  }
} finally {
  await server.close()
}
