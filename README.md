# Pre-reqs

* openssl
* OpenSC
* bash
* yubico-piv-tool
# Create the root certificate off-device

For ECDSA:
openssl ecparam -genkey -name secp384r1 -out slush_root.key

For RSA:
openssl genrsa -out slush_root.key 3744


OPENSSL_ENGINES=/opt/homebrew/lib/engines-3 \
  openssl req -new -sha384 -x509 \
  -subj '/CN=Slush yubiCA Root/O=Slush Technology/C=NZ' \
  -set_serial 1 -days 1000000 \
  -config openssl.cnf \
  -extensions ext_root \
  -key slush_root.key \
  -out slush_root.pem

# Setup the PIV subCA
user=dene
key=$(export LC_CTYPE=C; \
  dd if=/dev/urandom 2>/dev/null \
  | tr -d '[:lower:]' \
  | tr -cd '[:xdigit:]' \
  | fold -w48 | head -1)

echo $key > subCA-$user-mgnt-key.txt

pin=$(export LC_CTYPE=C; \
  dd if=/dev/urandom 2>/dev/null \
  | tr -cd '[:digit:]' \
  | fold -w6 | head -1)

echo $pin > subCA-$user-pin.txt

puk=$(export LC_CTYPE=C; \
  dd if=/dev/urandom 2>/dev/null \
  | tr -cd '[:digit:]' \
  | fold -w8 | head -1)

echo $puk > subCA-$user-puk.txt

yubico-piv-tool -a set-mgm-key -n $key
yubico-piv-tool -k $key -a change-pin -P 123456 -N $pin
yubico-piv-tool -k $key -a change-puk -P 12345678 -N $puk

# Setup CA scaffolding
user=dene
key=`cat subCA-$user-mgnt-key.txt`
pin=`cat subCA-$user-pin.txt`

ECDSA
openssl ecparam -genkey -name secp384r1 -out subCA-$user.key


RSA
openssl genrsa -out subCA-$user.key 2048

OPENSSL_ENGINES=/opt/homebrew/lib/engines-3 \
  openssl req -sha384 -new \
  -subj '/CN=Slush yubiCA $user Issuing CA/O=Slush Technology/C=NZ' \
  -config openssl.cnf \
  -key subCA-$user.key \
  -nodes \
  -out subCA-$user.csr

OPENSSL_ENGINES=/opt/homebrew/lib/engines-3 \
  openssl x509 \
  -sha384 -CA slush_root.pem \
  -CAkey slush_root.key \
  -days 3650 \
  -req -in subCA-$user.csr \
  -extfile openssl.cnf \
  -extensions ext_intermediate \
  -out subCA-$user.pem

echo 00 > serial

# Put the key material on the yubikey
user=dene
yubico-piv-tool -k $key -a import-key -s 9c < subCA-$user.key
yubico-piv-tool -k $key -a import-certificate -s 9c < subCA-$user.pem


# Sign a certificate
host=munin
user=dene

openssl genrsa -out $host.key 2048

OPENSSL_ENGINES=/opt/homebrew/lib/engines-3 \
  openssl req -sha384 \
  -new \
  -config openssl.cnf \
  -addext 'subjectAltName=DNS:example.com,DNS:example.net' \
  -subj '/CN=munin.slush.ca' \
  -key munin.key \
  -nodes \
  -out munin.csr

OPENSSL_ENGINES=/opt/homebrew/lib/engines-3 \
    openssl ca \
    -config openssl.cnf \
    -engine pkcs11 \
    -keyform engine \
    -extensions ext_server \
    -days 365 \
    -notext \
    -md sha384 \
    -in $host.csr \
    -out $host.pem
