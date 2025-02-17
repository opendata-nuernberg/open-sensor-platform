export def clean [] {
    docker image prune -a
}

export def build [] {
    # run-external "docker" "compose" "-f" "dev_docker/docker-compose.yml" "build"
    cd dev_docker;docker compose build
}  

export def start [] {
    cd dev_docker; docker compose up -d --build
}

export def stop [] {
    cd dev_docker; docker compose down
}

export def shell [] {
    docker_start
    docker exec -i -t open-sensor-platform-development-1 /bin/bash
}