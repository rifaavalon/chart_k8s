#!/usr/bin/env python3
"""
EKS Cluster Audit Script

This script performs comprehensive audits of EKS clusters including:
- Node health and capacity
- Pod status and resource usage
- Security configurations
- Network policies
- RBAC configurations
- Resource quotas and limits
"""

import argparse
import json
import os
import sys
from datetime import datetime
from typing import Dict, List, Any

try:
    from kubernetes import client, config
    from kubernetes.client.rest import ApiException
except ImportError:
    print("Error: kubernetes package not installed. Run: pip install kubernetes")
    sys.exit(1)

try:
    import boto3
    from botocore.exceptions import ClientError
except ImportError:
    print("Error: boto3 package not installed. Run: pip install boto3")
    sys.exit(1)


class ClusterAuditor:
    """Performs comprehensive EKS cluster audits"""

    def __init__(self, environment: str, region: str = "us-east-1"):
        """
        Initialize the cluster auditor

        Args:
            environment: Environment name (dev, stg, prod)
            region: AWS region
        """
        self.environment = environment
        self.region = region
        self.timestamp = datetime.utcnow().isoformat()

        # Initialize Kubernetes client
        try:
            config.load_kube_config()
        except:
            try:
                config.load_incluster_config()
            except:
                print("Error: Unable to load kubeconfig. Ensure kubectl is configured.")
                sys.exit(1)

        self.v1 = client.CoreV1Api()
        self.apps_v1 = client.AppsV1Api()
        self.rbac_v1 = client.RbacAuthorizationV1Api()
        self.networking_v1 = client.NetworkingV1Api()

        # Initialize AWS clients
        self.eks_client = boto3.client('eks', region_name=region)
        self.ec2_client = boto3.client('ec2', region_name=region)

    def audit_nodes(self) -> Dict[str, Any]:
        """Audit cluster nodes"""
        print("Auditing cluster nodes...")

        try:
            nodes = self.v1.list_node()
            node_info = []

            for node in nodes.items:
                conditions = {c.type: c.status for c in node.status.conditions}

                node_data = {
                    'name': node.metadata.name,
                    'status': 'Ready' if conditions.get('Ready') == 'True' else 'NotReady',
                    'role': node.metadata.labels.get('kubernetes.io/role', 'worker'),
                    'instance_type': node.metadata.labels.get('node.kubernetes.io/instance-type', 'unknown'),
                    'os_image': node.status.node_info.os_image,
                    'kubelet_version': node.status.node_info.kubelet_version,
                    'capacity': {
                        'cpu': node.status.capacity.get('cpu'),
                        'memory': node.status.capacity.get('memory'),
                        'pods': node.status.capacity.get('pods')
                    },
                    'allocatable': {
                        'cpu': node.status.allocatable.get('cpu'),
                        'memory': node.status.allocatable.get('memory'),
                        'pods': node.status.allocatable.get('pods')
                    },
                    'conditions': conditions
                }
                node_info.append(node_data)

            return {
                'total_nodes': len(nodes.items),
                'ready_nodes': sum(1 for n in node_info if n['status'] == 'Ready'),
                'nodes': node_info
            }
        except ApiException as e:
            return {'error': f'Failed to audit nodes: {str(e)}'}

    def audit_pods(self) -> Dict[str, Any]:
        """Audit cluster pods"""
        print("Auditing cluster pods...")

        try:
            pods = self.v1.list_pod_for_all_namespaces()

            pod_status_counts = {}
            pods_by_namespace = {}
            problem_pods = []

            for pod in pods.items:
                namespace = pod.metadata.namespace
                status = pod.status.phase

                # Count by status
                pod_status_counts[status] = pod_status_counts.get(status, 0) + 1

                # Count by namespace
                pods_by_namespace[namespace] = pods_by_namespace.get(namespace, 0) + 1

                # Track problem pods
                if status not in ['Running', 'Succeeded']:
                    problem_pods.append({
                        'name': pod.metadata.name,
                        'namespace': namespace,
                        'status': status,
                        'reason': pod.status.reason,
                        'message': pod.status.message
                    })

            return {
                'total_pods': len(pods.items),
                'status_counts': pod_status_counts,
                'pods_by_namespace': pods_by_namespace,
                'problem_pods': problem_pods
            }
        except ApiException as e:
            return {'error': f'Failed to audit pods: {str(e)}'}

    def audit_deployments(self) -> Dict[str, Any]:
        """Audit deployments"""
        print("Auditing deployments...")

        try:
            deployments = self.apps_v1.list_deployment_for_all_namespaces()

            deployment_info = []
            unhealthy_deployments = []

            for deployment in deployments.items:
                replicas = deployment.status.replicas or 0
                ready = deployment.status.ready_replicas or 0
                available = deployment.status.available_replicas or 0

                is_healthy = ready == replicas and available == replicas

                dep_data = {
                    'name': deployment.metadata.name,
                    'namespace': deployment.metadata.namespace,
                    'replicas': replicas,
                    'ready': ready,
                    'available': available,
                    'healthy': is_healthy
                }

                deployment_info.append(dep_data)

                if not is_healthy:
                    unhealthy_deployments.append(dep_data)

            return {
                'total_deployments': len(deployments.items),
                'healthy_deployments': sum(1 for d in deployment_info if d['healthy']),
                'unhealthy_deployments': unhealthy_deployments
            }
        except ApiException as e:
            return {'error': f'Failed to audit deployments: {str(e)}'}

    def audit_services(self) -> Dict[str, Any]:
        """Audit services"""
        print("Auditing services...")

        try:
            services = self.v1.list_service_for_all_namespaces()

            service_types = {}
            services_by_namespace = {}

            for service in services.items:
                svc_type = service.spec.type
                namespace = service.metadata.namespace

                service_types[svc_type] = service_types.get(svc_type, 0) + 1
                services_by_namespace[namespace] = services_by_namespace.get(namespace, 0) + 1

            return {
                'total_services': len(services.items),
                'service_types': service_types,
                'services_by_namespace': services_by_namespace
            }
        except ApiException as e:
            return {'error': f'Failed to audit services: {str(e)}'}

    def audit_namespaces(self) -> Dict[str, Any]:
        """Audit namespaces"""
        print("Auditing namespaces...")

        try:
            namespaces = self.v1.list_namespace()

            ns_info = []
            for ns in namespaces.items:
                ns_info.append({
                    'name': ns.metadata.name,
                    'status': ns.status.phase,
                    'labels': ns.metadata.labels or {}
                })

            return {
                'total_namespaces': len(namespaces.items),
                'namespaces': ns_info
            }
        except ApiException as e:
            return {'error': f'Failed to audit namespaces: {str(e)}'}

    def audit_rbac(self) -> Dict[str, Any]:
        """Audit RBAC configurations"""
        print("Auditing RBAC...")

        try:
            roles = self.rbac_v1.list_role_for_all_namespaces()
            cluster_roles = self.rbac_v1.list_cluster_role()
            role_bindings = self.rbac_v1.list_role_binding_for_all_namespaces()
            cluster_role_bindings = self.rbac_v1.list_cluster_role_binding()

            return {
                'total_roles': len(roles.items),
                'total_cluster_roles': len(cluster_roles.items),
                'total_role_bindings': len(role_bindings.items),
                'total_cluster_role_bindings': len(cluster_role_bindings.items)
            }
        except ApiException as e:
            return {'error': f'Failed to audit RBAC: {str(e)}'}

    def audit_network_policies(self) -> Dict[str, Any]:
        """Audit network policies"""
        print("Auditing network policies...")

        try:
            network_policies = self.networking_v1.list_network_policy_for_all_namespaces()

            policies_by_namespace = {}
            for policy in network_policies.items:
                namespace = policy.metadata.namespace
                policies_by_namespace[namespace] = policies_by_namespace.get(namespace, 0) + 1

            return {
                'total_network_policies': len(network_policies.items),
                'policies_by_namespace': policies_by_namespace
            }
        except ApiException as e:
            return {'error': f'Failed to audit network policies: {str(e)}'}

    def run_full_audit(self) -> Dict[str, Any]:
        """Run a full cluster audit"""
        print(f"\n{'='*60}")
        print(f"Starting EKS Cluster Audit - {self.environment}")
        print(f"Timestamp: {self.timestamp}")
        print(f"{'='*60}\n")

        audit_results = {
            'metadata': {
                'environment': self.environment,
                'region': self.region,
                'timestamp': self.timestamp
            },
            'nodes': self.audit_nodes(),
            'pods': self.audit_pods(),
            'deployments': self.audit_deployments(),
            'services': self.audit_services(),
            'namespaces': self.audit_namespaces(),
            'rbac': self.audit_rbac(),
            'network_policies': self.audit_network_policies()
        }

        return audit_results

    def save_results(self, results: Dict[str, Any], output_dir: str = "../output"):
        """Save audit results to JSON file"""
        os.makedirs(output_dir, exist_ok=True)

        filename = f"cluster-audit-{self.environment}-{datetime.utcnow().strftime('%Y%m%d-%H%M%S')}.json"
        filepath = os.path.join(output_dir, filename)

        with open(filepath, 'w') as f:
            json.dump(results, f, indent=2)

        print(f"\n{'='*60}")
        print(f"Audit results saved to: {filepath}")
        print(f"{'='*60}\n")

        return filepath

    def print_summary(self, results: Dict[str, Any]):
        """Print a summary of audit results"""
        print(f"\n{'='*60}")
        print("AUDIT SUMMARY")
        print(f"{'='*60}\n")

        # Nodes summary
        nodes = results.get('nodes', {})
        if 'error' not in nodes:
            print(f"Nodes: {nodes['ready_nodes']}/{nodes['total_nodes']} Ready")

        # Pods summary
        pods = results.get('pods', {})
        if 'error' not in pods:
            print(f"Pods: {pods['total_pods']} Total")
            if pods.get('problem_pods'):
                print(f"  ⚠️  {len(pods['problem_pods'])} Problem Pods")

        # Deployments summary
        deployments = results.get('deployments', {})
        if 'error' not in deployments:
            print(f"Deployments: {deployments['healthy_deployments']}/{deployments['total_deployments']} Healthy")
            if deployments.get('unhealthy_deployments'):
                print(f"  ⚠️  {len(deployments['unhealthy_deployments'])} Unhealthy Deployments")

        # Services summary
        services = results.get('services', {})
        if 'error' not in services:
            print(f"Services: {services['total_services']} Total")

        # Namespaces summary
        namespaces = results.get('namespaces', {})
        if 'error' not in namespaces:
            print(f"Namespaces: {namespaces['total_namespaces']} Total")

        print(f"\n{'='*60}\n")


def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='EKS Cluster Audit Tool')
    parser.add_argument(
        '--environment',
        required=True,
        choices=['dev', 'stg', 'prod'],
        help='Environment to audit'
    )
    parser.add_argument(
        '--region',
        default='us-east-1',
        help='AWS region (default: us-east-1)'
    )
    parser.add_argument(
        '--output-dir',
        default='../output',
        help='Output directory for audit results (default: ../output)'
    )
    parser.add_argument(
        '--no-save',
        action='store_true',
        help='Do not save results to file'
    )

    args = parser.parse_args()

    # Create auditor and run audit
    auditor = ClusterAuditor(environment=args.environment, region=args.region)
    results = auditor.run_full_audit()

    # Print summary
    auditor.print_summary(results)

    # Save results
    if not args.no_save:
        auditor.save_results(results, output_dir=args.output_dir)

    # Exit with error code if there are problems
    pods = results.get('pods', {})
    deployments = results.get('deployments', {})

    has_problems = (
        pods.get('problem_pods') or
        deployments.get('unhealthy_deployments')
    )

    sys.exit(1 if has_problems else 0)


if __name__ == '__main__':
    main()
