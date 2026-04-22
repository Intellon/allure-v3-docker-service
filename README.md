# Allure Docker Service

[![Allure Docker Service Workflow](https://github.com/Intellon/allure-v3-docker-service/actions/workflows/docker-publish.yml/badge.svg?branch=main)](https://github.com/Intellon/allure-docker-service/actions?query=branch%3Amain)

Docker container for [Allure 3](https://github.com/allure-framework/allure3) test reporting. Automatically detects new test results and generates reports, or accepts results via REST API.

**Image:** `ghcr.io/intellon/allure-docker-service`

## Usage

### Docker Compose

```yaml
services:
  allure:
    image: "ghcr.io/intellon/allure-docker-service"
    environment:
      CHECK_RESULTS_EVERY_SECONDS: NONE
      KEEP_HISTORY: 1
      KEEP_HISTORY_LATEST: 12
      SECURITY_ENABLED: 0
    ports:
      - "7272:5050"
    volumes:
      - ./projects:/app/projects

  allure-ui:
    image: "ghcr.io/intellon/allure-docker-service-ui"
    environment:
      ALLURE_DOCKER_PUBLIC_API_URL: "http://localhost:7272"
    ports:
      - "7474:5252"
```

```sh
docker compose up -d
```

- **API:** http://localhost:7272/allure-docker-service/swagger
- **UI:** http://localhost:7474/allure-docker-service-ui
- **Latest Report:** http://localhost:7272/allure-docker-service/latest-report

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CHECK_RESULTS_EVERY_SECONDS` | `NONE` | Seconds between result checks. `NONE` = manual/API only |
| `KEEP_HISTORY` | `0` | Set to `1` to preserve report history and trends |
| `KEEP_HISTORY_LATEST` | `30` | Max history entries kept in trend + max archived report snapshots. Any positive integer accepted |
| `SECURITY_ENABLED` | `0` | Set to `1` to enable JWT authentication |
| `SECURITY_USER` | - | Admin username (required when security enabled) |
| `SECURITY_PASS` | - | Admin password (required when security enabled) |
| `SECURITY_VIEWER_USER` | - | Viewer username (optional) |
| `SECURITY_VIEWER_PASS` | - | Viewer password (optional) |
| `MAKE_VIEWER_ENDPOINTS_PUBLIC` | `0` | Set to `1` to allow public access to viewer endpoints |
| `DEV_MODE` | `0` | Set to `1` for Flask debug mode |
| `TLS` | `0` | Set to `1` to enable HTTPS |
| `URL_PREFIX` | - | API URL prefix (e.g., `/my-prefix`) |
| `OPTIMIZE_STORAGE` | `0` | Set to `1` to use symlinks for shared report assets |
| `API_RESPONSE_LESS_VERBOSE` | `0` | Set to `1` to reduce API response verbosity |

### Volumes

| Container Path | Purpose |
|----------------|---------|
| `/app/allure-results` | Mount your test results here (single project) |
| `/app/default-reports` | Generated reports output |
| `/app/projects` | Mount here for multi-project setup |

## Local Development

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/)
- Git

### Start backend + UI via Docker Compose
```sh
docker compose -f docker-compose-dev.yml up -d --build
```
- **Allure Backend:** http://localhost:7272
- **Allure UI:** http://localhost:7474/allure-docker-service-ui

```sh
# View logs
docker compose -f docker-compose-dev.yml logs -f

# Stop
docker compose -f docker-compose-dev.yml down
```

The dev compose file builds the image from `docker/Dockerfile` using `ALLURE_RELEASE=3.3.1`, so local changes under `allure-docker-api/` and `allure-docker-scripts/` are picked up on `--build`.

## Local Docker Build & Test

Build and run only locally (without pushing to any registry):
```sh
# Build
docker build -t allure-docker-service \
  -f docker/Dockerfile \
  --build-arg ALLURE_RELEASE=3.3.1 .

# Run
docker run -d --name allure -p 7272:5050 \
  -e CHECK_RESULTS_EVERY_SECONDS=3 \
  -e KEEP_HISTORY=1 \
  -v "$(pwd)/allure-results:/app/allure-results" \
  allure-docker-service

# Test
curl http://localhost:7272/allure-docker-service/version
```
Open http://localhost:7272/allure-docker-service/swagger

Stop:
```sh
docker rm -f allure
```

## API

### Info Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/allure-docker-service/version` | Allure version |
| GET | `/allure-docker-service/config` | Service configuration |
| GET | `/allure-docker-service/swagger` | Swagger UI |

### Action Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/allure-docker-service/send-results` | Upload test results |
| GET | `/allure-docker-service/generate-report` | Generate report |
| GET | `/allure-docker-service/latest-report` | Redirect to latest report |
| GET | `/allure-docker-service/clean-results` | Clean results directory |
| GET | `/allure-docker-service/clean-history` | Clean history |
| GET | `/allure-docker-service/emailable-report/render` | Render emailable report |
| GET | `/allure-docker-service/emailable-report/export` | Export emailable report |
| GET | `/allure-docker-service/report/export` | Export full report as ZIP |

### Project Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/allure-docker-service/projects` | Create project |
| GET | `/allure-docker-service/projects` | List all projects |
| GET | `/allure-docker-service/projects/{id}` | Get project details |
| DELETE | `/allure-docker-service/projects/{id}` | Delete project |
| GET | `/allure-docker-service/projects/search?id={query}` | Search projects |

### Send Results via API

**Multipart upload:**
```sh
curl -X POST http://localhost:7272/allure-docker-service/send-results \
  -H 'Content-Type: multipart/form-data' \
  -F 'files[]=@allure-results/result1.json' \
  -F 'files[]=@allure-results/result2.json'
```

**JSON (base64):**
```sh
curl -X POST http://localhost:7272/allure-docker-service/send-results \
  -H 'Content-Type: application/json' \
  -d '{
    "results": [{
      "file_name": "result.json",
      "content_base64": "'$(base64 -w 0 allure-results/result.json)'"
    }]
  }'
```

**Generate report after upload:**
```sh
curl http://localhost:7272/allure-docker-service/generate-report
```

## Security

Enable JWT authentication:

```sh
docker run -d --name allure -p 7272:5050 \
  -e SECURITY_ENABLED=1 \
  -e SECURITY_USER=admin \
  -e SECURITY_PASS=secret \
  allure-docker-service
```

**Login:**
```sh
curl -X POST http://localhost:7272/allure-docker-service/login \
  -H 'Content-Type: application/json' \
  -d '{"username": "admin", "password": "secret"}' \
  -c cookies.txt
```

**Use authenticated endpoint:**
```sh
curl http://localhost:7272/allure-docker-service/generate-report -b cookies.txt
```

**Roles:** `admin` has full access, `viewer` has read-only access.

## Build & Push to GHCR

### CI/CD
The pipeline runs automatically on version tags and can be triggered manually. It builds multi-arch (amd64, arm64) and pushes to `ghcr.io/intellon/allure-docker-service`.

**Automatic** — push a version tag:
```sh
git tag v3.3.1
git push origin v3.3.1
```

**Manual** — trigger via GitHub UI:
Go to **Actions > Allure Docker Service Workflow > Run workflow**, enter the version (e.g. `3.3.1`) and choose whether to tag as `latest`.

**Prerequisite:** Enable **Settings > Actions > General > Workflow permissions > Read and write permissions** in your GitHub repository.

### Manual

```sh
# 1. Login
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# 2. Build
docker build -t ghcr.io/intellon/allure-docker-service:3.3.1 \
  -f docker/Dockerfile \
  --build-arg ALLURE_RELEASE=3.3.1 \
  --build-arg BUILD_VERSION=3.3.1 \
  --build-arg BUILD_REF=$(git rev-parse --short HEAD) \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') .

docker tag ghcr.io/intellon/allure-docker-service:3.3.1 ghcr.io/intellon/allure-docker-service:latest

# 3. Push
docker push ghcr.io/intellon/allure-docker-service:3.3.1
docker push ghcr.io/intellon/allure-docker-service:latest
```

**Multi-architecture build:**
```sh
docker buildx create --name multiarch --use
docker buildx build --no-cache \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/intellon/allure-docker-service:3.3.1 \
  -t ghcr.io/intellon/allure-docker-service:latest \
  -f docker/Dockerfile \
  --build-arg ALLURE_RELEASE=3.3.1 \
  --push .
```

**GitHub Token:** Settings > Developer Settings > Personal Access Tokens (classic) with scopes `write:packages`, `read:packages`.

## License

MIT - see [LICENSE](LICENSE)
