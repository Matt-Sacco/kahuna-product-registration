# Kahuna Smart Appliance Product Registration System
### REST API – Final Project Submission (Matthew Sacco)

This project implements a complete REST API for Kahuna Inc., allowing customers to register smart appliances, track warranty periods, and manage their product list.

The system is built using:
- PHP 8 (OOP)
- MariaDB
- Nginx
- Docker & Docker Compose
- Postman for API testing

It follows the specification of the *MySuccess Website Developer Final Project v2.3*.

---

## 1. Project Structure

```text
sc-bed-finalproject-env/
├── api/
│   ├── index.php                         # API entry point
│   └── com/icemalta/kahuna/
│       ├── api/Kahuna.php               # Main REST API controller
│       ├── model/                       # DB models (User, Product, Session, UserProduct, DBConnect)
│       └── util/                        # Utilities (ApiUtil, Auth)
│
├── client/
│   └── index.html                       # Simple landing/info page
│
├── support/
│   ├── db.sql                           # DB schema + seed data
│   └── db.erd                           # ERD diagram
│
├── docker/
│   ├── api.conf                         # Nginx config for API
│   └── client.conf                      # Nginx config for client
│
├── docker-compose.yml
├── Kahuna API - Full Test Suite.postman_collection.json
├── kahuna_environment.postman_environment.json
└── README.md
```

> Note: Some files above may be named slightly differently (e.g. ERD file name), but the structure and responsibilities match this layout.

---

## 2. Running the Project with Docker

### Prerequisites

- Docker
- Docker Compose

### Start the stack

From the `sc-bed-finalproject-env` directory:

```bash
docker-compose up --build
```

This will start the following services:

| Service  | Description             | URL / Host         |
|----------|-------------------------|--------------------|
| api      | Nginx serving the API   | http://localhost:8000 |
| php      | PHP-FPM                 | internal only      |
| client   | Static client site      | http://localhost:8001 |
| mariadb  | MariaDB database        | localhost:3306 (inside Docker network: `mariadb`) |

The **first time** the database container starts, it will automatically execute:

```text
support/db.sql
```

This creates the `Kahuna` database, tables, and seed data.

### Resetting the database

If you need to re-initialise the database (e.g. clean state):

```bash
docker-compose down -v
docker-compose up --build
```

`-v` removes the Docker volume used by MariaDB, causing it to run `support/db.sql` again.

---

## 3. API Base URL

All endpoints are available under:

```text
http://localhost:8000
```

Example:

```text
GET http://localhost:8000/health
```

The `api/index.php` file is the front controller for all requests and delegates to `Kahuna.php`.

---

## 4. Authentication

The API uses a simple **token-based session system**:

1. User calls `/login` with valid credentials.
2. A new row in the `Session` table is created.
3. The generated `token` must be sent with all protected requests.

The token can be supplied in three ways:

### 4.1. Header (recommended)

```http
X-Api-Key: <token>
```

### 4.2. Query parameter

```text
/view-products?token=<token>
```

### 4.3. JSON body

```json
{
  "token": "<token>"
}
```

Internally, `Kahuna.php` resolves the token in this order:

1. `X-Api-Key` header
2. `token` query parameter
3. `token` field in request body

---

## 5. API Endpoints

### 5.1. Public Endpoints

#### 5.1.1. Health Check

- **Method:** `GET`
- **URL:** `/health`

**Response (example):**

```json
{
  "success": true,
  "data": {
    "status": "ok",
    "message": "API is running",
    "timestamp": "2025-11-14 12:34:56"
  }
}
```

---

#### 5.1.2. Create Account

- **Method:** `POST`
- **URL:** `/create-account`

**Body:**

```json
{
  "username": "jdoe",
  "password": "secret",
  "role": "client"
}
```

`role` can be `client` or `admin`. If omitted, `client` is assumed.

---

#### 5.1.3. Login

- **Method:** `POST`
- **URL:** `/login`

**Body:**

```json
{
  "username": "jdoe",
  "password": "secret"
}
```

**Response (simplified):**

```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "jdoe",
      "role": "client"
    },
    "token": "abcdef123456...",
    "message": "Login successful"
  }
}
```

---

### 5.2. Client Endpoints (Authentication Required)

All these endpoints require a valid token (client or admin).

#### 5.2.1. Register Product

- **Method:** `POST`
- **URL:** `/register-product`

**Headers (recommended):**

```http
X-Api-Key: <client_token>
Content-Type: application/json
```

**Body:**

```json
{
  "serial": "KHWM8199911"
}
```

The `serial` must exist in the `Product` table. If registration already exists for this user and product, a HTTP 409 is returned.

---

#### 5.2.2. View All Registered Products

- **Method:** `GET`
- **URL:** `/view-products`

**Header:**

```http
X-Api-Key: <token>
```

**Response (simplified):**

```json
{
  "success": true,
  "data": {
    "products": [
      {
        "serial": "KHWM8199911",
        "name": "Kahuna Washing Machine 9000",
        "registeredAt": "2025-11-14 10:00:00",
        "warrantyLength": 5
      }
    ],
    "message": "Products retrieved successfully"
  }
}
```

---

#### 5.2.3. View Product Details (with Warranty Remaining)

- **Method:** `GET`
- **URL:** `/view-product?serial=KHWM8199911`

**Header:**

```http
X-Api-Key: <token>
```

The response includes a `warrantyRemaining` field calculated from:

- `registeredAt` date
- `warrantyLength` (years)

---

### 5.3. Admin-only Endpoints

#### 5.3.1. Add Product

- **Method:** `POST`
- **URL:** `/add-product`

**Headers:**

```http
X-Api-Key: <admin_token>
Content-Type: application/json
```

**Body:**

```json
{
  "serial": "NEW123456",
  "name": "Kahuna Smart Toaster",
  "warrantyLength": 2
}
```

Only users with the `admin` role can access this endpoint. If a product with the same serial already exists, the API responds with HTTP 409.

---

### 5.4. Logout

#### 5.4.1. Logout (Invalidate Session)

- **Method:** `POST`
- **URL:** `/logout`

**Body (or header):**

```json
{
  "token": "<token>"
}
```

This deletes the corresponding row from the `Session` table.

---

## 6. Database

The database is defined in `support/db.sql`.

### 6.1. Database Name

```sql
CREATE DATABASE IF NOT EXISTS Kahuna;
USE Kahuna;
```

### 6.2. Tables

- `User`
- `Product`
- `Session`
- `UserProduct`

The schema includes:

- Primary keys
- Foreign keys
- Unique constraint on `(userId, productId)` in `UserProduct`

### 6.3. Seed Data

The `Product` table is pre-populated with 10 products (serial numbers and warranty lengths) as specified in the assignment brief.

---

## 7. Postman Testing

Two JSON files are included for API testing with Postman:

1. **Collection**  
   `Kahuna API - Full Test Suite.postman_collection.json`  
   Contains requests and tests for:
   - Health
   - Create client
   - Create admin
   - Login client
   - Login admin
   - Register product
   - View products
   - View product
   - Add product (admin)
   - Register admin product (client)
   - Logout

2. **Environment**  
   `kahuna_environment.postman_environment.json`  
   Defines:
   - `baseUrl` – usually `http://localhost:8000`
   - `token` – client token (set dynamically by Login Client test)
   - `adminToken` – admin token (set dynamically by Login Admin test)

### 7.1. How to Run Tests

1. Open Postman.
2. Import:
   - `Kahuna API - Full Test Suite.postman_collection.json`
   - `kahuna_environment.postman_environment.json`
3. Select environment: **Kahuna API (Docker)** (or equivalent name).
4. Run the collection using the Postman Collection Runner.

---

## 8. Notes and Assumptions

- Passwords are stored as hashes in the database via PHP’s `password_hash` and verified with `password_verify`.
- The warranty calculation is based on the registration date stored in `UserProduct`.
- All API responses use a consistent JSON envelope:

  ```json
  {
    "success": true,
    "data": { ... }
  }
  ```

  or

  ```json
  {
    "success": false,
    "message": "Error description"
  }
  ```

---

## 9. Author

**Name:** Matthew Sacco  
**Course:** MySuccess Website Developer – Final Project  
**Module:** REST API & Database (Kahuna Product Registration)

