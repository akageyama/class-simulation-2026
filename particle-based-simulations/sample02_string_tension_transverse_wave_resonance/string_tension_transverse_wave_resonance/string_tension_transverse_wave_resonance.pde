/*
  string_tension_transverse_wave_resonance.pde
  
 - Akira Kageyama (kage@port.kobe-u.ac.jp)
 
 - History
           2026.04.12: cp and revise string_catenary2.pde. 
                       This is string_tension_transverse_wave.           
           2026.04.23: Rename from sring_tension_transverse_wave.
                       This is string_tension_transverse_wave_resonance.
  

 - Note
         - We solve only the vertical (y-direcional) motion of each particle.
 
 - Usage 
           Mouse click : Start/Stop calculation
 
 */

boolean RunningStateToggle = false;


// string in natural state:     ooooooooooooooooooooooooooooooo
//                              .                               .
//                              .                                 .
// string in streched state :   ooooooooooooooooooooooooooooooooooooo
//
//
//
// When NUM_OF_PARTICLES = 7
//
//         particle number:       0    1    2    3    4    5    6
//                               /    /    /    /    /    /    / 
// string in natural state:     *----*----*----*----*----*----*
//                              .                               .
//                              .                                 .
// string in streched state :   *-----*-----*-----*-----*-----*-----*
//                             /     /     /     /     /     /     /
//                            0     1     2     3     4     5     6
//


//--------------------<input parameters>--------------------
final float STRING_NATURAL_LENGTH   = 1.0;    // (m)
final float STRING_STRETCHED_LENGTH = 1.1;    // (m)
final float STRING_MASS             = 0.001;  // (kg)
final float STRING_TENSION_FORCE    = 1.0;    // (N)
final int NUM_OF_PARTICLES = 100;   
final int DISPLAY_SPEED = 50;  // the larger, the higher quicker.
final boolean DISPLAY_PHASE_VELOCITY_MARKS = false;
//-------------------</input parameters>--------------------


//--------------------<derived parameters>--------------------

final float STRING_STRETCH 
              = STRING_STRETCHED_LENGTH-STRING_NATURAL_LENGTH; // (m)
final float STRING_TENSION_COEFFICIENT
              = STRING_TENSION_FORCE / STRING_STRETCH; // (N)(m)^{-1}
final float STRING_MASS_DENSITY 
              = STRING_MASS / STRING_NATURAL_LENGTH;  // (kg)(m)^{-1}
//
//
//                                        NATURAL_DISTANCE_BETWEEN_PARTICLES
//                                        . 
//                                        .
//                                     |--+-|
//         particle number:       0    1    2    3    4    5    6
//                               /    /    /    /    /    /    / 
// string in natural state:     *----*----*====*----*----*----*
//                                           |
//                                           spring between particles
//
//
//                   i-th particle    (i+1)-th particle
//                   /               /
//                  o = = = = = = = o
//                           .
//                            .
//                             spring between particles
//
//
// string in streched state :   *-----*-----*-----*-----*-----*-----*
//                             /     /     /     /     /     /     /
//                            0     1     2     3     4     5     6

//                
final float SPRING_NATURAL_LENGTH = STRING_NATURAL_LENGTH / (NUM_OF_PARTICLES-1);
final float SPRING_STRETCHED_LENGTH = STRING_STRETCHED_LENGTH / (NUM_OF_PARTICLES-1);
final float MASS_OF_A_PARTICLE = STRING_MASS_DENSITY * SPRING_NATURAL_LENGTH;
final float SPRING_STRETCH = SPRING_STRETCHED_LENGTH - SPRING_NATURAL_LENGTH;
final float SPRING_CONST = STRING_TENSION_FORCE / SPRING_STRETCH;

final float STRING_PHASE_VELOCITY = sqrt(STRING_TENSION_FORCE/STRING_MASS_DENSITY);

//-------------------</derived parameters>--------------------


float[] particlePosX = new float[NUM_OF_PARTICLES];
float[] particlePosY = new float[NUM_OF_PARTICLES];
float[] particleVelX = new float[NUM_OF_PARTICLES];
float[] particleVelY = new float[NUM_OF_PARTICLES];
float[] springK  = new float[NUM_OF_PARTICLES-1];

float spring_omega_sq = SPRING_CONST / MASS_OF_A_PARTICLE;
float spring_omega = sqrt(spring_omega_sq);   // (sec)^{-1}
float spring_period = TWO_PI / spring_omega;  // (sec)
float xmax_stretched_string =  STRING_STRETCHED_LENGTH / 2;
float xmin_stretched_string = -STRING_STRETCHED_LENGTH / 2;

float ymin = -0.01;  // (m)
float ymax =  0.01;  // (m)

float time = 0.0; // (sec)
int   step = 0;
float   dt = spring_period*0.01;  // (sec)

final int NORMAL_MODE_MAX = 20;
float[] normal_modes_omega = new float[NORMAL_MODE_MAX+1];;


void initialize_string() {
  for (int i=0; i<NUM_OF_PARTICLES-1; i++) {
    springK[i] = SPRING_CONST;
  }

  for (int i=0; i<NUM_OF_PARTICLES; i++) {
    particlePosX[i] = xmin_stretched_string + i*SPRING_STRETCHED_LENGTH;
    particlePosY[i] = 0.0; // y
    particleVelX[i] = 0.0; // vx
    particleVelY[i] = 0.0; // vy
  }
  
  /*
  for (int i=0; i<NUM_OF_PARTICLES; i++) {
    float half_length_of_wave_packet = STRING_STRETCHED_LENGTH*0.1;
    float amplitude_of_wave_packet = 0.001;  // (m)
    float x = particlePosX[i];
    if ( abs(x) < half_length_of_wave_packet ) {
      particlePosY[i] = amplitude_of_wave_packet*0.5*(1+cos(x/half_length_of_wave_packet*PI));
      particleVelY[i] = 1.0*sin(x/half_length_of_wave_packet*PI);
    }
  }
  */
}

void calculate_normal_modes() 
{
    normal_modes_omega[0] = Float.NaN;  // Not used.
    
    for (int n=1; n<=NORMAL_MODE_MAX; n++) {
       float normal_mode_wave_number = n * PI / STRING_STRETCHED_LENGTH;
       normal_modes_omega[n] = STRING_PHASE_VELOCITY * normal_mode_wave_number;
    }
}

void initialize() { 
  initialize_string();
  calculate_normal_modes();
}


void setup() {
  size(1500, 500);
  background(255);
  initialize();
  frameRate(60);
}


void draw() {
  background(255);
  stroke(0, 0, 255);

  translate(0, height);
  scale(1, -1);
  drawString();
  drawHorizontalLine();
  if ( DISPLAY_PHASE_VELOCITY_MARKS ) drawPhaseVelocityTickMarks();

  if ( RunningStateToggle ) {
    for (int n=0; n<DISPLAY_SPEED; n++) { // to speed up the display
      rungeKutta4();
      step += 1;
      if ( step%100 == 0 ) {
        println("step=", nf(step,9), 
                "time=", nf(time,1,6), 
                "energy=", totalEnergy() );
      }
    }
  }
}


float totalEnergy() {
  float kineticEnergy = 0.0;
  float potentialEnergy = 0.0;
  
  for (int i=0; i<NUM_OF_PARTICLES; i++) {
    float posx = particlePosX[i];
    float posy = particlePosY[i];
    float velx = particleVelX[i];
    float vely = particleVelY[i];
  
    if ( i>=1 && i<= NUM_OF_PARTICLES-1 ) {
      kineticEnergy += 0.5*MASS_OF_A_PARTICLE*(velx*velx+vely*vely);
    }
    
    if ( i>0 ) {
      float posx0 = particlePosX[i-1];
      float posy0 = particlePosY[i-1];      
      float l = dist(posx,posy,posx0,posy0) - SPRING_NATURAL_LENGTH;
      float lsq = l*l;
      potentialEnergy += 0.5*SPRING_CONST*lsq; 
    }
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
  float dtm = dt / MASS_OF_A_PARTICLE;
    
  for (int i=1; i<=NUM_OF_PARTICLES-2; i++) {  
             // See boundaryCondition() for i=0 & NP-1.   

    // 
    //     (x0,y0)          (x1,y1)       (x2,y2)
    //         i-1           i            i+1
    //          o------------o------------o
    //          |            |            |
    //          |<--dist01-->|<--dist02-->|
    //                         
    //
    
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
    
    // Notice: Here we ignore the dissipation.
    float frictionCoeff = 0.0;
    float v_force_x = -frictionCoeff*velx[i];
    float v_force_y = -frictionCoeff*vely[i];
    
    float force_x = s_force12x - s_force01x + v_force_x;
    float force_y = s_force12y - s_force01y + v_force_y;
    
    // Notice: Here we ignore the horizontal motion.
    force_x = 0;

    dposx[i] = velx[i] * dt;  // dx = vx * dt
    dposy[i] = vely[i] * dt;  // dy = vy * dt
    dvelx[i] = force_x * dtm; // dvx = (fx/m)*dt 
    dvely[i] = force_y * dtm; // dvy = (fy/m- g)*dt
  }
}



void boundaryCondition( float t, float[] x, float y[] ) 
{
    float omega = normal_modes_omega[1];
    float amplitude = 0.0001;

    x[0] = xmin_stretched_string;   // x-coord of left-most particle.
//  y[0] = 0.0;                     // y-coord of left-most particle.
    y[0] = amplitude*sin(omega*t);  // y-coord of left-most particle.    
    x[NUM_OF_PARTICLES-1] = xmax_stretched_string;  // x-coord of right-most particle.
    y[NUM_OF_PARTICLES-1] = 0.0;                    // y-coord of right-most particle.
}


float mapx(float x) {
  // (x,y) = physical unit coords. 
  // (map(x),map(y)) = pixel coords.
  
  //   |              |                  |               |
  //   |--left space--|==================|--right space--|
  //   |              |                  |               |
  //   0              window_x1          window_x2       width
  
  float left_space_in_pixel = width*0.1;
  float right_space_in_pixel = left_space_in_pixel;
  float window_x1_in_pixel = left_space_in_pixel;
  float window_x2_in_pixel = width - right_space_in_pixel;
  
  return map(x, xmin_stretched_string, xmax_stretched_string, window_x1_in_pixel, window_x2_in_pixel);
}


float mapy(float y) {
  // (x,y) = physical unit coords. 
  // (map(x),map(y)) = pixel coords.
  
  float lower_space_in_pixel = height*0.1;
  float upper_space_in_pixel = lower_space_in_pixel;
  float window_y1_in_pixel = lower_space_in_pixel;
  float window_y2_in_pixel = height - upper_space_in_pixel;
  
  return map(y, ymin, ymax, window_y1_in_pixel, window_y2_in_pixel);
}



void drawHorizontalLine() {
  stroke(100);
  line(mapx(xmin_stretched_string), mapy(0), mapx(xmax_stretched_string), mapy(0));
}


void drawPhaseVelocityTickMarks() {
  int NUM_TICK_MARCKS = 10;
  //
  //  When NUM_TICK_MARCKS = 4,
  //
  //           xmin=================s=t=r=i=n=g=============xmax
  //             |          |          |          |          |
  //             D-->       D-->       D-->       D-->       
  //
  float distance_between_dummy_particles = STRING_STRETCHED_LENGTH / NUM_TICK_MARCKS;
  
  
  // Right-moving dummy particles
  strokeWeight(3);
  stroke(140,40,40);
  for (int i=0; i<NUM_TICK_MARCKS; i++) {
    float x = i*distance_between_dummy_particles;
    
    x += STRING_PHASE_VELOCITY * time;
    x = x % STRING_STRETCHED_LENGTH;
    x += xmin_stretched_string;        
    line(mapx(x), mapy(ymin*0.9), mapx(x), mapy(ymin*0.95));
  }
  
  // Left-moving dummy particles
  stroke(40,140,40);
  for (int i=0; i<NUM_TICK_MARCKS; i++) {
    float x = -i*distance_between_dummy_particles;
    
    x -= STRING_PHASE_VELOCITY * time;
    x = -((-x) % STRING_STRETCHED_LENGTH);
    x += xmax_stretched_string;        
    line(mapx(x), mapy(ymax*0.9), mapx(x), mapy(ymax*0.95));
  }
  strokeWeight(1);
  
}


void drawString() {
  stroke(125,125,255);

  for (int i=0; i<NUM_OF_PARTICLES-1; i++) {
    if ( springK[i] > 0.0 ) {
      float x0 = particlePosX[i];
      float y0 = particlePosY[i];
      float x1 = particlePosX[i+1];
      float y1 = particlePosY[i+1];
      line(mapx(x0), mapy(y0), mapx(x1), mapy(y1));
    }
  }

  fill(0);
  for (int i=0; i<NUM_OF_PARTICLES; i++) {
    float x = particlePosX[i];
    float y = particlePosY[i];
    ellipse(mapx(x), mapy(y), 5, 5);
  }
}



void mousePressed() {
  RunningStateToggle = !RunningStateToggle;
}
