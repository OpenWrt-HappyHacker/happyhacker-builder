#!/usr/bin/env python
#
# Extract the .onion hostname from the public key.
#
# Note: Here's the command to extract the public key in SPKI form from the private key:
#       openssl pkey -pubout -inform pem -outform der -in private_key -out public_key

import sys
import base64
import hashlib

# Get the public key in SPKI format.
with open(sys.argv[1], "rb") as fd:
    data = fd.read()
assert data

# Remove the first 22 bytes (the header).
assert len(data) > 22
data = data[22:]

# Calculate the SHA1 hash.
sha1 = hashlib.sha1()
sha1.update(data)
data = sha1.digest()
assert data

# Encode the hash in Base32 format.
data = base64.b32encode(data)
assert data

# Drop the last half of the hash.
data = data[:16]
assert len(data) == 16
assert data.isalnum()

# Convert to lowercase and append the ".onion" extension.
data = data.lower() + ".onion"
assert data.islower()

# Return the .onion hostname.
print data

