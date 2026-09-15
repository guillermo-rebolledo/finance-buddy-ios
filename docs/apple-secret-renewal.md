# Apple sign-in secret renewal

## Configured for production

| Variable | Subject | Expiry |
| --- | --- | --- |
| `APPLE_IOS_CLIENT_SECRET` | `com.guillermorebolledo.FinanceBuddy` | March 14, 2027, 18:57:24 UTC |
| `APPLE_CLIENT_SECRET` | Web Services ID | Production value is marked Sensitive and is not exportable; its exact deployed expiration was not verified |

The native secret was generated on September 15, 2026 using Apple key ID `KHWFW446T7`, team `X76BWPRADX`, and the owner-provided local `.p8` key. Its ES256 signature, subject, issuer and audience were verified locally before sending it directly to Vercel through stdin. No JWT or private-key contents were printed or committed.

Vercel confirms `APPLE_IOS_CLIENT_SECRET` exists as a Sensitive Production variable. Deployment `dpl_CNJ4Zr8VQuhAGbcxaHhw3rRYoizi` was created after the variable was added. Live native Apple sign-in/deletion remains a physical-device verification item.

## Renewal checklist

Set an owner reminder for **February 28, 2027**, leaving time to generate, deploy and test the replacement before March 14. No calendar reminder was created by this task.

1. Follow the backend's `docs/apple-sign-in.md`; generate the JWT with the correct subject. Web Services ID and native bundle ID require separate secrets.
2. Verify the signature, issuer, subject, audience and expiration without printing the token.
3. Replace the corresponding Sensitive Production variable in Vercel. Send the token by stdin or enter it directly in the dashboard; do not put it in shell arguments, logs, Git or chat.
4. Redeploy production. An environment-variable edit alone does not update running deployments.
5. Test provider sign-in and deletion with disposable accounts, then record the new expiration here.

Also establish the exact expiration of the deployed web secret through the owner's original generation record or rotate it before its known renewal deadline. A local development secret's claims do not prove the deployed production secret's expiry.
