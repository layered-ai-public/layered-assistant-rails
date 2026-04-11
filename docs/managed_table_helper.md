## Use `l_ui_managed_table` for index views

layered-ui-rails now provides a standalone table helper called `l_ui_managed_table`. It renders a styled, accessible data table that you can use in any view with any controller - no need to use the managed resources shared controller or routes.

### Helper API

```ruby
l_ui_managed_table(records,
  columns: [
    { attribute: :name, primary: true },
    { attribute: :description },
  ],
  actions: ->(r) { link_to "Edit", edit_persona_path(r) },
  caption: "Personas"
)
```

**Parameters:**
- `records` — any enumerable (ActiveRecord relation, array, etc.)
- `columns:` — array of column hashes (see below)
- `caption:` — screen-reader-only table caption (recommended for accessibility)
- `actions:` — proc receiving a record, returns HTML for a right-aligned actions cell. For multiple actions use `safe_join`: `actions: ->(r) { safe_join([link_to("Edit", edit_path(r)), link_to("Delete", path(r), data: { turbo_method: :delete })]) }`

**Column hash options:**
- `attribute:` (Symbol, required) — model attribute. Used for data extraction (when no `render:` proc) and for auto-generating the header label.
- `label:` (String, optional) — custom header text. Defaults to humanised attribute name.
- `primary:` (Boolean, optional) — renders as `<th scope="row">` for accessibility. Defaults to first column if none specified.
- `render:` (Proc, optional) — receives the record, returns cell content. When absent, falls back to `record.public_send(attribute)` with automatic date formatting. The proc runs in the view context so all helpers (`link_to`, `truncate`, `number_with_delimiter`, content tags, etc.) are available.

### Migration pattern

Replace hand-written index tables with the helper. Keep your existing controllers and routes - the helper only renders the table, so header actions, scoping, and routing stay in your control.

Before (hand-written):
```erb
<h1>Personas</h1>
<p><%= link_to "New persona", new_persona_path, class: "l-ui-button--primary" %></p>

<table class="l-ui-table">
  <thead>...</thead>
  <tbody>
    <% @personas.each do |persona| %>
      <tr>
        <th scope="row"><%= link_to persona.name, persona_path(persona) %></th>
        <td><%= truncate(persona.description, length: 60) %></td>
        <td><%= link_to "Edit", edit_persona_path(persona) %></td>
      </tr>
    <% end %>
  </tbody>
</table>
```

After:
```erb
<div class="l-ui-container--spread">
  <h1 class="l-ui-heading">Personas</h1>
  <%= link_to "New persona", new_persona_path, class: "l-ui-button--primary" %>
</div>

<%= l_ui_managed_table(@personas,
      columns: [
        { attribute: :name, primary: true, render: ->(r) { link_to r.name, persona_path(r) } },
        { attribute: :description, render: ->(r) { truncate(r.description, length: 60) } },
      ],
      actions: ->(r) { link_to "Edit", edit_persona_path(r) },
      caption: "Personas"
    ) %>

<%= l_ui_pagy(@pagy) if @pagy %>
```

### Common render proc patterns

```ruby
# Association traversal with nil fallback
{ attribute: :persona, render: ->(r) { r.persona&.name || "None" } }

# Linked cell
{ attribute: :name, primary: true, render: ->(r) { link_to r.name, conversation_path(r) } }

# Linked count
{ attribute: :messages_count, render: ->(r) { link_to r.messages_count, conversation_messages_path(r) } }

# Badge for boolean
{ attribute: :enabled, render: ->(r) {
    tag.span(r.enabled? ? "Enabled" : "Disabled",
             class: r.enabled? ? "l-ui-badge--success" : "l-ui-badge--danger")
  }
}

# Translated enum
{ attribute: :protocol, render: ->(r) { I18n.t("layered_assistant.protocols.#{r.protocol}") } }

# Number formatting
{ attribute: :token_estimate, render: ->(r) { number_with_delimiter(r.token_estimate) } }

# Text truncation
{ attribute: :description, render: ->(r) { truncate(r.description, length: 60) } }
```

### What stays in your control

- **Header actions** — wrap the heading and buttons in `<div class="l-ui-container--spread">` above the table call
- **Scoping** — your controller applies whatever scoping it needs before passing records to the view
- **Routing** — use your own route helpers in the `render:` and `actions:` procs
- **Pagination** — call `l_ui_pagy(@pagy)` separately below the table
- **Search** — call `l_ui_search_form(@q, ...)` separately above the table

### Good candidates to migrate first

Start with the simplest CRUD indices: **Personas** and **Skills**. They have straightforward columns with minimal custom rendering. Providers is a good next step. Conversations is likely too custom (conditional columns, dynamic headers) to benefit.
