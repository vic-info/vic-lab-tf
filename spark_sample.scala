// ---------------------------------------------
// VIC LAB Spark Shell Demo: User Action Analysis
// 使用 RDD 操作从 S3 加载日志数据并统计用户行为频率
// ---------------------------------------------

// Sample data (s3://viclab-datasets/user_logs.csv):
/*
user_id,timestamp,action,product_id
u1,2024-03-29T10:00:00Z,view,p100
u1,2024-03-29T10:01:00Z,click,p100
u2,2024-03-29T10:01:05Z,view,p200
u3,2024-03-29T10:02:10Z,view,p100
u2,2024-03-29T10:03:20Z,purchase,p200
*/

// 1. 加载数据（替换为你自己的 bucket 路径）
val raw = sc.textFile("s3a://viclab-datasets/user_logs.csv")

// 2. 去掉标题行
val data = raw.filter(line => !line.startsWith("user_id"))

// 3. 提取第三列（行为类型） action 字段
val actions = data.map(line => line.split(",")(2))

// 4. 统计每种行为出现次数
val actionCounts = actions.map(action => (action, 1)).reduceByKey(_ + _)

// 5. 打印结果
actionCounts.collect().foreach(println)

// 6. 保存到 S3（可选）
actionCounts.saveAsTextFile("s3a://viclab-output/action-stats")

// ✅ 教学建议：引导学生修改字段、增加过滤逻辑、增加用户维度等
