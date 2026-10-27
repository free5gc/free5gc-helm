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

### Access the WebUI

#### Option 1: ClusterIP (default)

The WebUI service uses `ClusterIP` by default. Install the free5gc chart without overriding the service type:

```console
helm -n <namespace> install <release-name> ./free5gc/
```

If an existing release uses `NodePort`, switch it back to `ClusterIP` while retaining its other values:

```console
helm -n <namespace> upgrade <release-name> ./free5gc/ \
  --reuse-values \
  --set free5gc-webui.webui.service.type=ClusterIP
```

To access the WebUI locally, start port-forwarding in a separate terminal:

```console
kubectl -n <namespace> port-forward svc/webui-service 5000:5000
```

Open http://127.0.0.1:5000 while port-forward is running.

#### Option 2: NodePort

To access the WebUI through a Kubernetes node's IP address, enable `NodePort` when installing the free5gc chart:

```console
helm -n <namespace> install <release-name> ./free5gc/ \
  --set free5gc-webui.webui.service.type=NodePort
```

For an existing release, upgrade it while retaining its current values:

```console
helm -n <namespace> upgrade <release-name> ./free5gc/ \
  --reuse-values \
  --set free5gc-webui.webui.service.type=NodePort
```

Open `http://<node-ip>:30500`, replacing `<node-ip>` with a reachable IP address of one of your Kubernetes nodes. The default node port is `30500`; make sure it is reachable from your browser. Port-forwarding is not required for this option.

### Uninstall free5gc
```console
helm -n <namespace> delete <release-name>
```
Or...
```console
helm -n <namespace> uninstall <release-name>
```

## Configuration

### Service exposure with ClusterIP

The WebUI and AMF N2 (NGAP) services use `ClusterIP` by default.

Install the free5gc chart without overriding the service types:

```console
helm -n <namespace> install <release-name> ./free5gc/
```

If an existing release uses `NodePort`, switch both services back to `ClusterIP` while retaining its other values:

```console
helm -n <namespace> upgrade <release-name> ./free5gc/ \
  --reuse-values \
  --set free5gc-webui.webui.service.type=ClusterIP \
  --set global.amf.service.ngap.type=ClusterIP
```

### Service exposure with NodePort

To expose either service through a node port, add the corresponding option to your Helm install or upgrade command for the free5gc chart:

- WebUI: `--set free5gc-webui.webui.service.type=NodePort`
  Then access `http://<node-ip>:30500`.
- AMF N2: `--set global.amf.service.ngap.type=NodePort`
  Then configure your external gNB to connect to `<node-ip>:31412` using SCTP.

The configured node ports default to `30500` for WebUI and `31412` for AMF N2. They are rendered only for `NodePort` or `LoadBalancer` services when the configured value is nonzero. Set the corresponding value to `0` to let Kubernetes allocate the node port automatically:

- WebUI: `free5gc-webui.webui.service.nodePort`
- AMF N2: `global.amf.service.ngap.nodeport`

For an existing `NodePort` service, Kubernetes may retain its allocated node port when the configured value is set to `0`; this does not force a new allocation. Use `kubectl -n <namespace> get svc` to check the actual assigned ports.

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
| `global.amf.service.ngap.enabled` | If `true` then a Kubernetes service will be used to expose the AMF NGAP service. | `true` |
| `global.amf.service.ngap.name` | The name of the AMF NGAP service. | `amf-n2` |
| `global.amf.service.ngap.type` | The type of the AMF NGAP service. | `ClusterIP` |
| `global.amf.service.ngap.port` | The AMF NGAP port number. | `38412` |
| `global.amf.service.ngap.nodeport` | The nodePort number to access the AMF NGAP service from outside the cluster. Used only for `NodePort` or `LoadBalancer`; set `0` for automatic allocation. | `31412` |
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
