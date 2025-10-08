# ===================================
# scripts/generate-ssl.sh
# ===================================
#!/bin/bash
# Generate self-signed SSL certificates for development

CERT_DIR="./api-gateway/ssl"
mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout "$CERT_DIR/nginx-selfsigned.key" \
  -out "$CERT_DIR/nginx-selfsigned.crt" \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"

openssl dhparam -out "$CERT_DIR/dhparam.pem" 2048

echo "SSL certificates generated in $CERT_DIR"
