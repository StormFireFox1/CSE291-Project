# To Containerize Or Not To Containerize: Cost-Benefit Analysis of AWS Offerings

This repository contains the code and scripts used to benchmark various AWS offerings for different workloads. The workloads include Redis, Hashcat, and NFS. The AWS offerings include EC2, ECS, and EKS.

## Redis

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
    ssh -i <key-pair>.pem ubuntu@<public-ip>
    ```
4. Install Redis using `redis-benchmark/ec2/redis-server-setup.sh` script
5. Copy public IP of the instance and use it to connect to the Redis server
6. Now, run the redis-benchmark tool with 1,000,000 requests, 200 concurrent connections, and only print the total number of operations per second using
    ```bash
    redis-benchmark -h <public-ip> -p 6379 -t set,get -n 1000000 -c 200 -q
    ```
7. After benchmarking, stop atop profiling and upload logs to S3 using `util/stop-and-upload.sh` script.
8. Terminate the instance

### ECS

1. We use `redis:7.2.5` DockerHub image for the Redis server as the base, and build a new image on top of it. 
2. The Dockerfile for the new image is `Dockerfile.redis`.
3. The new image is pushed to Dockerhub using the following command:
    ```bash
    docker build -t cse291-redis -f Dockerfile.redis .
    docker tag cse291-redis <dockerhub-username>/cse291-redis
    docker push <dockerhub-username>/cse291-redis
    ```

### EKS

## Hashcat

### EC2

### ECS

### EKS

## NFS

### EC2

### ECS

### EKS

### atop - System Monitor


## Authors

- [Mayank Jain](https://github.com/mayank-02)
- [Matei-Alexandru Gardus](https://github.com/StormFireFox1)
- [Tanya Sneh](https://github.com/tanya06)
- [Yuchen Jing](https://github.com/DuckDuckWhaleUCSD)