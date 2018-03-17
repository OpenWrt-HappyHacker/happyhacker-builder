This component enables OpenVPN to proxy network traffic through the device.
It configures the daemon to listen on localhost:1194 and creates the SSL certificates and .opvn client configuration file.
The idea is to only access it through tor, so the server only listens on localhost - not on the local network.
