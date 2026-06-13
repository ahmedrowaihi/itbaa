#!/usr/bin/env bash
set -uo pipefail
PROFILE="${AWS_PROFILE:?set AWS_PROFILE}"
REGION="${AWS_REGION:-us-east-1}"
REPO="${ECR_REPO:-itbaa-lambda}"
FN="${FUNCTION_NAME:-itbaa-pdf-example}"
ROLE="${ROLE_NAME:-itbaa-lambda-example-role}"

aws lambda delete-function --function-name "$FN" --region "$REGION" --profile "$PROFILE" 2>/dev/null && echo "deleted $FN"
aws ecr delete-repository --repository-name "$REPO" --force --region "$REGION" --profile "$PROFILE" 2>/dev/null && echo "deleted $REPO"
aws iam detach-role-policy --role-name "$ROLE" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole --profile "$PROFILE" 2>/dev/null
aws iam delete-role --role-name "$ROLE" --profile "$PROFILE" 2>/dev/null && echo "deleted $ROLE"
aws logs delete-log-group --log-group-name "/aws/lambda/$FN" --region "$REGION" --profile "$PROFILE" 2>/dev/null
echo "teardown complete"
