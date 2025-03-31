# 提供者配置
provider "aws" {
  region = "us-west-2"
}

# 获取最新的 Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# 安全组配置
resource "aws_security_group" "spark_sg" {
  name        = "spark-sg"
  description = "Allow SSH and Spark communication"
  
  # SSH 访问 - 示例环境使用开放设置
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Spark Web UI
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # 内部集群通信
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }
  
  # 所有出站流量
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "spark-security-group"
  }
}

# 为 Master 节点创建的用户数据脚本
locals {
  master_user_data = <<-EOF
#!/bin/bash
yum update -y
yum install -y java-1.8.0-openjdk wget
cd /home/ec2-user
wget https://downloads.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz
tar -xzf spark-3.5.0-bin-hadoop3.tgz
mv spark-3.5.0-bin-hadoop3 spark
chown -R ec2-user:ec2-user spark
echo 'export SPARK_HOME=/home/ec2-user/spark' >> /home/ec2-user/.bashrc
echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> /home/ec2-user/.bashrc
sudo -u ec2-user bash -c "source /home/ec2-user/.bashrc && /home/ec2-user/spark/sbin/start-master.sh"
echo "Spark Master Started" > /home/ec2-user/status.txt
EOF

  # 为 Worker 节点创建的用户数据脚本模板
  worker_user_data_template = <<-EOF
#!/bin/bash
yum update -y
yum install -y java-1.8.0-openjdk wget
cd /home/ec2-user
wget https://downloads.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz
tar -xzf spark-3.5.0-bin-hadoop3.tgz
mv spark-3.5.0-bin-hadoop3 spark
chown -R ec2-user:ec2-user spark
echo 'export SPARK_HOME=/home/ec2-user/spark' >> /home/ec2-user/.bashrc
echo 'export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin' >> /home/ec2-user/.bashrc
# 等待主节点启动
sleep 30
sudo -u ec2-user bash -c "source /home/ec2-user/.bashrc && /home/ec2-user/spark/sbin/start-worker.sh spark://%MASTER_IP%:7077"
echo "Spark Worker Started" > /home/ec2-user/status.txt
EOF
}

# 创建 Master 节点
resource "aws_instance" "spark_master" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.small" # 给 Master 节点更多资源
  key_name      = "viclab-key" # 使用您的现有密钥
  vpc_security_group_ids = [aws_security_group.spark_sg.id]
  user_data = local.master_user_data
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  
  tags = {
    Name = "spark-master"
  }
}

# 创建 Worker 节点
resource "aws_instance" "spark_workers" {
  count         = 2
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"
  key_name      = "viclab-key" # 使用您的现有密钥
  vpc_security_group_ids = [aws_security_group.spark_sg.id]
  
  user_data = replace(local.worker_user_data_template, "%MASTER_IP%", aws_instance.spark_master.private_ip)
  
  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }
  
  # 确保 Master 节点先创建
  depends_on = [aws_instance.spark_master]
  
  tags = {
    Name = "spark-worker-${count.index + 1}"
  }
}

# 输出
output "master_public_ip" {
  value = aws_instance.spark_master.public_ip
}

output "master_web_ui" {
  value = "http://${aws_instance.spark_master.public_ip}:8080"
}

output "worker_public_ips" {
  value = [for worker in aws_instance.spark_workers : worker.public_ip]
}