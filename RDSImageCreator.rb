=begin
 * - RDSImageCreator -
 * ランダムドットステレオグラム生成ライブラリ
 *
 * グレースケール画像(深度マップ画像)からRDSイメージを生成
 *
 * @author		dsler
 * @version		1.0.0
 * @update    2016/11/24
 *
 * Licensed under The MIT License
 * Copyright (c) 2016 dsler
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
=end

require "rmagick"

class RDSImageCreator

  def initialize(canvasWidth, canvasHeight, rdsPatternWidth=100, depthRange=20, density=1)
    @canvasWidth          = canvasWidth
    @canvasHeight         = canvasHeight
    @originalPatternWidth = rdsPatternWidth
    @depthRange           = depthRange
    @density              = density;
  end

  def create(depthImagePath)
    depthMap    = Magick::ImageList.new(depthImagePath).resize(@canvasWidth, @canvasHeight)
    rdsSurface  = Magick::Image.new(@canvasWidth, @canvasHeight)

    @canvasHeight.times do |i|
      iterator  = 0
      oldDepth  = 0
      pattern   = createNewRandomPattern(@originalPatternWidth)
      @canvasWidth.times do |j|
        dMPixel     = depthMap.pixel_color(j, i)
        dMPixelR    = 255 * (dMPixel.red.to_f   / Magick::QuantumRange.to_f)
        newDepth    = ((dMPixelR / 255) * @depthRange).to_i
        depthSub    = newDepth - oldDepth

        if depthSub != 0
          if    depthSub > 0
            pattern = createDeletedPattern(pattern, iterator % pattern.columns, depthSub)
          elsif depthSub < 0
            pattern = createInsertedPattern(pattern, iterator % pattern.columns, -depthSub)
          end
          iterator = 0;
        end
        rdsSurface.pixel_color(j, i, pattern.pixel_color(iterator % pattern.columns,0))
        iterator += 1
        oldDepth = newDepth
      end
    end

    return rdsSurface
  end

  def createNewRandomPattern(width)
    randomPattern = Magick::Image.new(width, 1){self.background_color='white'}
    wid           = width.to_i
    wid.times do |xi|
      random  = Random.new().rand * Magick::QuantumRange
      pixel   = random.to_i
      if (random - pixel) < @density
        randomPattern.pixel_color(xi, 0, Magick::Pixel.new(pixel,pixel,pixel))
      end
    end

    return randomPattern
  end

  def createDeletedPattern(prevPattern, delPoint, delWidth)
    prevPatternWidth  = prevPattern.columns
    returnPattern     = Magick::Image.new(prevPatternWidth - delWidth, 1)
    bWidth            = 0

    if prevPatternWidth - delPoint - delWidth > 0
      leftImage     = prevPattern.crop(delPoint + delWidth, 0, prevPatternWidth - delPoint - delWidth, 1)
      rightImage    = prevPattern.crop(0, 0, delPoint, 1)
      returnPattern = returnPattern.composite(leftImage, 0, 0, Magick::OverCompositeOp)
      returnPattern = returnPattern.composite(rightImage, leftImage.columns, 0, Magick::OverCompositeOp)
    else
      totalImage    = prevPattern.crop(delPoint + delWidth - prevPatternWidth, 0, prevPatternWidth - delWidth, 1)
      returnPattern = returnPattern.composite(totalImage, 0, 0, Magick::OverCompositeOp)
    end
    return returnPattern
  end

  def createInsertedPattern(prevPattern, edgeAt, insertRandWidth)
    prevPatternWidth  = prevPattern.columns
    returnPattern     = Magick::Image.new(prevPatternWidth + insertRandWidth, 1)
    firstPixel        = prevPattern.crop(edgeAt, 0, 1, 1)
    newRandPattern    = createNewRandomPattern(insertRandWidth)
    returnPattern     = returnPattern.composite(firstPixel, 0, 0, Magick::OverCompositeOp)
    returnPattern     = returnPattern.composite(newRandPattern, firstPixel.columns, 0, Magick::OverCompositeOp)

    if prevPatternWidth - edgeAt - 1 > 0
      leftImage       = prevPattern.crop(edgeAt + 1, 0, prevPatternWidth - edgeAt - 1, 1)
      returnPattern   = returnPattern.composite(leftImage, insertRandWidth + firstPixel.columns, 0, Magick::OverCompositeOp)
    end
    if edgeAt > 0
      rightImage      = prevPattern.crop(0, 0, edgeAt, 1)
      returnPattern   = returnPattern.composite(rightImage, prevPatternWidth - edgeAt + insertRandWidth, 0, Magick::OverCompositeOp)
    end
    return returnPattern
  end

end
