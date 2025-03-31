**VIC LAB - Spark 教学集群部署手册 (CloudShell + Terraform)**

---

## 🔄 部署方案概述

使用 AWS CloudShell 在网页控制台上直接运行 Terraform ，快速建立 Spark Master + Worker 教学模拟集群，全自动部署，支持 Spark UI 操作和连接 SSH 进行编程实操。

---

## ✅ 一、第一步：打开 CloudShell

1. 登录 AWS Console
2. 顶部对鼎线按钮中点击 **"CloudShell"**
3. 等待系统启动 Shell 窗口

---

## 🔧 二、安装 Terraform (CloudShell 中仅需一次)

```bash
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install terraform -y
```

验证是否成功：
```bash
terraform -version
```

---

## 📂 三、创建 Terraform 文件

```bash
mkdir spark-cluster && cd spark-cluster
nano main.tf
```

把你的全套 Terraform 配置复制到 `main.tf`

> 我已经为你准备好了，可以直接用之前手写好的版本

---

## ⚖️ 四、开始部署集群

```bash
terraform init
terraform apply
```

等待几分钟，EC2 三台就会被创建，并自动部署 Spark Master 和 Worker

---

## 💻 五、访问 Spark Web UI

当 Terraform 运行完成后，你会看到输出：
```bash
master_public_ip = "<IP>"
master_web_ui    = "http://<IP>:8080"
```

直接打开浏览器输入 Web UI 地址，看到三台机器状态

---

## 🚪 六、如需 SSH 连接

如果你在 AWS EC2 > Key Pair 中创建了 `viclab-key`，并下载了 `viclab-key.pem`，可使用 SSH 连接数据节点：

```bash
chmod 400 viclab-key.pem
ssh -i viclab-key.pem ec2-user@<master-public-ip>
```

---

## ❌ 七、部署后删除资源

教学完成后，一定记得执行释放命令，防止费用累积

```bash
terraform destroy
```

---

## ✨ 八、项目初始化后有什么？

- Spark 3.5.0 已装好
- Master 自动启动且远程可访问
- Worker 自动连接到 Master
- 你可以在 master 上运行 spark-shell：

```bash
cd /home/ec2-user/spark
./bin/spark-shell
```
