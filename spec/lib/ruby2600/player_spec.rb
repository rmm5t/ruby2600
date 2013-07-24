require 'spec_helper'

describe Ruby2600::Player do

  let(:tia) { Array.new(32, 0) }
  subject(:player) { Ruby2600::Player.new(tia, 0) }

  def pixels(player, first, last)
    (first-1).times { player.pixel }
    (0..(last - first)).map { player.pixel }
  end

  context 'player 1' do
    subject(:player1) { Ruby2600::Player.new(tia, 1) }

    before do 
      tia[GRP0] = 0x00
      tia[COLUP0] = 0x00
      tia[COLUP1] = 0xFF
      player1.strobe
      160.times { player1.pixel }
    end

    it 'should not draw anything without GRP1' do      
      pixels(player1, 1, 160).should_not include(0xFF)
    end

    it 'should draw if GRP1 is set' do
      tia[GRP1] = 0xFF
      pixels(player1, 1, 160).should include(0xFF)
    end
  end

  describe 'pixel' do
    it 'should never output if GRP0 is all zeros' do
      tia[GRP0] = 0
      300.times { player.pixel.should be_nil }
    end

    context 'drawing (strobe, NUSIZ0)' do
      COLOR = 2 * (rand(127) + 1)
      PIXELS = [COLOR, COLOR, nil, nil, COLOR, nil, COLOR, nil]
      PIXELS_2X = PIXELS.map    { |p| [p, p] }.flatten
      PIXELS_4X = PIXELS_2X.map { |p| [p, p] }.flatten

      before do
        # Cleanup and pick a random position
        tia[GRP0] = 0
        rand(160).times { player.pixel }

        # Preemptive strobe (to ensure we don't have retriggering leftovers)
        player.strobe
        80.times { player.pixel }

        # Setup
        tia[GRP0] = 0b11001010
        tia[COLUP0] = COLOR
      end

      context 'one copy' do
        before do
          tia[NUSIZ0] = 0
          player.strobe
        end

        it 'should not draw anything on current scanline' do
          5.times { player.pixel }
          pixels(player, 1, 160).should == Array.new(160)
        end

        it 'should draw after a full scanline (160pixels) + 5-bit delay' do
          165.times { player.pixel }
          pixels(player, 1, 8).should == PIXELS
        end

        it 'should draw again on subsequent scanlines' do
          325.times { player.pixel }
          5.times { pixels(player, 1, 160).should == PIXELS + Array.new(152) }
        end
      end

      context 'two copies, close' do
        before do
          tia[NUSIZ0] = 1
          player.strobe
        end

        it 'should only draw second copy on current scanline (after 5 bit delay)' do
          5.times { player.pixel }
          pixels(player, 1, 24).should == Array.new(16) + PIXELS
        end

        it 'should draw both copies on subsequent scanlines' do
          165.times { player.pixel }
          pixels(player, 1, 24).should == PIXELS + Array.new(8) + PIXELS
        end
      end

      context 'two copies, medium' do
        before do
          tia[NUSIZ0] = 2
          player.strobe
        end

        it 'should only draw second copy on current scanline (after 5 bit delay)' do
          5.times { player.pixel }
          pixels(player, 1, 40).should == Array.new(32) + PIXELS
        end

        it 'should draw both copies on subsequent scanlines' do
          165.times { player.pixel }
          pixels(player, 1, 40).should == PIXELS + Array.new(24) + PIXELS
        end
      end

      context 'three copies, close' do
        before do
          tia[NUSIZ0] = 3
          player.strobe
        end

        it 'should only draw second and third copy on current scanline (after 5 bit delay)' do
          5.times { player.pixel }
          pixels(player, 1, 40).should == Array.new(16) + PIXELS + Array.new(8) + PIXELS
        end

        it 'should draw three copies on subsequent scanlines' do
          165.times { player.pixel }
          pixels(player, 1, 40).should == PIXELS + Array.new(8) + PIXELS + Array.new(8) + PIXELS
        end
      end

      context 'two copies, wide' do
        before do
          tia[NUSIZ0] = 4
          player.strobe
        end

        it 'should only draw second copy on current scanline (after 5 bit delay)' do
          5.times { player.pixel }
          pixels(player, 1, 72).should == Array.new(64) + PIXELS
        end

        it 'should draw both copies on subsequent scanlines' do
          165.times { player.pixel }
          pixels(player, 1, 72).should == PIXELS + Array.new(56) + PIXELS
        end
      end

      context 'one copy, double size' do
        before do
          tia[NUSIZ0] = 5
          player.strobe
        end

        it 'should not draw anything on current scanline' do
          5.times { player.pixel }
          pixels(player, 1, 160).should == Array.new(160)
        end

        it 'should draw on subsequent scanlines' do
          165.times { player.pixel }
          5.times { pixels(player, 1, 160).should == PIXELS_2X + Array.new(144) }
        end
      end

      context 'three copies, medium' do
        before do
          tia[NUSIZ0] = 6
          player.strobe
        end

        it 'should only draw second and third copy on current scanline (after 5 bit delay)' do
          5.times { player.pixel }
          pixels(player, 1, 72).should == Array.new(32) + PIXELS + Array.new(24) + PIXELS
        end

        it 'should draw three copies on subsequent scanlines' do
          165.times { player.pixel }
          pixels(player, 1, 72).should == PIXELS + Array.new(24) + PIXELS + Array.new(24) + PIXELS
        end

        context 'with REFP0 set' do
          before { tia[REFP0] = rand(256) | 0b1000 }          

          it 'should reflect the drawing' do
            165.times { player.pixel }
            pixels(player, 1, 72).should == PIXELS.reverse + Array.new(24) + PIXELS.reverse + Array.new(24) + PIXELS.reverse
          end
        end
      end

      context 'one copy, quad size' do
        before do
          tia[NUSIZ0] = 7
          player.strobe
        end

        it 'should not draw anything on current scanline' do
          5.times { player.pixel }
          pixels(player, 1, 160).should == Array.new(160)
        end

        it 'should draw on subsequent scanlines' do
          165.times { player.pixel }
          5.times { pixels(player, 1, 160).should == PIXELS_4X + Array.new(128) }
        end

        context 'with REFP0 set' do
          before { tia[REFP0] = rand(256) | 0b1000 }          

          it 'should reflect the drawing' do
            165.times { player.pixel }
            5.times { pixels(player, 1, 160).should == PIXELS_4X.reverse + Array.new(128) }
          end
        end
      end
    end
  end
end
