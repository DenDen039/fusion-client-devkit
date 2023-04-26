#! /bin/sh
clientDir=$(ls -d *-client | tail -n 1)
clientName=${clientDir%%-client}

if [ ! -d  "$clientDir" ]; then
	echo "client directory not mounted. Did you run with docker -v <path-to-client-dir>:/<client-name>-client?"
	exit 1
fi

if [ ! -f "$clientDir/issuer" ]; then
	echo "issuer not found. Did you add the file issuer containing the application ID into your client directory?"
	exit 1
fi

# Find private key file
if [ -n "$PRIVATE_KEY_FILE" ] && [ -f "$clientDir/$PRIVATE_KEY_FILE" ]; then
  keyFile="$PRIVATE_KEY_FILE"
elif [ -f "$clientDir/private-key.pem" ]; then
  keyFile="private-key.pem"
else
  file=$(find "$clientDir" -type f -iname "*.pem" | head -n 1)
  if [ -n "$file" ]; then 
    keyFile=$(basename $file)
  fi
fi

if [ -z "$keyFile" ] || [ ! -f "$clientDir/$keyFile" ]; then
  echo "Private key not found. Add the file *.pem into your client directory"
  echo "Or add PRIVATE_KEY_FILE=<key-file> env variable to docker run and <key-file> into your client directory"
  exit 1 
fi

if [ ! -f "/root/.pure/fusion.json" ]; then
  mkdir -p ~/.pure/
  cat <<EOF > ~/.pure/fusion.json
{
  "default_profile": "$clientName",
  "profiles": {
    "$clientName": {
      "auth": {
        "issuer_id": "$(cat $clientDir/issuer)",
	"private_pem_file": "$(realpath $clientDir)/$keyFile"
      },
      "endpoint": "https://api.pure1.purestorage.com/fusion",
      "env": "pure1"
    }
  }
}
EOF
fi

export PRIV_KEY_FILE="$(realpath $clientDir)/$keyFile"
export FUSION_PRIVATE_KEY_FILE="$(realpath $clientDir)/$keyFile"
export API_CLIENT="$(cat $clientDir/issuer)"
export FUSION_ISSUER_ID="$API_CLIENT"
export FUSION_PRIVATE_KEY_FILE="$PRIV_KEY_FILE"
export PS1="fusion-devkit[$clientName]:\w$ "
