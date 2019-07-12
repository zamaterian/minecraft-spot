import logging

import docker

import spot_tools.logger

spot_tools.logger.setup_logging()
LOGGER = logging.getLogger(__name__)

def get_docker_client():
    if not get_docker_client._client:
        get_docker_client._client = docker.DockerClient(base_url='unix://var/run/docker.sock')
    return get_docker_client._client
get_docker_client._client = None

def get_docker_lowlevel_client():
    if not get_docker_lowlevel_client._client:
        get_docker_lowlevel_client._client = docker.APIClient(base_url='unix://var/run/docker.sock')
    return get_docker_lowlevel_client._client
get_docker_lowlevel_client._client = None
