wget https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc
apt install gnupg2
apt-key add 0x1285491434D8786F.asc


apt update
apt install srvadmin-all
