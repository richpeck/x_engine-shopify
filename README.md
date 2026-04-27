# XEngine SMTP Extension

A standalone extension for **XEngine** that provides SMTP mail delivery, outbound logging, and workflow nodes.

## Features

- **Decoupled Architecture:** Plugs into XEngine without modifying core files.
- **Dynamic Migrations:** Internal migrations that register with the XEngine Database manager.
- **Workflow Integration:** Includes a `send_email` node for use in the XEngine Dispatcher.
- **Audit Trail:** Every email is logged to `x_engine_smtp_logs` with a status (`pending`, `delivered`, `failed`) and full error tracking.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'x_engine-smtp'
```

---

:copyright: 2026 <a href="http://www.fl.co.uk" align="absmiddle"><img src="https://avatars.githubusercontent.com/u/7031641?s=200&v=4" height="22" align="absmiddle" title="Frontline Utilities LTD"  /></a> <a href="http://github.com/richpeck" align="absmiddle" ><img src="https://avatars0.githubusercontent.com/u/1104431" height="22" align="absmiddle" title="Contributors - R Peck" /></a>