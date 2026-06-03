# Virtual Shop

A simple e-commerce platform built with Ruby on Rails.

## Features

- User authentication (Devise)
- Admin and customer roles
- Product categories with nested (parent/child) relationships
- Product management (CRUD)
- Order management with order items
- Seeds for users, categories, products, and orders
- RSpec tests for models and business rules

## Models

### User
- Devise authentication
- Roles: `customer` (default), `admin`
- Associations: has many orders, has many carts

### Category
- Self-referencing: supports parent and subcategories
- Associations: has many products, has many subcategories
- Validations: unique name per parent, cannot be its own parent or descendant

### Product
- Belongs to a category
- Associations: has many order items, has many cart items
- Validations: name, price, and stock presence; price and stock must be non-negative

### Order
- Belongs to a user
- Has many order items
- Status enum: `pending`, `paid`, `shipped`, `delivered`, `cancelled`
- Validations: status and total presence

### OrderItem
- Belongs to an order and a product
- Stores quantity and price at the time of order

## Seeds

Seeds are organized in `db/seeds/`:
- `0-prepare.rb`: Cleans the database
- `1-users.rb`: Creates admin and customer users
- `2-categories.rb`: Creates categories and subcategories
- `3-products.rb`: Creates products linked to categories
- `4-orders.rb`: Creates sample orders and order items

To load all seeds:

```sh
rails db:seed
```

## Running Tests

RSpec is used for model and business rule testing:

```sh
bundle exec rspec
```

## Getting Started

1. Clone the repository
2. Install dependencies: `bundle install`
3. Setup the database: `rails db:setup`
4. Run the server: `rails server`
5. Access at [http://localhost:3000](http://localhost:3000)

## Running With Docker

Add the local development domain to your hosts file:

```sh
sudo sh -c 'echo "127.0.0.1 r6tech.store-local" >> /etc/hosts'
```

Build and start the app with PostgreSQL:

```sh
docker compose up --build
```

The app will be available at [http://r6tech.store-local:3030](http://r6tech.store-local:3030).
The container runs `rails db:prepare` automatically before starting the server.

Local ports are configurable through environment variables:

```sh
WEB_PORT=3030 POSTGRES_PORT=5454 docker compose up --build
```

To load sample data:

```sh
docker compose exec web rails db:seed
```

To run specs:

```sh
docker compose exec web bundle exec rspec
```

## Admin Access

- Default admin user (from seeds):
  - Email: `rafael@devbatista.com`
  - Password: `senha123`

---

Feel free to contribute or adapt this project!

> ⚠️ **This project is under active development and is being used as a study platform. New features and improvements (including frontend) are being implemented over time. Feel free to follow, suggest, or contribute!**
