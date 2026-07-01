{{- define "common.dockerCredentials" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.global.images.dockerCredentials.registry (printf "%s:%s" .Values.global.images.dockerCredentials.username .Values.global.images.dockerCredentials.password | b64enc) | b64enc }}
{{- end }}