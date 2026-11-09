# Dev server keeps a copy of the server bundle per SSR request when expo-updates is imported

This is `npx create-expo-app@latest` (SDK 58, default template, `web.output: "server"`) with two changes:

1. `npx expo install expo-updates`
2. `src/app/_layout.tsx` imports it: `import * as Updates from 'expo-updates';`

## Reproduce

```sh
npm install
./scripts/measure-leak.sh
```

With the import, the heap grows by about 120 MB per server-rendered request and never comes back after GC. Remove the
two import lines from `src/app/_layout.tsx` and run it again: the heap stays flat.
