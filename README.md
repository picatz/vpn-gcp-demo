# vpn-gcp-demo

```console
$ terraform init
...
```

```console
$ terraform validate
...
```

```console
$ terraform plan
...
```

```console
$ terraform apply
...
Apply complete! Resources: 22 added, 0 changed, 0 destroyed.
```

```console
$ gcloud compute instances list
NAME       ZONE        MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP     STATUS
first-vm   us-east1-b  f1-micro                   10.10.15.2   X.X.X.X         RUNNING
second-vm  us-east1-b  f1-micro                   10.10.16.2   X.X.X.X         RUNNING
```

```console
$ gcloud compute ssh first-vm --zone=us-east1-b -- ping 10.10.16.2
PING 10.10.16.2 (10.10.16.2) 56(84) bytes of data.
64 bytes from 10.10.16.2: icmp_seq=1 ttl=62 time=3.23 ms
64 bytes from 10.10.16.2: icmp_seq=2 ttl=62 time=1.16 ms
...
^C
```

```console
$ terraform destroy -force
...
Destroy complete! Resources: 22 destroyed.
```
