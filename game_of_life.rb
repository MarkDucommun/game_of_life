require 'spec_helper'

class World
  attr_reader :cells

  def initialize(cells = {})
    @cells = cells
  end

  def get(location)
    return cells[location] if cells[location] 
    cell = Cell.new(location)
    cells[location] = cell
    cell
  end

  def get_neighbors(location)
    neighbors = {}

    { left: {x: -1, y: 0},
      upleft: {x: -1, y: 1},
      up: {x: 0, y: 1},
      upright: {x: 1, y: 1},
      right: {x: 1, y: 0},
      downright: {x: 1, y: -1},
      down: {x: 0, y: -1},
      downleft: {x: -1, y: -1}
    }.each do |key, modify_by|
      x = location[:x] + modify_by[:x]
      y = location[:y] + modify_by[:y]
      neighbors[key] = get(x: x, y: y)
    end
    neighbors
  end

  def update_cell_status
    cells.each_value { |cell| cell.update_alive_last_turn }
  end

  def update_alive(cell)
    living_neighbors = get_neighbors(cell.location).select do |location, cell|
      cell.alive?
    end.length
    if cell.alive? && living_neighbors < 2
      cell.kill
    end
  end
end

describe World do
  let(:dead_cell) { Cell.new }
  let(:live_cell) { Cell.new({x: 0, y: 0}, true) }
  let(:world){ World.new({live_cell.location => live_cell}) }

  it "can be created with cells" do
    cell = Cell.new
    cells = {}
    cells[cell.location] = cell
    expect( World.new(cells).cells ).to eq cells
  end

  context "returns the cell at a particular location by" do
    it "finding an existing cell" do
      cell = Cell.new
      world = World.new({cell.location => cell})
      expect( world.get(x: 0, y: 0) ).to be cell
    end

    it "creating a dead cell if a cell does not yet exist" do
      cell = world.get(x: 1, y: 1)
      expect( cell.alive? ).to be_false
      location = {x: 1, y: 1}
      expect( cell.location ).to eq location
    end
  end

  it "can find the neighbors of each cell" do
    neighbors = world.get_neighbors(live_cell.location)

    expected = {
      left: {x: -1, y: 0},
      upleft: {x: -1, y: 1},
      up: {x: 0, y: 1},
      upright: {x: 1, y: 1},
      right: {x: 1, y: 0},
      downright: {x: 1, y: -1},
      down: {x: 0, y: -1},
      downleft: {x: -1, y: -1},
    }

    expected.each { |key, location| expect( neighbors[key].location ).to eq location }
  end

  it "can update the status of alive last turn for each cell" do
    world.get_neighbors(live_cell.location)
    world.update_cell_status
    expect( world.get(x: 1, y: 1).alive_last_turn? ).to be_false
    expect( world.get(x: 0, y: 0).alive_last_turn? ).to be_true
  end

  context "can determine whether a cell should be alive or dead" do
    it "kills a living cell if it has fewer than two living neighbors" do
      world.update_alive(world.cells[{x: 0, y: 0}])
      expect( world.cells[{x: 0, y: 0}].alive? ).to be_false
    end

    it "kills a living cell if it has more than three living neighbors" do
      world = World.new([Cell.new({x: 0, y: 0}, true),
                         Cell.new({x: 1, y: 0}, true),
                         Cell.new({x: -1, y: 0}, true),
                         Cell.new({x: 0, y: 1}, true),
                         Cell.new({x: 0, y: -1}, true),
                        ])
      world.update_alive(world.cells[{x: 0, y: 0}])
      expect( world.cells[{x: 0, y: 0}].alive? ).to be_false
    end

    it "revives a dead cell if it has exactly three living neighbors" do
      
    end
  end
end

class Cell
  attr_reader :location

  def initialize(location = {x: 0, y: 0}, alive = false)
    @alive = alive
    @alive_last_turn = false
    @location = location
  end

  def alive?
    @alive
  end

  def alive_last_turn?
    @alive_last_turn
  end

  def kill
    @alive = false
  end

  def revive
    @alive = true
  end

  def update_alive_last_turn
    @alive_last_turn = alive?
  end
end

describe Cell do
  let(:dead_cell) { Cell.new }
  let(:living_cell) { Cell.new({x: 0, y: 0}, true) }

  it "is dead upon creation" do
    expect( dead_cell.alive? ).to be_false
  end

  it "can be created alive" do
    expect( living_cell.alive? ).to be_true 
  end

  it "if alive, can be killed" do
    living_cell.kill
    expect( living_cell.alive? ).to be_false
  end

  it "if dead, can be brought back to life" do
    dead_cell.revive
    expect( dead_cell.alive? ).to be_true
  end

  it "knows whether it was alive or dead last turn" do
    expect( living_cell.alive_last_turn? ).to be_false
  end

  it "updates whether it was alive or dead last turn" do
    living_cell.update_alive_last_turn
    expect( living_cell.alive_last_turn? ).to be_true
  end

  it "exists at a particular location" do
    location = {x: 0, y: 0}
    expect( living_cell.location ).to eq location
  end

  it "can be created at a particular location" do
    location = {x: 1, y: 1}
    expect( Cell.new({x: 1, y: 1}).location ).to eq location
  end
end