require 'tty-prompt'
require 'tty-table'
require 'pastel'

module TUI
  class App
    def initialize
      @prompt = TTY::Prompt.new
      @pastel = Pastel.new
    end

    def run
      loop do
        system('clear') || system('cls')
        puts @pastel.bold.cyan("\n╔══════════════════════════════════════╗")
        puts @pastel.bold.cyan("║          BLOG MANAGEMENT TUI         ║")
        puts @pastel.bold.cyan("╚══════════════════════════════════════╝\n")

        choice = @prompt.select('What would you like to manage?') do |menu|
          menu.choice 'Authors', :authors
          menu.choice 'Posts', :posts
          menu.choice 'Comments', :comments
          menu.choice @pastel.red('Exit'), :exit
        end

        case choice
        when :authors then authors_menu
        when :posts then posts_menu
        when :comments then comments_menu
        when :exit
          puts @pastel.green("\nGoodbye!")
          break
        end
      end
    end

    private

    # ============ AUTHORS ============

    def authors_menu
      loop do
        choice = @prompt.select("\nAuthors Menu:") do |menu|
          menu.choice 'List all authors', :list
          menu.choice 'View author details', :show
          menu.choice 'Create new author', :create
          menu.choice 'Edit author', :edit
          menu.choice 'Delete author', :delete
          menu.choice @pastel.yellow('← Back'), :back
        end

        case choice
        when :list then list_authors
        when :show then show_author
        when :create then create_author
        when :edit then edit_author
        when :delete then delete_author
        when :back then break
        end
      end
    end

    def list_authors
      authors = Author.all
      if authors.empty?
        puts @pastel.yellow("\nNo authors found.")
      else
        table = TTY::Table.new(
          header: %w[ID Name Email Bio],
          rows: authors.map { |a| [a.id, a.name, a.email, a.bio&.truncate(30)] }
        )
        puts "\n" + table.render(:unicode, padding: [0, 1])
      end
      @prompt.keypress("\nPress any key to continue...")
    end

    def show_author
      author = select_author
      return unless author

      puts @pastel.bold("\n═══ Author Details ═══")
      puts "ID:    #{author.id}"
      puts "Name:  #{author.name}"
      puts "Email: #{author.email}"
      puts "Bio:   #{author.bio || 'N/A'}"
      puts "Posts: #{author.posts.count}"
      puts "Created: #{author.created_at}"

      @prompt.keypress("\nPress any key to continue...")
    end

    def create_author
      puts @pastel.bold("\n═══ Create New Author ═══")
      name = @prompt.ask('Name:', required: true)
      email = @prompt.ask('Email:', required: true)
      bio = @prompt.ask('Bio (optional):')

      author = Author.create!(name: name, email: email, bio: bio)
      puts @pastel.green("\n✓ Author '#{author.name}' created with ID #{author.id}")
    rescue ActiveRecord::RecordInvalid => e
      puts @pastel.red("\n✗ Error: #{e.record.errors.full_messages.join(', ')}")
    ensure
      @prompt.keypress("\nPress any key to continue...")
    end

    def edit_author
      author = select_author
      return unless author

      puts @pastel.bold("\n═══ Edit Author ═══")
      author.name = @prompt.ask('Name:', default: author.name)
      author.email = @prompt.ask('Email:', default: author.email)
      author.bio = @prompt.ask('Bio:', default: author.bio)
      author.save!

      puts @pastel.green("\n✓ Author updated successfully")
    rescue ActiveRecord::RecordInvalid => e
      puts @pastel.red("\n✗ Error: #{e.record.errors.full_messages.join(', ')}")
    ensure
      @prompt.keypress("\nPress any key to continue...")
    end

    def delete_author
      author = select_author
      return unless author

      if @prompt.yes?("Delete author '#{author.name}' and all their posts?")
        author.destroy!
        puts @pastel.green("\n✓ Author deleted")
      else
        puts @pastel.yellow("\nCancelled")
      end
      @prompt.keypress("\nPress any key to continue...")
    end

    def select_author
      authors = Author.all
      if authors.empty?
        puts @pastel.yellow("\nNo authors available.")
        @prompt.keypress("\nPress any key to continue...")
        return nil
      end

      choices = authors.map { |a| { name: "#{a.id}: #{a.name} (#{a.email})", value: a } }
      choices << { name: @pastel.yellow('← Cancel'), value: nil }
      @prompt.select("\nSelect an author:", choices)
    end

    # ============ POSTS ============

    def posts_menu
      loop do
        choice = @prompt.select("\nPosts Menu:") do |menu|
          menu.choice 'List all posts', :list
          menu.choice 'View post details', :show
          menu.choice 'Create new post', :create
          menu.choice 'Edit post', :edit
          menu.choice 'Publish/Unpublish post', :toggle_publish
          menu.choice 'Delete post', :delete
          menu.choice @pastel.yellow('← Back'), :back
        end

        case choice
        when :list then list_posts
        when :show then show_post
        when :create then create_post
        when :edit then edit_post
        when :toggle_publish then toggle_publish_post
        when :delete then delete_post
        when :back then break
        end
      end
    end

    def list_posts
      posts = Post.recent.includes(:author)
      if posts.empty?
        puts @pastel.yellow("\nNo posts found.")
      else
        table = TTY::Table.new(
          header: %w[ID Title Author Status Created],
          rows: posts.map do |p|
            status = p.published? ? @pastel.green('Published') : @pastel.yellow('Draft')
            [p.id, p.title.truncate(25), p.author&.name, status, p.created_at.strftime('%Y-%m-%d')]
          end
        )
        puts "\n" + table.render(:unicode, padding: [0, 1])
      end
      @prompt.keypress("\nPress any key to continue...")
    end

    def show_post
      post = select_post
      return unless post

      puts @pastel.bold("\n═══ Post Details ═══")
      puts "ID:        #{post.id}"
      puts "Title:     #{post.title}"
      puts "Author:    #{post.author&.name}"
      puts "Status:    #{post.published? ? 'Published' : 'Draft'}"
      puts "Published: #{post.published_at || 'N/A'}"
      puts "Comments:  #{post.comments.count}"
      puts "\n--- Body ---"
      puts post.body

      @prompt.keypress("\nPress any key to continue...")
    end

    def create_post
      author = select_author
      return unless author

      puts @pastel.bold("\n═══ Create New Post ═══")
      title = @prompt.ask('Title:', required: true)
      puts 'Body (end with an empty line):'
      body = read_multiline

      post = Post.create!(author: author, title: title, body: body)

      if @prompt.yes?('Publish now?')
        post.publish!
        puts @pastel.green("\n✓ Post '#{post.title}' created and published with ID #{post.id}")
      else
        puts @pastel.green("\n✓ Post '#{post.title}' created as draft with ID #{post.id}")
      end
    rescue ActiveRecord::RecordInvalid => e
      puts @pastel.red("\n✗ Error: #{e.record.errors.full_messages.join(', ')}")
    ensure
      @prompt.keypress("\nPress any key to continue...")
    end

    def edit_post
      post = select_post
      return unless post

      puts @pastel.bold("\n═══ Edit Post ═══")
      post.title = @prompt.ask('Title:', default: post.title)
      if @prompt.yes?('Edit body?')
        puts 'New body (end with an empty line):'
        post.body = read_multiline
      end
      post.save!

      puts @pastel.green("\n✓ Post updated successfully")
    rescue ActiveRecord::RecordInvalid => e
      puts @pastel.red("\n✗ Error: #{e.record.errors.full_messages.join(', ')}")
    ensure
      @prompt.keypress("\nPress any key to continue...")
    end

    def toggle_publish_post
      post = select_post
      return unless post

      if post.published?
        post.unpublish!
        puts @pastel.yellow("\n✓ Post unpublished (now a draft)")
      else
        post.publish!
        puts @pastel.green("\n✓ Post published!")
      end
      @prompt.keypress("\nPress any key to continue...")
    end

    def delete_post
      post = select_post
      return unless post

      if @prompt.yes?("Delete post '#{post.title}' and all its comments?")
        post.destroy!
        puts @pastel.green("\n✓ Post deleted")
      else
        puts @pastel.yellow("\nCancelled")
      end
      @prompt.keypress("\nPress any key to continue...")
    end

    def select_post
      posts = Post.recent.includes(:author)
      if posts.empty?
        puts @pastel.yellow("\nNo posts available.")
        @prompt.keypress("\nPress any key to continue...")
        return nil
      end

      choices = posts.map do |p|
        status = p.published? ? '[P]' : '[D]'
        { name: "#{p.id}: #{status} #{p.title.truncate(40)} by #{p.author&.name}", value: p }
      end
      choices << { name: @pastel.yellow('← Cancel'), value: nil }
      @prompt.select("\nSelect a post:", choices, per_page: 15)
    end

    # ============ COMMENTS ============

    def comments_menu
      loop do
        choice = @prompt.select("\nComments Menu:") do |menu|
          menu.choice 'List all comments', :list
          menu.choice 'View comments on a post', :by_post
          menu.choice 'Add comment to post', :create
          menu.choice 'Edit comment', :edit
          menu.choice 'Delete comment', :delete
          menu.choice @pastel.yellow('← Back'), :back
        end

        case choice
        when :list then list_comments
        when :by_post then list_comments_by_post
        when :create then create_comment
        when :edit then edit_comment
        when :delete then delete_comment
        when :back then break
        end
      end
    end

    def list_comments
      comments = Comment.includes(:post, :author).limit(20)
      if comments.empty?
        puts @pastel.yellow("\nNo comments found.")
      else
        table = TTY::Table.new(
          header: %w[ID Post Commenter Body Created],
          rows: comments.map do |c|
            [c.id, c.post&.title&.truncate(20), c.display_name, c.body.truncate(30), c.created_at.strftime('%Y-%m-%d')]
          end
        )
        puts "\n" + table.render(:unicode, padding: [0, 1])
      end
      @prompt.keypress("\nPress any key to continue...")
    end

    def list_comments_by_post
      post = select_post
      return unless post

      comments = post.comments.includes(:author)
      if comments.empty?
        puts @pastel.yellow("\nNo comments on this post.")
      else
        puts @pastel.bold("\n═══ Comments on '#{post.title}' ═══")
        comments.each do |c|
          puts "\n#{@pastel.bold(c.display_name)} (#{c.created_at.strftime('%Y-%m-%d %H:%M')}):"
          puts "  #{c.body}"
        end
      end
      @prompt.keypress("\nPress any key to continue...")
    end

    def create_comment
      post = select_post
      return unless post

      puts @pastel.bold("\n═══ Add Comment to '#{post.title}' ═══")

      use_author = @prompt.yes?('Comment as registered author?')
      author = nil
      commenter_name = nil

      if use_author
        author = select_author
        return unless author
      else
        commenter_name = @prompt.ask('Your name:', required: true)
      end

      body = @prompt.ask('Comment:', required: true)

      Comment.create!(post: post, author: author, commenter_name: commenter_name, body: body)
      puts @pastel.green("\n✓ Comment added successfully")
    rescue ActiveRecord::RecordInvalid => e
      puts @pastel.red("\n✗ Error: #{e.record.errors.full_messages.join(', ')}")
    ensure
      @prompt.keypress("\nPress any key to continue...")
    end

    def edit_comment
      comment = select_comment
      return unless comment

      puts @pastel.bold("\n═══ Edit Comment ═══")
      comment.body = @prompt.ask('Comment:', default: comment.body)
      comment.save!

      puts @pastel.green("\n✓ Comment updated successfully")
    rescue ActiveRecord::RecordInvalid => e
      puts @pastel.red("\n✗ Error: #{e.record.errors.full_messages.join(', ')}")
    ensure
      @prompt.keypress("\nPress any key to continue...")
    end

    def delete_comment
      comment = select_comment
      return unless comment

      if @prompt.yes?("Delete this comment?")
        comment.destroy!
        puts @pastel.green("\n✓ Comment deleted")
      else
        puts @pastel.yellow("\nCancelled")
      end
      @prompt.keypress("\nPress any key to continue...")
    end

    def select_comment
      comments = Comment.includes(:post, :author).limit(20)
      if comments.empty?
        puts @pastel.yellow("\nNo comments available.")
        @prompt.keypress("\nPress any key to continue...")
        return nil
      end

      choices = comments.map do |c|
        { name: "#{c.id}: [#{c.post&.title&.truncate(15)}] #{c.display_name}: #{c.body.truncate(30)}", value: c }
      end
      choices << { name: @pastel.yellow('← Cancel'), value: nil }
      @prompt.select("\nSelect a comment:", choices, per_page: 15)
    end

    # ============ HELPERS ============

    def read_multiline
      lines = []
      loop do
        line = gets
        break if line.nil? || line.strip.empty?
        lines << line.rstrip
      end
      lines.join("\n")
    end
  end
end
