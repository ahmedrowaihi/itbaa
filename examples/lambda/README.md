# itbaa on AWS Lambda

itbaa as a container-image Lambda. Each invocation renders the event's `html` to a
PDF/PNG/JPEG and returns it base64-encoded.

Two things the image must get right (both baked into the `Dockerfile`):

- **Container, not zip** — base `ubuntu:24.04` matches the binary's glibc (2.39); a `provided.al2023` runtime is glibc 2.34 and won't load it.
- **Fonts** — itbaa falls back to system fonts for missing glyphs but never the network, so non-Latin text needs the font installed (`fonts-noto-core` here for Arabic/RTL).

No Chromium: no `@sparticuz/chromium`, no browser to spin up — warm renders ~150 ms.

## Deploy

```bash
export AWS_PROFILE=your-profile
export AWS_REGION=us-east-1     # optional
./deploy.sh
```

Override `FUNCTION_NAME`, `ECR_REPO`, `ROLE_NAME`, `ARCH` (`arm64`|`x86_64`), `ITBAA_VERSION` via env.

## Invoke

```bash
aws lambda invoke --function-name itbaa-pdf-example \
  --payload fileb://event.json --cli-binary-format raw-in-base64-out \
  --region "$AWS_REGION" --profile "$AWS_PROFILE" out.json
jq -r '.body' out.json | base64 -d > out.pdf
```

## Tear down

```bash
./teardown.sh
```

| File | Purpose |
| --- | --- |
| `Dockerfile` | Ubuntu 24.04 + itbaa + `bootstrap` |
| `bootstrap` | runtime loop — renders each event |
| `event.json` | sample payload |
| `deploy.sh` / `teardown.sh` | create / remove all resources |
