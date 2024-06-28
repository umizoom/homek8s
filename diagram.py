from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.compute import Server
from diagrams.onprem.network import Nginx, Opnsense, Internet
from diagrams.onprem.container import Docker
from diagrams.onprem.storage import CephOsd # type: ignore
from diagrams.k8s.infra import Master, Node

with Diagram("Home Network Overview", show=True):
    dmz_ingress = Nginx("DMZ Ingress")
    opnsense = Opnsense("OpnSense")
    multi_gig_switch = Internet("2.5G Switch Lan 1")
    with Cluster("UnRaid"):
        unraid = [
            Docker("Containers"),
            CephOsd("Storage"),
            Server("VMs")]
    
    one_gb_switch = Internet("1G Switch Lan k8")
    with Cluster("k8s"):
        k8s = [
            Master("Control 1"),
            Master("Control 2"),
            Node("Worker 1"),
            Node("Worker 2"),
            Node("Worker 2")]

    dmz_ingress >> opnsense >>  Edge(label="192.168.1.x") >> multi_gig_switch >> unraid
    dmz_ingress >> opnsense >> Edge(label="192.168.2.x") >> one_gb_switch >> k8s
    dmz_ingress << Edge(label="192.168.11.x") << unraid[0]