#!/usr/bin/env bash
# Env: AWS_PROFILE (required), AWS_REGION, FUNCTION_NAME, ECR_REPO, ROLE_NAME, ARCH (arm64|x86_64), ITBAA_VERSION.
set -euo pipefail
cd "$(dirname "$0")"

PROFILE="${AWS_PROFILE:?set AWS_PROFILE}"
REGION="${AWS_REGION:-us-east-1}"
REPO="${ECR_REPO:-itbaa-lambda}"
FN="${FUNCTION_NAME:-itbaa-pdf-example}"
ROLE="${ROLE_NAME:-itbaa-lambda-example-role}"
ARCH="${ARCH:-arm64}"
ITBAA_VERSION="${ITBAA_VERSION:-v1.1.0}"
PLATFORM="linux/arm64"; [ "$ARCH" = "x86_64" ] && PLATFORM="linux/amd64"

ACCOUNT="$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text)"
ECR="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
IMAGE="${ECR}/${REPO}:latest"

aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" --profile "$PROFILE" >/dev/null 2>&1 \
  || aws ecr create-repository --repository-name "$REPO" --region "$REGION" --profile "$PROFILE" >/dev/null

aws ecr get-login-password --region "$REGION" --profile "$PROFILE" \
  | docker login --username AWS --password-stdin "$ECR"
# --provenance=false: buildx otherwise pushes an OCI manifest Lambda rejects ("media type ... is not supported").
docker build --platform "$PLATFORM" --provenance=false \
  --build-arg ITBAA_VERSION="$ITBAA_VERSION" -t "$IMAGE" .
docker push "$IMAGE"

if ! aws iam get-role --role-name "$ROLE" --profile "$PROFILE" >/dev/null 2>&1; then
  aws iam create-role --role-name "$ROLE" --profile "$PROFILE" \
    --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}' >/dev/null
  aws iam attach-role-policy --role-name "$ROLE" --profile "$PROFILE" \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
  sleep 10 # let the new role propagate before Lambda assumes it
fi
ROLE_ARN="$(aws iam get-role --role-name "$ROLE" --query 'Role.Arn' --output text --profile "$PROFILE")"

if aws lambda get-function --function-name "$FN" --region "$REGION" --profile "$PROFILE" >/dev/null 2>&1; then
  aws lambda update-function-code --function-name "$FN" --image-uri "$IMAGE" \
    --region "$REGION" --profile "$PROFILE" >/dev/null
else
  aws lambda create-function --function-name "$FN" --package-type Image --code ImageUri="$IMAGE" \
    --role "$ROLE_ARN" --architectures "$ARCH" --memory-size 1024 --timeout 30 \
    --region "$REGION" --profile "$PROFILE" >/dev/null
fi
aws lambda wait function-active-v2 --function-name "$FN" --region "$REGION" --profile "$PROFILE"
echo "deployed $FN ($ARCH) in $REGION"
