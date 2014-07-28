require 'spec_helper'

describe Terminal::Renderer do
  let(:renderer) { Terminal::Renderer.new }

  describe "rendering of curl.sh" do
    it "returns the expected result" do
      fixture = Fixture.for("curl.sh")

      expect(renderer.render(fixture.raw)).to eql(fixture.rendered)
    end
  end

  describe "rendering of homer.sh" do
    it "returns the expected result" do
      fixture = Fixture.for("homer.sh")

      expect(renderer.render(fixture.raw)).to eql(fixture.rendered)
    end
  end

  describe "#render" do
    it "chops off logs longer than 4 megabytes" do
      long_string = "x" * 4.5 * 1024 * 1024

      expect(renderer.render(long_string)).to end_with("Warning: Terminal has chopped the rest of this line off as it&#39;s over the allowed 50000 characters per line limit.")
    end

    it "closes colors that get opened" do
      raw = "he\033[81mllo"

      expect(renderer.render(raw)).to eql("he<span class='c81'>llo</span>")
    end

    it "skips over colors when backspacing" do
      raw = "he\e[32m\e[33m\bllo"

      expect(renderer.render(raw)).to eql("h<span class='c32'><span class='c33'>llo</span></span>")
    end

    it "starts overwriting characters when you \\r midway through somehing" do
      raw = "hello\rb"

      expect(renderer.render(raw)).to eql("bello")
    end

    it "colors across multiple lines" do
      raw = "\e[81mhello\n\nfriend\e[0m"

      expect(renderer.render(raw)).to eql("<span class='c81'>hello\n&nbsp;\nfriend</span>")
    end

    it "allows you to control the cursor forwards" do
      raw = "this is \e[4Cpoop and stuff"

      expect(renderer.render(raw)).to eql("this is     poop and stuff")
    end

    it "adds empty space if you forward further than the string length" do
      raw = "this is great \e[4C"

      expect(renderer.render(raw)).to eql("this is great     ")
    end

    it "allows you to control the cursor backwards" do
      raw = "this is good\e[4Dpoop and stuff"

      expect(renderer.render(raw)).to eql("this is poop and stuff")
    end

    it "allows you to control the cursor upwards" do
      raw = "1234\n56\e[1A78\e[B"

      expect(renderer.render(raw)).to eql("1278\n56")
    end

    it "chops off anything past the cursor" do
      # writes a grid of:
      # 1234
      # 5678
      # then goes up a row (defaults to 1 when no number is used). when the
      # render finishes, everything after the cursor is dropped
      raw = "1234\n5678\e[A"

      expect(renderer.render(raw)).to eql("1234")
    end

    it "allows you to control the cursor downwards" do
      # creates a grid of:
      # aaaa
      # bbbb
      # cccc
      # Then goes up 2 rows, down 1 row, jumps to the begining
      # of the line, rewrites it to 1234, then jumps back down
      # to the end of the grid.
      raw = "aaaa\nbbbb\ncccc\e[2A\e[1B\r1234\e[1B"

      expect(renderer.render(raw)).to eql("aaaa\n1234\ncccc")
    end

    it "doesn't blow up if you go back too many characters" do
      raw = "this is good\e[100Dpoop and stuff"

      expect(renderer.render(raw)).to eql("poop and stuff")
    end

    it "ignores \\e1[K" do
      raw = "hello friend\e[K!"

      expect(renderer.render(raw)).to eql("hello friend!")
    end

    it "ignores \\e1[0K" do
      raw = "hello friend\e[0K!"

      expect(renderer.render(raw)).to eql("hello friend!")
    end

    it "handles \\e[0G ghetto style" do
      raw = "hello friend\e[Ggoodbye buddy!"

      expect(renderer.render(raw)).to eql("goodbye buddy!")
    end

    it "allows erasing the current line up to a point" do
      raw = "hello friend\e[1K!"

      expect(renderer.render(raw)).to eql("            !")
    end

    it "allows clearing of the current line" do
      raw = "hello friend\e[2K!"

      expect(renderer.render(raw)).to eql("            !")
    end
  end
end