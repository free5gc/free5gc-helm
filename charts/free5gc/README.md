# free5gc Helm chart

This is a Helm chart for deploying the [free5GC](https://github.com/free5gc/free5gc) on Kubernetes. It can be used to deploy the following Helm charts:
 - [free5gc-amf](./charts/free5gc-amf)
 - [free5gc-ausf](./charts/free5gc-ausf)
 - [free5gc-n3iwf](./charts/free5gc-n3iwf)
 - [free5gc-nrf](./charts/free5gc-nrf)
 - [free5gc-nssf](./charts/free5gc-nssf)
 - [free5gc-pcf](./charts/free5gc-pcf)
 - [free5gc-smf](./charts/free5gc-smf)
 - [free5gc-udm](./charts/free5gc-udm)
 - [free5gc-udr](./charts/free5gc-udr)
 - [free5gc-upf](./charts/free5gc-upf)
 - [free5gc-webui](./charts/free5gc-webui)

## Prerequisites
 - A Kubernetes cluster ready to use with all worker nodes using kernel `5.0.0-23-generic` and they should contain gtp5g kernel module.
 - The AMF NGAP service relies on SCTP which is supported by default in Kubernetes from version [1.20](https://kubernetes.io/docs/setup/release/notes/#feature) onwards. If you are using an older version of Kubernetes please refer to this [link](https://v1-19.docs.kubernetes.io/docs/concepts/services-networking/service/#sctp) to enbale SCTP support.
 - A Persistent Volume Provisioner (optional).
 - [Multus-CNI](https://github.com/intel/multus-cni).
 - [Helm3](https://helm.sh/docs/intro/install/).
 - [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (optional).
 - A physical network interface on each Kubernetes node named `eth0`.
 - A physical network interface on each Kubernetes node named `eth1` to connect the UPF to the Data Network.
**Note:** If the names of network interfaces on your Kubernetes nodes are different from `eth0` and `eth1`, see [Networks configuration](#networks-configuration).

## Quickstart guide

### Verify the kernel version on worker nodes
```console
uname -r
```
It should be `5.0.0-23-generic`.

### Install the gtp5g kernel module on worker nodes
Please follow [free5GC's wiki](https://github.com/free5gc/free5gc/wiki/Installation#c-install-user-plane-function-upf).


### Create a Persistent Volume
If you don't have a Persistent Volume provisioner, you can use the following commands to create a namespace for the project and a [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/) within this namespace that will be consumed by MongoDB by adapting it to your implementation (you have to replace `worker1` by the name of the node and `/home/vagrant/kubedata` by the right directory on this node in which you want to persist the MongoDB data).
```console
kubectl create ns <namespace>
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-local-pv9
  labels:
    project: free5gc
spec:
  capacity:
    storage: 8Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  local:
    path: /home/vagrant/kubedata
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - worker1
EOF
```
**NOTE:** you must create the folder on the right node before creating the Peristent Volume.

### Install free5gc
```console
helm -n <namespace> install <release-name> ./free5gc/
```

### Check the state of the created pod
```console
kubectl -n <namespace> get pods -l "project=free5gc"
```

### Uninstall free5gc
```console
helm -n <namespace> delete <release-name>
```
Or...
```console
helm -n <namespace> uninstall <release-name>
```

## Configuration

### Connection for UERANSIM (Without Multus CNI)

If Multus CNI is not enabled and you need to use UERANSIM for connectivity:

- **Modify `charts/ueransim/values.yaml`:**
    - Update `global.free5gcReleaseName` to match your `helm install` specific **release name**.

### Enable Multus CNI

- Currently, free5gc-helm does not use Multus CNI by default.
- To enable it, follow these steps:
    - **`charts/free5gc/values.yaml`**:
        - Set `global.amf.multus.enabled`, `global.smf.multus.enabled`, and `global.upf.multus.enabled` to `true`.
        - Set `global.amf.service.ngap.enabled` to `false`.
    - **`charts/ueransim/values.yaml`**:
        - Set `global.gnb.multus.enabled` to `true`.

### Multus CNI Configuration

When Multus CNI is enabled, update **`charts/free5gc/values.yaml`** with the following settings:

**1. Network Interface Setup**

- Set the following to your machine's network interface (e.g., `enp0s8`):
    - `global.amf.multus.n2network.masterif`
    - `global.smf.multus.n4network.masterif`
    - `global.upf.multus.n3network.masterif`
    - `global.upf.multus.n4network.masterif`
    - `global.upf.multus.n9network.masterif`
- Set `global.upf.multus.n6network.masterif` to your external interface (e.g., `enp0s3`) for internet access.

**2. External Connectivity Settings (N6 Interface)**

*Note: The following values are examples for external access configuration:*

- **Network:** `subnetIP` (10.0.2.0), `gatewayIP` (10.0.2.2), `excludeIP` (10.0.2.254)
- **IP Assignments:**
    - `upf.n6if`: 10.0.2.11
    - `psaupf1.n6if`: 10.0.2.12
    - `psaupf2.n6if`: 10.0.2.13
    - `iupf1.n6if`: 10.0.2.14

### Enable the single UPF feature

- The default architecture of free5gc-helm is **ULCL**.

To enable a **single UPF**, replace the following files in `charts/free5gc/charts/free5gc-smf/`:

1. `values.yaml`: Replace with `single-upf-values.yaml`.
2. `templates/smf-configmap.yaml`: Replace with `smf-configmap-single-upf.yml`.
3. `charts/free5gc/values.yaml`, set `global.userPlaneArchitecture` to `single`.

### Network isolation on MicroK8s

Security is layered: Calico protects the primary pod interface (`eth0`),
MultiNetworkPolicy protects Multus interfaces, and Istio protects mesh TCP
traffic and authorizes NRF HTTP requests. None of these layers replaces the
others. The policy switches below belong to the **umbrella free5gc chart**;
standalone NF installations must supply their own policies and mesh identities.

| Setting | Default | Effect |
| --- | --- | --- |
| `networkPolicy.enabled` | `false` | Isolate NF ingress and egress on the primary CNI |
| `mongodb.networkPolicy.allowExternal` | `false` | Only release-specific database clients can reach MongoDB |
| `multusNetworkPolicy.enabled` | `false` | RAN-only N2/N3 and SMF/UPF-only N4 |
| `global.istio.enabled` | `false` | Inject all core workloads, enforce strict mTLS, authorize NRF SBI |

MongoDB isolation is enabled by default, independently of the NF policy switch.
NRF, UDR, PCF, CHF, WebUI and dbpython carry the release-specific
`free5gc.io/mongodb-client` label admitted by MongoDB's policy. The unrestricted
Bitnami external-client label is disabled. When upgrading, roll out these
clients before enforcing the MongoDB policy to avoid interrupting old pods.
MongoDB authentication remains a separate concern; this policy is not a
substitute for credentials.

#### 1. Primary interface: Calico

MicroK8s normally uses Calico. Check that it is running and that no alternative
CNI has replaced it:

```console
microk8s kubectl -n kube-system get daemonset calico-node
```

Enable `networkPolicy.enabled: true`. NF pods are selected by the Helm release
label and the presence of the `nf` label, not by namespace alone. They can
communicate with other NFs in the **same release and namespace**, reach MongoDB
on TCP/27017, and resolve DNS through the selected kube-system DNS pods.
MongoDB's separate ingress policy still restricts callers to database clients.
Unrelated pods, including other free5GC releases, are not admitted.

Adapt `networkPolicy.dnsNamespaceSelector` and `dnsPodSelector` if your DNS
deployment does not use `k8s-app: kube-dns`. If NodeLocal DNS is in use, add its
actual IP and TCP/UDP port 53 to `extraEgress`.

Without Multus, explicitly permit the RAN using `networkPolicy.ranPeers`.
For example, an independently installed UERANSIM release in the same namespace:

```yaml
networkPolicy:
  enabled: true
  ranPeers:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: ueransim
          app.kubernetes.io/instance: ran
```

This admits only N2 SCTP/38412 on AMF and N3 UDP/2152 on UPF, not SBI or MongoDB.
For another namespace, put `namespaceSelector` and `podSelector` in the **same
peer**. For an external RAN, use its actual source `ipBlock.cidr`, preferably
`/32`; account for any NodePort SNAT. Validate the source address observed by
Calico rather than allowing all node or pod subnets.

Monitoring, WebUI ingress, external databases and non-Multus N6 access are
denied unless explicitly added through `extraIngress`/`extraEgress` (complete
NetworkPolicy rule lists). Specify both peers and ports. Do not use empty
rules, empty selectors or `0.0.0.0/0` to work around denied traffic. For example,
allow your monitoring chart's exact namespace/pod labels and only the enabled
metrics ports. N6 data-network egress should allow only the required destination
CIDRs, excluding cluster/service/node CIDRs.

Kubernetes policies are additive: another permissive policy selecting these
pods can reopen access. Policies do not isolate traffic from the local node,
privileged/host-network workloads, or users who can create pods with trusted
labels or ServiceAccounts. Use RBAC and workload admission controls as well.

#### 2. Multus: RAN-only N2/N3 and SMF/UPF-only N4

Calico NetworkPolicy does **not** protect Multus attachments. Install the
MultiNetworkPolicy CRD and an enforcing agent on every relevant node, following
the [openshift/multus-networkpolicy guide](https://github.com/openshift/multus-networkpolicy/blob/main/README.md).
Creating the CRD alone does not enforce anything.

For the current nftables implementation:

- Load `nf_tables` on each node.
- Configure the agent to accept the chart's `ipvlan` networks (the documented
  plugin default is `macvlan`; include every plugin actually used).
- Configure its CRI endpoint for MicroK8s, normally
  `/var/snap/microk8s/common/run/containerd.sock`, including the required host
  socket mounts.
- Use a reviewed, pinned production image/manifest. Do not apply an upstream
  development/e2e manifest containing localhost images, a CRI-O socket or
  unconditional custom allow rules.
- Confirm your chosen implementation enforces **SCTP** as well as UDP. The
  current nftables implementation supports SCTP; do not assume this of older
  iptables implementations. Leave blanket ICMP bypass flags disabled unless
  you intentionally need them.

After enabling the AMF/SMF/UPF Multus settings described above:

```yaml
multusNetworkPolicy:
  enabled: true
  ranCIDRs:
    - 10.100.50.235/32 # Replace with the actual gNB N2/N3 interface addresses
```

List every trusted RAN secondary address (including N3IWF if used); do not list
the entire N2/N3 subnet. Empty RAN lists fail rendering when N2/N3 policies are
needed. N2 admits SCTP to the configured NGAP port and SCTP back to the RAN
(its source port may be ephemeral); N3 admits UDP/2152 in both directions.

N4 admits UDP/8805 **only** between the configured SMF N4 `/32` and the active
UPF N4 `/32` addresses: `upf` in single mode, or `iupf1`, `psaupf1`, `psaupf2`
in ULCL mode. Both SMF and UPF must have Multus N4 enabled. Each policy's
`policy-for` annotation refers to the chart's actual, release-qualified NAD.
Exact IP peers avoid relying on pod-selector resolution across the separate
SMF and UPF NADs. Update addresses together with the network configuration;
these are L3 allowlists, not authenticated identities or anti-spoofing.

N6 and N9 are deliberately outside these policies: N9 must retain ULCL
UPF-to-UPF traffic, and N6 requires a deployment-specific data-network policy.
The chart does not install policies on the RAN's separate NADs. Enforce
corresponding RAN-side policies if you also need to isolate the RAN itself.

#### 3. Istio: strict mTLS and NRF SBI authorization

MicroK8s exposes Istio through its community addon:

```console
microk8s enable community
microk8s enable istio
microk8s kubectl -n istio-system get pods
```

**Check the installed Istio version before enabling chart mesh settings.**
Some community-addon revisions still install Istio **1.18.2**, which is
unsupported and lacks the native-sidecar support required here. Do not use
that version for this configuration. If your addon is outdated, disable it
and install a supported, pinned upstream version instead, following the
[Istio Helm installation guide](https://istio.io/latest/docs/setup/install/helm/)
and its Kubernetes compatibility matrix. Do not install two control planes
over the same namespace.

This configuration requires Kubernetes native sidecars (enabled by default
from Kubernetes 1.29) and a compatible Istio injector that supports
`sidecar.istio.io/nativeSidecar`. Check **all worker versions**, not just the
API server. The restartable `istio-proxy` init container must start **before**
`wait-nrf`/`wait-mongo`: a conventional sidecar starts too late and these
startup checks deadlock against strict mTLS. `holdApplicationUntilProxyStarts`
alone does not solve init-container ordering.

Enable both primary-interface policies and mesh integration:

```yaml
networkPolicy:
  enabled: true
  istiodNamespaceSelector:
    matchLabels:
      kubernetes.io/metadata.name: istio-system
  istiodPodSelector:
    matchLabels:
      app: istiod
global:
  sbi:
    scheme: http
  istio:
    enabled: true
```

Adjust the istiod selectors to the actual addon installation. Explicit
TCP/15012 and TCP/15017 egress permits proxy configuration/certificate
bootstrap, including the otherwise egress-isolated MongoDB pod. Ensure any
policies on istiod itself also admit these clients.

The chart requests injection on every NF, all active UPFs, WebUI, dbpython and
MongoDB. It creates separate NF ServiceAccounts, applies release-scoped
`PeerAuthentication` in `STRICT` mode, and relies on Istio auto-mTLS for
service-to-service traffic. No namespace-wide policy affects unrelated pods.
If MongoDB is external, mesh and configure that server separately; the chart
cannot secure an external database automatically.

NRF's `AuthorizationPolicy` admits only the deployed control-plane NF
ServiceAccount principals in this release/namespace, the configured SBI port,
and the HTTP methods/paths in `istio.nrfAuthorization`. WebUI, dbpython, UPF
and arbitrary/default ServiceAccounts cannot call NRF SBI. `GET /` remains
allowed for existing NF startup checks; management/discovery v1 paths and the
OAuth token endpoint are allowed by default. Non-SBI NRF ports remain governed
by mTLS and the primary-interface policy, not this HTTP API allowlist.
Set `istio.trustDomain` if your mesh does not use `cluster.local`.

Keep application SBI on **HTTP**: Istio provides transport encryption with
mTLS. Application-level HTTPS hides HTTP methods/paths from Envoy, so enabling
it with this L7 policy is rejected. Use Service DNS addresses, not arbitrary
direct pod-IP connections. Do not add `DISABLE` DestinationRules or port-level
plaintext exemptions. Multus interfaces are excluded from sidecar capture;
UDP/SCTP N2/N3/N4 are **not** encrypted by Istio mTLS.

On an existing release, use a maintenance window for the coordinated injection
and strict-policy rollout; old non-meshed pods cannot reach strict destinations.
Wait for every Deployment and the MongoDB StatefulSet to finish rolling out.
Inspect admitted pods to confirm `istio-proxy` is a restartable init container
and injection has not been skipped. Merely creating PeerAuthentication without
an injected proxy does not enforce mTLS.

#### 4. Verify enforcement (not just rendered resources)

```console
microk8s kubectl -n <namespace> get networkpolicy
microk8s kubectl -n <namespace> get multinetworkpolicy
microk8s kubectl -n <namespace> get peerauthentication,authorizationpolicy
microk8s kubectl -n <namespace> get pods --show-labels
```

Verify these positive and negative cases on the target cluster:

- All NFs complete startup, resolve DNS and register/discover through NRF;
  the six database clients can reach MongoDB.
- An unrelated pod in both the same and another namespace cannot reach SBI,
  PFCP or MongoDB through the primary interface.
- The allowed gNB establishes NGAP and GTP-U; an unlisted secondary IP cannot.
  Only SMF/active UPF N4 pairs establish PFCP. Use real SCTP/PFCP/GTP-U sessions
  and inspect agent rules/counters; UDP `nc` alone cannot prove enforcement.
- From an authorized meshed NF identity, permitted NRF requests succeed and a
  request outside the configured method/path allowlist returns Envoy HTTP 403.
  A meshed but unauthorized identity admitted by the L3 test policy also gets
  403. Remove any temporary test policy immediately afterward.
- A plaintext client cannot communicate with a strict-mTLS core TCP endpoint.
  Use Istio proxy configuration/telemetry to confirm successful NF and
  database traffic uses mTLS; an L3 timeout alone does not prove mesh rejection.

Helm lint/template checks cannot verify Calico, secondary-interface firewall
rules, admission-webhook ordering or mesh encryption; these cluster checks
are required before treating the deployment as isolated.

### Enable the Prometheus and Grafana
To start Prometheus and Grafana, run the following commands to install Prometheus and Grafana using the kube-prometheus-stack chart.
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack -n <namespace>
```

In values.yaml, set metrics.enable to true for each NF you want to monitor.

Next, create a PodMonitor to tell Prometheus how to find and scrape the free5GC pods. (The namespace in prometheus.yaml must same as your free5GC deployment, default is free5gc)
```
cd ~/free5gc-helm/charts/free5gc
kubectl apply -f prometheus.yaml
```

Now you can access the prometheus and grafana by port forwarding, for example
```
kubectl port-forward --address 0.0.0.0 prometheus-prometheus-kube-prometheus-prometheus-0 9090:9090 -n <namespace>
kubectl port-forward --address 0.0.0.0 <grafana_pod_name> 3000:3000 -n <namespace>
```
default Grafana login info : admin / prom-operator

### Networks configuration

In this section, we'll suppose that you have only one interface on each Kubernetes node and its name is `toto`. Then you have to set these parameters to `toto`:
 - `global.n2network.masterIf`
 - `global.n3network.masterIf`
 - `global.n4network.masterIf`
 - `global.n6network.masterIf`
 - `global.n9network.masterIf`

In addition, please make sure `global.n6network.subnetIP`, `global.n6network.gatewayIP` and `free5gc-upf.upf.n6if.ipAddress` parameters will match the IP address of the `toto` interface in order to make the UPF able to reach the Data Network via its N6 interface.

In case of ULCL enabled take care about `free5gc-upf.iupf1.n6if.ipAddress`, `free5gc-upf.psaupf1.n6if.ipAddress` and `free5gc-upf.psaupf2.n6if.ipAddress` instead of `free5gc-upf.upf.n6if.ipAddress`.

## Customized installation
This chart allows you to customize its installation. The table below shows the parameters that can be modified before installing the chart or when upgrading it as well as their default values.

### Main chart parameters
| Parameter | Description | Default value |
| --- | --- | --- |
| `deployMongoDB` | If `true` then the MongoDB subchart will be installed. | `true` |
| `deploy<NFName in capital letters>` | If `true` then the `<NFName>` subchart will be installed. `<NFName>` must be one of the following: AMF, AUSF, N3IWF, NRF, NSSF, PCF, SMF, UDM, UDR, UPF, WEBUI. | `see values.yaml` |

### Global and subcharts' parameters
Please check this [link](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/) to see how to customize global and subcharts' parameters.

| Parameter | Description | Default value |
| --- | --- | --- |
| `global.projectName` | The name of the project. | `free5gc` |
| `global.userPlaneArchitecture` | User plane topology. Possible values are `single` and `ulcl` | `single` |
| `global.sbi.scheme` | The SBI scheme for all control plane NFs. Possible values are `http` and `https` | `http` |
| `global.nrf.service.name` | The name of the service used to expose the NRF SBI interface. | `nrf-nnrf` |
| `global.nrf.service.type` | The type of the NRF SBI service. | `NodePort` |
| `global.nrf.service.port` | The NRF SBI port number. | `8000` |
| `global.nrf.service.port` | The NRF SBI service nodePort number. | `30800` |
| `global.smf.n4if.ipAddress` | The IP address of the SMF’s N4 interface. | `10.100.50.249` |
| `global.amf.n2if.ipAddress` | The IP address of the AMF’s N2 interface. | `10.100.50.249` |
| `global.amf.service.ngap.enabled` | If `true` then a Kubernetes service will be used to expose the AMF NGAP service. | `false` |
| `global.amf.service.ngap.name` | The name of the AMF NGAP service. | `amf-n2` |
| `global.amf.service.ngap.type` | The type of the AMF NGAP service. | `NodePort` |
| `global.amf.service.ngap.port` | The AMF NGAP port number. | `38412` |
| `global.amf.service.ngap.nodeport` | The nodePort number to access the AMF NGAP service from outside of cluster. | `31412` |
| `global.amf.service.ngap.protocol` | The protocol used for this service. | `SCTP` |

### N2 Network parameters
| Parameter | Description | Default value |
| --- | --- | --- |
| `global.n2network.enabled` | If `true` then N2-related Network Attachment Definitions resources will be created. | `true` |
| `global.n2network.name` | N2 network name. | `n2network` |
| `global.n2network.masterIf` | N2 network MACVLAN master interface. | `eth0` |
| `global.n2network.subnetIP` | N2 network subnet IP address. | `10.100.50.248` |
| `global.n2network.cidr` | N2 network cidr. | `29` |
| `global.n2network.gatewayIP` | N2 network gateway IP address. | `10.100.50.254` |

### N3 Network parameters
| Parameter | Description | Default value |
| --- | --- | --- |
| `global.n3network.enabled` | If `true` then N3-related Network Attachment Definitions resources will be created. | `true` |
| `global.n3network.name` | N3 network name. | `n3network` |
| `global.n3network.masterIf` | N3 network MACVLAN master interface. | `eth0` |
| `global.n3network.subnetIP` | N3 network subnet IP address. | `10.100.50.232` |
| `global.n3network.cidr` | N3 network cidr. | `29` |
| `global.n3network.gatewayIP` | N3 network gateway IP address. | `10.100.50.238` |

### N4 Network parameters
| Parameter | Description | Default value |
| --- | --- | --- |
| `global.n4network.enabled` | If `true` then N4-related Network Attachment Definitions resources will be created. | `true` |
| `global.n4network.name` | N4 network name. | `n4network` |
| `global.n4network.masterIf` | N4 network MACVLAN master interface. | `eth0` |
| `global.n4network.subnetIP` | N4 network subnet IP address. | `10.100.50.240` |
| `global.n4network.cidr` | N4 network cidr. | `29` |
| `global.n4network.gatewayIP` | N4 network gateway IP address. | `10.100.50.246` |

### N6 Network parameters
| Parameter | Description | Default value |
| --- | --- | --- |
| `global.n6network.enabled` | If `true` then N6-related Network Attachment Definitions resources will be created. | `true` |
| `global.n6network.name` | N6 network name. | `n6network` |
| `global.n6network.masterIf` | N6 network MACVLAN master interface. The IP address of this interface must be in the N6 network subnet IP rang. | `eth1` |
| `global.n6network.subnetIP` | N6 network subnet IP address (The IP address of the Data Network. | `10.100.100.0` |
| `global.n6network.cidr` | N6 network cidr. | `24` |
| `global.n6network.gatewayIP` | N6 network gateway IP address (The IP address to go to the Data Network). | `10.100.100.1` |

### N9 Network parameters
These parameters if `global.userPlaneArchitecture` is set to `ulcl`.

| Parameter | Description | Default value |
| --- | --- | --- |
These parameters if `global.userPlaneArchitecture` is set to `ulcl`.
| `global.n9network.enabled` | If `true` then N9-related Network Attachment Definitions resources will be created. | `true` |
| `global.n9network.name` | N9 network name. | `n9network` |
| `global.n9network.masterIf` | N9 network MACVLAN master interface. The IP address of this interface must be in the N9 network subnet IP rang. | `eth0` |
| `global.n9network.subnetIP` | N9 network subnet IP address (The IP address of the Data Network. | `10.100.50.224` |
| `global.n9network.cidr` | N9 network cidr. | `29` |
| `global.n9network.gatewayIP` | N9 network gateway IP address (The IP address to go to the Data Network). | `10.100.50.230` |

## Reference
 - https://github.com/free5gc/free5gc
 - https://github.com/free5gc/free5gc-compose
