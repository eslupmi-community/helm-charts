
# Expand the name of the chart.

{{- define "impulse.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}


# Create a default fully qualified app name.
# We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
# If release name contains chart name it will be used as a full name.

{{- define "impulse.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


# Create chart name and version as used by the chart label.

{{- define "impulse.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}


# Common labels

{{- define "impulse.labels" -}}
helm.sh/chart: {{ include "impulse.chart" . }}
{{ include "impulse.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.labels }}
{{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}


# Selector labels

{{- define "impulse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "impulse.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


# Create the name of the service account to use

{{- define "impulse.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "impulse.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

# Var for autoscaling
{{- define "impulse.autoscalingEnabled" -}}
{{- if .Values.autoscaling -}}
{{- .Values.autoscaling.enabled | default false -}}
{{- else -}}
false
{{- end -}}
{{- end -}}

# Image name helper
{{- define "impulse.image" -}}
{{- printf "%s:%s" .Values.image.repository (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}

# Messenger credential env vars (secretKeyRef from existing or chart-managed secret)
{{- define "impulse.messengerSecretBindings" -}}
slack:
  inlineGateField: botUserOauthToken
  vars:
    - envName: SLACK_BOT_USER_OAUTH_TOKEN
      existingKeyField: botUserOauthTokenKey
      inlineSecretKey: slack-bot-user-oauth-token
      inlineValueField: botUserOauthToken
    - envName: SLACK_VERIFICATION_TOKEN
      existingKeyField: verificationTokenKey
      inlineSecretKey: slack-verification-token
      inlineValueField: verificationToken
mattermost:
  inlineGateField: accessToken
  vars:
    - envName: MATTERMOST_ACCESS_TOKEN
      existingKeyField: accessTokenKey
      inlineSecretKey: mattermost-access-token
      inlineValueField: accessToken
telegram:
  inlineGateField: botToken
  vars:
    - envName: TELEGRAM_BOT_TOKEN
      existingKeyField: botTokenKey
      inlineSecretKey: telegram-bot-token
      inlineValueField: botToken
{{- end -}}

{{- define "impulse.messengerSecretEnv" -}}
{{- $root := . -}}
{{- $type := $root.Values.impulseConfig.messenger.type -}}
{{- $bindings := include "impulse.messengerSecretBindings" $root | fromYaml -}}
{{- $cfg := index $bindings $type -}}
{{- if $cfg }}
{{- $existing := index ($root.Values.secrets.existing | default dict) $type | default dict -}}
{{- $inline := index ($root.Values.secrets.inline | default dict) $type | default dict -}}
{{- $chartSecret := printf "%s-secrets" (include "impulse.fullname" $root) -}}
{{- if $existing.secretName -}}
{{- range $cfg.vars }}
- name: {{ .envName }}
  valueFrom:
    secretKeyRef:
      name: {{ $existing.secretName }}
      key: {{ index $existing .existingKeyField }}
{{- end }}
{{- else if index $inline $cfg.inlineGateField -}}
{{- range $cfg.vars }}
- name: {{ .envName }}
  valueFrom:
    secretKeyRef:
      name: {{ $chartSecret }}
      key: {{ .inlineSecretKey }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "impulse.hasInlineMessengerSecrets" -}}
{{- $root := . -}}
{{- $type := $root.Values.impulseConfig.messenger.type -}}
{{- $bindings := include "impulse.messengerSecretBindings" $root | fromYaml -}}
{{- $cfg := index $bindings $type -}}
{{- if $cfg }}
{{- $inline := index ($root.Values.secrets.inline | default dict) $type | default dict -}}
{{- if index $inline $cfg.inlineGateField }}true{{- end }}
{{- end }}
{{- end -}}

{{- define "impulse.inlineGoogleSecret" -}}
{{- index (index (.Values.secrets.inline | default dict) "google" | default dict) "serviceAccountKey" -}}
{{- end -}}

{{- define "impulse.googleServiceAccountEnabled" -}}
{{- $googleExisting := get (.Values.secrets.existing | default dict) "google" | default dict -}}
{{- if $googleExisting.secretName -}}true{{- else if include "impulse.inlineGoogleSecret" . -}}true{{- end -}}
{{- end -}}

{{- define "impulse.integrationSecretBindings" -}}
auth:
  inlineGateField: clientSecret
  vars:
    - envName: AUTH_CLIENT_SECRET
      existingKeyField: clientSecretKey
      inlineSecretKey: auth-client-secret
      inlineValueField: clientSecret
jira:
  inlineGateField: apiToken
  vars:
    - envName: JIRA_API_TOKEN
      existingKeyField: apiTokenKey
      inlineSecretKey: jira-api-token
      inlineValueField: apiToken
{{- end -}}

{{- define "impulse.integrationSecretEnv" -}}
{{- $root := . -}}
{{- $bindings := include "impulse.integrationSecretBindings" $root | fromYaml -}}
{{- $chartSecret := printf "%s-secrets" (include "impulse.fullname" $root) -}}
{{- range $integration, $cfg := $bindings }}
{{- $existing := get ($root.Values.secrets.existing | default dict) $integration | default dict -}}
{{- $inline := get ($root.Values.secrets.inline | default dict) $integration | default dict -}}
{{- if $existing.secretName -}}
{{- range $cfg.vars }}
- name: {{ .envName }}
  valueFrom:
    secretKeyRef:
      name: {{ $existing.secretName }}
      key: {{ index $existing .existingKeyField }}
{{- end }}
{{- else if index $inline $cfg.inlineGateField -}}
{{- range $cfg.vars }}
- name: {{ .envName }}
  valueFrom:
    secretKeyRef:
      name: {{ $chartSecret }}
      key: {{ .inlineSecretKey }}
{{- end }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "impulse.hasInlineIntegrationSecrets" -}}
{{- $root := . -}}
{{- $bindings := include "impulse.integrationSecretBindings" $root | fromYaml -}}
{{- range $integration, $cfg := $bindings }}
{{- $inline := get ($root.Values.secrets.inline | default dict) $integration | default dict -}}
{{- if index $inline $cfg.inlineGateField }}true{{- end }}
{{- end }}
{{- end -}}

{{- define "impulse.hasInlineSecrets" -}}
{{- if include "impulse.hasInlineMessengerSecrets" . }}true{{- else if include "impulse.inlineGoogleSecret" . }}true{{- else if include "impulse.hasInlineIntegrationSecrets" . }}true{{- end }}
{{- end -}}

{{- define "impulse.authSecretEnabled" -}}
{{- $existing := get (.Values.secrets.existing | default dict) "auth" | default dict -}}
{{- if $existing.secretName -}}true{{- else if get (get (.Values.secrets.inline | default dict) "auth" | default dict) "clientSecret" -}}true{{- end -}}
{{- end -}}

{{- define "impulse.jiraSecretEnabled" -}}
{{- $existing := get (.Values.secrets.existing | default dict) "jira" | default dict -}}
{{- if $existing.secretName -}}true{{- else if get (get (.Values.secrets.inline | default dict) "jira" | default dict) "apiToken" -}}true{{- end -}}
{{- end -}}

{{- define "impulse.reservedEnvNames" -}}
LISTEN_HOST
LISTEN_PORT
{{- if include "impulse.authSecretEnabled" . -}}
AUTH_CLIENT_SECRET
{{- end -}}
{{- if include "impulse.jiraSecretEnabled" . -}}
JIRA_API_TOKEN
{{- end -}}
{{- $type := .Values.impulseConfig.messenger.type -}}
{{- $bindings := include "impulse.messengerSecretBindings" . | fromYaml -}}
{{- $cfg := index $bindings $type -}}
{{- if $cfg -}}
{{- $existing := get (.Values.secrets.existing | default dict) $type | default dict -}}
{{- $inline := get (.Values.secrets.inline | default dict) $type | default dict -}}
{{- if or $existing.secretName (index $inline $cfg.inlineGateField) -}}
{{- range $cfg.vars -}}
{{ .envName }}
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}