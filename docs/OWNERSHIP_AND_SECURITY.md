# Ownership And Security Checkpoint

All custom project assets and code ultimately belong to FLEXWOLF according to the
project contract, including applicable:

- Flutter code
- native bridge code
- backend code
- APIs
- admin/CMS code
- custom database/configuration
- design/editable assets
- Firebase/cloud/CMS configuration
- documentation

Do not introduce a developer-owned production dependency that prevents another
developer from continuing the project.

## Client Password Security

Do not request client passwords. Prefer collaborator invitations, developer
access, team roles, and service-specific access.

Sensitive secrets must later be entered through secure configuration or
FLEXWOLF-controlled secret management. Secrets must not be sent through chat or
committed to source control.
