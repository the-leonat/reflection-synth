

class Ray implements Renderable  {
  private PVector position;
  private PVector direction;
  public Ray next;
  public Mirror mirror;

  public Ray(PVector _position, PVector _direction) {
    this.position = _position;
    this.direction = _direction;

    this.direction.normalize();
    this.direction.mult(width * 1.6);
  }

  public Ray() {
    this.position = new PVector(0,0);
    this.direction = new PVector(1,0);
  }

  public void setDirection(PVector _direction) {
    this.direction = _direction;

    this.direction.normalize();
    this.direction.mult(width * 1.6);
  } 

  public void setPosition(PVector _position) {
    this.position = _position;
  }


  public void castRay(ArrayList<Mirror> _mirrorList) {
    if (this.direction == null || this.position == null) return;
    rcastRay(_mirrorList, this.position, this.direction, 0, null);
  }

  private void rcastRay(final ArrayList<Mirror> _mirrorList, final PVector _position, final PVector _direction, final int _depth, final Mirror lastMirror) {

    if (_depth > 100) { 
      System.out.println("depth reached");
      //_rayList.add(PVector.add(_position, _direction));
      next = null;
      return;
    };

    //ArrayList<Mirror> candidates = createCandidateList(_mirrorList, _position, _direction);

    float minDistance = width * 2;
    PVector minIntersectionPoint = null;
    Mirror intersectionMirror = null;

    for (Mirror m : _mirrorList) {
      if (lastMirror != null && m.equals(lastMirror)) continue;
      PVector iPoint = lineIntersection(m.mirrorStart, m.mirrorEnd, _position, PVector.add(_position, _direction));

      if (iPoint != null) {
        float d = PVector.sub(iPoint, _position).mag();
        if (d < minDistance) {     
          minDistance = d;
          minIntersectionPoint = iPoint;
          intersectionMirror = m;
        }
      }
    }

    if (intersectionMirror != null ) {
      // calc reflection
      PVector newDirection = reflection(_direction, intersectionMirror.normal);

      this.next = new Ray(minIntersectionPoint, newDirection);
      intersectionMirror.touch();

      //now use the lookup table to save some time
      float angle = newDirection.heading();
      angle = angle < 0 ? 2 * PI + angle : angle;

      ArrayList<Mirror> mirrors = intersectionMirror.angleLookUp[intersectionMirror.indexFromAngle(angle)];
      this.next.mirror = intersectionMirror;
      this.next.rcastRay(mirrors, minIntersectionPoint, newDirection, _depth + 1, intersectionMirror);
    } else {
      this.next = null;
      return;
    }
  }

  private ArrayList<Mirror> createCandidateList(ArrayList<Mirror> _mirrorList, PVector _position, PVector _direction) {
    //check behind.

    return _mirrorList;
  }

  private PVector reflection(PVector _direction, PVector _normal) {
    //Rr = Ri - 2 N (Ri . N)

    float dot = PVector.dot(_direction, _normal);
    PVector mult = PVector.mult(_normal, 2 * dot);

    return  PVector.sub(_direction, mult);
  }


  private PVector lineIntersection(PVector p1, PVector p2, PVector p3, PVector p4) {
    PVector b = PVector.sub(p2, p1);
    PVector d = PVector.sub(p4, p3);

    float b_dot_d_perp = b.x * d.y - b.y * d.x;
    if (b_dot_d_perp == 0) { 
      return null;
    }

    PVector c = PVector.sub(p3, p1);
    float t = (c.x * d.y - c.y * d.x) / b_dot_d_perp;
    if (t < 0 || t > 1) { 
      return null;
    }
    float u = (c.x * b.y - c.y * b.x) / b_dot_d_perp;
    if (u < 0 || u > 1) { 
      return null;
    }

    return new PVector(p1.x+t*b.x, p1.y+t*b.y);
  }
  
  public void applyTransformation(PGraphics _c) {
    _c.translate(width /2, height / 2);
  }

  public void render(PGraphics context) {

    stroke(0);
    strokeWeight(2);
    strokeJoin(BEVEL);
    strokeCap(PROJECT);

    rshow(0);
  }
 

  public void rshow(int d) {
    //vertex(this.position.x, this.position.y);
    //if (this.mirror != null && d == 1) {
    //  for (int i = 0; i < Mirror.ANGLE_LOOPUP_DIVISIONS; i++) {
    //    for (Mirror m : this.mirror.angleLookUp[i]) {
    //      strokeWeight(0.5);
    //      stroke(0, 0, 255);
    //      line(this.mirror.position.x, this.mirror.position.y, m.position.x, m.position.y);
    //    }
    //  }
    //}
    if (this.next != null) {
      stroke(0);
      strokeWeight(2);

      line(this.position.x, this.position.y, this.next.position.x, this.next.position.y );

      if (this.mirror != null) {
        float angle = this.direction.heading();
        angle = angle < 0 ? 2 * PI + angle : angle;
      }
      this.next.rshow(d + 1);
    } else {
      stroke(0);
      strokeWeight(2);

      line(this.position.x, this.position.y, this.position.x + this.direction.x, this.position.y + this.direction.y);
      //endShape();
    }
  }
}