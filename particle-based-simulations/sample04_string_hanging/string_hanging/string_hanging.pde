/*
  string_hanging.pde
  
 - Akira Kageyama (kage@port.kobe-u.ac.jp)
 
 - History
           2026.04.12: cp and revise string_catenary2.pde. 
                       This is string_tension_transverse_wave.           
           2026.04.23: Rename from sring_tension_transverse_wave.
                       This is string_tension_transverse_wave_resonance.
           2026.04.23: Rename string_catenary. This is string_catenary. 
           2026.04.25: cp from string_catenary. This is string_hanging.
  

 - Note
         - Release an end point from the ceiling.
 
 - Usage 
           Mouse click : 
               1st click --> Start calculation
               2nd click --> Release the end point
               3rd click --> Stop calculation
               4th and later --> Start/stop toggle
 
 */


// When NUM_OF_PARTICLES = 6
//
//   Before ReleaseEndPoint
//
//         ...............0.....................5.....
//                         .                   .
//                          1                 4           
//                            .             .
//                                2  .  3       
//     
//    
//     
//   After ReleaseEndPoint
//
//         ...............0............................
//                         .          
//                          1                  
//                            .               
//                              2              5
//                                 .          .
//                                    3  .  4
//                            
//         
//     


//--------------------<input parameters>--------------------
final int   NUM_OF_PARTICLES = 31;  // When odd --> triangle, even --> semi-circle.
final float STRING_LENGTH    = 2.0;    // (m)
final float STRING_MASS      = 0.005;  // (kg)
final float PARTICLE_MASS    = STRING_MASS / NUM_OF_PARTICLES;

final float SPRING_NATURAL_LENGTH = STRING_LENGTH / (NUM_OF_PARTICLES-1);
final float SPRING_CHAR_PERIOD = 0.004; // (sec)
final float SPRING_CHAR_OMEGA = TWO_PI / SPRING_CHAR_PERIOD;
final float SPRING_CHAR_OMEGA_SQ = SPRING_CHAR_OMEGA*SPRING_CHAR_OMEGA; // omega^2 = k/m
final float SPRING_CONST = PARTICLE_MASS * SPRING_CHAR_OMEGA_SQ;  // k = m*omega^2

final float GRAVITY_ACCELERATION = 9.8067;

final int DISPLAY_SPEED = 200;  // the larger, the quicker.

boolean RunningStateToggle = false;
boolean DrawSolutionCurvesToggle = true;
boolean ReleaseEndPoint = false;

//-------------------</input parameters>--------------------


float[] particlePosX = new float[NUM_OF_PARTICLES];
float[] particlePosY = new float[NUM_OF_PARTICLES];
float[] particleVelX = new float[NUM_OF_PARTICLES];
float[] particleVelY = new float[NUM_OF_PARTICLES];
float[] springK  = new float[NUM_OF_PARTICLES-1];


//                          footPointSeparation
//                         /
//                 LeftX  /     RightX
//                /      /     /
//               |<---------->|
//         ......o............o......... x
//                \          / 
//                 o        o
//                  \      / 
//                   o----o
//                         
float footPointSeparation = (STRING_LENGTH/PI) * 2;
float footPointRightX = footPointSeparation/2;
float footPointLeftX = -footPointRightX;

float xmin = -2.0;  // (m)
float xmax =  2.0;
float ymin = -2.5;
float ymax =  0.5;


float time = 0.0; // (sec)
int   step = 0;
float   dt = SPRING_CHAR_PERIOD*0.1;  // (sec)


void initialize() 
{  
  for (int i=0; i<NUM_OF_PARTICLES-1; i++) {
    springK[i] = SPRING_CONST;
  }

  particlePosX[0] = footPointLeftX; // x coord
  particlePosY[0] = 0.0; // y coord
  particleVelX[0] = 0.0; // vx
  particleVelY[0] = 0.0; // vy

  if ( NUM_OF_PARTICLES % 2 == 0 ) {
    initial_curve_single_semi_circle();
  } else {  
   initial_curve_triangle();
  }
}


void initial_curve_single_semi_circle()
{
  /*
         .       .
          .     .
            . .
  */
  
  for (int i=1; i<NUM_OF_PARTICLES; i++) {
    float angle = i*(PI/(NUM_OF_PARTICLES-1));
    float radius = footPointSeparation / 2;
    particlePosX[i] = -radius*cos(angle);  // x
    particlePosY[i] = -radius*sin(angle);  // y
    particleVelX[i] = 0.0; // vx
    particleVelY[i] = 0.0; // vy
  }
}

void initial_curve_triangle()
{
  /*
       When NUM_OF_PARTICLES = 7
         
                        _
         .           .   |
           .       .     |
             .   .       |  triangle height
               .        _|
               
         |           |
         |-----------|
               \
                \___ footPointSeparation
               
               
       We focus on the left-half.
       
                 ___  edge1 = (length=footPointSeparation/2)           
                /
            |-----|
            .......
           /  .   .
          /     . .
         e        .
           d     /
             g  /
               e
                 2
       */
       
  float l0 = SPRING_NATURAL_LENGTH;
  final int MID_PARTICLE = NUM_OF_PARTICLES / 2;  
         // Here we assume NUM_OF_PARTICLES is odd.
         // When NUM_OF_PARTICLES = 7, MID_PARTICLE = 3.
  float triangle_edge1_length = footPointSeparation / 2;
  float triangle_edge2_length = l0 * MID_PARTICLE;
  float cos_phi = triangle_edge1_length / triangle_edge2_length;
  float sin_phi = sqrt(1-pow(cos_phi,2));
  float delta_x = l0*cos_phi;
  float delta_y = l0*sin_phi;
  
  float x0 = footPointLeftX;
  float y0 = 0;
  
  for (int i=1; i<=MID_PARTICLE; i++) {
    x0 = particlePosX[i] = x0 + delta_x; 
    y0 = particlePosY[i] = y0 - delta_y;
    particleVelX[i] = 0.0; // vx
    particleVelY[i] = 0.0; // vy
  }
  
  for (int i=MID_PARTICLE+1; i<NUM_OF_PARTICLES; i++) {
    x0 = particlePosX[i] = x0 + delta_x; 
    y0 = particlePosY[i] = y0 + delta_y;
    particleVelX[i] = 0.0; // vx
    particleVelY[i] = 0.0; // vy
  }
}


void setup() {
  size(500, 500);
  background(255);
  initialize();
  frameRate(60);
}


float totalEnergy()
{
  float kineticEnergy = 0.0;
  float potentialEnergy = 0.0;
  
  for (int i=0; i<NUM_OF_PARTICLES; i++) {
    float velx = particleVelX[i];
    float vely = particleVelY[i];
    float posx = particlePosX[i];
    float posy = particlePosY[i];
  
    kineticEnergy += 0.5*PARTICLE_MASS*(velx*velx+vely*vely);

println("i, velx, vely", i, velx, vely);    
    
    if ( i>0 ) {
      float posx0 = particlePosX[i-1];
      float posy0 = particlePosY[i-1];      
      float l = dist(posx,posy,posx0,posy0) - SPRING_NATURAL_LENGTH;
      float lsq = l*l;
      potentialEnergy += 0.5*springK[i-1]*lsq; 
    }
    
    potentialEnergy += PARTICLE_MASS*GRAVITY_ACCELERATION*posy;
  }

  return(kineticEnergy + potentialEnergy);
}



void equationOfMotion(float  posx[],
                      float  posy[],
                      float  velx[],
                      float  vely[],                      
                      float dposx[],
                      float dposy[],
                      float dvelx[],
                      float dvely[],
                      float dt) 

{
  float l0 = SPRING_NATURAL_LENGTH;
  float dtm = dt / PARTICLE_MASS;
  
  
    
  for (int i=1; i<NUM_OF_PARTICLES; i++) {  
             // See boundaryCondition() for i=0 & NP-1.   

    // Before ReleaseEndPoint
    //
    //       ...............0.....................5.....
    //                       .                   .
    //                        1                 4           
    //                          .             .
    //                              2  .  3       
    //   
    //  
    //   
    // After ReleaseEndPoint
    //
    //       ...............0............................
    //                       .          
    //                        1                  
    //                          .               
    //                            2              5
    //                               .          .
    //                                  3  .  4
    //                          
    //       
    //       
    
    //float frictionCoeff = 0;  // No friction
    float frictionCoeff = 0.0001;
      
    float force_x = Float.NaN;
    float force_y = Float.NaN;

    if ( i < NUM_OF_PARTICLES-1 )  // Skip the end particle.
    {  
      float x0 = posx[i-1];
      float x1 = posx[i  ];
      float x2 = posx[i+1];
      float y0 = posy[i-1];
      float y1 = posy[i  ];
      float y2 = posy[i+1];
      float dist01 = dist(x0,y0,x1,y1);
      float dist12 = dist(x1,y1,x2,y2);

      float s_forceAmp01 = springK[i-1]*(dist01-l0);
      float s_forceAmp12 = springK[i  ]*(dist12-l0);
      
      float unitVec01x = (x1-x0)/dist01;
      float unitVec01y = (y1-y0)/dist01;
      float unitVec12x = (x2-x1)/dist12;
      float unitVec12y = (y2-y1)/dist12;
      float s_force01x = s_forceAmp01*unitVec01x;
      float s_force01y = s_forceAmp01*unitVec01y;
      float s_force12x = s_forceAmp12*unitVec12x;
      float s_force12y = s_forceAmp12*unitVec12y;
      float  g_force_y = -PARTICLE_MASS*GRAVITY_ACCELERATION;

      float v_force_x = -frictionCoeff*velx[i];
      float v_force_y = -frictionCoeff*vely[i];
      
      force_x = s_force12x - s_force01x + v_force_x;
      force_y = s_force12y - s_force01y + v_force_y + g_force_y;
    } 
    else if ( i==NUM_OF_PARTICLES-1 )  // The end particle
    {  
      float x0 = posx[i-1];
      float x1 = posx[i  ];
      float y0 = posy[i-1];
      float y1 = posy[i  ];
      float dist01 = dist(x0,y0,x1,y1);

      float s_forceAmp01 = springK[i-1]*(dist01-l0);
      
      float unitVec01x = (x1-x0)/dist01;
      float unitVec01y = (y1-y0)/dist01;
      float s_force01x = s_forceAmp01*unitVec01x;
      float s_force01y = s_forceAmp01*unitVec01y;
      float  g_force_y = -PARTICLE_MASS*GRAVITY_ACCELERATION;

      float v_force_x = -frictionCoeff*velx[i];
      float v_force_y = -frictionCoeff*vely[i];
      
      force_x = -s_force01x + v_force_x;
      force_y = -s_force01y + v_force_y + g_force_y;
    } 
    else 
    {
      println("*** Something is strange. ***");
      exit();
    }
    
    dposx[i] = velx[i] * dt;  // dx = vx * dt
    dposy[i] = vely[i] * dt;  // dy = vy * dt
    dvelx[i] = force_x * dtm; // dvx = (fx/m)*dt 
    dvely[i] = force_y * dtm; // dvy = (fy/m-g)*dt
  }
}



void boundaryCondition( float t, float[] x, float y[], float[] vx, float[] vy ) 
{
   x[0] = footPointLeftX;   // x-coord if particle No.0.
   y[0] = 0.0;              // y-coord if particle No.0.
  vx[0] = 0.0;
  vy[0] = 0.0;
  
  if ( !ReleaseEndPoint ) {  
     x[NUM_OF_PARTICLES-1] = footPointRightX;  //  x of the last particle.
     y[NUM_OF_PARTICLES-1] = 0.0;              //  y of the last particle.
    vx[NUM_OF_PARTICLES-1] = 0.0;              // vx of the last particle.
    vy[NUM_OF_PARTICLES-1] = 0.0;              // vy of the last particle.
  }
}


float mapx(float x) {
  // (x,y) = physical unit coords. 
  // (map(x),map(y)) = pixel coords.
  float scale = width/(xmax-xmin);
  return map(x, xmin, xmax, scale*xmin, scale*xmax);
}


float mapy(float y) {
  // (x,y) = physical unit coords. 
  // (map(x),map(y)) = pixel coords.
  float scale = height/(ymax-ymin);
  return map(y, ymin, ymax, scale*ymin, scale*ymax);
}



void drawText() {
  fill(0, 0, 0); 
  scale(1, -1);
}


void drawHorizontalLine() 
{
  stroke(200,0,200);
  line(mapx(xmin), mapy(0), mapx(xmax), mapy(0));
  stroke(200,0,0);
  line(mapx(0),mapy(0),mapx(xmin),mapy(0));
}


void drawString() {
  stroke(50, 100, 200);

  for (int i=0; i<NUM_OF_PARTICLES-1; i++) {
    if ( springK[i] > 0.0 ) {
      float x0 = particlePosX[i];
      float y0 = particlePosY[i];
      float x1 = particlePosX[i+1];
      float y1 = particlePosY[i+1];
      line(mapx(x0), mapy(y0), mapx(x1), mapy(y1));
    }
  }

  for (int i=0; i<NUM_OF_PARTICLES; i++) {
    float x = particlePosX[i];
    float y = particlePosY[i];
    ellipse(mapx(x), mapy(y), 5, 5);
  }
}


float cosh(float x) {
  return (exp(x)+exp(-x))/2;  
}


float catenaryCurve(float c1, float x1, float x) {
  return c1*(cosh(x/c1) - cosh(x1/c1));
}


void drawSingleSolutionCurveOfCatenary(float param_c1) {
  int npoint = 20;

  float dx = (footPointRightX-footPointLeftX)/(npoint-1);
  
  stroke(255,220,110);

  float x0 = footPointLeftX;
  float y0 = catenaryCurve(param_c1, footPointRightX, x0);
  
  for (int i=1; i<npoint; i++) {
    float x1 = footPointLeftX + dx*i;
    float y1 = catenaryCurve(param_c1, footPointLeftX, x1);
    line(mapx(x0), mapy(y0), mapx(x1), mapy(y1));
    x0 = x1;
    y0 = y1;
  }
}


void drawSolutionCurvesOfCatenary() {
  float param_c1_min = 0.3;
  float param_c1_max = 0.5;
  int ncurves = 10;
  
  for (int n=0; n<10; n++) {
    float param_c1 = param_c1_min + n*(param_c1_max-param_c1_min)/(ncurves-1);    
    drawSingleSolutionCurveOfCatenary( param_c1 );
  }
}


void draw() 
{
  background(255);
  stroke(0, 0, 255);

  translate(width/2, height*ymax/(ymax-ymin));
  scale(1, -1);

  if ( DrawSolutionCurvesToggle ) {
    drawSolutionCurvesOfCatenary();
  }
  drawString();
  drawHorizontalLine();

  if ( RunningStateToggle ) {
    for (int n=0; n<20; n++) { // to speed up the display
      rungeKutta4();
      step += 1;
      if ( step%100 == 0 ) {
        println("step=", nf(step,9), 
                "time=", nf(time,1,6), 
                "energy=", totalEnergy() );                
      }
    }
  }
  drawText();
}


void mousePressed() {
  if ( !RunningStateToggle && !ReleaseEndPoint ) { // Initial state
    RunningStateToggle = true;
    return;
  } 
    
  if ( RunningStateToggle && !ReleaseEndPoint ) {  // Release 
    ReleaseEndPoint = true;
    DrawSolutionCurvesToggle = false;
    return;
  }
  
  RunningStateToggle = !RunningStateToggle;
}
