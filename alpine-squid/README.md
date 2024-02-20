<!-- vale off -->
# Docker Alpine Squid
<!-- vale on -->

[![Software License](https://img.shields.io/badge/license-MIT-informational.svg?style=flat)](LICENSE)
[![Pipeline Status](https://gitlab.com/op_so/docker/alpine-squid/badges/main/pipeline.svg)](https://gitlab.com/op_so/docker/alpine-squid/pipelines)

A [Squid](http://www.squid-cache.org/) Docker image:

* **lightweight** image based on Alpine Linux only 8 MB,
* `multiarch` with support of **amd64** and **arm64**,
* **non-root** container user,
* available on **Docker Hub**.

[![GitLab](https://shields.io/badge/Gitlab-informational?logo=gitlab&style=flat-square)](https://gitlab.com/op_so/docker/alpine-squid) The main repository.

[![Docker Hub](https://shields.io/badge/dockerhub-informational?logo=docker&logoColor=white&style=flat-square)](https://hub.docker.com/r/gpjavierjob/alpine-squid) The Docker Hub registry.

## Running the `Squid` proxy

```shell
docker run -d --rm --name squid -p 3128:3128 gpjavierjob/alpine-squid
```

The configuration of Squid is the default one, with some additions:

`/etc/squid/squid.conf`

```shell
# Include a folder of config files
include /etc/squid/conf.d/*.conf
```

`/etc/squid/conf.d/squid-docker.conf`

```shell
# Specific configuration for Docker usage
pid_filename none
logfile_rotate 0
access_log stdio:/dev/stdout
cache_log stdio:/dev/stderr
```

## License

<!-- vale off -->
This program is free software: you can redistribute it and/or modify it under the terms of the MIT License (MIT). See the [LICENSE](https://opensource.org/licenses/MIT) for details.
<!-- vale on -->
