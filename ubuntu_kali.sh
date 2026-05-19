#!/bin/bash

read -p "Full install (recommended)? (y/n): " full_choice
if [[ "${full_choice,,}" == "y" ]]; then
  FULL_INSTALL=true
else
  FULL_INSTALL=false
fi

cd ~
# increase terminal
printf '\e[8;28;105t'  # Set rows=40, cols=110

# Get current profile
PROFILE_ID=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \')
PROFILE_PATH="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$PROFILE_ID/"

# Save original colors
ORIGINAL_BG=$(gsettings get "$PROFILE_PATH" background-color)
ORIGINAL_FG=$(gsettings get "$PROFILE_PATH" foreground-color)

# Set dark hacker theme
gsettings set "$PROFILE_PATH" use-theme-colors false
gsettings set "$PROFILE_PATH" background-color '#000000'
gsettings set "$PROFILE_PATH" foreground-color '#3CFF2D'
gsettings set "$PROFILE_PATH" font 'Monospace 16'
gsettings set "$PROFILE_PATH" use-system-font false


GREEN='\033[0;32m'
NC='\033[0m'

banner_lines=(
"██████╗ ██╗██╗  ██╗ ██████╗██╗  ██╗        ██████╗ ██╗   ██╗███████╗███████╗ ██╗ █████╗ ███╗   ██╗"
"██╔══██╗██║██║  ██║██╔════╝██║ ██╔╝        ██╔══██╗██║   ██║██╔════╝██╔════╝███║██╔══██╗████╗  ██║"
"██████╔╝██║███████║██║     █████╔╝         ██████╔╝██║   ██║███████╗███████╗╚██║███████║██╔██╗ ██║"
"██╔══██╗██║╚════██║██║     ██╔═██╗         ██╔══██╗██║   ██║╚════██║╚════██║ ██║██╔══██║██║╚██╗██║"
"██████╔╝███████╗██║╚██████╗██║  ██╗███████╗██║  ██║╚██████╔╝███████║███████║ ██║██║  ██║██║ ╚████║"
"╚═════╝ ╚══════╝╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝"
" "
" "
" "
" "
" "
" "
" "
" "
" "
" "
" "
" "
" "
" "
" "
" "
" "
" "
" "
)

echo -e "${GREEN}"
for line in "${banner_lines[@]}"; do
  echo "$line"
  sleep 0.07
done
echo -e "${NC}"


#Pre-accepting EULA...
sudo apt install debconf-utils -y
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections

echo "Installing essentials..."
sudo apt-get update && sudo apt install -y git curl flatpak figlet ubuntu-restricted-extras gnome-tweaks gnome-shell-extensions

if $FULL_INSTALL || { read -p "Install Dev stuff? (y/n): " dev_choice && [[ "$dev_choice" == "y" ]]; }; then
  echo "Installing dev tools..."
  #install docker
  # Add Docker's official GPG key:
  sudo apt-get update
  sudo apt-get install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  sleep 1
  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
  sudo usermod -aG docker $USER # (to run docker without sudo)
  sleep 1
  sudo apt install golang qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager swtpm wl-clipboard -y
  sudo usermod -aG libvirt $(whoami)
  sudo usermod -aG kvm $(whoami)
  sudo snap install --classic code
  # pin sublime to dock
  vscode_desktop="code_code.desktop"
  gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, '${vscode_desktop}']/")"
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null
  echo -e 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc' | sudo tee /etc/apt/sources.list.d/sublime-text.sources
  sudo apt-get update
  sudo apt install sublime-text -y
  # pin sublime to dock
  sublime_desktop="sublime_text.desktop"
  gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, '${sublime_desktop}']/")"
  # make sublime default
  xdg-mime default sublime_text.desktop text/plain
  # pin terminal to dock
  terminal_desktop="org.gnome.Terminal.desktop"
  gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, '${terminal_desktop}']/")"
fi



if $FULL_INSTALL || { read -p "Do you care about security/backup? (y/n): " sec_choice && [[ "$sec_choice" == "y" ]]; }; then
  echo "Installing security/backup tools..."
  sudo apt install -y timeshift gufw fail2ban apparmor apparmor-utils keepassxc
  sudo systemctl enable fail2ban apparmor
  sudo ufw enable
  
  #disable Apache
  systemctl list-unit-files | grep -q "^apache2.service" && sudo systemctl disable apache2
fi



# remove firefox from snap and install it normally with apt
sudo snap remove firefox
sudo apt purge firefox -y
#Add Mozilla PPA
sudo add-apt-repository ppa:mozillateam/ppa -y
echo '
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
' | sudo tee /etc/apt/preferences.d/mozilla-firefox

sudo apt update
sudo apt install firefox -y
timeout 5s firefox --headless || true

# install foxyproxy
sudo mkdir -p /etc/firefox/policies
sudo tee /etc/firefox/policies/policies.json >/dev/null <<'EOF'
{
  "policies": {
    "Extensions": {
      "Install": [
        "https://addons.mozilla.org/firefox/downloads/latest/foxyproxy-standard/latest.xpi"
      ]
    }
  }
}
EOF

if $FULL_INSTALL || { read -p 'Install Brave browser? ¯\_( ͡° ͜ʖ ͡°)_/¯ (y/y): ' brave_choice && [[ "$brave_choice" == "y" ]]; }; then
  echo "Installing Brave browser..."
  if ! sudo curl -fsS https://dl.brave.com/install.sh | sudo bash; then
    echo "Brave install failed."
  fi
fi
# pin brave to dock
brave_desktop="brave-browser.desktop"
# Ensure it exists
if [[ -f /usr/share/applications/$brave_desktop ]]; then
  gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, '${brave_desktop}']/")"
fi


# enable dark mode
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-purple-dark' 
# hide home folder
gsettings set org.gnome.shell.extensions.ding show-home false
# Move Dock to Bottom
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
# auto hide dock
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false
# disable dock "panel mode"
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
# change icon size to 60
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 60
# unpin Help from dock
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/, 'yelp.desktop'//; s/'yelp.desktop', //; s/'yelp.desktop'//")"
# add ALT + SHIFT for layout change
gsettings set org.gnome.desktop.input-sources xkb-options "['grp:alt_shift_toggle', 'lv3:ralt_switch']"
# add Hebrew as a secondery lang
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'il')]"
# set default "last modified" in file explorer
gsettings set org.gnome.nautilus.preferences default-sort-order 'mtime'
gsettings set org.gnome.nautilus.preferences default-sort-in-reverse-order true
# enable Do Not Disturb
gsettings set org.gnome.desktop.notifications show-banners false
# add utilities to upper bar
mkdir -p ~/.local/bin
cat > ~/.local/bin/enable-extensions-toggle.sh <<'EOF'
#!/usr/bin/env bash
sleep 5
EXTS=(
  system-monitor@gnome-shell-extensions.gcampax.github.com
  apps-menu@gnome-shell-extensions.gcampax.github.com
  places-menu@gnome-shell-extensions.gcampax.github.com
  workspace-indicator@gnome-shell-extensions.gcampax.github.com
)
# make sure they're listed in gsettings
gsettings set org.gnome.shell enabled-extensions "['${EXTS[0]}', '${EXTS[1]}', '${EXTS[2]}', '${EXTS[3]}']"

# toggle each extension so they show up right away
for e in "${EXTS[@]}"; do
  gnome-extensions disable "$e" || true
  gnome-extensions enable "$e" || true
done

# self-delete autostart so this only runs once
rm -f ~/.config/autostart/enable-extensions-toggle.desktop
EOF

chmod +x ~/.local/bin/enable-extensions-toggle.sh
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/enable-extensions-toggle.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Enable Extensions Toggle Once
Exec=/home/$USER/.local/bin/enable-extensions-toggle.sh
X-GNOME-Autostart-enabled=true
EOF


if $FULL_INSTALL || { read -p 'install ZSH (better shell)? (y/n): ' better_shell && [[ "$better_shell" == "y" ]]; }; then
  echo "install zsh..."
  sudo apt install zsh-common zsh-doc zsh
  # making zsh default
  sudo chsh -s $(which zsh) "$USER"
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  # installing fonts
  mkdir -p ~/.local/share/fonts 
  cd ~/.local/share/fonts 
  wget https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip 
  unzip FiraCode.zip 
  rm FiraCode.zip 
  fc-cache -fv 
  cd ~

  # install powerlevel10k theme
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k 
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 
  sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
  

  # pull my p10k script from my github my_p10k 
  curl -fsSL https://raw.githubusercontent.com/NVainer/fast_ubuntu/refs/heads/main/my_p10k.zsh -o ~/.p10k.zsh
  echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> ~/.zshrc
  echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc
  {
  echo '### BEGIN ZSH COMPLETION BLOCK ###'
  echo 'autoload -Uz compinit'
  echo 'compinit'
  echo "bindkey '^I' expand-or-complete"
  echo 'setopt AUTO_MENU LIST_PACKED'
  echo "zstyle ':completion:*' completer _complete"
  echo "zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'"
  echo '### END ZSH COMPLETION BLOCK ###'
  } >> ~/.zshrc
fi

# starting with kali tools
sudo apt update && sudo apt install -y \
nmap aircrack-ng hashcat hydra gobuster sqlmap \
john netcat-traditional tcpdump \
openvpn whois nikto \
postgresql postgresql-contrib libpq-dev
sudo systemctl enable --now postgresql
sudo DEBIAN_FRONTEND=noninteractive apt install -y wireshark
# essentials for metasploit
sudo apt install -y build-essential zlib1g zlib1g-dev libpq-dev libpcap-dev libsqlite3-dev ruby ruby-dev
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod +x msfinstall
sudo ./msfinstall
msfdb init

# installing burp
wget -O burpsuite_community_linux_2025.8.7.sh \
  "https://portswigger-cdn.net/burp/releases/download?product=community&version=2025.8.7&type=Linux&format=Sh"
chmod +x burpsuite_community_linux_2025.8.7.sh
./burpsuite_community_linux_2025.8.7.sh -q -dir /opt/BurpSuiteCommunity -overwrite -nofilefailures

burp_desktop="$(basename "$(ls ~/.local/share/applications/install4j*BurpSuiteCommunity.desktop 2>/dev/null | head -n1)")"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, '${burp_desktop}']/")"

cat > ~/.local/share/applications/vpn-settings.desktop <<'EOF'
[Desktop Entry]
Name=VPN Settings
Exec=gnome-control-center network
Icon=/usr/share/icons/Yaru/scalable/status/view-private-symbolic.svg
Terminal=false
Type=Application
Categories=Settings;Network;
EOF
chmod +x ~/.local/share/applications/vpn-settings.desktop

vpn_desktop="$(basename ~/.local/share/applications/vpn-settings.desktop)"
gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed "s/]$/, '${vpn_desktop}']/")"

read -p "Download Wordlists? (y/n):" download_wordlist
if [[ "${download_wordlist,,}" == "y" ]]; then
  # SecLists + rockyou
  git clone https://github.com/danielmiessler/SecLists.git ~/wordlists/SecLists
  wget -O ~/wordlists/rockyou.txt https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
fi

read -p "Download Payloads? (y/n):" download_payloads
if [[ "${download_payloads,,}" == "y" ]]; then
  # PayloadsAllTheThings + php-shell
  git clone https://github.com/swisskyrepo/PayloadsAllTheThings.git ~/payloads
  curl -O https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php -o ~/payloads/php-reverse-shell.php
fi


read -p "Want to create system backup with Timeshift now? it'll take a minute or two.. (y/n):" disable_ssh
if [[ "${disable_ssh,,}" == "y" ]]; then
  sudo timeshift --create --comments "stable system"
fi

rm msfinstall Fast

gsettings set "$PROFILE_PATH" background-color "$ORIGINAL_BG"
gsettings set "$PROFILE_PATH" foreground-color "$ORIGINAL_FG"
gsettings set "$PROFILE_PATH" font "$ORIGINAL_FONT"
gsettings set "$PROFILE_PATH" use-system-font true
gsettings set "$PROFILE_PATH" use-theme-colors true
gsettings set "$PROFILE_PATH" use-theme-colors false
gsettings set "$PROFILE_PATH" background-color '#150F1A'
gsettings set "$PROFILE_PATH" foreground-color '#D3D3D3'
printf '\e[8;28;125t'  # Set rows=40, cols=115

clear
echo -e "\e[1;32m"
figlet "All done!"
if [[ -d ~/payloads && -d ~/wordlists ]]; then
    echo -e "\e[1;34m[+] Payloads and Wordlists in Home folder"
fi
echo " "
echo " "
echo " "
echo " "
echo -e "\e[1;32m"
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "
echo " "
echo -e "It's time to logout/login ☺\e[0m"
read -p "Logout now? (y/n): " logout_now
if [[ "${logout_now,,}" == "y" ]]; then
  gnome-session-quit --logout --no-prompt
fi

