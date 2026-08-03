{{/*
SMF user-plane configuration for the single-UPF architecture.
*/}}
{{- define "free5gc-smf.singleConfig" -}}
smfName: SMF
snssaiInfos:
  - sNssai:
      sst: 1
      sd: 010203
    dnnInfos:
      - dnn: internet
        dnaiList:
          - mec
        dns:
          ipv4: 8.8.8.8
          ipv6: 2001:4860:4860::8888
plmnList:
  - mcc: "208"
    mnc: "93"
userplaneInformation:
  upNodes:
    gNB1:
      type: AN
    UPF:
      type: UPF
      nodeID: {{ if .Values.global.smf.multus.enabled }}{{ .Values.global.upf.multus.upf.n4if.ipAddress }}{{ else }}UPF_SERVICE_NAME{{ end }}
      sNssaiUpfInfos:
        - sNssai:
            sst: 1
            sd: 010203
          dnnUpfInfoList:
            - dnn: internet
              pools:
                - cidr: {{ .Values.global.uesubnet }}
              dnaiList:
                - mec
      interfaces:
        - interfaceType: N3
          endpoints:
            - {{ if .Values.global.smf.multus.enabled }}{{ .Values.global.upf.multus.upf.n3if.ipAddress }}{{ else }}UPF_SERVICE_NAME{{ end }}
          networkInstances:
            - internet
  links:
    - A: gNB1
      B: UPF
locality: area1
t3591:
  enable: true
  expireTime: 16s
  maxRetryTimes: 3
t3592:
  enable: true
  expireTime: 16s
  maxRetryTimes: 3
{{- end }}

{{/*
UE routing information for the single-UPF architecture.
*/}}
{{- define "free5gc-smf.singleUeRoutingInfo" -}}
UE1:
  members:
    - imsi-208930000000001
  topology:
    - A: gNB1
      B: UPF
{{- end }}
