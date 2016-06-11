#!/bin/bash

# Auto generates CSR for sites using 4096-bit SHA2 encryption and temp config file
# --KP, 09/16/2015

clear

echo "You are currently logged in as $USER"
echo "Please update authentication credentials"
sudo -v

echo "What is the FQDN of the site you wish to encrypt?"
read fqdn

echo "What is the organization name?"
read organization

echo "What is the contact email for this cert?"
read email

echo "State?"
read state

echo "Country?"
read country

echo "City?"
read city

echo "Generating..."
sudo echo " [ req ]
prompt = no
default_bits = 4096
default_keyfile = $fqdn.key
encrypt_key = no
distinguished_name = req_distinguished_name

string_mask = utf8only

req_extensions = v3_req

[ req_distinguished_name ]
O=$organization
L=$city
ST=$state
C=$country
CN=$fqdn

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment" >> temp-openssl.cfg

sudo openssl req -new -config temp-openssl.cfg -out $fqdn.csr

sudo rm temp-openssl.cfg

echo "Done. The CSR name is: $fqdn.csr"
echo "The key name is: $fqdn.key"
echo "All have been encrypted with 4096-bit encryption"

