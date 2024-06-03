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
    ```bash
    $ kubectl get pods
    $ kubectl exec -it <pod-name> -- /bin/bash
    $ /usr/local/bin/stop-and-upload.sh redis eks
    ```


### Benchmarking Results

| Environment    | GET Requests per Second | SET Requests per Second |
|----------------|-------------------------|-------------------------|
| EC2 @ t2.micro | 4237.79                 | 4186.75                 |
| EC2 @ t3.medium| 4211.75                 | 4195.14                 |
| ECS @ t3.medium| 4148.43                 | 4151.13                 |
| EKS @ t3.medium| 4084.40                 | 3916.81                 |


## Hashcat

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

### Benchmark Results

| Environment    | SHA2-512 Hashes/s       |
|----------------|-------------------------|
| EC2 @ t3.medium| 16940.9 kH/s            |
| ECS @ t3.medium| 14171.0 kH/s            |
| EKS @ t3.medium| 10719.7 kH/s            |

## NFS

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
6. After benchmarking, stop atop profiling on the server and upload logs to S3 using the `stop-and-upload.sh` script. Also upload the generated fio results generated on the client using the `upload-fio.sh` script.
7. Terminate the instance.

### ECS

1. We use `k8s.gcr.io/volume-nfs:0.8` as the base for the image.
2. The Dockerfile for the new image is `Dockerfile.nfs`.
3. The new image is pushed to Dockerhub using the following command:
    ```bash
    $ docker build -t cse291-nfs-benchmark -f Dockerfile.nfs .
    $ docker tag cse291-nfs-benchmark <dockerhub-username>/cse291-nfs-benchmark
    $ docker push <dockerhub-username>/cse291-nfs-benchmark
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
8. After benchmarking, stop atop profiling and upload logs to S3 using `util/stop-and-upload.sh` script on the server. To do this, SSH into the EC2 instance created and run the following command:
    ```bash
    $ docker ps
    $ docker exec -it <CONTAINER-ID> /bin/bash
    $ /usr/local/bin/stop-and-upload.sh nfs ecs
    ```
9. Also upload the generated fio results generated on the client using the `upload-fio.sh` script.
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
6. Once the benchmarking is done, stop atop profiling and upload logs to S3 using `util/stop-and-upload.sh` script on the server.
    ```bash
    $ kubectl get all -n storage
    $ kubectl exec -n storage -it <pod-name> -- /bin/bash
    $ /usr/local/bin/stop-and-upload.sh nfs eks
    ```
7. Also upload the generated fio results generated on the client using the `upload-fio.sh` script.
8. Terminate the cluster.

### Benchmark Results

| Environment    | Random Read Bandwidth   | Sequential Read Bandwidth   |
|----------------|-------------------------|-----------------------------| 
| EC2 @ t3.medium| 4607                    | 4620                        |
| ECS @ t3.medium|                         |                             |
| EKS @ t3.medium| 4226                    | 4423                        |


| Environment    | Random Write Bandwidth   | Sequential Write Bandwidth   |
|----------------|--------------------------|------------------------------| 
| EC2 @ t3.medium| 4546                     | 4550                         |
| ECS @ t3.medium|                          |                              |
| EKS @ t3.medium| 4544                     | 4533                         |

## Authors

- [Mayank Jain](https://github.com/mayank-02)
- [Matei-Alexandru Gardus](https://github.com/StormFireFox1)
- [Tanya Sneh](https://github.com/tanya06)
- [Yuchen Jing](https://github.com/DuckDuckWhaleUCSD)