"""Lambda FaaS exposee via API Gateway (integration proxy).

Routes :
  GET  /hello?nom=X   -> reponse simple, sans acces AWS (prouve API GW -> Lambda)
  GET  /users         -> liste les utilisateurs (DynamoDB)
  POST /users         -> cree un utilisateur (DynamoDB)
"""

import json
import os
import uuid
from datetime import datetime

import boto3

ENDPOINT = os.getenv("AWS_ENDPOINT_URL")              # injecte par Terraform en mode LocalStack
REGION = os.getenv("AWS_DEFAULT_REGION", "us-east-1")
TABLE = os.getenv("USERS_TABLE", "faas-users")


def _client(service):
    kwargs = {"region_name": REGION}
    if ENDPOINT:  # LocalStack : on force l'endpoint + credentials de test
        kwargs.update(endpoint_url=ENDPOINT, aws_access_key_id="test", aws_secret_access_key="test")
    return boto3.client(service, **kwargs)


def _resp(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json",
            # CORS : permet l'appel depuis un front (navigateur)
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
        "body": json.dumps(body, ensure_ascii=False),
    }


def handler(event, context):
    method = (event.get("httpMethod") or "GET").upper()
    path = event.get("path") or "/"
    qs = event.get("queryStringParameters") or {}

    # Requete preflight CORS envoyee par le navigateur avant un POST
    if method == "OPTIONS":
        return _resp(200, {"ok": True})

    # --- Endpoint sans AWS : valide la chaine API Gateway -> Lambda ---
    if path.endswith("/hello"):
        nom = (qs.get("nom") if qs else None) or "le monde"
        return _resp(200, {"message": f"Bonjour {nom} !", "via": "API Gateway + Lambda"})

    # --- Endpoints avec DynamoDB ---
    if path.endswith("/users"):
        ddb = _client("dynamodb")
        if method == "GET":
            items = ddb.scan(TableName=TABLE).get("Items", [])
            users = [{k: list(v.values())[0] for k, v in it.items()} for it in items]
            return _resp(200, {"count": len(users), "users": users})
        if method == "POST":
            data = json.loads(event.get("body") or "{}")
            user = {
                "userId": str(uuid.uuid4()),
                "nom": data.get("nom", "Inconnu"),
                "email": data.get("email", ""),
                "creeA": datetime.utcnow().isoformat(),
            }
            ddb.put_item(TableName=TABLE, Item={k: {"S": str(v)} for k, v in user.items()})
            return _resp(201, {"created": user})

    # --- Catalogue par defaut (route /) ---
    return _resp(200, {
        "message": "FaaS API en ligne",
        "method": method,
        "path": path,
        "endpoints": ["GET /hello?nom=X", "GET /users", "POST /users"],
    })
