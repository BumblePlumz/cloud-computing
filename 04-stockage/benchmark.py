"""Compare Object Storage (S3) vs Block Storage (fichiers locaux) : perf + couts.

- La mesure S3 est REELLE (appels a LocalStack).
- La mesure "block" utilise des fichiers locaux (= ton disque/SSD) pour
  illustrer l'ordre de grandeur : LocalStack ne fournit pas de vrai EBS.
"""

import os
import time
import tempfile

import boto3

CONFIG = dict(
    endpoint_url=os.getenv("AWS_ENDPOINT_URL", "http://localhost:4566"),
    region_name="us-east-1",
    aws_access_key_id="test",
    aws_secret_access_key="test",
)
s3 = boto3.client("s3", **CONFIG)

BUCKET = "benchmark-object-storage"
TAILLES = [1 * 1024, 100 * 1024, 10 * 1024 * 1024]  # 1 Ko, 100 Ko, 10 Mo


def _ms(debut):
    return (time.perf_counter() - debut) * 1000


def bench_object_storage():
    print("\n=== OBJECT STORAGE (S3 via LocalStack) ===")
    for taille in TAILLES:
        data = os.urandom(taille)
        cle = f"test-{taille}.bin"

        debut = time.perf_counter()
        s3.put_object(Bucket=BUCKET, Key=cle, Body=data)
        t_ecriture = _ms(debut)

        debut = time.perf_counter()
        s3.get_object(Bucket=BUCKET, Key=cle)["Body"].read()
        t_lecture = _ms(debut)

        print(f"  {taille // 1024:>6} Ko | Ecriture: {t_ecriture:7.2f} ms | Lecture: {t_lecture:7.2f} ms")


def bench_block_storage():
    print("\n=== BLOCK STORAGE (fichier local = equivalent EBS) ===")
    with tempfile.TemporaryDirectory() as tmp:
        for taille in TAILLES:
            data = os.urandom(taille)
            chemin = os.path.join(tmp, f"test-{taille}.bin")

            debut = time.perf_counter()
            with open(chemin, "wb") as f:
                f.write(data)
                f.flush()
                os.fsync(f.fileno())
            t_ecriture = _ms(debut)

            debut = time.perf_counter()
            with open(chemin, "rb") as f:
                f.read()
            t_lecture = _ms(debut)

            print(f"  {taille // 1024:>6} Ko | Ecriture: {t_ecriture:7.2f} ms | Lecture: {t_lecture:7.2f} ms")


def couts_1to():
    print("\n=== COUT MENSUEL POUR 1 To ===")
    print("  S3 Standard : ~23 EUR/mois  (0.023 USD/Go)")
    print("  EBS gp3     : ~82 EUR/mois  (0.08 USD/Go)")
    print("  EBS io2     : ~125 EUR/mois (0.125 USD/Go)")
    print("  => Economie S3 vs EBS gp3 : ~59 EUR/mois pour 1 To")


if __name__ == "__main__":
    bench_object_storage()
    bench_block_storage()
    couts_1to()
    print("\nRegle : modifier des octets AU MILIEU d'un fichier -> Block ;")
    print("        lire/ecrire des fichiers ENTIERS -> Object.")
