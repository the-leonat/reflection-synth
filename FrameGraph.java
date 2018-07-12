import processing.core.*;

class FrameGraph implements Renderable {
  public int[] buffer = new int[256];
  public int h = 100;
  public int w = 256;
  public int currentIndex = 0;
  public final int FRAME_RATE_CAP = 70;
  public PApplet p;

  public FrameGraph(PApplet _parent) {
    this.p = _parent;
    //p.registerMethod("draw", this);
  }

  public void applyTransformation(PGraphics _context) {
    _context.translate(10, 10);
  }


  public void render(PGraphics _context) {
    buffer[this.currentIndex] = (int)p.round(p.frameRate);

    _context.fill(0);  
    _context.text(buffer[this.currentIndex], 0, 0);



    for (int i = 0; i < this.buffer.length; i++) {
      //ring map
      final int bufferIndex = (i + this.currentIndex) % this.buffer.length;

      final int fps = this.buffer[bufferIndex];

      //map to axis
      final int y = h - (int)this.p.constrain(this.p.map(fps, 0, this.FRAME_RATE_CAP, 0, h), 0, h);
      _context.strokeWeight(1);
      _context.point(i, y);
    }


    this.currentIndex++;
    this.currentIndex %= this.buffer.length;
  }
}