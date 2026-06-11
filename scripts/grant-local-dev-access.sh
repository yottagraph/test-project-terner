#!/usr/bin/env bash
# Grant the current gcloud user the IAM roles needed to develop LOCALLY
# against a BC 2.0 tenant's own GCP project — the same data planes the
# in-cluster pod reaches via Workload Identity, but reached from your
# laptop via Application Default Credentials.
#
# In local dev YOU are the workload identity, so you need the human
# equivalent of the roles gcp-bctenant grants the tenant runtime GSAs.
# See .agents/skills/aether/local-dev-bc2.md.
#
# ⚠️  PREFER THE PORTAL OPT-IN ON TF-GOVERNED TENANTS (ENG-986).
# This script grants roles to YOUR user with `gcloud`, which needs
# `resourcemanager.projects.setIamPolicy` (project bindings) and
# `iam.serviceAccounts.setIamPolicy` (the GSA token-creator). On a real BC 2.0
# tenant the ONLY project owner is `sa-terraform-bctenant@`, so a normal
# developer has NEITHER — the GSA binding fails and the project bindings may
# too. The durable, auditable path is the portal local-dev opt-in: tick
# "local dev access" at provision, or have an operator run `enable_local_dev`.
# That makes gcp-bctenant TF-grant your dev group the SAME roles below (plus
# the GSA token-creator), so you don't run this script at all — just be a
# member of the configured group. `npm run bridge` tells you whether the
# tenant is already opted in. This script remains the right tool for a
# sandbox / personally-owned project where you ARE the owner.
#
# Usage:
#   gcloud auth login
#   gcloud auth application-default login
#   scripts/grant-local-dev-access.sh <tenant-gcp-project> [user-email]
#
# (`npm run bridge` prints the exact <tenant-gcp-project> for you.)
#
# Idempotent: add-iam-policy-binding is a no-op if the binding exists.
set -euo pipefail

PROJECT="${1:-}"
if [[ -z "$PROJECT" ]]; then
    echo "usage: $0 <tenant-gcp-project> [user-email]" >&2
    exit 2
fi

USER_EMAIL="${2:-$(gcloud config get-value account 2>/dev/null)}"
if [[ -z "$USER_EMAIL" || "$USER_EMAIL" == "(unset)" ]]; then
    echo "Could not resolve your gcloud account; pass it as the 2nd arg." >&2
    exit 2
fi

MEMBER="user:${USER_EMAIL}"

# Roles, by plane. Mirrors what gcp-bctenant grants the runtime GSAs:
#   - Firestore prefs            → datastore.user
#   - BigQuery (read + run jobs) → bigquery.jobUser + bigquery.dataViewer
#   - Cloud SQL (IAM auth)       → cloudsql.client + cloudsql.instanceUser
#   - Cloud SQL (list instances) → cloudsql.viewer, so `npm run bridge` can
#     resolve the TF-suffixed instance's connection name with your own creds
#     when the portal couldn't (see docs/BC_2_LOCAL_DEV.md).
ROLES=(
    "roles/datastore.user"
    "roles/bigquery.jobUser"
    "roles/bigquery.dataViewer"
    "roles/cloudsql.client"
    "roles/cloudsql.instanceUser"
    "roles/cloudsql.viewer"
)

echo "Granting local-dev roles on ${PROJECT} to ${MEMBER}:"
for ROLE in "${ROLES[@]}"; do
    echo "  + ${ROLE}"
    gcloud projects add-iam-policy-binding "$PROJECT" \
        --member="$MEMBER" \
        --role="$ROLE" \
        --condition=None \
        --quiet >/dev/null
done

# Cloud SQL is reached by IMPERSONATING the tenant runtime GSA
# (bc-aether-ui@<project>...), so you also need Token Creator ON that GSA.
# This is what lets `cloud-sql-proxy --impersonate-service-account` mint a
# token for the runtime identity (whose table grants already exist).
#
# Granting THIS binding needs iam.serviceAccounts.setIamPolicy on the GSA,
# which a non-owner developer usually lacks. Do NOT swallow a failure here:
# a silent "skipped" sends you off to debug an opaque Cloud SQL Auth Proxy
# error later. Surface it honestly with the exact owner-run remediation.
RUNTIME_GSA="bc-aether-ui@${PROJECT}.iam.gserviceaccount.com"
CLOUDSQL_BLOCKED=0
echo "  + roles/iam.serviceAccountTokenCreator on ${RUNTIME_GSA}"
if err=$(gcloud iam service-accounts add-iam-policy-binding "$RUNTIME_GSA" \
    --project="$PROJECT" \
    --member="$MEMBER" \
    --role="roles/iam.serviceAccountTokenCreator" \
    --quiet 2>&1); then
    : # bound (or already bound) — good
elif grep -qiE 'PERMISSION_DENIED|setIamPolicy' <<<"$err"; then
    CLOUDSQL_BLOCKED=1
    cat >&2 <<MSG

  ⚠️  Could NOT grant Token Creator on ${RUNTIME_GSA}:
      your account lacks iam.serviceAccounts.setIamPolicy on it.

      On a TF-governed BC 2.0 tenant this is EXPECTED — only the provisioning
      pipeline (sa-terraform-bctenant) owns the project, no human can grant on
      the GSA. This is NOT necessarily a problem:

      • If this tenant is OPTED INTO local-dev (portal "local dev access" /
        enable_local_dev — ENG-986), your dev group already holds this binding
        (and the project roles above) via Terraform, so this failure is
        HARMLESS and Cloud SQL will still be GREEN. Just be a member of the
        configured group. (`npm run bridge` reports the opt-in state.)

      • If it is NOT opted in, Cloud SQL stays RED until it is. The durable
        fix is the opt-in, NOT this script — ask an operator to run
        enable_local_dev for this tenant. Only where a human owner exists
        (e.g. a sandbox project) can someone run:
          gcloud iam service-accounts add-iam-policy-binding ${RUNTIME_GSA} \\
            --project=${PROJECT} --member="${MEMBER}" \\
            --role=roles/iam.serviceAccountTokenCreator
MSG
elif grep -qiE 'NOT_FOUND|does not exist' <<<"$err"; then
    echo "    (skipped — runtime GSA not created yet; re-run after provisioning)"
else
    echo "    (warning: ${err##*ERROR: })" >&2
fi

echo
echo "Done. Next:"
echo "  cat .env.bridge >> .env && npm run dev"
echo "  open http://localhost:3000/tenancy-probe"
echo
echo "Cloud SQL also needs the Auth Proxy running locally, and the agent"
echo "runs as a local adk api_server — see the commented blocks in .env.bridge."
if [[ "$CLOUDSQL_BLOCKED" == "1" ]]; then
    echo
    echo "NOTE: the Token Creator grant above did NOT land from this script. If this"
    echo "      tenant is opted into local-dev (ENG-986), your dev group already has"
    echo "      it via Terraform and Cloud SQL will be GREEN anyway — this is harmless."
    echo "      If not opted in, get opted in (portal enable_local_dev) rather than"
    echo "      chasing a manual grant; \`npm run bridge\` shows the opt-in state."
fi
