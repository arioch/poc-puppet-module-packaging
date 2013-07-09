    librarian-puppet install
    librarian-puppet update
    ./pkg.sh production stdlib
    dpkg -c puppet-module-production-stdlib_*.deb
