{{/* vim: set filetype=mustache: */}}
{{/*
Init container to process git-sync
*/}}

{{- define "common.gitSync.init" -}}
- name: {{ .Release.Name }}-gitsync
  image: registry.k8s.io/git-sync/git-sync:{{ .Values.gitSync.image.tag }}
  imagePullPolicy: {{ .Values.gitSync.image.pullPolicy }}
  env:
    - name: GIT_SYNC_REPO
      value: {{ .Values.gitSync.repo | quote }}
    - name: GIT_SYNC_USERNAME
      value: {{ .Values.gitSync.username | quote }}
    - name: GIT_SYNC_BRANCH
      value: {{ .Values.gitSync.branch | quote }}
    - name: GIT_SYNC_PASSWORD_FILE
      value: {{ printf "%s/%s" .Values.gitSync.secretMounthPath .Values.gitSync.secretName | quote }}
    - name: GIT_SYNC_ROOT
      value: {{ .Values.gitSync.syncRoot | quote }}
    {{- if .Values.gitSync.syncDest }}
    - name: GIT_SYNC_DEST
      value: {{ .Values.gitSync.syncDest | quote }}
    {{- end }}
    {{- if .Values.gitSync.sparseCheckOut }}
    - name: GIT_SYNC_SPARSE_CHECKOUT_FILE
      value: "/config/gitsync/.sparsecheckout-dashboards"
    {{- end }}      
  volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: secrets
      mountPath: {{ .Values.gitSync.secretMounthPath }}
    - name: gitsync
      mountPath: {{ .Values.gitSync.syncRoot }}
  resources:
    {{- toYaml .Values.gitSync.resources | nindent 4 }}
  securityContext:
    {{- toYaml .Values.gitSync.securityContext | nindent 4}}
{{- end -}}

{{/*
Running sidecar container for git-sync
*/}}
{{- define "common.gitSync.sidecar" -}}
- name: {{ .Release.Name }}-gitsync
  image: registry.k8s.io/git-sync/git-sync:{{ .Values.gitSync.image.tag }}
  imagePullPolicy: {{ .Values.gitSync.image.pullPolicy }}
  env:
    - name: GIT_SYNC_REPO
      value: {{ .Values.gitSync.repo | quote }}
    - name: GIT_SYNC_USERNAME
      value: {{ .Values.gitSync.username | quote }}
    - name: GIT_SYNC_BRANCH
      value: {{ .Values.gitSync.branch | quote }}
    - name: GIT_SYNC_WAIT
      value: "300"
    - name: GIT_SYNC_PASSWORD_FILE
      value: {{ printf "%s/%s" .Values.gitSync.secretMounthPath .Values.gitSync.secretName | quote }}
    - name: GIT_SYNC_ROOT
      value: {{ .Values.gitSync.syncRoot | quote }}
    - name: GIT_SYNC_HTTP_BIND
      value: ":8888"
    {{- if .Values.gitSync.syncDest }}
    - name: GIT_SYNC_DEST
      value: {{ .Values.gitSync.syncDest | quote }}
    {{- end }}
    {{- if .Values.gitSync.sparseCheckOut }}
    - name: GIT_SYNC_SPARSE_CHECKOUT_FILE
      value: "/config/gitsync/.sparsecheckout-dashboards"
    {{- end }}
  livenessProbe:
    httpGet:
      path: /
      port: 8888
  readinessProbe:
    httpGet:
      path: /
      port: 8888
  volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: secrets
      mountPath: {{ .Values.gitSync.secretMounthPath }}
    - name: gitsync
      mountPath: {{ .Values.gitSync.syncRoot }}
  resources:
    {{- toYaml .Values.gitSync.resources | nindent 4 }}
  securityContext:
    {{- toYaml .Values.gitSync.securityContext | nindent 4}}
{{- end -}}