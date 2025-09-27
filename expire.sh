#!/bin/bash

# 定义要修改的文件
WORKER_FILE="origin.js"

# 检查文件是否存在
if [ ! -f "$WORKER_FILE" ]; then
    echo "错误：找不到文件 $WORKER_FILE"
    exit 1
fi

# 备份原始文件
cp "$WORKER_FILE" "${WORKER_FILE}.bak"
echo "已创建备份文件: ${WORKER_FILE}.bak"

# 1. 在 config_Json 函数中添加过期时间计算
sed -i '/const config = {/i \
    // 计算过期时间\
    function 计算过期时间(有效时间 = 7, 更新时间 = 3) {\
        const 时区偏移 = 8; // 北京时间\
        const 起始日期 = new Date(2007, 6, 7, 更新时间, 0, 0);\
        const 一周的毫秒数 = 1000 * 60 * 60 * 24 * 有效时间;\
        \
        const 现在 = new Date();\
        const 调整后的现在 = new Date(现在.getTime() + 时区偏移 * 60 * 60 * 1000);\
        const 时间差 = Number(调整后的现在) - Number(起始日期);\
        const 当前周数 = Math.ceil(时间差 / 一周的毫秒数);\
        \
        const 结束时间 = new Date(起始日期.getTime() + 当前周数 * 一周的毫秒数);\
        \
        // 格式化时间为 %Y-%m-%d %H:%M:%S%z 格式\
        const 年 = 结束时间.getFullYear();\
        const 月 = String(结束时间.getMonth() + 1).padStart(2, '\''0'\'');\
        const 日 = String(结束时间.getDate()).padStart(2, '\''0'\'');\
        const 时 = String(结束时间.getHours()).padStart(2, '\''0'\'');\
        const 分 = String(结束时间.getMinutes()).padStart(2, '\''0'\'');\
        const 秒 = String(结束时间.getSeconds()).padStart(2, '\''0'\'');\
        \
        // 时区偏移量格式化为 +0800\
        const 时区偏移量 = 时区偏移 >= 0 ? \
            `+${String(时区偏移).padStart(2, '\''0'\'')}00` : \
            `-${String(Math.abs(时区偏移)).padStart(2, '\''0'\'')}00`;\
        \
        return `${年}-${月}-${日} ${时}:${分}:${秒}${时区偏移量}`;\
    }\
    \
    const 过期时间 = 计算过期时间(有效时间, 更新时间);\
' "$WORKER_FILE"

# 2. 修改 config 对象，添加 EXPIRE 字段
sed -i 's/KEY: (uuid != userID) ? {/KEY: (uuid != userID) ? {\
                DynamicUUID: true,\
                TOKEN: uuid || null,\
                UUID: userID.toLowerCase() || null,\
                UUIDLow: userIDLow || null,\
                TIME: 有效时间 || null,\
                UPTIME: 更新时间 || null,\
                EXPIRE: 过期时间, \/\/ 新增过期时间字段\
                fakeUserID: fakeUserID || null,/' "$WORKER_FILE"

sed -i 's/KEY: {/KEY: {\
                DynamicUUID: false,\
                UUID: userID.toLowerCase() || null,\
                EXPIRE: "永不过期", \/\/ 静态UUID显示永不过期\
                fakeUserID: fakeUserID || null,/' "$WORKER_FILE"

# 3. 在生成动态UUID函数中添加过期时间返回
sed -i '/function 生成动态UUID(密钥) {/a \
    function 计算过期时间() {\
        const 当前周数 = 获取当前周数();\
        const 结束时间 = new Date(起始日期.getTime() + 当前周数 * 一周的毫秒数);\
        \
        // 格式化时间为 %Y-%m-%d %H:%M:%S%z 格式\
        const 年 = 结束时间.getFullYear();\
        const 月 = String(结束时间.getMonth() + 1).padStart(2, '\''0'\'');\
        const 日 = String(结束时间.getDate()).padStart(2, '\''0'\'');\
        const 时 = String(结束时间.getHours()).padStart(2, '\''0'\'');\
        const 分 = String(结束时间.getMinutes()).padStart(2, '\''0'\'');\
        const 秒 = String(结束时间.getSeconds()).padStart(2, '\''0'\'');\
        \
        // 时区偏移量格式化为 +0800\
        const 时区偏移量 = 时区偏移 >= 0 ? \
            `+${String(时区偏移).padStart(2, '\''0'\'')}00` : \
            `-${String(Math.abs(时区偏移)).padStart(2, '\''0'\'')}00`;\
        \
        return `${年}-${月}-${日} ${时}:${分}:${秒}${时区偏移量}`;\
    }\
' "$WORKER_FILE"

sed -i '/const 上一个UUIDPromise = 生成UUID(密钥 + (当前周数 - 1));/a \
    const 过期时间 = 计算过期时间();\
' "$WORKER_FILE"

sed -i 's/return Promise.all(\[当前UUIDPromise, 上一个UUIDPromise\]);/return Promise.all([当前UUIDPromise, 上一个UUIDPromise, 过期时间]);/' "$WORKER_FILE"

echo "修改完成！已成功添加过期时间显示功能。"
