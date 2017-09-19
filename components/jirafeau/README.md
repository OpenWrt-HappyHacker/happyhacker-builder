This component enables a secure drop box using a customized version of the Jirafeau web application.
It also configures the uhttpd daemon to listen on localhost:443 on SSL and creates the SSL certificates.
The idea is to only access it through tor, so the server only listens on localhost - not on the local network.
