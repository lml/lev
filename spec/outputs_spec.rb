require 'spec_helper'

RSpec.describe Lev::Outputs do

  let(:outputs) { Lev::Outputs.new }

  it "should return a non-array when given just one non-array" do
    outputs.add(:x, 4)
    expect(outputs[:x]).to eq 4
  end

  it "should return an array when given just one array" do
    outputs.add(:x, [1,2])
    expect(outputs[:x]).to eq [1,2]
  end

  it "should work when given a non-array and an array" do
    outputs.add(:x, 4)
    outputs.add(:x, [1,2])
    expect(outputs[:x]).to eq [4, [1,2]]
  end

  it "should work when given two or three non-arrays" do
    outputs.add(:x, 1)
    outputs.add(:x, 2)
    expect(outputs.x).to eq [1,2]
    outputs.add(:x, 3)
    expect(outputs.x).to eq [1,2,3]
  end

  it "should work when given a mix" do
    outputs.add(:x, [3,4])
    outputs.add(:x, "hi")
    outputs.add(:x, {a: 2})
    expect(outputs.x).to eq [[3,4], "hi", {a: 2}]
  end

  it "should transfer well" do
    outputs.add(:x, 4)
    outputs.add(:x, 5)

    other_outputs = Lev::Outputs.new

    outputs.each do |name, value|
      other_outputs.add(name, value)
    end

    other_outputs.add(:x, 6)

    expect(other_outputs.x).to eq [4,5,6]
  end

  it "should work via transfer_to with name mapping" do
    outputs.add(:x, 4)
    outputs.add(:x, 5)

    other_outputs = Lev::Outputs.new

    outputs.transfer_to(other_outputs) do |name|
      :y
    end

    other_outputs.add(:y, 6)
    expect(other_outputs.y).to eq [4,5,6]
  end

  it "should work via transfer_to without name mapping" do
    outputs.add(:x, 4)
    outputs.add(:x, 5)

    other_outputs = Lev::Outputs.new

    outputs.transfer_to(other_outputs)

    other_outputs.add(:y, 6)
    expect(other_outputs.x).to eq [4,5]
    expect(other_outputs.y).to eq 6
  end

end
