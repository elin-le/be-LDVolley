# LD Volley Backend

Backend service for **LD Volley**, built with Java 21 and Spring Boot. The project uses PostgreSQL for persistence, Spring Data JPA for database access, Flyway for database migrations, and Spring Security with OAuth2 Client support.

> **Project status:** This repository snapshot contains the initial Spring Boot application setup and configuration. API endpoints, authentication flows, database schema, and feature-specific usage should be documented as they are implemented.

## Contents

- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Database Migrations](#database-migrations)
- [Run the Application](#run-the-application)
- [Run Tests](#run-tests)
- [Project Structure](#project-structure)
- [Useful Commands](#useful-commands)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)

## Technology Stack

| Technology | Purpose |
| --- | --- |
| Java 21 | Application runtime and language |
| Spring Boot 4.1.1 | Application framework |
| Kotlin DSL for Gradle | Build configuration (`build.gradle.kts`) |
| PostgreSQL 17 | Relational database |
| Spring Data JPA | Persistence and ORM |
| Spring Security | Application security foundation |
| OAuth2 Client | OAuth2 client integration support |
| Flyway | Database schema migration |
| Lombok | Reduces Java boilerplate |
| Docker Compose | Local PostgreSQL setup |
| JUnit 5 / Spring Boot Test | Automated tests |

## Prerequisites

Install the following before running the project:

- **JDK 21**
- **Docker Engine and Docker Compose** (recommended for running PostgreSQL locally)
- Git
- A terminal (macOS/Linux) or PowerShell/Command Prompt (Windows)

The repository includes the Gradle Wrapper, so a separate Gradle installation is not required. The wrapper downloads the configured Gradle distribution on its first run and requires network access.

Verify Java is available:

```bash
java -version
```

Make sure it reports Java 21. If not, configure `JAVA_HOME` to point to your JDK 21 installation.

## Getting Started

### 1. Clone the repository

Replace `<repository-url>` with the Git URL for this repository:

```bash
git clone <repository-url>
cd ld-volley-be
```

### 2. Create your local environment file

The application and Docker Compose configuration read database settings from environment variables. Create a `.env` file in the repository root:

```dotenv
POSTGRES_DB=ldvolley
POSTGRES_USER=ldvolley
POSTGRES_PASSWORD=replace-with-a-local-password
```

Choose your own local password. Do not commit `.env` or share real credentials.

The application configuration defaults to database `ldvolley` and username `ledan` if `POSTGRES_DB` and `POSTGRES_USER` are not set, but Docker Compose requires all three variables. Using the same values in `.env` keeps the application and database configuration consistent.

### 3. Start PostgreSQL

From the repository root, run:

```bash
docker compose up -d db
```

Check the container status:

```bash
docker compose ps
docker compose logs -f db
```

Docker Compose publishes PostgreSQL on `localhost:5432` and persists its data in the `ldvolley_data` named volume.

> If port `5432` is already in use, stop the other PostgreSQL service or change the host-side port mapping in `docker-compose.yml` and update the JDBC URL accordingly.

### 4. Build the project

On macOS/Linux:

```bash
./gradlew build
```

On Windows:

```bat
gradlew.bat build
```

If the wrapper is not executable on macOS/Linux, run `chmod +x gradlew` once, then retry.

## Configuration

The main configuration file is:

`src/main/resources/application.yml`

Current database configuration:

| Setting | Default / value |
| --- | --- |
| Application name | `ld-volley` |
| JDBC URL | `jdbc:postgresql://localhost:5432/${POSTGRES_DB:ldvolley}` |
| Database username | `${POSTGRES_USER:ledan}` |
| Database password | `${POSTGRES_PASSWORD}` |
| Flyway migration location | `classpath:db/migration` |
| Hibernate schema mode | `validate` |
| Open EntityManager in View | `false` |

Environment variables:

| Variable | Purpose |
| --- | --- |
| `POSTGRES_DB` | PostgreSQL database name |
| `POSTGRES_USER` | PostgreSQL username |
| `POSTGRES_PASSWORD` | PostgreSQL password |

The `application.yml` requires `POSTGRES_PASSWORD` to be provided. For local development, Docker Compose automatically reads a root `.env` file when starting the database container. Spring Boot does **not** automatically load Docker Compose's `.env` file as application environment variables in every launch setup. Export the variables in your shell or configure them in your IDE's run configuration before starting the app.

Example for macOS/Linux:

```bash
export POSTGRES_DB=ldvolley
export POSTGRES_USER=ldvolley
export POSTGRES_PASSWORD='replace-with-a-local-password'
```

For Windows PowerShell:

```powershell
$env:POSTGRES_DB = "ldvolley"
$env:POSTGRES_USER = "ldvolley"
$env:POSTGRES_PASSWORD = "replace-with-a-local-password"
```

Avoid placing production credentials directly in source files or committing them to Git.

## Database Migrations

Flyway is enabled and configured to search for migration scripts in:

```text
src/main/resources/db/migration/
```

Add versioned migration files there when introducing schema changes. For example:

```text
V1__create_initial_tables.sql
V2__add_player_table.sql
```

Use the project's migration history as the source of truth for the schema. Hibernate is configured with `ddl-auto: validate`, so it checks entity mappings against the existing database schema rather than creating or updating tables automatically.

> No migration scripts were present in the supplied project snapshot. If this is a fresh database, add the initial migrations before expecting entity-backed features to work.

## Run the Application

After PostgreSQL is running and the environment variables are configured:

macOS/Linux:

```bash
./gradlew bootRun
```

Windows:

```bat
gradlew.bat bootRun
```

The application should start using Spring Boot's default HTTP port (`8080`) unless configured otherwise. The supplied snapshot does not define a custom server port or document API routes, so check the current source/configuration for any changes.

To stop the application, press `Ctrl+C`.

## Run Tests

Run all tests:

macOS/Linux:

```bash
./gradlew test
```

Windows:

```bat
gradlew.bat test
```

The snapshot includes a basic Spring Boot context-load test at:

`src/test/java/com/elinledev/ld_volley/LdVolleyApplicationTests.java`

Run the full build, including tests, with `./gradlew build` or `gradlew.bat build`.

## Project Structure

```text
ld-volley-be/
├── gradle/
│   └── wrapper/                 # Gradle Wrapper configuration
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/elinledev/ld_volley/
│   │   │       └── LdVolleyApplication.java
│   │   └── resources/
│   │       └── application.yml  # Spring Boot configuration
│   └── test/
│       └── java/
│           └── com/elinledev/ld_volley/
│               └── LdVolleyApplicationTests.java
├── .gitignore
├── build.gradle.kts
├── docker-compose.yml           # Local PostgreSQL service
├── gradlew
├── gradlew.bat
└── settings.gradle.kts
```

As controllers, services, entities, repositories, security configuration, and migrations are added, update this section to reflect the actual package layout.

## Useful Commands

| Task | macOS/Linux | Windows |
| --- | --- | --- |
| Start database | `docker compose up -d db` | `docker compose up -d db` |
| Stop database | `docker compose down` | `docker compose down` |
| View database logs | `docker compose logs -f db` | `docker compose logs -f db` |
| Run app | `./gradlew bootRun` | `gradlew.bat bootRun` |
| Run tests | `./gradlew test` | `gradlew.bat test` |
| Build | `./gradlew build` | `gradlew.bat build` |
| Stop app | `Ctrl+C` | `Ctrl+C` |

To stop the database and remove the Compose network, run `docker compose down`. To also delete the persisted local database volume, run:

```bash
docker compose down -v
```

**Warning:** `docker compose down -v` permanently deletes the PostgreSQL data stored in the `ldvolley_data` volume.

## Troubleshooting

### PostgreSQL connection refused

- Confirm the database container is running: `docker compose ps`.
- Check logs: `docker compose logs -f db`.
- Confirm PostgreSQL is reachable on `localhost:5432`.
- Ensure `POSTGRES_DB`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` match the values used by the app.

### `POSTGRES_PASSWORD` is missing

- Ensure the variable is set in the terminal or IDE run configuration before starting Spring Boot.
- A root `.env` file is read by Docker Compose, but may not be loaded into a separately launched Spring Boot process.

### Hibernate schema validation fails

- Confirm the database is running and the correct database is selected.
- Check that the Flyway migrations have run successfully.
- Ensure entity mappings match the schema created by the migration scripts. Hibernate will not generate missing tables with the current `validate` setting.

### Gradle or Java version errors

- Run `java -version` and confirm JDK 21 is active.
- Try `./gradlew --version` (macOS/Linux) or `gradlew.bat --version` (Windows).
- The Gradle Wrapper may need network access to download its configured distribution.

## Security Notes

- Never commit `.env` files, passwords, OAuth client secrets, access tokens, private keys, or production credentials.
- Configure OAuth2 client credentials through environment variables or a secrets manager when adding provider-specific authentication.
- Review logs and configuration before sharing them publicly.
- The repository snapshot does not include documented OAuth provider setup, API endpoint documentation, or deployment instructions. Add those details when the relevant implementation is available.

## Contributing

1. Create a feature branch from the project's default branch.
2. Make your changes and add or update tests.
3. Run `./gradlew test` and, when appropriate, `./gradlew build`.
4. Keep configuration and secrets out of version control.
5. Open a pull request with a clear summary and testing notes.

## License

No license file was included in the supplied snapshot. Add a `LICENSE` file if you intend to specify how others may use, modify, or distribute this repository.
