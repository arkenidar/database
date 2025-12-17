require_relative 'lib/blog/db'

Blog.setup_database!
Blog.load_models!

require_relative 'app/api'

run BlogAPI
