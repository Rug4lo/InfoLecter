#!/bin/bash

greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"


function ctrl_c(){
  echo -e "\n\n${redColour}[!]${endColour} ${grayColour}Saliendo de manera forzosa${endColour} ${redColour}[!]${endColour}\n"
  exit 1
}

trap ctrl_c INT

# Functions 

function helpPanel (){
  echo -e "\n\t ${turquoiseColour}
    ____      ____      __              __           
   /  _/___  / __/___  / /   ___  _____/ /____  _____
   / // __ \/ /_/ __ \/ /   / _ \/ ___/ __/ _ \/ ___/
 _/ // / / / __/ /_/ / /___/  __/ /__/ /_/  __/ /    
/___/_/ /_/_/  \____/_____/\___/\___/\__/\___/_/     
                                                     
  ${endColour}\n"
  echo -e "${yellowColour}[+]${endColour} ${turquoiseColour}Este es el panel de ayuda de la herramienta:${endColour}\n"
  echo -e " ${grayColour}Esta herramienta sirve para hacer un escaneo de una maquina victima (puertos, dominios, etc), al finalizar el escaneo te creara un documento con el output de todos los escaneos (Recomendable ejecutar la herramienta como root)${endColour}\n"
  echo -e "${yellowColour}[+]${endColour} ${turquoiseColour}Estos son los parametros:${endColour}\n"
  echo -e "\t ${blueColour}-h)${endColour} ${grayColour}Panel de ayuda${endColour}"
  echo -e "\t\t ${grayColour}./InfoLecter.sh -h\n${endColour}"
  echo -e "\t ${blueColour}-i)${endColour} ${grayColour}IP victima${endColour}"
  echo -e "\t\t ${grayColour}./InfoLecter.sh -i 192.168.0.1${endColour}"
  echo -e "\t\t ${grayColour}./InfoLecter.sh -i google.es${endColour}"

}

function scan_all (){

  pingvar="0"
  ip="$1"

  ping -c 1 $ip &>/dev/null && pingvar="1" 

  if [ $pingvar -eq 1 ]; then

    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Empezando escaneo completo de la ip $ip${endColour}\n"

    sleep 1 

    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Escaneaneando OS...${endColour}\n"

    touch InfolecterScan.txt
    echo -e "\n-- OS Scan --\n" > InfolecterScan.txt
    resources/whichSystem.py $ip | sponge >> InfolecterScan.txt
    cat InfolecterScan.txt

    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Escaneando con Nmap...${endColour}\n"
    
    echo -e "\n-- Nmap scan --\n" | sponge >> InfolecterScan.txt
    sudo nmap -p- --open -T5 -sS -min-rate 5000 -n -Pn -oG ports $ip | sponge >> InfolecterScan.txt

    ports="$(cat ports | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"

    echo -e "\n- Nmap scripts scan -\n" | sponge >> InfolecterScan.txt
    sudo nmap -sCV -p$ports $ip | sponge >> InfolecterScan.txt
    sudo rm ports
    cat InfolecterScan.txt

    sleep 1

    echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Escaneando Directorios ${endColour}\n"

    echo -ne "${yellowColour}[?]${endColour} ${grayColour}Indica si vas a escanear una ip(1) o una url(2): ${endColour}" && read -r options


    if [ $options -eq 1 ]; then

      echo -ne "${yellowColour}[?]${endColour} ${grayColour}Indica la ip que quieras escanear (http://192.168.0.1:666): ${endColour}" && read -r url
    
      last_url= echo $url | tr '/' ' ' | awk 'NF{print $NF}' &>/dev/null

      echo -e "\n-- Gobuster Directory Scan --\n" | sponge >> InfolecterScan.txt
      sudo gobuster dir -u $url -w resources/directory-list-2.3-medium.txt -t20 | grep -vE "400|401|402|403|404" 2>/dev/null | sponge >> InfolecterScan.txt
      cat InfolecterScan.txt

      echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Escaneando Subdirectorios ${endColour}\n"

      echo -e "\n-- Wfuzz Subdirectory Scan --\n" | sponge >> InfolecterScan.txt
      wfuzz -c --hc=301,403,404,400 -t 20 -w resources/subdomains-top1million-5000.txt -H "Host: FUZZ.$mid_url" $url 2>/dev/null | grep -vE "301|400|401|402|403|404" |sponge >> InfolecterScan.txt
      cat InfolecterScan.txt

    else 

      echo -ne "${yellowColour}[?]${endColour} ${grayColour}Indica la url que quieras escanear (http://google.com): ${endColour}" && read -r url
    
      last_url= echo $url | tr '/' ' ' | awk 'NF{print $NF}' &>/dev/null

      echo -e "\n-- Gobuster Directory Scan --\n" | sponge >> InfolecterScan.txt
      sudo gobuster vhost -u $url -w resources/directory-list-2.3-medium.txt -t20 | grep -vE "400|401|402|403|404"  2>/dev/null | sponge >> InfolecterScan.txt
      cat InfolecterScan.txt

      echo -e "\n${yellowColour}[+]${endColour} ${grayColour}Escaneando Subdirectorios ${endColour}\n"

      echo -e "\n-- Wfuzz Subdirectory Scan --\n" | sponge >> InfolecterScan.txt
      wfuzz -c --hc=403,404,400 -t 20 -w resources/subdomains-top1million-5000.txt -H "Host: FUZZ.$mid_url" $url 2>/dev/null | grep -vE "301|400|401|402|403|404" |sponge >> InfolecterScan.txt
      cat InfolecterScan.txt

    fi

  else 
    
    echo -e "\n${redColour}[!]${endColour} ${grayColour}La ip $ip no es correcta${endColour}\n"
    
  fi

}

# Global variables 

declare -i parameter_counter=0

# Parameters

while getopts "ai:h" arg; do 
  case $arg in 
    i) ipAddress=$OPTARG; let parameter_counter+=1;;
    h) ;;


  esac
done

if [ $parameter_counter -eq 1 ]; then
  scan_all $ipAddress
else
  helpPanel
fi


