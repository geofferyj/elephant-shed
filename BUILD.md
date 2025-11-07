# Building Elephant Shed from Source

This document provides comprehensive instructions for building and deploying the Elephant Shed PostgreSQL dashboard from source.

## Table of Contents

1. [Prerequisites and System Requirements](#prerequisites-and-system-requirements)
2. [Build Dependencies Installation](#build-dependencies-installation)
3. [Building Debian Packages](#building-debian-packages)
4. [Building RPM Packages](#building-rpm-packages)
5. [Building Documentation](#building-documentation)
6. [Deployment Instructions](#deployment-instructions)
7. [Development Setup with Vagrant](#development-setup-with-vagrant)
8. [Troubleshooting](#troubleshooting)

## Prerequisites and System Requirements

### Supported Distributions

Elephant Shed supports the following distributions:

**Debian:**
- Debian Trixie (13)
- Debian Bookworm (12)

**Ubuntu:**
- Ubuntu Noble (24.04)
- Ubuntu Jammy (22.04)

**CentOS/RHEL:**
- CentOS 7
- RHEL 7

### Hardware Requirements

- **Minimum:** 2 GB RAM, 2 CPU cores, 20 GB disk space
- **Recommended:** 4 GB RAM, 4 CPU cores, 40 GB disk space

### Software Prerequisites

- Git for source code management
- Make (build-essential on Debian/Ubuntu)
- A supported distribution with repository access

## Build Dependencies Installation

### Debian/Ubuntu

Install the required build dependencies:

```bash
# Update package lists
sudo apt-get update

# Install build tools
sudo apt-get install -y devscripts build-essential

# Install build dependencies from debian/control
sudo apt-get build-dep -y ./

# Or install specific dependencies manually:
sudo apt-get install -y \
    debhelper \
    python3-sphinx \
    python3-recommonmark \
    python3-sphinx-rtd-theme \
    sphinx-common \
    tmate
```

### CentOS/RHEL

Install the required build dependencies:

```bash
# Install build tools
sudo yum install -y rpm-build yum-utils git make

# Install build dependencies from spec file
sudo yum-builddep -y rpm/elephant-shed.spec

# Additional tools for tarball creation
sudo yum install -y xz
```

## Building Debian Packages

### Quick Build

To build Debian packages quickly:

```bash
# Clone the repository
git clone https://github.com/credativ/elephant-shed.git
cd elephant-shed

# Build the package
make deb
```

This will:
1. Build the Debian package using `dpkg-buildpackage`
2. Run lintian for package quality checks
3. Place the built packages in the parent directory (`../*.deb`, `../*.dsc`, etc.)

### Build for Specific Distribution

The CI uses a rebuild script to prepare distribution-specific builds:

```bash
# Set environment variables
export DEBFULLNAME="Your Name"
export DEBEMAIL="your.email@example.com"

# Build for a specific distribution
./ci/rebuild.sh deb12    # For Debian Bookworm
./ci/rebuild.sh ubuntu22.04  # For Ubuntu Jammy

# Then build the package
make deb
```

### Build Arguments

You can pass additional arguments to dpkg-buildpackage:

```bash
# Build with specific options
make deb BUILD_ARGS="-us -uc -b"

# Build unsigned packages (for testing)
make deb BUILD_ARGS="-us -uc"
```

### Resulting Packages

After a successful build, you'll find these packages:

- `elephant-shed_*.deb` - Meta package depending on all components
- `elephant-shed-portal_*.deb` - Web interface
- `elephant-shed-postgresql_*.deb` - PostgreSQL integration
- `elephant-shed-cockpit_*.deb` - Cockpit integration
- `elephant-shed-grafana_*.deb` - Grafana integration
- `elephant-shed-prometheus_*.deb` - Prometheus integration
- `elephant-shed-prometheus-node-exporter_*.deb` - Node exporter
- `elephant-shed-prometheus-sql-exporter_*.deb` - SQL exporter
- `elephant-shed-pgbadger_*.deb` - pgBadger integration
- `elephant-shed-pgbackrest_*.deb` - pgBackRest integration
- `elephant-shed-powa_*.deb` - PoWA integration
- `elephant-shed-tmate_*.deb` - tmate integration
- `elephant-shed-omnidb_*.deb` - OmniDB integration

## Building RPM Packages

### Prerequisites for RPM Build

The RPM build requires pre-built documentation to be included in the tarball:

```bash
# Build documentation first (see Building Documentation section)
make docs
```

### Building RPM Packages

```bash
# Build RPM packages
make rpmbuild
```

This will:
1. Extract the version from `debian/changelog`
2. Create a source tarball (`rpm/SOURCES/elephant-shed_*.tar.xz`)
3. Include pre-built documentation in the tarball
4. Build RPM packages using `rpmbuild`

### Custom Package Release

To build with a custom release number:

```bash
make rpmbuild PACKAGE_RELEASE=2
```

### Development/CI Builds

For development builds with timestamp:

```bash
make rpmbuild PACKAGE_RELEASE=1~$(date -u +%Y%m%d.%H%M%S)
```

### Building from Different Branch

By default, the tarball is created from HEAD. To use a different branch:

```bash
make rpmbuild GITBRANCH=my-feature-branch
```

### Building tmate RPM

Elephant Shed includes a custom tmate package:

```bash
make rpmbuild-tmate
```

### Resulting RPM Packages

After a successful build, RPM packages will be in:
- `rpm/RPMS/noarch/*.rpm` - Binary packages
- `rpm/SRPMS/*.rpm` - Source packages

## Building Documentation

Elephant Shed uses Sphinx to build HTML documentation.

### Build HTML Documentation

```bash
# Build documentation
make docs

# Or directly in the doc directory
cd doc
make html
```

The built documentation will be in `doc/_build/html/`.

### Documentation Dependencies

The documentation build requires:
- `python3-sphinx`
- `python3-recommonmark`
- `python3-sphinx-rtd-theme`
- `sphinx-common`

For a complete build (with LaTeX support):

```bash
# On Debian/Ubuntu
sudo apt-get install -y texlive-latex-recommended texlive-latex-extra

# Build PDF documentation
cd doc
make latexpdf
```

### Clean Documentation Build

To clean previously built documentation:

```bash
make clean
# Or
cd doc
make clean
```

## Deployment Instructions

### Installing from Built Packages

#### Debian/Ubuntu

```bash
# Install the meta package (installs all components)
sudo dpkg -i elephant-shed_*.deb

# Install dependencies if needed
sudo apt-get install -f

# Or install specific components
sudo dpkg -i elephant-shed-portal_*.deb elephant-shed-postgresql_*.deb
```

#### CentOS/RHEL

```bash
# Install the meta package
sudo yum localinstall elephant-shed-*.rpm

# Or install specific components
sudo yum localinstall elephant-shed-portal-*.rpm elephant-shed-postgresql-*.rpm
```

### Post-Installation

After installation, the Elephant Shed portal will be available at:
- HTTPS: `https://your-server/`
- HTTP: `http://your-server/` (redirects to HTTPS)

Default services enabled:
- Apache/httpd (web server)
- PostgreSQL (database)
- Cockpit (system management)
- Grafana (monitoring dashboard)
- Prometheus (metrics collection)
- Various exporters and tools

### Accessing the Portal

1. Navigate to `https://your-server/` in a web browser
2. Accept the self-signed SSL certificate (or install your own)
3. Log in with your system credentials

## Development Setup with Vagrant

Vagrant provides an easy way to set up a development environment.

### Prerequisites

Install Vagrant and a provider (VirtualBox, libvirt, etc.):

```bash
# On Debian/Ubuntu
sudo apt-get install -y vagrant virtualbox

# On macOS with Homebrew
brew install vagrant virtualbox
```

### Using Vagrant

The Vagrantfile is located in the `vagrant/` directory:

```bash
cd vagrant

# Start the VM and provision it
vagrant up --provision

# SSH into the VM
vagrant ssh

# Stop the VM
vagrant halt

# Destroy the VM
vagrant destroy
```

### Vagrant Configuration

The Vagrantfile configures:
- Base box: `debian/bookworm64`
- Port forwarding:
  - 80 (HTTP) → 8080
  - 443 (HTTPS) → 4433
  - 3000 (Grafana) → 8730
  - 5432 (PostgreSQL) → 8732
  - 9090 (Prometheus) → 8790
  - 9100 (Node Exporter) → 8791
  - 4200 (PoWA) → 4200
  - 10090 (Cockpit) → 10090

### Building and Testing with Vagrant

```bash
# Build packages first
make deb

# Start Vagrant and provision
make vagrant

# Or use Ansible for provisioning
make ansible
```

### Custom Ansible Deployment

```bash
# Deploy with custom Ansible arguments
make ansible ANSIBLE_ARGS="--limit webserver"

# Deploy to OpenPower (example)
make deploy_openpower
```

### Vagrant Provisioning

The Vagrant setup uses Ansible for provisioning. The playbook is in `vagrant/elephant-shed.yml`.

## Troubleshooting

### Build Issues

#### Missing Build Dependencies

**Problem:** Build fails with missing dependencies.

**Solution:**
```bash
# Debian/Ubuntu
sudo apt-get build-dep -y ./

# CentOS/RHEL
sudo yum-builddep -y rpm/elephant-shed.spec
```

#### Lintian Warnings

**Problem:** Lintian reports warnings or errors.

**Solution:** Check `lintian.log` for details. Many warnings can be ignored for development builds.

#### Documentation Build Fails

**Problem:** Sphinx build fails.

**Solution:**
```bash
# Install required Python packages
sudo apt-get install -y python3-sphinx python3-recommonmark python3-sphinx-rtd-theme

# Check for syntax errors in doc/*.rst files
cd doc
make clean
make html
```

### RPM Build Issues

#### Missing Documentation in Tarball

**Problem:** RPM build fails because documentation is not found.

**Solution:**
```bash
# Build documentation first
make docs

# Then build RPM
make rpmbuild
```

#### Tarball Creation Fails

**Problem:** `git archive` fails or tarball is incomplete.

**Solution:**
```bash
# Ensure you're in a git repository
git status

# Ensure the branch exists
git branch

# Specify the branch explicitly
make rpmbuild GITBRANCH=master
```

### Vagrant Issues

#### Vagrant Up Fails

**Problem:** `vagrant up` fails to start.

**Solution:**
```bash
# Check Vagrant version
vagrant --version

# Update VirtualBox Guest Additions
vagrant plugin install vagrant-vbguest

# Try with verbose output
vagrant up --debug
```

#### Port Conflicts

**Problem:** Port forwarding conflicts.

**Solution:** Edit `vagrant/Vagrantfile` and change the host ports to avoid conflicts.

#### Provisioning Fails

**Problem:** Ansible provisioning fails.

**Solution:**
```bash
# Re-run provisioning
vagrant provision

# Or SSH in and debug manually
vagrant ssh
```

### Package Installation Issues

#### Dependency Problems (Debian/Ubuntu)

**Problem:** Package installation fails with dependency errors.

**Solution:**
```bash
# Add PostgreSQL repository
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Add repository key (modern method)
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
  sudo tee /etc/apt/trusted.gpg.d/postgresql.asc > /dev/null

sudo apt-get update

# Install with dependencies
sudo apt-get install -f
```

#### SELinux Issues (CentOS/RHEL)

**Problem:** Services fail to start due to SELinux policies.

**Solution:**
```bash
# Check SELinux status
getenforce

# Temporarily set to permissive for debugging
sudo setenforce 0

# Check audit logs
sudo ausearch -m avc -ts recent

# For production, create proper SELinux policies
```

### Service Issues

#### Apache/httpd Won't Start

**Problem:** Web server fails to start.

**Solution:**
```bash
# Check logs
sudo journalctl -u apache2    # Debian/Ubuntu
sudo journalctl -u httpd      # CentOS/RHEL

# Check configuration
sudo apache2ctl configtest    # Debian/Ubuntu
sudo httpd -t                 # CentOS/RHEL

# Verify SSL certificates exist
ls -l /etc/ssl/certs/ssl-cert-snakeoil.pem  # Debian/Ubuntu
ls -l /etc/pki/tls/certs/localhost.crt      # CentOS/RHEL
```

#### PostgreSQL Connection Issues

**Problem:** Cannot connect to PostgreSQL.

**Solution:**
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Check listening ports
sudo ss -tlnp | grep 5432

# Check pg_hba.conf
sudo -u postgres cat /etc/postgresql/*/main/pg_hba.conf

# Test connection
sudo -u postgres psql
```

### General Debugging

#### Check Logs

```bash
# System logs
sudo journalctl -xe

# Apache logs
sudo tail -f /var/log/apache2/error.log  # Debian/Ubuntu
sudo tail -f /var/log/httpd/error_log    # CentOS/RHEL

# PostgreSQL logs
sudo -u postgres tail -f /var/log/postgresql/postgresql-*-main.log
```

#### Verify Services

```bash
# Check all elephant-shed services
systemctl list-units 'elephant-shed-*' 'prometheus*' 'grafana*'

# Check specific service
sudo systemctl status elephant-shed-portal
```

## Additional Resources

- **Official Documentation:** https://elephant-shed.io/doc/
- **Source Repository:** https://github.com/credativ/elephant-shed
- **Issue Tracker:** https://github.com/credativ/elephant-shed/issues
- **IRC/Chat:** #elephant-shed on irc.oftc.net

## Contributing

When building for contribution:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Build and test locally
5. Submit a pull request

For more details, see the project's contribution guidelines.

## License

Elephant Shed is licensed under GPLv3. See the LICENSE file for details.
