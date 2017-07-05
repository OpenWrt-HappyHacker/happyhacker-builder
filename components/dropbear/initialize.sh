#!/bin/bash
set -e

# Create a new SSH keypair.
/OUTSIDE/script/guest/create_ssh_keys.sh

# Create a Tor hidden service for the SSH server.
/OUTSIDE/script/guest/create_hidden_service.sh SSHtor 22
