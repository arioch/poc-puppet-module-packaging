    librarian-puppet install
    librarian-puppet update
    ./pkg.sh stdlib development
    ./pkg.sh stdlib production
    dpkg -c puppet-module-production-stdlib_*.deb
    rpm -qpl puppet-module-production-stdlib-*.rpm
