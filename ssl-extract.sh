#!/bin/bash

# This script will extract both cert and key from a .pfx file
# Make sure to have the password on hand
# --KP, 09/16/2015

clear

echo "You are currently logged in as $USER"
echo "Please update authentication credentials"
sudo -v

echo "What is the cert name?"
read certname

echo "What is the site name?"
read site

echo "What is the .pfx passphrase?"
read -s passphrase

sudo openssl pkcs12 -in $certname.pfx -nocerts -out $site.key -nodes -password pass:$passphrase
sudo openssl pkcs12 -in $certname.pfx -nokeys -out $site.crt -password pass:$passphrase
sudo openssl rsa -in $site.key -out $site.key

echo "Done!"
echo "The cert is $site.crt"
echo "The key is $site.key"
