# Implementation Plan: WYSIWYG, Image Upload, and Replies

## 1. WYSIWYG Text Editor Selection

### Options Evaluation:

**Option A: Trix (Rails Native - RECOMMENDED)**
- Pros:
  - Built-in Rails integration (included in new Rails apps)
  - Works with ActionText for database storage
  - Simple rich_text_area helper
  - Handles embedded images natively
  - Lightweight, no external dependencies
  - Excellent for Rails conventions
- Cons:
  - Less customization than larger editors
  - Smaller ecosystem

**Option B: Quill.js**
- Pros:
  - Modern, modular design
  - Great customization options
  - Lightweight (~40KB)
  - Strong community
- Cons:
  - Requires custom integration with Rails
  - More setup work
  - Need to handle serialization manually

**Option C: CKEditor 5**
- Pros:
  - Feature-rich
  - Great collaboration features
  - Professional-grade
- Cons:
  - Heavy (large bundle size)
  - Complex setup
  - Overkill for forum use case
  - License considerations for cloud features

**Recommendation: Trix + ActionText**
- Rails has first-class support for this
- ActionText automatically creates an `action_text_rich_texts` table
- Clean database schema
- Post content stored as: `post.content` (ActionText)
- Works seamlessly with image attachments

### Implementation Architecture:

```
Database Layer:
├── Posts table
│   ├── id
│   ├── title
│   ├── content_type (ActionText blob_id reference)
│   └── ...

├── Replies table
│   ├── id
│   ├── post_id
│   ├── content_type (ActionText blob_id reference)
│   └── ...

└── ActionText tables (auto-created)
    ├── action_text_rich_texts (stores rich text content)
    └── active_storage_attachments (links content to images)

API Layer:
├── Serialization: Convert ActionText to JSON
│   └── Rich text + inline images as base64 or URLs
└── Deserialization: Convert JSON back to ActionText
```

---

## 2. Image Upload Strategy

### Storage Options:

**Option A: AWS S3 (RECOMMENDED for Production)**
- Pros:
  - Industry standard, proven at scale
  - CDN integration via CloudFront
  - Cost-effective ($0.023/GB storage)
  - Clean separation of concerns
  - Rails ActiveStorage has native S3 driver
  - Easy migration from local storage
- Cons:
  - Requires AWS account
  - Additional costs
  - Setup complexity

**Option B: Local File Storage (Development)**
- Pros:
  - Zero setup for development
  - No external dependencies
  - Perfect for testing
- Cons:
  - Not production-ready
  - Doesn't scale
  - Requires syncing in multi-server setups

**Option C: Azure Blob Storage / Google Cloud Storage**
- Pros:
  - Multi-cloud flexibility
  - Similar to S3
- Cons:
  - More setup than local or S3

### Recommended Architecture:

```
Development:
├── Local storage: storage/uploads/
├── Fast iteration
└── No AWS credentials needed

Production:
├── AWS S3 bucket
├── CloudFront CDN
├── ActiveStorage handles all abstractions
└── Same code works in both environments

Implementation Pattern:
1. Configure ActiveStorage (already available in Rails)
2. Set local storage in development
3. Set S3 in production via credentials
4. No code changes needed between environments
```

### Image Upload Flow:

```
Frontend:
1. User selects image in Trix editor
2. Image attached to post/reply form
3. On submit: POST with form-data + file

API:
1. Receive multipart/form-data
2. ActiveStorage attaches image to post/reply
3. Image stored (local/S3 depending on env)
4. Store image URL reference in ActionText content

Response:
1. Return post/reply with image URLs
2. Frontend displays inline images
3. Images persist with post
```

### Database Schema:

```
active_storage_blobs (auto-created):
├── id
├── key (unique identifier)
├── filename
├── content_type
├── metadata (JSON - width, height, etc)
├── byte_size
└── service_name (local/amazon)

active_storage_attachments (auto-created):
├── id
├── name (e.g., "content")
├── blob_id
├── record_id (post_id or reply_id)
├── record_type ("Post" or "Reply")
└── created_at
```

---

## 3. Reply Implementation with Shared WYSIWYG

### Architecture Overview:

```
Shared Component Pattern:

Frontend:
├── _rich_text_editor.html.erb (Partial)
│   ├── Trix editor
│   ├── Image upload handler
│   └── Character count / validation
│
├── _post_form.html.erb
│   ├── Post title field
│   ├── Render: _rich_text_editor (for post content)
│   ├── Post type selector
│   └── Submit button
│
└── _reply_form.html.erb
    ├── Reply to context (which post)
    ├── Render: _rich_text_editor (for reply content)
    └── Submit button

Backend:
├── Posts model
│   ├── has_many :replies
│   └── has_one_attached :images (via ActionText)
│
├── Replies model
│   ├── belongs_to :post
│   ├── belongs_to :user
│   └── has_one_attached :images (via ActionText)
│
└── API Responses (both use same JSON structure)
    ├── id, content (ActionText HTML)
    ├── images_urls []
    ├── user {id, email}
    └── created_at
```

### Reply Data Flow:

```
GET /api/posts/:id/replies
├── Fetch all replies for post
├── Include user info
├── Serialize ActionText content to HTML
└── Return array of replies

POST /api/posts/:id/replies
├── Authenticate user
├── Create Reply record
├── Attach images via ActionText
├── Calculate post heat (replies_count++)
└── Return created reply with HTML content

DELETE /api/replies/:id
├── Authenticate owner
├── Delete reply
├── Recalculate post heat
└── Return 200 OK
```

### Frontend Reply Display:

```
Post Show Page Structure:
├── Post content (Trix rendered HTML)
├── Post metadata
└── Replies Section
    ├── Replies list
    │   ├── Each reply
    │   │   ├── User avatar + name
    │   │   ├── Reply content (Trix HTML)
    │   │   ├── Images inline
    │   │   ├── Metadata (time ago)
    │   │   └── Actions (edit/delete/like/dislike)
    │   └── Nested replies (if threaded)
    │
    └── Reply form (at bottom)
        └── Render: _rich_text_editor partial
            ├── User inputs reply
            ├── Can upload images
            └── Submit creates reply
```

### Implementation Sequence (Backend):

1. **Setup ActionText** (add to Gemfile, run generators)
   - Creates necessary tables and models
   - Adds ActionText validations

2. **Update Post Model**
   ```
   Post:
   ├── has_rich_text :content
   ├── has_many :replies
   └── after_create_reply: recalculate_heat
   ```

3. **Create Reply Model**
   ```
   Reply:
   ├── belongs_to :post (counter_cache)
   ├── belongs_to :user
   ├── has_rich_text :content
   ├── has_many :post_interactions (like/dislike)
   └── after_create: update_post_heat
   ```

4. **Add API Endpoints**
   ```
   GET /api/posts/:id/replies
   POST /api/posts/:id/replies (create)
   GET /api/replies/:id (show single)
   PATCH /api/replies/:id (update)
   DELETE /api/replies/:id
   
   POST /api/replies/:id/like
   POST /api/replies/:id/dislike
   DELETE /api/replies/:id/unlike
   ```

5. **Serialization Helper**
   ```ruby
   def rich_text_json(record)
     {
       id: record.id,
       content: record.content.to_s,  # Rendered HTML
       plain_text: record.content.to_plain_text,
       images: extract_images(record.content),
       created_at: record.created_at
     }
   end
   ```

### Implementation Sequence (Frontend):

1. **Create Shared Editor Partial**
   - `app/views/shared/_rich_text_editor.html.erb`
   - Accept params: `form_id`, `field_name`, `placeholder`
   - Trix editor with image upload
   - Character counter
   - Validation feedback

2. **Update Post Form**
   - Replace textarea with shared editor
   - Test image upload works

3. **Create Reply View**
   - `app/views/posts/show.html.erb`
   - Display replies list
   - Embed reply form with shared editor
   - Same validation and styling as posts

4. **Add Stimulus Controller**
   - `reply_form_controller.js`
   - Handles reply submission
   - Updates replies list via Turbo
   - Recalculates post heat display
   - Shows/hides reply form

---

## 4. Database Migration Strategy

### New Tables/Columns to Add:

```ruby
# ActionText auto-creates these:
create_table :action_text_rich_texts
create_table :active_storage_blobs
create_table :active_storage_variant_records
create_table :active_storage_attachments

# Create Replies table:
create_table :replies do |t|
  t.belongs_to :post
  t.belongs_to :user
  t.integer :parent_reply_id  # For threading
  t.integer :likes_count, default: 0
  t.integer :dislikes_count, default: 0
  t.timestamps
end

# Update Posts table:
add_column :posts, :likes_count, :integer, default: 0
add_column :posts, :dislikes_count, :integer, default: 0
```

### Production Readiness Checklist:

```
☐ AWS S3 bucket created
☐ IAM credentials configured in credentials.yml.enc
☐ ActiveStorage configured for S3 in production.rb
☐ File size limits set (images < 10MB)
☐ Allowed MIME types whitelisted
☐ Image optimization/resizing setup (ImageMagick)
☐ CDN cache headers configured
☐ Virus scanning setup (optional but recommended)
☐ Database migrations tested on staging
☐ Rollback plan for ActionText (backup existing content)
☐ Performance testing with large images
☐ Load testing for concurrent uploads
```

---

## 5. Implementation Priority & Timeline

### Phase 1 (Week 1): WYSIWYG + Shared Editor
1. Add Trix/ActionText to posts
2. Create shared editor partial
3. Test local image uploads
4. Update API to return HTML content

### Phase 2 (Week 2): Replies System
1. Create Reply model
2. Add reply API endpoints
3. Build reply list UI
4. Implement threading (optional)

### Phase 3 (Week 3): Image Optimization & S3
1. Add ImageMagick for optimization
2. Configure S3 in production
3. Setup CDN caching
4. Load testing

### Phase 4 (Week 4): Polish & Edge Cases
1. Image size validation
2. Malware scanning
3. User notifications for replies
4. Reply notifications
5. Performance optimization

---

## Summary & Recommendations

| Feature | Approach | Rationale |
|---------|----------|-----------|
| **WYSIWYG** | Trix + ActionText | Rails native, simple, sufficient |
| **Images** | ActiveStorage + S3 | Production-ready, scales easily |
| **Replies** | Shared partial + API | DRY, consistent UX, maintainable |
| **Database** | ActionText tables | Abstracted, migrations handled |
| **Frontend** | Stimulus + Turbo | Existing patterns, fast updates |

**Next Steps:**
1. Confirm WYSIWYG choice (recommend Trix)
2. Confirm image storage (recommend S3)
3. Proceed with Phase 1 implementation
