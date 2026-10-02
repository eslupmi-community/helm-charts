# Changelog

All notable changes to this chart are documented here. Version numbers match [chart releases](https://github.com/eslupmi-community/helm-charts/releases).

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [v1.1.0]

### Added

- Top-level `env` map for literal container environment variables (replaces `config.env`).
- `envFrom` for loading environment variables from ConfigMaps and Secrets.
- Values and templates aligned with [documented environment variables](https://impulse.bot/docs/stable/envs/) and [impulse.yml options](https://impulse.bot/docs/stable/config_file/) (`general`, `inhibit_rules`, full `incident` defaults including `closed` TTL, messenger `groups`, UI `filters`, and `task_management` for Jira).
- `secrets.inline` / `secrets.existing` for auth (`AUTH_CLIENT_SECRET`) and Jira (`JIRA_API_TOKEN`), alongside existing messenger and Google secret options.
- Optional Jinja templates via `templates` for incident messages (`header`, `body`, `status_icons`), task management (`summary`, `description`), and all [thread messages](https://impulse.bot/docs/stable/concepts/templates/#thread-messages). Custom files are mounted over IMPulse defaults at `/app/templates` and `/app/thread_templates`.
- `LISTEN_PORT` is set from `service.port`; `LISTEN_HOST` defaults to `0.0.0.0`.
- OCI chart publishing to `oci://ghcr.io/eslupmi-community/helm-charts` on release (GHCR login in the release workflow; alongside GitHub Releases / Helm repo index).
- Pull-request CI: `helm lint`, default and messenger example value templates, `envFrom`, and custom Jinja template smoke tests.

### Changed

- Messenger, Google, auth, and Jira credentials use shared helper bindings in `_helpers.tpl` for deployment env vars, inline chart Secrets, and rollout checksums.
- Container listen port follows `service.port` (named port `http` on the pod).
- Literal `env` entries are rendered in stable alphabetical order; keys reserved for chart-managed listen, messenger, auth, and Jira variables are skipped when also set in `env`.
- ServiceMonitor scrapes the Service port named `http` (not the numeric port value).
- Google service account JSON is mounted at `env.GOOGLE_SERVICE_ACCOUNT_FILE` when inline or existing Google secrets are configured.
- Custom templates no longer inject deprecated `messenger.template_files` / `task_management.template_files` into `impulse.yml`; those keys are stripped if present in `impulseConfig`.
- ConfigMap rendering deep-copies `impulseConfig` before render (does not mutate release values).
- Ingress annotations are merged without mutating release values during template render.
- Ingress template uses `networking.k8s.io/v1` only; `pathType` defaults to `Prefix` when omitted; minimum Kubernetes version is 1.19 (`Chart.yaml` `kubeVersion`).
- Deployment omits `replicas` when autoscaling is enabled so the HPA owns replica count.
- Release workflow uses `helm/chart-releaser-action@v1.7.0` with `packages: write` for OCI pushes.

### Fixed

- Google service account Secret volume was defined but not mounted.
- ServiceMonitor referenced the numeric service port instead of the port name.
- Nil `secrets.existing` could break Google secret volume rendering.

### Upgrade notes

- Rename `config.env` to `env` in your values files.
- Remove messenger, auth, and Jira credentials from `env`; configure them via `secrets.inline` or `secrets.existing` instead.
- If you override `service.port`, the container now listens on that port as well (previously it stayed at 5000).
- Clusters below Kubernetes 1.19 are no longer supported by this chart.
- With `autoscaling.enabled: true`, set scale bounds via `autoscaling.minReplicas` / `maxReplicas`, not `replicaCount`.
- Remove `impulseConfig.messenger.template_files` and `impulseConfig.task_management.template_files`; set template contents under `templates` instead.
- Rename `templates.jiraSummary` / `templates.jiraDescription` to `templates.summary` / `templates.description` (old keys still work).

## [v1.0.15]

Previous release. See git history for details.
