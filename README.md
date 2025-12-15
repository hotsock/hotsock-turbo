# Hotsock Turbo

Turbo Streams integration for [Hotsock](https://www.hotsock.io), enabling real-time updates in Rails applications using Hotsock's WebSocket infrastructure.

## Overview

Hotsock Turbo provides a seamless way to broadcast Turbo Stream updates to your Rails application using Hotsock instead of Action Cable. It offers:

- Real-time page updates via WebSockets
- Model callbacks for automatic broadcasting on create, update, and destroy
- Support for Turbo Stream refresh (morphing) broadcasts
- Drop-in replacement mode for existing `Turbo::Broadcastable` usage
- Both synchronous and asynchronous (ActiveJob) broadcasting

## Requirements

- Ruby >= 3.2
- Rails with [Turbo](https://github.com/hotwired/turbo-rails)
- [Hotsock](https://rubygems.org/gems/hotsock) gem (>= 1.0)
- [@hotsock/hotsock-js](https://www.npmjs.com/package/@hotsock/hotsock-js) npm package

## Installation

Add the gem to your Gemfile:

```ruby
gem "turbo-rails"
gem "hotsock-turbo"
```

Then run:

```bash
bundle install
```

### JavaScript Setup

#### Using Importmap

```bash
bin/importmap pin @hotsock/hotsock-js
```

Then in your `application.js`:

```javascript
import "@hotsock/hotsock-js"
import "hotsock-turbo"
```

#### Using npm/yarn

```bash
npm install @hotsock/hotsock-js
# or
yarn add @hotsock/hotsock-js
```

Then in your JavaScript entry point:

```javascript
import "@hotsock/hotsock-js"
import "hotsock-turbo"
```

## Configuration

Create an initializer at `config/initializers/hotsock_turbo.rb`:

```ruby
Hotsock::Turbo.configure do |config|
  # Required: Path to an endpoint that returns Hotsock connection tokens
  config.connect_token_path = "/hotsock/connect_token"

  # Required: Your Hotsock WebSocket URL
  config.wss_url = "wss://your-hotsock-instance.example.com"

  # Optional: Log level for the JavaScript client (default: "warn")
  config.log_level = "warn"

  # Optional: Parent controller for any generated routes (default: "ApplicationController")
  config.parent_controller = "ApplicationController"

  # Optional: Enable drop-in replacement for Turbo::Broadcastable (default: false)
  config.override_turbo_broadcastable = false
end
```

### Configuration Options

| Option                         | Default                   | Description                                                            |
| ------------------------------ | ------------------------- | ---------------------------------------------------------------------- |
| `connect_token_path`           | `nil`                     | Path to your endpoint that issues Hotsock connection tokens            |
| `wss_url`                      | `nil`                     | Your Hotsock WebSocket server URL                                      |
| `log_level`                    | `"warn"`                  | JavaScript client log level (`"debug"`, `"info"`, `"warn"`, `"error"`) |
| `parent_controller`            | `"ApplicationController"` | Base controller for generated routes                                   |
| `override_turbo_broadcastable` | `false`                   | When `true`, overrides standard Turbo broadcast methods to use Hotsock |

## Usage

### View Helpers

#### Meta Tags

Add the required meta tags to your layout (typically in `<head>`):

```erb
<%= hotsock_turbo_meta_tags %>
```

This renders the configuration needed by the JavaScript client:

```html
<meta name="hotsock:connect-token-path" content="/hotsock/connect_token" />
<meta name="hotsock:log-level" content="warn" />
<meta
  name="hotsock:wss-url"
  content="wss://your-hotsock-instance.example.com"
/>
```

You can override configuration per-page:

```erb
<%= hotsock_turbo_meta_tags wss_url: "wss://other.example.com", log_level: "debug" %>
```

#### Stream Subscriptions

Subscribe to streams in your views:

```erb
<%= hotsock_turbo_stream_from @board %>
<%= hotsock_turbo_stream_from @board, :messages %>
<%= hotsock_turbo_stream_from "custom_stream_name" %>
```

This renders a custom element that manages the WebSocket subscription:

```html
<hotsock-turbo-stream-source
  data-channel="..."
  data-token="..."
  data-user-id="..."
>
</hotsock-turbo-stream-source>
```

### Model Broadcasting

Hotsock Turbo automatically includes broadcasting methods in all ActiveRecord models.

#### Broadcasting Refreshes

For models that should trigger page refreshes (works great with Turbo's morphing):

```ruby
class Board < ApplicationRecord
  # Broadcasts refresh to "boards" stream on create/update/destroy
  hotsock_broadcasts_refreshes
end

class Column < ApplicationRecord
  belongs_to :board

  # Broadcasts refresh to the board's stream on create/update/destroy
  hotsock_broadcasts_refreshes_to :board
end
```

#### Broadcasting DOM Updates

For fine-grained DOM updates (append, replace, remove):

```ruby
class Message < ApplicationRecord
  belongs_to :board

  # Broadcasts append on create, replace on update, remove on destroy
  hotsock_broadcasts_to :board
end

class Comment < ApplicationRecord
  # Broadcasts to "comments" stream by default
  hotsock_broadcasts
end
```

#### Options

```ruby
class Message < ApplicationRecord
  belongs_to :board

  # Customize the insert action and target
  hotsock_broadcasts_to :board,
    inserts_by: :prepend,          # :append (default), :prepend
    target: "board_messages",       # DOM ID to target
    partial: "messages/card"        # Custom partial
end
```

### Instance Methods

Broadcast from anywhere in your application:

```ruby
message = Message.find(1)

# Sync broadcasts (immediate)
message.hotsock_broadcast_refresh
message.hotsock_broadcast_refresh_to(board)
message.hotsock_broadcast_replace
message.hotsock_broadcast_replace_to(board)
message.hotsock_broadcast_append_to(board, target: "messages")
message.hotsock_broadcast_prepend_to(board, target: "messages")
message.hotsock_broadcast_remove
message.hotsock_broadcast_remove_to(board)

# Async broadcasts (via ActiveJob)
message.hotsock_broadcast_refresh_later
message.hotsock_broadcast_refresh_later_to(board)
message.hotsock_broadcast_replace_later
message.hotsock_broadcast_replace_later_to(board)
message.hotsock_broadcast_append_later_to(board, target: "messages")
message.hotsock_broadcast_prepend_later_to(board, target: "messages")
```

### Direct Channel Broadcasting

Broadcast without a model instance:

```ruby
Hotsock::Turbo::StreamsChannel.broadcast_refresh_to(board)
Hotsock::Turbo::StreamsChannel.broadcast_append_to(
  board,
  target: "messages",
  partial: "messages/message",
  locals: { message: message }
)
Hotsock::Turbo::StreamsChannel.broadcast_remove_to(board, target: "message_123")
```

### Drop-in Turbo Replacement

If you have existing code using `Turbo::Broadcastable` methods, you can enable drop-in replacement mode:

```ruby
# config/initializers/hotsock_turbo.rb
Hotsock::Turbo.configure do |config|
  config.override_turbo_broadcastable = true
end
```

Now standard Turbo method names work with Hotsock:

```ruby
class Message < ApplicationRecord
  belongs_to :board

  # These now use Hotsock instead of Action Cable
  broadcasts_refreshes_to :board
  broadcasts_to :board
  broadcasts
  broadcasts_refreshes
end

# Instance methods also work
message.broadcast_refresh
message.broadcast_replace_later_to(board)
```

### Suppressing Broadcasts

Temporarily disable broadcasts within a block:

```ruby
Message.suppressing_turbo_broadcasts do
  # No broadcasts will be sent
  Message.create!(content: "Silent message", board: board)
  message.update!(content: "Silent update")
end
```

Check suppression status:

```ruby
Message.suppressed_turbo_broadcasts?  # => false

Message.suppressing_turbo_broadcasts do
  Message.suppressed_turbo_broadcasts?  # => true
end
```

## Customization

### Custom User Identification

By default, subscriptions use `session.id` as the user identifier. Override this by defining `hotsock_uid` in your helper or controller:

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  private

  def hotsock_uid
    current_user&.id&.to_s || session.id.to_s
  end
end
```

## How It Works

1. **Meta tags** provide configuration to the JavaScript client
2. **`<hotsock-turbo-stream-source>`** elements connect to Hotsock via WebSocket
3. **Model callbacks** or direct calls trigger broadcasts via `Hotsock::Turbo::StreamsChannel`
4. **Hotsock** delivers messages to subscribed clients
5. **JavaScript client** receives messages and calls `Turbo.renderStreamMessage()` to update the DOM

## License

This gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
