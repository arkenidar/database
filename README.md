# Ruby Blog Application

A modular Ruby blog application featuring both a Terminal User Interface (TUI) and RESTful HTTP API. Built with ActiveRecord ORM and SQLite database.

## Features

- **Dual Interface**: Access your blog via terminal or HTTP API
- **Full CRUD Operations**: Create, Read, Update, Delete for Authors, Posts, and Comments
- **Blog Entities**: Authors, Posts (with publish/draft status), and Comments
- **Validations**: Email uniqueness, required fields, and referential integrity
- **Sample Data**: Seed script included for quick testing

## Project Structure

```
database/
├── Gemfile                      # Ruby gem dependencies
├── Rakefile                     # Rake tasks for database management
├── config.ru                    # Rack configuration for HTTP server
├── README.md                    # This file
│
├── config/
│   └── database.yml             # Database connection settings
│
├── db/
│   ├── blog.sqlite3             # SQLite database file
│   └── migrate/
│       ├── 001_create_authors.rb
│       ├── 002_create_posts.rb
│       └── 003_create_comments.rb
│
├── lib/blog/
│   ├── db.rb                    # Database setup and connection module
│   └── models/
│       ├── author.rb            # Author ActiveRecord model
│       ├── post.rb              # Post ActiveRecord model
│       └── comment.rb           # Comment ActiveRecord model
│
├── app/
│   └── api.rb                   # Sinatra REST API application
│
├── tui/
│   └── app.rb                   # Terminal UI application
│
└── bin/
    ├── tui                      # Launch TUI interface
    ├── server                   # Launch HTTP API server
    └── console                  # Interactive Ruby console
```

## Requirements

- Ruby 3.0+
- Bundler

## Installation

1. **Install dependencies:**
   ```bash
   bundle install
   ```

2. **Set up the database:**
   ```bash
   bundle exec rake db:migrate
   ```

3. **Seed with sample data (optional):**
   ```bash
   bundle exec rake db:seed
   ```

## Usage

### Terminal User Interface (TUI)

Launch the interactive terminal application:

```bash
./bin/tui
```

The TUI provides menu-driven navigation to:
- Manage Authors (list, create, edit, delete)
- Manage Posts (list, create, edit, publish/unpublish, delete)
- Manage Comments (list, create, edit, delete)

### HTTP API Server

Start the REST API server:

```bash
./bin/server
```

The server runs at `http://localhost:4567`

### Interactive Console

Open an IRB session with models loaded:

```bash
./bin/console
```

Example commands:
```ruby
Author.all
Post.published
Comment.first
Author.create!(name: "Jane", email: "jane@example.com")
```

## API Endpoints

### Authors

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/authors` | List all authors |
| GET | `/authors/:id` | Get author with their posts |
| POST | `/authors` | Create new author |
| PUT | `/authors/:id` | Update author |
| DELETE | `/authors/:id` | Delete author |

**Example - Create author:**
```bash
curl -X POST http://localhost:4567/authors \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Doe", "email": "jane@example.com", "bio": "Writer"}'
```

### Posts

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/posts` | List all posts |
| GET | `/posts?status=published` | List published posts only |
| GET | `/posts?status=drafts` | List draft posts only |
| GET | `/posts/:id` | Get post with comments |
| POST | `/posts` | Create new post |
| PUT | `/posts/:id` | Update post |
| POST | `/posts/:id/publish` | Publish a draft post |
| POST | `/posts/:id/unpublish` | Unpublish a post |
| DELETE | `/posts/:id` | Delete post |

**Example - Create post:**
```bash
curl -X POST http://localhost:4567/posts \
  -H "Content-Type: application/json" \
  -d '{"author_id": 1, "title": "My Post", "body": "Post content..."}'
```

**Example - Publish post:**
```bash
curl -X POST http://localhost:4567/posts/1/publish
```

### Comments

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/comments` | List all comments |
| GET | `/comments?post_id=1` | List comments for a post |
| GET | `/comments/:id` | Get single comment |
| POST | `/comments` | Create new comment |
| PUT | `/comments/:id` | Update comment |
| DELETE | `/comments/:id` | Delete comment |

**Example - Create comment:**
```bash
curl -X POST http://localhost:4567/comments \
  -H "Content-Type: application/json" \
  -d '{"post_id": 1, "commenter_name": "Reader", "body": "Great post!"}'
```

## Data Models

### Author
| Field | Type | Constraints |
|-------|------|-------------|
| id | Integer | Primary key, auto-increment |
| name | String | Required |
| email | String | Required, unique |
| bio | Text | Optional |
| created_at | DateTime | Auto-managed |
| updated_at | DateTime | Auto-managed |

**Associations:**
- `has_many :posts` (dependent: destroy)
- `has_many :comments`

### Post
| Field | Type | Constraints |
|-------|------|-------------|
| id | Integer | Primary key, auto-increment |
| author_id | Integer | Required, foreign key |
| title | String | Required |
| body | Text | Required |
| published_at | DateTime | Null = draft |
| created_at | DateTime | Auto-managed |
| updated_at | DateTime | Auto-managed |

**Associations:**
- `belongs_to :author`
- `has_many :comments` (dependent: destroy)

**Scopes:**
- `Post.published` - Posts with published_at set
- `Post.drafts` - Posts without published_at
- `Post.recent` - Ordered by created_at desc

### Comment
| Field | Type | Constraints |
|-------|------|-------------|
| id | Integer | Primary key, auto-increment |
| post_id | Integer | Required, foreign key |
| author_id | Integer | Optional, foreign key |
| commenter_name | String | Required if no author |
| body | Text | Required |
| created_at | DateTime | Auto-managed |
| updated_at | DateTime | Auto-managed |

**Associations:**
- `belongs_to :post`
- `belongs_to :author` (optional)

## Rake Tasks

```bash
# Run migrations
bundle exec rake db:migrate

# Seed sample data
bundle exec rake db:seed

# Drop database
bundle exec rake db:drop

# Reset database (drop + migrate)
bundle exec rake db:reset
```

## Dependencies

| Gem | Purpose |
|-----|---------|
| activerecord | ORM for database operations |
| sqlite3 | SQLite database adapter |
| sinatra | HTTP framework for REST API |
| sinatra-contrib | Sinatra extensions (JSON helper) |
| puma | Web server |
| tty-prompt | Interactive terminal prompts |
| tty-table | Terminal table formatting |
| pastel | Terminal text coloring |
| rake | Task automation |

## License

MIT
