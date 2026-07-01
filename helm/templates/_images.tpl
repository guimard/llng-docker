{{/*
Return the proper Docker Image
*/}}
{{- define "lemonldap.portal.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.portal.image ) }}
{{- end -}}

{{- define "lemonldap.manager.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.manager.image ) }}
{{- end -}}

{{- define "lemonldap.cronjob.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.cronjob.image ) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "lemonldap.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.image) "global" .Values.global) }}
{{- end -}}