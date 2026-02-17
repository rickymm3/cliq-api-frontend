# API Authentication Pattern

## Overview
All API controllers inherit from `Api::BaseController`, which includes the `ApiAuthenticatable` concern. This provides JWT authentication via the `Authorization` header.

## How to Protect Endpoints

### Require Authentication for All Actions (except read-only)
```ruby
class Api::PostsController < BaseController
  before_action :authenticate_api_user!, except: [:index, :show]
  before_action :set_resource, only: [:update, :destroy]
  
  # Actions protected: create, update, destroy
  # Actions public: index, show
end
```

### Require Authentication for Specific Actions
```ruby
class Api::CommentsController < BaseController
  before_action :authenticate_api_user!, only: [:create, :destroy]
  before_action :set_comment, only: [:show, :update, :destroy]
  
  # Only create and destroy require auth
  # index and show are public
end
```

### Optional Authentication (get current_user if token provided, but don't require it)
```ruby
class Api::PostsController < BaseController
  before_action :authenticate_api_user_optional!, only: [:index]
  
  def index
    posts = Post.all
    if current_user
      # Customize response with user preferences
    end
    render json: posts
  end
end
```

## ⚠️ Common Mistakes to Avoid

### ❌ DON'T: Duplicate before_action declarations
```ruby
# WRONG - Second one overrides the first!
before_action :authenticate_api_user!, except: [:index, :show]
before_action :authenticate_api_user!, only: [:like]
```

### ✅ DO: Combine into one declaration or use multiple specific ones
```ruby
# RIGHT - One clear declaration
before_action :authenticate_api_user!, except: [:index, :show]

# Or if you need different auth rules for some actions:
before_action :authenticate_api_user!, only: [:create, :update, :destroy]
before_action :authenticate_api_user_optional!, only: [:index]
```

## Accessing the Current User

In any API controller action:
```ruby
def create
  post = current_user.posts.build(post_params)
  post.save!
  render json: post
end
```

The `current_user` method is automatically available through the `ApiAuthenticatable` concern.

## JWT Token Format

Requests must include an Authorization header:
```
Authorization: Bearer <JWT_TOKEN>
```

Tokens are obtained by logging in to `/api/users/sign_in` endpoint, which returns:
```json
{
  "data": {
    "authentication_token": "eyJhbGciOiJIUzI1NiJ9..."
  }
}
```

## Testing Authentication

See `test/controllers/api/concerns/api_authenticatable_test.rb` for examples of testing authenticated endpoints.
