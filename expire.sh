#!/bin/bash

# 增强版：更精确的插入方法

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
        const 调整后的现在 = new Date(现在.getTime() + 极时区偏移 * 60 * 60 * 1000);\
        const 极时间差 = Number(调整后的现在) - Number(起始日期);\
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

# 找到动态UUID配置中UPTIME的位置（在DynamicUUID: true的块内）
uptime_line=$(awk '/DynamicUUID: true/,/fakeUserID:/ {if (/UPTIME:/) print NR}' origin.js | head -1)

if [ -z "$uptime_line" ]; then
    # 如果找不到，尝试简单查找
    uptime_line=$(grep -n "UPTIME: 更新时间 || null," origin.js | cut -d: -f1 | head -1)
fi

if [ -z "$uptime_line" ]; then
    echo "错误: 找不到 UPTIME 字段"
    exit 1
fi

# 在UPTIME后面添加EXPIRE字段（动态UUID）
sed -i "${uptime_line}a\\
            EXPIRE: 获取UUID过期时间(userID, 更新时间, 有效时间)," origin.js

# 找到非动态UUID配置中UUID的位置（在DynamicUUID: false的块内）
uuid_line=$(awk '/DynamicUUID: false/,/fakeUserID:/ {if (/UUID:/) print NR}' origin.js | head -1)

if [ -z "$uuid_line" ]; then
    # 如果找不到，尝试简单查找
    uuid_line=$(grep -n "UUID: userID.toLowerCase() || null," origin.js | cut -d: -f1 | head -1)
fi

if [ -z "$uuid_line" ]; then
    echo "错误: 找不到 UUID 字段"
    exit 1
fi

# 在UUID后面添加EXPIRE字段（非动态UUID）
sed -i "${uuid_line}a\\
            EXPIRE: '永久有效'," origin.js

echo "✅ 过期时间显示功能已成功添加到 origin.js"
echo "📁 已创建备份文件: origin.js.backup.*"
echo "📋 修改详情:"
echo "   - 动态UUID: EXPIRE 字段已添加到 UPTIME 后面"
echo "   - 非动态UUID: EXPIRE 字段已添加到 UUID 后面"

# 验证修改
echo "🔍 验证修改:"
echo "动态UUID配置:"
sed -n '/DynamicUUID: true/,/fakeUserID:/p' origin.js | grep -E "(UPTIME|EXPIRE)"
echo ""
echo "非动态UUID配置:"
sed -n '/DynamicUUID: false/,/fakeUserID:/p' origin.js | grep -E "(UUID|EXPIRE)"
