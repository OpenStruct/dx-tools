---
name: dx-k8s-generator
description: Build the Kubernetes YAML Generator tool for DX Tools. Generates k8s manifests for deployments, services, ingress, configmaps, secrets, jobs, cronjobs, PVCs, and HPA. Follow dx-tools-feature skill for architecture.
---

# Kubernetes YAML Generator

Read the [dx-tools-feature skill](../dx-tools-feature/SKILL.md) first for architecture and UI standards.

## Tool Definition

- **Enum case**: `k8sGenerator`
- **Category**: `.devops`
- **Display name**: "K8s YAML"
- **Icon**: `"square.3.layers.3d"`
- **Description**: "Generate Kubernetes manifests — Deployments, Services, Ingress, ConfigMaps, Jobs"

## Service: `K8sService.swift`

### Resource Types

```swift
enum ResourceType: String, CaseIterable {
    case deployment = "Deployment"
    case service = "Service"
    case ingress = "Ingress"
    case configMap = "ConfigMap"
    case secret = "Secret"
    case job = "Job"
    case cronJob = "CronJob"
    case pvc = "PersistentVolumeClaim"
    case hpa = "HorizontalPodAutoscaler"
    case namespace = "Namespace"
}
```

### Config Models

```swift
struct DeploymentConfig {
    var name: String              // e.g. "api-server"
    var namespace: String         // e.g. "default"
    var image: String             // e.g. "nginx:1.25"
    var replicas: Int             // e.g. 3
    var containerPort: Int        // e.g. 8080
    var cpuRequest: String        // e.g. "100m"
    var memoryRequest: String     // e.g. "128Mi"
    var cpuLimit: String          // e.g. "500m"
    var memoryLimit: String       // e.g. "512Mi"
    var envVars: [(key: String, value: String)]
    var labels: [(key: String, value: String)]
    var healthCheckPath: String   // e.g. "/healthz"
    var strategy: RolloutStrategy // .rollingUpdate, .recreate
}

struct ServiceConfig {
    var name: String
    var namespace: String
    var type: ServiceType         // .clusterIP, .nodePort, .loadBalancer
    var port: Int
    var targetPort: Int
    var selector: [(key: String, value: String)]
}

struct IngressConfig {
    var name: String
    var namespace: String
    var host: String              // e.g. "api.example.com"
    var path: String              // e.g. "/"
    var serviceName: String
    var servicePort: Int
    var tlsEnabled: Bool
    var tlsSecretName: String
    var ingressClass: String      // e.g. "nginx"
}
```

### Generation Methods

```swift
static func generateDeployment(_ config: DeploymentConfig) -> String
static func generateService(_ config: ServiceConfig) -> String
static func generateIngress(_ config: IngressConfig) -> String
static func generateConfigMap(name: String, namespace: String, data: [(key: String, value: String)]) -> String
static func generateSecret(name: String, namespace: String, data: [(key: String, value: String)]) -> String
static func generateJob(name: String, namespace: String, image: String, command: [String]) -> String
static func generateCronJob(name: String, namespace: String, image: String, schedule: String, command: [String]) -> String
static func generatePVC(name: String, namespace: String, size: String, storageClass: String, accessMode: String) -> String
static func generateHPA(name: String, namespace: String, targetRef: String, minReplicas: Int, maxReplicas: Int, cpuTarget: Int) -> String
static func generateFullStack(name: String, image: String, port: Int, replicas: Int, host: String) -> String // Deployment + Service + Ingress combined
```

All YAML output must use proper indentation (2 spaces), include `apiVersion`, `kind`, `metadata`, and `spec` sections. Use `---` separator for multi-document output.

### Validation

```swift
static func validate(_ yaml: String) -> [String]  // Check required fields, indentation, known issues
```

## View: `K8sView.swift`

### Layout

**ToolHeader**: Resource type picker (`ThemedPicker`) + "Generate" button + "Full Stack" preset button

**HSplitView:**

**Left panel — Form:**
- Dynamic form based on selected resource type
- Common fields: name, namespace, labels (add/remove key-value rows)
- Deployment: image, replicas, ports, resource limits, health check, env vars
- Service: type picker, port, targetPort, selector
- Ingress: host, path, service ref, TLS toggle
- ConfigMap/Secret: key-value editor (add/remove rows)
- Job/CronJob: image, command, schedule (CronJob only — can link to Cron Parser tool)
- Use themed form styling: `t.surface` backgrounds, `t.border` borders, `t.editorBg` for fields

**Right panel — YAML output:**
- `CodeEditor` (read-only, language "yaml")
- Copy button, Save button
- Validation warnings strip at bottom

### Quick Presets

- **Full Stack**: Generates Deployment + Service + Ingress combined (separated by `---`)
- **Redis**: Pre-filled Redis deployment + service
- **PostgreSQL**: Pre-filled Postgres with PVC

## Tests: `K8sServiceTests.swift`

- `testDeploymentGeneration` — correct apiVersion, kind, replicas, image, container port
- `testServiceClusterIP` — type: ClusterIP, correct ports
- `testServiceLoadBalancer` — type: LoadBalancer
- `testIngressWithTLS` — tls block present, secretName
- `testIngressWithoutTLS` — no tls block
- `testConfigMap` — data section with key-value pairs
- `testSecretBase64` — values are base64 encoded
- `testCronJobSchedule` — schedule field present
- `testHPA` — minReplicas, maxReplicas, targetCPU
- `testFullStack` — contains `---` separator, all 3 resources
- `testEmptyName` — handles gracefully
- `testResourceLimits` — requests and limits present in deployment
