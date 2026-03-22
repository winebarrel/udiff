# frozen_string_literal: true

module Udiff
  class Diff
    DEFAULT_CONTEXT = 3

    def initialize(string1, string2, context: DEFAULT_CONTEXT)
      @lines1 = split_lines(string1)
      @lines2 = split_lines(string2)
      @context = context
    end

    def to_s
      changes = compute_diff(@lines1, @lines2)
      hunks = build_hunks(changes, @context)
      return "" if hunks.empty?

      out = +""
      out << "--- a\n"
      out << "+++ b\n"
      hunks.each do |hunk|
        out << format_hunk(hunk)
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
      return b.map { |line| [:insert, line] } if n == 0
      return a.map { |line| [:delete, line] } if m == 0

      # v[k] = x value of the endpoint of the furthest reaching path in diagonal k
      v = Array.new(2 * max + 1)
      v[max + 1] = 0 # v[1] = 0, offset by max

      trace = []

      catch(:done) do
        (0..max).each do |d|
          trace << v.dup

          (-d..d).step(2) do |k|
            idx = k + max
            if k == -d || (k != d && v[idx - 1] < v[idx + 1])
              x = v[idx + 1]
            else
              x = v[idx - 1] + 1
            end

            y = x - k
            while x < n && y < m && a[x] == b[y]
              x += 1
              y += 1
            end

            v[idx] = x

            if x >= n && y >= m
              throw :done
            end
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

        if k == -d || (k != d && v[k - 1 + offset] < v[k + 1 + offset])
          prev_k = k + 1
        else
          prev_k = k - 1
        end

        prev_x = v[prev_k + offset]
        prev_y = prev_x - prev_k

        # Diagonal moves (equal lines)
        while x > prev_x && y > prev_y
          x -= 1
          y -= 1
          result.unshift([:equal, a[x]])
        end

        if d > 0
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
          else
            if current_hunk
              hunks << current_hunk
              current_hunk = nil
            end
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

    def format_hunk(hunk)
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
          lines << "-#{normalized}"
          old_count += 1
        when :insert
          lines << "+#{normalized}"
          new_count += 1
        end
      end

      header = "@@ -#{old_start},#{old_count} +#{new_start},#{new_count} @@\n"
      header + lines.join
    end

    def ensure_newline(line)
      line.end_with?("\n") ? line : "#{line}\n\\ No newline at end of file\n"
    end
  end
end
