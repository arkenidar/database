require_relative 'lib/blog/db'

namespace :db do
  desc 'Run database migrations'
  task :migrate do
    Blog.setup_database!
    Blog.migrate!
    puts 'Migrations complete!'
  end

  desc 'Drop the database'
  task :drop do
    db_path = File.join(Blog.root, 'db', 'blog.sqlite3')
    if File.exist?(db_path)
      File.delete(db_path)
      puts 'Database dropped!'
    else
      puts 'No database to drop.'
    end
  end

  desc 'Reset the database (drop + migrate)'
  task :reset => [:drop, :migrate]

  desc 'Seed the database with sample data'
  task :seed do
    Blog.setup_database!
    Blog.load_models!

    # Create sample authors
    author1 = Author.find_or_create_by!(email: 'alice@example.com') do |a|
      a.name = 'Alice Johnson'
      a.bio = 'Ruby enthusiast and blogger'
    end

    author2 = Author.find_or_create_by!(email: 'bob@example.com') do |a|
      a.name = 'Bob Smith'
      a.bio = 'Tech writer and developer'
    end

    # Create sample posts
    post1 = Post.find_or_create_by!(title: 'Getting Started with Ruby') do |p|
      p.author = author1
      p.body = 'Ruby is a wonderful programming language that emphasizes developer happiness...'
      p.published_at = Time.now
    end

    post2 = Post.find_or_create_by!(title: 'ActiveRecord Best Practices') do |p|
      p.author = author2
      p.body = 'When working with ActiveRecord, there are several patterns to keep in mind...'
      p.published_at = Time.now
    end

    post3 = Post.find_or_create_by!(title: 'Draft: Upcoming Features') do |p|
      p.author = author1
      p.body = 'This is a draft post about upcoming features...'
    end

    # Create sample comments
    Comment.find_or_create_by!(post: post1, commenter_name: 'Charlie') do |c|
      c.body = 'Great introduction to Ruby!'
    end

    Comment.find_or_create_by!(post: post1, author: author2) do |c|
      c.body = 'Nice article, Alice!'
    end

    puts 'Database seeded with sample data!'
  end
end
