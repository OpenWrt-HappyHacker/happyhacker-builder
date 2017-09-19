#!/bin/sh

# OpenWrt HappyHacker patch:
#   This file has been modified to always allow remote login, no matter what.
#   Useful for debugging, but absolutely discouraged in production!

exec /bin/ash --login
