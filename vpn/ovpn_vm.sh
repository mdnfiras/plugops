check=$(lsof -Pnl +M -i 4 | grep 1194)
[[ -z $check ]] && { vagrant up --provider libvirt ; exit 0 ; }
echo 'Please make sure no other service is listening on port 1194.'
echo 'Run lsof -Pnl +M -i 4 | grep 1194'