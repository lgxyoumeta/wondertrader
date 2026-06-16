#!/bin/bash

# =============================================================
# WonderTrader 环境检测脚本
# 目标：检测 CentOS 7 + Python 3.11 环境是否满足编译运行要求
# 参考文档：第二阶段-第2篇-Linux编译.md
# =============================================================

# 输出同时写入终端和文件（tee 方式，颜色码保留在终端，文件里去掉颜色）
OUTPUT_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/check_env_result.txt"
exec > >(tee >(sed 's/\x1b\[[0-9;]*m//g' > "$OUTPUT_FILE")) 2>&1
echo "检测时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "输出文件: $OUTPUT_FILE"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASS=0
WARN=0
FAIL=0

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_pass() {
    echo -e "  ${GREEN}[PASS]${NC} $1"
    PASS=$((PASS + 1))
}

print_warn() {
    echo -e "  ${YELLOW}[WARN]${NC} $1"
    WARN=$((WARN + 1))
}

print_fail() {
    echo -e "  ${RED}[FAIL]${NC} $1"
    FAIL=$((FAIL + 1))
}

print_info() {
    echo -e "  ${BLUE}[INFO]${NC} $1"
}

# =============================================================
# 1. 操作系统检测
# =============================================================
print_header "1. 操作系统"

OS_NAME=$(cat /etc/os-release 2>/dev/null | grep '^NAME=' | cut -d= -f2 | tr -d '"')
OS_VERSION=$(cat /etc/os-release 2>/dev/null | grep '^VERSION_ID=' | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
ARCH=$(uname -m)
# 兼容 macOS/BSD 和 Linux 的 grep 数字提取函数
extract_version() {
    echo "$1" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}
extract_version_short() {
    echo "$1" | grep -oE '[0-9]+\.[0-9]+' | head -1
}

print_info "系统: ${OS_NAME} ${OS_VERSION}"
print_info "内核: ${KERNEL}"
print_info "架构: ${ARCH}"

if echo "$OS_NAME" | grep -qi "centos"; then
    if [ "$OS_VERSION" = "7" ]; then
        print_warn "CentOS 7 检测到。文档期望 Ubuntu 18.04，但 CentOS 7 可以工作，需要手动处理依赖差异"
    else
        print_warn "CentOS ${OS_VERSION}，非文档要求的 Ubuntu 18.04，注意依赖安装方式不同（yum vs apt）"
    fi
elif echo "$OS_NAME" | grep -qi "ubuntu"; then
    if [ "$OS_VERSION" = "18.04" ]; then
        print_pass "Ubuntu 18.04 完美匹配文档要求"
    else
        print_warn "Ubuntu ${OS_VERSION}，非 18.04，大体可用但 gcc-8 安装方式可能略有不同"
    fi
else
    print_warn "未识别的系统: ${OS_NAME}，请参考文档自行适配"
fi

if [ "$ARCH" != "x86_64" ]; then
    print_fail "架构 ${ARCH} 非 x86_64，WonderTrader 预编译依赖库（mydeps_gcc8.4.0.7z）仅支持 x86_64"
else
    print_pass "架构 x86_64 符合要求"
fi

# =============================================================
# 2. GCC 版本检测
# =============================================================
print_header "2. GCC 编译器"

if command -v gcc &>/dev/null; then
    GCC_VERSION=$(gcc --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    GCC_MAJOR=$(echo "$GCC_VERSION" | cut -d. -f1)
    print_info "当前 gcc 版本: ${GCC_VERSION}"

    if [ "$GCC_MAJOR" -ge 8 ]; then
        print_pass "gcc ${GCC_VERSION} >= 8，满足 C++17 编译要求"
    else
        print_fail "gcc ${GCC_VERSION} < 8，不支持 C++17（-std=c++17），必须升级"
        echo ""
        echo -e "    ${YELLOW}CentOS 7 解决方案（二选一）：${NC}"
        echo "    方案A: 使用 SCL（Software Collections）安装 devtoolset"
        echo "      sudo yum install -y centos-release-scl"
        echo "      sudo yum install -y devtoolset-8-gcc devtoolset-8-gcc-c++"
        echo "      scl enable devtoolset-8 bash   # 进入带 gcc-8 的 shell"
        echo ""
        echo "    方案B: 直接用 Docker（最省事，官方 Dockerfile 已配好）"
        echo "      cd my_wondertrader/wondertrader/docker"
        echo "      docker build -t wondertrader -f Dockerfile ."
        echo "      docker run -it wondertrader /bin/bash"
    fi
else
    print_fail "gcc 未安装"
    echo "    CentOS 7: sudo yum install -y gcc gcc-c++"
fi

# 检测 gcc-8 是否单独存在（SCL 方式安装）
if command -v gcc-8 &>/dev/null; then
    print_pass "gcc-8 可用（$(gcc-8 --version | head -1)）"
elif [ -f /opt/rh/devtoolset-8/root/usr/bin/gcc ]; then
    print_warn "SCL devtoolset-8 已安装，但未激活。使用时需要：scl enable devtoolset-8 bash"
fi

if command -v g++ &>/dev/null; then
    GPP_VERSION=$(g++ --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    print_info "当前 g++ 版本: ${GPP_VERSION}"
else
    print_fail "g++ 未安装"
fi

# =============================================================
# 3. CMake 检测
# =============================================================
print_header "3. CMake"

if command -v cmake &>/dev/null; then
    CMAKE_VERSION=$(cmake --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    CMAKE_MAJOR=$(echo "$CMAKE_VERSION" | cut -d. -f1)
    CMAKE_MINOR=$(echo "$CMAKE_VERSION" | cut -d. -f2)
    print_info "cmake 版本: ${CMAKE_VERSION}"

    # WonderTrader CMakeLists.txt 一般要求 cmake >= 3.10
    if [ "$CMAKE_MAJOR" -ge 3 ] && [ "$CMAKE_MINOR" -ge 10 ]; then
        print_pass "cmake ${CMAKE_VERSION} 满足要求（需要 >= 3.10）"
    else
        print_fail "cmake ${CMAKE_VERSION} 过旧，建议升级到 3.10+"
        echo "    CentOS 7: sudo yum install -y cmake3  （注意命令是 cmake3，不是 cmake）"
        echo "    或从官网下载最新版: https://cmake.org/download/"
    fi
else
    print_fail "cmake 未安装"
    echo "    CentOS 7: sudo yum install -y cmake3"
fi

# =============================================================
# 4. 解压工具检测（7z）
# =============================================================
print_header "4. 解压工具 (7z / p7zip)"

if command -v 7za &>/dev/null || command -v 7z &>/dev/null; then
    SEVENZ_CMD=$(command -v 7za || command -v 7z)
    print_pass "7z 可用: ${SEVENZ_CMD}"
else
    print_fail "7z/7za 未安装，无法解压 mydeps_gcc8.4.0.7z"
    echo "    CentOS 7: sudo yum install -y p7zip p7zip-plugins"
    echo "    Ubuntu:   sudo apt-get install -y p7zip-full"
fi

# =============================================================
# 5. 预编译依赖库检测（/home/mydeps）
# =============================================================
print_header "5. WonderTrader 预编译依赖库 (/home/mydeps)"

if [ -d "/home/mydeps" ]; then
    print_pass "/home/mydeps 目录存在"

    if [ -d "/home/mydeps/include" ]; then
        print_pass "/home/mydeps/include 存在"
        # 检查 boost
        if [ -d "/home/mydeps/include/boost" ]; then
            BOOST_VER=$(cat /home/mydeps/include/boost/version.hpp 2>/dev/null | grep '#define BOOST_LIB_VERSION' | grep -oE '"[^"]+"' | tr -d '"')
            print_pass "boost 头文件存在，版本: ${BOOST_VER:-未知}"
        else
            print_fail "/home/mydeps/include/boost 不存在，CMake 编译会报 boost 头文件找不到"
        fi
    else
        print_fail "/home/mydeps/include 不存在"
    fi

    if [ -d "/home/mydeps/lib" ]; then
        LIB_COUNT=$(ls /home/mydeps/lib/*.a 2>/dev/null | wc -l)
        SO_COUNT=$(ls /home/mydeps/lib/*.so* 2>/dev/null | wc -l)
        print_pass "/home/mydeps/lib 存在（.a 文件: ${LIB_COUNT} 个，.so 文件: ${SO_COUNT} 个）"
    else
        print_fail "/home/mydeps/lib 不存在，链接时会找不到依赖库"
    fi
else
    print_warn "/home/mydeps 不存在，需要下载并解压预编译依赖包"
    echo ""
    echo "    操作步骤："
    echo "    1. 从 WonderTrader Gitee Releases 页下载 mydeps_gcc8.4.0.7z"
    echo "       https://gitee.com/wondertrader/wondertrader/releases"
    echo "    2. cd /home"
    echo "    3. sudo 7za x /path/to/mydeps_gcc8.4.0.7z"
    echo "    4. ls /home/mydeps/   # 应看到 include 和 lib"
fi

# =============================================================
# 6. Python 环境检测
# =============================================================
print_header "6. Python 环境"

# 检测 python3
PYTHON_CMD=""
for cmd in python3.11 python3 python; do
    if command -v "$cmd" &>/dev/null; then
        PY_VERSION=$("$cmd" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
        PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
        if [ "$PY_MAJOR" = "3" ] && [ "$PY_MINOR" -ge 8 ]; then
            PYTHON_CMD="$cmd"
            break
        fi
    fi
done

if [ -n "$PYTHON_CMD" ]; then
    print_pass "Python 可用: $(command -v $PYTHON_CMD) -> ${PY_VERSION}"
    print_info "使用命令: ${PYTHON_CMD}"

    if [ "$PY_MINOR" -ge 11 ]; then
        print_warn "Python ${PY_VERSION}：wtpy 的官方测试环境通常是 3.8/3.9/3.10，3.11+ 可能有兼容性问题，建议跑通后再确认"
    fi
else
    print_fail "未找到 Python 3.8+，wtpy 需要 Python >= 3.8"
    echo "    CentOS 7 安装 Python 3.11："
    echo "    sudo yum install -y python3.11  （或通过 pyenv、源码编译安装）"
fi

# pip 检测
if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
    PIP_CMD=$(command -v pip3 || command -v pip)
    PIP_VERSION=$($PIP_CMD --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    print_pass "pip 可用: ${PIP_CMD} (${PIP_VERSION})"
else
    print_fail "pip 未安装"
    echo "    ${PYTHON_CMD:-python3} -m ensurepip --upgrade"
fi

# 检测 wtpy 关键依赖
print_info "检测 wtpy 运行依赖..."
for pkg in numpy pandas; do
    if ${PYTHON_CMD:-python3} -c "import $pkg" 2>/dev/null; then
        PKG_VER=$(${PYTHON_CMD:-python3} -c "import $pkg; print($pkg.__version__)" 2>/dev/null)
        print_pass "Python 包 ${pkg} 已安装（${PKG_VER}）"
    else
        print_warn "Python 包 ${pkg} 未安装（wtpy 需要），运行 demo 前需先安装"
        echo "    ${PYTHON_CMD:-pip3} install ${pkg}"
    fi
done

# =============================================================
# 7. 系统资源检测
# =============================================================
print_header "7. 系统资源"

# CPU 核心数
CPU_CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "未知")
print_info "CPU 核心数: ${CPU_CORES}（编译时 make -j${CPU_CORES} 可充分利用）"

# 内存
TOTAL_MEM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
if [ -n "$TOTAL_MEM_KB" ]; then
    TOTAL_MEM_GB=$(echo "scale=1; $TOTAL_MEM_KB / 1024 / 1024" | bc 2>/dev/null || echo "$((TOTAL_MEM_KB / 1024 / 1024))")
    print_info "总内存: ${TOTAL_MEM_GB} GB"
    if [ "$TOTAL_MEM_KB" -lt 2097152 ]; then  # < 2GB
        print_warn "内存不足 2GB，编译时可能 OOM，建议至少 4GB"
    else
        print_pass "内存充足（${TOTAL_MEM_GB} GB）"
    fi
fi

# 磁盘空间
DISK_AVAIL=$(df -BG /home 2>/dev/null | tail -1 | awk '{print $4}' | tr -d 'G')
if [ -n "$DISK_AVAIL" ]; then
    print_info "/home 可用磁盘: ${DISK_AVAIL} GB"
    if [ "$DISK_AVAIL" -lt 5 ]; then
        print_warn "/home 可用空间 < 5GB，解压依赖库 + 编译产物可能空间不足"
    else
        print_pass "/home 磁盘空间充足（${DISK_AVAIL} GB 可用）"
    fi
fi

# =============================================================
# 8. 网络工具检测
# =============================================================
print_header "8. 网络与工具"

for tool in git wget curl; do
    if command -v "$tool" &>/dev/null; then
        print_pass "${tool} 已安装"
    else
        print_warn "${tool} 未安装"
        echo "    CentOS 7: sudo yum install -y ${tool}"
    fi
done

# =============================================================
# 9. Docker 检测（备用方案）
# =============================================================
print_header "9. Docker（备用编译方案）"

if command -v docker &>/dev/null; then
    DOCKER_VERSION=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    print_pass "Docker 已安装（${DOCKER_VERSION}）"
    print_info "如果本机编译困难，可直接用 Dockerfile 构建："
    print_info "  cd wondertrader/docker && docker build -t wondertrader -f Dockerfile ."
else
    print_info "Docker 未安装（非必须，但是最稳妥的备用编译方案）"
fi

# =============================================================
# 10. wondertrader 仓库检测
# =============================================================
print_header "10. 仓库状态"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WT_REPO="${SCRIPT_DIR}/wondertrader"
WTPY_REPO="${SCRIPT_DIR}/wtpy"

if [ -d "${WT_REPO}/src" ]; then
    print_pass "wondertrader 仓库存在: ${WT_REPO}"
    SRC_MODULES=$(ls "${WT_REPO}/src" | wc -l)
    print_info "src/ 下模块数量: ${SRC_MODULES}"
else
    print_fail "wondertrader/src 不存在，请先克隆仓库"
    echo "    git clone https://gitee.com/wondertrader/wondertrader.git"
fi

if [ -d "${WTPY_REPO}/wtpy" ]; then
    print_pass "wtpy 仓库存在: ${WTPY_REPO}"

    LINUX_SO_DIR="${WTPY_REPO}/wtpy/wrapper/linux"
    if [ -d "$LINUX_SO_DIR" ]; then
        SO_COUNT=$(ls "${LINUX_SO_DIR}"/*.so 2>/dev/null | wc -l)
        if [ "$SO_COUNT" -gt 0 ]; then
            print_pass "wtpy/wrapper/linux/ 已有 .so 文件（${SO_COUNT} 个），C++ 已编译并复制"
        else
            print_warn "wtpy/wrapper/linux/ 目录存在但无 .so 文件，需要先完成 C++ 编译"
        fi
    else
        print_warn "wtpy/wrapper/linux/ 目录不存在，编译完成后运行 copy_bins_linux.sh 会创建"
    fi
else
    print_warn "wtpy 仓库不存在，请克隆"
    echo "    git clone https://gitee.com/wondertrader/wtpy.git"
fi

# =============================================================
# 汇总报告
# =============================================================
print_header "检测结果汇总"

TOTAL=$((PASS + WARN + FAIL))
echo ""
echo -e "  ${GREEN}PASS${NC}: ${PASS}  ${YELLOW}WARN${NC}: ${WARN}  ${RED}FAIL${NC}: ${FAIL}  总计: ${TOTAL}"
echo ""

if [ "$FAIL" -eq 0 ] && [ "$WARN" -eq 0 ]; then
    echo -e "  ${GREEN}✓ 环境完全就绪，可以按文档步骤直接开始编译！${NC}"
elif [ "$FAIL" -eq 0 ]; then
    echo -e "  ${YELLOW}⚠ 存在 ${WARN} 个警告，建议处理后再编译（WARN 不影响基本流程，但可能有风险）${NC}"
else
    echo -e "  ${RED}✗ 存在 ${FAIL} 个错误，需要先解决再开始编译${NC}"
fi

echo ""
echo -e "  ${BLUE}=== CentOS 7 与 Ubuntu 18.04 的关键差异提示 ===${NC}"
echo "  1. 包管理器: apt-get → yum"
echo "  2. gcc-8 安装: apt install gcc-8 → yum install devtoolset-8 (SCL)"
echo "     激活方式: scl enable devtoolset-8 bash  （每次新 shell 都需要）"
echo "     或永久写入: echo 'source /opt/rh/devtoolset-8/enable' >> ~/.bashrc"
echo "  3. p7zip 安装: apt install p7zip-full → yum install p7zip p7zip-plugins"
echo "  4. cmake: CentOS 7 的 cmake 版本较老，可能需要安装 cmake3"
echo "     安装后命令是 cmake3，可软链: sudo ln -s /usr/bin/cmake3 /usr/bin/cmake"
echo "  5. 预编译依赖包 mydeps_gcc8.4.0.7z 是基于 gcc 8.4.0 编译的"
echo "     CentOS 7 用 SCL devtoolset-8 安装的 gcc 版本也是 8.x，兼容"
echo ""
echo "  推荐流程（CentOS 7）："
echo "  Step 1: sudo yum install -y centos-release-scl"
echo "  Step 2: sudo yum install -y devtoolset-8-gcc devtoolset-8-gcc-c++ cmake3 p7zip p7zip-plugins git"
echo "  Step 3: scl enable devtoolset-8 bash   （进入 gcc-8 环境）"
echo "  Step 4: sudo ln -sf /usr/bin/cmake3 /usr/bin/cmake  （可选）"
echo "  Step 5: 下载解压 mydeps_gcc8.4.0.7z 到 /home/"
echo "  Step 6: 按文档第四步开始 cmake 构建"
echo ""
