# To Containerize Or Not To Containerize: Cost-Benefit Analysis of AWS Offerings

This repository contains the code and scripts used to benchmark various AWS offerings for different workloads. The workloads include Redis, Hashcat, and NFS. The AWS offerings include EC2, ECS, and EKS.

## Redis

```bash
$ redis-server --version
Redis server v=7.2.5 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=d284576ab9ca3cc5
```

### EC2

1. Create a new EC2 instance with the following specifications:
    - AMI: Ubuntu Server 24.04 LTS (HVM), SSD Volume Type
    - Instance Type: t3.medium
    - Security Group: Create a new security group with the following inbound rules:
        - Type: Custom TCP Rule, Protocol: TCP, Port Range: 6379, Source: Anywhere
        - Type: Custom TCP Rule, Protocol: TCP, Port Range: 22, Source: Anywhere
    - Key Pair: Create a new key pair and download it
2. SSH into the instance using the key pair 
    ```
    $ ssh -i <key-pair>.pem ubuntu@<public-ip>
    ```
4. Install Redis using `redis-benchmark/ec2/redis-server-setup.sh` script
5. Copy public IP of the instance and use it to connect to the Redis server
6. Now, run the redis-benchmark tool with 1,000,000 requests, 200 concurrent connections, and only print the total number of operations per second using
    ```bash
    $ redis-benchmark -h <public-ip> -p 6379 -t set,get -n 1000000 -c 200 -q
    ```
7. After benchmarking, stop atop profiling and upload logs to S3 using `util/stop-and-upload.sh` script.
8. Terminate the instance

### ECS

1. We use `redis:7.2.5` DockerHub image for the Redis server as the base, and build a new image on top of it. 
2. The Dockerfile for the new image is `Dockerfile.redis`.
3. The new image is pushed to Dockerhub using the following command:
    ```bash
    $ docker build -t cse291-redis -f Dockerfile.redis .
    $ docker tag cse291-redis <dockerhub-username>/cse291-redis
    $ docker push <dockerhub-username>/cse291-redis
    ```
4. Create a new ECS cluster with the following specifications:
    - Cluster Name: redis-cluster
    - EC2 Instance Type: t3.xlarge
    - Number of Instances: 1
    - Key Pair: Use the same key pair as used for EC2
    - Security Group: Use the default security group
5. Create a new task definition using `redis-benchmark/ecs/redis-task-definition.json` file
6. Create a new service using the task definition
7. Once it is running, grab public IP of EC2 instance backing ECS container
8. Now, run the redis-benchmark tool with 1,000,000 requests, 200 concurrent connections, and only print the total number of operations per second using
    ```bash
    $ redis-benchmark -h <public-ip> -p 6379 -t set,get -n 1000000 -c 200 -q
    ```
9. Once the benchmarking is done, stop atop profiling and upload logs to S3 using `util/stop-and-upload.sh` script.
    ```bash
    $ ssh -i ~/key-pair.pem ec2-user@<public-ip>
    $ docker ps
    $ docker exec -it <container-id> /bin/bash
    $ /usr/local/bin/stop-and-upload.sh redis ecs
    ```

### EKS

1. Create a new EKS cluster
2. Grab the CLI/scripting keys from awsed.ucsd.edu and save it into `~/.kubesecrets`
3. To setup kubectl to talk to the newly created AWS EKS Cluster, run the following commands:
    ```bash
    $ source ~/.kubesecrets
    $ kubectl config set-context arn:aws:iam::017853670777:role/eksClusterRole
    $ aws eks update-kubeconfig --region us-west-2 --name "ClusterName"
    $ kubectl get all # Verify it works
    $ kubectl apply -f redis-benchmark/eks/redis-deployment.yaml
    ```
4. Read External IP from the output of `kubectl get svc redis`
5. Run benchmarking using the following commands:
    ```bash
    $ redis-benchmark -h <External-IP> -p 6379 -t set,get -n 1000000 -c 200 -q
    ```
6. Once the benchmarking is done, stop atop profiling and upload logs to S3 using `util/stop-and-upload.sh` script.
7. Delete the service and deployment using the following commands:
    ```bash
    $ kubectl delete -f redis-benchmark/eks/redis-deployment.yaml
    ```
8. Delete the NodeGroup and terminate the cluster.

### EKS (Scaling)

1. Create a new EKS cluster with Node Group of 3 `t3.medium` instances.
2. Grab the CLI/scripting keys from awsed.ucsd.edu and save it into `~/.kubesecrets`
3. To setup kubectl to talk to the newly created AWS EKS Cluster, run the following commands:
    ```bash
    $ source ~/.kubesecrets
    $ kubectl config set-context arn:aws:iam::017853670777:role/eksClusterRole
    $ aws eks update-kubeconfig --region us-west-2 --name "ClusterName"
    $ kubectl get all # Verify it works
    ```
4. Test scaling for 4 configurations
   1. 1 Master: Follow EKS steps of Redis to deploy and jump to step 6
   2. 1 Master, 1 Slave: Update replicas = 2 and NUM_SHARDS = 1 in `redis-cluster.yaml` 
   3. 2 Master, 2 Slave: Update replicas = 4 and NUM_SHARDS = 2 in `redis-cluster.yaml` 
   4. 3 Master, 3 Slave: Update replicas = 6 and NUM_SHARDS = 3 in `redis-cluster.yaml` 
5. Deploy the redis cluster
    ```bash
    $ kubectl apply -f redis-benchmark/eks/redis-cluster.yaml
    ```
6. Run benchmarking using the following commands:
    ```bash
    $ kubectl exec redis-cluster-0 -- redis-benchmark -p 6379 -t get,set -n 1000000 -c 1000 --cluster -q
    ```
7. Save the results and terminate the cluster.
7. Delete the service and deployment using the following commands:
    ```bash
    $ kubectl delete -f redis-benchmark/eks/redis-cluster.yaml
    ```
8. Delete the NodeGroup and terminate the cluster.


## Hashcat

Hashcat version: 6.2.6+ds1-1build2 (Ubuntu 24.04 LTS package)

### EC2

1. Create a new EC2 instance with the following specifications:
    - AMI: Ubuntu Server 24.04 LTS (HVM), SSD Volume Type
    - Instance Type: t3.medium
    - Security Group: Create a new security group with the following inbound rules:
        - Type: Custom TCP Rule, Protocol: TCP, Port Range: 22, Source: Anywhere
    - Key Pair: Create a new key pair and download it
2. SSH into the instance using the key pair 
    ```
    $ ssh -i <key-pair>.pem ubuntu@<public-ip>
    ```
4. Install Hashcat and corresponding CPU OpenCL headers by running `sudo apt install -y hashcat ocl-icd-opencl-dev opencl-headers clinfo`
6. Run the Hashcat benchmark script ./benchmark_hashcat. You may choose any [hash mode you like](https://hashcat.net/wiki/doku.php?id=example_hashes), but we chose SHA2-512 to make it complex:
    ```bash
    $ hashcat -m 1700 -b
    ```
8. Terminate the instance.

### ECS

1. We use `ubuntu:24.04` DockerHub image as the base for the image.
2. The Dockerfile for the new image is `Dockerfile.hashcat`.
3. The new image is pushed to Dockerhub using the following command:
    ```bash
    $ docker build -t cse291-hashcat-benchmark -f Dockerfile.hashcat .
    $ docker tag cse291-hashcat-benchmark <dockerhub-username>/cse291-hashcat-benchmark
    $ docker push <dockerhub-username>/cse291-hashcat-benchmark
    ```
4. Create a new ECS cluster with the following specifications:
    - Cluster Name: hashcat-cluster
    - EC2 Instance Type: t3.xlarge
    - Number of Instances: 1
    - Key Pair: Use the same key pair as used for EC2
    - Security Group: Use the default security group
5. Create a new task definition using the `hashcat-benchmark/hashcatTaskDefinition.json` configuration file.
6. Create a new Task using said task definition.
7. The task will be automatically destroyed and deploy the results to the designated S3 bucket.
8. Terminate the cluster.

### EKS

1. Create a new EKS cluster, name it `HashcatCluster`.
2. Grab the CLI keys from awsed.ucsd.edu and save it into `~/.awscredentials`
3. To setup kubectl to talk to the newly created AWS EKS Cluster, run the following commands:
    ```bash
    $ source ~/.awscredentials
    $ aws eks update-kubeconfig --region us-west-2 --name "HashcatCluster"
    $ kubectl get all # Verify it works
    $ kubectl apply -f hashcat-benchmark/hashcat-benchmark-job.yaml
    ```
4. The task will automatically run and upload the image to our S3 bucket. Wait for the job to be done with `kubectl wait --for=condition=complete job/hashcat-benchmark`.
5. Terminate the cluster.

## NFS

NFS utils version: 1.3.0-0.21.el7_2.1.x86_64 (CentOS Linux release 7.2.1511 (Core))

### EC2
1. Create a new EC2 instance with the following specifications:
    - AMI: Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
    - Instance Type: t3.medium
    - Security Group: Create a new security group with the following inbound rules:
        - Type: Custom TCP Rule, Protocol: TCP, Port Range: 22, Source: Anywhere
        - Type: Custom TCP Rule, Protocol: TCP, Port Range: 4029, Source: Anywhere
        - Type: Custom TCP Rule, Protocol: TCP, Port Range: 111, Source: Anywhere
        - Type: Custom TCP Rule, Protocol: TCP, Port Range: 20048, Source: Anywhere
    - Key Pair: Create a new key pair and download it
2. SSH into the instance using the key pair 
    ```
    $ ssh -i <key-pair>.pem ubuntu@<public-ip>
    ```
3. Copy the bash files in nfs-benchmark/server into `/usr/local/bin` on the EC2 host and setup the nfs server by running the script using `./server_setup.sh`.
4. Setup the nfs client on any linux host by running the script as `./client_setup.sh <server-public-ip>`. This would perform necessary installations and mount the directory `/exports` on the server to the `$HOME/shared` on the client. For performing only the mount, if installations have been done before run the following command:
    ```bash
    $ mount -t nfs <Server IP>:/exports "$HOME/shared"
    ```
5. On the client, enter the directory synced with the server and run the fio read-write benchmark using the configurations given in the job file. (Update the `<IP>` in the job file with the correct public ip of the nfs server)
    ```bash
    $ fio ../job-file --output=fio-results.json --output-format=json
    ```
7. Terminate the instance.

### ECS

1. We use `k8s.gcr.io/volume-nfs:0.8` as the base for the image.
2. The Dockerfile for the new image is `Dockerfile.nfs`.
3. The new image is pushed to Dockerhub using the following command:
    ```bash
    $ docker build -t cse291-nfs-sync -f Dockerfile.nfs .
    $ docker tag cse291-nfs-benchmark <dockerhub-username>/cse291-nfs-syn
    $ docker push <dockerhub-username>/cse291-nfs-sync
    ```
4. Create a new ECS cluster with the following specifications:
    - Cluster Name: nfs-cluster
    - EC2 Instance Type: t3.xlarge
    - Number of Instances: 1
    - Key Pair: Use the same key pair as used for EC2
    - Security Group: Use the default security group
5. The EC2 instance starts with the rpcbind.service up which hinders with our deployment. (This was confirmed using the `sudo journalctl -u docker.service` command on the EC2 instance) Therefore, SSH into the created instance and stop the rpcbind.service by running the following command:
    ```bash
    $ sudo systemctl stop rpcbind.service
    ```
5. Create a new task definition using the `nfs-benchmark/server/nfs-task-definition.json` configuration file.
6. Create a new Task using said task definition.
7. Once the task is deployed, setup any linux host as the client and run the fio benchmark as described in steps 4 and 5 of NFS EC2 section.
8. Terminate the ECS cluster. 

### EKS

1. Create a new EKS cluster
2. Grab the CLI/scripting keys from awsed.ucsd.edu and save it into `~/.kubesecrets`
3. To setup kubectl to talk to the newly created AWS EKS Cluster, run the following commands:
    ```bash
    $ source ~/.kubesecrets
    $ kubectl config set-context arn:aws:iam::017853670777:role/eksClusterRole
    $ aws eks update-kubeconfig --region us-west-2 --name "ClusterName"
    $ kubectl get all # Verify it works
    $ kubectl create ns storage
    $ kubectl apply -f nfs-benchmark/server/nfs-server-deployment.yaml
    ```
4. Read Loadbalancer ingress from the output of `kubectl describe svc -n storage nfs-service`
5. Using the captured value as the IP for the server, setup the mount on the client and run the fio benchmark as described in steps 4 and 5 of the NFS EC2 section.
8. Terminate the cluster.

## Results

TODO: Link the results sheet / document here.

## Authors

- [Mayank Jain](https://github.com/mayank-02)
- [Matei-Alexandru Gardus](https://github.com/StormFireFox1)
- [Tanya Sneh](https://github.com/tanya06)
- [Yuchen Jing](https://github.com/DuckDuckWhaleUCSD)