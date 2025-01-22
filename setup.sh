#!/bin/bash

# Color definitions
BLUE="\033[38;5;39m"
GREEN="\033[38;5;82m"
PURPLE="\033[38;5;171m"
ORANGE="\033[38;5;214m"
RED="\033[38;5;196m"
GRAY="\033[38;5;245m"
RESET="\033[0m"
BOLD="\033[1m"

# Spinner animation frames with consistent style
SPINNER_FRAMES=("◐" "◓" "◑" "◒")

print_banner() {
    clear
    echo -e "\033[38;5;218m   ('-.                                           .-') _           .-')      ('-.   .-') _                 _ (\`-. "
    echo -e "\033[38;5;218m _(  OO)                                         (  OO) )         ( OO ).  _(  OO) (  OO) )               ( (OO  )"
    echo -e "\033[38;5;218m(,------.,--.      ,--.      ,-.-')  .-'),-----. /     '._       (_)---\_)(,------./     '._ ,--. ,--.   _.\`     \\"
    echo -e "\033[38;5;218m |  .---'|  |.-')  |  |.-')  |  |OO)( OO'  .-.  '|'--...__)      /    _ |  |  .---'|'--...__)|  | |  |  (__...--''"
    echo -e "\033[38;5;218m |  |    |  | OO ) |  | OO ) |  |  \/   |  | |  |'--.  .--'      \\  :\` \`.  |  |    '--.  .--'|  | | .-') |  /  | |"
    echo -e "\033[38;5;218m(|  '--. |  |\`-' | |  |\`-' | |  |(_/\_) |  |\\|  |   |  |          '..\"''.)(|  '--.    |  |   |  |_|( OO )|  |_.' |"
    echo -e "\033[38;5;218m |  .--'(|  '---.'(|  '---.',|  |_.'  \\ |  | |  |   |  |         .-._)   \\ |  .--'    |  |   |  | | \`-' /|  .___.' "
    echo -e "\033[38;5;218m |  \`---.|      |  |      |(_|  |      \`'  '-'  '   |  |         \\       / |  \`---.   |  |  ('  '-'(_.-' |  |      "
    echo -e "\033[38;5;218m \`------'\`------'  \`------'  \`--'        \`-----'    \`--'          \`-----'  \`------'   \`--'    \`-----'    \`--'      "
    echo -e "\033[0m"
    echo -e "${BLUE}${BOLD} ${RESET}"
    printf "${BLUE}%-${COLUMNS}s${RESET}" " " | tr ' ' ' '
    echo ""
}

# Enhanced status display functions with consistent styling
show_spinner() {
    local pid=$1
    local message=$2
    local frame=0
    
    while kill -0 $pid 2>/dev/null; do
        echo -ne "\r${BLUE}${SPINNER_FRAMES[frame]} ${message}${RESET}"
        frame=$(( (frame + 1) % ${#SPINNER_FRAMES[@]} ))
        sleep 0.1
    done
    echo -ne "\r"
}

clear_line() {
    printf "\033[1A\033[K"
}

update_status() {
    local message=$1
    local color=${2:-$BLUE}
    local position=$((LINES-2))
    printf "\033[${position};0H\033[K"
    printf "\033[${position};0H%b%s${RESET}" "$color" "$message"
}

print_status() {
    update_status "⚡ $1" "$BLUE"
}

print_success() {
    update_status "✨ $1" "$GREEN"
}

print_error() {
    update_status "✖ $1" "$RED"
}

# Function to get user input for framework options
get_framework_options() {
    local framework_index=$1
    local options=$(jq -r ".frameworks[$framework_index].options" "$config_file")
    local automatic_flags=$(jq -r ".frameworks[$framework_index].automaticFlags" "$config_file")
    local command_args=""
    
    # Loop through each option for the framework (just project name now)
    local num_options=$(echo "$options" | jq length)
    for ((i=0; i<$num_options; i++)); do
        local prompt=$(echo "$options" | jq -r ".[$i].prompt")
        local flag=$(echo "$options" | jq -r ".[$i].flag")
        local required=$(echo "$options" | jq -r ".[$i].required // false")
        
        local user_input=""
        while [ -z "$user_input" ] && [ "$required" = "true" ]; do
            read -p "$prompt: " user_input
            if [ -z "$user_input" ] && [ "$required" = "true" ]; then
                echo "This field is required. Please try again."
            fi
        done
        
        if [ ! -z "$user_input" ]; then
            # Replace spaces with dashes in project name
            user_input="${user_input// /-}"
            command_args="$user_input"
        fi
    done
    
    # Add automatic flags after the project name
    command_args="$command_args $automatic_flags"
    
    echo "$command_args"
}

# Function to display menu and get user selection
display_menu() {
    local config_file="config.json"
    if [ ! -f "$config_file" ]; then
        print_error "Configuration file not found"
        exit 1
    fi

    print_banner
    
    # Calculate available space
    local menu_start=$((LINES-10))
    printf "\033[${menu_start};0H"  # Move cursor to menu start position
    
    echo -e "\n${BLUE}${BOLD}📦 Select a Framework${RESET}\n"
    printf "${BLUE}%-${COLUMNS}s${RESET}\n" "-" | tr ' ' '-'
    
    local frameworks=$(jq -r '.frameworks[] | "\(.name)|\(.description)"' "$config_file")
    local i=1
    
    # Get the maximum width of framework names for proper padding
    local max_name_width=0
    while IFS='|' read -r name description; do
        local name_length=${#name}
        if ((name_length > max_name_width)); then
            max_name_width=$name_length
        fi
    done <<< "$frameworks"
    
    # Add some padding
    max_name_width=$((max_name_width + 4))
    
    # Display frameworks with consistent styling
    while IFS='|' read -r name description; do
        printf "${GRAY}  %d)${RESET} ${BLUE}${BOLD}%-${max_name_width}s${RESET} ${GRAY}%s${RESET}\n" "$i" "$name" "$description"
        ((i++))
    done <<< "$frameworks"
    
    printf "\n${BLUE}%-${COLUMNS}s${RESET}\n" "-" | tr ' ' '-'
    
    local valid_selection=false
    while [ "$valid_selection" = false ]; do
        printf "\n${BLUE}${SPINNER_FRAMES[0]}${RESET} Enter your choice ${GRAY}(1-%d)${RESET}: " "$((i-1))"
        read -r selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le $((i-1)) ]; then
            valid_selection=true
        else
            clear_line
            print_error "Invalid selection. Please try again."
            sleep 1
            clear_line
            clear_line
        fi
    done
    
    local framework_index=$((selection-1))
    local framework_name=$(jq -r ".frameworks[$framework_index].name" "$config_file")
    
    print_banner
    print_status "Setting up $framework_name..."
    
    local base_command=$(jq -r ".frameworks[$framework_index].command" "$config_file")
    local options=$(get_framework_options $framework_index)
    
    # Extract project name from options
    local project_name=$(echo "$options" | awk '{print $1}')
    
    if [ -n "$project_name" ]; then
        handle_project_creation "$project_name" "$framework_name" "$base_command" "$options"
    else
        print_error "Project name is required"
        exit 1
    fi
}

# Enhanced project creation handler
handle_project_creation() {
    local project_name=$1
    local framework=$2
    local base_command=$3
    local options=$4
    
    exec 3>&1 4>&2
    local temp_output=$(mktemp)
    
    (eval "$base_command $options" > "$temp_output" 2>&1) &
    local pid=$!
    
    local center_position=$((LINES/2))
    local phases=(
        "${BLUE}📦 Initializing project structure"
        "${PURPLE}⚡ Installing core dependencies"
        "${GREEN}🔧 Configuring development environment"
        "${ORANGE}🎨 Setting up styling utilities"
        "${BLUE}📝 Generating template files"
        "${PURPLE}🔍 Running initial checks"
        "${GREEN}🚀 Finalizing setup"
    )
    
    # Enhanced progress bar settings
    local fill="█"
    local empty="▒"
    local bar_size=40
    local progress=0
    local phase_index=0
    
    tput sc
    tput civis
    
    while kill -0 $pid 2>/dev/null; do
        tput rc
        
        local current_phase=${phases[$phase_index]}
        
        local filled=$((progress * bar_size / 100))
        local empty_count=$((bar_size - filled))
        
        printf "\033[K\n"  # Clear line
        printf "%b${RESET}\n" "$current_phase "
        
        # Print the filled portion
        printf "${BLUE}"
        printf "%*s" "$filled" | tr ' ' "$fill"
        
        # Print the empty portion
        printf "${GRAY}"
        printf "%*s" "$empty_count" | tr ' ' "$empty"
        
        # Print percentage
        printf "${RESET} [%3d%%]\n" "$progress"
        
        # Print spinner and framework
        printf "${BLUE}%s${RESET} Setting up ${BOLD}%s${RESET}...\n" "${SPINNER_FRAMES[$((progress % ${#SPINNER_FRAMES[@]}))]}" "$framework"
        
        progress=$((progress + 1))
        if [ $progress -ge 100 ]; then 
            progress=0
            phase_index=$(((phase_index + 1) % ${#phases[@]}))
        fi
        
        sleep 0.1
    done
    
    wait $pid
    local exit_code=$?
    
    tput cnorm
    rm -f "$temp_output"
    exec 1>&3 2>&4
    
    if [ $exit_code -eq 0 ]; then
        print_banner
        echo -e "\n${GREEN}${BOLD}✨ Project setup completed successfully! ✨${RESET}\n"
        echo -e "${BLUE}📁 Project: ${BOLD}$project_name${RESET}"
        echo -e "${BLUE}🛠  Framework: ${BOLD}$framework${RESET}\n"
        echo -e "${GRAY}→ To get started:${RESET}"
        echo -e "${GRAY}  cd $project_name${RESET}"
        echo -e "${GRAY}  $(get_start_command "$framework")${RESET}\n"
        print_success "Ready to code! Happy hacking! 🚀"
    else
        print_error "Failed to create $framework project. Please check the error messages above."
        cat "$temp_output"
        exit 1
    fi
}

# Helper function to get framework-specific start command
get_start_command() {
    local framework=$1
    case "$framework" in
        "Next.js"|"Remix"|"Astro") echo "npm run dev" ;;
        "React") echo "npm start" ;;
        *) echo "npm run dev" ;;
    esac
}

# Function to handle phase 2 installation
handle_phase2_installation() {
    print_banner
    echo -e "\n${BLUE}${BOLD}⚡ Setting Up Development Environment${RESET}\n"
    printf "${BLUE}%-${COLUMNS}s${RESET}\n" "-" | tr ' ' '-'

    # Source NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Get Node.js version from config
    local NODE_VERSION=$(jq -r '.nodeVersion' config.json)
    
    # Setup progress tracking
    exec 3>&1 4>&2
    local temp_output=$(mktemp)
    
    # Start background process for installations
    (
        # Install Node.js
        nvm install "$NODE_VERSION" >/dev/null 2>&1
        nvm use "$NODE_VERSION" >/dev/null 2>&1
        node -v > .nvmrc
        
        # Install Bun
        if ! command -v bun &> /dev/null; then
            curl -fsSL https://bun.sh/install | bash >/dev/null 2>&1
        fi
    ) > "$temp_output" 2>&1 &
    
    local pid=$!
    local phases=(
        "${BLUE}📦 Preparing Node.js environment"
        "${PURPLE}⚡ Installing Node.js ${NODE_VERSION}"
        "${GREEN}🔧 Configuring NVM"
        "${ORANGE}🎨 Setting up Bun runtime"
        "${BLUE}📝 Verifying installations"
    )
    
    # Progress bar settings
    local fill="█"
    local empty="▒"
    local bar_size=40
    local progress=0
    local phase_index=0
    
    tput sc
    tput civis
    
    while kill -0 $pid 2>/dev/null; do
        tput rc
        
        local current_phase=${phases[$phase_index]}
        local filled=$((progress * bar_size / 100))
        local empty_count=$((bar_size - filled))
        
        # Build progress bar
        printf "\033[K\n"
        printf "%b${RESET}\n" "$current_phase"
        
        # Print filled portion
        printf "${BLUE}"
        printf "%*s" "$filled" | tr ' ' "$fill"
        
        # Print empty portion
        printf "${GRAY}"
        printf "%*s" "$empty_count" | tr ' ' "$empty"
        
        # Print percentage
        printf "${RESET} [%3d%%]\n" "$progress"
        
        # Print spinner
        printf "${BLUE}%s${RESET} Installing development tools...\n" "${SPINNER_FRAMES[$((progress % ${#SPINNER_FRAMES[@]}))]}"
        
        progress=$((progress + 1))
        if [ $progress -ge 100 ]; then 
            progress=0
            phase_index=$(((phase_index + 1) % ${#phases[@]}))
        fi
        
        sleep 0.1
    done
    
    wait $pid
    local exit_code=$?
    
    tput cnorm
    rm -f "$temp_output"
    exec 1>&3 2>&4
    
    if [ $exit_code -eq 0 ]; then
        print_banner
        echo -e "\n${GREEN}${BOLD}✨ Development environment setup completed! ✨${RESET}\n"
        
        # Get and display versions with consistent styling
        local node_version=$(node -v 2>/dev/null || echo "not installed")
        local npm_version=$(npm -v 2>/dev/null || echo "not installed")
        local bun_version=$(bun -v 2>/dev/null || echo "not installed")
        
        echo -e "${BLUE}📦 Installed Versions:${RESET}"
        printf "${BLUE}%-${COLUMNS}s${RESET}\n" "-" | tr ' ' '-'
        echo -e "${GRAY}Node.js: ${BOLD}${node_version}${RESET}"
        echo -e "${GRAY}NPM: ${BOLD}${npm_version}${RESET}"
        echo -e "${GRAY}Bun: ${BOLD}${bun_version}${RESET}\n"
        
        # Display framework selection menu
        display_menu
    else
        print_error "Failed to setup development environment. Please check the error messages above."
        cat "$temp_output"
        exit 1
    fi
}

# Check if this is phase 2 of the installation
if [ "$1" = "phase2" ]; then
    handle_phase2_installation
    exit 0
fi

# Phase 1: Initial Setup
print_banner

echo -e "\n${BLUE}${BOLD}📦 Initial Setup${RESET}\n"
printf "${BLUE}%-${COLUMNS}s${RESET}\n" "-" | tr ' ' '-'

# Check for required dependencies
if ! command -v jq &> /dev/null; then
    print_status "Installing jq..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        (brew install jq >/dev/null 2>&1) &
        show_spinner $! "Installing jq via Homebrew"
    else
        (sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y jq >/dev/null 2>&1) &
        show_spinner $! "Installing jq via apt-get"
    fi
    print_success "jq installed successfully"
fi

# Install NVM if not already installed
if [ ! -d "$HOME/.nvm" ]; then
    print_status "Installing Node Version Manager..."
    (curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >/dev/null 2>&1) &
    show_spinner $! "Downloading and installing NVM"
    print_success "NVM installed successfully"
fi

# Create temporary script for phase 2
print_status "Preparing environment..."
TEMP_SCRIPT=$(mktemp)
echo "#!/bin/bash" > $TEMP_SCRIPT
echo "$(pwd)/setup.sh phase2" >> $TEMP_SCRIPT
chmod +x $TEMP_SCRIPT

# Add temporary script to shell rc file
SHELL_RC="$HOME/.zshrc"
echo "$TEMP_SCRIPT" >> "$SHELL_RC"
echo "sed -i '' '/$(basename $TEMP_SCRIPT)/d' \"$SHELL_RC\"" >> $TEMP_SCRIPT

# Update version display with spinner animations
print_banner
echo -e "\n${BLUE}${BOLD}🔍 Checking Environment${RESET}\n"
printf "${BLUE}%-${COLUMNS}s${RESET}\n" "-" | tr ' ' '-'

(sleep 0.5) & show_spinner $! "Checking Node.js version"
node_version=$(node -v 2>/dev/null || echo "not installed")
printf "${GRAY}Node.js: ${BOLD}%s${RESET}\n" "$node_version"

(sleep 0.5) & show_spinner $! "Checking NPM version"
npm_version=$(npm -v 2>/dev/null || echo "not installed")
printf "${GRAY}NPM: ${BOLD}%s${RESET}\n" "$npm_version"

(sleep 0.5) & show_spinner $! "Checking Bun version"
bun_version=$(bun -v 2>/dev/null || echo "not installed")
printf "${GRAY}Bun: ${BOLD}%s${RESET}\n\n" "$bun_version"

print_status "Restarting shell to complete installation..."
sleep 1
exec zsh 