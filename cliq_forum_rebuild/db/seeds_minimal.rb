# frozen_string_literal: true

puts "== Minimal Seeding =="

# Clear data first just in case (though previous runs likely cleared it)
Reply.delete_all
Post.delete_all
Cliq.delete_all
User.delete_all

puts "Creating User..."
user = User.create!(
  email: "test@cliq.test",
  password: "password123!",
  password_confirmation: "password123!"
)

puts "Creating Cliq..."
cliq = Cliq.create!(
  name: "General",
  description: "General discussion",
  slug: "general"
)

puts "Creating Post..."
post = Post.create!(
  title: "Welcome to Cliq!",
  content: "This is a seeded post.",
  user: user,
  cliq: cliq
)

puts "Creating Reply..."
Reply.create!(
  content: "This is a seeded reply.",
  user: user,
  post: post
)

puts "Seeding Complete!"
