FROM node:22.14-bookworm AS build

WORKDIR /app

# Install dependencies first (better caching)
COPY package.json package-lock.json ./
RUN npm ci

# Copy source
COPY . .

# Install Go (required for Hugo modules)
RUN curl -O -L https://go.dev/dl/go1.24.6.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.24.6.linux-amd64.tar.gz && \
    rm go1.24.6.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:$PATH"

# Install Hugo Extended (needed for SCSS)
RUN curl -O -L https://github.com/gohugoio/hugo/releases/download/v0.152.2/hugo_extended_0.152.2_linux-amd64.tar.gz && \
    tar -xzf hugo_extended_0.152.2_linux-amd64.tar.gz && \
    mv hugo /usr/local/bin/ && \
    rm hugo_extended_0.152.2_linux-amd64.tar.gz

# Download pre-built Rós Madair indexer binary from release
ARG ROS_MADAIR_VERSION=v0.1.0-alpha.14
RUN curl -fsSL "https://github.com/flaxandteal/ros-madair/releases/download/${ROS_MADAIR_VERSION}/ros-madair-build-linux-amd64" \
      -o /usr/local/bin/ros-madair-build && \
    chmod +x /usr/local/bin/ros-madair-build

# Heap ceiling kept at 4096 MiB deliberately. The CI runner nodes
# (Catalyst Cloud c1.c4r8: 8 GB total RAM) cannot sustain an 8 GB V8
# heap alongside dind + buildkit + containerd; raising it will cause
# node-level OOM, not a clean "out of heap" failure.
RUN (for DATA_FILE in $(cd prebuild/business_data; ls -1 t_*.json); do ALIZARIN_BACKEND=napi npx --node-options=--max-old-space-size=4096 starches-builder etl --file ./prebuild/business_data/$DATA_FILE --prefix cat- --summary --include-private; done)

RUN cp -R prebuild/reference_data/controlled_lists prebuild/reference_data/collections
RUN ALIZARIN_BACKEND=napi npx starches-builder index --site docs --include-private

# Build Rós Madair index from the definitions output (separate step to
# avoid OOM when ros-madair-build runs alongside the Node.js heap).
RUN RDF_BASE_URI=$(node -e "const fs=require('fs'); const m=fs.readFileSync('hugo.yaml','utf8').match(/rdf_base_uri:\s*[\"']?([^\"'\n]+)/); console.log(m?m[1].trim():'https://example.org/')") && \
    npx starches-builder build-ros-madair --prebuild-dir docs/definitions --output docs/definitions/ros-madair --bin ros-madair-build --base-uri "${RDF_BASE_URI}"

RUN npm run precompile:templates

ARG DEFAULT_SHOW_FULL_ASSET=true
RUN sed -i "s/default_show_full_asset: .*/default_show_full_asset: \"${DEFAULT_SHOW_FULL_ASSET}\"/" hugo.yaml

ARG LINZ_API_KEY=""
RUN sed -i "s/linz_api_key: .*/linz_api_key: \"${LINZ_API_KEY}\"/" hugo.yaml

RUN hugo mod get && hugo

# Generate base64 .txt sidecars for all pagefind binary files.
# Enterprise proxies (Zscaler) block gzip-compressed binaries;
# the fetch interceptor in pagefind.ts falls back to these.
RUN npm run pagefind:fallback

# ---- SERVE WITH NGINX ----
FROM nginxinc/nginx-unprivileged:1.29-alpine
WORKDIR /usr/share/nginx/html
USER root
COPY --from=build /app/docs .
USER 33
EXPOSE 8080
