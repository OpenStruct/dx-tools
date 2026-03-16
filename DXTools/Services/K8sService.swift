import Foundation

struct K8sService {
    enum ResourceType: String, CaseIterable {
        case deployment = "Deployment"
        case service = "Service"
        case ingress = "Ingress"
        case configMap = "ConfigMap"
        case secret = "Secret"
        case cronJob = "CronJob"
        case pvc = "PVC"
        case hpa = "HPA"
    }

    // MARK: - Deployment

    static func generateDeployment(
        name: String, namespace: String = "default", image: String,
        replicas: Int = 3, containerPort: Int = 8080,
        cpuReq: String = "100m", memReq: String = "128Mi",
        cpuLim: String = "500m", memLim: String = "512Mi",
        healthPath: String = "/healthz",
        envVars: [(String, String)] = []
    ) -> String {
        var y = """
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: \(name)
          namespace: \(namespace)
          labels:
            app: \(name)
        spec:
          replicas: \(replicas)
          selector:
            matchLabels:
              app: \(name)
          strategy:
            type: RollingUpdate
            rollingUpdate:
              maxSurge: 1
              maxUnavailable: 0
          template:
            metadata:
              labels:
                app: \(name)
            spec:
              containers:
                - name: \(name)
                  image: \(image)
                  ports:
                    - containerPort: \(containerPort)
                  resources:
                    requests:
                      cpu: \(cpuReq)
                      memory: \(memReq)
                    limits:
                      cpu: \(cpuLim)
                      memory: \(memLim)
                  livenessProbe:
                    httpGet:
                      path: \(healthPath)
                      port: \(containerPort)
                    initialDelaySeconds: 15
                    periodSeconds: 10
                  readinessProbe:
                    httpGet:
                      path: \(healthPath)
                      port: \(containerPort)
                    initialDelaySeconds: 5
                    periodSeconds: 5
        """
        if !envVars.isEmpty {
            y += "\n              env:"
            for (k, v) in envVars {
                y += "\n                - name: \(k)\n                  value: \"\(v)\""
            }
        }
        return dedent(y)
    }

    // MARK: - Service

    enum ServiceType: String, CaseIterable {
        case clusterIP = "ClusterIP"
        case nodePort = "NodePort"
        case loadBalancer = "LoadBalancer"
    }

    static func generateService(
        name: String, namespace: String = "default",
        type: ServiceType = .clusterIP,
        port: Int = 80, targetPort: Int = 8080
    ) -> String {
        return dedent("""
        apiVersion: v1
        kind: Service
        metadata:
          name: \(name)
          namespace: \(namespace)
          labels:
            app: \(name)
        spec:
          type: \(type.rawValue)
          selector:
            app: \(name)
          ports:
            - port: \(port)
              targetPort: \(targetPort)
              protocol: TCP
        """)
    }

    // MARK: - Ingress

    static func generateIngress(
        name: String, namespace: String = "default",
        host: String, path: String = "/",
        serviceName: String, servicePort: Int = 80,
        tlsEnabled: Bool = false, tlsSecret: String = "",
        ingressClass: String = "nginx"
    ) -> String {
        var y = """
        apiVersion: networking.k8s.io/v1
        kind: Ingress
        metadata:
          name: \(name)
          namespace: \(namespace)
          annotations:
            kubernetes.io/ingress.class: \(ingressClass)
        spec:
        """
        if tlsEnabled {
            y += "\n  tls:\n    - hosts:\n        - \(host)\n      secretName: \(tlsSecret.isEmpty ? "\(name)-tls" : tlsSecret)"
        }
        y += """

          rules:
            - host: \(host)
              http:
                paths:
                  - path: \(path)
                    pathType: Prefix
                    backend:
                      service:
                        name: \(serviceName)
                        port:
                          number: \(servicePort)
        """
        return dedent(y)
    }

    // MARK: - ConfigMap

    static func generateConfigMap(
        name: String, namespace: String = "default",
        data: [(String, String)]
    ) -> String {
        var y = """
        apiVersion: v1
        kind: ConfigMap
        metadata:
          name: \(name)
          namespace: \(namespace)
        data:
        """
        for (k, v) in data {
            y += "\n  \(k): \"\(v)\""
        }
        return dedent(y)
    }

    // MARK: - Secret

    static func generateSecret(
        name: String, namespace: String = "default",
        data: [(String, String)]
    ) -> String {
        var y = """
        apiVersion: v1
        kind: Secret
        metadata:
          name: \(name)
          namespace: \(namespace)
        type: Opaque
        data:
        """
        for (k, v) in data {
            let encoded = Data(v.utf8).base64EncodedString()
            y += "\n  \(k): \(encoded)"
        }
        return dedent(y)
    }

    // MARK: - CronJob

    static func generateCronJob(
        name: String, namespace: String = "default",
        image: String, schedule: String = "0 */6 * * *",
        command: [String] = []
    ) -> String {
        var y = """
        apiVersion: batch/v1
        kind: CronJob
        metadata:
          name: \(name)
          namespace: \(namespace)
        spec:
          schedule: "\(schedule)"
          jobTemplate:
            spec:
              template:
                spec:
                  restartPolicy: OnFailure
                  containers:
                    - name: \(name)
                      image: \(image)
        """
        if !command.isEmpty {
            y += "\n                  command:"
            for c in command {
                y += "\n                    - \"\(c)\""
            }
        }
        return dedent(y)
    }

    // MARK: - PVC

    static func generatePVC(
        name: String, namespace: String = "default",
        size: String = "10Gi", storageClass: String = "standard",
        accessMode: String = "ReadWriteOnce"
    ) -> String {
        return dedent("""
        apiVersion: v1
        kind: PersistentVolumeClaim
        metadata:
          name: \(name)
          namespace: \(namespace)
        spec:
          accessModes:
            - \(accessMode)
          storageClassName: \(storageClass)
          resources:
            requests:
              storage: \(size)
        """)
    }

    // MARK: - HPA

    static func generateHPA(
        name: String, namespace: String = "default",
        targetRef: String, minReplicas: Int = 2,
        maxReplicas: Int = 10, cpuTarget: Int = 70
    ) -> String {
        return dedent("""
        apiVersion: autoscaling/v2
        kind: HorizontalPodAutoscaler
        metadata:
          name: \(name)-hpa
          namespace: \(namespace)
        spec:
          scaleTargetRef:
            apiVersion: apps/v1
            kind: Deployment
            name: \(targetRef)
          minReplicas: \(minReplicas)
          maxReplicas: \(maxReplicas)
          metrics:
            - type: Resource
              resource:
                name: cpu
                target:
                  type: Utilization
                  averageUtilization: \(cpuTarget)
        """)
    }

    // MARK: - Full Stack

    static func generateFullStack(
        name: String, image: String, port: Int = 8080,
        replicas: Int = 3, host: String = "app.example.com"
    ) -> String {
        let dep = generateDeployment(name: name, image: image, replicas: replicas, containerPort: port)
        let svc = generateService(name: name, port: 80, targetPort: port)
        let ing = generateIngress(name: name, host: host, serviceName: name, servicePort: 80)
        return [dep, svc, ing].joined(separator: "\n---\n")
    }

    // MARK: - Helpers

    private static func dedent(_ text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        guard let first = lines.first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) else { return text }
        let leadingSpaces = first.prefix(while: { $0 == " " }).count
        return lines.map { line in
            if line.trimmingCharacters(in: .whitespaces).isEmpty { return "" }
            let drop = min(leadingSpaces, line.prefix(while: { $0 == " " }).count)
            return String(line.dropFirst(drop))
        }.joined(separator: "\n").trimmingCharacters(in: .newlines)
    }
}
