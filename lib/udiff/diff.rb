# frozen_string_literal: true

module Udiff
  class Diff
    DEFAULT_CONTEXT = 3

    ANSI_COLORS = {
      header: "\033[90m",
      insert: "\033[32m",
      delete: "\033[31m",
      hunk_header: "\033[36m",
      reset: "\033[0m"
    }.freeze

    def initialize(string1, string2, context: DEFAULT_CONTEXT, include_diff_info: false)
      @lines1 = split_lines(string1)
      @lines2 = split_lines(string2)
      @context = context
      @include_diff_info = include_diff_info
    end

    def to_s(format = :text)
      changes = compute_diff(@lines1, @lines2)
      hunks = build_hunks(changes, @context)
      return "" if hunks.empty?

      out = +""
      if @include_diff_info
        out << colorize("--- a", :header, format) << "\n"
        out << colorize("+++ b", :header, format) << "\n"
      end
      hunks.each do |hunk|
        out << format_hunk(hunk, format, @include_diff_info)
      end
      out
    end

    private

    def split_lines(str)
      return [] if str.nil? || str.empty?

      lines = []
      str.each_line do |line|
        lines << line
      end
      lines
    end

    # Myers diff algorithm
    # Returns an array of [:equal, :delete, :insert] tagged pairs
    def compute_diff(a, b)
      n = a.size
      m = b.size
      max = n + m
      return b.map { |line| [:insert, line] } if n.zero?
      return a.map { |line| [:delete, line] } if m.zero?

      # v[k] = x value of the endpoint of the furthest reaching path in diagonal k
      v = Array.new((2 * max) + 1)
      v[max + 1] = 0 # v[1] = 0, offset by max

      trace = []

      catch(:done) do
        (0..max).each do |d|
          trace << v.dup

          (-d..d).step(2) do |k|
            idx = k + max
            x = if k == -d || (k != d && v[idx - 1] < v[idx + 1])
                  v[idx + 1]
                else
                  v[idx - 1] + 1
                end

            y = x - k
            while x < n && y < m && a[x] == b[y]
              x += 1
              y += 1
            end

            v[idx] = x

            throw :done if x >= n && y >= m
          end
        end
      end

      backtrack(trace, a, b, max)
    end

    def backtrack(trace, a, b, offset)
      x = a.size
      y = b.size
      result = []

      (trace.size - 1).downto(0) do |d|
        v = trace[d]
        k = x - y

        prev_k = if k == -d || (k != d && v[k - 1 + offset] < v[k + 1 + offset])
                   k + 1
                 else
                   k - 1
                 end

        prev_x = v[prev_k + offset]
        prev_y = prev_x - prev_k

        # Diagonal moves (equal lines)
        while x > prev_x && y > prev_y
          x -= 1
          y -= 1
          result.unshift([:equal, a[x]])
        end

        if d.positive?
          if x == prev_x
            # Insert
            y -= 1
            result.unshift([:insert, b[y]])
          else
            # Delete
            x -= 1
            result.unshift([:delete, a[x]])
          end
        end
      end

      result
    end

    def build_hunks(changes, context)
      hunks = []
      current_hunk = nil

      old_pos = 0
      new_pos = 0

      changes.each_with_index do |change, i|
        type, _line = change

        case type
        when :equal
          # Check if this equal line is within context of a change
          near_change = false

          # Look backward: are we within context lines after a change?
          if current_hunk
            last_change_idx = current_hunk[:last_change_idx]
            near_change = true if last_change_idx && (i - last_change_idx) <= context
          end

          # Look forward: are we within context lines before a change?
          unless near_change
            ((i + 1)..[i + context, changes.size - 1].min).each do |j|
              if changes[j][0] != :equal
                near_change = true
                break
              end
            end
          end

          if near_change
            current_hunk ||= new_hunk(old_pos, new_pos)
            current_hunk[:changes] << change
          elsif current_hunk
            hunks << current_hunk
            current_hunk = nil
          end

          old_pos += 1
          new_pos += 1
        when :delete
          current_hunk ||= new_hunk(old_pos, new_pos)
          current_hunk[:changes] << change
          current_hunk[:last_change_idx] = i
          old_pos += 1
        when :insert
          current_hunk ||= new_hunk(old_pos, new_pos)
          current_hunk[:changes] << change
          current_hunk[:last_change_idx] = i
          new_pos += 1
        end
      end

      hunks << current_hunk if current_hunk
      hunks
    end

    def new_hunk(old_start, new_start)
      { old_start: old_start, new_start: new_start, changes: [], last_change_idx: nil }
    end

    def colorize(text, type, format)
      return text unless format == :color

      code = ANSI_COLORS[type]
      return text unless code

      "#{code}#{text}#{ANSI_COLORS[:reset]}"
    end

    def format_hunk(hunk, format, include_diff_info)
      old_start = hunk[:old_start] + 1
      new_start = hunk[:new_start] + 1
      old_count = 0
      new_count = 0

      lines = []
      hunk[:changes].each do |type, line|
        normalized = ensure_newline(line)
        case type
        when :equal
          lines << " #{normalized}"
          old_count += 1
          new_count += 1
        when :delete
          lines << colorize("-#{normalized.chomp}", :delete, format) << "\n"
          old_count += 1
        when :insert
          lines << colorize("+#{normalized.chomp}", :insert, format) << "\n"
          new_count += 1
        end
      end

      if include_diff_info
        header = colorize("@@ -#{old_start},#{old_count} +#{new_start},#{new_count} @@", :hunk_header, format)
        "#{header}\n#{lines.join}"
      else
        lines.join
      end
    end

    def ensure_newline(line)
      line.end_with?("\n") ? line : "#{line}\n\\ No newline at end of file\n"
    end
  end
end
