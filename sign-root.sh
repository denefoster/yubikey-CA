#OPENSSL_ENGINES=/opt/homebrew/lib/engines-3 \
OPENSSL_ENGINES=/opt/homebrew/lib/engines-3 \
    openssl ca \
    -config openssl.cnf \
    -engine pkcs11 \
    -keyform engine \
    -extensions ext_intermediate \
    -days 1825 \
    -notext \
    -md sha256 \
    -in $host.csr \
    -out $host.pem
