#!/bin/bash
set -e

if [ "$#" -lt 3 ]; then
    echo "❌ Usage: $0 <app-name> <image-uri> <container-port> [url-path]"
    echo "💡 Example: $0 frontend-app 763054201983.dkr.ecr.us-east-1.amazonaws.com/frontend:latest 3000 /"
    exit 1
fi

APP_NAME=$1
IMAGE_URI=$2
PORT=$3
PATH_PREFIX=${4:-"/$APP_NAME"}
MANIFEST_FILE="platform-manifests/${APP_NAME}.yaml"

if [ "$PATH_PREFIX" = "/" ]; then
    INGRESS_PATH="/"
    REWRITE_ANNOTATION=""
else
    INGRESS_PATH="${PATH_PREFIX}(/|$)(.*)"
    REWRITE_ANNOTATION="nginx.ingress.kubernetes.io/rewrite-target: /\$2"
fi

echo "⚙️ Generating flexible wildcard-host manifests for '$APP_NAME'..."

cat << YAML > "$MANIFEST_FILE"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}-deployment
  namespace: apps
  labels:
    app: ${APP_NAME}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      labels:
        app: ${APP_NAME}
    spec:
      containers:
        - name: app-container
          image: ${IMAGE_URI}
          ports:
            - containerPort: ${PORT}
          resources:
            limits:
              memory: "256Mi"
              cpu: "500m"
            requests:
              memory: "128Mi"
              cpu: "250m"
---
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}-service
  namespace: apps
spec:
  ports:
    - port: 80
      targetPort: ${PORT}
      protocol: TCP
  selector:
    app: ${APP_NAME}
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${APP_NAME}-ingress
  namespace: apps
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    ${REWRITE_ANNOTATION}
spec:
  ingressClassName: nginx
  rules:
    - http:  # <--- Removed strict 'host' filter to allow direct IP and multi-domain browser access!
        paths:
          - path: "${INGRESS_PATH}"
            pathType: ImplementationSpecific
            backend:
              service:
                name: ${APP_NAME}-service
                port:
                  number: 80
YAML

echo "✅ Manifest optimized at: $MANIFEST_FILE"
echo "📦 Pushing structural platform update to Git repository..."

git add "$MANIFEST_FILE"
git commit -m "fix(platform): strip strict host constraints to enable seamless web browser routing"
git push origin main

echo "🚀 GitOps update pushed!"
