ARG DOCKER_REGISTRY_URL

FROM ${DOCKER_REGISTRY_URL}/dotnet/sdk:8.0 AS build-env

WORKDIR /src
ARG VERSION=1.0
ARG NUGET_SOURCE_URL
ARG ARTIFACTORY_USERNAME
ARG CACHE_BUST=1

RUN dotnet nuget disable source "nuget.org"
RUN --mount=type=secret,id=ARTIFACTORY_PASSWORD,env=ARTIFACTORY_PASSWORD dotnet nuget add source ${NUGET_SOURCE_URL} --store-password-in-clear-text --name "Artifactory" --username ${ARTIFACTORY_USERNAME} --password ${ARTIFACTORY_PASSWORD}

# Cache bust to ensure fresh copy of source code
RUN echo "Cache bust: ${CACHE_BUST}" && date

# Copy everything
COPY . .
# Restore as distinct layers
RUN dotnet restore -r linux-musl-x64

# RUN dotnet test -r linux-musl-x64 --collect:"XPlat Code Coverage"
# Build and publish a release
RUN dotnet publish -o /app -p Version=${VERSION} -c Release -r linux-musl-x64

# Build runtime image
FROM ${DOCKER_REGISTRY_URL}/dotnet/aspnet:8.0-alpin
EXPOSE 8080
# Install CA certificates

RUN apk update && apk add --no-cache ca-certificates
COPY ./ca-certificates.crt /etc/ssl/certs/pwc-certificates.crt
RUN cat /etc/ssl/certs/pwc-certificates.crt >> /etc/ssl/certs/ca-certificates.crt \
    && update-ca-certificates

RUN adduser -D -u 10001 trex \
    && mkdir /app \
    && chown -R trex:trex /app \
    && mkdir /app/logs \
    && chown trex:trex /app/logs

USER trex
WORKDIR /app
COPY --chown=trex:trex --from=build-env /app .
ENTRYPOINT [ "dotnet", "FabricManagement.dll", "--urls", "http://0.0.0.0:8080" ]
# ENTRYPOINT ["dotnet", "GDS.Fabric.ManagementService.Api.dll", "--urls", "http://0.0.0.0:8080"] 
