#!/bin/bash

# This script creates a new SSL/TLS certificate signed by a root certificate that is common to all builds.
# That way we can have a different certificate for each .onion domain, but at the same time a single root
# certificate for all to be installed on the client side, simplifying deployment. (For anything other than
# a browser, though, certificate pinning is highly recommended instead of relying on this!)

# Check the command line arguments.
if (( $# < 2 ))
then
    >&2 echo "Error: not enough arguments provided"
    exit 1
fi
if (( $# > 3 ))
then
    >&2 echo "Error: too many arguments provided"
    exit 1
fi

# Load the build configuration variables.
source /OUTSIDE/script/config.sh

# Paths to the global root certificate files, if present.
CA_GLOBAL_KEY="/OUTSIDE/script/data/ca.key"
CA_GLOBAL_CERT="/OUTSIDE/script/data/ca.crt"

# Paths to the per-profile root certificate files.
# If for some reason we don't have a profile set, use the global one.
if [ -z "${PROFILE_DIR}" ]
then
    >&2 echo "Warning: no profile set, using global CA settings"
    CA_KEY="${CA_GLOBAL_KEY}"
    CA_CERT="${CA_GLOBAL_CERT}"
else
    CA_KEY="${PROFILE_DIR}/ca.key"
    CA_CERT="${PROFILE_DIR}/ca.crt"
fi

# Switch to the output directory, so we can use relative paths.
pushd "$2" >/dev/null

# If there is a profile root cert, use it.
if [ -e "${CA_CERT}" ]
then
    echo "Root certificate found at: ${CA_CERT}"
else

    # If there is no profile root cert but there is a global cert, use it.
    if [ -e "${CA_GLOBAL_CERT}" ]
    then
        echo "Global root certificate found at: ${CA_GLOBAL_CERT}"
        cp -- "${CA_GLOBAL_KEY}" "${CA_KEY}"
        cp -- "${CA_GLOBAL_CERT}" "${CA_CERT}"
        echo "Copied to the profile directory: ${CA_CERT}"
    else

        # If there is no global cert either, create a new per-profile cert.
        echo "Root certificate not found, generating a new one..."
        openssl genrsa -out "${CA_KEY}" ${SSL_KEY_SIZE} >/dev/null 2>&1
        openssl req -new -x509 -utf8 -days ${CA_CERT_DAYS} -key "${CA_KEY}" -out "${CA_CERT}" >/dev/null 2>&1 <<EOF
${CA_CERT_COUNTRY}
${CA_CERT_STATE}
${CA_CERT_CITY}
${CA_CERT_COMPANY}
${CA_CERT_UNIT}
${CA_CERT_DN}
${CA_CERT_EMAIL}
EOF
        chmod 444 "${CA_CERT}"
        chmod 400 "${CA_KEY}"
        echo "New root key created at: ${CA_KEY}"
        echo "New root certificate created at: ${CA_CERT}"
        #openssl x509 -in "${CA_CERT}" -text -noout
    fi
fi

# Generate the key for the new certificate.
echo "Generating new SSL certificate..."
SSL_PASS="$(makepasswd)"
if (( $# > 2 ))
then
    SSL_CERT=$3
else
    SSL_CERT=$1
fi
openssl genrsa -out "${SSL_CERT}.key" ${SSL_KEY_SIZE} >/dev/null 2>&1
openssl req -new -utf8 -key "${SSL_CERT}.key" -out "${SSL_CERT}.csr" >/dev/null 2>&1 <<EOF
${CA_CERT_COUNTRY}
${CA_CERT_STATE}
${CA_CERT_CITY}
${CA_CERT_COMPANY}
${CA_CERT_UNIT}
$1
${CA_CERT_EMAIL}
${SSL_PASS}
${CA_CERT_EMAIL}
EOF
openssl x509 -req -days ${SSL_CERT_DAYS} -in "${SSL_CERT}.csr" -CA "${CA_CERT}" -CAkey "${CA_KEY}" -set_serial 01 -out "${SSL_CERT}.crt" >/dev/null 2>&1
openssl pkcs12 -export -out "${SSL_CERT}.p12" -inkey "${SSL_CERT}.key" -in "${SSL_CERT}.crt" -chain -CAfile "${CA_CERT}" >/dev/null 2>&1 < $(echo "${SSL_PASS}")
echo "New SSL certificate created for domain: $1"

# Go back to the original current directory.
popd >/dev/null

