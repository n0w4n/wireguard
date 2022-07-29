#!/bin/bash

# check if WireGuard is installed
status_wg=`dpkg -s wireguard 2>/dev/null | grep -e 'Status.*ok'`

if [[ -z "${status_wg}" ]]; then
	echo "[!] WireGuard is not installed"
	read -p 'Do you want to install WireGuard? (Y/n)' varInstall
	if [[ "${varInstall}" =~ [Yy] ]] || [[ -z "${varInstall}" ]]; then
		sudo apt update
		sudo apt install wireguard -y
	else
		echo "[-] Nothing happened....exiting"
		exit 0
	fi
else
	echo "[-] WireGuard is installed"
fi

echo "[-] Starting configuration"
echo "[-] Generating private key"
wg genkey | sudo tee /etc/wireguard/privkey
echo "[-] Generating public key"
cat /etc/wireguard/privkey | wg pubkey | sudo tee /etc/wireguard/pubkey

varPrivkey=`cat /etc/wireguard/privkey`
varPubkey=`cat /etc/wireguard/pubkey`

read -p 'Give VPN IP-adres of this client: ' varIp
read -p 'Give public key of WireGuard server: ' varPubPeer
read -p 'Do you want to use a preshared-key? (Y/n) ' varOptionPreSharedKey

if [[ "${varOptionPreSharedKey}" =~ [Nn] ]] || [[ -z "${varOptionPreSharedKey}" ]]; then
	varOptionPreSharedKey="no"
else
	read -p 'Give preshared-key: ' varPreSharedKey
fi

read -p 'Give IP-adres of WAN interface on VPN-server: ' varIpServer
read -p 'Give portnumber of VPN-server: ' varPortServer

function optionA () {
sudo tee -a /etc/wireguard/wg-client.conf <<EOF
[Interface]
PrivateKey = ${varPrivkey}
Address = ${varIp}/24
DNS = 1.1.1.1

[Peer]
PublicKey = "${varPubPeer}"
PreSharedKey = "${varPreSharedKey}"
AllowedIPs = 0.0.0.0/0
Endpoint = "${varIpServer}":"${varPortServer}"
EOF
}

function optionB () {
sudo tee -a /etc/wireguard/wg-client.conf <<EOF
[Interface]
PrivateKey = ${varPrivkey}
Address = ${varIp}/24
DNS = 1.1.1.1

[Peer]
PublicKey = ${varPubPeer}
AllowedIPs = 0.0.0.0/0
Endpoint = ${varIpServer}:${varPortServer}
EOF
}

if [[ "${varOptionPreSharedKey}" == "no" ]]; then
	optionB
else
	optionA
fi

echo "[-] Configuration is done"
echo "[-] To start WireGuard VPN: sudo wg-quick up /etc/wireguard/wg-client"
echo "[-] To stop WireGuard VPN: sudo wg-quick down /etc/wireguard/wg-client"
echo

