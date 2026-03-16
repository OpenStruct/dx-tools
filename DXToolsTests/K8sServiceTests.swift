import XCTest
@testable import DX_Tools

final class K8sServiceTests: XCTestCase {
    func testDeploymentGeneration() {
        let result = K8sService.generateDeployment(name: "web", image: "nginx:1.25", replicas: 3, containerPort: 8080)
        XCTAssertTrue(result.contains("apiVersion: apps/v1"))
        XCTAssertTrue(result.contains("kind: Deployment"))
        XCTAssertTrue(result.contains("name: web"))
        XCTAssertTrue(result.contains("replicas: 3"))
        XCTAssertTrue(result.contains("image: nginx:1.25"))
        XCTAssertTrue(result.contains("containerPort: 8080"))
    }

    func testDeploymentResourceLimits() {
        let result = K8sService.generateDeployment(name: "api", image: "node:20", cpuReq: "200m", memReq: "256Mi", cpuLim: "1", memLim: "1Gi")
        XCTAssertTrue(result.contains("cpu: 200m"))
        XCTAssertTrue(result.contains("memory: 256Mi"))
        XCTAssertTrue(result.contains("cpu: 1"))
        XCTAssertTrue(result.contains("memory: 1Gi"))
    }

    func testDeploymentWithEnvVars() {
        let result = K8sService.generateDeployment(name: "app", image: "app:latest", envVars: [("NODE_ENV", "production"), ("PORT", "3000")])
        XCTAssertTrue(result.contains("env:"))
        XCTAssertTrue(result.contains("name: NODE_ENV"))
        XCTAssertTrue(result.contains("value: \"production\""))
    }

    func testServiceClusterIP() {
        let result = K8sService.generateService(name: "web", type: .clusterIP, port: 80, targetPort: 8080)
        XCTAssertTrue(result.contains("kind: Service"))
        XCTAssertTrue(result.contains("type: ClusterIP"))
        XCTAssertTrue(result.contains("port: 80"))
        XCTAssertTrue(result.contains("targetPort: 8080"))
    }

    func testServiceLoadBalancer() {
        let result = K8sService.generateService(name: "api", type: .loadBalancer)
        XCTAssertTrue(result.contains("type: LoadBalancer"))
    }

    func testIngressWithTLS() {
        let result = K8sService.generateIngress(name: "web", host: "app.example.com", serviceName: "web", servicePort: 80, tlsEnabled: true, tlsSecret: "my-tls")
        XCTAssertTrue(result.contains("kind: Ingress"))
        XCTAssertTrue(result.contains("host: app.example.com"))
        XCTAssertTrue(result.contains("tls:"))
        XCTAssertTrue(result.contains("secretName: my-tls"))
    }

    func testIngressWithoutTLS() {
        let result = K8sService.generateIngress(name: "web", host: "app.example.com", serviceName: "web", servicePort: 80, tlsEnabled: false)
        XCTAssertFalse(result.contains("tls:"))
    }

    func testConfigMap() {
        let result = K8sService.generateConfigMap(name: "app-config", data: [("DB_HOST", "postgres"), ("DB_PORT", "5432")])
        XCTAssertTrue(result.contains("kind: ConfigMap"))
        XCTAssertTrue(result.contains("DB_HOST: \"postgres\""))
        XCTAssertTrue(result.contains("DB_PORT: \"5432\""))
    }

    func testSecretBase64() {
        let result = K8sService.generateSecret(name: "app-secret", data: [("password", "mysecret")])
        XCTAssertTrue(result.contains("kind: Secret"))
        XCTAssertTrue(result.contains("type: Opaque"))
        let encoded = Data("mysecret".utf8).base64EncodedString()
        XCTAssertTrue(result.contains("password: \(encoded)"))
    }

    func testCronJobSchedule() {
        let result = K8sService.generateCronJob(name: "backup", image: "busybox", schedule: "0 2 * * *", command: ["/bin/sh", "-c", "backup.sh"])
        XCTAssertTrue(result.contains("kind: CronJob"))
        XCTAssertTrue(result.contains("schedule: \"0 2 * * *\""))
        XCTAssertTrue(result.contains("command:"))
    }

    func testPVC() {
        let result = K8sService.generatePVC(name: "data-pvc", size: "50Gi", storageClass: "ssd")
        XCTAssertTrue(result.contains("kind: PersistentVolumeClaim"))
        XCTAssertTrue(result.contains("storage: 50Gi"))
        XCTAssertTrue(result.contains("storageClassName: ssd"))
        XCTAssertTrue(result.contains("ReadWriteOnce"))
    }

    func testHPA() {
        let result = K8sService.generateHPA(name: "web", targetRef: "web", minReplicas: 2, maxReplicas: 10, cpuTarget: 80)
        XCTAssertTrue(result.contains("kind: HorizontalPodAutoscaler"))
        XCTAssertTrue(result.contains("minReplicas: 2"))
        XCTAssertTrue(result.contains("maxReplicas: 10"))
        XCTAssertTrue(result.contains("averageUtilization: 80"))
    }

    func testFullStack() {
        let result = K8sService.generateFullStack(name: "myapp", image: "myapp:latest", port: 3000, replicas: 2, host: "myapp.dev")
        XCTAssertTrue(result.contains("---"))
        XCTAssertTrue(result.contains("kind: Deployment"))
        XCTAssertTrue(result.contains("kind: Service"))
        XCTAssertTrue(result.contains("kind: Ingress"))
        XCTAssertTrue(result.contains("host: myapp.dev"))
    }

    func testDeploymentHealthProbes() {
        let result = K8sService.generateDeployment(name: "api", image: "api:v1", healthPath: "/ready")
        XCTAssertTrue(result.contains("livenessProbe:"))
        XCTAssertTrue(result.contains("readinessProbe:"))
        XCTAssertTrue(result.contains("path: /ready"))
    }

    func testNamespace() {
        let result = K8sService.generateDeployment(name: "web", namespace: "staging", image: "web:latest")
        XCTAssertTrue(result.contains("namespace: staging"))
    }
}
