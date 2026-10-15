{{/*
SMF user-plane configuration for the ULCL architecture.
*/}}
{{- define "free5gc-smf.ulclConfig" -}}
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
    BranchingUPF:
      type: UPF
      nodeID: {{ if .Values.global.smf.multus.enabled }}{{ .Values.global.upf.multus.iupf1.n4if.ipAddress }}{{ else }}IUPF1_SERVICE_NAME{{ end }}
      sNssaiUpfInfos:
        - sNssai:
            sst: 1
            sd: 010203
          dnnUpfInfoList:
            - dnn: internet
              dnaiList:
                - mec
      interfaces:
        - interfaceType: N3
          endpoints:
            - {{ if .Values.global.smf.multus.enabled }}{{ .Values.global.upf.multus.iupf1.n3if.ipAddress }}{{ else }}IUPF1_SERVICE_NAME{{ end }}
          networkInstances:
            - internet
        - interfaceType: N9
          endpoints:
            - {{ if .Values.global.smf.multus.enabled }}{{ .Values.global.upf.multus.iupf1.n9if.ipAddress }}{{ else }}IUPF1_SERVICE_NAME{{ end }}
          networkInstances:
            - internet
    AnchorUPF1:
      type: UPF
      nodeID: {{ if .Values.global.smf.multus.enabled }}{{ .Values.global.upf.multus.psaupf1.n4if.ipAddress }}{{ else }}PSAUPF1_SERVICE_NAME{{ end }}
      sNssaiUpfInfos:
        - sNssai:
            sst: 1
            sd: 010203
          dnnUpfInfoList:
            - dnn: internet
              pools:
                - cidr: 10.60.0.0/17
      interfaces:
        - interfaceType: N9
          endpoints:
            - {{ if .Values.global.smf.multus.enabled }}{{ .Values.global.upf.multus.psaupf1.n9if.ipAddress }}{{ else }}PSAUPF1_SERVICE_NAME{{ end }}
          networkInstances:
            - internet
    AnchorUPF2:
      type: UPF
      nodeID: {{ if .Values.global.smf.multus.enabled }}{{ .Values.global.upf.multus.psaupf2.n4if.ipAddress }}{{ else }}PSAUPF2_SERVICE_NAME{{ end }}
      sNssaiUpfInfos:
        - sNssai:
            sst: 1
            sd: 010203
          dnnUpfInfoList:
            - dnn: internet
              pools:
                - cidr: 10.60.128.0/17
      interfaces:
        - interfaceType: N9
          endpoints:
            - {{ if .Values.global.smf.multus.enabled }}{{ .Values.global.upf.multus.psaupf2.n9if.ipAddress }}{{ else }}PSAUPF2_SERVICE_NAME{{ end }}
          networkInstances:
            - internet
  links:
    - A: gNB1
      B: BranchingUPF
    - A: BranchingUPF
      B: AnchorUPF1
    - A: BranchingUPF
      B: AnchorUPF2
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
UE routing information for the ULCL architecture.
*/}}
{{- define "free5gc-smf.ulclUeRoutingInfo" -}}
UE1:
  members:
    - imsi-208930000000001
  topology:
    - A: gNB1
      B: BranchingUPF
    - A: BranchingUPF
      B: AnchorUPF1
  specificPath:
    - dest: 1.0.0.1/32
      path: [BranchingUPF, AnchorUPF2]
UE2:
  members:
    - imsi-208930000000004
  topology:
    - A: gNB1
      B: BranchingUPF
    - A: BranchingUPF
      B: AnchorUPF1
  specificPath:
    - dest: 10.100.100.16/32
      path: [BranchingUPF, AnchorUPF2]
{{- end }}
