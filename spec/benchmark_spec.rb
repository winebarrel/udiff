# frozen_string_literal: true

require "benchmark/ips"
require "diffy"

RSpec.describe "Benchmark: Udiff vs Diffy" do
  def generate_text(lines, seed: 0)
    rng = Random.new(seed)
    lines.times.map { |i| "line #{i}: #{rng.rand(10_000)}\n" }.join
  end

  def mutate_text(text, change_ratio: 0.1, seed: 1)
    rng = Random.new(seed)
    lines = text.lines
    lines.map { |line| rng.rand < change_ratio ? "modified: #{line}" : line }.join
  end

  def run_benchmark(label, str1, str2)
    udiff_result = Udiff::Diff.new(str1, str2).to_s
    diffy_result = Diffy::Diff.new(str1, str2, diff: "-u").to_s

    expect(udiff_result).not_to be_nil
    expect(diffy_result).not_to be_nil

    report = Benchmark.ips do |x|
      x.config(warmup: 1, time: 3)

      x.report("Udiff") do
        Udiff::Diff.new(str1, str2).to_s
      end

      x.report("Diffy") do
        Diffy::Diff.new(str1, str2, diff: "-u").to_s
      end

      x.compare!
    end

    udiff_entry = report.entries.find { |e| e.label == "Udiff" }
    diffy_entry = report.entries.find { |e| e.label == "Diffy" }

    puts "  #{label}: Udiff #{format('%.1f', udiff_entry.ips)} ips vs Diffy #{format('%.1f', diffy_entry.ips)} ips " \
         "(#{format('%.2fx', udiff_entry.ips / diffy_entry.ips)})"
  end

  it "small input (10 lines, 10% changed)" do
    text = generate_text(10)
    modified = mutate_text(text)
    run_benchmark("small (10 lines)", text, modified)
  end

  it "medium input (100 lines, 10% changed)" do
    text = generate_text(100)
    modified = mutate_text(text)
    run_benchmark("medium (100 lines)", text, modified)
  end

  it "large input (1000 lines, 10% changed)" do
    text = generate_text(1000)
    modified = mutate_text(text)
    run_benchmark("large (1000 lines)", text, modified)
  end

  it "large input with many changes (1000 lines, 30% changed)" do
    text = generate_text(1000)
    modified = mutate_text(text, change_ratio: 0.3)
    run_benchmark("large many changes (1000 lines, 30%)", text, modified)
  end

  it "identical strings (1000 lines)" do
    text = generate_text(1000)
    run_benchmark("identical (1000 lines)", text, text)
  end
end
