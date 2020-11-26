#!/bin/bash -e

echo "Creating print admin user..."
# add print user
adduser --home /home/admin --shell /bin/bash --gecos "admin" --disabled-password admin
adduser admin sudo
adduser admin lp
adduser admin lpadmin
echo -e "${ADMIN_PASSWORD}\n${ADMIN_PASSWORD}" | passwd admin
echo 'admin ALL=(ALL:ALL) ALL' >> /etc/sudoers

for script in /setup_scripts/*.sh; do
    echo "Running ${script}..."
    ${script}
done

echo "DONE! Launching cupsd."
cupsd -f
