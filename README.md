# Pulse Zero

Real-time broadcasting generator for Rails + Inertia.js applications. Generate a complete WebSocket-based real-time system with zero runtime dependencies.

## What is Pulse Zero?

Pulse Zero generates a complete real-time broadcasting system directly into your Rails application. Unlike traditional gems, all code is copied into your project, giving you full ownership and the ability to customize everything.

Features:
- 🚀 WebSocket broadcasting via ActionCable
- 🔒 Secure signed streams
- 📱 Browser tab suspension handling
- 🔄 Automatic reconnection with exponential backoff
- 📦 TypeScript support for Inertia + React
- 🎯 Zero runtime dependencies

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
  
  # Broadcast to account-scoped channel
  broadcasts_to ->(post) { [post.account, "posts"] }
  
  # Or broadcast to a simple channel
  broadcasts "posts"
end
```

### 2. Pass Stream Token to Frontend

```ruby
class PostsController < ApplicationController
  def index
    @posts = Current.account.posts
    @pulse_stream = Pulse::Streams::StreamName
      .signed_stream_name([Current.account, "posts"])
  end
end
```

### 3. Subscribe in React Component

```tsx
import { usePulse } from '@/hooks/use-pulse'
import { useVisibilityRefresh } from '@/hooks/use-visibility-refresh'
import { router } from '@inertiajs/react'

export default function Posts({ posts, pulseStream }) {
  // Handle tab visibility
  useVisibilityRefresh(30, () => {
    router.reload({ only: ['posts'] })
  })
  
  // Subscribe to real-time updates
  usePulse(pulseStream, (message) => {
    switch (message.event) {
      case 'created':
      case 'updated':
      case 'deleted':
        router.reload({ only: ['posts'] })
        break
    }
  })
  
  return <PostsList posts={posts} />
}
```

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

Pulse Zero follows the same philosophy as [authentication-zero](https://github.com/lazaronixon/authentication-zero):

- **Own your code**: All code is generated into your project
- **No runtime dependencies**: The gem is only needed during generation
- **Customizable**: Modify any generated code to fit your needs
- **Production-ready**: Includes battle-tested patterns from real applications

## Contributing

Bug reports and pull requests are welcome on GitHub.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).