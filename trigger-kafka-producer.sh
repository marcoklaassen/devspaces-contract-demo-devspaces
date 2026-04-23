#!/bin/bash

# 1. Check if argument exists
if [ -z "$1" ]; then
    echo "Usage: $0 '<json-string>'"
    exit 1
fi

# 2. Fetch credentials and bootstrap info
KAFKA_SASL_JAAS_CONFIG=$(oc get secret kafka-developer -o json | jq -r '.data."sasl.jaas.config"' | base64 --decode)
BOOTSTRAP_SERVERS=$(oc get svc kafka-kafka-bootstrap -o json | jq -r '.metadata.name + ":" + (.spec.ports[] | select(.name == "tcp-clients").port | tostring)')

# 3. Generate temporary config
CONFIG_PATH="/tmp/client.properties"
echo "security.protocol=SASL_PLAINTEXT
sasl.mechanism=SCRAM-SHA-512
sasl.jaas.config=$KAFKA_SASL_JAAS_CONFIG" > $CONFIG_PATH

# 4. Send the message provided in the first argument ($1)
echo "$1" | kafka-console-producer.sh \
  --bootstrap-server "$BOOTSTRAP_SERVERS" \
  --topic contract \
  --producer.config "$CONFIG_PATH"

# 5. Cleanup
rm "$CONFIG_PATH"