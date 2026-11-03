# dev-image

Dev container image for AI coding agents, based on
[`mcr.microsoft.com/devcontainers/base:ubuntu-24.04`](https://github.com/devcontainers/images)
(same `vscode` user, uid 1000 — a home-directory PVC works unchanged).

Compared to the base image it adds:

- **Chromium/Chrome system libraries + fonts** — the set Playwright's
  `install-deps chromium` installs — so browsers downloaded at runtime
  (Chrome for Testing via [`agent-browser`](https://agent-browser.dev),
  Chromium via Playwright) can actually launch. Browser binaries themselves
  are *not* baked in; they live in `$HOME`.
- **[`mise`](https://mise.jdx.dev)** at `/usr/local/bin/mise`, with its shims on
  `PATH` — tools (node, go, kubectl, helm, flux2, …) are provisioned per-user
  from the mise config in `$HOME`, not baked into the image.

## Published images

`ghcr.io/mitchellhuang/dev-image` — pushed by GitHub Actions on every push to
`main` (`latest` + `sha-*`) and every `v*` tag (`0.1.0`, `0.1`, …).

To release a version: `git tag v0.2.0 && git push origin v0.2.0`.

## Using it

Devcontainer (`devcontainer.json`):

```json
{
  "image": "ghcr.io/mitchellhuang/dev-image:0.1.0",
  "remoteUser": "vscode"
}
```

Kubernetes pod:

```yaml
image: ghcr.io/mitchellhuang/dev-image:0.1.0
securityContext:
  runAsUser: 1000
```

If the GHCR package is private, either flip it to public (repo → Packages →
dev-image → Package settings → Change visibility) or add an
`imagePullSecrets` to the pod.

Inside a shell, zsh users should add once (lives on the PVC):

```sh
eval "$(mise activate zsh --shims)"
```

## Maintenance

- Bump `MISE_VERSION` in the `Dockerfile` to upgrade mise.
- Browser binaries update themselves at runtime (`agent-browser install`,
  `npx playwright install chromium`); the system libraries here rarely change.
  If a future Chromium needs a new library, add it to the `apt-get install`
  list and cut a new tag.

## CI

`build.yml` builds for `linux/amd64`, pushes to GHCR, then runs a smoke test
that downloads Chromium inside the image and renders a real screenshot of
`example.com` headlessly — the exact failure mode this image exists to fix.