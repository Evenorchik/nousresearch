#!/bin/bash

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color (reset)

# Check if curl is installed and install it if missing
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Display the logo
curl -s https://raw.githubusercontent.com/Evenorchik/evenorlogo/refs/heads/main/evenorlogo.sh | bash

# Menu
    echo -e "${YELLOW}Select an action:${NC}"
    echo -e "${CYAN}1) Install the bot${NC}"
    echo -e "${CYAN}2) Update the bot${NC}"
    echo -e "${CYAN}3) View logs${NC}"
    echo -e "${CYAN}4) Restart the bot${NC}"
    echo -e "${CYAN}5) Replace with your own questions${NC}"
    echo -e "${CYAN}6) Remove the bot${NC}"

    echo -e "${YELLOW}Enter the number:${NC} "
    read choice

    case $choice in
        1)
            echo -e "${BLUE}Installing the bot...${NC}"

            # --- 1. Update the system and install prerequisites ---
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y python3 python3-venv python3-pip curl
            
            # --- 2. Create the project folder ---
            PROJECT_DIR="$HOME/nous"
            mkdir -p "$PROJECT_DIR"
            cd "$PROJECT_DIR" || exit 1
            
            # --- 3. Create a virtual environment and install dependencies ---
            python3 -m venv venv
            source venv/bin/activate
            pip install --upgrade pip
            pip install requests
            deactivate
            cd
            
            # --- 4. Download the nous_bot.py file ---
            BOT_URL="https://raw.githubusercontent.com/Evenorchik/nousresearch/refs/heads/main/nous_bot.py"
            curl -fsSL -o nous/nous_bot.py "$BOT_URL"

            # --- 5. Ask for the API key and replace it in nous_bot.py ---
            echo -e "${YELLOW}Enter your API key for Nous:${NC}"
            read USER_API_KEY
            # Replace $API_KEY in the script. Assumes the line looks like:
            # NOUS_API_KEY = "$API_KEY"
            sed -i "s/NOUS_API_KEY = \"\$API_KEY\"/NOUS_API_KEY = \"$USER_API_KEY\"/" "$PROJECT_DIR/nous_bot.py"
            
            # --- 6. Download the questions.txt file ---
            QUESTIONS_URL="https://raw.githubusercontent.com/Evenorchik/nousresearch/refs/heads/main/questions.txt"
            curl -fsSL -o nous/questions.txt "$QUESTIONS_URL"

            # --- 7. Create a systemd service ---
            # Determine the user and home directory
            USERNAME=$(whoami)
            HOME_DIR=$(eval echo ~$USERNAME)

            sudo bash -c "cat <<EOT > /etc/systemd/system/nous-bot.service
[Unit]
Description=Nous API Bot Service
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/nous
ExecStart=$HOME_DIR/nous/venv/bin/python $HOME_DIR/nous/nous_bot.py
Restart=always
Environment=PATH=$HOME_DIR/nous/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

[Install]
WantedBy=multi-user.target
EOT"

            # --- 8. Reload systemd and start the service ---
            sudo systemctl daemon-reload
            sudo systemctl restart systemd-journald
            sudo systemctl enable nous-bot.service
            sudo systemctl start nous-bot.service
            
            # Final message
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${YELLOW}Command to view logs:${NC}"
            echo "sudo journalctl -u nous-bot.service -f"
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}Follow me on Twitter — https://x.com/Evenorchik${NC}"
            sleep 2
            sudo journalctl -u nous-bot.service -f
            ;;

        2)
            echo -e "${BLUE}Updating the bot...${NC}"
            sleep 2
            echo -e "${GREEN}No update required!${NC}"
            ;;

        3)
            echo -e "${BLUE}Viewing logs...${NC}"
            sudo journalctl -u nous-bot.service -f
            ;;

        4)
            echo -e "${BLUE}Restarting the bot...${NC}"
            sudo systemctl restart nous-bot.service
            sudo journalctl -u nous-bot.service -f
            ;;
        5)
            sudo systemctl stop nous-bot.service
            sleep 2
            QUESTIONS_FILE="$HOME/nous/questions.txt"

            # Clear the file
            > "$QUESTIONS_FILE"
            
            echo -e "${YELLOW}Paste your questions (one per line)${NC}"
            echo -e "${RED}When you are done, press Ctrl+D:${NC}"
            
            # Read all lines from STDIN into the file
            cat > "$QUESTIONS_FILE"

            sudo systemctl restart nous-bot.service
            sudo journalctl -u nous-bot.service -f           
            ;;
        6)
            echo -e "${BLUE}Removing the bot...${NC}"

            # Stop and remove the service
            sudo systemctl stop nous-bot.service
            sudo systemctl disable nous-bot.service
            sudo rm /etc/systemd/system/nous-bot.service
            sudo systemctl daemon-reload
            sleep 2
    
            # Remove the project folder
            rm -rf $HOME_DIR/nous
    
            echo -e "${GREEN}The bot has been removed successfully!${NC}"
            # Final output
            echo -e "${PURPLE}-----------------------------------------------------------------------${NC}"
            echo -e "${GREEN}Follow me on Twitter — https://x.com/Evenorchik${NC}"
            sleep 1
            ;;

        *)
            echo -e "${RED}Invalid choice. Please enter a number from 1 to 6!${NC}"
            ;;
    esac
