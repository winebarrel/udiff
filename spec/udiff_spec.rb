# frozen_string_literal: true

RSpec.describe Udiff::Diff do
  it "returns empty string for identical strings" do
    diff = Udiff::Diff.new("foo\nbar\n", "foo\nbar\n")
    expect(diff.to_s).to eq("")
  end

  it "shows a simple one-line change" do
    diff = Udiff::Diff.new("foo\n", "bar\n")
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
    diff = Udiff::Diff.new("foo\n", "foo\nbar\n")
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
    diff = Udiff::Diff.new("foo\nbar\n", "foo\n")
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
    diff = Udiff::Diff.new(a, b)
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
    diff = Udiff::Diff.new("", "foo\n")
    expected = <<~DIFF
      --- a
      +++ b
      @@ -1,0 +1,1 @@
      +foo
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  it "handles empty second string" do
    diff = Udiff::Diff.new("foo\n", "")
    expected = <<~DIFF
      --- a
      +++ b
      @@ -1,1 +1,0 @@
      -foo
    DIFF
    expect(diff.to_s).to eq(expected)
  end

  it "handles no newline at end of file" do
    diff = Udiff::Diff.new("foo", "bar")
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
    diff = Udiff::Diff.new(a, b)
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
    diff = Udiff::Diff.new(a, b, context: 1)
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
    diff = Udiff::Diff.new("a\nb\nc\n", "x\ny\nz\n")
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
end
