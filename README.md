# KumbiaPHP Docker Swarm

KumbiaPHP project containerized with Docker Swarm, MySQL and configurable versions.

## Features

- **KumbiaPHP**: PHP MVC framework with configurable version
- **Web Server Choice**: Apache or Nginx with PHP-FPM configurable
- **MySQL**: Database with configurable version  
- **Memcached**: Optional distributed caching system with configurable version
- **Docker Swarm**: Orchestration with high availability
- **phpMyAdmin**: Web interface to manage MySQL
- **Flexible versions**: Configure PHP, KumbiaPHP, MySQL and Memcached versions
- **Auto-configuration**: Automatic database and cache configuration
- **Session Management**: Memcached-backed sessions for scalability
- **Performance Testing**: Built-in cache and performance benchmarks
- **Automated scripts**: Simplified build and deploy

## Project Structure

```
kumbia/
├── Dockerfile                 # Main KumbiaPHP image
├── docker-compose.yml         # Docker Swarm configuration
├── config.env                 # Configuration variables
├── apache-config.conf         # Apache configuration
├── nginx-config.conf          # Nginx configuration
├── supervisord.conf           # Supervisor configuration for Nginx+PHP-FPM
├── init.sh                    # Container initialization script
├── build.sh                   # Script to build the application
├── deploy.sh                  # Script to deploy on Swarm
├── mysql/
│   └── init/
│       └── 01-init.sql        # MySQL initialization script
└── README.md                  # This documentation
```

## Configuration

### Environment Variables (config.env)

```bash
# Versions
KUMBIAPHP_VERSION=1.2.1 # KumbiaPHP version (1.0, beta2, master)
MYSQL_VERSION=8.0       # MySQL version (8.0, 5.7, etc.)
PHP_VERSION=8.4.1       # PHP version (8.1, 8.0, 7.4, etc.)
WEBSERVER=apache        # Web server: apache or nginx
MEMCACHED_VERSION=      # Memcached version (optional, e.g., 1.6.21)

# Database
MYSQL_ROOT_PASSWORD=kumbia_root_pass
MYSQL_DATABASE=kumbia_db
MYSQL_USER=kumbia_user
MYSQL_PASSWORD=kumbia_pass

# Application
APP_NAME=kumbia-app     # App name
APP_PORT=8180           # App port   
MYSQL_PORT=8181         # MySQL port
PHPMYADMIN_PORT=8182    # PhpMyadmin port
MEMCACHED_PORT=8183     # Memcached port (only if enabled)

# Docker Swarm
REPLICAS=3  # Number of application replicas
```

## Installation and Usage

### Prerequisites

- Docker Engine 20.10+
- Docker Compose V2
- Git

### 1. Clone the Project

```bash
git clone https://github.com/AFelipeTrujillo/kumbiaphp-docker-swarm
cd kumbiakumbiaphp-docker-swarm
```

### 2. Build the Application

```bash
# Permissions
chmod +x build.sh deploy.sh init.sh

# Use default configuration (without Memcached)
./build.sh

# Enable Memcached with specific version
./build.sh -mc 1.6.21

# Specify versions with Memcached
./build.sh -k v1.2.1 -m 8.0 -p 8.4.1 -w apache -mc 1.6.21

# Use Nginx with Memcached
./build.sh -w nginx -mc 1.6.21

# Combine all options
./build.sh -k v1.2.1 -w nginx -p 8.4.1 -m 8.0 -mc 1.6.21

# Rebuild without cache
./build.sh --no-cache -mc 1.6.21
```

### 3. Deploy on Docker Swarm

```bash
# First time (initialize Swarm)
./deploy.sh --init

# Subsequent deployments
./deploy.sh

# Update services
./deploy.sh --update
```

### 4. Access the Application

- **KumbiaPHP Application**: http://localhost:8180
- **phpMyAdmin**: http://localhost:8182
- **Memcached**: localhost:8183 (only if enabled with `-mc` parameter)

## Useful Commands

### Build Scripts

```bash
./build.sh --help                    # View help
./build.sh -k 1.0 -m 8.0 -p 8.1     # Specific versions
./build.sh -w nginx                  # Use Nginx web server
./build.sh -w apache                 # Use Apache web server (default)
./build.sh -mc 1.6.21               # Enable Memcached with version
./build.sh -mc 1.6.21 -w nginx      # Memcached with Nginx
./build.sh --no-cache                # Build without cache
```

### Deploy Scripts

```bash
./deploy.sh --status                 # View services status
./deploy.sh --logs                   # View all logs
./deploy.sh --logs kumbia-app        # Specific logs
./deploy.sh --logs memcached         # Memcached logs (if enabled)
./deploy.sh --remove                 # Remove complete stack
```

### Docker Swarm

```bash
# View services
docker stack services kumbia-stack

# View containers
docker stack ps kumbia-stack

# Scale services
docker service scale kumbia-stack_kumbia-app=5

# Update service
docker service update kumbia-stack_kumbia-app
```

## Database

### Automatic Configuration

The system automatically configures:
- MySQL connection in `app/config/databases.php`
- Example users table
- Optimized MySQL configurations

### Default Credentials

- **User**: kumbia_user
- **Password**: kumbia_pass
- **Database**: kumbia_db
- **Host**: mysql (inside container)

### Example Table

```sql
users (id, username, email, password, created_at, updated_at)
```

## 🚀 Memcached Integration

### Overview

This project includes optional Memcached support for distributed caching and session management, perfect for scalable applications running multiple replicas.

### Features

- **Optional Installation**: Enable with `-mc` parameter
- **Distributed Caching**: Share cache between all application instances
- **Session Management**: Store sessions in Memcached for scalability
- **Performance Boost**: Ultra-fast memory-based caching
- **Native Integration**: Custom KumbiaPHP driver included

### Session Configuration

When Memcached is enabled, PHP sessions are automatically configured:

```ini
session.save_handler = memcached
session.save_path = "memcached:11211"
```

This enables:
- **Shared sessions** across all application replicas
- **Session persistence** even when containers restart
- **Better performance** with memory-based session storage

### Performance Benefits

Typical performance improvements with Memcached:

- **Cache Operations**: 10,000+ ops/second
- **Session Access**: 90% faster than file-based sessions
- **Application Response**: 40-60% faster for cached content
- **Scalability**: Linear scaling with multiple replicas

## Customization

### Change Versions

Edit `config.env` or use parameters in `build.sh`:

```bash
# KumbiaPHP v1.0
./build.sh -k 1.0

# KumbiaPHP beta2
./build.sh -k beta2

# Specific branch
./build.sh -k master
```

### Supported Versions

- **KumbiaPHP**: 1.0, beta2, master, or any branch/tag
- **PHP**: 8.1, 8.0, 7.4, etc.
- **MySQL**: 8.0, 5.7, etc.
- **Memcached**: 1.6.x (recommended: 1.6.21)

### Modify Replicas

```bash
# 5 application replicas
./build.sh -r 5
./deploy.sh --update
```

## 🐳 Docker Structure

### Services

1. **kumbia-app**: PHP application with Apache or Nginx (configurable)
2. **mysql**: MySQL database
3. **phpmyadmin**: Web interface for MySQL
4. **memcached**: Distributed caching system (optional)

### Volumes

- `mysql_data`: MySQL persistent data
- `app_data`: Application data
- `./app`: Local mount for development

### Networks

- `kumbia_network`: Overlay network for service communication

## Troubleshooting

### Common Problems

**Error: Docker Swarm not active**
```bash
./deploy.sh --init
```

**Service not responding**
```bash
./deploy.sh --logs kumbia-app
./deploy.sh --status
```

**Database not connecting**
```bash
./deploy.sh --logs mysql
# Check variables in config.env
```

**Rebuild from scratch**
```bash
./deploy.sh --remove
./build.sh --no-cache
./deploy.sh --init
```

### Detailed Logs

```bash
# Real-time logs
./deploy.sh --logs kumbia-app

# All services logs
./deploy.sh --logs
```

## 📚 Development

### KumbiaPHP Project Structure

```
app/                           # Complete KumbiaPHP Framework Project
├── core/                      # KumbiaPHP Framework Core
│   ├── kumbia/               # Core framework components
│   ├── libs/                 # Core libraries
│   ├── views/                # Core views and layouts
│   ├── extensions/           # Framework extensions
│   ├── console/              # Command line tools
│   └── tests/                # Core tests
├── default/                   # Default KumbiaPHP Application
│   ├── index.php             # Entry point
│   ├── public/               # Public assets (CSS, JS, images)
│   └── app/                  # Application code
│       ├── controllers/      # Application controllers
│       ├── models/           # Data models
│       ├── views/            # Application views
│       ├── config/           # Configuration files
│       ├── libs/             # Application libraries
│       ├── locale/           # Internationalization
│       ├── temp/             # Temporary files
│       ├── tests/            # Application tests
│       ├── extensions/       # Custom extensions
│       └── bin/              # Executable scripts
├── vendor/                    # Composer dependencies
├── .git/                      # Git repository
├── composer.json             # Composer configuration
├── .gitignore               # Git ignore rules
├── .htaccess                # Apache configuration
├── .travis.yml              # CI/CD configuration
├── .phpmd.xml               # PHP Mess Detector config
├── README.md                # Project documentation
└── LICENSE                  # License file
```

### Local Development

The `app/` directory is mounted as a volume, allowing real-time development without rebuilding the image.

## 🤝 Contributing

1. Fork the project
2. Create feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create Pull Request

## 📄 License

This project is under the MIT License. See `LICENSE` for more details.

## 🆘 Support

- **KumbiaPHP Documentation**: https://www.kumbiaphp.com/
- **Docker Swarm**: https://docs.docker.com/engine/swarm/
- **Memcached Guide**: See `MEMCACHED.md` for detailed Memcached documentation
- **Issues**: Create issue in the repository

---

**Ready to develop with KumbiaPHP and Docker Swarm!** 
