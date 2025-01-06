#!/bin/bash

# 定义 SSH 配置文件路径
sshd_config_path="/etc/ssh/sshd_config"

# 检查是否有管理员权限
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 用户身份运行此脚本！"
  exit 1
fi

# 提示用户输入新的 root 密码
echo "请先设置 root 用户的新密码。"
while true; do
  read -s -p "请输入新密码: " root_password
  echo
  read -s -p "请再次确认新密码: " root_password_confirm
  echo
  if [ "$root_password" == "$root_password_confirm" ]; then
    echo "密码匹配，开始设置 root 用户密码..."
    echo "root:$root_password" | chpasswd
    if [ $? -eq 0 ]; then
      echo "root 密码设置成功！"
    else
      echo "设置密码失败，请检查系统权限或配置！"
      exit 1
    fi
    break
  else
    echo "两次输入的密码不匹配，请重新输入。"
  fi
done

echo "开始修改 SSH 配置以允许 root 密码登录..."

# 备份原始配置文件
if [ ! -f "${sshd_config_path}.bak" ]; then
  cp "$sshd_config_path" "${sshd_config_path}.bak"
  echo "已备份原始配置文件为 ${sshd_config_path}.bak"
else
  echo "备份文件已存在，跳过备份步骤。"
fi

# 修改 SSH 配置文件
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' "$sshd_config_path"
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' "$sshd_config_path"
sed -i '/^AuthenticationMethods/s/^/#/' "$sshd_config_path"

echo "配置已修改："
echo "- 允许 root 密码登录 (PermitRootLogin yes)"
echo "- 启用密码认证 (PasswordAuthentication yes)"
echo "- 禁用强制公钥认证 (注释 AuthenticationMethods 条目)"

# 重启 SSH 服务
echo "重启 SSH 服务..."
sudo systemctl restart ssh.service

if [ $? -eq 0 ]; then
  echo "SSH 服务已成功重启，修改生效！"
  echo "现在可以通过 root 用户和密码登录了。"
else
  echo "SSH 服务重启失败，请检查配置文件或系统日志！"
fi
