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

### ECS

### EKS

## NFS

### EC2

### ECS
sudo journalctl -u docker.service
sudo systemctl stop rpcbind.service


### EKS

### atop - System Monitor


## Authors

- [Mayank Jain](https://github.com/mayank-02)
- [Matei-Alexandru Gardus](https://github.com/StormFireFox1)
- [Tanya Sneh](https://github.com/tanya06)
- [Yuchen Jing](https://github.com/DuckDuckWhaleUCSD)