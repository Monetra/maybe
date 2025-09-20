# Web Frontend Integration

## Hotwire Architecture

Maybe uses the Hotwire stack (Turbo + Stimulus) to provide a modern, reactive user experience while maintaining the simplicity and power of server-side rendering.

## Turbo Integration

### Page-Level Navigation
Turbo Drive handles full-page navigation with seamless transitions:

```erb
<!-- Standard Rails links work with Turbo -->
<%= link_to "Accounts", accounts_path, class: "nav-link" %>
```

### Turbo Frames
Break up pages into independent, updatable sections:

```erb
<!-- Global chat sidebar -->
<%= turbo_frame_tag "chat-container", src: chat_view_path(@chat), loading: "lazy" do %>
  <div class="flex justify-center items-center h-full">
    <%= icon("loader-circle", class: "animate-spin") %>
  </div>
<% end %>
```

### Turbo Streams
Real-time updates without full page reloads:

```ruby
# Controller action
def create
  @transaction = Current.family.transactions.build(transaction_params)
  
  if @transaction.save
    respond_to do |format|
      format.turbo_stream # Renders create.turbo_stream.erb
      format.html { redirect_to @transaction }
    end
  end
end
```

```erb
<!-- create.turbo_stream.erb -->
<%= turbo_stream.append "transactions-list", @transaction %>
<%= turbo_stream.update "transaction-form", partial: "form" %>
```

## Stimulus Controllers

### Declarative Actions
HTML declares what happens, JavaScript responds:

```erb
<!-- GOOD: Declarative approach -->
<div data-controller="toggle">
  <button data-action="click->toggle#toggle" data-toggle-target="button">
    Show
  </button>
  <div data-toggle-target="content" class="hidden">
    Hello World!
  </div>
</div>
```

```javascript
// toggle_controller.js
export default class extends Controller {
  static targets = ["button", "content"]
  
  toggle() {
    this.contentTarget.classList.toggle("hidden")
    this.buttonTarget.textContent = this.contentTarget.classList.contains("hidden") ? "Show" : "Hide"
  }
}
```

### Controller Organization

#### Global Controllers (`app/javascript/controllers/`)
- Used across multiple views
- General-purpose functionality
- Examples: `app_layout_controller.js`, `bulk_select_controller.js`

#### Component Controllers (`app/components/`)
- Used only within their component
- Component-specific functionality
- Examples: `button_component.js`, `dialog_component.js`

### Data Flow Patterns

#### Rails to Stimulus
Pass data from Rails to Stimulus using `data-*-value` attributes:

```erb
<div data-controller="chart" 
     data-chart-data-value="<%= @chart_data.to_json %>"
     data-chart-type-value="line">
</div>
```

```javascript
// chart_controller.js
export default class extends Controller {
  static values = { data: Array, type: String }
  
  connect() {
    this.renderChart()
  }
  
  renderChart() {
    // Use this.dataValue and this.typeValue
  }
}
```

#### Stimulus to Rails
Submit forms or make requests from Stimulus:

```javascript
// form_controller.js
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
  
  async save() {
    const formData = new FormData(this.formTarget)
    
    const response = await fetch(this.saveUrlValue, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    
    if (response.ok) {
      this.showSuccess()
    }
  }
}
```

## ViewComponent Integration

### Component Structure
Reusable UI components with associated Stimulus controllers:

```ruby
# app/components/ds/button_component.rb
class DS::ButtonComponent < ApplicationComponent
  def initialize(variant: "primary", size: "md", **options)
    @variant = variant
    @size = size
    @options = options
  end
  
  private
  
  attr_reader :variant, :size, :options
end
```

```erb
<!-- app/components/ds/button_component.html.erb -->
<%= tag.button class: button_classes, **button_attributes do %>
  <%= content %>
<% end %>
```

```javascript
// app/components/ds/button_component.js
export default class extends Controller {
  static targets = ["button"]
  
  click() {
    // Button-specific behavior
  }
}
```

### Component Usage
Components are used throughout the application:

```erb
<%= render DS::Button.new(
  variant: "primary",
  size: "lg",
  data: { action: "click->form#submit" }
) do %>
  Save Transaction
<% end %>
```

## Real-Time Features

### Turbo Streams for Live Updates
Real-time updates using Turbo Streams:

```ruby
# Broadcast updates to all users
class Transaction < ApplicationRecord
  after_create_commit :broadcast_create
  after_update_commit :broadcast_update
  after_destroy_commit :broadcast_destroy
  
  private
  
  def broadcast_create
    broadcast_prepend_to "transactions", partial: "transaction", locals: { transaction: self }
  end
end
```

### WebSocket Integration
Real-time chat functionality:

```ruby
# Chat updates
class Chat < ApplicationRecord
  after_create_commit :broadcast_chat_created
  after_update_commit :broadcast_chat_updated
  
  private
  
  def broadcast_chat_created
    broadcast_prepend_to "chats", partial: "chat", locals: { chat: self }
  end
end
```

## Form Handling

### Progressive Enhancement
Forms work with and without JavaScript:

```erb
<!-- Form works with or without JavaScript -->
<%= form_with model: @transaction, local: false, data: { controller: "form" } do |form| %>
  <%= form.text_field :description, data: { action: "input->form#validate" } %>
  <%= form.submit "Save", data: { action: "click->form#submit" } %>
<% end %>
```

### Client-Side Validation
Immediate feedback without server round-trip:

```javascript
// form_controller.js
export default class extends Controller {
  validate() {
    const input = this.descriptionTarget
    const value = input.value.trim()
    
    if (value.length < 3) {
      this.showError("Description must be at least 3 characters")
    } else {
      this.clearError()
    }
  }
}
```

## State Management

### URL-Based State
Use query parameters for state instead of local storage:

```ruby
# Controller
def index
  @filter = params[:filter] || "all"
  @sort = params[:sort] || "date"
  @transactions = Current.family.transactions
    .filter_by(@filter)
    .order(@sort)
end
```

```erb
<!-- View -->
<%= link_to "All", transactions_path(filter: "all"), 
    class: @filter == "all" ? "active" : "" %>
<%= link_to "Income", transactions_path(filter: "income"), 
    class: @filter == "income" ? "active" : "" %>
```

### Stimulus State
Manage component state in Stimulus controllers:

```javascript
// filter_controller.js
export default class extends Controller {
  static values = { 
    currentFilter: String,
    availableFilters: Array 
  }
  
  connect() {
    this.updateUI()
  }
  
  selectFilter(event) {
    this.currentFilterValue = event.target.value
    this.updateUI()
    this.dispatch("filterChanged", { detail: { filter: this.currentFilterValue } })
  }
  
  updateUI() {
    // Update UI based on current state
  }
}
```

## Performance Optimization

### Lazy Loading
Load content only when needed:

```erb
<!-- Lazy load chat sidebar -->
<%= turbo_frame_tag "chat-container", 
    src: chat_view_path(@chat), 
    loading: "lazy" do %>
  <div class="loading-spinner">Loading...</div>
<% end %>
```

### Caching
Cache expensive operations:

```ruby
# Controller
def index
  @transactions = Rails.cache.fetch("transactions_#{Current.family.cache_key}", expires_in: 1.hour) do
    Current.family.transactions.includes(:category, :merchant).to_a
  end
end
```

### Background Processing
Move heavy operations to background jobs:

```ruby
# Controller
def create
  @transaction = Current.family.transactions.build(transaction_params)
  
  if @transaction.save
    # Process in background
    AutoCategorizeJob.perform_later(@transaction)
    redirect_to @transaction
  end
end
```

## Error Handling

### Graceful Degradation
Ensure functionality works without JavaScript:

```erb
<!-- Form with JavaScript enhancement -->
<%= form_with model: @transaction, local: true, data: { controller: "form" } do |form| %>
  <%= form.text_field :description %>
  <%= form.submit "Save" %>
<% end %>
```

### Error Display
Show errors in real-time:

```javascript
// form_controller.js
export default class extends Controller {
  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }
  
  clearError() {
    this.errorTarget.classList.add("hidden")
  }
}
```

## Testing Integration

### System Tests
Test the full integration:

```ruby
# test/system/transactions_test.rb
class TransactionsTest < ApplicationSystemTestCase
  test "creating a transaction" do
    visit transactions_path
    click_on "New Transaction"
    
    fill_in "Description", with: "Test Transaction"
    fill_in "Amount", with: "100.00"
    
    click_on "Save"
    
    assert_text "Transaction created successfully"
  end
end
```

### Stimulus Controller Tests
Test JavaScript functionality:

```javascript
// test/javascript/controllers/form_controller_test.js
import { Application } from "@hotwired/stimulus"
import FormController from "controllers/form_controller"

const application = Application.start()
application.register("form", FormController)

// Test form validation
test("validates form input", () => {
  const form = document.createElement("form")
  form.setAttribute("data-controller", "form")
  document.body.appendChild(form)
  
  const controller = application.getControllerForElementAndIdentifier(form, "form")
  
  // Test validation logic
  controller.validate()
  // Assert expected behavior
})
```

## Best Practices

### 1. Declarative Over Imperative
```erb
<!-- GOOD: Declarative -->
<button data-action="click->toggle#toggle">Toggle</button>

<!-- BAD: Imperative -->
<button id="toggle-btn">Toggle</button>
```

### 2. Keep Controllers Simple
```javascript
// GOOD: Simple, focused controller
export default class extends Controller {
  static targets = ["button", "content"]
  
  toggle() {
    this.contentTarget.classList.toggle("hidden")
  }
}

// BAD: Complex controller with many responsibilities
export default class extends Controller {
  // 200+ lines of code
}
```

### 3. Use Semantic HTML
```erb
<!-- GOOD: Semantic HTML -->
<button type="button" data-action="click->dialog#open">
  Open Dialog
</button>

<!-- BAD: Non-semantic HTML -->
<div class="button" data-action="click->dialog#open">
  Open Dialog
</div>
```

### 4. Progressive Enhancement
```erb
<!-- Form works with and without JavaScript -->
<%= form_with model: @transaction, local: true, data: { controller: "form" } do |form| %>
  <%= form.text_field :description %>
  <%= form.submit "Save" %>
<% end %>
```

### 5. Consistent Naming
```javascript
// GOOD: Consistent naming
export default class extends Controller {
  static targets = ["button", "content"]
  static values = { open: Boolean }
  
  toggle() {
    this.openValue = !this.openValue
  }
}
```

## Mobile Considerations

### Responsive Design
Ensure components work on mobile:

```erb
<!-- Mobile-friendly navigation -->
<nav class="lg:hidden flex justify-between items-center p-3">
  <%= icon("panel-left", as_button: true, data: { action: "app-layout#openMobileSidebar"}) %>
  <%= link_to root_path do %>
    <%= image_tag "logomark-color.svg", class: "w-9 h-9" %>
  <% end %>
</nav>
```

### Touch Interactions
Optimize for touch devices:

```javascript
// touch_controller.js
export default class extends Controller {
  static targets = ["item"]
  
  touchStart(event) {
    this.startY = event.touches[0].clientY
  }
  
  touchMove(event) {
    const currentY = event.touches[0].clientY
    const diff = this.startY - currentY
    
    if (Math.abs(diff) > 10) {
      // Handle swipe
    }
  }
}
```

This architecture provides a modern, reactive user experience while maintaining the simplicity and power of server-side rendering with Rails.
