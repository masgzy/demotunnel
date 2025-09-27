#!/bin/bash

# 更精确的插入方法

# 备份原文件
cp origin.js origin.js.backup.$(date +%Y%m%d%H%M%S)

# 找到config_Json函数的开始行
config_start_line=$(grep -n "async function config_Json" origin.js | cut -d: -f1)

if [ -z "$config_start_line" ]; then
    echo "错误: 找不到 config_Json 函数"
    exit 1
fi

# 在config_Json函数开头添加过期时间计算函数
sed -i "${config_start_line}a\\
function 获取UUID过期时间(密钥, 更新时间 = 3, 有效时间 = 7) {\
    const 时区偏移 = 8;\
    const 起始日期 = new Date(2007, 6, 7, 更新时间, 0, 0);\
    const 一周的毫秒数 = 1000 * 60 * 60 * 24 * 有效时间;\
\
    function 获取当前周数() {\
        const 现在 = new Date();\
        const 调整后的现在 = new Date(现在.getTime() + 时区偏移 * 60 * 60 * 1000);\
        const 时间差 = Number(调整后的现在) - Number(起始日期);\
        return Math.ceil(时间差 / 一周的毫秒数);\
    }\
\
    const 当前周数 = 获取当前周数();\
    const 结束时间 = new Date(起始日期.getTime() + 当前周数 * 一周的毫秒数);\
\
    function 格式化时间(时间) {\
        const 年 = 时间.getFullYear();\
        const 月 = (时间.getMonth() + 1).toString().padStart(2, '0');\
        const 日 = 时间.getDate().toString().padStart(2, '0');\
        const 时 = 时间.getHours().toString().padStart(2, '0');\
        const 分 = 时间.getMinutes().toString().padStart(2, '0');\
        const 秒 = 时间.getSeconds().toString().padStart(2, '0');\
        \
        return \`\${年}-\${月}-\${日} \${时}:\${分}:\${秒}+08:00\`;\
    }\
\
    return 格式化时间(结束时间);\
}" origin.js

# 找到KEY对象中UUIDLow的位置
uuidlow_line=$(grep -n "UUIDLow: userIDLow || null," origin.js | cut -d: -f1)

if [ -z "$uuidlow_line" ]; then
    echo "错误: 找不到 UUIDLow 字段"
    exit 1
fi

# 在UUIDLow后面添加EXPIRE字段
sed -i "${uuidlow_line}a\\
            EXPIRE: (uuid != userID) ? 获取UUID过期时间(userID, 更新时间, 有效时间) : '永久有效'," origin.js

echo "✅ 过期时间显示功能已成功添加到 origin.js"
echo "📁 已创建备份文件: origin.js.backup.*"
