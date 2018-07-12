class Mirror implements Renderable, Touchable {
  PVector position;
  float rotation;
  PVector mirrorStart;
  PVector mirrorEnd;
  PVector normal;
  PVector normalEnd;
  boolean touched;
  boolean active;
  boolean hovered = false;
  boolean selected = false;
  int index;
  int vel;
  int mirrorWidth;

  public static final int ANGLE_LOOPUP_DIVISIONS = 16;
  public static final int DEFAULT_MIRROR_WIDTH = 100;
  ArrayList<Mirror>[] angleLookUp;

  public Mirror(PVector _position, float _rotation, int _index) {
    position = _position;
    rotation = _rotation;
    mirrorWidth = DEFAULT_MIRROR_WIDTH;
    calculateLinePoints();
    index = _index;
    active = false;
    angleLookUp = new ArrayList[ANGLE_LOOPUP_DIVISIONS];

    //init empty
    for (int i = 0; i < angleLookUp.length; i++) {
      angleLookUp[i] = new ArrayList<Mirror>();
    }
  }

  public int getIndex() {
    return this.index;
  }

  public void touch() {
    touched = true;
  }

  public void activate() {
    active = true;

    // int pitch = 64;

    midi.sendNoteOn(1, pitch(), velocity());
    //System.out.println(velocity());
  }

  public int pitch() {
    // return 40;
    return getOctave() * 12 + scale[index % scale.length];
  }

  public int getOctave() {
    //return 5;
    return (int) 3 + (index / scale.length) % 4;
  }

  public int velocity() {
    return (int) map(position.mag(), 0, 350, 10, 127);
  }

  public void deactivate() {
    active = false;
    //int pitch = 64;

    midi.sendNoteOff(1, pitch(), velocity());
  }

  public void untouch() {
    if (touched) {
      if (!active) activate();
    } else {
      if (active) deactivate();
    }
    touched = false;
  }

  public void move(int x, int y) {
    this.position.x += x;
    this.position.y += y;
  }

  public void changeWidth(int w) {
    this.mirrorWidth = max(this.mirrorWidth + w, 10);
    calculateLinePoints();
  }

  public void rotate(int a) {
    this.rotation += a;
    this.calculateLinePoints();
  }

  private void calculateLinePoints() {
    PVector line = new PVector(this.mirrorWidth / 2., 0).rotate(radians(rotation));
    mirrorStart = PVector.add(position, line);
    mirrorEnd = PVector.sub(position, line); 


    normal = PVector.fromAngle(radians(rotation + 90));

    if (normal.x < 0) {
      normal.mult(-1);
    } else 
    if (normal.y > 0) {
      normal.mult(-1);
    }



    normalEnd = PVector.add(position, PVector.mult(normal, 15));
  }


  public int indexFromAngle(final float _a) {
    return (int)map(_a, 0, 2 * PI, 0, Mirror.ANGLE_LOOPUP_DIVISIONS);
  }

  public void patchAngleLookUp(Mirror _mirror) {
  }

  public void calculateAngleLookUp(ArrayList<Mirror> _mirrorList) {
    for (Mirror m : _mirrorList) {

      if (this.equals(m)) continue;

      //calc max and min angles 
      float[] angleList = new float[4];
      int[] indexList = new int[4];
      angleList[0] = PVector.sub(m.mirrorStart, this.mirrorStart).heading();
      angleList[1] = PVector.sub(m.mirrorEnd, this.mirrorStart).heading();
      angleList[2] = PVector.sub(m.mirrorStart, this.mirrorEnd).heading();
      angleList[3] = PVector.sub(m.mirrorEnd, this.mirrorEnd).heading();


      for (int i = 0; i < angleList.length; i++) {
        float a = angleList[i]; 
        //clip angles
        angleList[i] = a < 0 ? 2 * PI + a : a;
        indexList[i] = indexFromAngle(angleList[i]);
      }

      //define array for counting indices
      int indexCounter[] = new int[ANGLE_LOOPUP_DIVISIONS];

      //avoid gaps in indices: if 2 and 4 are touching, 3 must be aswell.


      int minI = min(indexList);
      int maxI = max(indexList);

      int diffI = maxI - minI;

      int start = diffI > ANGLE_LOOPUP_DIVISIONS / 2 ? maxI : minI;

      for (int i = 0; i < diffI + 1; i++) {
        indexCounter[(i + start) % ANGLE_LOOPUP_DIVISIONS] ++;
      }


      //iCounter[i0] ++;
      //iCounter[i1] ++;
      //iCounter[i2] ++;
      //iCounter[i3] ++;
      //only add mirrors once, for that we use the counter array.
      for (int d = 0; d < ANGLE_LOOPUP_DIVISIONS; d++) {
        if (indexCounter[d] >= 1) angleLookUp[d].add(m);
      }
    }
  }
  
  public void applyTransformation(PGraphics _c) {
    _c.translate(width /2, height / 2);
  }

  public void render(PGraphics context) {

    float mx = mouseX - width / 2.; 
    float my = mouseY - height / 2.; 
    int padding = 5;
    int weight = hovered ? 5 : 1;

    calculateLinePoints();



    stroke(0);
    noFill();

    if (touched) {
      stroke(255, 0, 0);
    }
    if (hovered) {
      stroke(0, 0, 255);
      ellipse(mirrorStart.x, mirrorStart.y, 20, 20);
      ellipse(mirrorEnd.x, mirrorEnd.y, 15, 15);

      fill(0);

      text(velocity(), -width / 2 + mouseX + normalEnd.x - position.x, -height / 2 + mouseY + normalEnd.y - position.y);
    }

    strokeWeight(weight);
    strokeCap(ROUND);


    line(mirrorStart.x, mirrorStart.y, mirrorEnd.x, mirrorEnd.y);

  }

  public void onHover(int actionIndex, boolean in) {
    hovered = in;
  }


  public void onClick(int actionIndex, boolean in) {
  }

  public void onDrag(int actionIndex, boolean in) {
    if (actionIndex == Window.DRAG_INDEX && in) {
      this.move(mouseX - pmouseX, mouseY - pmouseY);
    }

    if (actionIndex == Window.ROTATE_INDEX && in) {
      this.rotate(mouseX - pmouseX);
    }

    if (actionIndex == Window.ENLARGE_INDEX && in) {
      this.changeWidth(mouseX - pmouseX);
    }
  }


  public void renderToTouchSurface(PGraphics _c, int _actionIndex, color _color) {

    if (_actionIndex == Window.DRAG_INDEX) {
      _c.strokeWeight(10);
      _c.stroke(_color);
      _c.noFill();
      _c.line(mirrorStart.x, mirrorStart.y, mirrorEnd.x, mirrorEnd.y);
    } else if (_actionIndex == Window.ROTATE_INDEX) {
      _c.fill(_color);
      _c.noStroke();
      _c.ellipse(mirrorStart.x, mirrorStart.y, 20, 20);
    } else if (_actionIndex == Window.ENLARGE_INDEX) {
      _c.fill(_color);
      _c.noStroke();
      _c.ellipse(mirrorEnd.x, mirrorEnd.y, 20, 20);
    }

  }

  public boolean isSelected() {
    return this.selected;
  }
}