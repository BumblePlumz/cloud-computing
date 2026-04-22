"""Client Python simulant une app mobile appelant le BaaS (DynamoDB + S3)."""

import uuid
from datetime import datetime

import boto3

# Connexion LocalStack
config = dict(
    endpoint_url="http://localhost:4566",
    region_name="us-east-1",
    aws_access_key_id="test",
    aws_secret_access_key="test",
)

dynamo = boto3.resource("dynamodb", **config)
s3 = boto3.client("s3", **config)


def creer_utilisateur(nom: str, email: str) -> dict:
    table = dynamo.Table("baas-users")
    user = {
        "userId": str(uuid.uuid4()),
        "nom": nom,
        "email": email,
        "creeA": datetime.now().isoformat(),
    }
    table.put_item(Item=user)
    print(f"[BaaS] Utilisateur cree : {nom} ({user['userId'][:8]}...)")
    return user


def uploader_fichier(user_id: str, nom_fichier: str, contenu: str) -> None:
    cle = f"users/{user_id}/{nom_fichier}"
    s3.put_object(Bucket="baas-user-files", Key=cle, Body=contenu.encode())
    print(f"[BaaS] Fichier uploade : {cle}")


def lister_fichiers(user_id: str) -> list[str]:
    prefix = f"users/{user_id}/"
    resp = s3.list_objects_v2(Bucket="baas-user-files", Prefix=prefix)
    keys = [obj["Key"] for obj in resp.get("Contents", [])]
    print(f"[BaaS] {len(keys)} fichier(s) pour {user_id[:8]}...")
    return keys


if __name__ == "__main__":
    u = creer_utilisateur("Alice Dupont", "alice@exemple.fr")
    uploader_fichier(u["userId"], "profil.txt", "Donnees profil Alice")
    lister_fichiers(u["userId"])
    print("[BaaS] Application BaaS operationnelle !")
