[![](resources/allure.png)](https://allurereport.org/)
[![](resources/docker.png)](https://docs.docker.com/)

# Allure Docker Service

[![Allure Docker Service Workflow](https://github.com/Intellon/allure-docker-service/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/Intellon/allure-docker-service/actions)

Docker container for [Allure 3](https://github.com/allure-framework/allure3) test reporting. Automatically detects new test results and generates reports, or accepts results via REST API.

## Quick Start

### Build and run locally

```sh
git clone https://github.com/Intellon/allure-docker-service.git
cd allure-docker-service
docker build -f docker/Dockerfile -t allure-docker-service --build-arg ALLURE_RELEASE=3.3.1 .
docker run -d --name allure -p 7272:5050 \
  -e CHECK_RESULTS_EVERY_SECONDS=3 \
  -e KEEP_HISTORY=1 \
  -v ${PWD}/allure-results:/app/allure-results \
  allure-docker-service
```

### Or use Docker Compose

```sh
docker compose -f docker-compose-dev.yml up --build
```

### Open in browser

| Endpoint | URL |
|----------|-----|
| API Version | http://localhost:7272/allure-docker-service/version |
| Swagger UI | http://localhost:7272/allure-docker-service/swagger |
| Latest Report | http://localhost:7272/allure-docker-service/latest-report |

### Stop

```sh
docker stop allure && docker rm allure
```

---

## Container Registry

- Image: `ghcr.io/intellon/allure-docker-service`
- Architectures: amd64, arm64

```sh
docker pull ghcr.io/intellon/allure-docker-service:latest
docker run -d -p 7272:5050 ghcr.io/intellon/allure-docker-service:latest
```

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CHECK_RESULTS_EVERY_SECONDS` | `NONE` | Seconds between result checks. `NONE` = manual/API only |
| `KEEP_HISTORY` | `0` | Set to `1` to preserve report history and trends |
| `KEEP_HISTORY_LATEST` | `20` | Number of historical reports to keep |
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
|---------------|---------|
| `/app/allure-results` | Mount your test results here (single project) |
| `/app/default-reports` | Generated reports output |
| `/app/projects` | Mount here for multi-project setup |

---

## Usage

### Single Project

Mount your `allure-results` directory and the service auto-generates reports:

```sh
docker run -d --name allure -p 7272:5050 \
  -e CHECK_RESULTS_EVERY_SECONDS=3 \
  -e KEEP_HISTORY=1 \
  -v ${PWD}/allure-results:/app/allure-results \
  -v ${PWD}/allure-reports:/app/default-reports \
  allure-docker-service
```

### Multiple Projects

For multiple projects, use `CHECK_RESULTS_EVERY_SECONDS=NONE` and manage via API:

```sh
docker run -d --name allure -p 7272:5050 \
  -e CHECK_RESULTS_EVERY_SECONDS=NONE \
  -e KEEP_HISTORY=1 \
  -v ${PWD}/projects:/app/projects \
  allure-docker-service
```

Create a project:
```sh
curl -X POST http://localhost:7272/allure-docker-service/projects \
  -H 'Content-Type: application/json' \
  -d '{"id": "my-project"}'
```

### Docker Compose

```yaml
services:
  allure:
    image: "ghcr.io/intellon/allure-docker-service"
    environment:
      CHECK_RESULTS_EVERY_SECONDS: 3
      KEEP_HISTORY: 1
    ports:
      - "7272:5050"
    volumes:
      - ./allure-results:/app/allure-results
      - ./allure-reports:/app/default-reports
```

---

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

---

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

---

## Development

### Build image
```sh
docker build -f docker/Dockerfile -t allure-docker-service --build-arg ALLURE_RELEASE=3.3.1 .
```

### Run container
```sh
docker run -d --name allure -p 7272:5050 allure-docker-service
```

### Develop with Docker Compose
```sh
docker compose -f docker-compose-dev.yml up --build
```

### Access container
```sh
docker exec -it allure bash
```

### View logs
```sh
docker logs -f allure
```

### Security scan
```sh
docker scout cves allure-docker-service
```

---

## Manual Push to GHCR

### 1. Login
```sh
echo "${GITHUB_TOKEN}" | docker login ghcr.io -u ${GITHUB_USERNAME} --password-stdin
```
Create a PAT at https://github.com/settings/tokens with `write:packages` scope.

### 2. Build and tag
```sh
docker build --no-cache \
  -t ghcr.io/intellon/allure-docker-service:3.3.1 \
  -f docker/Dockerfile \
  --build-arg ALLURE_RELEASE=3.3.1 \
  --build-arg BUILD_VERSION=3.3.1 \
  .
docker tag ghcr.io/intellon/allure-docker-service:3.3.1 ghcr.io/intellon/allure-docker-service:latest
```

### 3. Push
```sh
docker push ghcr.io/intellon/allure-docker-service:3.3.1
docker push ghcr.io/intellon/allure-docker-service:latest
```

### 4. Multi-architecture build
```sh
docker buildx create --name multiarch --use
docker buildx build --no-cache \
  --platform linux/amd64,linux/arm64 \
  -t ghcr.io/intellon/allure-docker-service:3.3.1 \
  -t ghcr.io/intellon/allure-docker-service:latest \
  -f docker/Dockerfile \
  --build-arg ALLURE_RELEASE=3.3.1 \
  --push \
  .
```

### 5. Logout
```sh
docker logout ghcr.io
```

---

## CI/CD

The pipeline runs only on the `main` branch. Two ways to publish:

### Automatic (via Git tag)
```sh
git tag v3.3.1
git push origin v3.3.1
```

### Manual (via GitHub UI)
1. Go to `Actions > Allure Docker Service Workflow > Run workflow`
2. Enter the version (e.g. `3.3.1`)
3. Check "Tag as latest?" if desired
4. Click "Run workflow"

**Prerequisite:** Enable `Settings > Actions > General > Workflow permissions > Read and write permissions` in your GitHub repository.

---

## License

MIT - see [LICENSE](LICENSE)
