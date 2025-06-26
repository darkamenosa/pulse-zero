# Pulse Zero Examples

## Basic Setup

### 1. Install the gem and run generator

```bash
# Add to Gemfile
group :development do
  gem 'pulse_zero'
end

# Install and generate
bundle install
rails generate pulse_zero:install
```

### 2. Simple Post Model with Broadcasting

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  include Pulse::Broadcastable
  
  belongs_to :user
  belongs_to :account
  
  # Broadcast to account-specific channel
  broadcasts_to ->(post) { [post.account, "posts"] }
end
```

### 3. Controller Setup

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = current_account.posts.includes(:user)
    @pulse_stream = Pulse::Streams::StreamName.signed_stream_name(
      [current_account, "posts"]
    )
    
    render inertia: 'Posts/Index', props: {
      posts: @posts.map(&:as_json),
      pulseStream: @pulse_stream
    }
  end
  
  def create
    @post = current_account.posts.create!(post_params)
    redirect_to posts_path
  end
  
  private
  
  def post_params
    params.require(:post).permit(:title, :content).merge(user: current_user)
  end
end
```

### 4. React Component

```tsx
// app/frontend/pages/Posts/Index.tsx
import { useState } from 'react'
import { usePulse } from '@/hooks/use-pulse'
import { useVisibilityRefresh } from '@/hooks/use-visibility-refresh'
import { router } from '@inertiajs/react'

interface Post {
  id: string
  title: string
  content: string
  createdAt: string
}

interface Props {
  posts: Post[]
  pulseStream: string
}

export default function PostsIndex({ posts: initialPosts, pulseStream }: Props) {
  const [posts, setPosts] = useState(initialPosts)
  
  // Refresh data when tab becomes visible after 30 seconds
  useVisibilityRefresh(30, () => {
    router.reload({ only: ['posts'] })
  })
  
  // Handle real-time updates
  usePulse(pulseStream, (message) => {
    switch (message.event) {
      case 'created':
        // Add new post to the beginning
        setPosts(prev => [message.payload, ...prev])
        break
        
      case 'updated':
        // Update existing post
        setPosts(prev => prev.map(post => 
          post.id === message.payload.id ? message.payload : post
        ))
        break
        
      case 'deleted':
        // Remove deleted post
        setPosts(prev => prev.filter(post => post.id !== message.payload.id))
        break
        
      case 'refresh':
        // Full reload
        router.reload()
        break
    }
  })
  
  return (
    <div className="container mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Posts</h1>
      
      <div className="grid gap-4">
        {posts.map(post => (
          <article key={post.id} className="border p-4 rounded">
            <h2 className="text-xl font-semibold">{post.title}</h2>
            <p className="mt-2">{post.content}</p>
            <time className="text-sm text-gray-500">
              {new Date(post.createdAt).toLocaleString()}
            </time>
          </article>
        ))}
      </div>
    </div>
  )
}
```

## Advanced Examples

### Multi-Channel Broadcasting

```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  include Pulse::Broadcastable
  
  belongs_to :post
  belongs_to :user
  
  # Broadcast to both post-specific and account-wide channels
  broadcasts_to ->(comment) { [comment.post, "comments"] }
  broadcasts_to ->(comment) { [comment.post.account, "activity"] }
end
```

### Custom Event Broadcasting

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  include Pulse::Broadcastable
  
  enum status: { draft: 0, published: 1, archived: 2 }
  
  broadcasts_to ->(post) { [post.account, "posts"] }
  
  def publish!
    update!(status: :published, published_at: Time.current)
    
    # Broadcast custom event
    broadcast_event_to(
      [account, "posts"],
      event: "published",
      payload: {
        id: id,
        title: title,
        publishedAt: published_at.iso8601
      }
    )
  end
end
```

### Handling Custom Events in React

```tsx
usePulse(pulseStream, (message) => {
  if (message.event === 'published') {
    toast.success(`"${message.payload.title}" has been published!`)
    router.reload({ only: ['posts'] })
  }
  
  // Handle standard CRUD events
  switch (message.event) {
    case 'created':
    case 'updated':
    case 'deleted':
      router.reload({ only: ['posts'] })
      break
  }
})
```

### Bulk Operations with Suppressed Broadcasting

```ruby
# app/jobs/import_posts_job.rb
class ImportPostsJob < ApplicationJob
  def perform(csv_path)
    csv_data = CSV.read(csv_path, headers: true)
    
    # Suppress individual broadcasts during import
    Post.suppressing_pulse_broadcasts do
      Post.import(csv_data.map(&:to_h))
    end
    
    # Send single refresh broadcast
    Post.new.broadcast_refresh_to([account, "posts"])
  end
end
```

### Conditional Broadcasting

```ruby
# app/models/notification.rb
class Notification < ApplicationRecord
  include Pulse::Broadcastable
  
  belongs_to :user
  belongs_to :notifiable, polymorphic: true
  
  # Only broadcast unread notifications
  broadcasts_to ->(notification) { 
    [notification.user, "notifications"] if notification.unread?
  }
  
  # Custom callback for read status changes
  after_update_commit :broadcast_if_read_status_changed
  
  private
  
  def broadcast_if_read_status_changed
    if saved_change_to_read_at?
      broadcast_updated_to([user, "notifications"])
    end
  end
end
```

### Dashboard with Multiple Streams

```tsx
// app/frontend/pages/Dashboard.tsx
interface DashboardProps {
  stats: Stats
  recentPosts: Post[]
  notifications: Notification[]
  postStream: string
  notificationStream: string
  activityStream: string
}

export default function Dashboard({ 
  stats, 
  recentPosts, 
  notifications,
  postStream,
  notificationStream,
  activityStream 
}: DashboardProps) {
  // Handle post updates
  usePulse(postStream, (message) => {
    if (message.event === 'created') {
      router.reload({ only: ['stats', 'recentPosts'] })
    }
  })
  
  // Handle notification updates
  usePulse(notificationStream, (message) => {
    router.reload({ only: ['notifications'] })
    
    // Show toast for new notifications
    if (message.event === 'created') {
      toast.info('You have a new notification')
    }
  })
  
  // Handle general activity updates
  usePulse(activityStream, (message) => {
    router.reload({ only: ['stats'] })
  })
  
  // Refresh on tab visibility
  useVisibilityRefresh(60, () => {
    router.reload()
  })
  
  return (
    <div className="dashboard">
      {/* Dashboard content */}
    </div>
  )
}
```

### Custom Serializer for Different Contexts

```ruby
# config/initializers/pulse.rb
Rails.application.configure do
  config.pulse.serializer = lambda do |record|
    case record
    when Post
      if Current.user.admin?
        # Admin sees full data
        record.as_json(
          include: { user: { only: [:id, :name, :email] } },
          methods: [:view_count, :engagement_rate]
        )
      else
        # Regular users see limited data
        record.as_json(
          only: [:id, :title, :content, :published_at],
          include: { user: { only: [:id, :name] } }
        )
      end
      
    when Notification
      {
        id: record.id,
        type: record.notifiable_type,
        message: record.message,
        read: record.read?,
        createdAt: record.created_at.iso8601
      }
      
    else
      record.as_json
    end
  end
end
```

### Testing Broadcasting

```ruby
# test/models/post_test.rb
class PostTest < ActiveSupport::TestCase
  include ActionCable::TestHelper
  
  test "broadcasts on create" do
    account = accounts(:acme)
    
    assert_broadcast_on(
      Pulse::Streams::StreamName.signed_stream_name([account, "posts"])
    ) do
      Post.create!(
        account: account,
        user: users(:john),
        title: "Test Post",
        content: "Test content"
      )
    end
  end
  
  test "custom broadcast on publish" do
    post = posts(:draft)
    stream = Pulse::Streams::StreamName.signed_stream_name([post.account, "posts"])
    
    assert_broadcast_on(stream) do |data|
      message = JSON.parse(data)
      assert_equal "published", message["event"]
      assert_equal post.id.to_s, message["payload"]["id"]
    end
    
    post.publish!
  end
end
```

### Production Considerations

```ruby
# config/environments/production.rb
Rails.application.configure do
  # Use Redis for ActionCable in production
  config.action_cable.adapter = :redis
  config.action_cable.url = ENV["REDIS_URL"]
  
  # Configure allowed origins
  config.action_cable.allowed_request_origins = [
    'https://yourdomain.com',
    'https://www.yourdomain.com'
  ]
  
  # Use separate queue for broadcasts
  config.pulse.queue_name = :broadcasts
  
  # Increase debounce time for production
  config.pulse.debounce_ms = 500
end
```

### Error Handling

```tsx
// app/frontend/hooks/use-pulse-with-error-handling.ts
import { usePulse } from '@/hooks/use-pulse'
import { toast } from 'sonner'

export function usePulseWithErrorHandling(
  streamName: string,
  onMessage: (message: any) => void
) {
  usePulse(streamName, (message) => {
    try {
      onMessage(message)
    } catch (error) {
      console.error('[Pulse] Error handling message:', error)
      toast.error('Failed to process real-time update')
      
      // Fallback to full reload
      setTimeout(() => {
        window.location.reload()
      }, 2000)
    }
  })
}
```