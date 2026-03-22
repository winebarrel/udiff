# udiff

[![CI](https://github.com/winebarrel/udiff/actions/workflows/ci.yml/badge.svg)](https://github.com/winebarrel/udiff/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/udiff.svg)](https://badge.fury.io/rb/udiff)

Pure Ruby unified diff library. No external dependencies, no shelling out to `diff`.

Compatible with `Diffy::Diff.new(a, b, diff: '-u').to_s`.

Uses the [Myers diff algorithm](https://en.wikipedia.org/wiki/Diff#Myers's_algorithm).

## Installation

Add this line to your Gemfile:

```ruby
gem "udiff"
```

## Usage

### Basic (unified diff text)

```ruby
require "udiff"

a = "foo\nbar\nbaz\n"
b = "foo\nqux\nbaz\n"

puts Udiff::Diff.new(a, b).to_s
```

```diff
--- a
+++ b
@@ -1,3 +1,3 @@
 foo
-bar
+qux
 baz
```

### Color output

```ruby
puts Udiff::Diff.new(a, b).to_s(:color)
```

Produces ANSI-colored output:

- Red: removed lines
- Green: added lines
- Cyan: hunk headers (`@@...@@`)
- Gray: file headers (`---`/`+++`)

### Custom context lines

```ruby
# Show 1 line of context instead of the default 3
puts Udiff::Diff.new(a, b, context: 1).to_s
```
