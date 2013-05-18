module Ruby2600
  class Bus
    # FIXME make a better structure (classes?) for frame-to-whatever conversions
    attr_accessor :tia

    def initialize(cpu, tia, cart, riot)
      @cpu = cpu
      @tia  = tia
      @cart = cart
      @riot = riot

      @cpu.memory = self
      @tia.cpu = cpu
      cpu.reset
    end

    def [](address)
      case address
      when 0x0000..0x000D then @tia[address]
      when 0x0080..0x00FF then @riot[address]
      when 0xF000..0xFFFF then @cart[address - 0xF000]
      end
    end

    def []=(address, value)
      if address.between? 0x0000, 0x002C
        @tia[address] = value
      else
        @riot[address] = value
      end
    end
  end
end