"""Client Python simulant une app mobile appelant le BaaS GCP (Firestore + Cloud Storage).

Equivalent de ../app.py côté AWS. Compare les deux fichiers pour voir la différence
entre les SDKs boto3 et google-cloud-*.

Dépendances :
    pip install google-cloud-firestore google-cloud-storage

Auth :
    export GOOGLE_APPLICATION_CREDENTIALS=/chemin/vers/key.json
    export GCP_PROJECT=mon-projet-baas
    export FILES_BUCKET=mon-projet-baas-baas-user-files
"""

import os
import uuid
from datetime import datetime, timedelta

from google.cloud import firestore, storage

GCP_PROJECT = os.environ["GCP_PROJECT"]
FILES_BUCKET = os.environ["FILES_BUCKET"]

# Contrairement à boto3 qui nécessite des clés dans le code, le client GCP
# lit les credentials depuis la variable GOOGLE_APPLICATION_CREDENTIALS.
db = firestore.Client(project=GCP_PROJECT)
gcs = storage.Client(project=GCP_PROJECT)


def creer_utilisateur(nom: str, email: str) -> dict:
    # AWS : dynamo.Table("baas-users").put_item(Item=user)
    # GCP : db.collection("users").document(id).set(user)
    user = {
        "userId": str(uuid.uuid4()),
        "nom": nom,
        "email": email,
        "creeA": datetime.now().isoformat(),
    }
    db.collection("users").document(user["userId"]).set(user)
    print(f"[BaaS-GCP] Utilisateur cree : {nom} ({user['userId'][:8]}...)")
    return user


def creer_session(user_id: str) -> dict:
    # Session avec expiresAt dans 1h → suppression auto via TTL Firestore
    session = {
        "sessionId": str(uuid.uuid4()),
        "userId": user_id,
        "expiresAt": datetime.now() + timedelta(hours=1),
    }
    db.collection("sessions").document(session["sessionId"]).set(session)
    print(f"[BaaS-GCP] Session creee : {session['sessionId'][:8]}...")
    return session


def uploader_fichier(user_id: str, nom_fichier: str, contenu: str) -> None:
    # AWS : s3.put_object(Bucket=..., Key=..., Body=contenu)
    # GCP : bucket.blob(key).upload_from_string(contenu)
    bucket = gcs.bucket(FILES_BUCKET)
    blob = bucket.blob(f"users/{user_id}/{nom_fichier}")
    blob.upload_from_string(contenu)
    print(f"[BaaS-GCP] Fichier uploade : users/{user_id}/{nom_fichier}")


def lister_fichiers(user_id: str) -> list[str]:
    # AWS : s3.list_objects_v2(Bucket=..., Prefix=...)
    # GCP : gcs.list_blobs(bucket, prefix=...)
    prefix = f"users/{user_id}/"
    blobs = list(gcs.list_blobs(FILES_BUCKET, prefix=prefix))
    keys = [b.name for b in blobs]
    print(f"[BaaS-GCP] {len(keys)} fichier(s) pour {user_id[:8]}...")
    return keys


if __name__ == "__main__":
    u = creer_utilisateur("Alice Dupont", "alice@exemple.fr")
    creer_session(u["userId"])
    uploader_fichier(u["userId"], "profil.txt", "Donnees profil Alice")
    lister_fichiers(u["userId"])
    print("[BaaS-GCP] Application BaaS operationnelle !")
