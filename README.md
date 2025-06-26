# Pulse Zero

Real-time broadcasting generator for Rails + Inertia.js applications. Generate a complete WebSocket-based real-time system with zero runtime dependencies.

## What is Pulse Zero?

Pulse Zero generates a complete real-time broadcasting system directly into your Rails application. Unlike traditional gems, all code is copied into your project, giving you full ownership and the ability to customize everything.

Inspired by Turbo Rails, Pulse Zero brings familiar broadcasting patterns to Inertia.js applications. If you've used `broadcasts_to` in Turbo Rails, you'll feel right at home with Pulse Zero's API.

Features:
- 🚀 WebSocket broadcasting via ActionCable
- 🔒 Secure signed streams
- 📱 Browser tab suspension handling
- 🔄 Automatic reconnection with exponential backoff
- 📦 TypeScript support for Inertia + React
- 🎯 Zero runtime dependencies
- 🏗️ Turbo Rails-inspired API design

## Installation

Add this gem to your application's Gemfile:

```ruby
group :development do
  gem 'pulse_zero'
end
```

Then run:

```bash
bundle install
rails generate pulse_zero:install
```

## What Gets Generated?

### Backend (Ruby)
- `lib/pulse/` - Core broadcasting system
- `app/models/concerns/pulse/broadcastable.rb` - Model broadcasting DSL
- `app/controllers/concerns/pulse/request_id_tracking.rb` - Request tracking
- `app/channels/pulse/channel.rb` - WebSocket channel
- `app/jobs/pulse/broadcast_job.rb` - Async broadcasting
- `config/initializers/pulse.rb` - Configuration

### Frontend (TypeScript)
- `app/frontend/lib/pulse.ts` - Subscription manager
- `app/frontend/lib/pulse-connection.ts` - Connection monitoring
- `app/frontend/lib/pulse-recovery-strategy.ts` - Recovery logic
- `app/frontend/lib/pulse-visibility-manager.ts` - Tab visibility handling
- `app/frontend/hooks/use-pulse.ts` - React subscription hook
- `app/frontend/hooks/use-visibility-refresh.ts` - Tab refresh hook

## Quick Start

### 1. Enable Broadcasting on a Model

```ruby
class Post < ApplicationRecord
  include Pulse::Broadcastable
  
  # Broadcast to a simple channel
  broadcasts_to ->(post) { "posts" }
  
  # Or broadcast to account-scoped channel
  # broadcasts_to ->(post) { [post.account, "posts"] }
end
```

### 2. Pass Stream Token to Frontend

```ruby
class PostsController < ApplicationController
  def index
    @posts = Post.all

    render inertia: "Post/Index", props: {
      posts: @posts.map do |post|
        serialize_post(post)
      end,
      pulseStream: Pulse::Streams::StreamName.signed_stream_name("posts")
    }
  end
  
  private
  
  def serialize_post(post)
    {
      id: post.id,
      title: post.title,
      content: post.content,
      created_at: post.created_at
    }
  end
end
```

**Why pulseStream?** Following Turbo Rails' security model, Pulse uses signed stream names to prevent unauthorized access to WebSocket channels. Since Inertia.js doesn't have a built-in way to access streams like Turbo does, we pass the signed stream name as a prop. This approach:
- Maintains security through cryptographically signed tokens
- Works naturally with Inertia's prop system
- Keeps the API simple and explicit

### 3. Subscribe in React Component

```tsx
import { useState } from 'react'
import { usePulse } from '@/hooks/use-pulse'
import { useVisibilityRefresh } from '@/hooks/use-visibility-refresh'
import { router } from '@inertiajs/react'

interface IndexProps {
  posts: Array<{
    id: number
    title: string
    content: string
    created_at: string
  }>
  pulseStream: string
  flash: {
    success?: string
    error?: string
  }
}

export default function Index({ posts: initialPosts, flash, pulseStream }: IndexProps) {
  // Use local state for posts to enable real-time updates
  const [posts, setPosts] = useState(initialPosts)
  
  // Automatically refresh data when returning to the tab after 30+ seconds
  // This ensures users see fresh data after being away, handling cases where
  // WebSocket messages might have been missed during browser suspension
  useVisibilityRefresh(30, () => {
    router.reload({ only: ['posts'] })
  })

  // Subscribe to Pulse updates for real-time changes
  usePulse(pulseStream, (message) => {
    switch (message.event) {
      case 'created':
        // Add the new post to the beginning of the list
        setPosts(prev => [message.payload, ...prev])
        break
      case 'updated':
        // Replace the updated post in the list
        setPosts(prev => 
          prev.map(post => post.id === message.payload.id ? message.payload : post)
        )
        break
      case 'deleted':
        // Remove the deleted post from the list
        setPosts(prev => 
          prev.filter(post => post.id !== message.payload.id)
        )
        break
      case 'refresh':
        // Full reload for refresh events
        router.reload()
        break
    }
  })
  
  return (
    <>
      {flash.success && <div className="alert-success">{flash.success}</div>}
      <PostsList posts={posts} />
    </>
  )
}
```

**Note:** This example shows optimistic UI updates using local state. Alternatively, you can use `router.reload({ only: ['posts'] })` for all events to fetch fresh data from the server, which ensures consistency but may feel less responsive.

**Why useVisibilityRefresh?** When users switch tabs or minimize their browser, WebSocket connections can be suspended and messages may be lost. The `useVisibilityRefresh` hook detects when users return to your app and automatically refreshes the data if they've been away for more than the specified threshold (30 seconds in this example). This ensures users always see up-to-date information without manual refreshing.

## Broadcasting Events

Pulse broadcasts four types of events:

### `created` - When a record is created
```json
{
  "event": "created",
  "payload": { "id": 123, "content": "New post" },
  "requestId": "uuid-123",
  "at": 1234567890.123
}
```

### `updated` - When a record is updated
```json
{
  "event": "updated",
  "payload": { "id": 123, "content": "Updated post" },
  "requestId": "uuid-456",
  "at": 1234567891.456
}
```

### `deleted` - When a record is destroyed
```json
{
  "event": "deleted",
  "payload": { "id": 123 },
  "requestId": "uuid-789",
  "at": 1234567892.789
}
```

### `refresh` - Force a full refresh
```json
{
  "event": "refresh",
  "payload": {},
  "requestId": "uuid-012",
  "at": 1234567893.012
}
```

## Advanced Usage

### Manual Broadcasting

```ruby
# Broadcast with custom payload
post.broadcast_updated_to(
  [Current.account, "posts"],
  payload: { id: post.id, featured: true }
)

# Async broadcasting
post.broadcast_updated_later_to([Current.account, "posts"])
```

### Suppress Broadcasts During Bulk Operations

```ruby
Post.suppressing_pulse_broadcasts do
  Post.where(account: account).update_all(featured: true)
end

# Then send one refresh broadcast
Post.new.broadcast_refresh_to([account, "posts"])
```

### Custom Serialization

```ruby
# config/initializers/pulse.rb
Rails.application.configure do
  config.pulse.serializer = ->(record) {
    case record
    when Post
      record.as_json(only: [:id, :title, :state])
    else
      record.as_json
    end
  }
end
```

## Configuration

```ruby
# config/initializers/pulse.rb
Rails.application.configure do
  # Debounce window in milliseconds (default: 300)
  config.pulse.debounce_ms = 300
  
  # Background job queue (default: :default)
  config.pulse.queue_name = :low
  
  # Custom serializer
  config.pulse.serializer = ->(record) { record.as_json }
end
```

## Browser Tab Handling

Pulse includes sophisticated handling for browser tab suspension:

- **Quick switches (<30s)**: Just ensures connection is alive
- **Medium absence (30s-5min)**: Reconnects and syncs data
- **Long absence (>5min)**: Full page refresh for consistency

Platform-aware thresholds:
- Desktop Chrome/Firefox: 30 seconds
- Safari/Mobile: 15 seconds (more aggressive)

## Testing

```ruby
# In your test files
test "broadcasts on update" do
  post = posts(:one)
  
  assert_broadcast_on([post.account, "posts"]) do
    post.update!(title: "New Title")
  end
end

# Suppress broadcasts in tests
Post.suppressing_pulse_broadcasts do
  # Your test code
end
```

## Debugging

Enable debug logging:

```javascript
// In browser console
localStorage.setItem('PULSE_DEBUG', 'true')
```

Check connection health:

```javascript
import { getPulseMonitorStats } from '@/lib/pulse-connection'

const stats = getPulseMonitorStats()
console.log(stats)
```

## Requirements

- Rails 7.0+
- ActionCable
- Inertia.js
- React (Vue/Svelte support coming soon)
- TypeScript

## Philosophy

Pulse Zero follows the same philosophy as [authentication-zero](https://github.com/lazaronixon/authentication-zero), and is heavily inspired by [Turbo Rails](https://github.com/hotwired/turbo-rails). The API design closely mirrors Turbo Rails patterns, making it intuitive for developers already familiar with the Hotwire ecosystem.

- **Own your code**: All code is generated into your project
- **No runtime dependencies**: The gem is only needed during generation
- **Customizable**: Modify any generated code to fit your needs
- **Production-ready**: Includes battle-tested patterns from real applications
- **Familiar API**: Inspired by Turbo Rails, uses similar broadcasting patterns and conventions

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).