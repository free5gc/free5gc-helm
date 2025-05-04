# LoxiLB Helm Chart

This Helm chart deploys LoxiLB, an open-source, eBPF-based load balancer for NGAP Layer 7 load balancing within 5G networks.

based on https://goldenrod-town-d4b.notion.site/Install-free5gc-with-LoxiLB-NGAP-load-balancing-1ad453c1718680019cdfc94709fd6f48
## Features

- NGAP Layer 7 load balancing
- UE distribution across stateless AMFs
- Seamless handovers across multiple AMFs
- High availability with automatic failover
- Support for Free5GC integration

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Multus CNI for multi-network interfaces

## Installation

```bash
# Add the chart repository (replace with your actual repository)
helm repo add loxilb-repo https://example.com/helm-charts/

# Update helm repositories
helm repo update

# Install the chart with the release name 'loxilb'
helm install loxilb loxilb-repo/loxilb -n free5gc
```

Or to install from local directory:

```bash
# Navigate to the chart directory
cd loxilb

# Install the chart
helm install loxilb . -n free5gc
```

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | LoxiLB image repository | `ghcr.io/loxilb-io/loxilb` |
| `image.tag` | LoxiLB image tag | `scp2` |
| `image.pullPolicy` | Image pull policy | `Always` |
| `network.n2network.name` | Name of N2 network | `n2network-free5gc-helm-free5gc-amf` |
| `network.n2network.interface` | Interface name for N2 network | `n2` |
| `network.n2network.ips` | IPs for N2 network | `["10.100.50.253/29"]` |
| `network.n2network.gateway` | Gateway for N2 network | `["10.100.50.254"]` |
| `kubeLoxilb.enabled` | Whether to deploy kube-loxilb | `true` |
| `kubeLoxilb.args` | Args for kube-loxilb | See values.yaml |

For more configuration options, see the [values.yaml](values.yaml) file.

## Use with Free5GC

LoxiLB works as a load balancer in front of multiple AMFs in a Free5GC deployment to ensure high availability and seamless failover for NGAP connections from gNB. To use with Free5GC:

1. Deploy Free5GC with AMF service type set to LoadBalancer
2. Add the appropriate annotations to the AMF service
3. Deploy LoxiLB using this chart
4. Configure gNB (UERANSIM) to use LoxiLB's external IP

See the [Free5GC integration guide](https://www.loxilb.io/post/ngap-load-balancing-with-loxilb) for detailed instructions.

## License

Apache License 2.0
