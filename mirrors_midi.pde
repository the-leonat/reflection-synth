// code by leonard puhl, leonat.de

import themidibus.*;
import java.util.Collection;
import javax.sound.midi.MidiMessage;

ArrayList<Mirror> mirrorList = new ArrayList();
Ray ray = new Ray();
FrameGraph fpsGraph;
MidiBus midi;


int[] scale = {0, 3, 5, 7, 10};
//int[] scale = {0,1,2,3,4,5,6,7,8,9,10,11};

int clockCount = 0;
long starttimens = System.nanoTime();
boolean clockRunning = false;

float angle = 0;
Window window;


void setup() {
  size(1200, 800, FX2D);
  //noLoop();

  window = new Window(this);
  fpsGraph = new FrameGraph(this);
  randomSeed(0);

  for (int i = 0; i < 100; i++) {
    mirrorList.add(new Mirror(new PVector(random(-1.5, 1.5), random(-1., 1)).mult(350), random(360), i));
  }
  for (Mirror m : mirrorList) {
    m.calculateAngleLookUp(mirrorList);
  }
  

  window.setRenderables(mirrorList);
  window.setTouchables(mirrorList);
  window.addRenderable(ray);
  window.addRenderable(fpsGraph);

  window.renderTouchSurface();

  ray.setPosition(new PVector(0, 0));

  midi = new MidiBus(this, "midi_device", "midi_device");
  midi.sendTimestamps(false);

  MidiBus.list(); 
  //frameRate(100000);
  frameRate(60);
  //exit();
}

void midiMessage(MidiMessage message) {
  if (message.getStatus() == 0xFA) {
    System.out.println("start");
    clockRunning = true;
    clockCount = 0;
    this.sync();
    ///updateClock();
  }

  if (message.getStatus() == 0xFC) {
    System.out.println("end");
    clockRunning = false;
    sync();
  }

  if (message.getStatus() == 0xF8) {
    sync();
  }

  if (message.getStatus() == 0xF2) {
    clockCount = 0;
    sync();
  }
  //System.out.println(message.getStatus());
}

void sync() {
  clockCount++;
}

void updateClock() {
  long aminute = 60000000000L;
  long bpmns = aminute / (120 * 24); // multiply by 96 to get 24ppqn

  if (((System.nanoTime() - starttimens) >= bpmns)) {
    //bSystem.out.println("Currentelapsed: " + (System.nanoTime() - starttimens) + "bpmns: " + bpmns);
    starttimens = System.nanoTime();
    this.sync();
  }
}


void draw() {


  //angle += 60 / frameRate * 0.01;
  //if(!keyPressed) ray.setDirection(PVector.fromAngle(frameCount * 0.001));

  if (clockRunning) {
    text(clockCount / 24 % 16 % 2 == 0 ? "/" : "\\", -width / 2 + 10, 0);
    //ray.setDirection(PVector.fromAngle(map((int)clockCount / (24 / 4), 0, 16 * 4, 0, 2 * PI)));
    ray.setDirection(PVector.fromAngle(map((int)clockCount / (24 / 4), 0, 16 * 4, 0, 2 * PI)));

    ray.castRay(mirrorList);
  } else {
    if (!mousePressed) ray.setDirection(new PVector(mouseX - width / 2, mouseY - height / 2));
    ray.castRay(mirrorList);
  }


  background(255);
  

  window.render();  

  for (Mirror m : mirrorList) {
    m.untouch();
  }

  //image(window.ts, 0, 0, width, height);
}