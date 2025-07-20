#!/bin/bash

# Local build and test script for dev container base images
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TEMPLATES=("dbt-fusion" "dbt-cloud-cli")
REGISTRY="localhost:5000"  # Local registry
REPO_NAME="devcontainer-templates"

echo -e "${YELLOW}Starting local dev container build and test...${NC}"

# Function to build a template
build_template() {
    local template=$1
    local dockerfile_path="./src/${template}/.devcontainer/Dockerfile"
    local context_path="./src/${template}"
    
    echo -e "${YELLOW}Building ${template}...${NC}"
    
    if [ ! -f "$dockerfile_path" ]; then
        echo -e "${RED}Error: Dockerfile not found at $dockerfile_path${NC}"
        return 1
    fi
    
    # Build the image
    docker build \
        -t "${REGISTRY}/${REPO_NAME}/${template}:local" \
        -t "${REGISTRY}/${REPO_NAME}/${template}:latest" \
        -f "$dockerfile_path" \
        "$context_path"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully built ${template}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed to build ${template}${NC}"
        return 1
    fi
}

# Function to test a template
test_template() {
    local template=$1
    local image="${REGISTRY}/${REPO_NAME}/${template}:local"
    
    echo -e "${YELLOW}Testing ${template}...${NC}"
    
    # Basic test - check if image runs
    docker run --rm "$image" echo "Container startup test passed"
    
    # Core development tools
    echo "  Checking core tools..."
    docker run --rm "$image" which python3 > /dev/null && echo "  ✓ Python3 available" || echo "  ✗ Python3 missing"
    docker run --rm "$image" which git > /dev/null && echo "  ✓ Git available" || echo "  ✗ Git missing"
    
    # Modern Python tooling
    echo "  Checking Python ecosystem..."
    docker run --rm "$image" which uv > /dev/null && echo "  ✓ uv available" || echo "  ✗ uv missing"
    docker run --rm "$image" which pre-commit > /dev/null && echo "  ✓ pre-commit available" || echo "  ✗ pre-commit missing"
    
    # System utilities
    echo "  Checking system utilities..."
    docker run --rm "$image" which xdg-open > /dev/null && echo "  ✓ xdg-utils available" || echo "  ✗ xdg-utils missing"
    
    # Claude Code CLI
    echo "  Checking AI tools..."
    docker run --rm "$image" which claude > /dev/null && echo "  ✓ Claude Code available" || echo "  ✗ Claude Code missing"
    
    # Version checks for available tools
    echo "  Checking versions..."
    docker run --rm "$image" sh -c "python3 --version 2>/dev/null || echo '  ! Python3 version check failed'"
    docker run --rm "$image" sh -c "uv --version 2>/dev/null || echo '  ! uv version check failed'"
    docker run --rm "$image" sh -c "pre-commit --version 2>/dev/null || echo '  ! pre-commit version check failed'"
    docker run --rm "$image" sh -c "claude --version 2>/dev/null || echo '  ! Claude Code version check failed'"
    
    # If dbt-specific, test dbt
    if [[ "$template" == *"dbt"* ]]; then
        echo "  Checking DBT tools..."
        docker run --rm "$image" which dbt > /dev/null && echo "  ✓ DBT available" || echo "  ✗ DBT missing"
        docker run --rm "$image" sh -c "dbt --version 2>/dev/null || echo '  ! DBT version check failed'"
    fi
    
    # Test functional capabilities
    echo "  Testing functionality..."
    
    # Test uv basic functionality
    docker run --rm "$image" sh -c "uv --help > /dev/null 2>&1 && echo '  ✓ uv functional'" || echo "  ✗ uv not functional"
    
    # Test pre-commit basic functionality
    docker run --rm "$image" sh -c "pre-commit --help > /dev/null 2>&1 && echo '  ✓ pre-commit functional'" || echo "  ✗ pre-commit not functional"
    
    # Test xdg-utils (check if xdg-open exists and can show help)
    docker run --rm "$image" sh -c "xdg-open --help > /dev/null 2>&1 && echo '  ✓ xdg-utils functional'" || echo "  ✗ xdg-utils not functional"
    
    # Test Claude Code (if available)
    docker run --rm "$image" sh -c "claude --help > /dev/null 2>&1 && echo '  ✓ Claude Code functional'" || echo "  ✗ Claude Code not functional"
    
    echo -e "${GREEN}✓ Tests completed for ${template}${NC}"
}

# Function to start local registry
start_local_registry() {
    if ! docker ps | grep -q "registry:2"; then
        echo -e "${YELLOW}Starting local Docker registry...${NC}"
        docker run -d -p 5000:5000 --name registry registry:2
    else
        echo -e "${GREEN}Local registry already running${NC}"
    fi
}

# Function to run comprehensive tool tests
comprehensive_test() {
    local template=$1
    local image="${REGISTRY}/${REPO_NAME}/${template}:local"
    
    echo -e "${YELLOW}Running comprehensive tests for ${template}...${NC}"
    
    # Create a test script inside the container
    local test_script="
#!/bin/bash
echo '=== Comprehensive Tool Test ==='
echo 'Container: $template'
echo 'Date: \$(date)'
echo

# Function to test command availability and functionality
test_tool() {
    local tool=\$1
    local test_cmd=\$2
    
    if command -v \$tool >/dev/null 2>&1; then
        echo \"✓ \$tool: INSTALLED\"
        if [ -n \"\$test_cmd\" ]; then
            if eval \$test_cmd >/dev/null 2>&1; then
                echo \"  ✓ Functional test passed\"
            else
                echo \"  ✗ Functional test failed\"
            fi
        fi
        # Try to get version
        for version_flag in '--version' '--help' 'version' '-V' '-v'; do
            if \$tool \$version_flag 2>/dev/null | head -1 | grep -E '[0-9]+\.[0-9]+' >/dev/null; then
                echo \"  Version: \$(\$tool \$version_flag 2>/dev/null | head -1)\"
                break
            fi
        done
    else
        echo \"✗ \$tool: NOT FOUND\"
    fi
    echo
}

echo '=== Core Development Tools ==='
test_tool 'python3' 'python3 -c \"import sys; print(sys.version)\"'
test_tool 'git' 'git --version'
test_tool 'curl' 'curl --version'
test_tool 'wget' 'wget --version'

echo '=== Modern Python Ecosystem ==='
test_tool 'uv' 'uv --help'
test_tool 'pip' 'pip --version'
test_tool 'pre-commit' 'pre-commit --help'

echo '=== System Utilities ==='
test_tool 'xdg-open' 'xdg-open --help'
test_tool 'xdg-mime' 'xdg-mime --help'

echo '=== AI Development Tools ==='
test_tool 'claude' 'claude --help'

echo '=== DBT Ecosystem ==='
test_tool 'dbt' 'dbt --help'

echo '=== Additional Development Tools ==='
test_tool 'node' 'node --version'
test_tool 'npm' 'npm --version'
test_tool 'make' 'make --version'
test_tool 'docker' 'docker --version'
test_tool 'ssh' 'ssh -V'

echo '=== Environment Information ==='
echo \"OS: \$(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')\"
echo \"Shell: \$SHELL\"
echo \"User: \$(whoami)\"
echo \"Working Directory: \$(pwd)\"
echo \"PATH: \$PATH\"
echo

echo '=== Package Manager Tests ==='
if command -v apt >/dev/null 2>&1; then
    echo \"✓ APT package manager available\"
elif command -v yum >/dev/null 2>&1; then
    echo \"✓ YUM package manager available\"
elif command -v apk >/dev/null 2>&1; then
    echo \"✓ APK package manager available\"
else
    echo \"! No recognized package manager found\"
fi

echo
echo '=== Test Summary ==='
echo \"Test completed at: \$(date)\"
"
    
    # Run the comprehensive test
    docker run --rm "$image" sh -c "$test_script"
}

# Function to test all tools in a container interactively
interactive_test() {
    local template=$1
    local image="${REGISTRY}/${REPO_NAME}/${template}:local"
    
    echo -e "${YELLOW}Starting interactive test session for ${template}...${NC}"
    echo "You can now test tools manually. Type 'exit' to leave."
    
    docker run -it "$image" /bin/bash
}

# Function to push to local registry
push_to_local_registry() {
    local template=$1
    echo -e "${YELLOW}Pushing ${template} to local registry...${NC}"
    docker push "${REGISTRY}/${REPO_NAME}/${template}:local"
    docker push "${REGISTRY}/${REPO_NAME}/${template}:latest"
    echo -e "${GREEN}✓ Pushed ${template} to local registry${NC}"
}

# Function to stop local registry
stop_local_registry() {
    if docker ps | grep -q "registry:2"; then
        echo -e "${YELLOW}Stopping local Docker registry...${NC}"
        docker stop registry && docker rm registry
    fi
}

# Main execution
case "${1:-all}" in
    "build")
        echo "Building all templates..."
        for template in "${TEMPLATES[@]}"; do
            build_template "$template"
        done
        ;;
    "test")
        echo "Testing all templates..."
        for template in "${TEMPLATES[@]}"; do
            test_template "$template"
        done
        ;;
    "comprehensive")
        echo "Running comprehensive tests..."
        for template in "${TEMPLATES[@]}"; do
            comprehensive_test "$template"
        done
        ;;
    "interactive")
        template=${2:-dbt-fusion}
        if [[ " ${TEMPLATES[@]} " =~ " ${template} " ]]; then
            interactive_test "$template"
        else
            echo -e "${RED}Error: Template '$template' not found. Available: ${TEMPLATES[*]}${NC}"
        fi
        ;;
    "registry")
        start_local_registry
        for template in "${TEMPLATES[@]}"; do
            build_template "$template"
            push_to_local_registry "$template"
        done
        echo -e "${GREEN}All images available at localhost:5000${NC}"
        echo "To stop registry: $0 stop-registry"
        ;;
    "stop-registry")
        stop_local_registry
        ;;
    "all"|*)
        echo "Building and testing all templates..."
        for template in "${TEMPLATES[@]}"; do
            build_template "$template" && test_template "$template"
        done
        ;;
esac

echo -e "${GREEN}Done!${NC}"