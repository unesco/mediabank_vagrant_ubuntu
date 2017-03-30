#!/bin/bash -x

cd 

sed -i '/PATH=/c\PATH="$HOME/bin:$HOME/.local/bin:$HOME/eprints/bin:$HOME/eprints/tools:$PATH"' .profile
source .profile
wget http://bazaar.eprints.org/cgi/export/eprint/452/EPM/multilang_fields-0.0.9.epm -nv
cd eprints
git fetch --all
git checkout v3.3.15

# This is buggy...
rm -rf perl_lib/URI*
cp ~/vagrant/resources/SystemSettings.pm perl_lib/EPrints/

# Install multilang fields
epm install ../multilang_fields-0.0.9.epm

# Install gitaar for development
wget https://raw.githubusercontent.com/eprintsug/gitaar/master/gitaar -nv -O tools/gitaar
chmod 755 tools/gitaar
