"""Audit de securite S3 : compare le bucket vulnerable et le bucket securise.

Pour chaque controle, on lit la config reellement stockee dans LocalStack
et on affiche PASS / FAIL.
"""

import json
import os

import boto3
from botocore.exceptions import ClientError

s3 = boto3.client(
    "s3",
    endpoint_url=os.getenv("AWS_ENDPOINT_URL", "http://localhost:4566"),
    region_name="us-east-1",
    aws_access_key_id="test",
    aws_secret_access_key="test",
)

VULN = "bucket-vulnerable-demo"
SECURE = "bucket-securise-demo"


def check_public_access_block(bucket):
    try:
        cfg = s3.get_public_access_block(Bucket=bucket)["PublicAccessBlockConfiguration"]
        if all(cfg.values()):
            return True, "acces public bloque (4/4)"
        return False, f"acces public PAS totalement bloque : {cfg}"
    except ClientError:
        return False, "aucun Public Access Block (=ouvert)"


def check_encryption(bucket):
    try:
        rules = s3.get_bucket_encryption(Bucket=bucket)["ServerSideEncryptionConfiguration"]["Rules"]
        algo = rules[0]["ApplyServerSideEncryptionByDefault"]["SSEAlgorithm"]
        return True, f"chiffrement actif ({algo})"
    except ClientError:
        return False, "aucun chiffrement"


def check_versioning(bucket):
    status = s3.get_bucket_versioning(Bucket=bucket).get("Status")
    if status == "Enabled":
        return True, "versioning active"
    return False, "versioning absent"


def check_policy(bucket):
    try:
        pol = json.loads(s3.get_bucket_policy(Bucket=bucket)["Policy"])
        for st in pol.get("Statement", []):
            if st.get("Principal") == "*" or st.get("Principal") == {"AWS": "*"}:
                return False, "policy PUBLIQUE (Principal: *)"
        return True, "policy restreinte"
    except ClientError:
        return True, "aucune policy publique"


def audit(bucket):
    print(f"\n===== {bucket} =====")
    controls = [
        ("Public Access Block", check_public_access_block),
        ("Chiffrement", check_encryption),
        ("Versioning", check_versioning),
        ("Bucket Policy", check_policy),
    ]
    score = 0
    for nom, fn in controls:
        ok, detail = fn(bucket)
        score += 1 if ok else 0
        print(f"  [{'PASS' if ok else 'FAIL'}] {nom:<20} {detail}")
    print(f"  Score securite : {score}/{len(controls)}")


if __name__ == "__main__":
    audit(VULN)
    audit(SECURE)
    print("\n=> Le bucket vulnerable expose les donnees ; le securise les protege.")
