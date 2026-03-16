import SwiftUI

@Observable
class K8sViewModel {
    var resourceType: K8sService.ResourceType = .deployment
    var name: String = "my-app"
    var namespace: String = "default"
    var image: String = "nginx:1.25"
    var replicas: String = "3"
    var containerPort: String = "8080"
    var cpuReq: String = "100m"
    var memReq: String = "128Mi"
    var cpuLim: String = "500m"
    var memLim: String = "512Mi"
    var healthPath: String = "/healthz"
    var serviceType: K8sService.ServiceType = .clusterIP
    var servicePort: String = "80"
    var host: String = "app.example.com"
    var ingressPath: String = "/"
    var tlsEnabled: Bool = false
    var tlsSecret: String = ""
    var schedule: String = "0 */6 * * *"
    var command: String = ""
    var pvcSize: String = "10Gi"
    var storageClass: String = "standard"
    var minReplicas: String = "2"
    var maxReplicas: String = "10"
    var cpuTarget: String = "70"
    var envVars: [(key: String, value: String)] = []
    var configData: [(key: String, value: String)] = []
    var newKey: String = ""
    var newValue: String = ""
    var output: String = ""

    func generate() {
        switch resourceType {
        case .deployment:
            output = K8sService.generateDeployment(
                name: name, namespace: namespace, image: image,
                replicas: Int(replicas) ?? 3, containerPort: Int(containerPort) ?? 8080,
                cpuReq: cpuReq, memReq: memReq, cpuLim: cpuLim, memLim: memLim,
                healthPath: healthPath, envVars: envVars.map { ($0.key, $0.value) }
            )
        case .service:
            output = K8sService.generateService(
                name: name, namespace: namespace, type: serviceType,
                port: Int(servicePort) ?? 80, targetPort: Int(containerPort) ?? 8080
            )
        case .ingress:
            output = K8sService.generateIngress(
                name: name, namespace: namespace, host: host, path: ingressPath,
                serviceName: name, servicePort: Int(servicePort) ?? 80,
                tlsEnabled: tlsEnabled, tlsSecret: tlsSecret
            )
        case .configMap:
            output = K8sService.generateConfigMap(name: name, namespace: namespace, data: configData.map { ($0.key, $0.value) })
        case .secret:
            output = K8sService.generateSecret(name: name, namespace: namespace, data: configData.map { ($0.key, $0.value) })
        case .cronJob:
            let cmds = command.isEmpty ? [] : command.components(separatedBy: " ")
            output = K8sService.generateCronJob(name: name, namespace: namespace, image: image, schedule: schedule, command: cmds)
        case .pvc:
            output = K8sService.generatePVC(name: name, namespace: namespace, size: pvcSize, storageClass: storageClass)
        case .hpa:
            output = K8sService.generateHPA(
                name: name, namespace: namespace, targetRef: name,
                minReplicas: Int(minReplicas) ?? 2, maxReplicas: Int(maxReplicas) ?? 10,
                cpuTarget: Int(cpuTarget) ?? 70
            )
        }
    }

    func generateFullStack() {
        output = K8sService.generateFullStack(
            name: name, image: image,
            port: Int(containerPort) ?? 8080,
            replicas: Int(replicas) ?? 3, host: host
        )
    }

    func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }

    func addKeyValue() {
        let k = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else { return }
        configData.append((key: k, value: newValue))
        newKey = ""
        newValue = ""
    }

    func removeKeyValue(at index: Int) {
        guard configData.indices.contains(index) else { return }
        configData.remove(at: index)
    }

    func addEnvVar() {
        let k = newKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !k.isEmpty else { return }
        envVars.append((key: k, value: newValue))
        newKey = ""
        newValue = ""
    }

    func removeEnvVar(at index: Int) {
        guard envVars.indices.contains(index) else { return }
        envVars.remove(at: index)
    }
}
