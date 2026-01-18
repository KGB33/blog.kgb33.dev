"""
Uses diagrams & graphviz
https://diagrams.mingrammer.com/
"""

from diagrams import Diagram, Cluster
from diagrams.generic.compute import Rack
from diagrams.onprem import container, network

with Diagram("ssh Path"):
    ssh = network.Internet("User - SSH")
    firewall = network.Opnsense("Firewall")

    with Cluster("LAN"):
        with Cluster("Server"):
            sshd = Rack("ssh Daemon")
            gitea = container.Docker("Gitea Container")

    ssh >> firewall >> sshd >> gitea

with Diagram("HTTPs Path"):
    http = network.Internet("User - HTTPs")
    firewall = network.Opnsense("Firewall")

    with Cluster("LAN"):
        nginx = network.Nginx()
        with Cluster("Server"):
            gitea = container.Docker("Gitea Container")
    http >> firewall >> nginx >> gitea
