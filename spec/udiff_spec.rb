# frozen_string_literal: true

RSpec.describe Udiff::Diff do
  it "returns empty string for identical strings" do
    diff = Udiff::Diff.new("foo\nbar\n", "foo\nbar\n")
    expect(diff.to_s).to eq("")
  end

  it "shows a simple one-line change" do
    diff = Udiff::Diff.new("foo\n", "bar\n", include_diff_info: true)
    expected = <<~DIFF
      --- a
      +++ b
      @@ -1,1 +1,1 @@
      -foo
      +bar
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  it "shows added lines" do
    diff = Udiff::Diff.new("foo\n", "foo\nbar\n", include_diff_info: true)
    expected = <<~DIFF
      --- a
      +++ b
      @@ -1,1 +1,2 @@
       foo
      +bar
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  it "shows removed lines" do
    diff = Udiff::Diff.new("foo\nbar\n", "foo\n", include_diff_info: true)
    expected = <<~DIFF
      --- a
      +++ b
      @@ -1,2 +1,1 @@
       foo
      -bar
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  it "shows context lines around changes" do
    a = "1\n2\n3\n4\n5\n6\n7\n8\n9\n"
    b = "1\n2\n3\n4\nX\n6\n7\n8\n9\n"
    diff = Udiff::Diff.new(a, b, include_diff_info: true)
    expected = <<~DIFF
      --- a
      +++ b
      @@ -2,7 +2,7 @@
       2
       3
       4
      -5
      +X
       6
       7
       8
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  it "handles empty first string" do
    diff = Udiff::Diff.new("", "foo\n", include_diff_info: true)
    expected = <<~DIFF
      --- a
      +++ b
      @@ -1,0 +1,1 @@
      +foo
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  it "handles empty second string" do
    diff = Udiff::Diff.new("foo\n", "", include_diff_info: true)
    expected = <<~DIFF
      --- a
      +++ b
      @@ -1,1 +1,0 @@
      -foo
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  it "handles no newline at end of file" do
    diff = Udiff::Diff.new("foo", "bar", include_diff_info: true)
    expected = <<~'DIFF'
      --- a
      +++ b
      @@ -1,1 +1,1 @@
      -foo
      \ No newline at end of file
      +bar
      \ No newline at end of file
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  it "handles multiple hunks" do
    a = (1..20).map { |i| "line#{i}\n" }.join
    b_lines = (1..20).map { |i| "line#{i}\n" }
    b_lines[2] = "changed3\n"
    b_lines[17] = "changed18\n"
    b = b_lines.join
    diff = Udiff::Diff.new(a, b, include_diff_info: true)
    result = diff.to_s
    expect(result).to include("--- a")
    expect(result).to include("+++ b")
    expect(result.scan(/@@ /).size).to eq(2)
    expect(result).to include("-line3\n+changed3")
    expect(result).to include("-line18\n+changed18")
  end

  it "supports custom context size" do
    a = "1\n2\n3\n4\n5\n6\n7\n8\n9\n"
    b = "1\n2\n3\n4\nX\n6\n7\n8\n9\n"
    diff = Udiff::Diff.new(a, b, context: 1, include_diff_info: true)
    expected = <<~DIFF
      --- a
      +++ b
      @@ -4,3 +4,3 @@
       4
      -5
      +X
       6
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  it "handles completely different strings" do
    diff = Udiff::Diff.new("a\nb\nc\n", "x\ny\nz\n", include_diff_info: true)
    expected = <<~DIFF
      --- a
      +++ b
      @@ -1,3 +1,3 @@
      -a
      -b
      -c
      +x
      +y
      +z
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  describe "multiple changes" do
    it "produces two separate hunks for far apart changes" do
      a = (1..20).map { |i| "line#{i}\n" }.join
      b_lines = (1..20).map { |i| "line#{i}\n" }
      b_lines[2] = "changed3\n"
      b_lines[17] = "changed18\n"
      b = b_lines.join
      diff = Udiff::Diff.new(a, b, include_diff_info: true)
      result = diff.to_s
      expected = <<~DIFF
        --- a
        +++ b
        @@ -1,6 +1,6 @@
         line1
         line2
        -line3
        +changed3
         line4
         line5
         line6
        @@ -15,6 +15,6 @@
         line15
         line16
         line17
        -line18
        +changed18
         line19
         line20
      DIFF
      expect(result).to eq(expected)
    end

    it "merges adjacent changes into one hunk" do
      a = (1..20).map { |i| "line#{i}\n" }.join
      b_lines = (1..20).map { |i| "line#{i}\n" }
      b_lines[3] = "changed4\n"
      b_lines[9] = "changed10\n"
      b = b_lines.join
      diff = Udiff::Diff.new(a, b, include_diff_info: true)
      result = diff.to_s
      expected = <<~DIFF
        --- a
        +++ b
        @@ -1,13 +1,13 @@
         line1
         line2
         line3
        -line4
        +changed4
         line5
         line6
         line7
         line8
         line9
        -line10
        +changed10
         line11
         line12
         line13
      DIFF
      expect(result).to eq(expected)
    end

    it "produces three separate hunks" do
      a = (1..30).map { |i| "line#{i}\n" }.join
      b_lines = (1..30).map { |i| "line#{i}\n" }
      b_lines[1] = "changed2\n"
      b_lines[14] = "changed15\n"
      b_lines[27] = "changed28\n"
      b = b_lines.join
      diff = Udiff::Diff.new(a, b, include_diff_info: true)
      result = diff.to_s
      expect(result.scan(/@@ /).size).to eq(3)
      expect(result).to include("-line2\n+changed2")
      expect(result).to include("-line15\n+changed15")
      expect(result).to include("-line28\n+changed28")
    end

    it "handles consecutive changed lines" do
      a = (1..10).map { |i| "line#{i}\n" }.join
      b_lines = (1..10).map { |i| "line#{i}\n" }
      b_lines[4] = "new5\n"
      b_lines[5] = "new6\n"
      b_lines[6] = "new7\n"
      b = b_lines.join
      diff = Udiff::Diff.new(a, b, include_diff_info: true)
      result = diff.to_s
      expected = <<~DIFF
        --- a
        +++ b
        @@ -2,9 +2,9 @@
         line2
         line3
         line4
        -line5
        -line6
        -line7
        +new5
        +new6
        +new7
         line8
         line9
         line10
      DIFF
      expect(result).to eq(expected)
    end

    it "handles delete in one place and insert in another" do
      a = (1..15).map { |i| "line#{i}\n" }.join
      b_lines = (1..15).map { |i| "line#{i}\n" }
      b_lines.delete_at(2) # remove line3
      b_lines.insert(11, "inserted\n") # insert after line12
      b = b_lines.join
      diff = Udiff::Diff.new(a, b, include_diff_info: true)
      result = diff.to_s
      expect(result).to include("-line3\n")
      expect(result).to include("+inserted\n")
    end

    it "handles changes at the very beginning and end" do
      a = (1..15).map { |i| "line#{i}\n" }.join
      b_lines = (1..15).map { |i| "line#{i}\n" }
      b_lines[0] = "first\n"
      b_lines[14] = "last\n"
      b = b_lines.join
      diff = Udiff::Diff.new(a, b, include_diff_info: true)
      result = diff.to_s
      expect(result.scan(/@@ /).size).to eq(2)
      expected = <<~DIFF
        --- a
        +++ b
        @@ -1,4 +1,4 @@
        -line1
        +first
         line2
         line3
         line4
        @@ -12,4 +12,4 @@
         line12
         line13
         line14
        -line15
        +last
      DIFF
      expect(result).to eq(expected)
    end

    it "handles multiple inserts with no deletes" do
      a = (1..10).map { |i| "line#{i}\n" }.join
      b_lines = (1..10).map { |i| "line#{i}\n" }
      b_lines.insert(2, "new_after2\n")
      b_lines.insert(9, "new_after8\n")
      b = b_lines.join
      diff = Udiff::Diff.new(a, b)
      result = diff.to_s
      expect(result).to include("+new_after2\n")
      expect(result).to include("+new_after8\n")
      expect(result).not_to match(/^-/)
    end

    it "handles multiple deletes with no inserts" do
      a = (1..15).map { |i| "line#{i}\n" }.join
      b_lines = (1..15).map { |i| "line#{i}\n" }
      b_lines.delete_at(3)
      b_lines.delete_at(10) # originally line12
      b = b_lines.join
      diff = Udiff::Diff.new(a, b)
      result = diff.to_s
      expect(result).to include("-line4\n")
      expect(result).to include("-line12\n")
      expect(result).not_to match(/^\+/)
    end
  end

  describe "color format" do
    let(:reset) { "\033[0m" }
    let(:red) { "\033[31m" }
    let(:green) { "\033[32m" }
    let(:cyan) { "\033[36m" }
    let(:gray) { "\033[90m" }

    it "colorizes diff output" do
      diff = Udiff::Diff.new("foo\n", "bar\n", include_diff_info: true)
      result = diff.to_s(:color)

      expect(result).to include("#{gray}--- a#{reset}")
      expect(result).to include("#{gray}+++ b#{reset}")
      expect(result).to include("#{cyan}@@ -1,1 +1,1 @@#{reset}")
      expect(result).to include("#{red}-foo#{reset}")
      expect(result).to include("#{green}+bar#{reset}")
    end

    it "does not colorize context lines" do
      diff = Udiff::Diff.new("a\nb\nc\n", "a\nX\nc\n", include_diff_info: true)
      result = diff.to_s(:color)

      expect(result).to include(" a\n")
      expect(result).to include(" c\n")
      expect(result).not_to match(/\033\[\d+m a/)
    end

    it "returns plain text with default format" do
      diff = Udiff::Diff.new("foo\n", "bar\n")
      result = diff.to_s
      expect(result).not_to include("\033[")
    end
  end

  describe "include_diff_info: false (default)" do
    it "excludes file headers and hunk headers" do
      diff = Udiff::Diff.new("foo\n", "bar\n")
      result = diff.to_s
      expect(result).not_to include("--- a")
      expect(result).not_to include("+++ b")
      expect(result).not_to include("@@")
      expect(result).to eq("-foo\n+bar\n")
    end

    it "works with color format" do
      diff = Udiff::Diff.new("foo\n", "bar\n")
      result = diff.to_s(:color)
      expect(result).not_to include("--- a")
      expect(result).not_to include("+++ b")
      expect(result).not_to include("@@")
      expect(result).to include("\033[31m-foo\033[0m")
      expect(result).to include("\033[32m+bar\033[0m")
    end

    it "includes context lines" do
      diff = Udiff::Diff.new("a\nb\nc\n", "a\nX\nc\n")
      result = diff.to_s
      expect(result).to eq(" a\n-b\n+X\n c\n")
    end
  end
end
