#!/bin/bash

# ZeroTier 安装与配置恢复脚本
# 作者：DeepSeek-R1
# 日期：2025-06-13

# 配置区域（根据你的实际情况修改）
GITHUB_REPO="https://github.com/qw1642190428/zerotier"
BACKUP_PATH="zerotier-one"  # 例如 "backups/zerotier" 或空字符串如果是根目录
ZEROTIER_DIR="/var/lib/zerotier-one"

# 检查是否以 root 运行
if [ "$(id -u)" -ne 0 ]; then
    echo "错误：此脚本必须以 root 权限运行！"
    echo "请使用 sudo 执行此脚本"
    exit 1
fi

# 步骤 1: 安装 ZeroTier
echo "正在安装 ZeroTier..."
curl -s https://install.zerotier.com | bash

# 检查安装是否成功
if ! command -v zerotier-cli &> /dev/null; then
    echo "错误：ZeroTier 安装失败！"
    exit 1
fi

echo "ZeroTier 安装成功！"

# 步骤 2: 停止 ZeroTier 服务
echo "停止 ZeroTier 服务..."
systemctl stop zerotier-one

# 步骤 3: 创建备份目录
BACKUP_DIR="/tmp/zerotier_backup_$(date +%s)"
echo "创建临时下载目录: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# 步骤 4: 下载 GitHub 上的配置文件
echo "正在下载配置文件..."
if command -v git &> /dev/null; then
    echo "使用 git 下载..."
    git clone "$GITHUB_REPO" "$BACKUP_DIR"
else
    echo "使用 wget 下载..."
    wget -qO "$BACKUP_DIR/backup.zip" "$GITHUB_REPO/archive/main.zip"
    unzip "$BACKUP_DIR/backup.zip" -d "$BACKUP_DIR"
    mv "$BACKUP_DIR/$(basename $GITHUB_REPO)-main"/* "$BACKUP_DIR"
    rm -r "$BACKUP_DIR/$(basename $GITHUB_REPO)-main"
fi

# 检查下载是否成功
if [ ! -d "$BACKUP_DIR/$BACKUP_PATH" ]; then
    echo "错误：配置文件下载失败或路径不正确！"
    echo "请检查 GITHUB_REPO 和 BACKUP_PATH 设置"
    exit 1
fi

# 步骤 5: 备份现有配置（安全措施）
echo "备份现有配置到 /tmp/zerotier_backup_old..."
cp -r "$ZEROTIER_DIR" "/tmp/zerotier_backup_old"

# 步骤 6: 覆盖配置文件
echo "覆盖 ZeroTier 配置文件..."
SOURCE_DIR="$BACKUP_DIR/$BACKUP_PATH"

# 删除现有配置（保留目录结构）
find "$ZEROTIER_DIR" -mindepth 1 -delete

# 复制新配置
cp -r "$SOURCE_DIR"/* "$ZEROTIER_DIR/"

# 修复权限
echo "修复文件权限..."
chown -R zerotier-one:zerotier-one "$ZEROTIER_DIR"
chmod 700 "$ZEROTIER_DIR"
find "$ZEROTIER_DIR" -type f -exec chmod 600 {} \;
find "$ZEROTIER_DIR" -type d -exec chmod 700 {} \;

# 步骤 7: 启动服务
echo "启动 ZeroTier 服务..."
systemctl start zerotier-one

# 步骤 8: 清理临时文件
echo "清理临时文件..."
rm -rf "$BACKUP_DIR"

# 步骤 9: 验证状态
echo "等待服务启动..."
sleep 3
echo -e "\nZeroTier 状态:"
zerotier-cli status

echo -e "\n网络信息:"
zerotier-cli listnetworks

echo -e "\n节点信息:"
zerotier-cli info

echo -e "\n✅ 操作完成！你的 ZeroTier 配置已恢复。"
